package Classes::Foundry::Component::MemSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('FOUNDRY-SN-AGENT-MIB', (qw(
      snAgGblDynMemUtil snAgGblDynMemTotal snAgGblDynMemFree)));
}

sub check {
  my $self = shift;
  $self->add_info('checking memory');
  if (defined $self->{snAgGblDynMemUtil}) {
    $self->add_info(sprintf 'memory usage is %.2f%%',
        $self->{snAgGblDynMemUtil});
    $self->set_thresholds(warning => 80, critical => 99);
    $self->add_message($self->check_thresholds($self->{snAgGblDynMemUtil}));
    $self->add_perfdata(
        label => 'memory_usage',
        value => $self->{snAgGblDynMemUtil},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical}
    );
  } else {
    $self->add_unknown('cannot aquire momory usage');
  }
}

