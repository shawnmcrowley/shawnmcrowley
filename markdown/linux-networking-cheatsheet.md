# Linux Networking Cheat Sheet

> **The Ultimate Linux Networking Reference Guide** - Master Linux networking from basics to advanced techniques for professional system administration

## 📚 Table of Contents

### [Part 1: Linux Networking Basics](#part-1-linux-networking-basics-for-everyone)
- [Network Interfaces & IP Addresses](#network-interfaces--ip-addresses)
- [Routes & Gateways](#routes--gateways)
- [Ports, Sockets & Listening Services](#ports-sockets--listening-services)
- [DNS Resolution & Name Lookup](#dns-resolution--name-lookup)
- [Connectivity Testing](#connectivity-testing)
- [File Transfer Over Network](#file-transfer-over-network)
- [Firewall Basics (firewalld)](#firewall-basics-firewalld)
- [Common Networking Mistakes](#common-networking-mistakes)

### [Part 2: Advanced Networking & Troubleshooting](#part-2-advanced-networking--troubleshooting-beginner--advanced)
- [Linux Networking Stack](#linux-networking-stack-mental-model)
- [Advanced Socket Inspection](#advanced-socket-inspection-with-ss)
- [Firewall Deep Dive](#firewall-deep-dive-firewalld--rich-rules)
- [Packet Capture & Traffic Analysis](#packet-capture--traffic-analysis-with-tcpdump)
- [Security & Port Scan Detection](#security--port-scan-detection)
- [Bandwidth and Throughput Analysis](#bandwidth-and-throughput-analysis)
- [Advanced Routing & Network Namespaces](#advanced-routing--network-namespaces)
- [Production Debug Checklist](#production-debug-checklist)
- [Performance Tuning](#performance-and-network-tuning)
- [Security Hardening](#security-and-hardening)

---

## Part 1: Linux Networking Basics (For Everyone)

### Network Interfaces & IP Addresses

> **🎯 Foundation:** Everything in networking starts with understanding your interfaces. If an interface has the wrong IP, nothing else will work correctly.

| Command | Description | Use Case |
|---------|-------------|----------|
| `ip a` | Show all network interfaces | Complete interface information |
| `ip -br a` | Compact, readable output | Quick interface status check |
| `ip link show up` | Show only active interfaces | Filter active interfaces |
| `ifconfig` | Legacy command (avoid in automation) | Backward compatibility |

#### Essential Interface Commands

```bash
# List all network interfaces with details
ip a

# Compact, readable format (recommended)
ip -br a

# Show only active/up interfaces
ip link show up

# Legacy method (less preferred)
ifconfig

# Show specific interface details
ip addr show eth0
ip -s link show eth0  # With statistics
```

#### Interface Status Check
```bash
# Check if interface is up/down
ip link show eth0 | grep -E "state UP|state DOWN"

# Get interface statistics
ip -s link show eth0

# Show MAC address
ip link show eth0 | grep link/ether
```

### Routes & Gateways

> **⚠️ Critical:** Most "connection issues" are simply missing or incorrect routes.

| Command | Description | Example |
|---------|-------------|---------|
| `ip route` | Display routing table | Complete routing info |
| `ip route show default` | Show default gateway | Default route only |
| `ip route get 8.8.8.8` | Check route to destination | Test specific route |

#### Route Management

```bash
# Display complete routing table
ip route

# Show only default gateway
ip route show default

# Check how system routes traffic to destination
ip route get 8.8.8.8

# Show routes for specific interface
ip route show dev eth0

# Add temporary route (not persistent)
ip route add 192.168.1.0/24 via 192.168.0.1 dev eth0

# Delete route
ip route del 192.168.1.0/24
```

#### Route Debugging
```bash
# Trace route to destination (shows each hop)
traceroute 8.8.8.8

# More detailed tracing with timestamps
mtr 8.8.8.8

# Check routing table in real-time
watch -n 2 'ip route'
```

### Ports, Sockets & Listening Services

> **🔍 Port Intelligence:** `ss` is faster, more accurate, and should always be preferred over `netstat`.

| Command | Description | Output |
|---------|-------------|---------|
| `ss -lntup` | Modern replacement for netstat | All listening sockets |
| `ss -lntp` | Check specific port | Filtered listening |
| `ss -s` | Connection statistics | Summary stats |

#### Socket Inspection

```bash
# Modern replacement for netstat - show all listening TCP/UDP
ss -lntup

# Check specific port
ss -lntp | grep :80

# Show only TCP listening sockets
ss -ltn

# Show established connections
ss -ant state established

# Show connections in TIME_WAIT (often normal)
ss -ant state time-wait

# Count all connections
ss -ant | wc -l

# Show socket statistics
ss -s
```

#### Advanced Socket Analysis
```bash
# Show connections for specific process
ss -ltnp | grep :22

# Show UDP sockets
ss -lunp

# Filter by connection state
ss -ant state listening
ss -ant state established
ss -ant state time-wait

# Show detailed socket information
ss -i
ss -ie
```

### DNS Resolution & Name Lookup

> **🌐 DNS Diagnosis:** If an IP address works but hostname doesn't, the problem is DNS.

| Command | Description | Example |
|---------|-------------|---------|
| `dig domain.com` | Query DNS records | Complete DNS info |
| `dig +short domain.com` | Short output only | Just the answer |
| `getent hosts domain.com` | Use system resolver | System config |

#### DNS Troubleshooting

```bash
# Resolve domain name
dig google.com

# Short output only
dig +short google.com

# Query specific record type
dig google.com MX
dig google.com A
dig google.com AAAA

# Use system resolver configuration
getent hosts google.com

# Check resolver configuration
cat /etc/resolv.conf

# Test DNS server directly
nslookup google.com 8.8.8.8

# Query with specific DNS server
dig @8.8.8.8 google.com
```

#### DNS Configuration
```bash
# Flush DNS cache (systemd-resolved)
systemd-resolve --flush-caches

# Show DNS statistics
systemd-resolve --status

# Check /etc/hosts file
cat /etc/hosts

# Test local DNS resolution
getent ahosts localhost
```

### Connectivity Testing

| Tool | Command | Purpose | Example |
|------|---------|---------|---------|
| **ping** | `ping -c 4 8.8.8.8` | Basic connectivity | Test reachability |
| **traceroute** | `traceroute domain.com` | Path tracing | Find network hops |
| **mtr** | `mtr domain.com` | Real-time tracing | Continuous analysis |
| **curl** | `curl -I https://example.com` | HTTP connectivity | Web service test |
| **nc** | `nc -zv host 5432` | TCP port test | Service availability |

#### Connection Testing

```bash
# Basic connectivity test
ping -c 4 8.8.8.8

# Continuous ping
ping 8.8.8.8

# Trace network path
traceroute google.com

# Real-time tracing (combines ping + traceroute)
mtr google.com

# HTTP connectivity check
curl -I https://example.com

# Test TCP port availability
nc -zv google.com 443

# Test specific port range
nc -zv google.com 80 443 8080

# UDP port test
nc -zvu host 53
```

#### Advanced Connectivity
```bash
# Test with custom source IP
ping -I eth0 8.8.8.8

# Test with packet size
ping -s 1472 8.8.8.8

# Trace with specific protocol
traceroute -I google.com  # ICMP
traceroute -T google.com   # TCP
traceroute -U google.com  # UDP

# Web service detailed test
curl -v https://api.example.com/health
curl -w "@curl-format.txt" -o /dev/null -s http://example.com
```

### File Transfer Over Network

> **📦 Transfer Tools:** In production environments, `rsync` should be preferred for efficiency and reliability.

| Tool | Command | Use Case | Advantages |
|------|---------|----------|------------|
| **scp** | `scp file.txt user@host:/path` | Simple file transfer | Quick, secure |
| **rsync** | `rsync -avz dir/ user@host:/dir` | **Recommended** | Efficient, resumable |

#### File Transfer Methods

```bash
# Copy a single file
scp file.txt user@host:/path/to/destination/

# Copy a directory recursively
scp -r dir user@host:/path/to/destination/

# Copy with compression
scp -C file.txt user@host:/path/

# Use specific SSH key
scp -i ~/.ssh/id_rsa file.txt user@host:/path/

# Efficient and resumable transfer (RECOMMENDED)
rsync -avz dir/ user@host:/dir/

# Sync with progress and compression
rsync -avzP dir/ user@host:/dir/

# Exclude specific patterns
rsync -avz --exclude='*.log' dir/ user@host:/dir/

# Dry run (preview changes)
rsync -avz --dry-run dir/ user@host:/dir/
```

#### Advanced Transfer Options
```bash
# Preserve permissions and timestamps
rsync -avzp dir/ user@host:/dir/

# Delete files in destination not in source
rsync -avz --delete dir/ user@host:/dir/

# Bandwidth limiting
rsync -avz --bwlimit=1000 dir/ user@host:/dir/

# Resume interrupted transfer
rsync -avzP --partial dir/ user@host:/dir/

# Transfer over custom SSH port
rsync -avz -e "ssh -p 2222" dir/ user@host:/dir/
```

### Firewall Basics (firewalld)

> **🔥 Firewall Management:** Permanent rules are not active until the firewall is reloaded.

| Command | Description | Example |
|---------|-------------|---------|
| `firewall-cmd --get-active-zones` | Show active zones | Zone overview |
| `firewall-cmd --zone=public --list-all` | List zone rules | Current rules |
| `firewall-cmd --permanent --add-port=5000/tcp` | Add port rule | Open service |

#### Basic Firewall Commands

```bash
# Show active zones
firewall-cmd --get-active-zones

# List current rules for a zone
firewall-cmd --zone=public --list-all

# Open a TCP port temporarily (immediate effect)
firewall-cmd --add-port=5000/tcp

# Open a TCP port permanently (survives reboot)
firewall-cmd --permanent --add-port=5000/tcp

# Reload to apply permanent rules
firewall-cmd --reload

# Open service instead of port
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https

# Remove port/service
firewall-cmd --permanent --remove-port=5000/tcp
firewall-cmd --permanent --remove-service=http
```

#### Zone Management
```bash
# List all available zones
firewall-cmd --get-zones

# Set default zone
firewall-cmd --set-default-zone=public

# Add interface to specific zone
firewall-cmd --zone=public --add-interface=eth0

# Add source to zone (IP-based rules)
firewall-cmd --zone=public --add-source=192.168.1.0/24
```

### Common Networking Mistakes

> **⚠️ Learn from These:** Avoid these common pitfalls that cause networking issues.

#### The Big Five Mistakes

| ❌ Mistake | ✅ Solution | Why It Matters |
|------------|-------------|----------------|
| **Assuming service = open port** | Verify with `ss -lntup` | Service can be down/restarting |
| **Forgetting firewall rules** | Check `firewall-cmd --list-all` | Most connection issues are firewall-related |
| **Testing domains before IPs** | Test IP first, then domain | Separates DNS from connectivity |
| **Ignoring routing table** | Check `ip route get dest` | Wrong routes break connectivity |
| **Running tcpdump without filters** | Always use `-n` and port filters | Production tcpdump can overwhelm system |

#### Debugging Approach
```bash
# 1. Check interface status first
ip -br a

# 2. Verify routing
ip route get target.ip

# 3. Test connectivity
ping -c 1 target.ip

# 4. Check if port is listening
ss -lntp | grep :port

# 5. Check firewall
firewall-cmd --zone=public --list-all

# 6. Trace the path
traceroute target.ip
```

---

## Part 2: Advanced Networking & Troubleshooting (Beginner → Advanced)

### Linux Networking Stack (Mental Model)

> **🧠 Troubleshooting Rule:** Always start from the bottom and move upward.

#### Network Stack Layers

```
┌─────────────────┐    Application Layer
│   Application   │    (Your software)
├─────────────────┤
│     Socket      │    API Layer
├─────────────────┤    (TCP/UDP connections)
│   TCP / UDP     │    (Transport Layer)
├─────────────────┤
│       IP        │    Network Layer
├─────────────────┤    (Routing, addressing)
│      NIC        │    Link Layer
├─────────────────┤    (Network interface)
│   Physical NIC  │    Hardware Layer
└─────────────────┘    (Network card)
```

#### Layer-by-Layer Troubleshooting

```bash
# Layer 4: Application - Check if process is running
ps aux | grep service-name

# Layer 3: Socket - Check if port is listening
ss -lntp | grep :port

# Layer 2: TCP/UDP - Test connection establishment
nc -zv host port

# Layer 1: IP - Check routing and connectivity
ip route get destination
ping -c 1 destination

# Layer 0: Physical - Check interface status
ip link show interface
ethtool interface
```

### Advanced Socket Inspection with ss

> **🔬 Deep Analysis:** `ss` provides detailed socket information that `netstat` cannot match.

#### Connection State Analysis

```bash
# List all TCP connections with details
ss -ant

# Show only established connections
ss -ant state established

# Inspect TIME_WAIT sockets (often normal)
ss -ant state time-wait

# Show SYN-SENT connections (establishing)
ss -ant state syn-sent

# Count connections by state
ss -ant state all | awk '{print $1}' | sort | uniq -c

# Show connections for specific user
ss -ant | grep username
```

#### Advanced Filtering

```bash
# Filter by destination port
ss -ant dst :443
ss -ant dst 192.168.1.100:80

# Filter by source address
ss -ant src 192.168.1.0/24

# Combine filters
ss -ant dst :443 and src 192.168.1.0/24

# Show process information
ss -ltnp

# Show memory usage per socket
ss -mt

# Show timer information
ss -to
```

#### Socket Statistics
```bash
# Summary statistics
ss -s

# Detailed memory information
ss -m

# Show timer details
ss -t

# Extended socket information
ss -i
ss -ie
ss -ip
```

### Firewall Deep Dive (firewalld & rich rules)

> **🛡️ Advanced Rules:** Use rich rules for complex firewall scenarios with logging and specific conditions.

#### Rich Rules for Complex Scenarios

```bash
# Allow specific IP to access port (rich rule)
firewall-cmd --permanent --zone=public \
  --add-rich-rule='rule family="ipv4" source address="192.168.1.100" port port="5000" protocol="tcp" accept'

# Allow entire subnet
firewall-cmd --permanent --zone=public \
  --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port port="5000" protocol="tcp" accept'

# Remove rich rule
firewall-cmd --permanent --zone=public \
  --remove-rich-rule='rule family="ipv4" source address="192.168.1.100" port port="5000" protocol="tcp" accept'

# List all rich rules
firewall-cmd --zone=public --list-rich-rules
```

#### Advanced Rich Rule Examples

```bash
# Log and accept specific traffic
firewall-cmd --permanent --zone=public \
  --add-rich-rule='rule family="ipv4" source address="192.168.1.100" port port="22" protocol="tcp" accept log prefix="SSH-ACCESS"'

# Rate limiting (limit connection attempts)
firewall-cmd --permanent --zone=public \
  --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port port="22" protocol="tcp" accept limit value="5/m"'

# Reject with specific message
firewall-cmd --permanent --zone=public \
  --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port port="23" protocol="tcp" reject type="icmp-admin-prohibited"'

# Allow specific service with time restriction
firewall-cmd --permanent --zone=public \
  --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" service name="ssh" accept'

# Forward traffic (DNAT)
firewall-cmd --permanent --zone=external \
  --add-rich-rule='rule family="ipv4" destination address="203.0.113.1" port port="80" protocol="tcp" forward-port port="8080" to-addr="192.168.1.100"'
```

#### Logging and Monitoring

```bash
# Enable audit logging
firewall-cmd --set-log-denied=all

# Check kernel firewall logs
journalctl -k | grep -i firewalld

# Monitor firewall activity in real-time
journalctl -k -f | grep -i drop

# Check firewalld status
firewall-cmd --state
firewall-cmd --get-log-denied
```

### Packet Capture & Traffic Analysis with tcpdump

> **📊 Packet Analysis:** Always use filters to limit capture scope in production environments.

#### Essential tcpdump Commands

```bash
# Capture traffic on specific interface
tcpdump -i eth0 -n -s 0 port 5000

# Write capture to file
tcpdump -i eth0 -n -s 0 port 5000 -w /tmp/port5000.pcap

# View ASCII payload
tcpdump -i eth0 -n -s 0 -A tcp port 5000

# View hex and ASCII
tcpdump -i eth0 -n -s 0 -X tcp port 5000

# Capture with timestamps
tcpdump -i eth0 -n -s 0 -tttt port 5000

# Limit file size and rotate
tcpdump -i eth0 -n -s 0 -C 100 -W 10 -w /tmp/capture port 5000
```

#### Advanced Filtering

```bash
# Filter by source/destination IP
tcpdump -i eth0 -n src 192.168.1.100
tcpdump -i eth0 -n dst 8.8.8.8

# Filter by network
tcpdump -i eth0 -n net 192.168.1.0/24

# Filter by protocol
tcpdump -i eth0 -n tcp port 80
tcpdump -i eth0 -n udp port 53
tcpdump -i eth0 -n icmp

# Complex filtering
tcpdump -i eth0 -n 'tcp port 80 and host 192.168.1.100'
tcpdump -i eth0 -n 'tcp port 80 and not host 192.168.1.100'
tcpdump -i eth0 -n 'tcp port 80 and (host 192.168.1.100 or host 192.168.1.101)'
```

#### Performance and Production Considerations

```bash
# Capture with ring buffer
tcpdump -i eth0 -n -s 0 -G 3600 -W 24 -w /tmp/hourly_%Y%m%d_%H%M%S.pcap port 5000

# Use BPF filter for efficiency
tcpdump -i eth0 -n -s 0 'tcp[tcpflags] & tcp-syn != 0' port 80

# Monitor HTTP requests
tcpdump -i eth0 -n -A 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)' | grep -E 'GET|POST|HTTP'
```

### Security & Port Scan Detection

> **🔒 Security Analysis:** Detect malicious activity and network scans.

#### Port Scan Detection

```bash
# Detect SYN-only packets (SYN scan)
tcpdump -i eth0 -n 'tcp[13] & 2 != 0 and tcp[13] & 16 == 0'

# Detect NULL scans
tcpdump -i eth0 -n 'tcp[13] == 0'

# Detect FIN scans
tcpdump -i eth0 -n 'tcp[13] & 1 != 0'

# Detect XMAS scans (all flags set)
tcpdump -i eth0 -n 'tcp[13] & 1 != 0 and tcp[13] & 2 != 0 and tcp[13] & 4 != 0 and tcp[13] & 8 != 0 and tcp[13] & 16 != 0'

# Detect empty payload traffic
tcpdump -i eth0 -n tcp port 80 | grep "length 0"

# Monitor broadcast/multicast traffic
tcpdump -i eth0 -n 'broadcast or multicast'
```

#### Security Monitoring Commands

```bash
# Monitor failed SSH attempts
tcpdump -i eth0 -n -A 'tcp port 22 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)' | grep -E 'Failed|Permission'

# Track connection attempts to closed ports
ss -ant | grep ':445\|:139\|:135'

# Monitor suspicious traffic patterns
netstat -an | awk '$1 ~ /tcp/ && $6 == "SYN_SENT" {print $5}' | sort | uniq -c | sort -nr

# Check for port scanning activity
ss -ant | awk '{print $5}' | grep -E '^\d+\.\d+\.\d+\.\d+' | cut -d: -f1 | sort | uniq -c | sort -nr
```

### Bandwidth and Throughput Analysis

> **📈 Performance Metrics:** Latency checks do not measure bandwidth - use dedicated tools for throughput analysis.

#### Interface Statistics

```bash
# Interface statistics with packet counts
ip -s link

# Detailed interface statistics
ip -s -s link show eth0

# Historical statistics
cat /proc/net/dev

# Check for interface errors
ip -s link show eth0 | grep -E 'errors|dropped|overruns'
```

#### Real-time Monitoring

```bash
# Install and use nload for real-time bandwidth
nload eth0

# Use nethogs for process-level traffic
nethogs

# Use iftop for connection-level monitoring
iftop -i eth0

# Use bmon for comprehensive bandwidth monitoring
bmon
```

#### Throughput Testing

```bash
# Server setup (on one machine)
iperf3 -s

# Client test (from another machine)
iperf3 -c server-ip

# Test with specific duration
iperf3 -c server-ip -t 30

# Test with parallel streams
iperf3 -c server-ip -P 4

# UDP throughput test
iperf3 -c server-ip -u

# Reverse test (server sends to client)
iperf3 -c server-ip -R
```

#### Advanced Throughput Analysis

```bash
# Test with specific packet size
iperf3 -c server-ip -l 8K

# Test with TCP window scaling
iperf3 -c server-ip -w 1M

# Generate iperf3 report with timestamps
iperf3 -c server-ip -f K -t 10 > iperf_report.txt

# Test network latency and jitter
ping -c 100 -i 0.1 8.8.8.8

# Test path MTU
ping -M do -s 1472 8.8.8.8
```

### Advanced Routing & Network Namespaces

> **🌐 Network Isolation:** Containers rely heavily on namespaces for network isolation.

#### Policy Routing

```bash
# Show policy routing rules
ip rule show

# Show all routing tables
ip route show table all

# Show routing table for specific table
ip route show table main
ip route show table local

# Add route to specific table
ip route add 192.168.1.0/24 via 192.168.0.1 dev eth0 table 100

# Add rule to use specific table
ip rule add from 192.168.1.0/24 table 100
```

#### Network Namespaces

```bash
# List network namespaces
ip netns list

# Create network namespace
ip netns add ns1

# Execute command in namespace
ip netns exec ns1 bash

# Create virtual ethernet pair
ip link add veth0 type veth peer name veth1

# Assign interfaces to namespaces
ip link set veth1 netns ns1

# Configure interface in namespace
ip netns exec ns1 ip addr add 192.168.1.1/24 dev veth1
ip netns exec ns1 ip link set veth1 up
```

#### Advanced Namespace Configuration

```bash
# Set up loopback in namespace
ip netns exec ns1 ip link set lo up

# Create bridge and add namespace interfaces
ip link add br0 type bridge
ip link set veth1 master br0
ip netns exec ns1 ip link set veth1 master br0
ip link set br0 up

# Add IP to bridge
ip addr add 192.168.1.0/24 dev br0

# Configure default gateway in namespace
ip netns exec ns1 ip route add default via 192.168.1.1
```

### Production Debug Checklist

> **🔧 Systematic Approach:** Skipping steps leads to incorrect conclusions. Follow this checklist in order.

#### Complete Debug Checklist

```bash
# 1. Interface state
ip -br a

# 2. IP configuration
ip addr show interface

# 3. Routing table
ip route
ip route get target.ip

# 4. Listening services
ss -lntup

# 5. Firewall rules
firewall-cmd --list-all
iptables -L -n

# 6. Packet arrival
tcpdump -i interface -n port port

# 7. Kernel and firewall logs
journalctl -k | grep -i drop
dmesg | grep -i network

# 8. DNS resolution
getent hosts domain.com
dig domain.com

# 9. Connectivity test
ping -c 1 target.ip
nc -zv target.ip port

# 10. Service status
systemctl status service-name
```

#### Automated Health Check Script

```bash
#!/bin/bash
# Network Health Check Script

echo "=== Network Health Check ==="
echo "Timestamp: $(date)"
echo

echo "1. Interface Status:"
ip -br a
echo

echo "2. Default Route:"
ip route show default
echo

echo "3. DNS Configuration:"
cat /etc/resolv.conf
echo

echo "4. Active Connections:"
ss -tuln | head -10
echo

echo "5. Firewall Status:"
if command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --state
    firewall-cmd --list-all
else
    echo "firewalld not installed"
fi
echo

echo "6. Service Status:"
systemctl is-active networking
systemctl is-active NetworkManager
echo

echo "7. Recent Network Logs:"
journalctl -k --since "1 hour ago" | tail -5
```

### Performance and Network Tuning

> **⚡ Optimization:** Check NIC offloading features and tune for your workload.

#### Network Interface Optimization

```bash
# Check NIC offloading features
ethtool -k eth0

# Check link speed and duplex
ethtool eth0

# Set interface speed (if needed)
ethtool -s eth0 speed 1000 duplex full autoneg off

# Check ring buffer settings
ethtool -g eth0

# Modify ring buffer (if supported)
ethtool -G eth0 rx 4096 tx 4096

# Monitor queue disciplines
tc qdisc show
```

#### Advanced Interface Analysis

```bash
# Show interrupt coalescing settings
ethtool -c eth0

# Show hardware features
ethtool -k eth0

# Show driver information
ethtool -i eth0

# Show statistics
ethtool -S eth0

# Perform self-test
ethtool -t eth0
```

#### Traffic Control (TC)

```bash
# Show current qdisc
tc qdisc show

# Add traffic shaping
tc qdisc add dev eth0 root handle 1: htb default 12
tc class add dev eth0 parent 1: classid 1:1 htb rate 100mbit
tc class add dev eth0 parent 1:1 classid 1:10 htb rate 50mbit ceil 100mbit
tc class add dev eth0 parent 1:1 classid 1:12 htb rate 50mbit ceil 100mbit

# Add filter for specific traffic
tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dport 22 flowid 1:10
```

### Security Hardening

> **🔒 Defense Strategy:** Close unused ports, log suspicious connections, and block scanners early.

#### Security Best Practices

```bash
# Close unused ports
firewall-cmd --list-all
firewall-cmd --permanent --remove-service=ftp  # If not needed
firewall-cmd --permanent --remove-service=telnet  # If not needed

# Log suspicious connections
firewall-cmd --set-log-denied=all

# Block scanners early
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.0.0/8" drop'

# Monitor active connections regularly
ss -ant | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr
```

#### Advanced Security Rules

```bash
# Rate limiting for SSH
firewall-cmd --permanent --zone=public \
  --add-rich-rule='rule service name="ssh" limit value="10/m" accept'

# Block brute force attacks
firewall-cmd --permanent --zone=public \
  --add-rich-rule='rule source address="192.168.1.100" service name="ssh" reject'

# Log and drop
firewall-cmd --permanent --zone=public \
  --add-rich-rule='rule service name="ssh" log prefix="SSH-DROP" level="warning" drop'

# Block entire networks if needed
firewall-cmd --permanent --zone=block \
  --add-source=192.168.100.0/24
```

#### Security Monitoring

```bash
# Monitor failed login attempts
journalctl -u sshd | grep "Failed password"

# Track connection attempts to closed ports
ss -ant | grep -E ':445|:139|:135|:1433|:3389'

# Monitor for port scans
tcpdump -i eth0 -n 'tcp[13] & 2 != 0 and tcp[13] & 16 == 0' | awk '{print $3}' | cut -d. -f1-4 | sort | uniq -c

# Check for unusual traffic patterns
netstat -an | awk '$1 ~ /tcp/ && $6 == "ESTABLISHED" {print $5}' | cut -d: -f1 | sort | uniq -c | awk '$1 > 100 {print $2}'
```

---

## 🎯 Golden Rules & Pro Tips

### The Golden Rule
> **Start troubleshooting from the bottom layer and work your way up. Network problems cascade down - fix the foundation first.**

### Essential Networking Commands Summary

```bash
# Interface and IP configuration
ip -br a                    # Quick interface overview
ip route get target         # Check routing to target
ss -lntup                  # All listening sockets
dig domain.com             # DNS resolution
ping -c 1 target           # Basic connectivity
nc -zv target port         # Port availability

# Firewall management
firewall-cmd --list-all    # Current firewall state
firewall-cmd --reload      # Apply permanent changes

# Traffic analysis
tcpdump -i eth0 -n port 80  # Capture HTTP traffic
mtr target                 # Real-time traceroute
iperf3 -c target           # Bandwidth testing

# Troubleshooting
journalctl -k | grep -i drop  # Kernel logs
tc qdisc show              # Traffic control status
ethtool eth0              # Network interface details
```

### Performance Optimization Checklist

1. **Check interface status** - Ensure links are up with correct speed/duplex
2. **Verify routing** - Ensure proper routes exist for all destinations
3. **Monitor connection states** - Watch for connection limits and timeouts
4. **Analyze traffic patterns** - Use tcpdump to understand traffic flow
5. **Tune TCP parameters** - Adjust buffers and timeouts for your workload
6. **Monitor NIC offloading** - Ensure hardware acceleration is working
7. **Implement QoS** - Use traffic control for bandwidth management

### Security Best Practices

1. **Principle of least privilege** - Only open necessary ports
2. **Monitor continuously** - Watch for unusual traffic patterns
3. **Log everything** - Enable detailed logging for security events
4. **Block scanners early** - Use fail2ban and firewall rules
5. **Regular audits** - Review firewall rules and open ports
6. **Keep systems updated** - Apply security patches promptly
6. **Segment networks** - Use VLANs and network namespaces

---

## 📖 Final Thoughts

Linux networking is a powerful and complex topic that rewards systematic understanding:

**🧠 Master the fundamentals** - Interface configuration, routing, and DNS form the foundation of all network troubleshooting.

**🔧 Practice with tools** - `ip`, `ss`, `tcpdump`, and `firewall-cmd` are your essential toolkit.

**📊 Analyze systematically** - Follow the network stack from bottom to top when troubleshooting.

**🔒 Security first** - Always consider security implications when configuring network services.

**📈 Monitor continuously** - Network problems often appear suddenly - proactive monitoring prevents outages.

**This cheat sheet covers 50+ networking techniques** - You don't need to memorize them all. Bookmark it for reference when facing specific challenges!

**Remember:** Network problems tend to recur. The patterns you learn today will help you solve tomorrow's issues faster.

**Happy networking!** 🚀