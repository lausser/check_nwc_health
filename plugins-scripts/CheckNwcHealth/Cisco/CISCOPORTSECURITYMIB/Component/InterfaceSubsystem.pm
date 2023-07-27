package CheckNwcHealth::Cisco::CISCOPORTSECURITYMIB::Component::InterfaceSubsystem;
our @ISA = qw(CheckNwcHealth::IFMIB::Component::InterfaceSubsystem);
use strict;

sub init {
  my ($self) = @_;
  my @iftable_columns = qw(ifIndex ifDescr ifAlias ifName);
  my @cpsifconfigtable_columns = ();
  if ($self->mode =~ /device::interfaces::portsecurity/) {
    $self->get_snmp_objects('CISCO-PORT-SECURITY-MIB', qw(cpsGlobalPortSecurityEnable));
    if ($self->{cpsGlobalPortSecurityEnable} eq 'false') {
      return;
    }
    push(@iftable_columns, qw(
        ifOperStatus ifAdminStatus
    ));
    push(@cpsifconfigtable_columns, qw(
        cpsIfPortSecurityEnable cpsIfPortSecurityStatus cpsIfViolationCount
        cpsIfSecureLastMacAddress
    ));
  } else {
    $self->SUPER::init();
  }
  if ($self->mode =~ /device::interfaces::portsecurity/) {
    my $if_has_changed = $self->update_interface_cache(0);
    my $only_admin_up =
        $self->opts->name && $self->opts->name eq '_adminup_' ? 1 : 0;
    my $only_oper_up =
        $self->opts->name && $self->opts->name eq '_operup_' ? 1 : 0;
    if ($only_admin_up || $only_oper_up) {
      $self->override_opt('name', undef);
      $self->override_opt('drecksptkdb', undef);
    }
    my @indices = $self->get_interface_indices();
    my @all_indices = @indices;
    my @selected_indices = ();
    if (! $self->opts->name && ! $self->opts->name3) {
      # get_table erzwingen
      @indices = ();
      $self->bulk_is_baeh(10);
    }
    if (!$self->opts->name || scalar(@indices) > 0) {
      my @save_indices = @indices; # die werden in get_snmp_table_objects geshiftet
      foreach ($self->get_snmp_table_objects(
          'IFMIB', 'ifTable+ifXTable', \@indices, \@iftable_columns)) {
        next if $only_admin_up && $_->{ifAdminStatus} ne 'up';
        next if $only_oper_up && $_->{ifOperStatus} ne 'up';
        my $interface = CheckNwcHealth::Cisco::CISCOPORTSECURITYMIB::Component::InterfaceSubsystem::Interface->new(%{$_});
        $interface->{columns} = [@iftable_columns];
        push(@{$self->{interfaces}}, $interface);
      }
      @indices = map { [$_->{ifIndex}]; } @{$self->{interfaces}};
      if (! $self->opts->name && ! $self->opts->name3) {
        $self->get_snmp_tables('CISCO-PORT-SECURITY-MIB', [
            ['cpsifs', 'cpsIfConfigTable', 'CheckNwcHealth::Cisco::CISCOPORTSECURITYMIB::Component::InterfaceSubsystem::CpsIf'],
        ]);
      } else {
        $self->{cpsifs} = [];
        foreach ($self->get_snmp_table_objects(
            'CISCO-PORT-SECURITY-MIB', 'cpsIfConfigTable', \@indices, \@cpsifconfigtable_columns)) {
          my $interface = CheckNwcHealth::Cisco::CISCOPORTSECURITYMIB::Component::InterfaceSubsystem::CpsIf->new(%{$_});
          push(@{$self->{cpsifs}}, $interface);
        }
      }
      $self->merge_tables('interfaces', 'cpsifs');
      @{$self->{interfaces}} = grep {
        exists $_->{cpsIfPortSecurityEnable} &&
            $_->{cpsIfPortSecurityEnable} eq 'true';
      } @{$self->{interfaces}};
    }
  } else {
    $self->SUPER::init();
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::interfaces::portsecurity/) {
    if ($self->{cpsGlobalPortSecurityEnable} eq 'true') {
      $self->SUPER::check();
    } else {
      $self->add_ok("port security is not enabled on this device");
    }
  } else {
    $self->SUPER::check();
  }
}

package CheckNwcHealth::Cisco::CISCOPORTSECURITYMIB::Component::InterfaceSubsystem::CpsIf;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{cpsIfSecureLastMacAddress} = $self->{cpsIfSecureLastMacAddress} ?
      $self->unhex_mac($self->{cpsIfSecureLastMacAddress}) : '-unknown-';

}

package CheckNwcHealth::Cisco::CISCOPORTSECURITYMIB::Component::InterfaceSubsystem::Interface;
our @ISA = qw(CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::Interface);
use strict;


sub check {
  my ($self) = @_;
  my $full_descr = sprintf "%s%s",
      $self->{ifDescr},
      $self->{ifAlias} && $self->{ifAlias} ne $self->{ifDescr} ?
          " (alias ".$self->{ifAlias}.")" : "";
  if ($self->mode =~ /device::interfaces::portsecurity/) {
    if ($self->{cpsIfPortSecurityEnable} eq 'false') {
      $self->add_info(sprintf 'interface %s security not enabled',
          $full_descr);
      $self->add_ok();
    } else {
      $self->add_info(sprintf 'interface %s security status is %s',
          $full_descr, $self->{cpsIfPortSecurityStatus});
      if ($self->{cpsIfPortSecurityStatus} eq 'secureup') {
        $self->add_ok();
      } elsif ($self->{cpsIfPortSecurityStatus} eq 'securedown') {
        $self->annotate_info('last mac address was '.$self->{cpsIfSecureLastMacAddress});
        $self->add_unknown_mitigation();
      } elsif ($self->{cpsIfPortSecurityStatus} eq 'shutdown') {
        $self->annotate_info('last mac address was '.$self->{cpsIfSecureLastMacAddress});
        $self->add_critical();
      }
    }
  } else {
    $self->SUPER::check();
  }
}


