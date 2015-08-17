package Classes::Alcatel::OmniAccess::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('WLSX-SYSTEMEXT-MIB', [
      ['memories', 'wlsxSysExtProcessorTable', 'Classes::Alcatel::OmniAccess::Component::CpuSubsystem::Cpu'],
  ]);
}


package Classes::Alcatel::OmniAccess::Component::CpuSubsystem::Cpu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  my $label = sprintf '%s_usage', lc $self->{sysExtProcessorDescr};
  $label =~ s/\s+/_/g;
  $self->add_info(sprintf '%s usage is %.2f%%',
      $self->{sysExtProcessorDescr}, $self->{sysExtProcessorLoad});
  $self->set_thresholds(metric => $label, warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(
      metric => $label, value => $self->{sysExtProcessorLoad}));
  $self->add_perfdata(
      label => $label,
      value => $self->{sysExtProcessorLoad},
      uom => '%',
  );
}

