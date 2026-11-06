create table if not exists public.workspace_deletions (
  id bigint generated always as identity primary key,
  collection text not null,
  record_id text not null,
  deleted_by uuid references auth.users(id),
  deleted_at timestamptz not null default now(),
  record_snapshot jsonb not null
);

alter table public.workspace_deletions enable row level security;
create policy workspace_deletions_member_read on public.workspace_deletions
  for select to authenticated using (public.is_app_member());

create index if not exists persons_name_search_idx on public.persons (lower(first_name), lower(last_name));
create index if not exists family_history_name_idx on public.person_family_history (lower(family_name), person_id);
create index if not exists job_history_name_idx on public.person_job_history (lower(job), person_id);
create index if not exists routes_postal_location_idx on public.routes (postal_code, lower(location));

create or replace function public.mirror_workspace_state()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
declare
  item jsonb;
  person_item jsonb;
  family_item jsonb;
  job_item jsonb;
  relation_item jsonb;
  marriage_item jsonb;
  note_item jsonb;
  route_item jsonb;
  child_item jsonb;
  collection_name text;
begin
  for item in select value from jsonb_array_elements(coalesce(new.data->'families','[]'::jsonb)) loop
    insert into public.families(id,name,hometown,route,notes)
    values(item->>'id',coalesce(item->>'name',''),item->>'hometown',item->>'route',item->>'notes')
    on conflict(id) do update set name=excluded.name,hometown=excluded.hometown,route=excluded.route,notes=excluded.notes,updated_at=now();
  end loop;
  if nullif(new.data->>'family','') is not null and not exists(select 1 from public.families where lower(name)=lower(new.data->>'family')) then
    insert into public.families(id,name,hometown,route)
    values('family-retro-roleplay',new.data->>'family',new.data#>>'{familyInfo,hometown}',new.data#>>'{familyInfo,route}')
    on conflict(id) do update set name=excluded.name,hometown=excluded.hometown,route=excluded.route,updated_at=now();
  end if;

  for person_item in select value from jsonb_array_elements(coalesce(new.data->'persons','[]'::jsonb)) loop
    insert into public.persons(id,first_name,last_name,full_name,nickname,birth_date,gender,phone,phone_secondary,discord_name,discord_id,other_contact,residence,origin,occupation,employer,marital_status,description,vehicle,plate,other_phones,discord_contacts,known_nicknames,special_events,internal_info,historical_info,other_remarks,legacy_data)
    values(person_item->>'id',coalesce(person_item->>'firstName',''),coalesce(person_item->>'lastName',''),person_item->>'fullName',person_item->>'nickname',nullif(person_item->>'birthDate','')::date,person_item->>'gender',person_item->>'phone',person_item->>'phoneSecondary',person_item->>'discordName',person_item->>'discordId',person_item->>'otherContact',person_item->>'residence',person_item->>'origin',person_item->>'occupation',person_item->>'employer',person_item->>'maritalStatus',person_item->>'description',person_item->>'vehicle',person_item->>'plate',coalesce(person_item->'otherPhones','[]'::jsonb),coalesce(person_item->'discordContacts','[]'::jsonb),coalesce(person_item->'knownNicknames','[]'::jsonb),coalesce(person_item->'specialEvents','[]'::jsonb),person_item->>'internalInfo',person_item->>'historicalInfo',person_item->>'otherRemarks',person_item)
    on conflict(id) do update set first_name=excluded.first_name,last_name=excluded.last_name,full_name=excluded.full_name,nickname=excluded.nickname,birth_date=excluded.birth_date,gender=excluded.gender,phone=excluded.phone,phone_secondary=excluded.phone_secondary,discord_name=excluded.discord_name,discord_id=excluded.discord_id,other_contact=excluded.other_contact,residence=excluded.residence,origin=excluded.origin,occupation=excluded.occupation,employer=excluded.employer,marital_status=excluded.marital_status,description=excluded.description,vehicle=excluded.vehicle,plate=excluded.plate,other_phones=excluded.other_phones,discord_contacts=excluded.discord_contacts,known_nicknames=excluded.known_nicknames,special_events=excluded.special_events,internal_info=excluded.internal_info,historical_info=excluded.historical_info,other_remarks=excluded.other_remarks,legacy_data=excluded.legacy_data,updated_at=now();

    for family_item in select value from jsonb_array_elements(coalesce(person_item->'familyHistory','[]'::jsonb)) loop
      insert into public.person_family_history(id,person_id,family_id,family_name,joined_at,left_at,rank,status,exit_reason,notes)
      values(family_item->>'id',person_item->>'id',coalesce(nullif(family_item->>'familyId',''),(select id from public.families where lower(name)=lower(family_item->>'familyName') order by id limit 1)),coalesce(family_item->>'familyName',''),nullif(family_item->>'joinedAt','')::date,nullif(family_item->>'leftAt','')::date,family_item->>'rank',coalesce(family_item->>'status','current'),family_item->>'exitReason',family_item->>'notes')
      on conflict(id) do update set family_id=excluded.family_id,family_name=excluded.family_name,joined_at=excluded.joined_at,left_at=excluded.left_at,rank=excluded.rank,status=excluded.status,exit_reason=excluded.exit_reason,notes=excluded.notes,updated_at=now();
      if coalesce(nullif(family_item->>'familyId',''),(select id from public.families where lower(name)=lower(family_item->>'familyName') order by id limit 1)) is not null then
        insert into public.family_memberships(id,person_id,family_id,joined_at,left_at,rank,status,exit_reason,notes)
        values(family_item->>'id',person_item->>'id',coalesce(nullif(family_item->>'familyId',''),(select id from public.families where lower(name)=lower(family_item->>'familyName') order by id limit 1)),nullif(family_item->>'joinedAt','')::date,nullif(family_item->>'leftAt','')::date,family_item->>'rank',coalesce(family_item->>'status','current'),family_item->>'exitReason',family_item->>'notes')
        on conflict(id) do update set family_id=excluded.family_id,joined_at=excluded.joined_at,left_at=excluded.left_at,rank=excluded.rank,status=excluded.status,exit_reason=excluded.exit_reason,notes=excluded.notes,updated_at=now();
      end if;
    end loop;
    for job_item in select value from jsonb_array_elements(coalesce(person_item->'jobs','[]'::jsonb)) loop
      insert into public.person_job_history(id,person_id,job,employer,started_at,ended_at,is_current,position,description,notes)
      values(job_item->>'id',person_item->>'id',coalesce(job_item->>'job',''),job_item->>'employer',nullif(job_item->>'startedAt','')::date,nullif(job_item->>'endedAt','')::date,coalesce((job_item->>'current')::boolean,false),job_item->>'position',job_item->>'description',job_item->>'notes')
      on conflict(id) do update set job=excluded.job,employer=excluded.employer,started_at=excluded.started_at,ended_at=excluded.ended_at,is_current=excluded.is_current,position=excluded.position,description=excluded.description,notes=excluded.notes,updated_at=now();
    end loop;
    if nullif(person_item->>'notes','') is not null then
      insert into public.person_notes(id,person_id,note_type,body)
      values(person_item->>'id'||':general',person_item->>'id','general',person_item->>'notes')
      on conflict(id) do update set body=excluded.body,updated_at=now();
    end if;
    for note_item in select value from jsonb_array_elements(coalesce(person_item->'notesHistory','[]'::jsonb)) loop
      insert into public.person_notes(id,person_id,note_type,body,occurred_at)
      values(note_item->>'id',person_item->>'id',coalesce(note_item->>'type','historical'),coalesce(note_item->>'body',''),nullif(note_item->>'date','')::date)
      on conflict(id) do update set note_type=excluded.note_type,body=excluded.body,occurred_at=excluded.occurred_at,updated_at=now();
    end loop;
    for note_item in select value from jsonb_array_elements(coalesce(person_item->'specialEvents','[]'::jsonb)) loop
      insert into public.person_notes(id,person_id,note_type,body,occurred_at)
      values(note_item->>'id',person_item->>'id','event',coalesce(note_item->>'description',note_item->>'title',''),nullif(note_item->>'date','')::date)
      on conflict(id) do update set body=excluded.body,occurred_at=excluded.occurred_at,updated_at=now();
    end loop;
  end loop;

  for item in select value from jsonb_array_elements(coalesce(new.data->'members','[]'::jsonb)) loop
    insert into public.members(id,person_id,family_id,name,rank,phone,joined,status,contact,legacy_data)
    values(item->>'id',item->>'personId',item->>'familyId',coalesce(item->>'name',''),item->>'rank',item->>'phone',nullif(item->>'joined','')::date,item->>'status',item->>'contact',item)
    on conflict(id) do update set person_id=excluded.person_id,family_id=excluded.family_id,name=excluded.name,rank=excluded.rank,phone=excluded.phone,joined=excluded.joined,status=excluded.status,contact=excluded.contact,legacy_data=excluded.legacy_data,updated_at=now();
  end loop;
  for item in select value from jsonb_array_elements(coalesce(new.data->'contacts','[]'::jsonb)) loop
    insert into public.phonebook(id,person_id,family_id,first_name,last_name,phone,family_name,legacy_data)
    values(item->>'id',item->>'personId',item->>'familyId',coalesce(item->>'firstName',''),coalesce(item->>'lastName',''),item->>'phone',item->>'family',item)
    on conflict(id) do update set person_id=excluded.person_id,family_id=excluded.family_id,first_name=excluded.first_name,last_name=excluded.last_name,phone=excluded.phone,family_name=excluded.family_name,legacy_data=excluded.legacy_data,updated_at=now();
  end loop;
  for item in select value from jsonb_array_elements(coalesce(new.data->'tasks','[]'::jsonb)) loop
    insert into public.tasks(id,title,owner_name,due,priority,status,legacy_data)
    values(item->>'id',coalesce(item->>'title',''),item->>'owner',nullif(item->>'due','')::date,item->>'priority',item->>'status',item)
    on conflict(id) do update set title=excluded.title,owner_name=excluded.owner_name,due=excluded.due,priority=excluded.priority,status=excluded.status,legacy_data=excluded.legacy_data,updated_at=now();
  end loop;
  for item in select value from jsonb_array_elements(coalesce(new.data->'finances','[]'::jsonb)) loop
    insert into public.finances(id,label,type,amount,category,booked_at,legacy_data)
    values(item->>'id',coalesce(item->>'label',''),coalesce(item->>'type','unknown'),coalesce(nullif(item->>'amount','')::numeric,0),item->>'category',nullif(item->>'date','')::date,item)
    on conflict(id) do update set label=excluded.label,type=excluded.type,amount=excluded.amount,category=excluded.category,booked_at=excluded.booked_at,legacy_data=excluded.legacy_data,updated_at=now();
  end loop;
  for item in select value from jsonb_array_elements(coalesce(new.data->'credits','[]'::jsonb)) loop
    insert into public.credits(id,borrower,amount,reason,booked_at,due,status,legacy_data)
    values(item->>'id',item->>'borrower',coalesce(nullif(item->>'amount','')::numeric,0),item->>'reason',nullif(item->>'date','')::date,nullif(item->>'due','')::date,item->>'status',item)
    on conflict(id) do update set borrower=excluded.borrower,amount=excluded.amount,reason=excluded.reason,booked_at=excluded.booked_at,due=excluded.due,status=excluded.status,legacy_data=excluded.legacy_data,updated_at=now();
  end loop;
  for item in select value from jsonb_array_elements(coalesce(new.data->'inventory','[]'::jsonb)) loop
    insert into public.storage_items(id,name,quantity,category,location,legacy_data)
    values(item->>'id',coalesce(item->>'name',''),coalesce(nullif(item->>'quantity','')::numeric,0),item->>'category',item->>'location',item)
    on conflict(id) do update set name=excluded.name,quantity=excluded.quantity,category=excluded.category,location=excluded.location,legacy_data=excluded.legacy_data,updated_at=now();
  end loop;
  for item in select value from jsonb_array_elements(coalesce(new.data->'equipment','[]'::jsonb)) loop
    insert into public.equipment_issues(id,item,recipient,quantity,issued_at,due,returned,legacy_data)
    values(item->>'id',coalesce(item->>'item',''),item->>'recipient',coalesce(nullif(item->>'quantity','')::numeric,1),nullif(item->>'issuedAt','')::date,nullif(item->>'due','')::date,coalesce((item->>'returned')::boolean,false),item)
    on conflict(id) do update set item=excluded.item,recipient=excluded.recipient,quantity=excluded.quantity,issued_at=excluded.issued_at,due=excluded.due,returned=excluded.returned,legacy_data=excluded.legacy_data,updated_at=now();
  end loop;

  for item in select value from jsonb_array_elements(coalesce(new.data->'personRelationships','[]'::jsonb)) loop
    insert into public.person_relationships(id,person_id,related_person_id,relationship_type,inverse_type,started_at,ended_at,is_current,description,notes)
    values(item->>'id',item->>'personId',item->>'relatedPersonId',coalesce(item->>'relationshipType','other'),item->>'inverseType',nullif(item->>'startedAt','')::date,nullif(item->>'endedAt','')::date,coalesce((item->>'isCurrent')::boolean,true),item->>'description',item->>'notes')
    on conflict(id) do update set relationship_type=excluded.relationship_type,inverse_type=excluded.inverse_type,started_at=excluded.started_at,ended_at=excluded.ended_at,is_current=excluded.is_current,description=excluded.description,notes=excluded.notes,updated_at=now();
  end loop;
  for item in select value from jsonb_array_elements(coalesce(new.data->'personMarriages','[]'::jsonb)) loop
    insert into public.person_marriages(id,person_id,spouse_id,wedding_date,location,divorce_date,status,notes)
    values(item->>'id',item->>'personId',item->>'spouseId',nullif(item->>'weddingDate','')::date,item->>'location',nullif(item->>'divorceDate','')::date,coalesce(item->>'status','current'),item->>'notes')
    on conflict(id) do update set spouse_id=excluded.spouse_id,wedding_date=excluded.wedding_date,location=excluded.location,divorce_date=excluded.divorce_date,status=excluded.status,notes=excluded.notes,updated_at=now();
  end loop;
  for item in select value from jsonb_array_elements(coalesce(new.data->'events','[]'::jsonb)) loop
    insert into public.appointments(id,title,event_date,event_time,location,type,legacy_data)
    values(item->>'id',coalesce(item->>'title',''),nullif(item->>'date','')::date,nullif(item->>'time','')::time,item->>'location',item->>'type',item)
    on conflict(id) do update set title=excluded.title,event_date=excluded.event_date,event_time=excluded.event_time,location=excluded.location,type=excluded.type,legacy_data=excluded.legacy_data,updated_at=now();
  end loop;

  for route_item in select value from jsonb_array_elements(coalesce(new.data->'routes','[]'::jsonb)) loop
    insert into public.routes(id,route_code,name,description,location,address,coordinates,postal_code,category,status,responsible_family_id,responsible_person_id,notes,legacy_data)
    values(route_item->>'id',route_item->>'routeCode',coalesce(route_item->>'name',''),route_item->>'description',coalesce(route_item->>'location',route_item->>'area'),route_item->>'address',route_item->'coordinates',route_item->>'postalCode',route_item->>'category',route_item->>'status',route_item->>'responsibleFamilyId',route_item->>'responsiblePersonId',route_item->>'notes',route_item)
    on conflict(id) do update set route_code=excluded.route_code,name=excluded.name,description=excluded.description,location=excluded.location,address=excluded.address,coordinates=excluded.coordinates,postal_code=excluded.postal_code,category=excluded.category,status=excluded.status,responsible_family_id=excluded.responsible_family_id,responsible_person_id=excluded.responsible_person_id,notes=excluded.notes,legacy_data=excluded.legacy_data,updated_at=now();
    if route_item ? 'prices' then
      insert into public.route_prices(route_id,purchase_total,purchase_unit_price,purchase_quantity,purchase_unit,process_input_quantity,processor_fee,finished_quantity,selling_unit_price,selling_unit,other_fees)
      values(route_item->>'id',nullif(route_item#>>'{prices,purchaseTotal}','')::numeric,nullif(route_item#>>'{prices,purchaseUnitPrice}','')::numeric,nullif(route_item#>>'{prices,purchaseQuantity}','')::numeric,route_item#>>'{prices,purchaseUnit}',nullif(route_item#>>'{prices,processInputQuantity}','')::numeric,nullif(route_item#>>'{prices,processorFee}','')::numeric,nullif(route_item#>>'{prices,finishedQuantity}','')::numeric,nullif(route_item#>>'{prices,sellingUnitPrice}','')::numeric,route_item#>>'{prices,sellingUnit}',nullif(route_item#>>'{prices,otherFees}','')::numeric)
      on conflict(route_id) do update set purchase_total=excluded.purchase_total,purchase_unit_price=excluded.purchase_unit_price,purchase_quantity=excluded.purchase_quantity,purchase_unit=excluded.purchase_unit,process_input_quantity=excluded.process_input_quantity,processor_fee=excluded.processor_fee,finished_quantity=excluded.finished_quantity,selling_unit_price=excluded.selling_unit_price,selling_unit=excluded.selling_unit,other_fees=excluded.other_fees,updated_at=now();
    end if;
    for child_item in select value from jsonb_array_elements(coalesce(route_item->'npcs','[]'::jsonb)) loop
      insert into public.route_npcs(id,route_id,name,location,coordinates,description,image_id,notes)
      values(child_item->>'id',route_item->>'id',coalesce(child_item->>'name',''),child_item->>'location',child_item->'coordinates',child_item->>'description',null,child_item->>'notes')
      on conflict(id) do update set name=excluded.name,location=excluded.location,coordinates=excluded.coordinates,description=excluded.description,notes=excluded.notes,updated_at=now();
    end loop;
    for child_item in select value from jsonb_array_elements(coalesce(route_item->'images','[]'::jsonb)) loop
      if child_item ? 'path' then
        insert into public.route_images(id,route_id,bucket_id,object_path,image_type,caption)
        values(child_item->>'id',route_item->>'id',coalesce(child_item->>'bucket','route-images'),child_item->>'path',coalesce(child_item->>'type','other'),child_item->>'caption')
        on conflict(id) do update set object_path=excluded.object_path,image_type=excluded.image_type,caption=excluded.caption;
      end if;
    end loop;
    for child_item in select value from jsonb_array_elements(coalesce(route_item->'npcs','[]'::jsonb)) loop
      if nullif(child_item->>'imageId','') is not null then
        update public.route_npcs set image_id=child_item->>'imageId' where id=child_item->>'id';
      end if;
    end loop;
    for child_item in select value from jsonb_array_elements(coalesce(route_item->'familyHistory','[]'::jsonb)) loop
      insert into public.route_family_history(id,route_id,family_id,family_name,responsible_person_id,taken_over_at,handed_over_at,reason,notes)
      values(child_item->>'id',route_item->>'id',child_item->>'familyId',coalesce(child_item->>'familyName',''),child_item->>'responsiblePersonId',nullif(child_item->>'takenOverAt','')::date,nullif(child_item->>'handedOverAt','')::date,child_item->>'reason',child_item->>'notes')
      on conflict(id) do update set family_id=excluded.family_id,family_name=excluded.family_name,responsible_person_id=excluded.responsible_person_id,taken_over_at=excluded.taken_over_at,handed_over_at=excluded.handed_over_at,reason=excluded.reason,notes=excluded.notes;
    end loop;
    for child_item in select value from jsonb_array_elements(coalesce(route_item->'buyingFamilies','[]'::jsonb)) loop
      insert into public.route_buying_families(id,route_id,family_id,family_name,contact_person_id,contact_name,phone,started_at,ended_at,status,notes)
      values(child_item->>'id',route_item->>'id',child_item->>'familyId',coalesce(child_item->>'familyName',''),child_item->>'contactPersonId',child_item->>'contactName',child_item->>'phone',nullif(child_item->>'startedAt','')::date,nullif(child_item->>'endedAt','')::date,coalesce(child_item->>'status','unknown'),child_item->>'notes')
      on conflict(id) do update set family_id=excluded.family_id,family_name=excluded.family_name,contact_person_id=excluded.contact_person_id,contact_name=excluded.contact_name,phone=excluded.phone,started_at=excluded.started_at,ended_at=excluded.ended_at,status=excluded.status,notes=excluded.notes;
    end loop;
  end loop;

  if tg_op='UPDATE' then
    foreach collection_name in array array['members','contacts','tasks','finances','credits','inventory','equipment','persons','events','routes','families','personRelationships','personMarriages'] loop
      for item in select value from jsonb_array_elements(coalesce(old.data->collection_name,'[]'::jsonb)) loop
        if not exists(select 1 from jsonb_array_elements(coalesce(new.data->collection_name,'[]'::jsonb)) current_item where current_item->>'id'=item->>'id') then
          insert into public.workspace_deletions(collection,record_id,deleted_by,record_snapshot)
          values(collection_name,item->>'id',new.updated_by,item)
          on conflict do nothing;
        end if;
      end loop;
    end loop;
  end if;
  return new;
end;
$$;

create trigger workspace_state_mirror_after_save
after insert or update of data on public.workspace_state
for each row execute function public.mirror_workspace_state();

insert into public.schema_migrations(version)
values ('20261106000001_workspace_sync')
on conflict (version) do nothing;
