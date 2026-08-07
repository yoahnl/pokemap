import 'dart:io';

import 'package:pokemap_hub/platform/android_hub_platform_adapter.dart';
import 'package:pokemap_hub/core/ports/hub_platform_port.dart';
import 'package:pokemap_hub/platform/ios_hub_platform_adapter.dart';
import 'package:pokemap_hub/platform/macos_hub_platform_adapter.dart';

HubPlatformAdapter createHubPlatformAdapter() {
  if (Platform.isAndroid) return AndroidHubPlatformAdapter();
  if (Platform.isMacOS) return MacOSHubPlatformAdapter();
  if (Platform.isIOS) return IOSHubPlatformAdapter();
  throw UnsupportedError(
    'PokeMap Hub is not configured for ${Platform.operatingSystem}.',
  );
}
