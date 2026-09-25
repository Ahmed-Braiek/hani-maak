import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../context/caregiver_context_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caregiverContextProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Notifications unavailable.')),
        data: (data) {
          final items = data.notifications;
          if (items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 70),
                Icon(Icons.notifications_none_rounded, size: 52, color: HaniColors.muted),
                SizedBox(height: 16),
                Text(
                  'You are all caught up.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  'Hani keeps reminders quiet and relevant. Care Circle requests, incident follow-ups and appointments will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: HaniColors.muted, height: 1.45),
                ),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref
                .read(caregiverContextProvider.notifier)
                .refreshContext(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (_, index) {
                final item = items[index];
                final opened = item['opened_at'] != null;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: opened
                          ? const Color(0xFFF0F3F2)
                          : HaniColors.primarySoft,
                      child: Icon(
                        _icon(item['category']?.toString()),
                        color: opened ? HaniColors.muted : HaniColors.primary,
                      ),
                    ),
                    title: Text(
                      item['title']?.toString() ?? 'Hani Maak',
                      style: TextStyle(
                        fontWeight: opened ? FontWeight.w600 : FontWeight.w800,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item['body']?.toString() ?? '',
                        style: const TextStyle(height: 1.35),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static IconData _icon(String? category) {
    switch (category) {
      case 'care_circle_request':
        return Icons.groups_outlined;
      case 'appointment':
        return Icons.calendar_month_outlined;
      case 'incident_followup':
        return Icons.history_rounded;
      case 'wellbeing_checkin':
        return Icons.favorite_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}
