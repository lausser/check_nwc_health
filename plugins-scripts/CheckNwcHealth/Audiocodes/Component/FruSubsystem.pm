package CheckNwcHealth::Audiocodes::Component::FruSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('AC-SYSTEM-MIB', [
    ['fru_modules', 'acSysModuleTable', 'CheckNwcHealth::Audiocodes::Component::FruSubsystem::FruModule', sub { my ($o) = @_; $o->{parent} = $self; }],
  ]);
}

sub check {
  my ($self) = @_;
  $self->add_info('checking FRU modules');
  if (defined $self->{fru_modules} && ref($self->{fru_modules}) eq 'ARRAY') {
    foreach (@{$self->{fru_modules}}) {
      $_->check();
    }
  } else {
    $self->add_info('no FRU modules found');
  }
}

sub dump {
  my ($self) = @_;
  if (defined $self->{fru_modules} && ref($self->{fru_modules}) eq 'ARRAY') {
    foreach (@{$self->{fru_modules}}) {
      $_->dump();
    }
  }
}

package CheckNwcHealth::Audiocodes::Component::FruSubsystem::FruModule;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my $index = $self->{flat_indices};
  my $fru_status = $self->{acSysModuleFRUstatus};

  $self->add_info(sprintf 'module %s FRU status: %s', $index, $fru_status);

  if ($fru_status eq 'moduleNotExist' || $fru_status eq 'notApplicable') {
    # ignore these
    return;
  } elsif ($fru_status eq 'moduleExistOk') {
    $self->add_ok();
  } elsif ($fru_status eq 'moduleMismatch' || $fru_status eq 'moduleBackToServiceStart') {
    $self->add_warning(sprintf 'module %s FRU status: %s', $index, $fru_status);
  } elsif ($fru_status eq 'moduleOutOfService' || $fru_status eq 'moduleFaulty') {
    $self->add_critical(sprintf 'module %s FRU status: %s', $index, $fru_status);
  } else {
    $self->add_warning(sprintf 'module %s FRU status: %s (unknown)', $index, $fru_status);
  }
}

sub dump {
  my ($self) = @_;
  printf "module %s FRU status: %s\n",
      $self->{flat_indices}, $self->{acSysModuleFRUstatus};
}