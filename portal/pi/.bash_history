comitup-cli 
ifconfig
reboot
ifconfig
systemctl status
systemctl comitup status
systemctl status comitup
systemctl disable comitup
sudo systemctl disable comitup
sudo reboot
ifconfig
sudo systemctl status comitup
cat /etc/wpa_supplicant/wpa_supplicant.conf
cat /etc/wpa_supplicant/wpa_supplicant.conf.comitup_disable 
sudo cat /etc/wpa_supplicant/wpa_supplicant.conf.comitup_disable 
ls
cd /usr/share/comitup/
ls
cat /var/log/syslog 
cat /etc/dhcpcd.conf 
less /var/log/syslog 
cd /etc/
grep -r . "draad"
grep -r draad .
sudo grep -r draad .
cat NetworkManager/system-connections/draadloos.nmconnection 
sudo cat NetworkManager/system-connections/draadloos.nmconnection 
sudo apt update
sudo apt install hostapd dnsmasq
sudo nano /etc/dhcpcd.conf 
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo nano /etc/dnsmasq.conf
cat /etc/dhcpcd.conf 
sudo nano /etc/hostapd/hostapd.conf
sudo nano /etc/default/hostapd 
sudo reboot
ifconfig
sudo systemctl status hostapd
sudo systemctl unmask hostapd
sudo systemctl unmask dnsmasq
sudo systemctl enable dnsmasq
sudo systemctl enable hostapd
sudo reboot
ifconfig
cat /var/log/syslog 
sudo systemctl status hostapd
nmcli connection delete draadloos
sudo nmcli connection delete draadloos
ifconfig
sudo nmcli d wifi connect draadloos password bos72amster
ifconfig
cat /var/log/syslog 
sudo apt install pip3
sudo apt install python-pip3
sudo apt install python3-pip
mkdir portal
cd portal/
python3 -m pip install Flask==1.1.1
ls
python3 -m pip freeze > requirements.txt
nano app.py
python3 app.py 
sudo reboot
less /var/log/syslog 
ls
cd portal/
python3 app.py 
nano app.py 
python3 app.py 
sudo python3 app.py 
sudo nano /etc/dnsmasq.conf
sudo reboot
ifconfig
cd portal/
sudo python3 app.py 
nano portal/app.py 
cat /var/log/syslog 
ping google.com
sudo nano /etc/dnsmasq.
sudo nano /etc/dnsmasq.conf
sudo reboot
cd portal/
sudo python3 app.py 
sudo iptables -t nat -I PREROUTING -p tcp --dport 80  -j DNAT --to-destination 10.0.0.1
sudo python3 app.py 
nano app.py 
sudo python3 app.py 
sudo reboot
