import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:waiting_room_app/geolocation_service.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/queue_provider.dart';
import 'test_support.dart';

class FixedLocationService implements GeolocationService {
  @override
  Future<Position?> getCurrentPosition() async => Position(
    longitude: -122.4194,
    latitude: 37.7749,
    timestamp: DateTime.utc(2025),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  setUpAll(initializeTestDatabase);

  test('starts empty, adds client and stores its coordinates', () async {
    final local = LocalQueueService(inMemory: true);
    final provider = QueueProvider(
      useSupabase: false,
      localService: local,
      geoService: FixedLocationService(),
    );
    addTearDown(provider.dispose);

    await provider.initialize();
    expect(provider.clients, isEmpty);
    await provider.addClient('Sam');

    expect(provider.clients.single.name, 'Sam');
    expect(provider.clients.single.latitude, 37.7749);
    expect(provider.clients.single.longitude, -122.4194);
    expect((await local.getUnsyncedClients()), hasLength(1));
  });

  test('notifies listeners and removes next client safely', () async {
    final local = LocalQueueService(inMemory: true);
    final provider = QueueProvider(
      useSupabase: false,
      localService: local,
      geoService: NoLocationService(),
    );
    addTearDown(provider.dispose);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.initialize();
    await provider.addClient('First');
    await provider.addClient('Second');
    await provider.nextClient();
    await provider.nextClient();
    await provider.nextClient();

    expect(provider.clients, isEmpty);
    expect(await local.getPendingDeletions(), hasLength(2));
    expect(notifications, greaterThanOrEqualTo(4));
  });
}
