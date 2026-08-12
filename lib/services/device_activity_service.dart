import 'dart:io';

import '../models/activity_insights.dart';

abstract class DeviceActivityService {
  Future<List<DeviceCapabilityInfo>> getCapabilities();
}

class OfficialDeviceActivityService implements DeviceActivityService {
  OfficialDeviceActivityService._internal();

  static final OfficialDeviceActivityService instance =
      OfficialDeviceActivityService._internal();

  @override
  Future<List<DeviceCapabilityInfo>> getCapabilities() async {
    if (Platform.isAndroid) {
      return const <DeviceCapabilityInfo>[
        DeviceCapabilityInfo(
          id: 'app_usage',
          title: 'App usage duration',
          description:
              'Official Android UsageStats integration is reserved for a later MVP step and is not enabled yet.',
          status: DeviceCapabilityStatus.unavailable,
        ),
        DeviceCapabilityInfo(
          id: 'camera_usage',
          title: 'Camera activity duration',
          description:
              'Camera usage correlation is not enabled in this prototype. No camera frames or photos are collected.',
          status: DeviceCapabilityStatus.unavailable,
        ),
        DeviceCapabilityInfo(
          id: 'media_usage',
          title: 'Media app session duration',
          description:
              'Coarse media session tracking is not enabled in this prototype.',
          status: DeviceCapabilityStatus.unavailable,
        ),
      ];
    }

    return const <DeviceCapabilityInfo>[
      DeviceCapabilityInfo(
        id: 'app_usage',
        title: 'App usage duration',
        description:
            'Not supported on this platform in the current prototype.',
        status: DeviceCapabilityStatus.notSupported,
      ),
      DeviceCapabilityInfo(
        id: 'camera_usage',
        title: 'Camera activity duration',
        description:
            'Not supported on this platform in the current prototype.',
        status: DeviceCapabilityStatus.notSupported,
      ),
      DeviceCapabilityInfo(
        id: 'media_usage',
        title: 'Media app session duration',
        description:
            'Not supported on this platform in the current prototype.',
        status: DeviceCapabilityStatus.notSupported,
      ),
    ];
  }
}
