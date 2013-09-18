#! /usr/bin/env perl

use strict;

use DateTime qw();
use MongoDB::MongoClient;
use XML::Simple;
use Text::Levenshtein qw(distance);
use Config::Simple;
use TryCatch;

use Data::Dumper; #TODO DELETE ONLY USE FOR TESTING PURPOSE

###GLOBAL VARIABLE###
###USE WITH CAUTIOUS#
my $numberOfDaysToScan = 1;my $collection;my $hot;my $cfg;my $commonMatch;##TODO CLEAN ALL THAT MESS....
###END GLOBAL V#####

my ($arg) = @ARGV;
if(defined $arg){
	if( ( $numberOfDaysToScan ) = ( $arg =~ m/^-days=(\d{1,2})$/) ){}
	else{die('Wrong args...');}
}

###MAIN###
$cfg = new Config::Simple('app.conf'); ###Load conf
connectDb(\$collection, \$hot);###Connect DB
loadFlux();###Load every RSS flux
$commonMatch = $cfg->param('macthCommonWord');###LOAD COMMON MATCH, DON'T WANT TO BE LOAD FROM CONF FOR EVERY COMPARAISON
analyse($numberOfDaysToScan);
###END MAIN###

sub analyse{
	my ($numberOfDaysToScan) = @_;

	my $dayFrom;my $dayTo;

	for (my $var = 0; $var < $numberOfDaysToScan; $var++) {
		buildDate($var, \$dayFrom, \$dayTo);

		my $data = loadFlux();
		foreach my $cat (@{ $data->{category}->{category} }){
			processCat($cat, $dayFrom, $dayTo);
		}
		my $allLastData = $collection->find({ issued => {'$gt' => $dayFrom, '$lt' => $dayTo } });
		processData($allLastData, $cfg->param('superCat'), $cfg->param('minMatchAllTrigger'), $dayFrom);	
	}
}

sub loadFlux{
	my $xml = new XML::Simple;
	return $xml->XMLin($cfg->param('fluxFile'));
}

sub connectDb{
	my ($collection, $hot) = @_;
	my $client = MongoDB::MongoClient->new(	host => $cfg->param('host'), port => $cfg->param('port'), 
											username => $cfg->param('username'), password => $cfg->param('password'), 
											db_name => $cfg->param('dbName'));

	my $database = $client->get_database($cfg->param('dbName'));
	${$collection} = $database->get_collection( $cfg->param('dbCollectionData') );
	${$hot} = $database->get_collection( $cfg->param('dbCollectionHot') );
}

sub buildDate{
	my($numberOfDaysToScan, $dayFrom, $dayTo) = @_;

	${$dayFrom} = DateTime->now->subtract( days => $numberOfDaysToScan);
	${$dayTo} = DateTime->from_epoch( epoch => ${$dayFrom}->epoch );

	${$dayFrom}->set_hour(00);
	${$dayFrom}->set_minute(01);
	${$dayTo}->set_hour(23);
	${$dayTo}->set_minute(59);

}

sub processCat{
	my ($cat, $dayFrom, $dayTo) = @_ ;
	my $lastData = $collection->find({ issued => {'$gt' => $dayFrom, '$lt' => $dayTo }, category => $cat });
	processData( $lastData, $cat, $cfg->param('minMatchCatTrigger'), $dayFrom );
}

sub processData{
	my ($lastData, $cat, $matchMin, $dayFrom ) = @_;
	$matchMin = 2 unless defined $matchMin;

	my @objects = $lastData->all;

	while (scalar(@objects) > 0){
		my $element = pop @objects;
		my @hotTmp = ();
		foreach my $index (0 .. $#objects) {
			if(asAtLeasXCommonWords($element->{title}, $objects[$index]->{title})){
				if(scalar(compare( $element->{title}, $objects[$index]->{title} ) < $cfg->param('minLevenshteinPercMatch') ) ){
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
		if(scalar(@hotTmp) >= $matchMin){
			#Here we need to select only one title to save, the first in array is the one that have been compared to every other title,
			#it's the link between all this titles.
			my $title = shift ( @hotTmp );
			next if defined $hot->find_one({ title => $title, category => $cat });
		    $hot->insert({ 	category => $cat, 
									title => $title,
									date => $dayFrom });
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
		next if $word =~ m/\W/gi; #We don't want to match non word character, and we need to clean the string before inject it into a regex
		next if $word =~ m/^($commonMatch|\W+|\s+)$/i; #We don't want to math common word
		try{
			if($_[1] =~ m/$word/g){
				$match++;
				last if $match == $X;
			}			
		}
		catch{
			print "Invalid regex for : ".$word;
			next;
		}
	}
	return $match == $X ? 1 : 0;
}
