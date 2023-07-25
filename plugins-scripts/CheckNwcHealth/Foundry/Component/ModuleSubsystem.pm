package CheckNwcHealth::Foundry::Component::ModuleSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('FOUNDRY-SN-AGENT-MIB', [
      ['boards', 'snAgentBrdTable', 'CheckNwcHealth::Foundry::Component::ModuleSubsystem::Module', undef, ['snAgentBrdMainBrdDescription', 'snAgentBrdMainBrdId', 'snAgentBrdExpBrdDescription', 'snAgentBrdModuleStatus', 'snAgentBrdRedundantStatus']],
  ]);
}


package CheckNwcHealth::Foundry::Component::ModuleSubsystem::Module;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'module %s status is %s, redundancy status is %s', 
      $self->{snAgentBrdMainBrdDescription},
      $self->{snAgentBrdModuleStatus},
      $self->{snAgentBrdRedundantStatus});
  if ($self->{snAgentBrdRedundantStatus} eq 'crashed' ||
      $self->{snAgentBrdModuleStatus} eq 'moduleRejected') {
    $self->add_warning();
  } elsif ($self->{snAgentBrdModuleStatus} eq 'moduleBad') {
    $self->add_critical();
  }
}

