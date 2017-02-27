package Classes::F5::F5BIGIP::Component::GTMSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->mult_snmp_max_msg_size(10);
  $self->get_snmp_tables('F5-BIGIP-GLOBAL-MIB', [
      ['wideips', 'gtmWideipStatusTable', 'Classes::F5::F5BIGIP::Component::GTMSubsystem::WideIP'],
  ]);
}

sub check {
  my $self = shift;
  $self->SUPER::check();
  if (scalar(@{$self->{wideips}}) == 0) {
    $self->add_unknown('no wide IPs found');
  } else {
    $self->reduce_messages_short(sprintf '%d wide IPs working fine',
        scalar(@{$self->{wideips}})
    );
  }
}

package Classes::F5::F5BIGIP::Component::GTMSubsystem::WideIP;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'wide IP %s has status %s, is %s',
      $self->{gtmWideipStatusName},
      $self->{gtmWideipStatusAvailState},
      $self->{gtmWideipStatusEnabledState});
  if ($self->{gtmWideipStatusEnabledState} =~ /^disabled/) {
    $self->add_ok();
  } elsif ($self->{gtmWideipStatusAvailState} eq 'green') {
    $self->add_ok();
  } elsif ($self->{gtmWideipStatusAvailState} eq 'blue') {
    $self->add_unknown();
  } else {
    $self->add_critical();
  }
}

