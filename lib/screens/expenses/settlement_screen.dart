import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// SettlementScreen — placeholder.
/// Route: /settlement/:tripId
/// Purpose: Group balance summary.
/// Source: docs/NAVIGATION_MAP.md § 3.14
class SettlementScreen extends StatelessWidget {
  const SettlementScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      screenName: 'Settlement',
      purpose: 'Group balance summary for trip: $tripId',
    );
  }
}
