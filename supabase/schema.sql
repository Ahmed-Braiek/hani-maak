-- Hani Maak production-oriented Supabase/Postgres starting schema.
-- Competition build defaults to apps/web/data/demo-db.json; this schema is the migration path.
create extension if not exists pgcrypto;

create type appointment_state as enum ('requested','offered','confirmed','cancelled','completed','no_show','needs_assistance');
create type journey_step_state as enum ('upcoming','active','completed','skipped','blocked');

create table tenants (
  id uuid primary key default gen_random_uuid(), slug text unique not null, display_name text not null,
  timezone text not null default 'Africa/Tunis', default_locale text not null default 'fr', supported_locales text[] not null default '{fr,ar}',
  brand_config jsonb not null default '{}', contact_config jsonb not null default '{}', demo_mode boolean not null default false,
  created_at timestamptz not null default now()
);
create table staff_users (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade,
  auth_user_id uuid not null, display_name text not null, role text not null check(role in ('receptionist','coordinator','clinician','manager','tenant_admin')), active boolean not null default true,
  unique(tenant_id,auth_user_id)
);
create table patients (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade,
  auth_user_id uuid, first_name text not null, last_name text not null, phone_e164 text, email text, preferred_locale text not null default 'fr',
  preferred_channel text not null default 'app', consent_status text not null default 'unknown', data_provenance text not null,
  created_at timestamptz not null default now()
);
create table services (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, code text not null,
  name jsonb not null, description jsonb not null default '{}', department text, aliases jsonb not null default '{}', booking_mode text not null default 'direct',
  slot_duration_min int not null check(slot_duration_min between 5 and 240), location_node_id uuid, documents jsonb not null default '[]',
  preparation_template_id uuid, followup_template_id uuid, accessibility_notes text, active boolean not null default true, data_provenance text not null,
  unique(tenant_id,code)
);
create table schedule_rules (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, service_id uuid not null references services(id) on delete cascade,
  day_of_week int not null check(day_of_week between 0 and 6), start_time time not null, end_time time not null, capacity int not null check(capacity > 0), slot_duration_min int,
  effective_from date, effective_to date, check(end_time > start_time)
);
create table schedule_exceptions (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, service_id uuid not null references services(id) on delete cascade,
  exception_date date not null, start_time time, end_time time, closed boolean not null default false, capacity_override int, reason text
);
create table appointments (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, patient_id uuid not null references patients(id), service_id uuid not null references services(id),
  start_at timestamptz not null, end_at timestamptz not null, state appointment_state not null default 'requested', channel text not null, source_session_id uuid,
  cancellation_reason text, provenance text not null, version int not null default 1, idempotency_key text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(tenant_id,idempotency_key)
);
create index appointments_capacity_idx on appointments(tenant_id,service_id,start_at,state);
create table appointment_events (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, appointment_id uuid not null references appointments(id) on delete cascade,
  actor_type text not null, actor_id text, event_type text not null, payload jsonb not null default '{}', created_at timestamptz not null default now()
);
create table content_templates (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, type text not null,
  title jsonb not null, body jsonb not null, version int not null default 1, author_staff_id uuid, clinical_reviewed_by uuid,
  published_at timestamptz, provenance text not null, created_at timestamptz not null default now()
);
create table workflow_templates (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, service_id uuid references services(id), name text not null, version int not null, active boolean not null default true
);
create table workflow_template_steps (
  id uuid primary key default gen_random_uuid(), workflow_template_id uuid not null references workflow_templates(id) on delete cascade,
  sequence int not null, step_type text not null, title jsonb not null, content_template_id uuid references content_templates(id), relative_timing interval, required boolean not null default true, configuration jsonb not null default '{}'
);
create table journeys (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, patient_id uuid not null references patients(id), appointment_id uuid not null references appointments(id),
  service_id uuid not null references services(id), template_id uuid references workflow_templates(id), template_version int, state text not null default 'active', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table journey_steps (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, journey_id uuid not null references journeys(id) on delete cascade,
  step_type text not null, sequence int not null, state journey_step_state not null default 'upcoming', title jsonb not null, body jsonb, due_at timestamptz, activated_at timestamptz, completed_at timestamptz, payload jsonb not null default '{}'
);
create table notifications (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, patient_id uuid not null references patients(id), journey_step_id uuid references journey_steps(id),
  channel text not null, destination_ref text, template text, state text not null, external_id text, scheduled_at timestamptz, sent_at timestamptz, delivered_at timestamptz, failure_code text, created_at timestamptz not null default now()
);
create table facility_nodes (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, code text not null, label jsonb not null, type text not null, floor int not null default 0,
  lat double precision, lon double precision, local_x double precision, local_y double precision, accessible boolean not null default true, provenance text not null,
  unique(tenant_id,code)
);
create table facility_edges (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, from_node_id uuid not null references facility_nodes(id), to_node_id uuid not null references facility_nodes(id),
  distance_m numeric not null check(distance_m >= 0), bidirectional boolean not null default true, accessible boolean not null default true, restricted boolean not null default false,
  instruction jsonb not null default '{}', geometry_geojson jsonb, provenance text not null
);
create table call_sessions (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, patient_id uuid references patients(id), external_call_id text,
  caller_ref text, locale text not null, started_at timestamptz not null default now(), ended_at timestamptz, outcome text, state text, transcript_consent boolean not null default false,
  transcript_ref text, structured_summary jsonb, escalation_id uuid
);
create table agent_tool_events (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, call_session_id uuid not null references call_sessions(id) on delete cascade,
  agent_session_id text, tool_name text not null, sanitized_arguments jsonb not null default '{}', sanitized_result jsonb not null default '{}', status text not null, latency_ms int, created_at timestamptz not null default now()
);
create table escalations (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, patient_id uuid references patients(id), journey_id uuid references journeys(id),
  source text not null, category text not null, summary text not null, priority text not null default 'normal', state text not null default 'open', assigned_staff_id uuid references staff_users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table medicine_image_sessions (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, patient_id uuid not null references patients(id), storage_ref text,
  extracted_fields jsonb not null default '{}', user_confirmed_fields jsonb not null default '{}', linked_instruction_id uuid references content_templates(id), outcome text, created_at timestamptz not null default now()
);
create table audit_log (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, actor_type text not null, actor_id text, action text not null,
  resource_type text not null, resource_id text, metadata jsonb not null default '{}', created_at timestamptz not null default now()
);
create table product_events (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references tenants(id) on delete cascade, safe_session_ref text, event_name text not null, properties jsonb not null default '{}', created_at timestamptz not null default now()
);

-- Link service content/location after referenced tables exist.
alter table services add constraint services_location_fk foreign key(location_node_id) references facility_nodes(id) deferrable initially deferred;
alter table services add constraint services_prep_fk foreign key(preparation_template_id) references content_templates(id) deferrable initially deferred;
alter table services add constraint services_follow_fk foreign key(followup_template_id) references content_templates(id) deferrable initially deferred;

-- Tenant membership helper for RLS. In a real deployment, populate app_metadata.tenant_id or use a membership table.
create or replace function auth_tenant_id() returns uuid language sql stable as $$
  select nullif(auth.jwt() -> 'app_metadata' ->> 'tenant_id','')::uuid
$$;

alter table tenants enable row level security;
alter table staff_users enable row level security;
alter table patients enable row level security;
alter table services enable row level security;
alter table schedule_rules enable row level security;
alter table schedule_exceptions enable row level security;
alter table appointments enable row level security;
alter table appointment_events enable row level security;
alter table content_templates enable row level security;
alter table journeys enable row level security;
alter table journey_steps enable row level security;
alter table notifications enable row level security;
alter table facility_nodes enable row level security;
alter table facility_edges enable row level security;
alter table call_sessions enable row level security;
alter table agent_tool_events enable row level security;
alter table escalations enable row level security;
alter table medicine_image_sessions enable row level security;
alter table audit_log enable row level security;
alter table product_events enable row level security;

-- Staff tenant-scoped read/write baseline. Tighten each table by role in production.
create policy tenant_staff_services on services for all using (tenant_id = auth_tenant_id()) with check (tenant_id = auth_tenant_id());
create policy tenant_staff_schedule_rules on schedule_rules for all using (tenant_id = auth_tenant_id()) with check (tenant_id = auth_tenant_id());
create policy tenant_staff_schedule_exceptions on schedule_exceptions for all using (tenant_id = auth_tenant_id()) with check (tenant_id = auth_tenant_id());
create policy tenant_staff_appointments on appointments for all using (tenant_id = auth_tenant_id()) with check (tenant_id = auth_tenant_id());
create policy tenant_staff_journeys on journeys for all using (tenant_id = auth_tenant_id()) with check (tenant_id = auth_tenant_id());
create policy tenant_staff_journey_steps on journey_steps for all using (tenant_id = auth_tenant_id()) with check (tenant_id = auth_tenant_id());
create policy tenant_staff_content on content_templates for all using (tenant_id = auth_tenant_id()) with check (tenant_id = auth_tenant_id());
create policy tenant_staff_nodes on facility_nodes for all using (tenant_id = auth_tenant_id()) with check (tenant_id = auth_tenant_id());
create policy tenant_staff_edges on facility_edges for all using (tenant_id = auth_tenant_id()) with check (tenant_id = auth_tenant_id());
create policy tenant_staff_calls on call_sessions for all using (tenant_id = auth_tenant_id()) with check (tenant_id = auth_tenant_id());
create policy tenant_staff_tools on agent_tool_events for all using (tenant_id = auth_tenant_id()) with check (tenant_id = auth_tenant_id());
create policy tenant_staff_escalations on escalations for all using (tenant_id = auth_tenant_id()) with check (tenant_id = auth_tenant_id());
create policy tenant_staff_audit on audit_log for select using (tenant_id = auth_tenant_id());

-- Patient-own-record policies require auth_user_id linkage.
create policy patient_own_profile on patients for select using (auth_user_id = auth.uid());
create policy patient_own_appointments on appointments for select using (patient_id in (select id from patients where auth_user_id = auth.uid()));
create policy patient_own_journeys on journeys for select using (patient_id in (select id from patients where auth_user_id = auth.uid()));
create policy patient_own_journey_steps on journey_steps for select using (journey_id in (select id from journeys where patient_id in (select id from patients where auth_user_id = auth.uid())));

-- Appointment capacity must ultimately be enforced transactionally. For production, implement booking through
-- a SECURITY DEFINER database function or serializable transaction that re-calculates capacity and inserts
-- the appointment atomically. The JSON demo repository mimics this domain guard but is not a distributed lock.
