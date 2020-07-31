# File:         key_table.pl
# Language:     perl
# Authors:      Sean R. McCorkle, Kimberly M. Mayer, John Shanklin
#
# Description:  Render key_table for CPDL
#
# $Id: key_table.pl,v 4.0 2007/05/16 18:21:56 mccorkle Exp mccorkle $
#


my $left_label_col = 5;
my $key_tr;
my $h        = 2.5;


sub  render_key_table
   {
    $key_tr = make_track( 300, 6, 12, 30, 10 );
            #  make_track( 500, 6, 12, 30, 10 );   # for standalone
    my $size_color     = size_color();
    my $hydro_color    = hydro_color();
    my $charge_color   = charge_color();
    my $polarity_color = polarity_color();

    left_limit( 130 );   # kludge

    my $c = 5;
    my $last_hgroup = '';
    foreach my $res ( sort hgless ( aa_codes() ) )
       {
        my $gr = homolog_group( $res );
        $c++;
        $c++ if ( $gr ne $last_hgroup );
        place_symbol( $key_tr, $c, 20, $res, [ 1.0 ] );
        place_symbol( $key_tr, $c, 18, residue_size( $res ), $size_color);
        place_symbol( $key_tr, $c, 16, hydro_prop( $res ), $hydro_color);
        place_symbol( $key_tr, $c, 14, residue_charge( $res ), $charge_color);
        place_symbol( $key_tr, $c, 12, polar_prop( $res ), $polarity_color );
        place_symbol( $key_tr, $c, 10, aromatic_prop( $res ), [ 1.0 ] );
        $last_hgroup = $gr;
       }

    set_font( "Courier", 12 );
    left_label( "residue",        20 );
    left_label( "size",           18 );
    left_label( "hydrophobicity", 16 );
    left_label( "charge",         14 );
    left_label( "polarity",       12 );
    left_label( "aromaticity",    10 );

    explain( 18, 35, 'large', "large", $size_color );
    explain( 18, 42, 'small', "small", $size_color );
    explain( 18, 49, 'tiny',  "tiny",  $size_color );
  
    explain( 16, 35, 'hydrophobic', "hydrophobic",  $hydro_color );
    explain( 16, 46, 'hydrophilic', "hydrophilic",  $hydro_color );
  
    explain( 14, 35, 'positive',  "positive", $charge_color );
    explain( 14, 43, 'neutral',   "neutral",  $charge_color );
    explain( 14, 51, 'negative',  "negative", $charge_color );

    explain( 12, 35, 'polar',     "polar",     $polarity_color );
    explain( 12, 43, 'nonpolar',  "nonpolar",  $polarity_color );

    explain( 10, 35, 'aromatic',    "aromatic",      [ 1.0 ] );
    explain( 10, 43, 'nonaromatic', "non-aromatic",  [ 1.0 ] );
   }



sub  left_label
   {
    my ($s,$row) = @_;

    put_string_right( $s, column_to_x( $left_label_col ),
                          row_to_y( $key_tr, $row ) + $h, [ 1.0 ] );
   }

sub  explain
   {
    my ($row, $col, $prop, $exp, $color) = @_;

    place_symbol( $key_tr, $col, $row, $prop, $color);
    put_string( $exp, column_to_x( $col + 1),
                      row_to_y( $key_tr, $row ) + $h, [ 1.0 ] );
   }


#
# for sorting 1st by homolog group, then by residue alphabetically
#

sub  hgless
   {
    my $gr_a = homolog_group( $a );
    my $gr_b = homolog_group( $b );

    if ( $gr_a eq $gr_b )
       { return( $a cmp $b ); }
    else
       { return( $gr_a cmp $gr_b ); }
   }


1;







