import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';
import '../../core/notification_service.dart';
import '../../core/session/caregiver_identity.dart';
import '../../core/settings/app_settings.dart';
import 'hani_pcm_player.dart';

enum VoicePhase { idle, connecting, listening, thinking, speaking, ending, error }

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
    this.sessionId,
    this.analysisStatus,
  });

  final VoicePhase phase;
  final List<VoiceTranscriptLine> lines;
  final String locale;
  final String? error;
  final bool connected;
  final String? sessionId;
  final String? analysisStatus;

  HaniVoiceState copyWith({
    VoicePhase? phase,
    List<VoiceTranscriptLine>? lines,
    String? locale,
    String? error,
    bool? connected,
    String? sessionId,
    String? analysisStatus,
    bool clearError = false,
    bool clearSession = false,
    bool clearAnalysisStatus = false,
  }) {
    return HaniVoiceState(
      phase: phase ?? this.phase,
      lines: lines ?? this.lines,
      locale: locale ?? this.locale,
      error: clearError ? null : error ?? this.error,
      connected: connected ?? this.connected,
      sessionId: clearSession ? null : sessionId ?? this.sessionId,
      analysisStatus: clearAnalysisStatus
          ? null
          : analysisStatus ?? this.analysisStatus,
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

  static const int _bargeInPreRollBytes = 16000; // ~500 ms at 16 kHz PCM16.
  static const double _bargeInRmsThreshold = 0.055;
  static const double _bargeInPeakThreshold = 0.18;
  static const int _bargeInRequiredChunks = 2;

  final _recorder = AudioRecorder();
  final _pcmPlayer = HaniPcmPlayer();
  final List<Uint8List> _bargePreRoll = <Uint8List>[];

  WebSocketChannel? _channel;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<dynamic>? _socketSub;
  bool _disconnecting = false;
  bool _bargeInActive = false;
  bool _dropOldModelAudio = false;
  int _bargePreRollBytes = 0;
  int _bargeSpeechChunks = 0;
  Completer<void>? _callEndedCompleter;
  Timer? _watchdog;
  DateTime _lastServerActivity = DateTime.now();
  DateTime? _lastMicSpeechAt;
  DateTime? _lastMicRestartAt;
  DateTime _phaseStartedAt = DateTime.now();
  bool _recoveringMic = false;
  bool _postCallNotificationSent = false;

  Future<void> connect() async {
    if (state.phase != VoicePhase.idle && state.phase != VoicePhase.error) {
      return;
    }

    _postCallNotificationSent = false;
    _phaseStartedAt = DateTime.now();
    _lastServerActivity = DateTime.now();
    _lastMicSpeechAt = null;
    state = state.copyWith(
      phase: VoicePhase.connecting,
      clearError: true,
      lines: const [],
      connected: false,
      clearSession: true,
      clearAnalysisStatus: true,
    );

    try {
      final identity = await CaregiverIdentity.resolve();
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBase}/api/v1/heni/voice-token'),
            headers: {
              'content-type': 'application/json',
              ...identity.authHeaders,
            },
            body: jsonEncode({
              'locale': state.locale,
              'caregiverId': identity.caregiverId,
              'patientId': identity.patientId,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('voice_token_unavailable');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['token']?.toString();
      final wsUrl = body['wsUrl']?.toString();
      final issuedSessionId = body['sessionId']?.toString();

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
      _startWatchdog();
      _phaseStartedAt = DateTime.now();

      state = state.copyWith(
        phase: VoicePhase.listening,
        connected: true,
        sessionId: issuedSessionId,
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
      _onMicChunk,
      onError: (_) {
        if (state.connected && !_disconnecting) {
          unawaited(_recoverMic());
        }
      },
      onDone: () {
        _micSub = null;
        if (state.connected && !_disconnecting) {
          unawaited(_recoverMic());
        }
      },
    );
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _watchdogTick(),
    );
  }

  void _watchdogTick() {
    if (!mounted || !state.connected || _disconnecting) return;
    final now = DateTime.now();

    if (state.phase == VoicePhase.listening) {
      final recentSpeech = _lastMicSpeechAt != null &&
          now.difference(_lastMicSpeechAt!) < const Duration(seconds: 5);
      final serverSilent =
          now.difference(_lastServerActivity) > const Duration(seconds: 7);
      if (recentSpeech && serverSilent) {
        _channel?.sink.add(jsonEncode({'type': 'audio_stream_end'}));
        _phaseStartedAt = now;
        state = state.copyWith(phase: VoicePhase.thinking);
        unawaited(_recoverMic());
      } else if (now.difference(_phaseStartedAt) >
          const Duration(seconds: 45)) {
        unawaited(_ensureMic());
        _phaseStartedAt = now;
      }
      return;
    }

    if (state.phase == VoicePhase.thinking &&
        now.difference(_phaseStartedAt) > const Duration(seconds: 18)) {
      unawaited(_recoverMic());
      _phaseStartedAt = now;
      state = state.copyWith(
        phase: VoicePhase.listening,
        clearError: true,
      );
      return;
    }

    if (state.phase == VoicePhase.speaking &&
        !_pcmPlayer.isPlaying &&
        now.difference(_phaseStartedAt) > const Duration(seconds: 4)) {
      unawaited(_ensureMic());
      _phaseStartedAt = now;
      state = state.copyWith(phase: VoicePhase.listening);
    }
  }

  Future<void> _ensureMic() async {
    if (!state.connected || _disconnecting) return;
    if (_micSub == null) {
      await _startMic();
    }
  }

  Future<void> _recoverMic() async {
    if (_recoveringMic || _disconnecting || !state.connected) return;
    final now = DateTime.now();
    if (_lastMicRestartAt != null &&
        now.difference(_lastMicRestartAt!) < const Duration(seconds: 4)) {
      return;
    }

    _recoveringMic = true;
    _lastMicRestartAt = now;
    try {
      await _micSub?.cancel();
      _micSub = null;
      try {
        await _recorder.stop();
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (state.connected && !_disconnecting) {
        await _startMic();
      }
    } catch (_) {
      if (mounted && state.connected) {
        state = state.copyWith(
          phase: VoicePhase.error,
          error: 'Microphone recovery failed. Reconnect the voice call.',
          connected: false,
        );
      }
    } finally {
      _recoveringMic = false;
    }
  }

  void _onMicChunk(Uint8List chunk) {
    if (_channel == null || !state.connected || chunk.isEmpty) return;

    final level = _pcmLevel(chunk);
    final likelyHumanSpeech =
        level.$1 >= _bargeInRmsThreshold &&
        level.$2 >= _bargeInPeakThreshold;
    if (likelyHumanSpeech) {
      _lastMicSpeechAt = DateTime.now();
    }

    final assistantSpeaking =
        state.phase == VoicePhase.speaking || _pcmPlayer.isPlaying;

    if (!assistantSpeaking && !_bargeInActive) {
      _resetBargeGate();
      _channel?.sink.add(chunk);
      return;
    }

    if (_bargeInActive) {
      _channel?.sink.add(chunk);
      return;
    }

    // While Hani is speaking, keep a short local pre-roll instead of sending
    // speaker echo straight back to Gemini. This is what prevents false
    // self-interruptions while preserving the first syllable of a real barge-in.
    _pushBargePreRoll(chunk);

    if (likelyHumanSpeech) {
      _bargeSpeechChunks += 1;
    } else if (_bargeSpeechChunks > 0) {
      _bargeSpeechChunks -= 1;
    }

    if (_bargeSpeechChunks < _bargeInRequiredChunks) return;

    _bargeInActive = true;
    _dropOldModelAudio = true;
    _bargeSpeechChunks = 0;

    // Stop Hani locally immediately. Gemini will then receive the buffered
    // user speech and its server-side VAD will register the genuine barge-in.
    unawaited(_pcmPlayer.interrupt());

    if (mounted) {
      state = state.copyWith(phase: VoicePhase.listening);
    }

    for (final buffered in _bargePreRoll) {
      _channel?.sink.add(buffered);
    }
    _bargePreRoll.clear();
    _bargePreRollBytes = 0;
  }

  void _pushBargePreRoll(Uint8List chunk) {
    _bargePreRoll.add(Uint8List.fromList(chunk));
    _bargePreRollBytes += chunk.length;

    while (_bargePreRollBytes > _bargeInPreRollBytes &&
        _bargePreRoll.isNotEmpty) {
      final removed = _bargePreRoll.removeAt(0);
      _bargePreRollBytes -= removed.length;
    }
  }

  (double, double) _pcmLevel(Uint8List pcm) {
    final evenLength = pcm.length - (pcm.length % 2);
    if (evenLength <= 0) return (0, 0);

    final data = ByteData.sublistView(pcm, 0, evenLength);
    var sumSquares = 0.0;
    var peak = 0.0;
    final samples = evenLength ~/ 2;

    for (var i = 0; i < samples; i++) {
      final normalized =
          data.getInt16(i * 2, Endian.little).abs() / 32768.0;
      sumSquares += normalized * normalized;
      if (normalized > peak) peak = normalized;
    }

    final rms = samples == 0 ? 0.0 : math.sqrt(sumSquares / samples);
    return (rms, peak);
  }

  void _resetBargeGate() {
    _bargePreRoll.clear();
    _bargePreRollBytes = 0;
    _bargeSpeechChunks = 0;
  }

  void setLocale(String locale) {
    if (!const {'tn', 'ar', 'fr', 'en'}.contains(locale)) return;
    state = state.copyWith(locale: locale);
  }

  Future<String?> endCall() async {
    if (_disconnecting) return state.sessionId;
    _disconnecting = true;
    final sessionId = state.sessionId;

    try {
      _watchdog?.cancel();
      _watchdog = null;
      await _micSub?.cancel();
      _micSub = null;
      await _recorder.stop();
      await _pcmPlayer.interrupt();

      if (mounted && _channel != null && state.connected) {
        state = state.copyWith(
          phase: VoicePhase.ending,
          clearError: true,
        );
        _callEndedCompleter = Completer<void>();
        _channel!.sink.add(jsonEncode({'type': 'call_end'}));
        try {
          await _callEndedCompleter!.future.timeout(
            const Duration(seconds: 5),
          );
        } on TimeoutException {
          // The server also finalizes on disconnect. Never trap the user here.
          if (sessionId != null && sessionId.isNotEmpty) {
            unawaited(_notifyPostCall(sessionId, analysisReady: false));
          }
        }
      }

      await _socketSub?.cancel();
      _socketSub = null;

      _bargeInActive = false;
      _dropOldModelAudio = false;
      _resetBargeGate();

      await _channel?.sink.close();
      _channel = null;
    } finally {
      _callEndedCompleter = null;
      _disconnecting = false;
      if (mounted) {
        state = state.copyWith(
          phase: VoicePhase.idle,
          connected: false,
          clearError: true,
        );
      }
    }

    return sessionId;
  }

  Future<void> disconnect() async {
    await endCall();
  }

  Future<void> _notifyPostCall(
    String conversationId, {
    required bool analysisReady,
  }) async {
    if (_postCallNotificationSent) return;
    _postCallNotificationSent = true;
    final language = switch (state.locale) {
      'tn' => HaniLanguage.tounsi,
      'fr' => HaniLanguage.french,
      'en' => HaniLanguage.english,
      _ => HaniLanguage.arabic,
    };
    try {
      await HaniNotificationService.instance.showPostCall(
        conversationId: conversationId,
        language: language,
        analysisReady: analysisReady,
      );
    } catch (_) {
      // Notifications are supplementary and must never break a voice call.
    }
  }

  void _onSocketData(dynamic data) {
    _lastServerActivity = DateTime.now();
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
          sessionId: event['sessionId']?.toString(),
        );
        break;

      case 'status':
        final phase = event['phase']?.toString();
        if (phase == 'listening') {
          if (!_pcmPlayer.isPlaying) {
            _phaseStartedAt = DateTime.now();
            state = state.copyWith(phase: VoicePhase.listening);
            unawaited(_ensureMic());
          }
        } else if (phase == 'thinking') {
          _dropOldModelAudio = false;
          _phaseStartedAt = DateTime.now();
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
        if (role == 'user' && type == 'transcript_final' && state.connected) {
          _phaseStartedAt = DateTime.now();
          state = state.copyWith(phase: VoicePhase.thinking);
        }
        break;

      case 'locale':
        final locale = event['locale']?.toString();
        if (locale != null && const {'tn', 'ar', 'fr', 'en'}.contains(locale)) {
          state = state.copyWith(locale: locale);
        }
        break;

      case 'interrupted':
        _dropOldModelAudio = false;
        _interruptPlayback();
        break;

      case 'turn_complete':
        _dropOldModelAudio = false;
        unawaited(
          _pcmPlayer.flush().whenComplete(() {
            if (mounted && state.connected) {
              _phaseStartedAt = DateTime.now();
              state = state.copyWith(phase: VoicePhase.listening);
              unawaited(_ensureMic());
            }
          }).catchError((_) {
            if (mounted && state.connected) {
              state = state.copyWith(
                phase: VoicePhase.error,
                error: 'Hani audio playback failed. Reconnect the voice call.',
              );
            }
          }),
        );
        break;

      case 'call_ended':
        final serverSessionId = event['sessionId']?.toString();
        state = state.copyWith(
          sessionId: serverSessionId,
          analysisStatus:
              event['analysisStatus']?.toString() ?? 'not_started',
        );
        final completer = _callEndedCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.complete();
        }
        if (serverSessionId != null && serverSessionId.isNotEmpty) {
          unawaited(
            _notifyPostCall(
              serverSessionId,
              analysisReady: state.analysisStatus == 'completed',
            ),
          );
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
    if (!state.connected || bytes.isEmpty || _dropOldModelAudio) return;

    // A new assistant response starts a fresh possible barge-in window.
    _bargeInActive = false;
    _resetBargeGate();

    if (mounted && state.phase != VoicePhase.speaking) {
      _phaseStartedAt = DateTime.now();
      state = state.copyWith(phase: VoicePhase.speaking);
    }

    unawaited(
      _pcmPlayer.add(bytes).catchError((_) {
        if (mounted && state.connected) {
          state = state.copyWith(
            phase: VoicePhase.error,
            error: 'Hani audio playback failed. Reconnect the voice call.',
          );
        }
      }),
    );
  }

  Future<void> _interruptPlayback() async {
    await _pcmPlayer.interrupt();

    if (mounted && state.connected) {
      _phaseStartedAt = DateTime.now();
      state = state.copyWith(phase: VoicePhase.listening);
      unawaited(_ensureMic());
    }
  }

  void _fail(String message) {
    _watchdog?.cancel();
    _watchdog = null;
    if (!mounted) return;
    state = state.copyWith(
      phase: VoicePhase.error,
      error: message,
      connected: false,
    );
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _micSub?.cancel();
    _socketSub?.cancel();
    _channel?.sink.close();
    _recorder.dispose();
    _pcmPlayer.dispose();
    super.dispose();
  }
}

