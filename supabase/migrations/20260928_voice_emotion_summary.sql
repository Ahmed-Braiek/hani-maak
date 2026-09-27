alter table public.voice_emotion_analyses
  add column if not exists summary text null;
