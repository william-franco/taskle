import 'package:taskle_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:taskle_app/src/features/auth/view_models/auth_session_view_model.dart';
import 'package:taskle_app/src/features/auth/view_models/login_view_model.dart';
import 'package:taskle_app/src/features/auth/view_models/register_view_model.dart';
import 'package:taskle_app/src/features/auth/views/auth_view.dart';
import 'package:taskle_app/src/features/auth/views/login_view.dart';
import 'package:taskle_app/src/features/auth/views/register_view.dart';
import 'package:go_router/go_router.dart';

class AuthRoutes {
  static String get auth => '/auth';
  static String get login => '/login';
  static String get register => '/register';

  List<GoRoute> get routes => _routes;

  final List<GoRoute> _routes = [
    GoRoute(
      path: auth,
      builder: (context, state) {
        return AuthView(
          authSessionViewModel: locator<AuthSessionViewModel>(),
        );
      },
    ),
    GoRoute(
      path: login,
      builder: (context, state) {
        return LoginView(loginViewModel: locator<LoginViewModel>());
      },
    ),
    GoRoute(
      path: register,
      builder: (context, state) {
        return RegisterView(
          registerViewModel: locator<RegisterViewModel>(),
        );
      },
    ),
  ];
}
