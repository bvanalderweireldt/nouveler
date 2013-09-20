#! /usr/bin/env perl

BEGIN{
	use File::Basename;
	eval 'use lib "'.dirname(__FILE__).'"';
	eval 'chdir "'.dirname(__FILE__).'"';
}

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
my $numberOfDaysToScan = 1;my $collection;my $hot;my $cfg;my $commonMatch;my $minMatchSentenceTrigger; my $minMatchNewsTrigger;my $minLevenshteinPercMatch;##TODO CLEAN ALL THAT MESS....
###END GLOBAL V#####

my ($arg) = @ARGV;
if(defined $arg){
	if( ( $numberOfDaysToScan ) = ( $arg =~ m/^-days=(\d{1,2})$/) ){}
	else{die('Wrong args...');}
}

###MAIN###
$cfg = new Config::Simple('app.conf'); ###Load conf
connectDb(\$collection, \$hot);###Connect DB

$commonMatch = $cfg->param('macthCommonWord');###LOAD COMMON MATCH, DON'T WANT TO BE LOAD FROM CONF FOR EVERY COMPARAISON
$minMatchSentenceTrigger = $cfg->param('minMatchSentenceTrigger');###LOAD COMMON MATCH, DON'T WANT TO BE LOAD FROM CONF FOR EVERY COMPARAISON
$minMatchNewsTrigger = $cfg->param('minMatchNewsTrigger');###LOAD COMMON MATCH, DON'T WANT TO BE LOAD FROM CONF FOR EVERY COMPARAISON
$minLevenshteinPercMatch = $cfg->param('minLevenshteinPercMatch');###LOAD COMMON MATCH, DON'T WANT TO BE LOAD FROM CONF FOR EVERY COMPARAISON

analyse($numberOfDaysToScan);
###END MAIN###

sub analyse{
	my ($numberOfDaysToScan) = @_;

	my $dayFrom;my $dayTo;

	for (my $var = 0; $var < $numberOfDaysToScan; $var++) {
		buildDate($var, \$dayFrom, \$dayTo);

		my $allLastData = $collection->find({ issued => {'$gt' => $dayFrom, '$lt' => $dayTo } });
		processData($allLastData, $dayFrom, $dayTo);	
	}
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

sub processData{
	my ($lastData, $dayFrom, $dayTo ) = @_;
	$minMatchNewsTrigger = 5 if ! defined $minMatchNewsTrigger;

	my @objects = $lastData->all; #Our array of news
	my @hotTmp;
	my $element;

	while ( @objects ){
		$element = pop @objects;
		@hotTmp = ();
		lookForSimilarSentence( \$element, \@objects, \@hotTmp );

		if(scalar( @hotTmp ) >= $minMatchNewsTrigger){
			#Here we need to select only one title to save, the first in array is the one that have been compared to every other title,
			#it's the link between all this titles.
			next if defined $hot->find_one( { title => ${$hotTmp[0]}, date => { '$gt' => $dayFrom, '$lt' => $dayTo } } );
		    $hot->insert({ 	title => ${$hotTmp[0]}, 
		    				date => $dayFrom,
		    				link => ${$hotTmp[1]} });
		}
	}
}

sub lookForSimilarSentence{
	my ($sentence, $sentences, $result) = @_;

	for (my $i = 0; $i < @{ $sentences }.length; $i++) {
		next unless defined @{ $sentences }[$i];
		if( compareTwoSentences ( \${ $sentence }->{title}, \@{ $sentences }[$i]->{title} ) ) {
			push ( @{ $result }, ( \@{ $sentences }[$i]->{title}, \@{ $sentences }[$i]->{link} ) );
			my $sentenceCopy = @{ $sentences }[$i];
			undef @{ $sentences }[$i];
			lookForSimilarSentence( \$sentenceCopy, $sentences, $result );
		}
	}
}

#Compare two strings, return percentage base difference, 0 mean no difference
sub compareTwoWords{
	my $distance = distance ${@_[0]}, ${@_[1]}; #Compute the Levenshtein distance
	my $aLike = int((length(${@_[0]}) + length(${@_[1]})) / 2); #Average size of both strings
	return 0 if $distance == 0;
	return ( ( $distance * 100 ) / $aLike );
}

#Compare two strings, return percentage base difference, 0 mean no difference
sub compareTwoSentences{
	$minMatchSentenceTrigger = 4 if ! defined $minMatchSentenceTrigger;
	$minLevenshteinPercMatch = 30 if ! defined $minLevenshteinPercMatch ;
	foreach(@_){$$_ = lc $$_;}; #Force both string to lower case
	my @sentence2 = split( ' ', ${@_[0]} );
	my $match=0;
	foreach my $wordSentence1 (split( ' ', ${@_[1]})){
		next unless isASignificativeWord(\$wordSentence1);
		foreach my $wordSentence2 (@sentence2){
			if( compareTwoWords( \$wordSentence1, \$wordSentence2 ) < $minLevenshteinPercMatch ) {
				$match++;
			}
			last if $match > $minMatchSentenceTrigger;
		}
	}
	return ( $match > $minMatchSentenceTrigger ) ? 1 : 0;
}

#Return false if the word is a special character, or match any common English word
sub isASignificativeWord{
	return 0 if ${$_[0]} =~ m/\W/gi; #We don't want to match non word character, and we need to clean the string before inject it into a regex
	return 0 if ${$_[0]} =~ m/^($commonMatch|\W+|\s+)$/i; #We don't want to math common word
	return 1;
}