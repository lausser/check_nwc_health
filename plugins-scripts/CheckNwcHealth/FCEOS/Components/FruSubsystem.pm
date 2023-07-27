package CheckNwcHealth::FCEOS::Component::FruSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('FCEOS-MIB', [
      ['frus', 'fcEosFruTable', 'CheckNwcHealth::FCEOS::Component::FruSubsystem::Fcu'],
  ]);
}

package CheckNwcHealth::FCEOS::Component::FruSubsystem::Fcu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s fru (pos %s) is %s',
      $self->{fcEosFruCode},
      $self->{fcEosFruPosition},
      $self->{fcEosFruStatus});
  if ($self->{fcEosFruStatus} eq "failed") {
    $self->add_critical();
  } else {
    #$self->add_ok();
  }
}

