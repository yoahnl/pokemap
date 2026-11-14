import 'dart:async';

import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:avelune_studio/features/stories/domain/story_port.dart';
import 'package:avelune_studio/features/world/domain/world_port.dart';
import 'package:map_authoring/map_authoring_dialogue.dart'
    show DialogueLineTextEdit;
import 'package:map_core/map_core.dart';

final class StoryFakePorts
    implements EventPort, ScenePort, DialoguePort, WorldPort, StoryPort {
  StoryFakePorts(this.read);

  final ProjectManifest Function() read;
  final calls = <String>[];
  final sources = <String, DialogueSourceSnapshot>{};
  Object? Function(String call)? refuse;
  Completer<void>? reading;
  var _revisions = 0;

  ResourceMutationReceipt _write(
    String call,
    ProjectManifest Function(ProjectManifest before) change,
  ) {
    calls.add(call);
    if (refuse?.call(call) case final failure?) throw failure;
    final before = read();
    return ResourceMutationReceipt(
      before: before,
      manifest: change(before),
      beforeRevision: 'r${calls.length - 1}',
      revision: 'r${calls.length}',
      changedPaths: const ['project.json'],
    );
  }

  List<T> _put<T>(List<T> values, String id, T? value, String Function(T) of) {
    final kept = [
      for (final each in values)
        if (of(each) != id) each else ?value,
    ];
    return [...kept, if (!values.any((each) => of(each) == id)) ?value];
  }

  @override
  Future<ResourceMutationReceipt> publishEvent({
    required String id,
    required NarrativeEventRecord? base,
    required NarrativeEventRecord? current,
  }) async => _write('event $id', (before) {
    final registry = before.eventRegistry!;
    return before.copyWith(
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: registry.schemaVersion,
        mode: registry.mode,
        records: _put(registry.records, id, current, (record) => record.id),
        legacyClaims: registry.legacyClaims,
      ),
    );
  });

  @override
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  }) async {
    final receipt = _write('scene ${current.id}', (before) {
      final existing = before.scenes
          .where((scene) => scene.id == current.id)
          .firstOrNull;
      if (existing != base) throw const SceneFailure('scene changed');
      return before.copyWith(
        scenes: _put(before.scenes, current.id, current, (scene) => scene.id),
      );
    });
    return ScenePublicationReceipt(catalog: receipt, scene: current);
  }

  @override
  Future<DialogueSourceSnapshot> load(String id) async {
    await reading?.future;
    return sources[id] ?? (throw const DialogueFailure('absent'));
  }

  @override
  Future<DialoguePublicationReceipt> publish({
    required String id,
    required DialogueSourceSnapshot? base,
    required ProjectDialogueEntry? entry,
    required String? source,
    List<DialogueLineTextEdit>? lineTextEdits,
  }) async {
    DialogueSourceSnapshot? written;
    final receipt = _write('dialogue $id', (before) {
      if (sources[id]?.revision != base?.revision) {
        throw const DialogueFailure('dialogue changed on disk');
      }
      written = entry == null
          ? null
          : DialogueSourceSnapshot(
              entry: entry,
              source: source!,
              revision: 'dialogue-${++_revisions}',
            );
      written == null ? sources.remove(id) : sources[id] = written!;
      return before.copyWith(
        dialogues: _put(before.dialogues, id, entry, (each) => each.id),
      );
    });
    return DialoguePublicationReceipt(resources: receipt, snapshot: written);
  }

  @override
  Future<ResourceMutationReceipt> publishFact({
    required NarrativeFactDefinition? base,
    required NarrativeFactDefinition current,
  }) async => _write('fact ${current.id}', (before) {
    final existing = before.facts
        .where((fact) => fact.id == current.id)
        .firstOrNull;
    if (existing != base) throw const WorldFailure('fact changed');
    return before.copyWith(
      facts: _put(before.facts, current.id, current, (fact) => fact.id),
    );
  });

  @override
  Future<ResourceMutationReceipt> deleteFact(NarrativeFactDefinition base) =>
      throw UnimplementedError();

  @override
  Future<ResourceMutationReceipt> publishRule({
    required WorldRuleDefinition? base,
    required WorldRuleDefinition current,
  }) async => _write('rule ${current.id}', (before) {
    final existing = before.worldRules
        .where((rule) => rule.id == current.id)
        .firstOrNull;
    if (existing != base) throw const WorldFailure('rule changed');
    return before.copyWith(
      worldRules: _put(before.worldRules, current.id, current, (r) => r.id),
    );
  });

  @override
  Future<ResourceMutationReceipt> publishRuleBatch({
    required List<({WorldRuleDefinition? base, WorldRuleDefinition current})>
    rules,
  }) => throw UnimplementedError();

  @override
  Future<ResourceMutationReceipt> deleteRule(WorldRuleDefinition base) =>
      throw UnimplementedError();

  @override
  Future<List<MapData>> loadMaps() => throw UnimplementedError();

  @override
  Future<ResourceMutationReceipt> publishStory({
    required String id,
    required StorylineAsset? base,
    required StorylineAsset? current,
    Set<String> requiredStoryIds = const {},
    Set<String> requiredFactIds = const {},
    Set<String> requiredSceneIds = const {},
  }) async => _write('story $id', (before) {
    final existing = before.storylines.where((s) => s.id == id).firstOrNull;
    if (existing != base) throw const StoryFailure('story changed');
    return before.copyWith(
      storylines: _put(before.storylines, id, current, (s) => s.id),
    );
  });
}
