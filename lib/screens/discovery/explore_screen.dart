import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/routes.dart';
import '../../models/activity_insights.dart';
import '../../models/place.dart';
import '../../models/place_category.dart';
import '../../services/location_service.dart';
import '../../services/nearby_discovery_service.dart';
import '../../services/recommendation_service.dart';
import '../../services/travel_insights_service.dart';
import '../../services/itinerary_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import 'place_detail_sheet.dart';

/// "Explore Around Me" — Mobile-first travel discovery screen.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final LocationService _locationService = LocationService();
  final NearbyDiscoveryService _liveDiscoveryService = GeoapifyPlacesNearbyService();
  final NearbyDiscoveryService _demoDiscoveryService = MockNearbyDiscoveryService();
  final RecommendationService _recommendationService = RecommendationService();
  final TravelInsightsService _travelInsightsService = TravelInsightsService();

  LocationAddress? _currentAddress;
  Position? _currentPosition;
  List<Place> _allNearbyPlaces = [];
  List<Place> _rankedPlaces = [];
  Map<String, PlaceEngagementSignal> _engagementSignals =
      const <String, PlaceEngagementSignal>{};
  TravelInsightsConsentState _consentState =
      const TravelInsightsConsentState();
  TravelInsightsSummary _insightsSummary = TravelInsightsSummary.empty();

  UserIntent _selectedIntent = UserIntent.all;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isApiNotConfigured = false;
  bool _isDemoMode = false;

  @override
  void initState() {
    super.initState();
    _loadLocationAndPlaces();
  }

  Future<void> _loadLocationAndPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isApiNotConfigured = false;
    });

    try {
      // 1. Obtain actual device GPS position via existing LocationService
      final position = await _locationService.getCurrentPosition();
      _currentPosition = position;

      // 2. Reverse-geocode the same GPS fix for the UI header (no second GPS read)
      try {
        final address = await _locationService.getAddressForCoordinates(
          position.latitude,
          position.longitude,
        );
        _currentAddress = address;
      } catch (_) {
        // Reverse geocoding optional fallback for header label
      }

      // 3. Select active service provider (Live vs Demo Mode)
      List<Place> rawPlaces = [];
      if (_isDemoMode) {
        rawPlaces = await _demoDiscoveryService.getNearbyPlaces(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusMeters: 5000,
        );
      } else {
        rawPlaces = await _liveDiscoveryService.getNearbyPlaces(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusMeters: 5000,
        );
      }

      _allNearbyPlaces = rawPlaces;

      await _travelInsightsService.recordLocationObservation(
        position: position,
        nearbyPlaces: rawPlaces,
        isDemoMode: _isDemoMode,
      );

      final consent = await _travelInsightsService.getConsentState();
      final signals = await _travelInsightsService.getPlaceSignals();
      final summary = await _travelInsightsService.getSummary();
      if (!mounted) {
        return;
      }
      _consentState = consent;
      _engagementSignals = signals;
      _insightsSummary = summary;

      // 4. Rank places using Recommendation Engine
      _applyRecommendationFilter();
    } on PlacesApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e.code == 'API_NOT_CONFIGURED') {
            _isApiNotConfigured = true;
          } else {
            _errorMessage = e.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _applyRecommendationFilter() {
    if (!mounted || _currentPosition == null) {
      setState(() => _isLoading = false);
      return;
    }

    final ranked = _recommendationService.rankPlaces(
      places: List.from(_allNearbyPlaces),
      userLatitude: _currentPosition!.latitude,
      userLongitude: _currentPosition!.longitude,
      selectedIntent: _selectedIntent,
      searchRadiusKm: 5.0,
      engagementSignals: _engagementSignals,
    );

    setState(() {
      _rankedPlaces = ranked;
      _isLoading = false;
    });
  }

  void _onIntentChanged(UserIntent intent) {
    if (_selectedIntent == intent) return;
    setState(() {
      _selectedIntent = intent;
    });
    _applyRecommendationFilter();
  }

  void _toggleDemoMode(bool enabled) {
    setState(() {
      _isDemoMode = enabled;
    });
    _loadLocationAndPlaces();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Around Me'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _loadLocationAndPlaces,
            tooltip: 'Refresh location',
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () async {
              await Navigator.of(context).pushNamed(AppRoutes.privacyControls);
              if (mounted) {
                await _loadLocationAndPlaces();
              }
            },
            tooltip: 'Privacy & data controls',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLocationAndPlaces,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Demo Mode Banner if active ────────────────────────────────
            if (_isDemoMode)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.amber.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'DEMO MODE — Showing Sample Data',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _toggleDemoMode(false),
                        child: Text(
                          'Exit Demo',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Location & Header Banner ──────────────────────────────────
            SliverToBoxAdapter(
              child: _buildHeaderCard(theme),
            ),

            // ── Intent Chips Filter Bar ──────────────────────────────────
            SliverToBoxAdapter(
              child: _buildIntentFilterBar(),
            ),

            // ── Main Body Content ─────────────────────────────────────────
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: AppSpacing.md),
                      Text('Discovering nearby points of interest...'),
                    ],
                  ),
                ),
              )
            else if (_isApiNotConfigured)
              SliverFillRemaining(
                child: _buildUnconfiguredState(),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: _buildErrorState(),
              )
            else if (_rankedPlaces.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  message: 'No places found matching "${_selectedIntent.label}".\nTry selecting another category.',
                  icon: Icons.explore_off_outlined,
                  actionLabel: 'Show All Places',
                  action: () => _onIntentChanged(UserIntent.all),
                ),
              )
            else
              SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Recommended for You
                  _buildSectionHeader('⭐ Recommended For You', 'Scored by rating, review popularity & distance'),
                  _buildRecommendedCarousel(),

                  const SizedBox(height: AppSpacing.lg),

                  // 2. Popular Nearby
                  _buildSectionHeader('🔥 Popular Nearby', 'High review activity'),
                  ..._buildPopularList(),

                  const SizedBox(height: AppSpacing.lg),

                  // 3. Closest Options
                  _buildSectionHeader('📍 Closest Options', 'Closest to device GPS location'),
                  ..._buildClosestList(),

                  const SizedBox(height: AppSpacing.xxl),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.near_me, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPLORE AROUND YOU',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentAddress != null
                      ? '📍 ${_currentAddress!.areaLabel}'
                      : _currentPosition != null
                          ? '📍 GPS: ${_currentPosition!.latitude.toStringAsFixed(3)}, ${_currentPosition!.longitude.toStringAsFixed(3)}'
                          : 'Detecting your location...',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentAddress != null)
                  Text(
                    _currentAddress!.shortLine,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                Text(
                  _consentState.locationInsightsEnabled
                      ? _consentState.trackingPaused
                          ? 'Travel insights paused'
                          : 'Travel insights on · ${_insightsSummary.totalEvents} detected visits'
                      : 'Travel insights off by default',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntentFilterBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: UserIntent.values.length,
        itemBuilder: (context, index) {
          final intent = UserIntent.values[index];
          final isSelected = _selectedIntent == intent;

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              selected: isSelected,
              label: Text(intent.chipText),
              labelStyle: AppTypography.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
              selectedColor: AppTheme.primary,
              backgroundColor: Theme.of(context).cardColor,
              elevation: isSelected ? 2 : 0,
              onSelected: (_) => _onIntentChanged(intent),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildRecommendedCarousel() {
    final topRecommended = _rankedPlaces.take(5).toList();

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: topRecommended.length,
        itemBuilder: (context, index) {
          final place = topRecommended[index];
          return Container(
            width: 270,
            margin: const EdgeInsets.only(right: AppSpacing.md),
            child: _RecommendedPlaceCard(
              place: place,
              onTap: () => PlaceDetailSheet.show(context, place),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildPopularList() {
    final popular = List<Place>.from(_rankedPlaces)
      ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));

    return popular.take(4).map((place) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        child: _PlaceTileCard(
          place: place,
          onTap: () => PlaceDetailSheet.show(context, place),
        ),
      );
    }).toList();
  }

  List<Widget> _buildClosestList() {
    final closest = List<Place>.from(_rankedPlaces)
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return closest.take(4).map((place) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        child: _PlaceTileCard(
          place: place,
          onTap: () => PlaceDetailSheet.show(context, place),
        ),
      );
    }).toList();
  }

  /// Explicit API Unconfigured State Screen (Enforces Rules 9 & 10)
  Widget _buildUnconfiguredState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.api_outlined, size: 64, color: Colors.orangeAccent),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nearby Places API Not Configured',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'GEOAPIFY_API_KEY is required to search live places around your actual GPS location.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Retry Connection',
            icon: Icons.refresh,
            onPressed: _loadLocationAndPlaces,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _toggleDemoMode(true),
            icon: const Icon(Icons.developer_mode),
            label: const Text('Enable Demo Mode (Sample Data)'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off_outlined, size: 64, color: Colors.redAccent),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Unable to Fetch Nearby Places',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _errorMessage ?? 'Check location permissions and network connection.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Retry',
            icon: Icons.refresh,
            onPressed: _loadLocationAndPlaces,
          ),
        ],
      ),
    );
  }
}

class _RecommendedPlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _RecommendedPlaceCard({
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final itineraryService = ItineraryService();
    final isInItinerary = itineraryService.isPlaceInItinerary(place.id);

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: place.photoUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSpacing.radiusMd),
                        ),
                        child: Image.network(
                          place.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildCategoryPlaceholder(),
                        ),
                      )
                    : _buildCategoryPlaceholder(),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${place.category.iconEmoji} ${place.category.displayName}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(place.recommendationScore * 100).round()}% Match',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      place.hasRating
                          ? '⭐ ${place.ratingLabel} (${place.reviewCountLabel})'
                          : '⭐ Rating unavailable',
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '📍 ${place.distanceKm.toStringAsFixed(1)} km',
                      style: AppTypography.caption.copyWith(color: AppTheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  place.recommendationReason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: onTap,
                        child: const Text('View'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (isInItinerary) {
                            itineraryService.removePlaceFromItinerary(place.id);
                          } else {
                            itineraryService.addPlaceToItinerary(place);
                          }
                          (context as Element).markNeedsBuild();
                        },
                        child: Text(isInItinerary ? 'Added' : '+ Trip'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPlaceholder() {
    return Center(
      child: Icon(
        place.category.iconData,
        size: 40,
        color: AppTheme.primary,
      ),
    );
  }
}

class _PlaceTileCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _PlaceTileCard({
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              width: 64,
              height: 64,
              color: AppTheme.primary.withValues(alpha: 0.1),
              child: place.photoUrl != null
                  ? Image.network(
                      place.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Center(child: Text(place.category.iconEmoji, style: const TextStyle(fontSize: 28))),
                    )
                  : Center(child: Text(place.category.iconEmoji, style: const TextStyle(fontSize: 28))),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${place.category.displayName} · ${place.address}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      place.hasRating
                          ? '${place.ratingLabel} (${place.reviewCountLabel})'
                          : 'Rating unavailable',
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on, color: AppTheme.secondary, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '${place.distanceKm.toStringAsFixed(1)} km',
                      style: AppTypography.caption.copyWith(color: AppTheme.secondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
