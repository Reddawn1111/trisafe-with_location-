import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// ActiveJourneyScreen — placeholder.
/// Route: /journey/:tripId
/// Purpose: Current day progress; hub for timeline, expenses, memories.
/// Source: docs/NAVIGATION_MAP.md § 3.7
class ActiveJourneyScreen extends StatelessWidget {
  const ActiveJourneyScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      screenName: 'Active Journey',
      purpose: 'Current day hub for trip: $tripId',
    );
  }
}
