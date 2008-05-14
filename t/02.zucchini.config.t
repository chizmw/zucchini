#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
    use_ok 'Zucchini::Config';
}

BEGIN {
    use FindBin;
    use lib qq{$FindBin::Bin/testlib};
    use Zucchini::TestConfig;
}

can_ok(
    'Zucchini::Config',
    qw(
        new
        get_data
        get_options
        set_options
        get_site
        set_site
        get_siteconfig

        ignored_directories
        ignored_files
        is_dry_run
        is_fsync
        is_fsync_only
        is_rsync
        is_rsync_only
        templated_files
        verbose

        _load_config
        _sane_config
    )
);

# evil globals
my ($zucchini_cfg, $test_config);

# get a test_config object
$test_config = Zucchini::TestConfig->new();
isa_ok($test_config, q{Zucchini::TestConfig});

# just create a ::Config object
$zucchini_cfg = Zucchini::Config->new(
    {
        config_data => $test_config->site_config
    }
);
isa_ok($zucchini_cfg, q{Zucchini::Config});

# just create a ::Config object
$zucchini_cfg = Zucchini::Config->new(
    {
        config_data => $test_config->site_config,
        site => q{herlpacker},
    }
);
isa_ok($zucchini_cfg, q{Zucchini::Config});
is(
    $zucchini_cfg->get_site(),
    q{herlpacker},
    q{->get_site() returns correct value}
);
