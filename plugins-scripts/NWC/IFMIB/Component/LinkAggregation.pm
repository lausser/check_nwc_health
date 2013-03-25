package NWC::IFMIB::Component::LinkAggregation;
our @ISA = qw(NWC::IFMIB);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    link_aggregations => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  my %params = @_;
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
        NWC::IFMIB::Component::InterfaceSubsystem->new();
  } else {
    #error, must have a name
  }
  if ($self->mode =~ /device::interfaces::aggregation::availability/) {
    $self->{num_if} = scalar(@{$self->{components}->{interface_subsystem}->{interfaces}});
    $self->{num_up_if} = scalar(grep { $_->{ifOperStatus} eq "up" } @{$self->{components}->{interface_subsystem}->{interfaces}});
    $self->{num_down_if} = $self->{num_if} - $self->{num_up_if};
    $self->{availability} = $self->{num_if} ? int(100 * $self->{num_up_if} / $self->{num_if}) : 0;
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking link aggregation');
  if (scalar(@{$self->{components}->{interface_subsystem}->{interfaces}}) == 0) {
    $self->add_message(UNKNOWN, 'no interfaces');
    return;
  }
  if ($self->mode =~ /device::interfaces::aggregation::availability/) {
    my $info = sprintf 'aggregation %s availability is %.2f%%',
        $self->{name},
        $self->{availability};
    $self->add_info($info);
    $self->set_thresholds(warning => 80, critical => 90);
    $self->add_message($self->check_thresholds($self->{availability}), $info);
    $self->add_perfdata(
        label => 'aggr_'.$self->{name}.'_availability',
        value => $self->{availability},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical},
    );
  }
}


