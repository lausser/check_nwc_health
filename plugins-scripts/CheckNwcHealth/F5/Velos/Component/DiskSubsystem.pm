package CheckNwcHealth::F5::Velos::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('F5-PLATFORM-STATS-MIB', [
      ['processorstats', 'cpuProcessorStatsTable', 'Monitoring::GLPlugin::SNMP::TableItem', undef, ["index"]],
      ['disks', 'diskInfoTable', 'CheckNwcHealth::F5::Velos::Component::DiskSubsystem::Disk'],
      ['diskutils', 'diskUtilizationStatsTable', 'CheckNwcHealth::F5::Velos::Component::DiskSubsystem::Diskutil'],
  ]);
#DISK_12.99.111.110.116.114.111.108.108.101.114.45.49.7.110.118.109.101.48.110.49
#DTIL_12.99.111.110.116.114.111.108.108.101.114.45.49.7.110.118.109.101.48.110.49
  $self->merge_tables_with_code('disks', 'processorstats', sub {
      # siehe CpuSubsystem
      my ($disk, $proc) = @_;
      # DISK_12.99.111.110.116.114.111.108.108.101.114.45.50.7.110.118.109.101.48.110.49
      # TABLEITEM_12.99.111.110.116.114.111.108.108.101.114.45.50.1
      $proc->{flat_indices} =~ s/\.1$/./g;
      return (rindex($disk->{flat_indices}, $proc->{flat_indices}, 0) == 0) ? 1 : 0;
  });
  $self->merge_tables_with_code('disks', 'diskutils', sub {
      my ($disk, $util) = @_;
      return ($util->{flat_indices} eq $disk->{flat_indices}) ? 1 : 0;
  });
}

package CheckNwcHealth::F5::Velos::Component::DiskSubsystem::Diskutil;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckNwcHealth::F5::Velos::Component::DiskSubsystem::Disk;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if (defined $self->{diskPercentageUsed}) {
    $self->add_info(sprintf 'disk %s/%s usage is %d%%',
        $self->{index}, $self->{diskName}, $self->{diskPercentageUsed});
    my $label = sprintf "disk_%s/%s_usage", $self->{index}, $self->{diskName};
    $self->set_thresholds(
        metric => $label,
        warning => 80,
        critical => 90,
    );
    $self->add_message($self->check_thresholds(
        metric => $label,
        value => $self->{diskPercentageUsed}
    ));
    $self->add_perfdata(
        label => $label,
        value => $self->{diskPercentageUsed},
        uom => "%",
    );
  }
}

