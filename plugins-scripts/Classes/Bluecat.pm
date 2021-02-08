package Classes::Bluecat;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /Bluecat Address Manager/) {
    $self->rebless('Classes::Bluecat::AddressManager');
  } elsif ($self->{productname} =~ /Bluecat DNS\/DHCP Server/) {
    $self->rebless('Classes::Bluecat::DnsDhcpServer');
  }
  if (ref($self) ne "Classes::Bluecat") {
    $self->init();
  } else {
    $self->no_such_mode();
  }
}

