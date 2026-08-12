import 'dart:math';
import '../models/place.dart';
import '../models/place_category.dart';

/// Recommendation Engine for TRIPSAFE "Explore Around Me".
/// Scores and ranks nearby places using transparent, deterministic criteria.
///
/// Weight Distribution:
/// - Rating:          30%
/// - Popularity:      25% (Logarithmic normalization)
/// - Distance:        20% (Closer is higher score)
/// - Interest Match:  20% (User intent preference)
/// - Price / Safety:   5% (Placeholder for safety score integration)
class RecommendationService {
  // Configurable Weight Constants (Sum = 1.0)
  static const double weightRating = 0.30;
  static const double weightPopularity = 0.25;
  static const double weightDistance = 0.20;
  static const double weightIntent = 0.20;
  static const double weightPriceSafety = 0.05;

  /// Haversine formula to compute geodesic distance between 2 coordinates in km.
  double computeDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * pi / 180.0;

  /// Ranks places based on current location and selected UserIntent chip.
  List<Place> rankPlaces({
    required List<Place> places,
    required double userLatitude,
    required double userLongitude,
    UserIntent selectedIntent = UserIntent.all,
    double searchRadiusKm = 5.0,
  }) {
    if (places.isEmpty) return [];

    // Filter out places beyond the search radius (mandatory distance validation).
    final withinRadius = places.where((place) {
      final distKm = computeDistanceKm(
        userLatitude,
        userLongitude,
        place.latitude,
        place.longitude,
      );
      return distKm <= searchRadiusKm;
    }).toList();

    if (withinRadius.isEmpty) return [];

    // When a specific intent is selected, keep only matching categories.
    final intentFiltered = selectedIntent == UserIntent.all
        ? withinRadius
        : withinRadius
            .where((place) => selectedIntent.matches(place.category, place.types))
            .toList();

    if (intentFiltered.isEmpty) return [];

    // Find max review count across places to normalize popularity logarithmically
    final maxReviews = intentFiltered.map((p) => p.reviewCount).reduce(max);

    final rankedList = intentFiltered.map((place) {
      final distKm = computeDistanceKm(
        userLatitude,
        userLongitude,
        place.latitude,
        place.longitude,
      );

      // 1. Rating Score (0 to 1)
      final ratingScore = (place.rating / 5.0).clamp(0.0, 1.0);

      // 2. Popularity Score (Logarithmic scaling so 20,000 reviews doesn't completely crush 2,000)
      final popularityScore = maxReviews == 0
          ? 0.0
          : (log(place.reviewCount + 1) / log(maxReviews + 1)).clamp(0.0, 1.0);

      // 3. Distance Score (0 to 1, closer is better)
      final distanceScore = max(0.0, 1.0 - (distKm / searchRadiusKm));

      // 4. Intent Match Score (0.3 to 1.0)
      final bool isMatch = selectedIntent.matches(place.category, place.types);
      final intentScore = isMatch ? 1.0 : 0.3;

      // 5. Price / Safety Score (Placeholder default 0.85)
      const priceSafetyScore = 0.85;

      final totalScore = (ratingScore * weightRating) +
          (popularityScore * weightPopularity) +
          (distanceScore * weightDistance) +
          (intentScore * weightIntent) +
          (priceSafetyScore * weightPriceSafety);

      // Generate explainable recommendation reason
      final reason = _generateRecommendationReason(
        place: place,
        distKm: distKm,
        isIntentMatch: isMatch,
        intent: selectedIntent,
      );

      return place.copyWith(
        distanceKm: distKm,
        recommendationScore: totalScore.clamp(0.0, 1.0),
        recommendationReason: reason,
      );
    }).toList();

    // Sort descending by recommendation score
    rankedList.sort((a, b) => b.recommendationScore.compareTo(a.recommendationScore));

    return rankedList;
  }

  /// Generates a human-readable, explainable reason for the recommendation.
  String _generateRecommendationReason({
    required Place place,
    required double distKm,
    required bool isIntentMatch,
    required UserIntent intent,
  }) {
    if (intent == UserIntent.photos &&
        (place.category == PlaceCategory.viewpoint || place.category == PlaceCategory.photography)) {
      return '📸 Great scenic photo spot';
    }

    if (intent == UserIntent.eat &&
        (place.category == PlaceCategory.food || place.category == PlaceCategory.cafe)) {
      return '🍴 Highly recommended dining nearby';
    }

    if (place.reviewCount > 1000) {
      final formattedCount = (place.reviewCount / 1000).toStringAsFixed(1);
      return '🔥 Popular nearby (${formattedCount}k reviews)';
    }

    if (place.rating >= 4.7 && place.hasRating) {
      return '⭐ Top rated ${place.rating.toStringAsFixed(1)} location';
    }

    if (distKm <= 1.0) {
      return '📍 Very close to you (${distKm.toStringAsFixed(1)} km)';
    }

    if (!place.hasRating && !place.hasReviews) {
      return '${place.category.iconEmoji} Recommended ${place.category.displayName} nearby';
    }

    return '${place.category.iconEmoji} Popular ${place.category.displayName}';
  }
}