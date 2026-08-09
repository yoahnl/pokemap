import 'dart:async';

import 'package:map_player_ui/map_player_ui.dart' as player_ui;
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/features/session/application/services/hub_title_presentation_loader.dart';

Future<player_ui.PokeMapPlayerTypography> loadPlayerTypography(
  HubLoadedTitlePresentation presentation,
) async {
  final typography = presentation.typography;
  if (typography == null) {
    return const player_ui.PokeMapPlayerTypography();
  }
  final loaded = await const RuntimeProjectTypographyLoader()
      .load(<ProjectTypographyRole, RuntimeProjectFontRequest>{
        for (final entry in typography.roles.entries)
          entry.key: RuntimeProjectFontRequest(
            file: entry.value.file,
            family: entry.value.family,
            fallbackFamilies: entry.value.fallbackFamilies,
          ),
      });
  RuntimeLoadedFontRole role(
    ProjectTypographyRole role,
    List<String> fallback,
  ) =>
      loaded.roles[role] ??
      RuntimeLoadedFontRole(registeredFamily: null, fallbackFamilies: fallback);

  final display = role(ProjectTypographyRole.display, const <String>[
    'sans-serif',
  ]);
  final body = role(ProjectTypographyRole.body, const <String>['sans-serif']);
  final dialogue = role(ProjectTypographyRole.dialogue, const <String>[
    'sans-serif',
  ]);
  final numbers = role(ProjectTypographyRole.numbers, const <String>[
    'monospace',
  ]);
  return player_ui.PokeMapPlayerTypography(
    displayFamily: display.registeredFamily,
    displayFallback: display.fallbackFamilies,
    bodyFamily: body.registeredFamily,
    bodyFallback: body.fallbackFamilies,
    dialogueFamily: dialogue.registeredFamily,
    dialogueFallback: dialogue.fallbackFamilies,
    numbersFamily: numbers.registeredFamily,
    numbersFallback: numbers.fallbackFamilies,
  );
}
