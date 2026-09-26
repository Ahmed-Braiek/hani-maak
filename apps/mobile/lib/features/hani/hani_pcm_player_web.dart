// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:web_audio' as web_audio;
import 'dart:math' as math;
import 'dart:typed_data';

/// Low-latency PCM16LE player for Flutter Web.
///
/// Gemini Live sends raw mono PCM16 at 24 kHz. We schedule each received
/// buffer on one WebAudio timeline rather than reopening a WAV/audio element
/// for every chunk. This keeps playback sample-continuous and prevents the
/// repeated-word / repeated-fragment behavior caused by tiny WAV sources.
class HaniPcmPlayer {
  static const int sampleRate = 24000;

  web_audio.AudioContext? _context;
  final Set<web_audio.AudioBufferSourceNode> _active = {};
  double _nextStart = 0;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) {
      final context = _context;
      if (context != null && context.state == 'suspended') {
        await context.resume();
      }
      return;
    }

    final context = web_audio.AudioContext();
    _context = context;
    _nextStart = context.currentTime;

    if (context.state == 'suspended') {
      await context.resume();
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

    final audioBuffer = context.createBuffer(1, sampleCount, sampleRate);
    final channel = audioBuffer.getChannelData(0);
    final bytes = ByteData.sublistView(pcm, 0, evenLength);

    for (var i = 0; i < sampleCount; i++) {
      final sample = bytes.getInt16(i * 2, Endian.little);
      channel[i] = sample / 32768.0;
    }

    final source = context.createBufferSource();
    source.buffer = audioBuffer;
    source.connectNode(context.destination);

    // Keep a tiny scheduling cushion so network jitter does not make two
    // buffers overlap or restart. Never schedule in the past.
    final now = context.currentTime;
    final startAt = math.max(_nextStart, now + 0.025);
    _nextStart = startAt + (sampleCount / sampleRate);

    _active.add(source);
    source.onEnded.first.then((_) => _active.remove(source));
    source.start(startAt);
  }

  Future<void> interrupt() async {
    for (final source in _active.toList()) {
      try {
        source.stop(0);
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
        await context.close();
      } catch (_) {}
    }
  }
}
