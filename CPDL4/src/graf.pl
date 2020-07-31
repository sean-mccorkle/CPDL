# File:         graf.pl
# Language:     perl
# Authors:      Sean R. McCorkle, Kimberly M. Mayer, John Shanklin
# Description:  low-level (Postscript-generating) graphical routines for CPDL
#
#
# Routines:
#
#  preamble( $title, $progname ) - postscript preamble
#  page_preamble( $page_num )    - per PS Document Structuring Conventions
#  postamble()                   -  "   "     "         "          "
#  show_page()                   - flush page
#  set_landscape()               - establish landscape (horizontal page) 
#                                  environment
#  Page margins:      
#
#  $l = left_limit( $val )    - return (after optionally setting) left margin
#  $r = right_limit( $val )
#  $b = bottom_limit( $val )
#  $t = top_limit( $val )
#
#  Colors are represented by a references to a vector of length either 1 or 3.
#   A single number indicates a grayscale value for black and white, and
#   a triplet represents RGB values.  The routine set_color handles both
#   cases.  both gray level and rgb range from 0.0 to 1.0, 0.0 being white,
#   1.0 being darkest.
#
#  set_color( [ $number ] )  -sets a gray level  (length 1)
#  set_color( [ $num, $num, $num ] ) - sets a rgb value  (length 3)
#
#  Fonts:
#
#  set_font ($name, $size)    - select ps font, set size
#  $h = current_font_height() - return font size parameters for layout calcs.
#  $w = current_font_width()
#
#  Characters/strings:
#
#  put_char($c, $x, $y, $color)               - put char $c at $x, $y w/color
#  put_string($s, $x, $y, $color)             - left justfied string $s at 
#                                               $x, $y, $color 
#  put_string_right($s, $x, $y, $color)       - right justfied string 
#  put_string_vert_center($s, $x, $y, $color) - vertical stirng centered at x,y
#           
#  Geometric figures/symbols:
#
#     $style is either 'filled' or 'unfilled'                         
#
#  put_line($x1, $y1, $x2, $y2, $color)       - line from x1,y1 to x2, y2
#  put_box( $x, $y, $width, $height, $color)  - filled rectangle, where x & y
#                                               are coords of lower left corner
#  put_circle($x, $y, $radius, $color, $style)  - general circle
#  put_waterdrop($x, $y, $size, $color, $style) - hydrophilic symb if 'filled',
#                                                 hydrophobic if 'unfilled'
#                                                 depe
#  put_hexagon($x, $y, $size, $color, $style)   - hexagon for aromaticity
#  put_ellipses($x, $y, $r, $dy, $color)        - vertical ellipses 
#  put_negative($xc, $yc, $rad, $color)         - negative charge symbol
#  put_positive($xc, $yc, $rad, $color)         - positive charge symbol
#  put_polar($x0, $y0, $w, $h, $color)          - polarity symbol, x0, y0 lower
#                                                 left cornder, width, height
#  put_iso_triangle( $x, $y, $width, $height, $angle, $color, $style)
#                                               - isoscelese triangle with apex
#                                                 at $x, $y, rotated by $angle
#  
#
#  $Id: graf.pl,v 4.1 2007/05/16 19:55:05 mccorkle Exp mccorkle $
#
my $current_font_size;       # these save font size params so we can use
my $current_font_width;      # them for layout calculations
my $current_font_height;

# Margins of the plot - default for portrait

my $left_limit   = 70.0;         # set & viewed by left_limit()
my $right_limit  = 7.5 * 72;     #                 right_limit(), etc
my $bottom_limit = 50;
my $top_limit    = 9.5 * 72;

#
# These functions return and optionally set the above parameters
#
sub  left_limit
   {
    my $val = shift;
    $left_limit = $val if ( defined( $val ) );
    return( $left_limit );
   }

sub  right_limit
   {
    my $val = shift;
    $right_limit = $val if ( defined( $val ) );
    return( $right_limit );
   }

sub  bottom_limit
   {
    my $val = shift;
    $bottom_limit = $val if ( defined( $val ) );
    return( $bottom_limit );
   }

sub  top_limit
   {
    my $val = shift;
    $top_limit = $val if ( defined( $val ) );
    return( $top_limit );
   }

#
# set up for landscape output
#
sub  set_landscape
   {
    printf "0 %5.1f translate\n", (11.0 * 72);
    print "-90 rotate\n";
    bottom_limit( 30.0 );
    top_limit( 7.0 * 72 );
    left_limit( 40.0 );
    right_limit( 9.5 * 72 );
   }

sub  set_font
   { 
    my ($name, $size) = @_;
    $current_font_size = $size;
    $current_font_width =  0.6 * $size;
    $current_font_height =  0.8 * $size;
    print "/$name findfont $size scalefont setfont\n";
   }

sub  current_font_width { return( $current_font_width ); }

sub  current_font_height { return( $current_font_height ); }
  
sub  put_char
   {
    my ($c, $x, $y, $color) = @_;
    set_color( $color );
    print "$x $y moveto ($c) show\n";
   }

sub  put_string
   {
    my ($s, $x, $y, $color) = @_;
    set_color( $color );
    print "$x $y moveto ($s) show\n";
   }

sub  put_string_right
   {
    my ($s, $x, $y, $color) = @_;
    set_color( $color );
    print "$x $y moveto ($s) rightshow\n";
   }

sub  put_string_vert_center
   {
    my ($s, $x, $y, $color) = @_;
    set_color( $color );
    print "$x $y ($s) vshowcenter\n";
   }


sub  set_gray
   {
    my $gray = 1.0 - (shift);
    print "$gray setgray\n";
   }

sub  set_rgb_color
   {
    my ($r, $g, $b) = @_;
    print "$r $g $b setrgbcolor\n";
   }

#
# set_color( [ $number ] ) -sets a gray level  (length 1)
# set_color( [ $num, $num, $num ] ) - sets a rgb value  (length 3)
#                            - should add color names too
# colors are a reference to a vector of length 1 or 3.  set_color checks
# the length and invokes set_gray() or set_rgb_color() accordingly
#
sub  set_color
   {
    my @col = @{(shift)};
    if ( $#col == 0 )
       {  set_gray( $col[0] ); }
    elsif ( $#col == 2 )
       {  set_rgb_color( @col ); }
    else
       { die "Bad color in set_color: [@col]\n"; }
   }

#
# put_box( $x, $y, $width, $height, $color) - x, y coords of lower left corner
#

sub  put_box 
   {
    my ($x, $y, $width, $height, $color) = @_;
    set_color( $color );
    print "newpath $x $y moveto\n";
    print "0 $height rlineto\n";
    print "$width 0 rlineto\n";
    print "0 -$height rlineto\n";
    print "closepath fill\n";
   }

#
# put_iso_triangle( $x, $y, $width, $height, $angle, $color, $style)
#    draw isosceles triangle, apex at $x, $y,  $rotation angle,
#    negative height points down.  style: 'filled 'unfilled
#    uses Postscript routines {un}filledisotriangle - see preamble()
#
sub  put_iso_triangle
   {
    my ($x, $y, $width, $height, $ang, $color, $style) = @_;
    set_color( $color );
    print "$x $y $width $height $ang ",
          ( $style eq 'filled' ) ? "filledisotriangle" : "unfilledisotriangle",
          "\n";
   }

# put_circle($x, $y, $radius, $color, $style) 
#    circle of radius $radius, $x, $y center
#    uses Postscript routines {un}filledcircle - see preamble()
#
sub  put_circle
   {
    my ($x, $y, $radius, $color, $style) = @_;
    set_color( $color );
    print "$x $y $radius ",
           ($style eq 'filled' ? "filledcircle" : "unfilledcircle"), "\n";
   }

sub  put_line
   {
    my ($x1, $y1, $x2, $y2, $color) = @_;
    set_color( $color );
    print "newpath $x1 $y1 moveto $x2 $y2 lineto stroke\n";
   }

#
# put_waterdrop( $x, $y, $size, $color, $style )
#    uses Postscript routines {un}filledwaterdrop - see preamble()
#
sub  put_waterdrop
   {
    my ($x, $y, $size, $color, $style) = @_;
    set_color( $color );
    print "$x $y $size ",
          ($style eq 'filled' ? "filledwaterdrop" : "unfilledwaterdrop"), "\n";
   }

#
# put_hexagon($x, $y, $size, $color, $style) 
#    centered at $x, $y
#    uses Postscript routines {un}filledhexagon - see preamble()
#
sub  put_hexagon
   {
    my ($x, $y, $size, $color, $style) = @_;
    set_color( $color );
    print "$x $y moveto $size ",
          ($style eq 'filled' ? "filledhexagon" : "unfilledhexagon"), "\n";
   }

# draws vertical ellipses (3 dots) centered on $x, $y

sub  put_ellipses
   {
    my ($x, $y, $r, $dy, $color) = @_;
    put_circle( $x, $y - $dy, $r, $color, 'filled');
    put_circle( $x, $y, $r, $color, 'filled');
    put_circle( $x, $y + $dy, $r, $color, 'filled');
   }

# negative symbol is a circle with a dash inside

sub  put_negative
   {
    my ($xc, $yc, $rad, $color) = @_;
    my $loff = (0.25 / 0.45) * $rad;
    put_circle( $xc, $yc, $rad, $color, 'unfilled');
    put_line( $xc - $loff, $yc, $xc + $loff, $yc, $color);
   }

# positive symbol is a circle with a + inside

sub  put_positive
   {
    my ($xc, $yc, $rad, $color) = @_;
    my $loff = (0.28 / 0.45) * $rad;
    put_circle( $xc, $yc, $rad, $color, 'unfilled');
    put_line( $xc - $loff, $yc, $xc + $loff, $yc, $color);
    put_line( $xc, $yc - $loff, $xc, $yc + $loff, $color);
   }


# polar symbol is a diagonal double-arrowtipped line

sub  put_polar
   {
    my ($x0, $y0, $w, $h, $color) = @_;
    my $x1 = $x0 + 0.25 * $w;
    my $x2 = $x0 + 0.75 * $w;
    my $y1 = $y0 + 0.1 * $h;
    my $y2 = $y0 + 0.9 * $h;
    my $ang = (180.0 / 3.14159) * atan2( $x2-$x1, $y2-$y1);
    put_line( $x1, $y1, $x2, $y2, $color);
    put_iso_triangle( $x2, $y2, 0.5*$w, 0.3*$h, -$ang, $color, 'filled');
    put_iso_triangle( $x1, $y1, 0.5*$w, 0.3*$h, 180.0-$ang, $color, 'filled');
   }

#
# preamble( $title, $progname )
#
# postscript preamble - this contains a number of postscript subroutine
# defs which are used by many of the the put_something routines above.
#  
sub  preamble
   {
    my ($title, $progname) = @_;

print <<EndOfPreamble;
%!PS-Adobe-3.0
%%BoundingBox: 69 69 556 739
%%Title: $title
%%CreationDate: Tue Mar 16 11:52:57 2003
%%Creator: $progname (http://genome.bnl.gov)
%%Orientation: Landscape
%%Pages: (atend)
%%EndComments
%%BeginProlog

/rightshow { dup stringwidth pop 0 exch sub 0 rmoveto show } def
/vshowcenter { gsave 3 1 roll translate 90 rotate 0 0 moveto
               dup stringwidth pop 2 div 0 exch sub 0 rmoveto
               show  grestore } def
/filledcircle { newpath 0 360 arc fill } def
/unfilledcircle { newpath 0 360 arc stroke } def
/filledwaterdrop { 3 1 roll gsave translate dup scale newpath
  	              0  0.0  0.5  90 270 arc
	              0 -0.2  0.3 270  90 arc
	              0  0.3  0.2 270  90 arcn
	              fill grestore } def
/unfilledwaterdrop { 3 1 roll gsave translate dup dup scale
		        1 exch div setlinewidth newpath
         	        0  0.0  0.5  90 270 arc
	                0 -0.2  0.3 270  90 arc
	                0  0.3  0.2 270  90 arcn
	                stroke grestore } def
/hexside { 0 1 lineto currentpoint translate -60 rotate } def
/unfilledhexagon { gsave currentpoint translate
                   dup dup scale 1 exch div setlinewidth 
		      newpath  120 rotate  0 1 moveto
	  	      currentpoint translate -120 rotate
                   5 {hexside} repeat closepath
		   stroke grestore } def
/filledhexagon { gsave currentpoint translate dup scale
		    newpath 120 rotate 0 1 moveto
		    currentpoint translate -120 rotate
                 5 {hexside} repeat closepath
		    fill grestore } def
% xvert yvert w h ang isotriangle
/filledisotriangle { gsave 5 3 roll translate rotate
                     exch 2 div dup 3 -1 roll dup 4 1 roll neg
                     newpath 0 0 moveto lineto neg exch neg lineto
                     closepath fill grestore } def
/unfilledisotriangle { gsave 5 3 roll translate rotate
                       exch 2 div dup 3 -1 roll dup 4 1 roll neg
                       newpath 0 0 moveto lineto neg exch neg lineto
                       closepath stroke grestore } def

%%EndProlog
%%BeginSetup
%%EndSetup
EndOfPreamble
   }

sub  postamble
   {
    my $page_count = shift;
    print "%%Trailer\n";
    print "%%Pages: $page_count\n";
    print "%%EOF\n";
   }

sub  page_preamble
   {
    my $number = shift;
    print "\n";
    print "%%Page: $number $number\n";
    print "\n";
   }

sub  show_page
   { print "showpage\n"; }

1;


