#!/bin/bash
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
version="$1"
major=0
minor=0
build=0

# break down the version number into it's components
regex="([0-9]+).([0-9]+).([0-9]+)"
if [[ $version =~ $regex ]]; then
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  build="${BASH_REMATCH[3]}"
fi

# check paramater to see which number to increment
if [[ "$2" == "feature" ]]; then
  minor=$(echo $minor + 1 | bc)
elif [[ "$2" == "bug" ]]; then
  build=$(echo $build + 1 | bc)
elif [[ "$2" == "major" ]]; then
  major=$(echo $major+1 | bc)
elif [ -z $2 ]; then
  minor=$(echo $minor + 1 | bc)
else
  echo -e "${YELLOW}USAGE: Makefolder/version/version.sh version_number [major/feature/bug] or empty will be incremet feature" >&2;
fi

# echo the new version number
echo "${major}.${minor}.${build}" >&1