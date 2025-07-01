#!/bin/bash

set -e
set -u

STEP_UPLOAD_APP=true

security unlock-keychain

mkdir -p build/


echo "Installing dependencies..."

pod install

TARGET="Release"

echo "Target is $TARGET"

xcodebuild archive \
  -verbose \
  -jobs 2 \
  -workspace Generika.xcworkspace \
    CONFIGURATION_BUILD_DIR="$(PWD)/build" \
    -scheme Generika \
    -allowProvisioningUpdates \
    -configuration $TARGET \
    -derivedDataPath "$PWD/DerivedData" \
    -archivePath "$PWD/build/Generika.xcarchive" \
    || exit 1


#named config variables - pass values in directly for override
# xcodebuild archive \
#   -verbose \
#   -jobs 2 \
#   -project Generika.xcodeproj \
#     -scheme Generika \
#     -configuration $TARGET \
#     -derivedDataPath "$PWD/DerivedData" \
#     -archivePath ./build/Generika.xcarchive \
#     || exit 1
     PRODUCT_BUNDLE_IDENTIFIER=org.oddb.generika \
     PROVISIONING_PROFILE_SPECIFIER="Zeno Davatz" \
#     || exit 1

echo "Building IPA..."

#clean the build directory for .ipa
rm -rf ./build/*.ipa


#choose export options
if [ $TARGET = "Release" ]; then
  options="store.plist"
else
  options="adhoc.plist"
fi

#now create the .IPA using export options specified in property list files
xcodebuild -exportArchive \
 -verbose \
 -allowProvisioningUpdates \
 -archivePath ./build/Generika.xcarchive \
 -exportPath ./build \
 -exportOptionsPlist ./scripts/"$options" \

if [ $STEP_UPLOAD_APP ] ; then
  ipa="$(pwd)/build/generika.ipa"

  echo "Validating app..."
  # Submit the app for notarization
echo "Submitting app for notarization..."
  time xcrun notarytool submit "$ipa" --apple-id "$ITC_USER" --password "$ITC_PASSWORD" --team-id "$TEAM_ID"
fi
