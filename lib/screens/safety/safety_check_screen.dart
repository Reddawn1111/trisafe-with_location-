import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// SafetyCheckScreen — placeholder.
/// Route: /safety/:tripId
/// Purpose: Initial safety evaluation before journey.
/// Source: docs/NAVIGATION_MAP.md § 3.6
class SafetyCheckScreen extends StatelessWidget {
  const SafetyCheckScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      screenName: 'Safety Check',
      purpose: 'Initial safety evaluation for trip: $tripId',
    );
  }
}
