-- NEXORA THE MIND TRAP V3 upgrade. Safe to run after the original schema.sql.
-- Adds three-tier multiplayer question packs and room reuse after each completed match.
alter table public.nexora_rooms add column if not exists level_no integer not null default 1 check(level_no between 1 and 3);
create table if not exists public.nexora_level_question_bank(
 game_key text not null check(game_key in ('logic','case','cipher','impostor','survival','daily')),
 level_no integer not null check(level_no in (2,3)),
 round_no integer not null check(round_no between 1 and 5),
 payload jsonb not null, answer_key text not null, explanation text not null default '',
 points integer not null default 120 check(points between 0 and 1000),
 primary key(game_key,level_no,round_no)
);
revoke all on public.nexora_level_question_bank from public,anon,authenticated;

-- Private Realtime channels: only authenticated members of the matching room may exchange voice signalling.
drop policy if exists "NEXORA room members read private broadcasts" on realtime.messages;
create policy "NEXORA room members read private broadcasts" on realtime.messages
for select to authenticated using (
 exists(select 1 from public.nexora_room_players p where p.user_id=auth.uid()
 and realtime.topic()='nexora-room-'||p.room_id::text
 and realtime.messages.extension='broadcast')
);
drop policy if exists "NEXORA room members send private broadcasts" on realtime.messages;
create policy "NEXORA room members send private broadcasts" on realtime.messages
for insert to authenticated with check (
 exists(select 1 from public.nexora_room_players p where p.user_id=auth.uid()
 and realtime.topic()='nexora-room-'||p.room_id::text
 and realtime.messages.extension='broadcast')
);

insert into public.nexora_level_question_bank(game_key,level_no,round_no,payload,answer_key,explanation,points) values
('logic',2,1,'{"kind": "choice", "prompt": "What comes next: 2, 6, 12, 20, 30, …?", "options": ["36", "40", "42", "44"]}'::jsonb,'2','The gaps rise by two: +4,+6,+8,+10,+12.',120),
('logic',2,2,'{"kind": "choice", "prompt": "What comes next: 3, 8, 15, 24, 35, …?", "options": ["44", "48", "50", "52"]}'::jsonb,'1','The sequence follows n²−1: 3,8,15,24,35,48.',120),
('logic',2,3,'{"kind": "choice", "prompt": "All Zorbs are Mips. No Mips are Taves. What must be true?", "options": ["Some Zorbs are Taves", "No Zorbs are Taves", "All Taves are Zorbs", "No Mips are Zorbs"]}'::jsonb,'1','Zorbs are within Mips, and Mips exclude Taves.',120),
('logic',2,4,'{"kind": "choice", "prompt": "What follows 1, 2, 6, 24, 120?", "options": ["240", "360", "600", "720"]}'::jsonb,'3','Multiply by 2, 3, 4, 5, then 6.',120),
('logic',2,5,'{"kind": "choice", "prompt": "What is next in 1, 4, 9, 16, …?", "options": ["20", "24", "25", "36"]}'::jsonb,'2','These are consecutive square numbers.',120),
('logic',3,1,'{"kind": "choice", "prompt": "A pattern alternates ×2 and +3: 4,8,11,22,25,50,…?", "options": ["52", "53", "100", "103"]}'::jsonb,'1','The next operation is +3.',120),
('logic',3,2,'{"kind": "choice", "prompt": "A statement and its converse are both true. What relation holds?", "options": ["P implies Q only", "Q implies P only", "P and Q are equivalent", "They are unrelated"]}'::jsonb,'2','Each proposition is necessary and sufficient for the other.',120),
('logic',3,3,'{"kind": "choice", "prompt": "Which is the only guaranteed conclusion: all A are B; no B are C?", "options": ["Some A are C", "No A are C", "All C are A", "Some B are A"]}'::jsonb,'1','A is contained in B, and B excludes C.',120),
('logic',3,4,'{"kind": "choice", "prompt": "What follows 2, 3, 5, 9, 17, …?", "options": ["25", "31", "33", "34"]}'::jsonb,'2','The increments double: +1,+2,+4,+8,+16.',120),
('logic',3,5,'{"kind": "choice", "prompt": "If 5 machines make 5 parts in 5 minutes, how long do 100 machines take to make 100 parts?", "options": ["5 minutes", "20 minutes", "100 minutes", "500 minutes"]}'::jsonb,'0','Each machine makes one part in five minutes.',120),
('case',2,1,'{"kind": "choice", "prompt": "A badge was used at a door while its owner appears on camera elsewhere. What is established?", "options": ["Owner entered", "Badge was used, user not proven", "Camera is false", "No entry occurred"]}'::jsonb,'1','The badge log identifies a credential, not its physical user.',120),
('case',2,2,'{"kind": "choice", "prompt": "Two witnesses repeat the same group-chat claim. How independent is their corroboration?", "options": ["Fully independent", "Potentially dependent on a shared source", "Proof of truth", "Automatically false"]}'::jsonb,'1','A common source weakens independence.',120),
('case',2,3,'{"kind": "choice", "prompt": "A file hash changes after transfer. What should be checked first?", "options": ["Delete source", "Compare trusted hashes and transfer logs", "Assume tampering", "Rename file"]}'::jsonb,'1','A mismatch needs provenance and acquisition checks.',120),
('case',2,4,'{"kind": "choice", "prompt": "A phone connects to a tower covering a district. What can this alone establish?", "options": ["Exact address", "Approximate coverage area", "Owner committed crime", "Owner held phone"]}'::jsonb,'1','Cell-site location is approximate and does not identify the user.',120),
('case',2,5,'{"kind": "choice", "prompt": "A report conclusion exceeds its source data. Best review?", "options": ["Accept seniority", "Trace claims to source evidence", "Delete data", "Choose dramatic theory"]}'::jsonb,'1','Conclusions should not exceed supporting evidence.',120),
('case',3,1,'{"kind": "choice", "prompt": "CCTV is 7 minutes slow and shows 20:10; server log shows 20:16. Correct CCTV time?", "options": ["20:03", "20:10", "20:17", "20:23"]}'::jsonb,'2','Add the verified seven-minute offset.',120),
('case',3,2,'{"kind": "choice", "prompt": "A witness changes details after seeing news coverage. Best action?", "options": ["Treat as independent confirmation", "Record versions and assess influence", "Ignore all testimony", "Assume fabrication"]}'::jsonb,'1','Preserve the sequence and investigate post-event information.',120),
('case',3,3,'{"kind": "choice", "prompt": "One custody signature is missing but seals are intact. Best assessment?", "options": ["Automatically genuine", "Document gap and examine handling records", "Automatically unusable", "Proof of theft"]}'::jsonb,'1','Assess the significance of the custody gap.',120),
('case',3,4,'{"kind": "choice", "prompt": "A suspect phone is in a tower coverage zone. What cannot be inferred alone?", "options": ["Approximate area", "Network connection", "Exact street and handset user", "Timestamp"]}'::jsonb,'2','Tower coverage cannot establish exact location or who held the phone.',120),
('case',3,5,'{"kind": "choice", "prompt": "A document signature is valid but metadata timestamp differs. What is established?", "options": ["Signer altered it", "Metadata discrepancy needs provenance review", "Entire file false", "Nothing can be checked"]}'::jsonb,'1','A discrepancy is a lead, not proof of cause.',120),
('cipher',2,1,'{"kind": "text", "prompt": "Enter the four-digit code.", "clue": "All digits are different. First digit is 7. Final two digits are consecutive even digits in descending order.", "placeholder": "FOUR-DIGIT CODE"}'::jsonb,'7264','Code accepted.',150),
('cipher',2,2,'{"kind": "text", "prompt": "Enter the second archive code.", "clue": "The first two digits add to 12. The last two digits add to 6. No digit repeats.", "placeholder": "FOUR-DIGIT CODE"}'::jsonb,'4815','Code accepted.',150),
('cipher',2,3,'{"kind": "text", "prompt": "Enter the third security code.", "clue": "The first digit is the largest. The second digit is 3. The final two digits are 5 and 1.", "placeholder": "FOUR-DIGIT CODE"}'::jsonb,'9351','Code accepted.',150),
('cipher',2,4,'{"kind": "text", "prompt": "Enter the fourth lock code.", "clue": "The first digit is 2, the second is 6, the third is 0 and the final digit is 4.", "placeholder": "FOUR-DIGIT CODE"}'::jsonb,'2604','Code accepted.',150),
('cipher',2,5,'{"kind": "text", "prompt": "Enter the fifth lock code.", "clue": "The first digit is 8. The second digit is 1. The final two digits total 11.", "placeholder": "FOUR-DIGIT CODE"}'::jsonb,'8147','Code accepted.',150),
('cipher',3,1,'{"kind": "text", "prompt": "Expert vault: enter the code.", "clue": "Four unique digits. First plus second equals 14. Third is 3 less than second. Last is 7.", "placeholder": "FOUR-DIGIT CODE"}'::jsonb,'5967','Code accepted.',150),
('cipher',3,2,'{"kind": "text", "prompt": "Descending even-digit lock. Enter the code.", "clue": "Four descending even digits, each two less than the previous.", "placeholder": "FOUR-DIGIT CODE"}'::jsonb,'8642','Code accepted.',150),
('cipher',3,3,'{"kind": "text", "prompt": "Master archive: enter the code.", "clue": "The first digit is 1, second is 7, third is 2 and last is 9.", "placeholder": "FOUR-DIGIT CODE"}'::jsonb,'1729','Code accepted.',150),
('cipher',3,4,'{"kind": "text", "prompt": "Precision lock: enter the code.", "clue": "The first digit is 4, the second is 0, the third is 6 and the last is 3.", "placeholder": "FOUR-DIGIT CODE"}'::jsonb,'4063','Code accepted.',150),
('cipher',3,5,'{"kind": "text", "prompt": "Final master lock: enter the code.", "clue": "The first digit is 9, the second is 2, the third is 8 and the fourth is 4.", "placeholder": "FOUR-DIGIT CODE"}'::jsonb,'9284','Code accepted.',150),
('impostor',2,1,'{"kind": "choice", "prompt": "Which account is impossible?", "options": ["Packed at 08:00", "Sealed at 08:10", "Label printed at 08:12", "Inspected at 08:05 after sealing"]}'::jsonb,'3','Inspection cannot occur after sealing and before the stated seal time.',120),
('impostor',2,2,'{"kind": "choice", "prompt": "Which claim conflicts with the others?", "options": ["Every approved request has a reference", "Request K is approved", "K has no reference", "K is listed approved"]}'::jsonb,'2','Approval requires a reference under the first claim.',120),
('impostor',2,3,'{"kind": "choice", "prompt": "Which travel account is impossible?", "options": ["Train left 17:20", "Boarded 17:15", "Gate closed 17:18", "Arrived 17:25 then boarded"]}'::jsonb,'3','Arrival occurs after departure.',120),
('impostor',2,4,'{"kind": "choice", "prompt": "Which timeline is inconsistent?", "options": ["Alarm 02:01", "Dispatch 02:03", "Arrival 02:08", "Arrival 02:00 after dispatch"]}'::jsonb,'3','Arrival precedes dispatch.',120),
('impostor',2,5,'{"kind": "choice", "prompt": "Which statement contradicts the key log?", "options": ["Key out 09:00", "Custodian got it 09:05", "Returned 09:40", "Returned 08:55 after checkout 09:00"]}'::jsonb,'3','Return time is earlier than checkout.',120),
('impostor',3,1,'{"kind": "choice", "prompt": "Which pair cannot both be true?", "options": ["No red files archived", "File K is red", "File K is archived", "File K in cabinet 2"]}'::jsonb,'2','The first two exclude K from the archive.',120),
('impostor',3,2,'{"kind": "choice", "prompt": "A witness says nobody entered after 14:00 and says they entered at 14:12. What is this?", "options": ["Consistent", "Contradiction unless self-excluded", "Both true", "Irrelevant"]}'::jsonb,'1','The universal statement conflicts with the witness’s own entry.',120),
('impostor',3,3,'{"kind": "choice", "prompt": "Which statement conflicts with exactly one server offline?", "options": ["Server 2 online", "Server 3 online", "All three servers offline", "Server 1 offline"]}'::jsonb,'2','All three offline contradicts exactly one offline.',120),
('impostor',3,4,'{"kind": "choice", "prompt": "A report says a backup completed before it began. Best finding?", "options": ["Operator guilty", "Sequence internally inconsistent; verify logs", "Backup never happened", "Forgery proven"]}'::jsonb,'1','The timeline is inconsistent but cause is unproven.',120),
('impostor',3,5,'{"kind": "choice", "prompt": "Which account violates the locked-door record?", "options": ["Door locked 10:00", "Only key held by guard", "No access until 10:20", "Visitor entered at 10:10 without key or other route"]}'::jsonb,'3','The stated access conditions exclude that entry.',120),
('survival',2,1,'{"kind": "choice", "prompt": "Confidential customer data is posted publicly by mistake. First action?", "options": ["Forward it", "Contain exposure and notify responsible response contact", "Delete silently", "Repost details"]}'::jsonb,'1','Limit exposure and use incident procedure.',120),
('survival',2,2,'{"kind": "choice", "prompt": "A safety risk conflicts with a routine deadline. Prioritise?", "options": ["Easiest task", "Immediate harm risk and communicate delay", "Seniority only", "Neither"]}'::jsonb,'1','Prioritise imminent harm.',120),
('survival',2,3,'{"kind": "choice", "prompt": "Asked to vouch for an event you did not witness. Respond?", "options": ["Agree", "State only what you know", "Invent details", "Avoid all questions"]}'::jsonb,'1','Be precise about the limits of your knowledge.',120),
('survival',2,4,'{"kind": "choice", "prompt": "A public post exposes a private location during a dispute. Best action?", "options": ["Share widely", "Do not amplify; report exposure", "Visit location", "Add details"]}'::jsonb,'1','Avoid increasing risk and report it.',120),
('survival',2,5,'{"kind": "choice", "prompt": "A key project assumption fails. Best response?", "options": ["Hide it", "Reassess facts, communicate impact and revise plan", "Keep forecast", "Blame someone"]}'::jsonb,'1','Update the plan transparently.',120),
('survival',3,1,'{"kind": "choice", "prompt": "An action gives small gains but risks severe irreversible harm. Examine?", "options": ["Average gain only", "Severity, reversibility, safeguards and who bears risk", "Popularity", "Speed"]}'::jsonb,'1','Assess downside, safeguards and distribution of harm.',120),
('survival',3,2,'{"kind": "choice", "prompt": "Two emergency alerts conflict. Follow?", "options": ["Most confident post", "Verified emergency personnel and official alerts", "Social poll", "Both routes safe"]}'::jsonb,'1','Use authoritative incident instructions.',120),
('survival',3,3,'{"kind": "choice", "prompt": "A teammate asks to bypass access controls. Best?", "options": ["Share credentials", "Use approved logged emergency access", "Disable controls", "Use unattended session"]}'::jsonb,'1','Emergency access must be authorised and auditable.',120),
('survival',3,4,'{"kind": "choice", "prompt": "A majority benefits while a small group faces avoidable harm. Next?", "options": ["Ignore minority", "Assess impact, consult affected people and test alternatives", "Vote settles it", "Hide cost"]}'::jsonb,'1','Consider distribution of harm and alternatives.',120),
('survival',3,5,'{"kind": "choice", "prompt": "A financial error harms a customer but benefits team. Best?", "options": ["Keep quiet", "Escalate and correct before proceeding", "Wait", "Move amount"]}'::jsonb,'1','Correct the harm and document it.',120),
('daily',2,1,'{"kind": "choice", "prompt": "A 20% discount then a 20% increase gives what net change?", "options": ["No change", "4% lower", "4% higher", "20% lower"]}'::jsonb,'1','100 becomes 80 then 96, four percent lower.',120),
('daily',2,2,'{"kind": "choice", "prompt": "How many draws guarantee two same-colour tokens from red/blue only?", "options": ["2", "3", "4", "5"]}'::jsonb,'1','The third draw must match one of the first two.',120),
('daily',2,3,'{"kind": "choice", "prompt": "A fair coin is tossed three times. Probability of exactly two heads?", "options": ["1/8", "3/8", "1/2", "5/8"]}'::jsonb,'1','Three of eight outcomes have exactly two heads.',120),
('daily',2,4,'{"kind": "choice", "prompt": "A 25% rise followed by a 20% fall gives?", "options": ["No net change", "5% rise", "5% fall", "10% rise"]}'::jsonb,'0','1.25 × 0.8 = 1.',120),
('daily',2,5,'{"kind": "choice", "prompt": "Five machines make five parts in five minutes. 100 machines make 100 parts in?", "options": ["5 minutes", "20 minutes", "100 minutes", "500 minutes"]}'::jsonb,'0','Each machine makes one part in five minutes.',120),
('daily',3,1,'{"kind": "choice", "prompt": "Three boxes are all mislabelled APPLES, ORANGES, MIXED. Which box should you sample?", "options": ["APPLES", "ORANGES", "MIXED", "Any"]}'::jsonb,'2','The MIXED label must be wrong, so one draw identifies its true contents.',120),
('daily',3,2,'{"kind": "choice", "prompt": "A statement is true exactly when it is false. Diagnosis?", "options": ["Tautology", "Contradiction/paradox in classical logic", "Always true", "Always false"]}'::jsonb,'1','The condition cannot be consistently satisfied in two-valued logic.',120),
('daily',3,3,'{"kind": "choice", "prompt": "Average speed over equal distances at 2 km/h and 10 km/h is?", "options": ["3.33 km/h", "5 km/h", "6 km/h", "8 km/h"]}'::jsonb,'0','Harmonic mean: 2×2×10/(2+10)=3.33 km/h.',120),
('daily',3,4,'{"kind": "choice", "prompt": "A number rises 10%, then rises 10% again. Net increase?", "options": ["20%", "21%", "19%", "10%"]}'::jsonb,'1','1.1 × 1.1 = 1.21.',120),
('daily',3,5,'{"kind": "choice", "prompt": "A balance scale: one of 8 balls is heavier. Minimum weighings?", "options": ["1", "2", "3", "4"]}'::jsonb,'1','Split 3 vs 3; then resolve the remaining group in one weighing.',120)
on conflict(game_key,level_no,round_no) do update set payload=excluded.payload,answer_key=excluded.answer_key,explanation=excluded.explanation,points=excluded.points;

create or replace function public.nexora_create_room_v2(p_game_key text default 'logic',p_capacity integer default 4,p_level_no integer default 1)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_room public.nexora_rooms; v_name text;
begin
 if v_uid is null then raise exception 'Sign in is required.'; end if;
 if p_game_key not in ('logic','case','cipher','impostor','survival','daily') then raise exception 'Choose a valid NEXORA game.'; end if;
 if p_capacity not between 2 and 8 then raise exception 'Room capacity must be between 2 and 8.'; end if;
 if p_level_no not between 1 and 3 then raise exception 'Choose a valid level.'; end if;
 if p_level_no=1 and not exists(select 1 from public.nexora_question_bank where game_key=p_game_key) then raise exception 'No questions are published for this game.'; end if;
 if p_level_no>1 and not exists(select 1 from public.nexora_level_question_bank where game_key=p_game_key and level_no=p_level_no) then raise exception 'This level has no published questions.'; end if;
 select coalesce(display_name,'Player') into v_name from public.player_profiles where user_id=v_uid;
 if v_name is null then v_name:='Player-'||upper(substr(v_uid::text,1,4)); end if;
 insert into public.nexora_rooms(room_code,host_id,game_key,capacity,level_no) values(upper(substr(encode(gen_random_bytes(6),'hex'),1,6)),v_uid,p_game_key,p_capacity,p_level_no) returning * into v_room;
 insert into public.nexora_room_players(room_id,user_id,display_name,is_host,is_ready) values(v_room.id,v_uid,v_name,true,true);
 return jsonb_build_object('room_id',v_room.id,'room_code',v_room.room_code);
end $$;

create or replace function public.nexora_get_room(p_room_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room public.nexora_rooms; v_players jsonb;
begin
 select * into v_room from public.nexora_rooms where id=p_room_id;
 if not found or not exists(select 1 from public.nexora_room_players where room_id=p_room_id and user_id=auth.uid()) then raise exception 'Room not found or access denied.'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('user_id',p.user_id,'display_name',p.display_name,'is_host',p.is_host,'is_ready',p.is_ready,'score',p.score,'correct_count',p.correct_count) order by p.joined_at),'[]'::jsonb) into v_players from public.nexora_room_players p where p.room_id=p_room_id;
 return jsonb_build_object('id',v_room.id,'room_code',v_room.room_code,'game_key',v_room.game_key,'level_no',v_room.level_no,'capacity',v_room.capacity,'status',v_room.status,'current_round',v_room.current_round,'is_host',v_room.host_id=auth.uid(),'players',v_players);
end $$;

create or replace function public.nexora_start_room(p_room_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room public.nexora_rooms; v_count integer; v_ready integer; v_rounds integer;
begin
 select * into v_room from public.nexora_rooms where id=p_room_id for update;
 if not found or v_room.host_id<>auth.uid() then raise exception 'Only the room host can start this match.'; end if;
 if v_room.status<>'waiting' then raise exception 'This room is not waiting.'; end if;
 select count(*),count(*) filter(where is_ready) into v_count,v_ready from public.nexora_room_players where room_id=p_room_id;
 if v_count<2 then raise exception 'At least two players must join.'; end if;
 if v_count<>v_ready then raise exception 'Every player must be ready before the host starts.'; end if;
 if v_room.level_no=1 then select count(*) into v_rounds from public.nexora_question_bank where game_key=v_room.game_key;
 else select count(*) into v_rounds from public.nexora_level_question_bank where game_key=v_room.game_key and level_no=v_room.level_no; end if;
 if v_rounds<>5 then raise exception 'This game level must contain exactly five published rounds.'; end if;
 update public.nexora_rooms set status='in_progress',current_round=1,started_at=now(),ended_at=null where id=p_room_id;
 return public.nexora_get_room(p_room_id);
end $$;

create or replace function public.nexora_get_round(p_room_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room public.nexora_rooms; v_payload jsonb; v_answered boolean; v_total integer;
begin
 select * into v_room from public.nexora_rooms where id=p_room_id;
 if not found or v_room.status not in ('in_progress','completed') or not exists(select 1 from public.nexora_room_players where room_id=p_room_id and user_id=auth.uid()) then raise exception 'No active match found.'; end if;
 if v_room.status='completed' then return jsonb_build_object('complete',true,'round',v_room.current_round); end if;
 if v_room.level_no=1 then select payload into v_payload from public.nexora_question_bank where game_key=v_room.game_key and round_no=v_room.current_round;
 else select payload into v_payload from public.nexora_level_question_bank where game_key=v_room.game_key and level_no=v_room.level_no and round_no=v_room.current_round; end if;
 if v_payload is null then return jsonb_build_object('complete',true,'round',v_room.current_round); end if;
 if v_room.level_no=1 then select count(*) into v_total from public.nexora_question_bank where game_key=v_room.game_key; else select count(*) into v_total from public.nexora_level_question_bank where game_key=v_room.game_key and level_no=v_room.level_no; end if;
 select exists(select 1 from public.nexora_answers where room_id=p_room_id and round_no=v_room.current_round and user_id=auth.uid()) into v_answered;
 return jsonb_build_object('complete',false,'round',v_room.current_round,'total_rounds',v_total,'payload',v_payload,'already_answered',v_answered,'answered_count',(select count(*) from public.nexora_answers where room_id=p_room_id and round_no=v_room.current_round),'player_count',(select count(*) from public.nexora_room_players where room_id=p_room_id),'is_host',v_room.host_id=auth.uid());
end $$;

create or replace function public.nexora_submit_answer(p_room_id uuid,p_answer text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room public.nexora_rooms; v_payload jsonb; v_key text; v_explanation text; v_points integer; v_ok boolean; v_award integer; v_exact integer:=0; v_near integer:=0; v_feedback text; i integer;
begin
 select * into v_room from public.nexora_rooms where id=p_room_id for update;
 if not found or v_room.status<>'in_progress' then raise exception 'The match is not accepting answers.'; end if;
 if not exists(select 1 from public.nexora_room_players where room_id=p_room_id and user_id=auth.uid()) then raise exception 'You are not a member of this room.'; end if;
 if v_room.level_no=1 then select payload,answer_key,explanation,points into v_payload,v_key,v_explanation,v_points from public.nexora_question_bank where game_key=v_room.game_key and round_no=v_room.current_round;
 else select payload,answer_key,explanation,points into v_payload,v_key,v_explanation,v_points from public.nexora_level_question_bank where game_key=v_room.game_key and level_no=v_room.level_no and round_no=v_room.current_round; end if;
 if v_key is null then raise exception 'Round data not found.'; end if;
 v_ok:=lower(trim(p_answer))=lower(trim(v_key)); v_award:=case when v_ok then v_points else 0 end;
 if v_room.game_key='cipher' and length(trim(p_answer))=4 then for i in 1..4 loop if substr(trim(p_answer),i,1)=substr(v_key,i,1) then v_exact:=v_exact+1; elsif position(substr(trim(p_answer),i,1) in v_key)>0 then v_near:=v_near+1; end if; end loop; v_feedback:=format('Feedback: %s correct position(s), %s correct digit(s) in the wrong position.',v_exact,v_near); end if;
 insert into public.nexora_answers(room_id,round_no,user_id,answer,is_correct,points_awarded) values(p_room_id,v_room.current_round,auth.uid(),left(p_answer,100),v_ok,v_award);
 update public.nexora_room_players p set score=p.score+v_award,correct_count=p.correct_count+case when v_ok then 1 else 0 end where p.room_id=p_room_id and p.user_id=auth.uid();
 return jsonb_build_object('accepted',true,'correct',v_ok,'points',v_award,'explanation',v_explanation,'feedback',case when v_ok then v_explanation else coalesce(v_feedback,v_explanation) end);
exception when unique_violation then raise exception 'You have already submitted an answer for this round.';
end $$;

create or replace function public.nexora_advance_round(p_room_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room public.nexora_rooms; v_players integer; v_answered integer; v_total integer;
begin
 select * into v_room from public.nexora_rooms where id=p_room_id for update;
 if not found or v_room.host_id<>auth.uid() then raise exception 'Only the host can advance the round.'; end if;
 if v_room.status<>'in_progress' then raise exception 'The match is not in progress.'; end if;
 select count(*) into v_players from public.nexora_room_players where room_id=p_room_id;
 select count(*) into v_answered from public.nexora_answers where room_id=p_room_id and round_no=v_room.current_round;
 if v_answered<v_players then raise exception 'Wait until every player has submitted an answer.'; end if;
 if v_room.level_no=1 then select count(*) into v_total from public.nexora_question_bank where game_key=v_room.game_key; else select count(*) into v_total from public.nexora_level_question_bank where game_key=v_room.game_key and level_no=v_room.level_no; end if;
 if v_room.current_round>=v_total then update public.nexora_rooms set status='completed',ended_at=now() where id=p_room_id; else update public.nexora_rooms set current_round=current_round+1 where id=p_room_id; end if;
 return public.nexora_get_room(p_room_id);
end $$;

create or replace function public.nexora_next_match(p_room_id uuid,p_game_key text default null,p_level_no integer default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room public.nexora_rooms; v_game text; v_level integer;
begin
 select * into v_room from public.nexora_rooms where id=p_room_id for update;
 if not found or v_room.host_id<>auth.uid() then raise exception 'Only the host can start another match in this room.'; end if;
 if v_room.status<>'completed' then raise exception 'Finish the current match before starting another.'; end if;
 v_game:=coalesce(p_game_key,v_room.game_key); v_level:=coalesce(p_level_no,v_room.level_no);
 if v_game not in ('logic','case','cipher','impostor','survival','daily') or v_level not between 1 and 3 then raise exception 'Choose a valid game and level.'; end if;
 if v_level=1 then if (select count(*) from public.nexora_question_bank where game_key=v_game)<>5 then raise exception 'This game has no complete five-question level.'; end if;
 else if (select count(*) from public.nexora_level_question_bank where game_key=v_game and level_no=v_level)<>5 then raise exception 'This game level has no complete five-question pack.'; end if; end if;
 delete from public.nexora_answers where room_id=p_room_id;
 update public.nexora_room_players set score=0,correct_count=0,is_ready=(user_id=auth.uid()) where room_id=p_room_id;
 update public.nexora_rooms set game_key=v_game,level_no=v_level,status='waiting',current_round=0,started_at=null,ended_at=null where id=p_room_id;
 return public.nexora_get_room(p_room_id);
end $$;

grant execute on function public.nexora_create_room_v2(text,integer,integer) to authenticated;
grant execute on function public.nexora_next_match(uuid,text,integer) to authenticated;
revoke all on function public.nexora_create_room_v2(text,integer,integer) from public,anon;
revoke all on function public.nexora_next_match(uuid,text,integer) from public,anon;
