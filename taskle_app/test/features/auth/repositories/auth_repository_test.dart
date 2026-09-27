import 'package:taskle_app/src/common/constants/api_constant.dart';
import 'package:taskle_app/src/common/constants/value_constant.dart';
import 'package:taskle_app/src/common/patterns/result_pattern.dart';
import 'package:taskle_app/src/features/auth/exceptions/auth_exception.dart';
import 'package:taskle_app/src/features/auth/models/auth_model.dart';
import 'package:taskle_app/src/features/auth/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../auth_mocks.mocks.dart';

void main() {
  late MockConnectionService mockConnection;
  late MockHttpService mockHttp;
  late MockStorageService mockStorage;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockConnection = MockConnectionService();
    mockHttp = MockHttpService();
    mockStorage = MockStorageService();
    repository = AuthRepositoryImpl(
      connectionService: mockConnection,
      httpService: mockHttp,
      storageService: mockStorage,
    );
    when(mockConnection.isConnected).thenReturn(true);
  });

  group('login', () {
    test('returns SuccessResult and saves tokens on 200', () async {
      when(mockConnection.checkConnection()).thenAnswer((_) async {});
      when(
        mockHttp.postData(
          path: ApiConstant.authLogin,
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => (
          statusCode: 200,
          data: {
            'accessToken': 'access',
            'refreshToken': 'refresh',
            'user': {
              'id': 1,
              'name': 'Test',
              'email': 'a@b.com',
              'createdAt': '2024-01-01T00:00:00.000Z',
            },
          },
          error: null,
        ),
      );
      when(
        mockStorage.setStringValue(key: anyNamed('key'), value: anyNamed('value')),
      ).thenAnswer((_) async {});

      final result = await repository.login(
        email: 'a@b.com',
        password: 'secret',
      );

      expect(result, isA<SuccessResult<AuthModel, AuthException>>());
      final auth = (result as SuccessResult<AuthModel, AuthException>).value;
      expect(auth.accessToken, 'access');
      verify(
        mockStorage.setStringValue(
          key: ValueConstant.jwtToken,
          value: 'access',
        ),
      ).called(1);
    });

    test('returns ErrorResult when offline', () async {
      when(mockConnection.checkConnection()).thenAnswer((_) async {});
      when(mockConnection.isConnected).thenReturn(false);

      final result = await repository.login(
        email: 'a@b.com',
        password: 'secret',
      );

      expect(result, isA<ErrorResult<AuthModel, AuthException>>());
    });
  });

  group('hasSession', () {
    test('true when jwt token exists', () async {
      when(mockStorage.getStringValueSync(key: ValueConstant.jwtToken))
          .thenReturn('token');

      expect(await repository.hasSession(), isTrue);
    });

    test('false when jwt token missing', () async {
      when(mockStorage.getStringValueSync(key: ValueConstant.jwtToken))
          .thenReturn(null);

      expect(await repository.hasSession(), isFalse);
    });
  });
}
