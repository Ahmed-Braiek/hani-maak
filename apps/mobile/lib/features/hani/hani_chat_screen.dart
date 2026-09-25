import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
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

  Future<void> _send() async {
    final value = input.text.trim();
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
          duration: const Duration(milliseconds: 220),
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
        const SnackBar(content: Text('This action is unavailable right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(haniChatProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hani', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              'Context-aware · private by default',
              style: TextStyle(fontSize: 12, color: HaniColors.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Live voice',
            onPressed: () => context.push('/voice'),
            icon: const Icon(Icons.graphic_eq_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'Language',
            initialValue: state.locale,
            onSelected: ref.read(haniChatProvider.notifier).setLocale,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ar', child: Text('Tunisian / العربية')),
              PopupMenuItem(value: 'fr', child: Text('Français')),
              PopupMenuItem(value: 'en', child: Text('English')),
            ],
            icon: const Icon(Icons.language_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14, 3, 14, 4),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: HaniColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 17, color: HaniColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Personal wellbeing stays private unless you explicitly choose to share a summary.',
                    style: TextStyle(fontSize: 12.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              itemCount: state.messages.length + (state.sending ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                if (index == state.messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      label: Text('Hani is thinking…'),
                    ),
                  );
                }

                final message = state.messages[index];
                final fromHani = message.role == HaniRole.hani;
                return Align(
                  alignment:
                      fromHani ? Alignment.centerLeft : Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 345),
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
                            color: fromHani ? Colors.white : HaniColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            border: fromHani
                                ? Border.all(color: const Color(0xFFE8EEEC))
                                : null,
                          ),
                          child: Text(
                            message.text,
                            textDirection: RegExp(r'[\u0600-\u06FF]')
                                    .hasMatch(message.text)
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            style: TextStyle(
                              color:
                                  fromHani ? HaniColors.ink : Colors.white,
                              height: 1.45,
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                        if (message.uiActions.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: message.uiActions
                                .map(
                                  (action) => OutlinedButton.icon(
                                    onPressed: () => _openAction(action),
                                    icon: const Icon(
                                      Icons.open_in_new_rounded,
                                      size: 17,
                                    ),
                                    label: Text(
                                      action['label']?.toString() ?? 'Open',
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
                color: const Color(0xFFFFF4E8),
                borderRadius: BorderRadius.circular(14),
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
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE8EEEC))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Talk to Hani',
                    onPressed: () => context.push('/voice'),
                    icon: const Icon(Icons.mic_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 5,
                      enabled: !state.sending,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'احكي مع هاني… / Talk to Hani…',
                        filled: true,
                        fillColor: HaniColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.sending ? null : _send,
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
