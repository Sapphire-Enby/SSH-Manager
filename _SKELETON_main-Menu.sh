#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # cd into script dir, then captures pwd as str
SSHLOG_DIR="$SCRIPT_DIR/Server-Records/"
main() {
    PS3="Choose an option: "
    options=("List available servers" "Connect to server" "Generate new interface record" "Exit")
    
    select choice in "${options[@]}"; do
        case $REPLY in
            1) clear
               echo "Listing servers..."
               echo ""
               ls -1 $SSHLOG_DIR
               ;;
            2) clear
               echo "Select a server..."
               SELECTED_RECORD="$(./sshlog_selector.sh $SSHLOG_DIR)"
               echo "Filepath found $SELECTED_RECORD"
               [ -f $SELECTED_RECORD ] && echo "file found"
               echo "started choose_ip.sh"

               mapfile -t user_ip < <(./choose_ip.sh "$SELECTED_RECORD") 
               echo "${user_ip[1]}"
               sleep 3 
               clear
               ;;
            3) echo "Generating new record..."
               # Run get_interfaces.sh
               ;;
            4) echo "Goodbye!"
               exit 0
               ;;
            *) echo "Invalid option. Please try again."
               read -t 5 -p "hit enter to continue:"
               REPLY=
               clear
               ;;
        esac
        read -t 5 -p "Hit enter to continue:"
        REPLY=
        clear

    done
}

main
