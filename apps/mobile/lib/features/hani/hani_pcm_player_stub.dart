import 'dart:typed_data';

/// Native fallback. The current hackathon preview is Flutter Web; native
/// playback will get a dedicated low-latency implementation before store
/// packaging. Keeping this interface lets the rest of the voice controller
/// remain platform-agnostic.
class HaniPcmPlayer {
  Future<void> init() async {}
  Future<void> add(Uint8List pcm) async {}
  Future<void> interrupt() async {}
  Future<void> dispose() async {}
}
