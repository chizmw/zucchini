package Zucchini::Fsync;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Zucchini::Version; our $VERSION = $Zucchini::VERSION;

use Carp;
use Config::Any;
use Digest::MD5 qw(md5_hex);
use File::Basename;
use File::Find;
use File::Slurp qw(read_file write_file);
use File::Temp qw( tempfile );
use Net::FTP;
use Path::Class;

# class data
my %config_of       :ATTR( get => 'config',         set => 'config'         );
my %ftpclient_of    :ATTR( get => 'ftp_client',     set => 'ftp_client'     );
my %ftproot_of      :ATTR( get => 'ftp_root',       set => 'ftp_root'       );
my %remotedigest_of :ATTR( get => 'remote_digest'   set => 'remote_digest'  );

use Class::Std;
{
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

        # store the Zucchini::Config object
        $self->set_config(
            $arg_ref->{config}
        );

        return;
    }
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;

        # set up an ftp client/connection to work with
        if (defined $self->get_config) {
            $self->prepare_ftp_client;
        }

        return;
    }

    sub build_transfer_actions {
        my $self = shift;
        my $config  = $self->get_config->get_siteconfig();
        my ($local_digest_file, $remote_digest_file);
        my ($local_md5_of, $remote_md5_of, %transfer_action_of);

        # the two files we are going to compare
        $local_digest_file = file(
            $config->{output_dir},
            q{digest.md5}
        );
        warn "local: $local_digest_file\n";
        $remote_digest_file = file(
            $self->get_remote_digest
        );
        warn "remote: $remote_digest_file\n";

        $local_md5_of   = $self->parse_md5file($local_digest_file);
        $remote_md5_of  = $self->parse_md5file($remote_digest_file) || {};

        # run through the list of files we have locally
        foreach my $relpath (
            sort { length($a) <=> length($b) } keys %{$local_md5_of}
        ) {
            my $dirname     = dirname($relpath);
            my $parentdir   = dir($dirname)->parent();

            # make sure our parent directory exists
            # (prevents problems with nested dirs that contain no files)
            while (
                q{..} ne $parentdir
                    and 
                not exists $transfer_action_of{$parentdir}
            ) {
                # this is effectively a NO-OP that gets the directory name
                # into the list of (required) remote directories
                push @{$transfer_action_of{$parentdir}},
                {
                    action  => 'dir-dir',
                };

                # recurse upwards
                $parentdir = $parentdir->parent();
            }

            # does the file live in the server?
            if (exists $remote_md5_of->{$relpath}) {
                # if the MD5s match - nothing to do
                if ($local_md5_of->{$relpath} eq $remote_md5_of->{$relpath}) {
                    delete $local_md5_of->{$relpath};
                    delete $remote_md5_of->{$relpath};
                    next;
                }

                push @{$transfer_action_of{$dirname}},
                {
                    action  => 'update',
                    relname => $relpath,
                };
                delete $local_md5_of->{$relpath};
                delete $remote_md5_of->{$relpath};
            }
            # ... it's a new file to put on the server
            else {
                push @{$transfer_action_of{$dirname}},
                {
                    action  => 'new',
                    relname => $relpath,
                };
                delete $local_md5_of->{$relpath};
            }
        }

        # anything left in remote is a file we don't have locally
        # we'll store actions (remove) for these, but won't act on the
        # action until specifically asked
        foreach my $relpath (sort keys %{$remote_md5_of}) {
            my $dirname = dirname($relpath);
            push @{$transfer_action_of{$dirname}},
            {
                action  => 'remove',
                relname => $relpath,
            };
            delete $remote_md5_of->{$relpath};
        }

        # make sure we didn't miss anything
        if (keys %{$local_md5_of}) {
            warn qq{Some local files were not processed};
            warn qq{Local:   } . pp($local_md5_of);
        }
        if (keys %{$remote_md5_of}) {
            warn qq{Some remote files were not processed};
            warn qq{Remote:   } . pp($remote_md5_of);
        }

        return \%transfer_action_of;
    }

    sub do_remote_update {
        my $self                = shift;
        my $transfer_actions    = shift;
        my $config              = $self->get_config->get_siteconfig();
        my $ftp                 = $self->get_ftp_client;
        my $ftp_root            = $self->get_ftp_root;
        my $errors              = 0;

        if (not defined $ftp) {
            warn(qq{No FTP server defined. Aborting upload.\n});
            return;
        }

        # do transfer actions shortest dirname first
        my @remote_dirs = sort {
            length($a) <=> length($b)
        } keys %{$transfer_actions};

        my $ftp_root_status = $ftp->cwd($ftp_root);
        if (not $ftp_root_status) {
            die "$ftp_root: couldn't CWD to remote directory\n";
        }
        my $default_dir = $ftp->pwd();
        if ($default_dir !~ m{/\z}xms) {
            $default_dir .= q{/};
        }

        # make missing (remote) directories
        warn "checking remote directories...\n"
            if ($self->get_config->verbose(1));
        foreach my $dir (@remote_dirs) {
            my $status = $ftp->cwd($default_dir . $dir);
            if (not $status) {
                # verbose ouput
                warn (q{MKDIR } . dir($default_dir, $dir) . qq{\n})
                    if ($self->get_config->verbose(1));
                # make the missing directory
                if (not $ftp->mkdir($default_dir . $dir)) {
                    warn (
                          q{FAILED MKDIR }
                        . dir($default_dir, $dir) 
                        . q{ - }
                        . $ftp->message
                        . qq{\n});
                }
            }
        }
        # return to the default location
        $ftp->cwd($default_dir);

        # now run through everything and take the appropriate action for files
        warn "transferring files...\n"
            if ($self->get_config->verbose(1));
        foreach my $dir (@remote_dirs) {
            # run through the actions for the directory
            foreach my $action ( @{$transfer_actions->{$dir}} ) {
                if ($action->{action} =~ m{\A(?:new|update)\z}) {
                    # verbose ouput
                    warn (
                          q{PUT }
                        . $action->{relname}
                        . q{ }
                        . $action->{relname}
                        . qq{\n}
                    )
                        if ($self->get_config->verbose(1));
                    # send the file
                    if (not $ftp->put( $action->{relname}, $action->{relname} )) {
                        $errors++;
                        warn "failed to upload $action->{relname}\n";
                        warn (
                            q{FAILED PUT }
                            . $action->{relname}
                            . q{ }
                            . $action->{relname}
                            . q{ - }
                            . $ftp->message
                            . qq{\n}
                        );
                    }
                }
            }
        }

        # if we didn't have any errors, upload the digest
        if (not $errors) {
            # verbose ouput
            warn (
                  q{PUT }
                . q{digest.md5}
                . qq{\n}
            )
                if ($self->get_config->verbose(1));
            # upload the digest file
            $ftp->put('digest.md5');
        }
        else {
            warn "FTP ERRORS - SORRY!\n";
        }
    }

    sub fetch_remote_digest {
        my $self = shift;
        my $config  = $self->get_config->get_siteconfig();
        my ($fh, $filename, $get_ok);

        # a temporary file to use
        ($fh, $filename) = tempfile();
        $config->{tmp_remote_digest} = $filename;

        # get the (remote) digest file
        $get_ok = $self->get_ftp_client->get(
            q{digest.md5},
            $filename
        );
        if (not $get_ok) {
            warn "No remote digest\n";
            return;
        }

        $self->set_remote_digest($filename);

        return;
    }

    sub ftp_sync {
        my $self    = shift;
        my $config  = $self->get_config->get_siteconfig();
        my (@md5strings, $transfer_actions);

        # make sure we have an ftp client to use
        $self->prepare_ftp_client;
        if (not defined $self->get_ftp_client) {
            warn(qq{Failed to connect to remote FTP server. Aborting upload.\n});
            return;
        }

        # regenerate (local) md5s
        find(
            sub{
                $self->local_ftp_wanted(\@md5strings);
            },
            $config->{output_dir}
        );
        write_file(
            qq{$config->{output_dir}/digest.md5},
            @md5strings
        );

        # get the remote digest
        $self->fetch_remote_digest;

        # work out what needs to happen
        $transfer_actions = $self->build_transfer_actions;
        #use Data::Dump qw(pp); die pp($transfer_actions);

        # do the remote update
        $self->set_ftp_root(
            $config->{'ftp'}{'path'} || '/'
        );
        $self->do_remote_update($transfer_actions);

        return;
    }

    sub local_ftp_wanted {
        my ($self, $md5string_list) = @_;
        my $config  = $self->get_config->get_siteconfig();

        if (
            -f $_
                and
            $_ ne q{digest.md5}
                and
            $_ !~ m{\.sw?}
        ) {
            push @{$md5string_list},
                  $self->md5file($File::Find::name)
                . qq{\n};
        }
    }

    sub md5file {
        my ($self, $file) = @_;
        my $config  = $self->get_config->get_siteconfig();
        my $dir_prefix = $config->{output_dir};
        my ($filedata, $md5sum, $rel_filename, $md5data);

        # slurp the file
        $filedata = read_file($file)
            or die "$file: $!";
        # get the md5sum of the file
        $md5sum = md5_hex($filedata);
        # trim off any leading directories - making filename relative)
        if (defined $dir_prefix) {
            $rel_filename = $file;
            $rel_filename =~ s{\A${dir_prefix}/}{};
        }

        # return an md5 string
        return "$md5sum    $rel_filename";
    }

    sub parse_md5file {
        my ($self, $file) = @_;
        my (%md5_of, @lines);

        if (not defined $file or $file =~ m{\A\s*\z}) {
            carp "undefined filename passed to parse_md5file()";
            return {};
        }

        if (! -f $file) {
            carp "$file: file not found";
            return {};
        }

        # read in the file - ".q{}" forces any Path::Class objects to be
        # stringified
        @lines = read_file($file.q{})
            or die "$file: $!";

        # parse/split each line
        foreach my $line (@lines) {
            chomp($line);
            if ($line =~ m{\A([a-z0-9]{32})\s+(.+)\z}xms) {
                $md5_of{$2} = $1;
            }
        }

        return \%md5_of;
    }

    sub prepare_ftp_client {
        my $self = shift;
        my $config      = $self->get_config->get_siteconfig();
        my $cliopt      = $self->get_config->get_options();

        # make sure we have some defaults
        $config->{ftp}{hostname}    ||= 'localhost';
        $config->{ftp}{passive}     ||= 0;
        $config->{ftp}{username}    ||= 'anonymous';
        $config->{ftp}{password}    ||= 'coward';

        # if we already have an FTP object, use it
        if (defined $self->get_ftp_client) {
            warn qq{using existing FTP object\n}
                if ($self->get_config->verbose(3));
            # nothing to actually do
        }
        else {
            # make sure we can chdir() to the local root
            if (not chdir($config->{output_dir})) {
                warn qq{could not chdir to: $config->{output_dir}\n};
                exit;
            }

            warn qq{creating new FTP object\n}
                if ($self->get_config->verbose(3));
            my $ftp = Net::FTP->new(
                $config->{ftp}{hostname},
                Debug   => ($cliopt->{'ftp-debug'} || 0),
                Passive => $config->{ftp}{passive},
            );
            # make sure we've got a usable FTP object
            if (not defined $ftp) {
                warn(qq{Failed to connect to server [$config->{ftp}{hostname}]: $!\n});
                return;
            };
            # try to login
            if (not $ftp->login(
                    $config->{ftp}{username},
                    $config->{ftp}{password}
                )
            ) {
                warn(qq{Failed to login as $config->{ftp}{username}\n});
                return;
            }
            # try to cwd, if required
            if (defined $config->{ftp}{working_dir}) {
                if (not $ftp->cwd( $config->{ftp}{working_dir} ) ) {
                    warn(qq{Cannot change directory to $config->{ftp}{working_dir}\n});
                    return;
                }
            }
            # use binary transfer mode
            if (not $ftp->binary()) {
                warn(qq{Failed to set binary mode\n});
                return;
            }

            $self->set_ftp_client($ftp);
        }

        return;
    }
}

1;

__END__

=pod

=head1 NAME

Zucchini::Fsync - transfer files to remote server using "ftp-sync"

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<Zucchini>,

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

Copyright 2008 by Chisel Wright

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
