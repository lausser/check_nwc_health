package CheckNwcHealth::Cisco::CISCOENVMONMIB::Component::PowersupplySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-ENVMON-MIB', [
      ['supplies', 'ciscoEnvMonSupplyStatusTable', 'CheckNwcHealth::Cisco::CISCOENVMONMIB::Component::PowersupplySubsystem::Powersupply'],
  ]);
}


package CheckNwcHealth::Cisco::CISCOENVMONMIB::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->ensure_index('ciscoEnvMonSupplyStatusIndex');
  $self->add_info(sprintf 'powersupply %d (%s) is %s',
      $self->{ciscoEnvMonSupplyStatusIndex},
      $self->{ciscoEnvMonSupplyStatusDescr},
      $self->{ciscoEnvMonSupplyState});
  if ($self->{ciscoEnvMonSupplyState} eq 'notPresent') {
  } elsif ($self->{ciscoEnvMonSupplyState} eq 'warning') {
    $self->add_warning();
  } elsif ($self->{ciscoEnvMonSupplyState} eq 'critical' &&
      $self->{ciscoEnvMonSupplyStatusDescr} =~
      /Sw\d+, PS\d+ Critical, RPS Normal/) {
    # 4.8.2017:
    # Der Netzwerktechniker on site sagt mir, dass das aber so normal ist,
    # weil die Netzteile nicht angeschlossen sind, und der switch
    # nur ueber "RPS" seinen Saft bezieht. Gut ich kenn mich mit dem Geraffel
    # nicht aus, also glaube ich ihm das mal.
    # Gruesse, aus dem gerade extrem heissen Athen.
    $self->add_ok();
  } elsif ($self->{ciscoEnvMonSupplyState} eq 'shutdown' &&
      $self->{ciscoEnvMonSupplySource} eq 'ac') {
    # check for bug
    # https://communities.ca.com/thread/241748773
    my $stack = $self->get_snmp_object('ENTITY-MIB', 'entPhysicalModelName', 1);
    if ($stack && $stack =~ /C(3850|3750|3560)/i) {
      $self->blacklist();
      $self->annotate_info('Bug CSCuv18572');
    }
    $self->add_critical();
  } elsif ($self->{ciscoEnvMonSupplyState} ne 'normal') {
    $self->add_critical();
  }
}

__END__

checking supplies
powersupply 1017 (Switch 1 - Power Supply A, Normal) is normal
powersupply 1018 (Switch 1 - Power Supply B, Shutdown) is shutdown
powersupply 2014 (Switch 2 - Power Supply A, Normal) is normal
powersupply 2015 (Switch 2 - Power Supply B, Normal) is normal
CSCuv18572

1.3.6.1.4.1.9.9.249.1.1.1.1.5.1000 = STRING: "03.07.04E"
1.3.6.1.2.1.47.1.1.1.1.13.1 = STRING: "WS-C3850-24T"

So sieht der Bug aus:
[POWERSUPPLY_1018]
ciscoEnvMonSupplySource: ac  <---------------
ciscoEnvMonSupplyState: shutdown
ciscoEnvMonSupplyStatusDescr: Switch 1 - Power Supply B, Shutdown
ciscoEnvMonSupplyStatusIndex: 1018
info: powersupply 1018 (Switch 1 - Power Supply B, Shutdown) is shutdown


Das ist wirklich kaputt:
[POWERSUPPLY_1015]
ciscoEnvMonSupplySource: unknown  <--------
ciscoEnvMonSupplyState: shutdown
ciscoEnvMonSupplyStatusDescr: Switch 1 - Power Supply B, Shutdown
ciscoEnvMonSupplyStatusIndex: 1015
info: powersupply 1015 (Switch 1 - Power Supply B, Shutdown) is shutdown

