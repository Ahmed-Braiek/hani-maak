import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

/// Low-latency native PCM16LE playback for Gemini Live.
///
/// Gemini Live sends mono signed PCM16 at 24 kHz. This implementation feeds
/// the raw samples directly to Android/iOS instead of silently dropping them.
class HaniPcmPlayer {
  static const int sampleRate = 24000;

  bool _ready = false;
  bool _playing = false;
  Future<void> _serial = Future<void>.value();

  bool get isPlaying => _playing;

  Future<void> init() {
    return _enqueue(() async {
      if (_ready) return;
      await FlutterPcmSound.setup(
        sampleRate: sampleRate,
        channelCount: 1,
        iosAudioCategory: IosAudioCategory.playAndRecord,
      );
      await FlutterPcmSound.setFeedThreshold(sampleRate ~/ 10);
      FlutterPcmSound.setFeedCallback((remainingFrames) {
        _playing = remainingFrames > 0;
      });
      _ready = true;
    });
  }

  Future<void> add(Uint8List pcm) {
    return _enqueue(() async {
      if (pcm.length < 2) return;
      if (!_ready) {
        await FlutterPcmSound.setup(
          sampleRate: sampleRate,
          channelCount: 1,
          iosAudioCategory: IosAudioCategory.playAndRecord,
        );
        await FlutterPcmSound.setFeedThreshold(sampleRate ~/ 10);
        FlutterPcmSound.setFeedCallback((remainingFrames) {
          _playing = remainingFrames > 0;
        });
        _ready = true;
      }

      final evenLength = pcm.length - (pcm.length % 2);
      final data = ByteData.sublistView(pcm, 0, evenLength);
      final samples = List<int>.generate(
        evenLength ~/ 2,
        (index) => data.getInt16(index * 2, Endian.little),
        growable: false,
      );

      if (samples.isEmpty) return;
      _playing = true;
      await FlutterPcmSound.feed(PcmArrayInt16.fromList(samples));
      FlutterPcmSound.start();
    });
  }

  Future<void> interrupt() {
    return _enqueue(() async {
      if (!_ready) {
        _playing = false;
        return;
      }

      // flutter_pcm_sound 3.x intentionally has no public clear/stop queue API.
      // Releasing is the supported deterministic way to drop queued model
      // audio during a real barge-in. The next chunk lazily reinitializes.
      FlutterPcmSound.setFeedCallback(null);
      await FlutterPcmSound.release();
      _ready = false;
      _playing = false;
    });
  }

  Future<void> dispose() async {
    await interrupt();
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _serial.then((_) => operation());
    _serial = next.catchError((_) {});
    return next;
  }
}
