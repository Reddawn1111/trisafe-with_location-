import 'package:flutter_test/flutter_test.dart';
import 'package:tripsafe/models/place.dart';
import 'package:tripsafe/models/place_category.dart';
import 'package:tripsafe/services/recommendation_service.dart';

void main() {
  group('RecommendationService Engine Tests', () {
    final recommendationService = RecommendationService();
    const userLat = 11.2588;
    const userLon = 75.7804;

    test('High popularity with 4.7 rating beats 5.0 rating with 3 reviews', () {
      final placeA = Place(
        id: 'a',
        name: 'Obscure Cafe A',
        latitude: userLat + 0.005,
        longitude: userLon + 0.005,
        address: 'Street 1',
        category: PlaceCategory.cafe,
        rating: 5.0,
        reviewCount: 3,
      );

      final placeB = Place(
        id: 'b',
        name: 'Famous Heritage Bistro B',
        latitude: userLat + 0.006,
        longitude: userLon + 0.006,
        address: 'Street 2',
        category: PlaceCategory.cafe,
        rating: 4.7,
        reviewCount: 2000,
      );

      final ranked = recommendationService.rankPlaces(
        places: [placeA, placeB],
        userLatitude: userLat,
        userLongitude: userLon,
      );

      expect(ranked.first.id, equals('b'));
      expect(ranked.first.recommendationScore, greaterThan(ranked.last.recommendationScore));
    });

    test('Intent matching boosts matching categories', () {
      final photoSpot = Place(
        id: 'photo',
        name: 'Sunset Cliff Viewpoint',
        latitude: userLat + 0.01,
        longitude: userLon + 0.01,
        address: 'Cliff Rd',
        category: PlaceCategory.viewpoint,
        rating: 4.6,
        reviewCount: 500,
        types: ['scenic', 'viewpoint'],
      );

      final foodSpot = Place(
        id: 'food',
        name: 'Local Diner',
        latitude: userLat + 0.01,
        longitude: userLon + 0.01,
        address: 'Market St',
        category: PlaceCategory.food,
        rating: 4.6,
        reviewCount: 500,
        types: ['restaurant'],
      );

      final rankedForPhotos = recommendationService.rankPlaces(
        places: [foodSpot, photoSpot],
        userLatitude: userLat,
        userLongitude: userLon,
        selectedIntent: UserIntent.photos,
      );

      expect(rankedForPhotos.first.id, equals('photo'));
      expect(rankedForPhotos.first.recommendationReason, contains('📸'));

      final rankedForFood = recommendationService.rankPlaces(
        places: [foodSpot, photoSpot],
        userLatitude: userLat,
        userLongitude: userLon,
        selectedIntent: UserIntent.eat,
      );

      expect(rankedForFood.first.id, equals('food'));
    });
  });
}
