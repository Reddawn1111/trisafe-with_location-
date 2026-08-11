import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// AdaptTripScreen — placeholder.
/// Route: /adapt/:tripId/:alertId
/// Purpose: Explain adaptation; confirm user wants to replan.
/// Source: docs/NAVIGATION_MAP.md § 3.9
class AdaptTripScreen extends StatelessWidget {
  const AdaptTripScreen({
    super.key,
    required this.tripId,
    required this.alertId,
  });

  final String tripId;
  final String alertId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      screenName: 'Adapt Trip',
      purpose: 'Explain and confirm adaptation for trip: $tripId',
    );
  }
}
