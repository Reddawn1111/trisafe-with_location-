import 'package:flutter/material.dart';

import '../../models/activity_insights.dart';
import '../../services/travel_insights_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class TourismInsightsScreen extends StatefulWidget {
  const TourismInsightsScreen({super.key});

  @override
  State<TourismInsightsScreen> createState() => _TourismInsightsScreenState();
}

class _TourismInsightsScreenState extends State<TourismInsightsScreen> {
  final TravelInsightsService _travelInsightsService = TravelInsightsService();

  TourismInsightsDashboard _dashboard = TourismInsightsDashboard.empty();
  bool _isLoading = true;
  bool _isDemoMode = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
    });

    final dashboard = _isDemoMode
        ? _travelInsightsService.getDemoTourismDashboard()
        : await _travelInsightsService.getTourismDashboard();

    if (!mounted) {
      return;
    }

    setState(() {
      _dashboard = dashboard;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TripSafeAppBar(
        title: 'Tourism Insights',
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh insights',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingState(message: 'Preparing aggregate insights...')
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _DemoModeTile(
                    isDemoMode: _isDemoMode,
                    onChanged: (value) async {
                      setState(() {
                        _isDemoMode = value;
                      });
                      await _loadDashboard();
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_dashboard.isDemoData) const _DemoBanner(),
                  if (_dashboard.isDemoData)
                    const SizedBox(height: AppSpacing.sm),
                  _OverviewGrid(dashboard: _dashboard),
                  const SizedBox(height: AppSpacing.md),
                  _SectionTitle(
                    title: 'Most visited places',
                    subtitle:
                        'Grouped place statistics. Small groups are hidden.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (!_dashboard.hasPublishableData)
                    AppCard(
                      child: Text(
                        'Not enough traveller data yet. Minimum group threshold: ${_dashboard.minimumGroupThreshold} consenting visits.',
                        style: AppTypography.bodyMedium,
                      ),
                    )
                  else
                    for (final place in _dashboard.mostVisitedPlaces)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _PlaceInsightCard(place: place),
                      ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionTitle(
                    title: 'Activity distribution',
                    subtitle: 'Category-level estimates only.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DistributionCard(dashboard: _dashboard),
                  const SizedBox(height: AppSpacing.md),
                  _SectionTitle(
                    title: 'Broad movement',
                    subtitle:
                        'Aggregated category transitions, never individual trails.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Text(
                      _dashboard.movementBetweenBroadZones.isEmpty
                          ? 'Not enough traveller data yet.'
                          : _dashboard.movementBetweenBroadZones.join('\n'),
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionTitle(
                    title: 'Actionable recommendations',
                    subtitle:
                        'Recommendations support planning. They are not automatic decisions.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_dashboard.recommendations.isEmpty)
                    const AppCard(
                      child: Text('Not enough aggregate signal yet.'),
                    )
                  else
                    for (final recommendation in _dashboard.recommendations)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recommendation.title,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                recommendation.detail,
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _dashboard.disclaimer,
                    style: AppTypography.caption.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65),
                    ),
                  ),
                  if (_dashboard.suppressedStatsCount > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${_dashboard.suppressedStatsCount} small group statistic(s) hidden for privacy.',
                      style: AppTypography.caption.copyWith(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
    );
  }
}

class _DemoModeTile extends StatelessWidget {
  const _DemoModeTile({
    required this.isDemoMode,
    required this.onChanged,
  });

  final bool isDemoMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: isDemoMode,
      onChanged: onChanged,
      title: const Text('Demo mode'),
      subtitle: const Text('Show clearly labelled simulated traveller data.'),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        'DEMO DATA - simulated travellers',
        style: AppTypography.caption.copyWith(
          color: AppTheme.warning,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.dashboard});

  final TourismInsightsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric(
        label: 'Total consented visits',
        value: dashboard.totalConsentedVisits.toString(),
      ),
      _Metric(
        label: 'Active tourism zones',
        value: dashboard.activeTourismZones.toString(),
      ),
      _Metric(label: 'Peak hours', value: dashboard.peakPeriodLabel),
      _Metric(
        label: 'Average dwell',
        value: dashboard.averageDwellMinutes == 0
            ? 'Not available'
            : '${dashboard.averageDwellMinutes.toStringAsFixed(0)} min',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.45,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                metric.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                metric.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaceInsightCard extends StatelessWidget {
  const _PlaceInsightCard({required this.place});

  final TourismPlaceInsight place;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            place.placeName,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${place.estimatedVisitCount} consenting visits | Typical visit: ${place.averageDwellMinutes.toStringAsFixed(0)} min',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Peak: ${place.peakPeriodLabel} | Main activity: ${place.mainActivityLabel} | ${place.trendLabel}',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.dashboard});

  final TourismInsightsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    if (dashboard.categoryDistribution.isEmpty) {
      return const AppCard(
        child: Text('Not enough traveller data yet.'),
      );
    }

    final entries = dashboard.categoryDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: AppTypography.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTypography.caption.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _Metric {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
