package Classes::DrayTek::Vigor::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use Data::Dumper;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('ADSL-LINE-MIB', [
      ['lines', 'adslAturPhysTable', 'Classes::DrayTek::Vigor::Component::AdslLine'],
  ]);
}


package Classes::DrayTek::Vigor::Component::AdslLine;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  if ($self->{adslAturCurrStatus}) {
    chomp $self->{adslAturCurrStatus};
    $self->{adslAturCurrStatus} =~ s/\x00+$//;
  }
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'adsl line %s has status %s', 
      $self->{flat_indices}, $self->{adslAturCurrStatus});
  if ($self->{adslAturCurrStatus} ne "SHOWTIME") {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}

