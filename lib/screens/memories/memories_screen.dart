import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// MemoriesScreen — placeholder.
/// Route: /memories/:tripId
/// Purpose: List/add memories (photos, notes, etc.).
/// Source: docs/NAVIGATION_MAP.md § 3.15
class MemoriesScreen extends StatelessWidget {
  const MemoriesScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      screenName: 'Memories',
      purpose: 'Trip logbook — photos, notes, memories for trip: $tripId',
    );
  }
}
