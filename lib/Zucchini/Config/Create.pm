package Zucchini::Config::Create;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Zucchini::Version; our $VERSION = $Zucchini::VERSION;

use IO::File;

use Class::Std;
{
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;
        return;
    }

    sub write_default_config {
        my $self        = shift;
        my $filename    = shift;

        if (-e $filename) {
            # TODO - copy file to file.TIMESTAMP and create new
            warn "$filename already exists";
            return;
        }

        # create a filehandle to write to
        my $fh = IO::File->new($filename, 'w');

        # loop through the __DATA__ for this module
        # and print it to the filehandle
        while (my $line = <DATA>) {
            print $fh <DATA>;
        }
        $fh->close;
    }
};

1;

__DATA__
# which site configuration to use if none are specified on the command line
default_site                'default'

# site configurations
<site>
    # default site configuration - simply an example of the format
    <default>
        source_dir          '/path/to/tt_templates'
        includes_dir        '/path/to/tt_includes'
        output_dir          '/var/www/default_site/html'

        template_files      '\.html\z'

        ignore_dirs         'CVS'
        ignore_dirs         '.svn'
        ignore_dirs         'stats'
        ignore_dirs         'tmp'

        ignore_files        '\.swp\z'

        <tags>
            author          'Joe Bloggs'
            email           'joe@localhost'
            copyright       '&copy; 2000-2006 Joe Bloggs. All rights reserved.'
        </tags>

        <rsync>
            hostname        'remote.site'
            path            '/home/joe.bloggs'
        </rsync>

        <ftp>
            hostname        'remote.ftp.site'
            username        'joe.bloggs'
            passive         1
            password        'sekrit'
            path            '/htdocs/'
        </ftp>
    </default>


    # a second site definition - to demonstrate how to define multiple sites
    <my-site>
        source_dir          '/path/to/tt_templates'
        includes_dir        '/path/to/tt_includes'
        output_dir          '/var/www/default_site/html'
        website             'http://my.site.com/'

        plugin_base         MyPrefix::Template::Plugin

        template_files      '\.html\z'

        ignore_dirs:        'CVS'
        ignore_dirs:        '.svn'
        ignore_dirs:        'stats'
        ignore_dirs:        'tmp'

        ignore_files:       '\.swp\z'

        <tags>
            author          'Joe Bloggs'
            email           'joe@localhost'
            copyright       '&copy; 2000-2006 Joe Bloggs. All rights reserved.'
        <tags>

        <rsync>
            hostname        remote.ftp.site
            path            /home/joe.bloggs
        </rsync>
    </my-site>
</site>
