#!/bin/bash

# Find the most recently created firmware directory
selected_dir=$(find ~/Downloads -maxdepth 1 -type d -name "*firmware-no-clique*" -exec stat -f "%m %N" {} \; | sort -nr | head -1 | cut -d' ' -f2-)

# Check if we found a directory
if [ -z "$selected_dir" ]; then
    osascript -e 'display dialog "No firmware-no-clique directory found" buttons {"OK"} default button "OK"'
    exit 1
fi

echo "Selected directory: $selected_dir"

# Function to wait for drive to appear
wait_for_drive() {
    local side="$1"
    osascript -e "display dialog \"Put the ${side} half of the keyboard into bootloader mode and connect it via USB\" buttons {\"OK\"} default button \"OK\"" >/dev/null
    echo "Waiting for ADV360PRO drive to appear..."
    while [ ! -d "/Volumes/ADV360PRO" ]; do
        sleep 1
    done
    echo "ADV360PRO drive detected"
}

# Function to wait for drive to disappear
wait_for_drive_removal() {
    echo "Waiting for ADV360PRO drive to be removed..."
    while [ -d "/Volumes/ADV360PRO" ]; do
        sleep 1
    done
    echo "ADV360PRO drive removed"
}

# Function to copy file with confirmation
copy_with_confirmation() {
    local file_pattern="$1"
    local side="$2"
    
    # Find the file
    local file_to_copy=$(find "$selected_dir" -name "*${file_pattern}.uf2" -type f | head -1)
    
    if [ -z "$file_to_copy" ]; then
        echo "No file containing '${file_pattern}' found in $selected_dir"
        return 1
    fi
    
    # Get just the filename for display
    local filename=$(basename "$file_to_copy")
    
    # Perform the copy
    echo "Copying $filename to ADV360PRO drive..."
    cp "$file_to_copy" "/Volumes/ADV360PRO/" >/dev/null 2>&1
    
    echo "Copy completed"
}

# Main firmware flashing process
echo "Starting firmware flashing process..."

# Wait for drive and copy left firmware
wait_for_drive "left"
if ! copy_with_confirmation "left" "Left"; then
    echo "Left firmware copy failed or was cancelled. Exiting."
    exit 1
fi

# Wait for drive to be removed and reappear
wait_for_drive_removal
wait_for_drive "right"
if ! copy_with_confirmation "right" "Right"; then
    echo "Right firmware copy failed or was cancelled. Exiting."
    exit 1
fi

echo "Firmware flashing process completed!"
osascript -e 'display dialog "Firmware flashing process completed!\n\nBoth left and right firmware files have been copied." buttons {"OK"} default button "OK"' >/dev/null
