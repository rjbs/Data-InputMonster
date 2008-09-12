use strict;
use warnings;

use Test::More tests => 4;
use Data::InputMonster::Util qw(dig);

{
  my $input  = [ { }, { }, { foo => [ { bar => 13, baz => undef } ] } ];
  my $source = dig( [ qw( 2 foo 0 bar ) ] );

  is(
    $source->(undef, $input),
    13,
    "we can dig down a path correctly",
  );

  is(
    dig( [ 'foo' ] )->(undef, $input),
    undef,
    "trying to use a non-integer on an array gets us undef",
  );

  is(
    dig( [ qw(2 foo 19) ] )->(undef, $input),
    undef,
    "walking off the end of an array gets us undef",
  );

  is(
    dig( [ qw(2 foo 0 bar nothing) ] )->(undef, $input),
    undef,
    "subscripting a non-ref gets us undef",
  );
}

