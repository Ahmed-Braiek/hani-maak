import '../features/context/caregiver_context.dart';
import 'settings/app_settings.dart';
import 'widget_service.dart';

final HaniHomeWidgetService homeWidgetServiceInstance =
    _StubHomeWidgetService();

class _StubHomeWidgetService implements HaniHomeWidgetService {
  @override
  Future<void> sync(CaregiverContext context, HaniLanguage language) async {}

  @override
  Future<bool> requestPin() async => false;
}
