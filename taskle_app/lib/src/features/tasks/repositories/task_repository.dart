import 'package:taskle_app/src/common/constants/api_constant.dart';
import 'package:taskle_app/src/common/patterns/result_pattern.dart';
import 'package:taskle_app/src/common/services/connection_service.dart';
import 'package:taskle_app/src/common/services/http_service.dart';
import 'package:taskle_app/src/features/tasks/exceptions/task_exception.dart';
import 'package:taskle_app/src/features/tasks/models/deleted_task_model.dart';
import 'package:taskle_app/src/features/tasks/models/task_model.dart';

typedef TasksResult = ResultPattern<List<TaskModel>, TaskException>;
typedef TaskResult = ResultPattern<TaskModel, TaskException>;
typedef DeleteTaskResult = ResultPattern<DeletedTaskModel, TaskException>;

abstract interface class TaskRepository {
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
}

class TaskRepositoryImpl implements TaskRepository {
  final ConnectionService connectionService;
  final HttpService httpService;

  TaskRepositoryImpl({
    required this.connectionService,
    required this.httpService,
  });

  @override
  Future<TasksResult> findAllTasks() async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: TaskException('Dispositivo sem conexão.'));
      }

      final result = await httpService.getData(path: ApiConstant.tasks);

      if (result.statusCode == 200 && result.data != null) {
        final tasks = (result.data as List)
            .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return SuccessResult(value: tasks);
      }

      return ErrorResult(
        error: TaskException('Falha ao carregar tarefas: ${result.statusCode}'),
      );
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
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: TaskException('Dispositivo sem conexão.'));
      }

      final result = await httpService.postData(
        path: ApiConstant.tasks,
        body: {'title': title, 'content': content},
      );

      if ((result.statusCode == 201 || result.statusCode == 200) &&
          result.data != null) {
        return SuccessResult(
          value: TaskModel.fromJson(result.data as Map<String, dynamic>),
        );
      }

      return ErrorResult(
        error: TaskException('Falha ao criar tarefa: ${result.statusCode}'),
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
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: TaskException('Dispositivo sem conexão.'));
      }

      final result = await httpService.putData(
        path: '${ApiConstant.tasks}/$id',
        body: {
          'title': title,
          'content': content,
          'isCompleted': isCompleted,
        },
      );

      if (result.statusCode == 200 && result.data != null) {
        return SuccessResult(
          value: TaskModel.fromJson(result.data as Map<String, dynamic>),
        );
      }

      return ErrorResult(
        error: TaskException('Falha ao atualizar tarefa: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: TaskException('Erro inesperado: $error'));
    }
  }

  @override
  Future<DeleteTaskResult> deleteTask(int id) async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: TaskException('Dispositivo sem conexão.'));
      }

      final result = await httpService.deleteData(path: '${ApiConstant.tasks}/$id');

      if (result.statusCode == 200 && result.data != null) {
        final data = result.data as Map<String, dynamic>;
        return SuccessResult(
          value: DeletedTaskModel(
            title: data['title'] as String? ?? 'Task excluida',
            description: data['description'] as String? ?? '',
          ),
        );
      }

      return ErrorResult(
        error: TaskException('Falha ao excluir tarefa: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: TaskException('Erro inesperado: $error'));
    }
  }
}
