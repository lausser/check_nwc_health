package Classes::FCEOS::Component::FruSubsystem;
@ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('FCEOS-MIB', [
      ['frus', 'fcEosFruTable', 'Classes::FCEOS::Component::FruSubsystem::Fcu'],
  ]);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking frus');
  $self->blacklist('frus', '');
  foreach (@{$self->{frus}}) {
    $_->check();
  }
}


package Classes::FCEOS::Component::FruSubsystem::Fcu;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('fru', $self->{swSensorIndex});
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

