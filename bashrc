#!/bin/bash
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
  echo "OS version: $(lsb_release -d | awk '{print $2,$3,$4}')"
  echo "Kernel version: $(uname -r)"
  echo "CPU usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')%"
  echo "Memory usage: $(free -m | awk 'NR==2{printf "%.2f%%", $3/$2*100}')"
  echo ""
  echo "Top 5 processes by CPU usage:"
  ps aux --sort=-%cpu | head -6
  echo ""
  echo "Top 5 processes by memory usage:"
  ps aux --sort=-%mem | head -6
}

docker-container-ip() {
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

docker-container-logs() {
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

docker-container-bash() {
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

docker-cleanup() {
  docker system prune -f
  docker volume prune -f
}

docker-images() {
  docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}"
}

docker-pull-all() {
  docker-compose -f "$1" pull
}
