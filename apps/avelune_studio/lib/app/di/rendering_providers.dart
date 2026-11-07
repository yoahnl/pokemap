import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/map_workspace/application/map_layout_preferences.dart';
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

final studioMapLayoutPreferencesProvider = Provider<MapLayoutPreferences>((
  ref,
) {
  final preferences = MapLayoutPreferences();
  ref.onDispose(preferences.dispose);
  return preferences;
});
