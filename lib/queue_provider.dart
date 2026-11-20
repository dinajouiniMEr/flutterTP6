import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:waiting_room_app/geolocation_service.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/models/client.dart';

class QueueProvider extends ChangeNotifier {
  QueueProvider({
    required this.useSupabase,
    LocalQueueService? localService,
    GeolocationService? geoService,
    SupabaseClient? supabaseClient,
    Uuid? uuid,
  }) : _localDb = localService ?? LocalQueueService(),
       _geoService = geoService ?? GeolocationService(),
       _supabase = supabaseClient,
       _uuid = uuid ?? const Uuid();

  final bool useSupabase;
  final LocalQueueService _localDb;
  final GeolocationService _geoService;
  final SupabaseClient? _supabase;
  final Uuid _uuid;
  final List<Client> _clients = [];
  RealtimeChannel? _channel;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<void>? _initialization;

  List<Client> get clients => List.unmodifiable(_clients);

  SupabaseClient get _client => _supabase ?? Supabase.instance.client;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    await _refreshFromLocal();
    if (!useSupabase) return;

    unawaited(syncPendingClients());
    unawaited(_loadRemoteClients());
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      _,
    ) {
      unawaited(syncPendingClients());
    });
    try {
      _channel = _client
          .channel('public:clients')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'clients',
            callback: (_) => unawaited(_loadRemoteClients()),
          )
          .subscribe();
    } catch (error) {
      debugPrint('Realtime subscription unavailable: $error');
    }
  }

  Future<void> _refreshFromLocal() async {
    final rows = await _localDb.getClients();
    _clients
      ..clear()
      ..addAll(rows.map((row) => Client.fromMap(row)));
    notifyListeners();
  }

  Future<void> _loadRemoteClients() async {
    try {
      final rows = await _client.from('clients').select().order('created_at');
      final remoteIds = <String>{};
      for (final raw in rows) {
        final remote = Map<String, dynamic>.from(raw);
        final id = (remote['client_uuid'] ?? remote['id']).toString();
        remoteIds.add(id);
        if (await _localDb.isDeletionPending(id)) continue;
        remote['id'] = id;
        remote.remove('client_uuid');
        remote['is_synced'] = 1;
        await _localDb.insertClientLocally(remote);
      }
      await _localDb.reconcileSyncedClients(remoteIds);
      await _refreshFromLocal();
    } catch (error) {
      debugPrint('Remote queue refresh failed: $error');
    }
  }

  Future<void> addClient(String name) async {
    await initialize();
    final clientName = name.trim();
    if (clientName.isEmpty) return;

    Position? position;
    try {
      position = await _geoService.getCurrentPosition();
    } catch (_) {
      // A location failure must not prevent adding the client.
    }
    final client = Client(
      id: _uuid.v4(),
      name: clientName,
      createdAt: DateTime.now().toUtc(),
      latitude: position?.latitude,
      longitude: position?.longitude,
      locationAccuracy: position?.accuracy,
      locationCapturedAt: position?.timestamp,
    );
    await _localDb.insertClientLocally(client.toMap());
    _clients.add(client);
    _clients.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();

    if (useSupabase) unawaited(syncPendingClients());
  }

  Future<void> syncPendingClients() async {
    if (!useSupabase) return;
    try {
      for (final id in await _localDb.getPendingDeletions()) {
        try {
          await _client.from('clients').delete().eq('client_uuid', id);
          await _localDb.markDeletionAsSynced(id);
        } catch (error) {
          debugPrint('Sync failed for client removal $id: $error');
        }
      }
      final pending = await _localDb.getUnsyncedClients();
      for (final row in pending) {
        final local = Map<String, dynamic>.from(row)..remove('is_synced');
        final client = {
          'client_uuid': local.remove('id'),
          'name': local['name'],
          'lat': local['lat'],
          'lng': local['lng'],
          'location_accuracy_m': local['location_accuracy_m'],
          'location_captured_at': local['location_captured_at'],
          'created_at': local['created_at'],
        };
        try {
          await _client
              .from('clients')
              .upsert(client, onConflict: 'client_uuid');
          await _localDb.markClientAsSynced(row['id'] as String);
        } catch (error) {
          // Keep this row pending and continue; a later initialization/add retries it.
          debugPrint('Sync failed for ${row['id']}: $error');
        }
      }
    } catch (error) {
      debugPrint('Unable to read pending queue updates: $error');
    }
  }

  Future<void> removeClient(String id) async {
    await initialize();
    final index = _clients.indexWhere((client) => client.id == id);
    if (index < 0) return;
    await _localDb.deleteClient(id);
    _clients.removeAt(index);
    notifyListeners();
    if (useSupabase) {
      try {
        await _client.from('clients').delete().eq('client_uuid', id);
        await _localDb.markDeletionAsSynced(id);
      } catch (error) {
        debugPrint('Remote client removal failed: $error');
      }
    }
  }

  Future<void> removeClientAt(int index) async {
    if (index < 0 || index >= _clients.length) return;
    await removeClient(_clients[index].id);
  }

  Future<void> nextClient() async {
    if (_clients.isNotEmpty) await removeClient(_clients.first.id);
  }

  @override
  void dispose() {
    final channel = _channel;
    unawaited(_connectivitySubscription?.cancel());
    if (channel != null) unawaited(_removeChannel(channel));
    unawaited(_localDb.close());
    super.dispose();
  }

  Future<void> _removeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
