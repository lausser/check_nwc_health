package CheckNwcHealth::Cisco::CISCOSTACKMIB::Component::StackSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };


sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CISCO-STACK-MIB', qw(sysStatus
      chassisSysType 
      chassisPs1Type chassisPs1Status chassisPs1TestResult
      chassisPs2Type chassisPs2Status chassisPs2TestResult
      chassisPs3Type chassisPs3Status chassisPs3TestResult
      chassisFanStatus chassisFanTestResult
      chassisMinorAlarm chassisMajorAlarm chassisTempAlarm
      chassisModel chassisSerialNumberString
  ));
  $self->bulk_is_baeh(10);
  $self->get_snmp_tables("CISCO-STACK-MIB", [
      ['components', 'chassisComponentTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
      ['modules', 'moduleTable', 'CheckNwcHealth::Cisco::CISCOSTACKMIB::Component::StackSubsystem::Module'],
  ]);
  if (grep { exists $_->{moduleEntPhysicalIndex} } @{$self->{modules}}) {
    $self->get_snmp_tables('ENTITY-MIB', [
      ['entities', 'entPhysicalTable', 'Monitoring::GLPlugin::TableItem'],
    ]);
    my $entities = {};
    foreach (@{$self->{entities}}) {
      $entities->{$_->{flat_indices}} = $_;
    }
    foreach (@{$self->{modules}}) {
      if (exists $entities->{$_->{moduleEntPhysicalIndex}}) {
        foreach my $key (keys %{$entities->{$_->{moduleEntPhysicalIndex}}}) {
          $_->{$key} = $entities->{$_->{moduleEntPhysicalIndex}}->{$key} if $key =~ /entPhysical/;
        }
      }
    }
    delete $self->{entities};
  }
  $self->{numModules} = scalar(@{$self->{modules}});
  $self->{moduleSerialList} = [map { $_->{moduleSerialNumberString} } @{$self->{modules}}];
  map { $self->{numPorts} += $_->{moduleNumPorts} } @{$self->{modules}};
}

sub check {
  my ($self) = @_;
  if ($self->{chassisSysType} eq 'other' &&
      ! $self->{chassisSerialNumberString} &&
      ! $self->{chassisSerialNumberString}) {
    $self->add_message(defined $self->opts->mitigation() ?
        $self->opts->mitigation() : UNKNOWN,
        'this is probably not a stacked device');
    return;
  }
  foreach (@{$self->{modules}}) {
    $_->check();
  }
  if (defined $self->{sysStatus}) {
    $self->add_info(sprintf 'chassis sys status is %s',
        $self->{sysStatus});
    if ($self->{sysStatus} eq 'minorFault') {
      $self->add_warning();
    } elsif ($self->{sysStatus} eq 'majorFault') {
      $self->add_critical();
    } else {
      $self->add_ok();
    }
  }
  $self->add_info(sprintf 'chassis fan status is %s',
      $self->{chassisFanStatus});
  if ($self->{chassisFanStatus} !~ /^(ok|other)$/) {
    # other bedeutet wohl, daß kein fan verbaut wurde.
    $self->add_critical();
  }
  $self->add_info(sprintf 'chassis minor alarm is %s',
      $self->{chassisMinorAlarm});
  if ($self->{chassisMinorAlarm} ne 'off') {
    $self->add_warning();
  }
  $self->add_info(sprintf 'chassis major alarm is %s',
      $self->{chassisMajorAlarm});
  if ($self->{chassisMajorAlarm} ne 'off') {
    $self->add_critical();
  }
  $self->add_info(sprintf 'chassis temperature alarm is %s',
      $self->{chassisTempAlarm});
  if ($self->{chassisTempAlarm} ne 'off') {
    $self->add_critical();
  }
  for my $ps (1, 2, 3) {
    if (exists $self->{'chassisPs'.$ps.'Type'}) {
      # da wurde nix verbaut
      next if $self->{'chassisPs'.$ps.'Status'} eq 'other';
      $self->add_info(sprintf 'power supply %d status is %s',
          $ps, $self->{'chassisPs'.$ps.'Status'});
      if ($self->{'chassisPs'.$ps.'Status'} eq 'minorFault') {
        $self->add_warning();
      } elsif ($self->{'chassisPs'.$ps.'Status'} eq 'majorFault') {
        $self->add_critical();
      } else {
        $self->add_ok();
      }
    }
  }
  $self->opts->override_opt('lookback', 1800) if ! $self->opts->lookback;
  $self->valdiff({name => $self->{chassisSerialNumberString}, lastarray => 1},
      qw(moduleSerialList numModules numPorts));
  if (scalar(@{$self->{delta_found_moduleSerialList}}) > 0) {
    $self->add_warning(sprintf '%d new module(s) (%s)',
        scalar(@{$self->{delta_found_moduleSerialList}}),
        join(", ", @{$self->{delta_found_moduleSerialList}}));
  }
  if (scalar(@{$self->{delta_lost_moduleSerialList}}) > 0) {
    $self->add_critical(sprintf '%d module(s) missing (%s)',
        scalar(@{$self->{delta_lost_moduleSerialList}}),
        join(", ", @{$self->{delta_lost_moduleSerialList}}));
  }
  if ($self->{delta_numPorts} > 0) {
    $self->add_warning(sprintf '%d new ports', $self->{delta_numPorts});
  } elsif ($self->{delta_numPorts} < 0) {
    $self->add_critical(sprintf '%d missing ports', abs($self->{delta_numPorts}));
  }
  if (! $self->check_messages()) {
    $self->add_ok('chassis is ok');
  }
  $self->add_info(sprintf 'found %d modules with %d ports',
      $self->{numModules}, $self->{numPorts});
  $self->add_ok();
}

package CheckNwcHealth::Cisco::CISCOSTACKMIB::Component::StackSubsystem::Module;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{modulePortStatus} = unpack("H*", $self->{modulePortStatus});
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'module %d (serial %s) is %s',
      $self->{moduleIndex}, $self->{moduleSerialNumberString},
      $self->{moduleStatus}
  );
  if ($self->{moduleStatus} eq 'minorFault' && $self->{moduleTestResult} == 0) {
    # make Deepak happy
    $self->annotate_info('but all tests passed');
    $self->add_ok();
  } elsif ($self->{moduleStatus} eq 'minorFault') {
    $self->add_warning();
  } elsif ($self->{moduleStatus} ne 'ok') {
    $self->add_critical();
  }
}

