#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

require HTTP::Client::Any;

if ( ! HTTP::Client::Any->available( client => 'HTTP::Tiny' ) ) {
    plan skip_all => "HTTP::Tiny are required";
}

my $agent = HTTP::Client::Any->new( client => 'HTTP::Tiny' );
my $res   = $agent->get( 'http://www.example.com' );

like( $res->content, qr/Example Domain/ ) if $res->is_success;

if ( HTTP::Client::Any->available( client => 'HTTP::Tiny', https => 1 ) ) {
    my $https_agent = HTTP::Client::Any->new( client => 'HTTP::Tiny', https => 1 );

    my $https_res   = $https_agent->get( 'https://github.com' );

    like( $https_res->content, qr/GitHub/ ) if $https_res->is_success;
}

my $filename = '01mailrc.txt.gz';
my $uri = 'http://www.cpan.org/CPAN/authors/' . $filename;
my $dir = File::Temp->newdir;

my $path = File::Spec->catfile( $dir, $filename );

my $mirror = HTTP::Client::Any->new( client => 'HTTP::Tiny' );
my $mirror_res = $mirror->mirror( $uri, $filename );

ok( -e $filename );

my $mirror_retry = $mirror->mirror( $uri, $filename );

is( $mirror_retry->status_code, '304' );




done_testing();
