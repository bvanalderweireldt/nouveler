#! /usr/bin/perl

use strict;

use XML::Feed;
use XML::Simple;
use LWP::UserAgent;
use MongoDB::MongoClient;
use Config::Simple;
use TryCatch;
use Data::Dumper; #TODO DELETE ONLY USE FOR TESTING PURPOSE

###GLOBAL VARIABLE###
###USE WITH CAUTIOUS#
my $cfg;my $collection;my $ua;my $data;
###END GLOBAL V#####

###MAIN###
$cfg = new Config::Simple('app.conf');
connectDb(\$collection);
$ua = LWP::UserAgent->new;
$ua->timeout($cfg->param('timeout'));
$data = loadFlux();

foreach my $flux (@{ $data->{flux} }){
	try{
		processFlux($flux) if $flux->{active} == '1';
	}
	catch{
		print "Something went wrong while parsing : ".$flux->{desc};
	}
}
###END MAIN###

sub loadFlux{
	my $xml = new XML::Simple;
	return $xml->XMLin($cfg->param('fluxFile'));
}

sub connectDb{
	my ($collection) = @_;
	my $client = MongoDB::MongoClient->new(	host => $cfg->param('host'), port => $cfg->param('port'), 
											username => $cfg->param('username'), password => $cfg->param('password'), 
											db_name => $cfg->param('dbName'));

	my $database = $client->get_database($cfg->param('dbName'));
	${$collection} = $database->get_collection( $cfg->param('dbCollectionData') );
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