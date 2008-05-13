#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok 'Zucchini::Fsync';
}

can_ok(
    'Zucchini::Fsync',
    qw(
        new
        ftp_sync
        prepare_ftp_client
    )
);

# evil globals
my ($zucchini_fsync);

# just create a ::Rsync object
$zucchini_fsync = Zucchini::Fsync->new();
isa_ok($zucchini_fsync, q{Zucchini::Fsync});
