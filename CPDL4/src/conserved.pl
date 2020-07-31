# File:         conserved.pl
# Language:     perl
# Authors:      Sean R. McCorkle, Kimberly M. Mayer, John Shanklin
#
# Description:  conservation functions for CPDL
#
#               These are different functions to implement different 
#               definitions of conservation (selectable by the user).
#               The global $conservedf references one of these functions,
#               and is invoked by the function discrepancies(). 
#               New definitions of conservation can be implemented by simply
#               adding new functions which can be assigned to $conservedf
#               at program start.
#
#               Note that, unlike the function most_frequent() (freqs.pl),
#               which returns a list, these functions return a single member 
#               only (or '')
#
# Routines:
#
# $m = unanimous( $ft )          # returns the most frequent member if and 
#                                  only if there are no others, otherwise 
#                                  returns ''
# $m = unanimous_minus_1( $ft )  # returns the most frequent member if there 
#                                  are no others, or if the total is more than 
#                                  2 and there is only one other occurance of 
#                                  another member, otherwise returns ''
#
# set_conserved_func( 'unanimous' | 'unanimous_minus_1' ) # sets one of the two
#                                                           to current
# $func = conserved_func()       # return reference to current conserved_func
# $str = engl_conserved_func()   # return printable string (for output) 
#                                  indicating current function
#
# $Id: conserved.pl,v 4.0 2007/05/16 18:08:16 mccorkle Exp mccorkle $
#

sub  unanimous
   {
    my $freqs = shift;

    my $n = total_counts( $freqs );
    return( '' ) if ( $n < 1 );
    my ($c) = most_frequent( $freqs );
    if ( is_blank( $c ) )
       { return( '' ); }
    else
       { 
         my $v = counts( $freqs, $c );
         return( ( $v == $n ) ? $c : '' ); 
       }
   }


sub  unanimous_minus_1
   {
    my $freqs = shift;

    my $n = total_counts( $freqs );
    return( '' ) if ( $n < 1 );
    my ($c) = most_frequent( $freqs );
    if ( is_blank( $c ) )
       { return( '' ); }
    else
       { 
         my $v = counts( $freqs, $c );
         if ( $n <= 2 )                            # if 2 or 1 total,
            { return( ( $v == $n ) ? $c : '' ); }  # must be unanimous
         else
            { return( ( $v >= $n - 1 ) ? $c : '' ); }
       }
   }

my $conserved_f = \&unanimous_minus_1;

# set_conserved_func( 'unanimous' | 'unanimous_minus_1' )

sub  set_conserved_func
   {
    my $f = shift;
    if ( $f eq 'unanimous' )
       { $conserved_f = \&unanimous; }
    elsif ( $f eq 'unanimous_minus_1' )
       { $conserved_f = \&unanimous_minus_1; }
    else 
       { die "Bad value for set_conserved_func: $f\n"; }
   }

# conserved_func() - return reference to current conserved_func

sub  conserved_func
   {  return( $conserved_f ); }

#
# engl_conserved_func() returns explanitory string corresponding to
# current conserved function reference
#
sub engl_conserved_func
   {
    return( "all" )                if ( $conserved_f == \&unanimous );
    return( "all or all but one" ) if ( $conserved_f == \&unanimous_minus_1 );
    return( "none" );
   }
1;

