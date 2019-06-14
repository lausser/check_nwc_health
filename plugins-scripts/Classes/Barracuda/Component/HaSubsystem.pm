package Classes::Barracuda::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::role/) {
    $self->get_snmp_tables('PHION-MIB', [
      ['services', 'serverServicesTable', 'Classes::Barracuda::Component::HaSubsystem::Service'],
    ]);
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'active');
    }
  }
}

sub check {
  my ($self) = @_;
  $self->SUPER::check();
  printf "info %s\n", $self->get_info();
  if (! grep { $_->{serverServiceName} eq "SE1FWEXT_FWEXT" }
      @{$self->{services}}) {
    $self->add_unknown("no service SE1FWEXT_FWEXT found");
  } else {
	  printf "troet\n";
	  }
}


package Classes::Barracuda::Component::HaSubsystem::Service;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::role/) {
    if ($self->{serverServiceName} eq "SE1FWEXT_FWEXT") {
      $self->add_info(sprintf "%s node, service %s is %s",
          $self->opts->role(), $self->{serverServiceName},
	  $self->{serverServiceState});
      if ($self->opts->role() eq "active") {
        if ($self->{serverServiceState} eq "started") {
	  $self->add_ok();
	} elsif ($self->{serverServiceState} eq "stopped") {
	  $self->add_warning();
	} elsif ($self->{serverServiceState} eq "blocked") {
	  $self->add_critical();
	} else {
	  $self->add_unknown();
	}
      } else {
        if ($self->{serverServiceState} eq "stopped") {
	  $self->add_ok();
	} elsif ($self->{serverServiceState} eq "started") {
	  $self->add_warning();
	} elsif ($self->{serverServiceState} eq "blocked") {
	  $self->add_critical();
	} else {
	  $self->add_unknown();
	}
      }
    }
  }
}
