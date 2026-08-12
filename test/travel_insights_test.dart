import 'package:flutter_test/flutter_test.dart';
import 'package:tripsafe/models/activity_insights.dart';
import 'package:tripsafe/models/place.dart';
import 'package:tripsafe/models/place_category.dart';
import 'package:tripsafe/services/activity_analytics_service.dart';
import 'package:tripsafe/services/visit_detection_service.dart';

void main() {
  group('Travel insights MVP', () {
    final visitDetectionService = VisitDetectionService();
    final place = Place(
      id: 'viewpoint_1',
      name: 'Sunset Viewpoint',
      latitude: 12.9718,
      longitude: 77.5946,
      address: 'Sunset Hill',
      category: PlaceCategory.viewpoint,
      rating: 4.8,
      reviewCount: 1200,
    );

    test('visit detection requires repeated nearby samples and dwell time', () {
      final start = DateTime(2026, 8, 12, 17, 0);
      final samples = <LocationSample>[
        LocationSample(
          timestamp: start,
          latitude: 12.97181,
          longitude: 77.59461,
        ),
        LocationSample(
          timestamp: start.add(const Duration(minutes: 8)),
          latitude: 12.97182,
          longitude: 77.59462,
        ),
      ];

      final event = visitDetectionService.detectVisitEvent(
        latestSample: samples.last,
        recentSamples: samples,
        existingEvents: const <ActivityEvent>[],
        nearbyPlaces: <Place>[place],
        consentGranted: true,
        isDemoMode: false,
      );

      expect(event, isNotNull);
      expect(event!.placeId, equals(place.id));
      expect(event.activityType, equals(ActivityType.photoSpot));
      expect(event.durationMinutes, greaterThanOrEqualTo(8));
      expect(event.confidence, greaterThan(0));
    });

    test('analytics summary builds engagement signals and crowd-safe snapshot', () {
      final analytics = ActivityAnalyticsService();
      final events = <ActivityEvent>[
        ActivityEvent(
          id: 'event_1',
          timestamp: DateTime(2026, 8, 12, 17, 8),
          latitude: 12.97182,
          longitude: 77.59462,
          placeId: place.id,
          placeName: place.name,
          placeCategory: place.category,
          activityType: ActivityType.photoSpot,
          duration: const Duration(minutes: 18),
          confidence: 0.8,
          source: ActivityEventSource.location,
          consentGranted: true,
          arrivalTime: DateTime(2026, 8, 12, 16, 50),
          departureTime: DateTime(2026, 8, 12, 17, 8),
        ),
      ];

      final signals = analytics.buildPlaceSignals(events);
      expect(signals[place.id], isNotNull);
      expect(signals[place.id]!.score, greaterThan(0.3));

      final summary = analytics.summarize(events);
      expect(summary.totalEvents, equals(1));
      expect(summary.busiestLocations.first, contains(place.name));

      final snapshot = analytics.buildAnonymousSnapshot(
        events,
        const TravelInsightsConsentState(
          anonymousAnalyticsEnabled: true,
        ),
      );
      expect(snapshot.headline, contains('consenting visit events'));
      expect(snapshot.disclaimer, contains('consenting users only'));
    });
  });
}
