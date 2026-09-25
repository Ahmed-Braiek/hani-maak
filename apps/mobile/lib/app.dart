import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/app_shell.dart';
import 'features/today/today_screen.dart';
import 'features/patient/patient_screen.dart';
import 'features/care_circle/care_circle_screen.dart';
import 'features/wellbeing/wellbeing_screen.dart';
import 'features/hani/hani_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/today',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
        GoRoute(path: '/patient', builder: (_, __) => const PatientScreen()),
        GoRoute(path: '/circle', builder: (_, __) => const CareCircleScreen()),
        GoRoute(path: '/me', builder: (_, __) => const WellbeingScreen()),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/hani',
      builder: (_, __) => const HaniScreen(),
    ),
  ],
);

class HaniMaakApp extends StatelessWidget {
  const HaniMaakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Hani Maak',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
