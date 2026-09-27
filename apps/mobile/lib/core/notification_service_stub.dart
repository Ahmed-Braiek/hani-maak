import '../features/context/caregiver_context.dart';
import 'settings/app_settings.dart';
import 'notification_service.dart';

final HaniNotificationService notificationServiceInstance =
    _StubNotificationService();

class _StubNotificationService implements HaniNotificationService {
  @override
  void Function(String route)? routeHandler;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> sync(CaregiverContext context, HaniLanguage language) async {}

  @override
  Future<void> showTest() async {}

  @override
  Future<void> showAction({
    required String title,
    required String body,
    required String route,
  }) async {}

  @override
  Future<void> showPostCall({
    required String conversationId,
    required HaniLanguage language,
    required bool analysisReady,
  }) async {}
}
