package CheckNwcHealth::PaloAlto;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::ENTITYSENSORMIB::Component::EnvironmentalSubsystem");
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem");
    # entity-state-mib gibts u.u. auch
    # The entStateTable will have entries for Line Cards, Fan Trays and Power supplies. Since these entities only apply to chassis systems, only PA-7000 series devices will support this MIB.
    # gibts aber erst, wenn einer die entwicklung zahlt. bis dahin ist es
    # mir scheissegal, wenn euch die firewalls abkacken, ihr freibiervisagen
  } elsif ($self->mode =~ /device::hardware::load/) {
    # CPU util on management plane
    # Utilization of CPUs on dataplane that are used for system functions
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::ha::/) {
    $self->analyze_and_check_ha_subsystem("CheckNwcHealth::PaloAlto::Component::HaSubsystem");
  } elsif ($self->mode =~ /device::lb::session/) {
    # it's not a load balancer, but session-usage is the best mode here
    $self->analyze_and_check_session_subsystem("CheckNwcHealth::PaloAlto::Component::SessionSubsystem");
  } else {
    $self->no_such_mode();
  }
}

sub pretty_sysdesc {
  my ($self, $sysDescr) = @_;
  my $sw_version = $self->get_snmp_object('PAN-COMMON-MIB', 'panSysSwVersion');
  my $hw_version = $self->get_snmp_object('PAN-COMMON-MIB', 'panSysHwVersion');
  return sprintf "%s, sw version %s, hw version: %s",
      $sysDescr, $sw_version, $hw_version;
}
