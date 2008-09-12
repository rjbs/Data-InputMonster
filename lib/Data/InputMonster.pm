use strict;
use warnings;
package Data::InputMonster;
# ABSTRACT: consume data from multiple sources, best first; om nom nom!

=head1 DESCRIPTION

This module lets you describe a bunch of input fields you expect.  For each
field, you can specify validation, a default, and multiple places to look for a
value.  The first valid value found is accepted and returned in the results.

=cut

use Carp ();

=method new

  my $monster = Data::InputMonster->new({
    fields => {
      field_name => \%field_spec,
      ...
    },
  });

This builds a new monster.  For more information on the C<%field_spec>
parameters, see below.

=cut

sub new {
  my ($class, $arg) = @_;
  
  Carp::confess("illegal parameters to Data::InputMonster constructor")
    unless $arg and (keys %$arg == 1) and exists $arg->{fields};

  my $fields = $arg->{fields};

  $class->_assert_field_spec_ok($_) for values %$fields;

  bless { fields => $fields } => $class;
}

sub _assert_field_spec_ok {
  my ($self, $spec) = @_;

  Carp::confess("illegal or missing sources")
    unless $spec->{sources} and ref $spec->{sources} eq 'ARRAY';

  Carp::confess("if given, filter must be a coderef")
    if $spec->{filter} and ref $spec->{filter} ne 'CODE';

  Carp::confess("if given, check must be a coderef")
    if $spec->{check} and ref $spec->{check} ne 'CODE';

  Carp::confess("if given, store must be a coderef")
    if $spec->{store} and ref $spec->{store} ne 'CODE';

  Carp::confess("defaults that are references must be wrapped in code")
    if ((ref $spec->{default})||'CODE') ne 'CODE';
}

=method consume

  my $result = $monster->consume($input, \%arg);

This method processes the given input and returns a hashref of the finally
accepted values.  C<$input> can be anything; it is up to the field definitions
to expect and handle the data you plan to feed the monster.

Valid arguments are:

  no_default_for - a field name or arrayref of field names for which to NOT
                   fall back to default values

=cut

sub consume {
  my ($self, $input, $arg) = @_;
  $arg ||= {};

  my %no_default_for
    = (! $arg->{no_default_for})   ? ()
    : (ref $arg->{no_default_for}) ? (map {$_=>1} @{$arg->{no_default_for}})
    : ($arg->{no_default_for} => 1);

  my $field  = $self->{fields};
  my %output;

  FIELD: for my $field_name (keys %$field) {
    my $spec = $field->{$field_name};

    my $checker = $spec->{check};
    my $filter  = $spec->{filter};
    my $storer  = $spec->{store};

    my @sources = @{ $spec->{sources} };

    if (ref $sources[0]) {
      my $i = 1;
      @sources = map { ("source_" . $i++) => $_ } @sources;
    }

    SOURCE: for (my $i = 0; $i < @sources; $i += 2) {
      my ($name, $getter) = @sources[ $i, $i + 1 ];
      my $value = $getter->($self, $input);
      next unless defined $value;
      if ($filter)  { $filter->()  for $value; }
      if ($checker) { $checker->() or next SOURCE for $value; }
      
      $output{ $field_name } = $value;
      if ($storer) {
        $storer->($self, { source => $name, value => $value });
      }

      next FIELD;
    }

    my $default = $no_default_for{ $field_name } ? undef : $spec->{default};
    $output{ $field_name } = ref $default ? $default->() : $default;
  }

  return \%output;
}

=head1 FIELD DEFINITIONS

Each field is defined by a hashref with the following entries:

  sources - an arrayref of sources; see below; required
  filter  - a coderef to preprocess candidate values
  check   - a coderef to validate candidate values
  store   - a coderef to store accepted values
  default - a value to use if no source provides an acceptable value

Sources may be given in one of two formats:

  [ source_name => $source, ... ]
  [ $source_1, $source_2, ... ]

In the second form, sources will be assigned unique names.

The source value is a coderef which, handed the C<$input> argument to the
C<consume> method, returns a candidate value (or undef).

A filter is a coderef that works by altering C<$_>.

If given, check must be a coderef that inspects C<$_> and returns a true if the
value is acceptable.

Store is called if a value is accepted.  It is passed the monster and a hashref
with the following entries:

  value  - the value accepted
  source - the name of the source from which the value was accepted

If default is given, it must be a simple scalar (in which case that is the
default) or a coderef that will be called to provide a default value as needed.

=cut

"OM NOM NOM I EAT DATA";
