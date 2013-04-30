#!/bin/sh
# Copyright (C) 2006 OpenWrt.org

# DEBUG="echo"

switch_network_mode() {
  local mode="$1"
  local ssid="$2"
  local key="$3"

  AP_ADDR=$(uci get powertools.@system[0].address)
  UID=$(uci get powertools.@system[0].uid)
  RELEASE=$(uci get powertools.@system[0].release)
  if  [ "$AP_ADDR" == "" ]; then
    case $RELEASE in
      "nas") AP_ADDR="172.16.0.1" ;;
      "pulseaudio") AP_ADDR="172.16.10.1" ;;
    esac
  fi
  current_ssid=$(uci get wireless.@wifi-iface[1].ssid)
  if [ "$ssid" != "" ]; then
    if [ "$current_ssid" != "$ssid" ]; then
      uci set wireless.@wifi-iface[1].ssid="$ssid"
    fi
  fi
  current_key=$(uci get wireless.@wifi-iface[1].key)
  if [ "$key" != "" ]; then
    if [ "$current_key" != "$key" ]; then
      uci set wireless.@wifi-iface[1].key="$key"
    fi
  fi
  ssid=$(uci get wireless.@wifi-iface[1].ssid)
  key=$(uci get wireless.@wifi-iface[1].key)
  wifi_disabled=$(uci get wireless.@wifi-iface[1].disabled)
  if [ "$ssid" == "Disabled" ]; then
    if [ "$wifi_disabled" != "1" ]; then 
      uci set wireless.@wifi-iface[1].disabled=1
    fi
  else
    if [ "$wifi_disabled" != "0" ]; then
      uci set wireless.@wifi-iface[1].disabled=0
    fi
  fi
  if [ "$mode" == "auto" ]; then
    WIFI_UID=$(cat /sys/class/net/wlan0/address | awk -F':' '{print $5$6}')
    case $RELEASE in
      "nas") mode=2
               HOSTNAME=OpenWrt-NAS-"$WIFI_UID"
             ;;
      "pulseaudio") mode=1
                      HOSTNAME=OpenWrt-PulseAudio-"$WIFI_UID"
                    ;;
    esac
  fi
  if [ "$UID" != "" ]; then
    RELEASE="$RELEASE"-"$UID"
  fi
  if [ "$mode" != "" ]; then
  uci set powertools.@system[0].mode=$mode
  CURRENT_HOSTNAME=$(uci get system.@system[0].hostname)
  if [ "$CURRENT_HOSTNAME" != "$HOSTNAME" ]; then
    if [ "$HOSTNAME" != "" ]; then
      uci set system.@system[0].hostname=$HOSTNAME
    fi
  fi
  hostname_ip=$(grep ^"$AP_ADDR $RELEASE"$ /etc/hosts | awk '{print $1}')
    if [ "$hostname_ip" != "$AP_ADDR" ]; then
      if [ "$hostname_ip" != "" ]; then
        sed -e "s/.*'$RELEASE'/$AP_ADDR '$RELEASE'/" -i /etc/hosts
      else
        echo "$AP_ADDR $RELEASE" >> /etc/hosts
      fi
    fi
  fi
  case $mode in
    1) ## eth0 + wlan0 as lan, wlan1 and usb0 as two wans
  
      ## set network
  
      uci delete network.wan
      uci delete network.lan
      uci delete network.wifi
      uci delete network.usb
  
      uci set network.lan=interface
      uci set network.lan.ifname="eth0 wlan0"
      uci set network.lan.type=bridge
      uci set network.lan.proto=static
      uci set network.lan.ipaddr=$AP_ADDR
      uci set network.lan.netmask="255.255.255.0"
  
      uci set network.wifi=interface
      uci set network.wifi.ifname=wlan1
      uci set network.wifi.proto=dhcp
      uci set network.wifi.hostname=$RELEASE
      
      uci set network.usb=interface
      uci set network.usb.ifname=usb0
      uci set network.usb.proto=dhcp
      uci set network.usb.hostname=$RELEASE
  
      uci set wireless.@wifi-iface[1].wds=0
  
      ## set dhcp
      uci delete dhcp.wan
  
      uci set dhcp.lan.ignore=0
      uci set dhcp.wifi.ignore=1
  
      ## set multiwan
      #uci delete multiwan.wifi
      #uci delete multiwan.wan
  
      #uci set multiwan.wifi=interface
      #uci set multiwan.wifi.weight=10
      #uci set multiwan.wifi.health_interval=10
      #uci set multiwan.wifi.icmp_hosts=dns
      #uci set multiwan.wifi.timeout=3
      #uci set multiwan.wifi.health_fail_retries=3
      #uci set multiwan.wifi.health_recovery_retries=5
      #uci set multiwan.wifi.failover_to=disabled
      #uci set multiwan.wifi.dns=auto

      uci commit
      ;;
  
      2) ## wlan0 as lan, eth0, wlan1 and usb0 as three wans
  
      ## set network
      uci delete network.lan
      uci delete network.wan
      uci delete network.wifi
      uci delete network.usb
  
      uci set network.lan=interface
      uci set network.lan.ifname="wlan0"
      uci set network.lan.proto=static
      uci set network.lan.ipaddr=$AP_ADDR
      uci set network.lan.netmask="255.255.255.0"
  
  
      uci set network.wan=interface
      uci set network.wan.ifname=eth0
      uci set network.wan.proto=dhcp
      uci set network.wan.hostname=$RELEASE
  
  
      uci set network.wifi=interface
      uci set network.wifi.ifname=wlan1
      uci set network.wifi.proto=dhcp
      uci set network.wifi.hostname=$RELEASE
     
      uci set network.usb=interface
      uci set network.usb.ifname=usb0
      uci set network.usb.proto=dhcp
      uci set network.usb.hostname=$RELEASE
  
      uci set wireless.@wifi-iface[1].wds=0
  
      ## set dhcp
      uci set dhcp.lan.ignore=0
      uci set dhcp.wifi.ignore=1
  
      uci delete dhcp.wan
  
      uci set dhcp.wan=dhcp
      uci set dhcp.wan.interface=wan
      uci set dhcp.wan.ignore=1
  
  
      ## set multiwan
      #uci delete multiwan.wifi
      #uci delete multiwan.wan
  
      #uci set multiwan.wifi=interface
      #uci set multiwan.wifi.weight=10
      #uci set multiwan.wifi.health_interval=10
      #uci set multiwan.wifi.icmp_hosts=dns
      #uci set multiwan.wifi.timeout=3
      #uci set multiwan.wifi.health_fail_retries=3
      #uci set multiwan.wifi.health_recovery_retries=5
      #uci set multiwan.wifi.failover_to=disabled
      #uci set multiwan.wifi.dns=auto
  
  
      #uci set multiwan.wan=interface
      #uci set multiwan.wan.weight=10
      #uci set multiwan.wan.health_interval=10
      #uci set multiwan.wan.icmp_hosts=dns
      #uci set multiwan.wan.timeout=3
      #uci set multiwan.wan.health_fail_retries=3
      #uci set multiwan.wan.health_recovery_retries=5
      #uci set multiwan.wan.failover_to=disabled
      #uci set multiwan.wan.dns=auto
  
      uci commit
      ;;
  
      3) ## wlan0 as lan, eth0, wlan1 in WDS mode and usb0 as 2 wans
  
      ## set network
      uci delete network.lan
      uci delete network.wan
      uci delete network.wifi
      uci delete network.usb
  
      uci set network.lan=interface
      uci set network.lan.ifname="wlan0"
      uci set network.lan.proto=static
      uci set network.lan.ipaddr=$AP_ADDR
      uci set network.lan.netmask="255.255.255.0"
  
  
      uci set network.wifi=interface
      uci set network.wifi.ifname="eth0 wlan1"
      uci set network.wifi.type=bridge
      uci set network.wifi.proto=dhcp
      uci set network.wifi.hostname=$RELEASE

      uci set network.usb=interface
      uci set network.usb.ifname=usb0
      uci set network.usb.proto=dhcp
      uci set network.usb.hostname=$RELEASE
  
      uci set wireless.@wifi-iface[1].wds=1
  
      ## set dhcp
      uci set dhcp.lan.ignore=0
      uci set dhcp.wifi.ignore=1
  
      uci delete dhcp.wan
  
  
  
      ## set multiwan
      #uci delete multiwan.wifi
      #uci delete multiwan.wan
  
      #uci set multiwan.wifi=interface
      #uci set multiwan.wifi.weight=10
      #uci set multiwan.wifi.health_interval=10
      #uci set multiwan.wifi.icmp_hosts=dns
      #uci set multiwan.wifi.timeout=3
      #uci set multiwan.wifi.health_fail_retries=3
      #uci set multiwan.wifi.health_recovery_retries=5
      #uci set multiwan.wifi.failover_to=disabled
      #uci set multiwan.wifi.dns=auto
  
  
      uci commit
      ;;

      *)
       changes=$(uci changes)
       if [ "$changes" != "" ]; then
         uci commit
       fi
      ;;
  
  esac
}

set_multiwan() {
	local ifc="$1"
	local address="$2"
	local interface="$3"
	local gateway="$4"
	local metric="$5"" ""$6"
	local table
        local nexthop_opt=""
	case $ifc in
		usb) table=170;;
		wan) table=171;;
		wifi) table=172;;
	esac
	if [ "$table" != "" ] && [ "$gateway" != "" ]; then
		ip route flush table $table
		ip route add default via $gateway dev $interface proto static src $address table $table
		for line in $(ip route show | grep -v default | grep -v nexthop | grep $interface | awk -v table=$table '{print "ip|route|add|"$1"|"$2"|"$3"|"$4"|"$5"|"$6"|"$7"|"$8"|"$9"|table|"table}'); do
			cmd=$(echo $line | sed -e "s/|/ /g")
			sh -c "$cmd"
		done
		for line in $(ip rule show | awk -F":" '{print $2}' | grep  "lookup $table" | awk '{print "ip|rule|del|"$1"|"$2"|"$3"|"$4}'); do
			cmd=$(echo $line | sed -e "s/|/ /g")
			sh -c "$cmd"
		done
		ip rule add from $address table $table prio $table
		ip route del default
		for network in usb wan wifi; do
			nexthop_gateway=$(uci -p/var/state get network."$network".lease_gateway 2>/dev/null)
			nexthop_interface=$(uci -p/var/state get network."$network".device 2>/dev/null)
			interface_exist=$(grep $nexthop_interface /proc/net/dev)
			if [ "$nexthop_gateway" != "" ] && [ "$interface_exist" != "" ]; then
				nexthop_opt="$nexthop_opt nexthop via $nexthop_gateway dev $nexthop_interface weight 1 $metric"
			fi
		done
		if [ "$nexthop_opt" != "" ]; then
			ip route add default scope global $nexthop_opt
			echo 30 > /proc/sys/net/ipv4/route/gc_timeout
		else
			for network in "usb" "wan" "wifi"; do
				network_gateway=$(uci -p/var/state get network."$network".lease_gateway 2>/dev/null )
				network_interface=$(uci -p/var/state get network."$network".device 2>/dev/null)
				interface_exist=$(grep $network_interface /proc/net/dev)
				if [ "$network_gateway" != "" ] && [ "$interface_exist" != "" ]; then
					ip route add default via $network_gateway dev $network_interface $metric
				fi
			done
		fi 
		ip route flush cache
	fi
		

	
}

scan_dns() {
local RESOLV_CONF="$1"
	for network in usb wan wifi; do
		dns_entry=$(uci -p/var/state get network."$network".dns 2>/dev/null)
		domain_entry=$(uci -p/var/state get network."$network".dnsdomain 2>/dev/null)
		[ -n "$dns_entry" ] && old_dns=$(grep ^"nameserver $dns_entry"$ "$RESOLV_CONF")
		[ -n "$domain_entry" ] && old_domain=$(grep ^"search $domain_entry"$ "$RESOLV_CONF")
		if [ "$old_dns" == "" ] && [ "$dns_entry" != "" ]; then
			echo "nameserver $dns_entry" >> "$RESOLV_CONF"
		fi
		if [ "$old_domain" == "" ] && [ "$domain_entry" != "" ]; then
			echo "search $domain_entry" >> "$RESOLV_CONF"
		fi
	done
}

scan_route() {
multiwan_enable=$(uci get powertools.@system[0].multiwan)
if [ "$multiwan_enable" == "1" ]; then
	for network in usb wan wifi; do
		nexthop_gateway=$(uci -p/var/state get network."$network".gateway 2>/dev/null)
		nexthop_interface=$(uci -p/var/state get network."$network".device 2>/dev/null)
		interface_exist=$(grep $nexthop_interface /proc/net/dev)
		if [ "$nexthop_gateway" != "" ] && [ "$interface_exist" != "" ]; then
			nexthop_opt="$nexthop_opt nexthop via $nexthop_gateway dev $nexthop_interface weight 1"
		fi
	done
	if [ "$nexthop_opt" != "" ]; then
		ip route add default scope global $nexthop_opt
		echo 30 > /proc/sys/net/ipv4/route/gc_timeout
	fi
else
	for network in usb wan wifi; do
		network_gateway=$(uci -p/var/state get network."$network".gateway 2>/dev/null)
		network_interface=$(uci -p/var/state get network."$network".device 2>/dev/null)
		interface_exist=$(grep $network_interface /proc/net/dev)
		if [ "$network_gateway" != "" ] && [ "$interface_exist" != "" ]; then
			ip route add default via $network_gateway dev $network_interface
		fi
	done
fi
}
