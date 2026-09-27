import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_brand_logo.dart';
import 'models/hani_emotion_analysis.dart';

class HaniCallResultScreen extends StatefulWidget {
  const HaniCallResultScreen({
    super.key,
    required this.conversationId,
  });

  final String conversationId;

  @override
  State<HaniCallResultScreen> createState() => _HaniCallResultScreenState();
}

class _HaniCallResultScreenState extends State<HaniCallResultScreen> {
  final HaniEmotionApi _api = HaniEmotionApi();
  HaniEmotionAnalysis? _analysis;
  Object? _error;
  Timer? _timer;
  int _pollCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await _api.fetch(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _analysis = result;
        _error = null;
      });

      if (result.status == 'processing' || result.status == 'not_started') {
        _pollCount += 1;
        if (_pollCount < 30) {
          _timer?.cancel();
          _timer = Timer(const Duration(seconds: 2), _load);
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
      _pollCount += 1;
      if (_pollCount < 10) {
        _timer?.cancel();
        _timer = Timer(const Duration(seconds: 3), _load);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F6),
      appBar: AppBar(
        title: const HaniBrandLogo(
          height: 38,
          variant: HaniBrandVariant.horizontal,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          const Text(
            'Call completed',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hani is processing the vocal characteristics from the patient-side audio only.',
            style: TextStyle(
              color: HaniColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          if (_error != null && analysis == null)
            _StatusCard(
              icon: Icons.sync_problem_rounded,
              title: 'Analysis is temporarily unavailable',
              body: 'The Hani call was completed normally. Vocal emotion analysis can be retried separately.',
            )
          else if (analysis == null ||
              analysis.status == 'processing' ||
              analysis.status == 'not_started')
            const _StatusCard(
              icon: Icons.graphic_eq_rounded,
              title: 'Analyzing vocal emotion',
              body: 'This runs after the call and does not affect the live Hani conversation.',
              loading: true,
            )
          else if (analysis.status == 'insufficient_audio')
            const _StatusCard(
              icon: Icons.hearing_disabled_rounded,
              title: 'Not enough speech',
              body: 'Not enough patient speech was available to estimate vocal emotion reliably.',
            )
          else if (analysis.status == 'failed')
            _StatusCard(
              icon: Icons.info_outline_rounded,
              title: 'Vocal emotion analysis unavailable',
              body: analysis.failureMessage?.isNotEmpty == true
                  ? analysis.failureMessage!
                  : 'The call remains saved even though this supplementary analysis could not be completed.',
            )
          else
            _CompletedAnalysis(analysis: analysis),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HaniColors.line),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: HaniColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vocal emotion estimates are generated from characteristics of the speaker’s voice. They are probabilistic and are not a medical or psychiatric diagnosis.',
                    style: TextStyle(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedAnalysis extends StatelessWidget {
  const _CompletedAnalysis({required this.analysis});

  final HaniEmotionAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final dominant = analysis.dominantEmotion ?? 'unknown';
    final confidence = analysis.confidence ?? 0;
    final sorted = analysis.distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusCard(
          icon: Icons.multiline_chart_rounded,
          title: 'Detected vocal emotion',
          body: '${_label(dominant)} · ${_percent(confidence)}',
        ),
        const SizedBox(height: 18),
        const Text(
          'Vocal emotional signals',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...sorted.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    _label(entry.key),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: entry.value.clamp(0, 1),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 42,
                  child: Text(
                    _percent(entry.value),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (analysis.timeline.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'Emotion throughout the call',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...analysis.timeline.map(
            (segment) => Card(
              child: ListTile(
                leading: const Icon(Icons.graphic_eq_rounded),
                title: Text(_label(segment.dominantEmotion)),
                subtitle: Text(
                  '${_time(segment.startMs)}–${_time(segment.endMs)} · confidence ${_percent(segment.confidence)}',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _percent(double value) => '${(value * 100).round()}%';

  static String _time(int ms) {
    final seconds = (ms / 1000).round();
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  static String _label(String value) {
    return switch (value) {
      'angry' => 'Angry',
      'disgusted' => 'Disgusted',
      'fearful' => 'Fearful',
      'happy' => 'Happy',
      'neutral' => 'Neutral',
      'other' => 'Other',
      'sad' => 'Sad',
      'surprised' => 'Surprised',
      _ => 'Uncertain',
    };
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.body,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: HaniColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HaniColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(body, style: const TextStyle(height: 1.4)),
                if (loading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
