package CheckNwcHealth::Audiocodes::Component::SbcLicenseSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('AC-KPI-MIB', (qw(
    acKpiLicenseStatsCurrentGlobalLicenseSbcSignalingUsage
    acKpiLicenseStatsCurrentGlobalLicenseSbcMediaUsage
    acKpiLicenseStatsCurrentGlobalLicenseTranscodingUsage
    acKpiLicenseStatsCurrentGlobalLicenseWebRTCUsage
    acKpiLicenseStatsCurrentGlobalLicenseSipRecUsage
  )));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking sbc license usage');
  
  my @license_types = (
    { name => 'signaling', oid => 'acKpiLicenseStatsCurrentGlobalLicenseSbcSignalingUsage', label => 'signaling' },
    { name => 'media', oid => 'acKpiLicenseStatsCurrentGlobalLicenseSbcMediaUsage', label => 'media' },
    { name => 'transcoding', oid => 'acKpiLicenseStatsCurrentGlobalLicenseTranscodingUsage', label => 'transcoding' },
    { name => 'webrtc', oid => 'acKpiLicenseStatsCurrentGlobalLicenseWebRTCUsage', label => 'webrtc' },
    { name => 'siprec', oid => 'acKpiLicenseStatsCurrentGlobalLicenseSipRecUsage', label => 'siprec' },
  );
  
  my $any_defined = 0;
  my $level = 0;
  my @info_parts;

  foreach my $license (@license_types) {
    if (defined $self->{$license->{oid}}) {
      $any_defined = 1;
      push @info_parts, sprintf '%s %d%%', $license->{label}, $self->{$license->{oid}};
      $self->set_thresholds(
        metric => 'license_'.$license->{name},
        warning => 80,
        critical => 90
      );
      my $l = $self->check_thresholds(
        metric => 'license_'.$license->{name},
        value => $self->{$license->{oid}}
      );
      $level = ($l > $level) ? $l : $level;
      $self->add_perfdata(
        label => 'license_'.$license->{name},
        value => $self->{$license->{oid}},
        uom => '%',
      );
    }
  }

  if ($any_defined) {
    $self->add_info(sprintf 'license usage: %s', join(', ', @info_parts));
    $self->add_message($level);
  } else {
    $self->add_unknown('cannot read license usage (SBC license metrics not available)');
  }
}

1;
