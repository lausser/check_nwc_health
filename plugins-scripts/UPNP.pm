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
    require XML::LibXML;
  } else {
    $self->add_message(CRITICAL,
        'could not find SOAP::Lite module');
  }
  if (! $self->check_messages()) {
    eval {
      my $igddesc = sprintf "http://%s:%s/igddesc.xml",
          $self->opts->hostname, $self->opts->port;
      my $parser = XML::LibXML->new();
      my $doc = $parser->parse_file($igddesc);
      my $root = $doc->documentElement();
      my $xpc = XML::LibXML::XPathContext->new( $root );
      $xpc->registerNs('n', 'urn:schemas-upnp-org:device-1-0');
      $self->{productname} = $xpc->findvalue('(//n:device)[position()=1]/n:friendlyName' );
    };
    if ($@) {
      $self->add_message(CRITICAL, $@);
    }
  }
  if (! $self->check_messages()) {
    if ($self->mode =~ /device::uptime/) {
      my $som = SOAP::Lite
          -> proxy(sprintf 'http://%s:%s/upnp/control/WANCommonIFC1',
              $self->opts->hostname, $self->opts->port)
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
    } elsif ($self->{productname} =~ /Fritz/i) {
      bless $self, 'UPNP::AVM';
      $self->debug('using UPNP::AVM');
    } else {
      $self->no_such_mode();
    }
    $self->init();
  }
}

