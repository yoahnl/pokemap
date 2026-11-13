import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/map_workspace/coordination/map_layout_preferences.dart';
import '../../features/rendering/coordination/studio_rendering_preferences.dart';

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
