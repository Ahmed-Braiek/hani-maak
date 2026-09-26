import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import 'hani_controller.dart';

class HaniChatScreen extends ConsumerStatefulWidget {
  const HaniChatScreen({super.key});

  @override
  ConsumerState<HaniChatScreen> createState() => _HaniChatScreenState();
}

class _HaniChatScreenState extends ConsumerState<HaniChatScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final value = (preset ?? input.text).trim();
    if (value.isEmpty) return;
    input.clear();
    await ref.read(haniChatProvider.notifier).send(value);
    _toBottom();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openAction(Map<String, dynamic> action) async {
    final raw = action['url']?.toString();
    final uri = raw == null ? null : Uri.tryParse(raw);
    if (uri == null) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This action is unavailable right now.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(haniChatProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final language = appSettings.language;
    final expectedLocale = language.code;

    if (state.locale != expectedLocale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(haniChatProvider.notifier).setLocale(expectedLocale);
        }
      });
    }

    final empty = state.messages.isEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hani',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              'Context-aware · private by default',
              style: TextStyle(
                fontSize: 11.5,
                color: HaniColors.muted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Live voice',
            onPressed: () => context.push('/voice'),
            icon: const Icon(Icons.graphic_eq_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: empty
                ? _EmptyHani(
                    language: language,
                    onPrompt: _send,
                    onVoice: () => context.push('/voice'),
                  )
                : ListView.separated(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount:
                        state.messages.length + (state.sending ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      if (index == state.messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: _ThinkingBubble(),
                        );
                      }

                      final message = state.messages[index];
                      final fromHani = message.role == HaniRole.hani;

                      return Align(
                        alignment: fromHani
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 355),
                          child: Column(
                            crossAxisAlignment: fromHani
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient:
                                      fromHani ? null : HaniGradients.hero,
                                  color: fromHani ? Colors.white : null,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(21),
                                    topRight: const Radius.circular(21),
                                    bottomLeft: Radius.circular(
                                      fromHani ? 7 : 21,
                                    ),
                                    bottomRight: Radius.circular(
                                      fromHani ? 21 : 7,
                                    ),
                                  ),
                                  border: fromHani
                                      ? Border.all(color: HaniColors.line)
                                      : null,
                                ),
                                child: Text(
                                  message.text,
                                  textDirection:
                                      RegExp(r'[\u0600-\u06FF]')
                                              .hasMatch(message.text)
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                  style: TextStyle(
                                    color: fromHani
                                        ? HaniColors.ink
                                        : Colors.white,
                                    height: 1.45,
                                    fontSize: 15.2,
                                  ),
                                ),
                              ),
                              if (message.uiActions.isNotEmpty) ...[
                                const SizedBox(height: 7),
                                Wrap(
                                  spacing: 7,
                                  runSpacing: 7,
                                  children: message.uiActions
                                      .map(
                                        (action) => OutlinedButton.icon(
                                          onPressed: () =>
                                              _openAction(action),
                                          icon: const Icon(
                                            Icons.open_in_new_rounded,
                                            size: 16,
                                          ),
                                          label: Text(
                                            action['label']?.toString() ??
                                                'Open',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Material(
                color: HaniColors.warm,
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.wifi_off_rounded),
                  title: Text(state.error!),
                  trailing: TextButton(
                    onPressed: state.sending
                        ? null
                        : ref.read(haniChatProvider.notifier).retryLast,
                    child: const Text('Retry'),
                  ),
                ),
              ),
            ),
          _Composer(
            input: input,
            sending: state.sending,
            language: language,
            onSend: () => _send(),
            onVoice: () => context.push('/voice'),
          ),
        ],
      ),
    );
  }
}

class _EmptyHani extends StatelessWidget {
  const _EmptyHani({
    required this.language,
    required this.onPrompt,
    required this.onVoice,
  });

  final HaniLanguage language;
  final ValueChanged<String> onPrompt;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    final title = language == HaniLanguage.french
        ? 'Qu’est-ce qui se passe ?'
        : language == HaniLanguage.tounsi
            ? 'شنوّة صاير؟'
            : 'What is happening?';

    final body = language == HaniLanguage.french
        ? 'Parlez comme vous le feriez avec quelqu’un qui connaît déjà votre situation.'
        : language == HaniLanguage.tounsi
            ? 'احكي عادي كيف ما تحكي مع شخص يعرف حالتك من قبل.'
            : 'Talk naturally, like you would with someone who already knows the situation.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
      children: [
        const Center(child: _HaniOrb()),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: HaniColors.muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onVoice,
          icon: const Icon(Icons.graphic_eq_rounded),
          label: Text(
            language == HaniLanguage.french
                ? 'Démarrer la voix en direct'
                : language == HaniLanguage.tounsi
                    ? 'ابدأ مكالمة مباشرة'
                    : 'Start live voice',
          ),
        ),
        const SizedBox(height: 18),
        const HaniSectionHeader(title: 'Quick starts'),
        const SizedBox(height: 9),
        _PromptCard(
          icon: Icons.restaurant_outlined,
          text: language == HaniLanguage.tounsi
              ? 'ما حبّتش تاكل اليوم'
              : language == HaniLanguage.french
                  ? 'Elle refuse de manger aujourd’hui'
                  : 'She refuses to eat today',
          onTap: onPrompt,
        ),
        const SizedBox(height: 8),
        _PromptCard(
          icon: Icons.repeat_rounded,
          text: language == HaniLanguage.tounsi
              ? 'تعاود نفس السؤال برشة'
              : language == HaniLanguage.french
                  ? 'Elle répète la même question'
                  : 'She keeps repeating the same question',
          onTap: onPrompt,
        ),
        const SizedBox(height: 8),
        _PromptCard(
          icon: Icons.self_improvement_rounded,
          text: language == HaniLanguage.tounsi
              ? 'أنا تعبت وما عادش نجم'
              : language == HaniLanguage.french
                  ? 'Je suis épuisé, je n’en peux plus'
                  : 'I am exhausted and cannot take much more',
          onTap: onPrompt,
        ),
      ],
    );
  }
}

class _HaniOrb extends StatelessWidget {
  const _HaniOrb();

  @override
  Widget build(BuildContext context) => Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          gradient: HaniGradients.hero,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: HaniColors.primary.withValues(alpha: .22),
              blurRadius: 38,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 40,
        ),
      );
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: () => onTap(text),
          contentPadding: const EdgeInsets.all(14),
          leading: CircleAvatar(
            backgroundColor: HaniColors.primarySoft,
            child: Icon(icon, color: HaniColors.primary),
          ),
          title: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
        ),
      );
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HaniColors.line),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Hani is thinking…'),
          ],
        ),
      );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.input,
    required this.sending,
    required this.language,
    required this.onSend,
    required this.onVoice,
  });

  final TextEditingController input;
  final bool sending;
  final HaniLanguage language;
  final VoidCallback onSend;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: HaniColors.line)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton.filledTonal(
                tooltip: 'Live voice',
                onPressed: onVoice,
                icon: const Icon(Icons.mic_rounded),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: TextField(
                  controller: input,
                  minLines: 1,
                  maxLines: 5,
                  enabled: !sending,
                  decoration: InputDecoration(
                    hintText: language == HaniLanguage.french
                        ? 'Parlez à Hani…'
                        : language == HaniLanguage.tounsi
                            ? 'احكي مع هاني…'
                            : 'Talk to Hani…',
                    fillColor: HaniColors.surface,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              IconButton.filled(
                onPressed: sending ? null : onSend,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ],
          ),
        ),
      );
}
