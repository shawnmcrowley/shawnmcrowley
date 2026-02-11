#!/bin/bash
# Daily system update + cleanup

LOGFILE="/var/log/daily_maintenance.log"

echo "=== Daily maintenance started at $(date) ===" >> "$LOGFILE"

# System update
echo "Updating packages…" >> "$LOGFILE"
sudo apt update && sudo apt upgrade -y >> "$LOGFILE"

# Clean old packages
echo "Cleaning up old packages…" >> "$LOGFILE"
sudo apt autoremove -y >> "$LOGFILE"
sudo apt autoclean >> "$LOGFILE"

# Disk usage report
echo "Disk usage report:" >> "$LOGFILE"
df -h >> "$LOGFILE"

echo "=== Daily maintenance completed at $(date) ===" >> "$LOGFILE"