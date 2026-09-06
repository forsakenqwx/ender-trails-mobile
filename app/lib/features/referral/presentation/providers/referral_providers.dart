import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/referral_repository_impl.dart';
import '../../domain/entities/referral_info.dart';
import '../../domain/repositories/referral_repository.dart';

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepositoryImpl(
    storage: ref.watch(secureStorageProvider),
  );
});

final referralInfoProvider = FutureProvider<ReferralInfo>((ref) async {
  final repo = ref.watch(referralRepositoryProvider);
  return repo.getReferralInfo();
});
