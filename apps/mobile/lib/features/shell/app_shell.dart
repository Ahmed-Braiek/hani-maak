import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  int _index(String location) {
    if (location.startsWith('/patient')) return 1;
    if (location.startsWith('/circle')) return 2;
    if (location.startsWith('/me')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final settings = ref.watch(appSettingsProvider);
    final copy = AppCopy(settings.language);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            child,
            Positioned(
              top: 10,
              right: 14,
              child: Row(
                children: [
                  _TopAction(
                    tooltip: copy.t('settings'),
                    icon: Icons.tune_rounded,
                    onTap: () => context.push('/settings'),
                  ),
                  const SizedBox(width: 8),
                  _TopAction(
                    tooltip: copy.t('notifications'),
                    icon: Icons.notifications_none_rounded,
                    showDot: settings.notificationsEnabled,
                    onTap: () => context.push('/notifications'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _HaniFab(
        onTap: () => context.push('/hani'),
        onVoice: () => context.push('/voice'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index(location),
        onDestinationSelected: (index) {
          const paths = ['/today', '/patient', '/circle', '/me'];
          context.go(paths[index]);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: copy.t('today'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border_rounded),
            selectedIcon: const Icon(Icons.favorite_rounded),
            label: copy.t('patient'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups_rounded),
            label: copy.t('circle'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.self_improvement_outlined),
            selectedIcon: const Icon(Icons.self_improvement_rounded),
            label: copy.t('me'),
          ),
        ],
      ),
    );
  }
}

class _TopAction extends StatelessWidget {
  const _TopAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: Colors.white.withValues(alpha: .94),
          elevation: 2,
          shadowColor: HaniColors.ink.withValues(alpha: .08),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onTap,
            icon: Icon(icon, size: 21),
          ),
        ),
        if (showDot)
          Positioned(
            right: 5,
            top: 5,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: HaniColors.danger,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _HaniFab extends StatelessWidget {
  const _HaniFab({required this.onTap, required this.onVoice});
  final VoidCallback onTap;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onVoice,
      child: FloatingActionButton(
        heroTag: 'hani-main-fab',
        onPressed: onTap,
        elevation: 8,
        backgroundColor: HaniColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.auto_awesome_rounded, size: 27),
      ),
    );
  }
}
