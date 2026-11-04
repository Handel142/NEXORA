# Start NEXORA V4 on Windows

## 1. Extract and run

1. Right-click the ZIP and choose **Extract All**.
2. Open `NEXORA_THE_MIND_TRAP`.
3. Double-click `RUN_LOCAL_WINDOWS.bat`.
4. Your browser opens `http://localhost:8000`.

If Python is not installed, install Python 3 for Windows and enable **Add Python to PATH**. Alternatively open PowerShell in the project folder and run `py -m http.server 8000`.

## 2. What to test locally

- Home has only **Play Game** and **Play With Friends** as its two main actions.
- Use the top navigation to open Games, Play with Friends and Profile.
- Open each game and inspect its five level cards.
- Clear 3/5 to unlock the next level; replay a level and confirm your best score remains.
- Upload a profile photo/logo or use the generated first-letter avatar.
- Finish a level and try the certificate buttons. The image files download; the print dialog can save a PDF.
- Tap somewhere in the app to start the soft soundtrack; use the player to pause, change track and volume.

Online multiplayer will remain in offline-preview mode until you configure Supabase.

## 3. Connect the existing Supabase project

For the current V3 deployment:

1. Back up the database.
2. Run `backend/upgrade_v4.sql` in Supabase SQL Editor.
3. Add the Supabase project URL and public anon/publishable key to `backend/config.js`.
4. Never use a service-role key in `config.js`.
5. Redeploy the complete folder to Netlify over HTTPS.

For a brand-new Supabase project, run `backend/schema.sql`, then `backend/upgrade_v3.sql`, then `backend/upgrade_v4.sql`.

## 4. Install it like an app

- Android Chrome: use **Install App** or browser menu → Install app / Add to Home Screen.
- iPhone Safari: Share → Add to Home Screen.
- Desktop Chrome/Edge: use the install icon or **Install App**.

NEXORA V4 is a Progressive Web App. It is not yet a native APK or Play Store release.

## 5. Large-room voice note

Room sizes are 8, 20, 30 and 50 active players. Up to 20 spectators may watch an in-progress level. Voice is limited to eight simultaneous speakers with the current peer-to-peer architecture; an SFU service is needed for larger voice groups.

## 6. Run checks

```powershell
python tests/smoke_test.py
node tests/level_content_test.js
node --check src/app.js
node --check src/multiplayer.js
python tests/github_package_test.py
python tests/v4_migration_test.py
```

Local checks do not replace testing a deployed room with multiple real devices and microphones.
