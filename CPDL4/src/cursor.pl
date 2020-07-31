# File:         cursor.pl
# Language:     perl
# Authors:      Sean R. McCorkle, Kimberly M. Mayer, John Shanklin
#
# Description:  cursor data structure for CPDL
#
#               The cursor record keeps track of graphical position:
#               column on the page, course on the page, and position 
#               within the alignment.  
#
# Routines:
#
# advance( \&page_func );      # advance position, column, course and invoke
#                              # \&page_func() if page changes
# $val = curs_col( ... )       # optionally set, then return current column
# $val = curs_course( ... )    # optionally set, then return current course
# $val = curs_pos( ... )       # optionally set, then return current position
# 
# $Id: cursor.pl,v 4.0 2007/05/16 18:18:31 mccorkle Exp mccorkle $
#
my $num_columns = 80;          # these are appropriate for landscape US letter
my $num_courses = 1;           # only one course

%cursor = ( 'col'    => 0,     # horizontal column 
            'course' => 0,     # course 
            'pos'    => 0      # position in alignment 
          );

#
# advance( \&page_func );
# 
sub  advance
   {
    my $page_func = shift;
    my $col = curs_col() + 1;
    my $course = curs_course();
    my $pos = curs_pos() + 1;

    if ( $col >= $num_columns )  # if we run past right margin
       {
         $c = ($course + 1) % $num_courses;   # incr course 
         &{$page_func}() if ( $c == 0 && defined( $page_func ) ); # new page?
         curs_col( 0 );          # reset col 
         curs_course( $c );      # and set new course
       }
    else
       { curs_col( $col ); }     # increment column by 1 (course unchanged)
    curs_pos( $pos );            # always increment position in every case
   }


sub  curs_col
   { 
    my $val = shift;
    $cursor{'col'} = $val if ( defined( $val ) );
    return( $cursor{'col'} );   

   }

sub  curs_course
   { 
    my $val = shift;
    $cursor{'course'} = $val if ( defined( $val ) );
    return( $cursor{'course'} );   
   }

sub  curs_pos     
   { 
    my $val = shift;
    $cursor{'pos'} = $val if ( defined( $val ) );
    return( $cursor{'pos'} );   
   }

sub  print_cursor
   {
    print "% position (", curs_col(), " ", curs_course(), " ",curs_pos(), ")\n";
   }

sub  num_courses()
   { return( $num_courses ); }

1;
