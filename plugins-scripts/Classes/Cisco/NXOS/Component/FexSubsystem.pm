package Classes::Cisco::NXOS::Component::FexSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-ETHERNET-FABRIC-EXTENDER-MIB', [
    ['fexes', 'cefexConfigTable', 'Classes::Cisco::NXOS::Component::FexSubsystem::Fex'],
  ]);
  if (scalar (@{$self->{fexes}}) == 0) {
   # fallback
    $self->get_snmp_tables('ENTITY-MIB', [
      ['fexes', 'entPhysicalTable', 'Classes::Cisco::NXOS::Component::FexSubsystem::Fex'],
    ]);
    @{$self->{fexes}} = grep {
        $_->{entPhysicalClass} eq 'chassis' && $_->{entPhysicalDescr} =~ /fex/i; 
    } @{$self->{fexes}};
    if (scalar (@{$self->{fexes}}) == 0) {
      $self->get_snmp_tables('ENTITY-MIB', [
        ['fexes', 'entPhysicalTable', 'Classes::Cisco::NXOS::Component::FexSubsystem::Fex'],
      ]);
      # fallback
      my $known_fexes = {};
      @{$self->{fexes}} = grep {
        ! $known_fexes->{$_->{cefexConfigExtenderName}}++;
      } grep {
          $_->{entPhysicalClass} eq 'other' && $_->{entPhysicalDescr} =~ /fex.*cable/i; 
      } @{$self->{fexes}};
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{fexes}}) {
    $_->dump();
  }
}

sub check {
  my $self = shift;
  $self->add_info('counting fexes');
  $self->{numOfFexes} = scalar (@{$self->{fexes}});
  $self->{fexNameList} = [map { $_->{cefexConfigExtenderName} } @{$self->{fexes}}];
  if (scalar (@{$self->{fexes}}) == 0) {
    $self->add_unknown('no FEXes found');
  } else {
    # lookback, denn sonst muesste der check is_volatile sein und koennte bei
    # einem kurzen netzausfall fehler schmeissen.
    # empfehlung: check_interval 5 (muss jedesmal die entity-mib durchwalken)
    #             retry_interval 2
    #             max_check_attempts 2
    # --lookback 360
    $self->opts->override_opt('lookback', 1800) if ! $self->opts->lookback;
    $self->valdiff({name => $self->{name}, lastarray => 1},
        qw(fexNameList numOfFexes));
    if (scalar(@{$self->{delta_found_fexNameList}}) > 0) {
      $self->add_warning(sprintf '%d new FEX(es) (%s)',
          scalar(@{$self->{delta_found_fexNameList}}),
          join(", ", @{$self->{delta_found_fexNameList}}));
    }
    if (scalar(@{$self->{delta_lost_fexNameList}}) > 0) {
      $self->add_critical(sprintf '%d FEXes missing (%s)',
          scalar(@{$self->{delta_lost_fexNameList}}),
          join(", ", @{$self->{delta_lost_fexNameList}}));
    }
    $self->add_ok(sprintf 'found %d FEXes', scalar (@{$self->{fexes}}));
    $self->add_perfdata(
        label => 'num_fexes',
        value => $self->{numOfFexes},
    );
  }
}


package Classes::Cisco::NXOS::Component::FexSubsystem::Fex;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{original_cefexConfigExtenderName} = $self->{cefexConfigExtenderName};
  if (exists $self->{entPhysicalClass}) {
    # stammt aus ENTITY-MIB
    if ($self->{entPhysicalDescr} =~ /^FEX[^\d]*(\d+)/i) {
      $self->{cefexConfigExtenderName} = "FEX".$1;
    } else {
      $self->{cefexConfigExtenderName} = $self->{entPhysicalDescr};
    }
  } else {
    # stammt aus CISCO-ETHERNET-FABRIC-EXTENDER-MIB, kann FEX101-J8-VT04.01 heissen
    if ($self->{cefexConfigExtenderName} =~ /^FEX[^\d]*(\d+)/i) {
      $self->{cefexConfigExtenderName} = "FEX".$1;
    }
  }
}

__END__
entweder die cefexConfigTable ist bestueckt oder man liest als Fallback die Entities aus
entPhysicalAlias:
entPhysicalAssetID:
entPhysicalClass: chassis
entPhysicalContainedIn: 10
entPhysicalDescr: Fex-107 Nexus2248 Chassis
entPhysicalFirmwareRev:
entPhysicalHardwareRev: V03
entPhysicalIsFRU: 2
entPhysicalMfgName: Cisco Systems, Inc.
entPhysicalModelName: Fabric Extender Module: 48x1GE, 4x10GE
entPhysicalName: Fex-107 Nexus2248 Chassis
entPhysicalParentRelPos: 107
entPhysicalSerialNum: SSI162802BH
entPhysicalSoftwareRev:
entPhysicalVendorType: 1.3.6.1.4.1.9.12.3.1.3.914

