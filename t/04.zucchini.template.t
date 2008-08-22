#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use File::Find;
use Path::Class;
use Test::More tests => 6;

BEGIN {
    use FindBin;
    use lib qq{$FindBin::Bin/testlib};
    use Zucchini::TestConfig;
    use Zucchini::Test;
}

BEGIN {
    use_ok 'Zucchini::Template';
}

can_ok(
    'Zucchini::Template',
    qw(
        new

        get_config
        set_config

        get_ttobject
        set_ttobject

        directory_contents
        file_checksum
        file_modified
        ignore_directory
        ignore_file
        item_name
        process_directory
        process_file
        process_site
        relative_path_from_full
        same_file
        show_destination
        template_file
    )
);

# evil globals
my ($zucchini_tpl, $test_config, @input_tree, @output_tree);

# get a test_config object
$test_config = Zucchini::TestConfig->new();
isa_ok($test_config, q{Zucchini::TestConfig});

# create a ::Template object
$zucchini_tpl = Zucchini::Template->new(
    {
        config => $test_config->get_config,
    }
);
isa_ok($zucchini_tpl, q{Zucchini::Template});
ok(defined($zucchini_tpl->get_config), q{object has configuration data});

# perform the magic
$zucchini_tpl->process_site;

# make sure we get "what we expect" in the output directory
Zucchini::Test::compare_input_output($zucchini_tpl->get_config);
