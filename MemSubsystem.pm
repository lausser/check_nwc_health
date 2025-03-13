package MemSubsystem;

use strict;
use warnings;
use Net::SNMP;

# Initialize memory-related variables
my $total_memory = 0;
my $used_memory = 0;
my $free_memory = 0;

# SNMP OIDs for F5 Velos devices
my $oid_total_memory = '1.3.6.1.4.1.3375.2.1.1.2.1.44.0'; # Example OID, verify with F5 documentation
my $oid_used_memory = '1.3.6.1.4.1.3375.2.1.1.2.1.46.0';  # Example OID, verify with F5 documentation

sub new {
    my ($class, %args) = @_;
    my $self = {
        hostname => $args{hostname},
        community => $args{community} || 'public',
    };
    bless $self, $class;
    return $self;
}

sub fetch_memory_info {
    my ($self) = @_;

    my ($session, $error) = Net::SNMP->session(
        -hostname  => $self->{hostname},
        -community => $self->{community},
    );

    if (!defined $session) {
        die "Error creating SNMP session: $error";
    }

    my $result = $session->get_request(
        -varbindlist => [$oid_total_memory, $oid_used_memory],
    );

    if (!defined $result) {
        warn "SNMP get_request error: " . $session->error();
        $session->close();
        return;
    }

    # Error handling for undefined or zero values
    $total_memory = $result->{$oid_total_memory} // 0;
    $used_memory = $result->{$oid_used_memory} // 0;

    if ($total_memory == 0) {
        warn "Total memory is zero or undefined.";
        $session->close();
        return;
    }

    $free_memory = $total_memory - $used_memory;

    $session->close();
}

sub get_total_memory {
    my ($self) = @_;
    return $total_memory;
}

sub get_used_memory {
    my ($self) = @_;
    return $used_memory;
}

sub get_free_memory {
    my ($self) = @_;
    return $free_memory;
}

1;