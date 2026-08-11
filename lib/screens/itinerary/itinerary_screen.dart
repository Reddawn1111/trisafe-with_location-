import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// ItineraryScreen — placeholder.
/// Route: /itinerary/:tripId
/// Purpose: Display generated day-by-day plan.
/// Source: docs/NAVIGATION_MAP.md § 3.5
class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      screenName: 'Itinerary',
      purpose: 'Day-by-day plan for trip: $tripId',
    );
  }
}
