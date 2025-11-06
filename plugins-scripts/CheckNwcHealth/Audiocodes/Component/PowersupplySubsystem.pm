package CheckNwcHealth::Audiocodes::Component::PowersupplySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('AC-SYSTEM-MIB', [
    ['powersupplies', 'acSysPowerSupplyTable', 'CheckNwcHealth::Audiocodes::Component::PowersupplySubsystem::Powersupply'],
  ]);
}

sub check {
  my ($self) = @_;
  $self->add_info('checking power supplies');
  foreach (@{$self->{powersupplies}}) {
    $_->check();
  }
}

sub dump {
  my ($self) = @_;
  foreach (@{$self->{powersupplies}}) {
    $_->dump();
  }
}

package CheckNwcHealth::Audiocodes::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

 sub check {
   my ($self) = @_;
   my $existence = $self->{acSysPowerSupplyExistence};
   if ($existence eq 'present') { # present
     $self->add_info(sprintf 'power supply %d is present', $self->{acSysPowerSupplyIndex} || $self->{flat_indices});
     my $severity = $self->{acSysPowerSupplySeverity};
     if ($severity eq 'cleared') { # cleared
       $self->add_ok();
     } elsif ($severity eq 'indeterminate') { # indeterminate
       $self->add_warning('power supply indeterminate');
     } elsif ($severity eq 'warning') { # warning
       $self->add_warning('power supply warning');
     } elsif ($severity eq 'minor' || $severity eq 'major' || $severity eq 'critical') { # minor, major, critical
       $self->add_critical('power supply critical');
     }
   } else {
     $self->add_info(sprintf 'power supply %d is missing', $self->{acSysPowerSupplyIndex} || $self->{flat_indices});
   }
 }



