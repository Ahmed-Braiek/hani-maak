import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/session/caregiver_identity.dart';
import 'caregiver_context.dart';

class CaregiverContextApi {
  CaregiverContextApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<CaregiverContext> load() async {
    final identity = await CaregiverIdentity.resolve();

    try {
      final uri = Uri.parse('${AppConfig.apiBase}/api/v1/caregiver-app').replace(
        queryParameters: {
          'caregiverId': identity.caregiverId,
          'patientId': identity.patientId,
        },
      );
      final response = await _client
          .get(uri, headers: identity.authHeaders)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return CaregiverContext.fromJson(
            Map<String, dynamic>.from(decoded['data'] as Map),
          );
        }
      }
    } catch (_) {
      // Never silently replace a signed-in caregiver's authorized context with
      // synthetic demo data. That would be confusing and unsafe in production.
      if (!identity.isDemo) rethrow;
    }

    return CaregiverContext.fromJson(_demoContext);
  }

  Future<Map<String, dynamic>> ocrPrescription({
    required String imageBase64,
    required String mimeType,
    required String documentType,
    required String locale,
  }) async {
    final identity = await CaregiverIdentity.resolve();
    final response = await _client
        .post(
          Uri.parse('${AppConfig.apiBase}/api/v1/heni/ocr-prescription'),
          headers: {
            'content-type': 'application/json',
            ...identity.authHeaders,
          },
          body: jsonEncode({
            'caregiverId': identity.caregiverId,
            'patientId': identity.patientId,
            'imageBase64': imageBase64,
            'mimeType': mimeType,
            'documentType': documentType,
            'locale': locale,
          }),
        )
        .timeout(const Duration(seconds: 50));

    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? decoded['error']?.toString() ?? 'ocr_failed'
          : 'ocr_failed';
      throw StateError(message);
    }
    return decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>?> action(
    String action, {
    Map<String, dynamic> args = const {},
  }) async {
    final identity = await CaregiverIdentity.resolve();
    final response = await _client
        .post(
          Uri.parse('${AppConfig.apiBase}/api/v1/caregiver-app'),
          headers: {
            'content-type': 'application/json',
            ...identity.authHeaders,
          },
          body: jsonEncode({
            'caregiverId': identity.caregiverId,
            'patientId': identity.patientId,
            'action': action,
            'args': args,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('caregiver_action_failed');
    }

    final decoded = jsonDecode(response.body);
    return decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : null;
  }

  void dispose() => _client.close();

  static final Map<String, dynamic> _demoContext = {
    'caregiver': {
      'id': AppConfig.demoCaregiverId,
      'full_name': 'Mariem Ben Salah',
      'preferred_language': 'derja',
      'timezone': 'Africa/Tunis',
      'role': 'caregiver',
    },
    'patient': {
      'id': AppConfig.demoPatientId,
      'display_name': 'Fatma Ben Salah',
      'preferred_name': 'Fatma',
      'sex': 'female',
      'alzheimer_stage': 'moderate',
      'primary_language': 'ar',
      'important_notes': 'Synthetic demo profile.',
    },
    'relationship': {
      'caregiver_role': 'primary',
      'relationship_label': 'daughter',
      'access_status': 'active',
    },
    'medications': [
      {
        'id': 'demo-med-donepezil',
        'medication_name': 'Donepezil',
        'dose_text': '5 mg',
        'schedule_text': '20:00',
        'instructions':
            'Synthetic demo record. Follow the verified prescription; Hani never changes dose or timing.',
        'verified': true,
        'active': true,
        'starts_on': '2026-09-01',
      },
      {
        'id': 'demo-med-vitd',
        'medication_name': 'Vitamin D3',
        'dose_text': 'As recorded on the mock prescription',
        'schedule_text': 'Sunday morning',
        'instructions': 'Synthetic demo record for workflow testing.',
        'verified': false,
        'active': true,
      },
    ],
    'professionalInstructions': [
      {
        'title': 'Evening care plan',
        'body':
            'Synthetic demo instruction. Follow the verified care plan and contact the connected professional when a meaningful change needs review.',
        'status': 'active',
      },
    ],
    'recentIncidents': [
      {
        'id': 'demo-incident-1',
        'reported_by_profile_id': AppConfig.demoCaregiverId,
        'title': 'Refused dinner',
        'summary':
            'Fatma refused dinner and became upset when Mariem tried again. This synthetic demo incident is still private.',
        'support_level': 'routine_support',
        'visibility': 'private_draft',
      },
    ],
    'careTasks': [
      {
        'id': 'demo-task-1',
        'title': 'Evening routine',
        'description': 'Support Fatma through the evening routine.',
        'status': 'open',
        'effort_weight': 2,
        'difficulty': 'heavy',
        'assigned_to_profile_id': AppConfig.demoCaregiverId,
        'overnight': false,
      },
      {
        'id': 'demo-task-2',
        'title': 'Morning check-in',
        'description': 'Spend time with Fatma and note meaningful changes.',
        'status': 'accepted',
        'effort_weight': 1,
        'difficulty': 'moderate',
        'assigned_to_profile_id':
            '10000000-0000-0000-0000-000000000002',
        'overnight': false,
      },
    ],
    'privateWellbeing': [
      {
        'mood_label': 'tired',
        'energy_label': 'low',
        'sleep_label': 'poor',
        'free_text': 'Long night yesterday.',
      },
      {
        'mood_label': 'okay',
        'energy_label': 'medium',
        'sleep_label': 'okay',
      },
    ],
    'careCircle': {
      'id': '40000000-0000-0000-0000-000000000001',
      'name': 'Fatma Care Circle',
      'members': [
        {
          'profile_id': AppConfig.demoCaregiverId,
          'member_role': 'caregiver',
          'status': 'active',
          'profile': {
            'id': AppConfig.demoCaregiverId,
            'full_name': 'Mariem Ben Salah',
          },
        },
        {
          'profile_id': '10000000-0000-0000-0000-000000000002',
          'member_role': 'caregiver',
          'status': 'active',
          'profile': {
            'id': '10000000-0000-0000-0000-000000000002',
            'full_name': 'Sami Ben Salah',
          },
        },
      ],
    },
    'professionalRoutes': [
      {
        'connection': {'connection_type': 'neurology', 'status': 'active'},
        'professional': {
          'id': '20000000-0000-0000-0000-000000000001',
          'full_name': 'Dr Leila Ben Salem',
          'specialty': 'Neurology',
          'facility_name': 'Demo Care Network',
          'phone': '+21620000000',
          'whatsapp': '+21620000000',
          'is_verified': true,
        },
      },
    ],
    'notifications': [
      {
        'id': 'demo-notification-1',
        'category': 'incident_followup',
        'title': 'How did the evening go?',
        'body':
            'Hani can follow up on the private incident you recorded earlier.',
      },
      {
        'id': 'demo-notification-2',
        'category': 'care_circle_request',
        'title': 'Sami can help tomorrow',
        'body':
            'You have a heavier evening task tomorrow. Hani can help you ask Sami to cover one responsibility.',
      },
    ],
    'notificationPreferences': {
      'enabled': true,
      'incident_followup': true,
      'wellbeing_checkin': true,
      'care_circle_requests': true,
      'appointments': true,
    },
    'questionnaires': [],
    'timeline': [],
    'appointments': [
      {
        'id': 'demo-appointment-1',
        'scheduled_for': '2026-09-29T10:30:00+01:00',
        'reason': 'Neurology follow-up',
        'status': 'requested',
      },
    ],
    'medicationSchedules': [
      {
        'id': 'demo-schedule-1',
        'patient_medication_id': 'demo-med-donepezil',
        'timezone': 'Africa/Tunis',
        'times': ['20:00'],
        'days_of_week': [1,2,3,4,5,6,7],
        'reminder_minutes_before': 10,
        'active': true,
      },
    ],
    'medicationEvents': [
      {
        'id': 'demo-med-event-1',
        'patient_medication_id': 'demo-med-donepezil',
        'scheduled_for': '2026-09-25T20:00:00+01:00',
        'status': 'taken',
        'actual_at': '2026-09-25T20:08:00+01:00',
      },
      {
        'id': 'demo-med-event-2',
        'patient_medication_id': 'demo-med-donepezil',
        'scheduled_for': '2026-09-24T20:00:00+01:00',
        'status': 'delayed',
        'actual_at': '2026-09-24T21:05:00+01:00',
      },
    ],
    'careDocuments': [
      {
        'id': 'demo-doc-1',
        'document_type': 'prescription',
        'title': 'Prescription — September follow-up',
        'original_file_name': 'ordonnance_demo.jpg',
        'extracted_text': 'Synthetic demo OCR content reviewed by caregiver.',
        'extraction_json': {
          'medications': [
            {'name': 'Donepezil', 'dose': '5 mg', 'frequency': '20:00'}
          ]
        },
        'reviewed': true,
      },
    ],
    'memoryItems': [
      {
        'id': 'demo-memory-person',
        'item_type': 'person',
        'title': 'Sami, her son',
        'subtitle': 'Sunday lunch and family stories',
        'prompt': 'Who do you enjoy having lunch with on Sunday?',
        'sort_order': 1,
        'active': true,
      },
      {
        'id': 'demo-memory-place',
        'item_type': 'place',
        'title': 'Sidi Bou Said',
        'subtitle': 'Blue doors, sea view, afternoon walks',
        'prompt': 'What do you remember about the sea and the blue doors?',
        'sort_order': 2,
        'active': true,
      },
      {
        'id': 'demo-memory-routine',
        'item_type': 'routine',
        'title': 'Morning coffee by the window',
        'subtitle': 'A calm daily routine',
        'prompt': 'Would you like to sit by the window for coffee?',
        'sort_order': 3,
        'active': true,
      },
      {
        'id': 'demo-memory-music',
        'item_type': 'music',
        'title': 'Familiar Tunisian classics',
        'subtitle': 'Music the family says she enjoys',
        'prompt': 'Would you like to listen together for a few minutes?',
        'sort_order': 4,
        'active': true,
      },
    ],
    'activitySessions': [
      {
        'id': 'demo-activity-1',
        'memory_item_id': 'demo-memory-routine',
        'activity_type': 'routine',
        'response_label': 'calm',
        'note': 'Synthetic demo: calm engagement for about 10 minutes.',
        'started_at': '2026-09-25T09:00:00+01:00',
        'ended_at': '2026-09-25T09:10:00+01:00',
      },
    ],
    'summaryDeliveries': [],
    'supportSignals': [],
    'taskRequests': [],
    'patterns': [
      {'type': 'caregiver_strain', 'count': 2, 'windowCount': 2},
    ],
    'followUp': {
      'category': 'incident_followup',
      'title': 'How did the evening go?',
      'body': 'Continue the conversation with Hani when you are ready.',
    },
  };
}
