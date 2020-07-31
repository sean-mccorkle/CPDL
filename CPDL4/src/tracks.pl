# File:         tracks.pl
# Language:     perl
# Authors:      Sean R. McCorkle, Kimberly M. Mayer, John Shanklin
#
# Description:  track data structure for CPDL
#
#               Tracks represent horizontal arrays of empty cells which get 
#               filled with symbols by put_symbol (cpdlgraf.pl).  The graphics 
#               call to put_symbol() includes a track reference, a row and a 
#               column - the track data structure defined here includes data to
#               map the position to an absolute position (postscript pixels).
#               Rows are numbered 1, 2, ... going upwards (group A symbols) and
#               -1, -2, -3,... going downwards (group B symbols).  The zero or
#               center row (which doesn't necessarily have the same pixel 
#               height as the rest of the rows) is for displaying discrepancy 
#               symbols (triangles, orange circles, etc)
#
# Routines:
#
#  $tr = make_track( $base, $offset, $delta, $height, $depth )
#            - create a new track record and return a reference to it
#    $base   - y coordinate of the baseline
#    $offset - offset from base for the first row (1/2 height of zero cell)
#    $delta  - y distance between rows (above and below zero row)
#    $height - number of cells above base (for stacking)
#    $depth  - number of cells below base (for stacking)
#
#  $base   = track_base( $tr )    # these return the various track record 
#  $offset = track_offset( $tr )  #   quantities listed above
#  $delta  = track_delta( $tr )
#  $height = track_height( $tr )
#  $depth  = track_depth( $tr )
#  $vtr = offset_base( $tr, $offset )  # generates a new track, offset 
#                                      # verticaly from $tr by $offset
#  $vspan = track_vert_span( $tr )     # vertical size of track (used for
#                                      # layout purposes)
#
# $Id: tracks.pl,v 4.0 2007/05/16 17:32:43 mccorkle Exp mccorkle $
#

sub  make_track
   {
    my ( $base, $offset, $delta, $height, $depth ) = @_;
    my $tr = {};
    $$tr{'base'} = $base;
    $$tr{'offset'} = $offset;
    $$tr{'delta'} = $delta;
    $$tr{'height'} = $height;
    $$tr{'depth'} = $depth;
    return( $tr );
   }


sub  track_base   { return( ${(shift)}{'base'} ); }

sub  track_offset { return( ${(shift)}{'offset'} ); }

sub  track_delta  { return( ${(shift)}{'delta'} ); }

sub  track_height { return( ${(shift)}{'height'} ); }

sub  track_depth  { return( ${(shift)}{'depth'} ); }

sub  offset_base 
   {
    my ($tr,$off) = @_;
    return( make_track(  track_base( $tr ) - $off,
                         track_offset( $tr ),
                         track_delta( $tr ),
                         track_height( $tr ),
                         track_depth( $tr ) ) );
   }

sub  track_vert_span
   {
    my $tr = shift;
    return( track_delta( $tr ) * track_height( $tr ) +
            track_delta( $tr ) * track_depth( $tr ) +
            2 * track_offset( $tr ) );
   }

1;
