import 'dart:async';
import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart' as player_ui;
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/features/session/data/repositories/installed_game_launch_resolver.dart';
import 'package:pokemap_hub/presentation/features/player/state/hub_title_presentation_loader.dart';

/// Resolves the runtime typography and new-game identity a launched title
/// declares. Pulled out of the player page: it is I/O and manifest reading,
/// not widget code.

Future<player_ui.PokeMapPlayerTypography> loadPlayerTypography(
  HubLoadedTitlePresentation presentation,
) async {
  final typography = presentation.typography;
  if (typography == null) {
    return const player_ui.PokeMapPlayerTypography();
  }
  final loaded = await const RuntimeProjectTypographyLoader().load(
    <ProjectTypographyRole, RuntimeProjectFontRequest>{
      for (final entry in typography.roles.entries)
        entry.key: RuntimeProjectFontRequest(
          file: entry.value.file,
          family: entry.value.family,
          fallbackFamilies: entry.value.fallbackFamilies,
        ),
    },
  );
  RuntimeLoadedFontRole role(
    ProjectTypographyRole role,
    List<String> fallback,
  ) =>
      loaded.roles[role] ??
      RuntimeLoadedFontRole(
        registeredFamily: null,
        fallbackFamilies: fallback,
      );

  final display =
      role(ProjectTypographyRole.display, const <String>['sans-serif']);
  final body = role(ProjectTypographyRole.body, const <String>['sans-serif']);
  final dialogue =
      role(ProjectTypographyRole.dialogue, const <String>['sans-serif']);
  final numbers =
      role(ProjectTypographyRole.numbers, const <String>['monospace']);
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

Future<player_ui.PlayerNewGameIdentityPresentation>
    loadNewGameIdentityPresentation(
  InstalledGameLaunchContext launch,
) async {
  final projectFile = await launch.assets.resolveReference(launch.project);
  final decoded = jsonDecode(await projectFile.readAsString());
  if (decoded is! Map) {
    throw const FormatException(
      'The installed project manifest must be a JSON object.',
    );
  }
  final project = ProjectManifest.fromJson(
    Map<String, dynamic>.from(decoded),
  );
  final config = project.newGame;
  final charactersById = <String, ProjectCharacterEntry>{
    for (final character in project.characters) character.id: character,
  };
  final authoredIds = config.playerAvatarCharacterIds;
  final fallbackId = project.settings.defaultPlayerCharacterId?.trim();
  final avatarIds = authoredIds.isNotEmpty
      ? authoredIds
      : fallbackId == null || fallbackId.isEmpty
          ? const <String>[]
          : <String>[fallbackId];
  return player_ui.PlayerNewGameIdentityPresentation(
    defaultName: config.playerName,
    defaultPronounSet: config.playerPronounSet,
    defaultAvatarCharacterId: fallbackId,
    avatarOptions: <player_ui.PlayerNewGameAvatarOption>[
      for (final id in avatarIds)
        if (charactersById[id] case final character?)
          player_ui.PlayerNewGameAvatarOption(
            characterId: character.id,
            label: character.name,
          ),
    ],
  );
}
