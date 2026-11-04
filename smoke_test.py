from pathlib import Path
root=Path(__file__).resolve().parents[1]
html=(root/'index.html').read_text()
js=(root/'src/app.js').read_text()
mp=(root/'src/multiplayer.js').read_text()
css=(root/'src/styles.css').read_text()
sql=(root/'backend/schema.sql').read_text()
tracks=['01-the-threshold.mp3','02-evidence-in-rain.mp3','03-the-last-lock.mp3','04-after-the-choice.mp3']
checks={
 'main HTML exists':(root/'index.html').exists(),
 'six distinct solo game cards':html.count('data-launch=')==6,
 'six independent solo game definitions':all(f'{k}:{{title:' in js for k in ['logic','case','cipher','impostor','survival']),
 'daily solo challenge generator':'function dailyRounds()' in js,
 'solo answer submission and scoring':'function submit()' in js and 'active.score+=100' in js,
 'local solo progress persistence':'localStorage.setItem(storageKey' in js,
 'four compressed original audio tracks included':all((root/'assets/audio/music'/t).is_file() and (root/'assets/audio/music'/t).stat().st_size>100000 for t in tracks),
 'music dock controls wired':all(x in js for x in ['musicPlay','musicPrev','musicNext','musicVolume']),
 'music starts only after user action':'async function playMusic()' in js and "music.play()" in js,
 'soundtrack audio elements exist':'id="musicAudio"' in html and 'id="musicDock"' in html,
 'multiplayer selects all six games':all(f'value="{k}"' in html for k in ['logic','case','cipher','impostor','survival','daily']),
 'multiplayer room creation and join wired':all(x in mp for x in ['nexora_create_room','nexora_join_room','nexora_set_ready']),
 'multiplayer match flow wired':all(x in mp for x in ['nexora_start_room','nexora_get_round','nexora_submit_answer','nexora_advance_round']),
 'SQL has five rounds per game':all(sql.count(f"('{k}',{i},")>=1 for k in ['logic','case','cipher','impostor','survival','daily'] for i in range(1,6)),
 'server-side answer keys and score validation':'answer_key text not null' in sql and 'nexora_submit_answer' in sql,
 'RLS and restricted RPC grants':'enable row level security' in sql and 'revoke all on function public.nexora_submit_answer' in sql,
 'PWA cache includes soundtrack':'assets/audio/music/01-the-threshold.mp3' in (root/'service-worker.js').read_text() and 'nexora-mindtrap-v4' in (root/'service-worker.js').read_text(),
 'responsive mobile styling':'@media(max-width:600px)' in css and '@media(max-width:650px)' in css,
 'five difficulty tiers in solo progression':all(x in js for x in ['advancedLevels','masterLevels','[1,2,3,4,5]','function openLevelPicker']),
 'solo progression unlock threshold':'Math.ceil(total*.6)' in js and 'state.levels[active.id]' in js and 'active.level<5' in js,
 'all six games have advanced and master level packs':all(f'{k}:' in js for k in ['logic','case','cipher','impostor','survival','daily']) and 'const masterLevels=' in js,
 'founder credit shown':'Mysterious Big Boss' in html and 'MYSTERIOUS BIG BOSS' in js,
 'compact screen navigation':'data-page=\"home\"' in html and 'body[data-page=\"games\"]' in css,
 'shareable invitation link controls':'copyRoomLink' in html and 'shareRoomLink' in mp and '?room=' in mp,
 'room capacity supports large rooms':'value=\"50\"' in html and 'capacity between 2 and 50' in (root/'backend/upgrade_v4.sql').read_text(),
 'player podium and certificate controls':'podium-place' in mp and 'createCertificate' in js,
 'profile image upload':'avatarUpload' in html and 'nexora-avatars' in (root/'backend/upgrade_v4.sql').read_text(),
 'PWA install metadata':'icon-192.png' in (root/'manifest.webmanifest').read_text() and (root/'public/icon-512.png').exists(),
 'voice chat controls and WebRTC signaling':all(x in mp for x in ['getUserMedia','RTCPeerConnection','voice-signal','voiceMute','pendingIce']),
 'private room voice signaling access control':'private:true' in mp and 'realtime.messages' in sql and 'nexora_is_room_member' in sql,
 'persistent room next-match RPC':'nexora_next_match' in mp and 'nexora_next_match' in sql,
 'room session restores after reload':'getSession()' in mp and 'restoreRoom()' in mp and 'nexora.mindtrap.room' in mp,
 'room create uses V3 RPC':'nexora_create_room_v2' in mp and 'nexora_create_room_v2' in sql,
 'V3 multiplayer question bank includes both advanced levels':'nexora_level_question_bank' in sql and sql.count("('logic',2,")>=5 and sql.count("('logic',3,")>=5,
 'V4 migration adds Levels 4 and 5':'upgrade_v4.sql' in [p.name for p in (root/'backend').glob('*.sql')] and all(f"('{k}',{lv}," in (root/'backend/upgrade_v4.sql').read_text() for k in ['logic','case','cipher','impostor','survival','daily'] for lv in [4,5]),
}
for name,ok in checks.items():print(('PASS' if ok else 'FAIL')+'  '+name)
if not all(checks.values()):raise SystemExit(1)
