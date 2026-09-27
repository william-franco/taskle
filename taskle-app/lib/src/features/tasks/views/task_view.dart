import 'package:taskle_app/src/common/patterns/state_pattern.dart';
import 'package:taskle_app/src/common/state_management/state_management.dart';
import 'package:taskle_app/src/features/settings/routes/setting_routes.dart';
import 'package:taskle_app/src/features/tasks/exceptions/task_exception.dart';
import 'package:taskle_app/src/features/tasks/models/task_model.dart';
import 'package:taskle_app/src/features/tasks/models/task_screen_state.dart';
import 'package:taskle_app/src/features/tasks/routes/task_routes.dart';
import 'package:taskle_app/src/features/tasks/view_models/task_view_model.dart';
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
            return switch (screenState.tasks) {
              InitialState() || LoadingState() => const Center(
                child: CircularProgressIndicator(),
              ),
              ErrorState(:final error) => _buildError(error),
              SuccessState(:final data) => _buildSuccessState(data),
            };
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(TaskRoutes.taskForm, extra: widget.taskViewModel),
        child: const Icon(Icons.add_outlined),
      ),
    );
  }

  Widget _buildError(TaskException error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(error.message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => widget.taskViewModel.getAllTasks(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'Nenhuma tarefa.\nToque em + para criar.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskCard(
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

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Checkbox(value: task.isCompleted, onChanged: (v) => onToggle(v ?? false)),
        title: Text(
          task.title,
          style: task.isCompleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          task.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
      ),
    );
  }
}
