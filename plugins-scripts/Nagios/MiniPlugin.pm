package Nagios::MiniPlugin;

use strict;
use Getopt::Long qw(:config no_ignore_case bundling);

our @STATUS_CODES = qw(OK WARNING CRITICAL UNKNOWN DEPENDENT);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = (@STATUS_CODES, qw(nagios_exit nagios_die check_messages));
our @EXPORT_OK = qw(%ERRORS);

use constant OK         => 0;
use constant WARNING    => 1;
use constant CRITICAL   => 2;
use constant UNKNOWN    => 3;
use constant DEPENDENT  => 4;

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
       opts => Nagios::MiniPlugin::Getopt->new(%params),
  };
  foreach (qw(shortname usage version url plugin blurb extra
      license timeout)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
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

sub add_perfdata {
  my ($self, %args) = @_;
  #if ($args{label} =~ /\s/) {
    $args{label} = '\''.$args{label}.'\'';
  #}
  if (! exists $args{places}) {
    $args{places} = 2;
  }
  my $format = '%d';
  if ($args{value} =~ /\./) {
    $format = '%.'.$args{places}.'f';
  }
  my $str = $args{label}.'='.sprintf $format, $args{value};
  if ($args{uom}) {
    $str .= $args{uom};
  }
  if ($args{warning}) {
    $str .= ';'.$args{warning};
  }
  if ($args{critical}) {
    $str .= ';'.$args{critical};
  }
  push @{$self->{perfdata}}, $str;
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
  my $output = "$STATUS_TEXT{$code}";
  $output .= " - $message" if defined $message && $message ne '';
  if (scalar (@{$self->{perfdata}})) {
    $output .= " | ".join(" ", @{$self->{perfdata}});
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
  $self->{mywarning} = $self->opts->warning || $params{warning} || 0;
  $self->{mycritical} = $self->opts->critical || $params{critical} || 0;
}

sub force_thresholds {
  my $self = shift;
  my %params = @_;
  $self->{mywarning} = $params{warning} || 0;
  $self->{mycritical} = $params{critical} || 0;
}

sub get_thresholds {
  my $self = shift;
  return ($self->{mywarning}, $self->{mycritical});
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
    $value = $params{check};
    $warningrange = (defined $params{warning}) ?
        $params{warning} : $self->{mywarning};
    $criticalrange = (defined $params{critical}) ?
        $params{critical} : $self->{mycritical};
  } else {
    $value = $params[0];
    $warningrange = $self->{mywarning};
    $criticalrange = $self->{mycritical};
  }
  if ($warningrange =~ /^(\d+)$/) {
    # warning = 10, warn if > 10 or < 0
    $level = $ERRORS{WARNING}
        if ($value > $1 || $value < 0);
  } elsif ($warningrange =~ /^(\d+):$/) {
    # warning = 10:, warn if < 10
    $level = $ERRORS{WARNING}
        if ($value < $1);
  } elsif ($warningrange =~ /^~:(\d+)$/) {
    # warning = ~:10, warn if > 10
    $level = $ERRORS{WARNING}
        if ($value > $1);
  } elsif ($warningrange =~ /^(\d+):(\d+)$/) {
    # warning = 10:20, warn if < 10 or > 20
    $level = $ERRORS{WARNING}
        if ($value < $1 || $value > $2);
  } elsif ($warningrange =~ /^@(\d+):(\d+)$/) {
    # warning = @10:20, warn if >= 10 and <= 20
    $level = $ERRORS{WARNING}
        if ($value >= $1 && $value <= $2);
  }
  if ($criticalrange =~ /^(\d+)$/) {
    # critical = 10, crit if > 10 or < 0
    $level = $ERRORS{CRITICAL}
        if ($value > $1 || $value < 0);
  } elsif ($criticalrange =~ /^(\d+):$/) {
    # critical = 10:, crit if < 10
    $level = $ERRORS{CRITICAL}
        if ($value < $1);
  } elsif ($criticalrange =~ /^~:(\d+)$/) {
    # critical = ~:10, crit if > 10
    $level = $ERRORS{CRITICAL}
        if ($value > $1);
  } elsif ($criticalrange =~ /^(\d+):(\d+)$/) {
    # critical = 10:20, crit if < 10 or > 20
    $level = $ERRORS{CRITICAL}
        if ($value < $1 || $value > $2);
  } elsif ($criticalrange =~ /^@(\d+):(\d+)$/) {
    # critical = @10:20, crit if >= 10 and <= 20
    $level = $ERRORS{CRITICAL}
        if ($value >= $1 && $value <= $2);
  }
  return $level;
}


package Nagios::MiniPlugin::Getopt;

use strict;
use File::Basename;
use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case bundling);

# Standard defaults
my %DEFAULT = (
  timeout => 15,
  verbose => 0,
  license =>
"This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY.
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

sub _init
{
  my $self = shift;
  my %params = @_;
  # Check params
  my $plugin = basename($ENV{NAGIOS_PLUGIN} || $0);
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

sub new
{
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

1;
