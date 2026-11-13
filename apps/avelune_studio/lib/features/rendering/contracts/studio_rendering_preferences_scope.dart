import 'package:flutter/widgets.dart';

import '../coordination/studio_rendering_preferences.dart';

class StudioRenderingPreferencesScope extends InheritedWidget {
  const StudioRenderingPreferencesScope({
    super.key,
    required this.preferences,
    required super.child,
  });

  final StudioRenderingPreferences preferences;

  static StudioRenderingPreferences? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<StudioRenderingPreferencesScope>()
      ?.preferences;

  @override
  bool updateShouldNotify(StudioRenderingPreferencesScope oldWidget) =>
      oldWidget.preferences != preferences;
}
