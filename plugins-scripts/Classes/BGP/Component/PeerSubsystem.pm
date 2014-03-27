package Classes::BGP::Component::PeerSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

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

sub init {
  my $self = shift;
  $self->{peers} = [];
  if ($self->mode =~ /device::bgp::peer::list/) {
    $self->update_entry_cache(1, 'BGP4-MIB', 'bgpPeerTable', 'bgpPeerRemoteAddr');
  }
  foreach ($self->get_snmp_table_objects_with_cache(
      'BGP4-MIB', 'bgpPeerTable', 'bgpPeerRemoteAddr')) {
    if ($self->filter_name($_->{bgpPeerRemoteAddr})) {
      push(@{$self->{peers}},
          Classes::BGP::Component::PeerSubsystem::Peer->new(%{$_}));
    }
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking bgp peers');
  $self->blacklist('bgp', '');
  if (scalar(@{$self->{peers}}) == 0) {
    $self->add_unknown('no peers');
    return;
  }
  if ($self->mode =~ /peer::list/) {
    foreach (sort {$a->{bgpPeerRemoteAddr} cmp $b->{bgpPeerRemoteAddr}} @{$self->{peers}}) {
      printf "%s\n", $_->{bgpPeerRemoteAddr};
      #$_->list();
    }
  } else {
    # es gibt 
    # kleine installation: 1 peer zu 1 as, evt 2. as als fallback
    # grosse installation: n peer zu 1 as, alternative routen zum provider
    #                      n peer zu m as, mehrere provider, mehrere alternativrouten
    # 1 ausfall on 4 peers zu as ist egal
    my $as_numbers = {};
    foreach (@{$self->{peers}}) {
      $_->check();
      if (! exists $as_numbers->{$_->{bgpPeerRemoteAs}}->{peers}) {
        $as_numbers->{$_->{bgpPeerRemoteAs}}->{peers} = [];
        $as_numbers->{$_->{bgpPeerRemoteAs}}->{availability} = 100;
      }
      push(@{$as_numbers->{$_->{bgpPeerRemoteAs}}->{peers}}, $_);
    }
    if ($self->opts->name2) {
      $self->clear_ok();
      $self->clear_critical();
      if ($self->opts->name2 eq "_ALL_") {
        $self->opts->override_opt("name2", join(",", keys %{$as_numbers}));
      }
      foreach my $as (split(",", $self->opts->name2)) {
        my $asname = "";
        if ($as =~ /(\d+)=(\w+)/) {
          $as = $1;
          $asname = $2;
        }
        if (exists $as_numbers->{$as}) {
          my $num_peers = scalar(@{$as_numbers->{$as}->{peers}});
          my $num_ok_peers = scalar(grep { $_->{bgpPeerFaulty} == 0 } @{$as_numbers->{$as}->{peers}});
          $as_numbers->{$as}->{availability} = 100 * $num_ok_peers / $num_peers;
          $self->set_thresholds(warning => "100:", critical => "50:");
          $self->add_message($self->check_thresholds($as_numbers->{$as}->{availability}),
              sprintf "%d from %d connections to %s are up (%.2f%%)",
              $num_ok_peers, $num_peers, $asname ? $asname : "AS".$as, 
              $as_numbers->{$as}->{availability});
        } else {
          $self->add_critical(sprintf 'found no peer for %s', $asname ? $asname : "AS".$as);
        }
      }
      
    }
    if ($self->opts->report eq "short") {
      $self->clear_ok();
      $self->add_ok('no problems') if ! $self->check_messages();
    }
  }
}


package Classes::BGP::Component::PeerSubsystem::Peer;
our @ISA = qw(Classes::BGP::Component::PeerSubsystem);
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
  $self->{bgpPeerLastError} = $Classes::BGP::Component::PeerSubsystem::errorcodes->{$errorcode}->{$subcode};
  $self->{bgpPeerRemoteAsName} = "";
  $self->{bgpPeerRemoteAsImportant} = 0; # if named in --name2
  $self->{bgpPeerFaulty} = 0;
  my @parts = gmtime($self->{bgpPeerFsmEstablishedTime});
  $self->{bgpPeerFsmEstablishedTime} = sprintf ("%dd, %dh, %dm, %ds",@parts[7,2,1,0]);

  return $self;
}

sub check {
  my $self = shift;
  if ($self->opts->name2) {
    foreach my $as (split(",", $self->opts->name2)) {
      if ($as =~ /(\d+)=(\w+)/) {
        $as = $1;
        $self->{bgpPeerRemoteAsName} = ", ".$2;
      } else {
        $self->{bgpPeerRemoteAsName} = "";
      }
      if ($as eq "_ALL_" || $as == $self->{bgpPeerRemoteAs}) {
        $self->{bgpPeerRemoteAsImportant} = 1;
      }
    }
  } else {
    $self->{bgpPeerRemoteAsImportant} = 1;
  }
  if ($self->{bgpPeerState} eq "established" || $self->{bgpPeerState} eq "idle") {
    $self->add_ok(sprintf "peer %s (AS%s) state is %s since %s",
        $self->{bgpPeerRemoteAddr},
        $self->{bgpPeerRemoteAs}.$self->{bgpPeerRemoteAsName},
        $self->{bgpPeerState},
        $self->{bgpPeerFsmEstablishedTime}
    );
  } elsif ($self->{bgpPeerAdminStatus} eq "stop") {
    $self->add_message($self->{bgpPeerRemoteAsImportant} ? WARNING : OK, 
        sprintf "peer %s (AS%s) state is %s (is admin down)",
        $self->{bgpPeerRemoteAddr},
        $self->{bgpPeerRemoteAs}.$self->{bgpPeerRemoteAsName},
        $self->{bgpPeerState}
    );
    $self->{bgpPeerFaulty} = $self->{bgpPeerRemoteAsImportant} ? 1 : 0;
  } else {
    $self->add_message($self->{bgpPeerRemoteAsImportant} ? CRITICAL : OK,
        sprintf "peer %s (AS%s) state is %s (last error: %s)",
        $self->{bgpPeerRemoteAddr},
        $self->{bgpPeerRemoteAs}.$self->{bgpPeerRemoteAsName},
        $self->{bgpPeerState},
        $self->{bgpPeerLastError}
    );
    $self->{bgpPeerFaulty} = $self->{bgpPeerRemoteAsImportant} ? 1 : 0;
  }
}


