package Classes::Generic;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(Classes::Device);


sub init {
  my $self = shift;
  if ($self->mode =~ /device::interfaces::aggregation::availability/) {
    my $aggregation = NWC::IFMIB::Component::LinkAggregation->new();
    #$self->analyze_interface_subsystem();
    $aggregation->check();
  } elsif ($self->mode =~ /device::interfaces/) {
    $self->analyze_interface_subsystem();
    $self->check_interface_subsystem();
  } elsif ($self->mode =~ /device::bgp/) {
    $self->analyze_bgp_subsystem();
    $self->check_bgp_subsystem();
  } else {
    $self->init();
    #$self->no_such_mode();
  }
}


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

