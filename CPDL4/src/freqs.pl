# File:         freqs.pl
# Language:     perl
# Authors:      Sean R. McCorkle, Kimberly M. Mayer, John Shanklin
#
# Description:  frequence tables for CPDL 
#
#               these are histograms of symbol <-> count where symbols are 
#               either amino acid residues (A, P, I, L, .. etc) or residue 
#               properties (size, hydrophobicity etc) returned by the various
#               property functions in props.pl
#
# Routines 
#   
# $ft = make_freq_table()           # create new table, return reference to it
# accum_freq_table( $ft, $c, $incr )  # add incr counts  for res/prop $c
# $n = counts( $ft, $c )              # return current counts for res/prop $c
# $tot = total_counts( $ft )          # return total counts in table
# ( k1, k2, k3, ...) = sorted_keys( $ft )      # k's are residues or properties
# ( [k1,n1], [k2,n2], ...) = sorted_pairs( $ft ) # n's are associated counts
# ( $k1, $k2, ... ) = most_frequent( $ft )       # most freq res/props
# print_freq_table( $ft )                        # for debugging
#
# $Id: freqs.pl,v 4.0 2007/05/16 17:55:25 mccorkle Exp mccorkle $
#

sub  make_freq_table
   {
    my $ft = { 'total' => 0,        # total number of counts in the histogram
               'counts' => {}       # reference to histogram of counts
             };
    return ( $ft );
   }

sub  counts
   {
    my ( $ft, $c ) = @_;
    return( ${$$ft{'counts'}}{$c} );
   }

sub  total_counts
   { return( ${(shift)}{'total'} ); }


# accum_freq_table( $ft, $c ) or accum_freq_table( $ft, $c, $incr )
#
# add $incr more counts for key $c in table $f.
#  ($incr defaults to 1 if not specified.)

sub  accum_freq_table
   {
    my ( $ft, $c, $incr ) = @_;

    $incr = 1 if ( ! defined( $incr ) );
    $incr = 1 if ( $incr < 1 );
    (${$$ft{'counts'}}{$c}) += $incr;
    $$ft{'total'} += $incr;
   }

# returns a list of ( key1, key2, ... ) pairs sorted by decreasing
#  val (lexically by key in the case of equal vals )

sub  sorted_keys
   {
    my $ft = shift;
    
    return( sort { ${$$ft{'counts'}}{$b} <=> ${$$ft{'counts'}}{$a}
                      || sconv($a) cmp sconv($b); }
                 keys ( %{$$ft{'counts'}} ) 
           );
   }

# this is to ensure that "blanks" occur after other symbols/residues
# of equal frequency
#
sub  sconv
   {
    my $x = shift;
    return( is_blank( $x ) ? 'zzzzzzzzzzz' : $x );
   }

# returns a list of ( [key,val], [key,val] ) pairs sorted by decreasing
#  val (lexically by key in the case of equal vals )

sub  sorted_pairs
   {
    my $ft = shift;
    return( map(  [ $_, ${$$ft{'counts'}}{$_} ], sorted_keys( $ft ) ) );
   }

# ($a,$b,...) = most_frequent( $ft )
#  returns a *list* of the most frequent because two or more may
#  be tied for the first place.
#
sub  most_frequent
   {
    my $ft = shift;
    if ( total_counts($ft) > 0 )
       {
        my @ps = sorted_pairs( $ft );
        my ( $c1, $n1 ) = @{shift( @ps )};
        my @most = ( $c1 );
        foreach my $p ( @ps )
           {
            last if ( $$p[1] < $n1 );
            push( @most, $$p[0] );
           }
        return( @most );
       }
    else
       { return( '' ); }
   }

sub  print_freq_table
   {
    my $ft = shift;
    print total_counts( $ft ), "\n";
    foreach my $p ( sorted_pairs( $ft ) )
       { print "'", $$p[0], "': ", $$p[1], "\n"; }
   }

1;

