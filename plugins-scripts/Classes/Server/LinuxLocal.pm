package Server::LinuxLocal;
our @ISA = qw(Classes::Device);
use strict;


sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::interfaces/) {
    $self->analyze_and_check_interface_subsystem('Server::LinuxLocal::Component::InterfaceSubsystem');
  }
}


package Server::LinuxLocal::Component::InterfaceSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{interfaces} = [];
  if ($self->mode =~ /device::interfaces::list/) {
    foreach (glob "/sys/class/net/*") {
      my $name = $_;
      next if ! -d $name;
      $name =~ s/.*\///g;
      my $tmpif = {
        ifDescr => $name,
      };
      push(@{$self->{interfaces}},
        Server::LinuxLocal::Component::InterfaceSubsystem::Interface->new(%{$tmpif}));
    }
  } else {
    my $max_speed = 0;
    foreach (glob "/sys/class/net/*") {
      my $name = $_;
      $name =~ s/.*\///g;
      my $tmp_speed = (-f "/sys/class/net/$name/speed" ? do { local (@ARGV, $/) = "/sys/class/net/$name/speed"; my $x = <>; close ARGV; $x; } : undef);
      $max_speed = $tmp_speed if defined $tmp_speed && $tmp_speed > $max_speed;
      next if ! $self->filter_name($name);
      *SAVEERR = *STDERR;
      open ERR ,'>/dev/null';
      *STDERR = *ERR;
      my $tmpif = {
        ifDescr => $name,
        ifIndex => $name,
        ifSpeed => $tmp_speed,
        ifInOctets => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/rx_bytes"; my $x = <>; close ARGV; $x; },
        ifInDiscards => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/rx_dropped"; my $x = <>; close ARGV; $x; },
        ifInErrors => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/rx_errors"; my $x = <>; close ARGV; $x; },
        ifOutOctets => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/tx_bytes"; my $x = <>; close ARGV; $x; },
        ifOutDiscards => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/tx_dropped"; my $x = <>; close ARGV; $x; },
        ifOutErrors => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/tx_errors"; my $x = <>; close ARGV; $x; },
        ifOperStatus => do { local (@ARGV, $/) = "/sys/class/net/$name/operstate"; my $x = <>; close ARGV; $x; },
        ifInUcastPkts => 0, # sonst wird in IFMIB... ein StackSub draus
        ifOutUcastPkts => 0,
        ifCarrier => do { local (@ARGV, $/) = "/sys/class/net/$name/carrier"; my $x = <>; close ARGV; $x; },
      };
      *STDERR = *SAVEERR;
      map {
          chomp $tmpif->{$_} if defined $tmpif->{$_};
          $tmpif->{$_} =~ s/\s*$//g if defined $tmpif->{$_};
      } keys %{$tmpif};
      if ($tmpif->{ifOperStatus} eq 'unknown') {
        $tmpif->{ifOperStatus} = $tmpif->{ifCarrier} ? 'up' : 'down';
      }
      $tmpif->{ifAdminStatus} = $tmpif->{ifOperStatus};
      if (defined $self->opts->ifspeed) {
        $tmpif->{ifSpeed} = $self->opts->ifspeed * 1024*1024;
      } else {
        $tmpif->{ifSpeed} *= 1024*1024 if defined $tmpif->{ifSpeed};
      }
      push(@{$self->{interfaces}},
        Server::LinuxLocal::Component::InterfaceSubsystem::Interface->new(%{$tmpif}));
    }
    map { $_->{sysMaxSpeed} = $max_speed; chomp $_->{sysMaxSpeed}; } @{$self->{interfaces}};
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking interfaces');
  if (scalar(@{$self->{interfaces}}) == 0) {
    $self->add_unknown('no interfaces');
    return;
  }
  if ($self->mode =~ /device::interfaces::list/) {
    foreach (sort {$a->{ifDescr} cmp $b->{ifDescr}} @{$self->{interfaces}}) {
      $_->list();
    }
  } else {
    foreach (@{$self->{interfaces}}) {
      $_->check();
    }
  }
}


package Server::LinuxLocal::Component::InterfaceSubsystem::Interface;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem::Interface);
use strict;

sub finish {
  my ($self) = @_;
  if (! defined $self->{ifSpeed} && $self->mode =~ /device::interfaces::(complete|usage)/) {
    bless $self, 'Server::LinuxLocal::Component::InterfaceSubsystem::Interface::Virt';
  }
  $self->SUPER::finish();
}

package Server::LinuxLocal::Component::InterfaceSubsystem::Interface::Virt;
our @ISA = qw(Server::LinuxLocal::Component::InterfaceSubsystem::Interface);
use strict;

sub check {
  my ($self) = @_;
  if (! defined $self->{ifSpeed}) {
    if (defined $self->opts->mitigation && $self->opts->mitigation eq 'ok') {
      $self->{ifSpeed} = $self->{sysMaxSpeed};
      # virtuelles zeug bekommt die geschw. des schnellsten verbauten interf.
      # wird schon passen.
      $self->SUPER::check();
    } elsif ($self->mode =~ /evice::interfaces::(complete|usage)/) {
      $self->add_unknown(sprintf "There is no /sys/class/net/%s/speed. Use --ifspeed", $self->{ifDescr});
    } else {
      $self->SUPER::check();
    }
  } else {
    $self->SUPER::check();
  }
}

