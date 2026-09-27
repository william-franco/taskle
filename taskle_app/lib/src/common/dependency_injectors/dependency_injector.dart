import 'package:taskle_app/src/common/services/connection_service.dart';
import 'package:taskle_app/src/common/services/http_service.dart';
import 'package:taskle_app/src/common/services/storage_service.dart';
import 'package:taskle_app/src/features/auth/repositories/auth_repository.dart';
import 'package:taskle_app/src/features/auth/view_models/auth_session_view_model.dart';
import 'package:taskle_app/src/features/auth/view_models/login_view_model.dart';
import 'package:taskle_app/src/features/auth/view_models/register_view_model.dart';
import 'package:taskle_app/src/features/tasks/repositories/task_repository.dart';
import 'package:taskle_app/src/features/tasks/view_models/task_view_model.dart';
import 'package:taskle_app/src/features/settings/repositories/setting_repository.dart';
import 'package:taskle_app/src/features/settings/view_models/setting_view_model.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

void dependencyInjector() {
  _registerServices();
  _registerAuth();
  _registerTasks();
  _registerSettings();
}

void _registerServices() {
  locator.registerLazySingleton<ConnectionService>(
    () => ConnectionServiceImpl(),
  );
  locator.registerLazySingleton<StorageService>(() => StorageServiceImpl());
  locator.registerLazySingleton<HttpService>(
    () => HttpServiceImpl(storageService: locator<StorageService>()),
  );
}

void _registerAuth() {
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      connectionService: locator<ConnectionService>(),
      httpService: locator<HttpService>(),
      storageService: locator<StorageService>(),
    ),
  );
  locator.registerLazySingleton<LoginViewModel>(
    () => LoginViewModelImpl(authRepository: locator<AuthRepository>()),
  );
  locator.registerLazySingleton<RegisterViewModel>(
    () => RegisterViewModelImpl(authRepository: locator<AuthRepository>()),
  );
  locator.registerLazySingleton<AuthSessionViewModel>(
    () => AuthSessionViewModelImpl(authRepository: locator<AuthRepository>()),
  );
}

void _registerTasks() {
  locator.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      connectionService: locator<ConnectionService>(),
      httpService: locator<HttpService>(),
    ),
  );
  locator.registerLazySingleton<TaskViewModel>(
    () => TaskViewModelImpl(taskRepository: locator<TaskRepository>()),
  );
}

void _registerSettings() {
  locator.registerLazySingleton<SettingRepository>(
    () => SettingRepositoryImpl(storageService: locator<StorageService>()),
  );
  locator.registerLazySingleton<SettingViewModel>(
    () => SettingViewModelImpl(settingRepository: locator<SettingRepository>()),
  );
}

Future<void> initDependencies() async {
  await locator<StorageService>().initStorage();
  await Future.wait([
    locator<SettingViewModel>().getTheme(),
  ]);
}

void resetDependencies() {
  locator.reset();
}
