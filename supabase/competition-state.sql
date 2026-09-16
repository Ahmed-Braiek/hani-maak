-- Hani Maak competition state adapter.
-- This keeps the investor demo deployable with one server-side source of truth while the
-- normalized production schema in schema.sql remains the long-term target.
-- Run this once in the Supabase SQL editor when HANI_DATA_BACKEND=supabase.

create table if not exists public.hani_demo_state (
  id text primary key,
  payload jsonb not null,
  revision integer not null default 1,
  updated_at timestamptz not null default now()
);

alter table public.hani_demo_state enable row level security;

-- No browser-facing policies are created intentionally. The Next.js server accesses this table
-- using SUPABASE_SERVICE_ROLE_KEY. Never expose that key to a client bundle.
comment on table public.hani_demo_state is
  'Competition/demo state store. Replace with normalized tables for a live patient deployment.';
