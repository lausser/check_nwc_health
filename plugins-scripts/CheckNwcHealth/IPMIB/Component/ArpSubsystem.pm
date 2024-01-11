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
  $self->add_info('checking the arp cache');
  if ($self->mode =~ /device::arp::list/) {
    $self->add_ok(sprintf "found %d entries in the ARP cache", scalar(@{$self->{oentries}}));
    if ($self->opts->report eq "json") {
      my $coder = JSON::XS->new->ascii->allow_nonref;
      my @struct = map {
        $_->list();
      } @{$self->{oentries}};
      my $jsonscalar = $coder->encode(\@struct);
      $self->add_ok($jsonscalar);
    } else {
      foreach (@{$self->{oentries}}) {
        $_->list();
      }
      $self->add_ok("have fun");
    }
  }
  my $x = "schars";
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
        ip => $self->{ipNetToMediaNetAddress},
        mac => $self->{ipNetToMediaPhysAddress},
    }
  } else {
    printf "%-20s %s\n", $self->{ipNetToMediaNetAddress}, $self->{ipNetToMediaPhysAddress};
  }
}

