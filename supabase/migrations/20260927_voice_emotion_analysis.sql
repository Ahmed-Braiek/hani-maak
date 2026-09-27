create table if not exists public.voice_emotion_analyses (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null
    references public.hani_conversations(id)
    on delete cascade,
  patient_id uuid null
    references public.patients(id)
    on delete cascade,
  caregiver_profile_id uuid null
    references public.profiles(id)
    on delete set null,
  status text not null default 'processing'
    check (status in ('processing','completed','insufficient_audio','failed')),
  dominant_emotion text null
    check (
      dominant_emotion is null or dominant_emotion in (
        'angry','disgusted','fearful','happy','neutral',
        'other','sad','surprised','unknown'
      )
    ),
  confidence double precision null
    check (confidence is null or (confidence >= 0 and confidence <= 1)),
  distribution jsonb null,
  audio_duration_ms integer null check (audio_duration_ms is null or audio_duration_ms >= 0),
  analyzed_speech_ms integer null check (analyzed_speech_ms is null or analyzed_speech_ms >= 0),
  segment_count integer not null default 0 check (segment_count >= 0),
  model_name text not null default 'emotion2vec_plus_base',
  model_version text null,
  analysis_version text not null default 'v1',
  failure_code text null,
  failure_message text null,
  created_at timestamptz not null default now(),
  completed_at timestamptz null,
  unique (conversation_id)
);

create table if not exists public.voice_emotion_segments (
  id uuid primary key default gen_random_uuid(),
  analysis_id uuid not null
    references public.voice_emotion_analyses(id)
    on delete cascade,
  segment_index integer not null check (segment_index >= 0),
  start_ms integer not null check (start_ms >= 0),
  end_ms integer not null check (end_ms > start_ms),
  voiced_duration_ms integer null check (voiced_duration_ms is null or voiced_duration_ms >= 0),
  dominant_emotion text not null
    check (
      dominant_emotion in (
        'angry','disgusted','fearful','happy','neutral',
        'other','sad','surprised','unknown'
      )
    ),
  confidence double precision not null
    check (confidence >= 0 and confidence <= 1),
  distribution jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (analysis_id, segment_index)
);

create index if not exists voice_emotion_analyses_patient_created_idx
  on public.voice_emotion_analyses(patient_id, created_at desc);

create index if not exists voice_emotion_analyses_caregiver_created_idx
  on public.voice_emotion_analyses(caregiver_profile_id, created_at desc);

create index if not exists voice_emotion_segments_analysis_idx
  on public.voice_emotion_segments(analysis_id, segment_index);

alter table public.voice_emotion_analyses enable row level security;
alter table public.voice_emotion_segments enable row level security;

drop policy if exists voice_emotion_analyses_caregiver_select
  on public.voice_emotion_analyses;

create policy voice_emotion_analyses_caregiver_select
on public.voice_emotion_analyses
for select
using (
  exists (
    select 1
    from public.profiles p
    join public.caregiver_patient_relationships r
      on r.caregiver_profile_id = p.id
     and r.patient_id = voice_emotion_analyses.patient_id
     and r.access_status = 'active'
    where p.id = voice_emotion_analyses.caregiver_profile_id
      and p.auth_user_id = (select auth.uid())
  )
);

drop policy if exists voice_emotion_segments_caregiver_select
  on public.voice_emotion_segments;

create policy voice_emotion_segments_caregiver_select
on public.voice_emotion_segments
for select
using (
  exists (
    select 1
    from public.voice_emotion_analyses a
    join public.profiles p
      on p.id = a.caregiver_profile_id
    join public.caregiver_patient_relationships r
      on r.caregiver_profile_id = p.id
     and r.patient_id = a.patient_id
     and r.access_status = 'active'
    where a.id = voice_emotion_segments.analysis_id
      and p.auth_user_id = (select auth.uid())
  )
);
