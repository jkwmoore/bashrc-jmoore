#!/bin/bash

# Exit early if not running an interactive shell
if [[ ! -n "$PS1" ]]; then
  return 0 2>/dev/null || exit 0
fi

############################################ General stuff ############################################
checksum() {
  for file in "$@"
  do
    if [ -f "$file" ]; then
      printf "%s:\n" "$file"
      md5=$(md5sum "$file" | awk '{ print $1 }')
      sha1=$(sha1sum "$file" | awk '{ print $1 }')
      sha256=$(sha256sum "$file" | awk '{ print $1 }')
      printf "  md5: %s\n  sha1: %s\n  sha256: %s\n" "$md5" "$sha1" "$sha256"
    else
      echo "File not found: $file"
    fi
  done
}

ssh-key-rhost-scan() {
    ssh-keygen -lf <(ssh-keyscan "$1" 2>/dev/null)
}

ssh-key-lhost-scan() {
    for key in /etc/ssh/ssh_host_*_key.pub; do
        ssh-keygen -lf "$key"
    done
}

ssl-cert-summary() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: ssl-cert-summary <cert_file> [<cert_file2> ...]"
    else
        for cert_file in "$@"; do
            if [[ ! -f "$cert_file" ]]; then
                echo "Error: '$cert_file' is not a valid certificate file."
                continue
            fi

            echo "Certificate file: $cert_file"
            echo "---------------------------------------"
            start_date=$(openssl x509 -startdate -noout -in "$cert_file" | awk -F= '{print $2}' | xargs -I{} date -d {} '+%Y-%m-%d')
            end_date=$(openssl x509 -enddate -noout -in "$cert_file" | awk -F= '{print $2}' | xargs -I{} date -d {} '+%Y-%m-%d')
            cn=$(openssl x509 -noout -subject -in "$cert_file" | sed 's/.*CN=\([^\/]*\).*/\1/g')
            sans=$(openssl x509 -noout -text -in "$cert_file" | awk '/DNS:/ {split($0, a, "DNS:"); for (i=2; i<=length(a); i++) {print a[i]}}')
            issuer=$(openssl x509 -noout -issuer -in "$cert_file" | sed 's/.*CN=\([^\/]*\).*/\1/g')
            fingerprint=$(openssl x509 -noout -fingerprint -sha256 -in "$cert_file" | awk -F= '{print $2}' | sed 's/://g')
            key_size=$(openssl x509 -noout -text -in "$cert_file" | awk '/Public-Key:/ {print $2}')
            key_type=$(openssl x509 -noout -text -in "$cert_file" | awk '/Public-Key:/ {print $3}')

            echo "Certificate start date: $start_date"
            echo "Certificate end date: $end_date"
            echo "Common name: $cn"
            if [[ -n "$sans" ]]; then
                echo "Subject alternative names: $sans"
            fi
            echo "Issuer: $issuer"
            echo "SHA-256 fingerprint: $fingerprint"
            echo "Public key size: $key_size"
            echo "Public key type: $key_type"
            echo "---------------------------------------"
        done
    fi
}

list-users() {
    if [[ $# -eq 1 ]]; then
        getent group "$1" | awk -F: '{print $4}' | tr ',' '\n'
    else
        getent passwd | cut -d: -f1,4 | while read -r line; do
            user=$(echo "$line" | cut -d: -f1)
            groups=$(id -Gn "$user" | tr ' ' ',')
            echo "$user [$groups]"
        done
    fi
}

port-check() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: port-check [hostname] port1 [port2 ...]"
        return 1
    fi
    
    local host="$1"
    shift

    if [[ $# -eq 0 ]]; then
        ports=(
            80:"HTTP"
            443:"HTTPS"
            22:"SSH"
            25:"SMTP"
            143:"IMAP"
            993:"IMAPS"
            110:"POP3"
            995:"POP3S"
            3306:"MySQL"
            5432:"PostgreSQL"
        )
    else
        ports=("$@")
    fi

    for port in "${ports[@]}"; do
        if [[ "$port" =~ ^[0-9]+$ ]]; then
            description=""
        else
            description="(${port#*:})"
            port="${port%%:*}"
        fi
        (echo >/dev/tcp/"$host"/"$port") &>/dev/null && echo "Port $port is open $description" || echo "Port $port is closed $description"
    done
}

find-largest-files() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: find-largest-files <directory>"
    else
        largest=$(find "$1" -type f -printf '%s\n' | sort -rn | head -1)
        if (( largest < 1024 )); then
            unit="B"
            divisor=1
        elif (( largest < 1048576 )); then
            unit="KB"
            divisor=1024
        elif (( largest < 1073741824 )); then
            unit="MB"
            divisor=1048576
        else
            unit="GB"
            divisor=1073741824
        fi
        find "$1" -type f -printf '%s %p\n' | sort -rn | head -20 | awk -v unit="$unit" -v divisor="$divisor" '{ printf "%.2f%s\t%s\n", $1/divisor, unit, $2 }'
    fi
}

dnslookup() {
  dig +short "$1"
}

ptrlookup() {
  if [ "$1" = "local" ]; then
    dig -x "$(curl -s https://ipinfo.io/ip)"
  else
    dig -x "$1"
  fi
}

watchlog() {
  tail -f "$1" | grep --color=always "$2"
}

sysinfo() {
  # ANSI color codes
  BOLD="\033[1m"
  RESET="\033[0m"
  CYAN="\033[1;36m"
  GREEN="\033[0;32m"
  WHITE="\033[1;37m"
  YELLOW="\033[0;33m"
  RED="\033[0;31m"

  echo -e "${CYAN}=== System Information ===${RESET}"
  echo -e "${WHITE}OS version     :${RESET} ${GREEN}$(source /etc/os-release && echo "$NAME $VERSION")${RESET}"
  echo -e "${WHITE}Kernel version :${RESET} ${GREEN}$(uname -r)${RESET}"
  echo ""

  echo -e "${CYAN}=== CPU Usage ===${RESET}"
  cpu_line=$(top -bn1 | grep "%Cpu(s)" | head -1)
  user=$(echo "$cpu_line" | awk -F',' '{print $1}' | awk '{print $2}')
  system=$(echo "$cpu_line" | awk -F',' '{print $2}' | awk '{print $1}')
  nice=$(echo "$cpu_line" | awk -F',' '{print $1}' | awk '{print $4}')
  idle=$(echo "$cpu_line" | awk -F',' '{print $4}' | awk '{print $1}')
  iowait=$(echo "$cpu_line" | awk -F',' '{print $5}' | awk '{print $1}')
  total_used=$(awk "BEGIN {print 100 - $idle}")
  echo -e "${WHITE}User     :${RESET} ${GREEN}${user}%${RESET}"
  echo -e "${WHITE}System   :${RESET} ${GREEN}${system}%${RESET}"
  echo -e "${WHITE}Nice     :${RESET} ${GREEN}${nice}%${RESET}"
  echo -e "${WHITE}I/O Wait :${RESET} ${GREEN}${iowait}%${RESET}"
  echo -e "${WHITE}Idle     :${RESET} ${GREEN}${idle}%${RESET}"
  echo -e "${WHITE}Total Used:${RESET} ${YELLOW}${total_used}%${RESET}"
  echo ""

  echo -e "${CYAN}=== Memory Usage (MB) ===${RESET}"
  read -r _ total used free shared buff_cache available < <(free -m | awk 'NR==2')
  echo -e "${WHITE}Total      :${RESET} ${GREEN}${total} MB${RESET}"
  echo -e "${WHITE}Used       :${RESET} ${GREEN}${used} MB${RESET}"
  echo -e "${WHITE}Free       :${RESET} ${GREEN}${free} MB${RESET}"
  echo -e "${WHITE}Shared     :${RESET} ${GREEN}${shared} MB${RESET}"
  echo -e "${WHITE}Buff/Cache :${RESET} ${GREEN}${buff_cache} MB${RESET}"
  echo -e "${WHITE}Available  :${RESET} ${GREEN}${available} MB${RESET}"
  usage_pct=$(awk "BEGIN {printf \"%.2f\", $used / $total * 100}")
  echo -e "${WHITE}Usage      :${RESET} ${YELLOW}${usage_pct}%${RESET}"
  echo ""

  echo -e "${CYAN}=== Top 5 Processes by CPU Usage ===${RESET}"
  ps aux --sort=-%cpu | head -n 6
  echo ""

  echo -e "${CYAN}=== Top 5 Processes by Memory Usage ===${RESET}"
  ps aux --sort=-%mem | head -n 6
}

############################################ Docker stuff ############################################

dci() {
    local container_name=$1
    if [[ -n "$1" ]]; then
        local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1")
        echo "IP Address for container $1: $container_ip"
    else
        local running_containers=$(docker ps --format "{{.Names}}")
        if [ -z "$running_containers" ]; then
            echo "There are no running containers."
            return 1
        fi
        echo "Please select a container to view IP address for:"
        select container_name in $running_containers; do
            if [ -z "$container_name" ]; then
                echo "Invalid selection. Please try again."
            else
                local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name")
                echo "IP Address for container $1: $container_ip"
                break
            fi
        done
    fi
}

dcl() {
    local container_name=$1
    if [ -z "$container_name" ]; then
        local running_containers=$(docker ps --format "{{.Names}}")
        if [ -z "$running_containers" ]; then
            echo "There are no running containers."
            return 1
        fi
        echo "Please select a container to view logs for:"
        select container_name in $running_containers; do
            if [ -z "$container_name" ]; then
                echo "Invalid selection. Please try again."
            else
                break
            fi
        done
    fi

    if ! docker inspect "$container_name" >/dev/null 2>&1; then
        echo "Container $container_name not found."
        return 1
    fi

    docker logs -f --tail 20 "$container_name"
}

dcb() {
  local container_name=$1
  local containers=($(docker ps --format '{{.Names}}'))

  if [[ -z "$container_name" ]]; then
    # Prompt the user to select a container from the list of running containers
    echo "Please select a container to connect to:"
    select container_name in "${containers[@]}"; do
      if [[ -n "$container_name" ]]; then
        break
      fi
    done
  fi

  # Check if the container has bash shell and spawn a shell
  if docker exec -it "$container_name" bash -c 'echo $BASH_VERSION' &> /dev/null; then
    docker exec -it "$container_name" bash
  else
    docker exec -it "$container_name" sh
  fi
}

dcln() {
  docker system prune -f
  docker volume prune -f
}

dli() {
  docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}"
}

dpa() {
  if command -v docker-compose &> /dev/null; then
    docker-compose pull
  elif command -v docker &> /dev/null; then
    docker compose pull
  else
    echo "Error: Neither 'docker-compose' nor 'docker compose' is available. Please install either Docker Compose or Docker with Compose CLI."
  fi
}

############################################ HPC stuff ############################################

# If we have a modules system available load cmsh and slurm if present
MODULES_TO_LOAD=(cmsh slurm)

if type -t module > /dev/null 2>&1; then
  module_impl=$(type module)

  if echo "$module_impl" | grep -q '\$LMOD_CMD'; then
    echo "Detected module system: Lmod"
    for mod in "${MODULES_TO_LOAD[@]}"; do
      if module spider "$mod" > /dev/null 2>&1; then
        echo "Loading module: $mod"
        module --ignore_cache load "$mod"
      fi
    done

  elif echo "$module_impl" | grep -q '_module_raw'; then
    echo "Detected module system: Environment Modules (TCL)"
    alias ml='module'
    for mod in "${MODULES_TO_LOAD[@]}"; do
      if module avail "$mod" 2>&1 | grep -q "^$mod"; then
        echo "Loading module: $mod"
        module load "$mod"
      fi
    done
  else
    echo "Unknown module system: custom shell function"
  fi
else
  echo "No module system detected"
fi
