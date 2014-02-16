package Classes::CheckPoint::Firewall1::Component::FwSubsystem;
our @ISA = qw(Classes::CheckPoint::Firewall1);
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
  $self->{fwModuleState} = $self->get_snmp_object('CHECKPOINT-MIB', 'fwModuleState');
  $self->{fwPolicyName} = $self->get_snmp_object('CHECKPOINT-MIB', 'fwPolicyName');
  if ($self->mode =~ /device::fw::policy::installed/) {
  } elsif ($self->mode =~ /device::fw::policy::connections/) {
    $self->{fwNumConn} = $self->get_snmp_object('CHECKPOINT-MIB', 'fwNumConn');
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking fw module');
  if ($self->{fwModuleState} ne 'Installed') {
    $self->add_message(CRITICAL,
        sprintf 'fw module is %s', $self->{fwPolicyName});
  } elsif ($self->mode =~ /device::fw::policy::installed/) {
    if ($self->{fwPolicyName} eq $self->opts->name()) {
      $self->add_message(OK,
        sprintf 'fw policy is %s', $self->{fwPolicyName});
    } else {
      $self->add_message(CRITICAL,
          sprintf 'fw policy is %s, expected %s',
              $self->{fwPolicyName}, $self->opts->name());
    }
  } elsif ($self->mode =~ /device::fw::policy::connections/) {
    $self->set_thresholds(warning => 20000, critical => 23000);
    $self->add_message($self->check_thresholds($self->{fwNumConn}),
        sprintf 'policy %s has %s open connections',
            $self->{fwPolicyName}, $self->{fwNumConn});
    $self->add_perfdata(
        label => 'fw_policy_numconn',
        value => $self->{fwNumConn},
    );
  }
}

sub dump {
  my $self = shift;
  printf "[FW]\n";
}

