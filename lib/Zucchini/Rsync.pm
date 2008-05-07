package Zucchini::Rsync;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Zucchini::Version; our $VERSION = $Zucchini::VERSION;

use Carp;
use Config::Any;

# class data
my %config_of   :ATTR( get => 'config',     set => 'config' );

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
}

1;

__END__

=pod

=head1 NAME

Zucchini::Rsync - transfer files to remote server using rsync

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<Zucchini>,
L<Zucchini::Fsync>,
L<Zucchini::Rsync>,
L<Config::Any>,
L<Config::General>

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

Copyright 2008 by Chisel Wright

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
