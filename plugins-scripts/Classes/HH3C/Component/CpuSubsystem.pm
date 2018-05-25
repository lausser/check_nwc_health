package Classes::HH3C::Component::CpuSubsystem;
our @ISA = qw(Classes::HH3C::Component::EntitySubsystem);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables("ENTITY-MIB", [
    ["entities", "entPhysicalTable", "Classes::HH3C::Component::CpuSubsystem::Entity", sub { my ($o) = @_; $o->{entPhysicalClass} eq 'module' and $o->{entPhysicalName} =~ /board/i; }, ["entPhysicalDescr", "entPhysicalName", "entPhysicalClass"]]
  ]);
  $self->get_snmp_tables("HH3C-ENTITY-EXT-MIB", [
    ["entitystates", "hh3cEntityExtStateTable", "Classes::HH3C::Component::CpuSubsystem::EntityState", undef, ["hh3cEntityExtCpuAvgUsage"]]
  ]);
  $self->merge_tables("entities", "entitystates");
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpus');
  if (scalar (@{$self->{entities}}) == 0) {
    $self->add_unknown('no board found');
  } else {
    my $i = 0;
    foreach (@{$self->{entities}}) {
      $_->check($i++);
    }
  }
}

package Classes::HH3C::Component::CpuSubsystem::EntityState;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package Classes::HH3C::Component::CpuSubsystem::Entity;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self, $id) = @_;
  $self->add_info(sprintf 'CPU %s usage is %s%%',
      $id,
      $self->{hh3cEntityExtCpuAvgUsage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{hh3cEntityExtCpuAvgUsage}));
  $self->add_perfdata(
      label => 'cpu_'.$id.'_usage',
      value => $self->{hh3cEntityExtCpuAvgUsage},
      uom => '%',
  );
}
