import '../features/context/caregiver_context.dart';
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
  Future<void> sync(CaregiverContext context) async {}

  @override
  Future<void> showTest() async {}
}
