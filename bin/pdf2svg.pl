#!/usr/bin/perl

use warnings;
use strict;

use v5.10.0;

use Getopt::Long;
use Cwd;
use Cairo;
use Poppler;

$| = 1; # enable AUTOFLUSH mode
my @pages;

GetOptions("page:i{,}" => \@pages);

@pages = qw(1) unless (@pages);

my @pdfs = @ARGV;

for my $pdf (@pdfs) {
    die "[err] Did not find file: $pdf\n" unless (-e $pdf);
    my $pdf_uri = construct_file_uri($pdf);
    for my $page (@pages) {
        print "Converting $pdf -- page : $page ...";
        my $svg = create_svg_filename($pdf, $page);

        # setup poppler
        my $poppler = Poppler::Document->new_from_file($pdf_uri);
        my $page = $poppler->get_page( $page - 1 );
        my $dimension = $page->get_size;

        # setup Cairo
        my $surface = Cairo::SvgSurface->create(
                $svg,
                $dimension->get_width,
                $dimension->get_height
        );
        my $cr = Cairo::Context->create($surface);

        # perform the actual re-rendering
        $page->render_to_cairo($cr);
        $cr->show_page;
        print ' done', "\n";
    }
}

exit(0);

sub construct_file_uri {
    my $file = shift;
    my $path = Cwd::abs_path($file);
    $path = 'file://' . $path;
    return $path;
}

sub create_svg_filename {
    my ($pdf, $page) = @_;
    my $svg = $pdf;

    if (@pages == 1 && $pages[0] == 1) {
        $svg =~ s/pdf/svg/g;
        return $svg;
    }

    $svg =~ s/(pdf)$/$page\.svg/g;
    return $svg;
}
