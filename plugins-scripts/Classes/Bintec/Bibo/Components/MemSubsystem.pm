package Classes::Bintec::Bibo::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('BIANCA-BRICK-MIBRES-MIB', [
      ['mem', 'memoryTable', 'Classes::Bintec::Bibo::Component::MemSubsystem::Memory'],
  ]);
}


package Classes::Bintec::Bibo::Component::MemSubsystem::Memory;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish  {
  my $self = shift;
  $self->{usage} = $self->{memoryInuse} /
      $self->{memoryTotal} * 100;
  bless $self, "Classes::Bintec::Bibo::Component::MemSubsystem::Memory::Flash"
      if $self->{memoryType} eq "flash";
  bless $self, "Classes::Bintec::Bibo::Component::MemSubsystem::Memory::Dram"
      if $self->{memoryType} eq "dram";
  bless $self, "Classes::Bintec::Bibo::Component::MemSubsystem::Memory::Dpool"
      if $self->{memoryType} eq "dpool";
}


package Classes::Bintec::Bibo::Component::MemSubsystem::Memory::Flash;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->{memoryDescr} = $self->unhex_octet_string($self->{memoryDescr});
  $self->add_info(sprintf '%s usage is %.2f%%',
      $self->{memoryDescr}, $self->{usage});
  my $label = 'memory_'.$self->{memoryDescr}.'_usage';
  $self->set_thresholds(metric => $label, warning => 90, critical => 95);
  $self->add_message($self->check_thresholds(metric => $label, value => $self->{usage}));
  $self->add_perfdata(
      label => $label,
      value => $self->{usage},
      uom => '%',
  );
}


package Classes::Bintec::Bibo::Component::MemSubsystem::Memory::Dram;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->{memoryDescr} = $self->unhex_octet_string($self->{memoryDescr});
  $self->add_info(sprintf '%s usage is %.2f%%',
      $self->{memoryDescr}, $self->{usage});
  my $label = 'memory_'.$self->{memoryDescr}.'_usage';
  $self->set_thresholds(metric => $label, warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(metric => $label, value => $self->{usage}));
  $self->add_perfdata(
      label => $label,
      value => $self->{usage},
      uom => '%',
  );
}

package Classes::Bintec::Bibo::Component::MemSubsystem::Memory::Dpool;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s usage is %.2f%%',
      $self->{memoryDescr}, $self->{usage});
  my $label = 'memory_'.$self->{memoryDescr}.'_usage';
  $self->add_perfdata(
      label => $label,
      value => $self->{usage},
      uom => '%',
  );
}


