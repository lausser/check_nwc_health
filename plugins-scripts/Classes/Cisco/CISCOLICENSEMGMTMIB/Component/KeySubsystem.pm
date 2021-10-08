package Classes::Cisco::CISCOLICENSEMGMTMIB::Component::KeySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects("CISCO-LICENSE-MGMT-MIB", qw(clmgmtLicenseDeviceInformation clmgmtLicenseInformation clmgmtLicenseConfiguration));
  $self->get_snmp_tables('CISCO-LICENSE-MGMT-MIB', [
      ['licenses', 'clmgmtLicenseInfoTable', 'Classes::Cisco::CISCOLICENSEMGMTMIB::Component::KeySubsystem::License'],
  ]);
}

sub check {
  my ($self) = @_;
  if (! $self->{licenses} eq "false") {
    $self->add_ok("licensing is not enabled");
  } else {
    $self->SUPER::check();
  }
}


package Classes::Cisco::CISCOLICENSEMGMTMIB::Component::KeySubsystem::License;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{clmgmtLicenseValidityPeriodRemainingHuman} = scalar localtime (time + $self->{clmgmtLicenseValidityPeriodRemaining});
  $self->{clmgmtLicenseValidityPeriodRemainingDays} =
      int($self->{clmgmtLicenseValidityPeriodRemaining} / (3600*24));
}

sub check {
  my ($self) = @_;
  #$self->{keyDaysUntilExpire} = int($self->{keySecondsUntilExpire} / 86400);
  $self->add_info(sprintf "feature %s license type is %s",
      $self->{clmgmtLicenseFeatureName},
      $self->{clmgmtLicenseType},
  );
  if ($self->{clmgmtLicenseType} =~ /^permanent/) {
    $self->add_ok();
  } else {
    my $label = lc "expiration_".(my $new = $self->{clmgmtLicenseFeatureName} =~ s/\s+//gr);
    $self->set_thresholds(metric => $label,
        warning => "7:", critical => "2:");
    $self->add_message($self->check_thresholds(metric => $label,
        value => $self->{clmgmtLicenseValidityPeriodRemainingDays}));
    $self->add_perfdata(label => $label,
        value => $self->{clmgmtLicenseValidityPeriodRemainingDays}
    );
  }
}
__END__
This object identifies type of license. Licenses may have validity period defined in terms of time duration that the license is valid for or it may be defined in terms of actual calendar dates. Subscription licenses are licenses that have validity period defined in terms of calendar dates. 
demo(1) - demo(evaluation license) license. 
extension(2) - Extension(expiring) license. 
gracePeriod(3) - Grace period license. 
permanent(4) - permanent license, the license has no expiry date. 
paidSubscription(5) - Paid subscription licenses are the licenses which are purchased by customers. These licenses have a start date and end date associated with them. 
evaluationSubscription(6)-Evaluation subscription licenses are the trial licenses. These licenses are node locked and it can be obtained only once for an UDI. They are valid based on calendar days. These licenses have a start date and an end date associated with them and are issued once per UDI. 
extensionSubscription(7)- Extension subscription licenses are similar to evaluation subscription licenses but these licenses are issued based on customer request. There are no restrictions on the number of licenses available for a UDI. 
evalRightToUse(8) - Evaluation Right to use (RTU) license. 
rightToUse(9) - Right to use (RTU) license. 
permanentRightToUse(10) ? Right To Use license right after it is configured and is valid for the lifetime of the product. This is a Right To Use license which is not in evaluation mode for a limited time.
