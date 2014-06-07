package Classes::FCEOS::Component::FruSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('FCEOS-MIB', [
      ['frus', 'fcEosFruTable', 'Classes::FCEOS::Component::FruSubsystem::Fcu'],
  ]);
}

package Classes::FCEOS::Component::FruSubsystem::Fcu;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
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

