package Zucchini;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Zucchini::Version; our $VERSION = $Zucchini::VERSION;
use Zucchini::Config;

# object attributes
my %config_of :ATTR( get => 'config', set => 'config' );

use Class::Std;
{
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

        $self->set_config(
            Zucchini::Config->new()
        );

        return;
    }
};

1;

__END__

=pod

=head1 NAME

Zucchini - turn templates into static websites

=head1 DESCRIPTION

TODO

=head1 SYNOPSIS

TODO

=head1 SEE ALSO

Nothing

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

Copyright 2008 by Chisel Wright

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
