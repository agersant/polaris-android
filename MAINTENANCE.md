# Maintenance Guide

## Updating Flutter versions
- Update in `pubspec.yml`
- For local development: `nix flake update`
- For F-Droid builds: `cd .flutter`, `git checkout <hash>`
- For CI: update in files within `.github`

## Testing within Nix dev shell
- Run `run-test-emulator` to launch the emulator
- Use debug panel from VS code to launch app (Flutter VSCode extension possibly required)

## Deploying a branch to Beta
- Write the user-facing changelog in `fastlane/metadata/android/en-US/changelogs/CURRENT_VERSION.txt`
- Commit and push changes to the branch you want to deploy (usually **master**)
- On Github, go to **Actions**, select the **Release To Beta** workflow and click **Run workflow**
- Select the branch to deploy
- Input a user-facing version name (eg: **0.8.0**)
- Click the **Run workflow** button
- The **Release To Beta** job will deploy to Google Play, update changelog files, update versionCode and versionName in `build.gradle`, and move the **google-play-beta** tag

## Promoting Beta to Production
- On Github, go to **Actions**, select the **Promote Beta To Production** workflow and click **Run workflow**
- Click the **Run workflow** button
- The **Promote Beta To Production** job will deploy to Google Play, move the **google-play-production** tag and add a tag with the release name
