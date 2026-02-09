# App Store Connect Setup — Sync.md

Go to https://appstoreconnect.apple.com and set up my iOS app. The app record for "Sync.md" (bundle ID `bontecou.Sync-md`) should already exist. Navigate to it and fill out everything needed to submit version 1.0 for review.

## App Information

- **Name:** Sync.md
- **Subtitle:** Git-synced markdown notes
- **Primary Category:** Developer Tools
- **Secondary Category:** Productivity
- **Content Rights:** This app does not contain, show, or access third-party content.

## Pricing

- **Price:** Free (USD $0.00)

## App Store Listing (Version 1.0 — en-US)

### Promotional Text
Sync your markdown notes with GitHub. Clone, pull, commit & push — real Git on your iPhone. Works with Obsidian, iA Writer, and the Files app.

### Description
Sync.md brings real Git to your iPhone. Clone any GitHub repository, pull the latest changes, edit your markdown files, then commit and push — all without a terminal.

**Real Git, Not a Workaround**
Sync.md uses libgit2 to perform actual Git operations on your device. Your repos have a real .git directory. Commit history, branches, diffs — it's all there. No proprietary sync layer, no lock-in.

**Works With Your Favorite Editor**
Cloned repositories appear directly in the iOS Files app. Open them in Obsidian, iA Writer, 1Writer, Taio, or any app that supports the Files provider. Edit however you like, then come back to Sync.md to commit and push.

**GitHub Native**
Sign in with GitHub OAuth or paste a Personal Access Token. Browse your repositories and clone with one tap. Author name, email, and branch are configured per-repo.

**Full Git Workflow**
• Clone any GitHub repository to your iPhone
• Pull to fetch the latest remote changes
• Stage all changes, write a commit message, and push
• See uncommitted change counts at a glance
• View branch, commit SHA, and last sync time per repo

**Obsidian Integration**
Sync.md supports x-callback-url so other apps can trigger Git operations programmatically. The Obsidian Git community plugin can call syncmd://x-callback-url/sync to pull and push without leaving Obsidian.

**Multiple Repositories**
Manage as many repos as you need. Each one gets its own branch, author, and storage location. Clone your blog, your Zettelkasten, your dotfiles — all in one app.

**Your Data Stays Yours**
No accounts to create, no cloud service to trust. Your files live on your device and sync directly with GitHub. Sync.md never sees your content.

### Keywords
git,markdown,github,sync,obsidian,notes,commit,push,pull,clone

### What's New (Version 1.0)
Initial release of Sync.md — real Git for your markdown notes on iOS.

• Clone GitHub repositories with one tap
• Pull, commit & push with full libgit2 support
• GitHub OAuth and Personal Access Token sign-in
• Multiple repository management
• Obsidian x-callback-url integration
• Files app integration — edit with any markdown editor

### Support URL
https://github.com/CodyBontecou/Sync.md/issues

### Marketing URL
https://github.com/CodyBontecou/Sync.md

## Screenshots

Upload the 6.5-inch iPhone screenshots from these local files (they are 1242×2688 already). Upload them in this order:

1. `output/appstore-slide-1.png` — Hero: "Sync{.md}" with home screen showing two cloned repos
2. `output/appstore-slide-2.png` — "Pull, Commit & Push" showing a cloned repo
3. `output/appstore-slide-3.png` — "GitHub Native" showing the sign-in screen
4. `output/appstore-slide-4.png` — "Fully Configured" showing repo settings
5. `output/appstore-slide-5.png` — "Access in Files" showing the Files app integration

**Note:** If App Store Connect asks for 5.5-inch (1242×2208) screenshots too, upload the same images — they share the 1242 width and ASC will accept them or you can skip 5.5" if it's not required.

## App Privacy (Privacy Nutrition Labels)

When you reach the App Privacy section, answer as follows:

**Do you or your third-party partners collect data from this app?** → Yes

Then configure these data types:

1. **Contact Info — Email Address**
   - Collected from the user's GitHub profile to use as the Git commit author
   - **Purpose:** App Functionality
   - **Linked to identity:** Yes
   - **Used for tracking:** No

2. **Contact Info — Name**
   - The user's GitHub display name, used as Git commit author
   - **Purpose:** App Functionality
   - **Linked to identity:** Yes
   - **Used for tracking:** No

3. **Identifiers — User ID**
   - GitHub username, used to identify the signed-in user
   - **Purpose:** App Functionality
   - **Linked to identity:** Yes
   - **Used for tracking:** No

**No other data types apply.** The app does not collect:
- No analytics or diagnostics
- No usage data or crash logs sent anywhere
- No advertising identifiers
- No location, contacts, photos, health, financial, browsing history, search history, or sensitive info
- The OAuth token is stored only in the device Keychain and sent only to api.github.com

## Age Rating Questionnaire

Answer every question **No / None / Infrequent or Mild** (whichever is the lowest option):

- Cartoon or Fantasy Violence → None
- Realistic Violence → None
- Prolonged Graphic or Sadistic Realistic Violence → None
- Profanity or Crude Humor → None
- Mature/Suggestive Themes → None
- Horror/Fear Themes → None
- Medical/Treatment Information → None
- Alcohol, Tobacco, or Drug Use or References → None
- Gambling or Contests → None (not real money gambling)
- Simulated Gambling → None
- Sexual Content and Nudity → None
- Graphic Sexual Content and Nudity → None
- **Unrestricted Web Access?** → No
- **Made for Kids?** → No
- **Age Rating:** This should result in 4+

## Export Compliance

- **Does your app use encryption?** → Yes
- **Does your app qualify for any of the exemptions provided in Category 5, Part 2 of the U.S. Export Administration Regulations?** → Yes
- **Does your app implement any encryption algorithms that are proprietary or not accepted as standards by international standard bodies?** → No
- **Does your app use encryption only for authentication and/or to access data already encrypted?** → Yes (the app uses HTTPS via URLSession/ATS to communicate with api.github.com — this is Apple's standard networking stack, no custom encryption)

If there's a simpler path: select that the app **only uses standard HTTPS / TLS** (exempt under EAR 5 Part 2). Apple often provides a single checkbox for this — check it.

## App Review Information

### Review Notes
Sync.md is a Git client for syncing markdown files with GitHub repositories. To test the app:

1. Launch the app and sign in using one of two methods:
   a. Tap "Sign in with GitHub" to use OAuth (requires a GitHub account)
   b. Tap "Use a Personal Access Token" and enter a GitHub PAT with `repo` scope

2. After sign-in, tap "Add Repository" and select a GitHub repository from the list.

3. Tap the repository card, then tap "Clone Repository" to download it.

4. Once cloned, you can:
   - Tap "Pull" to fetch remote changes
   - Tap "Commit & Push" to push local edits (make changes via Files app first)
   - Tap "Files Location" to view the cloned files in the iOS Files app

5. The app communicates only with api.github.com and our OAuth relay at oauth-server-beige.vercel.app.

No demo account is provided — a free GitHub account with at least one repository is needed. You can create a test repo at github.com/new.

### Contact Information
Fill in my contact info if App Store Connect has it on file, or leave the contact fields for me to fill in manually.

## Build

The build should already be uploaded via Xcode/`xcodebuild`. Select the latest available build (version 1.0, build 1) for this version. If no build is available yet, save everything and I'll upload it separately.

## Final Steps

After filling everything out:
1. Save all changes on each page
2. Do NOT click "Submit for Review" — I want to review everything first
3. Let me know what's left to do before I can submit
