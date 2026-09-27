import 'package:taskle_app/src/common/constants/api_constant.dart';
import 'package:taskle_app/src/common/patterns/result_pattern.dart';
import 'package:taskle_app/src/features/tasks/exceptions/task_exception.dart';
import 'package:taskle_app/src/features/tasks/models/task_model.dart';
import 'package:taskle_app/src/features/tasks/repositories/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../task_mocks.mocks.dart';

void main() {
  late MockConnectionService mockConnection;
  late MockHttpService mockHttp;
  late TaskRepositoryImpl repository;

  setUp(() {
    mockConnection = MockConnectionService();
    mockHttp = MockHttpService();
    repository = TaskRepositoryImpl(
      connectionService: mockConnection,
      httpService: mockHttp,
    );
    when(mockConnection.isConnected).thenReturn(true);
  });

  final taskJson = {
    'id': 1,
    'title': 'Title',
    'content': 'Content',
    'isCompleted': false,
    'createdAt': '2024-01-01T00:00:00.000Z',
    'updatedAt': '2024-01-01T00:00:00.000Z',
  };

  test('findAllTasks returns list on 200', () async {
    when(mockConnection.checkConnection()).thenAnswer((_) async {});
    when(mockHttp.getData(path: ApiConstant.tasks)).thenAnswer(
      (_) async => (statusCode: 200, data: [taskJson], error: null),
    );

    final result = await repository.findAllTasks();

    expect(result, isA<SuccessResult<List<TaskModel>, TaskException>>());
    final tasks = (result as SuccessResult<List<TaskModel>, TaskException>).value;
    expect(tasks, hasLength(1));
    expect(tasks.first.title, 'Title');
  });

  test('createTask sends title and content', () async {
    when(mockConnection.checkConnection()).thenAnswer((_) async {});
    when(
      mockHttp.postData(path: ApiConstant.tasks, body: anyNamed('body')),
    ).thenAnswer(
      (_) async => (statusCode: 201, data: taskJson, error: null),
    );

    final result = await repository.createTask(
      title: 'Title',
      content: 'Content body here',
    );

    expect(result, isA<SuccessResult<TaskModel, TaskException>>());
    verify(
      mockHttp.postData(
        path: ApiConstant.tasks,
        body: argThat(
          allOf(
            containsPair('title', 'Title'),
            containsPair('content', 'Content body here'),
          ),
          named: 'body',
        ),
      ),
    ).called(1);
  });
}
