import 'package:taskle_app/src/common/patterns/state_pattern.dart';
import 'package:taskle_app/src/features/tasks/exceptions/task_exception.dart';
import 'package:taskle_app/src/features/tasks/models/deleted_task_model.dart';
import 'package:taskle_app/src/features/tasks/models/task_model.dart';

typedef TasksState = StatePattern<List<TaskModel>, TaskException>;
typedef TaskMutationState = StatePattern<TaskModel, TaskException>;
typedef DeletedTaskState = StatePattern<DeletedTaskModel, TaskException>;

class TaskScreenState {
  final TasksState tasks;
  final TaskMutationState mutation;
  final DeletedTaskState deleted;

  const TaskScreenState({
    this.tasks = const InitialState(),
    this.mutation = const InitialState(),
    this.deleted = const InitialState(),
  });

  TaskScreenState copyWith({
    TasksState? tasks,
    TaskMutationState? mutation,
    DeletedTaskState? deleted,
  }) {
    return TaskScreenState(
      tasks: tasks ?? this.tasks,
      mutation: mutation ?? this.mutation,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskScreenState &&
          tasks == other.tasks &&
          mutation == other.mutation &&
          deleted == other.deleted;

  @override
  int get hashCode => Object.hash(tasks, mutation, deleted);
}
