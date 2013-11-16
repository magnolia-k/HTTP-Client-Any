#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

require_ok( 'HTTP::Client::Any' );

my $agent = HTTP::Client::Any->new;
my $res   = $agent->get( 'http://www.example.com' );

ok( $res->is_success );
like( $res->content, qr/Example Domain/ );

done_testing();
