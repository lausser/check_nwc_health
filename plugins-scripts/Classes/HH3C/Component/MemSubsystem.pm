package Classes::HH3C::Component::MemSubsystem;
our @ISA = qw(Classes::HH3C::Component::EntitySubsystem);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables("ENTITY-MIB", [
    ["entities", "entPhysicalTable", "Classes::HH3C::Component::MemSubsystem::Entity", sub { my ($o) = @_; $o->{entPhysicalClass} eq 'module' and $o->{entPhysicalName} =~ /board/i; }, ["entPhysicalDescr", "entPhysicalName", "entPhysicalClass"]]
  ]);
  $self->get_snmp_tables("HH3C-ENTITY-EXT-MIB", [
    ["entitystates", "hh3cEntityExtStateTable", "Classes::HH3C::Component::MemSubsystem::EntityState", undef, ["hh3cEntityExtMemAvgUsage"]]
  ]);
  $self->merge_tables("entities", "entitystates");
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  if (scalar (@{$self->{entities}}) == 0) {
    $self->add_unknown('no board found');
  } else {
    my $i = 0;
    foreach (@{$self->{entities}}) {
      $_->check($i++);
    }
  }
}

package Classes::HH3C::Component::MemSubsystem::EntityState;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package Classes::HH3C::Component::MemSubsystem::Entity;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self, $id) = @_;
  $self->add_info(sprintf 'Memory %s usage is %s%%',
      $id,
      $self->{hh3cEntityExtMemAvgUsage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{hh3cEntityExtMemAvgUsage}));
  $self->add_perfdata(
      label => 'memory_'.$id.'_usage',
      value => $self->{hh3cEntityExtMemAvgUsage},
      uom => '%',
  );
}
