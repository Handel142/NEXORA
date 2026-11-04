from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
sql=(root/'backend'/'upgrade_v4.sql').read_text()
checks={
 'capacity 2–50 and supported room sizes':'capacity between 2 and 50' in sql and 'p_capacity not in (8,20,30,50)' in sql,
 'five-level constraints':'level_no between 1 and 5' in sql and 'level_no between 2 and 5' in sql,
 'spectator mode and admission':'is_spectator boolean' in sql and 'nexora_promote_spectator' in sql and "v_room.status not in ('waiting','in_progress','completed')" in sql,
 'private live scores':'case when v_room.status=\'completed\' then p.score else null end' in sql,
 'RLS blocks raw player rows during active matches':"r.status<>'in_progress'" in sql and 'room members read players outside active level' in sql,
 'RLS blocks answer rows until completion':"r.status='completed'" in sql and 'room members read answers after level' in sql,
 'safe room events replace score-bearing realtime feeds':"table:'nexora_rooms'" in (root/'src'/'multiplayer.js').read_text() and "table:'nexora_room_players'" not in (root/'src'/'multiplayer.js').read_text() and "table:'nexora_answers'" not in (root/'src'/'multiplayer.js').read_text(),
 'no per-question answer count returned':'can_advance' in sql and "'answered_count'" not in sql and "'player_count'" not in sql,
 'host and moderator controls':'nexora_set_moderator' in sql and 'is_moderator boolean' in sql and 'nexora_set_player_mute' in sql,
 'mute everyone RPC':'nexora_set_all_muted' in sql,
 'eight-speaker voice guard':'v_count>=8' in sql and 'nexora_voice_heartbeat' in sql,
 'avatar storage and profile URL':'nexora-avatars' in sql and 'avatar_url' in sql,
 'reused room next-match support':'nexora_next_match' in sql and "status='waiting'" in sql,
 'soft rejoin preserves the room-player row':'last_seen_at=now()' in sql and 'update public.nexora_room_players set last_seen_at=now()-interval' in sql and 'nexora_room_heartbeat' in sql,
 'disconnected players do not block progression':"last_seen_at>now()-interval '3 minutes'" in sql and 'v_new_host' in sql,
 'existing members reclaim their saved room row':'if found then\n   update public.nexora_room_players set last_seen_at=now()' in sql,
 'new arrivals can be spectators when the room is full':'v_spectator:=true' in sql and "is_spectator and last_seen_at>now()-interval '3 minutes'" in sql,
}
# Count exact seeded questions for every game and each of the two new levels.
for game in ['logic','case','cipher','impostor','survival','daily']:
 for level in [4,5]:
  count=len(re.findall(rf"\('{game}',{level},[1-5],",sql))
  checks[f'{game} level {level} has five seeded questions']=count==5
for label,ok in checks.items(): print(('PASS' if ok else 'FAIL')+' '+label)
if not all(checks.values()): raise SystemExit(1)
