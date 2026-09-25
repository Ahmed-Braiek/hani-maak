import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import 'caregiver_context.dart';

class CaregiverContextApi {
  CaregiverContextApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<CaregiverContext> load() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBase}/api/v1/caregiver-demo');
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return CaregiverContext.fromJson(
            Map<String, dynamic>.from(decoded['data'] as Map),
          );
        }
      }
    } catch (_) {
      // The coach/demo build has a synthetic fallback so the mobile UX remains
      // usable when the preview backend is rate-limited or unavailable.
    }

    return CaregiverContext.fromJson(_demoContext);
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
        'medication_name': 'Demo medication A',
        'dose_text': 'As prescribed',
        'schedule_text': 'Evening',
        'instructions':
            'Synthetic demo row. Follow the prescribing professional instructions.',
        'verified': true,
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
        'connection': {
          'connection_type': 'neurology',
          'status': 'active',
        },
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
      {
        'id': 'demo-notification-3',
        'category': 'wellbeing_checkin',
        'title': 'A moment for you',
        'body':
            'Your recent check-ins suggest the last few days have been heavier.',
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
  };
}
