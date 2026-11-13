# App Store draft

**Name:** Inly: Aligner Wear Timer
**Subtitle:** Track aligners in and out
**Category:** Health & Fitness (secondary: Lifestyle)
**Age rating:** 4+

## Promotional text
See at a glance how long your aligners have been out, right from the Dynamic Island.

## Description
Inly does one thing: it tracks how long your clear aligners are in and out of your mouth, and does it beautifully.

- Take them out and the Dynamic Island starts a live timer. Put them back in with one tap, without opening the app.
- A calm daily ring shows how much of your out-time budget is left (22 hours of wear by default, adjustable).
- Keep track of which tray you are on, when to switch, and how many days you stayed on each one.
- Home Screen and Lock Screen widgets, a Control Center toggle and Action Button support.
- Gentle reminders before your out-time runs out and on tray-change day.
- History with a 7-day chart and a 4-week calendar.
- Your data stays on your iPhone. No account, no ads, no tracking.

Inly is a tracking tool and not medical advice. Follow your orthodontist's instructions.

## Keywords
aligner,invisalign,tray,orthodontist,braces,retainer,teeth,timer,wear time,smile

## Privacy
Data not collected. Everything is stored on device. Privacy nutrition label: "Data Not Collected".
Needs: Live Activities (NSSupportsLiveActivities), notifications (optional).

## Screenshots to capture (6.9" and 6.5")
Today (in), Today (out) with Dynamic Island, Trays, Start tray, History, Lock Screen Live Activity.

## Before submitting (needs the owner)
- Marketing URL: https://inly-app.netlify.app/
- Support URL: https://inly-app.netlify.app/support
- Privacy Policy URL: https://inly-app.netlify.app/privacy
- Terms of Use (EULA link in description): https://inly-app.netlify.app/terms
- Final app icon artwork (current icon is a generated placeholder).
- Review notes: how to trigger the Live Activity (tap Take out).

## In-App Purchases (Inly+)

Create both in App Store Connect → Inly → Monetization → In-App Purchases. Type: **Non-Consumable** for both.

| Reference name | Product ID | Price | Notes |
| --- | --- | --- | --- |
| Inly+ Lifetime | `com.bzrmed.inly.plus` | $9.99 at launch, then $14.99 | Turn **Family Sharing on** (cannot be turned off later) |
| Inly+ 7-Day Free Trial | `com.bzrmed.inly.plus.trial` | Free ($0.00) | Apple allows a free non-consumable trial in apps without subscriptions. Name it with the length, e.g. "7-Day Trial" |

Localized display names and descriptions (App Store Connect limit: descriptions under 55 characters):

| Language | Lifetime name | Lifetime description | Trial name | Trial description |
| --- | --- | --- | --- | --- |
| English | Inly+ Lifetime | Apple Watch, widgets, sync, photos, reports. Pay once. | 7-Day Trial | Try every Inly+ feature free for 7 days. No charge. |
| French | Inly+ à vie | Apple Watch, widgets, synchro, rapports. Achat unique. | Essai de 7 jours | Toutes les fonctions Inly+ gratuites 7 jours. |
| Spanish | Inly+ de por vida | Apple Watch, widgets, sincronía, informes. Pago único. | Prueba de 7 días | Todas las funciones de Inly+ gratis 7 días. |
| Arabic | Inly+ مدى الحياة | Apple Watch والأدوات والمزامنة والتقارير. ادفع مرة. | تجربة 7 أيام | جرّب كل ميزات Inly+ مجانًا لمدة 7 أيام. |

Review screenshot: a screenshot of the Inly+ screen (Settings → Inly+ card).

Before the first purchase works (even in TestFlight sandbox): the **Paid Apps agreement** must be active (Business → Agreements), with banking and tax forms filled in. Join the **App Store Small Business Program** (15% commission).

Beta tester codes: App Store Connect → Inly → In-App Purchases → Inly+ Lifetime → Offer Codes → create one-time codes. Testers redeem them in Settings → Inly+ → Redeem code.

## Capabilities (developer portal, once)

- `com.bzrmed.inly`: App Groups (`group.com.bzrmed.inly`) and iCloud (key-value storage; CI turns iCloud on automatically).
- `com.bzrmed.inly.watchkitapp` and `com.bzrmed.inly.watchkitapp.widgets`: App Groups with `group.com.bzrmed.inly` ticked (needed by the watch complications). Create the widgets identifier if it does not exist yet.
