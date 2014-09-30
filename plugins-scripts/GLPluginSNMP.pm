package GLPlugin::SNMP;
our @ISA = qw(GLPlugin);

use strict;
use File::Basename;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use AutoLoader;
our $AUTOLOAD;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

{
  our $mode = undef;
  our $plugin = undef;
  our $blacklist = undef;
  our $session = undef;
  our $rawdata = {};
  our $tablecache = {};
  our $info = [];
  our $extendedinfo = [];
  our $summary = [];
  our $oidtrace = [];
  our $uptime = 0;
}

sub v2tov3 {
  my $self = shift;
  if ($self->opts->community && $self->opts->community =~ /^snmpv3(.)(.+)/) {
    my $separator = $1;
    my ($authprotocol, $authpassword, $privprotocol, $privpassword,
        $username, $contextengineid, $contextname) = split(/$separator/, $2);
    $self->override_opt('authprotocol', $authprotocol) 
        if defined($authprotocol) && $authprotocol;
    $self->override_opt('authpassword', $authpassword) 
        if defined($authpassword) && $authpassword;
    $self->override_opt('privprotocol', $privprotocol) 
        if defined($privprotocol) && $privprotocol;
    $self->override_opt('privpassword', $privpassword) 
        if defined($privpassword) && $privpassword;
    $self->override_opt('username', $username) 
        if defined($username) && $username;
    $self->override_opt('contextengineid', $contextengineid) 
        if defined($contextengineid) && $contextengineid;
    $self->override_opt('contextname', $contextname) 
        if defined($contextname) && $contextname;
    $self->override_opt('protocol', '3') ;
  }
  if (($self->opts->authpassword || $self->opts->authprotocol ||
      $self->opts->privpassword || $self->opts->privprotocol) && 
      ! $self->opts->protocol eq '3') {
    $self->override_opt('protocol', '3') ;
  }
}

sub add_snmp_args {
  my $self = shift;
  $self->add_arg(
      spec => 'port=i',
      help => '--port
     The SNMP port to use (default: 161)',
      required => 0,
      default => 161,
  );
  $self->add_arg(
      spec => 'domain=s',
      help => '--domain
     The transport domain to use (default: udp/ipv4, other possible values: udp6, udp/ipv6, tcp, tcp4, tcp/ipv4, tcp6, tcp/ipv6)',
      required => 0,
      default => 'udp',
  );
  $self->add_arg(
      spec => 'protocol|P=s',
      help => '--protocol
     The SNMP protocol to use (default: 2c, other possibilities: 1,3)',
      required => 0,
      default => '2c',
  );
  $self->add_arg(
      spec => 'community|C=s',
      help => '--community
     SNMP community of the server (SNMP v1/2 only)',
      required => 0,
      default => 'public',
  );
  $self->add_arg(
      spec => 'username:s',
      help => '--username
     The securityName for the USM security model (SNMPv3 only)',
      required => 0,
  );
  $self->add_arg(
      spec => 'authpassword:s',
      help => '--authpassword
     The authentication password for SNMPv3',
      required => 0,
  );
  $self->add_arg(
      spec => 'authprotocol:s',
      help => '--authprotocol
     The authentication protocol for SNMPv3 (md5|sha)',
      required => 0,
  );
  $self->add_arg(
      spec => 'privpassword:s',
      help => '--privpassword
     The password for authPriv security level',
      required => 0,
  );
  $self->add_arg(
      spec => 'privprotocol=s',
      help => '--privprotocol
     The private protocol for SNMPv3 (des|aes|aes128|3des|3desde)',
      required => 0,
  );
  $self->add_arg(
      spec => 'contextengineid=s',
      help => '--contextengineid
     The context engine id for SNMPv3 (10 to 64 hex characters)',
      required => 0,
  );
  $self->add_arg(
      spec => 'contextname=s',
      help => '--contextname
     The context name for SNMPv3 (empty represents the "default" context)',
      required => 0,
  );
}

sub validate_args {
  my $self = shift;
  $self->SUPER::validate_args();
  if ($self->opts->mode eq 'walk') {
    if ($self->opts->snmpwalk && $self->opts->hostname) {
      if ($self->check_messages == CRITICAL) {
        # gemecker vom super-validierer, der sicherstellt, dass die datei
        # snmpwalk existiert. in diesem fall wird sie aber erst neu angelegt,
        # also schnauze.
        my ($code, $message) = $self->check_messages;
        if ($message eq sprintf("file %s not found", $self->opts->snmpwalk)) {
          $self->clear_critical;
        }
      }
      # snmp agent wird abgefragt, die ergebnisse landen in einem file
      # opts->snmpwalk ist der filename. da sich die ganzen get_snmp_table/object-aufrufe
      # an das walkfile statt an den agenten halten wuerden, muss opts->snmpwalk geloescht
      # werden. stattdessen wird opts->snmpdump als traeger des dateinamens mitgegeben.
      # nur sinnvoll mit mode=walk
      $self->create_opt('snmpdump');
      $self->override_opt('snmpdump', $self->opts->snmpwalk);
      $self->override_opt('snmpwalk', undef);
    } elsif (! $self->opts->snmpwalk && $self->opts->hostname && $self->opts->mode eq 'walk') {   
      # snmp agent wird abgefragt, die ergebnisse landen in einem file, dessen name
      # nicht vorgegeben ist
      $self->create_opt('snmpdump');
    }
  } else {    
    if ($self->opts->snmpwalk && ! $self->opts->hostname) {
      # normaler aufruf, mode != walk, oid-quelle ist eine datei
      $self->override_opt('hostname', 'snmpwalk.file'.md5_hex($self->opts->snmpwalk))
    } elsif ($self->opts->snmpwalk && $self->opts->hostname) {
      # snmpwalk hat vorrang
      $self->override_opt('hostname', undef);
    }
  }
}

sub init {
  my $self = shift;
  if ($self->mode =~ /device::walk/) {
    my @trees = ();
    my $name = $GLPlugin::pluginname;
    $name =~ s/.*\///g;
    $name = sprintf "/tmp/snmpwalk_%s_%s", $name, $self->opts->hostname;
    if ($self->opts->oids) {
      # create pid filename
      # already running?;x
      @trees = split(",", $self->opts->oids);

    } elsif ($self->can("trees")) {
      @trees = $self->trees;
      push(@trees, "1.3.6.1.2.1.1");
    } else {
      @trees = ("1.3.6.1.2.1", "1.3.6.1.4.1");
    }
    if ($self->opts->snmpdump) {
      $name = $self->opts->snmpdump;
    }
    if (defined $self->opts->offline) {
      $self->{pidfile} = $name.".pid";
      if (! $self->check_pidfile()) {
        $self->debug("Exiting because another walk is already running");
        printf STDERR "Exiting because another walk is already running\n";
        exit 3;
      }
      $self->write_pidfile();
      my $timedout = 0;
      my $snmpwalkpid = 0;
      $SIG{'ALRM'} = sub {
        $timedout = 1;
        printf "UNKNOWN - %s timed out after %d seconds\n",
            $GLPlugin::plugin->{name}, $self->opts->timeout;
        kill 9, $snmpwalkpid;
      };
      alarm($self->opts->timeout);
      unlink $name.".partial";
      while (! $timedout && @trees) {
        my $tree = shift @trees;
        $SIG{CHLD} = 'IGNORE';
        my $cmd = sprintf "snmpwalk -ObentU -v%s -c %s %s %s >> %s", 
            $self->opts->protocol,
            $self->opts->community,
            $self->opts->hostname,
            $tree, $name.".partial";
        $self->debug($cmd);
        $snmpwalkpid = fork;
        if (not $snmpwalkpid) {
          exec($cmd);
        } else {
          wait();
        }
      }
      rename $name.".partial", $name if ! $timedout;
      -f $self->{pidfile} && unlink $self->{pidfile};
      if ($timedout) {
        printf "CRITICAL - timeout. There are still %d snmpwalks left\n", scalar(@trees);
        exit 3;
      } else {
        printf "OK - all requested oids are in %s\n", $name;
      }
    } else {
      printf "rm -f %s\n", $name;
      foreach (@trees) {
        printf "snmpwalk -ObentU -v%s -c %s %s %s >> %s\n", 
            $self->opts->protocol,
            $self->opts->community,
            $self->opts->hostname,
            $_, $name;
      }
    }
    exit 0;
  } elsif ($self->mode =~ /device::uptime/) {
    $self->add_info(sprintf 'device is up since %s',
        $self->human_timeticks($self->{uptime}));
    $self->set_thresholds(warning => '15:', critical => '5:');
    $self->add_message($self->check_thresholds($self->{uptime} / 60));
    $self->add_perfdata(
        label => 'uptime',
        value => $self->{uptime} / 60,
        places => 0,
    );
    my ($code, $message) = $self->check_messages(join => ', ', join_all => ', ');
    $GLPlugin::plugin->nagios_exit($code, $message);
  } elsif ($self->mode =~ /device::supportedmibs/) {
    our $mibdepot = [];
    my $unknowns = {};
    my @outputlist = ();
    %{$unknowns} = %{$self->rawdata};
    if ($self->opts->name && -f $self->opts->name) {
      eval { require $self->opts->name };
      $self->add_critical($@) if $@;
    } elsif ($self->opts->name && ! -f $self->opts->name) {
      $self->add_unknown("where is --name mibdepotfile?");
    }
    push(@{$mibdepot}, ['1.3.6.1.2.1.60', 'ietf', 'v2', 'ACCOUNTING-CONTROL-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.238', 'ietf', 'v2', 'ADSL2-LINE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.238.2', 'ietf', 'v2', 'ADSL2-LINE-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.94.3', 'ietf', 'v2', 'ADSL-LINE-EXT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.94', 'ietf', 'v2', 'ADSL-LINE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.94.2', 'ietf', 'v2', 'ADSL-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.74', 'ietf', 'v2', 'AGENTX-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.3.123', 'ietf', 'v2', 'AGGREGATE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.118', 'ietf', 'v2', 'ALARM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16.23', 'ietf', 'v2', 'APM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.34.3', 'ietf', 'v2', 'APPC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.13.1', 'ietf', 'v1', 'APPLETALK-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.27', 'ietf', 'v2', 'APPLICATION-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.62', 'ietf', 'v2', 'APPLICATION-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.34.5', 'ietf', 'v2', 'APPN-DLUR-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.34.4', 'ietf', 'v2', 'APPN-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.34.4', 'ietf', 'v2', 'APPN-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.34.4.0', 'ietf', 'v2', 'APPN-TRAP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.49', 'ietf', 'v2', 'APS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.117', 'ietf', 'v2', 'ARC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.37.1.14', 'ietf', 'v2', 'ATM2-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.59', 'ietf', 'v2', 'ATM-ACCOUNTING-INFORMATION-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.37', 'ietf', 'v2', 'ATM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.37', 'ietf', 'v2', 'ATM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.37.3', 'ietf', 'v2', 'ATM-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.15', 'ietf', 'v2', 'BGP4-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.15', 'ietf', 'v2', 'BGP4-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.3.122', 'ietf', 'v2', 'BLDG-HVAC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.17.1', 'ietf', 'v1', 'BRIDGE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.17', 'ietf', 'v2', 'BRIDGE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.19', 'ietf', 'v2', 'CHARACTER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.94', 'ietf', 'v2', 'CIRCUIT-IF-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.3.1.1', 'ietf', 'v1', 'CLNS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.3.1.1', 'ietf', 'v1', 'CLNS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.132', 'ietf', 'v2', 'COFFEE-POT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.89', 'ietf', 'v2', 'COPS-CLIENT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.18.1', 'ietf', 'v1', 'DECNET-PHIV-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.21', 'ietf', 'v2', 'DIAL-CONTROL-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.108', 'ietf', 'v2', 'DIFFSERV-CONFIG-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.97', 'ietf', 'v2', 'DIFFSERV-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.66', 'ietf', 'v2', 'DIRECTORY-SERVER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.88', 'ietf', 'v2', 'DISMAN-EVENT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.90', 'ietf', 'v2', 'DISMAN-EXPRESSION-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.82', 'ietf', 'v2', 'DISMAN-NSLOOKUP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.82', 'ietf', 'v2', 'DISMAN-NSLOOKUP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.80', 'ietf', 'v2', 'DISMAN-PING-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.80', 'ietf', 'v2', 'DISMAN-PING-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.63', 'ietf', 'v2', 'DISMAN-SCHEDULE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.63', 'ietf', 'v2', 'DISMAN-SCHEDULE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.64', 'ietf', 'v2', 'DISMAN-SCRIPT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.64', 'ietf', 'v2', 'DISMAN-SCRIPT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.81', 'ietf', 'v2', 'DISMAN-TRACEROUTE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.81', 'ietf', 'v2', 'DISMAN-TRACEROUTE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.46', 'ietf', 'v2', 'DLSW-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.32.2', 'ietf', 'v2', 'DNS-RESOLVER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.32.1', 'ietf', 'v2', 'DNS-SERVER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.127.5', 'ietf', 'v2', 'DOCS-BPI-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.69', 'ietf', 'v2', 'DOCS-CABLE-DEVICE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.69', 'ietf', 'v2', 'DOCS-CABLE-DEVICE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.126', 'ietf', 'v2', 'DOCS-IETF-BPI2-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.132', 'ietf', 'v2', 'DOCS-IETF-CABLE-DEVICE-NOTIFICATION-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.127', 'ietf', 'v2', 'DOCS-IETF-QOS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.125', 'ietf', 'v2', 'DOCS-IETF-SUBMGT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.127', 'ietf', 'v2', 'DOCS-IF-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.127', 'ietf', 'v2', 'DOCS-IF-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.45', 'ietf', 'v2', 'DOT12-IF-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.53', 'ietf', 'v2', 'DOT12-RPTR-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.155', 'ietf', 'v2', 'DOT3-EPON-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.158', 'ietf', 'v2', 'DOT3-OAM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.4.1.2.2.1.1', 'ietf', 'v1', 'DPI20-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.82', 'ietf', 'v2', 'DS0BUNDLE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.81', 'ietf', 'v2', 'DS0-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.18', 'ietf', 'v2', 'DS1-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.18', 'ietf', 'v2', 'DS1-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.18', 'ietf', 'v2', 'DS1-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.30', 'ietf', 'v2', 'DS3-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.30', 'ietf', 'v2', 'DS3-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.29', 'ietf', 'v2', 'DSA-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16.26', 'ietf', 'v2', 'DSMON-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.34.7', 'ietf', 'v2', 'EBN-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.167', 'ietf', 'v2', 'EFM-CU-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.47', 'ietf', 'v2', 'ENTITY-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.47', 'ietf', 'v2', 'ENTITY-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.47', 'ietf', 'v2', 'ENTITY-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.99', 'ietf', 'v2', 'ENTITY-SENSOR-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.131', 'ietf', 'v2', 'ENTITY-STATE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.130', 'ietf', 'v2', 'ENTITY-STATE-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.70', 'ietf', 'v2', 'ETHER-CHIPSET-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.7', 'ietf', 'v1', 'EtherLike-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.7', 'ietf', 'v1', 'EtherLike-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.35', 'ietf', 'v2', 'EtherLike-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.35', 'ietf', 'v2', 'EtherLike-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.35', 'ietf', 'v2', 'EtherLike-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.35', 'ietf', 'v2', 'EtherLike-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.224', 'ietf', 'v2', 'FCIP-MGMT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.56', 'ietf', 'v2', 'FC-MGMT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.15.73.1', 'ietf', 'v1', 'FDDI-SMT73-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.75', 'ietf', 'v2', 'FIBRE-CHANNEL-FE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.111', 'ietf', 'v2', 'Finisher-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.40', 'ietf', 'v2', 'FLOW-METER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.40', 'ietf', 'v2', 'FLOW-METER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.32', 'ietf', 'v2', 'FRAME-RELAY-DTE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.86', 'ietf', 'v2', 'FR-ATM-PVC-SERVICE-IWF-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.47', 'ietf', 'v2', 'FR-MFR-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.44', 'ietf', 'v2', 'FRNETSERV-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.44', 'ietf', 'v2', 'FRNETSERV-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.44', 'ietf', 'v2', 'FRNETSERV-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.95', 'ietf', 'v2', 'FRSLD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.16', 'ietf', 'v2', 'GMPLS-LABEL-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.15', 'ietf', 'v2', 'GMPLS-LSR-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.12', 'ietf', 'v2', 'GMPLS-TC-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.13', 'ietf', 'v2', 'GMPLS-TE-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.98', 'ietf', 'v2', 'GSMP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16.29', 'ietf', 'v2', 'HC-ALARM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.107', 'ietf', 'v2', 'HC-PerfHist-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16.20.5', 'ietf', 'v2', 'HC-RMON-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.25.1', 'ietf', 'v1', 'HOST-RESOURCES-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.25.7.1', 'ietf', 'v2', 'HOST-RESOURCES-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.34.6.1.5', 'ietf', 'v2', 'HPR-IP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.34.6', 'ietf', 'v2', 'HPR-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.106', 'ietf', 'v2', 'IANA-CHARSET-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.110', 'ietf', 'v2', 'IANA-FINISHER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.152', 'ietf', 'v2', 'IANA-GMPLS-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.30', 'ietf', 'v2', 'IANAifType-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.128', 'ietf', 'v2', 'IANA-IPPM-METRICS-REGISTRY-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.119', 'ietf', 'v2', 'IANA-ITU-ALARM-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.154', 'ietf', 'v2', 'IANA-MAU-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.109', 'ietf', 'v2', 'IANA-PRINTER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.4.1.2.6.2.13.1.1', 'ietf', 'v1', 'IBM-6611-APPN-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.166', 'ietf', 'v2', 'IF-CAP-STACK-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.230', 'ietf', 'v2', 'IFCP-MGMT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.77', 'ietf', 'v2', 'IF-INVERTED-STACK-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.31', 'ietf', 'v2', 'IF-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.31', 'ietf', 'v2', 'IF-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.31', 'ietf', 'v2', 'IF-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.85', 'ietf', 'v2', 'IGMP-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.76', 'ietf', 'v2', 'INET-ADDRESS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.76', 'ietf', 'v2', 'INET-ADDRESS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.76', 'ietf', 'v2', 'INET-ADDRESS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.52.5', 'ietf', 'v2', 'INTEGRATED-SERVICES-GUARANTEED-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.52', 'ietf', 'v2', 'INTEGRATED-SERVICES-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16.27', 'ietf', 'v2', 'INTERFACETOPN-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.17', 'ietf', 'v2', 'IPATM-IPMC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.57', 'ietf', 'v2', 'IPATM-IPMC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.4.24', 'ietf', 'v2', 'IP-FORWARD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.4.24', 'ietf', 'v2', 'IP-FORWARD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.168', 'ietf', 'v2', 'IPMCAST-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.48', 'ietf', 'v2', 'IP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.48', 'ietf', 'v2', 'IP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.83', 'ietf', 'v2', 'IPMROUTE-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.46', 'ietf', 'v2', 'IPOA-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.141', 'ietf', 'v2', 'IPS-AUTH-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.153', 'ietf', 'v2', 'IPSEC-SPD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.103', 'ietf', 'v2', 'IPV6-FLOW-LABEL-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.56', 'ietf', 'v2', 'IPV6-ICMP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.55', 'ietf', 'v2', 'IPV6-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.91', 'ietf', 'v2', 'IPV6-MLD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.3.86', 'ietf', 'v2', 'IPV6-TCP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.3.87', 'ietf', 'v2', 'IPV6-UDP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.142', 'ietf', 'v2', 'ISCSI-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.20', 'ietf', 'v2', 'ISDN-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.138', 'ietf', 'v2', 'ISIS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.163', 'ietf', 'v2', 'ISNS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.121', 'ietf', 'v2', 'ITU-ALARM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.120', 'ietf', 'v2', 'ITU-ALARM-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.4.1.2699.1.1', 'ietf', 'v2', 'Job-Monitoring-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.95', 'ietf', 'v2', 'L2TP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.165', 'ietf', 'v2', 'LANGTAG-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.227', 'ietf', 'v2', 'LMP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.227', 'ietf', 'v2', 'LMP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.101', 'ietf', 'v2', 'MALLOC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.26.1', 'ietf', 'v1', 'MAU-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.26.6', 'ietf', 'v2', 'MAU-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.26.6', 'ietf', 'v2', 'MAU-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.26.6', 'ietf', 'v2', 'MAU-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.26.6', 'ietf', 'v2', 'MAU-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.171', 'ietf', 'v2', 'MIDCOM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.38.1', 'ietf', 'v1', 'MIOX25-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.44', 'ietf', 'v2', 'MIP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.133', 'ietf', 'v2', 'MOBILEIPV6-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.38', 'ietf', 'v2', 'Modem-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.8', 'ietf', 'v2', 'MPLS-FTN-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.11', 'ietf', 'v2', 'MPLS-L3VPN-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.9', 'ietf', 'v2', 'MPLS-LC-ATM-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.10', 'ietf', 'v2', 'MPLS-LC-FR-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.5', 'ietf', 'v2', 'MPLS-LDP-ATM-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.6', 'ietf', 'v2', 'MPLS-LDP-FRAME-RELAY-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.7', 'ietf', 'v2', 'MPLS-LDP-GENERIC-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.4.1.9.10.65', 'ietf', 'v2', 'MPLS-LDP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.4', 'ietf', 'v2', 'MPLS-LDP-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.2', 'ietf', 'v2', 'MPLS-LSR-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.1', 'ietf', 'v2', 'MPLS-TC-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.166.3', 'ietf', 'v2', 'MPLS-TE-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.3.92', 'ietf', 'v2', 'MSDP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.28', 'ietf', 'v2', 'MTA-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.28', 'ietf', 'v2', 'MTA-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.28', 'ietf', 'v2', 'MTA-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.123', 'ietf', 'v2', 'NAT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.27', 'ietf', 'v2', 'NETWORK-SERVICES-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.27', 'ietf', 'v2', 'NETWORK-SERVICES-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.71', 'ietf', 'v2', 'NHRP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.92', 'ietf', 'v2', 'NOTIFICATION-LOG-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.133', 'ietf', 'v2', 'OPT-IF-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.14', 'ietf', 'v2', 'OSPF-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.14', 'ietf', 'v2', 'OSPF-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.14.16', 'ietf', 'v2', 'OSPF-TRAP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.14.16', 'ietf', 'v2', 'OSPF-TRAP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.34', 'ietf', 'v2', 'PARALLEL-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.17.6', 'ietf', 'v2', 'P-BRIDGE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.58', 'ietf', 'v2', 'PerfHist-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.58', 'ietf', 'v2', 'PerfHist-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.172', 'ietf', 'v2', 'PIM-BSR-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.3.61', 'ietf', 'v2', 'PIM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.157', 'ietf', 'v2', 'PIM-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.93', 'ietf', 'v2', 'PINT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.140', 'ietf', 'v2', 'PKTC-IETF-MTA-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.169', 'ietf', 'v2', 'PKTC-IETF-SIG-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.124', 'ietf', 'v2', 'POLICY-BASED-MANAGEMENT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.105', 'ietf', 'v2', 'POWER-ETHERNET-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.23.4', 'ietf', 'v1', 'PPP-BRIDGE-NCP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.23.3', 'ietf', 'v1', 'PPP-IP-NCP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.23.1.1', 'ietf', 'v1', 'PPP-LCP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.23.2', 'ietf', 'v1', 'PPP-SEC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.43', 'ietf', 'v2', 'Printer-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.43', 'ietf', 'v2', 'Printer-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.79', 'ietf', 'v2', 'PTOPO-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.17.7', 'ietf', 'v2', 'Q-BRIDGE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.67.2.2', 'ietf', 'v2', 'RADIUS-ACC-CLIENT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.67.2.2', 'ietf', 'v2', 'RADIUS-ACC-CLIENT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.67.2.1', 'ietf', 'v2', 'RADIUS-ACC-SERVER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.67.2.1', 'ietf', 'v2', 'RADIUS-ACC-SERVER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.67.1.2', 'ietf', 'v2', 'RADIUS-AUTH-CLIENT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.67.1.2', 'ietf', 'v2', 'RADIUS-AUTH-CLIENT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.67.1.1', 'ietf', 'v2', 'RADIUS-AUTH-SERVER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.67.1.1', 'ietf', 'v2', 'RADIUS-AUTH-SERVER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.145', 'ietf', 'v2', 'RADIUS-DYNAUTH-CLIENT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.146', 'ietf', 'v2', 'RADIUS-DYNAUTH-SERVER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16.31', 'ietf', 'v2', 'RAQMON-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16.32', 'ietf', 'v2', 'RAQMON-RDS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.39', 'ietf', 'v2', 'RDBMS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.1', 'ietf', 'v1', 'RFC1066-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.1', 'ietf', 'v1', 'RFC1156-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.1', 'ietf', 'v1', 'RFC1158-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.1', 'ietf', 'v1', 'RFC1213-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.12', 'ietf', 'v1', 'RFC1229-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.3.7', 'ietf', 'v1', 'RFC1230-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.9', 'ietf', 'v1', 'RFC1231-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.3.2', 'ietf', 'v1', 'RFC1232-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.3.15', 'ietf', 'v1', 'RFC1233-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.13.1', 'ietf', 'v1', 'RFC1243-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.13.1', 'ietf', 'v1', 'RFC1248-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.13.1', 'ietf', 'v1', 'RFC1252-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.14.1', 'ietf', 'v1', 'RFC1253-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.15', 'ietf', 'v1', 'RFC1269-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16.1', 'ietf', 'v1', 'RFC1271-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.7', 'ietf', 'v1', 'RFC1284-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.15.1', 'ietf', 'v1', 'RFC1285-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.17.1', 'ietf', 'v1', 'RFC1286-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.18.1', 'ietf', 'v1', 'RFC1289-phivMIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.31', 'ietf', 'v1', 'RFC1304-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.32', 'ietf', 'v1', 'RFC1315-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.19', 'ietf', 'v1', 'RFC1316-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.33', 'ietf', 'v1', 'RFC1317-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.34', 'ietf', 'v1', 'RFC1318-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.20.2', 'ietf', 'v1', 'RFC1353-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.4.24', 'ietf', 'v1', 'RFC1354-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.16', 'ietf', 'v1', 'RFC1381-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.5', 'ietf', 'v1', 'RFC1382-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.23.1', 'ietf', 'v1', 'RFC1389-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.7', 'ietf', 'v1', 'RFC1398-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.18', 'ietf', 'v1', 'RFC1406-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.30', 'ietf', 'v1', 'RFC1407-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.24.1', 'ietf', 'v1', 'RFC1414-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.23', 'ietf', 'v2', 'RIPv2-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16', 'ietf', 'v2', 'RMON2-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16', 'ietf', 'v2', 'RMON2-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16.1', 'ietf', 'v1', 'RMON-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16.20.8', 'ietf', 'v2', 'RMON-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.112', 'ietf', 'v2', 'ROHC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.114', 'ietf', 'v2', 'ROHC-RTP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.113', 'ietf', 'v2', 'ROHC-UNCOMPRESSED-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.33', 'ietf', 'v2', 'RS-232-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.134', 'ietf', 'v2', 'RSTP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.51', 'ietf', 'v2', 'RSVP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.87', 'ietf', 'v2', 'RTP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.139', 'ietf', 'v2', 'SCSI-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.104', 'ietf', 'v2', 'SCTP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.4.1.4300.1', 'ietf', 'v2', 'SFLOW-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.149', 'ietf', 'v2', 'SIP-COMMON-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.36', 'ietf', 'v2', 'SIP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.151', 'ietf', 'v2', 'SIP-SERVER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.148', 'ietf', 'v2', 'SIP-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.150', 'ietf', 'v2', 'SIP-UA-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.3.88', 'ietf', 'v2', 'SLAPM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16.22', 'ietf', 'v2', 'SMON-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.4.1.4.4', 'ietf', 'v1', 'SMUX-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.34', 'ietf', 'v2', 'SNA-NAU-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.34', 'ietf', 'v2', 'SNA-NAU-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.41', 'ietf', 'v2', 'SNA-SDLC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.18', 'ietf', 'v2', 'SNMP-COMMUNITY-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.18', 'ietf', 'v2', 'SNMP-COMMUNITY-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.10', 'ietf', 'v2', 'SNMP-FRAMEWORK-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.10', 'ietf', 'v2', 'SNMP-FRAMEWORK-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.10', 'ietf', 'v2', 'SNMP-FRAMEWORK-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.21', 'ietf', 'v2', 'SNMP-IEEE802-TM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.11', 'ietf', 'v2', 'SNMP-MPD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.11', 'ietf', 'v2', 'SNMP-MPD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.11', 'ietf', 'v2', 'SNMP-MPD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.13', 'ietf', 'v2', 'SNMP-NOTIFICATION-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.13', 'ietf', 'v2', 'SNMP-NOTIFICATION-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.13', 'ietf', 'v2', 'SNMP-NOTIFICATION-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.14', 'ietf', 'v2', 'SNMP-PROXY-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.14', 'ietf', 'v2', 'SNMP-PROXY-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.14', 'ietf', 'v2', 'SNMP-PROXY-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.22.1.1', 'ietf', 'v1', 'SNMP-REPEATER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.22.1.1', 'ietf', 'v1', 'SNMP-REPEATER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.22.5', 'ietf', 'v2', 'SNMP-REPEATER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.12', 'ietf', 'v2', 'SNMP-TARGET-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.12', 'ietf', 'v2', 'SNMP-TARGET-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.12', 'ietf', 'v2', 'SNMP-TARGET-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.15', 'ietf', 'v2', 'SNMP-USER-BASED-SM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.15', 'ietf', 'v2', 'SNMP-USER-BASED-SM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.15', 'ietf', 'v2', 'SNMP-USER-BASED-SM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.20', 'ietf', 'v2', 'SNMP-USM-AES-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.3.101', 'ietf', 'v2', 'SNMP-USM-DH-OBJECTS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.2', 'ietf', 'v2', 'SNMPv2-M2M-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.1', 'ietf', 'v2', 'SNMPv2-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.1', 'ietf', 'v2', 'SNMPv2-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.1', 'ietf', 'v2', 'SNMPv2-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.3', 'ietf', 'v2', 'SNMPv2-PARTY-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.6', 'ietf', 'v2', 'SNMPv2-USEC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.16', 'ietf', 'v2', 'SNMP-VIEW-BASED-ACM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.16', 'ietf', 'v2', 'SNMP-VIEW-BASED-ACM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.6.3.16', 'ietf', 'v2', 'SNMP-VIEW-BASED-ACM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.39', 'ietf', 'v2', 'SONET-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.39', 'ietf', 'v2', 'SONET-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.39', 'ietf', 'v2', 'SONET-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.17.3', 'ietf', 'v1', 'SOURCE-ROUTING-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16.28', 'ietf', 'v2', 'SSPM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.54', 'ietf', 'v2', 'SYSAPPL-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.137', 'ietf', 'v2', 'T11-FC-FABRIC-ADDR-MGR-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.162', 'ietf', 'v2', 'T11-FC-FABRIC-CONFIG-SERVER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.159', 'ietf', 'v2', 'T11-FC-FABRIC-LOCK-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.143', 'ietf', 'v2', 'T11-FC-FSPF-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.135', 'ietf', 'v2', 'T11-FC-NAME-SERVER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.144', 'ietf', 'v2', 'T11-FC-ROUTE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.161', 'ietf', 'v2', 'T11-FC-RSCN-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.176', 'ietf', 'v2', 'T11-FC-SP-AUTHENTICATION-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.178', 'ietf', 'v2', 'T11-FC-SP-POLICY-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.179', 'ietf', 'v2', 'T11-FC-SP-SA-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.175', 'ietf', 'v2', 'T11-FC-SP-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.177', 'ietf', 'v2', 'T11-FC-SP-ZONING-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.147', 'ietf', 'v2', 'T11-FC-VIRTUAL-FABRIC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.160', 'ietf', 'v2', 'T11-FC-ZONE-SERVER-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.136', 'ietf', 'v2', 'T11-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.156', 'ietf', 'v2', 'TCP-ESTATS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.4.1.23.2.29.1', 'ietf', 'v1', 'TCPIPX-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.49', 'ietf', 'v2', 'TCP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.49', 'ietf', 'v2', 'TCP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.200', 'ietf', 'v2', 'TE-LINK-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.122', 'ietf', 'v2', 'TE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.3.124', 'ietf', 'v2', 'TIME-AGGREGATE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.34.8', 'ietf', 'v2', 'TN3270E-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.34.9', 'ietf', 'v2', 'TN3270E-RT-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.9', 'ietf', 'v2', 'TOKENRING-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.9', 'ietf', 'v2', 'TOKENRING-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16.1', 'ietf', 'v1', 'TOKEN-RING-RMON-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.42', 'ietf', 'v2', 'TOKENRING-STATION-SR-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.16.30', 'ietf', 'v2', 'TPM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.100', 'ietf', 'v2', 'TRANSPORT-ADDRESS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.116', 'ietf', 'v2', 'TRIP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.115', 'ietf', 'v2', 'TRIP-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.131', 'ietf', 'v2', 'TUNNEL-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.131', 'ietf', 'v2', 'TUNNEL-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.170', 'ietf', 'v2', 'UDPLITE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.50', 'ietf', 'v2', 'UDP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.50', 'ietf', 'v2', 'UDP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.33', 'ietf', 'v2', 'UPS-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.164', 'ietf', 'v2', 'URI-TC-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.229', 'ietf', 'v2', 'VDSL-LINE-EXT-MCM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.228', 'ietf', 'v2', 'VDSL-LINE-EXT-SCM-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.10.97', 'ietf', 'v2', 'VDSL-LINE-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.129', 'ietf', 'v2', 'VPN-TC-STD-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.68', 'ietf', 'v2', 'VRRP-MIB']);
    push(@{$mibdepot}, ['1.3.6.1.2.1.65', 'ietf', 'v2', 'WWW-MIB']);
    my $oids = $self->get_entries_by_walk(-varbindlist => [
        '1.3.6.1.2.1', '1.3.6.1.4.1',
    ]);
    foreach my $mibinfo (@{$mibdepot}) {
      $GLPlugin::SNMP::mib_ids->{$mibinfo->[3]} = $mibinfo->[0];
    }
    $GLPlugin::SNMP::mib_ids->{'SNMP-MIB2'} = "1.3.6.1.2.1";
    foreach my $mib (keys %{$GLPlugin::SNMP::mib_ids}) {
      if ($self->implements_mib($mib)) {
        push(@outputlist, [$mib, $GLPlugin::SNMP::mib_ids->{$mib}]);
        $unknowns = {@{[map {
            $_, $self->rawdata->{$_}
        } grep {
            substr($_, 0, length($GLPlugin::SNMP::mib_ids->{$mib})) ne
                $GLPlugin::SNMP::mib_ids->{$mib} || (
            substr($_, 0, length($GLPlugin::SNMP::mib_ids->{$mib})) eq
                $GLPlugin::SNMP::mib_ids->{$mib} &&
            substr($_, length($GLPlugin::SNMP::mib_ids->{$mib}), 1) ne ".")
        } keys %{$unknowns}]}};
      }
    }
    my $toplevels = {};
    map {
        /^(1\.3\.6\.1\.(2|4)\.1\.\d+\.\d+)\./; $toplevels->{$1} = 1; 
    } keys %{$unknowns};
    foreach (sort {$a cmp $b} keys %{$toplevels}) {
      push(@outputlist, ["<unknown>", $_]);
    }
    foreach (sort {$a->[0] cmp $b->[0]} @outputlist) {
      printf "implements %s %s\n", $_->[0], $_->[1];
    }
    $self->add_ok("have fun");
    my ($code, $message) = $self->check_messages(join => ', ', join_all => ', ');
    $GLPlugin::plugin->nagios_exit($code, $message);
  }
}

sub check_snmp_and_model {
  my $self = shift;
  $GLPlugin::SNMP::mibs_and_oids->{'MIB-II'} = {
    sysDescr => '1.3.6.1.2.1.1.1',
    sysObjectID => '1.3.6.1.2.1.1.2',
    sysUpTime => '1.3.6.1.2.1.1.3',
    sysName => '1.3.6.1.2.1.1.5',
  };
  $GLPlugin::SNMP::mibs_and_oids->{'SNMP-FRAMEWORK-MIB'} = {
    snmpEngineID => '1.3.6.1.6.3.10.2.1.1.0',
    snmpEngineBoots => '1.3.6.1.6.3.10.2.1.2.0',
    snmpEngineTime => '1.3.6.1.6.3.10.2.1.3.0',
    snmpEngineMaxMessageSize => '1.3.6.1.6.3.10.2.1.4.0',
  };
  if ($self->opts->snmpwalk) {
    my $response = {};
    if (! -f $self->opts->snmpwalk) {
      $self->add_message(CRITICAL, 
          sprintf 'file %s not found',
          $self->opts->snmpwalk);
    } elsif (-x $self->opts->snmpwalk) {
      my $cmd = sprintf "%s -ObentU -v%s -c%s %s 1.3.6.1.4.1 2>&1",
          $self->opts->snmpwalk,
          $self->opts->protocol,
          $self->opts->community,
          $self->opts->hostname;
      open(WALK, "$cmd |");
      while (<WALK>) {
        if (/^([\.\d]+) = .*?: (\-*\d+)/) {
          $response->{$1} = $2;
        } elsif (/^([\.\d]+) = .*?: "(.*?)"/) {
          $response->{$1} = $2;
          $response->{$1} =~ s/\s+$//;
        }
      }
      close WALK;
    } else {
      if (defined $self->opts->offline && $self->opts->mode ne 'walk') {
        if ((time - (stat($self->opts->snmpwalk))[9]) > $self->opts->offline) {
          $self->add_message(UNKNOWN,
              sprintf 'snmpwalk file %s is too old', $self->opts->snmpwalk);
        }
      }
      $self->opts->override_opt('hostname', 'walkhost') if $self->opts->mode ne 'walk';
      open(MESS, $self->opts->snmpwalk);
      while(<MESS>) {
        # SNMPv2-SMI::enterprises.232.6.2.6.7.1.3.1.4 = INTEGER: 6
        if (/^([\d\.]+) = .*?INTEGER: .*\((\-*\d+)\)/) {
          # .1.3.6.1.2.1.2.2.1.8.1 = INTEGER: down(2)
          $response->{$1} = $2;
        } elsif (/^([\d\.]+) = .*?Opaque:.*?Float:.*?([\-\.\d]+)/) {
          # .1.3.6.1.4.1.2021.10.1.6.1 = Opaque: Float: 0.938965
          $response->{$1} = $2;
        } elsif (/^([\d\.]+) = STRING:\s*$/) {
          $response->{$1} = "";
        } elsif (/^([\d\.]+) = Network Address: (.*)/) {
          $response->{$1} = $2;
        } elsif (/^([\d\.]+) = Hex-STRING: (.*)/) {
          $response->{$1} = "0x".$2;
          $response->{$1} =~ s/\s+$//;
        } elsif (/^([\d\.]+) = \w+: (\-*\d+)/) {
          $response->{$1} = $2;
        } elsif (/^([\d\.]+) = \w+: "(.*?)"/) {
          $response->{$1} = $2;
          $response->{$1} =~ s/\s+$//;
        } elsif (/^([\d\.]+) = \w+: (.*)/) {
          $response->{$1} = $2;
          $response->{$1} =~ s/\s+$//;
        } elsif (/^([\d\.]+) = (\-*\d+)/) {
          $response->{$1} = $2;
        } elsif (/^([\d\.]+) = "(.*?)"/) {
          $response->{$1} = $2;
          $response->{$1} =~ s/\s+$//;
        }
      }
      close MESS;
    }
    foreach my $oid (keys %$response) {
      if ($oid =~ /^\./) {
        my $nodot = $oid;
        $nodot =~ s/^\.//g;
        $response->{$nodot} = $response->{$oid};
        delete $response->{$oid};
      }
    }
    map { $response->{$_} =~ s/^\s+//; $response->{$_} =~ s/\s+$//; }
        keys %$response;
    $self->set_rawdata($response);
  } else {
    $self->set_timeout_alarm();
    if (eval "require Net::SNMP") {
      my %params = ();
      my $net_snmp_version = Net::SNMP->VERSION(); # 5.002000 or 6.000000
      $params{'-translate'} = [ # because we see "NULL" coming from socomec devices
        -all => 0x0,
        -nosuchobject => 1,
        -nosuchinstance => 1,
        -endofmibview => 1,
        -unsigned => 1,
      ];
      $params{'-hostname'} = $self->opts->hostname;
      $params{'-version'} = $self->opts->protocol;
      if ($self->opts->port) {
        $params{'-port'} = $self->opts->port;
      }
      if ($self->opts->domain) {
        $params{'-domain'} = $self->opts->domain;
      }
      $self->v2tov3;
      if ($self->opts->protocol eq '3') {
        $params{'-version'} = $self->opts->protocol;
        $params{'-username'} = $self->opts->username;
        if ($self->opts->authpassword) {
          $params{'-authpassword'} = $self->opts->authpassword;
        }
        if ($self->opts->authprotocol) {
          $params{'-authprotocol'} = $self->opts->authprotocol;
        }
        if ($self->opts->privpassword) {
          $params{'-privpassword'} = $self->opts->privpassword;
        }
        if ($self->opts->privprotocol) {
          $params{'-privprotocol'} = $self->opts->privprotocol;
        }
        # context hat in der session nix verloren, sondern wird
        # als zusatzinfo bei den requests mitgeschickt
        #if ($self->opts->contextengineid) {
        #  $params{'-contextengineid'} = $self->opts->contextengineid;
        #}
        #if ($self->opts->contextname) {
        #  $params{'-contextname'} = $self->opts->contextname;
        #}
      } else {
        $params{'-community'} = $self->opts->community;
      }
      my ($session, $error) = Net::SNMP->session(%params);
      if (! defined $session) {
        $self->add_message(CRITICAL, 
            sprintf 'cannot create session object: %s', $error);
        $self->debug(Data::Dumper::Dumper(\%params));
      } else {
        my $max_msg_size = $session->max_msg_size();
        $session->max_msg_size(4 * $max_msg_size);
        $GLPlugin::SNMP::session = $session;
      }
    } else {
      $self->add_message(CRITICAL,
          'could not find Net::SNMP module');
    }
  }
  if (! $self->check_messages()) {
    my $tic = time;
    my $sysUptime = $self->get_snmp_object('MIB-II', 'sysUpTime', 0);
    my $snmpEngineTime = $self->get_snmp_object('SNMP-FRAMEWORK-MIB', 'snmpEngineTime');
    my $sysDescr = $self->get_snmp_object('MIB-II', 'sysDescr', 0);
    my $tac = time;
    if (defined $sysUptime && defined $sysDescr) {
      # drecksschrott asa liefert negative werte
      if (defined $snmpEngineTime && $snmpEngineTime > 0) {
        $self->{uptime} = $snmpEngineTime;
      } else {
        $self->{uptime} = $self->timeticks($sysUptime);
      }
      $self->{productname} = $sysDescr;
      $self->{sysobjectid} = $self->get_snmp_object('MIB-II', 'sysObjectID', 0);
      $self->debug(sprintf 'uptime: %s', $self->{uptime});
      $self->debug(sprintf 'up since: %s',
          scalar localtime (time - $self->{uptime}));
      $GLPlugin::SNMP::uptime = $self->{uptime};
      $self->debug('whoami: '.$self->{productname});
    } else {
      if ($tac - $tic >= $GLPlugin::SNMP::session->timeout) {
        $self->add_message(UNKNOWN,
            'could not contact snmp agent, timeout during snmp-get sysUptime');
      } else {
        $self->add_message(UNKNOWN,
            'got neither sysUptime nor sysDescr, is this snmp agent working correctly?');
      }
      $GLPlugin::SNMP::session->close if $GLPlugin::SNMP::session;
    }
  }
}

sub no_such_model {
  my $self = shift;
  printf "Model %s is not implemented\n", $self->{productname};
  exit 3;
}

sub no_such_mode {
  my $self = shift;
  if (ref($self) eq "Classes::Generic") {
    $self->init();
  } elsif (ref($self) eq "Classes::Device") {
    $self->add_message(UNKNOWN, 'the device did not implement the mibs this plugin is asking for');
    $self->add_message(UNKNOWN,
        sprintf('unknown device%s', $self->{productname} eq 'unknown' ?
            '' : '('.$self->{productname}.')'));
  } elsif (ref($self) eq "GLPlugin::SNMP") {
    # uptime, offline
    $self->init();
  } else {
    eval {
      bless $self, "Classes::Generic";
      $self->init();
    };
    if ($@) {
      bless $self, "GLPlugin::SNMP";
      $self->init();
    }
  }
  if (ref($self) eq "GLPlugin::SNMP") {
    printf "Mode %s is not implemented for this type of device\n",
        $self->opts->mode;
    exit 3;
  }
}

sub uptime {
  my $self = shift;
  return $GLPlugin::SNMP::uptime;
}

sub discover_suitable_class {
  my $self = shift;
  my $sysobj = $self->get_snmp_object('MIB-II', 'sysObjectID', 0);
  if ($sysobj && exists $GLPlugin::SNMP::discover_ids->{$sysobj}) {
    return $GLPlugin::SNMP::discover_ids->{$sysobj};
  }
}

sub implements_mib {
  my $self = shift;
  my $mib = shift;
  if (! exists $GLPlugin::SNMP::mib_ids->{$mib}) {
    return 0;
  }
  my $sysobj = $self->get_snmp_object('MIB-II', 'sysObjectID', 0);
  $sysobj =~ s/^\.// if $sysobj;
  if ($sysobj && $sysobj eq $GLPlugin::SNMP::mib_ids->{$mib}) {
    $self->debug(sprintf "implements %s (sysobj exact)", $mib);
    return 1;
  }
  if ($GLPlugin::SNMP::mib_ids->{$mib} eq
      substr $sysobj, 0, length $GLPlugin::SNMP::mib_ids->{$mib}) {
    $self->debug(sprintf "implements %s (sysobj)", $mib);
    return 1;
  }
  # some mibs are only composed of tables
  my $traces;
  if ($self->opts->snmpwalk) {
    $traces = {@{[map {
        $_, $self->rawdata->{$_} 
    } grep {
        substr($_, 0, length($GLPlugin::SNMP::mib_ids->{$mib})) eq $GLPlugin::SNMP::mib_ids->{$mib} 
    } keys %{$self->rawdata}]}};
  } else {
    my %params = (
        -varbindlist => [
            $GLPlugin::SNMP::mib_ids->{$mib}
        ]
    );
    if ($GLPlugin::SNMP::session->version() == 3) {
      $params{-contextengineid} = $self->opts->contextengineid if $self->opts->contextengineid;
      $params{-contextname} = $self->opts->contextname if $self->opts->contextname;
    }
    $traces = $GLPlugin::SNMP::session->get_next_request(%params);
  }
  if ($traces && # must find oids following to the ident-oid
      ! exists $traces->{$GLPlugin::SNMP::mib_ids->{$mib}} && # must not be the ident-oid
      grep { # following oid is inside this tree
          substr($_, 0, length($GLPlugin::SNMP::mib_ids->{$mib})) eq $GLPlugin::SNMP::mib_ids->{$mib};
      } keys %{$traces}) {
    $self->debug(sprintf "implements %s (found traces)", $mib);
    return 1;
  }
}

sub timeticks {
  my $self = shift;
  my $timestr = shift;
  if ($timestr =~ /\((\d+)\)/) {
    # Timeticks: (20718727) 2 days, 9:33:07.27
    $timestr = $1 / 100;
  } elsif ($timestr =~ /(\d+)\s*day[s]*.*?(\d+):(\d+):(\d+)\.(\d+)/) {
    # Timeticks: 2 days, 9:33:07.27
    $timestr = $1 * 24 * 3600 + $2 * 3600 + $3 * 60 + $4;
  } elsif ($timestr =~ /(\d+):(\d+):(\d+):(\d+)\.(\d+)/) {
    # Timeticks: 0001:03:18:42.77
    $timestr = $1 * 3600 * 24 + $2 * 3600 + $3 * 60 + $4;
  } elsif ($timestr =~ /(\d+):(\d+):(\d+)\.(\d+)/) {
    # Timeticks: 9:33:07.27
    $timestr = $1 * 3600 + $2 * 60 + $3;
  } elsif ($timestr =~ /(\d+)\s*hour[s]*.*?(\d+):(\d+)\.(\d+)/) {
    # Timeticks: 3 hours, 42:17.98
    $timestr = $1 * 3600 + $2 * 60 + $3;
  } elsif ($timestr =~ /(\d+)\s*minute[s]*.*?(\d+)\.(\d+)/) {
    # Timeticks: 36 minutes, 01.96
    $timestr = $1 * 60 + $2;
  } elsif ($timestr =~ /(\d+)\.\d+\s*second[s]/) {
    # Timeticks: 01.02 seconds
    $timestr = $1;
  } elsif ($timestr =~ /^(\d+)$/) {
    $timestr = $1 / 100;
  }
  return $timestr;
}

sub human_timeticks {
  my $self = shift;
  my $timeticks = shift;
  my $days = int($timeticks / 86400);
  $timeticks -= ($days * 86400);
  my $hours = int($timeticks / 3600);
  $timeticks -= ($hours * 3600);
  my $minutes = int($timeticks / 60);
  my $seconds = $timeticks % 60;
  $days = $days < 1 ? '' : $days .'d ';
  return $days . sprintf "%dh %dm %ds", $hours, $minutes, $seconds;
}

sub internal_name {
  my $self = shift;
  my $class = ref($self);
  $class =~ s/^.*:://;
  if (exists $self->{flat_indices}) {
    return sprintf "%s_%s", uc $class, $self->{flat_indices};
  } else {
    return sprintf "%s", uc $class;
  }
}

################################################################
# file-related functions
#
sub create_interface_cache_file {
  my $self = shift;
  my $extension = "";
  if ($self->opts->snmpwalk && ! $self->opts->hostname) {
    $self->opts->override_opt('hostname',
        'snmpwalk.file'.md5_hex($self->opts->snmpwalk))
  }
  if ($self->opts->community) { 
    $extension .= md5_hex($self->opts->community);
  }
  $extension =~ s/\//_/g;
  $extension =~ s/\(/_/g;
  $extension =~ s/\)/_/g;
  $extension =~ s/\*/_/g;
  $extension =~ s/\s/_/g;
  return sprintf "%s/%s_interface_cache_%s", $self->statefilesdir(),
      $self->opts->hostname, lc $extension;
}

sub create_entry_cache_file {
  my $self = shift;
  my $mib = shift;
  my $table = shift;
  my $key_attr = shift;
  return lc sprintf "%s_%s_%s_%s_cache",
      $self->create_interface_cache_file(),
      $mib, $table, join('#', @{$key_attr});
}

sub update_entry_cache {
  my $self = shift;
  my $force = shift;
  my $mib = shift;
  my $table = shift;
  my $key_attr = shift;
  if (ref($key_attr) ne "ARRAY") {
    $key_attr = [$key_attr];
  }
  my $cache = sprintf "%s_%s_%s_cache", 
      $mib, $table, join('#', @{$key_attr});
  my $statefile = $self->create_entry_cache_file($mib, $table, $key_attr);
  my $update = time - 3600;
  #my $update = time - 1;
  if ($force || ! -f $statefile || ((stat $statefile)[9]) < ($update)) {
    $self->debug(sprintf 'force update of %s %s %s %s cache',
        $self->opts->hostname, $self->opts->mode, $mib, $table);
    $self->{$cache} = {};
    foreach my $entry ($self->get_snmp_table_objects($mib, $table)) {
      my $key = join('#', map { $entry->{$_} } @{$key_attr});
      my $hash = $key . '-//-' . join('.', @{$entry->{indices}});
      $self->{$cache}->{$hash} = $entry->{indices};
    }
    $self->save_cache($mib, $table, $key_attr);
  }
  $self->load_cache($mib, $table, $key_attr);
}

sub save_cache {
  my $self = shift;
  my $mib = shift;
  my $table = shift;
  my $key_attr = shift;
  if (ref($key_attr) ne "ARRAY") {
    $key_attr = [$key_attr];
  }
  my $cache = sprintf "%s_%s_%s_cache", 
      $mib, $table, join('#', @{$key_attr});
  $self->create_statefilesdir();
  my $statefile = $self->create_entry_cache_file($mib, $table, $key_attr);
  open(STATE, ">".$statefile.".".$$);
  printf STATE Data::Dumper::Dumper($self->{$cache});
  close STATE;
  rename $statefile.".".$$, $statefile;
  $self->debug(sprintf "saved %s to %s",
      Data::Dumper::Dumper($self->{$cache}), $statefile);
}

sub load_cache {
  my $self = shift;
  my $mib = shift;
  my $table = shift;
  my $key_attr = shift;
  if (ref($key_attr) ne "ARRAY") {
    $key_attr = [$key_attr];
  }
  my $cache = sprintf "%s_%s_%s_cache", 
      $mib, $table, join('#', @{$key_attr});
  my $statefile = $self->create_entry_cache_file($mib, $table, $key_attr);
  $self->{$cache} = {};
  if ( -f $statefile) {
    our $VAR1;
    our $VAR2;
    eval {
      require $statefile;
    };
    if($@) {
      printf "rumms\n";
    }
    # keinesfalls mehr require verwenden!!!!!!
    # beim require enthaelt VAR1 andere werte als beim slurp
    # und zwar diejenigen, die beim letzten save_cache geschrieben wurden.
    my $content = do { local (@ARGV, $/) = $statefile; my $x = <>; close ARGV; $x };
    $VAR1 = eval "$content";
    $self->debug(sprintf "load %s", Data::Dumper::Dumper($VAR1));
    $self->{$cache} = $VAR1;
  }
}


################################################################
# top-level convenience functions
#
sub get_snmp_objects {
  my $self = shift;
  my $mib = shift;
  my @mos = @_;
  foreach (@mos) {
    my $value = $self->get_snmp_object($mib, $_, 0);
    if (defined $value) {
      $self->{$_} = $value;
    } else {
      my $value = $self->get_snmp_object($mib, $_);
      if (defined $value) {
        $self->{$_} = $value;
      }
    }
  }
}

sub get_snmp_tables {
  my $self = shift;
  my $mib = shift;
  my $infos = shift;
  foreach my $info (@{$infos}) {
    my $arrayname = $info->[0];
    my $table = $info->[1];
    my $class = $info->[2];
    my $filter = $info->[3];
    $self->{$arrayname} = [] if ! exists $self->{$arrayname};
    if (! exists $GLPlugin::SNMP::tablecache->{$mib} || ! exists $GLPlugin::SNMP::tablecache->{$mib}->{$table}) {
      $GLPlugin::SNMP::tablecache->{$mib}->{$table} = [];
      foreach ($self->get_snmp_table_objects($mib, $table)) {
        my $new_object = $class->new(%{$_});
        next if (defined $filter && ! &$filter($new_object));
        push(@{$self->{$arrayname}}, $new_object);
        push(@{$GLPlugin::SNMP::tablecache->{$mib}->{$table}}, $new_object);
      }
    } else {
      $self->debug(sprintf "get_snmp_tables %s %s cache hit", $mib, $table);
      foreach (@{$GLPlugin::SNMP::tablecache->{$mib}->{$table}}) {
        push(@{$self->{$arrayname}}, $_);
      }
    }
  }
}

################################################################
# 2nd level 
#
sub get_snmp_object {
  my $self = shift;
  my $mib = shift;
  my $mo = shift;
  my $index = shift;
  if (exists $GLPlugin::SNMP::mibs_and_oids->{$mib} &&
      exists $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$mo}) {
    my $oid = $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$mo}.
        (defined $index ? '.'.$index : '');
    my $response = $self->get_request(-varbindlist => [$oid]);
    if (defined $response->{$oid}) {
      if ($response->{$oid} eq 'noSuchInstance' || $response->{$oid} eq 'noSuchObject') {
        $response->{$oid} = undef;
      } elsif (my @symbols = $self->make_symbolic($mib, $response, [[$index]])) {
        $response->{$oid} = $symbols[0]->{$mo};
      }
    }
    $self->debug(sprintf "GET: %s::%s (%s) : %s", $mib, $mo, $oid, defined $response->{$oid} ? $response->{$oid} : "<undef>");
    return $response->{$oid};
  }
  return undef;
}

sub get_snmp_table_objects_with_cache {
  my $self = shift;
  my $mib = shift;
  my $table = shift;
  my $key_attr = shift;
  #return $self->get_snmp_table_objects($mib, $table);
  $self->update_entry_cache(0, $mib, $table, $key_attr);
  my @indices = $self->get_cache_indices($mib, $table, $key_attr);
  my @entries = ();
  foreach ($self->get_snmp_table_objects($mib, $table, \@indices)) {
    push(@entries, $_);
  }
  return @entries;
}

# get_snmp_table_objects('MIB-Name', 'Table-Name', 'Table-Entry', [indices])
# returns array of hashrefs
sub get_snmp_table_objects {
  my $self = shift;
  my $mib = shift;
  my $table = shift;
  my $indices = shift || [];
  my @entries = ();
  my $augmenting_table;
  $self->debug(sprintf "get_snmp_table_objects %s %s", $mib, $table);
  if ($table =~ /^(.*?)\+(.*)/) {
    $table = $1;
    $augmenting_table = $2;
  }
  my $entry = $table;
  $entry =~ s/Table/Entry/g;
  if (scalar(@{$indices}) == 1) {
    if (exists $GLPlugin::SNMP::mibs_and_oids->{$mib} &&
        exists $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$table}) {
      my $result = {};
      my $eoid = $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$entry}.'.';
      my $eoidlen = length($eoid);
      my @columns = map {
          $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$_}
      } grep {
        substr($GLPlugin::SNMP::mibs_and_oids->{$mib}->{$_}, 0, $eoidlen) eq
            $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$entry}.'.'
      } keys %{$GLPlugin::SNMP::mibs_and_oids->{$mib}};
      my $index = join('.', @{$indices->[0]});
      my $ifresult = $self->get_entries(
          -startindex => $index,
          -endindex => $index,
          -columns => \@columns,
      );
      map { $result->{$_} = $ifresult->{$_} }
          keys %{$ifresult};
      if ($augmenting_table &&
          exists $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$augmenting_table}) {
        my $entry = $augmenting_table;
        $entry =~ s/Table/Entry/g;
        my $eoid = $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$entry}.'.';
        my $eoidlen = length($eoid);
        my @columns = map {
            $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$_}
        } grep {
          substr($GLPlugin::SNMP::mibs_and_oids->{$mib}->{$_}, 0, $eoidlen) eq $eoid
        } keys %{$GLPlugin::SNMP::mibs_and_oids->{$mib}};
        my $ifresult = $self->get_entries(
            -startindex => $index,
            -endindex => $index,
            -columns => \@columns,
        );
        map { $result->{$_} = $ifresult->{$_} }
            keys %{$ifresult};
      }
      @entries = $self->make_symbolic($mib, $result, $indices);
      @entries = map { $_->{indices} = shift @{$indices}; $_ } @entries;
    }
  } elsif (scalar(@{$indices}) > 1) {
    # man koennte hier pruefen, ob die indices aufeinanderfolgen
    # und dann get_entries statt get_table aufrufen
    if (exists $GLPlugin::SNMP::mibs_and_oids->{$mib} &&
        exists $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$table}) {
      my $result = {};
      my $eoid = $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$entry}.'.';
      my $eoidlen = length($eoid);
      my @columns = map {
          $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$_}
      } grep {
        substr($GLPlugin::SNMP::mibs_and_oids->{$mib}->{$_}, 0, $eoidlen) eq $eoid
      } keys %{$GLPlugin::SNMP::mibs_and_oids->{$mib}};
      my @sortedindices = map { $_->[0] }
          sort { $a->[1] cmp $b->[1] }
              map { [$_,
                  join '', map { sprintf("%30d",$_) } split( /\./, $_)
              ] } map { join('.', @{$_})} @{$indices};
      my $startindex = $sortedindices[0];
      my $endindex = $sortedindices[$#sortedindices];
      if (0) {
        # holzweg. dicke ciscos liefern unvollstaendiges resultat, d.h.
        # bei 138,19,157 kommt nur 138..144, dann ist schluss.
        # maxrepetitions bringt nichts.
        $result = $self->get_entries(
            -startindex => $startindex,
            -endindex => $endindex,
            -columns => \@columns,
        );
      } else {
        foreach my $ifidx (@sortedindices) {
          my $ifresult = $self->get_entries(
              -startindex => $ifidx,
              -endindex => $ifidx,
              -columns => \@columns,
          );
          map { $result->{$_} = $ifresult->{$_} }
              keys %{$ifresult};
        }
      }
      if ($augmenting_table &&
          exists $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$augmenting_table}) {
        my $entry = $augmenting_table;
        $entry =~ s/Table/Entry/g;
        my $eoid = $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$entry}.'.';
        my $eoidlen = length($eoid);
        my @columns = map {
            $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$_}
        } grep {
          substr($GLPlugin::SNMP::mibs_and_oids->{$mib}->{$_}, 0, $eoidlen) eq $eoid
        } keys %{$GLPlugin::SNMP::mibs_and_oids->{$mib}};
        foreach my $ifidx (@sortedindices) {
          my $ifresult = $self->get_entries(
              -startindex => $ifidx,
              -endindex => $ifidx,
              -columns => \@columns,
          );
          map { $result->{$_} = $ifresult->{$_} }
              keys %{$ifresult};
        }
      }
      # now we have numerical_oid+index => value
      # needs to become symboic_oid => value
      #my @indices =
      # $self->get_indices($GLPlugin::SNMP::mibs_and_oids->{$mib}->{$entry});
      @entries = $self->make_symbolic($mib, $result, $indices);
      @entries = map { $_->{indices} = shift @{$indices}; $_ } @entries;
    }
  } else {
    if (exists $GLPlugin::SNMP::mibs_and_oids->{$mib} &&
        exists $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$table}) {
      $self->debug(sprintf "get_snmp_table_objects calls get_table %s",
          $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$table});
      my $result = $self->get_table(
          -baseoid => $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$table});
      $self->debug(sprintf "get_snmp_table_objects get_table returns %d oids",
          scalar(keys %{$result}));
      # now we have numerical_oid+index => value
      # needs to become symboic_oid => value
      my @indices = 
          $self->get_indices(
              -baseoid => $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$entry},
              -oids => [keys %{$result}]);
      $self->debug(sprintf "get_snmp_table_objects get_table returns %d indices",
          scalar(@indices));
      @entries = $self->make_symbolic($mib, $result, \@indices);
      @entries = map { $_->{indices} = shift @indices; $_ } @entries;
    }
  }
  @entries = map { $_->{flat_indices} = join(".", @{$_->{indices}}); $_ } @entries;
  return @entries;
}

################################################################
# 3rd level functions. calling net::snmp-functions
# 
sub get_request {
  my $self = shift;
  my %params = @_;
  my @notcached = ();
  foreach my $oid (@{$params{'-varbindlist'}}) {
    $self->add_oidtrace($oid);
    if (! exists $GLPlugin::SNMP::rawdata->{$oid}) {
      push(@notcached, $oid);
    }
  }
  if (! $self->opts->snmpwalk && (scalar(@notcached) > 0)) {
    my %params = ();
    if ($GLPlugin::SNMP::session->version() == 0) {
      $params{-varbindlist} = \@notcached;
    } elsif ($GLPlugin::SNMP::session->version() == 1) {
      $params{-varbindlist} = \@notcached;
      #$params{-nonrepeaters} = scalar(@notcached);
    } elsif ($GLPlugin::SNMP::session->version() == 3) {
      $params{-varbindlist} = \@notcached;
      $params{-contextengineid} = $self->opts->contextengineid if $self->opts->contextengineid;
      $params{-contextname} = $self->opts->contextname if $self->opts->contextname;
    }
    my $result = $GLPlugin::SNMP::session->get_request(%params);
    foreach my $key (%{$result}) {
      $self->add_rawdata($key, $result->{$key});
    }
  }
  my $result = {};
  map { $result->{$_} = $GLPlugin::SNMP::rawdata->{$_} }
      @{$params{'-varbindlist'}};
  return $result;
}

sub get_entries_get_bulk {
  my $self = shift;
  my %params = @_;
  my $result = {};
  $self->debug(sprintf "get_entries_get_bulk %s", Data::Dumper::Dumper(\%params));
  my %newparams = ();
  $newparams{'-startindex'} = $params{'-startindex'}
      if defined $params{'-startindex'};
  $newparams{'-endindex'} = $params{'-endindex'}
      if defined $params{'-endindex'};
  $newparams{'-columns'} = $params{'-columns'};
  if ($GLPlugin::SNMP::session->version() == 3) {
    $newparams{-contextengineid} = $self->opts->contextengineid if $self->opts->contextengineid;
    $newparams{-contextname} = $self->opts->contextname if $self->opts->contextname;
  }
  $result = $GLPlugin::SNMP::session->get_entries(%newparams);
  return $result;
}

sub get_entries_get_next {
  my $self = shift;
  my %params = @_;
  my $result = {};
  $self->debug(sprintf "get_entries_get_next %s", Data::Dumper::Dumper(\%params));
  my %newparams = ();
  $newparams{'-maxrepetitions'} = 0;
  $newparams{'-startindex'} = $params{'-startindex'}
      if defined $params{'-startindex'};
  $newparams{'-endindex'} = $params{'-endindex'}
      if defined $params{'-endindex'};
  $newparams{'-columns'} = $params{'-columns'};
  if ($GLPlugin::SNMP::session->version() == 3) {
    $newparams{-contextengineid} = $self->opts->contextengineid if $self->opts->contextengineid;
    $newparams{-contextname} = $self->opts->contextname if $self->opts->contextname;
  }
  $result = $GLPlugin::SNMP::session->get_entries(%newparams);
  return $result;
}

sub get_entries_get_next_1index {
  my $self = shift;
  my %params = @_;
  my $result = {};
  $self->debug(sprintf "get_entries_get_next_1index %s", Data::Dumper::Dumper(\%params));
  my %newparams = ();
  $newparams{'-startindex'} = $params{'-startindex'}
      if defined $params{'-startindex'};
  $newparams{'-endindex'} = $params{'-endindex'}
      if defined $params{'-endindex'};
  $newparams{'-columns'} = $params{'-columns'};
  my %singleparams = ();
  $singleparams{'-maxrepetitions'} = 0;
  if ($GLPlugin::SNMP::session->version() == 3) {
    $singleparams{-contextengineid} = $self->opts->contextengineid if $self->opts->contextengineid;
    $singleparams{-contextname} = $self->opts->contextname if $self->opts->contextname;
  }
  foreach my $index ($newparams{'-startindex'}..$newparams{'-endindex'}) {
    foreach my $oid (@{$newparams{'-columns'}}) {
      $singleparams{'-columns'} = [$oid];
      $singleparams{'-startindex'} = $index;
      $singleparams{'-endindex'} =$index;
      my $singleresult = $GLPlugin::SNMP::session->get_entries(%singleparams);
      foreach my $key (keys %{$singleresult}) {
        $result->{$key} = $singleresult->{$key};
      }
    }
  }
  return $result;
}

sub get_entries_get_simple {
  my $self = shift;
  my %params = @_;
  my $result = {};
  $self->debug(sprintf "get_entries_get_simple %s", Data::Dumper::Dumper(\%params));
  my %newparams = ();
  $newparams{'-startindex'} = $params{'-startindex'}
      if defined $params{'-startindex'};
  $newparams{'-endindex'} = $params{'-endindex'}
      if defined $params{'-endindex'};
  $newparams{'-columns'} = $params{'-columns'};
  my %singleparams = ();
  if ($GLPlugin::SNMP::session->version() == 3) {
    $singleparams{-contextengineid} = $self->opts->contextengineid if $self->opts->contextengineid;
    $singleparams{-contextname} = $self->opts->contextname if $self->opts->contextname;
  }
  foreach my $index ($newparams{'-startindex'}..$newparams{'-endindex'}) {
    foreach my $oid (@{$newparams{'-columns'}}) {
      $singleparams{'-varbindlist'} = [$oid.".".$index];
      my $singleresult = $GLPlugin::SNMP::session->get_request(%singleparams);
      foreach my $key (keys %{$singleresult}) {
        $result->{$key} = $singleresult->{$key};
      }
    }
  }
  return $result;
}

sub get_entries {
  my $self = shift;
  my %params = @_;
  # [-startindex]
  # [-endindex]
  # -columns
  my $result = {};
  $self->debug(sprintf "get_entries %s", Data::Dumper::Dumper(\%params));
  if (! $self->opts->snmpwalk) {
    $result = $self->get_entries_get_bulk(%params);
    if (! $result) {
      if (scalar (@{$params{'-columns'}}) < 50 && $params{'-startindex'} eq $params{'-endindex'}) {
        $result = $self->get_entries_get_simple(%params);
      } else {
        $result = $self->get_entries_get_next(%params);
      }
      if (! $result && $params{'-startindex'} !~ /\./) {
        # compound indexes cannot continue, as these two methods iterate numerically
        if ($GLPlugin::SNMP::session->error() =~ /tooBig/i) {
          $result = $self->get_entries_get_next_1index(%params);
        }
        if (! $result) {
          $result = $self->get_entries_get_simple(%params);
        }
        if (! $result) {
          $self->debug(sprintf "nutzt nix\n");
        }
      }
    }
    foreach my $key (keys %{$result}) {
      if (substr($key, -1) eq " ") {
        my $value = $result->{$key};
        delete $result->{$key};
        $key =~ s/\s+$//g;
        $result->{$key} = $value;
        #
        # warum?
        #
        # %newparams ist:
        #  '-columns' => [
        #                  '1.3.6.1.2.1.2.2.1.8',
        #                  '1.3.6.1.2.1.2.2.1.13',
        #                  ...
        #                  '1.3.6.1.2.1.2.2.1.16'
        #                ],
        #  '-startindex' => '2',
        #  '-endindex' => '2'
        #
        # und $result ist:
        #  ...
        #  '1.3.6.1.2.1.2.2.1.2.2' => 'Adaptive Security Appliance \'outside\' interface',
        #  '1.3.6.1.2.1.2.2.1.16.2 ' => 4281465004,
        #  '1.3.6.1.2.1.2.2.1.13.2' => 0,
        #  ...
        #
        # stinkstiefel!
        #
      }
      $self->add_rawdata($key, $result->{$key});
    }
  } else {
    my $preresult = $self->get_matching_oids(
        -columns => $params{'-columns'});
    foreach (keys %{$preresult}) {
      $result->{$_} = $preresult->{$_};
    }
    my @sortedkeys = map { $_->[0] }
        sort { $a->[1] cmp $b->[1] }
            map { [$_,
                    join '', map { sprintf("%30d",$_) } split( /\./, $_)
                  ] } keys %{$result};
    my @to_del = ();
    if ($params{'-startindex'}) {
      foreach my $resoid (@sortedkeys) {
        foreach my $oid (@{$params{'-columns'}}) {
          my $poid = $oid.'.';
          my $lpoid = length($poid);
          if (substr($resoid, 0, $lpoid) eq $poid) {
            my $oidpattern = $poid;
            $oidpattern =~ s/\./\\./g;
            if ($resoid =~ /^$oidpattern(.+)$/) {
              if ($1 lt $params{'-startindex'}) {
                push(@to_del, $oid.'.'.$1);
              }
            }
          }
        }
      }
    }
    if ($params{'-endindex'}) {
      foreach my $resoid (@sortedkeys) {
        foreach my $oid (@{$params{'-columns'}}) {
          my $poid = $oid.'.';
          my $lpoid = length($poid);
          if (substr($resoid, 0, $lpoid) eq $poid) {
            my $oidpattern = $poid;
            $oidpattern =~ s/\./\\./g;
            if ($resoid =~ /^$oidpattern(.+)$/) {
              if ($1 gt $params{'-endindex'}) {
                push(@to_del, $oid.'.'.$1);
              }
            }
          }
        }
      }
    }
    foreach (@to_del) {
      delete $result->{$_};
    }
  }
  return $result;
}

sub get_entries_by_walk {
  my $self = shift;
  my %params = @_;
  if (! $self->opts->snmpwalk) {
    $self->add_ok("if you get this crap working correctly, let me know");
    if ($GLPlugin::SNMP::session->version() == 3) {
      $params{-contextengineid} = $self->opts->contextengineid if $self->opts->contextengineid;
      $params{-contextname} = $self->opts->contextname if $self->opts->contextname;
    }
    $self->debug(sprintf "get_tree %s", Data::Dumper::Dumper(\%params));
    my @baseoids = @{$params{-varbindlist}};
    delete $params{-varbindlist};
    if ($GLPlugin::SNMP::session->version() == 0) {
      foreach my $baseoid (@baseoids) {
        $params{-varbindlist} = [$baseoid];
        while (my $result = $GLPlugin::SNMP::session->get_next_request(%params)) {
          $params{-varbindlist} = [($GLPlugin::SNMP::session->var_bind_names)[0]];
        }
      }
    } else {
      $params{-maxrepetitions} = 200;
      foreach my $baseoid (@baseoids) {
        $params{-varbindlist} = [$baseoid];
        while (my $result = $GLPlugin::SNMP::session->get_bulk_request(%params)) {
          my @names = $GLPlugin::SNMP::session->var_bind_names();
          my @oids = $self->sort_oids(\@names);
          $params{-varbindlist} = [pop @oids];
        }
      }
    }
  } else {
    return $self->get_matching_oids(
        -columns => $params{-varbindlist});
  }
}

sub get_table {
  my $self = shift;
  my %params = @_;
  $self->add_oidtrace($params{'-baseoid'});
  if (! $self->opts->snmpwalk) {
    my @notcached = ();
    if ($GLPlugin::SNMP::session->version() == 3) {
      $params{-contextengineid} = $self->opts->contextengineid if $self->opts->contextengineid;
      $params{-contextname} = $self->opts->contextname if $self->opts->contextname;
    }
    $self->debug(sprintf "get_table %s", Data::Dumper::Dumper(\%params));
    my $result = $GLPlugin::SNMP::session->get_table(%params);
    $self->debug(sprintf "get_table returned %d oids", scalar(keys %{$result}));
    if (scalar(keys %{$result}) == 0) {
      $self->debug(sprintf "get_table error: %s", 
          $GLPlugin::SNMP::session->error());
      $self->debug("get_table error: try fallback");
      $params{'-maxrepetitions'} = 1;
      $self->debug(sprintf "get_table %s", Data::Dumper::Dumper(\%params));
      $result = $GLPlugin::SNMP::session->get_table(%params);
      $self->debug(sprintf "get_table returned %d oids", scalar(keys %{$result}));
      if (scalar(keys %{$result}) == 0) {
        $self->debug(sprintf "get_table error: %s", 
            $GLPlugin::SNMP::session->error());
        $self->debug("get_table error: no more fallbacks. Try --protocol 1");
      }
    }
    # Drecksstinkstiefel Net::SNMP
    # '1.3.6.1.2.1.2.2.1.22.4 ' => 'endOfMibView',
    # '1.3.6.1.2.1.2.2.1.22.4' => '0.0',
    foreach my $key (keys %{$result}) {
      if (substr($key, -1) eq " ") {
        my $value = $result->{$key};
        delete $result->{$key};
        (my $shortkey = $key) =~ s/\s+$//g;
        if (! exists $result->{shortkey}) {
          $result->{$shortkey} = $value;
        }
        $self->add_rawdata($key, $result->{$key}) if exists $result->{$key};
      } else {
        $self->add_rawdata($key, $result->{$key});
      }
    }
  }
  return $self->get_matching_oids(
      -columns => [$params{'-baseoid'}]);
}

################################################################
# helper functions
# 
sub valid_response {
  my $self = shift;
  my $mib = shift;
  my $oid = shift;
  my $index = shift;
  if (exists $GLPlugin::SNMP::mibs_and_oids->{$mib} &&
      exists $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$oid}) {
    # make it numerical
    my $oid = $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$oid};
    if (defined $index) {
      $oid .= '.'.$index;
    }
    my $result = $self->get_request(
        -varbindlist => [$oid]
    );
    if (!defined($result) ||
        ! defined $result->{$oid} ||
        $result->{$oid} eq 'noSuchInstance' ||
        $result->{$oid} eq 'noSuchObject' ||
        $result->{$oid} eq 'endOfMibView') {
      return undef;
    } else {
      $self->add_rawdata($oid, $result->{$oid});
      return $result->{$oid};
    }
  } else {
    return undef;
  }
}

# make_symbolic
# mib is the name of a mib (must be in mibs_and_oids)
# result is a hash-key oid->value
# indices is a array ref of array refs. [[1],[2],...] or [[1,0],[1,1],[2,0]..
sub make_symbolic {
  my $self = shift;
  my $mib = shift;
  my $result = shift;
  my $indices = shift;
  my @entries = ();
  if (! wantarray && ref(\$result) eq "SCALAR" && ref(\$indices) eq "SCALAR") {
    # $self->make_symbolic('CISCO-IETF-NAT-MIB', 'cnatProtocolStatsName', $self->{cnatProtocolStatsName});
    my $oid = $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$result};
    $result = { $oid => $self->{$result} };
    $indices = [[]];
  }
  foreach my $index (@{$indices}) {
    # skip [], [[]], [[undef]]
    if (ref($index) eq "ARRAY") {
      if (scalar(@{$index}) == 0) {
        next;
      } elsif (!defined $index->[0]) {
        next;
      }
    }
    my $mo = {};
    my $idx = join('.', @{$index}); # index can be multi-level
    foreach my $symoid
        (keys %{$GLPlugin::SNMP::mibs_and_oids->{$mib}}) {
      my $oid = $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid};
      if (ref($oid) ne 'HASH') {
        my $fulloid = $oid . '.'.$idx;
        if (exists $result->{$fulloid}) {
          if (exists $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid.'Definition'}) {
            if (ref($GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid.'Definition'}) eq 'HASH') {
              if (exists $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid.'Definition'}->{$result->{$fulloid}}) {
                $mo->{$symoid} = $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid.'Definition'}->{$result->{$fulloid}};
              } else {
                $mo->{$symoid} = 'unknown_'.$result->{$fulloid};
              }
            } elsif ($GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid.'Definition'} =~ /^OID::(.*)/) {
              my $othermib = $1;
              my $value_which_is_a_oid = $result->{$fulloid};
              $value_which_is_a_oid =~ s/^\.//g;
              my @result = grep { $GLPlugin::SNMP::mibs_and_oids->{$othermib}->{$_} eq $value_which_is_a_oid } keys %{$GLPlugin::SNMP::mibs_and_oids->{$othermib}};
              if (scalar(@result)) {
                $mo->{$symoid} = $result[0];
              } else {
                $mo->{$symoid} = 'unknown_'.$result->{$fulloid};
              }
            } elsif ($GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid.'Definition'} =~ /^(.*?)::(.*)/) {
              my $mib = $1;
              my $definition = $2;
              if  (exists $GLPlugin::SNMP::definitions->{$mib} && exists $GLPlugin::SNMP::definitions->{$mib}->{$definition}
                  && exists $GLPlugin::SNMP::definitions->{$mib}->{$definition}->{$result->{$fulloid}}) {
                $mo->{$symoid} = $GLPlugin::SNMP::definitions->{$mib}->{$definition}->{$result->{$fulloid}};
              } else {
                $mo->{$symoid} = 'unknown_'.$result->{$fulloid};
              }
            } else {
              $mo->{$symoid} = 'unknown_'.$result->{$fulloid};
              # oder $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid.'Definition'}?
            }
          } else {
            $mo->{$symoid} = $result->{$fulloid};
          }
        }
      }
    }
    push(@entries, $mo);
  }
  if (@{$indices} and scalar(@{$indices}) == 1 and !defined $indices->[0]->[0]) {
    my $mo = {};
    foreach my $symoid
        (keys %{$GLPlugin::SNMP::mibs_and_oids->{$mib}}) {
      my $oid = $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid};
      if (ref($oid) ne 'HASH') {
        if (exists $result->{$oid}) {
          if (exists $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid.'Definition'}) {
            if (ref($GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid.'Definition'}) eq 'HASH') {
              if (exists $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid.'Definition'}->{$result->{$oid}}) {
                $mo->{$symoid} = $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid.'Definition'}->{$result->{$oid}};
                push(@entries, $mo);
              }
            } elsif ($GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid.'Definition'} =~ /^(.*?)::(.*)/) {
              my $mib = $1;
              my $definition = $2;
              if  (exists $GLPlugin::SNMP::definitions->{$mib} && exists $GLPlugin::SNMP::definitions->{$mib}->{$definition}
                  && exists $GLPlugin::SNMP::definitions->{$mib}->{$definition}->{$result->{$oid}}) {
                $mo->{$symoid} = $GLPlugin::SNMP::definitions->{$mib}->{$definition}->{$result->{$oid}};
              } else {
                $mo->{$symoid} = 'unknown_'.$result->{$oid};
              }
            } else {
              $mo->{$symoid} = 'unknown_'.$result->{$oid};
              # oder $GLPlugin::SNMP::mibs_and_oids->{$mib}->{$symoid.'Definition'}?
            }
          }
        }
      }
    }
    push(@entries, $mo) if keys %{$mo};
  }
  if (wantarray) {
    return @entries;
  } else {
    foreach my $entry (@entries) {
      foreach my $key (keys %{$entry}) {
        $self->{$key} = $entry->{$key};
      }
    }
  }
}

sub sort_oids {
  my $self = shift;
  my $oids = shift || [];
  my @sortedkeys = map { $_->[0] }
      sort { $a->[1] cmp $b->[1] }
          map { [$_,
                  join '', map { sprintf("%30d",$_) } split( /\./, $_)
                ] } @{$oids};
  return @sortedkeys;
}

sub get_matching_oids {
  my $self = shift;
  my %params = @_;
  my $result = {};
  $self->debug(sprintf "get_matching_oids %s", Data::Dumper::Dumper(\%params));
  foreach my $oid (@{$params{'-columns'}}) {
    my $oidpattern = $oid;
    $oidpattern =~ s/\./\\./g;
    map { $result->{$_} = $GLPlugin::SNMP::rawdata->{$_} }
        grep /^$oidpattern(?=\.|$)/, keys %{$GLPlugin::SNMP::rawdata};
  }
  $self->debug(sprintf "get_matching_oids returns %d from %d oids", 
      scalar(keys %{$result}), scalar(keys %{$GLPlugin::SNMP::rawdata}));
  return $result;
}

sub get_indices {
  my $self = shift;
  my %params = @_;
  # -baseoid : entry
  # find all oids beginning with $entry
  # then skip one field for the sequence
  # then read the next numindices fields
  my $entrypat = $params{'-baseoid'};
  $entrypat =~ s/\./\\\./g;
  my @indices = map {
      /^$entrypat\.\d+\.(.*)/ && $1;
  } grep {
      /^$entrypat/
  } keys %{$GLPlugin::SNMP::rawdata};
  my %seen = ();
  my @o = map {[split /\./]} sort grep !$seen{$_}++, @indices;
  return @o;
}

# this flattens a n-dimensional array and returns the absolute position
# of the element at position idx1,idx2,...,idxn
# element 1,2 in table 0,0 0,1 0,2 1,0 1,1 1,2 2,0 2,1 2,2 is at pos 6
sub get_number {
  my $self = shift;
  my $indexlists = shift; #, zeiger auf array aus [1, 2]
  my @element = @_;
  my $dimensions = scalar(@{$indexlists->[0]});
  my @sorted = ();
  my $number = 0;
  if ($dimensions == 1) {
    @sorted =
        sort { $a->[0] <=> $b->[0] } @{$indexlists};
  } elsif ($dimensions == 2) {
    @sorted =
        sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @{$indexlists};
  } elsif ($dimensions == 3) {
    @sorted =
        sort { $a->[0] <=> $b->[0] ||
               $a->[1] <=> $b->[1] ||
               $a->[2] <=> $b->[2] } @{$indexlists};
  }
  foreach (@sorted) {
    if ($dimensions == 1) {
      if ($_->[0] == $element[0]) {
        last;
      }
    } elsif ($dimensions == 2) {
      if ($_->[0] == $element[0] && $_->[1] == $element[1]) {
        last;
      }
    } elsif ($dimensions == 3) {
      if ($_->[0] == $element[0] &&
          $_->[1] == $element[1] &&
          $_->[2] == $element[2]) {
        last;
      }
    }
    $number++;
  }
  return ++$number;
}

################################################################
# caching functions
# 
sub set_rawdata {
  my $self = shift;
  $GLPlugin::SNMP::rawdata = shift;
}

sub add_rawdata {
  my $self = shift;
  my $oid = shift;
  my $value = shift;
  $GLPlugin::SNMP::rawdata->{$oid} = $value;
}

sub rawdata {
  my $self = shift;
  return $GLPlugin::SNMP::rawdata;
}

sub add_oidtrace {
  my $self = shift;
  my $oid = shift;
  $self->debug("cache: ".$oid);
  push(@{$GLPlugin::SNMP::oidtrace}, $oid);
}

#  $self->update_entry_cache(0, $mib, $table, $key_attr);
#  my @indices = $self->get_cache_indices();
sub get_cache_indices {
  my $self = shift;
  my $mib = shift;
  my $table = shift;
  my $key_attr = shift;
  if (ref($key_attr) ne "ARRAY") {
    $key_attr = [$key_attr];
  }
  my $cache = sprintf "%s_%s_%s_cache", 
      $mib, $table, join('#', @{$key_attr});
  my @indices = ();
  foreach my $key (keys %{$self->{$cache}}) {
    my ($descr, $index) = split('-//-', $key, 2);
    if ($self->opts->name) {
      if ($self->opts->regexp) {
        my $pattern = $self->opts->name;
        if ($descr =~ /$pattern/i) {
          push(@indices, $self->{$cache}->{$key});
        }
      } else {
        if ($self->opts->name =~ /^\d+$/) {
          if ($index == 1 * $self->opts->name) {
            push(@indices, [1 * $self->opts->name]);
          }
        } else {
          if (lc $descr eq lc $self->opts->name) {
            push(@indices, $self->{$cache}->{$key});
          }
        }
      }
    } else {
      push(@indices, $self->{$cache}->{$key});
    }
  }
  return @indices;
  return map { join('.', ref($_) eq "ARRAY" ? @{$_} : $_) } @indices;
}


package GLPlugin::SNMP::CSF;
#our @ISA = qw(GLPlugin::SNMP);
use Digest::MD5 qw(md5_hex);
use strict;

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
  if ($self->opts->snmpwalk && ! $self->opts->hostname) {
    return sprintf "%s/%s_%s%s", $self->statefilesdir(),
        'snmpwalk.file'.md5_hex($self->opts->snmpwalk),
        $self->opts->mode, lc $extension;
  } elsif ($self->opts->snmpwalk && $self->opts->hostname eq "walkhost") {
    return sprintf "%s/%s_%s%s", $self->statefilesdir(),
        'snmpwalk.file'.md5_hex($self->opts->snmpwalk),
        $self->opts->mode, lc $extension;
  } else {
    return sprintf "%s/%s_%s%s", $self->statefilesdir(),
        $self->opts->hostname, $self->opts->mode, lc $extension;
  }
}

package GLPlugin::SNMP::Item;
our @ISA = qw(GLPlugin::SNMP::CSF GLPlugin::Item GLPlugin::SNMP);
use strict;


package GLPlugin::SNMP::TableItem;
our @ISA = qw(GLPlugin::SNMP::CSF GLPlugin::TableItem GLPlugin::SNMP);
use strict;

sub ensure_index {
  my $self = shift;
  my $key = shift;
  $self->{$key} ||= $self->{flat_indices};
}

sub unhex_ip {
  my $self = shift;
  my $value = shift;
  if ($value && $value =~ /^0x(\w{8})/) {
    $value = join(".", unpack "C*", pack "H*", $1);
  } elsif ($value && $value =~ /^0x(\w{2} \w{2} \w{2} \w{2})/) {
    $value = $1;
    $value =~ s/ //g;
    $value = join(".", unpack "C*", pack "H*", $value);
  } elsif ($value && unpack("H8", $value) =~ /(\w{2})(\w{2})(\w{2})(\w{2})/) {
    $value = join(".", map { hex($_) } ($1, $2, $3, $4));
  }
  return $value;
}

sub unhex_mac {
  my $self = shift;
  my $value = shift;
  if ($value && $value =~ /^0x(\w{12})/) {
    $value = join(".", unpack "C*", pack "H*", $1);
  } elsif ($value && $value =~ /^0x(\w{2}\s*\w{2}\s*\w{2}\s*\w{2}\s*\w{2}\s*\w{2})/) {
    $value = $1;
    $value =~ s/ //g;
    $value = join(":", unpack "C*", pack "H*", $value);
  } elsif ($value && unpack("H12", $value) =~ /(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})/) {
    $value = join(":", map { hex($_) } ($1, $2, $3, $4, $5, $6));
  }
  return $value;
}


