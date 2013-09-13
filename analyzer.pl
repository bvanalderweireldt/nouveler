#! /usr/bin/env perl

use strict;

use DateTime qw();
use MongoDB::MongoClient;
use XML::Simple;
use Text::Levenshtein qw(distance);
use Config::Simple;

use Data::Dumper; #TODO DELETE ONLY USE FOR TESTING PURPOSE

my $cfg = new Config::Simple('app.ini');

my $client = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
my $database = $client->get_database( $cfg->param('dbName') );
my $collection = $database->get_collection( $cfg->param('dbCollectionData') );
my $hot = $database->get_collection( $cfg->param('dbCollectionHot') );

my $xml = new XML::Simple;
my $data = $xml->XMLin($cfg->param('categoryFile'));

my $commonMatch = $cfg->param('macthCommonWord');
foreach my $cat (@{ $data->{category} }){
	processCat($cat);
}

my $allLastData = $collection->find({ issued => {'$gt' => DateTime->now->subtract(days => 1)} });

processData($allLastData, $cfg->param('superCat'), $cfg->param('minMatchAllTrigger'));

sub processCat{
	my $cat = shift( @_ );

	my $lastData = $collection->find({ issued => {'$gt' => DateTime->now->subtract(days => 1)}, category => $cat });

	processData( $lastData, $cat, $cfg->param('minMatchCatTrigger') );
}

sub processData{
	my $lastData = shift( @_ );
	my $cat = shift( @_ );
	my $matchMin =shift( @_ );
	$matchMin = 2 unless defined $matchMin;

	my @objects = $lastData->all;

	while (scalar(@objects) > 0){
		my $element = pop @objects;
		my @hotTmp = ();
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
		}
		if(scalar(@hotTmp) > $matchMin){
			#Here we need to select only one title to save, the first in array is the one that have been compared to every other title,
			#it's the link between all this titles.
			my $title = shift ( @hotTmp );
			next if defined $hot->find_one({ title => $title, category => $cat });
		    $hot->insert({ 	category => $cat, 
									title => $title,
									date => DateTime->now() });
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
		next if $word =~ m/^($commonMatch)$/i;
		if($_[1] =~ m/$word/g){
			$match++;
			last if $match == $X;
		}
	}
	return $match == $X ? 1 : 0;
}
