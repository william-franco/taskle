import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConstant {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5062/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:5062/api/v1';
    return 'http://localhost:5062/api/v1';
  }

  static String get authRegister => '/auth/register';
  static String get authLogin => '/auth/login';
  static String get authLogout => '/auth/logout';
  static String get authMe => '/auth/me';
  static String get tasks => '/tasks';
}
