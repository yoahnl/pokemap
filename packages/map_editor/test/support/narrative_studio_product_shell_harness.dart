import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/l10n/app_localizations.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart';

Widget hostNarrativeStudioVisualWidget(
  Widget child, {
  Locale locale = const Locale('fr'),
  Size surfaceSize = const Size(1280, 941),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: PokeMapTheme.dark(),
    home: Scaffold(
      body: SizedBox.fromSize(size: surfaceSize, child: child),
    ),
  );
}

NarrativeStudioRouteLocation? resolveNarrativeStudioSearchLocation(
  NarrativeGlobalSearchEntry entry,
) {
  final diagnostic = entry.diagnostic;
  final resolution = diagnostic == null
      ? entry.navigationIntent == null
          ? null
          : resolveNarrativeDependencyNavigationIntent(
              entry.navigationIntent!,
            )
      : resolveNarrativeProjectDiagnostic(diagnostic);
  if (resolution?.kind != NarrativeStudioNavigationResolutionKind.internal) {
    return null;
  }
  return resolution?.location;
}
