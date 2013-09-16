#! /usr/bin/perl

use strict;

use XML::Feed;
use XML::Simple;
use LWP::UserAgent;
use MongoDB::MongoClient;
use Config::Simple;
use TryCatch;

use Data::Dumper; #TODO DELETE ONLY USE FOR TESTING PURPOSE

my $cfg = new Config::Simple('app.conf');

my $client = MongoDB::MongoClient->new(	host => $cfg->param('host'), port => $cfg->param('port'), 
										username => $cfg->param('username'), password => $cfg->param('password'), 
										db_name => $cfg->param('dbName'));
my $database = $client->get_database($cfg->param('dbName'));
my $collection = $database->get_collection( $cfg->param('dbCollectionData') );

my $ua = LWP::UserAgent->new;
$ua->timeout($cfg->param('timeout'));

my $xml = XML::Simple->new;
my $data = $xml->XMLin($cfg->param('fluxFile'));

foreach my $flux (@{ $data->{flux} }){
	try{
		processFlux($flux) if $flux->{active} == '1';
	}
	catch{
		print "Something went wrong while parsing : ".$flux->{desc};
	}
}

#Process every flux, download and then save it into DB
sub processFlux{

	my $flux = shift(@_);

	my $response = $ua->get($flux->{address});
	
	print "Can't get : ".$flux->{address} and return if $response->is_error;

	my $feed = XML::Feed->parse(\$response->content)
	    or die XML::Feed->errstr;

	for my $entry ($feed->entries) {

			my $cleanTitle = $entry->title;
			$cleanTitle =~ s/^(AUDIO|VIDEO|LIVE)\s?:\s?//gi; # We clean title name to avoid having VIDEO: .... or AUDIO: .....

			my $data = $collection->find_one({ title => $cleanTitle }); #If the title already exist, we consider it has been already saved
			next if defined $data;

			my $cleanContent = $entry->content->body;
			$cleanContent =~ s/<[^>]+>//gi; # We delete any tag from the content

		    $collection->insert({ 	category => $flux->{category}, 
		    						title => $cleanTitle,
		    						link => $entry->link,
    								issued => $entry->issued,
    								content => $cleanContent });
	}
}