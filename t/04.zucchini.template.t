#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 3;

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
my ($zucchini_tpl);

# just create a ::Template object
$zucchini_tpl = Zucchini::Template->new();
isa_ok($zucchini_tpl, q{Zucchini::Template});
