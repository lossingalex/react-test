#!/bin/bash

set -e # Exit with nonzero exit code if anything fails
echo "=================================================="
echo "=============     STARTING DEPLOY    ============="
echo "=================================================="

# s3 sync of build folder, with delete of inexisting file
# Travis Environment variable are expecting to be set for aws to run :
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_DEFAULT_REGION

aws s3 sync build s3://gfg.pricing-engine.uat --delete
