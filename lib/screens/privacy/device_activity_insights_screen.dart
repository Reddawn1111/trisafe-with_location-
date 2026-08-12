import 'package:flutter/material.dart';

import '../../models/activity_insights.dart';
import '../../services/device_activity_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DeviceActivityInsightsScreen extends StatefulWidget {
  const DeviceActivityInsightsScreen({super.key});

  @override
  State<DeviceActivityInsightsScreen> createState() =>
      _DeviceActivityInsightsScreenState();
}

class _DeviceActivityInsightsScreenState
    extends State<DeviceActivityInsightsScreen> {
  final DeviceActivityService _deviceActivityService =
      OfficialDeviceActivityService.instance;

  late Future<List<DeviceCapabilityInfo>> _capabilitiesFuture;

  @override
  void initState() {
    super.initState();
    _capabilitiesFuture = _deviceActivityService.getCapabilities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TripSafeAppBar(title: 'Device Activity Insights'),
      body: FutureBuilder<List<DeviceCapabilityInfo>>(
        future: _capabilitiesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingState(message: 'Checking device capabilities...');
          }

          final capabilities = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Official APIs only',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'This MVP does not monitor messages, files, keystrokes, clipboard contents, browser history, or other app content. Unsupported features stay off.',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final capability in capabilities)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                capability.title,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _CapabilityBadge(status: capability.status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          capability.description,
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
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CapabilityBadge extends StatelessWidget {
  const _CapabilityBadge({required this.status});

  final DeviceCapabilityStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (status) {
      case DeviceCapabilityStatus.available:
        color = AppTheme.success;
        break;
      case DeviceCapabilityStatus.unavailable:
        color = AppTheme.warning;
        break;
      case DeviceCapabilityStatus.notSupported:
        color = Colors.grey;
        break;
    }

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
        status.label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
