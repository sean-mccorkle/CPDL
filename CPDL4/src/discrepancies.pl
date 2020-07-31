# File:         discrepancies.pl
# Language:     perl
# Authors:      Sean R. McCorkle, Kimberly M. Mayer, John Shanklin
#
# Description:  discrepancy detecting functions for CPDL
#
# Routines:
#
# discrepancies( $conservedf, $freqs_a, $freqs_b ) -> [ $dis_a, $dis_b ]
#          $dis_a and $dis_b are either '' or [ $fill, $intensity ] pairs
#
#               The function discrepancies() is the heart of CPDL.  It compares
#               frequency tables (see freqs.pl) of amino acids or properties 
#               from the two homologous protein groups at one position in the 
#               alignment, and flags any major differences between conserved 
#               members of one group and the other (conserved or not).  
#               It compares in BOTH directions and reports a pair of results, 
#               one from the comparison of the conserved member (if present) 
#               in group a (top group) vs group b (bottom group), and the other
#               from the comparision of the conserved member (if present) in 
#               group b vs group a.
#
#               Two attributes are reported for a discrepancy: the "fill"
#               and the "intensity".  The fill value is either 'part' or 
#               'full' and indicates whether or not the conserved member 
#               in the first group occurs anywhere in the 2nd group.  In
#               graphics output, 'full' is rendered as a filled triangle, 
#               'part' as an unfilled triangle.  
#
#               The intensity value is either 'medium' or 'high' ('low' 
#               disappeared somewhere in the in the development history :)  )
#               Intensity only has meaning for amino acid residues and for 
#               charges; all other properties always yield 'high' intensities 
#               in discrepancies.  For amino acids, a value of 'high' indicates
#               that the conserved member of the first group and the most 
#               frequent member of the 2nd group are from different homolog 
#               groups (such as 'D' and 'F' or 'P' and 'W') where a value of 
#               'medium' indicates they are from the same group (such as 'E'
#               and 'N').  For charges, 'high' indicates the conserved value
#               in the first group and most frequent in the 2nd group are 
#               opposite (+ and - or - and +), and 'medium' indicates that 
#               one of the two is neutral.  In graphics output, 'high' is
#               indicated by the color red and 'medium' by black.
#
#               Example output pairs from discrepancies()
#
#               [ '', '' ]                   blank; no discrepancies at all
#
#               [ ['part', 'medium'], '' ]   top-vs-bottom discrepancy only -
#                                            downward-pointing unfilled black
#                                            triangle
#
#               [ '', ['full', 'medium'] ]   bottom-vs-top discrepancy only -
#                                            upward-pointing filled black
#                                            triangle
#
#               [ ['full', 'high'], ['full', 'high'] ]
#                                            discrepancies seen both ways,
#                                            red hourglass: good candidate for
#                                            functional difference
#
#               Much effort went into the establishment and tuning of rules
#               for reporting discrepancies to try to ensure meaningful 
#               functional preditions in the test cases.
#
# $bool = differs( $c, @list )           # true iff $c doesn't occur in list
#
# $inten = intensity( $a, $b )           # 'medium' or 'high'
#
# $fill = fill( $mf, @list )             # 'part' or 'full' 
#
# $bool = is_discrepancy( [$dis_a, $dis_b ] )  # true iff not ['','']
#
# $bool = is_full_high( [$dis_a, $dis_b ] ) #true iff [[full,high],[full,high]]
#
# $str = dis_string( [ $dis_a, $dis_b ] )  # returns scheme-like string for 
#                                          # compatibility of debug output with
#                                          # older versions
#
# $Id: discrepancies.pl,v 4.0 2007/05/16 18:16:51 mccorkle Exp mccorkle $
#

sub  discrepancies 
   {
    my ( $conservedf, $freqs_a, $freqs_b ) = @_;
    #print "in discrepancies, [$conservedf]\n";
    #print_freq_table( $freqs_a );
    #print_freq_table( $freqs_b );
    my $maj_a = &{$conservedf}( $freqs_a );
    my $maj_b = &{$conservedf}( $freqs_b );
    my @mf_a = most_frequent( $freqs_a );
    my @mf_b = most_frequent( $freqs_b );
    #print "maj_a = [$maj_a]\n";
    #print "maj_b = [$maj_b]\n";
    #print "mf_a = [$mf_a]\n";
    #$print "mf_b = [$mf_b]\n";

    my ( $dis_a, $dis_b );

    if ( $maj_a && differs( $maj_a, @mf_b ) )
       { $dis_a = [ fill( $freqs_a, $freqs_b ), 
                    intensity( $mf_a[0], $mf_b[0] ) ]; 
       }
    else 
       { $dis_a = ''; }

    if ( $maj_b && differs( $maj_b, @mf_a ) )
       { $dis_b = [ fill( $freqs_b, $freqs_a ), 
                    intensity( $mf_b[0], $mf_a[0] ) ];
       }
    else 
       { $dis_b = ''; }

    #print "[";
    #print "[$$dis_a[0], $$dis_a[1]]"  if ( $dis_a );
    #print "[$$dis_b[0], $$dis_b[1]]"  if ( $dis_b );
    #print "]\n";
    #print dis_string( [$dis_a, $dis_b] ), "\n";
    return( [$dis_a, $dis_b] );
   }



# predicate: differs( $maj_1, @most_freq_2 )
#    compares majority member from group 1 ($maj_1) to most frequent
#    members of group 2 (@most_freq_2) to make sure its not
#    in that set
#
sub  differs
   {
    my $maj_1 = shift;
    return( grep( ($_ eq $maj_1), @_ ) ? '' : 1 );
   }

# determine the "intensity" of the discrepancy between two amino acids
# or properites. Returns 'medium' or 'high' - currently, this applies
# only to whether or not amino acid differences are in/not in the same
# homolog group or whether or not charge differences are positive/negative.
# all other comparisons yield a value of 'high'
#
sub  intensity
   {
    my ( $a, $b ) = @_;
    if ( is_aa( $a ) )
       { return( homolog_equiv( $a, $b ) ? 'medium' : 'high' ); }
    elsif ( is_charge( $a ) )
       { return( is_opposite_charge( $a, $b ) ? 'high' : 'medium' ); }
    else
       { return( 'high' ); }
   }

# fill( $freqs_a, $freqs_b ) returns a discrepancy fill value of 'full' or 
# 'part' depending on whether or not the conserved value(s) in $freqs_a occur
# anywhere in $freqs_b.  If they do, 'part' is returned, otherwise 'full' is 
# returned.  fill() is only invoked if there is a conserved majority in 
# group a, so it should be true that group a has only one or two members; 
# all members of a are conserved.

sub  fill
   {
    my ( $fr_a, $fr_b ) = @_;

    my $a_in_b = 0;  # set true if any member of a in b
    my @as = sorted_keys( $fr_a );
    ( $#as <= 1 ) || die "fill assertion fail: #as is $#as \n";
    my @bs = sorted_keys( $fr_b );
    foreach my $a ( @as )
       { $a_in_b++ if grep( ($_ eq $a), @bs ); }
    return( $a_in_b ? 'part' : 'full' );
   }

#  predicate is_discrepancy returns true if either of a discrepancy
#  pair is not false

sub  is_discrepancy
   {
    my $d = shift;
    return( ($$d[0] ne '') || ($$d[1] ne '') );
   }

sub  is_full_high
   {
    my ($dis_a,$dis_b) = @{(shift)};
    if ( $dis_a && $dis_b
          && $$dis_a[0] eq 'full' && $$dis_a[1] eq 'high'
          && $$dis_b[0] eq 'full' && $$dis_b[1] eq 'high' )
      { return( 1 ); }
    else
      { return( 0 ); }
   }

# $sc = score_prop_discrepancies( ($dis,$dis,...)  );

sub  score_prop_discrepancies
   {
    my $sc = 0;
    foreach $dpair ( @_ )
       {
        if ( $dpair )
           {
            foreach $dis ( @{$dpair} )
               {
                my $s = 0;
                if ( $dis )
                   {
                    my ($a,$b) = @{$dis};
                    $s = 1 if ( $a eq 'part' && $b eq 'medium' );
                    $s = 2 if ( $a eq 'part' && $b eq 'high' );
                    $s = 3 if ( $a eq 'full' && $b eq 'medium' );
                    $s = 4 if ( $a eq 'full' && $b eq 'high' );
                   }
                $sc = $s if ( $s > $sc );
               }
           }
       }
    return( $sc );
   }

sub dis_string
   {
    my ($dis_a,$dis_b) = @{(shift)};
    return( "(" . dis_st( $dis_a ) . " " . dis_st( $dis_b ) . ")" );
   }

sub  dis_st
   {
    my $dis = shift;
    return( $dis ? "($$dis[0] $$dis[1])"  : false( $dis ) )
   }

1;
