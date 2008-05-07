#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok 'Zucchini::Rsync';
}

can_ok(
    'Zucchini::Rsync',
    qw(
        new
    )
);

# evil globals
my ($zucchini_rsync);

# just create a ::Rsync object
$zucchini_rsync = Zucchini::Rsync->new();
isa_ok($zucchini_rsync, q{Zucchini::Rsync});
