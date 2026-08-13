import '../models/activity_insights.dart';
import '../models/place.dart';
import '../models/place_category.dart';

class ActivityAnalyticsService {
  const ActivityAnalyticsService();

  static const int defaultMinimumGroupThreshold = 5;

  Map<String, PlaceEngagementSignal> buildPlaceSignals(
    List<ActivityEvent> events,
    {
    int minimumGroupThreshold = defaultMinimumGroupThreshold,
    bool applyMinimumGroupRule = true,
  }) {
    final byPlace = <String, List<ActivityEvent>>{};
    for (final event in events) {
      final placeId = event.placeId;
      final placeName = event.placeName;
      final category = event.placeCategory;
      if (placeId == null || placeName == null || category == null) {
        continue;
      }
      byPlace.putIfAbsent(placeId, () => <ActivityEvent>[]).add(event);
    }

    final result = <String, PlaceEngagementSignal>{};
    for (final entry in byPlace.entries) {
      final eventsForPlace = entry.value;
      if (applyMinimumGroupRule &&
          eventsForPlace.length < minimumGroupThreshold) {
        continue;
      }

      final totalDwellMinutes = eventsForPlace
          .map((event) => event.durationMinutes.toDouble())
          .fold<double>(0, (sum, value) => sum + value);
      final averageDwell = totalDwellMinutes / eventsForPlace.length;
      final cappedDwellScore = (averageDwell / 45).clamp(0.0, 1.0).toDouble();
      final cappedVisitScore =
          (eventsForPlace.length / 4).clamp(0.0, 1.0).toDouble();
      final score = ((cappedDwellScore * 0.65) + (cappedVisitScore * 0.35))
          .clamp(0.0, 1.0)
          .toDouble();

      final latest = eventsForPlace.last;
      result[entry.key] = PlaceEngagementSignal(
        placeId: entry.key,
        placeName: latest.placeName ?? 'Unknown place',
        category: latest.placeCategory ?? PlaceCategory.other,
        visitCount: eventsForPlace.length,
        averageDwellMinutes: averageDwell,
        totalDwellMinutes: totalDwellMinutes,
        score: score,
        peakPeriodLabel: _peakPeriodLabel(eventsForPlace),
        trendLabel: _trendLabel(eventsForPlace),
      );
    }

    return result;
  }

  Map<String, PlaceEngagementSignal> buildDemoPlaceSignals(List<Place> places) {
    final result = <String, PlaceEngagementSignal>{};
    for (var index = 0; index < places.length; index++) {
      final place = places[index];
      final visitCount = 90 - (index * 7);
      final averageDwell = 28.0 + ((index % 4) * 9);
      result[place.id] = PlaceEngagementSignal(
        placeId: place.id,
        placeName: place.name,
        category: place.category,
        visitCount: visitCount.clamp(24, 90).toInt(),
        averageDwellMinutes: averageDwell,
        totalDwellMinutes: averageDwell * visitCount,
        score: (0.82 - (index * 0.04)).clamp(0.45, 0.92).toDouble(),
        peakPeriodLabel: index.isEven ? '5 PM-8 PM' : '11 AM-2 PM',
        trendLabel: index % 3 == 0 ? 'Getting more popular' : 'Stable',
        isDemoData: true,
      );
    }
    return result;
  }

  TourismInsightsDashboard buildTourismDashboard(
    List<ActivityEvent> events, {
    int minimumGroupThreshold = defaultMinimumGroupThreshold,
  }) {
    if (events.isEmpty) {
      return TourismInsightsDashboard.empty(
        minimumGroupThreshold: minimumGroupThreshold,
      );
    }

    final byPlace = <String, List<ActivityEvent>>{};
    for (final event in events) {
      if (event.placeId == null ||
          event.placeName == null ||
          event.placeCategory == null) {
        continue;
      }
      byPlace.putIfAbsent(event.placeId!, () => <ActivityEvent>[]).add(event);
    }

    final publishableGroups = byPlace.values
        .where((group) => group.length >= minimumGroupThreshold)
        .toList();
    final suppressedCount = byPlace.values
        .where((group) => group.length < minimumGroupThreshold)
        .length;

    if (publishableGroups.isEmpty) {
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
        suppressedStatsCount: suppressedCount,
        isDemoData: false,
        disclaimer:
            'Statistics below the minimum group threshold are hidden to protect anonymity.',
      );
    }

    final publishableEvents = publishableGroups.expand((group) => group).toList()
      ..sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));
    final totalVisits = publishableEvents.length;
    final averageDwell = publishableEvents
            .map((event) => event.durationMinutes.toDouble())
            .fold<double>(0, (sum, value) => sum + value) /
        totalVisits;

    final placeInsights = publishableGroups.map((group) {
      final latest = group.last;
      final totalDwell = group
          .map((event) => event.durationMinutes.toDouble())
          .fold<double>(0, (sum, value) => sum + value);
      return TourismPlaceInsight(
        placeId: latest.placeId!,
        placeName: latest.placeName!,
        category: latest.placeCategory!,
        estimatedVisitCount: group.length,
        averageDwellMinutes: totalDwell / group.length,
        peakPeriodLabel: _peakPeriodLabel(group),
        mainActivityLabel: _mostCommonActivityLabel(group),
        trendLabel: _trendLabel(group),
      );
    }).toList()
      ..sort(
        (a, b) => b.estimatedVisitCount.compareTo(a.estimatedVisitCount),
      );

    final categoryDistribution = <String, int>{};
    for (final event in publishableEvents) {
      final category = event.placeCategory?.displayName ?? 'Unknown';
      categoryDistribution.update(category, (count) => count + 1,
          ifAbsent: () => 1);
    }

    return TourismInsightsDashboard(
      totalConsentedVisits: totalVisits,
      activeTourismZones: placeInsights.length,
      peakPeriodLabel: _peakPeriodLabel(publishableEvents),
      averageDwellMinutes: averageDwell,
      mostVisitedPlaces: placeInsights.take(6).toList(),
      categoryDistribution: categoryDistribution,
      movementBetweenBroadZones: _movementBetweenBroadZones(publishableEvents),
      recommendations: _recommendationsFor(placeInsights),
      minimumGroupThreshold: minimumGroupThreshold,
      suppressedStatsCount: suppressedCount,
      isDemoData: false,
      disclaimer:
          'All analytics are grouped estimates from consenting users. Individual travel histories and trails are not displayed.',
    );
  }

  TourismInsightsDashboard buildDemoTourismDashboard() {
    const places = <TourismPlaceInsight>[
      TourismPlaceInsight(
        placeId: 'demo_zone_a',
        placeName: 'Sunset Viewpoint Promenade',
        category: PlaceCategory.viewpoint,
        estimatedVisitCount: 320,
        averageDwellMinutes: 46,
        peakPeriodLabel: '5 PM-8 PM',
        mainActivityLabel: 'Photo Spot',
        trendLabel: 'Getting more popular',
        isDemoData: true,
      ),
      TourismPlaceInsight(
        placeId: 'demo_zone_b',
        placeName: 'Central Scenic Park & Gardens',
        category: PlaceCategory.park,
        estimatedVisitCount: 265,
        averageDwellMinutes: 38,
        peakPeriodLabel: '4 PM-7 PM',
        mainActivityLabel: 'Walking',
        trendLabel: 'Stable',
        isDemoData: true,
      ),
      TourismPlaceInsight(
        placeId: 'demo_zone_c',
        placeName: 'Grand City Plaza & Shopping Arcade',
        category: PlaceCategory.shopping,
        estimatedVisitCount: 210,
        averageDwellMinutes: 29,
        peakPeriodLabel: '6 PM-9 PM',
        mainActivityLabel: 'Shopping',
        trendLabel: 'Rising quickly',
        isDemoData: true,
      ),
      TourismPlaceInsight(
        placeId: 'demo_zone_d',
        placeName: 'Cultural History Museum',
        category: PlaceCategory.museum,
        estimatedVisitCount: 88,
        averageDwellMinutes: 18,
        peakPeriodLabel: '11 AM-2 PM',
        mainActivityLabel: 'Tourism',
        trendLabel: 'Needs attention',
        isDemoData: true,
      ),
    ];

    return TourismInsightsDashboard(
      totalConsentedVisits: 883,
      activeTourismZones: places.length,
      peakPeriodLabel: '5 PM-8 PM',
      averageDwellMinutes: 39,
      mostVisitedPlaces: places,
      categoryDistribution: const <String, int>{
        'Viewpoint & Sunset': 320,
        'Park & Garden': 265,
        'Shopping & Markets': 210,
        'Museum & Culture': 88,
      },
      movementBetweenBroadZones: const <String>[
        'Park & Garden -> Viewpoint & Sunset',
        'Museum & Culture -> Shopping & Markets',
      ],
      recommendations: _demoRecommendations,
      minimumGroupThreshold: defaultMinimumGroupThreshold,
      suppressedStatsCount: 0,
      isDemoData: true,
      disclaimer:
          'DEMO DATA - simulated travellers for hackathon presentation only.',
    );
  }

  TravelInsightsSummary summarize(List<ActivityEvent> events) {
    if (events.isEmpty) {
      return TravelInsightsSummary.empty();
    }

    final totalDwell = events
        .map((event) => event.durationMinutes.toDouble())
        .fold<double>(0, (sum, value) => sum + value);
    final averageDwell = totalDwell / events.length;

    final categoryCounts = <String, int>{};
    final placeTotals = <String, double>{};
    final quickStops = <String>[];
    final activityCounts = <String, int>{};

    for (final event in events) {
      final categoryLabel =
          event.placeCategory?.displayName ?? event.activityType.label;
      categoryCounts.update(categoryLabel, (count) => count + 1,
          ifAbsent: () => 1);

      final placeLabel = event.placeName ?? 'Unknown place';
      placeTotals.update(
        placeLabel,
        (minutes) => minutes + event.durationMinutes,
        ifAbsent: () => event.durationMinutes.toDouble(),
      );

      if (event.durationMinutes <= 10 && event.placeName != null) {
        quickStops.add(
          '${event.placeName} (${event.durationMinutes} min)',
        );
      }

      activityCounts.update(event.activityType.label, (count) => count + 1,
          ifAbsent: () => 1);
    }

    final recentPatterns = <String>[];
    final sortedEvents = List<ActivityEvent>.from(events)
      ..sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));
    for (var index = 1; index < sortedEvents.length; index++) {
      final previous = sortedEvents[index - 1];
      final current = sortedEvents[index];
      if (previous.placeName == null || current.placeName == null) {
        continue;
      }
      recentPatterns.add('${previous.placeName} -> ${current.placeName}');
    }

    List<String> topEntries(
      Map<String, num> source, {
      required String formatter(String key, num value),
      int limit = 3,
    }) {
      final sorted = source.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted
          .take(limit)
          .map((entry) => formatter(entry.key, entry.value))
          .toList();
    }

    return TravelInsightsSummary(
      totalEvents: events.length,
      averageDwellMinutes: averageDwell,
      mostVisitedCategories: topEntries(
        categoryCounts,
        formatter: (key, value) => '$key ($value visits)',
      ),
      busiestLocations: topEntries(
        placeTotals,
        formatter: (key, value) => '$key (${value.round()} min total)',
      ),
      quickStops: quickStops.take(3).toList(),
      popularActivityTypes: topEntries(
        activityCounts,
        formatter: (key, value) => '$key ($value)',
      ),
      recentTravelPatterns: recentPatterns.reversed.take(3).toList(),
      disclaimer:
          'Estimates are based only on opted-in, on-device samples captured while using this prototype.',
    );
  }

  AnonymousAnalyticsSnapshot buildAnonymousSnapshot(
    List<ActivityEvent> events,
    TravelInsightsConsentState consentState,
  ) {
    if (!consentState.anonymousAnalyticsEnabled || events.isEmpty) {
      return const AnonymousAnalyticsSnapshot(
        headline: 'Anonymous analytics are off',
        highlights: <String>[
          'No crowd-style estimates are prepared unless you opt in.',
        ],
        disclaimer:
            'This MVP keeps data on-device and does not send government-facing analytics anywhere.',
      );
    }

    final summary = summarize(events);
    return AnonymousAnalyticsSnapshot(
      headline:
          'Estimated ${events.length} consenting visit events captured on this device',
      highlights: <String>[
        if (summary.busiestLocations.isNotEmpty)
          'Busiest location: ${summary.busiestLocations.first}',
        if (summary.mostVisitedCategories.isNotEmpty)
          'Top category: ${summary.mostVisitedCategories.first}',
        if (summary.averageDwellMinutes > 0)
          'Average dwell time: ${summary.averageDwellMinutes.toStringAsFixed(0)} min',
      ],
      disclaimer:
          'Any future dashboard must stay aggregated and anonymized. These counts are estimates from consenting users only, not total population.',
    );
  }

  String _peakPeriodLabel(List<ActivityEvent> events) {
    if (events.isEmpty) {
      return 'Not available';
    }

    final hourCounts = <int, int>{};
    for (final event in events) {
      hourCounts.update(event.arrivalTime.hour, (count) => count + 1,
          ifAbsent: () => 1);
    }

    final sorted = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final startHour = sorted.first.key;
    final endHour = (startHour + 3).clamp(0, 24);
    return '${_formatHour(startHour)}-${_formatHour(endHour)}';
  }

  String _formatHour(int hour) {
    final normalized = hour % 24;
    if (normalized == 0) {
      return '12 AM';
    }
    if (normalized == 12) {
      return '12 PM';
    }
    if (normalized > 12) {
      return '${normalized - 12} PM';
    }
    return '$normalized AM';
  }

  String _trendLabel(List<ActivityEvent> events) {
    if (events.length < 2) {
      return 'Not available';
    }

    final sorted = List<ActivityEvent>.from(events)
      ..sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));
    final midpoint = sorted.length ~/ 2;
    final firstHalf = sorted.take(midpoint).length;
    final secondHalf = sorted.skip(midpoint).length;

    if (secondHalf > firstHalf) {
      return 'Getting more popular';
    }
    if (secondHalf < firstHalf) {
      return 'Cooling down';
    }
    return 'Stable';
  }

  String _mostCommonActivityLabel(List<ActivityEvent> events) {
    final counts = <String, int>{};
    for (final event in events) {
      counts.update(event.activityType.label, (count) => count + 1,
          ifAbsent: () => 1);
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.isEmpty ? 'Not available' : sorted.first.key;
  }

  List<String> _movementBetweenBroadZones(List<ActivityEvent> events) {
    final movements = <String, int>{};
    for (var index = 1; index < events.length; index++) {
      final previous = events[index - 1].placeCategory?.displayName;
      final current = events[index].placeCategory?.displayName;
      if (previous == null || current == null || previous == current) {
        continue;
      }
      movements.update('$previous -> $current', (count) => count + 1,
          ifAbsent: () => 1);
    }

    final sorted = movements.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((entry) => '${entry.key} (${entry.value})').toList();
  }

  List<TourismRecommendation> _recommendationsFor(
    List<TourismPlaceInsight> places,
  ) {
    final recommendations = <TourismRecommendation>[];
    for (final place in places) {
      if (place.estimatedVisitCount >= 100 && place.averageDwellMinutes >= 35) {
        recommendations.add(
          TourismRecommendation(
            title: 'Data-driven recommendation',
            detail:
                '${place.placeName}: high visits and long dwell. Prioritize maintenance, sanitation, staffing, and visitor flow support.',
          ),
        );
      } else if (place.estimatedVisitCount >= 80 &&
          place.averageDwellMinutes < 20) {
        recommendations.add(
          TourismRecommendation(
            title: 'Data-driven recommendation',
            detail:
                '${place.placeName}: high visits but short stays. Investigate accessibility, facilities, signage, or visitor experience.',
          ),
        );
      } else if (place.trendLabel.contains('popular') ||
          place.trendLabel.contains('Rising')) {
        recommendations.add(
          TourismRecommendation(
            title: 'Data-driven recommendation',
            detail:
                '${place.placeName}: rising visits. Increase monitoring and prepare nearby alternate routes or attractions.',
          ),
        );
      }
    }

    if (places.length == 1) {
      recommendations.add(
        TourismRecommendation(
          title: 'Data-driven recommendation',
          detail:
              'Visitor activity is concentrated in one zone. Promote nearby alternatives to distribute crowd pressure.',
        ),
      );
    }

    return recommendations.take(5).toList();
  }

  static const List<TourismRecommendation> _demoRecommendations =
      <TourismRecommendation>[
    TourismRecommendation(
      title: 'Data-driven recommendation',
      detail:
          'Sunset Viewpoint Promenade has high visits and long dwell. Add crowd diversion signs and evening sanitation support.',
    ),
    TourismRecommendation(
      title: 'Data-driven recommendation',
      detail:
          'Grand City Plaza is rising quickly during evening hours. Coordinate parking management from 6 PM-9 PM.',
    ),
    TourismRecommendation(
      title: 'Data-driven recommendation',
      detail:
          'Cultural History Museum has lower dwell despite steady visits. Review visitor facilities, guides, and accessibility.',
    ),
  ];
}
