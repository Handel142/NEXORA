# NEXORA V4 — implementation notes

## Interface and app installation
- Replaced the long scrolling landing-page presentation with a compact two-action home screen and dedicated Home, Games, Play with Friends and Profile screens.
- Hid global navigation during active matches and results; match/lobby views use dedicated controls.
- Paginated 50-player rosters and voice moderation controls instead of extending the page vertically.
- Added PWA manifest, 192px/512px icons, service-worker cache version V4, install control and iOS Add to Home Screen guidance.

## Games and progression
- Added Level 4 — THE BREAKING POINT and Level 5 — THE FINAL MIND to all six games.
- Added five questions per new level (60 new questions), preserving all existing questions and Level 2/3 content.
- Improved Last Lock deduction clues in Levels 2–5 without changing the answer codes.
- Added persistent best-score/accuracy records, replay support and NEXORA GRAND MIND recognition for mastering all six games.

## Multiplayer and rewards
- Added room sizes 8, 20, 30 and 50; up to 20 spectators can watch an in-progress level.
- New arrivals during a match join as spectators. Hosts can admit them between levels.
- Added direct invitation links, copy/share actions, soft-leave/rejoin restoration with preserved scores and answers, connection heartbeats, inactive-player handling, host failover and same-room next-match game/level selection.
- Scores and answer rows are withheld by both room RPCs and RLS during an active level; the client subscribes only to safe room-state events; results appear after all five rounds with a first/second/third podium and remaining rankings.
- Added host-appointed moderators, individual mute, host mute-all, personal mic mute and an eight-speaker voice limit with stale-slot heartbeat cleanup.
- Added avatar photo/logo upload to Supabase Storage, first-letter fallback avatars, achievement badges and top-three/level certificates.
- Certificates export as PNG image; the print dialog can save a PDF.

## Sound
- Soft ambient music starts after the first user gesture (browser autoplay restrictions apply), with player controls, track navigation and voice ducking.

## Database
- `backend/upgrade_v4.sql` is the V4 migration for the existing V3 schema. Back up Supabase before applying it.
- The migration seeds 60 new multiplayer questions, expands room/level constraints, adds spectator/moderator/mute/voice/profile columns, avatar storage policies and updated room RPCs.

## Verification boundary
- JavaScript syntax, question-pack structure, local asset references, package structure, PWA metadata and migration content are covered by local tests.
- The live Supabase migration has not been run against the user's project from this environment. Cross-device realtime, actual microphone paths, reconnect under network loss and installation on physical devices still require deployment testing with the user's credentials and devices.
