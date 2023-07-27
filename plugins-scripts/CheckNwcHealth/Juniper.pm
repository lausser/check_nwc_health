package CheckNwcHealth::Juniper;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

use constant trees => (
    '1.3.6.1.4.1.4874.',
    '1.3.6.1.4.1.3224.',
);

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::bgp/) {
    if ($self->implements_mib("JUNOS-BGP4V2-MIB")) {
      $self->analyze_and_check_bgp_subsystem("CheckNwcHealth::Juniper::JunOS::Component::BgpSubsystem");
    } else {
#      $self->{productname} =~ s/(?i:JunOS)/J#u#n#O#S/g;
      $self->no_such_mode();
    }
  } else {
    if ($self->{productname} =~ /Juniper.*MAG\-\d+/i) {
      # Juniper Networks,Inc,MAG-4610,7.2R10
      $self->rebless('CheckNwcHealth::Juniper::IVE');
    } elsif ($self->{productname} =~ /Juniper.*MAG\-SM\d+/i) {
      # Juniper Networks,Inc,MAG-SMx60,7.4R8
      $self->rebless('CheckNwcHealth::Juniper::IVE');
    } elsif ($self->{productname} =~ /srx/i) {
      $self->rebless('CheckNwcHealth::Juniper::SRX');
    } elsif ($self->{productname} =~ /NetScreen/i) {
      $self->rebless('CheckNwcHealth::Juniper::NetScreen');
    } elsif ($self->{productname} =~ /JunOS/i) {
      $self->rebless('CheckNwcHealth::Juniper::JunOS');
    } elsif ($self->implements_mib('NETSCREEN-PRODUCTS-MIB')) {
      $self->rebless('CheckNwcHealth::Juniper::NetScreen');
    } elsif ($self->{productname} =~ /^(GS|FS)/i) {
      $self->rebless('CheckNwcHealth::Juniper'); #? stammt aus Device.pm
    }
  }
  if (ref($self) ne "CheckNwcHealth::Juniper") {
    $self->init();
  }
}

