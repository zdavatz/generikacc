#!/bin/bash

set -e
set -u

altool="$(dirname "$(xcode-select -p)")/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Support/altool"
ipa="/Users/zdavatz/Documents/xcode/generikacc/build/generika.ipa"

echo "Validating app..."
time "$altool" --validate-app --type ios --file "$ipa" --username "$ITC_USER" --password "$ITC_PASSWORD"
echo "Uploading app to iTC..."
time "$altool" --upload-app --type ios --file "$ipa" --username "$ITC_USER" --password "$ITC_PASSWORD"
