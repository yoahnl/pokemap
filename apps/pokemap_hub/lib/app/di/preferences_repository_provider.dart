import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pokemap_hub/app/di/infrastructure_providers.dart';
import 'package:pokemap_hub/features/preferences/data/repositories/hub_preferences_repository_impl.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';

/// Infrastructure wiring for player preferences.
final playerPreferencesRepositoryProvider =
    FutureProvider<PlayerPreferencesRepositoryInterface>((ref) async {
  return HubPreferencesStore(
    supportRoot: await ref.watch(supportRootProvider.future),
  );
});
