import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';

class HaniApiResponse {
  const HaniApiResponse({
    required this.message,
    required this.sessionId,
    required this.locale,
    this.confirmationToken,
    this.uiActions = const [],
  });

  final String message;
  final String sessionId;
  final String locale;
  final String? confirmationToken;
  final List<Map<String, dynamic>> uiActions;

  factory HaniApiResponse.fromJson(Map<String, dynamic> json) {
    return HaniApiResponse(
      message: (json['message'] as String?)?.trim().isNotEmpty == true
          ? json['message'] as String
          : 'I’m here. Try that again in a few words.',
      sessionId: json['sessionId'] as String? ?? '',
      locale: json['locale'] as String? ?? 'ar',
      confirmationToken: json['confirmationToken'] as String?,
      uiActions: (json['uiActions'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
    );
  }
}

class HaniApiClient {
  HaniApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<HaniApiResponse> send({
    required String message,
    required String locale,
    String? sessionId,
    String? confirmationToken,
    List<Map<String, String>> history = const [],
  }) async {
    final uri = Uri.parse('${AppConfig.apiBase}/api/v1/heni/chat');
    final response = await _client
        .post(
          uri,
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'message': message,
            'locale': locale,
            'source': 'flutter',
            'caregiverId': AppConfig.demoCaregiverId,
            'patientId': AppConfig.demoPatientId,
            if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
            if (confirmationToken != null && confirmationToken.isNotEmpty)
              'confirmationToken': confirmationToken,
            'history': history.takeLast(16),
          }),
        )
        .timeout(const Duration(seconds: 36));

    final decoded = jsonDecode(response.body);
    final body = decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HaniApiException(
        body['error']?.toString() ?? 'Hani is temporarily unavailable.',
        response.statusCode,
      );
    }
    return HaniApiResponse.fromJson(body);
  }

  void dispose() => _client.close();
}

class HaniApiException implements Exception {
  const HaniApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

extension TakeLastExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (length <= count) return List<T>.from(this);
    return sublist(length - count);
  }
}
