package Classes::Barracuda::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::role/) {
    $self->get_snmp_tables('PHION-MIB', [
      ['services', 'serverServicesTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ]);
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'active');
    }
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::role/) {
  }
}
