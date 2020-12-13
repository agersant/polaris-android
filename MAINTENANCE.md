How to make a release:
	- Write the user-facing changelog in `fastlane/metadata/android/en-US/changelogs/CURRENT_VERSION.txt`
	- Commit and push changes to master
	- On Github, go to `Actions`, select the `Release to Beta` workflow
	- Input a user facing version name (ignore the branch dropdown)
	- Click `Run workflow`
	- The 'Release Beta' job in CI will deploy on Google Play, update changelog files, update versionCode and versionName, and move the `google-play-beta` tag
	- When ready to push to production, run `promote_release.ps1`