import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../maps/map_lifecycle_adapter.dart';
import 'dialogue_authoring_service.dart';
import 'dialogue_source_guards.dart';
import 'dialogue_source_store.dart';
import 'event_actions.dart';
import 'narrative_action_support.dart';
import 'scene_actions.dart';

class NarrativeDocumentActions {
  const NarrativeDocumentActions();

  static final descriptor = narrativeActionDescriptor(
    'narrative.publish_document',
    'Publish an authoritative map with compiled narrative dependencies',
    resourceKinds: const ['project', 'map', 'dialogueSource'],
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final fields = context.request.parameters;
    rejectUnknownNarrativeParameters(fields, const {
      'map',
      'mapRevision',
      'dialogues',
      'facts',
      'scenes',
      'cinematics',
      'storylines',
      'events',
    });
    final snapshot = context.snapshot;
    final map = MapData.fromJson(narrativeObjectParameter(fields, 'map'));
    final previousMap = snapshot.mapById(map.id);
    if (previousMap == null ||
        narrativeEventBytesFingerprint(
                snapshot.resourceBytes('map:${map.id}')) !=
            fields['mapRevision']) {
      throw StateError('La carte a changé depuis son ouverture.');
    }
    final entry =
        snapshot.manifest.maps.singleWhere((entry) => entry.id == map.id);
    final sources = _objects(fields, 'dialogues');
    final dialogues = [
      for (final source in sources)
        ProjectDialogueEntry.fromJson(
            Map<String, dynamic>.from(source['entry'] as Map))
    ];
    final facts = _objects(fields, 'facts')
        .map(NarrativeFactDefinition.fromJson)
        .toList();
    final scenes = _objects(fields, 'scenes').map(SceneAsset.fromJson).toList();
    final cinematics =
        _objects(fields, 'cinematics').map(CinematicAsset.fromJson).toList();
    final storylines =
        _objects(fields, 'storylines').map(StorylineAsset.fromJson).toList();
    var project = snapshot.manifest.copyWith(
      dialogues: _upsert(snapshot.manifest.dialogues, dialogues, (e) => e.id),
      facts: _upsert(snapshot.manifest.facts, facts, (e) => e.id),
      scenes: _upsert(snapshot.manifest.scenes, scenes, (e) => e.id),
      cinematics:
          _upsert(snapshot.manifest.cinematics, cinematics, (e) => e.id),
      storylines:
          _upsert(snapshot.manifest.storylines, storylines, (e) => e.id),
    );
    final paths = project.dialogues.map((e) => e.relativePath).toSet();
    if (paths.length != project.dialogues.length ||
        paths.contains('project.json') ||
        paths
            .intersection(project.maps.map((e) => e.relativePath).toSet())
            .isNotEmpty) {
      throw StateError('Dialogue source path conflict.');
    }
    final maps = [
      for (final item in snapshot.maps)
        if (item.id == map.id) map else item
    ];
    for (final scene in scenes) {
      project = const SceneActions().upsert(project, maps: maps, scene: scene);
    }
    for (final value in _objects(fields, 'events')) {
      project = const EventV2Actions().upsertRecord(project,
          maps: maps, record: NarrativeEventRecord.fromJson(value));
    }
    final registry = project.eventRegistry;
    if (registry != null) {
      final report = buildNarrativeEventValidationReport(
        registry: registry,
        catalog:
            buildNarrativeEventProjectCatalog(project: project, maps: maps),
      );
      if (report.hasBlockingDiagnostics) {
        throw StateError(
            'La publication laisse une interaction sans référence valide.');
      }
    }
    ProjectValidator.validate(project, maps: maps);
    for (final item in maps) {
      MapValidator.validate(item, projectDialogueContext: project);
    }
    final changes = <AuthoringResourceChange>[];
    final diffs = <AuthoringDiffEntry>[];
    void add(
        String kind, String id, String identity, String path, List<int> after) {
      final before = snapshot.findResourceBytes(identity);
      if (before != null &&
          narrativeEventBytesFingerprint(before) ==
              narrativeEventBytesFingerprint(after)) {
        return;
      }
      final resource = AuthoringResourceRef(
          kind: kind,
          id: id,
          revision: snapshot.resourceFingerprints[identity]);
      changes.add(AuthoringResourceChange(
          resource: resource,
          storageKey: path,
          beforeBytes: before,
          afterBytes: after));
      diffs.add(AuthoringDiffEntry(
          operation: before == null
              ? AuthoringDiffOperation.add
              : AuthoringDiffOperation.replace,
          resource: resource,
          path: '/',
          after: {'publication': 'narrative.publish_document'}));
    }

    add('project', 'project', 'project', 'project.json',
        encodeProjectAuthoringDocument(snapshot, project));
    add('map', map.id, 'map:${map.id}', entry.relativePath,
        encodeMapAuthoringDocument(map));
    for (var index = 0; index < sources.length; index++) {
      final source = sources[index];
      final dialogue = dialogues[index];
      final previous = snapshot.manifest.dialogues
          .where((e) => e.id == dialogue.id)
          .firstOrNull;
      if (previous != null && previous.relativePath != dialogue.relativePath) {
        throw StateError('Dialogue paths cannot be changed by publication.');
      }
      final identity = dialogueSourceResourceIdentity(dialogue.id);
      if (!dialogue.relativePath.endsWith('.yarn') ||
          snapshot.resourceStorageKeys.entries.any((entry) =>
              entry.key != identity && entry.value == dialogue.relativePath)) {
        throw StateError('Dialogue source path is owned by another resource.');
      }
      final bytes = snapshot.findResourceBytes(identity);
      if ((bytes == null ? null : narrativeEventBytesFingerprint(bytes)) !=
          source['revision']) {
        throw StateError('Le dialogue a changé sur le disque.');
      }
      final text = source['source'] as String;
      final result = const DialogueAuthoringCompiler()
          .compile(entry: dialogue, source: text);
      if (!result.canPublish) {
        throw StateError('Le dialogue ne peut pas être compilé.');
      }
      validateDialogueSceneStarts(
        project: project,
        dialogueId: dialogue.id,
        compiled: result,
      );
      add('dialogueSource', dialogue.id, identity, dialogue.relativePath,
          utf8.encode(text));
    }
    return AuthoringMutationDraft(
        projectedProject: project,
        changeSet: changes.isEmpty
            ? AuthoringChangeSet.noChanges()
            : AuthoringChangeSet(changes: changes, diff: AuthoringDiff(diffs)),
        preview: {
          'mapId': map.id,
          'dialogueIds': dialogues.map((e) => e.id).toList()
        });
  }
}

List<Map<String, dynamic>> _objects(Map<String, Object?> fields, String key) {
  final raw = fields[key] ?? const [];
  if (raw is! List) throw ArgumentError.value(raw, key);
  return [for (final value in raw) Map<String, dynamic>.from(value as Map)];
}

List<T> _upsert<T>(List<T> before, List<T> updates, String Function(T) id) {
  final ids = updates.map(id).toSet();
  if (ids.length != updates.length) {
    throw StateError('Duplicate narrative identities.');
  }
  return [
    for (final item in before)
      if (!ids.contains(id(item))) item,
    ...updates
  ];
}
