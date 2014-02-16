package Classes::AVOS::Component::ConnectionSubsystem;
our @ISA = qw(Classes::AVOS);
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
  foreach (qw(avSlowICAPConnections)) {
    $self->{$_} = $self->get_snmp_object('BLUECOAT-AV-MIB', $_);
  }
}

sub check {
  my $self = shift;
  $self->add_info(sprintf '%d slow ICAP connections',
      $self->{avSlowICAPConnections});
  $self->set_thresholds(warning => 100, critical => 100);
  $self->add_message($self->check_thresholds($self->{avSlowICAPConnections}), $self->{info});
  $self->add_perfdata(
      label => 'slow_connections',
      value => $self->{avSlowICAPConnections},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[CONNECTIONS]\n";
  foreach (qw(avSlowICAPConnections)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


