import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';

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

  static const int _playbackSampleRate = 24000;
  static const int _bytesPerSecond = _playbackSampleRate * 2;
  static const int _chunkBytes = 15360; // 320 ms of 24 kHz mono PCM16.

  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final Queue<Uint8List> _playQueue = Queue<Uint8List>();
  final List<int> _pendingPcm = <int>[];

  WebSocketChannel? _channel;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<dynamic>? _socketSub;
  bool _playingQueue = false;
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

      await _player.stop();
      _playQueue.clear();
      _pendingPcm.clear();
      _playingQueue = false;

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
        if (phase == 'listening' && !_playingQueue) {
          state = state.copyWith(phase: VoicePhase.listening);
        } else if (phase == 'thinking' && !_playingQueue) {
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
        _flushPendingAudio();
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
    _pendingPcm.addAll(bytes);

    while (_pendingPcm.length >= _chunkBytes) {
      final chunk = Uint8List.fromList(_pendingPcm.sublist(0, _chunkBytes));
      _pendingPcm.removeRange(0, _chunkBytes);
      _playQueue.add(chunk);
    }

    if (!_playingQueue && _playQueue.isNotEmpty) {
      unawaited(_drainPlaybackQueue());
    }
  }

  void _flushPendingAudio() {
    if (_pendingPcm.isNotEmpty) {
      _playQueue.add(Uint8List.fromList(_pendingPcm));
      _pendingPcm.clear();
    }

    if (!_playingQueue && _playQueue.isNotEmpty) {
      unawaited(_drainPlaybackQueue());
    }
  }

  Future<void> _drainPlaybackQueue() async {
    if (_playingQueue) return;
    _playingQueue = true;

    try {
      while (_playQueue.isNotEmpty && state.connected) {
        final pcm = _playQueue.removeFirst();
        if (pcm.isEmpty) continue;

        if (mounted) {
          state = state.copyWith(phase: VoicePhase.speaking);
        }

        final wav = _pcmToWav(
          pcm,
          sampleRate: _playbackSampleRate,
        );

        await _player.setAudioSource(_BytesAudioSource(wav));
        await _player.play();

        await _player.playerStateStream.firstWhere(
          (s) =>
              s.processingState == ProcessingState.completed ||
              !state.connected,
        );
      }
    } catch (_) {
      // A user barge-in intentionally stops playback; do not surface it as error.
    } finally {
      _playingQueue = false;
      if (mounted && state.connected) {
        state = state.copyWith(phase: VoicePhase.listening);
      }
    }
  }

  Future<void> _interruptPlayback() async {
    _playQueue.clear();
    _pendingPcm.clear();

    try {
      await _player.stop();
    } catch (_) {}

    _playingQueue = false;

    if (mounted && state.connected) {
      state = state.copyWith(phase: VoicePhase.listening);
    }
  }

  Uint8List _pcmToWav(Uint8List pcm, {required int sampleRate}) {
    final dataLength = pcm.length;
    final bytes = ByteData(44 + dataLength);

    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataLength, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, dataLength, Endian.little);

    final output = bytes.buffer.asUint8List();
    output.setRange(44, output.length, pcm);
    return output;
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
    _player.dispose();
    super.dispose();
  }
}

class _BytesAudioSource extends StreamAudioSource {
  _BytesAudioSource(this.bytes);

  final Uint8List bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final from = start ?? 0;
    final to = end ?? bytes.length;

    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: to - from,
      offset: from,
      stream: Stream.value(bytes.sublist(from, to)),
      contentType: 'audio/wav',
    );
  }
}
