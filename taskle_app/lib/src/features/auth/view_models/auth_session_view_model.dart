import 'package:taskle_app/src/common/state_management/state_management.dart';
import 'package:taskle_app/src/features/auth/models/auth_session_model.dart';
import 'package:taskle_app/src/features/auth/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

typedef _ViewModel = StateManagement<AuthSessionModel>;

abstract interface class AuthSessionViewModel extends _ViewModel {
  Future<void> checkSession();
  Future<void> logout();
}

class AuthSessionViewModelImpl extends _ViewModel implements AuthSessionViewModel {
  final AuthRepository authRepository;

  AuthSessionViewModelImpl({required this.authRepository});

  @override
  AuthSessionModel build() => const AuthSessionModel();

  @override
  Future<void> checkSession() async {
    final hasSession = await authRepository.hasSession();
    _emit(AuthSessionModel(hasSession: hasSession));
  }

  @override
  Future<void> logout() async {
    await authRepository.logout();
    _emit(const AuthSessionModel(hasSession: false));
  }

  void _emit(AuthSessionModel newState) {
    emitState(newState);
    debugPrint('AuthSessionViewModel: hasSession=${state.hasSession}');
  }
}
