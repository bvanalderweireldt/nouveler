#! /usr/bin/perl

use strict;

use XML::Feed;
use XML::Simple;
use Data::Dumper;
use MongoDB::MongoClient;

my $client = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
my $database = $client->get_database( 'nouveler' );
my $collection = $database->get_collection( 'data' );

my $xml = new XML::Simple;
my $data = $xml->XMLin("conf.xml");

foreach my $flux (@{ $data->{flux} }){
	processFlux($flux) if $flux->{active} == '1';
}

#Process every flux, download and then save it into DB
sub processFlux{

	my $flux = shift(@_);

	my $feed = XML::Feed->parse(URI->new($flux->{address}))
	    or die XML::Feed->errstr;

	for my $entry ($feed->entries) {

			my $cleanTitle = $entry->title;
			$cleanTitle =~ s/^(AUDIO|VIDEO)\s?:\s?//g; # We clean title name to avoid having VIDEO: .... or AUDIO: .....

			my $data = $collection->find_one({ title => $cleanTitle }); #If the title already exist, we consider it has been already saved
			next if defined $data;

			my $cleanContent = $entry->content->body;
			$cleanContent =~ s/<[^>]+>//gi; # We delete any tag from the content

		    my $id = $collection->insert({ 	category => $flux->{category}, 
		    								title => $cleanTitle,
		    								link => $entry->link,
		    								issued => $entry->issued,
		    								content => $cleanContent });
	}
}

