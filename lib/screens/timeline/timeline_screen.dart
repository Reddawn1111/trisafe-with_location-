import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// TimelineScreen — placeholder.
/// Route: /timeline/:tripId
/// Purpose: Chronological trip events.
/// Source: docs/NAVIGATION_MAP.md § 3.12
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      screenName: 'Timeline',
      purpose: 'Chronological events for trip: $tripId',
    );
  }
}
