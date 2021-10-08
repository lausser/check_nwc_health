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
  if ($self->{ciscoSlaEntitlementEnforceMode} =~ /(outOfCompliance|gracePeriodExpired|disabled)/) {
    $self->add_critical();
  } elsif ($self->{ciscoSlaEntitlementEnforceMode} =~ /(waiting|evaluationExpired|gracePeriod)/) {
    $self->add_warning();
  } else {
    $self->add_ok();
  }
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
  $self->add_info(sprintf "Registration status is %s", $self->{ciscoSlaRegistrationStatus});
  if ($self->{ciscoSlaRegistrationStatus} =~ /(notRegistered|registrationFailed)/ ) {
      $self->add_warning();
  }
  if ($self->{ciscoSlaRegisterSuccess} and
      $self->{ciscoSlaRegisterSuccess} ne "true" ) {
    $self->add_warning(sprintf "registration failed with %s", $self->{ciscoSlaRegisterFailureReason});
  }
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
  $self->{ciscoSlaAuthEvalPeriodLeftDays} =
      int(($self->{ciscoSlaAuthEvalPeriodLeft} - time) / (3600*24));
  $self->{ciscoSlaAuthEvalPeriodLeftDays} =
      $self->{ciscoSlaAuthEvalPeriodLeftDays} < 0 ?
      0 : $self->{ciscoSlaAuthEvalPeriodLeftDays};
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
  if ($self->{ciscoSlaAuthComplianceStatus} =~ /AUTHORIZED/) {
    # STRING: "AUTHORIZED"
    # STRING: "AUTHORIZED - RESERVED" scheint der beste Status von allen zu sein
    $self->add_ok();
  } else {
    $self->add_critical();
  }
  if ($self->{ciscoSlaAuthOOCStartTime}) {
    $self->add_critical(
        sprintf "smart agent entered out of compliance %d days ago",
        $self->{ciscoSlaAuthOOCStartTimeDays});
  }
  if ($self->{ciscoSlaAuthComplianceStatus} ne "AUTHORIZED - RESERVED") {
    my $label = "sla_remaining_days";
    $self->set_thresholds(metric => $label,
        warning => "7:", critical => "2:");
    $self->add_info(sprintf "authorization will expire in %d days",
        $self->{ciscoSlaAuthExpireTimeDays})
        if $self->{ciscoSlaAuthExpireTimeDays};
    $self->add_info("authorization has expired")
        if ! $self->{ciscoSlaAuthExpireTimeDays};
    $self->add_message($self->check_thresholds(metric => $label,
        value => $self->{ciscoSlaAuthExpireTimeDays}));
    $self->add_perfdata(label => $label,
        value => $self->{ciscoSlaAuthExpireTimeDays});
  }
  if ($self->{ciscoSlaAuthEvalPeriodInUse} and
      $self->{ciscoSlaAuthEvalPeriodInUse} eq "true") {
    my $label = "eval_remaining_days";
    $self->set_thresholds(metric => $label,
        warning => "7:", critical => "2:");
    $self->add_info(sprintf "evaluation will expire in %d days",
        $self->{ciscoSlaAuthEvalPeriodLeftDays})
        if $self->{ciscoSlaAuthEvalPeriodLeftDays};
    $self->add_info("evaluation has expired")
        if ! $self->{ciscoSlaAuthEvalPeriodLeftDays};
    $self->add_message($self->check_thresholds(metric => $label,
        value => $self->{ciscoSlaAuthEvalPeriodLeftDays}));
    $self->add_perfdata(label => $label,
        value => $self->{ciscoSlaAuthEvalPeriodLeftDays});
  }
}

