# Inly 1.0: App Store submission sheet

Texts per language are in the folders `en-US/`, `fr-FR/`, `es-ES/`, `ar-SA/` (name, subtitle, keywords, promotional text, description, release notes, URLs). Marketing screenshots are in `screenshots/`.

## App information
- **Category:** Medical (secondary: Health & Fitness)
- **Copyright:** 2026 (your name as on the developer account)
- **Support URL:** https://inly-app.netlify.app/support
- **Marketing URL:** https://inly-app.netlify.app/
- **Privacy Policy URL:** https://inly-app.netlify.app/privacy
- **Terms of Use:** the standard Apple EULA covers this, and our own Terms are linked in the description and in the app.
- **Content rights:** "No, it does not contain, show, or access third-party content."
- **Price:** the app itself is **Free**. Inly+ is an in-app purchase (see docs/APPSTORE.md).

## App Privacy (nutrition label)
- Does this app collect data? → **"No, we do not collect data from this app."**
  - Why: nothing leaves the device except to the user's own iCloud (iCloud sync) and Apple's purchase system. Neither counts as collection by the developer.
- Result on the store: **"Data Not Collected"**.

## Age rating questionnaire
Answer **None / No** to everything except:
- **Medical or treatment information:** "Infrequent / Mild". The app tracks orthodontic wear time and shows a disclaimer.
- Unrestricted web access: **No**. Links open Safari; there is no browser in the app.
- Expected result: **4+**. (If Apple's newer form asks about health topics, answer that it is general wellness/treatment tracking with no diagnosis.)

## Export compliance
Already declared in the build: `ITSAppUsesNonExemptEncryption = NO`. Apple won't ask again.

## Notes for App Review (paste into "App Review Information → Notes")

> Inly is an aligner wear timer. It requires no account and no login: all data stays on the device (and the user's own iCloud if they turn on sync).
>
> How to test:
> 1. Open the app and go through the short setup (any tray numbers work).
> 2. On Today, tap "Take out": a Live Activity starts on the Lock Screen and in the Dynamic Island. Tap "Put back in" to stop it.
> 3. Inly+ (one-time, non-consumable purchase "com.bzrmed.inly.plus"): open Settings → Inly+ card, or tap any locked feature (History export, widgets, a third photo). The paywall offers a free 7-day trial (a free non-consumable "com.bzrmed.inly.plus.trial", no automatic charge) and the lifetime purchase. "Restore purchases" and "Redeem code" are on the paywall and in Settings → Inly+.
> 4. Apple Watch: the watch app and complications are part of Inly+ and get their data from the iPhone app.
>
> Inly is a tracking tool, not a medical device. It does not diagnose or give medical advice and shows a disclaimer in setup and in Settings → About.
>
> Contact: support@healus-ai.com

- **Sign-in required:** No.
- **Contact information:** your name, phone and email (only Apple sees these).

## Screenshots to upload
- **iPhone 6.9" display:** `screenshots/<language>/iphone-01…06.png` (1320 × 2868).
- **Apple Watch:** `screenshots/<language>/watch-01…02.png`.
- Order: 1 Dynamic Island, 2 Today, 3 Trays, 4 History, 5 Calendar, 6 Privacy and Inly+.

## In-app purchases
Create them before submitting, and attach both to version 1.0 ("In-App Purchases" section of the version page). See `docs/APPSTORE.md` for IDs, prices and localized texts. Each needs a review screenshot: use the paywall screenshot.
