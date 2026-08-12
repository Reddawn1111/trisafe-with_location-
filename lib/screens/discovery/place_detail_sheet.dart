import 'package:flutter/material.dart';

import '../../models/place.dart';
import '../../services/itinerary_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/buttons.dart';

/// Bottom Sheet modal showing detailed information about a selected Place.
class PlaceDetailSheet extends StatefulWidget {
  final Place place;

  const PlaceDetailSheet({super.key, required this.place});

  static Future<void> show(BuildContext context, Place place) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaceDetailSheet(place: place),
    );
  }

  @override
  State<PlaceDetailSheet> createState() => _PlaceDetailSheetState();
}

class _PlaceDetailSheetState extends State<PlaceDetailSheet> {
  final _itineraryService = ItineraryService();
  late bool _isAdded;

  @override
  void initState() {
    super.initState();
    _isAdded = _itineraryService.isPlaceInItinerary(widget.place.id);
  }

  void _toggleItinerary() {
    if (_isAdded) {
      _itineraryService.removePlaceFromItinerary(widget.place.id);
      setState(() => _isAdded = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.place.name} removed from your itinerary.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      final success = _itineraryService.addPlaceToItinerary(widget.place);
      if (success) {
        setState(() => _isAdded = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.success,
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${widget.place.name} added to itinerary!'),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Image or Category Banner
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              height: 160,
              width: double.infinity,
              color: AppTheme.primary.withValues(alpha: 0.1),
              child: place.photoUrl != null
                  ? Image.network(
                      place.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderBanner(place),
                    )
                  : _buildPlaceholderBanner(place),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Name and Category Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  place.name,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${place.category.iconEmoji} ${place.category.displayName}',
                  style: AppTypography.caption.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // Rating, Review Count, Distance & Price Level
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    place.hasRating ? place.ratingLabel : 'Unavailable',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${place.reviewCountLabel})',
                    style: AppTypography.caption.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: AppTheme.secondary, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${place.distanceKm.toStringAsFixed(1)} km away',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
              if (place.priceDisplay.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    place.priceDisplay,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Recommendation Reason Box
          if (place.recommendationReason.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: AppTheme.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF00BFA6), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Why it is recommended:',
                          style: AppTypography.caption.copyWith(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          place.recommendationReason,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  place.address,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Relevant Tags / Types
          if (place.types.isNotEmpty) ...[
            Text(
              'Tags & Features',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: place.types.map((type) {
                final cleanedType = type.replaceAll('_', ' ');
                return Chip(
                  label: Text(cleanedType),
                  labelStyle: AppTypography.caption,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.all(0),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Action Buttons: Add to Itinerary & Open in Maps
          Row(
            children: [
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: _isAdded ? 'In Itinerary' : 'Add to Itinerary',
                  icon: _isAdded ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                  onPressed: _toggleItinerary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final mapsUrl =
                        'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening location: $mapsUrl'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions, size: 20),
                  label: const Text('Maps'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderBanner(Place place) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            place.category.iconData,
            size: 54,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            place.category.displayName,
            style: AppTypography.labelLarge.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
