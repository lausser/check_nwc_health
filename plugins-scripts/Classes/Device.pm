package Classes::Device;
our @ISA = qw(GLPlugin::SNMP GLPlugin::UPNP);
use strict;

sub classify {
  my $self = shift;
  if (! ($self->opts->hostname || $self->opts->snmpwalk)) {
    $self->add_unknown('either specify a hostname or a snmpwalk file');
  } else {
    if ($self->opts->servertype && $self->opts->servertype eq 'linuxlocal') {
    } elsif ($self->opts->servertype && $self->opts->servertype eq 'windowslocal') {
      eval "use DBD::WMI";
      if ($@) {
        $self->add_unknown("module DBD::WMI is not installed");
      }
    } elsif ($self->opts->port && $self->opts->port == 49000) {
      $self->{productname} = 'upnp';
      $self->check_upnp_and_model();
    } else {
      $self->check_snmp_and_model();
    }
    if ($self->opts->servertype) {
      $self->{productname} = $self->opts->servertype;
      $self->{productname} = 'cisco' if $self->opts->servertype eq 'cisco';
      $self->{productname} = 'huawei' if $self->opts->servertype eq 'huawei';
      $self->{productname} = 'hp' if $self->opts->servertype eq 'hp';
      $self->{productname} = 'brocade' if $self->opts->servertype eq 'brocade';
      $self->{productname} = 'netscreen' if $self->opts->servertype eq 'netscreen';
      $self->{productname} = 'linuxlocal' if $self->opts->servertype eq 'linuxlocal';
      $self->{productname} = 'procurve' if $self->opts->servertype eq 'procurve';
      $self->{productname} = 'bluecoat' if $self->opts->servertype eq 'bluecoat';
      $self->{productname} = 'checkpoint' if $self->opts->servertype eq 'checkpoint';
      $self->{productname} = 'clavister' if $self->opts->servertype eq 'clavister';
      $self->{productname} = 'ifmib' if $self->opts->servertype eq 'ifmib';
    }
    if (! $self->check_messages()) {
      if ($self->opts->verbose && $self->opts->verbose) {
        printf "I am a %s\n", $self->{productname};
      }
      if ($self->opts->mode =~ /^my-/) {
        $self->load_my_extension();
      } elsif ($self->{productname} =~ /upnp/i) {
        bless $self, 'Classes::UPNP';
        $self->debug('using Classes::UPNP');
      } elsif ($self->{productname} =~ /FRITZ/i) {
        bless $self, 'Classes::UPNP::AVM';
        $self->debug('using Classes::UPNP::AVM');
      } elsif ($self->{productname} =~ /linuxlocal/i) {
        bless $self, 'Server::Linux';
        $self->debug('using Server::Linux');
      } elsif ($self->{productname} =~ /windowslocal/i) {
        bless $self, 'Server::Windows';
        $self->debug('using Server::Windows');
      } elsif ($self->{productname} =~ /Cisco/i) {
        bless $self, 'Classes::Cisco';
        $self->debug('using Classes::Cisco');
      } elsif ($self->{productname} =~ /fujitsu intelligent blade panel 30\/12/i) {
        bless $self, 'Classes::Cisco';
        $self->debug('using Classes::Cisco');
      } elsif ($self->{productname} =~ /UCOS /i) {
        bless $self, 'Classes::Cisco';
        $self->debug('using Classes::Cisco');
      } elsif ($self->{productname} =~ /Nortel/i) {
        bless $self, 'Classes::Nortel';
        $self->debug('using Classes::Nortel');
      } elsif ($self->{productname} =~ /AT-GS/i) {
        bless $self, 'Classes::AlliedTelesyn';
        $self->debug('using Classes::AlliedTelesyn');
      } elsif ($self->{productname} =~ /AT-\d+GB/i) {
        bless $self, 'Classes::AlliedTelesyn';
        $self->debug('using Classes::AlliedTelesyn');
      } elsif ($self->{productname} =~ /Allied Telesyn Ethernet Switch/i) {
        bless $self, 'Classes::AlliedTelesyn';
        $self->debug('using Classes::AlliedTelesyn');
      } elsif ($self->{productname} =~ /DS_4100/i) {
        bless $self, 'Classes::Brocade';
        $self->debug('using Classes::Brocade');
      } elsif ($self->{productname} =~ /Connectrix DS_4900B/i) {
        bless $self, 'Classes::Brocade';
        $self->debug('using Classes::Brocade');
      } elsif ($self->{productname} =~ /EMC\s*DS.*4700M/i) {
        bless $self, 'Classes::Brocade';
        $self->debug('using Classes::Brocade');
      } elsif ($self->{productname} =~ /EMC\s*DS-24M2/i) {
        bless $self, 'Classes::Brocade';
        $self->debug('using Classes::Brocade');
      } elsif ($self->{productname} =~ /Brocade/i) {
        bless $self, 'Classes::Brocade';
        $self->debug('using Classes::Brocade');
      } elsif ($self->{productname} =~ /Fibre Channel Switch/i) {
        bless $self, 'Classes::Brocade';
        $self->debug('using Classes::Brocade');
      } elsif ($self->{productname} =~ /Juniper.*MAG\-\d+/i) {
        # Juniper Networks,Inc,MAG-4610,7.2R10
        bless $self, 'Classes::Juniper';
        $self->debug('using Classes::Juniper');
      } elsif ($self->{productname} =~ /Juniper.*MAG\-SM\d+/i) {
        # Juniper Networks,Inc,MAG-SMx60,7.4R8
        bless $self, 'Classes::Juniper::IVE';
        $self->debug('using Classes::Juniper::IVE');
      } elsif ($self->{productname} =~ /NetScreen/i) {
        bless $self, 'Classes::Juniper';
        $self->debug('using Classes::Juniper');
      } elsif ($self->{productname} =~ /^(GS|FS)/i) {
        bless $self, 'Classes::Juniper';
        $self->debug('using Classes::Juniper');
      } elsif ($self->implements_mib('NETSCREEN-PRODUCTS-MIB')) {
        $self->debug('using Classes::Juniper::NetScreen');
        bless $self, 'Classes::Juniper::NetScreen';
      } elsif ($self->implements_mib('PAN-PRODUCTS-MIB')) {
        $self->debug('using Classes::PaloAlto');
        bless $self, 'Classes::PaloAlto';
      } elsif ($self->{productname} =~ /SecureOS/i) {
        bless $self, 'Classes::SecureOS';
        $self->debug('using Classes::SecureOS');
      } elsif ($self->{productname} =~ /Linux.*((el6.f5.x86_64)|(el5.1.0.f5app)) .*/i) {
        bless $self, 'Classes::F5';
        $self->debug('using Classes::F5');
      } elsif ($self->{productname} =~ /Procurve/i) {
        bless $self, 'Classes::HP';
        $self->debug('using Classes::HP');
      } elsif ($self->{productname} =~ /(cpx86_64)|(Check\s*Point)|(Linux.*\dcp )/i) {
        bless $self, 'Classes::CheckPoint';
        $self->debug('using Classes::CheckPoint');
      } elsif ($self->{productname} =~ /Clavister/i) {
        bless $self, 'Classes::Clavister';
        $self->debug('using Classes::Clavister');
      } elsif ($self->{productname} =~ /Blue\s*Coat/i) {
        bless $self, 'Classes::Bluecoat';
        $self->debug('using Classes::Bluecoat');
      } elsif ($self->{productname} =~ /Foundry/i) {
        bless $self, 'Classes::Foundry';
        $self->debug('using Classes::Foundry');
      } elsif ($self->{productname} =~ /IronWare/i) {
        # although there can be a 
        # Brocade Communications Systems, Inc. FWS648, IronWare Version 07.1....
        bless $self, 'Classes::Foundry';
        $self->debug('using Classes::Foundry');
      } elsif ($self->{productname} =~ /Linux Stingray/i) {
        bless $self, 'Classes::HOSTRESOURCESMIB';
        $self->debug('using Classes::HOSTRESOURCESMIB');
      } elsif ($self->{productname} =~ /Fortinet|Fortigate/i) {
        bless $self, 'Classes::Fortigate';
        $self->debug('using Classes::Fortigate');
      } elsif ($self->{productname} eq "ifmib") {
        bless $self, 'Classes::Generic';
        $self->debug('using Classes::Generic');
      } elsif ($self->implements_mib('SW-MIB')) {
        bless $self, 'Classes::Brocade';
        $self->debug('using Classes::Brocade');
      } elsif ($self->{sysobjectid} =~ /1\.3\.6\.1\.4\.1\.9\./) {
        bless $self, 'Classes::Cisco';
        $self->debug('using Classes::Cisco');
      } else {
        if (my $class = $self->discover_suitable_class()) {
          bless $self, $class;
          $self->debug('using '.$class);
        } else {
          bless $self, 'Classes::Generic';
          $self->debug('using Classes::Generic');
        }
      }
    }
  }
  return $self;
}


package Classes::Generic;
our @ISA = qw(Classes::Device);
use strict;


sub init {
  my $self = shift;
  if ($self->mode =~ /device::interfaces::aggregation::availability/) {
    $self->analyze_and_check_aggregation_subsystem("Classes::IFMIB::Component::LinkAggregation");
  } elsif ($self->mode =~ /device::interfaces/) {
    $self->analyze_and_check_interface_subsystem("Classes::IFMIB::Component::InterfaceSubsystem");
  } elsif ($self->mode =~ /device::bgp/) {
    $self->analyze_and_check_bgp_subsystem("Classes::BGP::Component::PeerSubsystem");
  } else {
    bless $self, 'GLPlugin::SNMP';
    $self->no_such_mode();
  }
}

