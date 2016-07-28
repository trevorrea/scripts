#!/bin/bash
# To be used configuration management is not in use.  
# Puppet or Ansible would make this very simple.
set -x

# Checks if you have the right privileges
if [ "$USER" = "root" ]
then

NOW=$(date +"%Y-%m-%d-%X")
LOGFILE="USERADD-$NOW.log"

   # Checks if there is an argument
   [ $# -eq 0 ] && { echo >&2 ERROR: You may enter as an argument a colon separated text file with one entry per line. ; exit 1; }
   # checks if there a regular file
   [ -f "$1" ] || { echo >&2 ERROR: The input file does not exist. ; exit 1; }
   TMPIN=$(mktemp)
   # Remove blank lines and delete duplicates 
   sed '/^$/d' "$1"| sort -g | uniq > "$TMPIN"
   # Checks each line has four colon separated fields
   while IFS=':' read -ra fields; do        
      if [ ${#fields[@]} -ne 4 ]; then
        echo "Input file format invalid"
        echo >&2 "Input file format invalid" >> "$LOGFILE"
        exit 1
      else
        echo "Input file format valid"
        echo "Input file format valid" >> "$LOGFILE"
      fi
   done < "$TMPIN"

   IFS=:
      while read username fullname pass ssh_key
      do
      # Checks if the user already exists.
      cut -d: -f1 /etc/passwd | grep "$username" > /dev/null
      OUT=$?
      if [ $OUT -eq 0 ];then
         echo >&2 "ERROR: User account: \"$username\" already exists."
         echo >&2 "ERROR: User account: \"$username\" already exists." >> "$LOGFILE"
      else
         # Create a new user
         /usr/sbin/useradd -m "$username" -c "$fullname"
         # Add user to sudo group
         usermod -G sudo "$username"
         # Set password
         echo  "$username":"$pass" | /usr/sbin/chpasswd
         # Create .ssh directory
         mkdir -p /home/"$username"/.ssh
         # Set permissions on .ssh directory to 700
         chmod 700 /home/"$username"/.ssh
         # Change owner of .ssh directory to $username
         chown -R "$username":"$username" /home/"$username"/.ssh
         # Echo $key to authorized_keys file
         echo "$ssh_key" > /home/"$username"/.ssh/authorized_keys
         # Set permissions on .ssh/authorized_keys file to 600
         chmod 600 /home/"$username"/.ssh/authorized_keys
         echo "The user \"$username\" has been created"
         echo "The user \"$username\" has been created" >> "$LOGFILE"
      fi
  done < "$TMPIN"
   rm -f "$TMPIN"
   exit 0
else
   echo >&2 "ERROR: You must be a root user to execute this script."
   exit 1
fi
