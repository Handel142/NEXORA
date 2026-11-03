# Start THE MIND TRAP V3 on Windows

## 1. Extract the ZIP

Right-click `NEXORA_THE_MIND_TRAP_V3.zip` and choose **Extract All**. Open the extracted `NEXORA_APP` folder.

## 2. Run the solo game locally

The solo games and soundtrack can run locally. For the best experience, use a local web server rather than opening `index.html` directly.

1. Open the `NEXORA_APP` folder in File Explorer.
2. Click the address bar, type `powershell`, and press Enter.
3. Run:

```powershell
py -m http.server 8000
```

4. Open your browser at `http://localhost:8000`.

If Windows says `py` is not recognised, install Python 3 from https://www.python.org/downloads/windows/ and enable **Add Python to PATH**, or use Visual Studio Code with the Live Server extension.

## 3. Enable online rooms and voice

Online multiplayer is not activated until you connect your own Supabase project. The ZIP deliberately contains no private project credentials.

- For a new Supabase project, enable Anonymous sign-ins and run the complete `backend/schema.sql` in the Supabase SQL Editor.
- If you already deployed V2, run `backend/upgrade_v3.sql` after the V2 schema.
- Put your Supabase project URL and public anon/publishable key in `backend/config.js`. Never put a service-role key in this file.
- Host the site over HTTPS for other devices. Microphone access requires HTTPS or localhost and each player must grant permission.
- Optional TURN relay credentials can be configured in `backend/config.js` under `turnServers`. TURN is needed on some restrictive mobile/carrier networks for reliable voice.

## 4. What is included

- Six original game cards and original Level 1 questions retained.
- Level 2 and Level 3 added to all six experiences, five questions per level. Clear 3/5 to unlock the next solo level.
- Four MP3 soundtrack tracks, play/pause, next/previous and volume controls.
- Persistent room membership and same-code next matches after the V3 SQL is applied.
- Optional audio-only room voice chat with mic mute.
- Founder credit: **Mysterious Big Boss**.

## 5. Local checks

From the `NEXORA_APP` folder run:

```powershell
python tests/smoke_test.py
node tests/level_content_test.js
node --check src/app.js
node --check src/multiplayer.js
```

These checks validate project structure, question counts/answer indexes, JavaScript syntax and bundled audio assets. They do not replace a real two-device multiplayer and voice test against your Supabase deployment.
