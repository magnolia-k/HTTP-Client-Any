#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

require_ok( 'HTTP::Client::Any' );

my $agent = HTTP::Client::Any->new;
my $res   = $agent->get( 'http://www.example.com' );

ok( $res->is_success );
like( $res->content, qr/Example Domain/ );

diag( HTTP::Client::Any->available );
diag( HTTP::Client::Any->available( https => 1 ) );

done_testing();
