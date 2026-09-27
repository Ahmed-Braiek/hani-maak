import '../features/context/caregiver_context.dart';
import 'settings/app_settings.dart';
import 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_mobile.dart';

abstract class HaniNotificationService {
  static HaniNotificationService get instance => notificationServiceInstance;

  void Function(String route)? routeHandler;

  Future<void> initialize();
  Future<void> requestPermissions();
  Future<void> sync(CaregiverContext context, HaniLanguage language);
  Future<void> showTest();
  Future<void> showAction({
    required String title,
    required String body,
    required String route,
  });
  Future<void> showPostCall({
    required String conversationId,
    required HaniLanguage language,
    required bool analysisReady,
  });
}
