package Classes::Device;
our @ISA = qw(GLPlugin::SNMP);

use strict;
use IO::File;
use File::Basename;
use Digest::MD5  qw(md5_hex);
use Errno;
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
  our $statefilesdir = '/var/tmp/'.basename($0);
  our $oidtrace = [];
  our $uptime = 0;
}

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    productname => 'unknown',
  };
  bless $self, $class;
  if (! ($self->opts->hostname || $self->opts->snmpwalk)) {
    $self->add_message(UNKNOWN, 'either specify a hostname or a snmpwalk file');
  } else {
    $self->check_snmp_and_model();
    if (! $self->check_messages()) {
      if ($self->opts->verbose && $self->opts->verbose) {
        printf "I am a %s\n", $self->{productname};
      }
      if ($self->{productname} =~ /upnp/i) {
        bless $self, 'UPNP';
        $self->debug('using UPNP');
      } elsif ($self->mode =~ /device::uptime/) {
        bless $self, 'GLPlugin::SNMP';
      } elsif ($self->mode =~ /device::interfaces::/) {
        bless $self, 'Classes::Generic';
      } elsif ($self->{productname} =~ /Cisco/i) {
        bless $self, 'Classes::Cisco';
        $self->debug('using Classes::Cisco');
      } elsif ($self->{productname} =~ /fujitsu intelligent blade panel 30\/12/i) {
        bless $self, 'Classes::Cisco';
        $self->debug('using Classes::Cisco');
      } elsif ($self->{productname} =~ /Nortel/i) {
        bless $self, 'Classes::Nortel';
        $self->debug('using Classes::Nortel');
      } elsif ($self->{productname} =~ /AT-GS/i) {
        bless $self, 'Classes::AlliedTelesyn';
        $self->debug('using Classes::AlliedTelesyn');
      } elsif ($self->{productname} =~ /AT-\d+GB/i) {
        bless $self, 'Classes::AlliedTelesyn';
        $self->debug('using Classes::AlliedTelesyn');
      } elsif ($self->{productname} =~ /Allied Telesyn Ethernet Switch/i) {
        bless $self, 'Classes::AlliedTelesyn';
        $self->debug('using Classes::AlliedTelesyn');
      } elsif ($self->{productname} =~ /DS_4100/i) {
        bless $self, 'Classes::Brocade';
        $self->debug('using Classes::Brocade');
      } elsif ($self->{productname} =~ /Connectrix DS_4900B/i) {
        bless $self, 'Classes::Brocade';
        $self->debug('using Classes::Brocade');
      } elsif ($self->{productname} =~ /EMC\s*DS.*4700M/i) {
        bless $self, 'Classes::Brocade';
        $self->debug('using Classes::Brocade');
      } elsif ($self->{productname} =~ /EMC\s*DS-24M2/i) {
        bless $self, 'Classes::Brocade';
        $self->debug('using Classes::Brocade');
      } elsif ($self->{productname} =~ /Brocade.*ICX/i) {
        bless $self, 'Classes::Brocade';
        $self->debug('using Classes::Brocade');
      } elsif ($self->{productname} =~ /Fibre Channel Switch/i) {
        bless $self, 'Classes::Brocade';
        $self->debug('using Classes::Brocade');
      } elsif ($self->{productname} =~ /Juniper.*MAG\-\d+/i) {
        # Juniper Networks,Inc,MAG-4610,7.2R10
        bless $self, 'Classes::Juniper';
        $self->debug('using Classes::Juniper');
      } elsif ($self->{productname} =~ /NetScreen/i) {
        bless $self, 'Classes::Juniper';
        $self->debug('using Classes::Juniper');
      } elsif ($self->{productname} =~ /^(GS|FS)/i) {
        bless $self, 'Classes::Juniper';
        $self->debug('using Classes::Juniper');
      } elsif ($self->get_snmp_object('MIB-II', 'sysObjectID', 0) =~ /^([\d+\.]+)\.\d+$/ && $1 eq  $Classes::Device::mib_ids->{'NETSCREEN-PRODUCTS-MIB'}) {
        $self->debug('using Classes::Juniper::NetScreen');
        bless $self, 'Classes::Juniper::NetScreen';
      } elsif ($self->{productname} =~ /SecureOS/i) {
        bless $self, 'Classes::SecureOS';
        $self->debug('using Classes::SecureOS');
      } elsif ($self->{productname} =~ /Linux.*((el6.f5.x86_64)|(el5.1.0.f5app)) .*/i) {
        bless $self, 'Classes::F5';
        $self->debug('using Classes::F5');
      } elsif ($self->{productname} =~ /Procurve/i) {
        bless $self, 'Classes::HP';
        $self->debug('using Classes::HP');
      } elsif ($self->{productname} =~ /(cpx86_64)|(Check\s*Point)|(Linux.*\dcp )/i) {
        bless $self, 'Classes::CheckPoint';
        $self->debug('using Classes::CheckPoint');
      } elsif ($self->{productname} =~ /Blue\s*Coat/i) {
        bless $self, 'Classes::Bluecoat';
        $self->debug('using Classes::Bluecoat');
      } elsif ($self->{productname} =~ /Foundry/i) {
        bless $self, 'Classes::Foundry';
        $self->debug('using Classes::Foundry');
      } elsif ($self->{productname} =~ /Linux Stingray/i) {
        bless $self, 'Classes::HOSTRESOURCESMIB';
        $self->debug('using Classes::HOSTRESOURCESMIB');
      } elsif ($self->{productname} =~ /Fortinet|Fortigate/i) {
        bless $self, 'Classes::Fortigate';
        $self->debug('using Classes::Fortigate');
      } elsif ($self->{productname} =~ /linuxlocal/i) {
        bless $self, 'Server::Linux';
        $self->debug('using Server::Linux');
      } elsif ($self->{productname} eq "ifmib") {
        bless $self, 'Classes::Generic';
        $self->debug('using Classes::Generic');
      } elsif ($self->get_snmp_object('MIB-II', 'sysObjectID', 0) eq $Classes::Device::mib_ids->{'SW-MIB'}) {
        bless $self, 'Classes::Brocade';
        $self->debug('using Classes::Brocade');
      } elsif ($self->get_snmp_object('MIB-II', 'sysObjectID', 0) =~ /1\.3\.6\.1\.4\.1\.9\./) {
        bless $self, 'Classes::Cisco';
        $self->debug('using Classes::Cisco');
      } else {
        if (my $class = $self->discover_suitable_class()) {
          bless $self, $class;
          $self->debug('using '.$class);
        } else {
          $self->add_message(UNKNOWN, 'the device did not implement the mibs this plugin is asking for');
          $self->add_message(UNKNOWN,
              sprintf('unknown device%s', $self->{productname} eq 'unknown' ?
                  '' : '('.$self->{productname}.')'));
        }
      }
    }
  }
  return $self;
}

