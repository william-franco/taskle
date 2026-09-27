import 'package:taskle_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:taskle_app/src/common/routes/routes.dart';
import 'package:taskle_app/src/common/state_management/state_management.dart';
import 'package:taskle_app/src/features/settings/models/setting_model.dart';
import 'package:taskle_app/src/features/settings/view_models/setting_view_model.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  dependencyInjector();
  await initDependencies();
  final Routes appRoutes = Routes();
  runApp(
    MyApp(
      appRoutes: appRoutes,
      settingViewModel: locator<SettingViewModel>(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Routes appRoutes;
  final SettingViewModel settingViewModel;

  const MyApp({
    super.key,
    required this.appRoutes,
    required this.settingViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return StateBuilderWidget<SettingViewModel, SettingModel>(
      viewModel: settingViewModel,
      builder: (context, setting) {
        return MaterialApp.router(
          title: 'Taskle',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: setting.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          routerConfig: appRoutes.routes,
        );
      },
    );
  }
}
