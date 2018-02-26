package Classes::HOSTRESOURCESMIB::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['storagesram', 'hrStorageTable', 'Classes::HOSTRESOURCESMIB::Component::MemSubsystem::Ram', sub { return shift->{hrStorageType} eq 'hrStorageRam' } ],
  ]);
}

sub check {
  my ($self) = @_;
  my $ramsignature =
      join "_", sort map { $_->{hrStorageDescr} } @{$self->{storagesram}};
  if ($ramsignature eq "RAM_RAM (Buffers)_RAM (Cache)") {
    # https://eos.arista.com/introduction-to-managing-eos-devices-memory-utilisation/
    my ($total, $used, $buffers, $cached) = (0, 0, 0, 0);
    foreach (@{$self->{storagesram}}) {
      $used = $_->{hrStorageUsed} if $_->{hrStorageDescr} eq "RAM";
      $buffers = $_->{hrStorageUsed} if $_->{hrStorageDescr} eq "RAM (Buffers)";
      $cached = $_->{hrStorageUsed} if $_->{hrStorageDescr} eq "RAM (Cache)";
      $total = $_->{hrStorageSize} if $_->{hrStorageDescr} eq "RAM";
    }
    my $free = ($total - $used) + $buffers + $cached;
    my $usage = 100 * ($total - $free) / $total;
    $self->add_info(sprintf 'memory usage is %.2f%%', $usage);
    my $label = 'memory_usage';
    $self->set_thresholds(metric => $label, warning => '90', critical => '95');
    $self->add_message($self->check_thresholds(metric => $label,
        value => $usage));
    $self->add_perfdata(
        label => $label,
        value => $usage,
        uom => '%',
    );
  } else {
    $self->SUPER::check();
  }
}


package Classes::HOSTRESOURCESMIB::Component::MemSubsystem::Ram;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my $used = 100;
  eval {
     $used = 100 * $self->{hrStorageUsed} / $self->{hrStorageSize};
  };
  $self->add_info(sprintf 'memory %s (%s) usage is %.2f%%',
      $self->{hrStorageIndex},
      $self->{hrStorageDescr},
      $used);
  my $label = sprintf 'memory_%s_usage', $self->{hrStorageDescr};
  $self->set_thresholds(metric => $label, warning => '90', critical => '95');
  $self->add_message($self->check_thresholds(metric => $label,
      value => $used));
  $self->add_perfdata(
      label => $label,
      value => $used,
      uom => '%',
  );
}

