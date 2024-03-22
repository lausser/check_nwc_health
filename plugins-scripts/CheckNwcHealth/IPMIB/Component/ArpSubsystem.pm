package CheckNwcHealth::IPMIB::Component::ArpSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{interfaces} = [];
  $self->get_snmp_tables('IP-MIB', [
      ['oentries', 'ipNetToMediaTable', 'CheckNwcHealth::IPMIB::Component::ArpSubsystem::Entry'],
      ['entries', 'ipNetToPhysicalTable', 'CheckNwcHealth::IPMIB::Component::ArpSubsystem::Entry'],
  ]);
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::arp::list/) {
    $self->add_ok(sprintf "found %d entries in the ARP cache", scalar(@{$self->{oentries}}));
    if ($self->opts->report eq "json") {
      my $coder = JSON::XS->new->ascii->allow_nonref;
      my @struct = map {
        $_->list();
      } @{$self->{oentries}};
      my $jsonscalar = $coder->encode(\@struct);
      $self->add_info($jsonscalar);
    } else {
      foreach (@{$self->{oentries}}) {
        $self->add_info($_->list());
      }
      $self->add_ok("have fun");
    }
  }
}


package CheckNwcHealth::IPMIB::Component::ArpSubsystem::Entry;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{ipNetToMediaPhysAddress} = $self->unhex_mac($self->{ipNetToMediaPhysAddress});
}

sub list {
  my ($self) = @_;
  if ($self->opts->report eq "json") {
    return {
        $self->{ipNetToMediaNetAddress} =>
            $self->{ipNetToMediaPhysAddress}
    }
  } else {
    return sprintf "%-20s %s", $self->{ipNetToMediaNetAddress}, $self->{ipNetToMediaPhysAddress};
  }
}

