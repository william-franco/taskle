import 'package:taskle_app/src/features/auth/view_models/auth_session_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../auth_mocks.mocks.dart';

void main() {
  late MockAuthRepository mockRepository;
  late AuthSessionViewModelImpl viewModel;

  setUp(() {
    mockRepository = MockAuthRepository();
    viewModel = AuthSessionViewModelImpl(authRepository: mockRepository);
  });

  tearDown(() => viewModel.dispose());

  test('checkSession updates hasSession', () async {
    when(mockRepository.hasSession()).thenAnswer((_) async => true);

    await viewModel.checkSession();

    expect(viewModel.state.hasSession, isTrue);
  });

  test('logout clears session', () async {
    when(mockRepository.logout()).thenAnswer((_) async {});

    await viewModel.logout();

    expect(viewModel.state.hasSession, isFalse);
  });
}
