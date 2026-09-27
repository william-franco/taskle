import 'package:taskle_app/src/common/patterns/result_pattern.dart';
import 'package:taskle_app/src/common/patterns/state_pattern.dart';
import 'package:taskle_app/src/features/auth/exceptions/auth_exception.dart';
import 'package:taskle_app/src/features/auth/models/auth_model.dart';
import 'package:taskle_app/src/features/auth/models/user_model.dart';
import 'package:taskle_app/src/features/auth/view_models/register_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../auth_mocks.mocks.dart';

void main() {
  late MockAuthRepository mockRepository;
  late RegisterViewModelImpl viewModel;

  final authModel = AuthModel(
    accessToken: 'token_123',
    refreshToken: 'refresh_123',
    user: UserModel(
      id: 1,
      name: 'Test User',
      email: 'test@example.com',
      createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
    ),
  );

  setUpAll(() {
    provideDummy<ResultPattern<AuthModel, AuthException>>(
      ErrorResult(error: AuthException('dummy')),
    );
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    viewModel = RegisterViewModelImpl(authRepository: mockRepository);
  });

  tearDown(() => viewModel.dispose());

  test('register success emits SuccessState', () async {
    when(
      mockRepository.register(
        name: anyNamed('name'),
        email: anyNamed('email'),
        password: anyNamed('password'),
      ),
    ).thenAnswer((_) async => SuccessResult(value: authModel));

    await viewModel.register(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
    );

    expect(viewModel.state, isA<SuccessState<AuthModel, AuthException>>());
  });
}
