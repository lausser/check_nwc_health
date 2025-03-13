#!/usr/bin/perl
use strict;
use warnings;

# Ensure all necessary modules are loaded
use Module::Load;

# List of required modules
my @required_modules = qw(
    Data::Dumper
    File::Spec
    File::Basename
);

# Verify that all necessary modules are loaded and accessible
foreach my $module (@required_modules) {
    eval {
        load $module;
        1;
    } or do {
        die "Failed to load module $module: $@";
    };
}

# Check for naming conventions and ensure they match expected values
my %expected_naming_conventions = (
    'Data::Dumper' => 'Dumper',
    'File::Spec'   => 'Spec',
    'File::Basename' => 'Basename',
);

foreach my $module (keys %expected_naming_conventions) {
    no strict 'refs';
    my $expected_name = $expected_naming_conventions{$module};
    unless (defined &{"${module}::${expected_name}"}) {
        die "Naming convention mismatch for module $module: expected $expected_name";
    }
}

print "All modules loaded and naming conventions verified successfully.\n";