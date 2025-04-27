# Minecraft Reverse SSH Tunnel via VPS

Expose your home-hosted Minecraft server to the Internet through a public VPS (e.g. Oracle Free Tier) by using an SSH reverse tunnel managed by `autossh`. This README walks you through installing dependencies on the home server, configuring SSH on the VPS, creating a systemd service on your home server, and enabling the tunnel.

---

## Prerequisites

- **Home machine** running your Minecraft server on `localhost:25565`.  
- **Public VPS** (e.g. Oracle Free Tier) with a publicly reachable IP and SSH access.  
- **Root** (or sudo) privileges on both machines.

---

## 1. Install Dependencies on the Home Server

```bash
sudo apt update
sudo apt install -y autossh sshpass
```

> **Note:** You only need `autossh` and `sshpass` on your **home** machine. The VPS only requires the standard SSH server (no extra packages needed).

---

## 2. Configure the VPS SSH Daemon

1. SSH into your VPS:
   ```bash
   ssh root@<VPS_IP>
   ```
2. Edit `/etc/ssh/sshd_config` and ensure:
   ```conf
   GatewayPorts yes
   ```
3. Restart SSHD:
   ```bash
   systemctl restart sshd
   exit
   ```

---

## 3. Create the systemd Service on Your Home Server

On your **home** machine, as **root**

Open the `mc-reverse-tunnel.service` file and replace:
   - `<VPS_IP>` with your VPS’s public IP  
   - `<VPS_ROOT_PASSWORD>` with the root password on the VPS  

> **Note:** If you use a different port for the SSH connection, add `-p <port> \` after `-M 0 \`.

---

## 4. Enable & Start the Service

```bash
# Reload systemd definitions
sudo systemctl daemon-reload

# Enable auto-start at boot
sudo systemctl enable mc-reverse-tunnel

# Start the tunnel now
sudo systemctl start mc-reverse-tunnel
```

---

## 5. Verify & Test

- **Check service status:**
  ```bash
  sudo systemctl status mc-reverse-tunnel
  ```
- **Ensure the VPS is listening on port 25565:**
  ```bash
  sudo ss -tlpn | grep 25565
  ```
- **From any external client**, connect your Minecraft launcher to:
  ```
  <VPS_IP>:25565
  ```
  You should join your home-hosted world as if it were local.

---

## Notes & Security Considerations

- Storing your password in plaintext is **less secure**. For best practice, consider SSH key-based auth with an empty-passphrase key instead.  
- `StrictHostKeyChecking=no` and `UserKnownHostsFile=/dev/null` simplify automation but forfeit SSH’s host-fingerprint verification.  
- To disable password-auth entirely after setup, edit `/etc/ssh/sshd_config` on the VPS:
  ```conf
  PasswordAuthentication no
  PermitRootLogin prohibit-password
  ```
  And then restart SSHD.

