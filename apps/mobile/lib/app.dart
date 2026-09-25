import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/today/today_screen.dart';
import 'features/patient/patient_screen.dart';
import 'features/care_circle/care_circle_screen.dart';
import 'features/wellbeing/wellbeing_screen.dart';
import 'features/wellbeing/questionnaire_screen.dart';
import 'features/handoff/handoff_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/hani/hani_chat_screen.dart';
import 'features/hani/hani_voice_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (_, __) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (_, __) => const SignInScreen(),
    ),
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
      builder: (_, __) => const HaniChatScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/voice',
      builder: (_, __) => const HaniVoiceScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/handoff',
      builder: (_, __) => const HandoffScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/questionnaire',
      builder: (_, __) => const QuestionnaireScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/notifications',
      builder: (_, __) => const NotificationsScreen(),
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
