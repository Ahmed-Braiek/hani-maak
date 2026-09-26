import '../../features/context/caregiver_context.dart';

class DeviceCareServices {
  static Future<void> initialize({
    required void Function(String route) onRoute,
  }) async {}

  static Future<void> sync(CaregiverContext context) async {}

  static Future<bool> requestPermissions() async => false;

  static Future<bool> requestHomeWidget() async => false;
}
