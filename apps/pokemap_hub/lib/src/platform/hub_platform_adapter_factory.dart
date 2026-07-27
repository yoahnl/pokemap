import 'dart:io';

import 'android_hub_platform_adapter.dart';
import 'hub_platform_adapter.dart';
import 'ios_hub_platform_adapter.dart';
import 'macos_hub_platform_adapter.dart';

HubPlatformAdapter createHubPlatformAdapter() {
  if (Platform.isAndroid) return AndroidHubPlatformAdapter();
  if (Platform.isMacOS) return MacOSHubPlatformAdapter();
  if (Platform.isIOS) return IOSHubPlatformAdapter();
  throw UnsupportedError(
    'PokeMap Hub is not configured for ${Platform.operatingSystem}.',
  );
}
