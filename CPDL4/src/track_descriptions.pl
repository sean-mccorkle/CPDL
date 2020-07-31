# File:         track_descriptions.pl
# Language:     perl
# Authors:      Sean R. McCorkle, Kimberly M. Mayer, John Shanklin
#
# Description:  track data structure for CPDL
#
#               The track_description record structure incorporates a bunch of 
#               data needed to render the track on the page: labels, colors,
#               display settings, etc and the track record itself (tracks.pl)
#               and also asscociates a propery function (props.pl) with each
#               track.  The main program maintains a "master list" of track 
#               descriptions.
#
# Routines:
#
# $td = make_track_description( $name,$state,$prop_func,$track,$colorize_func )
#            - create a new track_description and return a reference to it
#
#         $name      - track name (appears as label on output)
#     
#         $state     - one of 
#                      'gone'  - track not there, takes no vertical space
#                      'blank' - track not shown but takes vertical space
#                      'on'    - track completely on - all positions shown
#                      'discrep' - positions only shown if there's a 
#                                        discrepancy between the res/properties
#                                        in the track
#                      'main_discrep' - positions only shown if there's a 
#                                       discrepancy between the residues
#                                       in the main track
#                      'main_full_high' - positions only shown if there's a 
#                                         discrepancy in the main track which
#                                         is full and high in both directions
#                                         (i.e. a "red hourglass")
#
#         $prop_func - reference to prop($aa) func from props.pl, 
#                       i.e. \&hydro_prop, \&residue_size, etc. 
#                      used to convert residue frequencies to frequencies
#                      of the appropriate property
#
#         $track     - reference to associated graphics track (tracks.pl)
#
#         $colorize_func -  reference to a greyscale or colorize function
#                           which takes two arguments (f, n) and returns
#                           a grayscale or color reference suitable for
#                           submitting to set_color().  f and n are 
#                           numerical frequency and normalization of a 
#                           residue or property - see cpdlgraf.pl for more
# 
# These routines return values/references for the various parts described
# above:
#
# $name = td_name( $td )    
# $state = td_state( $td )         
# $prop_f = td_prop_func( $td )
# $track = td_track( $td )      
# $colorf = td_colorize_func( $td )  
#
# $Id: track_descriptions.pl,v 4.0 2007/05/16 17:48:08 mccorkle Exp mccorkle $
#

sub  make_track_description
   {
    my ( $name, $state, $prop_func, $track, $colorize_func ) = @_;

    my $td = {};
    $$td{'name'} = $name;            # track name
    $$td{'state'} = $state;          # visibility state
    $$td{'prop_func'} = $prop_func;  # this function is invoked on residues
    $$td{'track'} = $track;          # reference to track structure
    $$td{'colorize_func'} = $colorize_func;   # coloring/greyscale function
    return( $td );    
   }


sub  td_name           { return( ${(shift)}{'name'} ); }

sub  td_state          { return( ${(shift)}{'state'} ); }

sub  td_prop_func      { return( ${(shift)}{'prop_func'} ); }

sub  td_track          { return( ${(shift)}{'track'} ); }

sub  td_colorize_func  { return( ${(shift)}{'colorize_func'} ); }

1;

