-- Einmalig im Supabase SQL Editor ausfuehren, wenn die Logins noch nicht funktionieren.
-- Die Passwoerter werden als bcrypt-Hash gespeichert. confirmed_at wird nicht gesetzt,
-- weil diese Spalte in aktuellen Supabase-Versionen automatisch generiert wird.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username = lower(username) and length(username) between 3 and 40),
  role text not null default 'user' check (role in ('user', 'admin')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

do $$
declare
  account_id uuid;
begin
  select id into account_id from auth.users where email in ('santobarbosa@login.nexora-farming.com', 'santobarbosa@login.gnadental.local') limit 1;
  if account_id is null then
    account_id := gen_random_uuid();
    insert into auth.users(id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
      values (account_id, 'santobarbosa@login.nexora-farming.com', crypt('MozaGeswalriga.06', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"username":"santobarbosa"}'::jsonb, 'authenticated', 'authenticated');
  else
    update auth.users
      set email = 'santobarbosa@login.nexora-farming.com',
          encrypted_password = crypt('MozaGeswalriga.06', gen_salt('bf')),
          email_confirmed_at = coalesce(email_confirmed_at, now()),
          deleted_at = null
      where id = account_id;
  end if;

  insert into public.profiles(id, username, role)
    values (account_id, 'santobarbosa', 'admin')
    on conflict (username) do update set id = excluded.id, role = 'admin';
end;
$$;

select id, email, email_confirmed_at
from auth.users
where email = 'santobarbosa@login.nexora-farming.com';

select id, username, role
from public.profiles
where username = 'santobarbosa';
