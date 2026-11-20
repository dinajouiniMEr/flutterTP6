import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/geolocation_service.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/main.dart';

void initializeTestDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

class NoLocationService implements GeolocationService {
  @override
  Future<Position?> getCurrentPosition() async => null;
}

class MemoryQueueService extends LocalQueueService {
  MemoryQueueService() : super(inMemory: true);

  final Map<String, Map<String, Object?>> _rows = {};
  final Set<String> _pendingDeletes = {};

  @override
  Future<List<Map<String, Object?>>> getClients() async =>
      _rows.values.map((row) => Map<String, Object?>.from(row)).toList()..sort(
        (a, b) =>
            (a['created_at'] as String).compareTo(b['created_at'] as String),
      );

  @override
  Future<List<Map<String, Object?>>> getUnsyncedClients() async => _rows.values
      .where((row) => row['is_synced'] == 0)
      .map((row) => Map<String, Object?>.from(row))
      .toList();

  @override
  Future<void> insertClientLocally(Map<String, Object?> client) async {
    _rows[client['id']! as String] = Map<String, Object?>.from(client);
  }

  @override
  Future<void> markClientAsSynced(String id) async {
    _rows[id]?['is_synced'] = 1;
  }

  @override
  Future<void> deleteClient(String id) async {
    _pendingDeletes.add(id);
    _rows.remove(id);
  }

  @override
  Future<List<String>> getPendingDeletions() async => _pendingDeletes.toList();

  @override
  Future<bool> isDeletionPending(String id) async =>
      _pendingDeletes.contains(id);

  @override
  Future<void> markDeletionAsSynced(String id) async {
    _pendingDeletes.remove(id);
  }

  @override
  Future<void> close() async {}
}

Widget createWaitingRoomTestApp({GeolocationService? geoService}) =>
    WaitingRoomApp(
      localQueueService: MemoryQueueService(),
      geoService: geoService ?? NoLocationService(),
    );
