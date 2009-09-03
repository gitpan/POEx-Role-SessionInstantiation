
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'POEx-Role-SessionInstantiation',
  NAME      => 'POEx::Role::SessionInstantiation',
  AUTHOR    => 'Nicholas\ Perez\ \<nperez\@cpan\.org\>',
  ABSTRACT  => 'Moose\ Role\ for\ turning\ ordinary\ objects\ into\ POE\ sessions',
  VERSION   => '0.092460',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'gpl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0.92',
    "MooseX::Declare" => '0.29',
    "POEx::Types" => '0.092460',
  },
);
