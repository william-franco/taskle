import 'package:taskle_app/src/common/constants/api_constant.dart';
import 'package:taskle_app/src/common/patterns/result_pattern.dart';
import 'package:taskle_app/src/common/services/connection_service.dart';
import 'package:taskle_app/src/common/services/http_service.dart';
import 'package:taskle_app/src/features/tasks/data_sources/task_local_data_source.dart';
import 'package:taskle_app/src/features/tasks/exceptions/task_exception.dart';
import 'package:taskle_app/src/features/tasks/models/deleted_task_model.dart';
import 'package:taskle_app/src/features/tasks/models/task_model.dart';

typedef TasksResult = ResultPattern<List<TaskModel>, TaskException>;
typedef TaskResult = ResultPattern<TaskModel, TaskException>;
typedef DeleteTaskResult = ResultPattern<DeletedTaskModel, TaskException>;

abstract interface class TaskRepository {
  bool get isOnline;

  Stream<bool> get onConnectionChanged;

  Future<TasksResult> findLocalTasks();

  Future<TasksResult> findAllTasks();
  Future<TaskResult> createTask({
    required String title,
    required String content,
  });
  Future<TaskResult> updateTask({
    required int id,
    required String title,
    required String content,
    required bool isCompleted,
  });
  Future<DeleteTaskResult> deleteTask(int id);

  Future<bool> syncTasks();
}

class TaskRepositoryImpl implements TaskRepository {
  final ConnectionService connectionService;
  final HttpService httpService;
  final TaskLocalDataSource localDataSource;

  bool _isSyncing = false;

  TaskRepositoryImpl({
    required this.connectionService,
    required this.httpService,
    required this.localDataSource,
  });

  @override
  bool get isOnline => connectionService.isConnected;

  @override
  Stream<bool> get onConnectionChanged => connectionService.onConnectionChanged;

  @override
  Future<TasksResult> findLocalTasks() async {
    try {
      return SuccessResult(value: await localDataSource.getTasks());
    } catch (error) {
      return ErrorResult(error: TaskException('Erro inesperado: $error'));
    }
  }

  @override
  Future<TasksResult> findAllTasks() async {
    try {
      await syncTasks();
      return SuccessResult(value: await localDataSource.getTasks());
    } catch (error) {
      return ErrorResult(error: TaskException('Erro inesperado: $error'));
    }
  }

  @override
  Future<TaskResult> createTask({
    required String title,
    required String content,
  }) async {
    try {
      final created = await localDataSource.insert(
        title: title,
        content: content,
        now: DateTime.now().toUtc(),
      );
      await syncTasks(pull: false);
      return SuccessResult(
        value: await localDataSource.getById(created.id) ?? created,
      );
    } catch (error) {
      return ErrorResult(error: TaskException('Erro inesperado: $error'));
    }
  }

  @override
  Future<TaskResult> updateTask({
    required int id,
    required String title,
    required String content,
    required bool isCompleted,
  }) async {
    try {
      final updated = await localDataSource.update(
        id: id,
        title: title,
        content: content,
        isCompleted: isCompleted,
        now: DateTime.now().toUtc(),
      );
      if (updated == null) {
        return ErrorResult(error: TaskException('Tarefa não encontrada.'));
      }
      await syncTasks(pull: false);
      return SuccessResult(value: await localDataSource.getById(id) ?? updated);
    } catch (error) {
      return ErrorResult(error: TaskException('Erro inesperado: $error'));
    }
  }

  @override
  Future<DeleteTaskResult> deleteTask(int id) async {
    try {
      final deleted = await localDataSource.delete(id);
      if (deleted == null) {
        return ErrorResult(error: TaskException('Tarefa não encontrada.'));
      }
      await syncTasks(pull: false);
      return SuccessResult(
        value: DeletedTaskModel(
          title: 'Task excluida',
          description: 'A task ${deleted.title} foi removida',
        ),
      );
    } catch (error) {
      return ErrorResult(error: TaskException('Erro inesperado: $error'));
    }
  }

  @override
  Future<bool> syncTasks({bool pull = true}) async {
    if (_isSyncing) return false;
    _isSyncing = true;
    try {
      try {
        await connectionService.checkConnection();
      } catch (_) {
        return false;
      }
      if (!connectionService.isConnected) return false;

      final pushed = await _pushPending();
      if (!pushed) return false;

      if (pull) {
        final result = await httpService.getData(path: ApiConstant.tasks);
        if (result.statusCode != 200 || result.data == null) return false;
        final remote = (result.data as List)
            .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await localDataSource.replaceSynced(remote);
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _pushPending() async {
    final pending = await localDataSource.getPending();
    for (final task in pending) {
      final ok = switch (task.syncState) {
        TaskSyncState.created => await _pushCreate(task),
        TaskSyncState.updated => await _pushUpdate(task),
        TaskSyncState.deleted => await _pushDelete(task),
        TaskSyncState.synced => true,
      };
      if (!ok) return false;
    }
    return true;
  }

  bool _isSuccess(HttpResult r) =>
      (r.statusCode == 200 || r.statusCode == 201) && r.data != null;

  Future<bool> _pushCreate(TaskModel task) async {
    final result = await httpService.postData(
      path: ApiConstant.tasks,
      body: {'title': task.title, 'content': task.content},
    );
    if (!_isSuccess(result)) return false;

    var remote = TaskModel.fromJson(result.data as Map<String, dynamic>);
    await localDataSource.markSynced(task.id, remote);

    if (task.isCompleted) {
      final updated = await httpService.putData(
        path: '${ApiConstant.tasks}/${remote.id}',
        body: {'isCompleted': true},
      );
      if (!_isSuccess(updated)) {
        await localDataSource.update(
          id: task.id,
          title: task.title,
          content: task.content,
          isCompleted: true,
          now: task.updatedAt,
        );
        return false;
      }
      remote = TaskModel.fromJson(updated.data as Map<String, dynamic>);
      await localDataSource.markSynced(task.id, remote);
    }
    return true;
  }

  Future<bool> _pushUpdate(TaskModel task) async {
    final result = await httpService.putData(
      path: '${ApiConstant.tasks}/${task.remoteId}',
      body: {
        'title': task.title,
        'content': task.content,
        'isCompleted': task.isCompleted,
        'clientUpdatedAt': task.updatedAt.toUtc().toIso8601String(),
      },
    );
    if (result.statusCode == 404) {
      await localDataSource.remove(task.id);
      return true;
    }
    if (!_isSuccess(result)) return false;
    await localDataSource.markSynced(
      task.id,
      TaskModel.fromJson(result.data as Map<String, dynamic>),
    );
    return true;
  }

  Future<bool> _pushDelete(TaskModel task) async {
    final result = await httpService.deleteData(
      path: '${ApiConstant.tasks}/${task.remoteId}',
    );
    if (result.statusCode == 200 || result.statusCode == 404) {
      await localDataSource.remove(task.id);
      return true;
    }
    return false;
  }
}
