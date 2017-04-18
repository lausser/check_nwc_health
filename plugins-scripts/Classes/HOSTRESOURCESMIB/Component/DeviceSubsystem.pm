package Classes::HOSTRESOURCESMIB::Component::DeviceSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['devices', 'hrDeviceTable', 'Classes::HOSTRESOURCESMIB::Component::DeviceSubsystem::Device'],
  ]);
}

package Classes::HOSTRESOURCESMIB::Component::DeviceSubsystem::Device;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  if ($self->{hrDeviceDescr} =~ /Guessing/ && ! $self->{hrDeviceStatus}) {
    # found on an F5: Guessing that there's a floating point co-processor.
    # if you guess there's a device, then i guess it's running.
    $self->{hrDeviceStatus} = 'running';
  }
}

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s (%s) has status %s',
      $self->{hrDeviceType}, $self->{hrDeviceDescr},
      $self->{hrDeviceStatus}
  );
  if ($self->{hrDeviceStatus} =~ /(warning|testing)/) {
    $self->add_warning();
  } elsif ($self->{hrDeviceStatus} =~ /down/ && $self->{hrDeviceDescr} ne 'sysfs') {
    $self->add_critical();
  } elsif ($self->{hrDeviceStatus} =~ /unknown/) {
    $self->add_unknown();
  } else {
    $self->add_ok();
  }
}

