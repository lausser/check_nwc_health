package Classes::HH3C::Component::CpuSubsystem;
our @ISA = qw(Classes::HH3C::Component::EntitySubsystem);
use strict;

sub init {
  my $self = shift;

  $self->get_entities('Classes::HH3C::Component::CpuSubsystem::EntityState',
    sub { my $o = shift; $o->{entPhysicalClass} eq 'module' and $o->{entPhysicalName} =~ /board/i; } );

  foreach ($self->get_sub_table('HH3C-ENTITY-EXT-MIB', [ 'hh3cEntityExtCpuAvgUsage' ])) {
    push @{$self->{entityext}}, $_;
  }

  $self->join_table($self->{entities}, $self->{entityext});
}

sub check {
  my $self = shift;

  $self->add_info('checking board');
  if (scalar (@{$self->{entities}}) == 0) {
    $self->add_unknown('no board found');
  } else {
    my $i = 0;
    foreach (@{$self->{entities}}) {
      $_->check($i++);
    }
  }
}

package Classes::HH3C::Component::CpuSubsystem::EntityState;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  my $id = shift;

  $self->add_info(sprintf 'CPU %s usage is %s%%',
      $id,
      $self->{hh3cEntityExtCpuAvgUsage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{hh3cEntityExtCpuAvgUsage}));
  $self->add_perfdata(
      label => 'cpu_'.$id.'_usage',
      value => $self->{hh3cEntityExtCpuAvgUsage},
      uom => '%',
  );
}
