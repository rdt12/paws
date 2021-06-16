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

my($instanceResult)              = $ec2->DescribeInstances();
my($vpcsResult)                  = $ec2->DescribeVpcs();
my($subnetsResult)               = $ec2->DescribeSubnets();
my($internetGatewaysResult)      = $ec2->DescribeInternetGateways();
my($natGatewaysResult)           = $ec2->DescribeNatGateways();
my($networkInterfacesResult)     = $ec2->DescribeNetworkInterfaces();
my($routeTablesResult)           = $ec2->DescribeRouteTables();
my($securityGroupsResult)        = $ec2->DescribeSecurityGroups();
my($vpcEndpointsResult)          = $ec2->DescribeVpcEndpoints();
my($vpcPeeringConnectionsResult) = $ec2->DescribeVpcPeeringConnections();

#my($reservations) = $result->{'Reservations'};

#print(Dumper($result));
my(@instances)             = getInstances($instanceResult);
my(@vpcs)                  = getSimple('Vpcs', $vpcsResult);
my(@subnets)               = getSimple('Subnets', $subnetsResult);
my(@internetGateways)      = getSimple('InternetGateways', $internetGatewaysResult);
my(@natGateways)           = getSimple('NatGateways', $natGatewaysResult);
my(@networkInterfaces)     = getSimple('NetworkInterfaces', $networkInterfacesResult);
my(@routeTables)           = getSimple('RouteTables', $routeTablesResult);
my(@securityGroups)        = getSimple('SecurityGroups', $securityGroupsResult);
my(@vpcEndpoints)          = getSimple('VpcEndpoints', $vpcEndpointsResult);
my(@vpcPeeringConnections) = getSimple('VpcPeeringConnections', $vpcPeeringConnectionsResult);
 
##
## Construct a map of VpcId to VPC name
##
my($vpc);
my($name, $cidr);
my(@tags);
my($tag);
my($vpcName);
my($vpcCidrBlock);
for $vpc (@vpcs) {
    $name = getName($vpc->{'Tags'});
    $vpcName->{$vpc->{'VpcId'}} = $name;
    $vpcCidrBlock->{$vpc->{'VpcId'}} = $vpc->{'CidrBlock'};
}

##
## Associate Instances with VPCs
##
my($inst);
my($vpcInstances);
for $inst (@instances) {
    $vpc = $inst->{'VpcId'};
    if (!defined($vpcInstances->{$vpc})) {
	$vpcInstances->{$vpc} = [];
    }
    push(@{$vpcInstances->{$vpc}}, $inst);
}

##
## Associate subnets with VPCs
##
my($s);
my($vpcSubnets);
for $s (@subnets) {
    $vpc = $s->{'VpcId'};
    if (!defined($vpcSubnets->{$vpc})) {
	$vpcSubnets->{$vpc} = [];
    }
    push(@{$vpcSubnets->{$vpc}}, $s);
}

##
## Associate Internet Gateways with VPCs
##
my($g, $a);
my(@attachments);
my($vpcInternetGateways);
for $g (@internetGateways) {
    @attachments = @{$g->{'Attachments'}};
    for $a (@attachments) {
	$vpc = $a->{'VpcId'};
	if (!defined($vpcInternetGateways->{$vpc})) {
	    $vpcInternetGateways->{$vpc} = [];
	}
	push(@{$vpcInternetGateways->{$vpc}}, $g);
    }
}

##
## Associate Nat Gateways with VPCs
##
my($vpcNatGateways);
for $g (@natGateways) {
    $vpc = $g->{'VpcId'};
    if (!defined($vpcNatGateways->{$vpc})) {
	$vpcNatGateways->{$vpc} = [];
    }
    push(@{$vpcNatGateways->{$vpc}}, $g);
}

##
## Associate Network Interfaces with VPCs.
##
my($vpcNetworkInterfaces);
my($n);
for $n (@networkInterfaces) {
    $vpc = $n->{'VpcId'};
    if (!defined($vpcNetworkInterfaces->{$vpc})) {
	$vpcNetworkInterfaces->{$vpc} = [];
    }
    push(@{$vpcNetworkInterfaces->{$vpc}}, $n);
}

##
## Associate Route Tables with VPCs.
##
my($vpcRouteTables);
my($r);
for $r (@routeTables) {
    $vpc = $r->{'VpcId'};
    if (!defined($vpcRouteTables->{$vpc})) {
	$vpcRouteTables->{$vpc} = [];
    }
    push(@{$vpcRouteTables->{$vpc}}, $r);
}

##
## Associate Security Groups with VPCs.
##
my($vpcSecurityGroups);
for $s (@securityGroups) {
    $vpc = $s->{'VpcId'};
    if (!defined($vpcSecurityGroups->{$vpc})) {
	$vpcSecurityGroups->{$vpc} = [];
    }
    push(@{$vpcSecurityGroups->{$vpc}}, $s);
}

##
## Associate VPC Endpoints with VPCs.
##
my($vpcVpcEndpoints);
my($v);
for $v (@vpcEndpoints) {
    $vpc = $v->{'VpcId'};
    if (!defined($vpcVpcEndpoints->{$vpc})) {
	$vpcVpcEndpoints->{$vpc} = [];
    }
    push(@{$vpcVpcEndpoints->{$vpc}}, $v);
}

##
## Associate VPC Peering Connection Accepters and Requesters with VPCs.
##
my($vpcVpcPeeringConnectionRequesters);
my($vpcVpcPeeringConnectionAccepters);
my($reqVpc, $accVpc);
for $v (@vpcPeeringConnections) {
    $reqVpc = $v->{'RequesterVpcInfo'}->{'VpcId'};
    $accVpc = $v->{'AccepterVpcInfo'}->{'VpcId'};
    if (!defined($vpcVpcPeeringConnectionRequesters->{$reqVpc})) {
	$vpcVpcPeeringConnectionRequesters->{$reqVpc} = [];
    }
    push(@{$vpcVpcPeeringConnectionRequesters->{$reqVpc}}, $v);

    if (!defined($vpcVpcPeeringConnectionAccepters->{$accVpc})) {
	$vpcVpcPeeringConnectionAccepters->{$accVpc} = [];
    }
    push(@{$vpcVpcPeeringConnectionAccepters->{$accVpc}}, $v);
	}

###
### Print report.
###
my($vpcId);
for $vpc (@vpcs) {
    $vpcId = $vpc->{'VpcId'};
    printf("VPC: %s Name: %s CIDR: %s\n", $vpcId, $vpcName->{$vpcId}, $vpcCidrBlock->{$vpcId});
    for $inst (@{$vpcInstances->{$vpcId}}) {
	printf("   Instance: %s Name: %s PrivateIp: %s\n", $inst->{'InstanceId'}, getName($inst->{'Tags'}), $inst->{'PrivateIpAddress'});
    }
    for $s (@{$vpcSubnets->{$vpcId}}) {
	printf("   Subnet: %s; CIDR: %s Name: %s\n", $s->{'SubnetId'}, $s->{'CidrBlock'}, getName($s->{'Tags'}));
    }
    for $g (@{$vpcInternetGateways->{$vpcId}}) {
	printf("   InternetGW: %s Name: %s\n", $g->{'InternetGatewayId'}, getName($g->{'Tags'}));
    }
    for $g (@{$vpcNatGateways->{$vpcId}}) {
	printf("   NatGW: %s Name: %s\n", $g->{'NatGatewayId'}, getName($g->{'Tags'}));
    }
    for $n (@{$vpcNetworkInterfaces->{$vpcId}}) {
	printf("   NetworkInterface: %s PrivateIp: %s\n", $n->{'NetworkInterfaceId'}, $n->{'PrivateIpAddress'});
    }
    for $r (@{$vpcRouteTables->{$vpcId}}) {
	printf("   RouteTable: %s Name: %s\n", $r->{'RouteTableId'}, getName($r->{'Tags'}));
    }
    for $s (@{$vpcSecurityGroups->{$vpcId}}) {
	printf("   Group: %s GroupName: %s\n", $s->{'GroupId'}, $s->{'GroupName'});
    }
    for $v (@{$vpcVpcEndpoints->{$vpcId}}) {
	printf("   VpcEndpoint: %s Name: %s\n", $v->{'VpcEndpointId'}, getName($v->{'Tags'}));
    }
    for $v (@{$vpcVpcPeeringConnectionRequesters->{$vpcId}}) {
	printf("   VpcPeerRequester: %s\n", $v->{'VpcPeeringConnectionId'});
    }
    for $v (@{$vpcVpcPeeringConnectionAccepters->{$vpcId}}) {
	printf("   VpcPeerAccepter: %s\n",  $v->{'VpcPeeringConnectionId'});
    }
    printf("\n\n");
}

exit(0);
###
###
###
sub getName {
    my($tags) = shift;
    my($tag);
    my($name) = "UNKNOWN";
    for $tag (@{$tags}) {
	if ($tag->{'Key'} eq 'Name') {
	    $name = $tag->{'Value'};
	}
    }
    return $name;
}

sub getSimple {
    my($s) = shift;
    my($r) = shift;
    return @{$r->{$s}};    
}

sub getInstances {
    my($result) = shift;
    my(@instances) = ();
    my($reservation);
    for $reservation (@{$result->{'Reservations'}}) {
	push(@instances, @{$reservation->{'Instances'}});
    }
    return @instances;
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
    printf("Generate a report about VPCs in the region specified by REGION associated with\n");
    printf("the account specified by CREDS_FILE and PROFILE. It includes a listing of\n");
    printf("various EC2 objects associated with the VPC.\n\n");
    printf("REGION defaults to 'us-west-2', PROFILE defaults to 'default', and CREDS_FILE\n");
    printf("defaults to '\$HOME/.aws/credentials'\n\n");
}

