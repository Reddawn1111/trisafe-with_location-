import 'dart:convert';

import 'place_category.dart';

enum ActivityType {
  travel,
  eating,
  shopping,
  tourism,
  walking,
  sports,
  entertainment,
  rest,
  photoSpot,
  unknown;

  String get label {
    switch (this) {
      case ActivityType.travel:
        return 'Travel';
      case ActivityType.eating:
        return 'Eating';
      case ActivityType.shopping:
        return 'Shopping';
      case ActivityType.tourism:
        return 'Tourism';
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.sports:
        return 'Sports';
      case ActivityType.entertainment:
        return 'Entertainment';
      case ActivityType.rest:
        return 'Rest';
      case ActivityType.photoSpot:
        return 'Photo Spot';
      case ActivityType.unknown:
        return 'Unknown';
    }
  }
}

enum ActivityEventSource {
  location,
  deviceUsage,
  cameraUsage,
  mediaUsage,
  demo;

  String get label {
    switch (this) {
      case ActivityEventSource.location:
        return 'Location';
      case ActivityEventSource.deviceUsage:
        return 'Device usage';
      case ActivityEventSource.cameraUsage:
        return 'Camera usage';
      case ActivityEventSource.mediaUsage:
        return 'Media usage';
      case ActivityEventSource.demo:
        return 'Demo';
    }
  }
}

enum DeviceCapabilityStatus {
  available,
  unavailable,
  notSupported;

  String get label {
    switch (this) {
      case DeviceCapabilityStatus.available:
        return 'Available';
      case DeviceCapabilityStatus.unavailable:
        return 'Unavailable';
      case DeviceCapabilityStatus.notSupported:
        return 'Not supported';
    }
  }
}

class TravelInsightsConsentState {
  final bool locationInsightsEnabled;
  final bool backgroundLocationEnabled;
  final bool appUsageInsightsEnabled;
  final bool cameraActivityInsightsEnabled;
  final bool mediaActivityInsightsEnabled;
  final bool anonymousAnalyticsEnabled;
  final bool trackingPaused;

  const TravelInsightsConsentState({
    this.locationInsightsEnabled = false,
    this.backgroundLocationEnabled = false,
    this.appUsageInsightsEnabled = false,
    this.cameraActivityInsightsEnabled = false,
    this.mediaActivityInsightsEnabled = false,
    this.anonymousAnalyticsEnabled = false,
    this.trackingPaused = false,
  });

  bool get canCaptureLocationInsights =>
      locationInsightsEnabled && !trackingPaused;

  TravelInsightsConsentState copyWith({
    bool? locationInsightsEnabled,
    bool? backgroundLocationEnabled,
    bool? appUsageInsightsEnabled,
    bool? cameraActivityInsightsEnabled,
    bool? mediaActivityInsightsEnabled,
    bool? anonymousAnalyticsEnabled,
    bool? trackingPaused,
  }) {
    return TravelInsightsConsentState(
      locationInsightsEnabled:
          locationInsightsEnabled ?? this.locationInsightsEnabled,
      backgroundLocationEnabled:
          backgroundLocationEnabled ?? this.backgroundLocationEnabled,
      appUsageInsightsEnabled:
          appUsageInsightsEnabled ?? this.appUsageInsightsEnabled,
      cameraActivityInsightsEnabled: cameraActivityInsightsEnabled ??
          this.cameraActivityInsightsEnabled,
      mediaActivityInsightsEnabled:
          mediaActivityInsightsEnabled ?? this.mediaActivityInsightsEnabled,
      anonymousAnalyticsEnabled:
          anonymousAnalyticsEnabled ?? this.anonymousAnalyticsEnabled,
      trackingPaused: trackingPaused ?? this.trackingPaused,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationInsightsEnabled': locationInsightsEnabled,
      'backgroundLocationEnabled': backgroundLocationEnabled,
      'appUsageInsightsEnabled': appUsageInsightsEnabled,
      'cameraActivityInsightsEnabled': cameraActivityInsightsEnabled,
      'mediaActivityInsightsEnabled': mediaActivityInsightsEnabled,
      'anonymousAnalyticsEnabled': anonymousAnalyticsEnabled,
      'trackingPaused': trackingPaused,
    };
  }

  factory TravelInsightsConsentState.fromJson(Map<String, dynamic> json) {
    return TravelInsightsConsentState(
      locationInsightsEnabled:
          json['locationInsightsEnabled'] as bool? ?? false,
      backgroundLocationEnabled:
          json['backgroundLocationEnabled'] as bool? ?? false,
      appUsageInsightsEnabled:
          json['appUsageInsightsEnabled'] as bool? ?? false,
      cameraActivityInsightsEnabled:
          json['cameraActivityInsightsEnabled'] as bool? ?? false,
      mediaActivityInsightsEnabled:
          json['mediaActivityInsightsEnabled'] as bool? ?? false,
      anonymousAnalyticsEnabled:
          json['anonymousAnalyticsEnabled'] as bool? ?? false,
      trackingPaused: json['trackingPaused'] as bool? ?? false,
    );
  }
}

class LocationSample {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final bool fromForegroundSession;

  const LocationSample({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.fromForegroundSession = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'fromForegroundSession': fromForegroundSession,
    };
  }

  factory LocationSample.fromJson(Map<String, dynamic> json) {
    return LocationSample(
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      fromForegroundSession: json['fromForegroundSession'] as bool? ?? true,
    );
  }
}

class ActivityEvent {
  final String id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? placeName;
  final PlaceCategory? placeCategory;
  final ActivityType activityType;
  final Duration duration;
  final double confidence;
  final ActivityEventSource source;
  final bool consentGranted;
  final DateTime arrivalTime;
  final DateTime departureTime;

  const ActivityEvent({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.activityType,
    required this.duration,
    required this.confidence,
    required this.source,
    required this.consentGranted,
    required this.arrivalTime,
    required this.departureTime,
    this.placeId,
    this.placeName,
    this.placeCategory,
  });

  int get durationMinutes => duration.inMinutes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
      'placeName': placeName,
      'placeCategory': placeCategory?.name,
      'activityType': activityType.name,
      'durationMinutes': duration.inMinutes,
      'confidence': confidence,
      'source': source.name,
      'consentGranted': consentGranted,
      'arrivalTime': arrivalTime.toIso8601String(),
      'departureTime': departureTime.toIso8601String(),
    };
  }

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    final durationMinutes = json['durationMinutes'] as int? ?? 0;

    return ActivityEvent(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      placeId: json['placeId'] as String?,
      placeName: json['placeName'] as String?,
      placeCategory: json['placeCategory'] == null
          ? null
          : PlaceCategory.values.byName(json['placeCategory'] as String),
      activityType: ActivityType.values.byName(
        json['activityType'] as String? ?? ActivityType.unknown.name,
      ),
      duration: Duration(minutes: durationMinutes),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      source: ActivityEventSource.values.byName(
        json['source'] as String? ?? ActivityEventSource.location.name,
      ),
      consentGranted: json['consentGranted'] as bool? ?? false,
      arrivalTime: DateTime.parse(json['arrivalTime'] as String),
      departureTime: DateTime.parse(json['departureTime'] as String),
    );
  }
}

class PlaceEngagementSignal {
  final String placeId;
  final String placeName;
  final PlaceCategory category;
  final int visitCount;
  final double averageDwellMinutes;
  final double totalDwellMinutes;
  final double score;
  final String peakPeriodLabel;
  final String trendLabel;
  final bool isDemoData;

  const PlaceEngagementSignal({
    required this.placeId,
    required this.placeName,
    required this.category,
    required this.visitCount,
    required this.averageDwellMinutes,
    required this.totalDwellMinutes,
    required this.score,
    this.peakPeriodLabel = 'Not available',
    this.trendLabel = 'Not available',
    this.isDemoData = false,
  });
}

class TourismPlaceInsight {
  final String placeId;
  final String placeName;
  final PlaceCategory category;
  final int estimatedVisitCount;
  final double averageDwellMinutes;
  final String peakPeriodLabel;
  final String mainActivityLabel;
  final String trendLabel;
  final bool isDemoData;

  const TourismPlaceInsight({
    required this.placeId,
    required this.placeName,
    required this.category,
    required this.estimatedVisitCount,
    required this.averageDwellMinutes,
    required this.peakPeriodLabel,
    required this.mainActivityLabel,
    required this.trendLabel,
    this.isDemoData = false,
  });
}

class TourismRecommendation {
  final String title;
  final String detail;

  const TourismRecommendation({
    required this.title,
    required this.detail,
  });
}

class TourismInsightsDashboard {
  final int totalConsentedVisits;
  final int activeTourismZones;
  final String peakPeriodLabel;
  final double averageDwellMinutes;
  final List<TourismPlaceInsight> mostVisitedPlaces;
  final Map<String, int> categoryDistribution;
  final List<String> movementBetweenBroadZones;
  final List<TourismRecommendation> recommendations;
  final int minimumGroupThreshold;
  final int suppressedStatsCount;
  final bool isDemoData;
  final String disclaimer;

  const TourismInsightsDashboard({
    required this.totalConsentedVisits,
    required this.activeTourismZones,
    required this.peakPeriodLabel,
    required this.averageDwellMinutes,
    required this.mostVisitedPlaces,
    required this.categoryDistribution,
    required this.movementBetweenBroadZones,
    required this.recommendations,
    required this.minimumGroupThreshold,
    required this.suppressedStatsCount,
    required this.isDemoData,
    required this.disclaimer,
  });

  bool get hasPublishableData => mostVisitedPlaces.isNotEmpty;

  factory TourismInsightsDashboard.empty({int minimumGroupThreshold = 5}) {
    return TourismInsightsDashboard(
      totalConsentedVisits: 0,
      activeTourismZones: 0,
      peakPeriodLabel: 'Not enough traveller data yet',
      averageDwellMinutes: 0,
      mostVisitedPlaces: const <TourismPlaceInsight>[],
      categoryDistribution: const <String, int>{},
      movementBetweenBroadZones: const <String>[],
      recommendations: const <TourismRecommendation>[],
      minimumGroupThreshold: minimumGroupThreshold,
      suppressedStatsCount: 0,
      isDemoData: false,
      disclaimer:
          'Aggregate statistics appear only after enough consenting visits are available.',
    );
  }
}

class TravelInsightsSummary {
  final int totalEvents;
  final double averageDwellMinutes;
  final List<String> mostVisitedCategories;
  final List<String> busiestLocations;
  final List<String> quickStops;
  final List<String> popularActivityTypes;
  final List<String> recentTravelPatterns;
  final String disclaimer;

  const TravelInsightsSummary({
    required this.totalEvents,
    required this.averageDwellMinutes,
    required this.mostVisitedCategories,
    required this.busiestLocations,
    required this.quickStops,
    required this.popularActivityTypes,
    required this.recentTravelPatterns,
    required this.disclaimer,
  });

  factory TravelInsightsSummary.empty() {
    return const TravelInsightsSummary(
      totalEvents: 0,
      averageDwellMinutes: 0,
      mostVisitedCategories: <String>[],
      busiestLocations: <String>[],
      quickStops: <String>[],
      popularActivityTypes: <String>[],
      recentTravelPatterns: <String>[],
      disclaimer:
          'Insights appear after you opt in and accumulate enough on-device visit samples.',
    );
  }
}

class AnonymousAnalyticsSnapshot {
  final String headline;
  final List<String> highlights;
  final String disclaimer;

  const AnonymousAnalyticsSnapshot({
    required this.headline,
    required this.highlights,
    required this.disclaimer,
  });
}

class DeviceCapabilityInfo {
  final String id;
  final String title;
  final String description;
  final DeviceCapabilityStatus status;

  const DeviceCapabilityInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
  });
}

String prettyPrintJson(Map<String, dynamic> json) {
  return const JsonEncoder.withIndent('  ').convert(json);
}
