import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

/// Low-latency native PCM16LE player for Gemini Live audio.
///
/// Gemini Live returns mono signed PCM16 at 24 kHz. The previous Android/iOS
/// implementation was a no-op, which explained why live transcription worked
/// while the installed app stayed silent.
class HaniPcmPlayer {
  static const int sampleRate = 24000;

  bool _ready = false;
  bool _playing = false;

  bool get isPlaying => _playing;

  Future<void> init() async {
    if (_ready) return;

    await FlutterPcmSound.setup(
      sampleRate: sampleRate,
      channelCount: 1,
      iosAudioCategory: IosAudioCategory.playAndRecord,
      iosAllowBackgroundAudio: false,
    );
    await FlutterPcmSound.setFeedThreshold(2400);
    FlutterPcmSound.setFeedCallback((remainingFrames) {
      if (remainingFrames == 0) {
        _playing = false;
      }
    });
    _ready = true;
  }

  Future<void> add(Uint8List pcm) async {
    if (pcm.length < 2) return;
    await init();

    final evenLength = pcm.length - (pcm.length % 2);
    final data = ByteData.sublistView(pcm, 0, evenLength);
    final samples = List<int>.generate(
      evenLength ~/ 2,
      (index) => data.getInt16(index * 2, Endian.little),
      growable: false,
    );

    if (!_playing) {
      _playing = true;
      FlutterPcmSound.start();
    }

    await FlutterPcmSound.feed(PcmArrayInt16.fromList(samples));
  }

  Future<void> interrupt() async {
    if (!_ready) return;
    _playing = false;
    try {
      await FlutterPcmSound.stop(clear: true);
    } catch (_) {
      try {
        await FlutterPcmSound.clear();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    await interrupt();
    _ready = false;
  }
}
