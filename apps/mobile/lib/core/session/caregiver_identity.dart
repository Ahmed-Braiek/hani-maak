import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class CaregiverIdentity {
  const CaregiverIdentity({
    required this.caregiverId,
    required this.patientId,
    this.accessToken,
    this.isDemo = false,
  });

  final String caregiverId;
  final String patientId;
  final String? accessToken;
  final bool isDemo;

  static Future<CaregiverIdentity> resolve() async {
    if (!AppConfig.hasSupabaseAuth) {
      return const CaregiverIdentity(
        caregiverId: AppConfig.demoCaregiverId,
        patientId: AppConfig.demoPatientId,
        isDemo: true,
      );
    }

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) {
      return const CaregiverIdentity(
        caregiverId: AppConfig.demoCaregiverId,
        patientId: AppConfig.demoPatientId,
        isDemo: true,
      );
    }

    try {
      final profiles = await client
          .from('profiles')
          .select('id')
          .eq('auth_user_id', session.user.id)
          .limit(1);
      if (profiles is! List || profiles.isEmpty) throw StateError('profile_not_found');
      final caregiverId = profiles.first['id']?.toString() ?? '';
      if (caregiverId.isEmpty) throw StateError('profile_not_found');

      final relationships = await client
          .from('caregiver_patient_relationships')
          .select('patient_id')
          .eq('caregiver_profile_id', caregiverId)
          .eq('access_status', 'active')
          .limit(1);
      if (relationships is! List || relationships.isEmpty) {
        throw StateError('caregiver_relationship_not_found');
      }
      final patientId = relationships.first['patient_id']?.toString() ?? '';
      if (patientId.isEmpty) throw StateError('patient_not_found');

      return CaregiverIdentity(
        caregiverId: caregiverId,
        patientId: patientId,
        accessToken: session.accessToken,
      );
    } catch (_) {
      return const CaregiverIdentity(
        caregiverId: AppConfig.demoCaregiverId,
        patientId: AppConfig.demoPatientId,
        isDemo: true,
      );
    }
  }

  Map<String, String> get authHeaders => accessToken == null
      ? const <String, String>{}
      : <String, String>{'authorization': 'Bearer $accessToken'};
}
