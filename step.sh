#!/bin/bash
set -e

cd $(mktemp -d)
git init
git remote add origin "$remote_url"
git pull origin master
mkdir -p docs
rm -rf "docs/$BITRISE_APP_TITLE"

set +e
spoon_dir_name=$(find "$BITRISE_SOURCE_DIR" -path \*/spoon/\*index.html | xargs dirname)
if [ -z "$spoon_dir_name" ]; then
      echo -n "unknown" | envman add --key ALL_TEST_COUNT
      echo -n 0 | envman add --key PASSED_TEST_COUNT
      echo -n "irrelevant" | envman add --key STF_DEVICE_COUNT
      exit 1
fi
set -e

jq -n "$STF_DEVICE_SERIAL_LIST | length" | envman add --key STF_DEVICE_COUNT

spoon_results=$(cat "$spoon_dir_name/result.json" | jq -rM '.results|to_entries|.[].value.testResults[][1].status')

mv $spoon_dir_name "docs/$BITRISE_APP_TITLE"
git add -A
git commit -am "$BITRISE_APP_TITLE $BITRISE_BUILD_NUMBER"
git push origin master

echo $spoon_results | tr ' ' '\n' | wc -l | tr -d '\n' | envman add --key ALL_TEST_COUNT
echo $spoon_results | tr ' ' '\n' | grep -c PASS | tr -d '\n' | envman add --key PASSED_TEST_COUNT
