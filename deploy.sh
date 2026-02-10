#!/bin/bash
# A copy from https://github.com/fzerorubigd/fzerorubigd.github.io/blob/56795503ca691a3807174314539e3b4677496048/deploy.sh
set -euo pipefail
IFS=$'\n\t'

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

cd blog-src

# Build the project.
hugo

# Add changes to git.
cd ..
git add -A

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# Push source and build repos.
git push origin master
