# NEXORA V4.3 — Online + Voice + PWA

This release builds on V4.2 stable navigation. It retains all six games, five levels per game, the question bank, solo play, original music files, profile, achievements, multiplayer podium and certificates.

### Online setup
- Netlify Git deployments can inject the public Supabase URL and anon/publishable key through `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- Added a Netlify Function as a runtime configuration fallback.
- Guest/anonymous Supabase sessions replace the postponed password-account requirement for multiplayer rooms.
- The permanent “ONLINE PLAY FOUNDATION · NOT CONNECTED” placeholder has been removed; status is now dynamic.
- Create/join controls stay disabled during initial connection setup to avoid early clicks before the online client is ready.

### Voice
- Host and appointed moderators can mute individual participants.
- Host can mute/unmute all participants.
- Successful moderation sends a room refresh so remote clients apply mute state promptly.
- Voice heartbeat refreshes presence while voice is active.

### Music and installation
- Music attempts autoplay on initial page load and retries after the first user gesture if browser autoplay policy blocks it.
- Updated PWA manifest identity and NEXORA icon declarations.
- Added safe-area and bottom spacing for platform overlays, badges and notices.
- Service worker cache version bumped; runtime configuration and function responses are not cached.

### Required deployment configuration
For Netlify Git deployment, set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in Site configuration → Environment variables, then redeploy. Enable Anonymous Sign-Ins in Supabase Auth. Confirm the V4 migration is installed. Manual static drag-and-drop uploads must instead set the public URL/key in `backend/config.js` because build environment variables are not available to a static upload.
