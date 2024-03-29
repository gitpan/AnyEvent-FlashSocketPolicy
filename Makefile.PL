use inc::Module::Install;
name 'AnyEvent-FlashSocketPolicy';
all_from 'lib/AnyEvent/FlashSocketPolicy.pm';
readme_from 'lib/AnyEvent/FlashSocketPolicy.pm';
readme_markdown_from 'lib/AnyEvent/FlashSocketPolicy.pm';
readme_pod_from 'lib/AnyEvent/FlashSocketPolicy.pm';
githubmeta;

requires 'Any::Moose';
requires 'AnyEvent';
requires 'AnyEvent::Handle';
requires 'AnyEvent::Socket';
requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'Text::MicroTemplate';
requires 'Try::Tiny';

include 'Module::AutoInstall';
install_script 'bin/flash-socket-policy-server';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
build_requires 'Perl6::Slurp';
build_requires 'Test::TCP';
build_requires 'Test::Exception';

auto_set_repository;
auto_include;
WriteAll;
