from pathlib import Path
root=Path(__file__).resolve().parents[1]
mp=(root/'src/multiplayer.js').read_text()
html=(root/'index.html').read_text()
sw=(root/'service-worker.js').read_text()
manifest=(root/'manifest.webmanifest').read_text()
netlify=(root/'netlify.toml').read_text()
fn=(root/'netlify/functions/nexora-config.js').read_text()
build=(root/'scripts/build-config.js').read_text()
checks={
 'old permanent disconnected placeholder removed':'ONLINE PLAY FOUNDATION · NOT CONNECTED' not in html,
 'runtime Netlify config loaded before app logic':html.index('backend/runtime-config.js') < html.index('src/app.js'),
 'Netlify environment config endpoint wired':'/.netlify/functions/nexora-config' in mp,
 'Netlify function returns only public URL and anon/publishable key':'SUPABASE_URL' in fn and 'SUPABASE_ANON_KEY' in fn and 'service_role' in fn,
 'Netlify build generates browser runtime config':'npm run build' in netlify and 'backend/runtime-config.js' in build,
 'anonymous player sign-in implemented':'signInAnonymously' in mp,
 'password account modal not required for room creation':'nexora:request-account' not in mp,
 'create and join handlers wired':"$('createRoom').addEventListener('click',create)" in mp and "$('joinRoom').addEventListener('click',join)" in mp,
 'moderators can mute individual players':'snapshot?.players?.some(p=>p.user_id===user?.id&&p.is_moderator)' in mp,
 'host mute-all refreshes room peers':"event:'room-refresh'" in mp and 'nexora_set_all_muted' in mp,
 'voice heartbeats refresh presence':'nexora_voice_heartbeat' in mp and '12000' in mp,
 'NEXORA PWA identity and custom icon declared':'"short_name": "NEXORA"' in manifest and 'public/icon-512.png' in manifest,
 'safe bottom clearance exists':'safe-area-inset-bottom' in (root/'src/styles.css').read_text(),
 'runtime config never cached by service worker':"endsWith('/backend/runtime-config.js')" in sw,
}
for name,ok in checks.items(): print(('PASS' if ok else 'FAIL')+' '+name)
if not all(checks.values()): raise SystemExit(1)
