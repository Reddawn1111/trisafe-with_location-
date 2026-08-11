import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// AlternativeDestinationScreen — placeholder.
/// Route: /alternatives/:tripId/:alertId
/// Purpose: List ranked alternative destinations.
/// Source: docs/NAVIGATION_MAP.md § 3.10
class AlternativeDestinationScreen extends StatelessWidget {
  const AlternativeDestinationScreen({
    super.key,
    required this.tripId,
    required this.alertId,
  });

  final String tripId;
  final String alertId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      screenName: 'Alternative Destinations',
      purpose: 'Ranked alternatives for trip: $tripId',
    );
  }
}
