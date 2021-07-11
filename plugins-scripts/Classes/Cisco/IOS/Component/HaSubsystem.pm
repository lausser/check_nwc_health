package Classes::Cisco::IOS::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::role/) {
    $self->get_snmp_tables("CISCO-FIREWALL-MIB", [
      ['resources', 'cfwHardwareStatusTable', 'Classes::Cisco::IOS::Component::HaSubsystem::Resource'],
    ]);
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'active'); # active/standby
    }
  }
}


package Classes::Cisco::IOS::Component::HaSubsystem::Resource;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub finish {
  my ($self) = @_;
  ($self->{cfwHardwareInformationShort} = $self->{cfwHardwareInformation}) =~ s/\s*\(this device\).*//g;
  if ($self->{cfwHardwareInformation} =~ /Failover LAN Interface/) {
    bless $self, "Classes::Cisco::IOS::Component::HaSubsystem::Resource::LAN";
  } elsif ($self->{cfwHardwareInformation} =~ /Primary/) {
    bless $self, "Classes::Cisco::IOS::Component::HaSubsystem::Resource::Primary";
  } elsif ($self->{cfwHardwareInformation} =~ /Secondary/) {
    bless $self, "Classes::Cisco::IOS::Component::HaSubsystem::Resource::Secondary";
  }
}

package Classes::Cisco::IOS::Component::HaSubsystem::Resource::Primary;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my @roles = split ',', $self->opts->role(); # active,standby for checking the cluster status
  $self->add_info(sprintf "resource %s has status %s (%s)", 
      $self->{cfwHardwareInformationShort},
      $self->{cfwHardwareStatusValue},
      $self->{cfwHardwareStatusDetail});
  if ($self->{cfwHardwareStatusDetail} eq "Failover Off") {
    $self->add_ok();
  } elsif ($self->{cfwHardwareInformation} =~ /this device/) {
    if (grep { "active" eq $_ } @roles) {
      $self->add_ok();
    } else {
      $self->add_critical_mitigation("this device should be ".$self->opts->role());
    }
  } else {
    # as seen from Secondary. check the cluster status, not the role
    if ($self->{cfwHardwareStatusValue} eq "error") {
      $self->add_critical_mitigation("Primary has failed");
    } elsif ($self->{cfwHardwareStatusValue} ne "active") {
      $self->add_warning_mitigation("Primary is not the active node");
    } else {
      $self->add_ok("Primary is active");
    }
  }
}

package Classes::Cisco::IOS::Component::HaSubsystem::Resource::Secondary;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my @roles = split ',', $self->opts->role(); # active,standby for checking the cluster status
  $self->add_info(sprintf "resource %s has status %s (%s)", 
      $self->{cfwHardwareInformationShort},
      $self->{cfwHardwareStatusValue},
      $self->{cfwHardwareStatusDetail});
  if ($self->{cfwHardwareStatusDetail} eq "Failover Off") {
    $self->add_ok();
  } elsif ($self->{cfwHardwareInformation} =~ /this device/) {
    if (grep { "standby" eq $_ } @roles) {
      $self->add_ok();
    } else {
      $self->add_critical();
      $self->add_info("this device should be ".$self->opts->role());
      $self->add_critical();
    }
  } else {
    # as seen from primary
    if ($self->{cfwHardwareStatusValue} eq "error") {
      $self->add_critical_mitigation("Secondary has failed");
    } elsif ($self->{cfwHardwareStatusValue} ne "standby") {
      $self->add_warning_mitigation("Secondary is not the standby node");
    } else {
      $self->add_ok("Secondary is standby");
    }
  }
}

package Classes::Cisco::IOS::Component::HaSubsystem::Resource::LAN;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "resource %s has status %s (%s)", 
      $self->{cfwHardwareInformationShort},
      $self->{cfwHardwareStatusValue},
      $self->{cfwHardwareStatusDetail});
  if ($self->{cfwHardwareStatusDetail} eq "Failover Off") {
    $self->add_ok();
#  } elsif ($self->{cfwHardwareStatusDetail} =~ /FAILOVER/) {
#    kommt verdaechtig oft vor und schaut so aus, als waere das normal
#    $self->add_warning_mitigation("cluster has switched");
  } elsif ($self->{cfwHardwareStatusValue} eq "error") {
    $self->add_warning_mitigation("cluster has lost redundancy");
  } elsif ($self->{cfwHardwareStatusValue} ne "up") {
    $self->add_warning_mitigation("LAN interface has a problem");
  }
}


__END__

>> Primary active unit:

        index     cfwHardwareInformation cfwHardwareStatusValue  cfwHardwareStatusDetail
 netInterface     Failover LAN Interface                     up failover Management0/0.1
  primaryUnit Primary unit (this device)                 active              Active unit
secondaryUnit             Secondary unit                standby             Standby unit

>> Secondary standby unit:

        index       cfwHardwareInformation cfwHardwareStatusValue  cfwHardwareStatusDetail
 netInterface       Failover LAN Interface                     up failover Management0/0.1
  primaryUnit                 Primary unit                 active              Active unit
secondaryUnit Secondary unit (this device)                standby             Standby unit

>> Unconfigured: 

        index       cfwHardwareInformation cfwHardwareStatusValue cfwHardwareStatusDetail
 netInterface       Failover LAN Interface                   down          not Configured
  primaryUnit                 Primary unit                   down            Failover Off
secondaryUnit Secondary unit (this device)                   down            Failover Off

>> Primary active unit when secondary has failed:

        index     cfwHardwareInformation cfwHardwareStatusValue     cfwHardwareStatusDetail
 netInterface     Failover LAN Interface                  error FAILOVER GigabitEthernet0/5
  primaryUnit Primary unit (this device)                 active                 Active unit
secondaryUnit             Secondary unit                  error             Unit has failed

>> Primary when failed over to Secondary

        index     cfwHardwareInformation cfwHardwareStatusValue     cfwHardwareStatusDetail
 netInterface     Failover LAN Interface                  error FAILOVER GigabitEthernet0/5
  primaryUnit Primary unit (this device)                standby                Standby unit
secondaryUnit             Secondary unit                 active                 Active unit

>> Secondary when failed over to Secondary

        index     cfwHardwareInformation   cfwHardwareStatusValue     cfwHardwareStatusDetail
 netInterface       Failover LAN Interface                  error FAILOVER GigabitEthernet0/5
  primaryUnit                 Primary unit                standby                Standby unit
secondaryUnit Secondary unit (this device)                 active                 Active unit

