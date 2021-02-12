package Classes::Cisco::CISCOSMARTLICMIB::Component::KeySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects("CISCO-SMART-LIC-MIB", qw(ciscoSlaEnabled));
  $self->get_snmp_tables('CISCO-SMART-LIC-MIB', [
      ['keys', 'ciscoSlaEntitlementInfoTable', 'Classes::Cisco::CISCOSMARTLICMIB::Component::KeySubsystem::Entitlement'],
      ['keys', 'ciscoSlaRegistrationStatusInfoTable', 'Classes::Cisco::CISCOSMARTLICMIB::Component::KeySubsystem::RegStatusInfo', sub { shift->{valid} }],
      ['keys', 'ciscoSlaAuthorizationInfoTable', 'Classes::Cisco::CISCOSMARTLICMIB::Component::KeySubsystem::AuthInfo', sub { shift->{valid} }],
  ]);
}

sub check {
  my ($self) = @_;
  if ($self->{ciscoSlaEnabled} eq "false") {
    $self->add_ok("smart licensing is not enabled");
  } else {
    $self->SUPER::check();
  }
}


package Classes::Cisco::CISCOSMARTLICMIB::Component::KeySubsystem::Entitlement;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  #$self->{keyDaysUntilExpire} = int($self->{keySecondsUntilExpire} / 86400);
  $self->add_info(sprintf "entitlement %s for feature %s mode is %s",
      $self->{ciscoSlaEntitlementTag},
      $self->{ciscoSlaEntitlementFeatureName},
      $self->{ciscoSlaEntitlementEnforceMode}
  );
  $self->add_ok();
}


package Classes::Cisco::CISCOSMARTLICMIB::Component::KeySubsystem::RegStatusInfo;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{valid} = exists $self->{ciscoSlaRegistrationStatus} ? 1 : 0;
  return if ! $self->{valid};
  foreach (qw(ciscoSlaNextCertificateExpireTime ciscoSlaRegisterInitTime ciscoSlaRenewNextRetryTime)) {
    $self->{$_."Human"} = scalar localtime $self->{$_}
        if exists $self->{$_} and $self->{$_} =~ /^\d+$/;
  }
}

sub check {
  my ($self) = @_;
}


package Classes::Cisco::CISCOSMARTLICMIB::Component::KeySubsystem::AuthInfo;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{valid} = exists $self->{ciscoSlaAuthComplianceStatus} ? 1 : 0;
  return if ! $self->{valid};
  foreach (qw(ciscoSlaAuthRenewTime ciscoSlaAuthExpireTime ciscoSlaAuthRenewNextRetryTime ciscoSlaAuthRenewInitTime)) {
    $self->{$_."Human"} = scalar localtime $self->{$_}
        if exists $self->{$_} and $self->{$_} =~ /^\d+$/;
  }
  $self->{ciscoSlaAuthExpireTimeDays} =
      int(($self->{ciscoSlaAuthExpireTime} - time) / (3600*24));
  $self->{ciscoSlaAuthExpireTimeDays} =
      $self->{ciscoSlaAuthExpireTimeDays} < 0 ?
      0 : $self->{ciscoSlaAuthExpireTimeDays};
  if ($self->{ciscoSlaAuthOOCStartTime} > 0) {
    $self->{ciscoSlaAuthOOCStartTimeDays} =
        int((time - $self->{ciscoSlaAuthExpireTime}) / (3600*24));
  } else {
    $self->{ciscoSlaAuthOOCStartTimeDays} = 0;
  }
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "compliance status is %s",
      $self->{ciscoSlaAuthComplianceStatus});
  if ($self->{ciscoSlaAuthComplianceStatus} eq "AUTHORIZED") {
    $self->add_ok();
  } else {
    $self->add_critical();
  }
  if ($self->{ciscoSlaAuthOOCStartTime}) {
    $self->add_critical(
        sprintf "smart agent entered out of compliance %d days ago",
        $self->{ciscoSlaAuthOOCStartTimeDays});
  }
  my $label = "sla_remaining_days";
  $self->set_thresholds(metric => $label,
      warning => "7:", critical => "2:");
  $self->add_info(sprintf "authorization will expire in %d days",
      $self->{ciscoSlaAuthExpireTimeDays});
  $self->add_message($self->check_thresholds(metric => $label,
      value => $self->{ciscoSlaAuthExpireTimeDays}));
  $self->add_perfdata(label => $label,
      value => $self->{ciscoSlaAuthExpireTimeDays});
}

