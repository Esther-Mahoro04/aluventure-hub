# aluventure_hub

A mobile app that connects ALU students with internship opportunities at student-led startups and ventures — bridging the gap between students who want real-world experience and founders who need help building.

## Features
- **Opportunity Feed** — browse all posted roles with search
- **Opportunity Details** — see full info: role, description, location, time commitment, skills needed, and startup
- **Apply** — submit interest in a role with one tap
- **Notifications** — get notified when someone applies to your posting, or when your application is accepted/rejected
- **Startup Verification** — startups auto-verify with a valid ALU email, unlocking the ability to post
- **Applicant Review** — accept or reject applicants directly, with the student notified automatically
- **Persistent Data** — Firebase-backed, so everything survives app restarts

## App Walkthrough

### Students
1. Register with your name, email
2. Browse the feed — search by role or startup name
3. Tap any opportunity to see full details
4. Hit **Apply** to submit interest
5. Check **Notifications** for updates on your application status

### Startup Owners
1. Register and select **Startup**
2. Set up your venture profile (name + about) — auto-verified if you sign up with a valid ALU email
3. Tap **+** to post a new opportunity (role, description, location, time commitment, skills)
4. **Accept** or **Reject** applicants — they're notified automatically

## Getting Started

### Requirements
- Flutter SDK
- Dart SDK
- Android Studio or Xcode for a device/emulator
- Firebase project (Firestore + Auth enabled)

### Steps
```bash
# 1. Clone the repo
git clone <repo-url>
cd aluventure_hub

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

## Demo Accounts (pre-loaded, no setup needed)

Email: p.paul@alustudent.com
password: paul1234

>all accounts must use an `@alustudent.com` or `@alueducation.com`email to auto-verify and unlock posting.

Or create your own account from the Register screen.