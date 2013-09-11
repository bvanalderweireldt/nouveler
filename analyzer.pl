#! /usr/bin/perl

use strict;

use DateTime qw();
use MongoDB::MongoClient;
use XML::Simple;
use Data::Dumper;

my $client = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
my $database = $client->get_database( 'nouveler' );
my $collection = $database->get_collection( 'data' );

my $xml = new XML::Simple;
my $data = $xml->XMLin("category.xml");

foreach my $cat (@{ $data->{category} }){
	processCat($cat);
}

sub processCat{
	my $cat = shift( @_ );

	my $lastData = $collection->find({ issued => {'$gt' => DateTime->now->subtract(days => 1)}, category => $cat });
	my %hot;
	while (my $cursor = $lastData->next){

		my @values = split(' ', $cursor->{title});
		
		foreach my $val (@values) {
			next if $val =~ m/^(\d+|[a-z]-|\$|\^|%|&|\*|\(|\)|\||the|be|to|of|and|a|in|that|have|I|it|for|not|on|with|he|as|you|do|at|this|but|his|by|from|they|we|say|her|she|or|an|will|my|one|all|would|there|their|so|up|out|if|about|who|get|which|go|me|when|make|can|like|time|no|just|him|know|people|into|year|your|good|some|could|them|see|other|than|then|now|look|only|come|its|over|think|back|after|use|two|how|our|work|first|well|way|even|new|want|because|any|these|give|day|most|us|why|more|off|is|)$/i;
			$val = lc($val);
			if(exists($hot{$val})){
				push( @{$hot{$val}}, $cursor->{title} );
			}
			elsif(defined $val) {
				$hot{$val} = [$cursor->{title}];
			}
		}
	}
	foreach my $key (%hot)
	{
		if(defined $hot{$key} and scalar @{ $hot{$key} } > 7){

			#print $key;
			my @tmp = deleteDuplicate($hot{$key});
			#print Dumper(@tmp);
			#print "\n";
		}
	}
}

sub deleteDuplicate {
	my @array = shift(@_);
	my @outputArray = ();
	my %buffer = ();

	foreach my $key (@array){
		unless ($buffer{$key}) {
			push @outputArray, $key;
			$buffer{$key} = 1;
		}
	}
	return @outputArray;
}