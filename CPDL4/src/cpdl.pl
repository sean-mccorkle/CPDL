#!/usr/bin/perl -w
# Program:      cpdl.pl   CPDL
# Language:     perl
# Description:  CPDL  Conserved Property Difference Locator
#
# Authors:      Sean R. McCorkle, Kimberly M. Mayer, John Shanklin
#               Brookhaven National Laboratory, Upton NY 11973
#
# Bug reports:  mccorkle@bnl.gov
# URL:          http://genome.bnl.gov/CPDL/
#
# Reference:    "Linking enzyme sequence to function using conserved
#                property difference locator to identify and annotate positions
#                likely to control specific functionality"
#                Kimberly M. Mayer, Sean R. McCorkle and John Shanklin
#                BMC Bioinformatics 2005,  6:284
#                http://www.biomedcentral.com/1471-2105/6/284
#
# License:      BSA Open Source License - see included files LICENSE.txt or
#               LICENSE.pdf
#
# Usage:        cpdl.pl [options] <n> [<aligmnent-file>]
#
#               Input file is a multiple alignment of two homologous groups
#               of proteins which are to be compared.
#
#               The input aligment format is text, one protein per line, where
#               each line consists of three whitespace-separated fields: 
#                              <seqnum> <seqname> <seq>
#               where
#                     <seqnum>  is an increasing integer 
#                     <seqname> is a sequence identifier 
#                     <seq>     is the protein amino acid sequence, as it 
#                               apears in
#                   the alignment, where inserted spaces are indicated by
#                   '.' (period character).  Amino acids should be all caps
#                   and can include 'X' (which is treated the same as '.')
#                   no spaces can occur in any of these fields. 
#
#                The two homologous groups of proteins must be separated in
#                the alignment such that all members of the first group are
#                in rows 1 to <n> and all the members of the second group are
#                in rows below (<n+1> to the end).   The number <n> tells
#                CPDL where the dividing line is between the two groups.
#
#                If alignment-file is not specified, stdin is scanned.
#
#                See README and reference above for more detailed description
#
# Options:
#               -g <gval> <gval> is "linear", "exponential" (default),
#                         or "plateau".  use exponential, exponential, linear 
#                         or flat gamma-correction functions to indicate lower 
#                         frequency residues or properties.
#               -C <cval> <cval> is "unanimous_minus_1" (default) or 
#                          "unanimous".  defines "conserved" to be "All but 
#                         one" or "all"
#               -d <n>  (default 0.25) controls darkness of output
#               -f <n> (default 5) frequency cutoff for printing - don't print 
#                        any more than <n> residues or properties in a track
#               -t <str> use <str> as plot title (default is filename)
#               -P       don't display orange circles (which indicate 
#                        differences in property tracks) in the main track 
#               -K       don't display key table at end of output
#               -U       don't print user's settings at end of output
#
#   The following options control the various property track display states:
#
#               -s <state>  size track
#               -w <state>  hydrophobicity track
#               -c <state>  charge track
#               -p <state>  polarity track
#               -a <state>  aromaticity track
#
#    where  <state> can be one of the following:
#
#          blank           don't show the track
#          on              show every position in the track
#          discrep         only show position if there's a difference (default)
#          main_discrep    only show position if there's a difference in the
#                          main track
#          main_full_high  only show position if there's a "full-high" 
#                          (red hourglass) difference in the main track
# 
#
# $Id: cpdl.pl,v 4.1 2012/01/05 16:09:51 seanmccorkle Exp seanmccorkle $
#
use strict;

use Getopt::Std;

use lib ".";

require "utils.pl";                 # miscellaneous utilities
require "freqs.pl";                 # frequency tables
require "tracks.pl";                # graphical track descriptors
require "track_descriptions.pl";    # other track data
require "props.pl";                 # residue property functions
require "conserved.pl";	            # user selected conservation definition 
                                    # functions
require "discrepancies.pl";         # discrepancy detecting function 
                                    # (differences)
require "cursor.pl";	            # mechanism for keeping track of position
require "cpdlgraf.pl";              # high level (track) graphics
require "key_table.pl";             # prints key at end of report

my %options = ();                      
getopts("a:c:C:d:f:g:I:KPp:s:Uw:t:",\%options) || die;  
                                       # this SHOULD be in handle_command_line
                                       # _options() but for the life of me I 
                                       # can't get getopts() to work in a sub

my $cpdl_revision = '$Revision: 4.1 $';
$cpdl_revision =~ s/^\$Revision: //;
$cpdl_revision =~ s/ \$\s*$//;

my $group_a_max = shift;

my $filename = @ARGV ? $ARGV[0] : "stdin";
my $input_filename = $filename;    # overridden by -I
my $title;                         # set by -t option

my $freq_print_cutoff = 5;  # don't print residue stack deeper than this number
                            # (if over, indicate with vertical ellipses ...)

my $size_track_state     = 'discrep';  # -s option (these are changed and then
my $hydro_track_state    = 'discrep';  # -w option  saved in @track_descrips 
my $charge_track_state   = 'discrep';  # -c         - see track_description.pl
my $polarity_track_state = 'discrep';  # -p         for more details)
my $aromatic_track_state = 'discrep';  # -a

my $show_property_diffs  = 1;   # cleared by -P option
my $show_key_table       = 1;   # cleared by -K option
my $show_user_settings   = 1;   # cleared by -U option

handle_command_line_options();

my $course_height  = 300;

my $last_seqnum = 0;
my $seqnum;
my $seqname;
my $seq;

my @seqs     = ();    # array of sequences
my @seqnames = ();    # array of sequence names
my @seqnums  = ();    # array os sequence numbers
my $length;

# group A arrays
my @a_seqs     = ();  # array of sequences
my @a_seqnames = ();  # array of sequence names
my @a_seqnums  = ();  # array os sequence numbers

# group B arrays
my @b_seqs     = ();  # array of sequences
my @b_seqnames = ();  # array of sequence names
my @b_seqnums  = ();  # array of sequence numbers

my @track_descrips;    # set by create_track_descrips

my $page_number = 0;   # used by start_page() and finish_page()


my %engl_states =   # maps track_description status symbols to english desc
      ( 'on'             =>  "on",
        'blank'          =>  "off",
        'discrep'        =>  "if in track",
        'main_discrep'   =>  "if in main track",
        'main_full_high' =>  "if in main red hourglass", 
      );


                              ################
                              # Main Program #
                              ################


read_alignment();

preamble( "", "CPDL v$cpdl_revision" );

start_page();
set_display_font();

build_track_descrips();
 
#   
# Keep global pointers to first track (residues) and last track
#
my $first_tr = td_track( $track_descrips[0] );
my $last_tr  = td_track( $track_descrips[$#track_descrips] );

separate_groups();

#
# Main loop: for the sake of sanity in graphics output, we work one column,
# or rather one aligmnent position at a time, and when a page is completed, 
# we flush it and start a new one.   However, this entails buffering results 
# for each of the tracks at the position, and plotting stuff only when
# everything else is done.
#
foreach my $pos ( 0..($length-1) )  # internally, column numbers run 0 to n-1
   {
    my $res_freqs_a = res_frequencies( $pos, @a_seqs );
    my $res_freqs_b = res_frequencies( $pos, @b_seqs );

    # for each property in @track_descrips, convert residue frequences to
    # property frequences, and put them all into a list for each group
    my $propsf_a = all_property_frequencies( $res_freqs_a, @track_descrips );
    my $propsf_b = all_property_frequencies( $res_freqs_b, @track_descrips );

    # go through all the residue/property frequencies and find any 
    # differences ("discrepancy" was the old term, later changed to 
    # "differences")
    my @discreps = all_discrepancies( $propsf_a, $propsf_b, @track_descrips );
                                      
    my $course_offset = $course_height * curs_course();
    print_cursor();
    my $j = 0;

    my $col = curs_col();
    if ( $col > 0  && ($col % 10 == 0) )  # tick marks go down first because
       {                                  # everything else goes overtop
        draw_tick_mark( $col, $pos, $first_tr, $last_tr, $course_offset);
       }

    if ( $show_property_diffs )         # orange circles go behind discrepancy
       {                                # flags in main track, so this is first
        show_property_diffs( $col, $course_offset, @discreps[1..$#discreps] ); 
       }

    foreach my $td ( @track_descrips )   # for each track (property)
       {
        if ( show_track( $td, $discreps[$j], $discreps[0] ) )
          { 
           my $tr = offset_base( td_track( $td ),   # in case of mult. courses
                                 curs_course() * $course_height );
           my $colorizef = td_colorize_func( $td );

           # print the vertical residue/symbol histograms for current position
           render_vert_column( $tr, $col, +1, $$propsf_a[$j], $colorizef );
           render_vert_column( $tr, $col, -1, $$propsf_b[$j], $colorizef );

           # finally, flag any differences in the track's center row
           plot_discrep( $tr, $col, $discreps[$j] );
          }
        $j++;
       }
    advance( sub { finish_page(); start_page(); } );
   }


finish_page();                                 # close off last page
if ( $show_key_table || $show_user_settings )  # start a final page for
   {                                           # user settings and/or key
    start_page();
    page_footer();
    render_user_settings() if ( $show_user_settings );
    set_display_font();
    if ( $show_key_table )
       {
        page_header( "Residue Properties/Symbol Key" );
        render_key_table();
       }
    show_page();
   }
postamble( $page_number );                    # postscript postamble




                             ###############
                             # Subroutines #
                             ###############


sub  handle_command_line_options
   {
    foreach my $x ( keys( %options ) )
       { print STDERR "[$x] [", $options{$x}, "]\n"; }

    set_gamma_correction( check_arg( 'g', ('exponential','linear','plateau')));

    set_conserved_func( check_arg( 'C', ('unanimous_minus_1', 'unanimous')) );

    set_darkness( defined( $options{'d'} ) ? $options{'d'} : 0.25 );

    $freq_print_cutoff = defined( $options{'f'} ) ? $options{'f'} : 5;

    $size_track_state     = check_td_state ( 's' );
    $hydro_track_state    = check_td_state ( 'w' );
    $charge_track_state   = check_td_state ( 'c' );
    $polarity_track_state = check_td_state ( 'p' );
    $aromatic_track_state = check_td_state ( 'a' );

    $show_property_diffs  = defined( $options{'P'} ) ? 0 : 1; 
    $show_key_table       = defined( $options{'K'} ) ? 0 : 1; 
    $show_user_settings   = defined( $options{'U'} ) ? 0 : 1; 
    $title = defined( $options{'t'} ) ? $options{'t'} : $filename;
    $input_filename = $options{'I'} if ( defined( $options{'I'} ) );
   }

#
# check_td_state( $opt ) returns check_arg() for a list of track display
#                        states
sub  check_td_state
   {
    return( check_arg( (shift), ( 'discrep', 'on', 'blank', 'main_discrep',  
                                  'main_full_high' ) ) );
   }

#
# check_arg( "option letter", allowed-list )
#  if value is not defined, default value (first in allowed-list)
#    is returned
#  if value is defined and in allowed-list, it is returned
#  if value is defined and not in allowed-list, bomb out with message
#
sub  check_arg
   {
    my ( $opt, @allowed ) = @_;

    return( $allowed[0] ) unless( defined( $options{$opt} ) );
    if ( grep( ( $_ eq $options{$opt} ), @allowed ) )
       { return( $options{$opt} ); }
    else
       {
        die "bad value \"". $options{$opt} .
             "\" for -$opt option; must be one of: " . 
             join( ", ", @allowed ) . "\n";
       }
   }

sub  build_track_descrips
   {
    #
    # This is a list of track_descript records, which record the
    # display settings and positions of the CPDL graphic output tracks.
    # Since the track positions depend on the $display_font_height,
    # this routine must be invoked after calling set_display_font()
    #
    # There's some description of the track_description fields in 
    # track_descriptions.pl

    my $display_font_height = 12;          # remove when graphics in place
    my $d1 = 0.5 * $display_font_height;
    my $h1 = $display_font_height;

    @track_descrips = 
        (
         make_track_description( 'sequence', 
                                 'on',     # sequence track is ALWAYs on
                                  0,       # no associated property function
                                  make_track( 490, $d1, $h1, 
                                                   $freq_print_cutoff + 3, 
                                                   $freq_print_cutoff + 3 ),
                                 \&greyscale ),
          make_track_description( 'size',
                                  $size_track_state,
                                  \&residue_size,
                                   make_track( 360, 0.6*$d1, 0.6*$h1, 3, 3 ),
                                   sub { color_scale( size_color(), @_ ); }
                                   ),
          make_track_description( 'hydro', 
                                  $hydro_track_state,
                                  \&hydro_prop,
                                   make_track( 290, 0.8*$d1, 0.8*$h1, 2, 2 ),
                                   sub { color_scale( hydro_color(), @_ ); }
                                  ),
          make_track_description( 'charge', 
                                  $charge_track_state,
                                  \&residue_charge,
                                   make_track( 210, 0.8*$d1, 0.8*$h1, 3, 3 ),
                                   sub { color_scale( charge_color(), @_ ); }
                                   ),
          make_track_description( 'polarity', 
                                  $polarity_track_state,
                                  \&polar_prop,
                                   make_track( 130, 0.8*$d1, 0.8*$h1, 2, 2 ),
                                   sub { color_scale( polarity_color(), @_ ); }
                                   ),
          make_track_description( 'aromatic', 
                                  $aromatic_track_state,
                                  \&aromatic_prop,
                                   make_track( 70, 0.8*$d1, 0.8*$h1, 2, 2 ),
                                  \&greyscale )
        );

   }


# reads a .cal format alignment from cmd line or stdin,
# fills global arrays @seqs, @seqnames, @seqnums - dies
# if an error is detected.
#
# Note to self: maybe we want to check that all seqs are 
# the same length?

sub  read_alignment
   {
    my $amino_acid_string = amino_acid_string() . 'X';
    while ( <> )
       {
        chomp;
        s/^\s+//;
        s/\s+$//;
        next unless ( $_ );
        ($seqnum,$seqname,$seq) = split( /\s+/ );
        ( $seqnum == $last_seqnum + 1 ) 
             || die "Bad seqnum input line $_\n" .
                    "expected: ", $last_seqnum+1, "; got: $seqnum\n";
        $last_seqnum = $seqnum;
        unless ( $seq =~ /^[\.$amino_acid_string]+$/ )
           { 
            $seq =~ /^[\.$amino_acid_string]*(.)/;
            my $bad = $1;
            die "Bad amino acid sequence: $_\n" . 
                "The character \"$bad\" is not allowed\n" 
           }
        push( @seqs, $seq );
        push( @seqnums, $seqnum );
        push( @seqnames, $seqname );
       }
    $length = maximum(  map( length( $_ ), @seqs ) );
   }

# split the sequences up into two groups

sub  separate_groups
   {
    if ( $group_a_max < 1 || $group_a_max > $#seqs )
       { die "group_a_max is $group_a_max; must be in range 1 to $#seqs\n"; }

    @a_seqs     = @seqs[0..$group_a_max-1];
    @a_seqnames = @seqnames[0..$group_a_max-1];
    @a_seqnums  = @seqnums[0..$group_a_max-1];

    @b_seqs     = @seqs[$group_a_max..$#seqs];
    @b_seqnames = @seqnames[$group_a_max..$#seqnames];
    @b_seqnums  = @seqnums[$group_a_max..$#seqnums];
    print "%group_a_tot is ", $#a_seqs+1, "\n";
    print "%group_b_tot is ", $#b_seqs+1, "\n";
   }

# extracted the residues (amino acids) from column $col_num of the
# given sequence group
# return a frequency table reference (freqs.pl)

sub  res_frequencies
   {
    my ( $col_num, @seqs ) = @_;
    my @col = map( substr( $_, $col_num, 1 ), @seqs );
    my $ft = make_freq_table();
    foreach my $c ( @col )
       { accum_freq_table( $ft, $c ); }
    return( $ft );
   }

#
# property_frequencies( $res_freqs, @track_descrips )
#    for each track in track_discrips, convert the residue frequencies
#    into a frequency table of the appropriate property and return
#    all the tables in an ordered list
#
sub  all_property_frequencies
   {
    my ( $res_freqs, @tds ) = @_;

    my @pfs = ();
    foreach my $td ( @tds )
       {
        my $state = td_state( $td );
        my $pfunc = td_prop_func( $td );
        my $pf;
        if ( $state eq 'gone' )
           { $pf = 0; }
        elsif ( ! $pfunc )        # if there's no property function
           { $pf = $res_freqs; }  # then this is the first (sequence) track
        else
           { $pf = prop_frequencies( $pfunc, $res_freqs ); }
        push( @pfs, $pf );
       }
    return( [ @pfs ] );
   }


#     
# all_discrepancies( $propsf_a, $propsf_b, @track_descrips )
#
#  invokes discrepancies() (see discrepancies.pl) for each pair of res/property
#  frequencies in the lists $propsf_a, $propsf_b
#
#  returns ( [ $disc_a, $disc_b], [ $disc_a, $disc_b ], ... ) 
#  for each pair of properties from group a and b for a 
#  particular position in the input alignment
#
sub  all_discrepancies
   {
    my (  $propsf_a, $propsf_b, @tds ) = @_;

    my @discreps = ();
    my $t = 0;
    foreach my $td ( @tds )
       {
        my $state = td_state( $td );
        if ( $state eq 'gone' )
           { push( @discreps, 0 ); }
        else
           { 
             push( @discreps, 
                  discrepancies( conserved_func(), 
                                 $$propsf_a[$t], $$propsf_b[$t]));
           }
        $t++;
       }
    return( @discreps );
   }

# this plots light orange circles in the center row of the main track
# to indicate any discrepancies (differences) in any of the property tracks

sub  show_property_diffs
   {
    my ($col, $course_offset, @discreps) = @_;
    my $sc = score_prop_discrepancies( @discreps );
    if ( $sc > 0 )
       { 
         place_symbol( offset_base( $first_tr, $course_offset ), $col, 0, 
                     ( $sc > 2 ) ? 'filled_big_circle' : 'unfilled_big_circle',
                       [ 0.9, 0.6, 0.2 ], );
       }
   }

#
# show_track( $td, $dis, $main_dis ) -> returns 1 if this position in this
#                                       track is to be displayed, depending on
#                                       track settings, discrepancies and
#                                       perhaps also main track discrepancies.
#                                       false ('') is returned otherwise
#
sub  show_track
   {
    my ( $td, $dis, $main_dis ) = @_;
    my $state = td_state( $td );
    print "%show-track ", dis_string( $dis ), " ", dis_string( $main_dis ),
                         " ", false( is_discrepancy( $dis ) ), "\n";
    if ( $state eq 'gone' )
       { return( '' ); }
    elsif ( $state eq 'blank' )
       { return( '' ); }
    elsif ( $state eq 'on' )
       { return( 1 ); }
    elsif ( $state eq 'discrep' )
       { return( is_discrepancy( $dis ) ); }
    elsif ( $state eq 'main_discrep' )
       { return( is_discrepancy( $dis ) && is_discrepancy( $main_dis ) ); }
    elsif ( $state eq 'main_full_high' )
       { return( is_discrepancy( $dis ) && is_full_high( $main_dis ) ); }
    else
       { die "in show_track, bad value for state: \"$state\"\n"; }
   }




# render_vert_column( $tr, $col, $dir, $freqs[$j], $colorizef );
#
#    At one position, given by $col in track $tr,  plot an upward or downward 
#    vertical column of residues or properties given in $freqs[] with the most 
#    frequent closest to the center row and the least frequent being the 
#    farthest from the 0 track.  As the frequency counts dimish, lighten 
#    the color of the symbol by using the $colorizef function to determine 
#    color (this includes darkening and gamma correction)
#
#    $dir is +1 for columns above the track baseline (group a)
#            -1 for columns below the track baseline (group b)
#

sub  render_vert_column
   {
    my ( $tr, $col, $dir, $freqs, $colorizef ) = @_;

    my $norm = total_counts( $freqs );
    # for each element of freqs
    my $i = 0;
    my $row = 0 + $dir;
    foreach my $p ( sorted_pairs( $freqs ) )
       {
        if ( $i++ > $freq_print_cutoff )
           {
             place_symbol( $tr, $col, $row, 'ellipses',
                           &{$colorizef}( $$p[1], $norm ) );
             last;
           }
        else
           { place_symbol( $tr, $col, $row, $$p[0], 
                           &{$colorizef}( $$p[1], $norm ) ); 
           }
        $row += $dir;
       }
   }

#
# plot_discrep( $tr, $col, $discreps[$j] ) 
#     - plots flags indicating discrepancies (differences) reported by
#       discrepancies()  - see discrepancies.pl for more explanation
#
sub  plot_discrep
   {
    my ( $tr, $col, $dis ) = @_;
    my ($topd,$botd) = @{$dis};
    print "% discrep $col ", dis_string( $dis ), " ",
               dis_st( $topd ), " ", dis_st( $botd ), "\n";
    my $sym = '?';
    if ( $topd )
       {
        $sym = 'filled_down_arrow' if ( $$topd[0] eq 'full' );
        $sym = 'unfilled_down_arrow' if ( $$topd[0] eq 'part' );
        place_symbol( $tr, $col, 0, $sym, intensity_color( $$topd[1] ) );
       }
    if ( $botd )
       {
        $sym = 'filled_up_arrow' if ( $$botd[0] eq 'full' );
        $sym = 'unfilled_up_arrow' if ( $$botd[0] eq 'part' );
        place_symbol( $tr, $col, 0, $sym, intensity_color( $$botd[1] ) );
       }
   }

# $color = intensity_color( 'high' | 'medium' ) converts an intensty
# (see discrepancies.pl) into a color vector (see graf.pl)

sub intensity_color
   {
    my $intens = shift;
    return( [ 1.0, 0.0, 0.0 ] ) if ( $intens eq 'high' );    # red if high
    return( [ 1.0 ] )           if ( $intens eq 'medium' );  # black if medium
    return( [ 0.5 ] );                                       # else 0.5
   }



my $current_line;

# This prints out the various program settings on the last page

sub  render_user_settings
   {
    $current_line = -2;
    
    set_font( "Courier-Bold", 12 );
    pline( "User settings:" );
    pline();
    set_font( "Courier", 12 );
    pline( "Alignment file: $input_filename" );
    pline( "Top group rows 1-", 1 + $#a_seqs, 
           ";  Bottom group rows ", 2 + $#a_seqs,
                                 "-", 1 + $#seqs );
    pline( "Property track display settings:" );
    foreach my $td ( @track_descrips[1..$#track_descrips] )
       { pline( "   ", td_name( $td ), ": ", $engl_states{td_state( $td )} ); }
    pline( "Conservation level: ", engl_conserved_func() );
    pline( ($show_property_diffs ? "F" : "Don't f"),
               "lag conserved residue property differences in main track",
               " with orange circles" );
    pline( "Grayscale function: ", engl_gamma_correction() );
    pline( "Darkness adjustment: ", darkness() );
   }

sub  pline
   {
    $current_line++;
    put_string( join( '', @_ ), left_limit(), 200-$current_line*11, [1.0] );
   }



# invoked by advance_cursor() when page is completed

sub  finish_page
   {
    page_header( $title );
    page_footer();
    set_font( "Courier", 11 );
    draw_track_labels();
    set_display_font();
    show_page();
   }

# also invoked by advance_cursor() when page is completed

sub  start_page
   {
    page_preamble( ++$page_number );
    set_landscape();
   }

# print stuff at bottom of each page

sub  page_footer
   {
    set_font( "Courier", 9 );
    put_string( "page $page_number", 
                 right_limit(), bottom_limit(), [ 1.0 ] );
    put_string( "produced " . timestamp() . " by CPDL v$cpdl_revision",
                 left_limit(), bottom_limit(), [ 1.0 ] );
   }

# this renders the track labels on each page.  currently
# this is invoked by finish_page()

sub  draw_track_labels
   {
    foreach my $c ( 0..(num_courses()-1) )
       {
        my $coff = $c * $course_height;
        foreach my $td ( @track_descrips )
           {
            put_string_vert_center( td_name( $td ), 20, 
                                    track_base( offset_base( td_track( $td ),
                                                             $coff ) ),
                                    &{(td_colorize_func( $td ))}( 10, 10 )
                                  )
           }
       }
   }
