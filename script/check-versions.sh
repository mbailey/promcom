#!/bin/bash

# Function to get version from docker-compose.yml
get_compose_version() {
    local image=$1
    local version=$(grep "image: $image" docker-compose.yml | grep -o ":.*" || echo ":latest")
    echo "${version#:}"
}

# Function to get latest stable version from Docker Hub API
get_latest_stable_version() {
    local image=$1
    local repo=${image#docker.io/}
    # Get all tags and find the first one that looks like a version number
    curl -s "https://registry.hub.docker.com/v2/repositories/${repo}/tags?page_size=100" | \
        jq -r '.results[].name' | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1
}

# Print header
printf "%-30s\t%-20s\t%-20s\n" "Image" "Current Version" "Latest Stable Version"
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
    current=$(get_compose_version "$image")
    latest=$(get_latest_stable_version "$image")
    printf "%-30s\t%-20s\t%-20s\n" "$image" "$current" "$latest"
done
