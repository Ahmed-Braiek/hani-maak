# Hani Maak — Team Handoff

## Production surfaces

- Web / Flutter host: https://hani-maak.vercel.app
- Heni agent: https://hani-maak-heni-agent.vercel.app
- Android package: com.hanimaak.hani_maak_mobile

## Current end-to-end flows

- Hani text chat with durable caregiver context
- Hani Live full-duplex voice with audible PCM playback and live transcription
- Supported conversation/transcription languages: Tunisian Derja, Arabic, French, English
- Daily Dilemma library and private incident workflow
- Patient Activity with familiar people, places, routines, music, and memories
- Medication manual entry, prescription/box OCR, caregiver review, schedules, reminders, and event history
- Care Hub: medications, appointments, verified instructions, timeline, documents, activities, summaries, professionals
- Native Android notification reminders with deep links
- Android home-screen widget with patient, medication, appointment, care status, and task data
- Caregiver daily/weekly summary generation
- WhatsApp Business delivery adapter plus reviewed WhatsApp deep-link fallback
- Care Circle task requests and response workflow
- Caregiver wellbeing and professional handoff

## Android permissions

The release APK requests only what its enabled features need:
- Internet
- Microphone / audio settings for Hani Live
- Camera for medication / prescription scanning
- Notifications
- Exact alarms for precise reminders
- Boot completed for reminder rescheduling
- URL intents for HTTPS, phone dialer, and WhatsApp

## External production configuration still required

### WhatsApp Business automatic delivery

Configure these on the production Next.js project:

- WHATSAPP_PHONE_NUMBER_ID
- WHATSAPP_ACCESS_TOKEN
- WHATSAPP_API_VERSION

The sender must be an approved WhatsApp Business sender and the recipient must be eligible under Meta messaging rules. Without these values, Hani Maak records the delivery as configuration_required and can still open WhatsApp with the exact reviewed summary.

### Remote push notifications

Local Android medication, appointment, follow-up, and scheduled care notifications are functional without a third-party push provider.

For server-initiated remote push while the app is fully closed, connect Firebase Cloud Messaging (or another approved push provider) and use the existing device_push_tokens model / registration action as the server-side token registry. Do not place service-account secrets in Flutter.

## Demo recipient

WhatsApp team test recipient: +216 27 983 305

## Safety boundaries

- OCR results are always reviewed before medication data is saved.
- Hani never changes medication dose, timing, crushing, mixing, or treatment.
- Private caregiver wellbeing and private Hani conversations stay outside shared summaries.
- Professional / Care Circle sharing requires explicit confirmation where configured.
- Clinical scenario guidance stays validation-gated; unreviewed clinical content is never presented as validated.
