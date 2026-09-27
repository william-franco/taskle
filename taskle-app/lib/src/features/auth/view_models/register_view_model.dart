import 'package:taskle_app/src/common/patterns/state_pattern.dart';
import 'package:taskle_app/src/common/state_management/state_management.dart';
import 'package:taskle_app/src/features/auth/exceptions/auth_exception.dart';
import 'package:taskle_app/src/features/auth/models/auth_model.dart';
import 'package:taskle_app/src/features/auth/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

typedef RegisterState = StatePattern<AuthModel, AuthException>;

typedef _ViewModel = StateManagement<RegisterState>;

abstract interface class RegisterViewModel extends _ViewModel {
  Future<void> register({
    required String name,
    required String email,
    required String password,
  });
}

class RegisterViewModelImpl extends _ViewModel implements RegisterViewModel {
  final AuthRepository authRepository;

  RegisterViewModelImpl({required this.authRepository});

  @override
  RegisterState build() => const InitialState();

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _emit(const LoadingState());
    final result = await authRepository.register(
      name: name,
      email: email,
      password: password,
    );
    _emitResult(result);
  }

  void _emitResult(AuthResult result) {
    final newState = result.fold<RegisterState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );
    _emit(newState);
  }

  void _emit(RegisterState newState) {
    emitState(newState);
    debugPrint('RegisterViewModel: $state');
  }
}
