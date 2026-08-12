/// Configuration for Geoapify Places API and discovery provider.
abstract class PlacesConfig {
  PlacesConfig._();

  /// Geoapify API Key.
  /// Supports String.fromEnvironment('GEOAPIFY_API_KEY') or runtime assignment.
  /// If unconfigured/empty, the app clearly displays an "API Not Configured" state
  /// instead of silently returning mock data.
  static String geoapifyApiKey = const String.fromEnvironment(
    'GEOAPIFY_API_KEY',
    defaultValue: '',
  );

  /// Helper getter to verify if the API key is configured.
  static bool get isConfigured =>
      geoapifyApiKey.isNotEmpty &&
      geoapifyApiKey != 'YOUR_API_KEY' &&
      geoapifyApiKey != 'YOUR_GEOAPIFY_API_KEY';

  /// Default search radius in meters (5 km)
  static const double defaultRadiusMeters = 5000.0;

  /// Max places to fetch per request
  static const int maxResultCount = 50;

  /// Broad travel-relevant Geoapify categories for general nearby discovery.
///
/// Top-level categories are intentionally used here because Geoapify
/// supports them directly and they include all relevant subcategories.
static const String geoapifyTravelCategories =
    'accommodation,'
    'activity,'
    'commercial,'
    'catering,'
    'entertainment,'
    'leisure,'
    'natural,'
    'tourism,'
    'sport,'
    'parking';

  static const List<String> excludedCategoryPrefixes = [
  'healthcare',
  'education',
  'office',
  'service',
  'public_transport',
  'adult',
  'ski',
];
}
