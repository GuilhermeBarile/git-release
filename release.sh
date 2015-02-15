#!/bin/bash

git=$(which git)

# locate repository
REPO=$($git rev-parse --show-toplevel 2> /dev/null)
x=$?

if [ $x -ne 0 ]; then
    echo "Error $x opening repo \"$REPO\""
    exit $x
fi

PACKAGE_JSON="$REPO/package.json"
if [ ! -f   ]; then
    echo "$PACKAGE_JSON not found";
    exit 1
fi

FILELIST="$REPO/.package/FILELIST.txt"
if [ ! -f "$FILELIST" ]; then
    echo "$FILELIST not found";
    exit 2
fi

VERSION=$(cat $PACKAGE_JSON | grep \"version\" | grep -oE '([0-9]+\.?)+')
if [ -z "$VERSION" ]; then
    echo "Invalid version $VERSION";
    exit 3
fi

if [ ! -z "$($git tag -l v$VERSION)" ]; then
    echo "Release v$VERSION already exists!";
    exit 4;
fi

BUILD_ROOT="$REPO/build"

[ -d "$BUILD_ROOT" ] && rm -rf "$BUILD_ROOT";

mkdir "$BUILD_ROOT";

# TODO
# rsync -av --files-from="$FILELIST"

echo "Releasing $(basename $REPO) v$VERSION";

TAG_MESSAGE="v$VERSION release"

CHANGELOG="$REPO/.package/CHANGELOG.md"
if [ -f "$CHANGELOG" ]; then
    TAG_MESSAGE=$(echo "$TAG_MESSAGE"; cat "$CHANGELOG" )
fi

cat /dev/null > "$CHANGELOG"

$git tag -a v$VERSION -m "$TAG_MESSAGE"

# increment version on package.json
perl -i -pe 's/(\"version\"[^"]+\"[0-9]+\.[0-9]+\.)([0-9]+)/$1.(1 + $2)/ge' $PACKAGE_JSON

# finally, commit the development new version
$git commit -m "new development version" "$CHANGELOG" "$PACKAGE_JSON"

# push to origin
$git push

# push tags
$git push --tags

# check for the last release,
#LAST_RELEASE=$($git describe --abbrev=0 --tags)
