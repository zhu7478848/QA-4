#!/bin/bash

# Show expanded commands while running
set -x

# Stop the script if any command fails
set -o errtrace
trap 'exit' ERR

ProjectName=${TRAVIS_REPO_SLUG##*/};

cd $TRAVIS_BUILD_DIR
cargo doc

echo "<meta http-equiv=refresh content=0;url=${ProjectName}/index.html>" > target/doc/index.html
pip install --user ghp-import
CommitMessage=$(git log -1 | tr '[:upper:]' '[:lower:]' | grep "version change to " | tr -d ' ')
git clone https://github.com/${TRAVIS_REPO_SLUG}.git --branch gh-pages --single-branch docs-stage
cd docs-stage
rm -rf .git*
if [[ $CommitMessage == versionchangeto* ]]; then
  Version=${CommitMessage##*to}
  mkdir -p $Version
  mkdir -p latest
  cp -rf ../target/doc/* $Version
  cp -rf ../target/doc/* latest
  git config --global user.email dev@maidsafe.net
  git config --global user.name maidsafe-jenkins
  git tag $Version -a -m "Version $Version"
  git push -q https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG} --tags
fi
mkdir -p master
cp -rf ../target/doc/* master
cd ..
ghp-import -n docs-stage
git push -fq https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git gh-pages