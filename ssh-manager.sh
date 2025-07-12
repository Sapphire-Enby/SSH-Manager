#!/usr/bin/env bash

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SSHLOG_DIR="$SCRIPT_DIR/Server-Records/"
readonly MENU_TIMEOUT=5

# Colors for better visual appeal
# these '\' characters are why echo need -e
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global variables
declare SELECTED_RECORD
declare -a SERVER_ARR

# Function to print colored output
# -e means to enable '\' interperatation
# otherwise \n wouldn't be newline
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header() { #called with param expansion to avoid string touching issues
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}       SSH Manager v1.0        ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# Menu action functions

list_servers() {
    clear
    print_header
    echo "Available servers:"
    echo ""
    
    if ls -1 "$SSHLOG_DIR"*.sshlog 2>/dev/null; then
        echo ""
        print_success "Server records found"
    else
        print_warning "No server records found"
    fi
}

select_server_file() {
    echo "Select a server to connect to..."
    echo ""
    
    if SELECTED_RECORD="$("$SCRIPT_DIR/sshlog_selector.sh" "$SSHLOG_DIR")"; then
        echo "Filepath found: $SELECTED_RECORD"
        [ -f "$SELECTED_RECORD" ] && print_success "File confirmed"
        read -p "Press enter to continue..."
        return 0
    else
        # Else: sshlog_selector.sh failed - user cancelled or no .sshlog files found
        print_warning "No server selected or operation cancelled"
        return 1
    fi
}

get_connection_details() {
    local selected_file="$1"
    
    echo "Getting server connection details..."
    
    # mapfile -t: read lines into array, remove trailing newlines
    # < <(): process substitution - treats command output like a file
    if mapfile -t SERVER_ARR < <("$SCRIPT_DIR/choose_ip.sh" "$selected_file"); then
        if [[ ${#SERVER_ARR[@]} -ge 2 ]]; then
            echo ""
            echo "Connection details received:"
            echo "Username: ${SERVER_ARR[0]}"
            echo "IP Address: ${SERVER_ARR[1]}"
            return 0
        else
            # Else: SERVER_ARR has less than 2 elements (missing username or IP)
            print_error "Invalid server data received"
            return 1
        fi
    else
        # Else: mapfile failed - choose_ip.sh returned error or no output
        print_error "Failed to get server information"
        return 1
    fi
}

establish_ssh_connection() {
    read -p "Press enter to connect..."
    clear
    
    echo -e "${BLUE}Connecting to ${SERVER_ARR[0]}@${SERVER_ARR[1]}...${NC}"
    echo "Press Ctrl+C to cancel if connection hangs"
    echo ""
    
    if ssh "${SERVER_ARR[0]}@${SERVER_ARR[1]}"; then
        print_success "SSH session completed"
    else
        print_error "SSH connection failed"
    fi
}

connect_to_server() {
    clear
    print_header
    
    # Step 1: Select server file
    if ! select_server_file; then
        return 1
    fi
    
    clear
    print_header
    
    # Step 2: Get connection details  
    if ! get_connection_details "$SELECTED_RECORD"; then
        return 1
    fi
    
    # Step 3: Establish SSH connection
    establish_ssh_connection
}

generate_record() {
    clear
    print_header
    echo "Generating new server record..."
    echo ""
    
    if "$SCRIPT_DIR/recorder.sh"; then
        print_success "Server record created successfully"
    else
        print_error "Failed to create server record"
    fi
}

exit_program() {
    echo ""
    print_success "Thank you for using SSH Manager!"
    exit 0
}

main() {
    PS3="Choose an option: " # reassign the select promp
    options=("List available servers" "Connect to existing server record" "Generate new interface record" "Exit")
    
    while true; do
        print_header
        select choice in "${options[@]}"; do
            case $REPLY in
                1) list_servers ;;
                2) connect_to_server ;;
                3) generate_record ;;
                4) exit_program ;;
                *) print_error "Invalid option. Please try again." ;;
            esac
            
            echo ""
            read -t "$MENU_TIMEOUT" -p "Press enter to continue (auto-continue in ${MENU_TIMEOUT}s)..."
            REPLY= # reset reply value 
            clear
            break
        done
    done
}

main