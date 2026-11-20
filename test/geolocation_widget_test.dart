import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:waiting_room_app/geolocation_service.dart';
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

  testWidgets('shows captured client coordinates in the queue', (tester) async {
    await tester.pumpWidget(
      createWaitingRoomTestApp(geoService: FixedLocationService()),
    );
    await tester.enterText(find.byType(TextField), 'Sam');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.textContaining('37.7749, -122.4194'), findsOneWidget);
  });
}
