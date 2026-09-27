import 'package:taskle_app/src/common/patterns/state_pattern.dart';
import 'package:taskle_app/src/common/state_management/state_management.dart';
import 'package:taskle_app/src/features/auth/exceptions/auth_exception.dart';
import 'package:taskle_app/src/features/auth/models/auth_model.dart';
import 'package:taskle_app/src/features/auth/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

typedef LoginState = StatePattern<AuthModel, AuthException>;

typedef _ViewModel = StateManagement<LoginState>;

abstract interface class LoginViewModel extends _ViewModel {
  Future<void> login({required String email, required String password});
}

class LoginViewModelImpl extends _ViewModel implements LoginViewModel {
  final AuthRepository authRepository;

  LoginViewModelImpl({required this.authRepository});

  @override
  LoginState build() => const InitialState();

  @override
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _emit(const LoadingState());
    final result = await authRepository.login(email: email, password: password);
    _emitResult(result);
  }

  void _emitResult(AuthResult result) {
    final newState = result.fold<LoginState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );
    _emit(newState);
  }

  void _emit(LoginState newState) {
    emitState(newState);
    debugPrint('LoginViewModel: $state');
  }
}
