#!/bin/bash

set -e

if [ ! -e ../yubiswitch/yubiswitch-Info.plist ]; then
  echo "Can't extrapolate bundle version."
  echo "Are you executing this from whiting the dmg/ dir?"
  exit 1
fi

VERSION=$(grep CFBundleShortVersionString ../yubiswitch/yubiswitch-Info.plist \
  -A1 | tail -1 | perl -lne 'print $1 if /<string>(.*)<\/string>/')

echo "Version: $VERSION"
SRC_BINARY=$(find ~/Library/Developer/Xcode/DerivedData/ \
  -name "yubiswitch.app" \
  | grep "Build/Products/Release/")
if [ -z "$SRC_BINARY" ]; then
  echo "Can find yubiswitch.app, make sure you have built a 'release' binary"
  exit 1
fi
OUTPUT=/tmp/yubiswitch_$VERSION.dmg

tmpdir=$(mktemp -d -t yubiswitch)
echo "Tempdir: $tmpdir"

if [ ! -e skeleton.dmg ]; then
  echo "Can't find skeleton.dmg."
  echo "Are you executing this from whiting the dmg/ dir?"
  exit 1
fi

cp skeleton.dmg $tmpdir/
hdiutil attach -readwrite $tmpdir/skeleton.dmg
echo "Copying $SRC_BINARY to /Volumes/yubiswitch/"
rm -rf /Volumes/yubiswitch/yubiswitch.app
rsync -av $SRC_BINARY/ /Volumes/yubiswitch/yubiswitch.app/
echo "Detach /Volumes/yubiswitch/"
hdiutil detach /Volumes/yubiswitch/
sync
sync

echo "Converting DMG to compressed/ro, and write to $OUTPUT"
rm -f $OUTPUT
hdiutil convert -format UDZO -o $OUTPUT $tmpdir/skeleton.dmg

if [ ! $OUTPUT ]; then
  echo "can't find $OUTPUT!"
  exit 1
fi

codesign -s "Developer ID Application: Angelo Failla (T8ZNNBVE9Z" $OUTPUT

echo "Removing tmpdir"
rm -rf $tmpdir
