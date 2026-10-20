import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class CaregiverIdentity {
  static bool demoSelected = false;
  static void enterDemo() { demoSelected = true; }
  static void leaveDemo() { demoSelected = false; }

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
    if (!AppConfig.hasSupabaseAuth) throw StateError('authentication_not_configured');
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) throw StateError('authentication_required');
    if (demoSelected) {
      if (session.user.isAnonymous) throw StateError('demo_password_login_required');
      final response = await http.post(
        Uri.parse('${AppConfig.apiBase}/api/v1/public-demo/bootstrap'),
        headers: {'authorization': 'Bearer ${session.accessToken}'},
      ).timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) throw StateError('demo_bootstrap_unavailable');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return CaregiverIdentity(
        caregiverId: data['caregiverId'] as String,
        patientId: data['patientId'] as String,
        accessToken: session.accessToken,
        isDemo: true,
      );
    }

    final profiles = await client
        .from('profiles')
        .select('id')
        .eq('auth_user_id', session.user.id)
        .limit(1);
    if (profiles is! List || profiles.isEmpty) {
      throw StateError('signed_in_caregiver_profile_not_found');
    }
    final caregiverId = profiles.first['id']?.toString() ?? '';
    if (caregiverId.isEmpty) {
      throw StateError('signed_in_caregiver_profile_not_found');
    }

    final relationships = await client
        .from('caregiver_patient_relationships')
        .select('patient_id')
        .eq('caregiver_profile_id', caregiverId)
        .eq('access_status', 'active')
        .limit(1);
    if (relationships is! List || relationships.isEmpty) {
      throw StateError('signed_in_caregiver_relationship_not_found');
    }
    final patientId = relationships.first['patient_id']?.toString() ?? '';
    if (patientId.isEmpty) {
      throw StateError('signed_in_patient_not_found');
    }

    return CaregiverIdentity(
      caregiverId: caregiverId,
      patientId: patientId,
      accessToken: session.accessToken,
    );
  }

  Map<String, String> get authHeaders => accessToken == null
      ? const <String, String>{}
      : <String, String>{'authorization': 'Bearer $accessToken'};
}
