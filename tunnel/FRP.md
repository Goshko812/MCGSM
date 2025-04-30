# GeyserMC FRP Setup Guide

## Step 1: Install FRP on both servers

First, let's download and install FRP on both your home server and datacenter machine:

```bash
# Run these commands on both servers
wget https://github.com/fatedier/frp/releases/download/v0.51.3/frp_0.51.3_linux_amd64.tar.gz
tar -xzvf frp_0.51.3_linux_amd64.tar.gz
cd frp_0.51.3_linux_amd64
sudo mkdir -p /etc/frp
```

## Step 2: Set up FRP Server (on your datacenter machine)

On your datacenter machine (100.10.0.1):

```bash
# Copy the server binary
sudo cp frps /usr/local/bin/
sudo chmod +x /usr/local/bin/frps

# Create the config file
sudo nano /etc/frp/frps.ini
```

Paste this content into frps.ini:

```ini
[common]
bind_port = 7000
token = replace_with_a_secure_random_token
```

Now create the server service:

```bash
sudo nano /etc/systemd/system/frps.service
```

Add this content:

```ini
[Unit]
Description=FRP Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/frps -c /etc/frp/frps.ini
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now frps.service
```

## Step 3: Set up FRP Client (on your home server)

On your home server:

```bash
# Copy the client binary
sudo cp frpc /usr/local/bin/
sudo chmod +x /usr/local/bin/frpc

# Create the config file
sudo nano /etc/frp/frpc.ini
```

Paste this content into frpc.ini (replace the token with the same one you used in the server config):

```ini
[common]
server_addr = 100.10.0.1
server_port = 7000
token = replace_with_a_secure_random_token

[minecraft-java]
type = tcp
local_ip = 127.0.0.1
local_port = 25565
remote_port = 25565

[minecraft-bedrock]
type = udp
local_ip = 127.0.0.1
local_port = 19132
remote_port = 19132
```

Now create the client service:

```bash
sudo nano /etc/systemd/system/frpc.service
```

Add this content:

```ini
[Unit]
Description=FRP Client
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/frpc -c /etc/frp/frpc.ini
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now frpc.service
```

## Step 4: Disable your previous SSH tunnel service

Since FRP will now handle all the traffic forwarding, you can disable your previous SSH tunnel:

```bash
sudo systemctl stop mc-reverse-tunnel.service
sudo systemctl disable mc-reverse-tunnel.service
```

## Step 5: Check if everything is working

Check the status of your FRP services:

```bash
# On datacenter machine
sudo systemctl status frps.service

# On home server
sudo systemctl status frpc.service
```

Look for any errors in the logs. If everything is working correctly, both services should show as "active (running)".

You should now be able to connect to your datacenter machine's IP address on port 25565 for Java Minecraft and on port 19132 for Bedrock Minecraft via GeyserMC.
