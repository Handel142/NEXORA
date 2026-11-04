-- NEXORA THE MIND TRAP V4 migration
-- Apply once in Supabase SQL Editor after your existing V3 schema + room-code hotfix.
-- Back up your database first. This preserves V1/V2/V3 question packs and room data.
begin;

alter table public.nexora_rooms drop constraint if exists nexora_rooms_capacity_check;
alter table public.nexora_rooms add constraint nexora_rooms_capacity_check check (capacity between 2 and 50);
alter table public.nexora_rooms drop constraint if exists nexora_rooms_level_no_check;
alter table public.nexora_rooms add constraint nexora_rooms_level_no_check check (level_no between 1 and 5);
alter table public.nexora_rooms add column if not exists updated_at timestamptz not null default now();
drop policy if exists "room members read players" on public.nexora_room_players;
drop policy if exists "room members read players outside active level" on public.nexora_room_players;
create policy "room members read players outside active level" on public.nexora_room_players for select using (public.nexora_is_room_member(room_id) and exists(select 1 from public.nexora_rooms r where r.id=room_id and r.status<>'in_progress'));
drop policy if exists "room members read answers" on public.nexora_answers;
drop policy if exists "room members read answers after level" on public.nexora_answers;
create policy "room members read answers after level" on public.nexora_answers for select using (public.nexora_is_room_member(room_id) and exists(select 1 from public.nexora_rooms r where r.id=room_id and r.status='completed'));
alter table public.nexora_level_question_bank drop constraint if exists nexora_level_question_bank_level_no_check;
alter table public.nexora_level_question_bank add constraint nexora_level_question_bank_level_no_check check (level_no between 2 and 5);
alter table public.nexora_room_players add column if not exists is_spectator boolean not null default false;
alter table public.nexora_room_players add column if not exists last_seen_at timestamptz not null default now();
alter table public.nexora_room_players add column if not exists is_muted boolean not null default false;
alter table public.nexora_room_players add column if not exists is_moderator boolean not null default false;
alter table public.nexora_room_players add column if not exists voice_active boolean not null default false;
alter table public.nexora_room_players add column if not exists voice_updated_at timestamptz;
alter table public.player_profiles add column if not exists avatar_url text;
insert into storage.buckets(id,name,public) values('nexora-avatars','nexora-avatars',true) on conflict(id) do nothing;
drop policy if exists "NEXORA avatar images are publicly readable" on storage.objects;
create policy "NEXORA avatar images are publicly readable" on storage.objects for select to public using(bucket_id='nexora-avatars');
drop policy if exists "NEXORA users upload own avatar" on storage.objects;
create policy "NEXORA users upload own avatar" on storage.objects for insert to authenticated with check(bucket_id='nexora-avatars' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "NEXORA users update own avatar" on storage.objects;
create policy "NEXORA users update own avatar" on storage.objects for update to authenticated using(bucket_id='nexora-avatars' and (storage.foldername(name))[1]=auth.uid()::text) with check(bucket_id='nexora-avatars' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "NEXORA users delete own avatar" on storage.objects;
create policy "NEXORA users delete own avatar" on storage.objects for delete to authenticated using(bucket_id='nexora-avatars' and (storage.foldername(name))[1]=auth.uid()::text);


insert into public.nexora_level_question_bank(game_key,level_no,round_no,payload,answer_key,explanation,points) values
('logic',4,1,'{"kind":"choice","prompt":"A sequence follows n²+n: 2, 6, 12, 20, 30. What is the next term?","options":["40","42","44","48"]}'::jsonb,'1','The terms are n(n+1): 1×2, 2×3, … 6×7 = 42.',150),
('logic',4,2,'{"kind":"choice","prompt":"A number is tripled, then 7 is subtracted. The result is 50. Find the number.","options":["17","18","19","20"]}'::jsonb,'2','Reverse the steps: (50+7)÷3 = 19.',150),
('logic',4,3,'{"kind":"choice","prompt":"If every Venn is a Ralo, and no Ralo is a Senn, which must be true?","options":["Some Venns are Senns","No Venn is a Senn","Every Senn is a Venn","No Ralo is a Venn"]}'::jsonb,'1','Venns are inside the Ralo set, which excludes all Senns.',150),
('logic',4,4,'{"kind":"choice","prompt":"A sequence alternates +2, ×3: 2, 4, 12, 14, 42, 44, …","options":["46","88","132","136"]}'::jsonb,'2','The next operation is ×3: 44×3 = 132.',150),
('logic',4,5,'{"kind":"choice","prompt":"A clock gains 4 minutes every hour. It is correct at 08:00. What does it show when real time is 14:00?","options":["14:20","14:24","14:30","14:40"]}'::jsonb,'1','Six hours × four minutes = 24 minutes gained.',150),
('logic',5,1,'{"kind":"choice","prompt":"A sequence adds consecutive primes: 2, 4, 7, 12, 19, … What comes next?","options":["28","30","32","34"]}'::jsonb,'2','Add 2, 3, 5, 7, 11, then 13: 19+13 = 32.',150),
('logic',5,2,'{"kind":"choice","prompt":"Three statements: P implies Q; Q implies R; R is false. What follows?","options":["P is true","Q is true","P is false","Nothing follows"]}'::jsonb,'2','If P were true, Q and then R would be true. Since R is false, P must be false.',150),
('logic',5,3,'{"kind":"choice","prompt":"A three-digit code has first digit twice the second and last digit three more than the second. The digits sum to 15. Which code fits?","options":["636","426","834","936"]}'::jsonb,'0','The second digit is 3; the first is 6 and the last is 6. The digits sum to 15.',150),
('logic',5,4,'{"kind":"choice","prompt":"A claim is true only if both X and Y are true. X is false. What can be concluded about the claim?","options":["It is true","It is false","It is undecidable","Y must be false"]}'::jsonb,'1','A conjunction with one false component is false.',150),
('logic',5,5,'{"kind":"choice","prompt":"A group has 5 people. Each shakes hands with every other person exactly once. How many handshakes occur?","options":["5","10","15","20"]}'::jsonb,'1','There are 5×4÷2 = 10 unique pairs.',150),
('case',4,1,'{"kind":"choice","prompt":"A server log records a successful login, but endpoint telemetry shows the device powered off at that time. What is the strongest conclusion?","options":["The owner logged in remotely","The records conflict and need clock/source validation","The log is fabricated","The device was definitely stolen"]}'::jsonb,'1','Conflicting records require validation of time synchronisation, identity and source integrity.',150),
('case',4,2,'{"kind":"choice","prompt":"A sample label matches a case file, but the seal number differs. What should happen next?","options":["Ignore the seal","Document the discrepancy and verify custody before relying on the sample","Assume substitution","Destroy the sample"]}'::jsonb,'1','A seal mismatch is a chain-of-custody concern that must be investigated.',150),
('case',4,3,'{"kind":"choice","prompt":"Two witnesses give matching descriptions after discussing the event together. What is the key limitation?","options":["Descriptions are automatically false","Their recollections may not be independent","They prove the event","They cannot be interviewed"]}'::jsonb,'1','Shared discussion can contaminate independence; record when and how they exchanged information.',150),
('case',4,4,'{"kind":"choice","prompt":"A report cites a screenshot but no original message or metadata. What is the best next step?","options":["Treat screenshot as conclusive","Seek original source, metadata and corroborating records","Reject every screenshot","Publish it"]}'::jsonb,'1','A screenshot can be altered or incomplete; obtain source material and provenance.',150),
('case',4,5,'{"kind":"choice","prompt":"An access log uses UTC; a camera uses local time UTC+3. Camera shows 12:10. What is the corresponding UTC time?","options":["09:10","12:10","15:10","10:10"]}'::jsonb,'0','Subtract three hours to convert local UTC+3 to UTC.',150),
('case',5,1,'{"kind":"choice","prompt":"A digital file hash matches the original, but the acquisition log is missing. What is established?","options":["Entire chain of custody is proven","The file contents match the reference hash, but acquisition history remains undocumented","The file is fake","The device owner is identified"]}'::jsonb,'1','A matching hash supports integrity from the reference point, not the full acquisition chain.',150),
('case',5,2,'{"kind":"choice","prompt":"A witness identifies a person only after seeing their name in a news article. What is the key risk?","options":["Perfect corroboration","Post-event information may have influenced the identification","The witness cannot speak","The person is guilty"]}'::jsonb,'1','Prior exposure can influence memory and confidence.',150),
('case',5,3,'{"kind":"choice","prompt":"A spreadsheet total differs from its source rows by exactly 10%. What should an auditor inspect first?","options":["Delete the total","Formula range, hidden rows, filters and source versions","Assume fraud","Round all figures"]}'::jsonb,'1','Check formulas and omitted/hidden data before drawing conclusions.',150),
('case',5,4,'{"kind":"choice","prompt":"A timeline is built from three clocks with unknown offsets. What is the soundest approach?","options":["Sort displayed times directly","Establish offsets and uncertainty from trusted reference events before ordering","Average all timestamps","Use the newest clock"]}'::jsonb,'1','Time normalisation and uncertainty are essential for defensible sequencing.',150),
('case',5,5,'{"kind":"choice","prompt":"A document has a valid digital signature, but the certificate was revoked before signing. What is the proper finding?","options":["Signature is automatically valid","Signature validation is compromised; check trusted timestamp and revocation history","Document is automatically forged","Signer is guilty"]}'::jsonb,'1','Validity depends on certificate status and trusted timestamp at signing.',150),
('cipher',4,1,'{"kind":"text","prompt":"LEVEL 4 LOCK. Enter the four-digit code.","clue":"The first digit is 5 and the last digit is 7. The two middle digits add to 11 and multiply to 24. The second digit is greater than the third. All four digits are different.","placeholder":"FOUR-DIGIT CODE"}'::jsonb,'5837','The code is 5837. The clue specifies 5, 8, 3, 7.',150),
('cipher',4,2,'{"kind":"text","prompt":"A second lock awaits.","clue":"The first digit is 2 and the last digit is 9. The two middle digits add to 10 and multiply to 24. The second digit is smaller than the third. All four digits are different.","placeholder":"FOUR-DIGIT CODE"}'::jsonb,'2469','The code is 2469. The clue specifies 2, 4, 6, 9.',150),
('cipher',4,3,'{"kind":"text","prompt":"Secure archive keypad.","clue":"The first digit is 7 and the last digit is 5. The two middle digits add to 4 and multiply to 3. The second digit is greater than the third. All four digits are different.","placeholder":"FOUR-DIGIT CODE"}'::jsonb,'7315','The code is 7315. The clue specifies 7, 3, 1, 5.',150),
('cipher',4,4,'{"kind":"text","prompt":"Vault panel four.","clue":"The first digit is 8 and the last digit is 2. The two middle digits add to 4 and multiply to 0. The second digit is smaller than the third. All four digits are different.","placeholder":"FOUR-DIGIT CODE"}'::jsonb,'8042','The code is 8042. The clue specifies 8, 0, 4, 2.',150),
('cipher',4,5,'{"kind":"text","prompt":"Final Level 4 code.","clue":"The first digit is 9 and the last digit is 4. The two middle digits add to 8 and multiply to 12. The second digit is smaller than the third. All four digits are different.","placeholder":"FOUR-DIGIT CODE"}'::jsonb,'9624','The code is 9624. The clue specifies 9, 6, 2, 4.',150),
('cipher',5,1,'{"kind":"text","prompt":"MASTER LOCK ONE.","clue":"The first digit is 4 and the last digit is 9. The two middle digits add to 8 and multiply to 7. The second digit is smaller than the third. All four digits are different.","placeholder":"FOUR-DIGIT CODE"}'::jsonb,'4179','The code is 4179. The clue specifies 4, 1, 7, 9.',150),
('cipher',5,2,'{"kind":"text","prompt":"MASTER LOCK TWO.","clue":"The first digit is 8 and the last digit is 3. The two middle digits add to 7 and multiply to 10. The second digit is smaller than the third. All four digits are different.","placeholder":"FOUR-DIGIT CODE"}'::jsonb,'8253','The code is 8253. The clue specifies 8, 2, 5, 3.',150),
('cipher',5,3,'{"kind":"text","prompt":"MASTER LOCK THREE.","clue":"The first digit is 6 and the last digit is 2. The two middle digits add to 9 and multiply to 0. The second digit is greater than the third. All four digits are different.","placeholder":"FOUR-DIGIT CODE"}'::jsonb,'6902','The code is 6902. The clue specifies 6, 9, 0, 2.',150),
('cipher',5,4,'{"kind":"text","prompt":"MASTER LOCK FOUR.","clue":"The first digit is 3 and the last digit is 1. The two middle digits add to 13 and multiply to 40. The second digit is smaller than the third. All four digits are different.","placeholder":"FOUR-DIGIT CODE"}'::jsonb,'3581','The code is 3581. The clue specifies 3, 5, 8, 1.',150),
('cipher',5,5,'{"kind":"text","prompt":"FINAL MIND LOCK.","clue":"The first digit is 7 and the last digit is 6. The two middle digits add to 5 and multiply to 4. The second digit is smaller than the third. All four digits are different.","placeholder":"FOUR-DIGIT CODE"}'::jsonb,'7146','The code is 7146. The clue specifies 7, 1, 4, 6.',150),
('impostor',4,1,'{"kind":"choice","prompt":"Four records describe a lab test. Which statement is impossible?","options":["Sample sealed at 09:10","Seal checked intact at 09:15","Sample opened at 09:12","Sample stored at 09:20"]}'::jsonb,'2','Opening at 09:12 conflicts with the claim that the seal remained intact at 09:15.',150),
('impostor',4,2,'{"kind":"choice","prompt":"Which claim conflicts with the rule: every encrypted backup is offline?","options":["Backup A is encrypted","Backup A is online","Backup B is offline","Some backups are encrypted"]}'::jsonb,'1','An encrypted backup cannot be online under the stated rule.',150),
('impostor',4,3,'{"kind":"choice","prompt":"A train leaves at 10:00 and reaches the next station at 10:18. Which account is impossible?","options":["Boarded 09:55","Arrived 10:18","Train passed signal 10:08","Passenger boarded at next station at 10:25 and rode this train from origin"]}'::jsonb,'3','The passenger boards after the train has already arrived.',150),
('impostor',4,4,'{"kind":"choice","prompt":"Which statement breaks the stated order: draft, review, approval, release?","options":["Draft before review","Review before approval","Release before approval","Approval before release"]}'::jsonb,'2','Release must follow approval.',150),
('impostor',4,5,'{"kind":"choice","prompt":"A door sensor reports closed continuously 14:00–14:10. Which account conflicts?","options":["Door was shut at 14:02","Door was closed at 14:08","Door opened at 14:05","Door was closed at 14:10"]}'::jsonb,'2','An opening at 14:05 contradicts continuous closed status.',150),
('impostor',5,1,'{"kind":"choice","prompt":"Exactly one of A,B,C is false. A is true and B is false. What must C be?","options":["True","False","Both","Cannot be determined"]}'::jsonb,'0','Since exactly one is false and B is already false, C must be true.',150),
('impostor',5,2,'{"kind":"choice","prompt":"All approved keys are logged. Key K is approved but absent from the log. Which is the contradiction?","options":["K is approved","All approved keys are logged","K is absent from log","All three can coexist"]}'::jsonb,'2','The rule and approval imply K must appear in the log.',150),
('impostor',5,3,'{"kind":"choice","prompt":"A witness says the room was empty at 16:00 and says they saw a person inside at 16:00. What is the issue?","options":["No issue","The two claims conflict unless “empty” has a narrower meaning","Both prove entry","Only the second claim matters"]}'::jsonb,'1','Under the same meaning and time, the statements cannot both be true.',150),
('impostor',5,4,'{"kind":"choice","prompt":"Which sequence violates strict increasing order?","options":["2,4,7,9","1,3,3,8","0,5,6,10","4,8,12,16"]}'::jsonb,'1','The repeated 3 means the sequence is not strictly increasing.',150),
('impostor',5,5,'{"kind":"choice","prompt":"A report states a file was deleted at 11:02, restored at 11:05, and first created at 11:08. Which claim is inconsistent?","options":["Deleted 11:02","Restored 11:05","Created 11:08","All three necessarily consistent"]}'::jsonb,'2','A file cannot be restored at 11:05 if its first creation was not until 11:08, absent a different file/version.',150),
('survival',4,1,'{"kind":"choice","prompt":"A decision has a small immediate benefit but may expose private data irreversibly. What should be assessed first?","options":["Only speed","Data minimisation, consent, exposure and reversible alternatives","Popularity","Whether others have done it"]}'::jsonb,'1','Assess privacy impact and less invasive options before acting.',150),
('survival',4,2,'{"kind":"choice","prompt":"You discover a critical safety checklist was skipped. The launch is in minutes. What is the responsible action?","options":["Proceed and hide it","Pause the affected step, verify safety and escalate the risk","Backdate the checklist","Blame the newest employee"]}'::jsonb,'1','A material safety control must be verified before proceeding.',150),
('survival',4,3,'{"kind":"choice","prompt":"A colleague asks you to alter a record to match a target. What should you do?","options":["Make the edit","Preserve the original, refuse falsification and use the reporting route","Delete the record","Ask them to send the request verbally"]}'::jsonb,'1','Maintain record integrity and report improper pressure.',150),
('survival',4,4,'{"kind":"choice","prompt":"A public warning is unverified but could prevent harm. What is best?","options":["Share it as fact","Check authoritative sources urgently and communicate uncertainty clearly","Ignore it","Add dramatic details"]}'::jsonb,'1','Rapid verification and transparent uncertainty reduce both delay and misinformation.',150),
('survival',4,5,'{"kind":"choice","prompt":"A team has limited resources and two risks. One is likely but minor; one is unlikely but catastrophic. What should guide allocation?","options":["Likelihood alone","Likelihood, severity, mitigation, exposure and reversibility","Choose randomly","Only short-term cost"]}'::jsonb,'1','Risk decisions should consider both probability and consequence plus controls.',150),
('survival',5,1,'{"kind":"choice","prompt":"A project metric improves because the team changed how it counts failures. What should an independent reviewer do?","options":["Celebrate the metric","Compare definitions and raw data across periods before concluding performance improved","Ignore all metrics","Use only the newest chart"]}'::jsonb,'1','A changed measurement definition can create an artificial improvement.',150),
('survival',5,2,'{"kind":"choice","prompt":"A person is accused based on an anonymous post. What is the fairest response?","options":["Repeat the accusation","Avoid amplifying it and require independently verifiable evidence","Assume it is true","Publish their details"]}'::jsonb,'1','Anonymous claims need verification; protect people from unsupported allegations.',150),
('survival',5,3,'{"kind":"choice","prompt":"An emergency plan depends on one communication channel that has failed before. What is the strongest improvement?","options":["Keep the plan unchanged","Add tested redundant channels and clear fallback ownership","Assume it will work","Wait for another failure"]}'::jsonb,'1','Resilience requires tested alternatives and clear responsibilities.',150),
('survival',5,4,'{"kind":"choice","prompt":"A proposed shortcut saves time but removes an audit trail. What should decide?","options":["Time saved only","Whether accountability and safety can be preserved with an approved alternative","Who suggested it","Whether the shortcut is common"]}'::jsonb,'1','Do not trade away essential accountability; use a controlled alternative.',150),
('survival',5,5,'{"kind":"choice","prompt":"A group must choose between a reversible delay and an irreversible action under uncertainty. What is generally safer?","options":["Irreversible action immediately","Prefer the reversible option while gathering decisive information, if delay is safe","Ignore uncertainty","Flip a coin"]}'::jsonb,'1','Preserving options is prudent when the cost of delay is acceptable.',150),
('daily',4,1,'{"kind":"choice","prompt":"A sequence multiplies by 2 then subtracts 1, repeatedly: 2,3,5,9,17,… What follows?","options":["31","32","33","34"]}'::jsonb,'2','17×2−1 = 33.',150),
('daily',4,2,'{"kind":"choice","prompt":"A fair die is rolled twice. Probability the total is 7?","options":["1/12","1/6","1/4","1/3"]}'::jsonb,'1','Six of 36 equally likely ordered outcomes total seven.',150),
('daily',4,3,'{"kind":"choice","prompt":"A price rises 15%, then falls 15%. Net result?","options":["No change","2.25% lower","2.25% higher","15% lower"]}'::jsonb,'1','1.15×0.85 = 0.9775, or 2.25% lower.',150),
('daily',4,4,'{"kind":"choice","prompt":"Five people each meet every other person once. How many unique meetings?","options":["5","10","15","20"]}'::jsonb,'1','5×4÷2 = 10 pairs.',150),
('daily',4,5,'{"kind":"choice","prompt":"A box has 4 red, 5 blue and 6 green tokens. Minimum draws to guarantee 3 of one colour?","options":["5","6","7","8"]}'::jsonb,'2','Worst case: take 2 of each colour (6), then the seventh makes a third of one colour.',150),
('daily',5,1,'{"kind":"choice","prompt":"A sequence adds consecutive squares: 1, 2, 6, 15, 31, … What comes next?","options":["46","55","67","71"]}'::jsonb,'2','Add 1², 2², 3², 4², 5², then 6²: 31+36 = 67.',150),
('daily',5,2,'{"kind":"choice","prompt":"A fair coin is tossed four times. Probability of all tails?","options":["1/8","1/12","1/16","1/4"]}'::jsonb,'2','Each toss has probability 1/2; (1/2)^4 = 1/16.',150),
('daily',5,3,'{"kind":"choice","prompt":"Two workers finish a task in 6 hours together. One alone takes 10 hours. How long for the other alone?","options":["12 hours","15 hours","18 hours","20 hours"]}'::jsonb,'1','Combined rate 1/6; first rate 1/10; second = 1/15.',150),
('daily',5,4,'{"kind":"choice","prompt":"A map scale is 1:50,000. A route measures 8 cm. Actual distance?","options":["0.4 km","4 km","40 km","400 km"]}'::jsonb,'1','8×50,000 cm = 400,000 cm = 4 km.',150),
('daily',5,5,'{"kind":"choice","prompt":"If the statement “If P then Q” is false, what must be true?","options":["P true and Q false","P false and Q true","Both true","Both false"]}'::jsonb,'0','A conditional is false only when its premise is true and conclusion false.',150)
on conflict(game_key,level_no,round_no) do update set payload=excluded.payload,answer_key=excluded.answer_key,explanation=excluded.explanation,points=excluded.points;


-- Improve the pre-existing Level 2/3 Last Lock clues without changing their codes or question order.
update public.nexora_level_question_bank set payload=jsonb_set(payload,'{clue}',to_jsonb('The first digit is 7 and the last is 4. The middle digits add to 8 and multiply to 12. The second digit is greater than the third.'::text)) where game_key='cipher' and level_no=2 and round_no=1;
update public.nexora_level_question_bank set payload=jsonb_set(payload,'{clue}',to_jsonb('The first digit is 4 and the last is 5. The middle digits add to 9 and multiply to 8. The second digit is greater than the third.'::text)) where game_key='cipher' and level_no=2 and round_no=2;
update public.nexora_level_question_bank set payload=jsonb_set(payload,'{clue}',to_jsonb('The first digit is 9 and the last is 1. The middle digits add to 8 and multiply to 15. The second digit is smaller than the third.'::text)) where game_key='cipher' and level_no=2 and round_no=3;
update public.nexora_level_question_bank set payload=jsonb_set(payload,'{clue}',to_jsonb('The first digit is 2 and the last is 8. The middle digits add to 6 and multiply to 0. The second digit is greater than the third.'::text)) where game_key='cipher' and level_no=2 and round_no=4;
update public.nexora_level_question_bank set payload=jsonb_set(payload,'{clue}',to_jsonb('The first digit is 8 and the last is 7. The middle digits add to 5 and multiply to 4. The second digit is smaller than the third.'::text)) where game_key='cipher' and level_no=2 and round_no=5;
update public.nexora_level_question_bank set payload=jsonb_set(payload,'{clue}',to_jsonb('The first digit is 5 and the last is 7. The middle digits add to 15 and multiply to 54. The second digit is greater than the third.'::text)) where game_key='cipher' and level_no=3 and round_no=1;
update public.nexora_level_question_bank set payload=jsonb_set(payload,'{clue}',to_jsonb('The first digit is 8 and the last is 2. The middle digits add to 10 and multiply to 24. The second digit is greater than the third.'::text)) where game_key='cipher' and level_no=3 and round_no=2;
update public.nexora_level_question_bank set payload=jsonb_set(payload,'{clue}',to_jsonb('The first digit is 1 and the last is 9. The middle digits add to 9 and multiply to 14. The second digit is greater than the third.'::text)) where game_key='cipher' and level_no=3 and round_no=3;
update public.nexora_level_question_bank set payload=jsonb_set(payload,'{clue}',to_jsonb('The first digit is 4 and the last is 3. The middle digits add to 6 and multiply to 0. The second digit is smaller than the third.'::text)) where game_key='cipher' and level_no=3 and round_no=4;
update public.nexora_level_question_bank set payload=jsonb_set(payload,'{clue}',to_jsonb('The first digit is 9 and the last is 4. The middle digits add to 10 and multiply to 16. The second digit is smaller than the third.'::text)) where game_key='cipher' and level_no=3 and round_no=5;

create or replace function public.nexora_set_ready(p_room_id uuid,p_ready boolean)
returns boolean language plpgsql security definer set search_path=public as $$
begin
 update public.nexora_room_players p set is_ready=p_ready from public.nexora_rooms r where p.room_id=p_room_id and p.user_id=auth.uid() and not p.is_spectator and r.id=p.room_id and r.status='waiting';
 if not found then raise exception 'You are not an active player in a waiting room.'; end if;
 update public.nexora_rooms set updated_at=now() where id=p_room_id;
 return true;
end $$;

create or replace function public.nexora_create_room_v2(p_game_key text default 'logic',p_capacity integer default 8,p_level_no integer default 1)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_room public.nexora_rooms; v_name text;
begin
 if v_uid is null then raise exception 'Sign in is required.'; end if;
 if p_game_key not in ('logic','case','cipher','impostor','survival','daily') then raise exception 'Choose a valid NEXORA game.'; end if;
 if p_capacity not in (8,20,30,50) then raise exception 'Choose a room size of 8, 20, 30 or 50 players.'; end if;
 if p_level_no not between 1 and 5 then raise exception 'Choose a valid level.'; end if;
 if p_level_no=1 and (select count(*) from public.nexora_question_bank where game_key=p_game_key)<>5 then raise exception 'This game has no complete five-question Level 1 pack.'; end if;
 if p_level_no>1 and (select count(*) from public.nexora_level_question_bank where game_key=p_game_key and level_no=p_level_no)<>5 then raise exception 'This game level has no complete five-question pack.'; end if;
 select coalesce(display_name,'Player') into v_name from public.player_profiles where user_id=v_uid;
 if v_name is null then v_name:='Player-'||upper(substr(v_uid::text,1,4)); end if;
 insert into public.nexora_rooms(room_code,host_id,game_key,capacity,level_no) values(upper(substr(replace(gen_random_uuid()::text,'-',''),1,6)),v_uid,p_game_key,p_capacity,p_level_no) returning * into v_room;
 insert into public.nexora_room_players(room_id,user_id,display_name,is_host,is_ready) values(v_room.id,v_uid,v_name,true,true);
 return jsonb_build_object('room_id',v_room.id,'room_code',v_room.room_code);
end $$;

create or replace function public.nexora_join_room(p_room_code text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_room public.nexora_rooms; v_name text; v_spectator boolean;
begin
 if v_uid is null then raise exception 'Sign in is required.'; end if;
 select * into v_room from public.nexora_rooms where room_code=upper(trim(p_room_code)) for update;
 if not found or v_room.status not in ('waiting','in_progress','completed') then raise exception 'Room code not found or room is closed.'; end if;
 select is_spectator into v_spectator from public.nexora_room_players where room_id=v_room.id and user_id=v_uid;
 if found then
   update public.nexora_room_players set last_seen_at=now(),voice_active=false,voice_updated_at=null,is_ready=case when v_room.status='waiting' then false else is_ready end where room_id=v_room.id and user_id=v_uid;
   update public.nexora_rooms set updated_at=now() where id=v_room.id;
   return jsonb_build_object('room_id',v_room.id,'room_code',v_room.room_code,'is_spectator',coalesce(v_spectator,false));
 end if;
 if v_room.status='waiting' and (select count(*) from public.nexora_room_players where room_id=v_room.id and not is_spectator)<v_room.capacity then
   v_spectator:=false;
 else
   if (select count(*) from public.nexora_room_players where room_id=v_room.id and is_spectator and last_seen_at>now()-interval '3 minutes')>=20 then raise exception 'This room has reached its spectator limit.'; end if;
   v_spectator:=true;
 end if;
 select display_name into v_name from public.player_profiles where user_id=v_uid;
 if v_name is null then v_name:='Player-'||upper(substr(v_uid::text,1,4)); end if;
 insert into public.nexora_room_players(room_id,user_id,display_name,is_spectator) values(v_room.id,v_uid,v_name,v_spectator) on conflict(room_id,user_id) do nothing;
 update public.nexora_rooms set updated_at=now() where id=v_room.id;
 return jsonb_build_object('room_id',v_room.id,'room_code',v_room.room_code,'is_spectator',v_spectator);
end $$;

create or replace function public.nexora_promote_spectator(p_room_id uuid,p_target_user_id uuid)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_room public.nexora_rooms;
begin
 select * into v_room from public.nexora_rooms where id=p_room_id for update;
 if not found or v_room.host_id<>auth.uid() then raise exception 'Only the host can promote spectators.'; end if;
 if v_room.status not in ('waiting','completed') then raise exception 'Spectators can be promoted between levels.'; end if;
 if (select count(*) from public.nexora_room_players where room_id=p_room_id and not is_spectator)>=v_room.capacity then raise exception 'The active player slots are full.'; end if;
 update public.nexora_room_players set is_spectator=false,is_ready=false,score=case when v_room.status='waiting' then 0 else score end,correct_count=case when v_room.status='waiting' then 0 else correct_count end where room_id=p_room_id and user_id=p_target_user_id and is_spectator=true and last_seen_at>now()-interval '3 minutes';
 if not found then raise exception 'Spectator not found.'; end if;
 update public.nexora_rooms set updated_at=now() where id=p_room_id;
 return true;
end $$;

create or replace function public.nexora_set_player_mute(p_room_id uuid,p_target_user_id uuid,p_muted boolean)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_room public.nexora_rooms;
begin
 select * into v_room from public.nexora_rooms where id=p_room_id;
 if not found or not exists(select 1 from public.nexora_room_players where room_id=p_room_id and user_id=auth.uid() and (is_host or is_moderator)) then raise exception 'Only the host or an appointed moderator can mute participants.'; end if;
 if p_target_user_id=auth.uid() then raise exception 'Use your own microphone control to mute yourself.'; end if;
 if exists(select 1 from public.nexora_room_players where room_id=p_room_id and user_id=p_target_user_id and (is_host or is_moderator)) and not exists(select 1 from public.nexora_room_players where room_id=p_room_id and user_id=auth.uid() and is_host) then raise exception 'Moderators cannot mute the host or another moderator.'; end if;
 update public.nexora_room_players set is_muted=p_muted where room_id=p_room_id and user_id=p_target_user_id and not is_spectator;
 if not found then raise exception 'Active participant not found.'; end if;
 update public.nexora_rooms set updated_at=now() where id=p_room_id;
 return true;
end $$;

create or replace function public.nexora_set_moderator(p_room_id uuid,p_target_user_id uuid,p_make_moderator boolean)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_room public.nexora_rooms;
begin
 select * into v_room from public.nexora_rooms where id=p_room_id;
 if not found or v_room.host_id<>auth.uid() then raise exception 'Only the room host can appoint moderators.'; end if;
 if p_target_user_id=auth.uid() then raise exception 'The room host already has full controls.'; end if;
 update public.nexora_room_players set is_moderator=p_make_moderator where room_id=p_room_id and user_id=p_target_user_id and not is_spectator and last_seen_at>now()-interval '3 minutes';
 if not found then raise exception 'Connected active participant not found.'; end if;
 update public.nexora_rooms set updated_at=now() where id=p_room_id;
 return true;
end $$;

create or replace function public.nexora_set_all_muted(p_room_id uuid,p_muted boolean)
returns integer language plpgsql security definer set search_path=public as $$
declare v_room public.nexora_rooms; v_count integer;
begin
 select * into v_room from public.nexora_rooms where id=p_room_id;
 if not found or v_room.host_id<>auth.uid() then raise exception 'Only the room host can mute everyone.'; end if;
 update public.nexora_room_players set is_muted=p_muted where room_id=p_room_id and not is_spectator;
 get diagnostics v_count=row_count;
 update public.nexora_rooms set updated_at=now() where id=p_room_id;
 return v_count;
end $$;

create or replace function public.nexora_set_voice_active(p_room_id uuid,p_active boolean)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_count integer;
begin
 if v_uid is null or not exists(select 1 from public.nexora_room_players where room_id=p_room_id and user_id=v_uid and not is_spectator) then raise exception 'Active players only can join voice.'; end if;
 if p_active then
   update public.nexora_room_players set voice_active=false,voice_updated_at=null where room_id=p_room_id and voice_active and voice_updated_at<now()-interval '90 seconds';
   select count(*) into v_count from public.nexora_room_players where room_id=p_room_id and voice_active and user_id<>v_uid;
   if v_count>=8 then raise exception 'All 8 voice places are currently occupied. Ask the host to free a voice place.'; end if;
   update public.nexora_room_players set voice_active=true,voice_updated_at=now() where room_id=p_room_id and user_id=v_uid;
   update public.nexora_rooms set updated_at=now() where id=p_room_id;
 else
   update public.nexora_room_players set voice_active=false,voice_updated_at=null where room_id=p_room_id and user_id=v_uid;
   update public.nexora_rooms set updated_at=now() where id=p_room_id;
 end if;
 return true;
end $$;

create or replace function public.nexora_room_heartbeat(p_room_id uuid)
returns boolean language plpgsql security definer set search_path=public as $$
begin
 update public.nexora_room_players set last_seen_at=now() where room_id=p_room_id and user_id=auth.uid();
 return found;
end $$;

create or replace function public.nexora_voice_heartbeat(p_room_id uuid)
returns boolean language plpgsql security definer set search_path=public as $$
begin
 update public.nexora_room_players set voice_updated_at=now() where room_id=p_room_id and user_id=auth.uid() and voice_active=true;
 return found;
end $$;

create or replace function public.nexora_leave_room(p_room_id uuid)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_host uuid; v_new_host uuid;
begin
 select host_id into v_host from public.nexora_rooms where id=p_room_id for update;
 if not found then return true; end if;
 update public.nexora_room_players set last_seen_at=now()-interval '4 minutes',voice_active=false,voice_updated_at=null where room_id=p_room_id and user_id=auth.uid();
 if v_host=auth.uid() then
   select user_id into v_new_host from public.nexora_room_players where room_id=p_room_id and user_id<>auth.uid() and not is_spectator and last_seen_at>now()-interval '3 minutes' order by joined_at limit 1;
   if v_new_host is not null then
     update public.nexora_rooms set host_id=v_new_host,updated_at=now() where id=p_room_id;
     update public.nexora_room_players set is_host=(user_id=v_new_host),is_moderator=false where room_id=p_room_id;
   else
     update public.nexora_rooms set updated_at=now() where id=p_room_id;
   end if;
 else
   update public.nexora_rooms set updated_at=now() where id=p_room_id;
 end if;
 return true;
end $$;

create or replace function public.nexora_get_room(p_room_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room public.nexora_rooms; v_players jsonb; v_new_host uuid;
begin
 select * into v_room from public.nexora_rooms where id=p_room_id;
 if not found or not exists(select 1 from public.nexora_room_players where room_id=p_room_id and user_id=auth.uid()) then raise exception 'Room not found or access denied.'; end if;
 if exists(select 1 from public.nexora_room_players where room_id=p_room_id and user_id=v_room.host_id and last_seen_at<now()-interval '3 minutes') then
   select user_id into v_new_host from public.nexora_room_players where room_id=p_room_id and not is_spectator and user_id<>v_room.host_id and last_seen_at>now()-interval '3 minutes' order by joined_at limit 1;
   if v_new_host is not null then update public.nexora_rooms set host_id=v_new_host,updated_at=now() where id=p_room_id; update public.nexora_room_players set is_host=(user_id=v_new_host),is_moderator=case when user_id=v_new_host then false else is_moderator end where room_id=p_room_id; select * into v_room from public.nexora_rooms where id=p_room_id; end if;
 end if;
 select coalesce(jsonb_agg(jsonb_build_object('user_id',p.user_id,'display_name',p.display_name,'is_host',p.is_host,'is_ready',p.is_ready,'score',case when v_room.status='completed' then p.score else null end,'correct_count',case when v_room.status='completed' then p.correct_count else null end,'is_spectator',p.is_spectator,'is_muted',p.is_muted,'is_moderator',p.is_moderator,'voice_active',p.voice_active,'is_connected',p.last_seen_at>now()-interval '3 minutes','avatar_url',pr.avatar_url) order by p.joined_at),'[]'::jsonb) into v_players from public.nexora_room_players p left join public.player_profiles pr on pr.user_id=p.user_id where p.room_id=p_room_id;
 return jsonb_build_object('id',v_room.id,'room_code',v_room.room_code,'game_key',v_room.game_key,'level_no',v_room.level_no,'capacity',v_room.capacity,'status',v_room.status,'current_round',v_room.current_round,'is_host',v_room.host_id=auth.uid(),'players',v_players);
end $$;

create or replace function public.nexora_start_room(p_room_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room public.nexora_rooms; v_count integer; v_ready integer; v_rounds integer;
begin
 select * into v_room from public.nexora_rooms where id=p_room_id for update;
 if not found or v_room.host_id<>auth.uid() then raise exception 'Only the room host can start this match.'; end if;
 if v_room.status<>'waiting' then raise exception 'This room is not waiting.'; end if;
 select count(*),count(*) filter(where is_ready) into v_count,v_ready from public.nexora_room_players where room_id=p_room_id and not is_spectator and last_seen_at>now()-interval '3 minutes';
 if v_count<2 then raise exception 'At least two active players must join.'; end if;
 if v_count<>v_ready then raise exception 'Every active player must be ready before the host starts.'; end if;
 if v_room.level_no=1 then select count(*) into v_rounds from public.nexora_question_bank where game_key=v_room.game_key;
 else select count(*) into v_rounds from public.nexora_level_question_bank where game_key=v_room.game_key and level_no=v_room.level_no; end if;
 if v_rounds<>5 then raise exception 'This game level must contain exactly five published rounds.'; end if;
 update public.nexora_rooms set status='in_progress',current_round=1,started_at=now(),ended_at=null,updated_at=now() where id=p_room_id;
 return public.nexora_get_room(p_room_id);
end $$;

create or replace function public.nexora_get_round(p_room_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room public.nexora_rooms; v_payload jsonb; v_answered boolean; v_total integer; v_spectator boolean;
begin
 select * into v_room from public.nexora_rooms where id=p_room_id;
 if not found or v_room.status not in ('in_progress','completed') then raise exception 'No active match found.'; end if;
 select is_spectator into v_spectator from public.nexora_room_players where room_id=p_room_id and user_id=auth.uid();
 if not found then raise exception 'You are not a member of this room.'; end if;
 if v_room.status='completed' then return jsonb_build_object('complete',true,'round',v_room.current_round,'is_spectator',coalesce(v_spectator,false)); end if;
 if v_room.level_no=1 then select payload into v_payload from public.nexora_question_bank where game_key=v_room.game_key and round_no=v_room.current_round;
 else select payload into v_payload from public.nexora_level_question_bank where game_key=v_room.game_key and level_no=v_room.level_no and round_no=v_room.current_round; end if;
 if v_payload is null then return jsonb_build_object('complete',true,'round',v_room.current_round,'is_spectator',coalesce(v_spectator,false)); end if;
 if v_room.level_no=1 then select count(*) into v_total from public.nexora_question_bank where game_key=v_room.game_key; else select count(*) into v_total from public.nexora_level_question_bank where game_key=v_room.game_key and level_no=v_room.level_no; end if;
 select exists(select 1 from public.nexora_answers where room_id=p_room_id and round_no=v_room.current_round and user_id=auth.uid()) into v_answered;
 return jsonb_build_object('complete',false,'round',v_room.current_round,'total_rounds',v_total,'payload',v_payload,'already_answered',v_answered,'can_advance',((select count(*) from public.nexora_answers a join public.nexora_room_players p on p.room_id=a.room_id and p.user_id=a.user_id where a.room_id=p_room_id and a.round_no=v_room.current_round and not p.is_spectator and p.last_seen_at>now()-interval '3 minutes')=(select count(*) from public.nexora_room_players where room_id=p_room_id and not is_spectator and last_seen_at>now()-interval '3 minutes')),'is_host',v_room.host_id=auth.uid(),'is_spectator',coalesce(v_spectator,false));
end $$;

create or replace function public.nexora_submit_answer(p_room_id uuid,p_answer text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room public.nexora_rooms; v_payload jsonb; v_key text; v_explanation text; v_points integer; v_ok boolean; v_award integer; v_exact integer:=0; v_near integer:=0; v_feedback text; i integer;
begin
 select * into v_room from public.nexora_rooms where id=p_room_id for update;
 if not found or v_room.status<>'in_progress' then raise exception 'The match is not accepting answers.'; end if;
 if not exists(select 1 from public.nexora_room_players where room_id=p_room_id and user_id=auth.uid() and not is_spectator) then raise exception 'Spectators cannot submit answers. Wait for the next level.'; end if;
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
 select count(*) into v_players from public.nexora_room_players where room_id=p_room_id and not is_spectator and last_seen_at>now()-interval '3 minutes';
 select count(*) into v_answered from public.nexora_answers a join public.nexora_room_players p on p.room_id=a.room_id and p.user_id=a.user_id where a.room_id=p_room_id and a.round_no=v_room.current_round and not p.is_spectator and p.last_seen_at>now()-interval '3 minutes';
 if v_answered<v_players then raise exception 'Wait until every active player has submitted an answer.'; end if;
 if v_room.level_no=1 then select count(*) into v_total from public.nexora_question_bank where game_key=v_room.game_key; else select count(*) into v_total from public.nexora_level_question_bank where game_key=v_room.game_key and level_no=v_room.level_no; end if;
 if v_room.current_round>=v_total then update public.nexora_rooms set status='completed',ended_at=now(),updated_at=now() where id=p_room_id; else update public.nexora_rooms set current_round=current_round+1,updated_at=now() where id=p_room_id; end if;
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
 if v_game not in ('logic','case','cipher','impostor','survival','daily') or v_level not between 1 and 5 then raise exception 'Choose a valid game and level.'; end if;
 if v_level=1 then if (select count(*) from public.nexora_question_bank where game_key=v_game)<>5 then raise exception 'This game has no complete five-question level.'; end if;
 else if (select count(*) from public.nexora_level_question_bank where game_key=v_game and level_no=v_level)<>5 then raise exception 'This game level has no complete five-question pack.'; end if; end if;
 delete from public.nexora_answers where room_id=p_room_id;
 update public.nexora_room_players set is_spectator=true,is_ready=false,voice_active=false,voice_updated_at=null where room_id=p_room_id and not is_spectator and user_id<>auth.uid() and last_seen_at<now()-interval '3 minutes';
 update public.nexora_room_players set score=0,correct_count=0,is_ready=(user_id=auth.uid()),is_muted=false,voice_active=false,voice_updated_at=null where room_id=p_room_id and not is_spectator;
 update public.nexora_rooms set game_key=v_game,level_no=v_level,status='waiting',current_round=0,started_at=null,ended_at=null,updated_at=now() where id=p_room_id;
 return public.nexora_get_room(p_room_id);
end $$;

revoke all on function public.nexora_create_room_v2(text,integer,integer) from public,anon;
revoke all on function public.nexora_join_room(text) from public,anon;
revoke all on function public.nexora_promote_spectator(uuid,uuid) from public,anon;
revoke all on function public.nexora_set_player_mute(uuid,uuid,boolean) from public,anon;
revoke all on function public.nexora_set_moderator(uuid,uuid,boolean) from public,anon;
revoke all on function public.nexora_set_voice_active(uuid,boolean) from public,anon;
revoke all on function public.nexora_room_heartbeat(uuid) from public,anon;
revoke all on function public.nexora_set_all_muted(uuid,boolean) from public,anon;
revoke all on function public.nexora_voice_heartbeat(uuid) from public,anon;
revoke all on function public.nexora_get_room(uuid) from public,anon;
revoke all on function public.nexora_start_room(uuid) from public,anon;
revoke all on function public.nexora_get_round(uuid) from public,anon;
revoke all on function public.nexora_submit_answer(uuid,text) from public,anon;
revoke all on function public.nexora_advance_round(uuid) from public,anon;
revoke all on function public.nexora_next_match(uuid,text,integer) from public,anon;
grant execute on function public.nexora_create_room_v2(text,integer,integer) to authenticated;
grant execute on function public.nexora_join_room(text) to authenticated;
grant execute on function public.nexora_promote_spectator(uuid,uuid) to authenticated;
grant execute on function public.nexora_set_player_mute(uuid,uuid,boolean) to authenticated;
grant execute on function public.nexora_set_moderator(uuid,uuid,boolean) to authenticated;
grant execute on function public.nexora_set_voice_active(uuid,boolean) to authenticated;
grant execute on function public.nexora_room_heartbeat(uuid) to authenticated;
grant execute on function public.nexora_set_all_muted(uuid,boolean) to authenticated;
grant execute on function public.nexora_voice_heartbeat(uuid) to authenticated;
grant execute on function public.nexora_get_room(uuid) to authenticated;
grant execute on function public.nexora_start_room(uuid) to authenticated;
grant execute on function public.nexora_get_round(uuid) to authenticated;
grant execute on function public.nexora_submit_answer(uuid,text) to authenticated;
grant execute on function public.nexora_advance_round(uuid) to authenticated;
grant execute on function public.nexora_next_match(uuid,text,integer) to authenticated;

commit;
