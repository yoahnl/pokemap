import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'narrative_authoring_exception.dart';

part 'standard_event_template_compiler.dart';

enum StandardEventTemplateKind { conditionalNpc, pickup, lockedDoor, trainer }

final class StandardEventTemplateSpec {
  StandardEventTemplateSpec({
    required this.kind,
    required this.mapId,
    required this.entityId,
    required this.name,
    required Map<String, Object?> parameters,
  }) : parameters = Map.unmodifiable(parameters) {
    for (final value in [mapId, entityId, name]) {
      if (value.trim().isEmpty || value != value.trim()) {
        throw const FormatException(
            'Template identities and name must be trimmed nonblank text.');
      }
    }
    final allowed = parameterFields[kind]!;
    if (parameters.keys.any((key) => !allowed.contains(key))) {
      throw const FormatException('Unknown standard event template parameter.');
    }
    for (final entry in parameters.entries) {
      if (entry.key == 'quantity') {
        if (entry.value is! int ||
            (entry.value as int) < 1 ||
            (entry.value as int) > 9999) {
          throw const FormatException(
              'Pickup quantity must be from 1 to 9999.');
        }
      } else if (entry.value is! String ||
          (entry.value as String).trim().isEmpty ||
          entry.value != (entry.value as String).trim()) {
        throw const FormatException(
            'Template resource references must be trimmed nonblank text.');
      }
    }
    for (final field in requiredParameterFields[kind]!) {
      if (!parameters.containsKey(field)) {
        throw FormatException('Missing template parameter: $field.');
      }
    }
  }

  static const parameterFields = {
    StandardEventTemplateKind.conditionalNpc: {
      'factId',
      'dialogueId',
      'alternateDialogueId',
      'characterId',
      'alternateCharacterId'
    },
    StandardEventTemplateKind.pickup: {
      'itemId',
      'quantity',
      'characterId',
      'dialogueId'
    },
    StandardEventTemplateKind.lockedDoor: {
      'itemId',
      'destinationMapId',
      'destinationWarpId',
      'dialogueId',
      'characterId'
    },
    StandardEventTemplateKind.trainer: {
      'trainerId',
      'dialogueId',
      'alternateDialogueId',
      'characterId'
    },
  };
  static const requiredParameterFields = {
    StandardEventTemplateKind.conditionalNpc: {
      'factId',
      'dialogueId',
      'alternateDialogueId',
      'characterId'
    },
    StandardEventTemplateKind.pickup: {'itemId', 'quantity', 'characterId'},
    StandardEventTemplateKind.lockedDoor: {
      'itemId',
      'destinationMapId',
      'destinationWarpId',
      'dialogueId'
    },
    StandardEventTemplateKind.trainer: {
      'trainerId',
      'dialogueId',
      'alternateDialogueId',
      'characterId'
    },
  };

  factory StandardEventTemplateSpec.fromJson(Map<String, dynamic> json) {
    const fields = {
      'schemaVersion',
      'kind',
      'mapId',
      'entityId',
      'name',
      'parameters'
    };
    if (json.length != fields.length ||
        !json.keys.every(fields.contains) ||
        json['schemaVersion'] != 1 ||
        json['parameters'] is! Map) {
      throw const FormatException(
          'Unsupported standard event template contract.');
    }
    final kind = StandardEventTemplateKind.values
        .where((kind) => kind.name == json['kind'])
        .firstOrNull;
    if (kind == null ||
        json['mapId'] is! String ||
        json['entityId'] is! String ||
        json['name'] is! String) {
      throw const FormatException('Invalid standard event template identity.');
    }
    return StandardEventTemplateSpec(
        kind: kind,
        mapId: json['mapId'] as String,
        entityId: json['entityId'] as String,
        name: json['name'] as String,
        parameters: Map<String, Object?>.from(json['parameters'] as Map));
  }

  final StandardEventTemplateKind kind;
  final String mapId;
  final String entityId;
  final String name;
  final Map<String, Object?> parameters;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'kind': kind.name,
        'mapId': mapId,
        'entityId': entityId,
        'name': name,
        'parameters': parameters
      };

  String text(String field) => parameters[field] as String;
}

final class StandardEventTemplatePage {
  StandardEventTemplatePage(
      {required this.id,
      required this.label,
      required this.condition,
      required List<String> actions,
      required this.appearance})
      : actions = List.unmodifiable(actions);
  final String id;
  final String label;
  final NarrativeEventConditionExpression condition;
  final List<String> actions;
  final MapEntityPresentationVariant appearance;
}

final class StandardEventTemplatePreview {
  StandardEventTemplatePreview(
      {required this.activePageId,
      required this.label,
      required this.reason,
      required List<String> actions,
      required this.visible,
      required this.blocksMovement,
      required this.branch})
      : actions = List.unmodifiable(actions);
  final String? activePageId;
  final String label;
  final String reason;
  final List<String> actions;
  final bool visible;
  final bool blocksMovement;
  final String? branch;
}

final class StandardEventTemplateProjection {
  StandardEventTemplateProjection(
      {required this.spec,
      required this.map,
      required List<SceneAsset> scenes,
      required List<NarrativeEventRecord> events,
      required List<StandardEventTemplatePage> pages})
      : scenes = List.unmodifiable(scenes),
        events = List.unmodifiable(events),
        pages = List.unmodifiable(pages);
  final StandardEventTemplateSpec spec;
  final MapData map;
  final List<SceneAsset> scenes;
  final List<NarrativeEventRecord> events;
  final List<StandardEventTemplatePage> pages;

  StandardEventTemplatePreview preview(
      {required ProjectManifest project, required GameState gameState}) {
    final registry = project.eventRegistry!;
    final ids = events.map((event) => event.id).toSet();
    final projected = project.copyWith(
        eventRegistry: NarrativeEventRegistry(
            schemaVersion: registry.schemaVersion,
            mode: registry.mode,
            records: [
              ...registry.records.where((event) => !ids.contains(event.id)),
              ...events
            ],
            legacyClaims: registry.legacyClaims));
    final entity =
        map.entities.singleWhere((entity) => entity.id == spec.entityId);
    final appearance = resolveMapEntityPresentation(
        project: projected, gameState: gameState, map: map, entity: entity);
    if (appearance == null) {
      return StandardEventTemplatePreview(
          activePageId: null,
          label: 'Aucune page active',
          reason: spec.kind == StandardEventTemplateKind.pickup
              ? 'Objet déjà ramassé : événement consommé.'
              : 'Les conditions des pages ne sont pas satisfaites.',
          actions: [],
          visible: false,
          blocksMovement: false,
          branch: null);
    }
    final page = pages.singleWhere((page) => page.id == appearance.id);
    String? branch;
    var reason = 'Les conditions de cette page sont satisfaites.';
    var actions = page.actions;
    if (spec.kind == StandardEventTemplateKind.lockedDoor) {
      final allowed = evaluateSceneInventoryCondition(
          source: _inventoryCondition(spec.text('itemId')),
          gameState: gameState);
      branch = allowed ? 'unlocked' : 'locked';
      reason = allowed
          ? 'Objet requis présent : passage autorisé.'
          : 'Objet requis absent : passage refusé.';
      actions = [
        allowed
            ? 'Passage vers ${_templateResourceName(project, 'destinationMapId', spec.text('destinationMapId'))}'
            : 'Dialogue ${_templateResourceName(project, 'dialogueId', spec.text('dialogueId'))}'
      ];
    } else if (spec.kind == StandardEventTemplateKind.trainer) {
      final defeated = gameState.storyFlags.activeFlags
          .contains('trainer_defeated:${spec.text('trainerId')}');
      branch = defeated ? 'after' : 'before';
      reason = defeated
          ? 'Dresseur déjà vaincu : dialogue après victoire.'
          : 'Dresseur non vaincu : dialogue puis combat.';
      actions = defeated
          ? [
              'Dialogue ${_templateResourceName(project, 'alternateDialogueId', spec.text('alternateDialogueId'))}'
            ]
          : [
              'Dialogue ${_templateResourceName(project, 'dialogueId', spec.text('dialogueId'))}',
              'Combat ${_templateResourceName(project, 'trainerId', spec.text('trainerId'))}',
              'Victoire : dialogue après ; défaite : nouvelle tentative'
            ];
    }
    return StandardEventTemplatePreview(
        activePageId: page.id,
        label: page.label,
        reason: reason,
        actions: actions,
        visible: true,
        blocksMovement: appearance.blocksMovement,
        branch: branch);
  }
}

const _recipeKey = 'standardEventTemplate.v1';
const _ownerKey = 'standardEventTemplate.owner';
const _sceneGenerationKey = 'standardEventTemplate.sceneGeneration.v1';

Set<String> standardEventTemplateEventIds(StandardEventTemplateSpec spec) => {
      for (final page in spec.kind == StandardEventTemplateKind.conditionalNpc
          ? ['before', 'after']
          : ['main'])
        _standardEventTemplateEventId(spec, page),
    };

String _standardEventTemplateEventId(
    StandardEventTemplateSpec spec, String page) {
  final hex = sha256
      .convert(utf8.encode(jsonEncode(
          ['standardEventTemplate', 1, spec.mapId, spec.entityId, page])))
      .toString();
  return 'evt_${hex.substring(0, 8)}-${hex.substring(8, 12)}-7${hex.substring(13, 16)}-8${hex.substring(17, 20)}-${hex.substring(20, 32)}';
}

Set<String> standardEventTemplateSceneIds(StandardEventTemplateSpec spec,
        {String? generation}) =>
    {
      for (final id in standardEventTemplateEventIds(spec))
        _standardEventTemplateSceneId(id, generation),
    };

String _standardEventTemplateSceneId(String eventId, String? generation) {
  if (generation != null && !RegExp(r'^[0-9a-f]{64}$').hasMatch(generation)) {
    _reject('scene_generation', 'La version des scènes générées est invalide.');
  }
  return 'scene_$eventId${generation == null ? '' : '_${generation.substring(0, 24)}'}';
}

String? standardEventTemplateNextSceneGeneration(StandardEventTemplateSpec spec,
    {StandardEventTemplateSpec? previous, String? previousGeneration}) {
  if (previous == null) return null;
  if (canonicalizeNarrativeEventJson(previous.toJson()) ==
      canonicalizeNarrativeEventJson(spec.toJson())) {
    return previousGeneration;
  }
  return sha256
      .convert(utf8.encode(canonicalizeNarrativeEventJson({
        'generation': previousGeneration,
        'before': previous.toJson(),
        'after': spec.toJson(),
      })))
      .toString();
}

StandardEventTemplateProjection compileStandardEventTemplate({
  required ProjectManifest project,
  required List<MapData> maps,
  required StandardEventTemplateSpec spec,
  ProjectItemCatalog? itemCatalog,
}) {
  final map = _one(maps.where((map) => map.id == spec.mapId), 'map');
  final entity = _one(
      map.entities.where((entity) => entity.id == spec.entityId), 'entity');
  final stored = entity.properties[_recipeKey];
  String? sceneGeneration;
  if (stored != null) {
    final previous = readStandardEventTemplate(
        project: project,
        map: map,
        entityId: entity.id,
        itemCatalog: itemCatalog,
        maps: maps);
    if (previous == null) {
      _reject('advanced_edits',
          'Les détails avancés ont changé ; ouvrez-les pour conserver vos modifications.');
    }
    if (previous.kind != spec.kind) {
      _reject('kind_change',
          'Le type d’un événement existant ne peut pas être remplacé.');
    }
    sceneGeneration = standardEventTemplateNextSceneGeneration(spec,
        previous: previous,
        previousGeneration: entity.properties[_sceneGenerationKey]);
  } else {
    if (entity.presentation != null ||
        entity.item != null ||
        entity.sign != null ||
        entity.spawn != null ||
        entity.fieldObstacle != null ||
        entity.healingDisplay != null ||
        entity.interactiveEncounter != null ||
        entity.size != const GridSize(width: 1, height: 1) ||
        entity.counterInteractionSides.isNotEmpty ||
        entity.npc?.dialogue != null ||
        entity.npc?.trainerId != null ||
        entity.npc?.defeatDialogueRef != null ||
        entity.npc?.visibilityRule != null ||
        (entity.npc?.lineOfSightRange ?? 0) != 0 ||
        entity.npc?.counterInteractionSides.isNotEmpty == true ||
        (entity.npc != null &&
            entity.npc!.movement != const MapEntityNpcMovementConfig()) ||
        entity.npc?.conditionalDialogues.isNotEmpty == true) {
      _reject('entity_configured',
          'Cet élément possède déjà un comportement ; choisissez un élément sans interaction.');
    }
  }
  return _compile(
      project: project,
      maps: maps,
      spec: spec,
      itemCatalog: itemCatalog,
      sceneGeneration: sceneGeneration,
      allowOwned: stored != null);
}

StandardEventTemplateSpec? readStandardEventTemplate(
    {required ProjectManifest project,
    required MapData map,
    required String entityId,
    ProjectItemCatalog? itemCatalog,
    List<MapData>? maps}) {
  try {
    final entity =
        _one(map.entities.where((entity) => entity.id == entityId), 'entity');
    final raw = entity.properties[_recipeKey];
    if (raw == null) return null;
    final spec = StandardEventTemplateSpec.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map));
    if (spec.mapId != map.id || spec.entityId != entityId) return null;
    final rebuilt = _compile(
        project: project,
        maps: maps ?? [map],
        spec: spec,
        itemCatalog: itemCatalog,
        sceneGeneration: entity.properties[_sceneGenerationKey],
        allowOwned: true,
        validateDestination: maps != null);
    final rebuiltEntity =
        rebuilt.map.entities.singleWhere((entity) => entity.id == entityId);
    if (entity != rebuiltEntity) return null;
    for (final scene in rebuilt.scenes) {
      if (project.scenes.where((value) => value.id == scene.id).singleOrNull !=
          scene) {
        return null;
      }
    }
    for (final event in rebuilt.events) {
      if (project.eventRegistry!.records
              .where((value) => value.id == event.id)
              .singleOrNull !=
          event) {
        return null;
      }
    }
    return spec;
  } on Object {
    return null;
  }
}

Never _reject(String code, String message) =>
    throw NarrativeAuthoringException('event_v2.template.$code', message);

T _one<T>(Iterable<T> values, String kind) {
  final list = values.toList();
  if (list.length != 1) {
    _reject(
        'reference_unavailable', 'Une référence $kind est absente ou ambiguë.');
  }
  return list.single;
}

SceneConditionSource _inventoryCondition(String itemId) => SceneConditionSource(
    sourceKind: SceneConditionSourceKind.inventoryItem,
    sourceId: itemId,
    operator: SceneConditionOperator.isTrue);

String _templateResourceName(ProjectManifest project, String field, String id,
    {ProjectItemCatalog? itemCatalog}) {
  final name = switch (field) {
    'dialogueId' ||
    'alternateDialogueId' =>
      project.dialogues.where((value) => value.id == id).firstOrNull?.name,
    'destinationMapId' =>
      project.maps.where((value) => value.id == id).firstOrNull?.name,
    'trainerId' =>
      project.trainers.where((value) => value.id == id).firstOrNull?.name,
    'itemId' => itemCatalog?.entries
        .where((value) => value.id == id)
        .firstOrNull
        ?.displayName,
    _ => null,
  };
  return name?.trim().isNotEmpty == true
      ? name!
      : switch (field) {
          'itemId' => 'l’objet choisi',
          'trainerId' => 'le dresseur choisi',
          'destinationMapId' => 'la carte choisie',
          _ => 'le dialogue choisi',
        };
}
