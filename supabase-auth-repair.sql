-- Einmalig im Supabase SQL Editor ausfuehren, wenn die Logins noch nicht funktionieren.
-- Die Passwoerter werden als bcrypt-Hash gespeichert. confirmed_at wird nicht gesetzt,
-- weil diese Spalte in aktuellen Supabase-Versionen automatisch generiert wird.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username = lower(username) and length(username) between 3 and 40),
  login_email text not null unique,
  role text not null default 'user' check (role in ('user', 'admin')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.profiles add column if not exists login_email text;

create or replace function public.resolve_login_email(p_username text)
returns text
language sql
security definer
set search_path = public
as $$
  select login_email
  from public.profiles
  where username = lower(trim(p_username));
$$;

grant execute on function public.resolve_login_email(text) to anon, authenticated;

drop policy if exists profile_self_read on public.profiles;
create policy profile_self_read on public.profiles
  for select to authenticated
  using (id = auth.uid());

do $$
declare
  account_id uuid;
begin
  select id into account_id from auth.users where email in ('s.barbosa.galaxy@gmail.com', 'santobarbosa@login.nexora-farming.com', 'santobarbosa@login.gnadental.local') limit 1;
  if account_id is null then
    account_id := gen_random_uuid();
    insert into auth.users(instance_id, id, email, encrypted_password, email_confirmed_at, confirmation_token, recovery_token, email_change, email_change_token_new, raw_app_meta_data, raw_user_meta_data, aud, role)
      values ('00000000-0000-0000-0000-000000000000', account_id, 's.barbosa.galaxy@gmail.com', crypt('MozaGeswalriga.06', gen_salt('bf')), now(), '', '', '', '', '{"provider":"email","providers":["email"]}'::jsonb, '{"username":"santobarbosa"}'::jsonb, 'authenticated', 'authenticated');
  else
    update auth.users
      set email = 's.barbosa.galaxy@gmail.com',
          encrypted_password = crypt('MozaGeswalriga.06', gen_salt('bf')),
          email_confirmed_at = coalesce(email_confirmed_at, now()),
          deleted_at = null
      where id = account_id;
  end if;

  insert into public.profiles(id, username, login_email, role)
    values (account_id, 'santobarbosa', 's.barbosa.galaxy@gmail.com', 'admin')
    on conflict (username) do update set id = excluded.id, login_email = excluded.login_email, role = 'admin';
end;
$$;

select id, email, email_confirmed_at
from auth.users
where email = 's.barbosa.galaxy@gmail.com';

select id, username, role
from public.profiles
where username = 'santobarbosa';
