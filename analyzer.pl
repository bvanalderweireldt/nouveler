#! /usr/bin/perl

use strict;

use DateTime qw();
use MongoDB::MongoClient;
use utf8;

use Data::Dumper;

my $client = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
my $database = $client->get_database( 'nouveler' );
my $collection = $database->get_collection( 'data' );

my $lastData = $collection->find({ issued => {'$gt' => DateTime->now->subtract(days => 1)} });
my %hot;
while (my $cursor = $lastData->next){

	my @values = split(' ', $cursor->{title});
	
	foreach my $val (@values) {
		next if $val =~ m/^(\d+\$|\^|%|&|\*|\(|\)|\||the|be|to|of|and|a|in|that|have|I|it|for|not|on|with|he|as|you|do|at|this|but|his|by|from|they|we|say|her|she|or|an|will|my|one|all|would|there|their|so|up|out|if|about|who|get|which|go|me|when|make|can|like|time|no|just|him|know|people|into|year|your|good|some|could|them|see|other|than|then|now|look|only|come|its|over|think|back|after|use|two|how|our|work|first|well|way|even|new|want|because|any|these|give|day|most|us|why|more)$/i;
		$val = lc($val);
		if(exists($hot{$val})){
			$hot{$val}++;
		}
		else{
			$hot{$val} = 1;
		}
	}
	while( $cursor->{title} =~ /\s((\s?[A-Z][a-zA-Z]+){1,4})\s/g){
		next if $1 =~ m/the|has|is|why|buy|world|new/i;
		#print "$1"."\n";
	}
}
foreach my $key (%hot)
{
  print( $key."\n" ) if $hot{$key} > 5;
}
sort { $hot{$a} <=> $hot{$b} } keys %hot;
#print Dumper(%hot);
