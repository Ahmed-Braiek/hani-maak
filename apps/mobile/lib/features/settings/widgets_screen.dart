import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';

class WidgetsScreen extends ConsumerWidget {
  const WidgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final c = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Today widgets')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          const HaniGradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HaniPill(
                  label: 'Personalize Today',
                  icon: Icons.dashboard_customize_outlined,
                ),
                SizedBox(height: 13),
                Text(
                  'Keep the home screen calm.',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5),
                Text(
                  'Show only the information that helps you act without adding mental load.',
                  style: TextStyle(color: HaniColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                _Toggle(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Hani companion',
                  subtitle: 'Fast text and live voice access',
                  value: s.showHaniWidget,
                  onChanged: c.setHaniWidget,
                ),
                const Divider(indent: 70),
                _Toggle(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Patient snapshot',
                  subtitle: 'Care stage and current context',
                  value: s.showPatientWidget,
                  onChanged: c.setPatientWidget,
                ),
                const Divider(indent: 70),
                _Toggle(
                  icon: Icons.balance_rounded,
                  title: 'Care load',
                  subtitle: 'Your open responsibilities at a glance',
                  value: s.showCareLoadWidget,
                  onChanged: c.setCareLoadWidget,
                ),
                const Divider(indent: 70),
                _Toggle(
                  icon: Icons.self_improvement_rounded,
                  title: 'Wellbeing pulse',
                  subtitle: 'Private check-in shortcut',
                  value: s.showWellbeingWidget,
                  onChanged: c.setWellbeingWidget,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      secondary: CircleAvatar(
        backgroundColor: HaniColors.primarySoft,
        child: Icon(icon, color: HaniColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: HaniColors.muted, fontSize: 12.2),
      ),
    );
  }
}
