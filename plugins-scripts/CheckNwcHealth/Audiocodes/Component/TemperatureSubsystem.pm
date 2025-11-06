package CheckNwcHealth::Audiocodes::Component::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('AC-SYSTEM-MIB', (qw(acSysStateTemperature)));
}

 sub check {
   my ($self) = @_;
   $self->add_info('checking temperature');
   if (defined $self->{acSysStateTemperature}) {
     if ($self->{acSysStateTemperature} == 0) {
       $self->add_info('temperature sensor not available or disabled (value 0)');
     } else {
       $self->add_info(sprintf 'temperature is %d°C', $self->{acSysStateTemperature});
       $self->set_thresholds(
         metric => 'temperature',
         warning => 50,
         critical => 60);
       $self->add_message($self->check_thresholds(
           metric => 'temperature',
           value => $self->{acSysStateTemperature}));
       $self->add_perfdata(
         label => 'temperature',
         value => $self->{acSysStateTemperature},
         uom => '°C',
       );
     }
   } else {
     $self->add_unknown('cannot read temperature');
   }
 }

sub dump {
  my ($self) = @_;
  printf "temperature: %s\n", $self->{acSysStateTemperature} || 'unknown';
}