# NEXORA V4.1 — Community Upgrade

## Added
- Player registration and sign-in using Supabase Auth email + password.
- Online multiplayer now requires a registered, authenticated account rather than silently creating anonymous sessions.
- Community screen with Founder’s Corner, latest message and message archive.
- Private founder dashboard protected by a database-backed founder allowlist.
- Daily and special founder messages with immediate publishing, future scheduling, editing, archiving and deletion.
- Image and video advertising campaigns with media upload, date windows, sponsor labels and founder approval before public display.
- Advertisement placements remain on the Community screen and outside active match screens.
- Dedicated storage buckets and row-level security policies for community content and media.
- Updated service-worker cache version and offline asset list.

## Existing features preserved
- Six original games and five-level progression.
- Existing multiplayer rooms, match flow, scoring protections, voice features, certificates and soundtrack.
- Original folder structure and project root retained for GitHub upload.

## Verification
- JavaScript syntax checks passed for app.js, multiplayer.js and community.js.
- Existing solo-game, V4 migration, package and content checks passed.
- New community-upgrade checks passed.
- ZIP archive integrity checked.
- Live Supabase registration, confirmation emails, SQL execution, scheduled publishing and media uploads still require configuration and testing in the owner's Supabase project.
