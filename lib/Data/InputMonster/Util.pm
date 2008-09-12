use strict;
use warnings;
package Data::InputMonster::Util;
# ABSTRACT: handy routines for use with the input monster
use Sub::Exporter::Util qw(curry_method);

use Sub::Exporter -setup => {
  exports => {
    dig => curry_method,
  },
};

=head1 DESCRIPTION

These methods, which provide some helpers for use with InputMonster, can be
exported as routines upon request.

=cut

=method dig

  my $source = dig( [ $key1, $key2, $key2 ]);
  my $source = dig( sub { ... } );

A C<dig> source looks through the input using the given locator.  If it's a
coderef, the code is called and passed the input.  If it's an arrayref, each
entry is used, in turn, to subscript the input as a deep data structure.

For example, given:

  $input  = [ { ... }, { ... }, { foo => [ { bar => 13, baz => undef } ] } ];
  $source = dig( [ qw( 2 foo 0 bar ) ] );

The source would find 13.

=cut

sub dig {
  my ($self, $locator) = @_;
  
  Carp::confess("locator must be either a code or array reference")
    unless ref $locator;

  if (ref $locator eq 'CODE') {
    return sub { $locator->($_[1]) };
  } elsif (ref $locator eq 'ARRAY') {
    return sub {
      my ($monster, $input) = @_;
      my $next = $input;

      for my $k (@$locator) {
        return unless my $ref = ref $next;
        return unless $ref and (($ref eq 'ARRAY') or ($ref eq 'HASH'));

        return if $ref eq 'ARRAY' and $k !~ /\A-?\d+\z/;
        $next = $next->[ $k ] if $ref eq 'ARRAY';
        $next = $next->{ $k } if $ref eq 'HASH';
      }

      return $next;
    };
  }

  Carp::confess("locator must be either a code or array reference");
}

'hi, domm!';
