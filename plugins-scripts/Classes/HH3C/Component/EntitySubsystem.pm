package Classes::HH3C::Component::EntitySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub get_entities {
  my $self = shift;
  my $class = shift;
  my $filter = shift;

  foreach ($self->get_sub_table('ENTITY-MIB', [
    'entPhysicalDescr',
    'entPhysicalName',
    'entPhysicalClass',
  ])) {
    my $new_object = $class->new(%{$_});
    next if (defined $filter && ! &$filter($new_object));
    push @{$self->{entities}}, $new_object;
  }
}

sub get_sub_table {
  my $self = shift;
  my $mib = shift;
  my $names = shift;

  my @oids = map {
    $Monitoring::GLPlugin::SNMP::mibs_and_oids->{$mib}->{$_}
  } @$names;

  my $result = $self->get_entries(
    -columns => \@oids
  );
  my $indices = ();
  map { if ($_ =~ /\.(\d+)$/) { $indices->{$1} = [ $1 ]; } } keys %$result;
  my @indices = values %$indices;

  my @entries = $self->make_symbolic($mib, $result, \@indices);
  @entries = map { $_->{indices} = shift @indices; $_ } @entries;
  @entries = map { $_->{flat_indices} = join(".", @{$_->{indices}}); $_ } @entries;

  return @entries;
}

sub join_table {
  my $self = shift;
  my $to = shift;
  my $from = shift;

  my $to_i = {};
  foreach (@$to) {
    my $i = $_->{flat_indices};
    $to_i->{$i} = $_;
  }

  foreach my $f (@$from) {
    my $i = $f->{flat_indices};
    if (exists $to_i->{$i}) {
      foreach (keys %$f) {
        next if $_ =~ /indices/;
        $to_i->{$i}->{$_} = $f->{$_};
      }
    }
  }
}
