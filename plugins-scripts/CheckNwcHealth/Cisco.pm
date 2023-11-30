package CheckNwcHealth::Cisco;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  my $sysobjectid = $self->get_snmp_object('MIB-2-MIB', 'sysObjectID', 0);
  $sysobjectid =~ s/^\.//g;
  if ($self->{productname} =~ /Cisco NX-OS/i) {
    $self->rebless('CheckNwcHealth::Cisco::NXOS');
  } elsif ($self->{productname} =~ /Cisco Controller/i ||
      $self->{productname} =~ /C9800 / ||
      $self->implements_mib('AIRESPACE-SWITCHING-MIB')) {
    # die AIRESPACE-WIRELESS-MIB haben manchmal auch stinknormale Switche,
    # das hat also nichts zu sagen. SWITCHING ist entscheidend.
    # juli 23, neues Modell C9800, hat kein AIRESPACE-SWITCHING-MIB, aber AIRESPACE-WIRELESS-MIB
    # und die LWAPP-MIB. Wird hier zu WLC erklärt, cpu/mem etc wird aber in der WLC.pm
    # dann wieder auf Cisco::IOS umgedengelt.
    $self->rebless('CheckNwcHealth::Cisco::WLC');
  } elsif ($self->{productname} =~ /Cisco.*(IronPort|AsyncOS)/i) {
    $self->rebless('CheckNwcHealth::Cisco::AsyncOS');
  } elsif ($self->{productname} =~ /Cisco.*Prime Network Control System/i) {
    $self->rebless('CheckNwcHealth::Cisco::PrimeNCS');
  } elsif ($self->{productname} =~ /UCOS /i) {
    $self->rebless('CheckNwcHealth::Cisco::UCOS');
  } elsif ($self->{productname} =~ /Cisco (PIX|Adaptive) Security Appliance/i) {
    $self->rebless('CheckNwcHealth::Cisco::ASA');
  } elsif ($self->implements_mib('VIPTELA-OPER-SYSTEM')) {
    $self->rebless('CheckNwcHealth::Cisco::Viptela');
  } elsif ($self->{productname} =~ /Cisco/i) {
    $self->rebless('CheckNwcHealth::Cisco::IOS');
  } elsif ($self->{productname} =~ /Fujitsu Intelligent Blade Panel 30\/12/i) {
    $self->rebless('CheckNwcHealth::Cisco::IOS');
  } elsif ($sysobjectid eq '1.3.6.1.4.1.9.1.1348') {
    $self->rebless('CheckNwcHealth::Cisco::CCM');
  } elsif ($sysobjectid eq '1.3.6.1.4.1.9.1.746') {
    $self->rebless('CheckNwcHealth::Cisco::CCM');
  } elsif ($sysobjectid =~ /1.3.6.1.4.1.9.6.1.83/) {
    $self->rebless('CheckNwcHealth::Cisco::SB');
  }
  if (ref($self) ne "CheckNwcHealth::Cisco") {
    if ($self->mode =~ /device::bgp/) {
      if ($self->implements_mib('CISCO-BGP4-MIB', 'cbgpPeer2Table')) {
        $self->analyze_and_check_interface_subsystem("CheckNwcHealth::Cisco::CISCOBGP4MIB::Component::PeerSubsystem");
      } else {
        $self->establish_snmp_secondary_session();
        if ($self->implements_mib('CISCO-BGP4-MIB', 'cbgpPeer2Table')) {
          $self->analyze_and_check_interface_subsystem("CheckNwcHealth::Cisco::CISCOBGP4MIB::Component::PeerSubsystem");
        } else {
          $self->establish_snmp_session();
          $self->debug("no CISCO-BGP4-MIB and/or no cbgpPeer2Table, fallback");
          $self->no_such_mode();
        }
      }
    } elsif ($self->mode =~ /device::eigrp/) {
      if ($self->implements_mib('CISCO-EIGRP-MIB')) {
        $self->analyze_and_check_interface_subsystem("CheckNwcHealth::Cisco::EIGRPMIB::Component::PeerSubsystem");
      } else {
        $self->no_such_mode();
      }
    } elsif ($self->mode =~ /device::interfacex::errdisabled/) {
      # if ($self->implements_mib('CISCO-ERR-DISABLE-MIB')) {
      # Ist bloed, aber wenn keine Spur dieser Mib zu finden ist,
      # dann kann das schlichtweg bedeuten, dass kein Interface
      # disabled wurde.
      $self->analyze_and_check_interface_subsystem("CheckNwcHealth::Cisco::CISCOERRDISABLEMIB::Component::InterfaceSubsystem");
    } elsif ($self->mode =~ /device::interfaces::etherstats/) {
      if ($self->implements_mib('OLD-CISCO-INTERFACES-MIB')) {
        $self->analyze_and_check_interface_subsystem("CheckNwcHealth::Cisco::OLDCISCOINTERFACESMIB::Component::InterfaceSubsystem");
      } else {
        $self->no_such_mode();
      }
    } elsif ($self->mode =~ /device::interfaces::portsecurity/) {
      if ($self->implements_mib('CISCO-PORT-SECURITY-MIB')) {
        $self->analyze_and_check_interface_subsystem("CheckNwcHealth::Cisco::CISCOPORTSECURITYMIB::Component::InterfaceSubsystem");
      } else {
        $self->no_such_mode();
      }
    } elsif ($self->mode =~ /device::licenses::/) {
      if ($self->implements_mib('CISCO-SMART-LIC-MIB')) {
        $self->analyze_and_check_lic_subsystem("CheckNwcHealth::Cisco::CISCOSMARTLICMIB::Component::KeySubsystem");
      } elsif ($self->implements_mib('CISCO-LICENSE-MGMT-MIB')) {
        $self->analyze_and_check_lic_subsystem("CheckNwcHealth::Cisco::CISCOLICENSEMGMTMIB::Component::KeySubsystem");
      } else {
        $self->no_such_mode();
      }
    } elsif ($self->mode =~ /device::rtt::check/) {
      if ($self->implements_mib('CISCO-RTTMON-MIB')) {
        $self->analyze_and_check_lic_subsystem("CheckNwcHealth::Cisco::CISCORTTMONMIB::Component::RttSubsystem");
      } else {
        $self->no_such_mode();
      }
    } elsif ($self->mode =~ /device::sdwan::/) {
    #} elsif ($self->mode =~ /device::sdwan::session::availability/) {
      if ($self->implements_mib("CISCO-SDWAN-OPER-SYSTEM-MIB")) {
        $self->analyze_and_check_sdwan_subsystem("CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem");
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

