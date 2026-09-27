import 'package:taskle_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:taskle_app/src/features/tasks/models/task_model.dart';
import 'package:taskle_app/src/features/tasks/view_models/task_view_model.dart';
import 'package:taskle_app/src/features/tasks/views/task_detail_view.dart';
import 'package:taskle_app/src/features/tasks/views/task_form_view.dart';
import 'package:taskle_app/src/features/tasks/views/task_view.dart';
import 'package:go_router/go_router.dart';

class TaskRoutes {
  static String get tasks => '/tasks';
  static String get taskForm => '/tasks/form';
  static String taskDetail(int id) => '/tasks/$id';

  List<RouteBase> get routes => [
    GoRoute(
      path: tasks,
      builder: (context, state) {
        return TaskView(taskViewModel: locator<TaskViewModel>());
      },
    ),
    GoRoute(
      path: taskForm,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          return TaskFormView(
            taskViewModel: extra['viewModel'] as TaskViewModel,
            task: extra['task'] as TaskModel?,
          );
        }
        if (extra is TaskViewModel) {
          return TaskFormView(taskViewModel: extra);
        }
        return TaskFormView(taskViewModel: locator<TaskViewModel>());
      },
    ),
    GoRoute(
      path: '/tasks/:id',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return TaskDetailView(
          task: extras['task'] as TaskModel,
          taskViewModel: extras['viewModel'] as TaskViewModel,
        );
      },
    ),
  ];
}
