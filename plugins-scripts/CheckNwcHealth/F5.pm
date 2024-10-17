package CheckNwcHealth::F5;
our @ISA = qw(CheckNwcHealth::Device);
use strict;


sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /Linux.*((el6.f5.x86_64)|(el5.1.0.f5app)) .*/i ||
      $self->{sysobjectid} =~ /1\.3\.6\.1\.4\.1\.3375\./) {
    $self->rebless("CheckNwcHealth::F5::F5BIGIP");
  } elsif ($self->implements_mib("F5-OS-SYSTEM-MIB")) {
    # $self->{sysobjectid} =~ /1\.3\.6\.1\.4\.1\.12276\.1\.3\.1\.
    $self->rebless("CheckNwcHealth::F5::Velos");
  }
  if (ref($self) ne "CheckNwcHealth::F5") {
    $self->init();
  }
}

