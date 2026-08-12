import 'package:geolocator/geolocator.dart';

import '../models/activity_insights.dart';
import '../models/place.dart';
import '../models/place_category.dart';

class VisitDetectionService {
  static const double associationRadiusMeters = 120;
  static const int minimumSamplesForVisit = 2;
  static final Duration minimumDwell = const Duration(minutes: 6);
  static final Duration duplicateWindow = const Duration(hours: 3);
  static final Duration recentSampleWindow = const Duration(hours: 2);

  ActivityEvent? detectVisitEvent({
    required LocationSample latestSample,
    required List<LocationSample> recentSamples,
    required List<ActivityEvent> existingEvents,
    required List<Place> nearbyPlaces,
    required bool consentGranted,
    required bool isDemoMode,
  }) {
    final place = _nearestCandidatePlace(
      latitude: latestSample.latitude,
      longitude: latestSample.longitude,
      places: nearbyPlaces,
    );

    if (place == null) {
      return null;
    }

    final cutoff = latestSample.timestamp.subtract(recentSampleWindow);
    final matchingSamples = recentSamples.where((sample) {
      if (sample.timestamp.isBefore(cutoff)) {
        return false;
      }

      final distance = Geolocator.distanceBetween(
        sample.latitude,
        sample.longitude,
        place.latitude,
        place.longitude,
      );
      return distance <= associationRadiusMeters;
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (matchingSamples.length < minimumSamplesForVisit) {
      return null;
    }

    final arrivalTime = matchingSamples.first.timestamp;
    final departureTime = matchingSamples.last.timestamp;
    final dwell = departureTime.difference(arrivalTime);
    if (dwell < minimumDwell) {
      return null;
    }

    final duplicateEvent = existingEvents.any((event) {
      if (event.placeId != place.id) {
        return false;
      }
      return latestSample.timestamp.difference(event.departureTime) <
          duplicateWindow;
    });

    if (duplicateEvent) {
      return null;
    }

    final confidence = _confidenceFor(
      sampleCount: matchingSamples.length,
      dwell: dwell,
    );

    return ActivityEvent(
      id: 'activity_${latestSample.timestamp.microsecondsSinceEpoch}',
      timestamp: latestSample.timestamp,
      latitude: latestSample.latitude,
      longitude: latestSample.longitude,
      placeId: place.id,
      placeName: place.name,
      placeCategory: place.category,
      activityType: _mapCategoryToActivityType(place.category),
      duration: dwell,
      confidence: confidence,
      source:
          isDemoMode ? ActivityEventSource.demo : ActivityEventSource.location,
      consentGranted: consentGranted,
      arrivalTime: arrivalTime,
      departureTime: departureTime,
    );
  }

  Place? _nearestCandidatePlace({
    required double latitude,
    required double longitude,
    required List<Place> places,
  }) {
    Place? nearest;
    double? nearestDistance;

    for (final place in places) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        place.latitude,
        place.longitude,
      );

      if (distance > associationRadiusMeters) {
        continue;
      }

      if (nearestDistance == null || distance < nearestDistance) {
        nearest = place;
        nearestDistance = distance;
      }
    }

    return nearest;
  }

  double _confidenceFor({
    required int sampleCount,
    required Duration dwell,
  }) {
    final sampleFactor = (sampleCount / 4).clamp(0.0, 1.0).toDouble();
    final dwellFactor = (dwell.inMinutes / 20).clamp(0.0, 1.0).toDouble();
    return ((sampleFactor * 0.45) + (dwellFactor * 0.55))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  ActivityType _mapCategoryToActivityType(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.food:
      case PlaceCategory.cafe:
        return ActivityType.eating;
      case PlaceCategory.shopping:
        return ActivityType.shopping;
      case PlaceCategory.attraction:
      case PlaceCategory.museum:
      case PlaceCategory.religious:
        return ActivityType.tourism;
      case PlaceCategory.park:
      case PlaceCategory.nature:
      case PlaceCategory.beach:
        return ActivityType.walking;
      case PlaceCategory.activity:
        return ActivityType.sports;
      case PlaceCategory.entertainment:
        return ActivityType.entertainment;
      case PlaceCategory.viewpoint:
      case PlaceCategory.photography:
        return ActivityType.photoSpot;
      case PlaceCategory.hotel:
        return ActivityType.rest;
      case PlaceCategory.other:
        return ActivityType.travel;
    }
  }
}
