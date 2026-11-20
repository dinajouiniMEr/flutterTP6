import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'test_support.dart';

void main() {
  setUpAll(initializeTestDatabase);

  test('insertClientLocally persists a client that is pending sync', () async {
    final service = LocalQueueService(inMemory: true);
    addTearDown(service.close);

    await service.insertClientLocally({
      'id': 'test-123',
      'name': 'Alice',
      'lat': 40.71,
      'lng': -74.00,
      'created_at': '2024-01-01T00:00:00Z',
      'is_synced': 0,
    });

    final clients = await service.getUnsyncedClients();
    expect(clients, hasLength(1));
    expect(clients.single['name'], 'Alice');
  });

  test('markClientAsSynced removes a client from the pending list', () async {
    final service = LocalQueueService(inMemory: true);
    addTearDown(service.close);
    await service.insertClientLocally({
      'id': 'test-456',
      'name': 'Bob',
      'created_at': '2024-01-01T00:00:00Z',
      'is_synced': 0,
    });

    await service.markClientAsSynced('test-456');

    expect(await service.getUnsyncedClients(), isEmpty);
  });
}
