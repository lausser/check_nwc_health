package Classes::Cisco::CCM::Component::CmSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-CCM-MIB', [
      ['ccms', 'ccmTable', 'Classes::Cisco::CCM::Component::CmSubsystem::Cm'],
  ]);
}

sub check {
  my $self = shift;
  foreach (@{$self->{ccms}}) {
    $_->check();
  }
  if (! scalar(@{$self->{ccms}})) {
    $self->add_message(
        defined $self->opts->mitigation() ? $self->opts->mitigation() : 2,
        'local callmanager is down');
  }
}


package Classes::Cisco::CCM::Component::CmSubsystem::Cm;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub check {
  my $self = shift;
  $self->add_info(sprintf 'cm %s is %s',
      $self->{ccmName},
      $self->{ccmStatus});
  $self->add_message($self->{ccmStatus} eq 'up' ? OK : CRITICAL);
}

