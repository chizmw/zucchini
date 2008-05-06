#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok 'Zucchini';
}

can_ok(
    'Zucchini',
    qw(
        new
        get_config
        set_config
        gogogo
    )
);

my $zucchini = Zucchini->new();
isa_ok($zucchini, q{Zucchini});
