import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/session/caregiver_identity.dart';

class CareWorkflowApi {
  CareWorkflowApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> run(
    String action, {
    Map<String, dynamic> args = const {},
    Duration timeout = const Duration(seconds: 55),
  }) async {
    final identity = await CaregiverIdentity.resolve();
    final response = await _client
        .post(
          Uri.parse('${AppConfig.apiBase}/api/v1/care-workflows'),
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
        .timeout(timeout);

    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? decoded['error']?.toString()
          : null;
      throw StateError(message ?? 'care_workflow_failed');
    }
    return decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
  }

  void dispose() => _client.close();
}
