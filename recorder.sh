#!/usr/bin/env bash

# Function to handle file naming with validation
get_filename() {
    local filename
    
    while true; do
        read -p "Enter filename (letters only, no extension): " filename
        
        # Check if input contains only letters
        if [[ "$filename" =~ ^[a-zA-Z]+$ ]]; then
            # Add .txt extension
            filename="${filename}.sshlog"
            
            # Check if file already exists in Server-Records
            if [[ -f "Server-Records/$filename" ]]; then
                echo "Error: File 'Server-Records/$filename' already exists. Please choose a different name."
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
    # 1. Prompt for username and IP address
        if [[ $# -eq 2 ]]; then
        username="$1"
        ip_address="$2"
    else
        read -p "Enter username: " username
        read -p "Enter IP address: " ip_address
    fi
    # Validate inputs
    if [[ -z "$username" || -z "$ip_address" ]]; then
        echo "Error: Username and IP address are required"
        exit 1
    fi
    
    # 2. SSH and run get_interfaces.sh, assign to interface_record variable
    echo "Connecting to $username@$ip_address..."
    interface_record=$(ssh "$username@$ip_address" 'bash -s' < get_interfaces.sh 2>/dev/null)
    
    # Check if SSH command was successful
    if [[ $? -ne 0 ]]; then
        echo "Error: SSH connection failed"
        exit 1
    fi
    
    # 3. If variable isn't empty, handle file naming and writing
    if [[ -n "$interface_record" ]]; then
        # Create Server-Records directory if it doesn't exist
        mkdir -p Server-Records
        
        # Get filename from user with validation
        filename=$(get_filename)
        
        # 4. Write interface_record data to file
        echo "$interface_record" > "Server-Records/$filename"
        
        echo "Interface record saved to: Server-Records/$filename"
    else
        echo "Warning: No interface data received from remote host"
    fi
}

# Run main function
main
