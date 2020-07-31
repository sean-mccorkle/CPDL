<BODY BGCOLOR=white>
<!-- $Id: cpdl_form.php,v 3.2 2004/11/24 03:35:06 mccorkle Exp mccorkle $ -->
<B>Run CPDL</B> - Conserved Property Difference Locator<BR>
<BR>

<FORM METHOD=post ACTION="run_cpdl.php" STYLE='background-color: white' 
      ENCTYPE="multipart/form-data" >

<A HREF="splash.html#afile">Alignment file</A>: 
<input  type="hidden"  name="MAX_FILE_SIZE"  value="1048576">
<input  name="userfile"  type="file"><BR>
<A HREF="splash.html#topg">Top group</A> extends from row 1 to 
<input  type="text"    name="group_a_max"  size=10 maxlength=10>
(inclusive)<BR>
<A HREF="splash.html#ofile">Output file name</A>:
<input  type="text"    name="plot_title"   size=20 maxlength=80>

<BR>
<BR>
<TABLE>
<TR>
<TH ALIGN=RIGHT><A HREF="splash.html#track">Track</A></TH>
<TH COLSPAN=5><A HREF="splash.html#display">Display Status</a></TH>
</TR>
<?
    $maskcolor = "khaki";

    print "<TR><TD COLSPAN=3></TD><TH BGCOLOR=\"" 
          . $maskcolor .  "\"COLSPAN=3>show only differences</TH></TR>\n";


    $vlabel["on"] = "on";
    $vlabel["blank"] = "off";
    $vlabel["discrep"] = "if in track";
    $vlabel["main_discrep"] = "if in main track";
    $vlabel["main_full_high"] = "if in main red hourglass";


    $vlabelcolor["on"] = "white";
    $vlabelcolor["blank"] = "white";
    $vlabelcolor["discrep"] = $maskcolor;
    $vlabelcolor["main_discrep"] = $maskcolor;
    $vlabelcolor["main_full_high"] = $maskcolor;

    function rbutton( $name, $val, $chkd = "" )
       {
        global $vlabel, $vlabelcolor;

        print "<TD BGCOLOR=\"" . $vlabelcolor[$val] . "\">";
        print "<INPUT TYPE=RADIO NAME=\"$name\" value=\"$val\" $chkd>" .
              $vlabel[$val] .  "\n";
        print "</TD>";
       }

    function stat_radio_row( $label, $name )
       {
        print "<TR><TH ALIGN=right><A HREF=\"splash.html#$label\">$label</A></TH>\n";
        foreach ( array( "on", "blank", "discrep", "main_discrep", 
                         "main_full_high" )
                  as $statval )
           {
            if ( $statval == "discrep" )
               $chkd = checked;
            else
               $chkd = "";
            rbutton( $name, $statval, $chkd );
           }
        print "</TR>\n";
       }

    stat_radio_row( "size",  "size_tr_stat" );
    stat_radio_row( "hydro", "hydro_tr_stat" );
    stat_radio_row( "charge", "charge_tr_stat" );
    stat_radio_row( "polarity", "polarity_tr_stat" );
    stat_radio_row( "aromatic", "aromatic_tr_stat" );

 ?>
</TABLE>

<BR>
<A HREF="splash.html#conservation">Conservation level</A> 
<input type=radio name=conserved_value value="unanimous">all
<input type=radio name=conserved_value value="unanimous_minus_1" checked>
     all or all but one
<BR>

<BR>
<input type=checkbox name=show_prop_diffs value=on checked>
Flag conserved residue property differences in main track with orange circles
<BR>
<input type=checkbox name=show_key value=on checked>
Include symbol key and residue properities table at end
<BR>
<BR>
<A HREF="splash.html#gray">Grayscale function</A>
<input type=radio name=gs_function value="plateau" checked>flat
<input type=radio name=gs_function value="linear">linear 
<input type=radio name=gs_function value="exponential"> exponential
<BR>
<BR>
<A HREF="splash.html#darkness">darkness adjustment</A> <input type=text name=darkness value=0.25>
<BR>
<BR>

<TABLE>
<TR VALIGN=top> 
<TD>
Select an output format:
</TD>
<TD>
<input type=radio name=output_format value="jpeg" checked> JPEG (easy viewing)
&nbsp;&nbsp;&nbsp;
(Resolution 
<select  name=jpeg_rez>
<option value=70>70
<option value=80>80
<option value=90 selected>90
<option value=100>100
<option value=110>110
<option value=110>120
</select>
dots per inch.  <I>A lower number yields smaller image</I>)
<BR>
<input type=radio name=output_format value="pdf"> PDF (<I>recommending for printing - </I>
 <A HREF="http://www.adobe.com/products/acrobat/readstep2.html">adobe reader</A>
can be used for display)
<BR>
<input type=radio name=output_format value="ps"> Postscript (PS)
<BR>
</TD>
</TR>
</TABLE>
<BR>
<INPUT TYPE=submit name=action value="Run CPDL">
<INPUT TYPE=reset value="Reset form">
</FORM>

<A HREF="splash.html">back to main page</A>