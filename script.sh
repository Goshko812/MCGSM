#!/bin/bash

# EaglerServerXVelocity Automation Script
# This script automates the setup and management of Eagler servers in Docker

# Define color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed. Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        print_message "Docker installed successfully! You may need to log out and log back in for changes to take effect."
        return 1
    else
        print_message "Docker is already installed."
        return 0
    fi
}

# Function to initialize the environment inside Docker container
init_environment() {
    print_message "Initializing environment within Docker container..."
    
    # Enter the Docker container and run commands
    docker exec -it pmc-server bash -c '
        echo "Installing system dependencies..."
        apt update && apt install -y sudo nano ranger curl unzip zip tmux
        
        echo "Installing SDKMAN..."
        curl -s "https://get.sdkman.io" | bash
        
        echo "Initializing SDKMAN..."
        source "/root/.sdkman/bin/sdkman-init.sh"
        
        echo "Installing Java 21.0.2-amzn..."
        bash -c "source /root/.sdkman/bin/sdkman-init.sh && sdk install java 21.0.2-amzn"
        
        echo "Environment setup complete!"
        echo "Please change the forwarding.secret found in:"
        echo "persistent-storage-folder/mc-server/velocity/forwarding.secret"
        echo "persistent-storage-folder/mc-server/limbo/settings.yml"
        echo "persistent-storage-folder/mc-server/server/config/paper-global.yml under the velocity section"
    '
    
    if [ $? -eq 0 ]; then
        print_message "Environment initialization completed successfully!"
    else
        print_error "Environment initialization failed!"
        exit 1
    fi
}

# Function to stop all tmux sessions gracefully
stop_servers() {
    # Send Ctrl-C to each session, wait, then kill
    print_message "Sending Ctrl-C to velocity server session..."
    docker exec -it pmc-server bash -c '
        if tmux has-session -t velocity 2>/dev/null; then tmux send-keys -t velocity C-c; fi
    '
    print_message "Sending Ctrl-C to main server session..."
    docker exec -it pmc-server bash -c '
        if tmux has-session -t server 2>/dev/null; then tmux send-keys -t server C-c; fi
    '
    print_message "Sending Ctrl-C to limbo server session..."
    docker exec -it pmc-server bash -c '
        if tmux has-session -t limbo 2>/dev/null; then tmux send-keys -t limbo C-c; fi
    '
    print_message "Waiting 5 seconds for clean shutdown..."
    sleep 5
    print_message "Killing velocity session..."
    docker exec -it pmc-server bash -c 'tmux kill-session -t velocity 2>/dev/null || true'
    print_message "Killing main server session..."
    docker exec -it pmc-server bash -c 'tmux kill-session -t server 2>/dev/null || true'
    print_message "Killing limbo session..."
    docker exec -it pmc-server bash -c 'tmux kill-session -t limbo 2>/dev/null || true'
    print_message "All tmux sessions terminated."
}

# Function to start all servers using tmux sessions
start_servers() {
    print_message "Starting servers using tmux sessions..."
    
    # Start Velocity server
    docker exec -it pmc-server bash -c '
        cd /data/mc-server
        tmux new-session -d -s velocity
        tmux send-keys -t velocity "cd velocity && chmod +x velocity.sh && ./velocity.sh" C-m
        echo "Velocity server started!"
    '
    
    # Start main server
    docker exec -it pmc-server bash -c '
        cd /data/mc-server
        tmux new-session -d -s server
        tmux send-keys -t server "cd server && chmod +x server.sh && ./server.sh" C-m
        echo "Main server started!"
    '
    
    # Start Limbo server
    docker exec -it pmc-server bash -c '
        cd /data/mc-server
        tmux new-session -d -s limbo
        tmux send-keys -t limbo "cd limbo && chmod +x limbo.sh && ./limbo.sh" C-m
        echo "Limbo server started!"
    '
    
    print_message "All servers started successfully!"
    print_message "To attach to a server, use: docker exec -it pmc-server tmux a -t [velocity|server|limbo]"
    print_message "To change the MOTD edit motd: in persistent-storage-folder/mc-server/velocity/velocity.toml "
}

# Function to create a backup of the server folder
# Stops servers only if any tmux sessions are active, then zips /data/mc-server to a date-named file
backup_servers() {
    current_date=$(date +%Y-%m-%d)
    backup_name="pmc-server-backup-${current_date}.zip"

    # Check if any tmux sessions exist inside the container
    if docker exec pmc-server bash -c "tmux has-session -t velocity 2>/dev/null || tmux has-session -t server 2>/dev/null || tmux has-session -t limbo 2>/dev/null"; then
        print_message "Stopping servers before backup..."
        stop_servers
    else
        print_message "No running tmux sessions detected; skipping stop."
    fi

    print_message "Creating backup: $backup_name"
    docker exec -it pmc-server bash -c "cd /data && zip -r ${backup_name} mc-server"

    if [ $? -eq 0 ]; then
        print_message "Backup created successfully at: ./persistent-storage-folder/${backup_name}"
    else
        print_error "Backup creation failed!"
        exit 1
    fi
}

# Function to restore a backup to /data/mc-server
restore_servers() {
    backup_file="$1"
    print_message "Restoring backup: $backup_file"

    if [ -z "$backup_file" ]; then
        print_error "No backup file specified. Usage: $0 --restore FILENAME"
        exit 1
    fi
    if [ ! -f "persistent-storage-folder/$backup_file" ]; then
        print_error "Backup file not found in ./persistent-storage-folder/"
        exit 1
    fi

    # Stop servers if any are running
    if docker exec pmc-server bash -c "tmux has-session -t velocity 2>/dev/null || tmux has-session -t server 2>/dev/null || tmux has-session -t limbo 2>/dev/null"; then
        print_message "Stopping servers before restore..."
        stop_servers
    fi

    # Copy and unzip inside container
    docker cp "persistent-storage-folder/$backup_file" pmc-server:/data/
    docker exec -it pmc-server bash -c "
        rm -rf /data/mc-server &&
        unzip -o /data/$backup_file -d /data &&
        rm /data/$backup_file
    "

    if [ $? -eq 0 ]; then
        print_message "Backup restored successfully!"
    else
        print_error "Backup restoration failed!"
        exit 1
    fi
}

# Function to check if the Docker container is running
check_container_running() {
    if [ "$(docker ps -q -f name=pmc-server)" ]; then
        return 0
    else
        return 1
    fi
}

# Function to start Docker Compose
start_docker_compose() {
    print_message "Starting Docker Compose services..."
    
    # Check if we're in the directory with docker-compose.yml
    if [ ! -f "docker-compose.yml" ]; then
        print_warning "docker-compose.yml not found in current directory."
        print_message "Please navigate to the directory containing docker-compose.yml and try again."
        exit 1
    fi
    
    # Run docker compose up (modern approach)
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        print_message "Docker Compose services started successfully!"
    else
        print_error "Failed to start Docker Compose services!"
        exit 1
    fi
}

# Function to wait for container to be ready
wait_for_container() {
    print_message "Waiting for container to be fully started..."
    sleep 5  # Give the container time to initialize
}

# Display help message
show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --init      Check for Docker, start container, and initialize environment"
    echo "  --start     Start all Minecraft servers in tmux sessions"
    echo "  --stop      Stop all running Minecraft server tmux sessions"
    echo "  --backup    Create a backup of all server data"
    echo "  --restore   Restore a backup file: --restore FILENAME"
    echo "  --help      Display this help message"
    echo "" 
}

# Main script execution
case "$1" in
    --init)
        check_docker
        start_docker_compose
        wait_for_container
        init_environment
        ;;

    --start)
        if ! check_container_running; then
            print_warning "Docker container is not running. Starting it now..."
            start_docker_compose
            wait_for_container
        fi
        start_servers
        ;;

    --stop)
        if ! check_container_running; then
            print_error "Docker container is not running. Please start it first with --init or --start"
            exit 1
        fi
        stop_servers
        ;;

    --backup)
        if ! check_container_running; then
            print_error "Docker container is not running. Please start it first with --init or --start"
            exit 1
        fi
        backup_servers
        ;;
        
    --restore)
        if ! check_container_running; then
            print_error "Docker container is not running. Please start it first with --init or --start"
            exit 1
        fi
        restore_servers "$2"
        ;;

    --help)
        show_help
        ;;

    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac

exit 0
