package CheckNwcHealth::TPLink;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->get_snmp_object('TPLINK-MIB', 'tpSysInfoDescription') && $self->get_snmp_object('TPLINK-MIB', 'tpSysInfoDescription') =~ /JetStream/i) {
    bless $self, 'CheckNwcHealth::TPLink';
    $self->debug('using CheckNwcHealth::TPLink');
  }
  if (ref($self) ne "CheckNwcHealth::TPLink") {
    $self->init();
  } else {
    if ($self->mode =~ /device::hardware::load/) {
      $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::TPLink::Component::CpuSubsystem");
    } elsif ($self->mode =~ /device::hardware::memory/) {
      $self->analyze_and_check_mem_subsystem("CheckNwcHealth::TPLink::Component::MemSubsystem");
    } else {
      $self->no_such_mode();
    }
  }
}
