import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/language/coordination/studio_language_preferences.dart';

final studioLanguagePreferencesProvider = Provider<StudioLanguagePreferences>((
  ref,
) {
  final preferences = StudioLanguagePreferences(MemoryStudioLanguageStore());
  ref.onDispose(preferences.dispose);
  return preferences;
});
