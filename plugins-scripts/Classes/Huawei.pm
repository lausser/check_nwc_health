package Classes::Huawei;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  my $sysobj = $self->get_snmp_object('MIB-2-MIB', 'sysObjectID', 0);
  if ($sysobj =~ /^\.*1\.3\.6\.1\.4\.1\.2011\.2\.239/) {
    bless $self, 'Classes::Huawei::CloudEngine';
    $self->debug('using Classes::Huawei::CloudEngine');
  }
  elsif ($sysobj =~ /^\.1\.3\.6\.1\.4\.1\.2011\.2\.23\./) {
    bless $self, 'Classes::Huawei::SSeries';
    $self->debug('using Classes::Huawei::SSeries');
  }
  if (ref($self) ne "Classes::Huawei") {
    $self->init();
  }
}

