# File:         props.pl
# Language:     perl
# Authors:      Sean R. McCorkle, Kimberly M. Mayer, John Shanklin
#
# Description:  residue propery functions for CPDL
#
# Routines:
# 
# $prop_ft = prop_frequencies( $pfunc, $res_ft) 
#               -  takes a residue frequency table and returns a frequency
#                  table (seq freqs.pl) of properties.   property is specified
#                  by passing a referenct to one of the following functions:
#
# These return residue properties of amino acids
#
# $prop = hydro_prop( $aa )     # 'hydrophobic' | 'hydrophilic' | ' '
# $prop = residue_size( $aa )   # 'tiny' | 'small' | 'large' | ' '
# $prop = homolog_group( $aa )  # 'homolog1' | 'homolog2' ... | 'homolog6'|' '
# $prop = residue_charge( $aa ) # 'positive' | 'negative' | 'neutral' | ' '
# $prop = polar_prop( $aa )     # 'polar' | 'nonpolar' | ' '
# $prop = aromatic_prop( $aa )  # 'aromatic' | 'nonaromatic' | ' '
#
#  These are predicates (return boolean yes/no)
#
#  $b = homolog_equiv( $h1, $h2 )       # same homolog groups?
#  $b = is_charge( $prop )              # is this property a charge?
#  $b = is_opposite_charge( $c1, $c2 )  # is one charge + and the other - ?
#
# $Id: props.pl,v 4.0 2007/05/16 18:06:03 mccorkle Exp mccorkle $
#

sub  prop_frequencies
   {
    my ( $prop_func, $freqs ) = @_;

    my $pf = make_freq_table();    
    foreach $c ( keys ( %{$$freqs{'counts'}} ) )
       {
        #print "$c: ", ${$$freqs{'counts'}}{$c}," -> ",
        #     &$prop_func( $c ), "\n";
        accum_freq_table( $pf, &$prop_func( $c ), ${$$freqs{'counts'}}{$c} );
       }
    return( $pf );
   }


my %hydro_p = ( 'C' => 'hydrophobic',
                'A' => 'hydrophobic',
                'T' => 'hydrophobic',
                'I' => 'hydrophobic',
                'V' => 'hydrophobic',
                'L' => 'hydrophobic',
                'M' => 'hydrophobic',
                'F' => 'hydrophobic',
                'Y' => 'hydrophobic',
                'W' => 'hydrophobic',
                'H' => 'hydrophobic',
                'K' => 'hydrophobic',

                'P' => 'hydrophilic',
                'S' => 'hydrophilic',
                'D' => 'hydrophilic',
                'N' => 'hydrophilic',
                'E' => 'hydrophilic',
                'Q' => 'hydrophilic',
                'R' => 'hydrophilic',

                'G' => ' ',
                '.' => ' ',
                'X' => ' ',
                ' ' => ' ',
               );

sub  hydro_prop
   {
    my $aa = shift;

    if ( $hydro_p{$aa} )
       { return( $hydro_p{$aa} ); }
    else
       { die "hydro_prop: bad residue value input: \"$aa\"\n"; }
      
   }

my %res_size_p = ( 'A' => 'tiny',
                   'G' => 'tiny',
                   'C' => 'tiny',
                   'S' => 'tiny',

                   'P' => 'small',
                   'V' => 'small',
                   'T' => 'small',
                   'D' => 'small',
                   'N' => 'small',

                   'I' => 'large',
                   'L' => 'large',
                   'M' => 'large',
                   'F' => 'large',
                   'Y' => 'large',
                   'W' => 'large',
                   'H' => 'large',
                   'K' => 'large',
                   'R' => 'large',
                   'E' => 'large',
                   'Q' => 'large',

                   '.' => ' ',
                   'X' => ' ',
                   ' ' => ' ',
                  );


sub  residue_size
   {
    my $aa = shift;

    if ( $res_size_p{$aa} )
       { return( $res_size_p{$aa} ); }
    else
       { die "residue size: bad residue value input: \"$aa\"\n"; }
      
   }


my %homolog_group_p = ( 'A' => 'homolog1',
                        'S' => 'homolog1',
                        'T' => 'homolog1',
                        'P' => 'homolog1',
                        'G' => 'homolog1',

                        'N' => 'homolog2',
                        'D' => 'homolog2',
                        'B' => 'homolog2',
                        'E' => 'homolog2',
                        'Q' => 'homolog2',
                        'Z' => 'homolog2',

                        'H' => 'homolog3',
                        'R' => 'homolog3',
                        'K' => 'homolog3',

                        'M' => 'homolog4',
                        'L' => 'homolog4',
                        'I' => 'homolog4',
                        'V' => 'homolog4',

                        'F' => 'homolog5',
                        'Y' => 'homolog5',
                        'W' => 'homolog5',

                        'C' => 'homolog6',     # for the sake of completion
                        
                        '.' => ' ',
                        'X' => ' ',
                        ' ' => ' ',
                      );

sub  homolog_group
   {
    my $aa = shift;

    if ( $homolog_group_p{$aa} )
       { return( $homolog_group_p{$aa} ); }
    else
       { die "homolog group: bad residue value input: \"$aa\"\n"; }
      
   }

# returns true if the two amino acid arguments are in the same
# homolog group, otherwise false.

sub  homolog_equiv
   {
    my ($a,$b) = @_;
    return( homolog_group( $a ) eq homolog_group( $b ) );
   }



my %residue_charge_p = ( 
                        'H' => 'positive',
                        'K' => 'positive',
                        'R' => 'positive',

                        'D' => 'negative',
                        'E' => 'negative',

                        'N' => 'neutral',
                        'Q' => 'neutral',
                        'S' => 'neutral',
                        'C' => 'neutral',
                        'G' => 'neutral',
                        'A' => 'neutral',
                        'T' => 'neutral',
                        'P' => 'neutral',
                        'F' => 'neutral',
                        'Y' => 'neutral',
                        'W' => 'neutral',
                        'V' => 'neutral',
                        'L' => 'neutral',
                        'I' => 'neutral',
                        'M' => 'neutral',

                        '.' => ' ',
                        'X' => ' ',
                        ' ' => ' ',
                      );

sub  residue_charge
   {
    my $aa = shift;

    if ( $residue_charge_p{$aa} )
       { return( $residue_charge_p{$aa} ); }
    else
       { die "residue_charge: bad residue value input: \"$aa\"\n"; }
      
   }

%residue_charge_vals = make_val_hash( \%residue_charge_p );

# returns true if argument is 'positive', 'negative', or 'neutral',
# false otherwise

sub  is_charge
   {
    my $c = $residue_charge_vals{(shift)};
    return( defined( $c ) );
   }

# returns true if and only if one of the two arguments is 'positive'
# and the other is 'negative', otherwise returns false

sub  is_opposite_charge
   {
    my ($a,$b) = @_;
    return( 1 ) if ( $a eq 'positive' && $b eq 'negative' );
    return( 1 ) if ( $b eq 'positive' && $a eq 'negative' );
    return( 0 );
   }


my %polar_prop_p = ( 
                     'C' => 'polar',
                     'S' => 'polar',
                     'T' => 'polar',
                     'N' => 'polar',
                     'D' => 'polar',
                     'Y' => 'polar',
                     'W' => 'polar',
                     'H' => 'polar',
                     'K' => 'polar',
                     'R' => 'polar',
                     'E' => 'polar',
                     'Q' => 'polar',

                     'P' => 'nonpolar',
                     'A' => 'nonpolar',
                     'G' => 'nonpolar',
                     'V' => 'nonpolar',
                     'I' => 'nonpolar',
                     'L' => 'nonpolar',
                     'M' => 'nonpolar',
                     'F' => 'nonpolar',

                     '.' => ' ',
                     'X' => ' ',
                     ' ' => ' ',
                    );

sub  polar_prop
   {
    my $aa = shift;

    if ( $polar_prop_p{$aa} )
       { return( $polar_prop_p{$aa} ); }
    else
       { die "polar_prop: bad residue value input: \"$aa\"\n"; }
      
   }

my %aromatic_prop_p = ( 
                       'F' => 'aromatic',
                       'Y' => 'aromatic',
                       'W' => 'aromatic',
                       'H' => 'aromatic',
 
                       'I' => 'nonaromatic',
                       'L' => 'nonaromatic',
                       'V' => 'nonaromatic',
                       'M' => 'nonaromatic',
                       'C' => 'nonaromatic',
                       'A' => 'nonaromatic',
                       'G' => 'nonaromatic',
                       'P' => 'nonaromatic',
                       'S' => 'nonaromatic',
                       'T' => 'nonaromatic',
                       'D' => 'nonaromatic',
                       'N' => 'nonaromatic',
                       'R' => 'nonaromatic',
                       'K' => 'nonaromatic',
                       'E' => 'nonaromatic',
                       'Q' => 'nonaromatic',

                       '.' => ' ',
                       'X' => ' ',
                       ' ' => ' ',
                      );

sub  aromatic_prop
   {
    my $aa = shift;

    if ( $aromatic_prop_p{$aa} )
       { return( $aromatic_prop_p{$aa} ); }
    else
       { die "aromatic_prop: bad residue value input: \"$aa\"\n"; }
      
   }

# Make hashes of the values of the above hashes to be able to quickly
# identify the type of property based on the value.  

sub  make_val_hash
   {
    my $pt = shift;
    my %res = ();
    map { $res{$_}++ if ( $_ ne ' ' ); }  values( %{$pt} );
    return( %res );
   }


1;
