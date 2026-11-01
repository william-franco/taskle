import 'package:taskle_app/src/common/patterns/state_pattern.dart';
import 'package:taskle_app/src/common/state_management/state_management.dart';
import 'package:taskle_app/src/features/settings/routes/setting_routes.dart';
import 'package:taskle_app/src/features/tasks/exceptions/task_exception.dart';
import 'package:taskle_app/src/features/tasks/models/task_model.dart';
import 'package:taskle_app/src/features/tasks/models/task_screen_state.dart';
import 'package:taskle_app/src/features/tasks/routes/task_routes.dart';
import 'package:taskle_app/src/features/tasks/view_models/task_view_model.dart';
import 'package:taskle_app/src/features/tasks/widgets/status_banner.dart';
import 'package:taskle_app/src/features/tasks/widgets/task_card.dart';
import 'package:taskle_app/src/features/tasks/widgets/task_empty_state.dart';
import 'package:taskle_app/src/features/tasks/widgets/task_error_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TaskView extends StatefulWidget {
  final TaskViewModel taskViewModel;

  const TaskView({super.key, required this.taskViewModel});

  @override
  State<TaskView> createState() => _TaskViewState();
}

class _TaskViewState extends State<TaskView> {
  @override
  void initState() {
    super.initState();
    widget.taskViewModel.startConnectionSync();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.taskViewModel.getAllTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => widget.taskViewModel.getAllTasks(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(SettingRoutes.setting),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => widget.taskViewModel.getAllTasks(),
        child: StateBuilderWidget<TaskViewModel, TaskScreenState>(
          viewModel: widget.taskViewModel,
          builder: (context, screenState) {
            final content = switch (screenState.tasks) {
              InitialState() || LoadingState() => const Center(
                child: CircularProgressIndicator(),
              ),
              ErrorState(:final error) => TaskErrorState(
                message: error.message,
                onRetry: () => widget.taskViewModel.getAllTasks(),
              ),
              SuccessState(:final data) => _buildSuccessState(data),
            };
            final hasPending =
                screenState.tasks
                    is SuccessState<List<TaskModel>, TaskException> &&
                (screenState.tasks
                        as SuccessState<List<TaskModel>, TaskException>)
                    .data
                    .any((t) => t.isPendingSync);
            return Column(
              children: [
                if (screenState.isOffline)
                  StatusBanner(
                    icon: Icons.cloud_off_outlined,
                    message: hasPending
                        ? 'Modo offline. Alterações serão sincronizadas ao reconectar.'
                        : 'Modo offline. Exibindo dados salvos no dispositivo.',
                  )
                else if (hasPending)
                  const StatusBanner(
                    icon: Icons.sync_outlined,
                    message: 'Há alterações pendentes de sincronização.',
                  ),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.push(TaskRoutes.taskForm, extra: widget.taskViewModel),
        child: const Icon(Icons.add_outlined),
      ),
    );
  }

  Widget _buildSuccessState(List<TaskModel> tasks) {
    if (tasks.isEmpty) return const TaskEmptyState();

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onTap: () => context.push(
            TaskRoutes.taskDetail(task.id),
            extra: {'task': task, 'viewModel': widget.taskViewModel},
          ),
          onEdit: () => context.push(
            TaskRoutes.taskForm,
            extra: {'task': task, 'viewModel': widget.taskViewModel},
          ),
          onToggle: (value) => widget.taskViewModel.updateTask(
            id: task.id,
            title: task.title,
            content: task.content,
            isCompleted: value,
          ),
        );
      },
    );
  }
}
