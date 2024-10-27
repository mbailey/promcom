#!/bin/bash

# Function to get images from docker-compose file
get_images() {
    local compose_file=$1
    yq -r '.services[].image' "$compose_file" | sort -u
}

# Function to get version from image string
get_compose_version() {
    local image=$1
    local compose_file=$2
    local version
    version=$(yq -r ".services[] | select(.image == \"$image\") | .image" "$compose_file" | grep -o ':[^"]*' || echo ":latest")
    version=${version#:}
    if [[ "$version" == "$image" ]]; then
        echo "latest"
    else
        echo "$version"
    fi
}

# Function to get latest stable version from Docker Hub API
get_latest_stable_version() {
    local image=$1
    local repo=${image#docker.io/}
    # Get all tags and find the first one that looks like a version number
    curl -s "https://registry.hub.docker.com/v2/repositories/${repo}/tags?page_size=100" | \
        jq -r '.results[].name' | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1
}

# Function to process compose file
process_compose_file() {
    local compose_file=$1
    
    # Print header
    printf "%-30s\t%-20s\t%-20s\n" "Image" "Current Version" "Latest Stable Version"
    printf "%s\n" "--------------------------------------------------------------------------------"
    
    # Get and process each image
    while IFS= read -r image; do
        current=$(get_compose_version "$image" "$compose_file")
        latest=$(get_latest_stable_version "$image")
        printf "%-30s\t%-20s\t%-20s\n" "$image" "$current" "$latest"
    done < <(get_images "$compose_file")
}

# Main logic
if [ -p /dev/stdin ]; then
    # Reading from stdin
    TMP_FILE=$(mktemp)
    cat > "$TMP_FILE"
    process_compose_file "$TMP_FILE"
    rm "$TMP_FILE"
elif [ $# -eq 1 ]; then
    # Use provided compose file
    if [ -f "$1" ]; then
        process_compose_file "$1"
    else
        echo "Error: File $1 not found"
        exit 1
    fi
else
    # Default to docker-compose.yml in current directory
    if [ -f "docker-compose.yml" ]; then
        process_compose_file "docker-compose.yml"
    else
        echo "Error: No docker-compose.yml found in current directory"
        exit 1
    fi
fi
