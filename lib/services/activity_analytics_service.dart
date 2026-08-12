import '../models/activity_insights.dart';
import '../models/place_category.dart';

class ActivityAnalyticsService {
  const ActivityAnalyticsService();

  Map<String, PlaceEngagementSignal> buildPlaceSignals(
    List<ActivityEvent> events,
  ) {
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
      );
    }

    return result;
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
}
