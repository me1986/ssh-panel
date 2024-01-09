#!/bin/bash
get_users() {
    awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd
}
user_stats() {
    directory="/var/log/ssh-panel/users"
    
    if [ ! -d "$directory" ]; then
        mkdir -p "$directory"
    fi
    ./hogs -type=csv /var/log/ssh-panel/* > hogs.csv
    local i=1
    if [ -n "$1" ]; then
        users="$1"
    else
        users=$(get_users)
    fi
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
            rm -f /var/log/ssh-panel/users/"$user".csv
        fi

        rm -f temp.csv
        cat hogs.csv | grep ",$user," > temp.csv
        while IFS=, read -r tmp upload download username path machine; do
            # date=$(echo "$path" | awk -F/ '{print $NF}' | awk -F. '{print $1}' | cut -d "-" -f "1-3")
            if [ -n "$upload" ]; then
                user_upload=$(echo "$user_upload + $upload" | bc)
            fi
            if [ -n "$download" ]; then
                user_download=$(echo "$user_download + $download" | bc)
            fi
        done < temp.csv

        local text
        if is_suspended "$user"; then
            text="$user(suspended)"
        else
            text="$user"
        fi
        echo "$user,$user_upload,$user_download" >> /var/log/ssh-panel/users/"$user".csv  

    
        i=$((i + 1))
    done
    rm -f /var/log/ssh-panel/*.log
    rm -f temp.csv hogs.csv
}

# nowminute=$(date +%M)
# topofhr="00"
# if [ "$nowminute" = "$topofhr" ]; then 
#     user_stats
# fi

# if [ ls -1 | wc -l = "$topofhr" ]; then 
#     user_stats
# fi

#  ls -1 | wc -l
user_stats
sleep 2s

timestamp=`date +%Y-%m-%d-%H-%M`
output=/var/log/ssh-panel/$timestamp.log

nethogs_pid=$(pgrep nethogs)
if [ -n "$nethogs_pid" ]; then
    kill "$nethogs_pid"
fi

nohup /usr/sbin/nethogs -t -a 2>&1 | grep 'sshd:' > "$output" 2>&1 &
