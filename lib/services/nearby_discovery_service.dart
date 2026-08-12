import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place.dart';
import '../models/place_category.dart';
import 'places_config.dart';

/// Abstract service interface for nearby place discovery.
/// Enables pluggable providers (Google Places API, Mock data, custom backend).
abstract class NearbyDiscoveryService {
  Future<List<Place>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusMeters = PlacesConfig.defaultRadiusMeters,
    List<String>? includedTypes,
  });
}

/// Production Google Places API (New) Provider implementation.
class GooglePlacesNearbyService implements NearbyDiscoveryService {
  final String apiKey;
  final http.Client _client;

  GooglePlacesNearbyService({
    String? apiKey,
    http.Client? client,
  })  : apiKey = apiKey ?? PlacesConfig.googlePlacesApiKey,
        _client = client ?? http.Client();

  @override
  Future<List<Place>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusMeters = PlacesConfig.defaultRadiusMeters,
    List<String>? includedTypes,
  }) async {
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY') {
      // Fallback to Mock service if no API key configured
      return MockNearbyDiscoveryService().getNearbyPlaces(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );
    }

    final url = Uri.parse('https://places.googleapis.com/v1/places:searchNearby');

    final bodyMap = <String, dynamic>{
      'maxResultCount': PlacesConfig.maxResultCount,
      'rankPreference': 'POPULARITY',
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': radiusMeters,
        },
      },
    };

    if (includedTypes != null && includedTypes.isNotEmpty) {
      bodyMap['includedTypes'] = includedTypes;
    }

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': PlacesConfig.googlePlacesFieldMask,
        },
        body: jsonEncode(bodyMap),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        // Fallback gracefully on API errors (e.g. quota, key restriction)
        return MockNearbyDiscoveryService().getNearbyPlaces(
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radiusMeters,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawPlaces = data['places'] as List<dynamic>? ?? [];

      return rawPlaces
          .map((p) => Place.fromGooglePlacesJson(p as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Return mock fallback on network exception
      return MockNearbyDiscoveryService().getNearbyPlaces(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );
    }
  }
}

/// Fallback / Demo Mock Provider.
/// Generates realistic multi-category POIs relative to user's location.
class MockNearbyDiscoveryService implements NearbyDiscoveryService {
  @override
  Future<List<Place>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusMeters = PlacesConfig.defaultRadiusMeters,
    List<String>? includedTypes,
  }) async {
    // Artificial latency for smooth UI loading state demonstration
    await Future.delayed(const Duration(milliseconds: 600));

    final places = [
      Place(
        id: 'place_1',
        name: 'Kappad Coastal Beach & Walkway',
        latitude: latitude + 0.012,
        longitude: longitude + 0.015,
        address: 'Beach Rd, Coastal Promenade',
        category: PlaceCategory.beach,
        rating: 4.8,
        reviewCount: 2450,
        priceLevel: 'FREE',
        types: ['beach', 'tourist_attraction', 'scenic'],
        photoUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
        metadata: {'sunset_view': true, 'crowd': 'Moderate'},
      ),
      Place(
        id: 'place_2',
        name: 'Ocean Peak Sunset Viewpoint',
        latitude: latitude + 0.008,
        longitude: longitude - 0.010,
        address: 'Cliff View Road, Hillside District',
        category: PlaceCategory.viewpoint,
        rating: 4.9,
        reviewCount: 1820,
        priceLevel: 'FREE',
        types: ['viewpoint', 'scenic', 'park'],
        photoUrl: 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800',
        metadata: {'photo_spot': true, 'best_time': '5:30 PM'},
      ),
      Place(
        id: 'place_3',
        name: 'The Heritage Seaside Cafe',
        latitude: latitude - 0.004,
        longitude: longitude + 0.006,
        address: '14 Fort Promenade, Old Town',
        category: PlaceCategory.cafe,
        rating: 4.7,
        reviewCount: 1290,
        priceLevel: 'MODERATE',
        types: ['cafe', 'food', 'bakery'],
        photoUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800',
      ),
      Place(
        id: 'place_4',
        name: 'Maritime History Museum',
        latitude: latitude - 0.009,
        longitude: longitude - 0.005,
        address: '88 Lighthouse Street, Cultural Quarter',
        category: PlaceCategory.museum,
        rating: 4.6,
        reviewCount: 840,
        priceLevel: 'INEXPENSIVE',
        types: ['museum', 'tourist_attraction', 'cultural'],
        photoUrl: 'https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?w=800',
      ),
      Place(
        id: 'place_5',
        name: 'Botanical Sanctuary & Pine Trails',
        latitude: latitude + 0.018,
        longitude: longitude - 0.012,
        address: 'Green Valley Reserve, North Entrance',
        category: PlaceCategory.nature,
        rating: 4.7,
        reviewCount: 950,
        priceLevel: 'FREE',
        types: ['park', 'hiking', 'natural_feature'],
        photoUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=800',
      ),
      Place(
        id: 'place_6',
        name: 'Spice & Artisan Craft Bazaar',
        latitude: latitude + 0.003,
        longitude: longitude - 0.008,
        address: 'Main Market Square, Heritage Row',
        category: PlaceCategory.shopping,
        rating: 4.5,
        reviewCount: 3100,
        priceLevel: 'MODERATE',
        types: ['shopping', 'market', 'store'],
        photoUrl: 'https://images.unsplash.com/photo-1533900298318-6b8da08a523e?w=800',
      ),
      Place(
        id: 'place_7',
        name: 'Coastal Seafood Grill & Bistro',
        latitude: latitude - 0.006,
        longitude: longitude + 0.011,
        address: '22 Marine Drive, Pier District',
        category: PlaceCategory.food,
        rating: 4.6,
        reviewCount: 1650,
        priceLevel: 'EXPENSIVE',
        types: ['restaurant', 'food'],
        photoUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
      ),
      Place(
        id: 'place_8',
        name: 'Lighthouse Rock Photo Spot',
        latitude: latitude + 0.014,
        longitude: longitude + 0.018,
        address: 'Cape Point Trail, South Reef',
        category: PlaceCategory.photography,
        rating: 4.8,
        reviewCount: 760,
        priceLevel: 'FREE',
        types: ['scenic', 'tourist_attraction', 'viewpoint'],
        photoUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
      ),
      Place(
        id: 'place_9',
        name: 'Adventure Kayak & Water Sports',
        latitude: latitude + 0.010,
        longitude: longitude + 0.020,
        address: 'Lagoon Bay Water Center',
        category: PlaceCategory.activity,
        rating: 4.9,
        reviewCount: 520,
        priceLevel: 'EXPENSIVE',
        types: ['activity', 'amusement', 'sports'],
        photoUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800',
      ),
      Place(
        id: 'place_10',
        name: 'Sunset Ampitheatre & Live Arena',
        latitude: latitude - 0.011,
        longitude: longitude + 0.004,
        address: 'Bayfront Park Pavilion',
        category: PlaceCategory.entertainment,
        rating: 4.4,
        reviewCount: 410,
        priceLevel: 'MODERATE',
        types: ['entertainment', 'amusement'],
        photoUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800',
      ),
    ];

    return places;
  }
}
