package Classes::Cisco;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  my $sysobjectid = $self->get_snmp_object('MIB-2-MIB', 'sysObjectID', 0);
  $sysobjectid =~ s/^\.//g;
  if ($self->{productname} =~ /Cisco NX-OS/i) {
    $self->rebless('Classes::Cisco::NXOS');
  } elsif ($self->{productname} =~ /Cisco Controller/i ||
      $self->implements_mib('AIRESPACE-SWITCHING-MIB')) {
    # die AIRESPACE-WIRELESS-MIB haben manchmal auch stinknormale Switche,
    # das hat also nichts zu sagen. SWITCHING ist entscheidend.
    $self->rebless('Classes::Cisco::WLC');
  } elsif ($self->{productname} =~ /Cisco.*(IronPort|AsyncOS)/i) {
    $self->rebless('Classes::Cisco::AsyncOS');
  } elsif ($self->{productname} =~ /Cisco.*Prime Network Control System/i) {
    $self->rebless('Classes::Cisco::PrimeNCS');
  } elsif ($self->{productname} =~ /UCOS /i) {
    $self->rebless('Classes::Cisco::UCOS');
  } elsif ($self->{productname} =~ /Cisco (PIX|Adaptive) Security Appliance/i) {
    $self->rebless('Classes::Cisco::ASA');
  } elsif ($self->{productname} =~ /Cisco/i) {
    $self->rebless('Classes::Cisco::IOS');
  } elsif ($self->{productname} =~ /Fujitsu Intelligent Blade Panel 30\/12/i) {
    $self->rebless('Classes::Cisco::IOS');
  } elsif ($sysobjectid eq '1.3.6.1.4.1.9.1.1348') {
    $self->rebless('Classes::Cisco::CCM');
  } elsif ($sysobjectid eq '1.3.6.1.4.1.9.1.746') {
    $self->rebless('Classes::Cisco::CCM');
  } elsif ($sysobjectid =~ /1.3.6.1.4.1.9.6.1.83/) {
    $self->rebless('Classes::Cisco::SB');
  }
  if (ref($self) ne "Classes::Cisco") {
    if ($self->mode =~ /device::bgp/) {
      if ($self->implements_mib('CISCO-BGP4-MIB', 'cbgpPeer2Table')) {
        $self->analyze_and_check_interface_subsystem("Classes::Cisco::CISCOBGP4MIB::Component::PeerSubsystem");
      } else {
        $self->establish_snmp_secondary_session();
        if ($self->implements_mib('CISCO-BGP4-MIB', 'cbgpPeer2Table')) {
          $self->analyze_and_check_interface_subsystem("Classes::Cisco::CISCOBGP4MIB::Component::PeerSubsystem");
        } else {
          $self->establish_snmp_session();
          $self->debug("no CISCO-BGP4-MIB and/or no cbgpPeer2Table, fallback");
          $self->no_such_mode();
        }
      }
    } elsif ($self->mode =~ /device::eigrp/) {
      if ($self->implements_mib('CISCO-EIGRP-MIB')) {
        $self->analyze_and_check_interface_subsystem("Classes::Cisco::EIGRPMIB::Component::PeerSubsystem");
      } else {
        $self->no_such_mode();
      }
    } elsif ($self->mode =~ /device::interfaces::etherstats/) {
      if ($self->implements_mib('OLD-CISCO-INTERFACES-MIB')) {
        $self->analyze_and_check_interface_subsystem("Classes::Cisco::OLDCISCOINTERFACESMIB::Component::InterfaceSubsystem");
      } else {
        $self->no_such_mode();
      }
    } elsif ($self->mode =~ /device::interfaces::portsecurity/) {
      if ($self->implements_mib('CISCO-PORT-SECURITY-MIB')) {
        $self->analyze_and_check_interface_subsystem("Classes::Cisco::CISCOPORTSECURITYMIB::Component::InterfaceSubsystem");
      } else {
        $self->no_such_mode();
      }
    } elsif ($self->mode =~ /device::licenses::/) {
      if ($self->implements_mib('CISCO-SMART-LIC-MIB')) {
        $self->analyze_and_check_lic_subsystem("Classes::Cisco::CISCOSMARTLICMIB::Component::KeySubsystem");
      } elsif ($self->implements_mib('CISCO-LICENSE-MGMT-MIB')) {
        $self->analyze_and_check_lic_subsystem("Classes::Cisco::CISCOLICENSEMGMTMIB::Component::KeySubsystem");
      } else {
        $self->no_such_mode();
      }
    } else {
      $self->init();
      if ($self->mode =~ /device::interfaces::ifstack::status/ &&
          $self->{productname} =~ /IOS.*((12.0\(25\)SX3)|(12.0S)|(12.1E)|(12.2)|(12.2S)|(12.3))/) {
        # known bug in this ios release. CSCed67708
        my ($code, $msg) = $self->check_messages(join => ', ', join_all => ', ');
        if ($code == 1 && $msg =~ /^(([^,]+? has stack status active but no sub-layer interfaces(, )*)+)$/) {
          $self->override_opt('negate', {'warning' => 'ok'});
        }
      }
    }
  } else {
    $self->no_such_mode();
  }
}

