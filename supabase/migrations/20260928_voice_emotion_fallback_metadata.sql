alter table public.voice_emotion_analyses
  add column if not exists emotional_summary text null,
  add column if not exists result_source text null;

update public.voice_emotion_analyses
set result_source = case
  when model_name like 'gemini_text_emotion_fallback:%'
    then 'gemini_transcript_fallback'
  when status = 'completed'
    then 'vocal_model'
  else result_source
end
where result_source is null;
