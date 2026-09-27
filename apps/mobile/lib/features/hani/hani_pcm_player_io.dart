import 'dart:async';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

/// Android/iOS PCM16LE playback for Gemini Live using just_audio.
///
/// Gemini Live returns mono signed PCM16 at 24 kHz. We buffer small chunks,
/// wrap them in an in-memory WAV container, and play them sequentially.
/// This avoids the flutter_pcm_sound native plugin that was crashing on the
/// user's Android device while keeping Hani's spoken replies audible.
class HaniPcmPlayer {
  static const int sampleRate = 24000;
  static const int _targetBytes = 24000; // ~500 ms of mono PCM16 at 24 kHz.

  final AudioPlayer _player = AudioPlayer();
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  Future<void> _serial = Future<void>.value();
  bool _disposed = false;
  bool _playing = false;

  bool get isPlaying => _playing;

  Future<void> init() async {
    // just_audio initializes lazily when the first in-memory WAV is loaded.
  }

  Future<void> add(Uint8List pcm) {
    if (_disposed || pcm.isEmpty) return Future<void>.value();
    _buffer.add(pcm);
    if (_buffer.length < _targetBytes) return Future<void>.value();

    final bytes = _buffer.takeBytes();
    return _enqueue(() => _playPcm(bytes));
  }

  Future<void> flush() {
    if (_disposed || _buffer.length == 0) return Future<void>.value();
    final bytes = _buffer.takeBytes();
    return _enqueue(() => _playPcm(bytes));
  }

  Future<void> _playPcm(Uint8List pcm) async {
    if (_disposed || pcm.length < 2) return;
    final evenLength = pcm.length - (pcm.length % 2);
    final payload = evenLength == pcm.length
        ? pcm
        : Uint8List.sublistView(pcm, 0, evenLength);

    final wav = _wavBytes(payload);
    _playing = true;
    try {
      await _player.setAudioSource(_MemoryAudioSource(wav));
      await _player.play();
      await _player.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
    } finally {
      _playing = false;
    }
  }

  Future<void> interrupt() async {
    _buffer.clear();
    await _player.stop();
    _playing = false;
  }

  Future<void> dispose() async {
    _disposed = true;
    _buffer.clear();
    await _player.dispose();
    _playing = false;
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _serial.then((_) => operation());
    _serial = next.catchError((_) {});
    return next;
  }

  Uint8List _wavBytes(Uint8List pcm) {
    const channels = 1;
    const bitsPerSample = 16;
    const byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    const blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = pcm.length;
    final fileSize = 36 + dataSize;

    final out = BytesBuilder(copy: false);
    void ascii(String value) => out.add(value.codeUnits);
    void u16(int value) {
      final b = ByteData(2)..setUint16(0, value, Endian.little);
      out.add(b.buffer.asUint8List());
    }
    void u32(int value) {
      final b = ByteData(4)..setUint32(0, value, Endian.little);
      out.add(b.buffer.asUint8List());
    }

    ascii('RIFF');
    u32(fileSize);
    ascii('WAVE');
    ascii('fmt ');
    u32(16);
    u16(1); // PCM
    u16(channels);
    u32(sampleRate);
    u32(byteRate);
    u16(blockAlign);
    u16(bitsPerSample);
    ascii('data');
    u32(dataSize);
    out.add(pcm);
    return out.toBytes();
  }
}

class _MemoryAudioSource extends StreamAudioSource {
  _MemoryAudioSource(this.bytes);

  final Uint8List bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final first = start ?? 0;
    final last = end ?? bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: last - first,
      offset: first,
      stream: Stream.value(bytes.sublist(first, last)),
      contentType: 'audio/wav',
    );
  }
}
