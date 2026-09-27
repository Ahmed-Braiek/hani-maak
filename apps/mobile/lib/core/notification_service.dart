import '../features/context/caregiver_context.dart';
import 'notification_service_stub.dart';

abstract class HaniNotificationService {
  static HaniNotificationService get instance => notificationServiceInstance;

  void Function(String route)? routeHandler;

  Future<void> initialize();
  Future<void> requestPermissions();
  Future<void> sync(CaregiverContext context);
  Future<void> showTest();
}
