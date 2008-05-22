package Zucchini::TestConfig;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use FindBin;
use File::Temp qw(tempdir);
use Zucchini::Config;

# class data
my %testdir_of      :ATTR( get => 'testdir',        set => 'testdir'        );
my %templatedir_of  :ATTR( get => 'templatedir',    set => 'templatedir'    );
my %includedir_of   :ATTR( get => 'includedir',     set => 'includedir'     );
my %outputdir_of    :ATTR( get => 'outputdir',      set => 'outputdir'      );
my %rsyncpath_of    :ATTR( get => 'rsyncpath',      set => 'rsyncpath'      );
my %config_of       :ATTR( get => 'config',                                 );

use Class::Std;
{
    sub START {
        my ( $self, $obj_ID, $arg_ref ) = @_;
        my ( $zcfg );

        # work out the template dir
        $self->set_templatedir(
              $FindBin::Bin
            . q{/testdata/templates}
        );
        # work out the include dir
        $self->set_includedir(
              $FindBin::Bin
            . q{/testdata/includes}
        );

        # set a temporary directory for templating output
        $self->set_outputdir(
            tempdir( CLEANUP => 1 )
        );

        # set a temporary directory for templating output
        $self->set_rsyncpath(
            tempdir( CLEANUP => 1 )
        );

        # create a new config object
        $zcfg = Zucchini::Config->new(
            {
                config_data => $self->site_config,
            }
        );
        $config_of{$obj_ID} = $zcfg;

        return;
    }

    sub site_config {
        my $self = shift;

        my $test_config = {
            default_site => 'testdata',
            site => {
                'testdata' => {
                    ignore_dirs     => ["CVS", ".svn", "tmp"],
                    ignore_files    => "\\.swp\\z",
                    includes_dir    => "XXWILLBEOVERRIDDENXX",
                    output_dir => "XXWILLBEOVERRIDDENXX",
                    source_dir      => "XXWILLBEOVERRIDDENXX",
                    template_files  => "\\.html\\z",
                    website         => "http://www.chizography.net/",

                    ftp => {
                        hostname  => "localhost",
                        passive   => 1,
                        password  => "sekrit",
                        path      => "/somewhere/",
                        username  => "ftpuser",
                    },
                    __ftp_ignore_dirs => [
                        "CVS",
                        ".svn",
                        "tmp",
                    ],

                    rsync => {
                        hostname    => "localhost",
                        path        => "XXWILLBEOVERRIDDENXX",
                    },

                    tags => {
                        author      => "Chisel Wright",
                        copyright   => "&copy; 2006-2008 Chisel Wright. All rights reserved.",
                        email       => "c&#104;isel&#64;chizography.net",
                    },
                },
                'second_site' => {
                    source_dir      => 'XXWILLBEOVERRIDDENXX',
                    includes_dir    => 'XXWILLBEOVERRIDDENXX',
                    output_dir      => 'XXWILLBEOVERRIDDENXX',
                    template_files  => "\\.html\\z",
                    ignore_dirs     => ["CVS", ".svn", "tmp"],
                    ignore_files    => "\\.swp\\z",
                    tags => {
                        author      => "Chisel Wright",
                        copyright   => "&copy; 2006-2008 Chisel Wright. All rights reserved.",
                        email       => "c&#104;isel&#64;chizography.net",
                    },
                },
            },
        };

        # override some values (because they're dynamic in some way)
        foreach my $site (keys %{ $test_config->{site} }) {
            my $site_data = $test_config->{site}{$site};
            $site_data->{includes_dir}    = $self->get_includedir;
            $site_data->{source_dir}      = $self->get_templatedir;
            $site_data->{output_dir}      = $self->get_outputdir;
            $site_data->{rsync}{path}     = $self->get_rsyncpath;
        }

        return $test_config;
    }
};

1;

__END__
