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
    required String? Function(String dialogueId) dialogueSourceText,
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
    final contexts = <PresentationPreviewContextResourceSnapshot>[
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
          sourceText: dialogueSourceText(dialogue.id),
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
    for (final dialogue in manifest.dialogues) {
      contexts.addAll(
        _dialogueScenarioContexts(
          dialogue,
          sourceText: dialogueSourceText(dialogue.id),
          manifest: manifest,
          workspaceRevision: workspaceRevision,
          portraitAssetPath: portraitAssetPath,
        ),
      );
    }
    return contexts;
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
  required String? sourceText,
}) {
  final diagnostics = <String>[
    if (sourceText == null) 'previewContext.dialogueSourceUnavailable',
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
      'sourceAvailable': sourceText != null,
    },
  );
}

List<PresentationPreviewContextResourceSnapshot> _dialogueScenarioContexts(
  ProjectDialogueEntry dialogue, {
  required String? sourceText,
  required ProjectManifest manifest,
  required String workspaceRevision,
  required String? Function(String assetId) portraitAssetPath,
}) {
  if (sourceText == null) {
    return const <PresentationPreviewContextResourceSnapshot>[];
  }
  RuntimeDialogueDocument document;
  try {
    document = const YarnDialogueCompiler().compile(sourceText);
  } on Object {
    return const <PresentationPreviewContextResourceSnapshot>[];
  }
  final characters = <String, ProjectCharacterEntry>{
    for (final character in manifest.characters) character.id: character,
  };
  final portraitStates = <String, String>{
    for (final state in manifest.characterStudioCatalog.portraitStates)
      state.id: state.displayName,
  };
  final contexts = <PresentationPreviewContextResourceSnapshot>[];
  for (var nodeIndex = 0; nodeIndex < document.nodes.length; nodeIndex++) {
    final node = document.nodes[nodeIndex];
    for (var stepIndex = 0; stepIndex < node.steps.length; stepIndex++) {
      final step = node.steps[stepIndex];
      switch (step) {
        case RuntimeDialogueLine():
          contexts.add(
            _dialogueLineScenario(
              dialogue,
              node: node,
              nodeIndex: nodeIndex,
              stepIndex: stepIndex,
              line: step,
              characters: characters,
              portraitStates: portraitStates,
              portraitAssetPath: portraitAssetPath,
              workspaceRevision: workspaceRevision,
            ),
          );
        case RuntimeDialogueChoiceBlock():
          contexts.add(
            _snapshot(
              id: 'dialogueScenario:${dialogue.id}:$nodeIndex:$stepIndex',
              name: '${dialogue.name} · ${node.title} · Choix',
              contextKind: 'dialogueScenario',
              sourceId: dialogue.id,
              workspaceRevision: workspaceRevision,
              diagnostics: const <String>[],
              detail: <String, Object?>{
                'dialogueId': dialogue.id,
                'nodeTitle': node.title,
                'stepIndex': stepIndex,
                'scenarioKind': 'choice',
                'choices': <Object?>[
                  for (final choice in step.choices)
                    <String, Object?>{
                      'label': choice.text,
                      if (choice.outcomeId != null)
                        'outcomeId': choice.outcomeId,
                    },
                ],
              },
            ),
          );
        case RuntimeDialogueJump():
          break;
      }
    }
  }
  return contexts;
}

PresentationPreviewContextResourceSnapshot _dialogueLineScenario(
  ProjectDialogueEntry dialogue, {
  required RuntimeDialogueNode node,
  required int nodeIndex,
  required int stepIndex,
  required RuntimeDialogueLine line,
  required Map<String, ProjectCharacterEntry> characters,
  required Map<String, String> portraitStates,
  required String? Function(String assetId) portraitAssetPath,
  required String workspaceRevision,
}) {
  final characterId = line.characterId;
  final portraitStateId = line.portraitStateId;
  final character = characterId == null ? null : characters[characterId];
  final portrait = character == null || portraitStateId == null
      ? null
      : character.portraits
          .where((candidate) => candidate.portraitStateId == portraitStateId)
          .firstOrNull;
  final portraitPath =
      portrait == null ? null : portraitAssetPath(portrait.assetId);
  final diagnostics = <String>[
    if (characterId != null && character == null)
      'previewContext.dialogueCharacterUnknown',
    if (portraitStateId != null && !portraitStates.containsKey(portraitStateId))
      'previewContext.dialoguePortraitStateUnknown',
    if (character != null && portraitStateId != null && portrait == null)
      'previewContext.dialoguePortraitUnassigned',
    if (portrait != null && portraitPath == null)
      'previewContext.dialoguePortraitAssetUnavailable',
  ];
  final scenarioKind = characterId == null ? 'textLine' : 'characterLine';
  final speaker = character?.name ?? characterId;
  return _snapshot(
    id: 'dialogueScenario:${dialogue.id}:$nodeIndex:$stepIndex',
    name: '${dialogue.name} · ${node.title} · '
        '${speaker ?? 'Texte'}',
    contextKind: 'dialogueScenario',
    sourceId: dialogue.id,
    workspaceRevision: workspaceRevision,
    diagnostics: diagnostics,
    detail: <String, Object?>{
      'dialogueId': dialogue.id,
      'nodeTitle': node.title,
      'stepIndex': stepIndex,
      'scenarioKind': scenarioKind,
      'text': line.text,
      if (characterId != null) 'characterId': characterId,
      if (character != null) 'characterName': character.name,
      if (portraitStateId != null) 'portraitStateId': portraitStateId,
      if (portraitStateId != null && portraitStates[portraitStateId] != null)
        'portraitStateLabel': portraitStates[portraitStateId],
      if (portrait != null) 'portraitAssetId': portrait.assetId,
      if (portrait != null) 'portraitFitMode': portrait.fitMode.name,
      if (portraitPath != null) 'portraitPath': portraitPath,
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
