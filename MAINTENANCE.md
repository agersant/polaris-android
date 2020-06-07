How to make a release:
	- Update the user-facing version number in  `app/build.gradle` (the field is called versionName)
	- Write changelog in `fastlane/metadata/android/en-US/changelogs/CURRENT_VERSION.txt`
	- Run `make_release.ps1`
	- After the 'Release Beta' CI job completes, the new version is pushed to beta users
