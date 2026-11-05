# Setup guide

## One-time setup (already done for this repo)
1. Apple Developer: App IDs `com.bzrmed.inly` and `com.bzrmed.inly.widgets`, App Group `group.com.bzrmed.inly`.
2. App Store Connect: app "Inly" created with bundle ID `com.bzrmed.inly`.
3. GitHub repo secrets (Settings -> Secrets and variables -> Actions):
   - `APPLE_TEAM_ID` - 10-character Team ID
   - `ASC_KEY_ID` - App Store Connect API key ID
   - `ASC_ISSUER_ID` - issuer ID
   - `ASC_KEY_P8` - full contents of the `.p8` file, including BEGIN/END lines

## Getting a build on your iPhone
1. GitHub -> **Actions** -> **TestFlight** -> **Run workflow** (branch `main`). Takes about 10-20 minutes.
2. App Store Connect -> **Apps** -> Inly -> **TestFlight**. The build appears after processing (a few more minutes).
3. First time only: **Internal Testing** -> **+** -> create a group, add yourself (your Apple ID must be a user on the team), enable the build for the group.
4. On your iPhone, install **TestFlight** from the App Store, sign in with the same Apple ID, open Inly and tap Install.
5. Later builds: run the workflow again; each run gets a new build number automatically.

## If the TestFlight workflow fails
- **"Missing repository secret"**: add the secret named in the error.
- **Provisioning or certificate errors** (for example "Cloud signing permission error" or "No signing certificate"): the API key role is too low to create a distribution certificate. In App Store Connect -> Users and Access -> Integrations, create a new key with the **Admin** role and replace `ASC_KEY_ID` and `ASC_KEY_P8`.
- **"App ID not found" or capability errors**: check that both App IDs exist and the App Group is enabled on each (Certificates, Identifiers and Profiles -> Identifiers).
- **Build uploaded but not visible**: wait for processing, and check your email for a rejection notice from App Store Connect.
- Logs from each run are attached to the run as an artifact (`testflight-logs`).
