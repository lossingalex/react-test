#!/bin/bash

set -e # Exit with nonzero exit code if anything fails

#TODO use TARGET_BRANCH and injected variable


# Set GIT credentials
echo "== Setting GIT credentials =="
git config credential.helper "store --file=.git/credentials"
echo "https://${GH_TOKEN}:@github.com" > .git/credentials
git config --global user.email "builds@travis-ci.com"
git config --global user.name "Travis CI"

echo "== BUMP package.json version and create new tag release =="
git checkout develop

git status
git remote -v

# Create a git tag of the new version to use
"{ sed -nE 's/^[ \\t]*\"version\": \"([0-9]{1,}\\.[0-9]{1,}\\.)[0-9x]{1,}\",$/\\1/p' package.json; git describe --abbrev=0 | sed -E 's/^v([0-9]{1,}\\.[0-9]{1,}\\.)([0-9]{1,})$/\\1 \\2/g'; } | tr \"\\n\" \" \" | awk '{printf($1==$2?\"v\"$2$3+1:\"v\"$1\"0\")}' | xargs -I {} git tag -a {} -m \"[skip ci] {}\"\n"
# Update package.json based on the git tag we just created
npm --no-git-tag-version version from-git
git add package.json
# cat package.json
git commit -m "[skip ci] bump version"
git push origin develop
git push --tags

