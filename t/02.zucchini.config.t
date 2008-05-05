#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok 'Zucchini::Config';
}

can_ok(
    'Zucchini::Config',
    qw(
        new
        get_data

        _load_config
    )
);

my $zucchini_cfg = Zucchini::Config->new();
isa_ok($zucchini_cfg, q{Zucchini::Config});

use Data::Dump qw(pp);
diag pp($zucchini_cfg->get_data);
