#!/usr/bin/env python3

import sys
import os
import tempfile
import json
import re
import shutil
from typing import List, Optional
import requests
import yaml

def get_images(compose_file: str) -> List[str]:
    """Get unique image names from docker-compose file, stripped of docker.io prefixes."""
    with open(compose_file) as f:
        compose_data = yaml.safe_load(f)
    
    images = []
    for service in compose_data.get('services', {}).values():
        image = service.get('image', '')
        # Strip docker.io/ and docker.io/library/ prefixes
        image = re.sub(r'^docker\.io/(?:library/)?', '', image)
        if ':' in image:
            image = image.split(':')[0]
        images.append(image)
    
    return sorted(set(images))

def get_compose_version(image: str, compose_file: str) -> str:
    """Get version of image from docker-compose file."""
    with open(compose_file) as f:
        compose_data = yaml.safe_load(f)
    
    # Check different possible image formats
    possible_images = [
        image,
        f"docker.io/{image}",
        f"docker.io/library/{image}"
    ]
    
    for service in compose_data.get('services', {}).values():
        service_image = service.get('image', '')
        if any(service_image.startswith(img) for img in possible_images):
            if ':' in service_image:
                return service_image.split(':')[1]
    
    return "latest"

def get_latest_stable_version(image: str) -> Optional[str]:
    """Get latest stable version from Docker Hub API."""
    # Handle official images
    if '/' not in image:
        repo = f"library/{image}"
    else:
        repo = image
    
    url = f"https://registry.hub.docker.com/v2/repositories/{repo}/tags?page_size=100"
    try:
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        
        # Find first version tag matching standard format
        for tag in data.get('results', []):
            tag_name = tag['name']
            if re.match(r'^v?\d+\.\d+\.\d+$', tag_name):
                return tag_name
                
        return None
    except Exception as e:
        print(f"Error: Failed to get version for {image}: {str(e)}", file=sys.stderr)
        return None

def update_image_version(compose_file: str, image: str, new_version: str):
    """Update image version in compose file."""
    with open(compose_file) as f:
        compose_data = yaml.safe_load(f)

    # Find and update the matching service
    for service in compose_data.get('services', {}).values():
        service_image = service.get('image', '')
        # Strip version if present
        base_image = service_image.split(':')[0] if ':' in service_image else service_image
        
        # Check against possible formats
        if (base_image == image or 
            base_image == f"docker.io/{image}" or 
            base_image == f"docker.io/library/{image}"):
            service['image'] = f"docker.io/{image}:{new_version}"

    # Write back to file with proper formatting
    with open(compose_file, 'w') as f:
        yaml.dump(compose_data, f, default_flow_style=False, sort_keys=False)

def process_compose_file(compose_file: str):
    """Process docker-compose file and handle version updates."""
    print(f"{'Image':<30}\t{'Current Version':<20}\t{'Latest Stable Version':<20}")
    print("-" * 80)
    
    update_all = False
    update_none = False
    
    for image in get_images(compose_file):
        current = get_compose_version(image, compose_file)
        latest = get_latest_stable_version(image)
        
        if latest is None:
            print(f"Skipping {image} - couldn't fetch latest version")
            continue
            
        print(f"{image:<30}\t{current:<20}\t{latest:<20}")
        
        if update_all:
            update_image_version(compose_file, image, latest)
            print(f"Updated {image} to version {latest}")
            continue
            
        if update_none:
            continue
            
        while True:
            response = input(f"Update {image} to version {latest}? [Y/n/a/q] ").lower()
            
            if response == '' or response == 'y':
                update_image_version(compose_file, image, latest)
                print(f"Updated {image} to version {latest}")
                break
            elif response == 'n':
                print(f"Skipping {image}")
                break
            elif response == 'a':
                update_all = True
                update_image_version(compose_file, image, latest)
                print(f"Updated {image} to version {latest}")
                break
            elif response == 'q':
                print("Exiting...")
                sys.exit(0)
            else:
                print("Please answer: Y (default), n (no), a (all), q (quit)")

def main():
    """Main entry point."""
    if sys.stdin.isatty():
        # Not reading from stdin
        if len(sys.argv) > 1:
            compose_file = sys.argv[1]
            if not os.path.isfile(compose_file):
                print(f"Error: File {compose_file} not found")
                sys.exit(1)
        else:
            compose_file = "docker-compose.yml"
            if not os.path.isfile(compose_file):
                print("Error: No docker-compose.yml found in current directory")
                sys.exit(1)
        
        process_compose_file(compose_file)
    else:
        # Reading from stdin
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp:
            shutil.copyfileobj(sys.stdin, tmp)
        
        try:
            process_compose_file(tmp.name)
        finally:
            os.unlink(tmp.name)

if __name__ == "__main__":
    main()
