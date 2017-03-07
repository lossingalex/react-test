#!/bin/bash

set -e # Exit with nonzero exit code if anything fails

#TODO use TARGET_BRANCH and injected variable
SOURCE_BRANCH='develop'
TARGET_BUILD_BRANCH='uat'
#TODO remove temporary test token


echo "== Setting GIT credentials and checking branches =="
git config credential.helper "store --file=.git/credentials"
echo "https://${GH_TOKEN}:@github.com"
echo "https://${GH_TOKEN}:@github.com" > .git/credentials
git config --global user.email "builds@travis-ci.com"
git config --global user.name "Travis CI"

git fetch origin $SOURCE_BRANCH
git fetch origin $TARGET_BUILD_BRANCH
git checkout $SOURCE_BRANCH

# == Method 1. If package.json major and minor versions match last tag, then increment last tag. Else use package.json major.minor.0.
# -  Reference: http://phdesign.com.au/programming/auto-increment-project-version-from-travis/ 
# - Drawback: Rely on last existing tag. Need to make sure last tag exists and follow current regex format (vX.X.X).
# - Advantage: Allow to have X.X.0 as a first tag in case of major or minor increment
#TAG=$({ sed -nE 's/^[ \t]*"version": "([0-9]{1,}\.[0-9]{1,}\.)[0-9x]{1,}",$/\1/p' package.json; git describe --abbrev=0 | sed -E 's/^v([0-9]{1,}\.[0-9]{1,}\.)([0-9]{1,})$/\1 \2/g'; } | tr "\n" " " | awk '{printf($1==$2?"v"$2$3+1:"v"$1"0")}' | xargs -I {})
#echo $TAG
#npm --no-git-tag-version version from-git

# == Method 2. Always increment patch version in package.json, read the new package.json version as new tag
# - Drawback: Will always skip the tag X.X.0 and start with X.X.1
# - Advantage: Easier to maintain, no error possible due to regex. Rely solely on package.json current version
TAG=$(npm --no-git-tag-version version patch)

echo "== Bumping package.json to $TAG =="
git add package.json
git commit -m "[skip ci] Bump version $TAG"
git push origin $SOURCE_BRANCH

echo "== Creating new tag release $TAG =="
git tag -a $TAG -m "$TAG"
git push --tags

echo "== switching to temporary release branch release-$TAG-$TRAVIS_BUILD_ID =="
RELEASE_BRANCH="release-$TAG-$TRAVIS_BUILD_ID"
git checkout -b "$RELEASE_BRANCH"

echo "== generating npm-shrinkwrap and Changelog=="
npm shrinkwrap


echo "== Merging to target build branch $TARGET_BUILD_BRANCH =="
git checkout "$TARGET_BUILD_BRANCH"
git merge $RELEASE_BRANCH
git push origin $TARGET_BUILD_BRANCH
