import 'package:geolocator/geolocator.dart';

import '../models/activity_insights.dart';
import '../models/place.dart';
import '../repositories/activity_repository.dart';
import 'activity_analytics_service.dart';
import 'visit_detection_service.dart';

class TravelInsightsService {
  TravelInsightsService._internal({
    ActivityRepository? repository,
    VisitDetectionService? visitDetectionService,
    ActivityAnalyticsService? analyticsService,
  })  : _repository = repository ?? LocalJsonActivityRepository.instance,
        _visitDetectionService =
            visitDetectionService ?? VisitDetectionService(),
        _analyticsService = analyticsService ?? const ActivityAnalyticsService();

  static final TravelInsightsService instance = TravelInsightsService._internal();

  factory TravelInsightsService() => instance;

  final ActivityRepository _repository;
  final VisitDetectionService _visitDetectionService;
  final ActivityAnalyticsService _analyticsService;

  Future<TravelInsightsConsentState> getConsentState() {
    return _repository.loadConsentState();
  }

  Future<void> updateConsentState(TravelInsightsConsentState state) {
    return _repository.saveConsentState(state);
  }

  Future<List<ActivityEvent>> getActivityEvents() {
    return _repository.loadActivityEvents();
  }

  Future<TravelInsightsSummary> getSummary() async {
    final events = await _repository.loadActivityEvents();
    return _analyticsService.summarize(events);
  }

  Future<AnonymousAnalyticsSnapshot> getAnonymousSnapshot() async {
    final consent = await _repository.loadConsentState();
    final events = await _repository.loadActivityEvents();
    return _analyticsService.buildAnonymousSnapshot(events, consent);
  }

  Future<Map<String, PlaceEngagementSignal>> getPlaceSignals() async {
    final consent = await _repository.loadConsentState();
    if (!consent.locationInsightsEnabled || consent.trackingPaused) {
      return const <String, PlaceEngagementSignal>{};
    }

    final events = await _repository.loadActivityEvents();
    return _analyticsService.buildPlaceSignals(events);
  }

  Future<void> recordLocationObservation({
    required Position position,
    required List<Place> nearbyPlaces,
    required bool isDemoMode,
    DateTime? timestamp,
  }) async {
    final consent = await _repository.loadConsentState();
    if (!consent.canCaptureLocationInsights) {
      return;
    }

    final sample = LocationSample(
      timestamp: timestamp ?? DateTime.now(),
      latitude: position.latitude,
      longitude: position.longitude,
    );

    await _repository.appendLocationSample(sample);
    final samples = await _repository.loadLocationSamples();
    final events = await _repository.loadActivityEvents();

    final event = _visitDetectionService.detectVisitEvent(
      latestSample: sample,
      recentSamples: samples,
      existingEvents: events,
      nearbyPlaces: nearbyPlaces,
      consentGranted: true,
      isDemoMode: isDemoMode,
    );

    if (event != null) {
      await _repository.appendActivityEvent(event);
    }
  }

  Future<void> setTrackingPaused(bool paused) async {
    final consent = await _repository.loadConsentState();
    await _repository.saveConsentState(
      consent.copyWith(trackingPaused: paused),
    );
  }

  Future<void> clearActivityData() {
    return _repository.clearActivityData();
  }

  Future<void> clearConsentState() async {
    await _repository.clearConsentState();
  }

  Future<String> exportData() async {
    final store = await _repository.exportStore();
    return prettyPrintJson(store);
  }
}
