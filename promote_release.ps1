git fetch origin --tags --prune-tags

git tag -d production-release-candidate
git push --delete origin production-release-candidate

git checkout beta
git tag production-release-candidate
git push --tags
git checkout master
