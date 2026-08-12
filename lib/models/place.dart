import 'place_category.dart';

/// Generic model representing a nearby Point of Interest / Place.
/// Supports multi-category discovery (restaurants, beaches, viewpoints, attractions, etc.)
class Place {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final PlaceCategory category;
  final double rating;
  final int reviewCount;
  final String? priceLevel; // e.g. PRICE_LEVEL_INEXPENSIVE, $$, etc.
  final List<String> types;
  final String? photoUrl;
  final String? photoReference;
  final Map<String, dynamic>? metadata;

  // Dynamic ranking variables calculated by RecommendationService
  double distanceKm;
  double recommendationScore;
  String recommendationReason;

  Place({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.category,
    required this.rating,
    required this.reviewCount,
    this.priceLevel,
    this.types = const [],
    this.photoUrl,
    this.photoReference,
    this.metadata,
    this.distanceKm = 0.0,
    this.recommendationScore = 0.0,
    this.recommendationReason = '',
  });

  bool get hasRating => rating > 0;
  bool get hasReviews => reviewCount > 0;

  String get ratingLabel =>
      hasRating ? rating.toStringAsFixed(1) : 'Unavailable';

  String get reviewCountLabel {
    if (!hasReviews) return 'Reviews unavailable';
    return '$reviewCount reviews';
  }

  /// Price display string (e.g. $, $$, $$$)
  String get priceDisplay {
    if (priceLevel == null || priceLevel!.isEmpty) return '';
    if (priceLevel!.contains('FREE')) return 'Free';
    if (priceLevel!.contains('INEXPENSIVE') || priceLevel == '1') return '\$';
    if (priceLevel!.contains('MODERATE') || priceLevel == '2') return '\$\$';
    if (priceLevel!.contains('EXPENSIVE') || priceLevel == '3') return '\$\$\$';
    if (priceLevel!.contains('VERY_EXPENSIVE') || priceLevel == '4') return '\$\$\$\$';
    return priceLevel!;
  }

  /// Create a Place instance from a Geoapify Places API GeoJSON feature.
  factory Place.fromGeoapifyFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
    final coordinates = geometry['coordinates'] as List<dynamic>? ?? [];
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};

    final categories = (properties['categories'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final longitude = (properties['lon'] as num?)?.toDouble() ??
        (coordinates.isNotEmpty ? (coordinates[0] as num).toDouble() : 0.0);
    final latitude = (properties['lat'] as num?)?.toDouble() ??
        (coordinates.length > 1 ? (coordinates[1] as num).toDouble() : 0.0);

    final address = properties['formatted']?.toString() ??
        properties['address_line1']?.toString() ??
        'Address unavailable';

    final name = properties['name']?.toString();
    final displayName = (name != null && name.isNotEmpty) ? name : address;

    String? priceLevel;
    if (categories.any((c) => c.contains('no_fee'))) {
      priceLevel = 'FREE';
    }

    return Place(
      id: properties['place_id']?.toString() ?? '',
      name: displayName,
      latitude: latitude,
      longitude: longitude,
      address: address,
      category: PlaceCategory.primaryFromGeoapifyCategories(categories),
      rating: 0.0,
      reviewCount: 0,
      priceLevel: priceLevel,
      types: categories,
      photoUrl: null,
      photoReference: null,
    );
  }

  /// Copy with updated scores
  Place copyWith({
    double? distanceKm,
    double? recommendationScore,
    String? recommendationReason,
  }) {
    return Place(
      id: id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      address: address,
      category: category,
      rating: rating,
      reviewCount: reviewCount,
      priceLevel: priceLevel,
      types: types,
      photoUrl: photoUrl,
      photoReference: photoReference,
      metadata: metadata,
      distanceKm: distanceKm ?? this.distanceKm,
      recommendationScore: recommendationScore ?? this.recommendationScore,
      recommendationReason: recommendationReason ?? this.recommendationReason,
    );
  }
}
