package Classes::Bluecat::AddressManager::Component::MgmtSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('BAM-SNMP-MIB', (qw(lastSuccessfulBackupTime)));
  $self->{lastSuccessfulBackupAge} = int((time - $self->{lastSuccessfulBackupTime}) / 3600);
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "last successful backup was %d hours ago (%s)",
      $self->{lastSuccessfulBackupAge},
      scalar localtime $self->{lastSuccessfulBackupTime}
  );
  $self->set_thresholds(metric => "backup_age",
      warning => 24*7,
      critical => 24*7*4,
  );
  $self->add_message($self->check_thresholds(metric => "backup_age",
      value => $self->{lastSuccessfulBackupAge}));
}
