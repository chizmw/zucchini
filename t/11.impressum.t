#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use FindBin;
    use lib qq{$FindBin::Bin/testlib};
    use Zucchini::Test;
    use Zucchini::TestConfig;
}

BEGIN {
    use_ok 'Zucchini';
}

# evil globals
my ($test_config, $zucchini);

# get a test_config object
$test_config = Zucchini::TestConfig->new();
isa_ok($test_config, q{Zucchini::TestConfig});
# create a Zucchini object using our test-config
$zucchini = Zucchini->new(
    {
        config_data => $test_config->site_config,
        site => 'impressum',
    }
);
isa_ok($zucchini, q{Zucchini});
ok(defined($zucchini->get_config), q{object has configuration data});
