-- Atomare RPCs für die Wahlgang-Übergänge.
-- Jede Funktion ersetzt mehrere sequentielle UPDATEs durch einen
-- einzigen Round-Trip und reduziert so spürbar die Wartezeit
-- zwischen Klick und Animation.
--
-- In Supabase ausführen: SQL Editor -> neue Query -> diesen Block ausführen.

-- ---------------------------------------------------------------
-- open_voting: Wahlgang öffnen (Status open, Results unsichtbar, Validity reset)
-- ---------------------------------------------------------------
create or replace function public.open_voting(p_session_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.vote_sessions
    set status = 'open',
        results_visible = false,
        is_valid = null
    where id = p_session_id;
$$;

grant execute on function public.open_voting(uuid) to authenticated;

-- ---------------------------------------------------------------
-- close_voting: Wahlgang schließen (Status closed, Results unsichtbar)
-- ---------------------------------------------------------------
create or replace function public.close_voting(p_session_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.vote_sessions
    set status = 'closed',
        results_visible = false
    where id = p_session_id;
$$;

grant execute on function public.close_voting(uuid) to authenticated;
