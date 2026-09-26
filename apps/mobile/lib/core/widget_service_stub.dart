import '../features/context/caregiver_context.dart';
import 'widget_service.dart';

final HaniHomeWidgetService homeWidgetServiceInstance =
    _StubHomeWidgetService();

class _StubHomeWidgetService implements HaniHomeWidgetService {
  @override
  Future<void> sync(CaregiverContext context) async {}
}
