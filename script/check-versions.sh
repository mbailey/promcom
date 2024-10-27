#!/bin/bash

# Function to get images from docker-compose file
get_images() {
    local compose_file=$1
    # Strip docker.io/ prefix if present and return unique image names
    yq -r '.services[].image' "$compose_file" | sed 's|^docker.io/||' | sort -u
}

# Function to get version from image string
get_compose_version() {
    local image=$1
    local compose_file=$2
    
    # Handle both with and without docker.io prefix
    local full_image=$(yq -r ".services[] | select(.image == \"docker.io/$image\" or .image == \"$image\") | .image" "$compose_file")
    
    # Extract version after colon, default to "latest"
    if [[ "$full_image" == *":"* ]]; then
        echo "${full_image#*:}"
    else
        echo "latest"
    fi
}

# Function to get latest stable version from Docker Hub API
get_latest_stable_version() {
    local image=$1
    local repo=${image#docker.io/}
    local api_response
    
    # Handle official images differently
    if [[ "$repo" != *"/"* ]]; then
        # Official images use library/ prefix
        api_response=$(curl -s "https://registry.hub.docker.com/v2/repositories/library/${repo}/tags?page_size=100")
    else
        api_response=$(curl -s "https://registry.hub.docker.com/v2/repositories/${repo}/tags?page_size=100")
    fi

    if [[ -n $DEBUG ]]; then 
        # Debug output - only show version tags
        echo "DEBUG: Version tags for $repo:" >&2
        echo "$api_response" | jq -r '.results[].name' 2>/dev/null | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' >&2
    fi
    
    # Check if we got a valid response
    if [ -z "$api_response" ] || [ "$api_response" = "null" ]; then
        echo "Error: No response from Docker Hub for $repo" >&2
        return 1
    fi
    
    # Process the response
    echo "$api_response" | \
        jq -r '.results[].name' 2>/dev/null | \
        grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | \
        head -n 1 || echo "No version found"
}

# Function to update image version in compose file
update_image_version() {
    local compose_file=$1
    local image=$2
    local new_version=$3
    
    # Create a temporary file
    local tmp_file=$(mktemp)
    
    # Update the image version
    sed "s|image: ${image}:*.*|image: ${image}:${new_version}|" "$compose_file" > "$tmp_file"
    mv "$tmp_file" "$compose_file"
}

# Function to process compose file
process_compose_file() {
    local compose_file=$1
    local update_all=false
    local update_none=false
    
    # Print header
    printf "%-30s\t%-20s\t%-20s\n" "Image" "Current Version" "Latest Stable Version"
    printf "%s\n" "--------------------------------------------------------------------------------"
    
    # Get and process each image
    while IFS= read -r image; do
        current=$(get_compose_version "$image" "$compose_file")
        latest=$(get_latest_stable_version "$image")
        printf "%-30s\t%-20s\t%-20s\n" "$image" "$current" "$latest"
        
        if [ "$update_all" = true ]; then
            update_image_version "$compose_file" "$image" "$latest"
            echo "Updated $image to version $latest"
            continue
        fi
        
        if [ "$update_none" = true ]; then
            continue
        fi
        
        while true; do
            read -p "Update $image to version $latest? (yes/no/all/none/quit) " response
            case $response in
                yes|YES|y|Y)
                    update_image_version "$compose_file" "$image" "$latest"
                    echo "Updated $image to version $latest"
                    break
                    ;;
                no|NO|n|N)
                    echo "Skipping $image"
                    break
                    ;;
                all|ALL|a|A)
                    update_all=true
                    update_image_version "$compose_file" "$image" "$latest"
                    echo "Updated $image to version $latest"
                    break
                    ;;
                none|NONE)
                    update_none=true
                    echo "Skipping remaining updates"
                    break
                    ;;
                quit|QUIT|q|Q)
                    echo "Exiting..."
                    exit 0
                    ;;
                *)
                    echo "Please answer yes, no, all, none or quit"
                    ;;
            esac
        done
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
