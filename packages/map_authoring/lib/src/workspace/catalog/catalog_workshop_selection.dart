import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/authoring_request.dart';
import '../../domains/assets/asset_store.dart';
import '../../domains/assets/project_media_store.dart';
import '../../domains/narrative/dialogue_source_store.dart';
import '../../domains/narrative/dialogue_authoring_service.dart';
import '../../domains/narrative/scene_party_move_catalog.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/plan_store.dart';
import '../../ports/project_file_reader.dart';
import '../../ports/transaction_file_gateway.dart';
import '../project_snapshot.dart';
import '../workspace_handle_store.dart';
import 'catalog_project_reader.dart';
import 'catalog_metadata_documents.dart';
import '../../domains/narrative/standard_event_template.dart';

part 'catalog_gameplay_workshop_selection.dart';
part 'catalog_guided_workshop_selection.dart';
part 'catalog_model_light_selection.dart';
part 'catalog_audio_media_selection.dart';

final class CatalogWorkshopSelection {
  CatalogWorkshopSelection._(
      this.reader, this.snapshot, this.writableSections, this.resourceRevisions,
      {this.metadataDocuments});

  final CatalogProjectReader reader;
  final ProjectSnapshot snapshot;
  final Set<String> writableSections;
  final Map<String, String?> resourceRevisions;
  final CatalogMetadataDocumentSelection? metadataDocuments;

  static const _narrativeFields = {
    'maps',
    'groups',
    'dialogueFolders',
    'dialogues',
    'scripts',
    'scenarios',
    'cinematics',
    'presentationCinematics',
    'cinematicMediaAssets',
    'facts',
    'worldRules',
    'scenes',
    'storylines',
    'trainers',
    'shops',
    'badges',
    'newGame',
    'presentation',
    'pokemon',
    'eventRegistry',
    'cinematicLibraryCatalog',
    'railJourneyCatalog',
    'characterStudioCatalog',
  };

  static bool supports(String action, {Map<String, Object?>? parameters}) =>
      (action == 'model3d.configure' &&
          parameters != null &&
          parameters.containsKey('light') &&
          parameters.keys.every((key) => {'modelId', 'light'}.contains(key))) ||
      action == 'scene.dialogue.audioMedia.import' ||
      action == 'project.battle_audio.update' ||
      _guidedActions.contains(action) ||
      _gameplayActions.contains(action) ||
      const {
        'fact.create',
        'fact.create_batch',
        'fact.update',
        'storyline.upsert',
        'storyline.reorder_chapters',
        'storyline.reorder_steps',
        'scene.upsert',
        'scene.upsert_batch',
        'cinematic.upsert',
        'dialogue.create',
        'dialogue.create_batch',
        'dialogue.update',
        'dialogue.source_update',
        'event_v2.record_upsert',
        'event_v2.record_upsert_batch',
        'event_v2.registry_mode.set',
        'world_rule.create',
        'world_rule.update',
        'world_rule.upsert_batch',
        'regionalMap.region.upsert',
        'regionalMap.poi.upsert',
        'pokemon.documents.write',
        'pokemon.catalog.write',
        'pokemon.species.write',
        'pokemon.learnset.write',
        'pokemon.evolution.write',
        'pokemon.media.write',
        'presentationCinematic.publish',
        'cinematicLibraryEntry.upsert',
        'cinematicLibraryEntry.setArchived',
        'cinematicLibraryEntry.place',
        'cinematicLibraryEntry.reorder',
        'cinematicLibraryAsset.create',
        'cinematicLibraryAsset.duplicate',
        'cinematicLibraryFolder.create',
        'cinematicLibraryFolder.rename',
        'cinematicLibraryFolder.move',
        'cinematicLibraryFolder.reorder'
      }.contains(action) ||
      (const [
            'presentationCinematic.',
            'presentationTrack.',
            'presentationLayer.',
            'presentationTimeline.',
            'presentationClip.',
            'presentationVisualFolder.'
          ].any(action.startsWith) &&
          !action.endsWith('.delete'));

  static Never unsupported(String action, [String? reason]) =>
      throw AuthoringPlanException(
        code: 'catalog.mutation_scope_required',
        message:
            'The action $action requires ${reason ?? 'a proven targeted dependency scope'} before it can edit this catalog.',
        remediation: const [
          'Preserve the draft. Use an explicitly prepared dependency index for reference-sensitive changes.'
        ],
      );

  static Future<CatalogWorkshopSelection> read({
    required CatalogProjectReader reader,
    required ProjectHandle projectHandle,
    required String actionId,
    Map<String, Object?> parameters = const {},
    Map<String, String> readDependencies = const {},
  }) async {
    if (!supports(actionId, parameters: parameters)) unsupported(actionId);
    if (actionId == 'model3d.configure') {
      if (readDependencies.isNotEmpty) {
        unsupported(
            actionId, 'no external dependencies for a light configuration');
      }
      return _readModelLightWorkshop(
          reader: reader, projectHandle: projectHandle, parameters: parameters);
    }
    if (actionId == 'scene.dialogue.audioMedia.import' || actionId == 'project.battle_audio.update') {
      return _readAudioMediaWorkshop(
          actionId: actionId,
          reader: reader,
          projectHandle: projectHandle,
          parameters: parameters,
          readDependencies: readDependencies);
    }
    if (_guidedActions.contains(actionId)) {
      return _readGuidedWorkshop(
          reader: reader,
          projectHandle: projectHandle,
          actionId: actionId,
          parameters: parameters,
          readDependencies: readDependencies);
    }
    if (_gameplayActions.contains(actionId)) {
      return _readGameplayWorkshop(
          reader: reader,
          projectHandle: projectHandle,
          actionId: actionId,
          parameters: parameters,
          readDependencies: readDependencies);
    }
    final fact = actionId.startsWith('fact.');
    final pokemon = actionId.startsWith('pokemon.');
    final regional = actionId.startsWith('regionalMap.');
    final fields = <String>{
      'settings',
      if (actionId.startsWith('dialogue.')) 'newGame',
      if (fact)
        'facts'
      else if (pokemon) ...{
        'pokemon',
        'trainers',
        'partyCompanion'
      } else if (regional) ...{
        'maps',
        'regionalMap'
      } else if (actionId.startsWith('storyline.')) ...{
        'storylines',
        'facts'
      } else if (actionId.startsWith('cinematic.')) ...{
        'cinematics',
        'maps',
        'dialogues',
        'cinematicMediaAssets',
        'cinematicLibraryCatalog',
        'storylines'
      } else if (actionId.startsWith('world_rule.')) ...{
        'worldRules',
        'facts',
        'storylines',
        'eventRegistry',
        'maps',
        'dialogues'
      } else if (actionId == 'dialogue.source_update') ...{
        'dialogues',
        'scenes',
        'facts',
        'cinematicMediaAssets',
        'characterStudioCatalog'
      } else if (actionId.startsWith('presentation') &&
          parameters['link'] == null) ...{
        'presentationCinematics',
        'scenes',
        'cinematicLibraryCatalog',
        'presentationPresets',
        'cinematicMediaAssets',
        'facts',
        'presentation'
      } else
        ..._narrativeFields,
    };
    final writable = <String>{
      if (fact)
        'facts'
      else if (pokemon)
        ...<String>{}
      else if (regional)
        'regionalMap'
      else if (actionId.startsWith('event_v2.'))
        'eventRegistry'
      else if (actionId.startsWith('storyline.'))
        'storylines'
      else if (actionId.startsWith('scene.'))
        'scenes'
      else if (actionId.startsWith('world_rule.'))
        'worldRules'
      else if (actionId.startsWith('dialogue.')) ...{
        'dialogues',
        'scenes'
      } else if (actionId.startsWith('cinematic.')) ...{
        'cinematics',
        'cinematicLibraryCatalog'
      } else ...{
        'cinematics',
        'presentationCinematics',
        'cinematicLibraryCatalog',
        'scenes'
      },
    };
    final selected = await reader.withMetadataFields(fields);
    return selected.read((catalog) async {
      var manifest = catalog.projectMetadata;
      final values = <String, List<int>>{};
      final paths = <String, String>{};
      final revisions = <String, String?>{};
      Future<void> readFile(String path, String identity) async {
        validateProjectRelativePath(path);
        if (revisions.containsKey(path)) return;
        final payload = await reader.store.gateway.captureResourcePayload(path);
        revisions[path] = payload?.resourceRevision;
        if (payload == null) return;
        try {
          values[identity] = await payload.readBytes();
          paths[identity] = path;
        } finally {
          await payload.release();
        }
      }

      for (final entry in readDependencies.entries) {
        if (entry.key == 'project' ||
            entry.value == 'project.json' ||
            entry.value.startsWith('catalog/') ||
            entry.value.startsWith('.pokemap/')) {
          throw const FormatException(
              'catalog.workshop: invalid read dependency');
        }
        await readFile(entry.value, entry.key);
      }
      if (actionId == 'event_v2.registry_mode.set' &&
          manifest.maps.isNotEmpty &&
          (parameters['mode'] == 'v2Only' ||
              manifest.eventRegistry?.mode == EventSystemMode.v2Only)) {
        unsupported(actionId,
            'an indexed legacy map event census for this registry mode transition');
      }
      final candidateValues = <Object?>[
        parameters,
        manifest.settings.toJson(),
        manifest.newGame.toJson(),
      ];
      final projectJson = manifest.toJson();
      for (final field in writable) {
        final value = projectJson[field];
        if (value is List) {
          final ids = _ownedIds(parameters);
          candidateValues.addAll(value
              .where((entry) => entry is Map && ids.contains(entry['id'])));
        } else if (field == 'eventRegistry') {
          final ids = _ownedIds(parameters);
          candidateValues.addAll([
            for (final record in manifest.eventRegistry?.records ??
                const <NarrativeEventRecord>[])
              if (ids.contains(record.id)) record.toJson(),
          ]);
        } else if (value != null) {
          candidateValues.add(value);
        }
      }
      final strings = _referenceIds(candidateValues, const {
        'sceneId',
        'cinematicId',
        'presentationCinematicId',
        'storylineId',
        'dialogueId',
        'trainerId',
        'shopId',
        'factId',
        'worldRuleId'
      });
      strings.addAll(_ownedIds(parameters));
      var previousCount = -1;
      while (previousCount != strings.length) {
        previousCount = strings.length;
        for (final field in const [
          'scenes',
          'cinematics',
          'presentationCinematics',
          'storylines',
          'trainers',
          'shops'
        ]) {
          final value = projectJson[field];
          if (value is! List) continue;
          for (final item in value) {
            if (item is Map && strings.contains(item['id'])) {
              if (!candidateValues.contains(item)) candidateValues.add(item);
              strings.addAll(_referenceIds(item, const {
                'sceneId',
                'cinematicId',
                'presentationCinematicId',
                'storylineId',
                'dialogueId',
                'trainerId',
                'shopId',
                'factId',
                'worldRuleId'
              }));
            }
          }
        }
      }
      if (parameters['source'] is String) {
        final rawEntry = parameters['entry'];
        final entry = rawEntry is Map
            ? ProjectDialogueEntry.fromJson(Map<String, dynamic>.from(rawEntry))
            : manifest.dialogues
                .where((entry) => entry.id == parameters['dialogueId'])
                .firstOrNull;
        if (entry != null) {
          final compiled = const DialogueAuthoringCompiler()
              .compile(entry: entry, source: parameters['source'] as String);
          if (compiled.document != null) {
            candidateValues.add(compiled.document!.toJson());
          }
        }
      }
      if (actionId == 'dialogue.create' ||
          actionId == 'dialogue.create_batch') {
        for (final item in actionId == 'dialogue.create'
            ? [parameters]
            : parameters['dialogues'] is List
                ? parameters['dialogues'] as List
                : const []) {
          if (item is Map && item['entry'] is Map) {
            final entry = ProjectDialogueEntry.fromJson(
                Map<String, dynamic>.from(item['entry'] as Map));
            await readFile(
                entry.relativePath, dialogueSourceResourceIdentity(entry.id));
          }
        }
      }
      if (pokemon) {
        final documents = parameters['documents'];
        for (final raw in documents is List
            ? documents
            : [
                {'actionId': actionId, 'parameters': parameters}
              ]) {
          if (raw is! Map || raw['parameters'] is! Map) continue;
          final p = raw['parameters'] as Map;
          final path = p['relativePath'];
          if (path is! String) continue;
          final document = p['document'];
          final id = document is Map
              ? document['id'] ?? document['speciesId'] ?? document['catalog']
              : null;
          final action = raw['actionId'];
          final identity = action == 'pokemon.species.write' && id is String
              ? pokemonSpeciesResourceIdentity(id)
              : action == 'pokemon.media.write' && id is String
                  ? pokemonMediaResourceIdentity(id)
                  : action == 'pokemon.catalog.write' && id is String
                      ? 'pokemonCatalog:$id'
                      : action == 'pokemon.learnset.write'
                          ? 'pokemonLearnset:$path'
                          : 'pokemonEvolution:$path';
          await readFile(path, identity);
        }
      }
      final maps = <MapData>[];
      if (!fact && !pokemon) {
        for (final entry in manifest.dialogues) {
          if (strings.contains(entry.id)) {
            await readFile(
                entry.relativePath, dialogueSourceResourceIdentity(entry.id));
          }
        }
        final mapIds = _referenceIds(candidateValues, const {
          'mapId',
          'mapIds',
          'destinationMapId',
          'targetMapId',
          'sourceMapId'
        });
        for (final entry in manifest.maps) {
          if (!mapIds.contains(entry.id)) continue;
          await readFile(entry.relativePath, 'map:${entry.id}');
          final bytes = values['map:${entry.id}'];
          if (bytes == null) {
            throw const ProjectSnapshotException('project.map_missing',
                'A map required by this mutation is missing.');
          }
          final map = MapData.fromJson(
              Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map));
          if (map.id != entry.id) {
            throw const FormatException(
                'catalog.workshop: map identity mismatch');
          }
          maps.add(map);
        }
        final roots = <CatalogDefinitionKey>{};
        for (final (kind, keys) in const [
          (
            CatalogDefinitionKind.tileset,
            {'tilesetId', 'assetId', 'iconAssetId'}
          ),
          (
            CatalogDefinitionKind.element,
            {'elementId', 'portraitElementId', 'illustrationElementId'}
          ),
          (
            CatalogDefinitionKind.character,
            {
              'characterId',
              'avatarCharacterId',
              'defaultPlayerCharacterId',
              'playerAvatarCharacterIds'
            }
          ),
          (CatalogDefinitionKind.model3d, {'modelId'}),
        ]) {
          for (final id in _referenceIds(candidateValues, keys)) {
            final key = CatalogDefinitionKey(kind, id);
            if (await catalog.snapshot.indexEntry(key) != null) roots.add(key);
          }
        }
        manifest = await ProjectCatalogSelection(catalog).resolve(roots);
        if (maps.isNotEmpty) {
          final mapReader = await selected.withMetadataFields({
            'maps',
            'groups',
            'newGame',
            'scenes',
            'eventRegistry',
            'cinematics',
            'trainers',
            'scenarios',
            'pokemon',
            'dialogues',
            'encounterTables',
            'scripts',
            'regionalMap',
          });
          await mapReader.read((mapCatalog) async {
            for (final map in maps) {
              final definitions =
                  await ProjectCatalogSelection(mapCatalog).forMap(map);
              MapValidator.validate(map, projectDialogueContext: definitions);
            }
          });
        }
        if (actionId.startsWith('scene.') ||
            actionId.startsWith('presentation') ||
            actionId.startsWith('event_v2.') ||
            regional) {
          await readFile(assetCatalogStorageKey, assetCatalogResourceIdentity);
          await readFile(projectMediaCatalogStorageKey,
              projectMediaCatalogResourceIdentity);
        }
        if (actionId.startsWith('scene.')) {
          final itemPath = manifest.pokemon.catalogFiles['items'];
          if (manifest.pokemon.enabled && itemPath != null) {
            await readFile(itemPath, itemCatalogResourceIdentity);
          }
          final rawScenes = actionId == 'scene.upsert'
              ? [parameters['scene']]
              : parameters['scenes'] is List
                  ? parameters['scenes'] as List
                  : const [];
          final needsMoves = rawScenes
              .whereType<Map>()
              .map((raw) => SceneAsset.fromJson(Map<String, dynamic>.from(raw)))
              .any(sceneNeedsPartyMoveCatalog);
          final movesPath = manifest.pokemon.catalogFiles['moves'];
          if (needsMoves && manifest.pokemon.enabled && movesPath != null) {
            await readFile(movesPath, 'pokemonCatalog:moves');
          }
        }
      }
      final projectBytes = utf8.encode(jsonEncode(manifest.toJson()));
      final projectFingerprint = computeAuthoringBytesFingerprint(projectBytes,
          logicalName: 'project.json');
      values['project'] = projectBytes;
      paths['project'] = 'project.json';
      final resourceFingerprints = <String, String>{
        'project': projectFingerprint
      };
      for (final entry in paths.entries) {
        if (entry.key != 'project') {
          resourceFingerprints[entry.key] = revisions[entry.value]!;
        }
      }
      final revision = fingerprint(selected.revision, revisions);
      final snapshot = ProjectSnapshot(
        materializedCatalogProject: true,
        projectHandle: projectHandle,
        revision: revision,
        manifest: manifest,
        availableProjectSections: fields,
        maps: maps,
        resourceFingerprints: resourceFingerprints,
        resourceStorageKeys: paths,
        resourceBytes: values,
        itemCatalog: values[itemCatalogResourceIdentity] == null
            ? null
            : decodeProjectItemCatalog(Map<String, dynamic>.from(
                jsonDecode(utf8.decode(values[itemCatalogResourceIdentity]!))
                    as Map)),
      );
      final result = CatalogWorkshopSelection._(selected, snapshot,
          Set.unmodifiable(writable), Map.unmodifiable(revisions));
      await result.requireCurrent();
      return result;
    });
  }

  static Set<String> _referenceIds(Object? value, Set<String> keys) {
    final result = <String>{};
    void visit(Object? item) {
      if (item is Map) {
        for (final entry in item.entries) {
          if (keys.contains(entry.key)) {
            if (entry.value is String && (entry.value as String).isNotEmpty) {
              result.add(entry.value as String);
            } else if (entry.value is List) {
              result.addAll((entry.value as List)
                  .whereType<String>()
                  .where((id) => id.isNotEmpty));
            }
          }
          visit(entry.value);
        }
      }
      if (item is List) item.forEach(visit);
    }

    visit(value);
    return result;
  }

  static Set<String> _ownedIds(Map<String, Object?> parameters) => {
        ..._referenceIds(parameters, const {
          'sceneId',
          'cinematicId',
          'dialogueId',
          'storylineId',
          'characterId',
          'folderId'
        }),
        for (final key in const [
          'scene',
          'cinematic',
          'storyline',
          'fact',
          'entry',
          'rule',
          'record'
        ])
          if (parameters[key] case final Map value)
            if (value['id'] case final String id) id,
        for (final key in const ['scenes', 'rules', 'facts', 'records'])
          if (parameters[key] case final List values)
            for (final value in values.whereType<Map>())
              if (value['id'] case final String id) id,
      };

  static String fingerprint(
          String catalogRevision, Map<String, String?> resources) =>
      resources.isEmpty
          ? catalogRevision
          : computeAuthoringJsonFingerprint({
              'catalogRevision': catalogRevision,
              'resources': {
                for (final path in resources.keys.toList()..sort())
                  path: resources[path]
              },
            }, logicalName: 'catalog-workshop-selection.json');

  Future<String> currentRevision() async {
    final descriptor =
        await reader.store.gateway.captureResourcePayload('project.json');
    if (descriptor == null) {
      throw AuthoringPlanException(
          code: 'plan.stale',
          message: 'The project descriptor disappeared before publication.');
    }
    try {
      if (descriptor.byteLength > 4096 ||
          canonicalAuthoringJson(
                  jsonDecode(utf8.decode(await descriptor.readBytes()))) !=
              canonicalAuthoringJson(reader.descriptor)) {
        throw AuthoringPlanException(
            code: 'plan.stale',
            message: 'The project descriptor changed before publication.');
      }
    } finally {
      await descriptor.release();
    }
    final catalogRevision = reader.readOnly
        ? reader.revision
        : 'sha256:${(await reader.store.readHead())!.sha256}';
    final resources = <String, String?>{};
    for (final path in resourceRevisions.keys) {
      resources[path] = await reader.store.gateway.readResourceRevision(path);
    }
    return fingerprint(catalogRevision, resources);
  }

  Future<void> requireCurrent() async {
    if (await currentRevision() != snapshot.revision) {
      throw AuthoringPlanException(
          code: 'plan.stale',
          message: 'The workshop dependencies changed while reading.');
    }
  }

  void requireSafeParameters(AuthoringRequest request) {
    final p = request.parameters;
    if (request.actionId == 'fact.update' && p['fact'] is Map) {
      final fact = NarrativeFactDefinition.fromJson(
          Map<String, dynamic>.from(p['fact'] as Map));
      final before =
          snapshot.manifest.facts.where((f) => f.id == fact.id).firstOrNull;
      if (before != null &&
          (before.valueKind != fact.valueKind ||
              before.legacyFlagName != fact.legacyFlagName)) {
        unsupported(request.actionId,
            'a complete incoming Fact reference index for changing its type or identity alias');
      }
    }
    if (request.actionId == 'dialogue.update') {
      final entry = ProjectDialogueEntry.fromJson(
          Map<String, dynamic>.from(p['entry'] as Map));
      final before = snapshot.manifest.dialogues
          .where((e) => e.id == entry.id)
          .firstOrNull;
      if (before != null &&
          before.declaredOutcomes.any((old) =>
              !entry.declaredOutcomes.any((next) => old.id == next.id))) {
        unsupported(
            request.actionId, 'a complete incoming outcome reference index');
      }
      if (p['outcomeReplacements'] case final Map replacements
          when replacements.isNotEmpty) {
        unsupported(
            request.actionId, 'a complete incoming outcome reference index');
      }
    }
    if (request.actionId == 'scene.upsert' ||
        request.actionId == 'scene.upsert_batch') {
      final incoming = request.actionId == 'scene.upsert'
          ? [p['scene']]
          : p['scenes'] as List;
      for (final raw in incoming) {
        final scene =
            SceneAsset.fromJson(Map<String, dynamic>.from(raw as Map));
        final before =
            snapshot.manifest.scenes.where((s) => s.id == scene.id).firstOrNull;
        if (before != null &&
            before.declaredOutcomes.any((old) =>
                !scene.declaredOutcomes.any((next) => old.id == next.id))) {
          unsupported(request.actionId,
              'a complete incoming Scene outcome reference index');
        }
      }
    }
    if (request.actionId == 'storyline.upsert' && p['storyline'] is Map) {
      final story = StorylineAsset.fromJson(
          Map<String, dynamic>.from(p['storyline'] as Map));
      final before = snapshot.manifest.storylines
          .where((s) => s.id == story.id)
          .firstOrNull;
      final ids = {
        for (final chapter in story.chapters) chapter.id,
        for (final chapter in story.chapters)
          for (final step in chapter.steps) step.id
      };
      if (before != null &&
          [
            for (final chapter in before.chapters) chapter.id,
            for (final chapter in before.chapters)
              for (final step in chapter.steps) step.id
          ].any((id) => !ids.contains(id))) {
        unsupported(request.actionId,
            'a complete incoming chapter and step reference index');
      }
    }
  }
}
