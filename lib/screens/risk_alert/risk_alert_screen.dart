import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// RiskAlertScreen — placeholder.
/// Route: /alert/:tripId/:alertId
/// Purpose: Show risk alert; recommend adaptation.
/// Source: docs/NAVIGATION_MAP.md § 3.8
class RiskAlertScreen extends StatelessWidget {
  const RiskAlertScreen({
    super.key,
    required this.tripId,
    required this.alertId,
  });

  final String tripId;
  final String alertId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      screenName: 'Risk Alert',
      purpose: 'Risk alert $alertId for trip: $tripId',
    );
  }
}
