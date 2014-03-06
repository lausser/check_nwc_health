package Classes::F5::F5BIGIP::Component::FanSubsystem;
@ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('F5-BIGIP-SYSTEM-MIB', [
      ['fans', 'sysChassisFanTable', 'Classes::F5::F5BIGIP::Component::FanSubsystem::Fan'],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking fans');
  $self->blacklist('ff', '');
  foreach (@{$self->{fans}}) {
    $_->check();
  }
}


package Classes::F5::F5BIGIP::Component::FanSubsystem::Fan;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('f', $self->{sysChassisFanIndex});
  $self->add_info(sprintf 'chassis fan %d is %s (%drpm)',
      $self->{sysChassisFanIndex},
      $self->{sysChassisFanStatus},
      $self->{sysChassisFanSpeed});
  if ($self->{sysChassisFanStatus} eq 'notpresent') {
  } else {
    if ($self->{sysChassisFanStatus} ne 'good') {
      $self->add_critical();
    }
    $self->add_perfdata(
        label => sprintf('fan_%s', $self->{sysChassisFanIndex}),
        value => $self->{sysChassisFanSpeed},
        warning => undef,
        critical => undef,
    );
  }
}

