import 'dart:io' show Platform;

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:taskle_app/src/features/tasks/models/task_model.dart';

abstract interface class TaskLocalDataSource {
  Future<void> init();

  Future<List<TaskModel>> getTasks();
  Future<TaskModel?> getById(int id);

  Future<TaskModel> insert({
    required String title,
    required String content,
    required DateTime now,
  });

  Future<TaskModel?> update({
    required int id,
    required String title,
    required String content,
    required bool isCompleted,
    required DateTime now,
  });

  Future<TaskModel?> delete(int id);

  Future<List<TaskModel>> getPending();

  Future<void> markSynced(int id, TaskModel remote);
  Future<void> remove(int id);

  Future<void> replaceSynced(List<TaskModel> remote);

  Future<void> clear();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  static const String _table = 'tasks';

  late final Database _db;

  @override
  Future<void> init() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final path = p.join(await getDatabasesPath(), 'taskle.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER UNIQUE,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            is_completed INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_state TEXT NOT NULL
          )
        ''');
      },
    );
  }

  TaskModel _fromRow(Map<String, Object?> r) => TaskModel(
    id: r['id'] as int,
    remoteId: r['remote_id'] as int?,
    title: r['title'] as String,
    content: r['content'] as String,
    isCompleted: (r['is_completed'] as int) == 1,
    createdAt: DateTime.parse(r['created_at'] as String),
    updatedAt: DateTime.parse(r['updated_at'] as String),
    syncState: TaskSyncState.fromName(r['sync_state'] as String?),
  );

  Map<String, Object?> _toRow(TaskModel t) => {
    'remote_id': t.remoteId,
    'title': t.title,
    'content': t.content,
    'is_completed': t.isCompleted ? 1 : 0,
    'created_at': t.createdAt.toUtc().toIso8601String(),
    'updated_at': t.updatedAt.toUtc().toIso8601String(),
    'sync_state': t.syncState.name,
  };

  @override
  Future<List<TaskModel>> getTasks() async {
    final rows = await _db.query(
      _table,
      where: 'sync_state != ?',
      whereArgs: [TaskSyncState.deleted.name],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<TaskModel?> getById(int id) async {
    final rows = await _db.query(_table, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<TaskModel> insert({
    required String title,
    required String content,
    required DateTime now,
  }) async {
    final task = TaskModel(
      id: 0,
      title: title,
      content: content,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      syncState: TaskSyncState.created,
    );
    final id = await _db.insert(_table, _toRow(task));
    return task.copyWith(id: id);
  }

  @override
  Future<TaskModel?> update({
    required int id,
    required String title,
    required String content,
    required bool isCompleted,
    required DateTime now,
  }) async {
    final current = await getById(id);
    if (current == null || current.syncState == TaskSyncState.deleted) {
      return null;
    }
    final updated = current.copyWith(
      title: title,
      content: content,
      isCompleted: isCompleted,
      updatedAt: now,
      syncState: current.syncState == TaskSyncState.created
          ? TaskSyncState.created
          : TaskSyncState.updated,
    );
    await _db.update(_table, _toRow(updated), where: 'id = ?', whereArgs: [id]);
    return updated;
  }

  @override
  Future<TaskModel?> delete(int id) async {
    final current = await getById(id);
    if (current == null) return null;
    if (current.remoteId == null) {
      await remove(id);
    } else {
      await _db.update(
        _table,
        {'sync_state': TaskSyncState.deleted.name},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return current;
  }

  @override
  Future<List<TaskModel>> getPending() async {
    final rows = await _db.query(
      _table,
      where: 'sync_state != ?',
      whereArgs: [TaskSyncState.synced.name],
      orderBy: 'id ASC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> markSynced(int id, TaskModel remote) async {
    await _db.update(
      _table,
      _toRow(remote.copyWith(syncState: TaskSyncState.synced)),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> remove(int id) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> replaceSynced(List<TaskModel> remote) async {
    await _db.transaction((txn) async {
      final remoteIds = remote.map((e) => e.remoteId).toSet();
      final rows = await txn.query(_table);
      final byRemote = <int, Map<String, Object?>>{
        for (final r in rows)
          if (r['remote_id'] != null) r['remote_id'] as int: r,
      };

      for (final r in rows) {
        final remoteId = r['remote_id'] as int?;
        final isSynced = r['sync_state'] == TaskSyncState.synced.name;
        if (isSynced && !remoteIds.contains(remoteId)) {
          await txn.delete(_table, where: 'id = ?', whereArgs: [r['id']]);
        }
      }

      for (final task in remote) {
        final existing = byRemote[task.remoteId];
        final row = _toRow(task.copyWith(syncState: TaskSyncState.synced));
        if (existing == null) {
          await txn.insert(_table, row);
        } else if (existing['sync_state'] == TaskSyncState.synced.name) {
          await txn.update(
            _table,
            row,
            where: 'id = ?',
            whereArgs: [existing['id']],
          );
        }
      }
    });
  }

  @override
  Future<void> clear() async {
    await _db.delete(_table);
  }
}
