package Classes::F5::F5BIGIP;
our @ISA = qw(Classes::F5);
use strict;

sub init {
  my $self = shift;
  # gets 11.* and 9.*
  $self->{productversion} = $self->get_snmp_object('F5-BIGIP-SYSTEM-MIB', 'sysProductVersion');
  if (! defined $self->{productversion} ||
      $self->{productversion} !~ /^((9)|(10)|(11))/) {
    $self->{productversion} = "4";
  }
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::F5::F5BIGIP::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::F5::F5BIGIP::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::F5::F5BIGIP::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::lb/) {
    $self->analyze_and_check_ltm_subsystem();
  } else {
    $self->no_such_mode();
  }
}

sub analyze_ltm_subsystem {
  my $self = shift;
  $self->{components}->{ltm_subsystem} =
      Classes::F5::F5BIGIP::Component::LTMSubsystem->new('productversion' => $self->{productversion});
}

