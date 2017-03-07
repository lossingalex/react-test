#!/bin/bash

set -e # Exit with nonzero exit code if anything fails
echo "=================================================="
echo "=============     STARTING CI/CD     ============="
echo "=================================================="


# Build a tag
sh ./cicd_scripts/build.sh

# deploy a tag
sh ./cicd_scripts/deploy.sh

