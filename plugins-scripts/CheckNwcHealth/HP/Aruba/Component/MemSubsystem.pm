package CheckNwcHealth::HP::Aruba::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('ARUBAWIRED-VSF-MIB', [
      ['members', 'arubaWiredVsfMemberTable', 'CheckNwcHealth::HP::Aruba::Component::MemSubsystem::Member'],
  ]);
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  if (scalar (@{$self->{members}}) == 0) {
  } else {
    foreach (@{$self->{members}}) {
      $_->check();
    }
  }
}


package CheckNwcHealth::HP::Aruba::Component::MemSubsystem::Member;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->{usage} = $self->{arubaWiredVsfMemberCurrentUsage} / 
      $self->{arubaWiredVsfMemberTotalMemory} * 100;
  $self->add_info(sprintf 'member %s memory usage is %.2f',
      $self->{arubaWiredVsfMemberIndex}, $self->{usage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{usage}));
  $self->add_perfdata(
      label => 'memory_'.$self->{arubaWiredVsfMemberIndex}.'_usage',
      value => $self->{usage},
      uom => '%',
  );
}

