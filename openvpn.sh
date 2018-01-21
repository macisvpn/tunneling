#install vpn
apt-get -y install openvpn easy-rsa
cat > /etc/openvpn/server.conf <<-END
port 1194
proto tcp
dev tun
tun-mtu 1500
tun-mtu-extra 32
mssfix 1450
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
plugin /etc/openvpn/openvpn-plugin-auth-pam.so /etc/pam.d/login
client-cert-not-required
username-as-common-name
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
push "route-method exe"
push "route-delay 2"
keepalive 5 30
cipher AES-128-CBC
comp-lzo
persist-key
persist-tun
status server-vpn.log
verb 3
END
cat > /etc/openvpn/udp25.conf <<-END
port 25
proto udp
dev tun
tun-mtu 1500
tun-mtu-extra 32
mssfix 1450
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
plugin /etc/openvpn/openvpn-plugin-auth-pam.so /etc/pam.d/login 
client-cert-not-required
username-as-common-name
server 10.9.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
push "route-method exe"
push "route-delay 2"
keepalive 5 30
cipher AES-128-CBC
comp-lzo
persist-key
persist-tun
status server-vpn.log
verb 3
END
cat > /etc/openvpn/udpssl53.conf <<-END
port 110
proto udp
dev tun
tun-mtu 1500
tun-mtu-extra 32
mssfix 1450
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
plugin /etc/openvpn/openvpn-plugin-auth-pam.so /etc/pam.d/login
client-cert-not-required
username-as-common-name
server 10.10.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
push "route-method exe"
push "route-delay 2"
keepalive 5 30
cipher AES-128-CBC
comp-lzo
persist-key
persist-tun
status server-vpn.log
verb 3
END
cp -r /usr/share/easy-rsa/ /etc/openvpn
mkdir /etc/openvpn/easy-rsa/keys
wget -O /etc/openvpn/easy-rsa/vars "https://github.com/malikshi/elora/raw/master/vars"
openssl dhparam -out /etc/openvpn/dh2048.pem 2048
cd /etc/openvpn/easy-rsa
. ./vars
./clean-all
# Buat Sertifikat
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --initca $*
# buat key server
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --server server
# seting KEY CN
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" client
#copy to openvpn folder
cp /etc/openvpn/easy-rsa/keys/{server.crt,server.key,ca.crt} /etc/openvpn
ls /etc/openvpn
sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn
service openvpn restart
ip=$(ifconfig | awk -F':' '/inet addr/&&!/127.0.0.1/&&!/127.0.0.2/{split($2,_," ");print _[1]}')
cat > /etc/openvpn/globalssh.ovpn <<-END
# OpenVPN Configuration GlobalSSH Server
# (Official @www.globalssh.net & www.readyssh.com)
client
dev tun
proto tcp
#proto udp
#
#for tcp 1194
remote $ip 1194
#for udp 25
#remote $ip 25
#for udp 110
#remote $ip 110
#change port and proto as you want            # rubah port dan proto sesuai yang diinginkan
#there the prosedur edit type connection      #berikut prosedur mengubah jenis koneki tcp/udp
#proto udp #with port active udp 25 & 110 choose as u want  # ganti proto tcp ke proto udp jika memakai koneksi udp
#change 1194 to 25 or 110 as the port udp u want to use     #ganti port pada remote ke port udp/tcp yang diinginkan
resolv-retry infinite
route-method exe
resolv-retry infinite
cipher AES-128-CBC
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END
echo '<ca>' >> /etc/openvpn/globalssh.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/globalssh.ovpn
echo '</ca>' >> /etc/openvpn/globalssh.ovpn
sed -i $ip /etc/openvpn/globalssh.ovpn
cp /usr/lib/openvpn/openvpn-plugin-auth-pam.so /etc/openvpn/
