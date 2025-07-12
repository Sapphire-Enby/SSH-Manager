#!/usr/bin/env bash
# makes a menu to choose sshlog file

# Uses provided record directory or Server-Records folder near running script
script_dir="$(dirname "${BASH_SOURCE[0]}")"
record_dir="${1:-$script_dir/Server-Records/}" #:- set as if missing

# cd into dir and build array of *sshlog files
# exit if dir missing
cd "$record_dir" || exit 1
files=(*.sshlog) # if no files this will be a string literal 

# No file - exit failed
if [ ! -f "${files[0]}" ]; then 
    echo "No .sshlog files found" >&2
    exit 1
fi

# One file - use it
if [ ${#files[@]} -eq 1 ]; then # number of elements 
    selected_file="${files[0]}" # grab it immediately
 
# Multiple files - show menu without extensions
else
    # Create menu array
    names=()
    for file in "${files[@]}"; do
        names+=("${file%.*}") # file (remainder) match first .*
    done 
    # select a file name
    select f in "${names[@]}"; do
        # for index loop until its value is correct
        # use that index to get path of record
        for i in "${!names[@]}"; do # for indexes in array
            if [[ "${names[$i]}" == "$f" ]]; then
                selected_file="${files[$i]}"
                break
            fi
        done
        break
    done
fi

# no file - exit failed
if [ -z "$selected_file" ]; then 
    echo "file not selected" >&2
    exit 1 
else
    echo "$(realpath "$selected_file")" #return the full path of the .sshlog file 
    exit 0
fi