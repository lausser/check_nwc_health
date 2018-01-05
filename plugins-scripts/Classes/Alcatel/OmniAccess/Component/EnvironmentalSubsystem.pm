package Classes::Alcatel::OmniAccess::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{fan_subsystem} =
      Classes::Alcatel::OmniAccess::Component::FanSubsystem->new();
  $self->get_snmp_objects('WLSX-SYSTEMEXT-MIB', qw(
      wlsxSysExtInternalTemparature));
  $self->{powersupply_subsystem} = 
      Classes::Alcatel::OmniAccess::Component::PowersupplySubsystem->new();
  $self->{storage_subsystem} = 
      Classes::Alcatel::OmniAccess::Component::StorageSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{fan_subsystem}->check();
  $self->{powersupply_subsystem}->check();
  $self->{storage_subsystem}->check();
  $self->add_info(sprintf "temperature is %s", $self->{wlsxSysExtInternalTemparature});
  if ($self->{wlsxSysExtInternalTemparature} =~ /\(.*\)/ &&
      $self->{wlsxSysExtInternalTemparature} !~ /normal/i) {
    # -1.00 degrees Celsius (NORMAL)
    # wenn kein "(irgendwas)" enthalten ist, dann gibt's wahrsch. eh keinen
    # status, also ignorieren. und warum -1 grad normal sein sollen, muss
    # mir auch mal einer erklaeren.
    $self->add_warning();
  }
  $self->reduce_messages("environmental hardware working fine");
}

sub dump {
  my ($self) = @_;
  printf "[%s]\n%s\n", uc "wlsxSysExtInternalTemparature", 
      $self->{wlsxSysExtInternalTemparature};
  $self->{fan_subsystem}->dump();
  $self->{powersupply_subsystem}->dump();
  $self->{storage_subsystem}->dump();
}

