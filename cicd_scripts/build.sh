#!/bin/bash

set -e # Exit with nonzero exit code if anything fails
echo "== STARTING BUILD =="

#TODO read owner and repo from TRAVIS_REPO_SLUG
OWNER='lossingalex'
REPO='react-test'
SOURCE_BRANCH='develop'
TARGET_BUILD_BRANCH='uat'
BUILD_ID=${TRAVIS_BUILD_ID}

#TODO check if can work withuot modifying existing global credentials
echo "== Setting GIT credentials and checking branches =="
git config credential.helper "store --file=.git/credentials"
echo "https://${GH_TOKEN}:@github.com"
echo "https://${GH_TOKEN}:@github.com" > .git/credentials
git config --global user.email "builds@travis-ci.com"
git config --global user.name "Travis CI"

git fetch origin $SOURCE_BRANCH
git fetch origin $TARGET_BUILD_BRANCH
git checkout $SOURCE_BRANCH

# == Bumping Method 1. If package.json major and minor versions match last tag, then increment last tag. Else use package.json major.minor.0.
# -  Reference: http://phdesign.com.au/programming/auto-increment-project-version-from-travis/ 
# - Drawback: Rely on last existing tag. Need to make sure last tag exists and follow current regex format (vX.X.X).
# - Advantage: Allow to have X.X.0 as a first tag in case of major or minor increment
#TAG=$({ sed -nE 's/^[ \t]*"version": "([0-9]{1,}\.[0-9]{1,}\.)[0-9x]{1,}",$/\1/p' package.json; git describe --abbrev=0 | sed -E 's/^v([0-9]{1,}\.[0-9]{1,}\.)([0-9]{1,})$/\1 \2/g'; } | tr "\n" " " | awk '{printf($1==$2?"v"$2$3+1:"v"$1"0")}' | xargs -I {})
#echo $TAG
#npm --no-git-tag-version version from-git

# == Bumping Method 2. Always increment patch version in package.json, read the new package.json version as new tag
# - Drawback: Will always skip the tag X.X.0 and start with X.X.1
# - Advantage: Easier to maintain, no error possible due to regex. Rely solely on package.json current version
echo "== Bumping package.json =="
TAG=$(npm --no-git-tag-version version patch)
echo "New tag: $TAG"

echo "== Generating Changelog =="
github-changes -o $OWNER -r $REPO -a --token ${GH_TOKEN} --branch $SOURCE_BRANCH

echo "== Updating $SOURCE_BRANCH branch with package.json and CHANGELOG.md =="
git add package.json
git add CHANGELOG.md
git commit -m "[skip ci] Bump version $TAG + Update Changelog"
git push origin $SOURCE_BRANCH

echo "== Switching to temporary release branch release-$TAG-$BUILD_ID =="
TMP_RELEASE_BRANCH="release-$TAG-$BUILD_ID"
git checkout -b "$TMP_RELEASE_BRANCH"

echo "== Generating npm-shrinkwrap =="
npm shrinkwrap

echo "== Commiting shrinkwrap and build to temporary release branch =="
git add npm-shrinkwrap.json
git add build
git commit -m "Updating npm-shrinkwrap.json and release files"

echo "== Merging to target build branch $TARGET_BUILD_BRANCH =="
git checkout "$TARGET_BUILD_BRANCH"
git merge $TMP_RELEASE_BRANCH
git push origin $TARGET_BUILD_BRANCH

echo "== Creating new tag release $TAG =="
git tag -a $TAG -m "$TAG"
git push --tags
