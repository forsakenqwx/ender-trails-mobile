import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/banner_service.dart';
import '../../domain/entities/remote_banner.dart';

final bannerServiceProvider = Provider<BannerService>((ref) {
  return BannerService(
    storage: ref.watch(secureStorageProvider),
  );
});

class RemoteBannerNotifier extends AsyncNotifier<RemoteBanner?> {
  @override
  Future<RemoteBanner?> build() async {
    final service = ref.watch(bannerServiceProvider);
    return service.fetchBanner();
  }

  Future<void> dismiss() async {
    final current = state.value;
    if (current == null) return;

    state = const AsyncValue.data(null);
    final service = ref.read(bannerServiceProvider);
    await service.dismissBanner(current.id);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final service = ref.read(bannerServiceProvider);
    state = AsyncValue.data(await service.fetchBanner());
  }
}

final remoteBannerNotifierProvider =
    AsyncNotifierProvider<RemoteBannerNotifier, RemoteBanner?>(
  RemoteBannerNotifier.new,
);
