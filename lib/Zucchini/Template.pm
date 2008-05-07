package Zucchini::Template;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Zucchini::Version; our $VERSION = $Zucchini::VERSION;

use Carp;
use Digest::MD5;
use File::Copy;
use File::stat;
use Template;

# object attributes
my %config_of   :ATTR( get => 'config',     set => 'config' );
my %ttobject_of :ATTR( get => 'ttobject',   set => 'ttobject' );

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

    sub process_site {
        my $self = shift;
        my $directory = $self->get_config->get_siteconfig->{source_dir};

        # start the directory descent ...
        $self->process_directory( $directory );

        return;
    }

    sub process_directory {
        my $self        = shift;
        my $directory   = shift;

        # for easier access - we should probably objectify this better - TODO
        my $config  = $self->get_config->get_siteconfig();
        my $cliopt  = $self->get_config->get_options();

        # function variables
        my (@list, $relpath);

        # get the list of stuff in the directory
        @list = $self->directory_contents($directory);
        # get our relative path from 'source_dir'
        $relpath = $self->relative_path_from_full($directory);

        # loop through the items in the list and Do The Right Thing
        foreach my $item (@list) {
            # process individual files
            if (-f qq{$directory/$item}) {
                # skip ignored files
                if ($self->ignore_file($item)) {
                    next;
                }

                # getting this far means we should (try to) process the file
                $self->process_file($directory, $item);
                next;
            }

            # process directories
            elsif (-d qq{$directory/$item}) {
                # skip ignored dirs
                if ($self->ignore_directory($item)) {
                    next;
                }

                my $outdir = qq{$config->{output_dir}/$relpath/$item};
                # make sure the directory exists in the output tree
                if (! -d $outdir) {
                    warn "ouput directory '$outdir' does not exist\n";
                    if (not mkdir($outdir)) {
                        carp "couldn't create output directory: $!";
                        exit;
                    }
                    warn "created: $outdir\n";

                }

                # process the subdirectory
                $self->process_directory(qq{$directory/$item});
                next;
            }

            # not a file or directory?
            # we don't handle Odd Stuff (yet?)
            else {
                warn "unhandled file-type for '$directory/$item\n";
                next;
            }
        }

        return;
    }

    sub directory_contents {
        my $self        = shift;
        my $directory   = shift;
        my (@list);

        # get a list of everything (except . and ..) in $directory
        opendir(DIR, $directory)
            or die("can't open '$directory': $!\n");

        @list = grep { $_ !~ /^\.\.?$/ } readdir(DIR);

        return @list;
    }

    sub file_checksum {
        my $self = shift;
        my $file = shift;
        my ($md5);

        # try to open the file
        open(FILE,$file) or do {
            warn "Can't open $file: $!";
            return undef;
        };
        binmode(FILE);

        $md5 = Digest::MD5->new->addfile(*FILE)->hexdigest;

        return $md5;
    }

    sub file_modified {
        my $self = shift;
        my ($template_file, $templated_file) = @_;
        my ($template_stat, $templated_stat);

        # if the destination file doesn't exist, it's "modified"
        if (not -e $templated_file) {
            return 1;
        }

        # get stat info for each file
        $template_stat  = stat( $template_file)   or die "no file: $!\n";
        $templated_stat = stat($templated_file)   or die "no file: $!\n";

        # return true if the templated file is OLDER than the template itself
        # i.e. the source has been altered since we last generated the final result
        return ($templated_stat->mtime < $template_stat->mtime);
    }

    sub ignore_directory {
        my ($self, $directory) = @_;

        foreach my $ignore_me (@{ $self->get_config->ignored_directories }) {
            my $regex = qr/ \A $ignore_me \z /x;

            if ($directory =~ $regex) {
                warn "ignoring directory '$directory'. Match on '$regex'.\n"
                    if ($self->get_config->verbose);
                return 1;
            }
        }

        return;
    }

    sub ignore_file {
        my ($self, $filename) = @_;

        foreach my $ignore_me (@{ $self->get_config->ignored_files }) {
            my $regex = qr/ $ignore_me /x;

            if ($filename =~ $regex) {
                warn "ignoring file '$filename'. Match on '$regex'.\n"
                    if ($self->get_config->verbose);
                return 1;
            }
        }

        return;
    }

    sub item_name {
        my $self = shift;
        my ($directory, $item) = @_;
        my ($filename);

        # TODO - objectify better
        my $cliopt  = $self->get_config->get_options();
        my $config  = $self->get_config->get_siteconfig();

        # default case - just the item name
        $filename = $item;

        # if we want to see the relative path
        if ($cliopt->{showpath}) {
            # get the full path to the file
            $filename = "$directory/$item";
            # remove path to sourcedir
            $filename =~ s{\A$config->{source_dir}/}{}xms;
        }

        return $filename;
    }

    sub process_file {
        my $self        = shift;
        my $directory   = shift;
        my $item        = shift;
        my ($relpath);

        # stuff we used to pass through in the script
        # TODO objectify this
        my $config  = $self->get_config->get_siteconfig();
        my $cliopt  = $self->get_config->get_options();

        # get the relative path
        $relpath = $self->relative_path_from_full($directory);

        # push the section name into the vars to replace
        my $site_vars = {
            source_dir  => $config->{source_dir},
            %{ $config->{tags} }
        };

        # some files should be run through TT
        if ($self->template_file($item)) {

            # only create the template object once - it's stupid to create
            # a new one for each file we template
            if (not defined $self->get_ttobject) {
                my $tt_config = {
                    ABSOLUTE        => 1,
                    EVAL_PERL       => 0,
                    INCLUDE_PATH    => "$config->{source_dir}:$config->{includes_dir}",
                };
                if (defined $config->{plugin_base}) {
                    $tt_config->{PLUGIN_BASE} = $config->{plugin_base};
                }

                $self->set_ttobject(
                    Template->new( $tt_config )
                );
            }

            # if the template and the destination have the same timestamp, nothing's changed
            # HOWEVER, we only care if we're not forcing the template-output to be regenerated
            if (not $cliopt->{force}) {
                if (not $self->file_modified("$directory/$item", "$config->{output_dir}/$relpath/$item")) {
                    warn "unchanged: " . $self->item_name($directory,$item) .  qq{\n}
                        if ($self->get_config->verbose(2));
                    return;
                }
            }

            warn (q{templating: } . $self->item_name($directory, $item) . qq{\n});
            $self->show_destination($directory, $item);

            $self->get_ttobject->process(
                "$directory/$item",
                $site_vars,
                "$config->{output_dir}/$relpath/$item"
            )
                or Carp::croak ("\n" . $self->get_ttobject->error());
        }
        # others should be copied (if they've changed
        else {
            # only copy files if the MD5 hasn't changed
            if (not $self->same_file("$directory/$item", "$config->{output_dir}/$relpath/$item")) {
                warn (q{Copying: } . $self->item_name($directory, $item) . qq{\n});
                copy("$directory/$item", "$config->{output_dir}/$relpath/$item");
                $self->show_destination($directory, $item);
            }
        }

        return;
    }

    sub relative_path_from_full {
        my $self        = shift;
        my $directory   = shift;
        my $config      = $self->get_config->get_siteconfig();
        my ($relpath);

        # get the relative path from the full srcdir path
        $relpath = $directory;
        # remove source_dir from directory path
        $relpath =~ s:^$config->{source_dir}::;
        # remove leading / (if any)
        $relpath =~ s:^/::;

        return $relpath;
    }

    sub same_file {
        my $self = shift;
        my ($file1, $file2) = @_;

        if (! -f $file2 or ! -f $file2) {
            return 0;
        }

        if ($self->file_checksum($file1) eq $self->file_checksum($file2)) {
            return 1;
        }

        return 0;
    }

    sub show_destination {
        my $self = shift;
        my ($directory, $item) = @_;
        my ($relpath);

        # stuff we used to pass through in the script
        # TODO objectify this
        my $config  = $self->get_config->get_siteconfig();
        my $cliopt  = $self->get_config->get_options();

        # get the relative path for the directory
        $relpath = $self->relative_path_from_full($directory);

        if ($cliopt->{showdestination}) {
            if ($relpath) {
                warn(qq{  --> $config->{output_dir}/$relpath/$item\n});
            }
            # top-level files don't have a relpath and we'd prefer not to have '//' in the path
            else {
                warn(qq{  --> $config->{output_dir}/$item\n});
            }
        }

        return;
    }

    sub template_file {
        my ($self,$filename) = @_;
        my $config  = $self->get_config->get_siteconfig();

        foreach my $ignore_me (@{ $self->get_config->templated_files }) {
            my $regex = qr/ $ignore_me /x;

            if ($filename =~ $regex) {
                return 1;
            }
        }

        return;
    }

};

1;

__END__

=pod

=head1 NAME

Zucchini::Template - process templates and output static files

=head1 DESCRIPTION

TODO

=head1 SYNOPSIS

TODO

=head1 SEE ALSO

L<Zucchini>

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

Copyright 2008 by Chisel Wright

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

