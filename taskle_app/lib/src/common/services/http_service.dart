import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:taskle_app/src/common/constants/api_constant.dart';
import 'package:taskle_app/src/common/constants/value_constant.dart';
import 'package:taskle_app/src/common/services/storage_service.dart';

typedef HttpResult = ({int? statusCode, Object? data, String? error});

abstract interface class HttpService {
  Future<HttpResult> getData({required String path});
  Future<HttpResult> postData({
    required String path,
    required Map<String, dynamic> body,
  });
  Future<HttpResult> putData({
    required String path,
    required Map<String, dynamic> body,
  });
  Future<HttpResult> deleteData({required String path});
}

class HttpServiceImpl implements HttpService {
  final StorageService storageService;
  bool _isRefreshing = false;

  late final Dio _client;
  late final Dio _authClient;

  HttpServiceImpl({required this.storageService}) {
    final baseOptions = BaseOptions(
      baseUrl: ApiConstant.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    );

    _authClient = Dio(baseOptions);

    _client = Dio(baseOptions)
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final token = storageService.getStringValueSync(
              key: ValueConstant.jwtToken,
            );
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            debugPrint('➡️  ${options.method} ${options.path}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('✅ ${response.statusCode} ${response.requestOptions.path}');
            handler.next(response);
          },
          onError: (error, handler) async {
            debugPrint('❌ ${error.response?.statusCode} ${error.requestOptions.path}');

            if (error.response?.statusCode == 401 && !_isRefreshing) {
              _isRefreshing = true;
              final refresh = storageService.getStringValueSync(
                key: ValueConstant.refreshToken,
              );
              if (refresh != null) {
                try {
                  final res = await _authClient.post(
                    '/auth/refresh',
                    data: {'refreshToken': refresh},
                  );
                  final newAccess = res.data['accessToken'] as String;
                  final newRefresh = res.data['refreshToken'] as String;
                  await storageService.setStringValue(
                    key: ValueConstant.jwtToken,
                    value: newAccess,
                  );
                  await storageService.setStringValue(
                    key: ValueConstant.refreshToken,
                    value: newRefresh,
                  );
                  _isRefreshing = false;
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newAccess';
                  final retried = await _client.fetch(error.requestOptions);
                  return handler.resolve(retried);
                } catch (_) {
                  await storageService.removeValue(key: ValueConstant.jwtToken);
                  await storageService.removeValue(
                    key: ValueConstant.refreshToken,
                  );
                }
              }
              _isRefreshing = false;
            }

            handler.next(error);
          },
        ),
      );
  }

  HttpResult _ok(Response r) =>
      (statusCode: r.statusCode, data: r.data, error: null);

  HttpResult _err(DioException e) => (
    statusCode: e.response?.statusCode,
    data: e.response?.data,
    error: e.message,
  );

  HttpResult _generic(Object e) =>
      (statusCode: null, data: null, error: '$e');

  @override
  Future<HttpResult> getData({required String path}) async {
    try {
      return _ok(await _client.get(path));
    } on DioException catch (e) {
      return _err(e);
    } catch (e) {
      return _generic(e);
    }
  }

  @override
  Future<HttpResult> postData({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    try {
      return _ok(await _client.post(path, data: body));
    } on DioException catch (e) {
      return _err(e);
    } catch (e) {
      return _generic(e);
    }
  }

  @override
  Future<HttpResult> putData({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    try {
      return _ok(await _client.put(path, data: body));
    } on DioException catch (e) {
      return _err(e);
    } catch (e) {
      return _generic(e);
    }
  }

  @override
  Future<HttpResult> deleteData({required String path}) async {
    try {
      return _ok(await _client.delete(path));
    } on DioException catch (e) {
      return _err(e);
    } catch (e) {
      return _generic(e);
    }
  }
}
