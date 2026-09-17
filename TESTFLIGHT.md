# Getting AMS Coffee onto the iPhone through TestFlight

Once this is set up, every new version reaches the phone by itself. No cable, no
Xcode, no seven-day expiry. Everything you have to do happens in a web browser.

You already did the hard parts for AMS PARA — the Developer Program membership
and the App Store Connect key. You do **not** need to make a new key. You only
need to give the same key to this repo, and tell Apple this app exists.

## What you do, once — about five minutes

### 1. Give this repo the same four secrets

<https://github.com/marsch124/AMS-Coffee/settings/secrets/actions> › **New repository secret**

GitHub keeps secrets per repository and never lets anything read them back, not
even itself, so they cannot be copied across from AMS-PARA. You paste the same
four values you used there:

| Name | Value |
| --- | --- |
| `ASC_KEY_ID` | the Key ID, ten characters |
| `ASC_ISSUER_ID` | the Issuer ID, a long code with dashes |
| `ASC_KEY_P8` | the whole contents of your `AuthKey_XXXXXXXXXX.p8` file, including the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines |
| `ASC_TEAM_ID` | `D24ENP83QQ` |

The first three are on the same page you made them:
<https://appstoreconnect.apple.com> › **Users and Access** › **Integrations** ›
**App Store Connect API**. The Key ID and Issuer ID are shown there. The `.p8`
file itself is the one Apple let you download only once — wherever you saved it.

### 2. Send the first build

<https://github.com/marsch124/AMS-Coffee/actions/workflows/testflight.yml> ›
**Run workflow**

It runs the whole test suite first and stops without uploading anything if a
test fails. Then it archives, and Apple registers the bundle identifier
`com.schabbauer.AMSCoffee` and its iCloud container on the way through.

The upload itself will fail the first time, with Apple saying there is no such
app. That is expected — see step 3.

### 3. Create the app record

<https://appstoreconnect.apple.com> › **Apps** › **+** › **New App**

- Platform: **iOS**
- Name: `AMS Coffee`
- Primary language: English
- Bundle ID: pick `com.schabbauer.AMSCoffee` from the list — step 2 put it there
- SKU: `ams-coffee`
- User access: Full Access

### 4. Run the workflow again

Same link as step 2. About ten minutes. When it is green, Apple processes the
build for a few more minutes and then emails you.

### 5. Open TestFlight on the phone

Sign in with the same Apple ID and AMS Coffee is waiting. Tap Install.

## Which build is which

The workflow reads the version straight out of `Guide.appVersion`, the same
value the app's own **Version history** pill shows. So "1.1" in TestFlight and
"v1.1" in the app are always the same thing. The number after it is the run
number, because Apple refuses two uploads with the same build number.

## Afterwards

Every new version: run the workflow. That is all. A red test suite blocks the
upload, so nothing broken can reach the phone.
