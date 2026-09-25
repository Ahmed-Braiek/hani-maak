import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';
import 'hani_pcm_player.dart';

enum VoicePhase { idle, connecting, listening, thinking, speaking, error }

class VoiceTranscriptLine {
  const VoiceTranscriptLine({
    required this.turnId,
    required this.role,
    required this.text,
    this.isFinal = false,
  });

  final int turnId;
  final String role;
  final String text;
  final bool isFinal;

  VoiceTranscriptLine copyWith({
    String? text,
    bool? isFinal,
  }) {
    return VoiceTranscriptLine(
      turnId: turnId,
      role: role,
      text: text ?? this.text,
      isFinal: isFinal ?? this.isFinal,
    );
  }
}

class HaniVoiceState {
  const HaniVoiceState({
    this.phase = VoicePhase.idle,
    this.lines = const [],
    this.locale = 'ar',
    this.error,
    this.connected = false,
  });

  final VoicePhase phase;
  final List<VoiceTranscriptLine> lines;
  final String locale;
  final String? error;
  final bool connected;

  HaniVoiceState copyWith({
    VoicePhase? phase,
    List<VoiceTranscriptLine>? lines,
    String? locale,
    String? error,
    bool? connected,
    bool clearError = false,
  }) {
    return HaniVoiceState(
      phase: phase ?? this.phase,
      lines: lines ?? this.lines,
      locale: locale ?? this.locale,
      error: clearError ? null : error ?? this.error,
      connected: connected ?? this.connected,
    );
  }
}

final haniVoiceProvider =
    StateNotifierProvider<HaniVoiceController, HaniVoiceState>((ref) {
  final controller = HaniVoiceController();
  ref.onDispose(controller.dispose);
  return controller;
});

class HaniVoiceController extends StateNotifier<HaniVoiceState> {
  HaniVoiceController() : super(const HaniVoiceState());

  final _recorder = AudioRecorder();
  final _pcmPlayer = HaniPcmPlayer();

  WebSocketChannel? _channel;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<dynamic>? _socketSub;
  bool _disconnecting = false;

  Future<void> connect() async {
    if (state.phase != VoicePhase.idle && state.phase != VoicePhase.error) {
      return;
    }

    state = state.copyWith(
      phase: VoicePhase.connecting,
      clearError: true,
      lines: const [],
      connected: false,
    );

    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBase}/api/v1/heni/voice-token'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'locale': state.locale,
              'caregiverId': AppConfig.demoCaregiverId,
              'patientId': AppConfig.demoPatientId,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('voice_token_unavailable');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['token']?.toString();
      final wsUrl = body['wsUrl']?.toString();

      if (token == null || wsUrl == null) {
        throw Exception('voice_token_invalid');
      }

      final uri = Uri.parse(wsUrl).replace(queryParameters: {'token': token});
      _channel = WebSocketChannel.connect(uri);

      _socketSub = _channel!.stream.listen(
        _onSocketData,
        onError: (Object error) {
          if (!_disconnecting) {
            _fail('Voice connection was interrupted.');
          }
        },
        onDone: () {
          if (mounted && !_disconnecting) {
            state = state.copyWith(
              phase: VoicePhase.idle,
              connected: false,
            );
          }
        },
      );

      await _pcmPlayer.init();
      await _startMic();

      state = state.copyWith(
        phase: VoicePhase.listening,
        connected: true,
      );
    } catch (_) {
      _fail('Hani voice could not connect. Tap to try again.');
    }
  }

  Future<void> _startMic() async {
    if (_micSub != null) return;

    if (!await _recorder.hasPermission()) {
      throw Exception('microphone_permission_denied');
    }

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );

    _micSub = stream.listen(
      (chunk) {
        if (_channel != null && state.connected) {
          _channel?.sink.add(chunk);
        }
      },
      onError: (_) => _fail('Microphone stream was interrupted.'),
    );
  }

  void setLocale(String locale) {
    if (!const {'ar', 'fr', 'en'}.contains(locale)) return;
    state = state.copyWith(locale: locale);
  }

  Future<void> disconnect() async {
    if (_disconnecting) return;
    _disconnecting = true;

    try {
      await _micSub?.cancel();
      _micSub = null;
      await _recorder.stop();

      await _socketSub?.cancel();
      _socketSub = null;

      await _pcmPlayer.interrupt();

      await _channel?.sink.close();
      _channel = null;
    } finally {
      _disconnecting = false;
      if (mounted) {
        state = state.copyWith(
          phase: VoicePhase.idle,
          connected: false,
          clearError: true,
        );
      }
    }
  }

  void _onSocketData(dynamic data) {
    if (data is Uint8List) {
      _onAudioBytes(data);
      return;
    }

    if (data is List<int>) {
      _onAudioBytes(Uint8List.fromList(data));
      return;
    }

    if (data is! String) return;

    dynamic decoded;
    try {
      decoded = jsonDecode(data);
    } catch (_) {
      return;
    }

    if (decoded is! Map) return;

    final event = Map<String, dynamic>.from(decoded);
    final type = event['type']?.toString();

    switch (type) {
      case 'session':
        state = state.copyWith(
          connected: true,
          phase: VoicePhase.listening,
        );
        break;

      case 'status':
        final phase = event['phase']?.toString();
        if (phase == 'listening') {
          state = state.copyWith(phase: VoicePhase.listening);
        } else if (phase == 'thinking') {
          state = state.copyWith(phase: VoicePhase.thinking);
        }
        break;

      case 'transcript_partial':
      case 'transcript_final':
        final text = event['text']?.toString().trim() ?? '';
        if (text.isEmpty) return;

        final role = event['role']?.toString() ?? 'model';
        final turnId = int.tryParse(event['turnId']?.toString() ?? '') ?? 0;

        _upsertTranscript(
          turnId: turnId,
          role: role,
          text: text,
          isFinal: type == 'transcript_final',
        );
        break;

      case 'locale':
        final locale = event['locale']?.toString();
        if (locale != null && const {'ar', 'fr', 'en'}.contains(locale)) {
          state = state.copyWith(locale: locale);
        }
        break;

      case 'interrupted':
        _interruptPlayback();
        break;

      case 'turn_complete':
        if (mounted && state.connected) {
          state = state.copyWith(phase: VoicePhase.listening);
        }
        break;

      case 'error':
        _fail('Hani voice is temporarily unavailable.');
        break;
    }
  }

  void _upsertTranscript({
    required int turnId,
    required String role,
    required String text,
    required bool isFinal,
  }) {
    final lines = List<VoiceTranscriptLine>.from(state.lines);
    final index = lines.indexWhere(
      (line) => line.turnId == turnId && line.role == role,
    );

    if (index >= 0) {
      final previous = lines[index];

      // Never let a late partial hypothesis overwrite the finalized turn.
      if (previous.isFinal && !isFinal) return;

      lines[index] = previous.copyWith(
        text: text,
        isFinal: previous.isFinal || isFinal,
      );
    } else {
      lines.add(
        VoiceTranscriptLine(
          turnId: turnId,
          role: role,
          text: text,
          isFinal: isFinal,
        ),
      );
    }

    state = state.copyWith(
      lines: lines.length > 20
          ? lines.sublist(lines.length - 20)
          : lines,
    );
  }

  void _onAudioBytes(Uint8List bytes) {
    if (!state.connected || bytes.isEmpty) return;

    if (mounted && state.phase != VoicePhase.speaking) {
      state = state.copyWith(phase: VoicePhase.speaking);
    }

    unawaited(_pcmPlayer.add(bytes));
  }

  Future<void> _interruptPlayback() async {
    await _pcmPlayer.interrupt();

    if (mounted && state.connected) {
      state = state.copyWith(phase: VoicePhase.listening);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    state = state.copyWith(
      phase: VoicePhase.error,
      error: message,
      connected: false,
    );
  }

  @override
  void dispose() {
    _micSub?.cancel();
    _socketSub?.cancel();
    _channel?.sink.close();
    _recorder.dispose();
    _pcmPlayer.dispose();
    super.dispose();
  }
}

