import 'package:map_core/map_core.dart';

import '../../../contracts/json_contract_support.dart';

final class CharacterStudioResourceSnapshot {
  CharacterStudioResourceSnapshot({
    required Map<String, Object?> summary,
    required Map<String, Object?> detail,
  })  : summary = freezeContractJsonObject(
          summary,
          field: 'characterStudio.summary',
        ),
        detail = freezeContractJsonObject(
          detail,
          field: 'characterStudio.detail',
        );

  final Map<String, Object?> summary;
  final Map<String, Object?> detail;
}

final class CharacterStudioResourceProjection {
  CharacterStudioResourceProjection(
    Map<String, List<CharacterStudioResourceSnapshot>> resources,
  ) : _resources = Map.unmodifiable({
          for (final entry in resources.entries)
            entry.key: List<CharacterStudioResourceSnapshot>.unmodifiable(
              entry.value,
            ),
        });

  final Map<String, List<CharacterStudioResourceSnapshot>> _resources;

  List<CharacterStudioResourceSnapshot>? records(String resourceKind) =>
      _resources[resourceKind];
}

final class CharacterStudioResourceProjector {
  const CharacterStudioResourceProjector();

  CharacterStudioResourceProjection project({
    required ProjectManifest manifest,
    required String workspaceRevision,
    String? selectedCharacterId,
  }) {
    final selectedId = selectedCharacterId?.trim();
    final references = buildCharacterStudioReferenceIndex(manifest);
    final readiness = analyzeCharacterStudioReadiness(
      manifest: manifest,
      requiredCharacterIds: {
        if (selectedId != null && selectedId.isNotEmpty) selectedId,
      },
    );
    final portraitStates = manifest.characterStudioCatalog.portraitStates
        .toList()
      ..sort(_compareDefinitions);
    final customDefinitions =
        manifest.characterStudioCatalog.customAnimationDefinitions.toList()
          ..sort(_compareDefinitions);
    final animationDefinitions = <Map<String, Object?>>[
      ..._systemAnimationDefinitions,
      for (final definition in customDefinitions)
        <String, Object?>{
          ...definition.toJson(),
          'system': false,
        },
    ]..sort((left, right) =>
        (left['id']! as String).compareTo(right['id']! as String));
    final characters = manifest.characters.toList()
      ..sort((left, right) {
        final order = left.sortOrder.compareTo(right.sortOrder);
        return order != 0 ? order : left.id.compareTo(right.id);
      });

    final characterRecords = <CharacterStudioResourceSnapshot>[];
    final readinessRecords = <CharacterStudioResourceSnapshot>[];
    for (final character in characters) {
      final characterReferences = references.referencesTo(
        CharacterStudioReferenceTargetKind.character,
        character.id,
      );
      final diagnostics = readiness.forCharacter(character.id);
      final coverage = _coverage(
        character,
        portraitStates: portraitStates,
        customDefinitions: customDefinitions,
      );
      final isSelected = character.id == selectedId;
      final isDefaultPlayer =
          character.id == manifest.settings.defaultPlayerCharacterId;
      final warningCount = diagnostics
          .where(
            (diagnostic) =>
                diagnostic.severity == CharacterStudioReadinessSeverity.warning,
          )
          .length;
      final errorCount = diagnostics.length - warningCount;
      final summary = <String, Object?>{
        'id': character.id,
        'name': character.name,
        'resourceKind': 'characterStudioCharacter',
        'workspaceRevision': workspaceRevision,
        'sortOrder': character.sortOrder,
        'isSelected': isSelected,
        'isDefaultPlayer': isDefaultPlayer,
        'portraitCoverage': coverage['portraitCoverage'],
        'dependencyCount': characterReferences.length,
        'warningCount': warningCount,
        'errorCount': errorCount,
      };
      characterRecords.add(
        CharacterStudioResourceSnapshot(
          summary: summary,
          detail: <String, Object?>{
            ...summary,
            'tilesetId': character.tilesetId,
            'frameWidth': character.frameWidth,
            'frameHeight': character.frameHeight,
            'tags': character.tags,
            'portraits': [
              for (final portrait in character.portraits) portrait.toJson(),
            ],
            'animations': [
              for (final animation in character.animations) animation.toJson(),
            ],
            'customAnimations': [
              for (final animation in character.customAnimations)
                animation.toJson(),
            ],
            'coverage': coverage,
            'readiness': <String, Object?>{
              'isReady': errorCount == 0,
              'warningCount': warningCount,
              'errorCount': errorCount,
            },
          },
        ),
      );
      final readinessSummary = <String, Object?>{
        'id': character.id,
        'name': character.name,
        'resourceKind': 'characterStudioReadiness',
        'workspaceRevision': workspaceRevision,
        'isSelected': isSelected,
        'isReady': errorCount == 0,
        'warningCount': warningCount,
        'errorCount': errorCount,
      };
      readinessRecords.add(
        CharacterStudioResourceSnapshot(
          summary: readinessSummary,
          detail: <String, Object?>{
            ...readinessSummary,
            'coverage': coverage,
            'diagnostics': [
              for (final diagnostic in diagnostics) _diagnosticJson(diagnostic),
            ],
          },
        ),
      );
    }

    final dependencyRecords = <CharacterStudioResourceSnapshot>[
      for (var index = 0; index < references.references.length; index++)
        _dependencySnapshot(
          references.references[index],
          index: index,
          workspaceRevision: workspaceRevision,
        ),
    ];
    final catalogSummary = <String, Object?>{
      'id': 'catalog',
      'name': 'Character Studio',
      'resourceKind': 'characterStudioCatalog',
      'workspaceRevision': workspaceRevision,
      'characterCount': characters.length,
      'portraitStateCount': portraitStates.length,
      'customAnimationDefinitionCount': customDefinitions.length,
    };
    return CharacterStudioResourceProjection({
      'characterStudioCatalog': <CharacterStudioResourceSnapshot>[
        CharacterStudioResourceSnapshot(
          summary: catalogSummary,
          detail: <String, Object?>{
            ...catalogSummary,
            'portraitStates': [
              for (final state in portraitStates) state.toJson(),
            ],
            'animationDefinitions': animationDefinitions,
          },
        ),
      ],
      'characterStudioCharacter': characterRecords,
      'characterStudioDependency': dependencyRecords,
      'characterStudioReadiness': readinessRecords,
    });
  }
}

const List<Map<String, Object?>> _systemAnimationDefinitions = [
  <String, Object?>{
    'id': 'base',
    'displayName': 'Base',
    'mode': 'directional',
    'sortOrder': 0,
    'system': true,
    'state': 'idle',
  },
  <String, Object?>{
    'id': 'walk',
    'displayName': 'Marche',
    'mode': 'directional',
    'sortOrder': 1,
    'system': true,
    'state': 'walk',
  },
  <String, Object?>{
    'id': 'run',
    'displayName': 'Course',
    'mode': 'directional',
    'sortOrder': 2,
    'system': true,
    'state': 'run',
  },
];

Map<String, Object?> _coverage(
  ProjectCharacterEntry character, {
  required List<CharacterPortraitStateDefinition> portraitStates,
  required List<CharacterCustomAnimationDefinition> customDefinitions,
}) {
  final portraitIds = character.portraits
      .where((portrait) => portrait.assetId.trim().isNotEmpty)
      .map((portrait) => portrait.portraitStateId)
      .toSet();
  final portraitRequired = portraitStates.length;
  final portraitDefined =
      portraitStates.where((state) => portraitIds.contains(state.id)).length;
  int systemCount(CharacterAnimationState state) => character.animations
      .where(
        (animation) => animation.state == state && animation.frames.isNotEmpty,
      )
      .map((animation) => animation.direction)
      .toSet()
      .length;
  final customDefined = customDefinitions.where((definition) {
    return character.customAnimations.any(
      (animation) =>
          animation.definitionId == definition.id &&
          animation.frames.isNotEmpty,
    );
  }).length;
  return <String, Object?>{
    'portraitDefined': portraitDefined,
    'portraitRequired': portraitRequired,
    'portraitCoverage':
        portraitRequired == 0 ? 1.0 : portraitDefined / portraitRequired,
    'baseDefined': systemCount(CharacterAnimationState.idle),
    'baseRequired': EntityFacing.values.length,
    'walkDefined': systemCount(CharacterAnimationState.walk),
    'walkRequired': EntityFacing.values.length,
    'runDefined': systemCount(CharacterAnimationState.run),
    'runRequired': EntityFacing.values.length,
    'customDefined': customDefined,
    'customRequired': customDefinitions.length,
  };
}

Map<String, Object?> _diagnosticJson(
  CharacterStudioReadinessDiagnostic diagnostic,
) {
  return <String, Object?>{
    'code': diagnostic.code.name,
    'severity': diagnostic.severity.name,
    'path': diagnostic.path,
    'message': diagnostic.message,
    if (diagnostic.characterId != null) 'characterId': diagnostic.characterId,
    if (diagnostic.portraitStateId != null)
      'portraitStateId': diagnostic.portraitStateId,
    if (diagnostic.animationDefinitionId != null)
      'animationDefinitionId': diagnostic.animationDefinitionId,
    if (diagnostic.animationState != null)
      'animationState': diagnostic.animationState!.name,
    if (diagnostic.direction != null) 'direction': diagnostic.direction!.name,
  };
}

CharacterStudioResourceSnapshot _dependencySnapshot(
  CharacterStudioReference reference, {
  required int index,
  required String workspaceRevision,
}) {
  final id = 'dependency-${index.toString().padLeft(4, '0')}';
  final detail = <String, Object?>{
    'id': id,
    'name': '${reference.sourceKind.name}:${reference.sourceId}',
    'resourceKind': 'characterStudioDependency',
    'workspaceRevision': workspaceRevision,
    'targetKind': reference.targetKind.name,
    'targetId': reference.targetId,
    'sourceKind': reference.sourceKind.name,
    'sourceId': reference.sourceId,
    'path': reference.path,
  };
  return CharacterStudioResourceSnapshot(summary: detail, detail: detail);
}

int _compareDefinitions(Object left, Object right) {
  final leftOrder = switch (left) {
    CharacterPortraitStateDefinition() => left.sortOrder,
    CharacterCustomAnimationDefinition() => left.sortOrder,
    _ => throw ArgumentError.value(left, 'definition'),
  };
  final rightOrder = switch (right) {
    CharacterPortraitStateDefinition() => right.sortOrder,
    CharacterCustomAnimationDefinition() => right.sortOrder,
    _ => throw ArgumentError.value(right, 'definition'),
  };
  final order = leftOrder.compareTo(rightOrder);
  if (order != 0) return order;
  final leftId = switch (left) {
    CharacterPortraitStateDefinition() => left.id,
    CharacterCustomAnimationDefinition() => left.id,
    _ => '',
  };
  final rightId = switch (right) {
    CharacterPortraitStateDefinition() => right.id,
    CharacterCustomAnimationDefinition() => right.id,
    _ => '',
  };
  return leftId.compareTo(rightId);
}
