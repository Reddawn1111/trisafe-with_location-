import 'dart:convert';
import 'dart:io';

import '../models/activity_insights.dart';

abstract class ActivityRepository {
  Future<TravelInsightsConsentState> loadConsentState();
  Future<void> saveConsentState(TravelInsightsConsentState state);
  Future<List<LocationSample>> loadLocationSamples();
  Future<void> appendLocationSample(LocationSample sample);
  Future<List<ActivityEvent>> loadActivityEvents();
  Future<void> appendActivityEvent(ActivityEvent event);
  Future<void> clearActivityData();
  Future<void> clearConsentState();
  Future<Map<String, dynamic>> exportStore();
}

class LocalJsonActivityRepository implements ActivityRepository {
  LocalJsonActivityRepository._internal();

  static final LocalJsonActivityRepository instance =
      LocalJsonActivityRepository._internal();

  static const int _maxLocationSamples = 240;
  static const int _maxActivityEvents = 120;
  static final Duration _retentionWindow = const Duration(days: 14);

  Map<String, dynamic>? _cache;

  Future<File> _storeFile() async {
    final directory = Directory.systemTemp;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}${Platform.pathSeparator}tripsafe_activity_store.json');
  }

  Future<Map<String, dynamic>> _readStore() async {
    if (_cache != null) {
      return _cache!;
    }

    final file = await _storeFile();
    if (!await file.exists()) {
      _cache = _emptyStore();
      await _writeStore(_cache!);
      return _cache!;
    }

    try {
      final raw = await file.readAsString();
      final decoded = Map<String, dynamic>.from(
        jsonDecode(raw) as Map<dynamic, dynamic>,
      );
      _cache = decoded;
      _pruneExpiredData(_cache!);
      return _cache!;
    } catch (_) {
      _cache = _emptyStore();
      await _writeStore(_cache!);
      return _cache!;
    }
  }

  Future<void> _writeStore(Map<String, dynamic> store) async {
    _cache = store;
    final file = await _storeFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(store),
      flush: true,
    );
  }

  Map<String, dynamic> _emptyStore() {
    return {
      'consent': const TravelInsightsConsentState().toJson(),
      'locationSamples': <Map<String, dynamic>>[],
      'activityEvents': <Map<String, dynamic>>[],
    };
  }

  void _pruneExpiredData(Map<String, dynamic> store) {
    final cutoff = DateTime.now().subtract(_retentionWindow);

    List<Map<String, dynamic>> pruneList(
      String key,
      ActivityTimeReader readTime,
      int maxCount,
    ) {
      final raw = (store[key] as List<dynamic>? ?? <dynamic>[])
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList();

      final kept = raw.where((entry) => readTime(entry).isAfter(cutoff)).toList()
        ..sort(
          (a, b) => readTime(a).compareTo(readTime(b)),
        );

      if (kept.length > maxCount) {
        return kept.sublist(kept.length - maxCount);
      }
      return kept;
    }

    store['locationSamples'] = pruneList(
      'locationSamples',
      (entry) => DateTime.parse(entry['timestamp'] as String),
      _maxLocationSamples,
    );
    store['activityEvents'] = pruneList(
      'activityEvents',
      (entry) => DateTime.parse(entry['timestamp'] as String),
      _maxActivityEvents,
    );
  }

  @override
  Future<TravelInsightsConsentState> loadConsentState() async {
    final store = await _readStore();
    return TravelInsightsConsentState.fromJson(
      Map<String, dynamic>.from(
        store['consent'] as Map? ?? <String, dynamic>{},
      ),
    );
  }

  @override
  Future<void> saveConsentState(TravelInsightsConsentState state) async {
    final store = await _readStore();
    store['consent'] = state.toJson();
    await _writeStore(store);
  }

  @override
  Future<List<LocationSample>> loadLocationSamples() async {
    final store = await _readStore();
    final raw = (store['locationSamples'] as List<dynamic>? ?? <dynamic>[])
        .map((entry) => Map<String, dynamic>.from(entry as Map));
    return raw.map(LocationSample.fromJson).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Future<void> appendLocationSample(LocationSample sample) async {
    final store = await _readStore();
    final items = (store['locationSamples'] as List<dynamic>? ?? <dynamic>[])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
    items.add(sample.toJson());
    store['locationSamples'] = items;
    _pruneExpiredData(store);
    await _writeStore(store);
  }

  @override
  Future<List<ActivityEvent>> loadActivityEvents() async {
    final store = await _readStore();
    final raw = (store['activityEvents'] as List<dynamic>? ?? <dynamic>[])
        .map((entry) => Map<String, dynamic>.from(entry as Map));
    return raw.map(ActivityEvent.fromJson).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Future<void> appendActivityEvent(ActivityEvent event) async {
    final store = await _readStore();
    final items = (store['activityEvents'] as List<dynamic>? ?? <dynamic>[])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
    items.add(event.toJson());
    store['activityEvents'] = items;
    _pruneExpiredData(store);
    await _writeStore(store);
  }

  @override
  Future<void> clearActivityData() async {
    final store = await _readStore();
    store['locationSamples'] = <Map<String, dynamic>>[];
    store['activityEvents'] = <Map<String, dynamic>>[];
    await _writeStore(store);
  }

  @override
  Future<void> clearConsentState() async {
    final store = await _readStore();
    store['consent'] = const TravelInsightsConsentState().toJson();
    await _writeStore(store);
  }

  @override
  Future<Map<String, dynamic>> exportStore() async {
    final store = await _readStore();
    return {
      'consent': Map<String, dynamic>.from(
        store['consent'] as Map? ?? <String, dynamic>{},
      ),
      'locationSamples': List<Map<String, dynamic>>.from(
        (store['locationSamples'] as List<dynamic>? ?? <dynamic>[])
            .map((entry) => Map<String, dynamic>.from(entry as Map)),
      ),
      'activityEvents': List<Map<String, dynamic>>.from(
        (store['activityEvents'] as List<dynamic>? ?? <dynamic>[])
            .map((entry) => Map<String, dynamic>.from(entry as Map)),
      ),
    };
  }
}

typedef ActivityTimeReader = DateTime Function(Map<String, dynamic> entry);
