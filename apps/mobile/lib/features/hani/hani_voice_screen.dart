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
    final active = state.connected &&
        state.phase != VoicePhase.idle &&
        state.phase != VoicePhase.error;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () async {
                      await controller.disconnect();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Hani',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Private caregiver voice companion',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: HaniColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.language_rounded),
                    initialValue: state.locale,
                    enabled: !active,
                    onSelected: controller.setLocale,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'ar',
                        child: Text('Tunisian / العربية'),
                      ),
                      PopupMenuItem(
                        value: 'fr',
                        child: Text('Français'),
                      ),
                      PopupMenuItem(
                        value: 'en',
                        child: Text('English'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: _LiveOrb(
                      phase: state.phase,
                      active: active,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: Text(
                      _phaseLabel(state.phase),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Center(
                    child: Text(
                      active
                          ? 'Just talk. Hani listens continuously — no send button.'
                          : 'Start a private live conversation with Hani.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: HaniColors.muted,
                        height: 1.4,
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
                    const SizedBox(height: 36),
                    Row(
                      children: [
                        const Text(
                          'Live conversation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: HaniColors.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: HaniColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...state.lines.takeLast(8).map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Align(
                          alignment: line.role == 'user'
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 330),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: line.role == 'user'
                                    ? HaniColors.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: line.role == 'user'
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFE4EBE8),
                                      ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                child: Text(
                                  line.text,
                                  style: TextStyle(
                                    color: line.role == 'user'
                                        ? Colors.white
                                        : HaniColors.ink,
                                    height: 1.4,
                                    fontSize: 14.5,
                                    fontStyle: line.isFinal
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                  ),
                                ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
              child: active
                  ? _RoundCallButton(
                      icon: Icons.call_end_rounded,
                      background: const Color(0xFFE65353),
                      foreground: Colors.white,
                      label: 'End',
                      onPressed: controller.disconnect,
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: state.phase == VoicePhase.connecting
                            ? null
                            : controller.connect,
                        icon: const Icon(Icons.graphic_eq_rounded),
                        label: Text(
                          state.phase == VoicePhase.error
                              ? 'Reconnect voice'
                              : 'Start live conversation',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                      ),
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
        return 'Connecting…';
      case VoicePhase.listening:
        return 'I’m listening';
      case VoicePhase.thinking:
        return 'Thinking…';
      case VoicePhase.speaking:
        return 'Hani is speaking';
      case VoicePhase.error:
        return 'Connection issue';
      case VoicePhase.idle:
        return 'Talk with Hani';
    }
  }
}

class _LiveOrb extends StatelessWidget {
  const _LiveOrb({
    required this.phase,
    required this.active,
  });

  final VoicePhase phase;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final speaking = phase == VoicePhase.speaking;
    final thinking = phase == VoicePhase.thinking;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: active ? 178 : 150,
      height: active ? 178 : 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFFF8FFFC),
            Color(0xFFDDEFE8),
          ],
        ),
        border: Border.all(
          color: HaniColors.primary.withValues(
            alpha: active ? .30 : .13,
          ),
          width: active ? 12 : 7,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  blurRadius: speaking ? 52 : 36,
                  spreadRadius: speaking ? 5 : 2,
                  color: HaniColors.primary.withValues(
                    alpha: speaking ? .20 : .12,
                  ),
                ),
              ]
            : const [],
      ),
      child: Icon(
        speaking
            ? Icons.graphic_eq_rounded
            : thinking
                ? Icons.auto_awesome_rounded
                : Icons.mic_none_rounded,
        size: 66,
        color: HaniColors.primary,
      ),
    );
  }
}

class _RoundCallButton extends StatelessWidget {
  const _RoundCallButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String label;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 66,
              height: 66,
              child: Icon(
                icon,
                color: foreground,
                size: 29,
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(
            color: HaniColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

extension TakeLastVoice<T> on List<T> {
  List<T> takeLast(int count) {
    if (length <= count) return List<T>.from(this);
    return sublist(length - count);
  }
}
