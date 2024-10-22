#!/bin/bash
set -x
eval $(python3 /home/pinaka/tmps/script.py)
install_date_file="/home/pinaka/all_in_one/vpinakastra/.install-date"
stop_time_file="/home/pinaka/all_in_one/vpinakastra/stop-time.txt"
nodes=("$")  # List of nodes

max_uptime_seconds=$((20 * 86400))  # 20 days in seconds

trial_end_message=$(cat <<EOF
\033[1;31m
************************************************************
*  YOUR PINAKASTRA CLOUD TRIAL PERIOD WILL END SOON.        *
*  TO CONTINUE USING PINAKASTRA CLOUD, REACH OUT TO        *
*  CLOUD@PINAKASTRA.COM                                    *
*  Trial period ends at: %s
************************************************************
\033[0m
EOF
)

banner_message=$(cat <<EOF
\033[1;31m
************************************************************
*  YOUR PINAKASTRA CLOUD TRIAL PERIOD HAS ENDED.           *
*  TO CONTINUE USING PINAKASTRA CLOUD, REACH OUT TO        *
*  CLOUD@PINAKASTRA.COM                                    *
************************************************************
\033[0m
EOF
)

set_login_banner() {
    for node in "${nodes[@]}"; do
        ssh "$node" "echo -e '$banner_message' | sudo tee /etc/motd > /etc/issue"
    done
}

display_remaining_trial_time() {
    current_date_epoch=$(date +%s)
    end_date_epoch=$((install_date_epoch + max_uptime_seconds))
    end_date=$(date -d @"$end_date_epoch")
    remaining_seconds=$((end_date_epoch - current_date_epoch))

    if [ "$remaining_seconds" -gt 0 ]; then
        remaining_days=$((remaining_seconds / 86400))
        remaining_hours=$(( (remaining_seconds % 86400) / 3600 ))
        remaining_minutes=$(( (remaining_seconds % 3600) / 60 ))
        printf "$trial_end_message" "$end_date"
        echo "Trial time remaining: $remaining_days days, $remaining_hours hours, and $remaining_minutes minutes."
        echo "Docker services will be stopped at: $end_date"
    else
        echo "Trial time has ended. Docker services should be stopped soon."
    fi
}

stop_docker_on_node() {
    node=$1
    echo "Stopping Docker service on $node..."
    ssh "$node" "sudo systemctl stop docker.service 2>/dev/null"

    echo "Disabling Docker service on $node..."
    ssh "$node" "sudo systemctl disable docker.service 2>/dev/null"

    stop_time=$(date)
    echo "Docker services stopped at: $stop_time on $node" >> "$stop_time_file"
}

stop_containers() {
    node=$1
    echo "Stopping all Docker containers on $node..."
    ssh "$node" "sudo docker stop \$(docker ps -aq) 2>/dev/null"
}

check_docker_uptime_on_node() {
    node=$1
    echo "Checking Docker service on $node..."
    if ssh "$node" "sudo systemctl is-active --quiet docker.service"; then
        echo "Docker is running on $node."
        return 0
    else
        echo "Docker is not running on $node."
        return 1
    fi
}

check_and_perform_actions() {
    if [ ! -f "$install_date_file" ]; then
        echo "Install date file not found. Exiting..."
        exit 1
    fi

    install_date=$(cat "$install_date_file")
    install_date_epoch=$(date -d "$install_date" +%s)
    current_date_epoch=$(date +%s)
    seconds_uptime=$((current_date_epoch - install_date_epoch))

    display_remaining_trial_time

    if [ "$seconds_uptime" -ge "$max_uptime_seconds" ]; then
        echo "Trial time ended, checking Docker service status before taking action."

        docker_running=false
        for node in "${nodes[@]}"; do
            if check_docker_uptime_on_node "$node"; then
                docker_running=true
                break
            fi
        done

        if [ "$docker_running" = true ]; then
            echo "Docker service is running, taking action."
            for node in "${nodes[@]}"; do
                if check_docker_uptime_on_node "$node"; then
                    stop_containers "$node"
                else
                    echo "Docker service is not active on $node, so no action taken."
                fi
            done

            for node in "${nodes[@]}"; do
                if check_docker_uptime_on_node "$node"; then
                    stop_docker_on_node "$node"
                else
                    echo "Docker service is not active on $node, so no action taken."
                fi
            done

            set_login_banner

            for node in "${nodes[@]}"; do
                ssh "$node" "sudo reboot"
            done
        else
            echo "Docker service is not running on any node, so no action taken."
        fi
    else
        echo "Trial time is not exceeded, so no action taken."
    fi
}

while true; do
    if [ -f "$install_date_file" ]; then
        check_and_perform_actions
    else
        echo "Install date file not found. Exiting..."
        exit 1
    fi

    sleep 3600  # Sleep for 1 hour
done
