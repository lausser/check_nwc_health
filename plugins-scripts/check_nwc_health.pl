# /usr/bin/perl -w

use strict;
no warnings qw(once);

if ( ! grep /BEGIN/, keys %Monitoring::GLPlugin::) {
  eval {
    require Monitoring::GLPlugin;
    require Monitoring::GLPlugin::SNMP;
    require Monitoring::GLPlugin::UPNP;
  };
  if ($@) {
    printf "UNKNOWN - module Monitoring::GLPlugin was not found. Either build a standalone version of this plugin or set PERL5LIB\n";
    printf "%s\n", $@;
    exit 3;
  }
}

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
    plugin => $Monitoring::GLPlugin::pluginname,
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
    internal => 'device::disk::usage',
    spec => 'disk-usage',
    alias => undef,
    help => 'Check the disk usage of the device',
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
    help => 'Check the error-rate of interfaces (without discards)',
);
$plugin->add_mode(
    internal => 'device::interfaces::discards',
    spec => 'interface-discards',
    alias => undef,
    help => 'Check the discard-rate of interfaces',
);
$plugin->add_mode(
    internal => 'device::interfaces::operstatus',
    spec => 'interface-status',
    alias => undef,
    help => 'Check the status of interfaces (oper/admin)',
);
$plugin->add_mode(
    internal => 'device::interfaces::duplex',
    spec => 'interface-duplex',
    alias => undef,
    help => 'Check if interfaces operate in duplex mode',
);
$plugin->add_mode(
    internal => 'device::interfaces::complete',
    spec => 'interface-health',
    alias => undef,
    help => 'Check everything interface',
);
$plugin->add_mode(
    internal => 'device::interfaces::nat::sessions::count',
    spec => 'interface-nat-count-sessions',
    alias => undef,
    help => 'Count the number of nat sessions',
);
$plugin->add_mode(
    internal => 'device::interfaces::nat::rejects',
    spec => 'interface-nat-rejects',
    alias => undef,
    help => 'Count the number of nat sessions rejected due to lack of resources',
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
    internal => 'device::interfaces::ifstack::status',
    spec => 'interface-stack-status',
    alias => undef,
    help => 'Check the status of interface sublayers (mostly layer 2)',
);
$plugin->add_mode(
    internal => 'device::interfaces::ifstack::availability',
    spec => 'interface-stack-availability',
    alias => undef,
    help => 'Check the percentage of available sublayer interfaces',
);
$plugin->add_mode(
    internal => 'device::interfaces::etherstats',
    spec => 'interface-etherstats',
    alias => undef,
    help => 'Check the ethernet statistics of interfaces',
);
$plugin->add_mode(
    internal => 'device::interfaces::uptime',
    spec => 'interface-uptime',
    alias => undef,
    help => 'Check state changes of interfaces',
);
$plugin->add_mode(
    internal => 'device::interfaces::portsecurity',
    spec => 'interface-security',
    alias => undef,
    help => 'Check interfaces for security violations',
);
$plugin->add_mode(
    internal => 'device::routes::list',
    spec => 'list-routes',
    alias => undef,
    help => 'Show the configured routes',
    help => 'Check the percentage of up interfaces in a link aggregation',
);
$plugin->add_mode(
    internal => 'device::routes::exists',
    spec => 'route-exists',
    alias => undef,
    help => 'Check if a route exists. (--name is the dest, --name2 check also the next hop)',
);
$plugin->add_mode(
    internal => 'device::routes::count',
    spec => 'count-routes',
    alias => undef,
    help => 'Count the routes. (--name is the dest, --name2 is the hop)',
);
$plugin->add_mode(
    internal => 'device::vpn::status',
    spec => 'vpn-status',
    alias => undef,
    help => 'Check the status of vpns (up/down)',
);
$plugin->add_mode(
    internal => 'device::fcinterfaces::usage',
    spec => 'fc-interface-usage',
    alias => undef,
    help => 'Check the utilization of fibrechannel interfaces',
);
$plugin->add_mode(
    internal => 'device::fcinterfaces::errors',
    spec => 'fc-interface-errors',
    alias => undef,
    help => 'Check the error-rate of fibrechannel interfaces',
);
$plugin->add_mode(
    internal => 'device::fcinterfaces::discards',
    spec => 'fc-interface-discards',
    alias => undef,
    help => 'Check the discard-rate of interfaces',
);
$plugin->add_mode(
    internal => 'device::fcinterfaces::operstatus',
    spec => 'fc-interface-status',
    alias => undef,
    help => 'Check the status of interfaces (oper/admin)',
);
$plugin->add_mode(
    internal => 'device::fcinterfaces::complete',
    spec => 'fc-interface-health',
    alias => undef,
    help => 'Check everything interface',
);
$plugin->add_mode(
    internal => 'device::fcinterfaces::list',
    spec => 'fc-list-interfaces',
    alias => undef,
    help => 'Show the fcal interfaces of the device and update the name cache',
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
    internal => 'device::vrrp::state',
    spec => 'vrrp-state',
    alias => undef,
    help => 'Check the state in a VRRP group',
);
$plugin->add_mode(
    internal => 'device::vrrp::failover',
    spec => 'vrrp-failover',
    alias => undef,
    help => 'Check if a VRRP group\'s nodes have changed their roles',
);
$plugin->add_mode(
    internal => 'device::vrrp::list',
    spec => 'list-vrrp-groups',
    alias => undef,
    help => 'Show the VRRP groups configured on this device',
);
$plugin->add_mode(
    internal => 'device::bgp::peer::status',
    spec => 'bgp-peer-status',
    alias => undef,
    help => 'Check status of BGP peers',
);
$plugin->add_mode(
    internal => 'device::bgp::peer::count',
    spec => 'count-bgp-peers',
    alias => undef,
    help => 'Count the number of BGP peers',
);
$plugin->add_mode(
    internal => 'device::bgp::peer::watch',
    spec => 'watch-bgp-peers',
    alias => undef,
    help => 'Watch BGP peers appear and disappear',
);
$plugin->add_mode(
    internal => 'device::bgp::peer::list',
    spec => 'list-bgp-peers',
    alias => undef,
    help => 'Show BGP peers known to this device',
);
$plugin->add_mode(
    internal => 'device::bgp::prefix::count',
    spec => 'count-bgp-prefixes',
    alias => undef,
    help => 'Count the number of BGP prefixes (for specific peer with --name)',
);
$plugin->add_mode(
    internal => 'device::ospf::neighbor::status',
    spec => 'ospf-neighbor-status',
    alias => undef,
    help => 'Check status of OSPF neighbors',
);
$plugin->add_mode(
    internal => 'device::ospf::neighbor::watch',
    spec => 'watch-ospf-neighbors',
    alias => undef,
    help => 'Watch OSPF neighbors appear and disappear',
);
$plugin->add_mode(
    internal => 'device::ospf::neighbor::list',
    spec => 'list-ospf-neighbors',
    alias => undef,
    help => 'Show OSPF neighbors',
);
$plugin->add_mode(
    internal => 'device::eigrp::peer::count',
    spec => 'count-eigrp-peers',
    alias => undef,
    help => 'Count the number of EIGRP peers',
);
$plugin->add_mode(
    internal => 'device::eigrp::peer::status',
    spec => 'eigrp-peer-status',
    alias => undef,
    help => 'Check status (existance) of EIGRP peers',
);
$plugin->add_mode(
    internal => 'device::eigrp::peer::watch',
    spec => 'watch-eigrp-peers',
    alias => undef,
    help => 'Watch EIGRP peers appear and disappear',
);
$plugin->add_mode(
    internal => 'device::eigrp::peer::list',
    spec => 'list-eigrp-peers',
    alias => undef,
    help => 'Show EIGRP peers',
);
$plugin->add_mode(
    internal => 'device::ha::status',
    spec => 'ha-status',
    alias => undef,
    help => 'Check the status of a clustered setup',
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
    internal => 'device::process::status',
    spec => 'process-status',
    alias => undef,
    help => 'Check the status of the running processes'
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
    internal => 'device::lb::pool::connections',
    spec => 'pool-connections',
    alias => undef,
    help => 'Check the number of connections of a load balancer pool',
);
$plugin->add_mode(
    internal => 'device::lb::pool::complections',
    spec => 'pool-complections',
    alias => undef,
    help => 'Check the members and connections of a load balancer pool',
);
$plugin->add_mode(
    internal => 'device::wideip::status',
    spec => 'wideip-status',
    alias => undef,
    help => 'Check the status of F5 Wide IPs',
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
    alias => ['count-connections-client', 'count-connections-server', 'count-sessions'],
    help => 'Check the number of connections/sessions (-client, -server is possible)',
);
$plugin->add_mode(
    internal => 'device::cisco::fex::watch',
    spec => 'watch-fexes',
    alias => undef,
    help => 'Check if FEXes appear and disappear (use --lookup)',
);
$plugin->add_mode(
    internal => 'device::hardware::chassis::health',
    spec => 'chassis-hardware-health',
    alias => undef,
    help => 'Check the status of stacked switches and chassis, count modules and ports',
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
    internal => 'device::wlan::aps::clients',
    spec => 'count-accesspoint-clients',
    alias => undef,
    help => 'Check if the number of access point clients is within a certain range',
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
    help => 'Check if a Fritz!DECT 200 plug is on (or Comet DECT)',
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
    internal => 'device::smarthome::device::temperature',
    spec => 'smart-home-device-temperature',
    alias => undef,
    help => 'Show the temperature measured by a Fritz! compatible device',
);
$plugin->add_default_modes();
$plugin->add_snmp_modes();
$plugin->add_snmp_args();
$plugin->add_default_args();
$plugin->mod_arg("name",
    help => "--name
   The name of an interface (ifDescr) or pool or ...",
);
$plugin->add_arg(
    spec => 'alias=s',
    help => "--alias
   The alias name of a 64bit-interface (ifAlias)",
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
    spec => 'role=s',
    help => "--role
   The role of this device in a hsrp group (active/standby/listen)",
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
  ;
}
my ($code, $message) = $plugin->opts->multiline ?
    $plugin->check_messages(join => "\n", join_all => ', ') :
    $plugin->check_messages(join => ', ', join_all => ', ');
$message .= sprintf "\n%s\n", $plugin->get_info("\n")
    if $plugin->opts->verbose >= 1;

$plugin->nagios_exit($code, $message);
