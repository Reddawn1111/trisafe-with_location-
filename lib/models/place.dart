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

  /// Create a Place instance from Google Places API (New) JSON node.
  factory Place.fromGooglePlacesJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final displayName = json['displayName'] as Map<String, dynamic>? ?? {};
    final typesList = (json['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    
    // Determine main category from types
    PlaceCategory primaryCategory = PlaceCategory.other;
    for (final t in typesList) {
      final cat = PlaceCategory.fromGoogleType(t);
      if (cat != PlaceCategory.other) {
        primaryCategory = cat;
        break;
      }
    }

    // Photo reference if present
    String? photoRef;
    final photos = json['photos'] as List<dynamic>?;
    if (photos != null && photos.isNotEmpty) {
      photoRef = photos[0]['name']?.toString();
    }

    return Place(
      id: json['id']?.toString() ?? '',
      name: displayName['text']?.toString() ?? json['name']?.toString() ?? 'Nearby Attraction',
      latitude: (location['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (location['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['formattedAddress']?.toString() ?? 'Address unavailable',
      category: primaryCategory,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['userRatingCount'] as num?)?.toInt() ?? 0,
      priceLevel: json['priceLevel']?.toString(),
      types: typesList,
      photoReference: photoRef,
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
