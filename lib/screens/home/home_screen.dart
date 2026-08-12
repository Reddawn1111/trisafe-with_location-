import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../utils/app_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/location_summary_card.dart';

/// HomeScreen — app entry point.
/// Route: /
/// Source: docs/NAVIGATION_MAP.md § 3.1
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppTheme.primary,
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppRoutes.privacyControls),
                  icon: const Icon(Icons.tune),
                  tooltip: 'Privacy & data controls',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  bottom: AppSpacing.sm,
                ),
                title: Text(
                  'TripSafe',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                background: _HeroBanner(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: 'Your Location'),
                  const SizedBox(height: AppSpacing.sm),
                  const LocationSummaryCard(),
                  const SizedBox(height: AppSpacing.sm),
                  _SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: AppSpacing.sm),
                  _QuickActions(),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: 'Your Trips'),
                  const SizedBox(height: AppSpacing.sm),
                  EmptyState(
                    message:
                        'No trips yet.\nDiscover destinations to get started.',
                    icon: Icons.luggage_outlined,
                    actionLabel: 'Browse Destinations',
                    action: () =>
                        Navigator.of(context).pushNamed(AppRoutes.discover),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Discover Destinations',
                    icon: Icons.explore_outlined,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.discover),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withValues(alpha: 0.7),
            AppTheme.secondary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: 10,
            child: Icon(
              Icons.travel_explore,
              size: 160,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.explore_outlined,
        label: 'Discover',
        route: AppRoutes.discover,
        color: AppTheme.primary,
      ),
      _QuickAction(
        icon: Icons.map_outlined,
        label: 'Journey',
        route: AppRoutes.journey,
        color: AppTheme.secondary,
      ),
      _QuickAction(
        icon: Icons.shield_outlined,
        label: 'Safety',
        route: AppRoutes.safety,
        color: AppTheme.warning,
      ),
      _QuickAction(
        icon: Icons.photo_library_outlined,
        label: 'Memories',
        route: AppRoutes.memories,
        color: Colors.purple,
      ),
    ];

    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: _QuickActionTile(action: a),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String route;
  final Color color;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xs,
      ),
      onTap: () => Navigator.of(context).pushNamed(action.route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(action.icon, color: action.color, size: 28),
          const SizedBox(height: AppSpacing.xs),
          Text(
            action.label,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
