import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// UpdatedItineraryScreen — placeholder.
/// Route: /itinerary/:tripId/updated
/// Purpose: Show regenerated itinerary after safety adaptation.
/// Source: docs/NAVIGATION_MAP.md § 3.11
class UpdatedItineraryScreen extends StatelessWidget {
  const UpdatedItineraryScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      screenName: 'Updated Itinerary',
      purpose: 'Regenerated plan after adaptation for trip: $tripId',
    );
  }
}
