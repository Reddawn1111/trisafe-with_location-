import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// DiscoveryScreen — placeholder.
/// Route: /discover
/// Purpose: Browse/search destinations.
/// Source: docs/NAVIGATION_MAP.md § 3.2
class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      screenName: 'Discovery',
      purpose: 'Browse and search destinations.',
    );
  }
}
