package CheckNwcHealth::Clavister::Firewall1::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use Data::Dumper;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CLAVISTER-MIB', [
      ['sensor', 'clvHWSensorEntry', 'CheckNwcHealth::Clavister::Firewall1::Component::HWSensor'],
  ]);
}

sub check {
  my ($self) = @_;
  foreach (@{$self->{sensor}}) {
    $_->check();
  }
}


package CheckNwcHealth::Clavister::Firewall1::Component::HWSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if ($self->{clvHWSensorName} =~ /Fan/i) {
    $self->add_info(sprintf '%s is running (%d %s)', 
        $self->{clvHWSensorName}, $self->{clvHWSensorValue}, $self->{clvHWSensorUnit});
    $self->set_thresholds(warning => "6000:7500", critical => "1000:10000");
    $self->add_message($self->check_thresholds($self->{clvHWSensorValue}));
    $self->add_perfdata(
        label => $self->{clvHWSensorName}.'_rpm',
        value => $self->{clvHWSensorValue},
    );
  } elsif ($self->{clvHWSensorName} =~ /Temp/i) {
    $self->add_info(sprintf '%s is running (%d %s)',
        $self->{clvHWSensorName}, $self->{clvHWSensorValue}, $self->{clvHWSensorUnit});
    $self->set_thresholds(warning => 60, critical => 70);
    $self->add_message($self->check_thresholds($self->{clvHWSensorValue}));
    $self->add_perfdata(
        label => $self->{clvHWSensorName}.'_'.$self->{clvHWSensorUnit},
        value => $self->{clvHWSensorValue},
    );
  }
}

