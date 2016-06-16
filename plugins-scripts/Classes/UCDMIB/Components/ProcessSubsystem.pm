package Classes::UCDMIB::Component::ProcessSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('UCD-SNMP-MIB', [
      ['processes', 'prTable', 'Classes::UCDMIB::Component::ProcessSubsystem::Process',
        sub {
          my $self = shift;
          # limit process checks to specific names. could be improvied by
          # checking the names first and then request the table by indizes
          if ($self->opts->name) {
            if ($self->opts->regexp) {
              my $pattern = $self->opts->name;
              return $self->{prNames} =~ /$pattern/i;
            } else {
              return grep { $_ eq $self->{prNames} }
                  split ',', $self->opts->name;
            }
          } else {
            return 1;
          }
        }
      ]
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking processes');
  if (scalar(@{$self->{processes}}) == 0) {
    $self->add_unknown('no processes');
    return;
  }
  foreach (@{$self->{processes}}) {
    $_->check();
  }
}

package Classes::UCDMIB::Component::ProcessSubsystem::Process;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s: %d%s',
      $self->{prNames},
      $self->{prCount},
      $self->{prErrorFlag} eq 'error'
          ? sprintf ' (%s)', $self->{prErrMessage}
          : '');
  my $threshold = sprintf '%u:%s',
      !$self->{prMin} && !$self->{prMax} ? 1 : $self->{prMin},
      $self->{prMax} && $self->{prMax} >= $self->{prMin} ? $self->{prMax} : '';
  $self->set_thresholds(
      metric => $self->{prNames},
      warning => $threshold,
      critical => $threshold);
  if ($self->{prErrorFlag} eq 'error') {
    $self->add_critical();
  } else {
    $self->add_message($self->check_thresholds(
        metric => $self->{prNames},
        value => $self->{prCount}));
  }
  $self->add_perfdata(
      label => $self->{prNames},
      value => $self->{prCount}
  );
}

