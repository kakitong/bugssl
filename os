#                 UNIRISES | 2020                            #
#            Debian 9 and 10 VPS Installer                   #
#                                                            #
##############################################################                                                         

MyScriptName='UNIRISES'

# OpenSSH Ports
SSH_Port1='22'
SSH_Port2='225'

# Your SSH Banner
SSH_Banner='https://pastebin.com/raw/txZhxLfG'

# Dropbear Ports
Dropbear_Port1='550'
Dropbear_Port2='555'

# Stunnel Ports
Stunnel_Port1='443' # through Dropbear
Stunnel_Port2='444' # through OpenSSH

# OpenVPN Ports
OpenVPN_Port1='110' # take note when you change this port, openvpn sun noload config will not work

# Privoxy Ports (must be 1024 or higher)
Privoxy_Port1='8000'
Privoxy_Port2='8080'

# OpenVPN Config Download Port
OvpnDownload_Port='88' # Before changing this value, please read this document. It contains all unsafe ports for Google Chrome Browser, please read from line #23 to line #89: https://chromium.googlesource.com/chromium/src.git/+/refs/heads/master/net/base/port_util.cc

# Server local time
MyVPS_Time='Asia/Manila'
#############################


#############################
#############################
## All function used for this script
#############################
## WARNING: Do not modify or edit anything
## if you did'nt know what to do.
## This part is too sensitive.
#############################
#############################

function InstUpdates(){
 export DEBIAN_FRONTEND=noninteractive
 apt-get update
 apt-get upgrade -y
 
 # Removing some firewall tools that may affect other services
 apt-get remove --purge ufw firewalld -y

 
 # Installing some important machine essentials
 apt-get install nano wget curl zip unzip tar gzip p7zip-full bc rc openssl cron net-tools dnsutils dos2unix screen bzip2 ccrypt -y
 
 # Now installing all our wanted services
 apt-get install dropbear stunnel4 privoxy ca-certificates nginx ruby apt-transport-https lsb-release squid screenfetch -y

 # Installing all required packages to install Webmin
 apt-get install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python dbus libxml-parser-perl -y
 
 # Installing a text colorizer
 gem install lolcat

 # Trying to remove obsolette packages after installation
 apt-get autoremove -y
 
 # Installing OpenVPN by pulling its repository inside sources.list file 
 rm -rf /etc/apt/sources.list.d/openvpn*
 echo "deb http://build.openvpn.net/debian/openvpn/stable $(lsb_release -sc) main" > /etc/apt/sources.list.d/openvpn.list
 wget -qO - http://build.openvpn.net/debian/openvpn/stable/pubkey.gpg|apt-key add -
 apt-get update
 apt-get install openvpn -y
}

function InstWebmin(){
 # Download the webmin .deb package
 # You may change its webmin version depends on the link you've loaded in this variable(.deb file only, do not load .zip or .tar.gz file):
 WebminFile='http://prdownloads.sourceforge.net/webadmin/webmin_1.910_all.deb'
 wget -qO webmin.deb "$WebminFile"
 
 # Installing .deb package for webmin
 dpkg --install webmin.deb
 
 rm -rf webmin.deb
 
 # Configuring webmin server config to use only http instead of https
 sed -i 's|ssl=1|ssl=0|g' /etc/webmin/miniserv.conf
 
 # Then restart to take effect
 systemctl restart webmin
}

function InstSSH(){
 # Removing some duplicated sshd server configs
 rm -f /etc/ssh/sshd_config*
 
 # Creating a SSH server config using cat eof tricks
 cat <<'MySSHConfig' > /etc/ssh/sshd_config
# My OpenSSH Server config
Port myPORT1
Port myPORT2
AddressFamily inet
ListenAddress 0.0.0.0
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
PermitRootLogin yes
MaxSessions 1024
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
ClientAliveInterval 240
ClientAliveCountMax 2
UseDNS no
Banner /etc/banner
AcceptEnv LANG LC_*
Subsystem	 sftp /usr/lib/openssh/sftp-server
MySSHConfig

 # Now we'll put our ssh ports inside of sshd_config
 sed -i "s|myPORT1|$SSH_Port1|g" /etc/ssh/sshd_config
 sed -i "s|myPORT2|$SSH_Port2|g" /etc/ssh/sshd_config

 # Download our SSH Banner
 rm -f /etc/banner
 wget -qO /etc/banner "$SSH_Banner"
 dos2unix -q /etc/banner

 # My workaround code to remove `BAD Password error` from passwd command, it will fix password-related error on their ssh accounts.
 sed -i '/password\s*requisite\s*pam_cracklib.s.*/d' /etc/pam.d/common-password
 sed -i 's/use_authtok //g' /etc/pam.d/common-password

 # Some command to identify null shells when you tunnel through SSH or using Stunnel, it will fix user/pass authentication error on HTTP Injector, KPN Tunnel, eProxy, SVI, HTTP Proxy Injector etc ssh/ssl tunneling apps.
 sed -i '/\/bin\/false/d' /etc/shells
 sed -i '/\/usr\/sbin\/nologin/d' /etc/shells
 echo '/bin/false' >> /etc/shells
 echo '/usr/sbin/nologin' >> /etc/shells
 
 # Restarting openssh service
 systemctl restart ssh
 
 # Removing some duplicate config file
 rm -rf /etc/default/dropbear*
 
 # creating dropbear config using cat eof tricks
 cat <<'MyDropbear' > /etc/default/dropbear
# My Dropbear Config
NO_START=0
DROPBEAR_PORT=PORT01
DROPBEAR_EXTRA_ARGS="-p PORT02"
DROPBEAR_BANNER="/etc/banner"
DROPBEAR_RSAKEY="/etc/dropbear/dropbear_rsa_host_key"
DROPBEAR_DSSKEY="/etc/dropbear/dropbear_dss_host_key"
DROPBEAR_ECDSAKEY="/etc/dropbear/dropbear_ecdsa_host_key"
DROPBEAR_RECEIVE_WINDOW=65536
MyDropbear

 # Now changing our desired dropbear ports
 sed -i "s|PORT01|$Dropbear_Port1|g" /etc/default/dropbear
 sed -i "s|PORT02|$Dropbear_Port2|g" /etc/default/dropbear
 
 # Restarting dropbear service
 systemctl restart dropbear
}

function InsStunnel(){
 StunnelDir=$(ls /etc/default | grep stunnel | head -n1)

 # Creating stunnel startup config using cat eof tricks
cat <<'MyStunnelD' > /etc/default/$StunnelDir
# My Stunnel Config
ENABLED=1
FILES="/etc/stunnel/*.conf"
OPTIONS=""
BANNER="/etc/banner"
PPP_RESTART=0
# RLIMITS="-n 4096 -d unlimited"
RLIMITS=""
MyStunnelD

 # Removing all stunnel folder contents
 rm -rf /etc/stunnel/*
 
 # Creating stunnel certifcate using openssl
 openssl req -new -x509 -days 9999 -nodes -subj "/C=PH/ST=NCR/L=Manila/O=$MyScriptName/OU=$MyScriptName/CN=$MyScriptName" -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem &> /dev/null
##  > /dev/null 2>&1

 # Creating stunnel server config
 cat <<'MyStunnelC' > /etc/stunnel/stunnel.conf
# My Stunnel Config
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
TIMEOUTclose = 0

[dropbear]
accept = Stunnel_Port1
connect = 127.0.0.1:dropbear_port_c

[openssh]
accept = Stunnel_Port2
connect = 127.0.0.1:openssh_port_c
MyStunnelC

 # setting stunnel ports
 sed -i "s|Stunnel_Port1|$Stunnel_Port1|g" /etc/stunnel/stunnel.conf
 sed -i "s|dropbear_port_c|$(netstat -tlnp | grep -i dropbear | awk '{print $4}' | cut -d: -f2 | xargs | awk '{print $2}' | head -n1)|g" /etc/stunnel/stunnel.conf
 sed -i "s|Stunnel_Port2|$Stunnel_Port2|g" /etc/stunnel/stunnel.conf
 sed -i "s|openssh_port_c|$(netstat -tlnp | grep -i ssh | awk '{print $4}' | cut -d: -f2 | xargs | awk '{print $2}' | head -n1)|g" /etc/stunnel/stunnel.conf

 # Restarting stunnel service
 systemctl restart $StunnelDir

}

function InsOpenVPN(){
 # Checking if openvpn folder is accidentally deleted or purged
 if [[ ! -e /etc/openvpn ]]; then
  mkdir -p /etc/openvpn
 fi

 # Removing all existing openvpn server files
 rm -rf /etc/openvpn/*

 # Creating server.conf, ca.crt, server.crt and server.key
 cat <<'myOpenVPNconf' > /etc/openvpn/server.conf
# My OpenVPN 
port MyOvpnPort
dev tun
proto tcp
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh.pem
duplicate-cn
cipher none
ncp-disable
auth none
comp-lzo
plugin /etc/openvpn/openvpn-auth-pam.so login
verify-client-cert none
username-as-common-name
max-clients 4000
server 10.200.0.0 255.255.0.0
tun-mtu 1500
tun-mtu-extra 32
mssfix 1400
reneg-sec 0
sndbuf 0
rcvbuf 0
push "sndbuf 393216"
push "rcvbuf 393216"
push "redirect-gateway def1"
push "route-method exe"
push "route-delay 2"
client-to-client
keepalive 10 120
persist-tun
persist-key
persist-remote-ip
status /etc/openvpn/stats.txt
log /etc/openvpn/openvpn.log
verb 2
script-security 2
socket-flags TCP_NODELAY
push "socket-flags TCP_NODELAY"
myOpenVPNconf
 cat <<'EOF7'> /etc/openvpn/ca.crt
-----BEGIN CERTIFICATE-----
MIIEATCCA2qgAwIBAgIJAOCyX0XMJp/pMA0GCSqGSIb3DQEBCwUAMIGyMQswCQYD
VQQGEwJQSDEMMAoGA1UECBMDTkNSMQ8wDQYDVQQHEwZNYW5pbGExFTATBgNVBAoT
DFBIQ29ybmVyLk5FVDEbMBkGA1UECxMSQm9udmVpbyBBdXRvc2NyaXB0MRgwFgYD
VQQDEw9QSENvcm5lci5ORVQgQ0ExETAPBgNVBCkTCEJvbi1jaGFuMSMwIQYJKoZI
hvcNAQkBFhRvcGVudnBuQHBoY29ybmVyLm5ldDAeFw0xOTA2MDgyMDIzMTRaFw00
NjEwMTQyMDIzMTRaMIGyMQswCQYDVQQGEwJQSDEMMAoGA1UECBMDTkNSMQ8wDQYD
VQQHEwZNYW5pbGExFTATBgNVBAoTDFBIQ29ybmVyLk5FVDEbMBkGA1UECxMSQm9u
dmVpbyBBdXRvc2NyaXB0MRgwFgYDVQQDEw9QSENvcm5lci5ORVQgQ0ExETAPBgNV
BCkTCEJvbi1jaGFuMSMwIQYJKoZIhvcNAQkBFhRvcGVudnBuQHBoY29ybmVyLm5l
dDCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAxKyzeWAALqWhZx0d6jM2H/WB
AJTzq30+7XyfsJZ1E05bvQ/iVpTEISU4mSg/bJyW6yoVeuR5sdULAwNTswGnqoYF
V9VW36p0OJklTxgGQpy92b89UeUTxfoGFYRYd6JDqMp+eZLLDdf2JraKUD53gbDz
HbMtVNmP00X4UT2p2S0CAwEAAaOCARswggEXMB0GA1UdDgQWBBRECIKLevT/AZM+
5r1ixF2iGN+BzTCB5wYDVR0jBIHfMIHcgBRECIKLevT/AZM+5r1ixF2iGN+BzaGB
uKSBtTCBsjELMAkGA1UEBhMCUEgxDDAKBgNVBAgTA05DUjEPMA0GA1UEBxMGTWFu
aWxhMRUwEwYDVQQKEwxQSENvcm5lci5ORVQxGzAZBgNVBAsTEkJvbnZlaW8gQXV0
b3NjcmlwdDEYMBYGA1UEAxMPUEhDb3JuZXIuTkVUIENBMREwDwYDVQQpEwhCb24t
Y2hhbjEjMCEGCSqGSIb3DQEJARYUb3BlbnZwbkBwaGNvcm5lci5uZXSCCQDgsl9F
zCaf6TAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4GBAICs6tRpZWpgHWUC
DMkWedUD+cDYVlDTP2dwRY0Xi0FuNVlsRdEOWsBfVaXj+wpc2qn6fKt/sUVBQWof
mKQlDlHY3rj0EqEPq+9VUMjxB2OMXMbtumK2usZ30O7nKcKSsLJsRhcaY6LghHkq
BEUv/Z1/AWr7BLBIQCtMUZkmYVGJ
-----END CERTIFICATE-----
EOF7
 cat <<'EOF9'> /etc/openvpn/server.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 1 (0x1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=PH, ST=NCR, L=Manila, O=PHCorner.NET, OU=Bonveio Autoscript, CN=PHCorner.NET CA/name=Bon-chan/emailAddress=openvpn@phcorner.net
        Validity
            Not Before: Jun  8 20:24:02 2019 GMT
            Not After : Oct 14 20:24:02 2046 GMT
        Subject: C=PH, ST=NCR, L=Manila, O=PHCorner.NET, OU=Bonveio Autoscript, CN=server/name=Bon-chan/emailAddress=openvpn@phcorner.net
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (1024 bit)
                Modulus:
                    00:be:89:b8:c7:5a:52:2f:96:5b:3e:fd:7d:25:1f:
                    2e:3c:83:ab:5d:25:cc:97:4e:c7:3f:01:ab:43:03:
                    7e:3c:dd:83:6a:e1:c3:6e:ff:32:80:65:d2:29:27:
                    a0:ae:0f:fd:53:f9:ce:82:10:b9:af:83:8e:79:f8:
                    20:4f:41:ec:e5:66:70:85:63:5b:5b:89:0b:05:ca:
                    b6:57:17:ac:e1:2d:67:85:b4:66:a4:51:97:19:86:
                    11:b2:f0:c7:af:96:a3:00:ec:c5:bb:5d:00:8f:79:
                    b9:23:e1:47:43:ee:8a:a1:bc:cc:62:71:f9:12:51:
                    28:6d:7f:2c:79:35:c7:a9:89
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            Netscape Cert Type: 
                SSL Server
            Netscape Comment: 
                Easy-RSA Generated Server Certificate
            X509v3 Subject Key Identifier: 
                26:C9:39:A0:F9:75:73:1B:5A:29:D5:8C:80:35:71:23:44:56:00:14
            X509v3 Authority Key Identifier: 
                keyid:44:08:82:8B:7A:F4:FF:01:93:3E:E6:BD:62:C4:5D:A2:18:DF:81:CD
                DirName:/C=PH/ST=NCR/L=Manila/O=PHCorner.NET/OU=Bonveio Autoscript/CN=PHCorner.NET CA/name=Bon-chan/emailAddress=openvpn@phcorner.net
                serial:E0:B2:5F:45:CC:26:9F:E9

            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Key Usage: 
                Digital Signature, Key Encipherment
            X509v3 Subject Alternative Name: 
                DNS:server
    Signature Algorithm: sha256WithRSAEncryption
         a6:46:e3:8d:8d:16:42:85:d2:c7:99:87:a6:66:c7:1b:36:af:
         f9:37:3a:a8:d9:6f:e3:1e:2d:93:1c:bf:52:9f:01:88:82:bc:
         39:07:1d:e1:62:ff:65:a7:74:31:2b:32:37:d0:d7:e0:5c:2d:
         4e:9a:c2:01:cb:6a:e2:69:f8:1b:f7:df:15:5c:3e:30:84:ca:
         6e:2d:18:be:bc:f7:fa:a2:af:70:26:ae:3e:e1:a0:75:92:a3:
         91:94:52:5f:21:ce:e0:38:97:c5:c6:55:1e:42:d7:f5:38:7f:
         e1:ef:2c:b4:5c:32:5c:74:6e:a8:08:ab:6c:a7:72:ba:7e:b5:
         b5:74
-----BEGIN CERTIFICATE-----
MIIEazCCA9SgAwIBAgIBATANBgkqhkiG9w0BAQsFADCBsjELMAkGA1UEBhMCUEgx
DDAKBgNVBAgTA05DUjEPMA0GA1UEBxMGTWFuaWxhMRUwEwYDVQQKEwxQSENvcm5l
ci5ORVQxGzAZBgNVBAsTEkJvbnZlaW8gQXV0b3NjcmlwdDEYMBYGA1UEAxMPUEhD
b3JuZXIuTkVUIENBMREwDwYDVQQpEwhCb24tY2hhbjEjMCEGCSqGSIb3DQEJARYU
b3BlbnZwbkBwaGNvcm5lci5uZXQwHhcNMTkwNjA4MjAyNDAyWhcNNDYxMDE0MjAy
NDAyWjCBqTELMAkGA1UEBhMCUEgxDDAKBgNVBAgTA05DUjEPMA0GA1UEBxMGTWFu
aWxhMRUwEwYDVQQKEwxQSENvcm5lci5ORVQxGzAZBgNVBAsTEkJvbnZlaW8gQXV0
b3NjcmlwdDEPMA0GA1UEAxMGc2VydmVyMREwDwYDVQQpEwhCb24tY2hhbjEjMCEG
CSqGSIb3DQEJARYUb3BlbnZwbkBwaGNvcm5lci5uZXQwgZ8wDQYJKoZIhvcNAQEB
BQADgY0AMIGJAoGBAL6JuMdaUi+WWz79fSUfLjyDq10lzJdOxz8Bq0MDfjzdg2rh
w27/MoBl0iknoK4P/VP5zoIQua+Djnn4IE9B7OVmcIVjW1uJCwXKtlcXrOEtZ4W0
ZqRRlxmGEbLwx6+WowDsxbtdAI95uSPhR0PuiqG8zGJx+RJRKG1/LHk1x6mJAgMB
AAGjggGWMIIBkjAJBgNVHRMEAjAAMBEGCWCGSAGG+EIBAQQEAwIGQDA0BglghkgB
hvhCAQ0EJxYlRWFzeS1SU0EgR2VuZXJhdGVkIFNlcnZlciBDZXJ0aWZpY2F0ZTAd
BgNVHQ4EFgQUJsk5oPl1cxtaKdWMgDVxI0RWABQwgecGA1UdIwSB3zCB3IAURAiC
i3r0/wGTPua9YsRdohjfgc2hgbikgbUwgbIxCzAJBgNVBAYTAlBIMQwwCgYDVQQI
EwNOQ1IxDzANBgNVBAcTBk1hbmlsYTEVMBMGA1UEChMMUEhDb3JuZXIuTkVUMRsw
GQYDVQQLExJCb252ZWlvIEF1dG9zY3JpcHQxGDAWBgNVBAMTD1BIQ29ybmVyLk5F
VCBDQTERMA8GA1UEKRMIQm9uLWNoYW4xIzAhBgkqhkiG9w0BCQEWFG9wZW52cG5A
cGhjb3JuZXIubmV0ggkA4LJfRcwmn+kwEwYDVR0lBAwwCgYIKwYBBQUHAwEwCwYD
VR0PBAQDAgWgMBEGA1UdEQQKMAiCBnNlcnZlcjANBgkqhkiG9w0BAQsFAAOBgQCm
RuONjRZChdLHmYemZscbNq/5Nzqo2W/jHi2THL9SnwGIgrw5Bx3hYv9lp3QxKzI3
0NfgXC1OmsIBy2riafgb998VXD4whMpuLRi+vPf6oq9wJq4+4aB1kqORlFJfIc7g
OJfFxlUeQtf1OH/h7yy0XDJcdG6oCKtsp3K6frW1dA==
-----END CERTIFICATE-----
EOF9
 cat <<'EOF10'> /etc/openvpn/server.key
-----BEGIN PRIVATE KEY-----
MIICeAIBADANBgkqhkiG9w0BAQEFAASCAmIwggJeAgEAAoGBAL6JuMdaUi+WWz79
fSUfLjyDq10lzJdOxz8Bq0MDfjzdg2rhw27/MoBl0iknoK4P/VP5zoIQua+Djnn4
IE9B7OVmcIVjW1uJCwXKtlcXrOEtZ4W0ZqRRlxmGEbLwx6+WowDsxbtdAI95uSPh
R0PuiqG8zGJx+RJRKG1/LHk1x6mJAgMBAAECgYEAiuUeW8RNsP7sGSj0N0FZlSdu
ngJV996nhBiVXc6IEZpwmFNnAdzqVYrj/rgye3CQfMzXax0CHx3JmMP12ZD3PKY9
P2NBwJE0D1CloVNsOmvdQdLMR/aBkSCFBYkNwMgBNsLLkVfObLAknXzFBsSjD/TW
CorMbGvxQsPCJThX9lkCQQD6Yc7C8WrHH36+YqU9drZdM49opjoyQDqyb0Y8C7Zw
XUG973ZN1L5HdJmW1pE0Hgp1GeGfBuMbNOusCXsZGHT3AkEAwtArlHVHtg2E/JbQ
9WSCSTY24IP3Q0QCnxZtMBebBbQAIPIiMGf9vpHCUr5FbRGhql6wGn0HaoU5Xxuz
IeW1fwJALqTj8NsqqjfK08rqv52K8af2UmeNNelTRgSG0A7aiOpGogynPG6imAs3
xarpWA00o4YTyx1sV5gvQ1hsz0sIFwJBAJfczxwbkJtKTrDYoGuqviV0LbM3LDkz
exeo09T5kc8QUklcd2pkplk4JtN5n4U2iV/WEFGVxYIz+FU7sphqCOECQQDTJ2f+
rwgQgPRpoZeg8kAl6Uqik0+vLOM/ZtIwcrEowIGKfmBp79VUKoqpW7tJXtkWK8QM
hWiu9+O4+dQNTcOm
-----END PRIVATE KEY-----
EOF10

 # Getting all dns inside resolv.conf then use as Default DNS for our openvpn server
 grep -v '#' /etc/resolv.conf | grep 'nameserver' | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | while read -r line; do
	echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server.conf
done

 # setting openvpn server port
 sed -i "s|MyOvpnPort|$OpenVPN_Port1|g" /etc/openvpn/server.conf
 
 # Generating openvpn dh.pem file using openssl
 openssl dhparam -out /etc/openvpn/dh.pem 1024
 
 # Getting some OpenVPN plugins for unix authentication
 wget -qO /etc/openvpn/b.zip 'https://unirisesvpn.com.ph/revy-a/unirisesadmin/vps/debian/openvpn_plugin64'
 unzip -qq /etc/openvpn/b.zip -d /etc/openvpn
 rm -f /etc/openvpn/b.zip
 
 # Some workaround for OpenVZ machines for "Startup error" openvpn service
 if [[ "$(hostnamectl | grep -i Virtualization | awk '{print $2}' | head -n1)" == 'openvz' ]]; then
 sed -i 's|LimitNPROC|#LimitNPROC|g' /lib/systemd/system/openvpn*
 systemctl daemon-reload
fi

 # Allow IPv4 Forwarding
 sed -i '/net.ipv4.ip_forward.*/d' /etc/sysctl.conf
 echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/20-openvpn.conf
 sysctl --system &> /dev/null

 # Iptables Rule for OpenVPN server
 iptables -I FORWARD -s $IPCIDR -j ACCEPT
 iptables -t nat -A POSTROUTING -o $PUBLIC_INET -j MASQUERADE
 iptables -t nat -A POSTROUTING -s $IPCIDR -o $PUBLIC_INET -j MASQUERADE
 
 # Starting OpenVPN server
 systemctl start openvpn@server
 systemctl enable openvpn@server
 
 wget -qO /etc/openvpn/openvpn.bash "https://unirisesvpn.com.ph/revy-a/unirisesadmin/vps/debian/openvpn.bash"
 chmod +x /etc/openvpn/openvpn.bash
 echo -e "@reboot\troot\t/bin/bash /etc/openvpn/openvpn.bash" > /etc/cron.d/openvpn_server
}

function InsProxy(){
 # Removing Duplicate privoxy config
 rm -rf /etc/privoxy/config*
 
 # Creating Privoxy server config using cat eof tricks
 cat <<'myPrivoxy' > /etc/privoxy/config
# My Privoxy Server Config
user-manual /usr/share/doc/privoxy/user-manual
confdir /etc/privoxy
logdir /var/log/privoxy
filterfile default.filter
logfile logfile
listen-address 0.0.0.0:8000
listen-address 0.0.0.0:8080
toggle 1
enable-remote-toggle 0
enable-remote-http-toggle 0
enable-edit-actions 0
enforce-blocks 0
buffer-limit 4096
enable-proxy-authentication-forwarding 1
forwarded-connect-retries 1
accept-intercepted-requests 1
allow-cgi-request-crunching 1
split-large-forms 0
keep-alive-timeout 5
tolerate-pipelining 1
socket-timeout 300
permit-access 0.0.0.0/0 IP-ADDRESS
myPrivoxy

 # Setting machine's IP Address inside of our privoxy config(security that only allows this machine to use this proxy server)
 sed -i "s|IP-ADDRESS|$IPADDR|g" /etc/privoxy/config

 # I'm setting Some Squid workarounds to prevent Privoxy's overflowing file descriptors that causing 50X error when clients trying to connect to your proxy server(thanks for this trick @homer_simpsons)
 rm -rf /etc/squid/sq*
 cat <<'mySquid' > /etc/squid/squid.conf
http_access deny all
cache_peer 127.0.0.1 parent SquidCacheHelper 7 no-query no-digest default
cache deny all
coredump_dir /var/spool/squid
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
mySquid
 sed -i "s|SquidCacheHelper|$Privoxy_Port1|g" /etc/squid/squid.conf

 # Starting Proxy server
 echo -e "Restarting proxy server.."
 systemctl restart squid
 systemctl restart privoxy
}

function OvpnConfigs(){
 # Creating nginx config for our ovpn config downloads webserver
 cat <<'myNginxC' > /etc/nginx/conf.d/bonveio-ovpn-config.conf
# My OpenVPN Config Download Directory
server {
 listen 0.0.0.0:myNginx;
 server_name localhost;
 root /var/www/openvpn;
 index index.html;
}
myNginxC

 # Setting our nginx config port for .ovpn download site
 sed -i "s|myNginx|$OvpnDownload_Port|g" /etc/nginx/conf.d/bonveio-ovpn-config.conf

 # Removing Default nginx page(port 80)
 rm -rf /etc/nginx/sites-*

 # Creating our root directory for all of our .ovpn configs
 rm -rf /var/www/openvpn
 mkdir -p /var/www/openvpn

 # Now creating all of our OpenVPN Configs 
cat <<EOF15> /var/www/openvpn/Unirises-GTM-PC-Config.ovpn
client
dev tun
proto tcp
remote $IPADDR $OpenVPN_Port1
remote-cert-tls server
resolv-retry infinite
nobind
tun-mtu 1500
tun-mtu-extra 32
mssfix 1450
persist-key
persist-tun
auth-user-pass
auth none
auth-nocache
cipher none
keysize 0
comp-lzo
setenv CLIENT_CERT 0
reneg-sec 0
verb 1
http-proxy $IPADDR $Privoxy_Port1
http-proxy-option VERSION 1.1
http-proxy-option CUSTOM-HEADER ""
http-proxy-option CUSTOM-HEADER "GET https://storage.googleapis.com HTTP/1.1"
http-proxy-option CUSTOM-HEADER Host storage.googleapis.com
http-proxy-option CUSTOM-HEADER X-Forward-Host storage.googleapis.com
http-proxy-option CUSTOM-HEADER X-Forwarded-For storage.googleapis.com
http-proxy-option CUSTOM-HEADER Referrer storage.googleapis.com

<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
EOF15

cat <<EOF152> /var/www/openvpn/Unirises-GTMConfig.ovpn
client
dev tun
proto tcp
remote $IPADDR $OpenVPN_Port1
remote-cert-tls server
resolv-retry infinite
nobind
tun-mtu 1500
tun-mtu-extra 32
mssfix 1450
persist-key
persist-tun
auth-user-pass
auth none
auth-nocache
cipher none
keysize 0
comp-lzo
setenv CLIENT_CERT 0
reneg-sec 0
verb 1
http-proxy $IPADDR $Privoxy_Port1
http-proxy-option VERSION 1.1
http-proxy-option CUSTOM-HEADER Host www.googleapis.com
http-proxy-option CUSTOM-HEADER X-Forwarded-For www.googleapis.com

<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
EOF152

cat <<EOF16> /var/www/openvpn/Unirises-SunConfig.ovpn
client
dev tun
proto tcp
remote $IPADDR $OpenVPN_Port1
remote-cert-tls server
resolv-retry infinite
nobind
tun-mtu 1500
tun-mtu-extra 32
mssfix 1450
persist-key
persist-tun
auth-user-pass
auth none
auth-nocache
cipher none
keysize 0
comp-lzo
setenv CLIENT_CERT 0
reneg-sec 0
verb 1
http-proxy $IPADDR $Privoxy_Port1
http-proxy-option VERSION 1.1
http-proxy-option CUSTOM-HEADER ""
http-proxy-option CUSTOM-HEADER "POST https://secure.viber.com HTTP/1.1"
http-proxy-option CUSTOM-HEADER "Host: secure.viber.com"
http-proxy-option CUSTOM-HEADER X-Forward-Host secure.viber.com
http-proxy-option CUSTOM-HEADER Referrer secure.viber.com

<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
EOF16

cat <<EOF17> /var/www/openvpn/Unirises-SunNoloadConfig.ovpn
client
dev tun
proto tcp-client
remote $IPADDR $OpenVPN_Port1
remote-cert-tls server
bind
float
tun-mtu 1500
tun-mtu-extra 32
mssfix 1450
mute-replay-warnings
connect-retry-max 9999
redirect-gateway def1
connect-retry 0 1
resolv-retry infinite
setenv CLIENT_CERT 0
persist-tun
persist-key
auth-user-pass
auth none
auth-nocache
auth-retry interact
cipher none
keysize 0
comp-lzo
reneg-sec 0
verb 0
nice -20
log /dev/null
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
EOF17

 # Creating OVPN download site index.html
cat <<'mySiteOvpn' > /var/www/openvpn/index.html
<!DOCTYPE html>
<html lang="en">

<!-- Simple OVPN Download By Unirises -->

<head>
<meta charset="utf-8" />
<title>MyScriptName OVPN Config Download</title>
<meta name="description" content="MyScriptName Server" />
<meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport" />
<meta name="theme-color" content="#808080" />
<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.8.2/css/all.css">
<link href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/mdbootstrap/4.8.3/css/mdb.min.css" rel="stylesheet">
</head>
<body>
<div class="container justify-content-center"  style="margin-top:2em;margin-bottom:2em;">
<div class="col-md">
<div class="view">
<body style="background-color:#808080;">
<img src="https://unirisesvpn.com.ph/pictures/revy/ovpn.png" class="card-img-top">
<div class="mask rgba-red-slight">
</div>
</div>
<div class="card">
<div class="card-body">
<div class="w3- w3-red">
<center> <h5 class="card-title">Unirises VPN - Config List</h5> </center>
<br />
<div class="container">
<div class="card-columns">
   <div class="card" style="width:200px">
    <center><img class="card-img-top" src="https://unirisesvpn.com.ph/pictures/revy/globe.png" alt="Card image" style="width:50%"></center>
    <div class="card-body">
    <center><span class="badge light-blue light-4">Android/iOS</span></center>
      <h4 class="card-title">For Globe/TM</h4>
      <small> For EZ/GS Promo with WNP,SNS,FB and IG freebies</small>
     <a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/Unirises-GTMConfig.ovpn" style="float:center;">
<i class="fa fa-download"></i> Download</a>
    </div>
    </div>
    <br>
    <div class="card" style="width:200px">
    <center><img class="card-img-top" src="https://unirisesvpn.com.ph/pictures/revy/globe.png" alt="Card image" style="width:50%"></center>
    <div class="card-body">
    <center><span class="badge light-blue light-4">PC/Modem</span></center>
      <h4 class="card-title">For Globe/TM</h4>
      <small> For EZ/GS Promo with WNP,SNS,FB and IG freebies</small></p>
     <a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/Unirises-GTM-PC-Config.ovpn" style="float:center;">
<i class="fa fa-download"></i> Download</a>
    </div>
  </div>
  <br>
  <div class="card" style="width:200px">
    <center><img class="card-img-top" src="https://unirisesvpn.com.ph/pictures/revy/sun.png" alt="Card image" style="width:50%"></center>
    <div class="card-body">
    <center><span class="badge light-blue light-4">Modem</span></center>
      <h4 class="card-title">For Sun</h4>
      <small> Without Promo/Noload</small></p>
     <a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/Unirises-SunNoloadConfig.ovpn" style="float:center;">
<i class="fa fa-download"></i> Download</a>
    </div>
  </div>
  <br>
 <div class="card" style="width:200px">
    <center><img class="card-img-top" src="https://unirisesvpn.com.ph/pictures/revy/sun.png" alt="Card image" style="width:50%"></center>
    <div class="card-body">
    <center><span class="badge light-blue light-4">Android/iOS/PC/Modem</span></center>
      <h4 class="card-title"> For Sun</h4>
      <small> For TU Promos</small></p>
     <a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/Unirises-SunConfig.ovpn">
<i class="fa fa-download"></i> Download</a> 
    </div>
  </div>
</div>
</div>
</div>
</div>
</body>
</html>
mySiteOvpn
 
 # Setting template's correct name,IP address and nginx Port
 sed -i "s|MyScriptName|$MyScriptName|g" /var/www/openvpn/index.html
 sed -i "s|NGINXPORT|$OvpnDownload_Port|g" /var/www/openvpn/index.html
 sed -i "s|IP-ADDRESS|$IPADDR|g" /var/www/openvpn/index.html

 # Restarting nginx service
 systemctl restart nginx
 
 # Creating all .ovpn config archives
 cd /var/www/openvpn
 zip -qq -r Configs.zip *.ovpn
 cd
}

function ip_address(){
  local IP="$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )"
  [ -z "${IP}" ] && IP="$( wget -qO- -t1 -T2 ipv4.icanhazip.com )"
  [ -z "${IP}" ] && IP="$( wget -qO- -t1 -T2 ipinfo.io/ip )"
  [ ! -z "${IP}" ] && echo "${IP}" || echo
} 
IPADDR="$(ip_address)"

function ConfStartup(){
 # Daily reboot time of our machine
 # For cron commands, visit https://crontab.guru
 echo -e "0 4\t* * *\troot\treboot" > /etc/cron.d/b_reboot_job

 # Creating directory for startup script
 rm -rf /etc/bonveio
 mkdir -p /etc/bonveio
 
 # Creating startup script using cat eof tricks
 cat <<'EOFSH' > /etc/bonveio/startup.sh
#!/bin/bash
# Setting server local time
ln -fs /usr/share/zoneinfo/MyVPS_Time /etc/localtime

# Prevent DOS-like UI when installing using APT (Disabling APT interactive dialog)
export DEBIAN_FRONTEND=noninteractive

# Cleaning cache and download tmp file from APT packages
apt clean

# Allowing ALL TCP ports for our machine (Simple workaround for policy-based VPS)
iptables -A INPUT -s $(wget -4qO- http://ipinfo.io/ip) -p tcp -m multiport --dport 1:65535 -j ACCEPT

# Allowing OpenVPN to Forward traffic
/bin/bash /etc/openvpn/openvpn.bash

# Deleting Expired SSH Accounts
/usr/local/sbin/delete_expired &> /dev/null
EOFSH
 chmod +x /etc/bonveio/startup.sh
 
 # Setting server local time every time this machine reboots
 sed -i "s|MyVPS_Time|$MyVPS_Time|g" /etc/bonveio/startup.sh

 # Setting our startup script to run every machine boots
 echo -e "@reboot\troot\t/bin/bash /etc/bonveio/startup.sh" > /etc/cron.d/b_startup_job 

 # Rebooting cron service
 systemctl restart cron
 
 cat <<'EOFsysctlp' > /etc/sysctl.d/99-mainsys.conf
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 8192 87380 16777216
net.ipv4.udp_rmem_min = 16384
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.ipv4.tcp_wmem = 8192 65536 16777216
net.ipv4.udp_wmem_min = 16384
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 16384
net.core.dev_weight = 64
net.core.optmem_max = 65535
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 16384
net.ipv4.tcp_orphan_retries = 0
net.ipv4.ipfrag_high_thresh = 512000
net.ipv4.ipfrag_low_thresh = 446464
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.unix.max_dgram_qlen = 50
net.ipv4.neigh.default.gc_thresh3 = 2048
net.ipv4.neigh.default.gc_thresh1 = 32
net.ipv4.neigh.default.gc_interval = 30
net.ipv4.neigh.default.proxy_qlen = 96
net.ipv4.neigh.default.unres_qlen = 6
EOFsysctlp
 sysctl --system &> /dev/null
}

function ConfMenu(){
echo -e " Creating Menu scripts.."

cd /usr/local/sbin/
rm -rf {accounts,base-ports,base-ports-wc,base-script,bench-network,clearcache,connections,create,create_random,create_trial,delete_expired,diagnose,edit_dropbear,edit_openssh,edit_openvpn,edit_ports,edit_squid3,edit_stunnel4,locked_list,menu,options,ram,reboot_sys,reboot_sys_auto,restart_services,server,set_multilogin_autokill,set_multilogin_autokill_lib,show_ports,speedtest,user_delete,user_details,user_details_lib,user_extend,user_list,user_lock,user_unlock}
wget -q 'https://unirisesvpn.com.ph/revy-a/unirisesadmin/vps/debian//menu.zip'
unzip -qq menu.zip
rm -f menu.zip
chmod +x ./*
dos2unix ./* &> /dev/null
sed -i 's|/etc/squid/squid.conf|/etc/privoxy/config|g' ./*
sed -i 's|http_port|listen-address|g' ./*
cd ~

echo 'clear' > /etc/profile.d/bonv.sh
echo 'echo '' > /var/log/syslog' >> /etc/profile.d/bonv.sh
echo 'screenfetch -p -A Android' >> /etc/profile.d/bonv.sh
chmod +x /etc/profile.d/bonv.sh
}

function ScriptMessage(){
 echo -e "  $MyScriptName Debian VPS Installer"
 echo -e " Made for Unirises VPN and Revy VPN"
 echo -e ""
 echo -e " Powered by Unirises"
 echo -e ""
}


#############################
#############################
## Installation Process
#############################
## WARNING: Do not modify or edit anything
## if you did'nt know what to do.
## This part is too sensitive.
#############################
#############################

 # First thing to do is check if this machine is Debian
 source /etc/os-release
if [[ "$ID" != 'debian' ]]; then
 ScriptMessage
 echo -e "[\e[1;31mError\e[0m] This script is for Debian only, exting..." 
 exit 1
fi

 # Now check if our machine is in root user, if not, this script exits
 # If you're on sudo user, run `sudo su -` first before running this script
 if [[ $EUID -ne 0 ]];then
 ScriptMessage
 echo -e "[\e[1;31mError\e[0m] This script must be run as root, exiting..."
 exit 1
fi

 # (For OpenVPN) Checking it this machine have TUN Module, this is the tunneling interface of OpenVPN server
 if [[ ! -e /dev/net/tun ]]; then
 echo -e "[\e[1;31m×\e[0m] You cant use this script without TUN Module installed/embedded in your machine, file a support ticket to your machine admin about this matter"
 echo -e "[\e[1;31m-\e[0m] Script is now exiting..."
 exit 1
fi

 # Begin Installation by Updating and Upgrading machine and then Installing all our wanted packages/services to be install.
 ScriptMessage
 sleep 2
 InstUpdates
 
 # Configure OpenSSH and Dropbear
 echo -e "Configuring ssh..."
 InstSSH
 
 # Configure Stunnel
 echo -e "Configuring stunnel..."
 InsStunnel
 
 # Configure Webmin
 echo -e "Configuring webmin..."
 InstWebmin
 
 # Configure Privoxy and Squid
 echo -e "Configuring proxy..."
 InsProxy
 
 # Configure OpenVPN
 echo -e "Configuring OpenVPN..."
 InsOpenVPN
 
 # Configuring Nginx OVPN config download site
 OvpnConfigs
 
 # Some assistance and startup scripts
 ConfStartup
 ConfMenu
 
 # Setting server local time
 ln -fs /usr/share/zoneinfo/$MyVPS_Time /etc/localtime
 
 clear
 cd ~

 # Running sysinfo 
 bash /etc/profile.d/bonv.sh
 
 # Showing script's banner message
 ScriptMessage
 
 # Showing additional information from installating this script
 echo -e ""
 echo -e " Unirises VPN Successfully installed"
 echo -e ""
 echo -e " Service Ports: "
 echo -e " OpenSSH: $SSH_Port1, $SSH_Port2"
 echo -e " Stunnel: $Stunnel_Port1, $Stunnel_Port2"
 echo -e " DropbearSSH: $Dropbear_Port1, $Dropbear_Port2"
 echo -e " Privoxy: $Privoxy_Port1, $Privoxy_Port2"
 echo -e " OpenVPN: $OpenVPN_Port1"
 echo -e " NGiNX: $OvpnDownload_Port"
 echo -e " Webmin: 10000"
 echo -e ""
 echo -e ""
 echo -e " Unirises OpenVPN Configs Download site"
 echo -e " http://$IPADDR:$OvpnDownload_Port"
 echo -e ""
 echo -e " All Unirises OpenVPN Configs Archive"
 echo -e " http://$IPADDR:$OvpnDownload_Port/Configs.zip"
 echo -e ""
 echo -e " Powered By: Unirises"
 echo -e "Panel link: https://unirisesvpn.com.ph"
 echo -e ""
 echo -e " ©BonvScripts"
 echo -e ""

 # Clearing all logs from installation
 rm -rf /root/.bash_history && history -c && echo '' > /var/log/syslog

rm -f os*
exit 1
