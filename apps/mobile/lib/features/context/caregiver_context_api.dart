import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import 'caregiver_context.dart';

class CaregiverContextApi {
  CaregiverContextApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<CaregiverContext> load() async {
    final uri = Uri.parse('${AppConfig.apiBase}/api/v1/caregiver-demo');
    final response = await _client.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('caregiver_context_unavailable');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['data'] is! Map) {
      throw Exception('caregiver_context_invalid');
    }

    return CaregiverContext.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  void dispose() => _client.close();
}
