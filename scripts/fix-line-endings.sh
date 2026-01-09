#!/bin/bash
# Fix line endings for shell scripts
# Run this if you get "bad interpreter: /bin/bash^M" errors

echo "Fixing line endings for shell scripts..."

# Convert all .sh files to Unix line endings
find . -name "*.sh" -type f -exec dos2unix {} \; 2>/dev/null || {
    # If dos2unix is not available, use sed
    find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;
}

echo "Done! Line endings fixed."
echo "You can now run the scripts normally."
