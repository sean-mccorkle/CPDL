<? 
// Run CPDL
// $Id: run_cpdl.php,v 3.3 2005/06/20 20:09:28 mccorkle Exp mccorkle $

$gs = "/usr/bin/gs";
$pstopdf = "/usr/bin/ps2pdf";
$cmscan = "./cmscan";
$alntrans = "./aln2cal";
$msftrans = "./msf2cal";
$cpdl = "./cpdl.pl";
$conv = "/usr/bin/convert";
$log_file = "Logs/activity_log";
//$image_dir = "Images"; 
$image_dir = "/tmp"; 
$logging  = 1;
$log = "";

$user_file_errmsg = array ( 1 => 'File exceeded max upload limit',
                            2 => 'File exceeded 1 Mb size limit',
                            3 => 'File only partially uploaded',
                            4 => 'No file uploaded' );

function bailout( $msg )
   {
    global $log, $logging;

    print "<BODY BGCOLOR=white>\n";
    print "<FONT COLOR=red>Error: $msg</FONT><BR>\n";
    if ( $logging )
       {
        fwrite( $log, "   **** bailout: $msg ***\n" );
        fclose( $log );
       }
    exit;
   }

function get_first_line( $file )
   {
    if ( ! ($f = fopen( $file, "r" )) )
        bailout( "Serious: unable to read from alignment file \"$file\"" );

    do {
        $line = fgets( $f, 1024 );
        } while ( (!feof( $f )) && 
                   ( ! ereg( "(CLUSTAL|PileUp|MSF:)", $line ) ) && 
                   (trim( $line ) == "" || ereg( "(\\^@)+", $line )
                               || ereg( "(HTML|META|BODY|PRE)", $line ) ) );

    if ( feof( $f ) )
        bailout( "Bad alignment file; encountered EOF looking for 1st nonblank line" );
    fclose( $f );
    return( $line );
   }

//
// returns a count of the number of rows (proteins) in the CPDL input alignment (cal) file.
// At this point, this is mostly for detecting if there was some sort of problem with
// the user input file that fouled up the cal translator.
// (In principle, this could be expanded in the future to verify the format as well)

function count_rows( $file )
   {
    if ( ! ($f = fopen( $file, "r" )) )
        bailout( "Serious: unable to read from scheme file \"$file\"" );
    $last_line = "";
    $n = 0;
    while ( ! feof( $f ) )
       {
        $line = fgets( $f ); 
        if ( $line != "" )
           {
            $last_line = trim( $line );
            $n++;
           }
       }
    fclose( $f );
    return( $n );
   }

function precheck( $file, $exe="" )
   {
    global $logging, $log;

    if ( $logging )
       fwrite( $log, "prcheck $file\n" );
    if ( ! file_exists( $file ) )
        bailout( "configuration precheck failure: file \"$file\" does not exist\n" );

    if ( ! is_readable( $file ) )
        bailout( "configuration precheck failure: file \"$file\" is not readable\n" );

    if ( $exe == "x" && ! is_executable( $file ) )
        bailout( "configuration precheck failure: file \"$file\" is not executable\n" );
   }

function configuration_prechecks()
   {
    global $logging, $log, $gs, $pstopdf, $conv, $cmscan, $alntrans, $msftrans, $cpdl;

    if ( $logging )
       fwrite( $log,  "oh hai dis is de prechekcs!\n" );
    precheck( "/bin/cat", "x");
    precheck( $gs, "x" );
    precheck( $pstopdf, "x" );
    precheck( $conv, "x" );
    precheck( $cmscan, "x" );
    precheck( $alntrans, "x" );
    precheck( $msftrans, "x" );
    precheck( $cpdl, "x" );
 
    precheck( "utils.pl" );   // these are used by cpdl.pl
    precheck( "tracks.pl" );
    precheck( "track_descriptions.pl" );
    precheck( "props.pl" );
    precheck( "conserved.pl" );
    precheck( "discrepancies.pl" );
    precheck( "cursor.pl" );
    precheck( "cpdlgraf.pl" );
    precheck( "key_table.pl" );

   }

                             //////////  
                             // Main //
                             //////////  

$userfile          = $_FILES['userfile']['tmp_name'];
$userfile_err      = $_FILES['userfile']['error'];
$remote_file       = $_FILES['userfile']['name'];
$action            = $_POST['action'];
$group_a_max       = $_POST['group_a_max'];
$plot_title        = $_POST['plot_title'];
$gs_function       = $_POST['gs_function'];
$conserved_value   = $_POST['conserved_value'];
$size_tr_stat      = $_POST['size_tr_stat'];
$hydro_tr_stat     = $_POST['hydro_tr_stat'];
$charge_tr_stat    = $_POST['charge_tr_stat'];
$polarity_tr_stat  = $_POST['polarity_tr_stat'];
$aromatic_tr_stat  = $_POST['aromatic_tr_stat'];
$show_prop_diffs   = $_POST['show_prop_diffs'];
$show_key          = $_POST['show_key'];
$darkness          = $_POST['darkness'];
$output_format     = $_POST['output_format'];
$jpeg_rez          = $_POST['jpeg_rez'];

if ( $logging )
  {
   $log = fopen( $log_file, 'a' );
   $log = fopen( $log_file, 'a' );
   fwrite( $log, "Begin " . date( "D M j G:i:s T Y" ) . "\n" );
  }

configuration_prechecks();   // make sure everything we need is in the right place

if ( $userfile_err > 0 )
    bailout( "Alignment file problem: " . $user_file_errmsg[$userfile_err] );

if ( $userfile == "none" )
    bailout( "No alignment file specified" );

$userqfile = tempnam( "/tmp", "cpdl_q" );
$usertfile = tempnam( "/tmp", "cpdl_t" );

// Since we're not (yet) certain how to ensure proper text conversion 
// (^M -> newline, etc) in the handoff between the users browser
// and apache, we go through some contortions here.  Also, some 
// browsers (IE on MacOSX) seem to enclose text in some garbage,
// so we cat -v to get the control chars to show up

system( "/bin/cat -v $userfile >$userqfile" );

// note that cmscan expects the output of cat -v

system( "./cmscan $userqfile >$usertfile" );
 

if ( $logging )
  {
   fwrite( $log, "   userfile [$userfile]\n" );
   fwrite( $log, "   userqfile [$userqfile]\n" ); 
   fwrite( $log, "   usertfile [$usertfile]\n" ); 
   fwrite( $log, "   group_a_max [$group_a_max]\n" );
   fwrite( $log, "   plot_title  [$plot_title]\n" );
   $usercopyfile = tempnam( "/tmp", "cpdl_ucopy" );
   fwrite( $log, "   usercopyfile [$usercopyfile]\n" );
   if ( ! copy( $usertfile, $usercopyfile ) )
       fwrite( $log, 
        "   ***** error couldn't copy $userfile -> $usercopyfile\n" );
   else
       chmod( $usercopyfile, 0644 );
  }

if ( $plot_title == "" && $remote_file != "" )
    $plot_title = $remote_file;

$opts = "-t \"$plot_title\"";
$opts .= " -g $gs_function";
$opts .= " -C $conserved_value";
$opts .= " -s $size_tr_stat";
$opts .= " -w $hydro_tr_stat";
$opts .= " -c $charge_tr_stat";
$opts .= " -p $polarity_tr_stat";
$opts .= " -a $aromatic_tr_stat";

if ( $show_prop_diffs != "on" )
    $opts .= " -P";
if ( $show_key != "on" )
    $opts .= " -K";
if ( $remote_file != "" )
    $opts .= " -I '$remote_file'";

$darkness = trim( $darkness );
if ( ! ereg( "^[0-9]?\.[0-9]+$", $darkness ) )
    bailout( "darkness adjustment \"$darkness\" must be a number between 0.0 & 1.0" );

$opts .= " -d $darkness";

$group_a_max = trim( $group_a_max );
if ( ! ereg( "^[0-9]+$", $group_a_max ) )
    bailout( "Invalid top group row \"$group_a_max\"; must be a number" );

$first_line = get_first_line( $usertfile );
if ( $logging )
    fwrite( $log, "   first line is [$first_line]\n" );

$calfile = tempnam( "/tmp", "cpdl_cal" );
$psfile  = tempnam( "/tmp", "cpdl_ps" );
$pdffile = tempnam( "/tmp", "cpdl_pdf" );
$jpgfile = tempnam( "/tmp", "cpdl_jpg" );

if ( $logging )
    fwrite( $log, "   scheme file is $calfile\n   ps file is $psfile\n" );

if ( ereg( "CLUSTAL", $first_line ) )
   {
    if ( $logging )
        fwrite( $log, "   this is a CLUSTAL file\n" );
    system( "$alntrans $usertfile >$calfile" );
   }
elseif ( ereg( "PileUp", $first_line ) || ereg( "MSF:", $first_line ) )
   {
    if ( $logging )
       fwrite( $log, "   this is an MSF file\n" );
    system( "$msftrans $usertfile >$calfile" );
   }
else
    bailout( "Unknown alignment file type; doesn't seem to be CLUSTAL or ALN" );

$num_rows = count_rows( $calfile );
if ( $logging )
   fwrite( $log, "   count_rows: $num_rows\n" );
    
if (  $num_rows <= 0 || filesize( $calfile ) <= 0 )
    bailout( "An error occured while attempting to convert alignment file" );

if ( $group_a_max < 1 )
    bailout( "top group row must be 1 or greater" );
if ( $group_a_max >= $num_rows )
    bailout( "top group row must be less than number of rows in alignment" .
             " ($num_rows)" );

//readfile( $calfile );

if ( $output_format == "pdf" )
   {
    header( 'Content-type: application/pdf' );
    header( "Content-disposition: inline; filename=" . 
            str_replace( " ", "", $plot_title ) . ".pdf" );
   }
else if ( $output_format == "ps" )
   {
    header( 'Content-type: application/ps' );
    header( "Content-disposition: inline; filename=" . 
            str_replace( " ", "", $plot_title ) . ".ps" );
   }
else if ( $output_format == "jpeg" )
   {
    // print( "You have chosen wisely.<BR>\n" );
   }

$cmd = "$cpdl $opts $group_a_max $calfile";

if ( $logging )
    fwrite( $log, "   command $cmd\n" );
system( "$cmd >$psfile" );

//
// CPDL always outputs Postscript.  If the user wanted another format
// we perform a converion here.
//

if ( $output_format == "pdf" )
   {
    if ( $logging )
       {
        fwrite( $log, "   pdffile is $pdffile\n" );
        fwrite( $log, "   pstopdf $psfile -o $pdffile\n" );
       }
    //system( "$pstopdf $psfile -o $pdffile" );
    system( "$pstopdf $psfile $pdffile" );
    readfile( $pdffile );
   }
else if ( $output_format == "ps" )
    readfile( $psfile );
else if ( $output_format == "jpeg" )
   { 
    if ( $logging )
        $joutmsg = $log_file;
    else
        $joutmsg = "/dev/null";
    $jcmd = "$gs -r$jpeg_rez -sDEVICE=jpeg -sOutputFile=$jpgfile-\%d.jpg -dJPEGQ=100 -dSAFER -dBATCH -dNOPAUSE $psfile >>$joutmsg";
    if ( $logging )
       {
        fwrite( $log, "   jpgfile is $jpgfile-\%d.jpg\n" );
        fwrite( $log, "   $jcmd\n" );
       }
    system( $jcmd );
    foreach ( glob( "$jpgfile-*.jpg" ) as $jfile )
       { 
        $basen = basename( $jfile );
        $newj = "$image_dir/rot_" . $basen;
        if ( $logging )
            fwrite( $log, "   $conv -rotate -90 $jfile $newj\n" );
        system( "$conv -rotate -90 $jfile $newj 1>> $log_file 2>>$log_file" );
        print( "<IMG SRC=\"$newj\"> <BR>\n" );
       }
   }



if ( $logging )
   {
    fwrite( $log, "   result in $psfile\n" );
    fwrite( $log, "End " . date( "D M j G:i:s T Y" ) . "\n" );
    fclose( $log );
   }
else
   {
    unlink( $calfile );
    unlink( $psfile );
    if ( $output_format == "pdf" )
        unlink( $pdffile );
    else if ( $output_format == "jpeg" )
       // unlink jpegs
        { }
   }

?>



