#!/bin/bash

# Function to get current version from docker inspect
get_current_version() {
    docker inspect "$1" 2>/dev/null | grep -i version | head -n 1 | tr -d ' ",' | cut -d: -f2 || echo "Not pulled"
}

# Function to get latest version from Docker Hub API
get_latest_version() {
    local image=$1
    local repo=${image#docker.io/}
    curl -s "https://registry.hub.docker.com/v2/repositories/${repo}/tags/latest" | \
        grep -o '"name":"[^"]*' | cut -d'"' -f4
}

# Print header
printf "%-30s\t%-20s\t%-20s\n" "Image" "Current Version" "Latest Version"
printf "%s\n" "--------------------------------------------------------------------------------"

# Check each image
images=(
    "docker.io/prom/prometheus"
    "docker.io/grafana/grafana"
    "docker.io/prom/alertmanager"
    "docker.io/prom/blackbox-exporter"
    "docker.io/nginx"
)

for image in "${images[@]}"; do
    current=$(get_current_version "$image")
    latest=$(get_latest_version "$image")
    printf "%-30s\t%-20s\t%-20s\n" "$image" "$current" "$latest"
done
