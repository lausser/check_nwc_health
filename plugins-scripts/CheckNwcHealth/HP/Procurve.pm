package CheckNwcHealth::HP::Procurve;
our @ISA = qw(CheckNwcHealth::HP);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::HP::Procurve::Component::EnvironmentalSubsystem");
    if ($self->implements_mib("ENTITY-SENSOR-MIB")) {
      $self->{components}->{senvironmental_subsystem} = CheckNwcHealth::ENTITYSENSORMIB::Component::EnvironmentalSubsystem->new();
      @{$self->{components}->{senvironmental_subsystem}->{sensors}} = grep {
        # ENTITYSENSORMIB-sensoren fliegen raus, wenn sie vorher schon per HP-Mib gefunden wurden.
        my $sensor = $_;
        my $unique = 1;
        foreach (@{$self->{components}->{environmental_subsystem}->{components}->{sensor_subsystem}->{sensors}}) {
          if (exists $_->{entPhysicalIndex} and $sensor->{entPhysicalIndex} == $_->{entPhysicalIndex}) {
            # schleich de, du grippl, du elendicher!
            $unique = 0;
            last;
          }
        }
        $unique;
      } @{$self->{components}->{senvironmental_subsystem}->{sensors}};

      $self->{components}->{senvironmental_subsystem}->check();
      # vergleichen: entPhysicalIndex entity id mit hpSystemAirEntPhysicalIndex
      $self->{components}->{senvironmental_subsystem}->dump()
          if $self->opts->verbose >= 2;
    }
    $self->reduce_messages_short('environmental hardware working fine');
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::HP::Procurve::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::HP::Procurve::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

