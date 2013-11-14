use 5.006;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'HTTP-Client-Any',
    AUTHOR           => q{magnolia <magnolia.k@me.com>},
    VERSION_FROM     => 'lib/HTTP/Client/Any.pm',
    ABSTRACT_FROM    => 'lib/HTTP/Client/Any.pm',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => 5.010001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.56,
    },

    PREREQ_PM		=> {
    },

    TEST_REQUIRES   => {
        'Test::More'        =>  '0.98',
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HTTP-Client-Any-*' },
);
