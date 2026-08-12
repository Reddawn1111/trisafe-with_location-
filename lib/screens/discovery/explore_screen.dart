import 'package:flutter/material.dart';
import '../../models/place.dart';
import '../../models/place_category.dart';
import '../../services/location_service.dart';
import '../../services/nearby_discovery_service.dart';
import '../../services/recommendation_service.dart';
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
  final NearbyDiscoveryService _discoveryService = GooglePlacesNearbyService();
  final RecommendationService _recommendationService = RecommendationService();

  LocationAddress? _currentAddress;
  List<Place> _allNearbyPlaces = [];
  List<Place> _rankedPlaces = [];

  UserIntent _selectedIntent = UserIntent.all;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLocationAndPlaces();
  }

  Future<void> _loadLocationAndPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Obtain current GPS location & reverse geocoded address using existing LocationService
      final address = await _locationService.getCurrentLocationAddress();
      _currentAddress = address;

      // 2. Discover nearby places using Places Discovery Service abstraction
      final rawPlaces = await _discoveryService.getNearbyPlaces(
        latitude: address.latitude,
        longitude: address.longitude,
        radiusMeters: 5000, // 5 km radius
      );

      _allNearbyPlaces = rawPlaces;

      // 3. Rank places using Recommendation Engine
      _applyRecommendationFilter();
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
    if (_currentAddress == null) {
      setState(() => _isLoading = false);
      return;
    }

    final ranked = _recommendationService.rankPlaces(
      places: List.from(_allNearbyPlaces),
      userLatitude: _currentAddress!.latitude,
      userLongitude: _currentAddress!.longitude,
      selectedIntent: _selectedIntent,
      searchRadiusKm: 5.0,
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLocationAndPlaces,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
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
                      Text('Discovering interesting places nearby...'),
                    ],
                  ),
                ),
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
                  // 1. Recommended for You (Top carousel/cards)
                  _buildSectionHeader('⭐ Recommended For You', 'Scored by rating, popularity & distance'),
                  _buildRecommendedCarousel(),

                  const SizedBox(height: AppSpacing.lg),

                  // 2. Popular Nearby
                  _buildSectionHeader('🔥 Popular Nearby', 'High review count & traveler activity'),
                  ..._buildPopularList(),

                  const SizedBox(height: AppSpacing.lg),

                  // 3. Closest Options
                  _buildSectionHeader('📍 Closest Options', 'Shortest distance from current location'),
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
    // Sort by review count
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
    // Sort by distance
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
            label: 'Grant Permission / Retry',
            icon: Icons.refresh,
            onPressed: _loadLocationAndPlaces,
          ),
        ],
      ),
    );
  }
}

/// Featured Card for "Recommended for You" carousel
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
          // Banner Image or Category Header
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

              // Category Badge
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

              // Recommendation Score Badge
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
                      '${place.rating.toStringAsFixed(1)} (${place.reviewCount})',
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

/// List Tile Card for Popular & Closest Places
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
          // Category Avatar / Image
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

          // Details
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
                      '${place.rating.toStringAsFixed(1)} (${place.reviewCount})',
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
