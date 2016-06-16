package Classes::UCDMIB::Component::LoadSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  my %params = @_;
  my $type = 0;
  $self->get_snmp_tables('UCD-SNMP-MIB', [
      ['loads', 'laTable', 'Classes::UCDMIB::Component::LoadSubsystem::Load'],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking loads');
  foreach (@{$self->{loads}}) {
    $_->check();
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{loads}}) {
    $_->dump();
  }
}


package Classes::UCDMIB::Component::LoadSubsystem::Load;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use Data::Dumper;

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->set_thresholds(
      metric => lc $self->{laNames},
      warning => $self->{laConfig},
      critical => $self->{laConfig}
  );
  $self->add_info(
      sprintf '%s is %.2f%s',
      lc $self->{laNames}, $self->{laLoad},
      $self->{'laErrorFlag'} eq 'error'
          ? sprintf ' (%s)', $self->{'laErrMessage'}
          : ''
  );
  if ($self->{'laErrorFlag'} eq 'error') {
    $self->add_critical();
  } else {
    $self->add_message($self->check_thresholds(
        metric => lc $self->{laNames},
        value => $self->{laLoad}));
  }
  $self->add_perfdata(
      label => lc $self->{laNames},
      value => $self->{laLoad},
  );
}

