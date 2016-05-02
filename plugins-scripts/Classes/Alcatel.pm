package Classes::Alcatel;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->{productname} =~ /AOS.*OAW/i) {
    bless $self, 'Classes::Alcatel::OmniAccess';
    $self->debug('using Classes::Alcatel::OmniAccess');
  }
  if ($self->mode =~ /device::vrrp/) {
    $self->analyze_and_check_vrrp_subsystem("Classes::VRRPMIB::Component::VRRPSubsystem");
  } elsif (ref($self) ne "Classes::Alcatel") {
    $self->init();
  }
}

