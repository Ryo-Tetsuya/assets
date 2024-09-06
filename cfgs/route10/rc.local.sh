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

# Apply custom DNS proxy configuration and restart service
cp /cfg/https-dns-proxy /etc/config/https-dns-proxy
/etc/init.d/https-dns-proxy restart

# Set dnsmasq to use only the custom DoH server (127.0.0.1#5053) and reload the service.
uci delete dhcp.@dnsmasq[0].server
uci add_list dhcp.@dnsmasq[0].server='127.0.0.1#5053'
uci set dhcp.@dnsmasq[0].noresolv='1'
uci commit dhcp
/etc/init.d/dnsmasq reload

# Disable peer DNS, commit the change, and reload the network configuration.
uci set network.wan.peerdns='0'
uci commit network
/etc/init.d/network reload

echo "* * * * * /cfg/dns_failover >> /tmp/dns_failover.log 2>&1" >> /etc/crontabs/root && /etc/init.d/cron reload