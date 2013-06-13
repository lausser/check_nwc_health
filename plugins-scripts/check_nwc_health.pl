#! /usr/bin/perl

use strict;
use Digest::MD5 qw(md5_hex);;

use vars qw ($PROGNAME $REVISION $CONTACT $TIMEOUT $STATEFILESDIR $needs_restart %commandline);

$PROGNAME = "check_nwc_health";
$REVISION = '$Revision: #PACKAGE_VERSION# $';
$CONTACT = 'gerhard.lausser@consol.de';
$TIMEOUT = 60;
$STATEFILESDIR = '/var/tmp/check_nwc_health';

use constant OK         => 0;
use constant WARNING    => 1;
use constant CRITICAL   => 2;
use constant UNKNOWN    => 3;
use constant DEPENDENT  => 4;

my @modes = (
  ['device::uptime',
      'uptime', undef,
      'Check the uptime of the device' ],
  ['device::hardware::health',
      'hardware-health', undef,
      'Check the status of environmental equipment (fans, temperatures, power)' ],
  ['device::hardware::load',
      'cpu-load', ['cpu-usage'],
      'Check the CPU load of the device' ],
  ['device::hardware::memory',
      'memory-usage', undef,
      'Check the memory usage of the device' ],
#  ['device::interfaces::traffic',
#      'interface-traffic', undef,
#      'Check the in- and outgoing traffic on interfaces' ],
  ['device::interfaces::usage',
      'interface-usage', undef,
      'Check the utilization of interfaces' ],
  ['device::interfaces::errors',
      'interface-errors', undef,
      'Check the error-rate of interfaces (errors+discards per sec)' ],
  ['device::interfaces::operstatus',
      'interface-status', undef,
      'Check the status of interfaces' ],
  ['device::interfaces::list',
      'list-interfaces', undef,
      'Show the interfaces of the device and update the name cache' ],
  ['device::interfaces::listdetail',
      'list-interfaces-detail', undef,
      'Show the interfaces of the device and some details' ],
  ['device::interfaces::availability',
      'interface-availability', undef,
      'Show the availability (oper != up) of interfaces' ],
  ['device::interfaces::aggregation::availability',
      'link-aggregation-availability', undef,
      'Check the percentage of up interfaces in a link aggregation' ],
  ['device::shinken::interface',
      'create-shinken-service', undef,
      'Create a Shinken service definition' ],
  ['device::hsrp::state',
      'hsrp-state', undef,
      'Check the state in a HSRP group' ],
  ['device::hsrp::failover',
      'hsrp-failover', undef,
      'Check if a HSRP group\'s nodes have changed their roles' ],
  ['device::hsrp::list',
      'list-hsrp-groups', undef,
      'Show the HSRP groups configured on this device' ],
  ['device::ha::role',
      'ha-role', undef,
      'Check the role in a ha group' ],
  ['device::svn::status',
      'svn-status', undef,
      'Check the status of the svn subsystem' ],
  ['device::mngmt::status',
      'mngmt-status', undef,
      'Check the status of the management subsystem' ],
  ['device::fw::policy::installed',
      'fw-policy', undef,
      'Check the installed firewall policy' ],
  ['device::fw::policy::connections',
      'fw-connections', undef,
      'Check the number of firewall policy connections' ],
  ['device::lb::pool::completeness',
      'pool-completeness', undef,
      'Check the members of a load balancer pool' ],
  ['device::security',
      'security-status', undef,
      'Check if there are security-relevant incidents' ],
  ['device::lb::pool::list',
      'list-pools', undef,
      'List load balancer pools' ],
  ['device::wlan::aps::status',
      'accesspoint-status', undef,
      'Check the status of access points' ],
  ['device::wlan::aps::count',
      'count-accesspoints', undef,
      'Check if the number of access points is within a certain range' ],
  ['device::wlan::aps::watch',
      'watch-accesspoints', undef,
      'Check if access points appear and disappear (use --lookup)' ],
  ['device::wlan::aps::list',
      'list-accesspoints', undef,
      'List access points managed by this device' ],
  ['device::smarthome::device::list',
      'list-smart-home-devices', undef,
      'List Fritz!DECT 200 plugs managed by this device' ],
  ['device::smarthome::device::status',
      'smart-home-device-status', undef,
      'Check if a Fritz!DECT 200 plug is on' ],
  ['device::smarthome::device::energy',
      'smart-home-device-energy', undef,
      'Show the current power consumption of a Fritz!DECT 200 plug' ],
  ['device::smarthome::device::consumption',
      'smart-home-device-consumption', undef,
      'Show the cumulated power consumption of a Fritz!DECT 200 plug' ],
  ['device::walk',
      'walk', undef,
      'Show snmpwalk command with the oids necessary for a simulation' ],
  # todo device::modules::{filtering,management,ha,svn}
);
my $modestring = "";
my $longest = length ((reverse sort {length $a <=> length $b} map { $_->[1] } @modes)[0]);
my $format = "       %-".
  (length ((reverse sort {length $a <=> length $b} map { $_->[1] } @modes)[0])).
  "s\t(%s)\n";
foreach (@modes) {
  $modestring .= sprintf $format, $_->[1], $_->[3];
}
$modestring .= sprintf "\n";


my $plugin = Nagios::MiniPlugin->new(
    shortname => '',
    usage => 'Usage: %s [ -v|--verbose ] [ -t <timeout> ] '.
        '--mode <what-to-do> '.
        '--hostname <network-component> --community <snmp-community>'.
        '  ...]',
    version => $REVISION,
    blurb => 'This plugin checks various parameters of network components ',
    url => 'http://labs.consol.de/nagios/check_nwc_health',
    timeout => 60,
    shortname => '',
);
$plugin->add_arg(
    spec => 'blacklist|b=s',
    help => '--blacklist
   Blacklist some (missing/failed) components',
    required => 0,
    default => '',
);
#$plugin->add_arg(
#    spec => 'customthresholds|c=s',
#    help => '--customthresholds
#   Use custom thresholds for certain temperatures',
#    required => 0,
#);
#$plugin->add_arg(
#    spec => 'perfdata=s',
#    help => '--perfdata=[short]
#   Output performance data. If your performance data string becomes
#   too long and is truncated by Nagios, then you can use --perfdata=short
#   instead. This will output temperature tags without location information',
#    required => 0,
#);
$plugin->add_arg(
    spec => 'hostname|H=s',
    help => '--hostname
   Hostname or IP-address of the switch or router',
    required => 0,
);
$plugin->add_arg(
    spec => 'port=i',
    help => '--port
   The SNMP port to use (default: 161)',
    required => 0,
    default => 161,
);
$plugin->add_arg(
    spec => 'domain=s',
    help => '--domain
   The transport domain to use (default: udp/ipv4, other possible values: udp6, udp/ipv6, tcp, tcp4, tcp/ipv4, tcp6, tcp/ipv6)',
    required => 0,
    default => 'udp',
);
$plugin->add_arg(
    spec => 'protocol|P=s',
    help => '--protocol
   The SNMP protocol to use (default: 2c, other possibilities: 1,3)',
    required => 0,
    default => '2c',
);
$plugin->add_arg(
    spec => 'community|C=s',
    help => '--community
   SNMP community of the server (SNMP v1/2 only)',
    required => 0,
    default => 'public',
);
$plugin->add_arg(
    spec => 'username=s',
    help => '--username
   The securityName for the USM security model (SNMPv3 only)',
    required => 0,
);
$plugin->add_arg(
    spec => 'authpassword=s',
    help => '--authpassword
   The authentication password for SNMPv3',
    required => 0,
);
$plugin->add_arg(
    spec => 'authprotocol=s',
    help => '--authprotocol
   The authentication protocol for SNMPv3 (md5|sha)',
    required => 0,
);
$plugin->add_arg(
    spec => 'privpassword=s',
    help => '--privpassword
   The password for authPriv security level',
    required => 0,
);
$plugin->add_arg(
    spec => 'privprotocol=s',
    help => '--privprotocol
   The private protocol for SNMPv3 (des|aes|aes128|3des|3desde)',
    required => 0,
);
$plugin->add_arg(
    spec => 'warning=s',
    help => '--warning
   The warning threshold',
    required => 0,
);
$plugin->add_arg(
    spec => 'mode=s',
    help => "--mode
   A keyword which tells the plugin what to do
$modestring",
    required => 1,
);
$plugin->add_arg(
    spec => 'name=s',
    help => "--name
   The name of an interface (ifDescr)",
    required => 0,
);
$plugin->add_arg(
    spec => 'alias=s',
    help => "--alias
   The alias name of a 64bit-interface (ifAlias)",
    required => 0,
);
$plugin->add_arg(
    spec => 'regexp',
    help => "--regexp
   A flag indicating that --name is a regular expression",
    required => 0,
);
$plugin->add_arg(
    spec => 'ifspeedin=i',
    help => "--ifspeedin
   Override the ifspeed oid of an interface (only inbound)",
    required => 0,
);
$plugin->add_arg(
    spec => 'ifspeedout=i',
    help => "--ifspeedout
   Override the ifspeed oid of an interface (only outbound)",
    required => 0,
);
$plugin->add_arg(
    spec => 'ifspeed=i',
    help => "--ifspeed
   Override the ifspeed oid of an interface",
    required => 0,
);
$plugin->add_arg(
    spec => 'units=s',
    help => "--units
   One of %, B, KB, MB, GB, Bit, KBi, MBi, GBi. (used for e.g. mode interface-usage)",
    required => 0,
);
$plugin->add_arg(
    spec => 'role=s',
    help => "--role
   The role of this device in a hsrp group (active/standby/listen)",
    required => 0,
);
$plugin->add_arg(
    spec => 'report=s',
    help => "--report
   Can be used to shorten the output",
    required => 0,
    default => 'long',
);
$plugin->add_arg(
    spec => 'lookback=s',
    help => "--lookback
   The amount of time you want to look back when calculating average rates.
   Use it for mode interface-errors or interface-usage. Without --lookback
   the time between two runs of check_nwc_health is the base for calculations.
   If you want your checkresult to be based for example on the past hour,
   use --lookback 3600. ",
    required => 0,
);
$plugin->add_arg(
    spec => 'critical=s',
    help => '--critical
   The critical threshold',
    required => 0,
);
$plugin->add_arg(
    spec => 'mitigation=s',
    help => "--mitigation
   The parameter allows you to change a critical error to a warning.",
    required => 0,
);
$plugin->add_arg(
    spec => 'servertype=s',
    help => '--servertype
   The type of the network device: cisco (default). Use it if auto-detection
   is not possible',
    required => 0,
);
$plugin->add_arg(
    spec => 'statefilesdir=s',
    help => '--statefilesdir
   An alternate directory where the plugin can save files',
    required => 0,
);
$plugin->add_arg(
    spec => 'snmpwalk=s',
    help => '--snmpwalk
   A file with the output of a snmpwalk (used for simulation)
   Use it instead of --hostname',
    required => 0,
);
$plugin->add_arg(
    spec => 'snmphelp',
    help => '--snmphelp
   Output the list of OIDs you need to walk for a simulation file',
    required => 0,
);
$plugin->add_arg(
    spec => 'multiline',
    help => '--multiline
   Multiline output',
    required => 0,
);

$plugin->getopts();
if ($plugin->opts->multiline) {
  $ENV{NRPE_MULTILINESUPPORT} = 1;
} else {
  $ENV{NRPE_MULTILINESUPPORT} = 0;
}
if ($plugin->opts->snmphelp) {
  my @subtrees = ("1");
  foreach my $mib (keys %{$NWC::Device::mibs_and_oids}) {
    foreach my $table (grep {/Table$/} keys %{$NWC::Device::mibs_and_oids->{$mib}}) {
      push(@subtrees, $NWC::Device::mibs_and_oids->{$mib}->{$table});
    }
  }
  printf "snmpwalk -On ... %s\n", join(" ", @subtrees);
  printf "snmpwalk -On ... %s\n", join(" ", @subtrees);
  exit 0;
}
if ($plugin->opts->community) {
  if ($plugin->opts->community =~ /^snmpv3(.)(.+)/) {
    my $separator = $1;
    my ($authprotocol, $authpassword, $privprotocol, $privpassword, $username) =
        split(/$separator/, $2);
    $plugin->override_opt('authprotocol', $authprotocol) 
        if defined($authprotocol) && $authprotocol;
    $plugin->override_opt('authpassword', $authpassword) 
        if defined($authpassword) && $authpassword;
    $plugin->override_opt('privprotocol', $privprotocol) 
        if defined($privprotocol) && $privprotocol;
    $plugin->override_opt('privpassword', $privpassword) 
        if defined($privpassword) && $privpassword;
    $plugin->override_opt('username', $username) 
        if defined($username) && $username;
    $plugin->override_opt('protocol', '3') ;
  }
}
if ($plugin->opts->snmpwalk) {
  $plugin->override_opt('hostname', 'snmpwalk.file'.md5_hex($plugin->opts->snmpwalk)) 
}
if (! $plugin->opts->statefilesdir) {
  if (exists $ENV{OMD_ROOT}) {
    $plugin->override_opt('statefilesdir', $ENV{OMD_ROOT}."/var/tmp/check_nwc_health");
  } else {
    $plugin->override_opt('statefilesdir', $STATEFILESDIR);
  }
}


$plugin->{messages}->{unknown} = []; # wg. add_message(UNKNOWN,...)

$plugin->{info} = []; # gefrickel

if ($plugin->opts->mode =~ /^my-([^\-.]+)/) {
  my $param = $plugin->opts->mode;
  $param =~ s/\-/::/g;
  push(@modes, [$param, $plugin->opts->mode, undef, 'my extension']);
} elsif ($plugin->opts->mode eq 'encode') {
  my $input = <>;
  chomp $input;
  $input =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
  printf "%s\n", $input;
  exit 0;
} elsif ((! grep { $plugin->opts->mode eq $_ } map { $_->[1] } @modes) &&
    (! grep { $plugin->opts->mode eq $_ } map { defined $_->[2] ? @{$_->[2]} : () } @modes)) {
  printf "UNKNOWN - mode %s\n", $plugin->opts->mode;
  $plugin->opts->print_help();
  exit 3;
}
if ($plugin->opts->name && $plugin->opts->name =~ /(%22)|(%27)/) {
  my $name = $plugin->opts->name;
  $name =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
  $plugin->override_opt('name', $name);
}

$SIG{'ALRM'} = sub {
  printf "UNKNOWN - check_nwc_health timed out after %d seconds\n", 
      $plugin->opts->timeout;
  exit $ERRORS{UNKNOWN};
};
alarm($plugin->opts->timeout);

$NWC::Device::plugin = $plugin;
$NWC::Device::mode = (
    map { $_->[0] }
    grep {
       ($plugin->opts->mode eq $_->[1]) ||
       ( defined $_->[2] && grep { $plugin->opts->mode eq $_ } @{$_->[2]})
    } @modes
)[0];
my $server = NWC::Device->new( runtime => {

    plugin => $plugin,
    options => {
        servertype => $plugin->opts->servertype,
        verbose => $plugin->opts->verbose,
        customthresholds => $plugin->opts->get('customthresholds'),
        blacklist => $plugin->opts->blacklist,
#        celsius => $CELSIUS,
#        perfdata => $PERFDATA,
#        extendedinfo => $EXTENDEDINFO,
#        hwinfo => $HWINFO,
#        noinstlevel => $NOINSTLEVEL,
    },
},);
#$server->dumper();
if (! $plugin->check_messages()) {
  $server->init();
  if (! $plugin->check_messages()) {
    $plugin->add_message(OK, $server->get_summary()) 
        if $server->get_summary();
    $plugin->add_message(OK, $server->get_extendedinfo()) 
        if $server->get_extendedinfo();
  } 
} else {
  $plugin->add_message(CRITICAL, 'wrong device');
}
my ($code, $message) = $plugin->opts->multiline ? 
    $plugin->check_messages(join => "\n", join_all => ', ') :
    $plugin->check_messages(join => ', ', join_all => ', ');
$message .= sprintf "\n%s\n", join("\n", @{$NWC::Device::info})
    if $plugin->opts->verbose >= 1;
#printf "%s\n", Data::Dumper::Dumper($plugin->{info});
$plugin->nagios_exit($code, $message);

