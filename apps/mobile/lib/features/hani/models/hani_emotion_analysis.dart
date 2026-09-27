import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/session/caregiver_identity.dart';

class HaniEmotionSegment {
  const HaniEmotionSegment({
    required this.segmentIndex,
    required this.startMs,
    required this.endMs,
    required this.dominantEmotion,
    required this.confidence,
    required this.distribution,
  });

  final int segmentIndex;
  final int startMs;
  final int endMs;
  final String dominantEmotion;
  final double confidence;
  final Map<String, double> distribution;

  factory HaniEmotionSegment.fromJson(Map<String, dynamic> json) {
    return HaniEmotionSegment(
      segmentIndex: int.tryParse(json['segmentIndex']?.toString() ?? '') ?? 0,
      startMs: int.tryParse(json['startMs']?.toString() ?? '') ?? 0,
      endMs: int.tryParse(json['endMs']?.toString() ?? '') ?? 0,
      dominantEmotion: json['dominantEmotion']?.toString() ?? 'unknown',
      confidence: _toDouble(json['confidence']),
      distribution: _distribution(json['distribution']),
    );
  }
}

class HaniEmotionAnalysis {
  const HaniEmotionAnalysis({
    required this.status,
    this.dominantEmotion,
    this.confidence,
    this.distribution = const {},
    this.timeline = const [],
    this.audioDurationMs = 0,
    this.analyzedSpeechMs = 0,
    this.model,
    this.analysisVersion,
    this.summary,
    this.failureCode,
    this.failureMessage,
  });

  final String status;
  final String? dominantEmotion;
  final double? confidence;
  final Map<String, double> distribution;
  final List<HaniEmotionSegment> timeline;
  final int audioDurationMs;
  final int analyzedSpeechMs;
  final String? model;
  final String? analysisVersion;
  final String? summary;
  final String? failureCode;
  final String? failureMessage;

  factory HaniEmotionAnalysis.fromEnvelope(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? 'not_started';
    final raw = json['analysis'];
    if (raw is! Map) {
      return HaniEmotionAnalysis(status: status);
    }

    final analysis = Map<String, dynamic>.from(raw);
    return HaniEmotionAnalysis(
      status: status,
      dominantEmotion: analysis['dominantEmotion']?.toString(),
      confidence: analysis['confidence'] == null
          ? null
          : _toDouble(analysis['confidence']),
      distribution: _distribution(analysis['distribution']),
      timeline: (analysis['timeline'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => HaniEmotionSegment.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      audioDurationMs:
          int.tryParse(analysis['audioDurationMs']?.toString() ?? '') ?? 0,
      analyzedSpeechMs:
          int.tryParse(analysis['analyzedSpeechMs']?.toString() ?? '') ?? 0,
      model: analysis['model']?.toString(),
      analysisVersion: analysis['analysisVersion']?.toString(),
      summary: analysis['summary']?.toString(),
      failureCode: analysis['failureCode']?.toString(),
      failureMessage: analysis['failureMessage']?.toString(),
    );
  }
}

class HaniEmotionApi {
  HaniEmotionApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<HaniEmotionAnalysis> fetch(String conversationId) async {
    final identity = await CaregiverIdentity.resolve();
    final uri = Uri.parse(
      '${AppConfig.apiBase}/api/v1/heni/voice-session/'
      '${Uri.encodeComponent(conversationId)}/emotion',
    ).replace(
      queryParameters: {
        'caregiverId': identity.caregiverId,
        'patientId': identity.patientId,
      },
    );

    final response = await _client.get(
      uri,
      headers: identity.authHeaders,
    ).timeout(const Duration(seconds: 12));

    final decoded = jsonDecode(response.body);
    final body = decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['error']?.toString() ?? 'emotion_result_failed');
    }

    return HaniEmotionAnalysis.fromEnvelope(body);
  }

  void dispose() => _client.close();
}

double _toDouble(dynamic value) {
  final parsed = double.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed.isNaN || parsed.isInfinite) return 0;
  return parsed.clamp(0, 1);
}

Map<String, double> _distribution(dynamic raw) {
  if (raw is! Map) return const {};
  final output = <String, double>{};
  for (final entry in raw.entries) {
    output[entry.key.toString()] = _toDouble(entry.value);
  }
  return output;
}
