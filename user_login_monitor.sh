#!/bin/bash

# ===========================================
# User Login Monitor with Email Notification
# ===========================================

WATCH_USER="student"                # Replace 'student' with your username to monitor
ALERT_EMAIL="youremail@example.com" # Replace with your own email address
LOG_FILE="$HOME/user_monitor.log"
TEMP_FILE="/tmp/current_users.txt"
PID_FILE="/tmp/user_monitor.pid"

# Function: Send email alert
send_alert() {
    local user="$1"
    local time_now
    time_now=$(date)
    echo "Alert: User '$user' logged in at $time_now" | mail -s "Login Alert: $user" "$ALERT_EMAIL"
    echo "[$time_now] Email alert sent for user '$user' to $ALERT_EMAIL" >> "$LOG_FILE"
}

# Function: Start monitoring
start_monitor() {
    if [ -f "$PID_FILE" ]; then
        echo "Monitor is already running (PID: $(cat $PID_FILE))"
        return
    fi

    echo "Starting User Login Monitor..."
    who > "$TEMP_FILE"

    (
        echo "User Login Monitor Started at $(date)" >> "$LOG_FILE"
        echo "--------------------------------------" >> "$LOG_FILE"

        while true; do
            sleep 5
            NEW_USERS="/tmp/new_users.txt"
            who > "$NEW_USERS"

            LOGIN_USERS=$(comm -13 "$TEMP_FILE" "$NEW_USERS")
            if [ ! -z "$LOGIN_USERS" ]; then
                echo "[$(date)] Login detected:" >> "$LOG_FILE"
                echo "$LOGIN_USERS" >> "$LOG_FILE"
                echo "--------------------------------------" >> "$LOG_FILE"

                if echo "$LOGIN_USERS" | grep -q "$WATCH_USER"; then
                    send_alert "$WATCH_USER"
                fi
            fi

            LOGOUT_USERS=$(comm -23 "$TEMP_FILE" "$NEW_USERS")
            if [ ! -z "$LOGOUT_USERS" ]; then
                echo "[$(date)] Logout detected:" >> "$LOG_FILE"
                echo "$LOGOUT_USERS" >> "$LOG_FILE"
                echo "--------------------------------------" >> "$LOG_FILE"
            fi

            mv "$NEW_USERS" "$TEMP_FILE"
        done
    ) &

    echo $! > "$PID_FILE"
    echo "Monitoring started successfully (PID: $(cat $PID_FILE))"
}

# Function: Stop monitoring
stop_monitor() {
    if [ ! -f "$PID_FILE" ]; then
        echo "Monitor is not running."
        return
    fi

    PID=$(cat "$PID_FILE")
    kill "$PID" 2>/dev/null
    rm -f "$PID_FILE"
    echo "Monitoring stopped (PID: $PID)"
}

# Function: View log
view_log() {
    if [ -f "$LOG_FILE" ]; then
        echo "========= User Login Log ========="
        cat "$LOG_FILE"
        echo "=================================="
    else
        echo "No log file found!"
    fi
}

# Function: Clear log
clear_log() {
    > "$LOG_FILE"
    echo "Log file cleared."
}

# Menu loop
while true; do
    echo
    echo "===== USER LOGIN MONITOR MENU ====="
    echo "1. Start Monitoring"
    echo "2. Stop Monitoring"
    echo "3. View Log"
    echo "4. Clear Log"
    echo "5. Exit"
    echo "==================================="
    read -p "Enter your choice: " choice

    case $choice in
        1) start_monitor ;;
        2) stop_monitor ;;
        3) view_log ;;
        4) clear_log ;;
        5) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid choice! Try again." ;;
    esac
done

