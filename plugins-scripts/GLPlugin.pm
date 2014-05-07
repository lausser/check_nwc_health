package GLPlugin;
use strict;
use IO::File;
use File::Basename;
use Digest::MD5 qw(md5_hex);
use Errno;
use AutoLoader;
our $AUTOLOAD;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

{
  our $mode = undef;
  our $plugin = undef;
  our $pluginname = basename($0);
  our $blacklist = undef;
  our $info = [];
  our $extendedinfo = [];
  our $summary = [];
}

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {};
  bless $self, $class;
  $GLPlugin::plugin = GLPlugin::Commandline->new(%params);
  return $self;
}

sub statefilesdir {
  my $self = shift;
  return $GLPlugin::plugin->{statefilesdir};
}

#
# Plugin-related methods
#
sub nagios_exit {
  my $self = shift;
  return $GLPlugin::plugin->nagios_exit(@_);
}

sub mode {
  my $self = shift;
  return $GLPlugin::mode;
}

sub add_ok {
  my $self = shift;
  my $message = shift || $self->{info};
  $self->add_message(OK, $message);
}

sub add_warning {
  my $self = shift;
  my $message = shift || $self->{info};
  $self->add_message(WARNING, $message);
}

sub add_critical {
  my $self = shift;
  my $message = shift || $self->{info};
  $self->add_message(CRITICAL, $message);
}

sub add_unknown {
  my $self = shift;
  my $message = shift || $self->{info};
  $self->add_message(UNKNOWN, $message);
}

sub add_message {
  my $self = shift;
  my $level = shift;
  my $message = shift || $self->{info};
  $GLPlugin::plugin->add_message($level, $message)
      unless $self->is_blacklisted();
  if (exists $self->{failed}) {
    if ($level == UNKNOWN && $self->{failed} == OK) {
      $self->{failed} = $level;
    } elsif ($level > $self->{failed}) {
      $self->{failed} = $level;
    }
  }
}

sub status_code {
  my $self = shift;
  return $GLPlugin::plugin->status_code(@_);
}

sub check_messages {
  my $self = shift;
  return $GLPlugin::plugin->check_messages(@_);
}

sub clear_ok {
  my $self = shift;
  return $self->clear_messages(OK);
}

sub clear_warning {
  my $self = shift;
  return $self->clear_messages(WARNING);
}

sub clear_critical {
  my $self = shift;
  return $self->clear_messages(CRITICAL);
}

sub clear_unknown {
  my $self = shift;
  return $self->clear_messages(UNKNOWN);
}

sub clear_messages {
  my $self = shift;
  return $GLPlugin::plugin->clear_messages(@_);
}

sub suppress_messages {
  my $self = shift;
  return $GLPlugin::plugin->suppress_messages(@_);
}

sub add_html {
  my $self = shift;
  return $GLPlugin::plugin->add_html(@_);
}

sub html_string {
  my $self = shift;
  return $GLPlugin::plugin->html_string(@_);
}

sub add_perfdata {
  my $self = shift;
  $GLPlugin::plugin->add_perfdata(@_);
}

sub selected_perfdata {
  my $self = shift;
  $GLPlugin::plugin->selected_perfdata(@_);
}

sub add_modes {
  my $self = shift;
  my $modes = shift;
  my $modestring = "";
  my @modes = @{$modes};
  my $longest = length ((reverse sort {length $a <=> length $b} map { $_->[1] } @modes)[0]);
  my $format = "       %-".
      (length ((reverse sort {length $a <=> length $b} map { $_->[1] } @modes)[0])).
      "s\t(%s)\n";
  foreach (@modes) {
    $modestring .= sprintf $format, $_->[1], $_->[3];
  }
  $modestring .= sprintf "\n";
  $GLPlugin::plugin->{modestring} = $modestring;
}

sub add_arg {
  my $self = shift;
  my %args = @_;
  if ($args{help} =~ /^--mode/) {
    $args{help} .= "\n".$GLPlugin::plugin->{modestring};
  }
  $GLPlugin::plugin->{opts}->add_arg(%args);
}

sub add_mode {
  my $self = shift;
  my %args = @_;
  push(@{$GLPlugin::plugin->{modes}}, \%args);
  my $longest = length ((reverse sort {length $a <=> length $b} map { $_->{spec} } @{$GLPlugin::plugin->{modes}})[0]);
  my $format = "       %-".
      (length ((reverse sort {length $a <=> length $b} map { $_->{spec} } @{$GLPlugin::plugin->{modes}})[0])).
      "s\t(%s)\n";
  $GLPlugin::plugin->{modestring} = "";
  foreach (@{$GLPlugin::plugin->{modes}}) {
    $GLPlugin::plugin->{modestring} .= sprintf $format, $_->{spec}, $_->{help};
  }
  $GLPlugin::plugin->{modestring} .= "\n";
}

sub getopts {
  my $self = shift;
  $GLPlugin::plugin->getopts();
}

sub override_opt {
  my $self = shift;
  $GLPlugin::plugin->override_opt(@_);
}

sub validate_args {
  my $self = shift;
  if ($self->opts->mode =~ /^my-([^\-.]+)/) {
    my $param = $self->opts->mode;
    $param =~ s/\-/::/g;
    $self->add_mode(
        internal => $param,
        spec => $self->opts->mode,
        alias => undef,
        help => 'my extension',
    );
  } elsif ($self->opts->mode eq 'encode') {
    my $input = <>;
    chomp $input;
    $input =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
    printf "%s\n", $input;
    exit 0;
  } elsif ((! grep { $self->opts->mode eq $_ } map { $_->{spec} } @{$GLPlugin::plugin->{modes}}) &&
      (! grep { $self->opts->mode eq $_ } map { defined $_->{alias} ? @{$_->{alias}} : () } @{$GLPlugin::plugin->{modes}})) {
    printf "UNKNOWN - mode %s\n", $self->opts->mode;
    $self->opts->print_help();
    exit 3;
  }
  if ($self->opts->name && $self->opts->name =~ /(%22)|(%27)/) {
    my $name = $self->opts->name;
    $name =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    $self->override_opt('name', $name);
  }
  $GLPlugin::mode = (
      map { $_->{internal} }
      grep {
         ($self->opts->mode eq $_->{spec}) ||
         ( defined $_->{alias} && grep { $self->opts->mode eq $_ } @{$_->{alias}})
      } @{$GLPlugin::plugin->{modes}}
  )[0];
  if ($self->opts->multiline) {
    $ENV{NRPE_MULTILINESUPPORT} = 1;
  } else {
    $ENV{NRPE_MULTILINESUPPORT} = 0;
  }
  if (! $self->opts->statefilesdir) {
    if (exists $ENV{NAGIOS__SERVICESTATEFILESDIR}) {
      $self->override_opt('statefilesdir', $ENV{NAGIOS__SERVICESTATEFILESDIR});
    } elsif (exists $ENV{OMD_ROOT}) {
      $self->override_opt('statefilesdir', $ENV{OMD_ROOT}."/var/tmp/".$GLPlugin::plugin->{name});
    } else {
      $self->override_opt('statefilesdir', "/var/tmp/".$GLPlugin::plugin->{name});
    }
  }
  $GLPlugin::plugin->{statefilesdir} = $self->opts->statefilesdir;
  if ($self->opts->can("warningx") && $self->opts->warningx) {
    foreach my $key (keys %{$self->opts->warningx}) {
      $self->set_thresholds(metric => $key, 
          warning => $self->opts->warningx->{$key});
    }
  }
  if ($self->opts->can("criticalx") && $self->opts->criticalx) {
    foreach my $key (keys %{$self->opts->criticalx}) {
      $self->set_thresholds(metric => $key, 
          critical => $self->opts->criticalx->{$key});
    }
  }
  $SIG{'ALRM'} = sub {
    printf "UNKNOWN - %s timed out after %d seconds\n",
        $GLPlugin::plugin->{name}, $self->opts->timeout;
    exit 3;
  };
  alarm($self->opts->timeout);
}


sub init {
  my $self = shift;
  if ($self->opts->can("blacklist") && $self->opts->blacklist &&
      -f $self->opts->blacklist) {
    $self->opts->blacklist = do {
        local (@ARGV, $/) = $self->opts->blacklist; <> };
  }
}

sub debug {
  my $self = shift;
  my $format = shift;
  my $tracefile = "/tmp/".$0.".trace";
  $self->{trace} = -f $tracefile ? 1 : 0;
  if ($self->opts->verbose && $self->opts->verbose > 10) {
    printf("%s: ", scalar localtime);
    printf($format, @_);
    printf "\n";
  }
  if ($self->{trace}) {
    my $logfh = new IO::File;
    $logfh->autoflush(1);
    if ($logfh->open($tracefile, "a")) {
      $logfh->printf("%s: ", scalar localtime);
      $logfh->printf($format, @_);
      $logfh->printf("\n");
      $logfh->close();
    }
  }
}

sub filter_namex {
  my $self = shift;
  my $opt = shift;
  my $name = shift;
  if ($opt) {
    if ($self->opts->regexp) {
      if ($name =~ /$opt/i) {
        return 1;
      }
    } else {
      if (lc $opt eq lc $name) {
        return 1;
      }
    }
  } else {
    return 1;
  }
  return 0;
}

sub filter_name {
  my $self = shift;
  my $name = shift;
  return $self->filter_namex($self->opts->name, $name);
}

sub filter_name2 {
  my $self = shift;
  my $name = shift;
  return $self->filter_namex($self->opts->name2, $name);
}

sub filter_name3 {
  my $self = shift;
  my $name = shift;
  return $self->filter_namex($self->opts->name3, $name);
}

sub blacklist {
  my $self = shift;
  $self->{blacklisted} = 1;
}

sub add_blacklist {
  my $self = shift;
  my $list = shift;
  $GLPlugin::blacklist = join('/',
      (split('/', $self->opts->blacklist), $list));
}

sub is_blacklisted {
  my $self = shift;
  if (! $self->opts->can("blacklist")) {
    return 0;
  }
  if (! exists $self->{blacklisted}) {
    $self->{blacklisted} = 0;
  }
  if (exists $self->{blacklisted} && $self->{blacklisted}) {
    return $self->{blacklisted};
  }
  # FAN:459,203/TEMP:102229/ENVSUBSYSTEM
  # FAN_459,FAN_203,TEMP_102229,ENVSUBSYSTEM
  if ($self->opts->blacklist =~ /_/) {
    foreach my $bl_item (split(/,/, $self->opts->blacklist)) {
      if ($bl_item eq $self->internal_name()) {
        $self->{blacklisted} = 1;
      }
    }
  } else {
    foreach my $bl_items (split(/\//, $self->opts->blacklist)) {
      if ($bl_items =~ /^(\w+):([\:\d\-,]+)$/) {
        my $bl_type = $1;
        my $bl_names = $2;
        foreach my $bl_name (split(/,/, $bl_names)) {
          if ($bl_type."_".$bl_name eq $self->internal_name()) {
            $self->{blacklisted} = 1;
          }
        }
      } elsif ($bl_items =~ /^(\w+)$/) {
        if ($bl_items eq $self->internal_name()) {
          $self->{blacklisted} = 1;
        }
      }
    }
  } 
  return $self->{blacklisted};
}


sub set_thresholds {
  my $self = shift;
  $GLPlugin::plugin->set_thresholds(@_);
}

sub force_thresholds {
  my $self = shift;
  $GLPlugin::plugin->force_thresholds(@_);
}

sub check_thresholds {
  my $self = shift;
  my @params = @_;
  #($self->{warning}, $self->{critical}) =
  #    $GLPlugin::plugin->get_thresholds(@params);
  return $GLPlugin::plugin->check_thresholds(@params);
}

sub get_thresholds {
  my $self = shift;
  my @params = @_;
  my @thresholds = $GLPlugin::plugin->get_thresholds(@params);
  #my($warning, $critical) = $GLPlugin::plugin->get_thresholds(@params);
  #$self->{warning} = $thresholds[0];
  #$self->{critical} = $thresholds[1];
  return @thresholds;
}

sub set_level {
  my $self = shift;
  my $code = shift;
  $code = (qw(ok warning critical unknown))[$code] if $code =~ /^\d+$/;
  $code = lc $code;
  if (! exists $self->{tmp_level}) {
    $self->{tmp_level} = {
      ok => 0,
      warning => 0,
      critical => 0,
      unknown => 0,
    };
  }
  $self->{tmp_level}->{$code}++;
}

sub get_level {
  my $self = shift;
  return OK if ! exists $self->{tmp_level};
  my $code = OK;
  $code ||= CRITICAL if $self->{tmp_level}->{critical};
  $code ||= WARNING  if $self->{tmp_level}->{warning};
  $code ||= UNKNOWN  if $self->{tmp_level}->{unknown};
  return $code;
}

sub add_info {
  my $self = shift;
  my $info = shift;
  $info = $self->is_blacklisted() ? $info.' (blacklisted)' : $info;
  $self->{info} = $info;
  push(@{$GLPlugin::info}, $info);
}

sub annotate_info {
  my $self = shift;
  my $annotation = shift;
  my $lastinfo = pop(@{$GLPlugin::info});
  $lastinfo .= sprintf ' (%s)', $annotation;
  push(@{$GLPlugin::info}, $lastinfo);
}

sub add_extendedinfo {
  my $self = shift;
  my $info = shift;
  $self->{extendedinfo} = $info;
  return if ! $self->opts->extendedinfo;
  push(@{$GLPlugin::extendedinfo}, $info);
}

sub get_info {
  my $self = shift;
  my $separator = shift || ' ';
  return join($separator , @{$GLPlugin::info});
}

sub get_extendedinfo {
  my $self = shift;
  my $separator = shift || ' ';
  return join($separator, @{$GLPlugin::extendedinfo});
}

sub add_summary {
  my $self = shift;
  my $summary = shift;
  push(@{$GLPlugin::summary}, $summary);
}

sub get_summary {
  my $self = shift;
  return join(', ', @{$GLPlugin::summary});
}

sub opts {
  my $self = shift;
  return $GLPlugin::plugin->opts();
}

sub valdiff {
  my $self = shift;
  my $pparams = shift;
  my %params = %{$pparams};
  my @keys = @_;
  my $now = time;
  my $newest_history_set = {};
  my $last_values = $self->load_state(%params) || eval {
    my $empty_events = {};
    foreach (@keys) {
      if (ref($self->{$_}) eq "ARRAY") {
        $empty_events->{$_} = [];
      } else {
        $empty_events->{$_} = 0;
      }
    }
    $empty_events->{timestamp} = 0;
    if ($self->opts->lookback) {
      $empty_events->{lookback_history} = {};
    }
    $empty_events;
  };
  foreach (@keys) {
    if ($self->opts->lookback) {
      # find a last_value in the history which fits lookback best
      # and overwrite $last_values->{$_} with historic data
      if (exists $last_values->{lookback_history}->{$_}) {
        foreach my $date (sort {$a <=> $b} keys %{$last_values->{lookback_history}->{$_}}) {
            $newest_history_set->{$_} = $last_values->{lookback_history}->{$_}->{$date};
            $newest_history_set->{timestamp} = $date;
        }
        foreach my $date (sort {$a <=> $b} keys %{$last_values->{lookback_history}->{$_}}) {
          if ($date >= ($now - $self->opts->lookback)) {
            $last_values->{$_} = $last_values->{lookback_history}->{$_}->{$date};
            $last_values->{timestamp} = $date;
            last;
          } else {
            delete $last_values->{lookback_history}->{$_}->{$date};
          }
        }
      }
    }
    if ($self->{$_} =~ /^\d+$/) {
      $last_values->{$_} = 0 if ! exists $last_values->{$_};
      if ($self->{$_} >= $last_values->{$_}) {
        $self->{'delta_'.$_} = $self->{$_} - $last_values->{$_};
      } else {
        # vermutlich db restart und zaehler alle auf null
        $self->{'delta_'.$_} = $self->{$_};
      }
      $self->debug(sprintf "delta_%s %f", $_, $self->{'delta_'.$_});
    } elsif (ref($self->{$_}) eq "ARRAY") {
      if ((! exists $last_values->{$_} || ! defined $last_values->{$_}) && exists $params{lastarray}) {
        # innerhalb der lookback-zeit wurde nichts in der lookback_history
        # gefunden. allenfalls irgendwas aelteres. normalerweise
        # wuerde jetzt das array als [] initialisiert.
        # d.h. es wuerde ein delta geben, @found s.u.
        # wenn man das nicht will, sondern einfach aktuelles array mit
        # dem array des letzten laufs vergleichen will, setzt man lastarray
        $last_values->{$_} = %{$newest_history_set} ?
            $newest_history_set->{$_} : []
      } elsif ((! exists $last_values->{$_} || ! defined $last_values->{$_}) && ! exists $params{lastarray}) {
        $last_values->{$_} = [] if ! exists $last_values->{$_};
      } elsif (exists $last_values->{$_} && ! defined $last_values->{$_}) {
        # $_ kann es auch ausserhalb des lookback_history-keys als normalen
        # key geben. der zeigt normalerweise auf den entspr. letzten
        # lookback_history eintrag. wurde der wegen ueberalterung abgeschnitten
        # ist der hier auch undef.
        $last_values->{$_} = %{$newest_history_set} ?
            $newest_history_set->{$_} : []
      }
      my %saved = map { $_ => 1 } @{$last_values->{$_}};
      my %current = map { $_ => 1 } @{$self->{$_}};
      my @found = grep(!defined $saved{$_}, @{$self->{$_}});
      my @lost = grep(!defined $current{$_}, @{$last_values->{$_}});
      $self->{'delta_found_'.$_} = \@found;
      $self->{'delta_lost_'.$_} = \@lost;
    }
  }
  $self->{'delta_timestamp'} = $now - $last_values->{timestamp};
  $params{save} = eval {
    my $empty_events = {};
    foreach (@keys) {
      $empty_events->{$_} = $self->{$_};
    }
    $empty_events->{timestamp} = $now;
    if ($self->opts->lookback) {
      $empty_events->{lookback_history} = $last_values->{lookback_history};
      foreach (@keys) {
        $empty_events->{lookback_history}->{$_}->{$now} = $self->{$_};
      }
    }
    $empty_events;
  };
  $self->save_state(%params);
}

sub create_statefilesdir {
  my $self = shift;
  if (! -d $self->statefilesdir()) {
    eval {
      use File::Path;
      mkpath $self->statefilesdir();
    };
    if ($@ || ! -w $self->statefilesdir()) {
      $self->add_message(UNKNOWN,
        sprintf "cannot create status dir %s! check your filesystem (permissions/usage/integrity) and disk devices", $self->statefilesdir());
    }
  } elsif (! -w $self->statefilesdir()) {
    $self->add_message(UNKNOWN,
        sprintf "cannot write status dir %s! check your filesystem (permissions/usage/integrity) and disk devices", $self->statefilesdir());
  }
}

sub create_statefile {
  my $self = shift;
  my %params = @_;
  my $extension = "";
  $extension .= $params{name} ? '_'.$params{name} : '';
  if ($self->opts->community) {
    $extension .= md5_hex($self->opts->community);
  }
  $extension =~ s/\//_/g;
  $extension =~ s/\(/_/g;
  $extension =~ s/\)/_/g;
  $extension =~ s/\*/_/g;
  $extension =~ s/\s/_/g;
  if ($self->opts->snmpwalk && ! $self->opts->hostname) {
    return sprintf "%s/%s_%s%s", $self->statefilesdir(),
        'snmpwalk.file'.md5_hex($self->opts->snmpwalk),
        $self->opts->mode, lc $extension;
  } elsif ($self->opts->snmpwalk && $self->opts->hostname eq "walkhost") {
    return sprintf "%s/%s_%s%s", $self->statefilesdir(),
        'snmpwalk.file'.md5_hex($self->opts->snmpwalk),
        $self->opts->mode, lc $extension;
  } else {
    return sprintf "%s/%s_%s%s", $self->statefilesdir(),
        $self->opts->hostname, $self->opts->mode, lc $extension;
  }
}

sub schimpf {
  my $self = shift;
  printf "statefilesdir %s is not writable.\nYou didn't run this plugin as root, didn't you?\n", $self->statefilesdir();
}

# $self->protect_value('1.1-flat_index', 'cpu_busy', 'percent');
sub protect_value {
  my $self = shift;
  my $ident = shift;
  my $key = shift;
  my $validfunc = shift;
  if (ref($validfunc) ne "CODE" && $validfunc eq "percent") {
    $validfunc = sub {
      my $value = shift;
      return ($value < 0 || $value > 100) ? 0 : 1;
    };
  }
  if (&$validfunc($self->{$key})) {
    $self->save_state(name => 'protect_'.$ident.'_'.$key, save => {
        $key => $self->{$key},
        exception => 0,
    });
  } else {
    # if the device gives us an clearly wrong value, simply use the last value.
    my $laststate = $self->load_state(name => 'protect_'.$ident.'_'.$key);
    $self->debug(sprintf "self->{%s} is %s and invalid for the %dth time",
        $key, $self->{$key}, $laststate->{exception} + 1);
    if ($laststate->{exception} <= 5) {
      # but only 5 times.
      # if the error persists, somebody has to check the device.
      $self->{$key} = $laststate->{$key};
    }
    $self->save_state(name => 'protect_'.$ident.'_'.$key, save => {
        $key => $laststate->{$key},
        exception => $laststate->{exception}++,
    });
  }
}

sub save_state {
  my $self = shift;
  my %params = @_;
  $self->create_statefilesdir();
  my $statefile = $self->create_statefile(%params);
  if ((ref($params{save}) eq "HASH") && exists $params{save}->{timestamp}) {
    $params{save}->{localtime} = scalar localtime $params{save}->{timestamp};
  }
  my $seekfh = new IO::File;
  if ($seekfh->open($statefile, "w")) {
    $seekfh->printf("%s", Data::Dumper::Dumper($params{save}));
    $seekfh->close();
    $self->debug(sprintf "saved %s to %s",
        Data::Dumper::Dumper($params{save}), $statefile);
  } else {
    $self->add_message(UNKNOWN,
        sprintf "cannot write status file %s! check your filesystem (permissions/usage/integrity) and disk devices", $statefile);
  }
}

sub load_state {
  my $self = shift;
  my %params = @_;
  my $statefile = $self->create_statefile(%params);
  if ( -f $statefile) {
    our $VAR1;
    eval {
      require $statefile;
    };
    if($@) {
      printf "rumms\n";
    }
    $self->debug(sprintf "load %s", Data::Dumper::Dumper($VAR1));
    return $VAR1;
  } else {
    return undef;
  }
}

sub dumper {
  my $self = shift;
  my $object = shift;
  my $run = $object->{runtime};
  delete $object->{runtime};
  printf STDERR "%s\n", Data::Dumper::Dumper($object);
  $object->{runtime} = $run;
}

sub no_such_mode {
  my $self = shift;
  printf "Mode %s is not implemented for this type of device\n",
      $self->opts->mode;
  exit 3;
}

sub check_pidfile {
  my $self = shift;
  my $fh = new IO::File;
  if ($fh->open($self->{pidfile}, "r")) {
    my $pid = $fh->getline();
    $fh->close();
    if (! $pid) {
      $self->debug("Found pidfile %s with no valid pid. Exiting.",
          $self->{pidfile});
      return 0;
    } else {
      $self->debug("Found pidfile %s with pid %d", $self->{pidfile}, $pid);
      kill 0, $pid;
      if ($! == Errno::ESRCH) {
        $self->debug("This pidfile is stale. Writing a new one");
        $self->write_pidfile();
        return 1;
      } else {
        $self->debug("This pidfile is held by a running process. Exiting");
        return 0;
      }
    }
  } else {
    $self->debug("Found no pidfile. Writing a new one");
    $self->write_pidfile();
    return 1;
  }
}

sub write_pidfile {
  my $self = shift;
  if (! -d dirname($self->{pidfile})) {
    eval "require File::Path;";
    if (defined(&File::Path::mkpath)) {
      import File::Path;
      eval { mkpath(dirname($self->{pidfile})); };
    } else {
      my @dirs = ();
      map {
          push @dirs, $_;
          mkdir(join('/', @dirs))
              if join('/', @dirs) && ! -d join('/', @dirs);
      } split(/\//, dirname($self->{pidfile}));
    }
  }
  my $fh = new IO::File;
  $fh->autoflush(1);
  if ($fh->open($self->{pidfile}, "w")) {
    $fh->printf("%s", $$);
    $fh->close();
  } else {
    $self->debug("Could not write pidfile %s", $self->{pidfile});
    die "pid file could not be written";
  }
}

sub accentfree {
  my $self = shift;
  my $text = shift;
  # thanks mycoyne who posted this accent-remove-algorithm
  # http://www.experts-exchange.com/Programming/Languages/Scripting/Perl/Q_23275533.html#a21234612
  my @transformed;
  my %replace = (
    '9a' => 's', '9c' => 'oe', '9e' => 'z', '9f' => 'Y', 'c0' => 'A', 'c1' => 'A',
    'c2' => 'A', 'c3' => 'A', 'c4' => 'A', 'c5' => 'A', 'c6' => 'AE', 'c7' => 'C',
    'c8' => 'E', 'c9' => 'E', 'ca' => 'E', 'cb' => 'E', 'cc' => 'I', 'cd' => 'I',
    'ce' => 'I', 'cf' => 'I', 'd0' => 'D', 'd1' => 'N', 'd2' => 'O', 'd3' => 'O',
    'd4' => 'O', 'd5' => 'O', 'd6' => 'O', 'd8' => 'O', 'd9' => 'U', 'da' => 'U',
    'db' => 'U', 'dc' => 'U', 'dd' => 'Y', 'e0' => 'a', 'e1' => 'a', 'e2' => 'a',
    'e3' => 'a', 'e4' => 'a', 'e5' => 'a', 'e6' => 'ae', 'e7' => 'c', 'e8' => 'e',
    'e9' => 'e', 'ea' => 'e', 'eb' => 'e', 'ec' => 'i', 'ed' => 'i', 'ee' => 'i',
    'ef' => 'i', 'f0' => 'o', 'f1' => 'n', 'f2' => 'o', 'f3' => 'o', 'f4' => 'o',
    'f5' => 'o', 'f6' => 'o', 'f8' => 'o', 'f9' => 'u', 'fa' => 'u', 'fb' => 'u',
    'fc' => 'u', 'fd' => 'y', 'ff' => 'y',
  );
  my @letters = split //, $text;;
  for (my $i = 0; $i <= $#letters; $i++) {
    my $hex = sprintf "%x", ord($letters[$i]);
    $letters[$i] = $replace{$hex} if (exists $replace{$hex});
  }
  push @transformed, @letters;
  return join '', @transformed;
}

sub dump {
  my $self = shift;
  my $class = ref($self);
  $class =~ s/^.*:://;
  if (exists $self->{flat_indices}) {
    printf "[%s_%s]\n", uc $class, $self->{flat_indices};
  } else {
    printf "[%s]\n", uc $class;
  }
  foreach (grep !/^(info|trace|warning|critical|blacklisted|extendedinfo|flat_indices|indices)/, sort keys %{$self}) {
    printf "%s: %s\n", $_, $self->{$_} if defined $self->{$_} && ref($self->{$_}) ne "ARRAY";
  }
  if ($self->{info}) {
    printf "info: %s\n", $self->{info};
  }
  printf "\n";
  foreach (grep !/^(info|trace|warning|critical|blacklisted|extendedinfo|flat_indices|indices)/, sort keys %{$self}) {
    if (defined $self->{$_} && ref($self->{$_}) eq "ARRAY") {
      foreach my $obj (@{$self->{$_}}) {
        $obj->dump();
      }
    }
  }
}

sub AUTOLOAD {
  my $self = shift;
  return if ($AUTOLOAD =~ /DESTROY/);
  $self->debug("AUTOLOAD %s\n", $AUTOLOAD)
        if $self->opts->verbose >= 2;
  if ($AUTOLOAD =~ /^(.*)::analyze_and_check_(.*)_subsystem$/) {
    my $class = $1;
    my $subsystem = $2;
    my $analyze = sprintf "analyze_%s_subsystem", $subsystem;
    my $check = sprintf "check_%s_subsystem", $subsystem;
    my @params = @_;
    if (@params) {
      # analyzer class
      my $subsystem_class = shift @params;
      $self->{components}->{$subsystem.'_subsystem'} = $subsystem_class->new();
      $self->debug(sprintf "\$self->{components}->{%s_subsystem} = %s->new()",
          $subsystem, $subsystem_class);
    } else {
      $self->$analyze();
      $self->debug("call %s()", $analyze);
    }
    $self->$check();
  } elsif ($AUTOLOAD =~ /^(.*)::check_(.*)_subsystem$/) {
    my $class = $1;
    my $subsystem = sprintf "%s_subsystem", $2;
    $self->{components}->{$subsystem}->check();
    $self->{components}->{$subsystem}->dump()
        if $self->opts->verbose >= 2;
  } else {
    $self->debug("AUTOLOAD: class %s has no method %s\n",
        ref($self), $AUTOLOAD);
  }
}

package GLPlugin::Commandline;
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3, DEPENDENT => 4 };
our %ERRORS = (
    'OK'        => OK,
    'WARNING'   => WARNING,
    'CRITICAL'  => CRITICAL,
    'UNKNOWN'   => UNKNOWN,
    'DEPENDENT' => DEPENDENT,
);

our %STATUS_TEXT = reverse %ERRORS;


sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
       perfdata => [],
       messages => {
         ok => [],
         warning => [],
         critical => [],
         unknown => [],
       },
       args => [],
       opts => GLPlugin::Commandline::Getopt->new(%params),
       modes => [],
       statefilesdir => undef,
  };
  foreach (qw(shortname usage version url plugin blurb extra
      license timeout)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  $self->{name} = $self->{plugin};
  $GLPlugin::plugin = $self;
}

sub add_arg {
  my $self = shift;
  $self->{opts}->add_arg(@_);
}

sub getopts {
  my $self = shift;
  $self->{opts}->getopts();
}

sub override_opt {
  my $self = shift;
  $self->{opts}->override_opt(@_);
}

sub create_opt {
  my $self = shift;
  $self->{opts}->create_opt(@_);
}

sub opts {
  my $self = shift;
  return $self->{opts};
}

sub add_message {
  my $self = shift;
  my ($code, @messages) = @_;
  $code = (qw(ok warning critical unknown))[$code] if $code =~ /^\d+$/;
  $code = lc $code;
  push @{$self->{messages}->{$code}}, @messages;
}

sub selected_perfdata {
  my $self = shift;
  my $label = shift;
  if ($self->opts->can("selectedperfdata") && $self->opts->selectedperfdata) {
    my $pattern = $self->opts->selectedperfdata;
    return ($label =~ /$pattern/i) ? 1 : 0;
  } else {
    return 1;
  }
}

sub add_perfdata {
  my ($self, %args) = @_;
#printf "add_perfdata %s\n", Data::Dumper::Dumper(\%args);
#printf "add_perfdata %s\n", Data::Dumper::Dumper($self->{thresholds});
#
# wenn warning, critical, dann wird von oben ein expliziter wert mitgegeben
# wenn thresholds
#  wenn label in 
#    warningx $self->{thresholds}->{$label}->{warning} existiert
#  dann nimm $self->{thresholds}->{$label}->{warning}
#  ansonsten thresholds->default->warning
#

  my $label = $args{label};
  my $value = $args{value};
  my $uom = $args{uom} || "";
  my $format = '%d';
  if ($value =~ /\./) {
    if (defined $args{places}) {
      $value = sprintf '%.'.$args{places}.'f', $value;
    } else {
      $value = sprintf "%.2f", $value;
    }
  } else {
    $value = sprintf "%d", $value;
  }
  my $warn = "";
  my $crit = "";
  my $min = "";
  my $max = "";
  if ($args{thresholds} || (! exists $args{warning} && ! exists $args{critical})) {
    if (exists $self->{thresholds}->{$label}->{warning}) {
      $warn = $self->{thresholds}->{$label}->{warning};
    } elsif (exists $self->{thresholds}->{default}->{warning}) {
      $warn = $self->{thresholds}->{default}->{warning};
    }
    if (exists $self->{thresholds}->{$label}->{critical}) {
      $crit = $self->{thresholds}->{$label}->{critical};
    } elsif (exists $self->{thresholds}->{default}->{critical}) {
      $crit = $self->{thresholds}->{default}->{critical};
    }
  } else {
    if ($args{warning}) {
      $warn = $args{warning};
    }
    if ($args{critical}) {
      $crit = $args{critical};
    }
  }
  if ($uom eq "%") {
    $min = 0;
    $max = 100;
  }
  push @{$self->{perfdata}}, sprintf("'%s'=%s%s;%s;%s;%s;%s",
      $label, $value, $uom, $warn, $crit, $min, $max)
      if $self->selected_perfdata($label);
}

sub add_html {
  my $self = shift;
  my $line = shift;
  push @{$self->{html}}, $line;
}

sub suppress_messages {
  my $self = shift;
  $self->{suppress_messages} = 1;
}

sub clear_messages {
  my $self = shift;
  my $code = shift;
  $code = (qw(ok warning critical unknown))[$code] if $code =~ /^\d+$/;
  $code = lc $code;
  $self->{messages}->{$code} = [];
}

sub check_messages {
  my $self = shift;
  my %args = @_;

  # Add object messages to any passed in as args
  for my $code (qw(critical warning unknown ok)) {
    my $messages = $self->{messages}->{$code} || [];
    if ($args{$code}) {
      unless (ref $args{$code} eq 'ARRAY') {
        if ($code eq 'ok') {
          $args{$code} = [ $args{$code} ];
        }
      }
      push @{$args{$code}}, @$messages;
    } else {
      $args{$code} = $messages;
    }
  }
  my %arg = %args;
  $arg{join} = ' ' unless defined $arg{join};

  # Decide $code
  my $code = OK;
  $code ||= CRITICAL  if @{$arg{critical}};
  $code ||= WARNING   if @{$arg{warning}};
  $code ||= UNKNOWN   if @{$arg{unknown}};
  return $code unless wantarray;

  # Compose message
  my $message = '';
  if ($arg{join_all}) {
      $message = join( $arg{join_all},
          map { @$_ ? join( $arg{'join'}, @$_) : () }
              $arg{critical},
              $arg{warning},
              $arg{unknown},
              $arg{ok} ? (ref $arg{ok} ? $arg{ok} : [ $arg{ok} ]) : []
      );
  }

  else {
      $message ||= join( $arg{'join'}, @{$arg{critical}} )
          if $code == CRITICAL;
      $message ||= join( $arg{'join'}, @{$arg{warning}} )
          if $code == WARNING;
      $message ||= join( $arg{'join'}, @{$arg{unknown}} )
          if $code == UNKNOWN;
      $message ||= ref $arg{ok} ? join( $arg{'join'}, @{$arg{ok}} ) : $arg{ok}
          if $arg{ok};
  }

  return ($code, $message);
}

sub status_code {
  my $self = shift;
  my $code = shift;
  $code = (qw(ok warning critical unknown))[$code] if $code =~ /^\d+$/;
  $code = uc $code;
  $code = $ERRORS{$code} if defined $code && exists $ERRORS{$code};
  $code = UNKNOWN unless defined $code && exists $STATUS_TEXT{$code};
  return "$STATUS_TEXT{$code}";
}

sub perfdata_string {
  my $self = shift;
  if (scalar (@{$self->{perfdata}})) {
    return join(" ", @{$self->{perfdata}});
  } else {
    return "";
  }
}

sub html_string {
  my $self = shift;
  if (scalar (@{$self->{html}})) {
    return join(" ", @{$self->{html}});
  } else {
    return "";
  }
}

sub nagios_exit {
  my $self = shift;
  my ($code, $message, $arg) = @_;
  $code = $ERRORS{$code} if defined $code && exists $ERRORS{$code};
  $code = UNKNOWN unless defined $code && exists $STATUS_TEXT{$code};
  $message = '' unless defined $message;
  if (ref $message && ref $message eq 'ARRAY') {
      $message = join(' ', map { chomp; $_ } @$message);
  } else {
      chomp $message;
  }
  if ($self->opts->negate) {
    foreach my $from (keys %{$self->opts->negate}) {
      if ((uc $from) =~ /^(OK|WARNING|CRITICAL|UNKNOWN)$/ &&
          (uc $self->opts->negate->{$from}) =~ /^(OK|WARNING|CRITICAL|UNKNOWN)$/) {
        if ($code == $ERRORS{uc $from}) {
          $code = $ERRORS{uc $self->opts->negate->{$from}};
        }
      }
    }
  }
  my $output = "$STATUS_TEXT{$code}";
  $output .= " - $message" if defined $message && $message ne '';
  if (scalar (@{$self->{perfdata}})) {
    $output .= " | ".$self->perfdata_string();
  }
  $output .= "\n";
  if (! exists $self->{suppress_messages}) {
    print $output;
  }
  exit $code;
}

sub set_thresholds {
  my $self = shift;
  my %params = @_;
  if (exists $params{metric}) {
    my $metric = $params{metric};
    $self->{thresholds}->{$metric}->{warning} = 
        $params{warning} if $params{warning};
    $self->{thresholds}->{$metric}->{warning} = 
        $self->{thresholds}->{$metric}->{warning} 
        if $self->{thresholds}->{$metric}->{warning};
    $self->{thresholds}->{$metric}->{critical} = 
        $params{critical} if $params{critical};
    $self->{thresholds}->{$metric}->{critical} = 
        $self->{thresholds}->{$metric}->{critical}
        if $self->{thresholds}->{$metric}->{critical};
  } else {
    $self->{thresholds}->{default}->{warning} =
        $self->opts->warning || $params{warning} || 0;
    $self->{thresholds}->{default}->{critical} =
        $self->opts->critical || $params{critical} || 0;
  }
}

sub force_thresholds {
  my $self = shift;
  my %params = @_;
  if (exists $params{metric}) {
    my $metric = $params{metric};
    $self->{thresholds}->{$metric}->{warning} = $params{warning} || 0;
    $self->{thresholds}->{$metric}->{critical} = $params{critical} || 0;
  } else {
    $self->{thresholds}->{default}->{warning} = $params{warning} || 0;
    $self->{thresholds}->{default}->{critical} = $params{critical} || 0;
  }
}

sub get_thresholds {
  my $self = shift;
  my @params = @_;
  if (scalar(@params) > 1) {
    my %params = @params;
    my $metric = $params{metric};
    return ($self->{thresholds}->{$metric}->{warning},
        $self->{thresholds}->{$metric}->{critical});
  } else {
    return ($self->{thresholds}->{default}->{warning},
        $self->{thresholds}->{default}->{critical});
  }
}

sub check_thresholds {
  my $self = shift;
  my @params = @_;
  my $level = $ERRORS{OK};
  my $warningrange;
  my $criticalrange;
  my $value;
  if (scalar(@params) > 1) {
    my %params = @params;
    $value = $params{value};
    my $metric = $params{metric};
    if ($metric ne 'default') {
      $warningrange = exists $self->{thresholds}->{$metric}->{warning} ?
          $self->{thresholds}->{$metric}->{warning} :
          $self->{thresholds}->{default}->{warning};
      $criticalrange = exists $self->{thresholds}->{$metric}->{critical} ?
          $self->{thresholds}->{$metric}->{critical} :
          $self->{thresholds}->{default}->{critical};
    } else {
      $warningrange = (defined $params{warning}) ?
          $params{warning} : $self->{thresholds}->{default}->{warning};
      $criticalrange = (defined $params{critical}) ?
          $params{critical} : $self->{thresholds}->{default}->{critical};
    }
  } else {
    $value = $params[0];
    $warningrange = $self->{thresholds}->{default}->{warning};
    $criticalrange = $self->{thresholds}->{default}->{critical};
  }
  if ($warningrange =~ /^([-+]?[0-9]*\.?[0-9]+)$/) {
    # warning = 10, warn if > 10 or < 0
    $level = $ERRORS{WARNING}
        if ($value > $1 || $value < 0);
  } elsif ($warningrange =~ /^([-+]?[0-9]*\.?[0-9]+):$/) {
    # warning = 10:, warn if < 10
    $level = $ERRORS{WARNING}
        if ($value < $1);
  } elsif ($warningrange =~ /^~:([-+]?[0-9]*\.?[0-9]+)$/) {
    # warning = ~:10, warn if > 10
    $level = $ERRORS{WARNING}
        if ($value > $1);
  } elsif ($warningrange =~ /^([-+]?[0-9]*\.?[0-9]+):([-+]?[0-9]*\.?[0-9]+)$/) {
    # warning = 10:20, warn if < 10 or > 20
    $level = $ERRORS{WARNING}
        if ($value < $1 || $value > $2);
  } elsif ($warningrange =~ /^@([-+]?[0-9]*\.?[0-9]+):([-+]?[0-9]*\.?[0-9]+)$/) {
    # warning = @10:20, warn if >= 10 and <= 20
    $level = $ERRORS{WARNING}
        if ($value >= $1 && $value <= $2);
  }
  if ($criticalrange =~ /^([-+]?[0-9]*\.?[0-9]+)$/) {
    # critical = 10, crit if > 10 or < 0
    $level = $ERRORS{CRITICAL}
        if ($value > $1 || $value < 0);
  } elsif ($criticalrange =~ /^([-+]?[0-9]*\.?[0-9]+):$/) {
    # critical = 10:, crit if < 10
    $level = $ERRORS{CRITICAL}
        if ($value < $1);
  } elsif ($criticalrange =~ /^~:([-+]?[0-9]*\.?[0-9]+)$/) {
    # critical = ~:10, crit if > 10
    $level = $ERRORS{CRITICAL}
        if ($value > $1);
  } elsif ($criticalrange =~ /^([-+]?[0-9]*\.?[0-9]+):([-+]?[0-9]*\.?[0-9]+)$/) {
    # critical = 10:20, crit if < 10 or > 20
    $level = $ERRORS{CRITICAL}
        if ($value < $1 || $value > $2);
  } elsif ($criticalrange =~ /^@([-+]?[0-9]*\.?[0-9]+):([-+]?[0-9]*\.?[0-9]+)$/) {
    # critical = @10:20, crit if >= 10 and <= 20
    $level = $ERRORS{CRITICAL}
        if ($value >= $1 && $value <= $2);
  }
  return $level;
}


package GLPlugin::Commandline::Getopt;
use strict;
use File::Basename;
use Getopt::Long qw(:config no_ignore_case bundling);

# Standard defaults
my %DEFAULT = (
  timeout => 15,
  verbose => 0,
  license =>
"This monitoring plugin is free software, and comes with ABSOLUTELY NO WARRANTY.
It may be used, redistributed and/or modified under the terms of the GNU
General Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).",
);
# Standard arguments
my @ARGS = ({
    spec => 'usage|?',
    help => "-?, --usage\n   Print usage information",
  }, {
    spec => 'help|h',
    help => "-h, --help\n   Print detailed help screen",
  }, {
    spec => 'version|V',
    help => "-V, --version\n   Print version information",
  }, {
    #spec => 'extra-opts:s@',
    #help => "--extra-opts=[<section>[@<config_file>]]\n   Section and/or config_file from which to load extra options (may repeat)",
  }, {
    spec => 'timeout|t=i',
    help => sprintf("-t, --timeout=INTEGER\n   Seconds before plugin times out (default: %s)", $DEFAULT{timeout}),
    default => $DEFAULT{timeout},
  }, {
    spec => 'verbose|v+',
    help => "-v, --verbose\n   Show details for command-line debugging (can repeat up to 3 times)",
    default => $DEFAULT{verbose},
  },
);
# Standard arguments we traditionally display last in the help output
my %DEFER_ARGS = map { $_ => 1 } qw(timeout verbose);

sub _init {
  my $self = shift;
  my %params = @_;
  # Check params
  my $plugin = basename($0);
  #my %attr = validate( @_, {
  my %attr = (
    usage => 1,
    version => 0,
    url => 0,
    plugin => { default => $plugin },
    blurb => 0,
    extra => 0,
    'extra-opts' => 0,
    license => { default => $DEFAULT{license} },
    timeout => { default => $DEFAULT{timeout} },
  );

  # Add attr to private _attr hash (except timeout)
  $self->{timeout} = delete $attr{timeout};
  $self->{_attr} = { %attr };
  foreach (keys %{$self->{_attr}}) {
    if (exists $params{$_}) {
      $self->{_attr}->{$_} = $params{$_};
    } else {
      $self->{_attr}->{$_} = $self->{_attr}->{$_}->{default}
          if ref ($self->{_attr}->{$_}) eq 'HASH' &&
              exists $self->{_attr}->{$_}->{default};
    }
  }
  # Chomp _attr values
  chomp foreach values %{$self->{_attr}};

  # Setup initial args list
  $self->{_args} = [ grep { exists $_->{spec} } @ARGS ];

  $self
}

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  $self->_init(@_);
}

sub add_arg {
  my $self = shift;
  my %arg = @_;
  push (@{$self->{_args}}, \%arg);
}

sub getopts {
  my $self = shift;
  my %commandline = ();
  my @params = map { $_->{spec} } @{$self->{_args}};
  if (! GetOptions(\%commandline, @params)) {
    $self->print_help();
    exit 0;
  } else {
    no strict 'refs';
    do { $self->print_help(); exit 0; } if $commandline{help};
    do { $self->print_version(); exit 0 } if $commandline{version};
    do { $self->print_usage(); exit 3 } if $commandline{usage};
    foreach (map { $_->{spec} =~ /^([\w\-]+)/; $1; } @{$self->{_args}}) {
      my $field = $_;
      *{"$field"} = sub {
        return $self->{opts}->{$field};
      };
    }
    foreach (map { $_->{spec} =~ /^([\w\-]+)/; $1; }
        grep { exists $_->{required} && $_->{required} } @{$self->{_args}}) {
      do { $self->print_usage(); exit 0 } if ! exists $commandline{$_};
    }
    foreach (grep { exists $_->{default} } @{$self->{_args}}) {
      $_->{spec} =~ /^([\w\-]+)/;
      my $spec = $1;
      $self->{opts}->{$spec} = $_->{default};
    }
    foreach (keys %commandline) {
      $self->{opts}->{$_} = $commandline{$_};
    }
  }
}

sub create_opt {
  my $self = shift;
  my $key = shift;
  no strict 'refs';
  *{"$key"} = sub {
      return $self->{opts}->{$key};
  };
}

sub override_opt {
  my $self = shift;
  my $key = shift;
  my $value = shift;
  $self->{opts}->{$key} = $value;
}

sub get {
  my $self = shift;
  my $opt = shift;
  return $self->{opts}->{$opt};
}

sub print_help {
  my $self = shift;
  $self->print_version();
  printf "\n%s\n", $self->{_attr}->{license};
  printf "\n%s\n\n", $self->{_attr}->{blurb};
  $self->print_usage();
  foreach (@{$self->{_args}}) {
    printf " %s\n", $_->{help};
  }
  exit 0;
}

sub print_usage {
  my $self = shift;
  printf $self->{_attr}->{usage}, $self->{_attr}->{plugin};
  print "\n";
}

sub print_version {
  my $self = shift;
  printf "%s %s", $self->{_attr}->{plugin}, $self->{_attr}->{version};
  printf " [%s]", $self->{_attr}->{url} if $self->{_attr}->{url};
  print "\n";
}

sub print_license {
  my $self = shift;
  printf "%s\n", $self->{_attr}->{license};
  print "\n";
}


package GLPlugin::Item;
our @ISA = qw(GLPlugin);

use strict;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub check {
  my $self = shift;
  my $lists = shift;
  my @lists = $lists ? @{$lists} : grep { ref($self->{$_}) eq "ARRAY" } keys %{$self};
  foreach my $list (@lists) {
    $self->add_info('checking '.$list);
    foreach my $element (@{$self->{$list}}) {
      $element->blacklist() if $self->is_blacklisted();
      $element->check();
    }
  }
}


package GLPlugin::TableItem;
our @ISA = qw(GLPlugin::Item);

use strict;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {};
  bless $self, $class;
  foreach (keys %params) {
    $self->{$_} = $params{$_};
  }
  if ($self->can("finish")) {
    $self->finish(%params);
  }
  return $self;
}

sub ensure_index {
  my $self = shift;
  my $key = shift;
  $self->{$key} ||= $self->{flat_indices};
}

sub check {
  my $self = shift;
  # some tableitems are not checkable, they are only used to enhance other
  # items (e.g. sensorthresholds enhance sensors)
  # normal tableitems should have their own check-method
}

