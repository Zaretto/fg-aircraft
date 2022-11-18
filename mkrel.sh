#!/bin/sh
FILE='ReleaseNotes.md'
branch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p' | sed 's/^release\///')
LATEST_TAG=$(git describe --abbrev=0)

> $FILE
echo '## RELEASE NOTES - ' ${TARGET_NAME} $BUILD_VER.$BUILD_NUM >> $FILE
echo '' >> $FILE
echo "#### Change summary for $branch:" >> $FILE
git log master..HEAD --no-merges --pretty=format:"+ %ad  F-14: %s" --date=short aircraft/f-14b | sed 's/F\-14\: F\-14/F\-14\:/' | sed 's/F\-14\: F14/F\-14\: /'  >> $FILE
git log master..HEAD --no-merges --pretty=format:"+ %ad  F-15: %s" --date=short aircraft/F-15  | sed 's/F\-15\: F\-15/F\-15\:/' | sed 's/F\-15\: F15/F\-15\: /'  >> $FILE

