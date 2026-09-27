import 'package:taskle_app/src/common/services/connection_service.dart';
import 'package:taskle_app/src/common/services/http_service.dart';
import 'package:taskle_app/src/common/services/storage_service.dart';
import 'package:taskle_app/src/features/auth/repositories/auth_repository.dart';
import 'package:taskle_app/src/features/auth/view_models/auth_session_view_model.dart';
import 'package:taskle_app/src/features/auth/view_models/login_view_model.dart';
import 'package:taskle_app/src/features/auth/view_models/register_view_model.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([
  ConnectionService,
  HttpService,
  StorageService,
  AuthRepository,
  LoginViewModel,
  RegisterViewModel,
  AuthSessionViewModel,
])
void main() {}
