package Classes::DrayTek;
our @ISA = qw(Classes::Device);
use strict;


sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /Vigor/i) {
    bless $self, 'Classes::DrayTek::Vigor';
    $self->debug('using Classes::DrayTek::Vigor');
  }
  if (ref($self) ne "Classes::DrayTek") {
    $self->init();
  } else {
    $self->no_such_device();
  }
}

sub pretty_sysdesc {
  my ($self, $sysDescr) = @_;
  if ($sysDescr =~ /DrayTek.*Vigor(\d+).*(Version: .*?)[ ,]/) {
    return 'DrayTek Vigor '.$1.' '.$2;
  }
}

