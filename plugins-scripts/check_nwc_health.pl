# /usr/bin/perl -w

use strict;
use File::Basename;



my $plugin = Classes::Device->new(
    shortname => '',
    usage => 'Usage: %s [ -v|--verbose ] [ -t <timeout> ] '.
        '--mode <what-to-do> '.
        '--hostname <network-component> --community <snmp-community>'.
        '  ...]',
    version => '$Revision: #PACKAGE_VERSION# $',
    blurb => 'This plugin checks various parameters of network components ',
    url => 'http://labs.consol.de/nagios/check_nwc_health',
    timeout => 60,
    plugin => basename($0),
);
$plugin->add_mode(
    internal => 'device::uptime',
    spec => 'uptime',
    alias => undef,
    help => 'Check the uptime of the device',
);
$plugin->add_mode(
    internal => 'device::hardware::health',
    spec => 'hardware-health',
    alias => undef,
    help => 'Check the status of environmental equipment (fans, temperatures, power)',
);
$plugin->add_mode(
    internal => 'device::hardware::load',
    spec => 'cpu-load',
    alias => ['cpu-usage'],
    help => 'Check the CPU load of the device',
);
$plugin->add_mode(
    internal => 'device::hardware::memory',
    spec => 'memory-usage',
    alias => undef,
    help => 'Check the memory usage of the device',
);
$plugin->add_mode(
    internal => 'device::interfaces::usage',
    spec => 'interface-usage',
    alias => undef,
    help => 'Check the utilization of interfaces',
);
$plugin->add_mode(
    internal => 'device::interfaces::errors',
    spec => 'interface-errors',
    alias => undef,
    help => 'Check the error-rate of interfaces (errors+discards per sec)',
);
$plugin->add_mode(
    internal => 'device::interfaces::operstatus',
    spec => 'interface-status',
    alias => undef,
    help => 'Check the status of interfaces (oper/admin)',
);
$plugin->add_mode(
    internal => 'device::interfaces::list',
    spec => 'list-interfaces',
    alias => undef,
    help => 'Show the interfaces of the device and update the name cache',
);
$plugin->add_mode(
    internal => 'device::interfaces::listdetail',
    spec => 'list-interfaces-detail',
    alias => undef,
    help => 'Show the interfaces of the device and some details',
);
$plugin->add_mode(
    internal => 'device::interfaces::availability',
    spec => 'interface-availability',
    alias => undef,
    help => 'Show the availability (oper != up) of interfaces',
);
$plugin->add_mode(
    internal => 'device::interfaces::aggregation::availability',
    spec => 'link-aggregation-availability',
    alias => undef,
    help => 'Check the percentage of up interfaces in a link aggregation',
);
$plugin->add_mode(
    internal => 'device::shinken::interface',
    spec => 'create-shinken-service',
    alias => undef,
    help => 'Create a Shinken service definition',
);
$plugin->add_mode(
    internal => 'device::hsrp::state',
    spec => 'hsrp-state',
    alias => undef,
    help => 'Check the state in a HSRP group',
);
$plugin->add_mode(
    internal => 'device::hsrp::failover',
    spec => 'hsrp-failover',
    alias => undef,
    help => 'Check if a HSRP group\'s nodes have changed their roles',
);
$plugin->add_mode(
    internal => 'device::hsrp::list',
    spec => 'list-hsrp-groups',
    alias => undef,
    help => 'Show the HSRP groups configured on this device',
);
$plugin->add_mode(
    internal => 'device::bgp::peer::status',
    spec => 'bgp-peer-status',
    alias => undef,
    help => 'Check status of BGP peers',
);
$plugin->add_mode(
    internal => 'device::bgp::peer::list',
    spec => 'list-bgp-peers',
    alias => undef,
    help => 'Show BGP peers known to this device',
);
$plugin->add_mode(
    internal => 'device::ha::role',
    spec => 'ha-role',
    alias => undef,
    help => 'Check the role in a ha group',
);
$plugin->add_mode(
    internal => 'device::svn::status',
    spec => 'svn-status',
    alias => undef,
    help => 'Check the status of the svn subsystem',
);
$plugin->add_mode(
    internal => 'device::mngmt::status',
    spec => 'mngmt-status',
    alias => undef,
    help => 'Check the status of the management subsystem',
);
$plugin->add_mode(
    internal => 'device::fw::policy::installed',
    spec => 'fw-policy',
    alias => undef,
    help => 'Check the installed firewall policy',
);
$plugin->add_mode(
    internal => 'device::fw::policy::connections',
    spec => 'fw-connections',
    alias => undef,
    help => 'Check the number of firewall policy connections',
);
$plugin->add_mode(
    internal => 'device::lb::session::usage',
    spec => 'session-usage',
    alias => undef,
    help => 'Check the session limits of a load balancer',
);
$plugin->add_mode(
    internal => 'device::security',
    spec => 'security-status',
    alias => undef,
    help => 'Check if there are security-relevant incidents',
);
$plugin->add_mode(
    internal => 'device::lb::pool::completeness',
    spec => 'pool-completeness',
    alias => undef,
    help => 'Check the members of a load balancer pool',
);
$plugin->add_mode(
    internal => 'device::lb::pool::list',
    spec => 'list-pools',
    alias => undef,
    help => 'List load balancer pools',
);
$plugin->add_mode(
    internal => 'device::licenses::validate',
    spec => 'check-licenses',
    alias => undef,
    help => 'Check the installed licences/keys',
);
$plugin->add_mode(
    internal => 'device::users::count',
    spec => 'count-users',
    alias => ['count-sessions', 'count-connections'],
    help => 'Count the (connected) users/sessions',
);
$plugin->add_mode(
    internal => 'device::config::status',
    spec => 'check-config',
    alias => undef,
    help => 'Check the status of configs (cisco, unsaved config changes)',
);
$plugin->add_mode(
    internal => 'device::connections::check',
    spec => 'check-connections',
    alias => undef,
    help => 'Check the quality of connections',
);
$plugin->add_mode(
    internal => 'device::connections::count',
    spec => 'count-connections',
    alias => ['count-connections-client', 'count-connections-server'],
    help => 'Check the number of connections (-client, -server is possible)',
);
$plugin->add_mode(
    internal => 'device::wlan::aps::status',
    spec => 'accesspoint-status',
    alias => undef,
    help => 'Check the status of access points',
);
$plugin->add_mode(
    internal => 'device::wlan::aps::count',
    spec => 'count-accesspoints',
    alias => undef,
    help => 'Check if the number of access points is within a certain range',
);
$plugin->add_mode(
    internal => 'device::wlan::aps::watch',
    spec => 'watch-accesspoints',
    alias => undef,
    help => 'Check if access points appear and disappear (use --lookup)',
);
$plugin->add_mode(
    internal => 'device::wlan::aps::list',
    spec => 'list-accesspoints',
    alias => undef,
    help => 'List access points managed by this device',
);
$plugin->add_mode(
    internal => 'device::phone::cmstatus',
    spec => 'phone-cm-status',
    alias => undef,
    help => 'Check if the callmanager is up',
);
$plugin->add_mode(
    internal => 'device::phone::status',
    spec => 'phone-status',
    alias => undef,
    help => 'Check the number of registered/unregistered/rejected phones',
);
$plugin->add_mode(
    internal => 'device::smarthome::device::list',
    spec => 'list-smart-home-devices',
    alias => undef,
    help => 'List Fritz!DECT 200 plugs managed by this device',
);
$plugin->add_mode(
    internal => 'device::smarthome::device::status',
    spec => 'smart-home-device-status',
    alias => undef,
    help => 'Check if a Fritz!DECT 200 plug is on',
);
$plugin->add_mode(
    internal => 'device::smarthome::device::energy',
    spec => 'smart-home-device-energy',
    alias => undef,
    help => 'Show the current power consumption of a Fritz!DECT 200 plug',
);
$plugin->add_mode(
    internal => 'device::smarthome::device::consumption',
    spec => 'smart-home-device-consumption',
    alias => undef,
    help => 'Show the cumulated power consumption of a Fritz!DECT 200 plug',
);
$plugin->add_mode(
    internal => 'device::walk',
    spec => 'walk',
    alias => undef,
    help => 'Show snmpwalk command with the oids necessary for a simulation',
);
$plugin->add_arg(
    spec => 'blacklist|b=s',
    help => '--blacklist
   Blacklist some (missing/failed) components',
    required => 0,
    default => '',
);
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
    spec => 'username:s',
    help => '--username
   The securityName for the USM security model (SNMPv3 only)',
    required => 0,
);
$plugin->add_arg(
    spec => 'authpassword:s',
    help => '--authpassword
   The authentication password for SNMPv3',
    required => 0,
);
$plugin->add_arg(
    spec => 'authprotocol:s',
    help => '--authprotocol
   The authentication protocol for SNMPv3 (md5|sha)',
    required => 0,
);
$plugin->add_arg(
    spec => 'privpassword:s',
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
    spec => 'mode=s',
    help => "--mode
   A keyword which tells the plugin what to do",
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
    spec => 'name2=s',
    help => "--name2
   The secondary name of a component",
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
    spec => 'warning=s',
    help => '--warning
   The warning threshold',
    required => 0,
);
$plugin->add_arg(
    spec => 'warningx=s%',
    help => '--warningx
   The extended warning thresholds',
    required => 0,
);
$plugin->add_arg(
    spec => 'criticalx=s%',
    help => '--criticalx
   The extended critical thresholds',
    required => 0,
);
$plugin->add_arg(
    spec => 'mitigation=s',
    help => "--mitigation
   The parameter allows you to change a critical error to a warning.",
    required => 0,
);
$plugin->add_arg(
    spec => 'selectedperfdata=s',
    help => "--selectedperfdata
   The parameter allows you to limit the list of performance data. It's a perl regexp.
   Only matching perfdata show up in the output",
    required => 0,
);
$plugin->add_arg(
    spec => 'negate=s%',
    help => "--negate
   The parameter allows you to map exit levels, such as warning=critical",
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
    spec => 'oids=s',
    help => '--oids
   A list of oids which are downloaded and written to a cache file.
   Use it together with --mode oidcache',
    required => 0,
);
$plugin->add_arg(
    spec => 'offline:i',
    help => '--offline
   The maximum number of seconds since the last update of cache file before
   it is considered too old',
    required => 0,
);
$plugin->add_arg(
    spec => 'multiline',
    help => '--multiline
   Multiline output',
    required => 0,
);


$plugin->getopts();
$plugin->classify();
$plugin->validate_args();


if (! $plugin->check_messages()) {
  $plugin->init();
  if (! $plugin->check_messages()) {
    $plugin->add_ok($plugin->get_summary())
        if $plugin->get_summary();
    $plugin->add_ok($plugin->get_extendedinfo(" "))
        if $plugin->get_extendedinfo();
  }
} elsif ($plugin->opts->snmpwalk && $plugin->opts->offline) {
  ;
} else {
  $plugin->add_critical('wrong device');
}
my ($code, $message) = $plugin->opts->multiline ?
    $plugin->check_messages(join => "\n", join_all => ', ') :
    $plugin->check_messages(join => ', ', join_all => ', ');
$message .= sprintf "\n%s\n", $plugin->get_info("\n")
    if $plugin->opts->verbose >= 1;
#printf "%s\n", Data::Dumper::Dumper($plugin);
$plugin->nagios_exit($code, $message);

