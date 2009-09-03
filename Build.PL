
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'POEx::Role::SessionInstantiation',
  license       => 'gpl',
  dist_abstract => "Moose\ Role\ for\ turning\ ordinary\ objects\ into\ POE\ sessions",
  dist_name     => "POEx\-Role\-SessionInstantiation",
  dist_author   => [
"Nicholas\ Perez\ \<nperez\@cpan\.org\>",
  ],
  requires      => {
    "Test::More" => '0.92',
    "MooseX::Declare" => '0.29',
    "POEx::Types" => '0.092460',
  },
  script_files => [ qw() ],
);

$build->create_build_script;
