# File:         cpdlgraf.pl
# Language:     perl
# Authors:      Sean R. McCorkle, Kimberly M. Mayer, John Shanklin
#
# Description:  CPDL Graphics - high level (track based) graphics routines for 
#               Conserved Property Difference Locator
#
# Routines:
#
#  page_header( $title )      - draw title on page
#  set_display_font()         - set fontsize for residues
#  place_symbol( $tr, $column, $row, $sym, $color ); 
#                             - draw symbol in cell $column, $row in track $tr
#                               (see tracks.pl for more)
#                               $sym is either a residue or a property
#                               $color is a color vector (see graf.pl) for more
#  column_to_x( $col )        - convert column number to pixel offset (same for
#                               all tracks)
#  row_to_y( $tr, $col )      - convert row number to pixel offset for track 
#      
#  draw_tick_mark($col,$pos,$first_tr,$last_tr,$course_offset)
#           - vertical guide line & number at column $col, showing position 
#             $pos in alignment, extending from top track to bottom track
#
#  set_gamma_correction( $f ) - sets user-desired gamma corr. function
#  engl_gamma_correction()    - returns a string for output on final page
#  exp_correction( $x )       - exponential gamma correction function
#  linear_correction( $x )    - linear gamma correction function
#  plateau_correction( $x )   - plateau (flat) gamma correction function
#
#  set_darkness( $d )         - sets user-desired darkness parameter
#  darkness                   - returns current darkness parameter
#  darken( $f )               - apply darkness to gamma-corrected $f ratio
#                                ($freq/$norm)
#  $lev = greyscale( $freq, $norm )  - compute an appropriate greyscale level
#                                      for $freq/$norm, with 0 lightest and 1
#                                      darkest.
#  $color = color_scale( $color, $freq, $norm ) - compute an appropriate color
#                                    - for $freq/$norm based on $color - 0 
#                                      lightest and 1 darkest
#
#                             - greyscale and color_scale invoke the current
#                               gamma correction function and darken()
#
#  $color = interp_color( $f, $col1, $col2 ) - interpolate between two RGB 
#                                              colors, $f = 0 => col2
#                                                    $f = 1 => col1`
#                                                    $f = 0.5 => (col2+col1)/2 
#                                                
# base colors for the properties
#
#  $color = size_color( ... )     - return (after optionally setting) color
#  $color = hydro_color( ... )
#  $color = charge_color( ... )
#  $color = polarity_color( ... )
#  $color = tick_color( ... )
#
# $Id: cpdlgraf.pl,v 4.0 2007/05/16 17:30:38 mccorkle Exp mccorkle $
#

require "graf.pl";


my $display_font_width;     # these are initialized by set_display_font()
my $display_font_height;
my $column_width;
my $col_space_frac = 0;     # was 1.2 - this times font width space every 10

sub  page_header
   {
    my $t = shift;
    set_font( "Courier-Bold", 12 );
    put_string( $t, left_limit(), 9 * current_font_height() + top_limit(), 
                 [ 1.0 ] );
   }

#
# sets the font for the distilled alignment display (main track)
# This must be invoked at least once before any graphics rendering, 
# because it sets the global $column_width, which is used by other routines, 
# such as column_to_x, etc.  It also most be invoked before 
# build_track_descrips() in cpdl.pl, because it sets globals
# $display_font_width and $display_font_height 
#
sub  set_display_font

   {
    set_font( "Courier-Bold", 15 );
    $display_font_width = current_font_width();
    $display_font_height = current_font_height();
    $column_width = $display_font_width;
   }

# place_symbol( $tr, $column, $row, $symbol, $color )
#
#  - draw one symbol on a track at a 
#   $tr     - track where symbol is to be placed
#   $column - column in track (integer 0 to num_columns)
#   $row    - how many cells above (+) or below (-) track baseline
#   $symbol  - either an amino acid (character), property, or 
#                "filled_up_triangle" etc or ellipse.s
#                 also 
#   $color is a color vector suitable for sending to set_color()
#
sub  place_symbol
   {
    my ( $tr, $column, $row, $sym, $color ) = @_;

    #print "place_symbol $column $row $sym [", @{$color},"]\n";
    my $x = column_to_x( $column );
    my $y = row_to_y( $tr, $row );
    my $h;
    if ( $row == 0 )
       { $h = 2 * track_offset( $tr ); }
    else
       { $h = track_delta( $tr ); }
    my $xc = $x + 0.5 * $column_width;
    my $yc = $y + 0.5 * $h;


    if ( $sym eq '-' || $sym eq '.' || $sym eq 'X' )     # can't use is_blank()
       { put_char( '-', $x, ($y + 0.12 * $h), $color ); }  #here - for blank aa
    elsif ($sym eq ' ' )                                 # but don't print 
       { }                                               # blank propertys
    elsif ( is_aa( $sym ) )
       { put_char( $sym, $x, ($y + 0.12 * $h), $color ); }
    elsif ( $sym eq 'filled_cell' )
       { put_box( $x, $y, $column_width, track_delta( $tr ), $color); }
    elsif ( $sym eq 'ellipses' )
       { put_ellipses( $xc, $yc, (0.1 * $column_width), (0.3 * $h), $color); }
    elsif ( $sym eq 'neutral' )
       { put_circle( $xc, $yc, (0.45 * $column_width), $color, 'unfilled'); }
    elsif ( $sym eq 'negative' )
       { put_negative( $xc, $yc, (0.45 * $column_width), $color); }
    elsif ( $sym eq 'positive' )
       { put_positive( $xc, $yc, (0.45 * $column_width), $color); }
    elsif ( $sym eq 'polar' )
       { put_polar( $x, $y, $column_width, $h, $color); }
    elsif ( $sym eq 'nonpolar' )
       { put_circle( $xc, $yc, (0.3 * $column_width), $color, 'unfilled'); }
    elsif ( $sym eq 'hydrophilic' ) 
       {
         put_waterdrop( $xc, $yc, (0.8 * $column_width), $color, 'unfilled');
         put_waterdrop( $xc, $yc, (0.8 * $column_width), $color, 'filled');
       }
    elsif ( $sym eq 'hydrophobic' )
       {
         put_waterdrop( $xc, $yc, (0.8 * $column_width), $color, 'unfilled');
         my $x1 = $x + 0.1 * $column_width;
         my $y1 = $y + 0.1 * $column_width;
         my $x2 = $x + 0.7 * $column_width;
         my $y2 = $y + 0.7 * $h;
         put_line( $x1, $y1, $x2, $y2, $color );
         #put_line( $x1, $y2, $x2, $y1, $color);
       }
    elsif ( $sym eq 'aromatic' )
       { put_hexagon( $xc, $yc, (0.5 * $column_width), $color, 'unfilled'); }
    elsif ( $sym eq 'nonaromatic' )
       { 
         my $d = 0.2 * $column_width;
         put_line( $xc - $d, $yc - $d, $xc + $d, $yc + $d, $color);
         put_line( $xc - $d, $yc + $d, $xc + $d, $yc - $d, $color);
       }
    elsif ( $sym eq 'large' )
       { put_circle( $xc, $yc, (0.42 * $column_width), $color, 'filled' ); }
    elsif ( $sym eq 'small' )
       { put_circle( $xc, $yc, (0.28 * $column_width), $color, 'filled' ); }
    elsif ( $sym eq 'tiny' )
       { put_circle( $xc, $yc, (0.18 * $column_width), $color, 'filled' ); }
    elsif ( $sym eq 'undefined')   # fix this!
       { } 
    elsif ( ($sty, $psym) = parse_symbol( $sym ) )
       {
        if ( $psym eq 'up_arrow' )
           {
            if ( $sty eq 'unfilled' )   # blankout triangle background first
               { put_iso_triangle( $xc, ($y + 0.55 * $h), $column_width,
                                   (0.55 * $h), 0, [ 0 ], 'filled' ); }
            put_iso_triangle( $xc, ($y + 0.55 * $h), $column_width, 
                                   (0.55 * $h), 0, $color, $sty);
           }
        elsif ( $psym eq 'down_arrow' )
           {
            if ( $sty eq 'unfilled' )
               { put_iso_triangle( $xc, ($y + $h - 0.55 * $h), $column_width,
                                   (0.55 * $h), 180, [ 0 ], 'filled' ); }
            put_iso_triangle( $xc, ($y + $h - 0.55 * $h), $column_width,
                                   (0.55 * $h), 180, $color, $sty);
           }
        elsif ( $psym eq 'big_circle' )
           { put_circle( $xc, $yc, (0.42 * $column_width), $color, $sty); }
        elsif ( $psym eq 'medium_circle' )
           { put_circle( $xc, $yc, (0.28 * $column_width), $color, $sty); }
        elsif ($psym eq 'small_circle' )
           { put_circle( $xc, $yc, (0.18 * $column_width), $color, $sty); }
        else 
           { die "place_symbol1: bad symbol: \"$sym\"\n"; }
       }
    else 
       { die "place_symbol2: bad symbol: \"$sym\"\n"; }
   }


# split symbol into "filled/unfilled" and actual symbol

sub  parse_symbol
   {
    if ( (shift) =~ /^((un)?filled)_(((up|down)_arrow)|((small|medium|big)_circle))$/ )
       { return( ($1, $3) ); }
    else
       { return( '' ); }
   }


sub  draw_tick_mark
   {
    my ($col,$pos,$first_tr,$last_tr,$course_offset) = @_;
    my $top = offset_base( $first_tr, $course_offset );
    my $bot = offset_base( $last_tr, $course_offset );
    place_tick( $top, $bot, $col, tick_color() );
    write_pos( $top, $col, $pos )
   }

sub  write_pos
   {
    my ($tr, $col, $pos) = @_;
    set_font( "Courier", 9 );
    place_string_right( $tr, $col, track_height( $tr ), $pos, tick_color() );
    set_display_font();
   }

#           
# place_tick( $top_track, $bot_track, $column, $color )
#
sub  place_tick
   {
    my ($top_tr, $bot_tr, $column, $color) = @_;
    my $x = column_to_x( $column );

    put_line( $x, row_to_y( $top_tr, track_height( $top_tr ) ),
               $x, row_to_y( $bot_tr, -( track_depth( $bot_tr )) ), $color );
   }

sub  place_string_right
   {
    my ($tr, $column, $row, $s, $color) = @_;
    put_string_right( $s, column_to_x( $column ), 
                       row_to_y( $tr, $row), $color );
   }



#
# column_to_x( $col ) returns a drawable x coordinate for column number c
#

sub  column_to_x
   {
    my $col = shift;
    return( left_limit() + $column_width * $col 
                         + $column_width * $col_space_frac * int( $col / 10 ) 
          );
   }

# row_to_y( $track, $row ) returns a drawable y coordinate for row $row,
#                          in the apprropriate track   

sub  row_to_y
   {
    my ( $track, $row ) = @_;
    my $ybase  = track_base( $track );
    my $yoff   = track_offset( $track );
    my $ydelta = track_delta( $track );
    if ( $row > 0 )
       { return( $ybase + $yoff + $ydelta * ($row - 1) ); }
    elsif ( $row == 0 )
       { return( $ybase - $yoff ); }
    elsif ( $row < 0 )
       { return( ($ybase + $ydelta * $row) - $yoff ); }

   }

#
#  "gamma correction" functions - these modify the linear grayscale 
#  values before plotting.  These functions correspond to the grayscale 
#  options given by -g or --grayscale.   Gamma correction is also applied 
#  to colors as well
#
# The parameters for these were tuned by eye to get a nice result via
# ghostscript, Adobe acrobat, and a color laser printer.
#

my $linear_p1 = 0.8;     # extracted out as globals? maybe these could
my $linear_p2 = 0.1;     # be set by options or some configuration file?

sub  linear_correction
   { return( $linear_p1 * (shift) + $linear_p2 ); }

my $epsilon = 1.0e-6;
my $plateau_p1 = 0.3;

sub  plateau_correction
   {
    my $x = shift;
    return( ( abs(1 - $x) < $epsilon ) ? 1 : $plateau_p1 );
   }

my $exp_p1 = 2;

sub  exp_correction
   { return( exp( $exp_p1 * ((shift)-1) ) ); }

my $gamma_correcton_f = \&exp_correction;
my $engl_gamma_f = 'exponential';

# set_gamma_correction( [ 'linear' | 'exponential' | 'plateau' ] )

sub set_gamma_correction
   {
    my $w = shift;
    if ( $w eq 'linear' ) 
        { $gamma_correction_f = \&linear_correction; 
          $engl_gamma_f = 'linear';
        }
    elsif ( $w eq 'exponential' )
        { $gamma_correction_f = \&exp_correction; 
          $engl_gamma_f = 'exponential';
        }
    elsif ( $w eq 'plateau' )
        { $gamma_correction_f = \&plateau_correction; 
          $engl_gamma_f = 'flat';
        }
    else
        { die "Bad value for gamma_correction: \"$w\"" . 
               "should be linear, exponential or plateau\n"; }
   }

sub  engl_gamma_correction
   { return( $engl_gamma_f ); }

# darken() is kind of a kludgy attempt to darken the output
#  to compensate for bad printers, etc


my $base_darkness = 0.25;
my $darkness = $base_darkness;

sub  set_darkness
   { $darkness = shift; }


sub  darkness
   { return( $darkness ); }


sub  darken
   {
    my $f = shift;
    my $b = 1.0 - (1.0 - $f) * (1.0 - $darkness) / (1.0 - $base_darkness );
    if ( $b < 0.0 )
       { return( 0.0 ); }
    elsif ( $b > 1.0 ) 
       { return( 1.0 ); }
    else
       { return( $b ); }
   }

#
# greyscale( $freq, $norm ) returns a grey level suitable for submission
#  to set_color or set_gray, with the gamma correction already replied
#
sub  greyscale
   {
    my ( $freq, $norm ) = @_;
    return( [ darken( &{$gamma_correction_f}( 1.0 * $freq / $norm ) ) ] );
   }


#  interp_color( $f, $color1, $color2 )
#    interpolate between two color vectors $color1, $color2.  
#    $f between 0 (all $color2) or 1 ($all color 1), 
#        0.5 halfway between the two

sub  interp_color
   {
    my ( $f, $color1, $color2 ) = @_;
    my @res = ();
    for ( my $i = 0; $i <= $#{$color1}; $i++ )
      { push( @res, (1-$f) * $$color2[$i] + $f * $$color1[$i] ); }
    return( [ @res ] );
   }


sub  color_scale
   {
    my ( $color, $freq, $norm ) = @_;
    my $f = &{$gamma_correction_f}( 1.0 * $freq / $norm );
    return( interp_color( darken( $f ), $color, [1.0, 1.0, 1.0] ) );
   }


my $size_color       = [ 0.05,  0.5,   0.1 ];   # green
my $hydro_color      = [ 0.0,   0.0,   0.8 ];   # blue (of course)
my $charge_color     = [ 0.8,   0.3,   0.0 ];   # orangish
my $polarity_color   = [ 0.5,   0.0,   0.3 ];   # magenta/cranberryish
my $base_tick_color  = [ 0.841, 0.802, 0.649 ]; # color of vertical position
                                                # lines

sub  size_color
   {
    my $v = shift;
    $size_color = $v if ( defined( $v ) );
    return( $size_color );
   }

sub  hydro_color
   {
    my $v = shift;
    $hydro_color = $v if ( defined( $v ) );
    return( $hydro_color );
   }

sub  charge_color
   {
    my $v = shift;
    $charge_color = $v if ( defined( $v ) );
    return( $charge_color );
   }

sub  polarity_color
   {
    my $v = shift;
    $polarity_color = $v if ( defined( $v ) );
    return( $polarity_color );
   }

sub tick_color()
   {
    interp_color( ($darkness - $base_darkness),
                   [ 0.0, 0.0, 0.0], $base_tick_color );
   }


1;

