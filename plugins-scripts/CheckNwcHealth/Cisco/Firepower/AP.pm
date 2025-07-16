package CheckNwcHealth::Cisco::Firepower::AP;
our @ISA = qw(CheckNwcHealth::Cisco);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem");
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Cisco::CISCOENTITYALARMMIB::Component::AlarmSubsystem");
    $self->reduce_messages("hardware working fine");
  } elsif ($self->mode =~ /device::hardware::load/) {
    # CISCO-PROCESS-MIB ist nicht so toll, 18 Cpus, und jeder Fan
    # hat eine eigene Cpu.
    # $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Cisco::IOS::Component::CpuSubsystem");
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::UCDMIB::Component::LoadSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    # udc liefert mem_usage: 20.4970930075049
    # und memTotalReal: 65702956, hat demnach 64MB Speicher, realistisch
    #$self->analyze_and_check_cpu_subsystem("CheckNwcHealth::UCDMIB::Component::MemSubsystem");
    # Aber IOS bzw. CISCO-ENHANCED-MEMPOOL-MIB cempMemPoolTable liefert
    # mehrere Pools, z.T. viel groesser, virtuell. Ist vielleicht
    # aussagekraeftiger, auch wenn kuenftig so Heap-Zeug gewhitelistet
    # werden muss.
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Cisco::IOS::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}



