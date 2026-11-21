import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/studio_ai_preferences.dart';
import '../../features/settings/studio_appearance_preferences.dart';

final studioAppearanceStoreProvider = Provider<StudioAppearanceStore>(
  (ref) => MemoryStudioAppearanceStore(),
);

final studioAppearancePreferencesProvider =
    Provider<StudioAppearancePreferences>((ref) {
      final preferences = StudioAppearancePreferences(
        ref.watch(studioAppearanceStoreProvider),
      );
      unawaited(preferences.load());
      ref.onDispose(preferences.dispose);
      return preferences;
    });

final studioAiKeyStoreProvider = Provider<StudioAiKeyStore>(
  (ref) => throw StateError('Studio secure key storage is not configured.'),
);

final studioAiConnectionProvider = Provider<StudioAiConnection>(
  (ref) => throw StateError('Studio AI connection is not configured.'),
);
