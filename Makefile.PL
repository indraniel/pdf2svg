use strict;
use warnings;
use v5.10.0;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'pdf2svg',
    AUTHOR              => 'Indraniel Das <indraniel@gmail.com>',
    VERSION_FROM        => 'bin/pdf2svg.pl',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    ABSTRACT_FROM       => 'bin/pdf2svg.pl',
    EXE_FILES            => ['bin/pdf2svg.pl']
    PREREQ_PM => {
        'Test::More' => 0,
        'Cairo'      => 1.060,
        'Poppler'    => 0.02
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'pdf2svg-*' },
);
