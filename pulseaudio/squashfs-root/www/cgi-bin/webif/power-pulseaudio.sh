#!/usr/bin/webif-page
<?
. /usr/lib/webif/webif.sh
###################################################################
timeout=60
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

header_inject_head=$(cat <<EOF
<style type="text/css">
<!--
#modtable table {
	width: 98%;
	margin-left: auto;
	margin-right: auto;
	text-align: left;
	font-size: 0.9em;
	border-style: none;
	border-spacing: 0;
}
#modtable td, th {
	padding-left: 0.2em;
	padding-right: 0.2em;
}
#modtable .number {
	text-align: right;
}
-->
</style>
<meta http-equiv="refresh" content="$timeout"; />
EOF

)



header "Power Tools" "PulseAudio" "@TR<<status_pulseaudio#PulseAudio Status>>"

?>

<div class="settings">
USB sound card/speakers information can be found <a href="http://<? echo $RELEASE ?>/cgi-bin/webif/status-usb.sh">here</a>.</br></br>
<h3><strong>@TR<<status_pulseaudio_sinks#Sinks>></strong></h3>
<div id="modtable">
<table>
<tbody>
<tr>
	<th >@TR<<status_pulseaudio_sink_th_ID#Id>></th>
	<th >@TR<<status_pulseaudio_sink_th_Name#Name>></th>
        <th >@TR<<status_pulseaudio_sink_th_Sink_Steate#State>></th>
	<th >@TR<<status_pulseaudio_sink_th_Driver#Driver>></th>
	<th >@TR<<status_pulseaudio_sink_th_Format#Format>></th>
	<th >@TR<<status_pulseaudio_sink_th_Channels#Channels>></th>
	<th >@TR<<status_pulseaudio_sink_th_Sample_Rate#Sample Rate>></th>
</tr>

<?


env HOME=/tmp pactl list short sinks 2>/dev/null  | awk  '
BEGIN{
	odd=1
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
		print td_ind "<td >" $1 "</td>"
		print td_ind "<td>" $2 "</td>"
                        module = $3
			format = $4
                        channels = $5
                        sample_rate = $6
                        state = $7
                        print td_ind "<td >" state "</td>"
                        print td_ind "<td >" module "</td>"
			print td_ind "<td>" format "</td>"
			print td_ind "<td>" channels "</td>"
		print td_ind "<td>" sample_rate "</td>"
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


?>

<div class="settings">
<h3><strong>@TR<<status_pulseaudio_sink_inputs#Sink Inputs>></strong></h3>
<div id="modtable">
<table>
<tbody>
<tr>
	<th >@TR<<status_pulseaudio_sink_inputs_th_ID#Id>></th>
	<th >@TR<<status_pulseaudio_sink_inputs_th_Sink_ID#Sink Id>></th>
        <th >@TR<<status_pulseaudio_sink_inputs_th_Client_ID#Client Id>></th>
	<th >@TR<<status_pulseaudio_sink_inputs_th_Driver#Driver>></th>
        <th >@TR<<status_pulseaudio_sink_inputs_th_Format#Format>></th>
	<th >@TR<<status_pulseaudio_sink_inputs_th_Channels#Channels>></th>
	<th >@TR<<status_pulseaudio_sink_inputs_th_Sample_Rate#Sample Rate>></th>
</tr>
<?


env HOME=/tmp pactl list short sink-inputs 2>/dev/null  | awk  '
BEGIN{
	odd=1
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
		print td_ind "<td >" $1 "</td>"
		print td_ind "<td>" $2 "</td>"
                if ($3 == "-") {
                    client_id = "&nbsp;"
                } else {
                    client_id = $3
                }
		print td_ind "<td>" client_id "</td>"
                print td_ind "<td>" $4 "</td>"
                print td_ind "<td>" $5 "</td>"
                print td_ind "<td>" $6 "</td>"
                print td_ind "<td>" $7 "</td>"
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

?>

<div class="settings">
<h3><strong>@TR<<status_pulseaudio_clients#Clients>></strong></h3>
<div id="modtable">
<table>
<tbody>
<tr>
	<th >@TR<<status_pulseaudio_clients_th_ID#Id>></th>
        <th >@TR<<status_pulseaudio_clients_th_Name#Name>></th>
	<th >@TR<<status_pulseaudio_clients_th_Driver#Driver>></th>
</tr>
<?


env HOME=/tmp pactl list short clients 2>/dev/null  | awk  '
BEGIN{
	odd=1
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
		print td_ind "<td >" $1 "</td>"
                driver=$2
                name=$3
		print td_ind "<td>" name "</td>"
		print td_ind "<td>" driver"</td>"
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


cat << EOF
<div class="settings">
<h3><strong>@TR<<status_pulseaudio_logs#Logs>></strong></h3>
<div id="modtable">
<table>
<tbody>
<tr>
	<th > Time in 
EOF
uci get system.@system[0].timezone
cat << EOF
</th>
        <th >@TR<<status_pulseaudio_clients_th_Entry#Log Entry>></th>
</tr>
EOF


logread 2>/dev/null  | grep [pulseaudio]  | awk '{ x = $0 "\n" x } END { printf "%s", x }'  | awk  '
BEGIN{
	odd=1
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
		print td_ind "<td >" $1" "$2" "$3 "</td>"
                print td_ind "<td>"
                for (i=8; i<=NF; i++) {
                printf ("%s ", $i)
                }
                print "</td>"
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

footer ?>
<!--
##WEBIF:name:Power Tools:030:PulseAudio
-->
