import 'dart:math';
import 'package:your_app/models/restaurant.dart';

class RecommendationService {
  double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  List<Restaurant> rankRestaurants({
    required List<Restaurant> restaurants,
    required double userLatitude,
    required double userLongitude,
  }) {
    if (restaurants.isEmpty) {
      return [];
    }

    final maxReviews = restaurants
        .map((r) => r.reviewCount)
        .reduce(max);

    for (final restaurant in restaurants) {
      restaurant.distanceKm = _distanceKm(
        userLatitude,
        userLongitude,
        restaurant.latitude,
        restaurant.longitude,
      );

      // Rating: 0-1
      final ratingScore = restaurant.rating / 5.0;

      // Popularity: logarithmic so 10,000 reviews
      // doesn't completely destroy a restaurant with 2,000.
      final popularityScore = maxReviews == 0
          ? 0
          : log(restaurant.reviewCount + 1) /
              log(maxReviews + 1);

      // 0-1. Closer is better.
      final distanceScore =
          max(0.0, 1 - (restaurant.distanceKm / 5.0));

      restaurant.recommendationScore =
          (ratingScore * 0.45) +
          (popularityScore * 0.35) +
          (distanceScore * 0.20);
    }

    restaurants.sort(
      (a, b) => b.recommendationScore
          .compareTo(a.recommendationScore),
    );

    return restaurants;
  }
}