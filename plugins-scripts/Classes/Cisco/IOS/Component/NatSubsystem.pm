package Classes::Cisco::IOS::Component::NatSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::interfaces::nat::sessions::count/) { 
    $self->get_snmp_objects('CISCO-IETF-NAT-MIB', qw(
        cnatAddrBindNumberOfEntries cnatAddrPortBindNumberOfEntries
    ));
  } elsif ($self->mode =~ /device::interfaces::nat::rejects/) { 
    $self->get_snmp_tables('CISCO-IETF-NAT-MIB', [
        'protocolstats', 'cnatProtocolStatsTable', 'Classes::Cisco::IOS::Component::NatSubsystem::CnatProtocolStats',
    ]);
  }
}

sub check {
  my $self = shift;
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

package Classes::Cisco::IOS::Component::NatSubsystem::CnatProtocolStats;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{cnatProtocolStatsTranslate} = $self->{cnatProtocolStatsInTranslate} + $self->{cnatProtocolStatsOutTranslate};
  $self->{rejects} = $self->{cnatProtocolStatsTranslate} ? 100 * $self->{cnatProtocolStatsTranslate} / $self->{cnatProtocolStatsRejectCount} : 0;
}

sub check {
  my $self = shift;
  $self->add_info(sprintf '%.2f%% of all %s packets have been dropped/rejected',
      $self->{cnatProtocolStatsName}, $self->{rejects});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{rejects}));
}

