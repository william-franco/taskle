import 'package:taskle_app/src/common/constants/api_constant.dart';
import 'package:taskle_app/src/common/patterns/result_pattern.dart';
import 'package:taskle_app/src/features/tasks/data_sources/task_local_data_source.dart';
import 'package:taskle_app/src/features/tasks/exceptions/task_exception.dart';
import 'package:taskle_app/src/features/tasks/models/task_model.dart';
import 'package:taskle_app/src/features/tasks/repositories/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../task_mocks.mocks.dart';

/// In-memory implementation mirroring the SQLite data source behavior.
class FakeTaskLocalDataSource implements TaskLocalDataSource {
  final Map<int, TaskModel> rows = {};
  int _nextId = 1;

  @override
  Future<void> init() async {}

  @override
  Future<List<TaskModel>> getTasks() async =>
      rows.values.where((t) => t.syncState != TaskSyncState.deleted).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<TaskModel?> getById(int id) async => rows[id];

  @override
  Future<TaskModel> insert({
    required String title,
    required String content,
    required DateTime now,
  }) async {
    final task = TaskModel(
      id: _nextId++,
      title: title,
      content: content,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      syncState: TaskSyncState.created,
    );
    rows[task.id] = task;
    return task;
  }

  @override
  Future<TaskModel?> update({
    required int id,
    required String title,
    required String content,
    required bool isCompleted,
    required DateTime now,
  }) async {
    final current = rows[id];
    if (current == null || current.syncState == TaskSyncState.deleted) {
      return null;
    }
    return rows[id] = current.copyWith(
      title: title,
      content: content,
      isCompleted: isCompleted,
      updatedAt: now,
      syncState: current.syncState == TaskSyncState.created
          ? TaskSyncState.created
          : TaskSyncState.updated,
    );
  }

  @override
  Future<TaskModel?> delete(int id) async {
    final current = rows[id];
    if (current == null) return null;
    if (current.remoteId == null) {
      rows.remove(id);
    } else {
      rows[id] = current.copyWith(syncState: TaskSyncState.deleted);
    }
    return current;
  }

  @override
  Future<List<TaskModel>> getPending() async =>
      rows.values.where((t) => t.syncState != TaskSyncState.synced).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  @override
  Future<void> markSynced(int id, TaskModel remote) async {
    rows[id] = remote.copyWith(id: id, syncState: TaskSyncState.synced);
  }

  @override
  Future<void> remove(int id) async => rows.remove(id);

  @override
  Future<void> replaceSynced(List<TaskModel> remote) async {
    final ids = remote.map((e) => e.remoteId).toSet();
    rows.removeWhere(
      (_, t) =>
          t.syncState == TaskSyncState.synced && !ids.contains(t.remoteId),
    );
    for (final task in remote) {
      final entry = rows.entries
          .where((e) => e.value.remoteId == task.remoteId)
          .firstOrNull;
      if (entry == null) {
        final id = _nextId++;
        rows[id] = task.copyWith(id: id);
      } else if (entry.value.syncState == TaskSyncState.synced) {
        rows[entry.key] = task.copyWith(id: entry.key);
      }
    }
  }

  @override
  Future<void> clear() async => rows.clear();
}

void main() {
  late MockConnectionService mockConnection;
  late MockHttpService mockHttp;
  late FakeTaskLocalDataSource local;
  late TaskRepositoryImpl repository;
  var online = true;

  setUp(() {
    online = true;
    mockConnection = MockConnectionService();
    mockHttp = MockHttpService();
    local = FakeTaskLocalDataSource();
    repository = TaskRepositoryImpl(
      connectionService: mockConnection,
      httpService: mockHttp,
      localDataSource: local,
    );
    when(mockConnection.isConnected).thenAnswer((_) => online);
    when(mockConnection.checkConnection()).thenAnswer((_) async {});
    when(mockHttp.getData(path: ApiConstant.tasks)).thenAnswer(
      (_) async => (statusCode: 200, data: <dynamic>[], error: null),
    );
  });

  Map<String, dynamic> json(
    int id, {
    String title = 'Title',
    bool done = false,
    String updatedAt = '2024-01-01T00:00:00.000Z',
  }) => {
    'id': id,
    'title': title,
    'content': 'Content',
    'isCompleted': done,
    'createdAt': '2024-01-01T00:00:00.000Z',
    'updatedAt': updatedAt,
  };

  test('findAllTasks pulls remote tasks into the local cache', () async {
    when(
      mockHttp.getData(path: ApiConstant.tasks),
    ).thenAnswer((_) async => (statusCode: 200, data: [json(10)], error: null));

    final result = await repository.findAllTasks();

    final tasks =
        (result as SuccessResult<List<TaskModel>, TaskException>).value;
    expect(tasks, hasLength(1));
    expect(tasks.first.remoteId, 10);
    expect(tasks.first.isPendingSync, isFalse);
  });

  test('findAllTasks returns cached tasks when offline', () async {
    when(
      mockHttp.getData(path: ApiConstant.tasks),
    ).thenAnswer((_) async => (statusCode: 200, data: [json(10)], error: null));
    await repository.findAllTasks();

    online = false;
    final result = await repository.findAllTasks();

    final tasks =
        (result as SuccessResult<List<TaskModel>, TaskException>).value;
    expect(tasks, hasLength(1));
    verify(mockHttp.getData(path: ApiConstant.tasks)).called(1);
  });

  test('createTask offline is stored locally and queued', () async {
    online = false;

    final result = await repository.createTask(title: 'A', content: 'B');

    final task = (result as SuccessResult<TaskModel, TaskException>).value;
    expect(task.syncState, TaskSyncState.created);
    expect(task.remoteId, isNull);
    verifyNever(
      mockHttp.postData(path: anyNamed('path'), body: anyNamed('body')),
    );
  });

  test(
    'pending create is pushed when connection returns, keeping local id',
    () async {
      online = false;
      final created = await repository.createTask(title: 'A', content: 'B');
      final localId =
          (created as SuccessResult<TaskModel, TaskException>).value.id;

      online = true;
      when(mockHttp.postData(path: ApiConstant.tasks, body: anyNamed('body')))
          .thenAnswer(
            (_) async =>
                (statusCode: 201, data: json(99, title: 'A'), error: null),
          );
      when(mockHttp.getData(path: ApiConstant.tasks)).thenAnswer(
        (_) async =>
            (statusCode: 200, data: [json(99, title: 'A')], error: null),
      );

      expect(await repository.syncTasks(), isTrue);

      final task = (await local.getById(localId))!;
      expect(task.remoteId, 99);
      expect(task.isPendingSync, isFalse);
      expect(local.rows, hasLength(1));
    },
  );

  test('create then delete offline never reaches the server', () async {
    online = false;
    final created = await repository.createTask(title: 'A', content: 'B');
    final id = (created as SuccessResult<TaskModel, TaskException>).value.id;

    await repository.deleteTask(id);

    expect(local.rows, isEmpty);
    expect(await local.getPending(), isEmpty);
  });

  test(
    'update offline sends clientUpdatedAt (last-write-wins) on sync',
    () async {
      when(mockHttp.getData(path: ApiConstant.tasks)).thenAnswer(
        (_) async => (statusCode: 200, data: [json(10)], error: null),
      );
      await repository.findAllTasks();
      final id = local.rows.keys.first;

      online = false;
      await repository.updateTask(
        id: id,
        title: 'New',
        content: 'C',
        isCompleted: true,
      );
      expect((await local.getById(id))!.syncState, TaskSyncState.updated);

      online = true;
      when(
        mockHttp.putData(
          path: '${ApiConstant.tasks}/10',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => (
          statusCode: 200,
          data: json(
            10,
            title: 'Server',
            updatedAt: '2030-01-01T00:00:00.000Z',
          ),
          error: null,
        ),
      );
      await repository.syncTasks(pull: false);

      verify(
        mockHttp.putData(
          path: '${ApiConstant.tasks}/10',
          body: argThat(
            containsPair('clientUpdatedAt', isA<String>()),
            named: 'body',
          ),
        ),
      ).called(1);
      final task = (await local.getById(id))!;
      expect(task.title, 'Server');
      expect(task.isPendingSync, isFalse);
    },
  );

  test('delete offline is pushed later and removes the row', () async {
    when(
      mockHttp.getData(path: ApiConstant.tasks),
    ).thenAnswer((_) async => (statusCode: 200, data: [json(10)], error: null));
    await repository.findAllTasks();
    final id = local.rows.keys.first;

    online = false;
    await repository.deleteTask(id);
    expect(await local.getTasks(), isEmpty);
    expect(await local.getPending(), hasLength(1));

    online = true;
    when(mockHttp.deleteData(path: '${ApiConstant.tasks}/10')).thenAnswer(
      (_) async => (
        statusCode: 200,
        data: {'title': 't', 'description': 'd'},
        error: null,
      ),
    );
    await repository.syncTasks(pull: false);

    expect(local.rows, isEmpty);
  });

  test('failed push keeps pending operations for a later retry', () async {
    online = false;
    await repository.createTask(title: 'A', content: 'B');
    online = true;
    when(
      mockHttp.postData(path: ApiConstant.tasks, body: anyNamed('body')),
    ).thenAnswer((_) async => (statusCode: null, data: null, error: 'timeout'));

    expect(await repository.syncTasks(), isFalse);
    expect(await local.getPending(), hasLength(1));
  });
}
