import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/json_contract_support.dart';

final class PresentationPreviewContextResourceSnapshot {
  PresentationPreviewContextResourceSnapshot({
    required Map<String, Object?> summary,
    required Map<String, Object?> detail,
  })  : summary = freezeContractJsonObject(
          summary,
          field: 'presentationPreviewContext.summary',
        ),
        detail = freezeContractJsonObject(
          detail,
          field: 'presentationPreviewContext.detail',
        );

  final Map<String, Object?> summary;
  final Map<String, Object?> detail;
}

final class PresentationPreviewContextProjector {
  const PresentationPreviewContextProjector();

  List<PresentationPreviewContextResourceSnapshot> project({
    required ProjectManifest manifest,
    required String workspaceRevision,
    required Iterable<MapData> maps,
    required bool Function(String dialogueId) dialogueSourceAvailable,
    required String? Function(String assetId) portraitAssetPath,
  }) {
    final loadedMaps = <String, MapData>{
      for (final map in maps) map.id: map,
    };
    final portraitStateLabels = <String, String>{
      for (final state in manifest.characterStudioCatalog.portraitStates)
        state.id: state.displayName,
    };
    final playerPokemon = manifest.newGame.initialParty.firstOrNull ??
        manifest.newGame.starterOptions.firstOrNull?.pokemon;
    return <PresentationPreviewContextResourceSnapshot>[
      for (final entry in manifest.maps)
        _mapContext(
          entry,
          loadedMaps[entry.id],
          workspaceRevision: workspaceRevision,
        ),
      for (final dialogue in manifest.dialogues)
        _dialogueContext(
          dialogue,
          workspaceRevision: workspaceRevision,
          sourceAvailable: dialogueSourceAvailable(dialogue.id),
        ),
      for (final character in manifest.characters)
        for (final portrait in character.portraits)
          _portraitContext(
            character,
            portrait,
            workspaceRevision: workspaceRevision,
            stateLabel: portraitStateLabels[portrait.portraitStateId],
            assetPath: portraitAssetPath(portrait.assetId),
          ),
      for (final table in manifest.encounterTables)
        _encounterContext(
          table,
          workspaceRevision: workspaceRevision,
          playerPokemon: playerPokemon,
        ),
    ];
  }
}

PresentationPreviewContextResourceSnapshot _mapContext(
  ProjectMapEntry entry,
  MapData? map, {
  required String workspaceRevision,
}) {
  final diagnostics = <String>[
    if (map == null) 'previewContext.mapSourceUnavailable',
  ];
  return _snapshot(
    id: 'map:${entry.id}',
    name: entry.name,
    contextKind: 'map',
    sourceId: entry.id,
    workspaceRevision: workspaceRevision,
    diagnostics: diagnostics,
    detail: <String, Object?>{
      'mapId': entry.id,
      'relativePath': entry.relativePath,
      if (map != null)
        'map': jsonDecode(jsonEncode(map.toJson())) as Map<String, dynamic>,
    },
  );
}

PresentationPreviewContextResourceSnapshot _dialogueContext(
  ProjectDialogueEntry dialogue, {
  required String workspaceRevision,
  required bool sourceAvailable,
}) {
  final diagnostics = <String>[
    if (!sourceAvailable) 'previewContext.dialogueSourceUnavailable',
  ];
  return _snapshot(
    id: 'dialogue:${dialogue.id}',
    name: dialogue.name,
    contextKind: 'dialogue',
    sourceId: dialogue.id,
    workspaceRevision: workspaceRevision,
    diagnostics: diagnostics,
    detail: <String, Object?>{
      'dialogueId': dialogue.id,
      'relativePath': dialogue.relativePath,
      'defaultStartNode': dialogue.defaultStartNode,
      'sourceAvailable': sourceAvailable,
    },
  );
}

PresentationPreviewContextResourceSnapshot _portraitContext(
  ProjectCharacterEntry character,
  CharacterPortraitVariant portrait, {
  required String workspaceRevision,
  required String? stateLabel,
  required String? assetPath,
}) {
  final diagnostics = <String>[
    if (stateLabel == null) 'previewContext.portraitStateUnknown',
    if (assetPath == null) 'previewContext.portraitAssetUnavailable',
  ];
  final label = stateLabel ?? portrait.portraitStateId;
  return _snapshot(
    id: 'characterPortrait:${character.id}:${portrait.portraitStateId}',
    name: '${character.name} · $label',
    contextKind: 'characterPortrait',
    sourceId: character.id,
    workspaceRevision: workspaceRevision,
    diagnostics: diagnostics,
    detail: <String, Object?>{
      'characterId': character.id,
      'characterName': character.name,
      'portraitStateId': portrait.portraitStateId,
      'portraitStateLabel': label,
      'portraitAssetId': portrait.assetId,
      if (assetPath != null) 'portraitPath': assetPath,
      'portraitFitMode': portrait.fitMode.name,
    },
  );
}

PresentationPreviewContextResourceSnapshot _encounterContext(
  ProjectEncounterTable table, {
  required String workspaceRevision,
  required PlayerPokemon? playerPokemon,
}) {
  final diagnostics = <String>[
    if (table.entries.isEmpty) 'previewContext.encounterTableEmpty',
    if (playerPokemon == null) 'previewContext.playerPokemonUnavailable',
  ];
  return _snapshot(
    id: 'encounter:${table.id}',
    name: table.name,
    contextKind: 'encounter',
    sourceId: table.id,
    workspaceRevision: workspaceRevision,
    diagnostics: diagnostics,
    detail: <String, Object?>{
      'encounterTableId': table.id,
      'encounterKind': table.encounterKind.name,
      'entries': <Object?>[
        for (final entry in table.entries) entry.toJson(),
      ],
      if (playerPokemon != null) 'playerPokemon': playerPokemon.toJson(),
    },
  );
}

PresentationPreviewContextResourceSnapshot _snapshot({
  required String id,
  required String name,
  required String contextKind,
  required String sourceId,
  required String workspaceRevision,
  required List<String> diagnostics,
  required Map<String, Object?> detail,
}) {
  final summary = <String, Object?>{
    'id': id,
    'name': name,
    'resourceKind': 'presentationPreviewContext',
    'contextKind': contextKind,
    'sourceId': sourceId,
    'workspaceRevision': workspaceRevision,
    'availability': diagnostics.isEmpty ? 'ready' : 'degraded',
    'diagnosticCodes': diagnostics,
  };
  return PresentationPreviewContextResourceSnapshot(
    summary: summary,
    detail: <String, Object?>{...summary, ...detail},
  );
}
