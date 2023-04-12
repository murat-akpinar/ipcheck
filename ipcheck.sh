#!/bin/bash

# Check if nmap and fping are installed
if ! command -v nmap &> /dev/null || ! command -v fping &> /dev/null; then
  echo "This script requires nmap and fping to be installed. Please install these packages and try again."
  exit 1
fi

# Define the network address and subnet mask for your site
NETWORK="192.168.1.0/24"

# Generate a list of all possible IP addresses on your site
IP_LIST=$(for i in {1..254}; do echo "${NETWORK%.*}.$i"; done)

# Use nmap to scan for active hosts on your site
ACTIVE_HOSTS=$(sudo nmap -sn $NETWORK | grep "is up" | cut -d " " -f 2)

# Check each IP address to see if it is in use
IN_USE=()
TOTAL_IPS=$(echo $IP_LIST | wc -w)
for ((i=1; i<=$TOTAL_IPS; i++)); do
  IP=$(echo $IP_LIST | cut -d " " -f $i)
  if ! echo "$ACTIVE_HOSTS" | grep -q $IP && fping -c 1 -t 500 $IP >/dev/null 2>&1; then
    IN_USE+=($IP)
  fi
  PERCENT=$((100 * i / TOTAL_IPS))
  echo -ne "Scanning IPs... $PERCENT%\r"
done
echo -ne "\n"

# Compare the two lists to find free IP addresses
FREE_IPS=$(comm -23 <(echo "$IP_LIST" | sort) <(echo "$ACTIVE_HOSTS ${IN_USE[@]}" | tr ' ' '\n' | sort))

# Write the results to a log file with the current date
LOG_FILE="./$(date +%Y-%m-%d).log"
echo "IP scan results on $(date):" >> $LOG_FILE
echo "IP addresses in use but not responding to ICMP packets:" >> $LOG_FILE
echo "-------------------------------------" >> $LOG_FILE
echo "${IN_USE[@]}" >> $LOG_FILE
echo "-------------------------------------" >> $LOG_FILE
echo "Free IP addresses:" >> $LOG_FILE
echo "-------------------------------------" >> $LOG_FILE
echo "$FREE_IPS" >> $LOG_FILE

echo "finished"

