package NWC::CiscoWLC::Component::WlanSubsystem;
our @ISA = qw(NWC::CiscoWLC);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    aps => [],
    ifs => [],
    ifloads => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  my %params = @_;
  my $snmpwalk = $params{rawdata};
  my $ignore_redundancy = $params{ignore_redundancy};
  my $type = 0;
  $self->{name} = $self->get_snmp_object(
     'MIB-II', 'sysName', 0);
  foreach ($self->get_snmp_table_objects(
     'AIRESPACE-WIRELESS-MIB', 'bsnAPTable')) {
    if ($self->filter_name($_->{bsnAPName})) {
      push(@{$self->{aps}},
          NWC::CiscoWLC::Component::WlanSubsystem::AP->new(%{$_}));
    }
  }
  foreach ($self->get_snmp_table_objects(
     'AIRESPACE-WIRELESS-MIB', 'bsnAPIfTable')) {
    push(@{$self->{ifs}},
        NWC::CiscoWLC::Component::WlanSubsystem::IF->new(%{$_}));
  }
  foreach ($self->get_snmp_table_objects(
     'AIRESPACE-WIRELESS-MIB', 'bsnAPIfLoadParametersTable')) {
    push(@{$self->{ifloads}},
        NWC::CiscoWLC::Component::WlanSubsystem::IFLoad->new(%{$_}));
  }
  $self->assign_loads_to_ifs();
  $self->assign_ifs_to_aps();
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking access points');
  $self->blacklist('ap', '');
  $self->{numOfAPs} = scalar (@{$self->{aps}});
  $self->{apNameList} = [map { $_->{bsnAPName} } @{$self->{aps}}];
  if (scalar (@{$self->{aps}}) == 0) {
    $self->add_message(UNKNOWN, 'no access points found');
  } else {
    foreach (@{$self->{aps}}) {
      $_->check();
    }
    if ($self->mode =~ /device::wlan::aps::watch/) {
      $self->valdiff({name => $self->{name}},
          qw(apNameList numOfAPs));
      if (scalar(@{$self->{delta_found_apNameList}}) > 0 &&
          1 # initial
          ) {
        $self->add_message(WARNING, sprintf '%d new access points (%s)',
            scalar(@{$self->{delta_found_apNameList}}),
            join(", ", @{$self->{delta_found_apNameList}}));
      }
      if (scalar(@{$self->{delta_lost_apNameList}}) > 0) {
        $self->add_message(CRITICAL, sprintf '%d access points missing (%s)',
            scalar(@{$self->{delta_lost_apNameList}}),
            join(", ", @{$self->{delta_lost_apNameList}}));
      }
      $self->add_message($self->check_thresholds(
          scalar (@{$self->{aps}})), 
          sprintf 'found %d access points', scalar (@{$self->{aps}}));
      $self->add_perfdata(
          label => 'num_aps',
          value => scalar (@{$self->{aps}}),
      );
    } elsif ($self->mode =~ /device::wlan::aps::count/) {
      $self->set_thresholds(warning => '10:', critical => '5:');
      $self->add_message($self->check_thresholds(
          scalar (@{$self->{aps}})), 
          sprintf 'found %d access points', scalar (@{$self->{aps}}));
      $self->add_perfdata(
          label => 'num_aps',
          value => scalar (@{$self->{aps}}),
          warning => $self->{warning},
          critical => $self->{critical},
      );
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{aps}}) {
    $_->dump();
  }
}

sub assign_ifs_to_aps {
  my $self = shift;
  foreach my $ap (@{$self->{aps}}) {
    $ap->{interfaces} = [];
    foreach my $if (@{$self->{ifs}}) {
      if ($if->{flat_indices} eq $ap->{bsnAPDot3MacAddress}.".".$if->{bsnAPIfSlotId}) {
        push(@{$ap->{interfaces}}, $if);
      }
    }
    $ap->{NumOfClients} = 0;
    map { $ap->{NumOfClients} += $_->{bsnAPIfLoadNumOfClients} }
        @{$ap->{interfaces}};
  }
}

sub assign_loads_to_ifs {
  my $self = shift;
  foreach my $if (@{$self->{ifs}}) {
    foreach my $load (@{$self->{ifloads}}) {
      if ($load->{flat_indices} eq $if->{flat_indices}) {
        map { $if->{$_} = $load->{$_} } grep { $_ !~ /indices/ } keys %{$load};
      }
    }
  }
}

package NWC::CiscoWLC::Component::WlanSubsystem::IF;
our @ISA = qw(NWC::CiscoWLC::Component::WlanSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach (qw(bsnApIfNoOfUsers bsnAPIfPortNumber bsnAPIfAdminStatus bsnAPIfSlotId bsnAPIfType bsnAPIfOperStatus flat_indices)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

package NWC::CiscoWLC::Component::WlanSubsystem::IFLoad;
our @ISA = qw(NWC::CiscoWLC::Component::WlanSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach (keys %params) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

package NWC::CiscoWLC::Component::WlanSubsystem::AP;
our @ISA = qw(NWC::CiscoWLC::Component::WlanSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach (qw(bsnAPName bsnAPLocation bsnAPModel bsnApIpAddress bsnAPSerialNumber
      bsnAPDot3MacAddress bsnAPIOSVersion bsnAPGroupVlanName bsnAPPrimaryMwarName
      bsnAPSecondaryMwarName bsnAPType bsnAPPortNumber bsnAPOperationStatus)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  if ($self->{bsnAPDot3MacAddress} =~ /0x(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})/) {
    $self->{bsnAPDot3MacAddress} = join(".", map { hex($_) } ($1, $2, $3, $4, $5, $6));
  }
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('ap', $self->{bsnAPName});
  my $info = sprintf 'access point %s has %d interfaces with %d clients',
      $self->{bsnAPName}, scalar(@{$self->{interfaces}}),
      $self->{NumOfClients};
  $self->add_info($info);
  if ($self->mode =~ /device::wlan::aps::status/) {
  
  } else {
  }
  #$self->add_message(OK, $info);
  #$self->set_thresholds(warning => 80, critical => 90);
  #$self->add_message($self->check_thresholds($self->{usage}), $info);
}

sub dump {
  my $self = shift;
  printf "[ACCESSPOINT_%s]\n", $self->{bsnAPName};
  foreach (qw(bsnAPName bsnAPLocation bsnAPModel bsnApIpAddress bsnAPSerialNumber
      bsnAPDot3MacAddress bsnAPIOSVersion bsnAPGroupVlanName bsnAPPrimaryMwarName
      bsnAPSecondaryMwarName bsnAPType bsnAPPortNumber bsnAPOperationStatus)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

my $remarks =<<'EORR';


#  APs auslesen mit:  snmpwalk -c public hostadresse -v 2c 1.3.6.1.4.1.14179.2.2.1.1.3
#  Read out the APs OID with : snmpwalk -c public hostadresse -v 2c 1.3.6.1.4.1.14179.2.2.1.1.3
#
#  und unten in liste definieren als APid[10] - APid[11] -APid12[] .....
#  insert the oids in the list and  add ".0" ad the end of the oid.


APid[1]=".0.14.132.171.8.128.0"			# dlbruap002
APid[2]=".0.15.247.235.80.0"			# dlbruap007
APid[3]=".0.24.186.50.191.16"			# dlbruap005
APid[4]=".0.31.157.33.45.48.0"			# dlbruap006
APid[5]=".0.31.157.33.52.16.0"			# dlbruap009	
APid[6]=".0.31.157.33.76.112.0"			# dlbruap008
APid[7]=".0.31.157.33.68.192.0"			# dlbruap001	
APid[8]=".44.63.56.49.84.176"      		# dlbruap010
APid[9]=".100.160.231.248.169.160.0"	# dlbruap011
APid[10]=".0.26.48.231.24.32.0"			# dlbruap003
APid[11]=".44.63.56.43.167.96.0"		# bruap013 
maxind=11

#
#
## End APs definition


 

oid_AP_NumOfClients="1.3.6.1.4.1.14179.2.2.13.1.4"
oid_AP_Name="1.3.6.1.4.1.14179.2.2.1.1.3"
oid_AP_Place="1.3.6.1.4.1.14179.2.2.1.1.4"
oid_AP_Firmware="1.3.6.1.4.1.14179.2.2.1.1.16"
oid_AP_IP="1.3.6.1.4.1.14179.2.2.1.1.19"

EORR

