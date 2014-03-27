package Classes::Cisco::WLC::Component::WlanSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->{name} = $self->get_snmp_object(
     'MIB-II', 'sysName', 0);
  foreach ($self->get_snmp_table_objects(
     'AIRESPACE-WIRELESS-MIB', 'bsnAPTable')) {
    if ($self->filter_name($_->{bsnAPName})) {
      push(@{$self->{aps}},
          Classes::Cisco::WLC::Component::WlanSubsystem::AP->new(%{$_}));
    }
  }
  $self->get_snmp_tables('AIRESPACE-WIRELESS-MIB', [
      ['ifs', 'bsnAPIfTable', 'Classes::Cisco::WLC::Component::WlanSubsystem::IF'],
  ]);
  $self->get_snmp_tables('AIRESPACE-WIRELESS-MIB', [
      ['ifloads', 'bsnAPIfLoadParametersTable', 'Classes::Cisco::WLC::Component::WlanSubsystem::IFLoad'],
  ]);
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
    $self->add_unknown('no access points found');
  } else {
    foreach (@{$self->{aps}}) {
      $_->check();
    }
    if ($self->mode =~ /device::wlan::aps::watch/) {
      $self->opts->override_opt('lookback', 1800) if ! $self->opts->lookback;
      $self->valdiff({name => $self->{name}, lastarray => 1},
          qw(apNameList numOfAPs));
      if (scalar(@{$self->{delta_found_apNameList}}) > 0) {
      #if (scalar(@{$self->{delta_found_apNameList}}) > 0 &&
      #    $self->{delta_timestamp} > $self->opts->lookback) {
        $self->add_warning(sprintf '%d new access points (%s)',
            scalar(@{$self->{delta_found_apNameList}}),
            join(", ", @{$self->{delta_found_apNameList}}));
      }
      if (scalar(@{$self->{delta_lost_apNameList}}) > 0) {
        $self->add_critical(sprintf '%d access points missing (%s)',
            scalar(@{$self->{delta_lost_apNameList}}),
            join(", ", @{$self->{delta_lost_apNameList}}));
      }
      $self->add_ok(sprintf 'found %d access points', scalar (@{$self->{aps}}));
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
    } elsif ($self->mode =~ /device::wlan::aps::status/) {
      if ($self->opts->report eq "short") {
        $self->clear_ok();
        $self->add_ok('no problems') if ! $self->check_messages();
      }
    } elsif ($self->mode =~ /device::wlan::aps::list/) {
      foreach (@{$self->{aps}}) {
        printf "%s\n", $_->{bsnAPName};
      }
    }
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
    map {$ap->{NumOfClients} += $_->{bsnAPIfLoadNumOfClients} }
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


package Classes::Cisco::WLC::Component::WlanSubsystem::IF;
our @ISA = qw(GLPlugin::TableItem);
use strict;


package Classes::Cisco::WLC::Component::WlanSubsystem::IFLoad;
our @ISA = qw(GLPlugin::TableItem);
use strict;


package Classes::Cisco::WLC::Component::WlanSubsystem::AP;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  if ($self->{bsnAPDot3MacAddress} =~ /0x(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})/) {
    $self->{bsnAPDot3MacAddress} = join(".", map { hex($_) } ($1, $2, $3, $4, $5, $6));
  }
  $self->blacklist('ap', $self->{bsnAPName});
  $self->add_info(sprintf 'access point %s is %s (%d interfaces with %d clients)',
      $self->{bsnAPName}, $self->{bsnAPOperationStatus},
      scalar(@{$self->{interfaces}}), $self->{NumOfClients});
  if ($self->mode =~ /device::wlan::aps::status/) {
    if ($self->{bsnAPOperationStatus} eq 'disassociating') {
      $self->add_critical();
    } elsif ($self->{bsnAPOperationStatus} eq 'downloading') {
      # das verschwindet hoffentlich noch vor dem HARD-state
      $self->add_warning();
    } elsif ($self->{bsnAPOperationStatus} eq 'associated') {
      $self->add_ok();
    } else {
      $self->add_unknown();
    }
  }
}

