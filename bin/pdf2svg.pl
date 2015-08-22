#!/usr/bin/perl

use warnings;
use strict;

use v5.10.0;

use Getopt::Long();
use Pod::Usage();
use Cwd();
use Cairo();
use Poppler();
use URI::Escape();

$| = 1; # enable AUTOFLUSH mode
my (@pages, $opt_all, $opt_help);

Getopt::Long::GetOptions(
    "pages:i{,}" => \@pages,
    all         => \$opt_all,
    help        => \$opt_help
);

pod2usage(
    -exitval => 0,
    -verbose => 2,
) if $opt_help;

@pages = qw(1) unless (@pages && not defined $opt_all);

my @pdfs = @ARGV;

for my $pdf (@pdfs) {
    die "[err] Did not find file: $pdf\n" unless (-e $pdf);
    my $pdf_uri = construct_file_uri($pdf);

    my $poppler = Poppler::Document->new_from_file($pdf_uri);
    if ($opt_all) {
        my $total_pages = $poppler->get_n_pages;
        @pages = (1 .. $total_pages);
    }

    for my $page (@pages) {
        print "Converting $pdf -- page : $page ...";
        my $svg = create_svg_filename($pdf, $page);

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
    my $path = shift;
    #apparently, neither URL not URI modules can
    #convert URI<-local path in Cygwin. Blah! They're useless.
    $path = File::Spec->rel2abs($path);
    my ($drive,$dirs,$file)=File::Spec->splitpath($path);
    # in Win32, `C:' or `\\server\share' goes into $drive,
    # in Cygwin, both go into $dirs. Perl, quirky as ever.
    my @dirs=File::Spec->splitdir($dirs);
    my @drive=File::Spec->splitdir($drive);
    my $drive_is_unc = $#drive>2;
    my $dirs_is_unc = !$drive_is_unc && $#dirs>2 
        && $dirs[0]eq"" && $dirs[1]eq"";

    #Spec: RFC1738, 3.10; RFC3986, 2.5 (UTF-8),
    #https://en.wikipedia.org/wiki/File_URI_scheme#Windows_2 (drive letter)
    my $url = "file://";
    if ($drive_is_unc) {
        #well, not _entirely_ useless
        @drive=map(URI::Escape::uri_escape_utf8($_),@drive);
    }
    $url.= $drive_is_unc ? join('/',@drive[2,-1]) :
        ($drive?"/$drive":"");
    {
        #not quoting the `:' after a drive letter
        #_is_ Windows-specific
        my $i = (($^O eq "cygwin") && $#dirs>0 &&
            $dirs[0]=~/^[A-Za-z]:$/) ? 1:0;
        foreach(@dirs[$i,-1])
            {$_ = URI::Escape::uri_escape_utf8($_);}
    }
    $url.= $dirs_is_unc ? join('/',@dirs[2,-1]) :
        "/".join('/',@dirs);
    #typically, there's a trailing slash in $dirs that's
    #transformed into a blank member
    $url.=($#dirs>0 && $dirs[-1]eq"")?$file:'/'.$file;
    return $url;
}

sub undef_($) {
        return defined($_[0])?$_[0]:"";
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

__END__

=head1 NAME

pdf2svg - convert pdf file(s) to svg file(s)

=head1 SYNOPSIS

pdf2svg [options] [pdf files ...]

 Options:
   -help            brief help message
   -all             convert all pages in respective pdf files
   -pages           specify list of pages in pdf file to convert

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-all>

Convert all pages in each respective pdf file specified on the command line.

=item B<-pages>

Specify a list of which pages to convert in the list of pdf files specified
on the command line.

=back

=head1 DESCRIPTION

B<pdf2svg> will process the given input pdf file(s) and convert the
appropriate pages into svg file(s).

If no pages are specified via the I<-all> or I<-pages> options the first
page of each pdf file will be set for conversion into a SVG formatted file.

=head1 EXAMPLES

=head1 AUTHOR

Indraniel Das <indraniel@gmail.com>

=head1 SEE ALSO

Poppler, Cairo

=head1 LICENSE AND COPYRIGHT

=cut
