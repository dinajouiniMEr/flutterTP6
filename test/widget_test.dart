import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';

void main() {
  setUpAll(initializeTestDatabase);
  testWidgets('Waiting room screen renders and adds a client', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWaitingRoomTestApp());

    expect(find.text('Local Waiting Room'), findsOneWidget);
    expect(find.text('Clients in Queue: 0'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'John Doe');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Clients in Queue: 1'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
  });
}
