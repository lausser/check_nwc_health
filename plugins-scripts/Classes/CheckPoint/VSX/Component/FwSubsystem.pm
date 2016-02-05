package Classes::CheckPoint::VSX::Component::FwSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
      fwModuleState fwPolicyName)));
  if ($self->mode =~ /device::fw::policy::installed/) {
  } elsif ($self->mode =~ /device::fw::policy::connections/) {
    $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['vsxs', 'vsxCountersTable', 'Classes::CheckPoint::VSX::Component::FwSubsystem::Vsx'],
      ['vsxstatus', 'vsxStatusTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ]);
    foreach my $vsx (@{$self->{vsxs}}) {
      foreach my $vsxstatus (@{$self->{vsxstatus}}) {
        if ($vsx->{vsxCountersVSId} eq $vsxstatus->{vsxStatusVSId}) {
          map {
              $vsx->{$_} = $vsxstatus->{$_}
          } grep {
              /^vsx/
          } keys %{$vsxstatus};
        }
      }
    }
    delete $self->{vsxstatus};
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking fw module');
  if ($self->{fwModuleState} ne 'Installed') {
    $self->add_critical(sprintf 'fw module is %s', $self->{fwPolicyName});
  } elsif ($self->mode =~ /device::fw::policy::installed/) {
    if (! $self->opts->name()) {
      $self->add_unknown('please specify a policy with --name');
    } elsif ($self->{fwPolicyName} eq $self->opts->name()) {
      $self->add_ok(sprintf 'fw policy is %s', $self->{fwPolicyName});
    } else {
      $self->add_critical(sprintf 'fw policy is %s, expected %s',
          $self->{fwPolicyName}, $self->opts->name());
    }
  } elsif ($self->mode =~ /device::fw::policy::connections/) {
    $self->{sumNumConn} = 0;
    map { $self->{fwNumConn} += $_->{vsxCountersConnNum} } @{$self->{vsxs}};
    $self->set_thresholds(metric => 'fwNumConn',
        warning => 20000, critical => 23000);
    $self->add_message($self->check_thresholds(
        metric => 'fwNumConn',
        value => $self->{fwNumConn}),
        sprintf 'policy %s has %s open connections',
            $self->{fwPolicyName}, $self->{fwNumConn});
    $self->add_perfdata(
        label => 'fw_policy_numconn',
        value => $self->{fwNumConn},
    );
    $self->SUPER::check();
  }
}

package Classes::CheckPoint::VSX::Component::FwSubsystem::Vsx;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  my $label = sprintf 'vsx_%s_numconn', $self->{vsxStatusVsName};
  $self->set_thresholds(metric => $label,
      warning => 20000, critical => 23000);
  $self->add_message($self->check_thresholds(
      metric => $label,
      value => $self->{vsxCountersConnNum}),
      sprintf 'vsx %s has %s open connections',
          $self->{vsxStatusVsName}, $self->{vsxCountersConnNum});
  $self->add_perfdata(
      label => $label,
      value => $self->{vsxCountersConnNum},
  );
}

