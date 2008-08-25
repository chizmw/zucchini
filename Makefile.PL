# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Zucchini';
version         '0.0.11';
author          'Chisel Wright<chiselwright@users.berlios.de>';
license         'perl';
abstract        'turn templates into static websites';


# Specific dependencies
requires(
    'Carp'                          => 0, # core with perl5
    'Config::Any'                   => '0.09',
    'Digest::MD5'                   => '2.36',
    'File::Basename'                => 0, # core with perl5
    'File::Copy'                    => '2.09',
    'File::Find'                    => 0, # core with perl5
    'File::Rsync'                   => '0.42',
    'File::Slurp'                   => '9999.12',
    'File::stat'                    => '1.00',
    'File::Temp'                    => 0, # core since 5.006001
    'HTML::Lint'                    => '2.02',
    'IO::File'                      => 0, # core since 5.00307
    'Moose'                         => '0.55',
    'Net::FTP'                      => '2.77',
    'Path::Class'                   => '0.16',
    'Template'                      => '2.19',
    'version'                       => 0, # core since 5.009
);

# dependencies for building/testing
build_requires(
    'File::Find'                    => 0, # core with perl5
    'File::Temp'                    => '0.18',
    'Test::File::Contents'          => '0.05',
    'Test::More'                    => '0.72',
    'Test::NoWarnings'              => '0.083',
);

# recommended modules for the script to "be the best"
# XXX does this actually do anything without auto_install?
recommends (
    'Config::General'               => '2.37',
);

no_index    'directory' => 'legacy';

install_script 'script/zucchini';
#auto_install;
WriteAll;
