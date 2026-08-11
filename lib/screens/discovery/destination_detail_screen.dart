import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// DestinationDetailScreen — placeholder.
/// Route: /discover/:destinationId
/// Purpose: Destination info, safety baseline, pricing hint.
/// Source: docs/NAVIGATION_MAP.md § 3.3
class DestinationDetailScreen extends StatelessWidget {
  const DestinationDetailScreen({super.key, required this.destinationId});

  final String destinationId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      screenName: 'Destination Detail',
      purpose: 'Destination info for: $destinationId',
    );
  }
}
