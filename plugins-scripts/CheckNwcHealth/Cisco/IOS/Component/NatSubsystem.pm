package CheckNwcHealth::Cisco::IOS::Component::NatSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::interfaces::nat::sessions::count/) { 
    $self->get_snmp_objects('CISCO-IETF-NAT-MIB', qw(
        cnatAddrBindNumberOfEntries cnatAddrPortBindNumberOfEntries
    ));
  } elsif ($self->mode =~ /device::interfaces::nat::rejects/) { 
    $self->get_snmp_tables('CISCO-IETF-NAT-MIB', [
        ['protocolstats', 'cnatProtocolStatsTable', 'CheckNwcHealth::Cisco::IOS::Component::NatSubsystem::CnatProtocolStats'],
    ]);
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::interfaces::nat::sessions::count/) { 
    $self->add_info(sprintf '%d bind entries (%d addr, %d port)',
        $self->{cnatAddrBindNumberOfEntries} + $self->{cnatAddrPortBindNumberOfEntries},
        $self->{cnatAddrBindNumberOfEntries},
        $self->{cnatAddrPortBindNumberOfEntries}
    );
    $self->add_ok();
    $self->add_perfdata(
        label => 'nat_bindings',
        value => $self->{cnatAddrBindNumberOfEntries} + $self->{cnatAddrPortBindNumberOfEntries},
    );
    $self->add_perfdata(
        label => 'nat_addr_bindings',
        value => $self->{cnatAddrBindNumberOfEntries},
    );
    $self->add_perfdata(
        label => 'nat_port_bindings',
        value => $self->{cnatAddrPortBindNumberOfEntries},
    );
  } elsif ($self->mode =~ /device::interfaces::nat::rejects/) {
    foreach (@{$self->{protocolstats}}) {
      $_->check();
    }
  }
}

package CheckNwcHealth::Cisco::IOS::Component::NatSubsystem::CnatProtocolStats;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{cnatProtocolStatsName} = $self->{flat_indices};
  $self->make_symbolic('CISCO-IETF-NAT-MIB', 'cnatProtocolStatsName', $self->{cnatProtocolStatsName});
  $self->valdiff({name => $self->{cnatProtocolStatsName}},
      qw(cnatProtocolStatsInTranslate cnatProtocolStatsOutTranslate cnatProtocolStatsRejectCount));
  $self->{delta_cnatProtocolStatsTranslate} = 
      $self->{delta_cnatProtocolStatsInTranslate} +
      $self->{delta_cnatProtocolStatsOutTranslate};
  $self->{rejects} = $self->{delta_cnatProtocolStatsTranslate} ?
      (100 * $self->{delta_cnatProtocolStatsRejectCount} / 
      $self->{delta_cnatProtocolStatsTranslate}) : 0;
  $self->protect_value($self->{rejects}, 'rejects', 'percent');
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%.2f%% of all %s packets have been dropped/rejected',
      $self->{rejects}, $self->{cnatProtocolStatsName});
  $self->set_thresholds(warning => 30, critical => 50);
  $self->add_message($self->check_thresholds($self->{rejects}));
}

