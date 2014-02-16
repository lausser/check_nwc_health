package Server::Linux;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(Classes::Device);

sub init {
  my $self = shift;
  $self->{components} = {
      interface_subsystem => undef,
  };
  $self->{serial} = 'unknown';
  $self->{product} = 'unknown';
  $self->{romversion} = 'unknown';
  if (! $self->check_messages()) {
    if ($self->mode =~ /device::interfaces/) {
      $self->analyze_interface_subsystem();
      $self->check_interface_subsystem();
    }
  }
}

sub analyze_interface_subsystem {
  my $self = shift;
  $self->{components}->{interface_subsystem} =
      Server::Linux::Component::InterfaceSubsystem->new();
}

sub check_interface_subsystem {
  my $self = shift;
  $self->{components}->{interface_subsystem}->check();
  $self->{components}->{interface_subsystem}->dump()
      if $self->opts->verbose >= 2;
}

package Server::Linux::Component::InterfaceSubsystem;
our @ISA = qw(Server::Linux);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    interfaces => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  my %params = @_;
  if ($self->mode =~ /device::interfaces::list/) {
    foreach (glob "/sys/class/net/*") {
      my $name = $_;
      next if ! -d $name;
      $name =~ s/.*\///g;
      my $tmpif = {
        ifDescr => $name,
      };
      push(@{$self->{interfaces}},
        Server::Linux::Component::InterfaceSubsystem::Interface->new(%{$tmpif}));
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
        ifSpeed => (-f "/sys/class/net/$name/speed" ? do { local (@ARGV, $/) = "/sys/class/net/$name/speed"; my $x = <>; close ARGV; $x} * 1024*1024 : undef),
        ifInOctets => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/rx_bytes"; my $x = <>; close ARGV; $x},
        ifInDiscards => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/rx_dropped"; my $x = <>; close ARGV; $x},
        ifInErrors => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/rx_errors"; my $x = <>; close ARGV; $x},
        ifOutOctets => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/tx_bytes"; my $x = <>; close ARGV; $x},
        ifOutDiscards => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/tx_dropped"; my $x = <>; close ARGV; $x},
        ifOutErrors => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/tx_errors"; my $x = <>; close ARGV; $x},
      };
      *STDERR = *SAVEERR;
      foreach (keys %{$tmpif}) {
        chomp($tmpif->{$_}) if defined $tmpif->{$_};
      }
      if (defined $self->opts->ifspeed) {
        $tmpif->{ifSpeed} = $self->opts->ifspeed * 1024*1024;
      }
      if (! defined $tmpif->{ifSpeed}) {
        $self->add_message(UNKNOWN, sprintf "There is no /sys/class/net/%s/speed. Use --ifspeed", $name);
      } else {
        push(@{$self->{interfaces}},
          Server::Linux::Component::InterfaceSubsystem::Interface->new(%{$tmpif}));
      }
    }
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking interfaces');
  $self->blacklist('ff', '');
  if (scalar(@{$self->{interfaces}}) == 0) {
    $self->add_message(UNKNOWN, 'no interfaces');
    return;
  }
  if ($self->mode =~ /device::interfaces::list/) {
    foreach (sort {$a->{ifDescr} cmp $b->{ifDescr}} @{$self->{interfaces}}) {
      $_->list();
    }
  } else {
    if (scalar (@{$self->{interfaces}}) == 0) {
    } else {
      foreach (@{$self->{interfaces}}) {
        $_->check();
      }
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{interfaces}}) {
    $_->dump();
  }
}


package Server::Linux::Component::InterfaceSubsystem::Interface;
our @ISA = qw(Server::Linux::Component::InterfaceSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    ifDescr => $params{ifDescr},
    ifSpeed => $params{ifSpeed},
    ifInOctets => $params{ifInOctets},
    ifInDiscards => $params{ifInDiscards},
    ifInErrors => $params{ifInErrors},
    ifOutOctets => $params{ifOutOctets},
    ifOutDiscards => $params{ifOutDiscards},
    ifOutErrors => $params{ifOutErrors},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach my $key (keys %params) {
    $self->{$key} = 0 if ! defined $params{$key};
  }
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  if ($self->mode =~ /device::interfaces::traffic/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInOctets ifInDiscards ifInErrors ifOutOctets ifOutDiscards ifOutErrors));
  } elsif ($self->mode =~ /device::interfaces::usage/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInOctets ifOutOctets));
    if ($self->{ifSpeed} == 0) {
      # vlan graffl
      $self->{inputUtilization} = 0;
      $self->{outputUtilization} = 0;
    } else {
      $self->{inputUtilization} = $self->{delta_ifInOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->{ifSpeed});
      $self->{outputUtilization} = $self->{delta_ifOutOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->{ifSpeed});
    }
    $self->{inputRate} = $self->{delta_ifInOctets} / $self->{delta_timestamp};
    $self->{outputRate} = $self->{delta_ifOutOctets} / $self->{delta_timestamp};
    my $factor = 1/8; # default Bits
    if ($self->opts->units) {
      if ($self->opts->units eq "GB") {
        $factor = 1024 * 1024 * 1024;
      } elsif ($self->opts->units eq "MB") {
        $factor = 1024 * 1024;
      } elsif ($self->opts->units eq "KB") {
        $factor = 1024;
      } elsif ($self->opts->units eq "GBi") {
        $factor = 1024 * 1024 * 1024 / 8;
      } elsif ($self->opts->units eq "MBi") {
        $factor = 1024 * 1024 / 8;
      } elsif ($self->opts->units eq "KBi") {
        $factor = 1024 / 8;
      } elsif ($self->opts->units eq "B") {
        $factor = 1;
      } elsif ($self->opts->units eq "Bit") {
        $factor = 1/8;
      }
    }
    $self->{inputRate} /= $factor;
    $self->{outputRate} /= $factor;
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInErrors ifOutErrors ifInDiscards ifOutDiscards));
    $self->{inputErrorRate} = $self->{delta_ifInErrors} 
        / $self->{delta_timestamp};
    $self->{outputErrorRate} = $self->{delta_ifOutErrors} 
        / $self->{delta_timestamp};
    $self->{inputDiscardRate} = $self->{delta_ifInDiscards} 
        / $self->{delta_timestamp};
    $self->{outputDiscardRate} = $self->{delta_ifOutDiscards} 
        / $self->{delta_timestamp};
    $self->{inputRate} = ($self->{delta_ifInErrors} + $self->{delta_ifInDiscards}) 
        / $self->{delta_timestamp};
    $self->{outputRate} = ($self->{delta_ifOutErrors} + $self->{delta_ifOutDiscards}) 
        / $self->{delta_timestamp};
  } elsif ($self->mode =~ /device::interfaces::operstatus/) {
  }
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('if', $self->{ifDescr});
  if ($self->mode =~ /device::interfaces::traffic/) {
  } elsif ($self->mode =~ /device::interfaces::usage/) {
    my $info = sprintf 'interface %s usage is in:%.2f%% (%s) out:%.2f%% (%s)',
        $self->{ifDescr}, 
        $self->{inputUtilization}, 
        sprintf("%.2f%s/s", $self->{inputRate},
            ($self->opts->units ? $self->opts->units : 'Bits')),
        $self->{outputUtilization},
        sprintf("%.2f%s/s", $self->{outputRate},
            ($self->opts->units ? $self->opts->units : 'Bits'));
    $self->add_info($info);
    $self->set_thresholds(warning => 80, critical => 90);
    my $in = $self->check_thresholds($self->{inputUtilization});
    my $out = $self->check_thresholds($self->{outputUtilization});
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level, $info);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_usage_in',
        value => $self->{inputUtilization},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_usage_out',
        value => $self->{outputUtilization},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_in',
        value => $self->{inputRate},
        uom => $self->opts->units,
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_out',
        value => $self->{outputRate},
        uom => $self->opts->units,
    );
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    my $info = sprintf 'interface %s errors in:%.2f/s out:%.2f/s '.
        'discards in:%.2f/s out:%.2f/s',
        $self->{ifDescr},
        $self->{inputErrorRate} , $self->{outputErrorRate},
        $self->{inputDiscardRate} , $self->{outputDiscardRate};
    $self->add_info($info);
    $self->set_thresholds(warning => 1, critical => 10);
    my $in = $self->check_thresholds($self->{inputRate});
    my $out = $self->check_thresholds($self->{outputRate});
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level, $info);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_errors_in',
        value => $self->{inputErrorRate},
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_errors_out',
        value => $self->{outputErrorRate},
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_discards_in',
        value => $self->{inputDiscardRate},
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_discards_out',
        value => $self->{outputDiscardRate},
        warning => $self->{warning},
        critical => $self->{critical},
    );
  }
}

sub list {
  my $self = shift;
  printf "%s\n", $self->{ifDescr};
}

sub dump {
  my $self = shift;
  printf "[IF_%s]\n", $self->{ifDescr};
  foreach (qw(ifDescr ifSpeed ifInOctets ifInDiscards ifInErrors ifOutOctets ifOutDiscards ifOutErrors)) {
    printf "%s: %s\n", $_, defined $self->{$_} ? $self->{$_} : 'undefined';
  }
#  printf "info: %s\n", $self->{info};
  printf "\n";
}

