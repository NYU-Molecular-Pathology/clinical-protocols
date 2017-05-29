#!/bin/bash
# set -x
## USAGE: setup_user_python.sh
## DESCRIPTION: This script will set a user's .bashrc to automatically load Python 2.7 at login

py_command="module load python/2.7"

bashrc_file="${HOME}/.bashrc"

bash_profile_file="${HOME}/.bash_profile"

# make sure file exists
[ ! -f "$bash_profile_file" ] && printf "File %s not found, creating it.." && touch "$bash_profile_file"
[ ! -f "$bashrc_file" ] && printf "File %s not found, creating it.." && touch "$bashrc_file"

# make sure bashrc is included in bash_profile
if ! grep -Fq "$(basename "$bashrc_file")" "$bash_profile_file"
then
    printf "WARNING: %s file was not listed inside %s file.\n" "$(basename "$bashrc_file")" "$bash_profile_file"
fi

# check for pre-existing module load python
if ! grep -q "module load python" "$bashrc_file"
then
    printf "WARNING: '%s' was found in file %s. Make sure another version of Python is not being loaded already!\n" "module load python" "$bashrc_file"
    printf "You should remove other '%s' entries from %s, and try again. \nExiting script...\n" "module load python" "$bashrc_file"
    exit
fi

# check for pre-existing module load python/2.7
if grep -q "$py_command" "$bashrc_file"
then
    printf "WARNING: '%s' was found in file %s. Make sure another version of Python is not being loaded already!\n" "$py_command" "$bashrc_file"
    printf "Your %s file does not need to be editted.\nExiting script...\n" "$bashrc_file"
    exit
else
    printf "Adding entry '%s' to file %s" "$py_command" "$bashrc_file"
    echo "$py_command" >> "$bashrc_file"
fi
