import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../models/activity_insights.dart';
import '../../services/device_activity_service.dart';
import '../../services/travel_insights_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';

class PrivacyControlsScreen extends StatefulWidget {
  const PrivacyControlsScreen({super.key});

  @override
  State<PrivacyControlsScreen> createState() => _PrivacyControlsScreenState();
}

class _PrivacyControlsScreenState extends State<PrivacyControlsScreen> {
  final TravelInsightsService _travelInsightsService = TravelInsightsService();
  final DeviceActivityService _deviceActivityService =
      OfficialDeviceActivityService.instance;

  TravelInsightsConsentState _consentState =
      const TravelInsightsConsentState();
  TravelInsightsSummary _summary = TravelInsightsSummary.empty();
  AnonymousAnalyticsSnapshot _anonymousSnapshot =
      const AnonymousAnalyticsSnapshot(
        headline: 'Anonymous analytics are off',
        highlights: <String>[],
        disclaimer: '',
      );
  List<DeviceCapabilityInfo> _capabilities = const <DeviceCapabilityInfo>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final results = await Future.wait<dynamic>([
      _travelInsightsService.getConsentState(),
      _travelInsightsService.getSummary(),
      _travelInsightsService.getAnonymousSnapshot(),
      _deviceActivityService.getCapabilities(),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _consentState = results[0] as TravelInsightsConsentState;
      _summary = results[1] as TravelInsightsSummary;
      _anonymousSnapshot = results[2] as AnonymousAnalyticsSnapshot;
      _capabilities = results[3] as List<DeviceCapabilityInfo>;
      _isLoading = false;
    });
  }

  DeviceCapabilityInfo? _capabilityById(String id) {
    for (final capability in _capabilities) {
      if (capability.id == id) {
        return capability;
      }
    }
    return null;
  }

  Future<void> _updateConsent(TravelInsightsConsentState next) async {
    await _travelInsightsService.updateConsentState(next);
    await _loadData();
  }

  bool _isCapabilityAvailable(String id) {
    return _capabilityById(id)?.status == DeviceCapabilityStatus.available;
  }

  String _capabilityNote(String id) {
    final capability = _capabilityById(id);
    if (capability == null) {
      return 'Capability status unavailable.';
    }
    return capability.description;
  }

  Future<void> _showExportDialog() async {
    final exportJson = await _travelInsightsService.exportData();
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Exported Activity Data'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                exportJson,
                style: AppTypography.caption.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAndRun({
    required String title,
    required String body,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await action();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: TripSafeAppBar(title: 'Privacy & Data Controls'),
        body: LoadingState(message: 'Loading privacy controls...'),
      );
    }

    return Scaffold(
      appBar: const TripSafeAppBar(title: 'Privacy & Data Controls'),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _IntroCard(consentState: _consentState),
            const SizedBox(height: AppSpacing.md),
            _SectionTitle(
              title: 'Consent toggles',
              subtitle:
                  'Everything below is optional and off by default in this MVP.',
            ),
            const SizedBox(height: AppSpacing.sm),
            _ConsentTile(
              title: 'Location insights',
              value: _consentState.locationInsightsEnabled,
              onChanged: (value) => _updateConsent(
                _consentState.copyWith(locationInsightsEnabled: value),
              ),
              details: const [
                'What: timestamped foreground GPS samples while using Explore, plus visit estimates near nearby POIs.',
                'Why: to build dwell-based travel activity insights and improve Explore relevance.',
                'Retention: stored locally for up to 14 days in this prototype.',
                'Recipients: no external recipients in this MVP.',
              ],
            ),
            _ConsentTile(
              title: 'Background location',
              value: _consentState.backgroundLocationEnabled,
              enabled: false,
              onChanged: (_) {},
              details: const [
                'What: would collect coarse visit updates outside the active Explore screen.',
                'Why: to improve visit continuity after explicit consent.',
                'Retention: not collected in this MVP.',
                'Recipients: none.',
              ],
              trailingNote:
                  'Not supported in this prototype yet. Explore currently samples location only in the foreground.',
            ),
            _ConsentTile(
              title: 'App usage insights',
              value: _consentState.appUsageInsightsEnabled,
              enabled: _isCapabilityAvailable('app_usage'),
              onChanged: (value) => _updateConsent(
                _consentState.copyWith(appUsageInsightsEnabled: value),
              ),
              details: const [
                'What: coarse app usage duration only when the platform officially exposes it.',
                'Why: to add optional behavioral context for travel activity summaries.',
                'Retention: would stay local for up to 14 days.',
                'Recipients: no external recipients in this MVP.',
              ],
              trailingNote: _capabilityNote('app_usage'),
            ),
            _ConsentTile(
              title: 'Camera activity insights',
              value: _consentState.cameraActivityInsightsEnabled,
              enabled: _isCapabilityAvailable('camera_usage'),
              onChanged: (value) => _updateConsent(
                _consentState.copyWith(
                  cameraActivityInsightsEnabled: value,
                ),
              ),
              details: const [
                'What: camera app timestamps and duration only, never photos or image contents.',
                'Why: to estimate photo-stop behavior near places.',
                'Retention: would stay local for up to 14 days.',
                'Recipients: no external recipients in this MVP.',
              ],
              trailingNote: _capabilityNote('camera_usage'),
            ),
            _ConsentTile(
              title: 'Media activity insights',
              value: _consentState.mediaActivityInsightsEnabled,
              enabled: _isCapabilityAvailable('media_usage'),
              onChanged: (value) => _updateConsent(
                _consentState.copyWith(mediaActivityInsightsEnabled: value),
              ),
              details: const [
                'What: coarse media app session duration only, not songs, searches, or messages.',
                'Why: to add optional contextual signals for travel engagement.',
                'Retention: would stay local for up to 14 days.',
                'Recipients: no external recipients in this MVP.',
              ],
              trailingNote: _capabilityNote('media_usage'),
            ),
            _ConsentTile(
              title: 'Anonymous analytics contribution',
              value: _consentState.anonymousAnalyticsEnabled,
              onChanged: (value) => _updateConsent(
                _consentState.copyWith(anonymousAnalyticsEnabled: value),
              ),
              details: const [
                'What: aggregated estimates such as visits, peak windows, and average dwell time.',
                'Why: to preview future crowd-management style analytics without individual trails.',
                'Retention: derived from local events within the 14-day window.',
                'Recipients: no one outside this device in the current MVP.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.deviceActivityInsights),
              child: Row(
                children: [
                  const Icon(Icons.privacy_tip_outlined),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device Activity Insights',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'See which official capabilities are available on this device and which are intentionally unsupported.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionTitle(
              title: 'Current insights',
              subtitle:
                  'These on-device summaries only appear after opted-in visit detection creates activity events.',
            ),
            const SizedBox(height: AppSpacing.sm),
            _SummaryCard(summary: _summary),
            const SizedBox(height: AppSpacing.md),
            _AnonymousSnapshotCard(snapshot: _anonymousSnapshot),
            const SizedBox(height: AppSpacing.md),
            _SectionTitle(
              title: 'Controls',
              subtitle:
                  'Use these to pause, export, or remove the data captured by this prototype.',
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile.adaptive(
              value: _consentState.trackingPaused,
              title: const Text('Pause tracking'),
              subtitle: const Text(
                'Stops new activity sampling while keeping your consent choices and stored events.',
              ),
              onChanged: (value) async {
                await _travelInsightsService.setTrackingPaused(value);
                await _loadData();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: 'Export Activity Data',
              icon: Icons.file_download_outlined,
              onPressed: _showExportDialog,
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'Delete Collected Activity Data',
              icon: Icons.delete_outline,
              onPressed: () => _confirmAndRun(
                title: 'Delete activity data?',
                body:
                    'This removes stored location samples and detected activity events from this device.',
                action: _travelInsightsService.clearActivityData,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'Clear Consent State',
              icon: Icons.refresh_outlined,
              onPressed: () => _confirmAndRun(
                title: 'Clear consent state?',
                body:
                    'This turns off all optional travel insights toggles. Existing data is not deleted unless you choose the delete action separately.',
                action: _travelInsightsService.clearConsentState,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.consentState});

  final TravelInsightsConsentState consentState;

  @override
  Widget build(BuildContext context) {
    final trackingStatus = consentState.trackingPaused
        ? 'Paused'
        : consentState.locationInsightsEnabled
            ? 'Active when using Explore'
            : 'Off';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consent-based travel activity intelligence',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'TripSafe only creates activity insights from data you explicitly allow. The current MVP samples foreground location while you use Explore and keeps analytics on-device.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _StatusChip(
                label: 'Tracking: $trackingStatus',
                color: consentState.locationInsightsEnabled
                    ? AppTheme.primary
                    : Colors.grey,
              ),
              _StatusChip(
                label: consentState.anonymousAnalyticsEnabled
                    ? 'Anonymous summary enabled'
                    : 'Anonymous summary off',
                color: consentState.anonymousAnalyticsEnabled
                    ? AppTheme.secondary
                    : Colors.grey,
              ),
            ],
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.details,
    this.enabled = true,
    this.trailingNote,
  });

  final String title;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final List<String> details;
  final String? trailingNote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: value,
              onChanged: enabled ? onChanged : null,
              title: Text(title),
              subtitle: trailingNote == null ? null : Text(trailingNote!),
            ),
            for (final detail in details)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  detail,
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.72),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final TravelInsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.totalEvents == 0) {
      return AppCard(
        child: Text(
          summary.disclaimer,
          style: AppTypography.bodyMedium,
        ),
      );
    }

    Widget line(String title, List<String> values) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              values.isEmpty ? 'No strong signal yet.' : values.join('\n'),
              style: AppTypography.caption,
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${summary.totalEvents} detected activity events',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Average dwell time: ${summary.averageDwellMinutes.toStringAsFixed(0)} min',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          line('Most visited categories', summary.mostVisitedCategories),
          line('Busiest locations', summary.busiestLocations),
          line('Short stop locations', summary.quickStops),
          line('Popular activity types', summary.popularActivityTypes),
          line('Recent travel patterns', summary.recentTravelPatterns),
          Text(
            summary.disclaimer,
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnonymousSnapshotCard extends StatelessWidget {
  const _AnonymousSnapshotCard({required this.snapshot});

  final AnonymousAnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            snapshot.headline,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final highlight in snapshot.highlights)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                highlight,
                style: AppTypography.bodyMedium,
              ),
            ),
          if (snapshot.highlights.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          Text(
            snapshot.disclaimer,
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
