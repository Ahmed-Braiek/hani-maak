import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'hani_controller.dart';

class HaniScreen extends ConsumerStatefulWidget {
  const HaniScreen({super.key});

  @override
  ConsumerState<HaniScreen> createState() => _HaniScreenState();
}

class _HaniScreenState extends ConsumerState<HaniScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    controller.clear();
    _scrollToEnd();
    await ref.read(haniChatProvider.notifier).send(value);
    _scrollToEnd();
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
            Text('Hani', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(
              'Here with you · private',
              style: TextStyle(fontSize: 12, color: HaniColors.muted),
            ),
          ],
        ),
        actions: [
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
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
                    'Your wellbeing conversation stays private by default.',
                    style: TextStyle(fontSize: 12.5, color: HaniColors.ink),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              itemCount: state.messages.length + (state.sending ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                if (index == state.messages.length) {
                  return const _ThinkingBubble();
                }
                return _MessageBubble(message: state.messages[index]);
              },
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Live voice is being connected to this same Hani session.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mic_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: !state.sending,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 5,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'احكي مع هاني… / Talk to Hani…',
                        filled: true,
                        fillColor: HaniColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send',
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final HaniMessage message;

  @override
  Widget build(BuildContext context) {
    final fromHani = message.role == HaniRole.hani;
    return Align(
      alignment: fromHani ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          crossAxisAlignment:
              fromHani ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: fromHani ? Colors.white : HaniColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(fromHani ? 6 : 20),
                  bottomRight: Radius.circular(fromHani ? 20 : 6),
                ),
                border: fromHani
                    ? Border.all(color: const Color(0xFFE8EEEC))
                    : null,
              ),
              child: Text(
                message.text,
                textDirection: _directionFor(message.text),
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.45,
                  color: fromHani ? HaniColors.ink : Colors.white,
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
                        onPressed: () {},
                        icon: const Icon(Icons.open_in_new_rounded, size: 17),
                        label: Text(action['label']?.toString() ?? 'Open'),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static TextDirection _directionFor(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Hani is thinking…'),
            ],
          ),
        ),
      ),
    );
  }
}
