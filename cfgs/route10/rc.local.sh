#!/bin/sh

# Port mappings for the device
# Port | Interface | SSDK Port Number | Manufacturer Label
# ---------------------------------------------------------------
# 1    | eth3      | 4                | WAN1
# 2    | eth2      | 3                | LAN1
# 3    | eth1      | 2                | LAN2
# 4    | eth0      | 1                | LAN3
# 5    | eth5      | 6                | LAN4
# 6    | eth4      | 5                | WAN2

# Disable flow control on specific ports for performance
ssdk_sh flow status set 0
ssdk_sh port flowCtrl set 1 disable
ssdk_sh port flowCtrl set 2 enable
ssdk_sh port flowCtrl set 3 disable
ssdk_sh port flowCtrl set 4 disable
ssdk_sh port flowCtrl set 5 disable
ssdk_sh port flowCtrl set 6 disable

# Block execution until WAN connectivity is confirmed
while ! ping -c 1 -W 2 1.1.1.1 >/dev/null; do
    sleep 2
done

# Synchronize system clock to enable SSL certificate validation
/bin/busybox ntpd -q -n -p 162.159.200.1 >/dev/null 2>&1

# Initialize DNS-over-HTTPS proxy with primary configuration
cp /cfg/https-dns-proxy /etc/config/https-dns-proxy
/etc/init.d/https-dns-proxy restart

# Configure Dnsmasq to forward queries to the local DoH listener
uci delete dhcp.@dnsmasq[0].server
uci add_list dhcp.@dnsmasq[0].server='127.0.0.1#5053'
uci set dhcp.@dnsmasq[0].noresolv='1'

# Map DoH endpoint to static IP to prevent resolution loops
uci add dhcp domain
uci set dhcp.@domain[-1].name='dns.supercluster.io'
uci set dhcp.@domain[-1].ip='132.147.81.15'
uci commit dhcp
/etc/init.d/dnsmasq reload

# Disable ISP DNS peering and refresh network interface
uci set network.wan.peerdns='0'
uci commit network
/etc/init.d/network reload

# Start DNS health monitor daemon in the background
/cfg/dns_failover &

exit 0
