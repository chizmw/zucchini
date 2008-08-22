#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::NoWarnings;
use Test::More tests => 6;

BEGIN {
    use FindBin;
    use lib qq{$FindBin::Bin/testlib};
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
        config => $test_config->get_config,
    }
);
isa_ok($zucchini, q{Zucchini});
ok(defined($zucchini->get_config), q{object has configuration data});

# process / generate the site
$zucchini->process_templates;

diag $test_config->get_outputdir;

# make sure that the "swp" file wasn't copied
ok (
    ! -e $test_config->get_outputdir . q{_should_be_ignored_.swp},
    q{'swp' file not copied to outdir}
)
