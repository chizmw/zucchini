package Zucchini::Fsync;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Zucchini::Version; our $VERSION = $Zucchini::VERSION;

use Carp;
use Config::Any;
use Net::FTP;

# class data
my %config_of       :ATTR( get => 'config',     set => 'config'     );
my %ftpclient_of    :ATTR( get => 'ftp_client', set => 'ftp_client' );

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

    sub ftp_sync {
        my $self = shift;
        my $config      = $self->get_config->get_siteconfig();

        # make sure we have an ftp client to use
        $self->prepare_ftp_client;

        return;
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
