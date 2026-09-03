#!/bin/bash

# OneDrive TUI using whiptail
# Designed for abraunegg/onedrive client on Ubuntu

# Ensure whiptail is installed
if ! command -v whiptail &> /dev/null; then
    echo "whiptail is not installed. Please install it using 'sudo apt install whiptail'."
    exit 1
fi

# Ensure onedrive is installed
if ! command -v onedrive &> /dev/null; then
    whiptail --title "Error" --msgbox "OneDrive client not found. Please install the abraunegg/onedrive client first." 8 78
    exit 1
fi

BACKTITLE="OneDrive Client TUI"
show_menu() {
    whiptail --title "OneDrive Main Menu" \
        --backtitle "$BACKTITLE" \
        --menu "Select an option:" 21 78 13 \
        "1" "Synchronize Now" \
        "2" "Full Resync (Rebuild Database)" \
        "3" "View Sync Status" \
        "4" "View Configuration" \
        "5" "Edit Configuration" \
        "6" "Manage Sync List" \
        "7" "Start Background Monitor" \
        "8" "Stop Background Monitor" \
        "9" "Check Background Monitor Status" \
        "10" "View Monitor Logs" \
        "11" "Authenticate / Re-Authenticate" \
        "12" "Exit" \
        3>&1 1>&2 2>&3
}

pause() {
    echo ""
    read -p "Press [Enter] to return to the menu..."
}

manage_sync_list() {
    SYNC_LIST_FILE="${HOME}/.config/onedrive/sync_list"
    mkdir -p "$(dirname "$SYNC_LIST_FILE")"
    touch "$SYNC_LIST_FILE"
    
    whiptail --title "Manage Sync List" --backtitle "$BACKTITLE" \
        --msgbox "You are about to edit the sync_list file.\n\nInstructions:\n- Add one directory or file per line (relative to OneDrive root).\n- To include, just type the path: /Documents\n- To exclude, prefix with '!': !/Documents/temp\n\nThe file will open in nano. Press Ctrl+O to save, and Ctrl+X to exit." 16 70
    
    # Use default EDITOR or nano if not set
    ${EDITOR:-nano} "$SYNC_LIST_FILE"
}

edit_config() {
    CONFIG_FILE="${HOME}/.config/onedrive/config"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    update_config() {
        local key="$1"
        local val="$2"
        if [ -n "$val" ]; then
            if [ -f "$CONFIG_FILE" ] && grep -qE "^${key}\s*=" "$CONFIG_FILE"; then
                sed -i "s|^${key}\s*=.*|${key} = \"${val}\"|" "$CONFIG_FILE"
            else
                echo "${key} = \"${val}\"" >> "$CONFIG_FILE"
            fi
        else
            if [ -f "$CONFIG_FILE" ]; then
                sed -i "/^${key}\s*=.*/d" "$CONFIG_FILE"
            fi
        fi
    }

    get_config() {
        local key="$1"
        if [ -f "$CONFIG_FILE" ]; then
            grep -E "^${key}\s*=" "$CONFIG_FILE" | cut -d'=' -f2- | tr -d ' "'
        fi
    }

    while true; do
        CHOICE=$(whiptail --title "Edit Configuration" --backtitle "$BACKTITLE" \
            --menu "Select an option to edit:" 22 85 14 \
            "sync_dir" "Directory used for synchronisation" \
            "skip_file" "Files to skip from syncing" \
            "skip_dir" "Directories to skip from syncing" \
            "monitor_interval" "Seconds between sync operations in monitor mode" \
            "monitor_log_frequency" "Frequency of logging in monitor mode" \
            "monitor_fullscan_frequency" "Sync cycles before full scan" \
            "check_nomount" "Check for .nosync in syncdir root (true/false)" \
            "check_nosync" "Check for .nosync in each directory (true/false)" \
            "download_only" "Only download changes (true/false)" \
            "upload_only" "Only upload changes (true/false)" \
            "disable_notifications" "Disable desktop notifications (true/false)" \
            "local_first" "Sync from local first (true/false)" \
            "skip_dot_files" "Skip dot files and folders (true/false)" \
            "skip_size" "Skip new files larger than this size in MB" \
            "skip_symlinks" "Skip syncing of symlinks (true/false)" \
            "threads" "Number of worker threads" \
            "Back" "Return to Main Menu" \
            3>&1 1>&2 2>&3)
            
        if [ $? -ne 0 ] || [ "$CHOICE" = "Back" ]; then
            break
        fi
        
        # Get description for the chosen key
        DESC=""
        case "$CHOICE" in
            sync_dir) DESC="Directory used for synchronisation to OneDrive. (e.g. ~/OneDrive)";;
            skip_file) DESC="Skip any files that match this pattern. (e.g. ~*|.~*|*.tmp)";;
            skip_dir) DESC="Skip any directories that match this pattern.";;
            monitor_interval) DESC="Number of seconds between sync operations. (e.g. 300)";;
            monitor_log_frequency) DESC="Frequency of logging in monitor mode. (e.g. 5)";;
            monitor_fullscan_frequency) DESC="Number of scheduled monitor-interval sync cycles before full-scan. (e.g. 12)";;
            check_nomount) DESC="Check for the presence of .nosync in the syncdir root. (true or false)";;
            check_nosync) DESC="Check for the presence of .nosync in each directory. (true or false)";;
            download_only) DESC="Replicate the OneDrive online state locally, do not upload. (true or false)";;
            upload_only) DESC="Only upload local changes to OneDrive. Do not download. (true or false)";;
            disable_notifications) DESC="Do not use desktop notifications in monitor mode. (true or false)";;
            local_first) DESC="Synchronise from the local directory source first. (true or false)";;
            skip_dot_files) DESC="Skip dot files and folders from syncing. (true or false)";;
            skip_size) DESC="Skip new files larger than this size in MB. (e.g. 1000)";;
            skip_symlinks) DESC="Skip syncing of symlinks. (true or false)";;
            threads) DESC="Number of worker threads used for parallel operations. (e.g. 4)";;
        esac
        
        CURRENT_VAL=$(get_config "$CHOICE")
        
        NEW_VAL=$(whiptail --title "Edit $CHOICE" --backtitle "$BACKTITLE" \
            --inputbox "Configuration Option: $CHOICE\n\n# $DESC\n\nLeave empty to use default/remove." 12 70 "$CURRENT_VAL" \
            3>&1 1>&2 2>&3)
            
        if [ $? -eq 0 ]; then
            update_config "$CHOICE" "$NEW_VAL"
            whiptail --title "Success" --msgbox "'$CHOICE' updated successfully." 8 45
        fi
    done
}

while true; do
    CHOICE=$(show_menu)
    EXITSTATUS=$?
    
    if [ $EXITSTATUS -ne 0 ]; then
        clear
        exit 0
    fi
    
    case $CHOICE in
        "1")
            clear
            echo "Starting Synchronization..."
            echo "----------------------------------------"
            onedrive --sync -s
            echo "----------------------------------------"
            echo "Synchronization complete."
            pause
            ;;
        "2")
            whiptail --title "Warning: Full Resync" --backtitle "$BACKTITLE" \
                --yesno "A full resync will delete the client's local state database and rebuild it from the current online state.\n\nThis is only needed if you changed your sync directory or sync_list.\n\nAre you sure you want to proceed?" 12 70
            if [ $? -eq 0 ]; then
                clear
                echo "Starting Full Resync..."
                echo "----------------------------------------"
                onedrive --resync --sync -s
                echo "----------------------------------------"
                echo "Resync complete."
                pause
            fi
            ;;
        "3")
            TEMP_FILE=$(mktemp)
            onedrive --display-sync-status > "$TEMP_FILE" 2>&1
            whiptail --title "Sync Status" --backtitle "$BACKTITLE" --scrolltext --textbox "$TEMP_FILE" 24 80
            rm -f "$TEMP_FILE"
            ;;
        "4")
            TEMP_FILE=$(mktemp)
            onedrive --display-config > "$TEMP_FILE" 2>&1
            whiptail --title "Configuration" --backtitle "$BACKTITLE" --scrolltext --textbox "$TEMP_FILE" 24 80
            rm -f "$TEMP_FILE"
            ;;
        "5")
            edit_config
            ;;
        "6")
            manage_sync_list
            ;;
        "7")
            systemctl --user start onedrive >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                whiptail --title "Success" --backtitle "$BACKTITLE" --msgbox "Background monitor service started successfully via systemctl." 8 60
            else
                nohup onedrive --monitor > /dev/null 2>&1 &
                if [ $? -eq 0 ]; then
                    whiptail --title "Success (Fallback)" --backtitle "$BACKTITLE" --msgbox "systemctl failed. Started background monitor via nohup instead." 8 60
                else
                    whiptail --title "Error" --backtitle "$BACKTITLE" --msgbox "Failed to start background monitor service via both systemctl and nohup." 8 60
                fi
            fi
            ;;
        "8")
            systemctl --user stop onedrive >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                pkill -f 'onedrive --monitor'
                whiptail --title "Success" --backtitle "$BACKTITLE" --msgbox "Background monitor service stopped." 8 60
            else
                pkill -f 'onedrive --monitor'
                if [ $? -eq 0 ]; then
                    whiptail --title "Success (Fallback)" --backtitle "$BACKTITLE" --msgbox "systemctl failed, but stopped nohup background monitor." 8 60
                else
                    whiptail --title "Error" --backtitle "$BACKTITLE" --msgbox "Failed to stop background monitor service (no nohup process found either)." 8 60
                fi
            fi
            ;;
        "9")
            TEMP_FILE=$(mktemp)
            systemctl --user status onedrive > "$TEMP_FILE" 2>&1
            if [ $? -ne 0 ]; then
                echo -e "\nNote: systemctl failed or is not running. Checking for standalone nohup processes:" >> "$TEMP_FILE"
                ps aux | grep '[o]nedrive --monitor' >> "$TEMP_FILE"
                if [ $? -ne 0 ]; then
                    echo "No standalone onedrive --monitor processes found." >> "$TEMP_FILE"
                fi
            else
                if pgrep -f 'onedrive --monitor' > /dev/null; then
                    echo -e "\nNote: found running standalone nohup processes as well:" >> "$TEMP_FILE"
                    ps aux | grep '[o]nedrive --monitor' >> "$TEMP_FILE"
                fi
            fi
            whiptail --title "Monitor Service Status" --backtitle "$BACKTITLE" --scrolltext --textbox "$TEMP_FILE" 24 80
            rm -f "$TEMP_FILE"
            ;;
        "10")
            clear
            echo "Showing logs for OneDrive service. Press 'q' to exit the log viewer."
            echo "------------------------------------------------------------------"
            journalctl --user-unit=onedrive -f
            pause
            ;;
        "11")
            clear
            echo "Authentication"
            echo "----------------------------------------"
            echo "Please follow any prompts below to authenticate."
            onedrive --reauth
            echo "----------------------------------------"
            pause
            ;;
        "12")
            clear
            exit 0
            ;;
    esac
done
