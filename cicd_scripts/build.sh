#!/bin/bash

set -e # Exit with nonzero exit code if anything fails
echo "=================================================="
echo "=============     STARTING BUILD     ============="
echo "=================================================="

#TODO read owner and repo from TRAVIS_REPO_SLUG
OWNER='lossingalex'
REPO='react-test'
SOURCE_BRANCH='develop'
TARGET_BUILD_BRANCH='uat'
BUILD_ID=${TRAVIS_BUILD_NUMBER}


#TODO check if can work withuot modifying existing global credentials
echo "== Setting GIT credentials and checking branches =="
git config credential.helper "store --file=.git/credentials"
echo "https://${GH_TOKEN}:@github.com" > .git/credentials
git config --global user.email "builds@travis-ci.com"
git config --global user.name "Travis CI"

echo "== Fetching and checking out $TARGET_BUILD_BRANCH branch =="
# Stash any modification due to .travis.yml script (chmod)
#ls
#git status
#git stash
#git remote set-branches --add origin $TARGET_BUILD_BRANCH
#git fetch
#git branch -avv
#git checkout -b $TARGET_BUILD_BRANCH origin/$TARGET_BUILD_BRANCH



echo "== Switching to temporary release branch release-$TAG-Travis-$BUILD_ID =="
TMP_RELEASE_BRANCH="release-$TAG-Travis-$BUILD_ID"
git checkout -b "$TMP_RELEASE_BRANCH"

#echo "== Checking out $SOURCE_BRANCH branch =="
#git checkout $SOURCE_BRANCH


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
github-changes -o $OWNER -r $REPO -a --only-pulls --token ${GH_TOKEN} --branch $SOURCE_BRANCH --verbose --use-commit-body

echo "== Updating $SOURCE_BRANCH branch with package.json and CHANGELOG.md =="
git add package.json
git add CHANGELOG.md
git commit -m "[skip ci] Bump version $TAG + Update Changelog"
#git push origin $SOURCE_BRANCH
#

#echo "== Apply change to package.json and CHANGELOG to $SOURCE_BRANCH using rebase =="
#git checkout $SOURCE_BRANCH
#git status
#git log -n 5
#git pull origin $SOURCE_BRANCH
#git rebase $TMP_RELEASE_BRANCH
#echo "== REBASE Done, try to push =="
#git status
#git log -n 5
#git push origin $SOURCE_BRANCH
## If success, comes back to release branch for creating final tag
#git checkout $TMP_RELEASE_BRANCH



echo "== Apply change to package.json and CHANGELOG to $SOURCE_BRANCH using rebase =="
git checkout $SOURCE_BRANCH
git pull origin $SOURCE_BRANCH
git merge $TMP_RELEASE_BRANCH -m "[skip CI] Merging package.json and CHANGELOG"
echo "== REBASE Done, try to push =="
git status
git log -n 5
git push origin $SOURCE_BRANCH
# If success, comes back to release branch for creating final tag
git checkout $TMP_RELEASE_BRANCH


#echo "== Switching to temporary release branch release-$TAG-Travis-$BUILD_ID =="
#TMP_RELEASE_BRANCH="release-$TAG-Travis-$BUILD_ID"
#git checkout -b "$TMP_RELEASE_BRANCH"

echo "== Generating npm-shrinkwrap =="
npm shrinkwrap

echo "== Commiting shrinkwrap =="
git add npm-shrinkwrap.json
#git add -f build
git commit -m "Add npm-shrinkwrap.json"

echo "== Creating new tag release $TAG =="
git tag -a $TAG -m "$TAG"
git push --tags
export BUILD_TAG=${TAG}

#echo "== Merging to target build branch $TARGET_BUILD_BRANCH =="
#git push --force origin $TMP_RELEASE_BRANCH:$TARGET_BUILD_BRANCH

