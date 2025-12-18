#!/bin/bash

# Move to the terraform directory
echo "Initiating Platform Teardown..."
cd ../terraform

# Execute the destruction
# Using -auto-approve skips the 'yes' prompt for a faster exit
terraform destroy -auto-approve

# Final confirmation
if [ $? -eq 0 ]; then
    echo "------------------------------------------------------------"
    echo "SUCCESS: All AWS resources have been decommissioned."
    echo "----------------:--------------------------------------------"
else
    echo "ERROR: Destruction failed."
    exit 1
fi
