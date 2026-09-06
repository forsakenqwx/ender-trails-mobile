import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/entities/subscription_profile.dart';
import '../../domain/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl(
    storage: ref.watch(secureStorageProvider),
  );
});

final subscriptionProfileProvider =
    AsyncNotifierProvider<SubscriptionProfileNotifier, SubscriptionProfile?>(
  SubscriptionProfileNotifier.new,
);

class SubscriptionProfileNotifier extends AsyncNotifier<SubscriptionProfile?> {
  @override
  Future<SubscriptionProfile?> build() async {
    final authState = ref.watch(authControllerProvider);
    final subUrl = authState.session?.subscriptionUrl;

    final repo = ref.read(subscriptionRepositoryProvider);
    if (subUrl == null || subUrl.isEmpty) {
      return await repo.getCachedProfile();
    }

    final res = await repo.fetchSubscription(subUrl);

    return await res.fold(
      (failure) async => await repo.getCachedProfile(),
      (profile) async => profile,
    );
  }

  Future<bool> refresh() async {
    state = const AsyncValue.loading();
    bool success = false;
    state = await AsyncValue.guard(() async {
      final authState = ref.read(authControllerProvider);
      final subUrl = authState.session?.subscriptionUrl;
      final repo = ref.read(subscriptionRepositoryProvider);
      if (subUrl == null || subUrl.isEmpty) {
        return await repo.getCachedProfile();
      }

      final res = await repo.fetchSubscription(subUrl, forceRefresh: true);
      return res.fold(
        (failure) async => await repo.getCachedProfile(),
        (p) {
          success = true;
          return p;
        },
      );
    });
    return success;
  }
}
