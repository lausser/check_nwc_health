package CheckNwcHealth::Zpesystems;
our @ISA = qw(CheckNwcHealth::Device);
use strict;


# ZPE Systems devices (enterprise 1.3.6.1.4.1.42518) are detected in
# CheckNwcHealth::Device::classify() by sysDescr "Nodegrid - ..." or by
# their ZPE-PRODUCTS-MIB sysObjectID. Nodegrid appliances answer the
# Nodegrid-MIB (1.3.6.1.4.1.42518.4.2.1) and are reblessed into
# CheckNwcHealth::Zpesystems::NodeGrid. Other ZPE products (e.g. the
# ZSW-228 partner switches) have no model class yet and fall back to
# CheckNwcHealth::Generic via no_such_mode().

sub init {
  my ($self) = @_;
  if ($self->implements_mib('Nodegrid-MIB')) {
    $self->rebless('CheckNwcHealth::Zpesystems::NodeGrid');
  }
  if (ref($self) ne "CheckNwcHealth::Zpesystems") {
    $self->init();
  } else {
    $self->no_such_mode();
  }
}

