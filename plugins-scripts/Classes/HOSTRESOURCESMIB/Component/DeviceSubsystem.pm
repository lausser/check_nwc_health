package Classes::HOSTRESOURCESMIB::Component::DeviceSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['devices', 'hrDeviceTable', 'Classes::HOSTRESOURCESMIB::Component::DeviceSubsystem::Device'],
  ]);
}

package Classes::HOSTRESOURCESMIB::Component::DeviceSubsystem::Device;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  my $class = ref($self);
  my $newclass = $class."::".$self->{hrDeviceType};
  {
    no strict 'refs';
    if (! scalar %{$newclass."::"}) {
      *{ ${newclass}."::ISA" } = \@{ ${class}."::ISA" };
      *{ ${newclass}."::check" } = \&{ ${class}."::check" };
      if ($self->{hrDeviceType} eq "hrDeviceNetwork") {
        *{ ${newclass}."::internal_name" } = sub {
          my ($this) = (@_);
          $this->{hrDeviceDescr} =~ /network interface (.*)/;
          if ($1) {
            return (uc $this->{hrDeviceType})."_".$1;
          } else {
            return $this->SUPER::internal_name();
          }
        };
      }
    }
  }
  bless $self, $newclass;
  if ($self->{hrDeviceDescr} =~ /Guessing/ && ! $self->{hrDeviceStatus}) {
    # found on an F5: Guessing that there's a floating point co-processor.
    # if you guess there's a device, then i guess it's running.
    $self->{hrDeviceStatus} = 'running';
  } elsif ($self->{hrDeviceType} eq 'hrDeviceDiskStorage' && ! $self->{hrDeviceStatus}) {
    $self->{hrDeviceStatus} = 'running';
  }
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s (%s) has status %s',
      $self->{hrDeviceType}, $self->{hrDeviceDescr},
      $self->{hrDeviceStatus}
  );
  if ($self->{hrDeviceStatus} =~ /(warning|testing)/) {
    $self->add_warning();
  } elsif ($self->{hrDeviceStatus} =~ /down/ && ! (
      # cd, sd, ramdisk fliegen raus. neuerdings auch nfs, weil die
      # zum umounten zu bloed sind.
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'sysfs' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'sunrpc' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'devtmpfs' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'securityfs' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'cgroup' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'pstore' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'configfs' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'selinuxfs' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'mqueue' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'hugetlbfs' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'systemd-1' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'debugfs' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'binfmt_misc' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'overlay' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'shm' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'rootfs' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} eq 'sysfs' ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} =~ /CDROM/ ||
      $self->{hrDeviceType} eq 'hrDeviceDiskStorage' && $self->{hrDeviceDescr} =~ /:\// ||
      $self->{hrDeviceType} eq 'hrDeviceNetwork' && $self->{hrDeviceDescr} eq 'sit0' ||
      $self->{hrDeviceType} eq 'hrDeviceNetwork' && $self->{hrDeviceDescr} eq 'ip_vti0'
    )) {
    $self->add_critical();
  } elsif ($self->{hrDeviceStatus} =~ /unknown/) {
    $self->add_unknown();
  } else {
    $self->add_ok();
  }
}


