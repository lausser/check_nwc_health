package CheckNwcHealth::DrayTek;
our @ISA = qw(CheckNwcHealth::Device);
use strict;


sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /Vigor/i) {
    bless $self, 'CheckNwcHealth::DrayTek::Vigor';
    $self->debug('using CheckNwcHealth::DrayTek::Vigor');
  }
  if (ref($self) ne "CheckNwcHealth::DrayTek") {
    $self->init();
  } else {
    $self->no_such_model();
  }
}

sub pretty_sysdesc {
  my ($self, $sysDescr) = @_;
  if ($sysDescr =~ /DrayTek.*Vigor(\d+).*(Version: .*?)[ ,]/) {
    return 'DrayTek Vigor '.$1.' '.$2;
  }
}

