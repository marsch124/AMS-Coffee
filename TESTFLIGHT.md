# Getting AMS Coffee onto the iPhone through TestFlight

Once this is set up, every new version reaches the phone by itself. No cable, no
Xcode, no seven-day expiry. Everything you have to do happens in a web browser.

You already did the hard parts for AMS PARA — the Developer Program membership
and the App Store Connect key. You do **not** need to make a new key. You only
need to give the same key to this repo, and tell Apple this app exists.

## 🚨 It must be the Admin key

You have two key files saved:

```
Apple Developer/AMS PARA/p8 file - App Manager/AuthKey_GSZY82U3ML.p8   ← does NOT work
Apple Developer/AMS PARA/p8 file - Admin/AuthKey_63M2792NNV.p8         ← use this one
```

**Use the Admin one.** An App Manager key can upload a build but cannot do the
cloud signing that `-exportArchive` performs, and fails with *"Cloud signing
permission error"* at the very last step. This already cost a round of
head-scratching on AMS PARA; the two folder names are the scar.

## What you do, once — about five minutes

### 1. Give this repo the same four secrets

<https://github.com/marsch124/AMS-Coffee/settings/secrets/actions> › **New repository secret**

GitHub keeps secrets per repository and never lets anything read them back, not
even itself, so they cannot be copied across from AMS-PARA. You paste the same
four values you used there:

| Name | Value |
| --- | --- |
| `ASC_KEY_ID` | `63M2792NNV` — the Admin key. Already set for you. |
| `ASC_ISSUER_ID` | the Issuer ID, a long code with dashes |
| `ASC_KEY_P8` | the whole contents of `p8 file - Admin/AuthKey_63M2792NNV.p8`, including the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines |
| `ASC_TEAM_ID` | `D24ENP83QQ` — already set for you. |

So there are really only **two** left to paste: the Issuer ID and the key itself.

The Issuer ID is at the top of <https://appstoreconnect.apple.com> ›
**Users and Access** › **Integrations** › **App Store Connect API**. The `.p8`
file is in `Apple Developer/AMS PARA/p8 file - Admin/` — open it in TextEdit and
copy everything.

### 2. Make the iCloud container — once

AMS Coffee keeps one file in iCloud Drive so the phone and the Mac read the
same shelf. That needs an **iCloud container** registered to your account, and
**this is the one thing no build and no API can do for you** — Apple only
allows it in the web portal.

<https://developer.apple.com/account/resources/identifiers/list/cloudContainer> ›
**+**

- Description: `AMS Coffee`
- Identifier: `iCloud.com.schabbauer.AMSCoffee`
- Continue › Register

Without this, the archive fails with *"Authentication failed: Make sure a
bearer token was provided"* — which sounds like a broken key and is nothing of
the sort. That message cost an afternoon.

### 3. Send the first build

<https://github.com/marsch124/AMS-Coffee/actions/workflows/testflight.yml> ›
**Run workflow**

It runs the whole test suite first and stops without uploading anything if a
test fails. Then it archives, and Apple registers the bundle identifier
`com.schabbauer.AMSCoffee` and its iCloud container on the way through.

The upload itself will fail the first time, with Apple saying there is no such
app. That is expected — see step 3.

### 4. Create the app record

<https://appstoreconnect.apple.com> › **Apps** › **+** › **New App**

- Platform: **iOS**
- Name: `AMS Coffee`
- Primary language: English
- Bundle ID: pick `com.schabbauer.AMSCoffee` from the list — it is already
  registered
- SKU: `ams-coffee`
- User access: Full Access

### 5. Run the workflow again

Same link as step 2. About ten minutes. When it is green, Apple processes the
build for a few more minutes and then emails you.

### 6. There must be a tester group, or nothing reaches you

**A successful upload does not put the app on your phone by itself.** The build
sits in App Store Connect until it is released to a group of testers, and until
then TestFlight stays silent and sends no email. A brand-new app has no groups,
so this bites once per app.

This is already set up for AMS Coffee: an internal group called **Martin**,
with you in it, receiving every build. Nothing to do.

For the next app, it is three API calls or two minutes in App Store Connect ›
TestFlight › Internal Testing › **+** › name the group › add yourself › tick
the build.

### 7. Open TestFlight on the phone

Sign in with the same Apple ID and AMS Coffee is waiting. Tap Install.

## If the archive says the certificate limit is reached

Every run signs in the cloud on a fresh machine, so Apple mints a new
development certificate each time, and an account can only hold so many. After
a lot of runs in one day the archive stops with:

> Choose a certificate to revoke. Your account has reached the maximum number
> of certificates.

It is harmless housekeeping. Revoke the ones called **"Created via API"** —
they are machine-made and nothing depends on them — at
<https://developer.apple.com/account/resources/certificates/list>. **Never
revoke the one with your own name on it**; that is the certificate your Mac
holds the private key for, and Xcode needs it.

One release a day never comes close to the limit. Today it took eleven runs to
get the first build out, which is what filled it.

## Which build is which

The workflow reads the version straight out of `Guide.appVersion`, the same
value the app's own **Version history** pill shows. So "1.1" in TestFlight and
"v1.1" in the app are always the same thing. The number after it is the run
number, because Apple refuses two uploads with the same build number.

## Afterwards

Every new version: run the workflow. That is all. A red test suite blocks the
upload, so nothing broken can reach the phone.
