#!/bin/sh

# Define log file path for logging DNS failover events
log_file="/tmp/dns_failover.log"

# Define the primary and backup DNS resolvers (DoH endpoints)
primary_dns="https://dns.supercluster.io/dns-query/router"
backup_dns="https://1.1.1.2/dns-query"

# Define the domain to be used for testing DNS resolution
test_domain="google.com"

# Retrieve the current DNS resolver configuration from UCI
current_dns=$(uci get https-dns-proxy.@https-dns-proxy[0].resolver_url 2>/dev/null)

# Perform a DNS lookup on the test domain through the local DoH proxy (127.0.0.1:5053)
# Check if a valid IP address is returned to determine if the DNS resolver is functioning properly
if nslookup -p 5053 "$test_domain" 127.0.0.1 | grep -E "Address [0-9]:" > /dev/null 2>&1; then
    # If DNS is working and the current resolver is not set to the primary DNS, revert to the primary DNS
    if [ "$current_dns" != "$primary_dns" ]; then
        echo "$(date) - Primary DNS is back, reverting to primary." >> "$log_file"
        uci set https-dns-proxy.@https-dns-proxy[0].resolver_url="$primary_dns"
        uci commit https-dns-proxy
        /etc/init.d/https-dns-proxy restart
    fi
else
    # If primary DNS fails, and the current resolver is not set to the backup DNS, switch to backup
    if [ "$current_dns" != "$backup_dns" ]; then
        echo "$(date) - Primary DNS failed, switching to backup." >> "$log_file"
        uci set https-dns-proxy.@https-dns-proxy[0].resolver_url="$backup_dns"
        uci commit https-dns-proxy
        /etc/init.d/https-dns-proxy restart
    fi
fi