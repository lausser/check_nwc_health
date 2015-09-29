package Classes::HH3C::Component::MemSubsystem;
our @ISA = qw(Classes::HH3C::Component::EntitySubsystem);
use strict;

sub init {
  my $self = shift;

  $self->get_entities('Classes::HH3C::Component::MemSubsystem::EntityState',
    sub { my $o = shift; $o->{entPhysicalClass} eq 'module' and $o->{entPhysicalName} =~ /board/i; } );

  foreach ($self->get_sub_table('HH3C-ENTITY-EXT-MIB', [ 'hh3cEntityExtMemAvgUsage' ])) {
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

package Classes::HH3C::Component::MemSubsystem::EntityState;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  my $id = shift;

  $self->add_info(sprintf 'Memory %s usage is %s%%',
      $id,
      $self->{hh3cEntityExtMemAvgUsage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{hh3cEntityExtMemAvgUsage}));
  $self->add_perfdata(
      label => 'memory_'.$id.'_usage',
      value => $self->{hh3cEntityExtMemAvgUsage},
      uom => '%',
  );
}
