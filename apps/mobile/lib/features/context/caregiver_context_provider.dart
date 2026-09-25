import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Future<CaregiverContext> build() {
    return ref.read(caregiverContextApiProvider).load();
  }

  Future<void> refreshContext() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(caregiverContextApiProvider).load(),
    );
  }
}
