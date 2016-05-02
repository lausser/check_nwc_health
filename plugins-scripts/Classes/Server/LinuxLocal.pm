package Server::LinuxLocal;
our @ISA = qw(Classes::Device);
use strict;


sub init {
  my $self = shift;
  if ($self->mode =~ /device::interfaces/) {
    $self->analyze_and_check_interface_subsystem('Server::LinuxLocal::Component::InterfaceSubsystem');
  }
}


package Server::LinuxLocal::Component::InterfaceSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
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
    foreach (glob "/sys/class/net/*") {
      my $name = $_;
      $name =~ s/.*\///g;
      if ($self->opts->name) {
        if ($self->opts->regexp) {
          my $pattern = $self->opts->name;
          if ($name !~ /$pattern/i) {
            next;
          }
        } elsif (lc $name ne lc $self->opts->name) {
          next;
        }
      }
      *SAVEERR = *STDERR;
      open ERR ,'>/dev/null';
      *STDERR = *ERR;
      my $tmpif = {
        ifDescr => $name,
        ifIndex => $name,
        ifSpeed => (-f "/sys/class/net/$name/speed" ? do { local (@ARGV, $/) = "/sys/class/net/$name/speed"; my $x = <>; close ARGV; $x; } : undef),
        ifInOctets => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/rx_bytes"; my $x = <>; close ARGV; $x; },
        ifInDiscards => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/rx_dropped"; my $x = <>; close ARGV; $x; },
        ifInErrors => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/rx_errors"; my $x = <>; close ARGV; $x; },
        ifOutOctets => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/tx_bytes"; my $x = <>; close ARGV; $x; },
        ifOutDiscards => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/tx_dropped"; my $x = <>; close ARGV; $x; },
        ifOutErrors => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/tx_errors"; my $x = <>; close ARGV; $x; },
        ifOperStatus => do { local (@ARGV, $/) = "/sys/class/net/$name/operstate"; my $x = <>; close ARGV; $x; },
      };
      *STDERR = *SAVEERR;
      map {
          chomp $tmpif->{$_} if defined $tmpif->{$_}; 
          $tmpif->{$_} =~ s/\s*$//g if defined $tmpif->{$_};
      } keys %{$tmpif};
      $tmpif->{ifOperStatus} = 'down' if $tmpif->{ifOperStatus} ne 'up';
      $tmpif->{ifAdminStatus} = $tmpif->{ifOperStatus};
      if (defined $self->opts->ifspeed) {
        $tmpif->{ifSpeed} = $self->opts->ifspeed * 1024*1024;
      } else {
        $tmpif->{ifSpeed} *= 1024*1024 if defined $tmpif->{ifSpeed};
      }
      if (! defined $tmpif->{ifSpeed}) {
        $self->add_unknown(sprintf "There is no /sys/class/net/%s/speed. Use --ifspeed", $name);
      } else {
        push(@{$self->{interfaces}},
          Server::LinuxLocal::Component::InterfaceSubsystem::Interface->new(%{$tmpif}));
      }
    }
  }
}

sub check {
  my $self = shift;
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


