package Classes::IFMIB::Component::LinkAggregation;
our @ISA = qw(Classes::IFMIB);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  if ($self->opts->name) {
    my @ifs = split(",", $self->opts->name);
    $self->{name} = shift @ifs;
    if ($self->opts->regexp) {
      $self->opts->override_opt('name',
          sprintf "(%s)", join("|", map { sprintf "(%s)", $_ } @ifs));
    } else {
      $self->opts->override_opt('name',
          sprintf "(%s)", join("|", map { sprintf "(^%s\$)", $_ } @ifs));
      $self->opts->override_opt('regexp', 1);
    }
    $self->{components}->{interface_subsystem} =
        Classes::IFMIB::Component::InterfaceSubsystem->new();
  } else {
    #error, must have a name
  }
  if ($self->mode =~ /device::interfaces::aggregation::availability/) {
    $self->{num_if} = scalar(@{$self->{components}->{interface_subsystem}->{interfaces}});
    $self->{down_if} = [grep { $_->{ifOperStatus} eq "down" } @{$self->{components}->{interface_subsystem}->{interfaces}}];
    $self->{num_down_if} = scalar(@{$self->{down_if}});
    $self->{num_up_if} = $self->{num_if} - $self->{num_down_if};
    $self->{availability} = $self->{num_if} ? (100 * $self->{num_up_if} / $self->{num_if}) : 0;
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking link aggregation');
  if (scalar(@{$self->{components}->{interface_subsystem}->{interfaces}}) == 0) {
    $self->add_unknown('no interfaces');
    return;
  }
  if ($self->mode =~ /device::interfaces::aggregation::availability/) {
    my $down_info = scalar(@{$self->{down_if}}) ?
        sprintf " (down: %s)", join(", ", map { $_->{ifDescr} } @{$self->{down_if}}) : "";
    $self->add_info(sprintf 'aggregation %s availability is %.2f%% (%d of %d)%s',
        $self->{name},
        $self->{availability}, $self->{num_up_if}, $self->{num_if},
        $down_info);
    my $cavailability = $self->{num_if} ? (100 * 1 / $self->{num_if}) : 0;
    $cavailability = $cavailability == int($cavailability) ? $cavailability + 1: int($cavailability + 1.0);
    $self->set_thresholds(
        metric => 'aggr_'.$self->{name}.'_availability',
        warning => '100:',
        critical => $cavailability.':'
    );
    $self->add_message($self->check_thresholds(
        metric => 'aggr_'.$self->{name}.'_availability',
        value => $self->{availability}
    ));
    $self->add_perfdata(
        label => 'aggr_'.$self->{name}.'_availability',
        value => $self->{availability},
        uom => '%',
    );
  }
}


