# MCGSM
Scripts to get your Minecraft 1.21.4 Server up and running without a hassle
The script initializes a Docker environment and setups everything necessary to run the velocity, limbo, and Minecraft server.
The script also supports making backups, which can and should be automated using [crontab](https://crontab.guru/).

![trash code](https://img.shields.io/badge/code-trash%20🗑️-red)
![works](https://img.shields.io/badge/works-on%20my%20machine-brightgreen)
![bash magic](https://img.shields.io/badge/powered%20by-bash%20and%20hope-yellow)

### Setup

1. Download the repo:
```bash
git clone https://github.com/Goshko812/MCGSM
```
2. Enter the directory and make the script executable:
```bash
cd MCGSM && chmod +x script.sh
```
3. Run the script to initialize the environment:
```bash
./script.sh --init
```
4. Run the script again to start the servers:
```bash
./script --start
```
5. Profit
## Misc Information
#### Options:
```
--init      Check for Docker, start container, and initialize environment"
--start     Start all Minecraft servers in tmux sessions"
--stop      Stop all running Minecraft server tmux sessions"
--backup    Create a backup of all server data"
--restore   Restore a backup file: --restore FILENAME"
--help      Display this help message"
```
#### tmux cheat sheet
**Creating session**
```bash
tmux new -s <session_name>
```
**Connecting to session**
```bash
tmux a -t <session_name>
```
**Exiting a session**
```
hit control + B and then hit D
```
**Scroll Mode**
```
hit control + B and then hit [
```
You can exit scroll mode by hitting `Q`
