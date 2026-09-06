import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../data/deep_link_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

final secureStorageProvider = Provider<AppSecureStorage>((ref) {
  return AppSecureStorage();
});

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService();
  service.initialize();
  ref.onDispose(service.dispose);
  return service;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    storage: ref.watch(secureStorageProvider),
  );
});

enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

class AuthState {
  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
  });

  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated && session != null;
  bool get isAuthenticating => status == AuthStatus.authenticating;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  StreamSubscription<String>? _deepLinkSub;

  @override
  AuthState build() {
    final deepLinks = ref.watch(deepLinkServiceProvider);

    _deepLinkSub?.cancel();
    _deepLinkSub = deepLinks.tokenStream.listen((token) {
      loginWithToken(token);
    });

    ref.onDispose(() {
      _deepLinkSub?.cancel();
    });

    _checkCurrentSession();

    return const AuthState(status: AuthStatus.initial);
  }

  Future<void> _checkCurrentSession() async {
    final repo = ref.read(authRepositoryProvider);
    final session = await repo.getCurrentSession();
    if (session != null) {
      state = AuthState(status: AuthStatus.authenticated, session: session);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> loginWithToken(String token) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.loginWithToken(token);

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.messageKey,
        );
        return false;
      },
      (session) {
        state = AuthState(
          status: AuthStatus.authenticated,
          session: session,
        );
        return true;
      },
    );
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
