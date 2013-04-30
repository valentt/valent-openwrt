#!/usr/bin/webif-page
<?
. /usr/lib/webif/webif.sh

timeout=40
release=$(uci get powertools.@system[0].release)
ifname=$(uci show -p/var/state network |grep "ipaddr=$SERVER_ADDR" | awk -F '=' '{print $1}' | awk -F'.' '{print $1"."$2}')
RELEASE_VERSION=$(uci get powertools.@system[0].version)
RELEASE_URL="http://xbox-remote.googlecode.com/svn/trunk/embeded-system/openwrt/$release/release"

proto=$(uci get -p/var/state "$ifname".proto)

if [ "$proto" == "static" ]; then
  ns_result=$(nslookup "$release" | grep "Address" | grep "$release"  | awk '{print $3}')
  if [ "$ns_result" == "$SERVER_ADDR" ]; then
    RELEASE="$release"
  else
    RELEASE="$SERVER_ADDR"
  fi
else
  hostname=$(uci get -p/var/state "$ifname".lease_hostname)
  if [ "$hostname" != "" ]; then
    RELEASE="$hostname"
  else
    RELEASE="$SERVER_ADDR"
  fi
fi


header "Power Tools" "Upgrade" "@TR<<Firmware Upgrade>>" ' onload="modechange()" ' "$SCRIPT_NAME"

cat << EOF
<div class="settings">
<div class="version">
<h3><strong>@TR<<Version#Current Firmware Version>></strong></h3>
<div id="modtable">
<table>
<tbody>
EOF
if [ "$RELEASE_VERSION" != "" ]; then
echo "<tr><td>$RELEASE_VERSION</td></tr>"
else
echo "<tr><td>Unknown</td></tr>"
fi
cat << EOF
</tbody>
</table>
</div>
<div class="clearfix">&nbsp;</div></div>
EOF

if empty "$FORM_reboot"; then
  if [ -f /tmp/powertools-release ]; then
  rm /tmp/powertools-release
  fi
  wget -O /tmp/powertools-release $RELEASE_URL 2>/dev/null

  RELEASE_RESULT=$(cat /tmp/powertools-release | awk '{print $1 "," $2 "," $3 "@"}')

  for firmware in $(cat /tmp/powertools-release | awk '{print $2}'); do
    if empty "$firmware_selection" ; then
      firmware_selection="option|$firmware|@TR<<$firmware>>"
    else
    firmware_selection=$(echo -ne "$firmware_selection  \n option|$firmware|@TR<<$firmware>>")
    fi
  done



  FORM_firmware_selected=$(cat /tmp/powertools-release | awk '{print $2}' | head -n 1)

cat <<EOF
<script type="text/javascript" src="/webif.js"></script>
<script type="text/javascript">
<!--
function modechange()
{
  var myrelease = value('RELEASE_RESULT');
  var mysplit = myrelease.split('@');
  var myfirmware = value('firmware_selected');
  for (var j=0; j<mysplit.length; j++) {
    if (mysplit[j].search(myfirmware) >= 0){
      var mysum = mysplit[j].split(",")[0];
    }
  }
  set_value('show_FIRMWARE_SUM', mysum);
  set_value('show_FIRMWARE_URL', 'http://xbox-remote.googlecode.com/files/'+myfirmware);
}
-->                                                                                                                    
</script>                                                                                                              
EOF

cat <<EOF
<input type="hidden" id="RELEASE_RESULT" value="$RELEASE_RESULT" />
<h3><strong>@TR<<Firmware#Select Firmware>></strong></h3>
<div id="modtable">
<table>
<tbody>
EOF

display_form <<EOF
onchange|modechange
field|@TR<<Available Firmware>>
select|firmware_selected|$FORM_firmware_selected
$firmware_selection
field|@TR<<FIRMWARE_URL_Sring#Firmware URL>>|view_firwware_url_string|
string|<input id="show_FIRMWARE_URL" type="text" style="width: 96%;[D height: 1.2em; " name="show_FIRMWARE_URL" value="@TR<<system_settings_js_required#This field requires the JavaScript support.>>" />
field|@TR<<FIRMWARE_MD5SUM_Sring#Firmware MD5SUM>>|view_firmware_md5sum_string|
string|<input id="show_FIRMWARE_SUM" type="text" style="width: 96%;[D height: 1.2em; " name="show_FIRMWARE_SUM" value="@TR<<system_settings_js_required#This field requires the JavaScript support.>>" />
field|@TR<<>>
submit|reboot| @TR<<Upgrade Firmware>> |
end_form
EOF

else

  if [ "$FORM_show_FIRMWARE_URL" != "This field requires the JavaScript support." ] && [ "$FORM_show_FIRMWARE_URL" != "" ]; then

cat << EOF
<div class="log">
<h3><strong>@TR<<Logs#Downloading Logs>></strong></h3>
<div id="modtable">
<table>
<tbody>
EOF
echo "<tr><td>Downloading firmware from URL $FORM_show_FIRMWARE_URL </td></tr>"

  /usr/bin/wget -O /tmp/openwrt-upgrade.bin "$FORM_show_FIRMWARE_URL" 2>&1 | awk  '
BEGIN{
	odd=0
	tr_ind = ""
	td_ind = "\t"
}
function oddline() {
	if (odd == 1) {
		print tr_ind "<tr>"
		odd--
	} else {
		print tr_ind "<tr class=\"odd\">"
		odd++
	}
}
{
	if (length($0) != 0) {
		oddline()
		print td_ind "<td >" $0 "</td>"
		print tr_ind "</tr>"
	}
}
END{
}
'
display_form <<EOF
string|</tbody>
end_form
EOF

  download_sum=$(md5sum /tmp/openwrt-upgrade.bin | awk '{print $1}')
    if [ "$FORM_show_FIRMWARE_SUM" == "$download_sum" ] && ! empty "$download_sum" ; then
cat <<EOF
<div class="log">
<h3><strong>@TR<<Logs#Flashing Logs>></strong></h3>
<div id="modtable">
<table>
<tbody>
<tr><td>Flashing firmware... This can take up to 2 minutes.</td></tr>
<tr class="odd"><td>Please wait about 2 minutes and click here <a href="http://$RELEASE">$RELEASE</a>. </td></tr>
</tbody>
</table>
</div>
<div class="clearfix">&nbsp;</div></div>
<br/><br/><br/>
<table width="90%" border="0" cellpadding="2" cellspacing="2" align="center">
<tr>
<td><script type="text/javascript" src="/js/progress.js"></script>
<center>
<script type="text/javascript">
<!--
var bar1=createBar(350,15,'white',1,'black','blue',85,7,3,'');
-->
</script>
</center>
<br/><br/><br/></td>
</tr>
</table>
<meta http-equiv="refresh" content="120;http://$RELEASE" />
EOF

    sleep 3
    uci_set webif general firstboot 1
    uci_commit "webif"
    sysupgrade -v -n /tmp/openwrt-upgrade.bin

    else   
    cat << EOF
<div class="log">
<h3><strong>@TR<<Error_Logs#Error Logs>></strong></h3>
<div id="modtable">
<table>
<tbody>
<tr><td><font color="red"> md5sum does not match!!! Upgrade aborted!!!</font></td></tr>
</tbody>
</table>
</div>
<div class="clearfix">&nbsp;</div></div>
<meta http-equiv="refresh" content="$timeout;http://$RELEASE" />"
EOF
    
    
    fi
  exit
  fi
fi

?>

<!--
##WEBIF:name:Power Tools:020:Upgrade
-->
