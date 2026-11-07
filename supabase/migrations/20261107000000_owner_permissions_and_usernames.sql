alter table public.app_members
  add column if not exists username text,
  add column if not exists discord_id text;

alter table public.app_members
  drop constraint if exists app_members_role_check;

alter table public.app_members
  add constraint app_members_role_check check (role in ('owner', 'admin', 'member'));

create unique index if not exists app_members_username_ci_idx
  on public.app_members (lower(username))
  where username is not null;

create or replace function public.validate_app_member_username()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
declare auth_email text;
begin
  select lower(email) into auth_email
  from auth.users
  where id = new.user_id;

  if auth_email is distinct from (lower(new.username) || '@users.retro-roleplay.invalid') then
    raise exception 'app_member_auth_email_mismatch';
  end if;
  return new;
end;
$$;

drop trigger if exists app_members_validate_username on public.app_members;
create trigger app_members_validate_username
  before insert or update of user_id, username on public.app_members
  for each row execute function public.validate_app_member_username();

create or replace function public.is_app_owner()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1
    from public.app_members
    where user_id = auth.uid()
      and active
      and role = 'owner'
      and discord_id = '1434906594742632603'
  )
$$;

drop policy if exists app_members_read_self on public.app_members;
create policy app_members_read_self on public.app_members
  for select to authenticated
  using (user_id = auth.uid() or public.is_app_owner());

drop policy if exists app_members_admin_write on public.app_members;
create policy app_members_owner_insert on public.app_members
  for insert to authenticated
  with check (
    public.is_app_owner()
    and role = 'member'
    and active
    and username ~ '^[a-z0-9][a-z0-9._-]{2,31}$'
  );

create policy app_members_owner_update on public.app_members
  for update to authenticated
  using (public.is_app_owner() and user_id <> auth.uid())
  with check (
    public.is_app_owner()
    and role = 'member'
    and active
    and username ~ '^[a-z0-9][a-z0-9._-]{2,31}$'
  );

create policy app_members_owner_delete on public.app_members
  for delete to authenticated
  using (public.is_app_owner() and user_id <> auth.uid());
