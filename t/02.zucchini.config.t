#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    use_ok 'Zucchini::Config';
}

can_ok(
    'Zucchini::Config',
    qw(
        new
        get_data
        get_options
        get_site
        set_site
        get_siteconfig

        ignored_directories
        ignored_files
        is_fsync_only
        is_rsync_only
        verbose

        _load_config
        _sane_config
    )
);

# evil globals
my ($zucchini_cfg);

# just create a ::Config object
$zucchini_cfg = Zucchini::Config->new();
isa_ok($zucchini_cfg, q{Zucchini::Config});

use Data::Dump qw(pp);
#diag pp($zucchini_cfg->get_data);
#diag pp($zucchini_cfg->get_siteconfig);

# just create a ::Config object
$zucchini_cfg = Zucchini::Config->new(
    {
        site => 'herlpacker',
    }
);
isa_ok($zucchini_cfg, q{Zucchini::Config});
is(
    $zucchini_cfg->get_site(),
    q{herlpacker},
    q{->get_site() returns correct value}
);
