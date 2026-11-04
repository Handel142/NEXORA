from pathlib import Path
root=Path(__file__).resolve().parents[1]
html=(root/'index.html').read_text()
js=(root/'src'/'community.js').read_text()
mp=(root/'src'/'multiplayer.js').read_text()
sql=(root/'backend'/'upgrade_community.sql').read_text()
sw=(root/'service-worker.js').read_text()
checks={
 'community screen and script are included':"section.id='community'" in js and 'src/community.js' in html,
 'player account registration and password sign-in':'auth.signUp({email,password' in js and 'auth.signInWithPassword({email,password})' in js,
 'account passwords are never stored in app tables':'Supabase Auth manages credentials' in sql and 'password text' not in sql.lower(),
 'online multiplayer requires a real account':'Please create a NEXORA account or sign in' in mp and 'signInAnonymously' not in mp,
 'private founder dashboard checks server-side founder role':'founder_admins' in js and 'nexora_is_founder' in sql,
 'daily and special messages support scheduling':'message_type' in sql and 'scheduled_at' in sql and "status='scheduled'" in sql,
 'message history and archive controls exist':'adminHistory' in js and 'founderArchive' in js,
 'image and video advertisement support':'nexora-ad-images' in sql and 'nexora-ad-videos' in sql and "option value=\"video\"" in js,
 'advertisements require founder approval':'status:\'pending\'' in js and "status='approved'" in sql,
 'media uploads are limited and MIME checked':'5242880' in sql and '52428800' in sql and 'image/webp' in sql and 'video/webm' in sql,
 'ad slots only exist on the community screen':'adSpotlight' in js and 'in-match' not in js,
 'service worker caches community client and updates cache version':'community.js' in sw and 'v4-1' in sw,
}
for name,ok in checks.items(): print(('PASS' if ok else 'FAIL')+' '+name)
if not all(checks.values()): raise SystemExit(1)
