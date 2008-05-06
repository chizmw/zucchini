# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Zucchini';
version         '0.0.1';
author          'Chisel Wright<chiselwright@users.berlios.de>';
all_from        'lib/Zucchini.pm';

# Specific dependencies
requires(
    'Carp'                          => 0, # core with perl5
    'Class::Std'                    => '0.0.8',
    'Config::Any'                   => '0.08',
    'Digest::MD5'                   => '2.36',
    'File::Copy'                    => '2.09',
    'File::stat'                    => '1.00',
    'IO::File'                      => 0, # core since 5.00307
    'Template'                      => '2.19',
);

# dependencies for building/testing
build_requires(
    'Test::More'                    => '0.72',
);

# recommended modules for the script to "be the best"
# XXX does this actually do anything?
recommends (
    'Config::General'               => '2.37',
);


install_script 'script/zucchini';
#auto_install;
WriteAll;
