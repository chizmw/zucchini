package Zucchini::Types;
use strict;
# ABSTRACT: Moo type definitions
use MooX::Types::MooseLike::Base;
use base qw(Exporter);
our @EXPORT_OK = ();
my $defs = [
{ 
  name => 'ZucchiniConfig', 
  test => sub { ref($_[0]) && 'Zucchini::Config' eq ref($_[0]) }, 
  message => sub { "$_[0] is not the type we want!" }
},
{ 
  name => 'NetFTP', 
  test => sub { ref($_[0]) && 'Net::FTP' eq ref($_[0]) }, 
  message => sub { "$_[0] is not the type we want!" }
},
{ 
  name => 'TemplateToolkit', 
  test => sub { ref($_[0]) && 'Template' eq ref($_[0]) }, 
  message => sub { "$_[0] is not the type we want!" }
},
];
MooX::Types::MooseLike::register_types($defs, __PACKAGE__);
# optionally add an 'all' tag so one can:
# use MyApp::Types qw/:all/; # to import all types
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);
