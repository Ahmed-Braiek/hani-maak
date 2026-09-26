import '../features/context/caregiver_context.dart';
import 'widget_service_stub.dart'
    if (dart.library.io) 'widget_service_mobile.dart';

abstract class HaniHomeWidgetService {
  static HaniHomeWidgetService get instance => homeWidgetServiceInstance;

  Future<void> sync(CaregiverContext context);
}
