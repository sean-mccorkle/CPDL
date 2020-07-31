# File:         utils.pl
# Language:     perl
# Authors:      Sean R. McCorkle, Kimberly M. Mayer, John Shanklin
#
# Description:  miscellaneous routines for CPDL
#
# Routines:
#
# @residues = aa_codes()          # yields protein amino acid alphabet as list
# $residues = amino_acid_string()  #  "      "       "    "      "  as  string
# $boolean = is_aa( $res )         # true if $res is member of aa alphabet
# $boolewan = is_blank( $sym )     # true if $sym is '.', ' ' or 'X'
# $max = maximum( @list )          # max value from @list (numbers)
# $str = timestamp()               # time/date string for page output 
#
# $Id: utils.pl,v 4.0 2007/05/16 17:52:06 mccorkle Exp mccorkle $
#

my @aa_codes = ( 'G', 'P', 'A', 'V', 'L', 'I', 'M', 'C', 'F', 'Y', 
                 'W', 'H', 'K', 'R', 'Q', 'N', 'E', 'D', 'S', 'T' );

sub aa_codes
   { return( @aa_codes ); }

sub amino_acid_string 
   { return( join( '', @aa_codes ) ); }


my %aa_table = ();
map { $aa_table{$_}++; } @aa_codes;

sub  is_aa 
   { 
    my $v = $aa_table{(shift)};
    return( defined( $v ) ? $v : '' ); 
   }


# predicate to test if elment is blank (accepts residues or
# property arguments).  blank means vacancy in the alignment

sub  is_blank
   {
    my $x = shift;
    return( $x eq ' ' || $x eq '.' || $x eq 'X' );
   }

# maximum( @list ) returns the numerically largest member
# of @list

sub  maximum
   {
    my $max = 0;
    foreach my $m ( @_ )
       {  $max = $m if ( $m > $max ); }
    return( $max );
   }

#
# return a formated time & date string indicating current time
#
sub timestamp
   { 
    my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime();
    my $month = ("Jan","Feb","Mar","Apr","May","Jun",
                 "Jul","Aug","Sep","Oct","Nov","Dec" )[$mon];
    my $dow = ("Sun","Mon","Tue","Wed","Thu","Fri","Sat")[$wday];
    sprintf( "%02d:%02d:%02d  %d %s %4d (%s)", 
             $hour, $min,$sec, $mday, $month, $year+1900, $dow );
   }

# to mimic scheme output, convert '' or 0 to #f
#   this is a really terrible name and should be changed

sub false
   {
    my $x = shift;
    return( "#t" ) if ( $x eq "1" );
    return( $x ? $x : "#f" );
   }

1;
