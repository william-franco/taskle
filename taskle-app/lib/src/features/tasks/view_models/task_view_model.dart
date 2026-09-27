import 'package:taskle_app/src/common/patterns/state_pattern.dart';
import 'package:taskle_app/src/common/state_management/state_management.dart';
import 'package:taskle_app/src/common/patterns/result_pattern.dart';
import 'package:taskle_app/src/features/tasks/exceptions/task_exception.dart';
import 'package:taskle_app/src/features/tasks/models/task_model.dart';
import 'package:taskle_app/src/features/tasks/models/task_screen_state.dart';
import 'package:taskle_app/src/features/tasks/repositories/task_repository.dart';
import 'package:flutter/foundation.dart';

typedef _ViewModel = StateManagement<TaskScreenState>;

abstract interface class TaskViewModel extends _ViewModel {
  Future<void> getAllTasks();
  Future<void> createTask({required String title, required String content});
  Future<void> updateTask({
    required int id,
    required String title,
    required String content,
    required bool isCompleted,
  });
  Future<void> deleteTask(int id);
  void resetMutationState();
  void resetDeletedTaskState();
}

class TaskViewModelImpl extends _ViewModel implements TaskViewModel {
  final TaskRepository taskRepository;

  TaskViewModelImpl({required this.taskRepository});

  @override
  TaskScreenState build() => const TaskScreenState();

  @override
  Future<void> getAllTasks() async {
    _emit(state.copyWith(tasks: const LoadingState()));
    final result = await taskRepository.findAllTasks();
    final tasksState = result.fold<TasksState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );
    _emit(state.copyWith(tasks: tasksState));
  }

  @override
  Future<void> createTask({
    required String title,
    required String content,
  }) async {
    _emit(state.copyWith(mutation: const LoadingState()));
    final result = await taskRepository.createTask(title: title, content: content);
    final mutationState = result.fold<TaskMutationState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );
    _emit(state.copyWith(mutation: mutationState));
    if (result is SuccessResult<TaskModel, TaskException>) {
      await getAllTasks();
    }
  }

  @override
  Future<void> updateTask({
    required int id,
    required String title,
    required String content,
    required bool isCompleted,
  }) async {
    _emit(state.copyWith(mutation: const LoadingState()));
    final result = await taskRepository.updateTask(
      id: id,
      title: title,
      content: content,
      isCompleted: isCompleted,
    );
    final mutationState = result.fold<TaskMutationState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );
    _emit(state.copyWith(mutation: mutationState));
    if (result is SuccessResult<TaskModel, TaskException>) {
      await getAllTasks();
    }
  }

  @override
  Future<void> deleteTask(int id) async {
    _emit(state.copyWith(deleted: const LoadingState()));
    final result = await taskRepository.deleteTask(id);
    final deletedState = result.fold<DeletedTaskState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );
    _emit(state.copyWith(deleted: deletedState));
    if (result is SuccessResult) {
      await getAllTasks();
    }
  }

  @override
  void resetMutationState() {
    _emit(state.copyWith(mutation: const InitialState()));
  }

  @override
  void resetDeletedTaskState() {
    _emit(state.copyWith(deleted: const InitialState()));
  }

  void _emit(TaskScreenState newState) {
    emitState(newState);
    debugPrint('TaskViewModel: $state');
  }
}
