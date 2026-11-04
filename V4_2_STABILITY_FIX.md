# NEXORA V4.2 — Stability repair

- Fixed the navigation crash: `HTMLElement.dataset` is read-only; the previous router attempted to replace it before setting `data-page`, causing a TypeError on every tab click.
- Navigation now updates `document.body.dataset.page` directly and responds to browser hash changes.
- Temporarily postponed the account / Founder’s Corner / advertising client module as requested; no registration is required for local solo play.
- Preserved the six games, five-level progression, local player profile, badges, certificates, soundtrack, and existing multiplayer foundation.
- Bumped the service-worker cache name so browsers do not keep serving the broken JavaScript.

## Important
Solo play and local progress work without accounts. Online multiplayer still depends on a correctly configured Supabase project and its migrations; it is not represented as offline functionality.
