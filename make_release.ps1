git tag -d release-candidate
git push --delete origin release-candidate
git tag release-candidate
git push --tags