package Classes::FabOS::Component::InterfaceSubsystem;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem);
use strict;

sub enrich_interface_cache {
  my ($self) = @_;
  $self->get_snmp_tables('SW-MIB', [
    ['fcinterfaces', 'swFCPortTable', 'Monitoring::GLPlugin::SNMP::TableItem', undef, ['swFCPortIndex', 'swFCPortName']],
  ]);
  foreach my $index (keys %{$self->{interface_cache}}) {
    my $ifDescr = $self->{interface_cache}->{$index}->{ifDescr};
    if ($ifDescr =~ /FC port 0\/(\d+)/) {
      my $label = $1;
      foreach my $fcinterface (@{$self->{fcinterfaces}}) {
        if ($fcinterface->{swFCPortName} &&
            $fcinterface->{swFCPortIndex} == $label + 1 &&
            $fcinterface->{swFCPortName} !~ /^port\d+$/) {
          $self->{interface_cache}->{$index}->{swFCPortName} =
              $fcinterface->{swFCPortName};
          $self->{interface_cache}->{$index}->{swFCPortIndex} =
              $fcinterface->{swFCPortIndex};
        }
      }
    }
  }
}

sub get_interface_indices {
  my ($self) = @_;
  # --name3 swFCPortName
  # wer sowas haben will: kostet 2880 Euro.
  $self->SUPER::get_interface_indices();
}

sub enrich_interface_attributes {
  my ($self, $interface) = @_;
  foreach my $index (keys %{$self->{interface_cache}}) {
    if ($index eq $interface->{flat_indices}) {
      if (exists $self->{interface_cache}->{$index}->{swFCPortName}) {
        $interface->{swFCPortName} =
            $self->{interface_cache}->{$index}->{swFCPortName};
        $interface->{swFCPortIndex} =
            $self->{interface_cache}->{$index}->{swFCPortIndex};
        if (! $interface->{ifAlias} || $interface->{ifAlias} eq '________') {
          $interface->{ifAlias} = $interface->{swFCPortName};
        }
      }
    }
  }
}

# eigentlich unnoetig, aber Classes::IFMIB::Component::InterfaceSubsystem
# blesst ref($self)::Interface
# falls es mal doch nich noetig sein sollte, am interface-check() was zu drehen
#
package Classes::FabOS::Component::InterfaceSubsystem::Interface;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem::Interface);
use strict;

package Classes::FabOS::Component::InterfaceSubsystem::Interface::64bit;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem::Interface::64bit);
use strict;


