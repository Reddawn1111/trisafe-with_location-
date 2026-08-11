import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// TripSummaryScreen — placeholder.
/// Route: /summary/:tripId
/// Purpose: End-of-trip recap.
/// Source: docs/NAVIGATION_MAP.md § 3.16
class TripSummaryScreen extends StatelessWidget {
  const TripSummaryScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      screenName: 'Trip Summary',
      purpose: 'End-of-trip recap for trip: $tripId',
    );
  }
}
