import 'package:flutter/material.dart';
import '../../services/itinerary_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// ItineraryScreen — Displays the user's trip itinerary and saved places.
/// Route: /itinerary
class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key, this.tripId = ''});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final itineraryService = ItineraryService();

    return Scaffold(
      appBar: AppBar(
        title: Text(tripId.isNotEmpty ? 'Trip Itinerary ($tripId)' : 'My Trip Itinerary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              itineraryService.clearItinerary();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Itinerary cleared.')),
              );
            },
            tooltip: 'Clear Itinerary',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: itineraryService,
        builder: (context, _) {
          final items = itineraryService.items;

          if (items.isEmpty) {
            return EmptyState(
              message: 'Your itinerary is currently empty.\nExplore nearby places and add them to your trip!',
              icon: Icons.map_outlined,
              actionLabel: 'Explore Nearby Places',
              action: () => Navigator.of(context).pushNamed('/discover'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final place = item.place;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      child: Text(place.category.iconEmoji),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${place.category.displayName} · ⭐ ${place.rating.toStringAsFixed(1)}',
                            style: AppTypography.caption.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '📍 ${place.distanceKm.toStringAsFixed(1)} km away',
                            style: AppTypography.caption.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                      onPressed: () {
                        itineraryService.removePlaceFromItinerary(place.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          );
        },
      ),
    );
  }
}
