import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';

void main() {
  setUpAll(initializeTestDatabase);
  testWidgets('should add a new client to the list on button tap', (
    WidgetTester tester,
  ) async {
    // ARRANGE
    await tester.pumpWidget(createWaitingRoomTestApp());
    // ACT
    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle(); // Wait for the local SQLite write.
    // ASSERT
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Clients in Queue: 1'), findsOneWidget);
  });

  testWidgets(
    'should remove a client from the list when the delete button is tapped',
    (WidgetTester tester) async {
      // ARRANGE
      await tester.pumpWidget(createWaitingRoomTestApp());
      await tester.enterText(find.byType(TextField), 'Bob');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      // ACT
      // Find the remove button associated with 'Bob' and tap it.
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      // ASSERT
      expect(find.text('Bob'), findsNothing);
      expect(find.text('Clients in Queue: 0'), findsOneWidget);
    },
  );
}
