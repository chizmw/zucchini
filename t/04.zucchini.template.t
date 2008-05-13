#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use File::Find;
use Path::Class;
use Test::More tests => 5;

BEGIN {
    use FindBin;
    use lib qq{$FindBin::Bin/testlib};
    use Zucchini::TestConfig;
}

BEGIN {
    use_ok 'Zucchini::Template';
}

can_ok(
    'Zucchini::Template',
    qw(
        new
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

# perform the magic
$zucchini_tpl->process_site;

PROCESS_WORKED: {

    sub add_to_tree_list {
        my $file    = shift;
        my $dir     = shift;
        my $root    = shift;
        my $listref = shift;

        $dir =~ s{\A${root}}{};
        push @{$listref}, file($dir, $file);
        #warn "Found: " . file($dir, $file);
    }

    # get a list of files in the input dir
    find(
        {
            wanted => sub {
                -r && do {
                    add_to_tree_list(
                        $_,
                        $File::Find::dir,
                        $zucchini_tpl->get_config->get_siteconfig->{source_dir},
                        \@input_tree
                    );
                };
            },
        },
        $zucchini_tpl->get_config->get_siteconfig->{source_dir},
    );
    # get a list of files in the output dir
    find(
        {
            wanted => sub {
                -r && do {
                    add_to_tree_list(
                        $_,
                        $File::Find::dir,
                        $zucchini_tpl->get_config->get_siteconfig->{output_dir},
                        \@output_tree
                    );
                };
            },
        },
        $zucchini_tpl->get_config->get_siteconfig->{output_dir},
    );

    # we should have the same files in the template directory
    # and the output directory
    is_deeply(\@input_tree, \@output_tree);
}
