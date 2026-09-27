import 'package:taskle_app/src/common/services/connection_service.dart';
import 'package:taskle_app/src/common/services/http_service.dart';
import 'package:taskle_app/src/features/tasks/repositories/task_repository.dart';
import 'package:taskle_app/src/features/tasks/view_models/task_view_model.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([
  ConnectionService,
  HttpService,
  TaskRepository,
  TaskViewModel,
])
void main() {}
