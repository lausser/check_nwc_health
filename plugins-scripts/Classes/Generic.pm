package Classes::Generic;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(Classes::Device);


sub analyze_interface_subsystem {
  my $self = shift;
  $self->{components}->{interface_subsystem} =
      Classes::IFMIB::Component::InterfaceSubsystem->new();
}

sub analyze_bgp_subsystem {
  my $self = shift;
  $self->{components}->{bgp_subsystem} =
      Classes::BGP::Component::PeerSubsystem->new();
}

