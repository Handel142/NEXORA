-- NEXORA THE MIND TRAP: room-code generation hotfix
-- Run this in Supabase SQL Editor on the EXISTING project.
-- It replaces the room-creation RPC without relying on an extension-specific function.
-- PostgreSQL's built-in gen_random_uuid() is used instead.

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
 insert into public.nexora_rooms(room_code,host_id,game_key,capacity,level_no) values(upper(substr(replace(gen_random_uuid()::text,'-',''),1,6)),v_uid,p_game_key,p_capacity,p_level_no) returning * into v_room;
 insert into public.nexora_room_players(room_id,user_id,display_name,is_host,is_ready) values(v_room.id,v_uid,v_name,true,true);
 return jsonb_build_object('room_id',v_room.id,'room_code',v_room.room_code);
end $$;

