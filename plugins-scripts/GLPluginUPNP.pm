package GLPlugin::UPNP;
our @ISA = qw(GLPlugin);

use strict;
use File::Basename;
use Digest::MD5 qw(md5_hex);
use AutoLoader;
our $AUTOLOAD;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

{
  our $mode = undef;
  our $plugin = undef;
  our $blacklist = undef;
  our $session = undef;
  our $rawdata = {};
  our $info = [];
  our $extendedinfo = [];
  our $summary = [];
  our $oidtrace = [];
  our $uptime = 0;
}

sub init {
  my $self = shift;
  if ($self->mode =~ /device::walk/) {
  } elsif ($self->mode =~ /device::uptime/) {
    my $info = sprintf 'device is up since %s',
        $self->human_timeticks($self->{uptime});
    $self->add_info($info);
    $self->set_thresholds(warning => '15:', critical => '5:');
    $self->add_message($self->check_thresholds($self->{uptime}), $info);
    $self->add_perfdata(
        label => 'uptime',
        value => $self->{uptime} / 60,
        warning => $self->{warning},
        critical => $self->{critical},
    );
    my ($code, $message) = $self->check_messages(join => ', ', join_all => ', ');
    $GLPlugin::plugin->nagios_exit($code, $message);
  }
}

sub check_upnp_and_model {
  my $self = shift;
  if (eval "require SOAP::Lite") {
    require XML::LibXML;
  } else {
    $self->add_critical('could not find SOAP::Lite module');
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
      $self->{productname} = $xpc->findvalue('(//n:device)[position()=1]/n:modelName' );
    };
    if ($@) {
      $self->add_critical($@);
    }
  }
  if (! $self->check_messages()) {
    eval {
      my $som = SOAP::Lite
          -> proxy(sprintf 'http://%s:%s/upnp/control/WANIPConn1',
              $self->opts->hostname, $self->opts->port)
          -> uri('urn:schemas-upnp-org:service:WANIPConnection:1')
          -> GetStatusInfo();
      $self->{uptime} = $som->valueof("//GetStatusInfoResponse/NewUptime");
      $self->{uptime} /= 1.0;
    };
    if ($@) {
      $self->add_critical("could not get uptime: ".$@);
    }
  }
}

sub create_statefile {
  my $self = shift;
  my %params = @_;
  my $extension = "";
  $extension .= $params{name} ? '_'.$params{name} : '';
  if ($self->opts->community) {
    $extension .= md5_hex($self->opts->community);
  }
  $extension =~ s/\//_/g;
  $extension =~ s/\(/_/g;
  $extension =~ s/\)/_/g;
  $extension =~ s/\*/_/g;
  $extension =~ s/\s/_/g;
  return sprintf "%s/%s_%s%s", $self->statefilesdir(),
      $self->opts->hostname, $self->opts->mode, lc $extension;
}

