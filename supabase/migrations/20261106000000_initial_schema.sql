create extension if not exists pgcrypto;

create table if not exists public.app_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('admin', 'member')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create or replace function public.is_app_member()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from public.app_members where user_id = auth.uid() and active)
$$;

create or replace function public.is_app_admin()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from public.app_members where user_id = auth.uid() and active and role = 'admin')
$$;

create table if not exists public.families (
  id text primary key default gen_random_uuid()::text,
  name text not null,
  hometown text,
  route text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.persons (
  id text primary key default gen_random_uuid()::text,
  first_name text not null default '',
  last_name text not null default '',
  full_name text,
  nickname text,
  birth_date date,
  gender text,
  phone text,
  phone_secondary text,
  discord_name text,
  discord_id text,
  other_contact text,
  residence text,
  origin text,
  occupation text,
  employer text,
  marital_status text,
  description text,
  vehicle text,
  plate text,
  other_phones jsonb not null default '[]'::jsonb,
  discord_contacts jsonb not null default '[]'::jsonb,
  known_nicknames jsonb not null default '[]'::jsonb,
  special_events jsonb not null default '[]'::jsonb,
  internal_info text,
  historical_info text,
  other_remarks text,
  legacy_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.members (
  id text primary key default gen_random_uuid()::text,
  person_id text references public.persons(id) on delete set null,
  family_id text references public.families(id) on delete set null,
  name text not null,
  rank text,
  phone text,
  joined date,
  status text,
  contact text,
  legacy_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.phonebook (
  id text primary key default gen_random_uuid()::text,
  person_id text references public.persons(id) on delete set null,
  family_id text references public.families(id) on delete set null,
  first_name text not null default '',
  last_name text not null default '',
  phone text,
  family_name text,
  notes text,
  legacy_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.family_memberships (
  id text primary key default gen_random_uuid()::text,
  person_id text not null references public.persons(id) on delete cascade,
  family_id text not null references public.families(id) on delete restrict,
  joined_at date,
  left_at date,
  rank text,
  status text not null default 'current',
  exit_reason text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (left_at is null or joined_at is null or left_at >= joined_at)
);

create table if not exists public.tasks (
  id text primary key default gen_random_uuid()::text,
  title text not null,
  owner_id text references public.members(id) on delete set null,
  owner_name text,
  due date,
  priority text,
  status text,
  legacy_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.finances (
  id text primary key default gen_random_uuid()::text,
  label text not null,
  type text not null,
  amount numeric(14,2) not null default 0,
  category text,
  booked_at date,
  legacy_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.credits (
  id text primary key default gen_random_uuid()::text,
  borrower_id text references public.persons(id) on delete set null,
  borrower text,
  amount numeric(14,2) not null default 0,
  reason text,
  booked_at date,
  due date,
  status text,
  legacy_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.storage_items (
  id text primary key default gen_random_uuid()::text,
  name text not null,
  quantity numeric(14,2) not null default 0,
  category text,
  location text,
  legacy_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.equipment_issues (
  id text primary key default gen_random_uuid()::text,
  item text not null,
  recipient_id text references public.members(id) on delete set null,
  recipient text,
  quantity numeric(14,2) not null default 1,
  issued_at date,
  due date,
  returned boolean not null default false,
  legacy_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.person_family_history (
  id text primary key default gen_random_uuid()::text,
  person_id text not null references public.persons(id) on delete cascade,
  family_id text references public.families(id) on delete set null,
  family_name text not null,
  joined_at date,
  left_at date,
  rank text,
  status text not null default 'current',
  exit_reason text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (left_at is null or joined_at is null or left_at >= joined_at)
);

create table if not exists public.person_job_history (
  id text primary key default gen_random_uuid()::text,
  person_id text not null references public.persons(id) on delete cascade,
  job text not null,
  employer text,
  started_at date,
  ended_at date,
  is_current boolean not null default false,
  position text,
  description text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ended_at is null or started_at is null or ended_at >= started_at)
);

create table if not exists public.person_relationships (
  id text primary key default gen_random_uuid()::text,
  person_id text not null references public.persons(id) on delete cascade,
  related_person_id text not null references public.persons(id) on delete cascade,
  relationship_type text not null,
  inverse_type text,
  started_at date,
  ended_at date,
  is_current boolean not null default true,
  description text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (person_id <> related_person_id),
  check (ended_at is null or started_at is null or ended_at >= started_at)
);

create table if not exists public.person_marriages (
  id text primary key default gen_random_uuid()::text,
  person_id text not null references public.persons(id) on delete cascade,
  spouse_id text not null references public.persons(id) on delete cascade,
  wedding_date date,
  location text,
  divorce_date date,
  status text not null default 'current',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (person_id <> spouse_id)
);

create table if not exists public.person_notes (
  id text primary key default gen_random_uuid()::text,
  person_id text not null references public.persons(id) on delete cascade,
  note_type text not null default 'general',
  body text not null,
  occurred_at date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.appointments (
  id text primary key default gen_random_uuid()::text,
  title text not null,
  event_date date,
  event_time time,
  location text,
  type text,
  legacy_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.routes (
  id text primary key default gen_random_uuid()::text,
  route_code text,
  name text not null,
  description text,
  location text,
  address text,
  coordinates jsonb,
  postal_code text,
  category text,
  status text,
  responsible_family_id text references public.families(id) on delete set null,
  responsible_person_id text references public.persons(id) on delete set null,
  notes text,
  legacy_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.route_images (
  id text primary key default gen_random_uuid()::text,
  route_id text not null references public.routes(id) on delete cascade,
  bucket_id text not null default 'route-images',
  object_path text not null,
  image_type text not null default 'other',
  caption text,
  created_at timestamptz not null default now(),
  unique (bucket_id, object_path)
);

create table if not exists public.route_npcs (
  id text primary key default gen_random_uuid()::text,
  route_id text not null references public.routes(id) on delete cascade,
  name text not null,
  location text,
  coordinates jsonb,
  description text,
  image_id text references public.route_images(id) on delete set null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.route_prices (
  route_id text primary key references public.routes(id) on delete cascade,
  purchase_total numeric(14,2),
  purchase_unit_price numeric(14,2),
  purchase_quantity numeric(14,3),
  purchase_unit text,
  process_input_quantity numeric(14,3),
  processor_fee numeric(14,2),
  finished_quantity numeric(14,3),
  selling_unit_price numeric(14,2),
  selling_unit text,
  other_fees numeric(14,2),
  updated_at timestamptz not null default now()
);

create table if not exists public.route_family_history (
  id text primary key default gen_random_uuid()::text,
  route_id text not null references public.routes(id) on delete cascade,
  family_id text references public.families(id) on delete set null,
  family_name text not null,
  responsible_person_id text references public.persons(id) on delete set null,
  taken_over_at date,
  handed_over_at date,
  reason text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.route_buying_families (
  id text primary key default gen_random_uuid()::text,
  route_id text not null references public.routes(id) on delete cascade,
  family_id text references public.families(id) on delete set null,
  family_name text not null,
  contact_person_id text references public.persons(id) on delete set null,
  contact_name text,
  phone text,
  started_at date,
  ended_at date,
  status text not null default 'unknown',
  notes text,
  created_at timestamptz not null default now(),
  check (ended_at is null or started_at is null or ended_at >= started_at)
);

create table if not exists public.workspace_state (
  id text primary key default 'retro-roleplay',
  data jsonb not null,
  revision bigint not null default 1,
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);

create or replace function public.save_workspace_state(p_data jsonb, p_expected_revision bigint)
returns public.workspace_state language plpgsql security definer set search_path = public, pg_temp as $$
declare current_row public.workspace_state;
begin
  if not public.is_app_member() then raise exception 'not_authorized'; end if;
  select * into current_row from public.workspace_state where id = 'retro-roleplay' for update;
  if not found then
    if p_expected_revision <> 0 then raise exception 'stale_revision'; end if;
    insert into public.workspace_state(id, data, revision, updated_by)
      values ('retro-roleplay', p_data, 1, auth.uid()) returning * into current_row;
    return current_row;
  end if;
  if current_row.revision <> p_expected_revision then raise exception 'stale_revision'; end if;
  update public.workspace_state set data = p_data, revision = revision + 1,
    updated_by = auth.uid(), updated_at = now()
    where id = 'retro-roleplay' returning * into current_row;
  return current_row;
end;
$$;

create table if not exists public.schema_migrations (
  version text primary key,
  applied_at timestamptz not null default now()
);
insert into public.schema_migrations(version) values ('20261106000000_initial_schema') on conflict (version) do nothing;

alter table public.app_members enable row level security;
create policy app_members_read_self on public.app_members for select to authenticated using (user_id = auth.uid() or public.is_app_admin());
create policy app_members_admin_write on public.app_members for all to authenticated using (public.is_app_admin()) with check (public.is_app_admin());

-- All application records are private to explicitly allow-listed, active users.
do $$
declare table_name text;
begin
  foreach table_name in array array[
    'families','persons','members','phonebook','family_memberships','tasks','finances','credits',
    'storage_items','equipment_issues','person_family_history','person_job_history','person_relationships',
    'person_marriages','person_notes','appointments','routes','route_images','route_npcs','route_prices',
    'route_family_history','route_buying_families','workspace_state','schema_migrations'
  ] loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format('create policy %I on public.%I for all to authenticated using (public.is_app_member()) with check (public.is_app_member())', table_name || '_member_access', table_name);
  end loop;
end $$;

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('route-images', 'route-images', false, 10485760, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = false;

create policy route_images_member_read on storage.objects for select to authenticated
using (bucket_id = 'route-images' and public.is_app_member());
create policy route_images_member_insert on storage.objects for insert to authenticated
with check (bucket_id = 'route-images' and public.is_app_member());
create policy route_images_member_update on storage.objects for update to authenticated
using (bucket_id = 'route-images' and public.is_app_member())
with check (bucket_id = 'route-images' and public.is_app_member());
create policy route_images_member_delete on storage.objects for delete to authenticated
using (bucket_id = 'route-images' and public.is_app_member());

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'workspace_state'
     ) then
    alter publication supabase_realtime add table public.workspace_state;
  end if;
end $$;
