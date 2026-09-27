import 'package:taskle_app/src/common/patterns/result_pattern.dart';
import 'package:taskle_app/src/common/patterns/state_pattern.dart';
import 'package:taskle_app/src/features/tasks/exceptions/task_exception.dart';
import 'package:taskle_app/src/features/tasks/models/task_model.dart';
import 'package:taskle_app/src/features/tasks/view_models/task_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../task_mocks.mocks.dart';

void main() {
  late MockTaskRepository mockRepository;
  late TaskViewModelImpl viewModel;

  final sampleTask = TaskModel(
    id: 1,
    title: 'Task 1',
    content: 'Content 1',
    isCompleted: false,
    createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
    updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
  );

  setUpAll(() {
    provideDummy<ResultPattern<List<TaskModel>, TaskException>>(
      ErrorResult(error: TaskException('dummy')),
    );
    provideDummy<ResultPattern<TaskModel, TaskException>>(
      ErrorResult(error: TaskException('dummy')),
    );
  });

  setUp(() {
    mockRepository = MockTaskRepository();
    viewModel = TaskViewModelImpl(taskRepository: mockRepository);
  });

  tearDown(() => viewModel.dispose());

  test('initial state', () {
    expect(viewModel.state.tasks, isA<InitialState>());
    expect(viewModel.state.mutation, isA<InitialState>());
    expect(viewModel.state.deleted, isA<InitialState>());
  });

  test('getAllTasks success', () async {
    when(mockRepository.findAllTasks()).thenAnswer(
      (_) async => SuccessResult(value: [sampleTask]),
    );

    await viewModel.getAllTasks();

    expect(
      viewModel.state.tasks,
      isA<SuccessState<List<TaskModel>, TaskException>>(),
    );
  });

  test('createTask refreshes list on success', () async {
    when(
      mockRepository.createTask(
        title: anyNamed('title'),
        content: anyNamed('content'),
      ),
    ).thenAnswer((_) async => SuccessResult(value: sampleTask));
    when(mockRepository.findAllTasks()).thenAnswer(
      (_) async => SuccessResult(value: [sampleTask]),
    );

    await viewModel.createTask(title: 'T', content: 'Content long enough');

    verify(mockRepository.findAllTasks()).called(1);
  });
}
