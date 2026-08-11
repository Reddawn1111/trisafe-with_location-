import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripsafe/app/app.dart';

void main() {
  group('TripSafe foundation', () {
    testWidgets('app launches without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const TripSafeApp());
      await tester.pumpAndSettle();
      // App root widget is present
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('HomeScreen renders TripSafe title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const TripSafeApp());
      await tester.pumpAndSettle();
      expect(find.text('TripSafe'), findsWidgets);
    });

    testWidgets('HomeScreen shows Discover Destinations button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const TripSafeApp());
      await tester.pumpAndSettle();
      // Scroll down to bring button into view
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Discover Destinations'), findsOneWidget);
    });
  });
}
