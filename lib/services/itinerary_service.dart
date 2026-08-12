import 'package:flutter/foundation.dart';
import '../models/place.dart';
import '../models/itinerary_item.dart';

/// Service managing user's trip itinerary items.
/// Provides a clean interface: `addPlaceToItinerary(Place place)`.
class ItineraryService extends ChangeNotifier {
  static final ItineraryService instance = ItineraryService._internal();

  factory ItineraryService() => instance;

  ItineraryService._internal();

  final List<ItineraryItem> _items = [];

  List<ItineraryItem> get items => List.unmodifiable(_items);

  bool isPlaceInItinerary(String placeId) {
    return _items.any((item) => item.place.id == placeId);
  }

  /// Minimal clean interface to add a Place to the trip itinerary.
  bool addPlaceToItinerary(Place place, {String? note}) {
    if (isPlaceInItinerary(place.id)) {
      return false; // Already added
    }

    _items.add(
      ItineraryItem(
        id: 'itin_${DateTime.now().millisecondsSinceEpoch}',
        place: place,
        addedAt: DateTime.now(),
        note: note,
      ),
    );
    notifyListeners();
    return true;
  }

  /// Remove a place from itinerary
  void removePlaceFromItinerary(String placeId) {
    _items.removeWhere((item) => item.place.id == placeId);
    notifyListeners();
  }

  /// Clear all itinerary items
  void clearItinerary() {
    _items.clear();
    notifyListeners();
  }
}
