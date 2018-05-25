package Classes::Alcatel::OmniAccess::Component::WlanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('WLSX-WLAN-MIB', qw(wlsxWlanTotalNumAccessPoints));
  $self->get_snmp_tables('WLSX-WLAN-MIB', [
      ['aps', 'wlsxWlanAPTable', 'Classes::Alcatel::OmniAccess::Component::WlanSubsystem::AP', sub { return $self->filter_name(shift->{wlanAPName}) } ],
  ]);
}

sub check {
  my ($self) = @_;
  $self->add_info('checking access points');
  $self->{numOfAPs} = scalar (@{$self->{aps}});
  $self->{apNameList} = [map { $_->{wlanAPName} } @{$self->{aps}}];
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
      );
    } elsif ($self->mode =~ /device::wlan::aps::status/) {
      $self->reduce_messages('no problems');
      $self->add_perfdata(
          label => 'num_aps',
          value => scalar (@{$self->{aps}}),
      );
      $self->add_perfdata(
          label => 'num_up_aps',
          value => scalar (grep { $_->{wlanAPStatus} ne "down" } @{$self->{aps}}),
      );
      $self->add_perfdata(
          label => 'num_down_aps',
          value => scalar (grep { $_->{wlanAPStatus} eq "down" } @{$self->{aps}}),
      );
    } elsif ($self->mode =~ /device::wlan::aps::list/) {
      foreach (@{$self->{aps}}) {
        printf "%s\n", $_->{wlanAPName};
      }
    }
  }
}

package Classes::Alcatel::OmniAccess::Component::WlanSubsystem::AP;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  if ($self->{wlanAPMacAddress} && $self->{wlanAPMacAddress} =~ /0x(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})/) {
    $self->{wlanAPMacAddress} = join(".", map { hex($_) } ($1, $2, $3, $4, $5, $6));
  } elsif ($self->{wlanAPMacAddress} && unpack("H12", $self->{wlanAPMacAddress}) =~ /(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})/) {
    $self->{wlanAPMacAddress} = join(".", map { hex($_) } ($1, $2, $3, $4, $5, $6));
  }
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'access point %s is %s',
      $self->{wlanAPName}, $self->{wlanAPStatus});
  if ($self->mode =~ /device::wlan::aps::status/) {
    if ($self->{wlanAPStatus} eq 'down') {
      $self->add_critical();
    } else {
      $self->add_ok();
    }
  }
}

