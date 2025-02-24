Testing connection between the app and the database:
```bash
mongosh "mongodb://10.0.2.4:27017"
```

Configuring iptables:
```bash
sudo iptables -A INPUT -p tcp --dport 27017 -s 10.0.1.0/24 -j ACCEPT
```

After ensuring database 