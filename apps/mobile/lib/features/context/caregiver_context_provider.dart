import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/settings/app_settings.dart';
import 'caregiver_context.dart';
import 'caregiver_context_api.dart';

final caregiverContextApiProvider = Provider<CaregiverContextApi>((ref) {
  final api = CaregiverContextApi();
  ref.onDispose(api.dispose);
  return api;
});

final caregiverContextProvider =
    AsyncNotifierProvider<CaregiverContextController, CaregiverContext>(
  CaregiverContextController.new,
);

class CaregiverContextController extends AsyncNotifier<CaregiverContext> {
  @override
  Future<CaregiverContext> build() async {
    final data = await ref.read(caregiverContextApiProvider).load();
    ref.read(appSettingsProvider.notifier).hydrateFromCareContext(
          data.caregiver,
          data.notificationPreferences,
        );
    return data;
  }

  Future<void> refreshContext() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await ref.read(caregiverContextApiProvider).load();
      ref.read(appSettingsProvider.notifier).hydrateFromCareContext(
            data.caregiver,
            data.notificationPreferences,
          );
      return data;
    });
  }
}
