import 'package:flutter/material.dart';
import 'package:location/location.dart';

import '../services/location_service.dart';
import '../services/restaurant_service.dart';
import '../services/recommendation_service.dart';
import '../models/restaurant.dart';

class NearbyRestaurantsScreen extends StatefulWidget {
  const NearbyRestaurantsScreen({super.key});

  @override
  State<NearbyRestaurantsScreen> createState() =>
      _NearbyRestaurantsScreenState();
}

class _NearbyRestaurantsScreenState
    extends State<NearbyRestaurantsScreen> {
  final LocationService _locationService = LocationService();

  // Replace this during development.
  final RestaurantService _restaurantService =
      RestaurantService('YOUR_API_KEY');

  final RecommendationService _recommendationService =
      RecommendationService();

  List<Restaurant> restaurants = [];

  bool loading = false;
  String? error;

  Future<void> findRestaurants() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final LocationData? location =
          await _locationService.getCurrentLocation();

      if (location?.latitude == null ||
          location?.longitude == null) {
        throw Exception('Could not get your location.');
      }

      final lat = location!.latitude!;
      final lng = location.longitude!;

      final results =
          await _restaurantService.getNearbyRestaurants(
        latitude: lat,
        longitude: lng,
        radiusMeters: 5000,
      );

      final ranked =
          _recommendationService.rankRestaurants(
        restaurants: results,
        userLatitude: lat,
        userLongitude: lng,
      );

      setState(() {
        restaurants = ranked;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants Near You'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : findRestaurants,
                icon: const Icon(Icons.location_on),
                label: Text(
                  loading
                      ? 'Finding restaurants...'
                      : 'Find Restaurants Near Me',
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),

            Expanded(
              child: ListView.builder(
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = restaurants[index];

                  return RestaurantCard(
                    restaurant: restaurant,
                    rank: index + 1,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final int rank;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text('$rank'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    restaurant.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              '⭐ ${restaurant.rating.toStringAsFixed(1)} '
              '(${restaurant.reviewCount} reviews)',
            ),

            const SizedBox(height: 4),

            Text(
              '📍 ${restaurant.distanceKm.toStringAsFixed(1)} km away',
            ),

            const SizedBox(height: 8),

            LinearProgressIndicator(
              value: restaurant.recommendationScore,
            ),

            const SizedBox(height: 4),

            Text(
              'Recommended ${(restaurant.recommendationScore * 100).round()}%',
            ),
          ],
        ),
      ),
    );
  }
}