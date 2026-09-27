import '../features/context/caregiver_context.dart';
import 'widget_service_stub.dart';

abstract class HaniHomeWidgetService {
  static HaniHomeWidgetService get instance => homeWidgetServiceInstance;

  Future<void> sync(CaregiverContext context);
}
