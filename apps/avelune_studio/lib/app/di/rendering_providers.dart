import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/rendering/application/studio_rendering_preferences.dart';

final studioRenderingPreferencesProvider = Provider<StudioRenderingPreferences>(
  (ref) {
    final preferences = StudioRenderingPreferences(
      MemoryRenderingPreferencesStore(),
    );
    ref.onDispose(preferences.dispose);
    return preferences;
  },
);
