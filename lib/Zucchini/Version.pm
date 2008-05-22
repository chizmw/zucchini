package Zucchini;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

# from mst on #catalyst
use version; our $VERSION = qv(0.0.7)->numify;

package Zucchini::Version;

our $VERSION = $Zucchini::VERSION;

1;

__END__

=head1 NAME

Zucchini::Version - The Zucchini project-wide version number

=head1 SYNOPSIS

    package Zucchini::Whatever;

    # Must be on one line so MakeMaker can parse it.
    use Zucchini::Version;  our $VERSION = $Zucchini::VERSION;

=head1 DESCRIPTION

Because of the problems coordinating revision numbers in a distributed
version control system and across a directory full of Perl modules, this
module provides a central location for the project's release number.

=head1 IDEA FROM

This idea was taken from L<SVK>

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

Copyright 2008 by Chisel Wright

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
