import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  int _index(String location) {
    if (location.startsWith('/patient')) return 1;
    if (location.startsWith('/circle')) return 2;
    if (location.startsWith('/me')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            child,
            Positioned(
              top: 8,
              right: 12,
              child: Material(
                color: Colors.white.withValues(alpha: .96),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'hani-fab',
        onPressed: () => context.push('/hani'),
        backgroundColor: HaniColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Hani'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index(location),
        onDestinationSelected: (index) {
          const paths = ['/today', '/patient', '/circle', '/me'];
          context.go(paths[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Patient',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Care Circle',
          ),
          NavigationDestination(
            icon: Icon(Icons.self_improvement_outlined),
            selectedIcon: Icon(Icons.self_improvement_rounded),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}
