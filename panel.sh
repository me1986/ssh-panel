#!/bin/bash

version="2.9"
date="2025-10-17"
title="SSH Panel v$version"

linux_dist() {
    if [ -x "$(command -v yum)" ]; then
        echo "CentOS/RHEL"
    elif [ -x "$(command -v apt-get)" ]; then
        echo "Debian/Ubuntu"
    else
        echo "Unsupported"
        exit 1
    fi
}

get_users() {
    awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd
}

is_suspended() {
    local username="$1"
    local account_status

    account_status=$(sudo chage -l "$username" 2>/dev/null | grep "Password expires")

    if [ -z "$(echo "$account_status" | grep "never")" ]; then
        return 0
    else
        return 1
    fi
}

manage_users() {
    users=$(get_users)

    if [ -n "$1" ]; then
        filtered_users=""
        for user in $users; do
            if echo "$user" | grep -q "$1"; then
                filtered_users="$filtered_users $user"
            fi
        done
        users="$filtered_users"
    fi

    local i=1
    local choices=""
    local user_list=""

    for user in $users; do
        local text
        if is_suspended "$user"; then
            text="$user(suspended)"
        else
            text="$user"
        fi
        choices="$choices $i $text"
        user_list="$user_list$user "
        i=$(($i+1))
    done

    choice=$(dialog --clear --backtitle "$title" \
        --title "Non-System Users" \
        --menu "Select username:" 30 60 20 $choices 2>&1 >/dev/tty)

    username="$(echo "$user_list" | cut -d " " -f "$choice")"

    if [ -n "$username" ]; then
        choice=$(dialog --clear --backtitle "$title" \
            --title "Manage User: $username" \
            --menu "\nChoose an action:" 20 60 5 \
                "S" "Statistics" \
                "R" "Reset Password" \
                "U" "Suspend User" \
                "D" "Delete" \
            2>&1 >/dev/tty)

        case "$choice" in
            "S") # Statistics
                user_stats "$username"
                ;;
            
            "R") # Reset Password
                clear
                echo "Resetting password for \`$username\`"
                sudo passwd "$username"
                dialog --clear --backtitle "$title" --title "Success" --msgbox "\nPassword for \`$username\` updated successfully." 10 60
                ;;
            
            "U") # Suspend User
                confirmed_username=$(dialog --clear --backtitle "$title" --title "Suspend User" \
                --inputbox "Enter \`$username\` to confirm:" 10 60 2>&1 >/dev/tty)

                if [ "$username" = "$confirmed_username" ]; then
                    sudo passwd -e "$username"
                    dialog --clear --backtitle "$title" --title "Suspended" --msgbox "\nUser \`$username\` suspended successfully." 10 60
                else
                    dialog --clear --backtitle "$title" --title "Error!" --msgbox "\nOperation canceled!" 10 60
                fi
                ;;
            
            "D") # Delete
                confirmed_username=$(dialog --clear --backtitle "$title" --title "Delete User" \
                --inputbox "Enter \`$username\` to confirm:" 10 60 2>&1 >/dev/tty)

                if [ "$username" = "$confirmed_username" || "d"= "$confirmed_username" ]; then
                    sudo killall -u "$username"
                    sudo userdel -r "$username"
                    dialog --clear --backtitle "$title" --title "Deleted" --msgbox "\nUser `$username` deleted successfully." 10 60
                else
                    dialog --clear --backtitle "$title" --title "Error!" --msgbox "\nOperation canceled!" 10 60
                fi
                ;;
        esac
    fi
}

user_stats() {
    directory="/var/log/ssh-panel/users"
    
    if [ ! -d "$directory" ]; then
        mkdir -p "$directory"
    fi
    # ./hogs -type=csv /var/log/ssh-panel/* > hogs.csv
    local i=1
    if [ -n "$1" ]; then
        users="$1"
    else
        users=$(get_users)
    fi

    clear
    printf " |-------|-------------------------------------|--------------|--------------|\n"
    printf " |   #   |               Username              |  Upload(KB)  | Download(KB) |\n"
    printf " |-------|-------------------------------------|--------------|--------------|\n"
    for user in $users; do   
        user_upload=0
        user_download=0
        if test -f /var/log/ssh-panel/users/$user.csv; then
            while IFS="," read -r col1 col2 col3
                do
                    if [ "$col2" != 0 ]; then
                       # echo "$col2" 
                        user_upload=$(echo "($col2)"| bc)
                    fi
                    if [ "$col3" != 0 ]; then
                       # echo "$col3" 
                        user_download=$(echo "($col3)"| bc)
                    fi                   
                done < /var/log/ssh-panel/users/"$user".csv
            # rm -f /var/log/ssh-panel/users/"$user".csv
        fi

        # rm -f temp.csv
        # cat hogs.csv | grep ",$user," > temp.csv
        # while IFS=, read -r tmp upload download username path machine; do
        #     # date=$(echo "$path" | awk -F/ '{print $NF}' | awk -F. '{print $1}' | cut -d "-" -f "1-3")
        #     if [ -n "$upload" ]; then
        #         user_upload=$(echo "$user_upload + $upload" | bc)
        #     fi
        #     if [ -n "$download" ]; then
        #         user_download=$(echo "$user_download + $download" | bc)
        #     fi
        # done < temp.csv

        local text
        if is_suspended "$user"; then
            text="$user(suspended)"
        else
            text="$user"
        fi

        user_upload_formatted=$(echo $user_upload | numfmt --grouping)
        user_download_formatted=$(echo $user_download | numfmt --grouping)
        # sqlite3 dbtest.db <<'END_SQL'
        #     CREATE TABLE IF NOT EXISTS user1(name text, upload int, dowload int);
        #     insert into tbl1 values('"$text"', "$user_upload_formatted","$user_download_formatted");
        #     select * from user1
        #     END_SQL
        # echo "$user,$user_upload,$user_download" >> /var/log/ssh-panel/users/"$user".csv  

        printf " | %4d  |  %-34s |  %10s  |  %10s  |\n" $i "$text" "$user_upload_formatted" "$user_download_formatted"
        i=$((i + 1))
    done
    # rm -f /var/log/ssh-panel/*.log
    # rm -f temp.csv hogs.csv
    printf " |-------|-------------------------------------|--------------|--------------|\n\n"
    echo "Press Enter to continue..."
    dd bs=1 count=1 2>/dev/null
}

while true; do
    choice=$(dialog --clear --backtitle "$title" \
        --title "SSH User Management" \
        --no-cancel \
        --menu "\nChoose an operation:" 20 60 10 \
            "S" "Statistics" \
            "M" "Manage Users" \
            "C" "Create User" \
            "F" "Find User" \
            "U" "Update" \
            "A" "About" \
            "Q" "Quit" \
        2>&1 > /dev/tty)

    case "$choice" in
        "S") # Statistics
            choice=$(dialog --clear --backtitle "$title" \
                --title "Statistics" \
                --menu "\nChoose an action:" 20 60 5 \
                    "S" "Statistics / User" \
                    "C" "Clear Statistics" \
                2>&1 > /dev/tty)

            case "$choice" in
                "C") # Clear Statistics
                    prompt=$(dialog --clear --backtitle "$title" --title "Clear Statistics" \
                        --inputbox "Enter \`CLEAR\` to confirm:" 10 60 2>&1 >/dev/tty)
                    if [ "$prompt" = "CLEAR" ]; then
                        sudo rm -rf /var/log/ssh-panel/*.log
                        dialog --clear --backtitle "$title" --title "Success" --msgbox "\nStatistics cleared successfully." 10 60
                    else
                        dialog --clear --backtitle "$title" --title "Cancel" --msgbox "\nOperation canceled!" 10 60
                    fi
                    ;;

                *) # Statistics / User
                    user_stats
                    ;;

                # 2) # Daily
                #     ;;
            esac
            ;;

        "M") # Manage Users
            manage_users
            ;;

        "C") # Create User
            username=$(dialog --clear --backtitle "$title" \
                --title "Create User" \
                --inputbox "Enter Username:" 10 40 2>&1 >/dev/tty)

            if [ -n "$username" ]; then
                if [ linux_dist = "CentOS/RHEL" ]; then
                    sudo adduser --shell /usr/sbin/nologin "$username"
                else
                    sudo adduser --shell /usr/sbin/nologin --no-create-home --disabled-password --gecos "" "$username"
                fi
                dialog --clear --backtitle "$title" --title "Success" --msgbox "\nUser \`$username\` created successfully." 10 60
                clear
                sudo passwd "$username"
                dialog --clear --backtitle "$title" --title "Success" --msgbox "\nPassword for \`$username\` updated successfully." 10 60
            else
                dialog --clear --backtitle "$title" --title "Error!" --msgbox "\nOperation canceled!" 10 60
            fi
            ;;

        "F") # Find User
            username=$(dialog --clear --backtitle "$title" \
                --title "Find User" \
                --inputbox "Enter Username:" 10 40 2>&1 >/dev/tty)
            
            manage_users "$username"
            ;;

        "U") # Update Panel
            current_sha=$(cat version.info)
            latest_sha=$(curl -s "https://api.github.com/repos/me1986/ssh-panel/commits/main" | jq -r .sha)

            if [ "$current_sha" = "$latest_sha" ]; then
                dialog --clear --backtitle "$title" --title "Up to Date" --msgbox "\nYou already have the latest version." 10 60
            else
                prompt=$(dialog --clear --backtitle "$title" --title "Update Panel" \
                    --inputbox "Enter \`UPDATE\` to confirm:" 10 60 2>&1 >/dev/tty)
                if [ "$prompt" = "UPDATE" ]; then
                    cd ..
                    clear
                    wget -O ssh-panel-install.sh https://raw.githubusercontent.com/me1986/ssh-panel/main/install.sh
                    sudo rm -rf ssh-panel/* 
                    sudo sh ssh-panel-install.sh
                    sudo rm -f ssh-panel-install.sh
                    dialog --clear --backtitle "$title" --title "Success" --msgbox "\nPanel updated successfully." 10 60
                    clear
                    cd ..
                    exit
                else
                    dialog --clear --backtitle "$title" --title "Cancel" --msgbox "\nOperation canceled!" 10 60
                fi
            fi
            ;;

        "A") # About
            dialog --clear --backtitle "$title" \
            --title "About" \
            --msgbox "\n$title \n\nBy Hamid Test Version" 15 60
            ;;

        "Q") # Quit
            clear
            exit 0
            ;;
    esac
done

