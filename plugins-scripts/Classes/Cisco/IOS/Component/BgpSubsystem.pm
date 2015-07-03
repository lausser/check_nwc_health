package Classes::Cisco::IOS::Component::BgpSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-BGP4-MIB', [
      ['prefixes', 'cbgpPeerAddrFamilyPrefixTable', 'Classes::Cisco::IOS::Component::BgpSubsystem::Prefix', sub { return $self->filter_name(shift->{cbgpPeerRemoteAddr}) } ],
  ]);
}


package Classes::Cisco::IOS::Component::BgpSubsystem::Prefix;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{cbgpPeerAddrFamilyAfi} = pop @{$self->{indices}};
  $self->{cbgpPeerAddrFamilySafi} = pop @{$self->{indices}};
  $self->{cbgpPeerRemoteAddr} = join(".", @{$self->{indices}});
}

sub check {
  my $self = shift;
  if ($self->mode =~ /prefix::count/) {
    $self->add_info(sprintf "peer %s accepted %d prefixes", 
        $self->{cbgpPeerRemoteAddr}, $self->{cbgpPeerAddrAcceptedPrefixes});
    $self->set_thresholds(metric => $self->{cbgpPeerRemoteAddr}.'_accepted_prefixes',
        warning => '1:', critical => '1:');
    $self->add_message($self->check_thresholds(
        metric => $self->{cbgpPeerRemoteAddr}.'_accepted_prefixes',
        value => $self->{cbgpPeerAddrAcceptedPrefixes}));
    $self->add_perfdata(
        label => $self->{cbgpPeerRemoteAddr}.'_accepted_prefixes',
        value => $self->{cbgpPeerAddrAcceptedPrefixes},
    );
  }
}
