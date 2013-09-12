#! /usr/bin/perl

use strict;

use DateTime qw();
use MongoDB::MongoClient;
use XML::Simple;
use Data::Dumper;
use Text::Levenshtein qw(distance);

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

	my $lastData = $collection->find({ issued => {'$gt' => DateTime->now->subtract(days => 2)}, category => $cat });
	my @hot;

	my @objects = $lastData->all;
	while (scalar(@objects) > 0){
		my $element = pop @objects;
		my @hotTmp;
		foreach my $index (0 .. $#objects) {
			if(asAtLeasXCommonWords($element->{title}, $objects[$index]->{title})){
				if(scalar(compare( $element->{title}, $objects[$index]->{title} ) < 75 ) ){
					my $tmpVar = $objects[$index]->{title};
					push @hotTmp, $tmpVar;
					delete $objects[$index];
					@objects = grep defined, @objects;
				}
			}
		}
		@hotTmp = grep defined, @hotTmp;

		if(scalar(@hotTmp) > 0){
			push @hotTmp, $element->{title};
			push @hot, @hotTmp;
		}

		if(scalar(@hotTmp) > 2){
			print Dumper(@hotTmp)."\n----------------\n";
			#############################################
			############## TODO #########################
			##SAVE result to db, must select one entry###
		}
	}
}

#Compare two strings, return percentage base difference, 0 mean no difference
sub compare{
	my $distance = distance $_[0], $_[1];
	my $aLike = int((length($_[0]) + length($_[1])) / 2);
	return 0 if $distance == 0;
	return ( ( $distance * 100 ) / $aLike );
}

#Return true if the two given words have at least two common words
sub asAtLeasXCommonWords{
	my $X = 2;
	my $match = 0;
	my @words = split( ' ', $_[0] );

	foreach my $word (@words){
		if($_[1] =~ m/$word/g){
			$match++;
			last if $match == $X;
		}
	}
	return $match == $X ? 1 : 0;
}
