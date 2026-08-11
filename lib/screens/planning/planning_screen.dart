import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// PlanningScreen — placeholder.
/// Route: /plan/:destinationId
/// Purpose: Collect TripPreferences; create trip.
/// Source: docs/NAVIGATION_MAP.md § 3.4
class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key, required this.destinationId});

  final String destinationId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      screenName: 'Trip Planning',
      purpose: 'Collect trip preferences for destination: $destinationId',
    );
  }
}
