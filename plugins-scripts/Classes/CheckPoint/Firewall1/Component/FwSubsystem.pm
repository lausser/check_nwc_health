package Classes::CheckPoint::Firewall1::Component::FwSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
      fwModuleState fwPolicyName fwNumConn)));
  if ($self->mode =~ /device::fw::policy::installed/) {
  } elsif ($self->mode =~ /device::fw::policy::connections/) {
  }
}

sub check {
  my ($self) = @_;
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
    $self->set_thresholds(warning => 20000, critical => 23000);
    $self->add_message($self->check_thresholds($self->{fwNumConn}),
        sprintf 'policy %s has %s open connections',
            $self->{fwPolicyName}, $self->{fwNumConn});
    $self->add_perfdata(
        label => 'fw_policy_numconn',
        value => $self->{fwNumConn},
    );
  }
}

