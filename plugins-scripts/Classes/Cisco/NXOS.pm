package Classes::Cisco::NXOS;
our @ISA = qw(Classes::Cisco);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Cisco::NXOS::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::cisco::fex::watch/) {
    $self->analyze_fex_subsystem();
    $self->check_fex_subsystem();
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Cisco::NXOS::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Cisco::NXOS::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::hsrp/) {
    $self->analyze_and_check_hsrp_subsystem("Classes::HSRP::Component::HSRPSubsystem");
  } else {
    $self->no_such_mode();
  }
}

sub analyze_fex_subsystem {
  my $self = shift;
  $self->{components}->{fex_subsystem} = Classes::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem->new();
  @{$self->{fexes}} = grep {
      $_->{entPhysicalName} =~ /^fex.*chassis$/i;
  } map {
      $_->{entPhysicalName} ||= $_->{entPhysicalDescr}; $_;
  } grep { 
      $_->{entPhysicalClass} eq "chassis"
  } @{$self->{components}->{fex_subsystem}->{entities}};
}

sub check_fex_subsystem {
  my $self = shift;
  $self->add_info('counting fexes');
  $self->{numOfFexes} = scalar (@{$self->{fexes}});
  $self->{fexNameList} = [map { $_->{entPhysicalName} } @{$self->{fexes}}];
  if (scalar (@{$self->{fexes}}) == 0) {
    $self->add_unknown('no FEXes found');
  } else {
    $self->opts->override_opt('lookback', 1800) if ! $self->opts->lookback;
    $self->valdiff({name => $self->{name}, lastarray => 1},
        qw(fexNameList numOfFexes));
    if (scalar(@{$self->{delta_found_fexNameList}}) > 0) {
      $self->add_warning(sprintf '%d new FEX(es) (%s)',
          scalar(@{$self->{delta_found_fexNameList}}),
          join(", ", @{$self->{delta_found_fexNameList}}));
    }
    if (scalar(@{$self->{delta_lost_fexNameList}}) > 0) {
      $self->add_critical(sprintf '%d FEXes missing (%s)',
          scalar(@{$self->{delta_lost_fexNameList}}),
          join(", ", @{$self->{delta_lost_fexNameList}}));
    }
    $self->add_ok(sprintf 'found %d FEXes', scalar (@{$self->{fexes}}));
    $self->add_perfdata(
        label => 'num_fexes',
        value => $self->{numOfFexes},
    );
  }
}

