#!/usr/bin/perl
use strict;

use Config::Simple;
use MongoDB::MongoClient;
use DateTime qw();
use Data::Dumper;##TODO DON'T NEED IN PRODUCTION
use Log::Log4perl;
use CGI;
use JSON;

my $cfg = new Config::Simple('/home/nouveler/app.conf') or die ('Can\'t load conf!!!');

Log::Log4perl::init($cfg->param('log4perl'));

my $logger = Log::Log4perl->get_logger('nouveler');

my $client = MongoDB::MongoClient->new(	host => $cfg->param('host'), port => $cfg->param('port'), 
										username => $cfg->param('username'), password => $cfg->param('password'), 
										db_name => $cfg->param('dbName'));

my $database = $client->get_database($cfg->param('dbName'));
my $collection = $database->get_collection( $cfg->param('dbCollectionData') );
my $hot = $database->get_collection( $cfg->param('dbCollectionHot') );

my $q = CGI->new;
my $days = 1;
my $dateArg  = $q->param('date');
my $dateFrom;
my $dateTo;

if ( defined $dateArg ){
	$dateFrom = DateTime->from_epoch( epoch => $dateArg );
}
else{
	$dateFrom =  DateTime->now;
}
$dateTo = DateTime->from_epoch( epoch => $dateFrom->epoch );
$dateFrom->set_hour(00);
$dateFrom->set_minute(00);
$dateTo->set_hour(23);
$dateTo->set_minute(59);

$logger->debug($dateFrom);
$logger->debug($dateTo);

my $allData = $collection->find( { issued => {'$gt' => $dateFrom, '$lt' => $dateTo }  } )->fields({ 'title' => 1, 'link' => 1, '_id' => 0});
my $allHot = $hot->find( { date => {'$gt' => $dateFrom, '$lt' => $dateTo } } )->fields({ 'title' => 1, 'link' => 1, '_id' => 0});

print "Content-type:application/json\n\n";

my %json = ( 'date' => $dateFrom->epoch );

my @data = ();

while ( my $row = $allData->next ){
	push (@data, $row);
}
$json{data} = \@data;

my @hot = ();
while ( my $row = $allHot->next ){
	push (@hot, $row);
}
$json{hot} = \@hot;


print to_json( \%json, { allow_nonref => 1, pretty => 0} );
