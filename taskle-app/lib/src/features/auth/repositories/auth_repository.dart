import 'package:taskle_app/src/common/constants/api_constant.dart';
import 'package:taskle_app/src/common/constants/value_constant.dart';
import 'package:taskle_app/src/common/patterns/result_pattern.dart';
import 'package:taskle_app/src/common/services/connection_service.dart';
import 'package:taskle_app/src/common/services/http_service.dart';
import 'package:taskle_app/src/common/services/storage_service.dart';
import 'package:taskle_app/src/features/auth/exceptions/auth_exception.dart';
import 'package:taskle_app/src/features/auth/models/auth_model.dart';

typedef AuthResult = ResultPattern<AuthModel, AuthException>;

abstract interface class AuthRepository {
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthResult> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<bool> hasSession();
}

class AuthRepositoryImpl implements AuthRepository {
  final ConnectionService connectionService;
  final HttpService httpService;
  final StorageService storageService;

  AuthRepositoryImpl({
    required this.connectionService,
    required this.httpService,
    required this.storageService,
  });

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _authenticate(
      path: ApiConstant.authRegister,
      body: {'name': name, 'email': email, 'password': password},
    );
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return _authenticate(
      path: ApiConstant.authLogin,
      body: {'email': email, 'password': password},
    );
  }

  Future<AuthResult> _authenticate({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: AuthException('Dispositivo sem conexão.'));
      }

      final result = await httpService.postData(path: path, body: body);

      if (result.statusCode == 200 && result.data != null) {
        final auth = AuthModel.fromJson(result.data as Map<String, dynamic>);
        await _saveTokens(auth);
        return SuccessResult(value: auth);
      }

      final message = _extractMessage(result.data) ??
          'Falha na autenticação: ${result.statusCode}';
      return ErrorResult(error: AuthException(message));
    } catch (error) {
      return ErrorResult(error: AuthException('Erro inesperado: $error'));
    }
  }

  @override
  Future<void> logout() async {
    final refresh = storageService.getStringValueSync(
      key: ValueConstant.refreshToken,
    );

    if (refresh != null) {
      await httpService.postData(
        path: ApiConstant.authLogout,
        body: {'refreshToken': refresh},
      );
    }

    await storageService.removeValue(key: ValueConstant.jwtToken);
    await storageService.removeValue(key: ValueConstant.refreshToken);
  }

  @override
  Future<bool> hasSession() async {
    final token = storageService.getStringValueSync(
      key: ValueConstant.jwtToken,
    );
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveTokens(AuthModel auth) async {
    await storageService.setStringValue(
      key: ValueConstant.jwtToken,
      value: auth.accessToken,
    );
    await storageService.setStringValue(
      key: ValueConstant.refreshToken,
      value: auth.refreshToken,
    );
  }

  String? _extractMessage(Object? data) {
    if (data is Map<String, dynamic> && data['message'] != null) {
      return data['message'].toString();
    }
    return null;
  }
}
