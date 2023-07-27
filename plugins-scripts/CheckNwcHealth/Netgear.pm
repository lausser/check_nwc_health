package CheckNwcHealth::Netgear;
our @ISA = qw(CheckNwcHealth::Device);
use strict;


sub init {
  my ($self) = @_;
  # netgear does not publish mibs
  $self->no_such_mode();
}

sub pretty_sysdesc {
  my ($self, $sysDescr) = @_;
  if ($sysDescr =~ /GS\d+TP/) {
    return 'Netgear '.$sysDescr;
  }
}
