package Classes::Alcatel::OmniAccess::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my $self = shift;
  if ($self->mode =~ /device::ha::role/) {
    $self->get_snmp_objects('WLSX-SYSTEMEXT-MIB', (qw(wlsxSysExtSwitchRole)));
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'master');
    }
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking ha');
  $self->add_info(sprintf 'ha role is %s', $self->{wlsxSysExtSwitchRole});
  if ($self->{wlsxSysExtSwitchRole} ne $self->opts->role()) {
    $self->add_warning();
    $self->add_warning(sprintf "expected role %s", $self->opts->role());
  } else {
    $self->add_ok();
  }
}

