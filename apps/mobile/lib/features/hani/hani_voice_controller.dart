import 'dart:async';
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
  const VoiceTranscriptLine({required this.role, required this.text});
  final String role;
  final String text;
}

class HaniVoiceState {
  const HaniVoiceState({
    this.phase = VoicePhase.idle,
    this.lines = const [],
    this.locale = 'ar',
    this.error,
  });

  final VoicePhase phase;
  final List<VoiceTranscriptLine> lines;
  final String locale;
  final String? error;

  HaniVoiceState copyWith({
    VoicePhase? phase,
    List<VoiceTranscriptLine>? lines,
    String? locale,
    String? error,
    bool clearError = false,
  }) {
    return HaniVoiceState(
      phase: phase ?? this.phase,
      lines: lines ?? this.lines,
      locale: locale ?? this.locale,
      error: clearError ? null : error ?? this.error,
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
  final _player = AudioPlayer();
  WebSocketChannel? _channel;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<dynamic>? _socketSub;
  final BytesBuilder _audioBuffer = BytesBuilder(copy: false);

  Future<void> connect() async {
    if (state.phase != VoicePhase.idle && state.phase != VoicePhase.error) {
      return;
    }
    state = state.copyWith(
      phase: VoicePhase.connecting,
      clearError: true,
      lines: const [],
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
        onError: (Object error) => _fail('Voice connection was interrupted.'),
        onDone: () {
          if (mounted && state.phase != VoicePhase.idle) {
            state = state.copyWith(phase: VoicePhase.idle);
          }
        },
      );

      await _startMic();
      state = state.copyWith(phase: VoicePhase.listening);
    } catch (_) {
      _fail('Hani voice could not connect. Tap to try again.');
    }
  }

  Future<void> _startMic() async {
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

    _micSub = stream.listen((chunk) {
      if (state.phase == VoicePhase.listening) {
        _channel?.sink.add(chunk);
      }
    });
  }

  Future<void> stopTalking() async {
    await _micSub?.cancel();
    _micSub = null;
    await _recorder.stop();
    _channel?.sink.add(jsonEncode({'type': 'audio_stream_end'}));
    if (mounted) state = state.copyWith(phase: VoicePhase.thinking);
  }

  Future<void> resumeTalking() async {
    if (_channel == null) return;
    await _player.stop();
    _audioBuffer.clear();
    await _startMic();
    if (mounted) state = state.copyWith(phase: VoicePhase.listening);
  }

  void setLocale(String locale) {
    if (!const {'ar', 'fr', 'en'}.contains(locale)) return;
    state = state.copyWith(locale: locale);
  }

  Future<void> disconnect() async {
    await _micSub?.cancel();
    _micSub = null;
    await _socketSub?.cancel();
    _socketSub = null;
    await _recorder.stop();
    await _player.stop();
    await _channel?.sink.close();
    _channel = null;
    _audioBuffer.clear();
    if (mounted) state = state.copyWith(phase: VoicePhase.idle);
  }

  void _onSocketData(dynamic data) {
    if (data is Uint8List) {
      _audioBuffer.add(data);
      if (mounted && state.phase != VoicePhase.speaking) {
        state = state.copyWith(phase: VoicePhase.speaking);
      }
      return;
    }
    if (data is List<int>) {
      _audioBuffer.add(data);
      if (mounted) state = state.copyWith(phase: VoicePhase.speaking);
      return;
    }
    if (data is! String) return;

    final event = jsonDecode(data);
    if (event is! Map) return;
    final type = event['type']?.toString();

    if (type == 'transcript') {
      final text = event['text']?.toString().trim() ?? '';
      if (text.isEmpty) return;
      final role = event['role']?.toString() ?? 'model';
      state = state.copyWith(
        lines: [
          ...state.lines,
          VoiceTranscriptLine(role: role, text: text),
        ],
      );
    } else if (type == 'locale') {
      final locale = event['locale']?.toString();
      if (locale != null) state = state.copyWith(locale: locale);
    } else if (type == 'interrupted') {
      _player.stop();
      _audioBuffer.clear();
      state = state.copyWith(phase: VoicePhase.listening);
    } else if (type == 'turn_complete') {
      _playBufferedTurn();
    } else if (type == 'error') {
      _fail('Hani voice is temporarily unavailable.');
    }
  }

  Future<void> _playBufferedTurn() async {
    final pcm = _audioBuffer.takeBytes();
    if (pcm.isEmpty) {
      if (mounted) state = state.copyWith(phase: VoicePhase.listening);
      return;
    }

    final wav = _pcmToWav(pcm, sampleRate: 24000);
    try {
      await _player.setAudioSource(_BytesAudioSource(wav));
      state = state.copyWith(phase: VoicePhase.speaking);
      await _player.play();
      await _player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      );
      if (mounted) state = state.copyWith(phase: VoicePhase.listening);
    } catch (_) {
      if (mounted) state = state.copyWith(phase: VoicePhase.listening);
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
    state = state.copyWith(phase: VoicePhase.error, error: message);
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
