#!/usr/bin/env bash

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly RECORDS_DIR="$SCRIPT_DIR/Server-Records"
readonly SSHLOG_EXTENSION=".sshlog"
readonly SSH_TIMEOUT=10

# Function to validate IP address
# Regex comparison for 1 to 3 values from 0-9 followed by a dot, four times
# then using . as a delimiter, reads $ip into array
# then for each element, check if octlet is over 255 (invalid)
# exits with proper code
validate_ip() {
    #read -r raw dont ignore \
    #read -a store in array
    #<<< pass string directly into commands std in
    local ip="$1"
    
    if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        # Check if each octet is valid (0-255)
        IFS='.' read -ra octets <<< "$ip" 
        for octet in "${octets[@]}"; do
            if [[ "$octet" -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Function to validate username
validate_username() {
    local username="$1"
    
    # Username should only contain alphanumeric, underscore, hyphen
    # also checks if unsername string is less than or equal to 32 characters
    if [[ "$username" =~ ^[a-zA-Z0-9_-]+$ ]] && [[ ${#username} -le 32 ]]; then
        return 0
    fi
    return 1
}

# Function to handle file naming with validation
get_filename() {
    local filename
    
    while true; do
        read -p "Enter filename (letters only, no extension): " filename
        
        # Check if input contains only letters
        if [[ "$filename" =~ ^[a-zA-Z]+$ ]]; then
            # Add .sshlog extension
            filename="${filename}${SSHLOG_EXTENSION}"
            
            # Check if file already exists in Server-Records
            if [[ -f "$RECORDS_DIR/$filename" ]]; then
                echo "Error: File '$RECORDS_DIR/$filename' already exists. Please choose a different name."
            else
                echo "$filename"
                return 0
            fi
        else
            echo "Error: Filename must contain only letters (a-z, A-Z)"
        fi
    done
}

# Main script
main() {
    # 1. Prompt for username and IP address with validation
    if [[ $# -eq 2 ]]; then
        username="$1"
        ip_address="$2"
    else
        # Get username with validation
        while true; do
            read -p "Enter username: " username
            if [[ -n "$username" ]] && validate_username "$username"; then #non zero and passes validation check 
                break #leave the loop
            else
                echo "Error: Username must contain only letters, numbers, underscore, or hyphen (max 32 chars)"
            fi
        done
        
        # Get IP address with validation
        while true; do
            read -p "Enter IP address: " ip_address
            if [[ -n "$ip_address" ]] && validate_ip "$ip_address"; then
                break
            else
                echo "Error: Please enter a valid IP address (format: xxx.xxx.xxx.xxx)"
            fi
        done
    fi
    
    # 2. SSH and run get_interfaces.sh, assign to interface_record variable
    # allows pubkey or password authentification, supresses errors, gives general error messag on fail.
    echo "Connecting to $username@$ip_address..."
    echo "This may take a few seconds..."
    
    if ! interface_record=$(ssh -o ConnectTimeout="$SSH_TIMEOUT" -o PasswordAuthentication=yes -o PubkeyAuthentication=yes "$username@$ip_address" 'bash -s' < "$SCRIPT_DIR/get_interfaces.sh" 2>/dev/null); then
        echo "Error: SSH connection failed. Please check:"
        echo "  - Username and IP address are correct"
        echo "  - SSH key authentication is set up"
        echo "  - Target host is reachable"
        echo "  - Target host has the required network utilities"
        exit 1
    fi
    
    # 3. If variable isn't empty, handle file naming and writing
    if [[ -n "$interface_record" ]]; then
        # Create Server-Records directory if it doesn't exist
        mkdir -p "$RECORDS_DIR"
        
        # Get filename from user with validation
        filename=$(get_filename)
        
        # 4. Write interface_record data to file
        echo "$interface_record" > "$RECORDS_DIR/$filename"
        
        echo "✓ Interface record saved to: $RECORDS_DIR/$filename"
        
        # Show what was recorded
        echo ""
        echo "Recorded data:"
        echo "-------------"
        cat "$RECORDS_DIR/$filename"
    else
        echo "Warning: No interface data received from remote host"
        echo "This could mean:"
        echo "  - The remote host doesn't have network interfaces configured"
        echo "  - The 'ip' command is not available on the remote host"
        echo "  - Permission issues on the remote host"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"