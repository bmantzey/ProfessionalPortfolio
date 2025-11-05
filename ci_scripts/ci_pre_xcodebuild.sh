#!/bin/sh
set -eo pipefail
echo "Running CI pre-xcodebuild step"
# decode the base64 PLIST variable for Firebase
echo "$GOOGLE_SERVICE_INFO_B64" | base64 --decode > "$CI_PRIMARY_REPOSITORY_PATH/ProfessionalPortfolio/GoogleService-Info.plist"
