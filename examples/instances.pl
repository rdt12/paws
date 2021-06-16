#!/usr/bin/perl -w 
###
### Author: rdt12+github@psu.edu
### Date:   Jun 16, 2020
###
use strict;
use Paws;
use Paws::Credential::File;
use Data::Dumper;
use Getopt::Long;

my($opt_Help, $opt_Region, $opt_Profile, $opt_Creds);
GetOptions("help"          => \$opt_Help,
           "region=s"      => \$opt_Region,
	   "profile=s"     => \$opt_Profile,
	   "credentials=s" => \$opt_Creds);

if (defined($opt_Help)) {
    printUsage();
    exit(0);
}

my($region) = 'us-west-2';
if (defined($opt_Region)) {
    $region = $opt_Region;
}

my($profile) = 'default';
if (defined($opt_Profile)) {
    $profile = $opt_Profile;
}

my($credsFile) = $ENV{'HOME'} . '/.aws/credentials';
if (defined($opt_Creds)) {
    $credsFile = $opt_Creds;
}

my($creds)  = Paws::Credential::File->new(profile => $profile, credentials_file => $credsFile);
my($config) = {credentials => $creds, profile => $profile, region => $region};

my($paws) = Paws->new(config => $config);

my($ec2) = $paws->service('EC2');

my($result) = $ec2->DescribeInstances();

my($reservations) = $result->{'Reservations'};

my($instances);
my($inst);
my($res);
my($name);
my(@tags);
my($tag);
for $res (@{$reservations}) {
    $instances = $res->{'Instances'};
    for $inst (@{$instances}) {
	@tags = @{$inst->{'Tags'}};
	$name = "UNKNOWN";
	for $tag (@tags) {
	    if ($tag->{'Key'} eq 'Name') {
		$name = $tag->{'Value'};
	    }
	}
	printf("Instance: %s VPC: %s Name: %s\n", $inst->{'InstanceId'}, $inst->{'VpcId'}, $name);
    }
}


sub myName {
    my($name) = $0;
    if ($name =~ /([^\/]+)$/) {
        $name = $1;
    }
    chomp($name);
    return $name;
}


sub printUsage {
    my($name) = myName();

    printf("\nUsage:\n\n");
    printf("  %s [--region=REGION] [--profile=PROFILE] [--credentials=CREDS_FILE]\n\n", $name);
    printf("Generate a report about EC2 instances in the region specified by REGION associated with\n");
    printf("the account specified by CREDS_FILE and PROFILE.\n\n");
    printf("REGION defaults to 'us-west-2', PROFILE defaults to 'default', and CREDS_FILE\n");
    printf("defaults to '\$HOME/.aws/credentials'\n\n");
}

