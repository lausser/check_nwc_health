<?php
#
# This is a template for the visualisation addon PNP (http://www.pnp4nagios.org)
#
# Plugin: check_nwc_health - https://labs.consol.de/nagios/check_nwc_health/
# Release 1.1 2015-09-15
#

$def[1] = "";
$opt[1] = "";

$_WARNRULE = '#FFFF00';
$_CRITRULE = '#FF0000';

$num = 1;
foreach ($DS as $i=>$VAL) {

    # eth0_usage_in / out
    # GigabitEthernet 0/0_usage_in / out
    if(preg_match('/^(.*?)_usage_in/', $NAME[$i])) {
        $interface = preg_replace('/_.*$/', '', $LABEL[$i]);
        $ds_name[$num] = $interface.' usage';
        $opt[$num]  = "--vertical-label \"Usage\" -l 0 -u 100 --title \"Interface Usage for $hostname - ".$interface."\" ";
        $def[$num]  = "DEF:percin=$RRDFILE[$i]:$DS[$i]:AVERAGE ";
        $def[$num] .= "DEF:percout=".$RRDFILE[$i+1].":".$DS[$i+1].":AVERAGE ";
        $def[$num] .= "LINE2:percin#00e060:\"in\t\" ";
        $def[$num] .= "GPRINT:percin:LAST:\"%10.1lf %% last\" ";
        $def[$num] .= "GPRINT:percin:AVERAGE:\"%7.1lf %% avg\" ";
        $def[$num] .= "GPRINT:percin:MAX:\"%7.1lf %% max\\n\" ";
        $def[$num] .= "LINE2:percout#0080e0:\"out\t\" ";
        $def[$num] .= "GPRINT:percout:LAST:\"%10.1lf %% last\" ";
        $def[$num] .= "GPRINT:percout:AVERAGE:\"%7.1lf %% avg\" ";
        $def[$num] .= "GPRINT:percout:MAX:\"%7.1lf %% max\"\\n ";
        $def[$num] .= rrd::hrule($WARN[$i], $_WARNRULE);
        $def[$num] .= rrd::hrule($CRIT[$i], $_CRITRULE);
        $num++;
    }

    # eth0_traffic_in / out
    # GigabitEthernet 0/0_traffic_in / out
    if(preg_match('/^(.*?)_traffic_in/', $NAME[$i])) {
        $interface = preg_replace('/_.*$/', '', $LABEL[$i]);
        $ds_name[$num] = $interface.' traffic';
        $opt[$num]  = "--vertical-label \"Traffic\" -b 1024 --title \"Interface Traffic for $hostname - $interface\" ";
        $def[$num]  = "DEF:bitsin=$RRDFILE[$i]:$DS[$i]:AVERAGE ";
        $def[$num] .= "DEF:bitsout=".$RRDFILE[$i+1].":".$DS[$i+1].":AVERAGE ";
        $def[$num] .= "AREA:bitsin#00e060:\"in\t\" ";
        $def[$num] .= "GPRINT:bitsin:LAST:\"%10.1lf %Sb/s last\" ";
        $def[$num] .= "GPRINT:bitsin:AVERAGE:\"%7.1lf %Sb/s avg\" ";
        $def[$num] .= "GPRINT:bitsin:MAX:\"%7.1lf %Sb/s max\\n\" ";
        $def[$num] .= "CDEF:bitsminusout=0,bitsout,- ";
        $def[$num] .= "AREA:bitsminusout#0080e0:\"out\t\" ";
        $def[$num] .= "GPRINT:bitsout:LAST:\"%10.1lf %Sb/s last\" ";
        $def[$num] .= "GPRINT:bitsout:AVERAGE:\"%7.1lf %Sb/s avg\" ";
        $def[$num] .= "GPRINT:bitsout:MAX:\"%7.1lf %Sb/s max\\n\" ";
        $num++;
    }

}
?>
