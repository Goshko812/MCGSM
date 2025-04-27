> [!IMPORTANT]
> DOCS NOT FINISHED
> 

# MCGSM
Scripts to get your Minecraft 1.21.4 Server up and running without a hassle
The script initializes a Docker environment and setups everything necessary to run the velocity, limbo, and Minecraft server.
The script also supports making backups, which can and should be automated using [crontab](https://crontab.guru/).

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
