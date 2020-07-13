How to make a release:
	- Make sure you are on the `master` branch
	- Run `git pull` to avoid missing recent contributions
	- Update the user-facing version number in `app/build.gradle` (the field is called versionName)
	- Write changelog in `fastlane/metadata/android/en-US/changelogs/CURRENT_VERSION.txt`
	- Commit and push changes
	- Run `make_release.ps1`
	- After the 'Release Beta' CI job completes, the new version is pushed to beta users
	- When ready to push to production, run `promote_release.ps1`