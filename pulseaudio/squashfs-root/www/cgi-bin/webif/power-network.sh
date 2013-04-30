#!/usr/bin/webif-page
<?
. /usr/lib/webif/webif.sh
. /lib/network/networkmode.sh

timeout=60
if ! empty "$FORM_reboot"; then
	release=$(uci get powertools.@system[0].release)
        ifname=$(uci show -p/var/state network |grep "ipaddr=$SERVER_ADDR" | awk -F '=' '{print $1}' | awk -F'.' '{print $1"."$2}')
	proto=$(uci get -p/var/state "$ifname".proto)
        WIFI_UID=$(cat /sys/class/net/wlan0/address | awk -F':' '{print $5$6}')
	
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
        UID=$(uci get powertools.@system[0].uid)
        if [ "$FORM_enable_uid" == "1" ]; then
          if [ "$WIFI_UID" != "$UID" ]; then
            uci set powertools.@system[0].uid=$WIFI_UID
            uci commit
            if [ "$release""-alt" == "$RELEASE" ]; then
              RELEASE="$release""-""$WIFI_UID""-alt"
            fi
	    if [ "$release" == "$RELEASE" ]; then
              RELEASE="$RELEASE""-""$WIFI_UID"
            fi
          fi
        else
          if [ "$UID" != "" ]; then
            uci delete  powertools.@system[0].uid
            uci commit
            if  [ "$release""-""$WIFI_UID""-alt" == "$RELEASE" ]; then
              RELEASE="$release""-alt"
            fi
	    if  [ "$release""-""$WIFI_UID" == "$RELEASE" ]; then
	      RELEASE="$release"
            fi
          fi
        fi

	header_inject_head="<meta http-equiv=\"refresh\" content=\"$timeout;http://$RELEASE\" />"
	reboot_msg="@TR<<Netowork Reconfigured. Rebooting now>>...
<br/><br/>
@TR<<reboot_wait#Please wait about>> $timeout @TR<<reboot_seconds#seconds.>> @TR<<reboot_reload#The webif&sup2; should automatically reload.>>
<br/><br/>
<center>
<script type=\"text/javascript\">
<!--
var bar1=createBar(350,15,'white',1,'black','blue',85,7,3,'');
-->
</script>
</center>"
fi

header "Power Tools" "Network" "@TR<<Network Mode Selection>>" '' "$SCRIPT_NAME"

if empty "$FORM_reboot"; then
current_mode=$(uci get powertools.@system[0].mode)
if empty "$current_mode"; then
current_mode=1
fi
display_form <<EOF
start_form|@TR<<WIFI Station Settings>>
field|@TR<<ESSID>>
text|ssid|$(uci get wireless.@wifi-iface[1].ssid)
field|@TR<<KEY>>
password|key|$(uci get wireless.@wifi-iface[1].key)
EOF
cat << EOF
</td></tr><tr><td class="wr_client"><h5>&nbsp;</h5></td></tr>
</td></tr><tr><td class="wr_client"><h5>@TR<<WR703N as a wifi station>>:</h5></td></tr>
<tr class="wr_client"><td><p><font size="2">Optionally WR703N can be configured to connect to an external wifi AP, i.e. as a wifi client/station.</font></p></td></tr>
EOF
display_form <<EOF
helpitem|WiFi SSID
helptext|HelpText WiFi SSID#The wifi network name. Only WPA-PSK and WPA-PSK2 protected wifi network is supported.
helpitem|Wifi Key
helptext|HelpText WiFi Key#The wifi key for the network you want to connect. 
end_form
EOF
release=$(uci get powertools.@system[0].release)
WIFI_UID=$(cat /sys/class/net/wlan0/address | awk -F':' '{print $5$6}')
UID=$(uci get powertools.@system[0].uid)
if [ "$UID" != "$WIFI_UID" ]; then
  uid_state=0
else
  uid_state=1
fi

display_form <<EOF
start_form|@TR<<Unique Device ID>>
field|@TR<<UID>>
string|<input id="show_UID" type="text" style="width: 40%; height: 1.2em; color: #2f2f2f; background: #ececec; " name="show_UID" readonly="readonly" value="$WIFI_UID" />
field|@TR<<>>
radio|enable_uid|$uid_state|0|@TR<<Disabled>>
radio|enable_uid|$uid_state|1|@TR<<Enabled>>
EOF
cat << EOF
</td></tr><tr><td class="wr_client"><h5>&nbsp;</h5></td></tr>
</td></tr><tr><td class="wr_client"><h5>@TR<<UID>>:</h5></td></tr>
<tr class="wr_client"><td><p><font size="2">UID is taken from the last 4 letters from the mac address which is printed on the back of the WR703N.</font></p></td></tr>
EOF
display_form <<EOF
helpitem|UID
helptext|HelpText UID#If you have multiple WR703Ns running on the same network it will be desirable to turn on Unique Device ID and you will then be able to access it from <a href="http://$release-$WIFI_UID">$release-$WIFI_UID</a>.
end_form
EOF


cat << EOF
<div class="settings">
<h3><strong>@TR<<Mode#Available Modes>></strong></h3>
<div id="modtable">
<div class="settings-content">
<table width="100%" >
<tbody>
EOF
for display_mode in 1 2 3; do
  case $display_mode in
    1) message="Mode 1: eth0, wlan0 as bridged lan; wlan1 and usb0 as two wans" ;;
    2) message="Mode 2: wlan0 as lan; eth0, wlan1 and usb0 as three wans" ;;
    3) message="Mode 3: wlan0 as lan; eth0, wlan1 as bridged WDS wan and usb0 as 2nd wan" ;;
  esac
  if [ "$display_mode" == "$current_mode" ]; then
    echo "<tr><td> <input type=\"radio\" name=\"mode\" value=\"$display_mode\" checked=\"checked\" > $message </td></tr>"
  else
    echo "<tr><td> <input type=\"radio\" name=\"mode\" value=\"$display_mode\" > $message </td></tr>"
  fi
echo "<tr><td> &nbsp; </td></tr>"
done
echo "<tr><td> <input type=\"submit\" name=\"reboot\" value=\" Set Network Mode \" /> </td></tr>"
cat << EOF
</tbody>
</table>
</div>
</div>
<div class="clearfix">&nbsp;</div></div>
EOF

else
  cat << EOF
<div class="settings">
<h3><strong>@TR<<Logs#Network Reconfiguration Logs>></strong></h3>
<div id="modtable">
<table>
<tbody>
EOF
  switch_network_mode $FORM_mode $FORM_ssid $FORM_key
  echo "<tr><td>Netowork Reconfigured. Rebooting now ...</td></tr>"
  echo "<tr class=\"odd\"><td>Please wait about $timeout seconds. The webif&sup2; should automatically reload.</td></tr>"
cat << EOF
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
EOF

reboot -d 5 &
fi
?>
<!--
##WEBIF:name:Power Tools:010:Network
-->
