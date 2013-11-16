#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

require HTTP::Client::Any;

if ( ! HTTP::Client::Any->available( client => 'Furl' ) ) {
    plan skip_all => "Furl are required";
}

my $agent = HTTP::Client::Any->new( client => 'Furl' );
my $res   = $agent->get( 'http://www.example.com' );

like( $res->content, qr/Example Domain/ ) if $res->is_success;

if ( HTTP::Client::Any->available( client => 'Furl', https => 1 ) ) {
    my $https_agent = HTTP::Client::Any->new( client => 'Furl', https => 1 );

    my $https_res   = $https_agent->get( 'https://github.com' );

    like( $https_res->content, qr/GitHub/ ) if $https_res->is_success;
}

done_testing();
