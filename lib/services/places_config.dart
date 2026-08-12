/// Configuration for Google Places API and discovery provider.
abstract class PlacesConfig {
  PlacesConfig._();

  /// Google Places API Key.
  /// Replace with your active Google Cloud Places API Key for live API data.
  /// If set to empty or invalid, the app gracefully uses the fallback mock provider.
  static String googlePlacesApiKey = '';

  /// Default search radius in meters (5 km as required by prompt)
  static const double defaultRadiusMeters = 5000.0;

  /// Max places to fetch per request
  static const int maxResultCount = 20;

  /// Field mask requested from Google Places API (New) to control cost & payload size.
  static const String googlePlacesFieldMask = 
      'places.id,'
      'places.displayName,'
      'places.location,'
      'places.formattedAddress,'
      'places.rating,'
      'places.userRatingCount,'
      'places.priceLevel,'
      'places.types,'
      'places.photos';
}
