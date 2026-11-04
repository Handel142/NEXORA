# NEXORA V4.3 — Online, voice and install improvements

## What changed
- Netlify Git builds can read `SUPABASE_URL` and `SUPABASE_ANON_KEY` from environment variables. The public anon/publishable key is exposed to the browser by design; service-role/secret keys are rejected.
- Added a Netlify Function fallback for runtime configuration.
- Online players use Supabase anonymous sessions, so password accounts remain postponed and CREATE ROOM / JOIN ROOM no longer require an account modal.
- Connection status now reports the actual configuration/session state rather than the old permanent “ONLINE PLAY FOUNDATION · NOT CONNECTED” placeholder.
- Voice moderation refreshes peers after host/moderator mute actions; appointed moderators can mute individual players as permitted by the database RPC. Host-only mute-all remains host-only.
- Voice heartbeat refreshes presence more frequently while voice is active.
- Music now attempts playback on first page load and retries on the first user gesture if the browser blocks autoplay. Browsers do not permit websites to force autoplay with sound before user interaction.
- PWA metadata explicitly brands the installed app as NEXORA and references the NEXORA icon files. Added safe-area/bottom clearance for floating platform badges and notices.
- Service worker cache version bumped and runtime config/function responses are never cached.

## Required one-time deployment settings
1. Netlify Git deployment: add `SUPABASE_URL` and `SUPABASE_ANON_KEY` under Site configuration → Environment variables, then redeploy.
2. Enable Supabase Authentication → Sign In / Providers → Anonymous Sign-Ins.
3. Confirm the NEXORA `schema.sql` and `upgrade_v4.sql` migrations have been applied to the connected Supabase project.
4. Confirm Supabase Realtime is enabled for the project. Use HTTPS for microphone access.
5. For manual drag-and-drop static deployments, environment variables are not injected. Put the project URL and public anon/publishable key in `backend/config.js` instead.

## Local verification
The source archive includes static checks for runtime configuration, guest sessions, room controls, voice moderation, PWA metadata and safe-area layout. Run `python tests/v4_3_online_test.py` alongside the V4.2 smoke/migration/content/package tests.

## Important limits
- The actual Supabase project and its credentials are not included in this source archive, so live room creation, cross-device voice, and deployment-specific install behaviour cannot be certified from local static tests alone.
- Browser autoplay policy may require the first tap/key press before audible playback.
- Peer-to-peer voice supports up to eight simultaneous speakers; a TURN relay improves connectivity on restrictive networks.
- Do not put a Supabase service-role or secret key in any browser-accessible file or Netlify function response.
