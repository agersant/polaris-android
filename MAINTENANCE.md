How to deploy a branch to beta:
- Write the user-facing changelog in `fastlane/metadata/android/en-US/changelogs/CURRENT_VERSION.txt`
- Commit and push changes
- On Github, go to **Actions**, select the **Release To Beta** workflow and click **Run workflow**
- Select the branch to deploy
- Input a user-facing version name
- Click the **Run workflow** button
- The **Release To Beta** job in CI will deploy on Google Play, update changelog files, update versionCode and versionName, and move the **google-play-beta** tag
- When ready to push to production, run **promote_release.ps1**