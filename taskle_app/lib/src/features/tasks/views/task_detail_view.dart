import 'package:taskle_app/src/common/patterns/state_pattern.dart';
import 'package:taskle_app/src/common/state_management/state_management.dart';
import 'package:taskle_app/src/features/tasks/exceptions/task_exception.dart';
import 'package:taskle_app/src/features/tasks/models/task_model.dart';
import 'package:taskle_app/src/features/tasks/models/task_screen_state.dart';
import 'package:taskle_app/src/features/tasks/routes/task_routes.dart';
import 'package:taskle_app/src/features/tasks/view_models/task_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TaskDetailView extends StatefulWidget {
  final TaskModel task;
  final TaskViewModel taskViewModel;

  const TaskDetailView({
    super.key,
    required this.task,
    required this.taskViewModel,
  });

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da Tarefa')),
      body: StateConsumerWidget<TaskViewModel, TaskScreenState>(
        viewModel: widget.taskViewModel,
        listener: (context, screenState) {
          if (screenState.deleted is SuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tarefa excluída')),
            );
            widget.taskViewModel.resetDeletedTaskState();
            context.go(TaskRoutes.tasks);
          }
        },
        builder: (context, screenState) {
          TaskModel current = widget.task;
          if (screenState.tasks is SuccessState<List<TaskModel>, TaskException>) {
            final list =
                (screenState.tasks as SuccessState<List<TaskModel>, TaskException>).data;
            current = list.firstWhere(
              (t) => t.id == widget.task.id,
              orElse: () => widget.task,
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(current.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Chip(
                  label: Text(current.isCompleted ? 'Concluída' : 'Pendente'),
                ),
                const SizedBox(height: 16),
                Text(current.content),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => context.push(
                    TaskRoutes.taskForm,
                    extra: {'task': current, 'viewModel': widget.taskViewModel},
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outlined),
                  label: const Text('Excluir'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir tarefa'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.taskViewModel.deleteTask(widget.task.id);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
