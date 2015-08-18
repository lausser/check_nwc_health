package Classes::Alcatel::OmniAccess;
our @ISA = qw(Classes::Alcatel);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Alcatel::OmniAccess::Component::EnvironmentalSubsystem");
    # waere praktischer, aber in diesem fall muss alarmdreck ausgeputzt werden
    #$self->analyze_and_check_alarm_subsystem("Classes::ALARMMIB::Component::AlarmSubsystem");
    $self->{components}->{alarm_subsystem} = Classes::ALARMMIB::Component::AlarmSubsystem->new();
    @{$self->{components}->{alarm_subsystem}->{alarms}} = grep {
      # accesspoint down und so interface-zeugs interessiert hier nicht, dafuer
      # gibt's die *accesspoint*- und *interface*-modes
      $_->{alarmActiveDescription} =~ /(Temperature is out of range)|(Out of range voltage)|(failed)/ ? 1 : undef;
    } @{$self->{components}->{alarm_subsystem}->{alarms}};
    $self->{components}->{alarm_subsystem}->{stats}->[0]->{alarmActiveStatsActiveCurrent} = scalar(@{$self->{components}->{alarm_subsystem}->{alarms}});
    $self->check_alarm_subsystem();
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Alcatel::OmniAccess::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Alcatel::OmniAccess::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::wlan/) {
    $self->analyze_and_check_wlan_subsystem("Classes::Alcatel::OmniAccess::Component::WlanSubsystem");
  } elsif ($self->mode =~ /device::ha::/) {
    $self->analyze_and_check_ha_subsystem("Classes::Alcatel::OmniAccess::Component::HaSubsystem");
  } else {
    $self->no_such_mode();
  }
}

