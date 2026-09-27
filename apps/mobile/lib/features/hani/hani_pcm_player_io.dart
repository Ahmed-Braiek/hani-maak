import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

/// Stable Android/iOS playback for Gemini Live PCM16LE audio.
///
/// Gemini Live returns mono signed PCM16 at 24 kHz. We buffer each assistant
/// turn, wrap it as WAV, write it to temporary storage, then play it through
/// just_audio. This avoids the native flutter_pcm_sound plugin that caused
/// startup crashes on the target Android device.
class HaniPcmPlayer {
  static const int sampleRate = 24000;

  final AudioPlayer _player = AudioPlayer();
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  Future<void> _serial = Future<void>.value();
  bool _disposed = false;
  bool _playing = false;
  File? _activeFile;

  bool get isPlaying => _playing;

  Future<void> init() async {}

  Future<void> add(Uint8List pcm) async {
    if (_disposed || pcm.isEmpty) return;
    _buffer.add(pcm);
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
    final file = File(
      '${Directory.systemTemp.path}/hani_voice_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    _activeFile = file;
    await file.writeAsBytes(wav, flush: true);

    _playing = true;
    try {
      await _player.setFilePath(file.path);
      await _player.play();
      await _player.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
    } finally {
      _playing = false;
      if (_activeFile?.path == file.path) _activeFile = null;
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<void> interrupt() async {
    _buffer.clear();
    await _player.stop();
    final file = _activeFile;
    _activeFile = null;
    if (file != null) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    _playing = false;
  }

  Future<void> dispose() async {
    _disposed = true;
    _buffer.clear();
    await _player.dispose();
    final file = _activeFile;
    _activeFile = null;
    if (file != null) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
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
    u16(1);
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
