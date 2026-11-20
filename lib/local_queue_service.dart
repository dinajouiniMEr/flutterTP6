import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

/// Persistent local source of truth for waiting room clients.
class LocalQueueService {
  LocalQueueService({this.inMemory = false});

  static const tableName = 'local_clients';
  final bool inMemory;
  Database? _database;

  Future<Database> get database async => _database ??= await _openDatabase();

  Future<Database> _openDatabase() async {
    if (inMemory) {
      return openDatabase(
        inMemoryDatabasePath,
        version: 2,
        onCreate: _createSchema,
        onUpgrade: _upgradeSchema,
      );
    }
    if (kIsWeb) {
      return openDatabase(
        'waiting_room.db',
        version: 2,
        onCreate: _createSchema,
        onUpgrade: _upgradeSchema,
      );
    }
    final directory = await getApplicationDocumentsDirectory();
    return openDatabase(
      p.join(directory.path, 'waiting_room.db'),
      version: 2,
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        lat REAL,
        lng REAL,
        location_accuracy_m REAL,
        location_captured_at TEXT,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_deletions (
        id TEXT PRIMARY KEY NOT NULL
      )
    ''');
  }

  Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN location_accuracy_m REAL',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN location_captured_at TEXT',
      );
    }
  }

  Future<void> insertClientLocally(Map<String, Object?> client) async {
    await (await database).insert(
      tableName,
      client,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> getClients() async =>
      (await database).query(tableName, orderBy: 'created_at ASC');

  Future<List<Map<String, Object?>>> getUnsyncedClients() async =>
      (await database).query(tableName, where: 'is_synced = ?', whereArgs: [0]);

  Future<void> markClientAsSynced(String id) async {
    await (await database).update(
      tableName,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteClient(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('pending_deletions', {
        'id': id,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete(tableName, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> reconcileSyncedClients(Set<String> remoteIds) async {
    final db = await database;
    await db.transaction((txn) async {
      final synced = await txn.query(
        tableName,
        columns: ['id'],
        where: 'is_synced = ?',
        whereArgs: [1],
      );
      for (final row in synced) {
        final id = row['id'] as String;
        if (!remoteIds.contains(id)) {
          await txn.delete(tableName, where: 'id = ?', whereArgs: [id]);
        }
      }
    });
  }

  Future<List<String>> getPendingDeletions() async {
    final rows = await (await database).query('pending_deletions');
    return rows.map((row) => row['id'] as String).toList();
  }

  Future<bool> isDeletionPending(String id) async {
    final rows = await (await database).query(
      'pending_deletions',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> markDeletionAsSynced(String id) async {
    await (await database).delete(
      'pending_deletions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    await db?.close();
  }
}
