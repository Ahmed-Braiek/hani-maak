import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../../core/widgets/hani_brand_logo.dart';
import 'hani_voice_controller.dart';

class HaniVoiceScreen extends ConsumerWidget {
  const HaniVoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(haniVoiceProvider);
    final controller = ref.read(haniVoiceProvider.notifier);
    final settings = ref.watch(appSettingsProvider);
    final active = state.connected &&
        state.phase != VoicePhase.idle &&
        state.phase != VoicePhase.error;
    String t(String tn, String ar, String en, String fr) =>
        haniText(settings.language, tn: tn, ar: ar, en: en, fr: fr);

    if (!active && state.locale != settings.language.code) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setLocale(settings.language.code);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F6),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: t('رجوع', 'رجوع', 'Back', 'Retour'),
                    onPressed: () async {
                      await controller.disconnect();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  const Expanded(
                    child: Center(
                      child: HaniBrandLogo(
                        height: 45,
                        variant: HaniBrandVariant.horizontal,
                      ),
                    ),
                  ),
                  if (!active)
                    PopupMenuButton<HaniLanguage>(
                      icon: const Icon(Icons.language_rounded),
                      initialValue: settings.language,
                      onSelected: (language) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setLanguage(language);
                        controller.setLocale(language.code);
                      },
                      itemBuilder: (_) => HaniLanguage.values
                          .map(
                            (language) => PopupMenuItem(
                              value: language,
                              child: Text(language.label),
                            ),
                          )
                          .toList(),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                children: [
                  Center(
                    child: _BreathingOrb(
                      phase: state.phase,
                      active: active,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    _phaseLabel(state.phase, settings.language),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    active
                        ? _activeHint(settings.language)
                        : _idleHint(settings.language),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: HaniColors.muted,
                      height: 1.45,
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(height: 14),
                    Center(
                      child: HaniPill(
                        label: state.phase == VoicePhase.speaking
                            ? t('هاني يحكي', 'هاني يتحدث', 'HANI SPEAKING', 'HANI PARLE')
                            : state.phase == VoicePhase.thinking
                                ? t('نخمّم', 'جارٍ التفكير', 'THINKING', 'RÉFLEXION')
                                : t('نسمعك', 'أستمع إليك', 'LISTENING', 'ÉCOUTE'),
                        icon: state.phase == VoicePhase.speaking
                            ? Icons.graphic_eq_rounded
                            : Icons.hearing_rounded,
                      ),
                    ),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: HaniColors.warm,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        state.error!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  if (state.lines.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    HaniSectionHeader(
                      title: t(
                        'المحادثة المباشرة',
                        'المحادثة المباشرة',
                        'Live conversation',
                        'Conversation en direct',
                      ),
                      subtitle: t(
                        'النص يتحدّث وإنت تحكي',
                        'يتم تحديث النص أثناء حديثك',
                        'Transcript updates as you speak',
                        'La transcription se met à jour pendant que vous parlez',
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...state.lines.takeLast(8).map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Align(
                              alignment: line.role == 'user'
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 345),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: line.role == 'user'
                                        ? HaniGradients.hero
                                        : null,
                                    color: line.role == 'user'
                                        ? null
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: line.role == 'user'
                                        ? null
                                        : Border.all(
                                            color: HaniColors.line,
                                          ),
                                  ),
                                  child: Text(
                                    line.text,
                                    style: TextStyle(
                                      color: line.role == 'user'
                                          ? Colors.white
                                          : HaniColors.ink,
                                      height: 1.4,
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
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: active
                  ? Center(
                      child: Column(
                        children: [
                          FloatingActionButton.large(
                            heroTag: 'end-live-voice',
                            onPressed: state.phase == VoicePhase.ending
                                ? null
                                : () async {
                                    final sessionId =
                                        await controller.endCall();
                                    if (context.mounted &&
                                        sessionId != null &&
                                        sessionId.isNotEmpty) {
                                      context.go('/voice-result/$sessionId');
                                    }
                                  },
                            backgroundColor: HaniColors.danger,
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.call_end_rounded),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t('سكر', 'إنهاء', 'End', 'Terminer'),
                            style: const TextStyle(
                              color: HaniColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: state.phase == VoicePhase.connecting
                          ? null
                          : controller.connect,
                      icon: const Icon(Icons.graphic_eq_rounded),
                      label: Text(
                        state.phase == VoicePhase.error
                            ? t(
                                'عاود اربط الصوت',
                                'أعد الاتصال الصوتي',
                                'Reconnect voice',
                                'Reconnecter la voix',
                              )
                            : t(
                                'ابدأ المكالمة',
                                'ابدأ المكالمة',
                                'Start live conversation',
                                'Démarrer la conversation',
                              ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _phaseLabel(
    VoicePhase phase,
    HaniLanguage language,
  ) {
    if ((language == HaniLanguage.tounsi || language == HaniLanguage.arabic)) {
      return switch (phase) {
        VoicePhase.connecting => 'نربط مع هاني…',
        VoicePhase.listening => 'نسمعك',
        VoicePhase.thinking => 'نخمّم…',
        VoicePhase.speaking => 'هاني يحكي',
        VoicePhase.ending => 'نكمّل المكالمة…',
        VoicePhase.error => 'فما مشكل في الربط',
        VoicePhase.idle => 'احكي مع هاني',
      };
    }

    if (language == HaniLanguage.french) {
      return switch (phase) {
        VoicePhase.connecting => 'Connexion…',
        VoicePhase.listening => 'Je vous écoute',
        VoicePhase.thinking => 'Je réfléchis…',
        VoicePhase.speaking => 'Hani parle',
        VoicePhase.ending => 'Fin de l’appel…',
        VoicePhase.error => 'Problème de connexion',
        VoicePhase.idle => 'Parler à Hani',
      };
    }

    return switch (phase) {
      VoicePhase.connecting => 'Connecting…',
      VoicePhase.listening => 'I’m listening',
      VoicePhase.thinking => 'Thinking…',
      VoicePhase.speaking => 'Hani is speaking',
      VoicePhase.ending => 'Ending call…',
      VoicePhase.error => 'Connection issue',
      VoicePhase.idle => 'Talk with Hani',
    };
  }

  static String _activeHint(HaniLanguage language) =>
      language == HaniLanguage.french
          ? 'Parlez naturellement. Vous pouvez interrompre Hani comme dans une vraie conversation.'
          : (language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
              ? 'احكي عادي. تنجم تقاطع هاني كيف مكالمة حقيقية.'
              : 'Talk naturally. You can interrupt Hani like a real conversation.';

  static String _idleHint(HaniLanguage language) =>
      language == HaniLanguage.french
          ? 'Une conversation privée et continue avec votre compagnon aidant.'
          : (language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
              ? 'مكالمة خاصة ومتصلة مع هاني، مساعدك في الرعاية.'
              : 'A private continuous conversation with your caregiver companion.';
}

class _BreathingOrb extends StatefulWidget {
  const _BreathingOrb({
    required this.phase,
    required this.active,
  });

  final VoicePhase phase;
  final bool active;

  @override
  State<_BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<_BreathingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final wave =
            (math.sin(controller.value * math.pi * 2) + 1) / 2;
        final scale = widget.active ? .98 + (.04 * wave) : 1.0;
        final speaking = widget.phase == VoicePhase.speaking;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 186,
            height: 186,
            decoration: BoxDecoration(
              gradient: HaniGradients.hero,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: HaniColors.primary.withValues(
                    alpha: widget.active ? .18 + (.12 * wave) : .12,
                  ),
                  blurRadius: speaking ? 58 : 42,
                  spreadRadius: widget.active ? 6 * wave : 2,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .09),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .22),
                    width: 10,
                  ),
                ),
                child: const Center(
                  child: HaniBrandLogo(
                    variant: HaniBrandVariant.markOnly,
                    light: true,
                    height: 82,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

extension TakeLastVoice<T> on List<T> {
  List<T> takeLast(int count) {
    if (length <= count) return List<T>.from(this);
    return sublist(length - count);
  }
}
