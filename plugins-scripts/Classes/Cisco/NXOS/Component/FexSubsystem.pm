package Classes::Cisco::NXOS::Component::FexSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-ETHERNET-FABRIC-EXTENDER-MIB', [
    ['fexes', 'cefexConfigTable', 'Classes::Cisco::NXOS::Component::FexSubsystem::Fex'],
  ]);
}

sub dump {
  my $self = shift;
  foreach (@{$self->{fexes}}) {
    $_->dump();
  }
}

sub check {
  my $self = shift;
  $self->add_info('counting fexes');
  $self->{numOfFexes} = scalar (@{$self->{fexes}});
  $self->{fexNameList} = [map { $_->{cefexConfigExtenderName} } @{$self->{fexes}}];
  if (scalar (@{$self->{fexes}}) == 0) {
    $self->add_unknown('no FEXes found');
  } else {
    # lookback, denn sonst muesste der check is_volatile sein und koennte bei
    # einem kurzen netzausfall fehler schmeissen.
    # empfehlung: check_interval 5 (muss jedesmal die entity-mib durchwalken)
    #             retry_interval 2
    #             max_check_attempts 2
    # --lookback 360
    $self->opts->override_opt('lookback', 1800) if ! $self->opts->lookback;
    $self->valdiff({name => $self->{name}, lastarray => 1},
        qw(fexNameList numOfFexes));
    if (scalar(@{$self->{delta_found_fexNameList}}) > 0) {
      $self->add_warning(sprintf '%d new FEX(es) (%s)',
          scalar(@{$self->{delta_found_fexNameList}}),
          join(", ", @{$self->{delta_found_fexNameList}}));
    }
    if (scalar(@{$self->{delta_lost_fexNameList}}) > 0) {
      $self->add_critical(sprintf '%d FEXes missing (%s)',
          scalar(@{$self->{delta_lost_fexNameList}}),
          join(", ", @{$self->{delta_lost_fexNameList}}));
    }
    $self->add_ok(sprintf 'found %d FEXes', scalar (@{$self->{fexes}}));
    $self->add_perfdata(
        label => 'num_fexes',
        value => $self->{numOfFexes},
    );
  }
}

package Classes::Cisco::NXOS::Component::FexSubsystem::Fex;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

