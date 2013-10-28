package NWC::BGP::Component::PeerSubsystem;
our @ISA = qw(NWC::BGP);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our $errorcodes = {
  0 => {
    0 => 'No Error',
  },
  1 => {
    0 => 'MESSAGE Header Error',
    1 => 'Connection Not Synchronized',
    2 => 'Bad Message Length',
    3 => 'Bad Message Type',
  },
  2 => {
    0 => 'OPEN Message Error',
    1 => 'Unsupported Version Number',
    2 => 'Bad Peer AS',
    3 => 'Bad BGP Identifier',
    4 => 'Unsupported Optional Parameter',
    5 => '[Deprecated => see Appendix A]',
    6 => 'Unacceptable Hold Time',
  },
  3 => {
    0 => 'UPDATE Message Error',
    1 => 'Malformed Attribute List',
    2 => 'Unrecognized Well-known Attribute',
    3 => 'Missing Well-known Attribute',
    4 => 'Attribute Flags Error',
    5 => 'Attribute Length Error',
    6 => 'Invalid ORIGIN Attribute',
    7 => '[Deprecated => see Appendix A]',
    8 => 'Invalid NEXT_HOP Attribute',
    9 => 'Optional Attribute Error',
   10 => 'Invalid Network Field',
   11 => 'Malformed AS_PATH',
  },
  4 => {
    0 => 'Hold Timer Expired',
  },
  5 => {
    0 => 'Finite State Machine Error',
  },
  6 => {
    0 => 'Cease',
    1 => 'Maximum Number of Prefixes Reached',
    2 => 'Administrative Shutdown',
    3 => 'Peer De-configured',
    4 => 'Administrative Reset',
    5 => 'Connection Rejected',
    6 => 'Other Configuration Change',
    7 => 'Connection Collision Resolution',
    8 => 'Out of Resources',
  },
};

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    peers => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  my %params = @_;
  if ($self->mode =~ /device::bgp::peer::list/) {
    $self->update_entry_cache(1, 'BGP4-MIB', 'bgpPeerTable', 'bgpPeerRemoteAddr');
  }
  foreach ($self->get_snmp_table_objects_with_cache(
      'BGP4-MIB', 'bgpPeerTable', 'bgpPeerRemoteAddr')) {
    if ($self->filter_name($_->{bgpPeerRemoteAddr})) {
      push(@{$self->{peers}},
          NWC::BGP::Component::PeerSubsystem::Peer->new(%{$_}));
    }
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking bgp peers');
  $self->blacklist('bgp', '');
  if (scalar(@{$self->{peers}}) == 0) {
    $self->add_message(UNKNOWN, 'no peers');
    return;
  }
  if ($self->mode =~ /peer::list/) {
    foreach (sort {$a->{bgpPeerRemoteAddr} cmp $b->{bgpPeerRemoteAddr}} @{$self->{peers}}) {
      printf "%s\n", $_->{bgpPeerRemoteAddr};
      #$_->list();
    }
  } else {
    foreach (@{$self->{peers}}) {
      $_->check();
    }
printf "all ckeches\n";
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{peers}}) {
    $_->dump();
  }
}


package NWC::BGP::Component::PeerSubsystem::Peer;
our @ISA = qw(NWC::BGP::Component::PeerSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };


sub new {
  my $class = shift;
  my %params = @_;
  my $self = {};
  foreach(keys %params) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  $self->{bgpPeerLastError} |= "00 00";
  my $errorcode = 0;
  my $subcode = 0;
  if (lc $self->{bgpPeerLastError} =~ /([0-9a-f]+)\s+([0-9a-f]+)/) {
    $errorcode = hex($1) * 1;
    $subcode = hex($2) * 1;
  }
  $self->{bgpPeerLastError} = $NWC::BGP::Component::PeerSubsystem::errorcodes->{$errorcode}->{$subcode};
  return $self;
}

sub check {
  my $self = shift;
printf "check\n";
  if ($self->{bgpPeerState} ne "established") {
    $self->add_message(CRITICAL, sprintf "peer %s (%s) connection is %s (last error: %s)",
        $self->{bgpPeerRemoteAs},
        $self->{bgpPeerRemoteAddr},
        $self->{bgpPeerState},
        $self->{bgpPeerLastError}
    );
  } else {
    $self->add_message(OK, sprintf "peer %s (%s) connection is %s since %ds",
        $self->{bgpPeerRemoteAs},
        $self->{bgpPeerRemoteAddr},
        $self->{bgpPeerState},
        $self->{bgpPeerFsmEstablishedTransitions}
    );
  }
}

sub dump {
  my $self = shift;
  printf "[BGP_PEER_%s]\n", $self->{bgpPeerRemoteAddr};
  foreach(qw(bgpPeerRemoteAddr bgpPeerRemotePort bgpPeerState bgpPeerAdminStatus bgpPeerIdentifier
      bgpPeerLocalAddr bgpPeerLocalPort bgpPeerRemoteAs bgpPeerFsmEstablishedTime)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
}



