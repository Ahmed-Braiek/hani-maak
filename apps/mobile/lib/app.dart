import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/how_hani_works_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/today/today_screen.dart';
import 'features/dilemmas/dilemma_library_screen.dart';
import 'features/patient/patient_screen.dart';
import 'features/patient/patient_activity_screen.dart';
import 'features/patient/care_hub_screen.dart';
import 'features/care_circle/care_circle_screen.dart';
import 'features/wellbeing/wellbeing_screen.dart';
import 'features/wellbeing/questionnaire_screen.dart';
import 'features/handoff/handoff_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/widgets_screen.dart';
import 'features/hani/hani_chat_screen.dart';
import 'features/hani/hani_voice_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/welcome',
  routes: [
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
    GoRoute(
      path: '/how-it-works',
      builder: (_, __) => const HowHaniWorksScreen(),
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
      builder: (_, state) => HaniChatScreen(
        initialPrompt: state.uri.queryParameters['prompt'],
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/dilemmas',
      builder: (_, __) => const DilemmaLibraryScreen(),
    ),
    GoRoute(parentNavigatorKey: _rootKey, path: '/voice', builder: (_, __) => const HaniVoiceScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/handoff', builder: (_, __) => const HandoffScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/questionnaire', builder: (_, __) => const QuestionnaireScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/widgets', builder: (_, __) => const WidgetsScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/activity', builder: (_, __) => const PatientActivityScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/care-hub', builder: (_, __) => const CareHubScreen()),
  ],
);

class HaniMaakApp extends ConsumerWidget {
  const HaniMaakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appSettingsProvider.select((s) => s.language));

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Hani Maak',
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) => Directionality(
        textDirection: language.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: _ResponsiveAppFrame(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}


class _ResponsiveAppFrame extends StatelessWidget {
  const _ResponsiveAppFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) return child;

        return ColoredBox(
          color: HaniColors.ink,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: HaniColors.surface,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .28),
                          blurRadius: 48,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
