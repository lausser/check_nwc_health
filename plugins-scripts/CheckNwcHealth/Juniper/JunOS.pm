package CheckNwcHealth::Juniper::JunOS;
our @ISA = qw(CheckNwcHealth::Juniper);
use strict;

use constant trees => (
  '1.3.6.1.2.1',        # mib-2
  '1.3.6.1.2.1.105',
);

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::bgp/) {
    $self->analyze_and_check_bgp_subsystem("CheckNwcHealth::Juniper::JunOS::Component::BgpSubsystem");
  } else {
    $self->no_such_mode();
  }
}

