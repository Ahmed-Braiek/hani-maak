import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../context/caregiver_context_provider.dart';
import '../hani/hani_controller.dart';

class HandoffScreen extends ConsumerWidget {
  const HandoffScreen({super.key});

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    String channel,
    String professional,
  ) async {
    await ref.read(haniChatProvider.notifier).send(
      'I want to contact $professional by $channel. Prepare only the minimum necessary summary and ask for my confirmation before sending anything.',
    );
    if (context.mounted) context.push('/hani');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caregiverContextProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Professional support')),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Professional routes unavailable.')),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: HaniColors.primarySoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text(
                'Hani shares only a short relevant summary after your explicit approval. Your private conversation is not sent by default.',
                style: TextStyle(height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            if (data.professionals.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No verified professional route is connected yet.'),
                ),
              )
            else
              ...data.professionals.map((route) {
                final professional = route['professional'] is Map
                    ? Map<String, dynamic>.from(route['professional'] as Map)
                    : <String, dynamic>{};
                final name = professional['full_name']?.toString() ?? 'Professional';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text(
                            professional['specialty']?.toString() ?? 'Professional',
                            style: const TextStyle(color: HaniColors.muted),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _start(context, ref, 'call', name),
                                icon: const Icon(Icons.call_outlined),
                                label: const Text('Call'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _start(context, ref, 'WhatsApp', name),
                                icon: const Icon(Icons.chat_outlined),
                                label: const Text('WhatsApp'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () => _start(context, ref, 'appointment request', name),
                                icon: const Icon(Icons.calendar_month_outlined),
                                label: const Text('Appointment'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
