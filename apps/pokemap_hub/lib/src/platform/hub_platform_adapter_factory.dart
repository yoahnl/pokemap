import 'dart:io';

import 'hub_platform_adapter.dart';
import 'ios_hub_platform_adapter.dart';
import 'macos_hub_platform_adapter.dart';

HubPlatformAdapter createHubPlatformAdapter() {
  if (Platform.isMacOS) return MacOSHubPlatformAdapter();
  if (Platform.isIOS) return IOSHubPlatformAdapter();
  throw UnsupportedError(
    'PokeMap Hub is not configured for ${Platform.operatingSystem}.',
  );
}
