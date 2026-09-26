import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Low-latency PCM16LE player for Flutter Web.
///
/// Gemini Live sends mono PCM16 at 24 kHz. Each network PCM buffer is copied
/// into one Web Audio timeline, so chunks play exactly once and remain
/// sample-continuous instead of reopening tiny WAV/audio elements.
class HaniPcmPlayer {
  static const int sampleRate = 24000;

  web.AudioContext? _context;
  final Set<web.AudioBufferSourceNode> _active = <web.AudioBufferSourceNode>{};

  double _nextStart = 0;
  bool _ready = false;

  bool get isPlaying {
    final context = _context;
    if (context == null) return false;
    return context.currentTime + 0.01 < _nextStart;
  }

  Future<void> init() async {
    if (_ready) {
      final context = _context;
      if (context != null && context.state == 'suspended') {
        context.resume();
      }
      return;
    }

    final context = web.AudioContext();
    _context = context;
    _nextStart = context.currentTime;

    if (context.state == 'suspended') {
      context.resume();
    }

    _ready = true;
  }

  Future<void> add(Uint8List pcm) async {
    if (pcm.length < 2) return;
    await init();

    final context = _context;
    if (context == null) return;

    final evenLength = pcm.length - (pcm.length % 2);
    final sampleCount = evenLength ~/ 2;
    if (sampleCount == 0) return;

    final raw = ByteData.sublistView(pcm, 0, evenLength);
    final samples = Float32List(sampleCount);

    for (var i = 0; i < sampleCount; i++) {
      samples[i] = raw.getInt16(i * 2, Endian.little) / 32768.0;
    }

    final audioBuffer = context.createBuffer(1, sampleCount, sampleRate);
    audioBuffer.copyToChannel(samples.toJS, 0);

    final source = context.createBufferSource();
    source.buffer = audioBuffer;
    source.connect(context.destination);

    // Schedule on one monotonic Web Audio clock. The small cushion absorbs
    // network jitter without overlapping or replaying chunks.
    final now = context.currentTime;
    final startAt = math.max(_nextStart, now + 0.025).toDouble();
    final durationSeconds = sampleCount / sampleRate;
    _nextStart = startAt + durationSeconds;

    _active.add(source);
    source.start(startAt);

    // AudioBufferSourceNode is single-use. Remove the Dart reference after its
    // scheduled playback window, while retaining it long enough for barge-in.
    Timer(
      Duration(
        milliseconds: ((startAt - now + durationSeconds) * 1000).ceil() + 150,
      ),
      () => _active.remove(source),
    );
  }

  Future<void> interrupt() async {
    for (final source in _active.toList()) {
      try {
        source.stop();
      } catch (_) {}
    }

    _active.clear();

    final context = _context;
    if (context != null) {
      _nextStart = context.currentTime;
    }
  }

  Future<void> dispose() async {
    await interrupt();

    final context = _context;
    _context = null;
    _ready = false;

    if (context != null) {
      try {
        context.close();
      } catch (_) {}
    }
  }
}
