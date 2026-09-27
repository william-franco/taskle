import 'package:taskle_app/src/common/patterns/state_pattern.dart';
import 'package:taskle_app/src/common/state_management/state_management.dart';
import 'package:taskle_app/src/features/tasks/exceptions/task_exception.dart';
import 'package:taskle_app/src/features/tasks/models/task_model.dart';
import 'package:taskle_app/src/features/tasks/models/task_screen_state.dart';
import 'package:taskle_app/src/features/tasks/view_models/task_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TaskFormView extends StatefulWidget {
  final TaskViewModel taskViewModel;
  final TaskModel? task;

  const TaskFormView({super.key, required this.taskViewModel, this.task});

  @override
  State<TaskFormView> createState() => _TaskFormViewState();
}

class _TaskFormViewState extends State<TaskFormView> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late bool _isCompleted;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title);
    _contentController = TextEditingController(text: widget.task?.content);
    _isCompleted = widget.task?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Tarefa' : 'Nova Tarefa'),
        leading: IconButton(
          icon: const Icon(Icons.close_outlined),
          onPressed: () {
            widget.taskViewModel.resetMutationState();
            context.pop();
          },
        ),
      ),
      body: StateConsumerWidget<TaskViewModel, TaskScreenState>(
        viewModel: widget.taskViewModel,
        listener: (context, screenState) {
          if (screenState.mutation is SuccessState<TaskModel, TaskException>) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEditing ? 'Tarefa atualizada!' : 'Tarefa criada!',
                ),
              ),
            );
            widget.taskViewModel.resetMutationState();
            context.pop();
          }
          if (screenState.mutation is ErrorState<TaskModel, TaskException>) {
            final error =
                (screenState.mutation as ErrorState<TaskModel, TaskException>).error;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.message)),
            );
          }
        },
        builder: (context, screenState) {
          final loading = screenState.mutation is LoadingState;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Concluída'),
                    value: _isCompleted,
                    onChanged: loading ? null : (v) => setState(() => _isCompleted = v),
                  ),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Salvar' : 'Criar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o título')),
      );
      return;
    }
    if (isEditing) {
      widget.taskViewModel.updateTask(
        id: widget.task!.id,
        title: title,
        content: content,
        isCompleted: _isCompleted,
      );
    } else {
      widget.taskViewModel.createTask(title: title, content: content);
    }
  }
}
