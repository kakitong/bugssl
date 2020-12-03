#!/bin/sh
# Script by FordSenpai

wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg|apt-key add -
sleep 2
echo "deb http://build.openvpn.net/debian/openvpn/release/2.4 stretch main" > /etc/apt/sources.list.d/openvpn-aptrepo.list
#Requirement
apt update
apt upgrade -y
apt install openvpn nginx php7.0-fpm stunnel4 privoxy squid3 dropbear easy-rsa vnstat ufw build-essential fail2ban zip -y

# initializing var
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";
cd /root
wget "https://raw.githubusercontent.com/TholhahZabri/VPS-Scripts/master/D9SSL/plugin.tgz"
wget "https://raw.githubusercontent.com/TholhahZabri/VPS-Scripts/master/D9SSL/bashmenu.zip"

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6


# set time GMT +8
ln -fs /usr/share/zoneinfo/Asia/Manila /etc/localtime

# install webmin
cd
wget "https://nchc.dl.sourceforge.net/project/webadmin/webmin/1.920/webmin_1.920_all.deb"
dpkg --install webmin_1.920_all.deb;
apt-get -y -f install;
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
rm /root/webmin_1.920_all.deb
service webmin restart

# install screenfetch
cd
wget -O /usr/bin/screenfetch "https://raw.githubusercontent.com/TholhahZabri/VPS-Scripts/master/D9SSL/screenfetch"
chmod +x /usr/bin/screenfetch
echo "clear" >> .profile
echo "screenfetch" >> .profile

# install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=442/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells

# install privoxy
cat > /etc/privoxy/config <<-END
user-manual /usr/share/doc/privoxy/user-manual
confdir /etc/privoxy
logdir /var/log/privoxy
filterfile default.filter
logfile logfile
listen-address  0.0.0.0:3356
listen-address  0.0.0.0:8086
toggle  1
enable-remote-toggle  0
enable-remote-http-toggle  0
enable-edit-actions 0
enforce-blocks 0
buffer-limit 4096
enable-proxy-authentication-forwarding 1
forwarded-connect-retries  1
accept-intercepted-requests 1
allow-cgi-request-crunching 1
split-large-forms 0
keep-alive-timeout 5
tolerate-pipelining 1
socket-timeout 300
permit-access 0.0.0.0/0 xxxxxxxxx
END
sed -i $MYIP2 /etc/privoxy/config;

# install squid3
cat > /etc/squid/squid.conf <<-END
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl localnet src 10.0.0.0/8
acl localnet src 172.16.0.0/12
acl localnet src 192.168.0.0/16
acl localnet src fc00::/7
acl localnet src fe80::/10
acl ads url_regex -i "/etc/squid/ads.txt"
acl malware url_regex -i "/etc/squid/malware.txt"
http_access deny ads
http_access deny malware
acl SSL_ports port 80-8085
acl Safe_ports port 110
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 444
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
acl SSH dst xxxxxxxxx-xxxxxxxxx/32
acl SSH dst 103.103.0.118-103.103.0.118/32
http_access allow SSH
http_access allow localnet
http_access allow manager localhost
http_access deny manager
http_access allow localhost
http_access deny all
http_port 8085
http_port 3355
coredump_dir /var/spool/squid3
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
visible_hostname FordSenpai
END
sed -i $MYIP2 /etc/squid/squid.conf;

# deny ads
cat > /etc/squid/ads.txt <<-END
zyrdu.cruisingsmallship.com
END

# setting banner
rm /etc/issue.net
wget -O /etc/issue.net "https://raw.githubusercontent.com/TholhahZabri/VPS-Scripts/master/D9SSL/issue.net"
sed -i 's@#Banner@Banner@g' /etc/ssh/sshd_config
sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/issue.net"@g' /etc/default/dropbear
service ssh restart
service dropbear restart

# install badvpn
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/TholhahZabri/VPS-Scripts/master/D9SSL/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/TholhahZabri/VPS-Scripts/master/D9SSL/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

#install OpenVPN
cp -r /usr/share/easy-rsa/ /etc/openvpn
mkdir /etc/openvpn/easy-rsa/keys

# replace bits
sed -i 's|export KEY_COUNTRY="US"|export KEY_COUNTRY="PH"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_PROVINCE="CA"|export KEY_PROVINCE="Davao Del Sur"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_CITY="SanFrancisco"|export KEY_CITY="Davao City"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_ORG="Fort-Funston"|export KEY_ORG="Team Vmodz"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_EMAIL="me@myhost.mydomain"|export KEY_EMAIL="kerobby.vmodz@gmail.com"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU="MyOrganizationalUnit"|export KEY_OU="Team Vmodz-Glitch"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_NAME="EasyRSA"|export KEY_NAME="Status404Error"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU=changeme|export KEY_OU=Team Vmodz-Glitch|' /etc/openvpn/easy-rsa/vars

#Create Diffie-Helman Pem
openssl dhparam -out /etc/openvpn/dh1024.pem 1024
# Create PKI
cd /etc/openvpn/easy-rsa
cp openssl-1.0.0.cnf openssl.cnf
. ./vars
./clean-all
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --initca $*
# create key server
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --server server
# setting KEY CN
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" client
cd
#cp /etc/openvpn/easy-rsa/keys/{server.crt,server.key} /etc/openvpn
cp /etc/openvpn/easy-rsa/keys/server.crt /etc/openvpn/server.crt
cp /etc/openvpn/easy-rsa/keys/server.key /etc/openvpn/server.key
cp /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn/ca.crt

# Change Certificate
cd /etc/openvpn/
rm -Rf easy-rsa
rm -Rf ca.crt
rm -Rf server.crt
rm -Rf server.key
rm -Rf dh1024.pem
wget -q https://raw.githubusercontent.com/TholhahZabri/VPS-Scripts/master/D9SSL/certs.zip -O certs.zip
unzip certs.zip

cd

chmod +x /etc/openvpn/ca.crt

# Setting Server
tar -xzvf /root/plugin.tgz -C /usr/lib/openvpn/
chmod +x /usr/lib/openvpn/*
cat > /etc/openvpn/server.conf <<-END
port 110
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh1024.pem
verify-client-cert none
username-as-common-name
key-direction 0
plugin /usr/lib/openvpn/plugins/openvpn-plugin-auth-pam.so login
server 192.168.10.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "route-method exe"
push "route-delay 2"
keepalive 10 120
comp-lzo
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
log openvpn.log
verb 3
ncp-disable
cipher none
auth none

END
systemctl start openvpn@server
#Create OpenVPN Config
mkdir -p /home/vps/public_html
cat > /home/vps/public_html/sun-tuctc.ovpn <<-END
# Vmodz Script
# By: FordSenpai
auth-user-pass
client
dev tun
proto tcp-client
remote $MYIP 110
nobind
persist-key
persist-tun
comp-lzo
keepalive 10 120
tls-client
remote-cert-tls server
verb 3
auth-user-pass
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0
redirect-gateway def1
dhcp-option DNS 1.1.1.1
dhcp-option DNS 1.0.0.1
http-proxy $MYIP 3356
http-proxy-option CUSTOM-HEADER ""
http-proxy-option CUSTOM-HEADER "POST https://viber.com HTTP/1.0"

END
echo '<ca>' >> /home/vps/public_html/sun-tuctc.ovpn
cat /etc/openvpn/ca.crt >> /home/vps/public_html/sun-tuctc.ovpn
echo '</ca>' >> /home/vps/public_html/sun-tuctc.ovpn

cat > /home/vps/public_html/noload.ovpn <<-END
# Vmodz Script
# By: FordSenpai
auth-user-pass
client
dev tun
proto tcp-client
remote $MYIP 110
persist-key
persist-tun
comp-lzo
bind
float
remote-cert-tls server
verb 3
auth-user-pass
redirect-gateway def1
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0
dhcp-option DNS 1.1.1.1
dhcp-option DNS 1.0.0.1

END
echo '<ca>' >> /home/vps/public_html/noload.ovpn
cat /etc/openvpn/ca.crt >> /home/vps/public_html/noload.ovpn
echo '</ca>' >> /home/vps/public_html/noload.ovpn

cat > /home/vps/public_html/fixplan.ovpn <<-END
# Vmodz Script
# By: FordSenpai
auth-user-pass
client
dev tun
proto tcp-client
remote $MYIP 110
nobind
persist-key
persist-tun
comp-lzo
keepalive 10 120
tls-client
remote-cert-tls server
verb 3
auth-user-pass
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0
redirect-gateway def1
dhcp-option DNS 1.1.1.1
dhcp-option DNS 1.0.0.1
http-proxy $MYIP 3356
http-proxy-option CUSTOM-HEADER ""
http-proxy-option CUSTOM-HEADER "POST https://viber.com HTTP/1.1"
http-proxy-option CUSTOM-HEADER "Proxy-Connection: Keep-Alive"

END
echo '<ca>' >> /home/vps/public_html/fixplan.ovpn
cat /etc/openvpn/ca.crt >> /home/vps/public_html/fixplan.ovpn
echo '</ca>' >> /home/vps/public_html/fixplan.ovpn

cat > /home/vps/public_html/default.ovpn <<-END
# Vmodz Script
# By: FordSenpai
auth-user-pass
client
dev tun
proto tcp-client
remote $MYIP 110
nobind
persist-key
persist-tun
comp-lzo
keepalive 10 120
tls-client
remote-cert-tls server
verb 3
auth-user-pass
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
reneg-sec 0
redirect-gateway def1
dhcp-option DNS 1.1.1.1
dhcp-option DNS 1.0.0.1

END
echo '<ca>' >> /home/vps/public_html/default.ovpn
cat /etc/openvpn/ca.crt >> /home/vps/public_html/default.ovpn
echo '</ca>' >> /home/vps/public_html/default.ovpn

cat > /home/vps/public_html/tu200.ovpn <<-END
# Vmodz Script
# By: FordSenpai
auth-user-pass
client
dev tun
proto tcp-client
remote $MYIP 110
nobind
persist-key
persist-tun
comp-lzo
keepalive 10 120
tls-client
remote-cert-tls server
verb 3
auth-user-pass
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0
redirect-gateway def1
dhcp-option DNS 1.1.1.1
dhcp-option DNS 1.0.0.1
http-proxy $MYIP 3355
http-proxy-option CUSTOM-HEADER CONNECT HTTP/1.0
http-proxy-option CUSTOM-HEADER Host line.telegram.me
http-proxy-option CUSTOM-HEADER X-Online-Host line.telegram.me
http-proxy-option CUSTOM-HEADER X-Forward-Host line.telegram.me
http-proxy-option CUSTOM-HEADER Connection Keep-Alive

END
echo '<ca>' >> /home/vps/public_html/tu200.ovpn
cat /etc/openvpn/ca.crt >> /home/vps/public_html/tu200.ovpn
echo '</ca>' >> /home/vps/public_html/tu200.ovpn

cat > /home/vps/public_html/gtmfbig.ovpn <<-END
# Vmodz Script
# By: FordSenpai
auth-user-pass
client
dev tun
proto tcp-client
remote $MYIP 110
nobind
persist-key
persist-tun
comp-lzo
keepalive 10 120
tls-client
remote-cert-tls server
verb 3
auth-user-pass
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0
redirect-gateway def1
dhcp-option DNS 1.1.1.1
dhcp-option DNS 1.0.0.1
http-proxy $MYIP 3356
http-proxy-option CUSTOM-HEADER "" 
http-proxy-option CUSTOM-HEADER "PUT https://s3.amazonaws.com HTTP/1.1"
http-proxy-option CUSTOM-HEADER Host s3.amazonaws.com
http-proxy-option CUSTOM-HEADER Connection Keep-Alive
http-proxy-option CUSTOM-HEADER Upgrade-Insecure-Requests: 1 

END
echo '<ca>' >> /home/vps/public_html/gtmfbig.ovpn
cat /etc/openvpn/ca.crt >> /home/vps/public_html/gtmfbig.ovpn
echo '</ca>' >> /home/vps/public_html/gtmfbig.ovpn

cat > /home/vps/public_html/sunfreeyt.ovpn <<-END
# Vmodz Script
# By: FordSenpai
auth-user-pass
client
dev tun
proto tcp
remote $MYIP 110
nobind
persist-key
persist-tun
comp-lzo
keepalive 10 120
tls-client
remote-cert-tls server
verb 3
auth-user-pass
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0
redirect-gateway def1
dhcp-option DNS 1.1.1.1
dhcp-option DNS 1.0.0.1
http-proxy $MYIP 8085
http-proxy-option CUSTOM-HEADER CONNECT HTTP/1.0
http-proxy-option CUSTOM-HEADER Host data.iflix.com
http-proxy-option CUSTOM-HEADER X-Online-Host data.iflix.com
http-proxy-option CUSTOM-HEADER X-Forward-Host data.iflix.com
http-proxy-option CUSTOM-HEADER Connection Keep-Alive

END
echo '<ca>' >> /home/vps/public_html/sunfreeyt.ovpn
cat /etc/openvpn/ca.crt >> /home/vps/public_html/sunfreeyt.ovpn
echo '</ca>' >> /home/vps/public_html/sunfreeyt.ovpn

cat > /home/vps/public_html/OpenVPN-SSL.ovpn <<-END
# Vmodz Script
# By: FordSenpai
auth-user-pass
client
dev tun
proto tcp
remote 127.0.0.1 110
route $MYIP 255.255.255.255 net_gateway
nobind
persist-key
persist-tun
comp-lzo
keepalive 10 120
tls-client
remote-cert-tls server
verb 3
auth-user-pass
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0
redirect-gateway def1
dhcp-option DNS 1.1.1.1
dhcp-option DNS 1.0.0.1

END
echo '<ca>' >> /home/vps/public_html/OpenVPN-SSL.ovpn
cat /etc/openvpn/ca.crt >> /home/vps/public_html/OpenVPN-SSL.ovpn
echo '</ca>' >> /home/vps/public_html/OpenVPN-SSL.ovpn

cat > /home/vps/public_html/JFTV-WG.conf <<-END
# Vmodz Script
# By: FordSenpai
[Interface]
PrivateKey = mP0EfgBeD0vcbx91bNamvsZF8EZkBIasYE3FvuJUw2I=
DNS = 9.9.9.9, 149.112.112.112
Address = 172.16.0.2

[Peer]
PublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
AllowedIPs = 0.0.0.0/0
AllowedIPs = ::/0
Endpoint = engage.johnfordtv.ga:2408
END
echo '<ca>' >> /home/vps/public_html/JFTV-WG.conf
cat /etc/openvpn/ca.crt >> /home/vps/public_html/JFTV-WG.conf
echo '</ca>' >> /home/vps/public_html/JFTV-WG.conf

cat > /home/vps/public_html/stunnel.conf <<-END

client = yes
debug = 6

[openvpn]
accept = 127.0.0.1:443
connect = $MYIP:587
TIMEOUTclose = 0
verify = 0
sni = www.viber.com.edgekey.net
END

# Configure Stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 -subj '/CN=127.0.0.1/O=localhost/C=PH' -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem
cat > /etc/stunnel/stunnel.conf <<-END

sslVersion = all
pid = /stunnel.pid
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
client = no

[openvpn]
accept = 443
connect = 127.0.0.1:110
cert = /etc/stunnel/stunnel.pem

[dropbear]
accept = 444
connect = 127.0.0.1:442
cert = /etc/stunnel/stunnel.pem

[openssh]
accept = 445
connect = 127.0.0.1:22
cert = /etc/stunnel/stunnel.pem

END

#Setting UFW
ufw allow ssh
ufw allow 110/tcp
sed -i 's|DEFAULT_INPUT_POLICY="DROP"|DEFAULT_INPUT_POLICY="ACCEPT"|' /etc/default/ufw
sed -i 's|DEFAULT_FORWARD_POLICY="DROP"|DEFAULT_FORWARD_POLICY="ACCEPT"|' /etc/default/ufw


# set ipv4 forward
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf

#Setting IPtables
cat > /etc/iptables.up.rules <<-END
*nat
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -j SNAT --to-source xxxxxxxxx
-A POSTROUTING -o eth0 -j MASQUERADE
-A POSTROUTING -s 192.168.10.0/24 -o eth0 -j MASQUERADE
COMMIT
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:fail2ban-ssh - [0:0]
-A INPUT -p tcp -m multiport --dports 22 -j fail2ban-ssh
-A INPUT -p ICMP --icmp-type 8 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 110 -j ACCEPT
-A INPUT -i tun0 -j ACCEPT
-A INPUT -p tcp --dport 22  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 80  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 143  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 442  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 443  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 444  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 587  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 110  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 110  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 3355  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 3355  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 8085  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 8085  -m state --state NEW -j ACCEPT 
-A INPUT -p tcp --dport 3356  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 3356  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 8086  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 8086  -m state --state NEW -j ACCEPT 
-A INPUT -p tcp --dport 10000  -m state --state NEW -j ACCEPT
-A fail2ban-ssh -j RETURN
-A OUTPUT -p icmp --icmp-type echo-request -j DROP
-A INPUT -p tcp --tcp-flags ALL NONE -j DROP
-A INPUT -p tcp --tcp-flags ALL ALL -j DROP
-A INPUT -f -j DROP
-A INPUT -p tcp ! --syn -m state --state NEW -j DROP
-A INPUT -m string --string "BitTorrent" --algo bm --to 65535 -j DROP
-A INPUT -m string --string "BitTorrent protocol" --algo bm --to 65535 -j DROP
-A INPUT -m string --string "peer_id=" --algo bm --to 65535 -j DROP
-A INPUT -m string --string ".torrent" --algo bm --to 65535 -j DROP
-A INPUT -m string --string "announce.php?passkey=" --algo bm --to 65535 -j DROP
-A INPUT -m string --string "torrent" --algo bm --to 65535 -j DROP
-A INPUT -m string --string "announce" --algo bm --to 65535 -j DROP
-A INPUT -m string --string "info_hash" --algo bm --to 65535 -j DROP
-A INPUT -m string --string "peer_id" --algo kmp --to 65535 -j DROP
-A INPUT -m string --string "BitTorrent" --algo kmp --to 65535 -j DROP
-A INPUT -m string --string "BitTorrent protocol" --algo kmp --to 65535 -j DROP
-A INPUT -m string --string "bittorrent-announce" --algo kmp --to 65535 -j DROP
-A INPUT -m string --string "announce.php?passkey=" --algo kmp --to 65535 -j DROP
-A INPUT -m string --string "find_node" --algo kmp --to 65535 -j DROP
-A INPUT -m string --string "info_hash" --algo kmp --to 65535 -j DROP
-A INPUT -m string --string "get_peers" --algo kmp --to 65535 -j DROP
-A INPUT -m string --string "announce" --algo kmp --to 65535 -j DROP
-A INPUT -m string --string "announce_peers" --algo kmp --to 65535 -j DROP
-t nat -A POSTROUTING -o eth0 -j MASQUERADE
-I OUTPUT -p tcp --dport 1723 -j ACCEPT
-A OUTPUT -p tcp --dport 6881:6889 -j DROP
-A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
-A FORWARD -p tcp --dport 6881:6889 -j DROP
-D FORWARD -m string --algo bm --string "BitTorrent" -j LOGDROP
-D FORWARD -m string --algo bm --string "BitTorrent protocol" -j LOGDROP
-D FORWARD -m string --algo bm --string "peer_id=" -j LOGDROP
-D FORWARD -m string --algo bm --string ".torrent" -j LOGDROP
-D FORWARD -m string --algo bm --string "announce.php?passkey=" -j LOGDROP
-D FORWARD -m string --algo bm --string "torrent" -j LOGDROP
-D FORWARD -m string --algo bm --string "announce" -j LOGDROP
-D FORWARD -m string --algo bm --string "info_hash" -j LOGDROP
-A FORWARD -m string --string "get_peers" --algo bm -j DROP
-A FORWARD -m string --string "announce_peer" --algo bm -j LOGDROP
-A FORWARD -m string --string "find_node" --algo bm -j LOGDROP
-A FORWARD -p udp -m string --algo bm --string "BitTorrent" -j DROP
-A FORWARD -p udp -m string --algo bm --string "BitTorrent protocol" -j DROP
-A FORWARD -p udp -m string --algo bm --string "peer_id=" -j DROP
-A FORWARD -p udp -m string --algo bm --string ".torrent" -j DROP
-A FORWARD -p udp -m string --algo bm --string "announce.php?passkey=" -j DROP
-A FORWARD -p udp -m string --algo bm --string "torrent" -j DROP 
-A FORWARD -p udp -m string --algo bm --string "announce" -j DROP
-A FORWARD -p udp -m string --algo bm --string "info_hash" -j DROP 
-A FORWARD -p udp -m string --algo bm --string "tracker" -j DROP 
-A INPUT -p udp -m string --algo bm --string "BitTorrent" -j DROP 
-A INPUT -p udp -m string --algo bm --string "BitTorrent protocol" -j DROP iptables -A INPUT -p udp -m string --algo bm --string "peer_id=" -j DROP 
-A INPUT -p udp -m string --algo bm --string ".torrent" -j DROP 
-A INPUT -p udp -m string --algo bm --string "announce.php?passkey=" -j DROP iptables -A INPUT -p udp -m string --algo bm --string "torrent" -j DROP 
-A INPUT -p udp -m string --algo bm --string "announce" -j DROP 
-A INPUT -p udp -m string --algo bm --string "info_hash" -j DROP 
-A INPUT -p udp -m string --algo bm --string "tracker" -j DROP 
-I INPUT -p udp -m string --algo bm --string "BitTorrent" -j DROP 
-I INPUT -p udp -m string --algo bm --string "BitTorrent protocol" -j DROP iptables -I INPUT -p udp -m string --algo bm --string "peer_id=" -j DROP 
-I INPUT -p udp -m string --algo bm --string ".torrent" -j DROP 
-I INPUT -p udp -m string --algo bm --string "announce.php?passkey=" -j DROP iptables -I INPUT -p udp -m string --algo bm --string "torrent" -j DROP 
-I INPUT -p udp -m string --algo bm --string "announce" -j DROP
-I INPUT -p udp -m string --algo bm --string "info_hash" -j DROP 
-I INPUT -p udp -m string --algo bm --string "tracker" -j DROP 
-D INPUT -p udp -m string --algo bm --string "BitTorrent" -j DROP 
-D INPUT -p udp -m string --algo bm --string "BitTorrent protocol" -j DROP iptables -D INPUT -p udp -m string --algo bm --string "peer_id=" -j DROP 
-D INPUT -p udp -m string --algo bm --string ".torrent" -j DROP 
-D INPUT -p udp -m string --algo bm --string "announce.php?passkey=" -j DROP iptables -D INPUT -p udp -m string --algo bm --string "torrent" -j DROP 
-D INPUT -p udp -m string --algo bm --string "announce" -j DROP 
-D INPUT -p udp -m string --algo bm --string "info_hash" -j DROP 
-D INPUT -p udp -m string --algo bm --string "tracker" -j DROP 
-I OUTPUT -p udp -m string --algo bm --string "BitTorrent" -j DROP 
-I OUTPUT -p udp -m string --algo bm --string "BitTorrent protocol" -j DROP iptables -I OUTPUT -p udp -m string --algo bm --string "peer_id=" -j DROP 
-I OUTPUT -p udp -m string --algo bm --string ".torrent" -j DROP 
-I OUTPUT -p udp -m string --algo bm --string "announce.php?passkey=" -j DROP iptables -I OUTPUT -p udp -m string --algo bm --string "torrent" -j DROP 
-I OUTPUT -p udp -m string --algo bm --string "announce" -j DROP 
-I OUTPUT -p udp -m string --algo bm --string "info_hash" -j DROP 
-I OUTPUT -p udp -m string --algo bm --string "tracker" -j DROP
-D INPUT -m string --algo bm --string "BitTorrent" -j DROP 
-D INPUT -m string --algo bm --string "BitTorrent protocol" -j DROP 
-D INPUT -m string --algo bm --string "peer_id=" -j DROP
-D INPUT -m string --algo bm --string ".torrent" -j DROP 
-D INPUT -m string --algo bm --string "announce.php?passkey=" -j DROP 
-D INPUT -m string --algo bm --string "torrent" -j DROP 
-D INPUT -m string --algo bm --string "announce" -j DROP
-D INPUT -m string --algo bm --string "info_hash" -j DROP
-D INPUT -m string --algo bm --string "tracker" -j DROP 
-D OUTPUT -m string --algo bm --string "BitTorrent" -j DROP
-D OUTPUT -m string --algo bm --string "BitTorrent protocol" -j DROP
-D OUTPUT -m string --algo bm --string "peer_id=" -j DROP
-D OUTPUT -m string --algo bm --string ".torrent" -j DROP
-D OUTPUT -m string --algo bm --string "announce.php?passkey=" -j DROP 
-D OUTPUT -m string --algo bm --string "torrent" -j DROP
-D OUTPUT -m string --algo bm --string "announce" -j DROP
-D OUTPUT -m string --algo bm --string "info_hash" -j DROP
-D OUTPUT -m string --algo bm --string "tracker" -j DROP 
-D FORWARD -m string --algo bm --string "BitTorrent" -j DROP
-D FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
-D FORWARD -m string --algo bm --string "peer_id=" -j DROP
-D FORWARD -m string --algo bm --string ".torrent" -j DROP
-D FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
-D FORWARD -m string --algo bm --string "torrent" -j DROP
-D FORWARD -m string --algo bm --string "announce" -j DROP
-D FORWARD -m string --algo bm --string "info_hash" -j DROP
-D FORWARD -m string --algo bm --string "tracker" -j DROP
COMMIT
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
END
sed -i $MYIP2 /etc/iptables.up.rules;
iptables-restore < /etc/iptables.up.rules

# Configure Nginx
sed -i 's/\/var\/www\/html;/\/home\/vps\/public_html\/;/g' /etc/nginx/sites-enabled/default
cp /var/www/html/index.nginx-debian.html /home/vps/public_html/index.html

#Create Admin
useradd admin
echo "admin:itangsagli" | chpasswd

# Create and Configure rc.local
cat > /etc/rc.local <<-END
#!/bin/sh -e

exit 0
END
chmod +x /etc/rc.local
sed -i '$ i\echo "nameserver 8.8.8.8" > /etc/resolv.conf' /etc/rc.local
sed -i '$ i\echo "nameserver 8.8.4.4" >> /etc/resolv.conf' /etc/rc.local
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local

# Configure menu
apt-get install unzip
cd /usr/local/bin/
wget "https://raw.githubusercontent.com/TholhahZabri/VPS-Scripts/master/D9SSL/bashmenu.zip" 
unzip bashmenu.zip
chmod +x /usr/local/bin/*

# add eth0 to vnstat
vnstat -u -i eth0

# compress configs
cd /home/vps/public_html
zip configs.zip sun-tuctc.ovpn OpenVPN-SSL.ovpn stunnel.conf fixplan.ovpn noload.ovpn sunfreeyt.ovpn default.ovpn gtmfbig.ovpn tu200.ovpn JFTV-WG.conf

# install libxml-parser
apt-get install libxml-parser-perl -y -f

# finalizing
vnstat -u -i eth0
apt-get -y autoremove
chown -R www-data:www-data /home/vps/public_html
service nginx start
service php7.0-fpm start
service vnstat restart
service openvpn restart
service dropbear restart
service fail2ban restart
service squid restart
service privoxy restart

#clearing history
history -c
rm -rf /root/*
cd /root
# info
clear
echo " "
echo "Installation has been completed!!"
echo " Please Reboot your VPS"
echo "--------------------------- Configuration Setup Server -------------------------"
echo "                            Debian Premium Script                               "
echo "                                 -FordSenpai-                                   "
echo "--------------------------------------------------------------------------------"
echo ""  | tee -a log-install.txt
echo "Server Information"  | tee -a log-install.txt
echo "   - Timezone    : Asia/Manila (GMT +8)"  | tee -a log-install.txt
echo "   - Fail2Ban    : [ON]"  | tee -a log-install.txt
echo "   - IPtables    : [ON]"  | tee -a log-install.txt
echo "   - Auto-Reboot : [OFF]"  | tee -a log-install.txt
echo "   - IPv6        : [OFF]"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Application & Port Information"  | tee -a log-install.txt
echo "   - OpenVPN		: TCP 110 "  | tee -a log-install.txt
echo "   - OpenVPN-SSL	: 443 "  | tee -a log-install.txt
echo "   - Dropbear		: 442"  | tee -a log-install.txt
echo "   - Stunnel  	: 444"  | tee -a log-install.txt
echo "   - Squid Proxy	: 3355, 8085 (limit to IP Server)"  | tee -a log-install.txt
echo "   - Privoxy		: 3356, 8086 (limit to IP Server)"  | tee -a log-install.txt
echo "   - BadVPN		: 7300"  | tee -a log-install.txt
echo "   - Nginx		: 80"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Premium Script Information"  | tee -a log-install.txt
echo "   To display list of commands: menu"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Important Information"  | tee -a log-install.txt
echo "   - Download Config OpenVPN : http://$MYIP/configs.zip"  | tee -a log-install.txt
echo "   - Installation Log        : cat /root/log-install.txt"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "   - Webmin                  : http://$MYIP:10000/"  | tee -a log-install.txt
echo ""
echo "------------------------------ Team Vmodz-Glitch -----------------------------"
echo "-----Please Reboot your VPS -----"
sleep 5
