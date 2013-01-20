package UPNP::AVM;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(UPNP);

sub init {
  my $self = shift;
  $self->{components} = {
      interface_subsystem => undef,
  };
  if ($self->{productname} =~ /7390/) {
    bless $self, 'UPNP::AVM::FritzBox7390';
    $self->debug('using UPNP::AVM::FritzBox7390');
  }
  $self->init();
}

