#!/bin/bash

set -e # Exit with nonzero exit code if anything fails
echo "=================================================="
echo "=============     STARTING CI/CD     ============="
echo "=================================================="

# Build a tag
bash ./cicd_scripts/build.sh
BUILD_TAG=${BUILD_TAG}
echo "New tag $BUILD_TAG..."

# deploy a tag
bash ./cicd_scripts/deploy.sh

