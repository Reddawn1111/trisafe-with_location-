import 'package:flutter/material.dart';
import '../shared/placeholder_screen.dart';

/// ExpensesScreen — placeholder.
/// Route: /expenses/:tripId
/// Purpose: List/add/edit expenses.
/// Source: docs/NAVIGATION_MAP.md § 3.13
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      screenName: 'Expenses',
      purpose: 'Manage expenses for trip: $tripId',
    );
  }
}
