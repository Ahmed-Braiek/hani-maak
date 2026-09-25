import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'hani_voice_controller.dart';

class HaniVoiceScreen extends ConsumerWidget {
  const HaniVoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(haniVoiceProvider);
    final controller = ref.read(haniVoiceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hani Voice'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language_rounded),
            initialValue: state.locale,
            onSelected: controller.setLocale,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ar', child: Text('Tunisian / العربية')),
              PopupMenuItem(value: 'fr', child: Text('Français')),
              PopupMenuItem(value: 'en', child: Text('English')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  const Text(
                    'Talk naturally.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Hani already knows the caregiver and patient context.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: HaniColors.muted),
                  ),
                  const SizedBox(height: 30),
                  Center(child: _VoiceOrb(phase: state.phase)),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      _phaseLabel(state.phase),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: HaniColors.muted,
                      ),
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        state.error!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  if (state.lines.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    const Text(
                      'Live transcript',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...state.lines.take(12).map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Align(
                          alignment: line.role == 'user'
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 330),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: line.role == 'user'
                                  ? HaniColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: line.role == 'user'
                                  ? null
                                  : Border.all(
                                      color: const Color(0xFFE8EEEC),
                                    ),
                            ),
                            child: Text(
                              line.text,
                              style: TextStyle(
                                color: line.role == 'user'
                                    ? Colors.white
                                    : HaniColors.ink,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE8EEEC)),
                ),
              ),
              child: Row(
                children: [
                  if (state.phase == VoicePhase.idle ||
                      state.phase == VoicePhase.error)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: controller.connect,
                        icon: const Icon(Icons.mic_rounded),
                        label: const Text('Start live voice'),
                      ),
                    )
                  else ...[
                    Expanded(
                      child: state.phase == VoicePhase.listening
                          ? FilledButton.icon(
                              onPressed: controller.stopTalking,
                              icon: const Icon(Icons.stop_circle_outlined),
                              label: const Text('I’m done speaking'),
                            )
                          : OutlinedButton.icon(
                              onPressed: state.phase == VoicePhase.speaking
                                  ? controller.resumeTalking
                                  : null,
                              icon: const Icon(Icons.mic_rounded),
                              label: const Text('Interrupt and speak'),
                            ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.outlined(
                      tooltip: 'End call',
                      onPressed: controller.disconnect,
                      icon: const Icon(Icons.call_end_rounded),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _phaseLabel(VoicePhase phase) {
    switch (phase) {
      case VoicePhase.connecting:
        return 'Connecting securely…';
      case VoicePhase.listening:
        return 'Listening';
      case VoicePhase.thinking:
        return 'Thinking';
      case VoicePhase.speaking:
        return 'Hani is speaking';
      case VoicePhase.error:
        return 'Connection issue';
      case VoicePhase.idle:
        return 'Ready when you are';
    }
  }
}

class _VoiceOrb extends StatelessWidget {
  const _VoiceOrb({required this.phase});
  final VoicePhase phase;

  @override
  Widget build(BuildContext context) {
    final active = phase == VoicePhase.listening ||
        phase == VoicePhase.thinking ||
        phase == VoicePhase.speaking;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: active ? 154 : 132,
      height: active ? 154 : 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: HaniColors.primarySoft,
        border: Border.all(
          color: HaniColors.primary.withValues(alpha: active ? .36 : .18),
          width: active ? 10 : 6,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  blurRadius: 34,
                  spreadRadius: 2,
                  color: HaniColors.primary.withValues(alpha: .13),
                ),
              ]
            : const [],
      ),
      child: Icon(
        phase == VoicePhase.speaking
            ? Icons.graphic_eq_rounded
            : Icons.mic_rounded,
        size: 56,
        color: HaniColors.primary,
      ),
    );
  }
}
