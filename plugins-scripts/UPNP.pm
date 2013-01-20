package UPNP;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(NWC::Device);

sub init {
  my $self = shift;
  $self->{components} = {
      interface_subsystem => undef,
  };
  $self->{serial} = 'unknown';
  $self->{product} = 'unknown';
  $self->{romversion} = 'unknown';
  if (eval "require SOAP::Lite") {
  } else {
    $self->add_message(CRITICAL,
        'could not find SOAP::Lite module');
  }
  if (! $self->check_messages()) {
    $self->{productname} = 'AVM Fritz 7390';
    if ($self->{productname} =~ /AVM/) {
      bless $self, 'UPNP::AVM';
      $self->debug('using UPNP::AVM');
    } elsif ($self->mode =~ /device::uptime/) {
      my $som = SOAP::Lite
          -> proxy('http://192.168.1.1:49000/upnp/control/WANCommonIFC1')
          -> uri('urn:schemas-upnp-org:service:WANIPConnection:1')
          -> GetStatusInfo();
      $self->{uptime} = $som->valueof("//GetStatusInfoResponse/NewUptime");
      $self->{uptime} /= 60;
      my $info = sprintf 'device is up since %d minutes', $self->{uptime};
      $self->add_info($info);
      $self->set_thresholds(warning => '15:', critical => '5:');
      $self->add_message($self->check_thresholds($self->{uptime}), $info);
      $self->add_perfdata(
          label => 'uptime',
          value => $self->{uptime},
          warning => $self->{warning},
          critical => $self->{critical},
      );
      my ($code, $message) = $self->check_messages(join => ', ', join_all => ' , ');
      $NWC::Device::plugin->nagios_exit($code, $message);
    }
    $self->init();
  }
}

