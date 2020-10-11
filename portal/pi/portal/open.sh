sudo iptables -t nat -I PREROUTING -p tcp --dport 80  -j DNAT --to-destination 10.0.0.1
sudo python3 app.py
