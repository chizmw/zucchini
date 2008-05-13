#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use FindBin;
    use lib qq{$FindBin::Bin/testlib};
    use Zucchini::TestConfig;
}

BEGIN {
    use File::Temp qw(tempdir);
    use_ok 'Zucchini::Rsync';
}

can_ok(
    'Zucchini::Rsync',
    qw(
        new
        remote_sync
    )
);

# evil globals
my ($zucchini_rsync, $test_config);

# get a test_config object
$test_config = Zucchini::TestConfig->new();
isa_ok($test_config, q{Zucchini::TestConfig});

# just create a ::Rsync object
$zucchini_rsync = Zucchini::Rsync->new(
    {
        config => $test_config->get_config,
    }
);
isa_ok($zucchini_rsync, q{Zucchini::Rsync});

$zucchini_rsync->get_config->set_options(
    {
        verbose => 3,
    }
);

diag $zucchini_rsync->get_config->get_siteconfig->{rsync}{path};
$zucchini_rsync->remote_sync();


use File::Find;
find(
    sub { -r && print },
    $zucchini_rsync->get_config->get_siteconfig->{rsync}{path}
);

