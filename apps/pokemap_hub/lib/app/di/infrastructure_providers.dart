import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_distribution/map_distribution.dart';

import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/core/ports/clock_port.dart';
import 'package:pokemap_hub/core/ports/hub_platform_port.dart';
import 'package:pokemap_hub/core/ports/support_root_port.dart';
import 'package:pokemap_hub/platform/hub_platform_adapter_factory.dart';
import 'package:pokemap_hub/platform/path_provider_support_root_adapter.dart';

/// Cross-cutting infrastructure. Nothing here belongs to a single feature.

final supportRootPortProvider = Provider<SupportRootPort>(
  (ref) => const PathProviderSupportRootAdapter(),
);

/// The Hub's writable root, resolved once and created if missing.
///
/// Tests override this with a temporary directory, which is what makes the
/// whole repository graph below relocatable.
final supportRootProvider = FutureProvider<Directory>((ref) async {
  final root = await ref.watch(supportRootPortProvider).resolve();
  await root.create(recursive: true);
  return root;
});

final hubPlatformAdapterProvider = Provider<HubPlatformAdapter>((ref) {
  final adapter = createHubPlatformAdapter();
  ref.onDispose(adapter.dispose);
  return adapter;
});

final hostCompatibilityProvider = Provider<GamePackageHostCompatibility>(
  (ref) => aveluneHostCompatibility(),
);

final clockProvider = Provider<ClockPort>((ref) => const SystemClock());
