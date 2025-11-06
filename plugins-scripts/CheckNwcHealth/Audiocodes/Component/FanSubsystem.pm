package CheckNwcHealth::Audiocodes::Component::FanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('AC-SYSTEM-MIB', [
    ['fantrays', 'acSysFanTrayTable', 'CheckNwcHealth::Audiocodes::Component::FanSubsystem::Fantray'],
  ]);
}

sub check {
  my ($self) = @_;
  $self->add_info('checking fan trays');
  foreach (@{$self->{fantrays}}) {
    $_->check();
  }
}

package CheckNwcHealth::Audiocodes::Component::FanSubsystem::Fantray;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my $existence = $self->{acSysFanTrayExistence};
  if ($existence eq 'present') { # present
    $self->add_info(sprintf 'fan tray %d is present', $self->{acSysFanTrayIndex} || $self->{flat_indices});
    my $severity = $self->{acSysFanTraySeverity};
    if ($severity eq 'cleared') { # cleared
      $self->add_ok();
    } elsif ($severity eq 'indeterminate') { # indeterminate
      $self->add_warning('fan tray indeterminate');
    } elsif ($severity eq 'warning') { # warning
      $self->add_warning('fan tray warning');
    } elsif ($severity eq 'minor' || $severity eq 'major' || $severity eq 'critical') { # minor, major, critical
      $self->add_critical('fan tray critical');
    }
  } else {
    $self->add_info(sprintf 'fan tray %d is missing', $self->{acSysFanTrayIndex} || $self->{flat_indices});
  }
}

