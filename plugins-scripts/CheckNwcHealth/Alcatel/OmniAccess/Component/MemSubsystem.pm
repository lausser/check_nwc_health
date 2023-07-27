package CheckNwcHealth::Alcatel::OmniAccess::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('WLSX-SYSTEMEXT-MIB', [
      ['memories', 'wlsxSysExtMemoryTable', 'CheckNwcHealth::Alcatel::OmniAccess::Component::MemSubsystem::Memory'],
  ]);
}


package CheckNwcHealth::Alcatel::OmniAccess::Component::MemSubsystem::Memory;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{usage} = 100 * $self->{sysExtMemoryUsed} / $self->{sysExtMemorySize};
}

sub check {
  my ($self) = @_;
  my $label = sprintf 'memory_%s_usage', $self->{flat_indices};
  $self->add_info(sprintf 'memory %s usage is %.2f%%',
      $self->{flat_indices}, $self->{usage});
  $self->set_thresholds(metric => $label, warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(
      metric => $label, value => $self->{usage}));
  $self->add_perfdata(
      label => $label,
      value => $self->{usage},
      uom => '%',
  );
}

