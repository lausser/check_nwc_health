package Classes::Bluecoat;
our @ISA = qw(Classes::Device);
use strict;


sub init {
  my $self = shift;
  if ($self->{productname} =~ /Blue.*Coat.*(SG\d+|SGOS)/i) {
    # product ProxySG  Blue Coat SG600
    # iso.3.6.1.4.1.3417.2.11.1.3.0 = STRING: "Version: SGOS 5.5.8.1, Release id: 78642 Proxy Edition"
    bless $self, 'Classes::SGOS';
    $self->debug('using Classes::SGOS');
  } elsif ($self->{productname} =~ /Blue.*Coat.*AV\d+/i) {
    # product Blue Coat AV510 Series, ProxyAV Version: 3.5.1.1, Release id: 111017
    bless $self, 'Classes::AVOS';
    $self->debug('using Classes::AVOS');
  }
  if (ref($self) ne "Classes::Bluecoat") {
    $self->init();
  } else {
    $self->no_such_mode();
  }
}

