package CheckNwcHealth::Bluecat;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /Bluecat Address Manager/i) {
    $self->rebless('CheckNwcHealth::Bluecat::AddressManager');
  } elsif ($self->{productname} =~ /Bluecat DNS\/DHCP Server/i) {
    $self->rebless('CheckNwcHealth::Bluecat::DnsDhcpServer');
  }
  if (ref($self) ne "CheckNwcHealth::Bluecat") {
    $self->init();
  } else {
    $self->no_such_mode();
  }
}

