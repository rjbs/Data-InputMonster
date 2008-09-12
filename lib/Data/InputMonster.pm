use strict;
use warnings;
package Data::InputMonster;

use Carp ();

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

  return 1;
}

sub consume {
  my ($self, $input) = @_;

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

    my $default = $spec->{default};
    $output{ $field_name } = ref $default ? $default->() : $default;
  }

  return \%output;
}

1;
