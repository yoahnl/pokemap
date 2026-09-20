import 'package:map_core/map_core_domain.dart';

import 'narrative_overview.dart';

class NarrativeOverviewContext {
  NarrativeOverviewContext(
    this.project,
    this.stories,
    this.facts,
    Iterable<MapData> maps,
  ) {
    mapNames = {for (final map in project.maps) map.id: map.name};
    openMaps = {for (final map in maps) map.id: map};
    entities = {
      for (final map in maps)
        map.id: {for (final e in map.entities) e.id: e.name},
    };
    triggers = {
      for (final map in maps)
        map.id: {for (final t in map.triggers) t.id: t.name},
    };
  }
  final ProjectManifest project;
  final List<StorylineAsset> stories;
  final List<NarrativeFactDefinition> facts;
  late final Map<String, String> mapNames;
  late final Map<String, MapData> openMaps;
  late final Map<String, Map<String, String>> entities, triggers;
  late final steps = {
    for (final story in stories)
      for (final chapter in story.chapters)
        for (final step in chapter.steps) step.id: step,
  };
  late final factNames = {for (final fact in facts) fact.id: fact.label};
  late final scenes = {for (final scene in project.scenes) scene.id: scene};
  late final cinematics = {
    for (final value in project.cinematics) value.id: value,
  };
  late final dialogueNames = {
    for (final value in project.dialogues) value.id: value.name,
  };
  late final eventNames = {
    for (final record
        in project.eventRegistry?.records ?? <NarrativeEventRecord>[])
      record.id:
          record.definitionOrNull?.name ??
          record.draftOrNull?.name ??
          record.id,
  };
  late final sceneSteps = _sceneSteps();

  Map<String, Set<String>> _sceneSteps() {
    final result = <String, Set<String>>{};
    for (final story in stories) {
      for (final link in story.sceneLinks) {
        if (link.sceneRef != null && link.stepId != null) {
          result
              .putIfAbsent(link.sceneRef!.targetId, () => {})
              .add(link.stepId!);
        }
      }
      final links = {for (final link in story.sceneLinks) link.id: link};
      for (final chapter in story.chapters) {
        for (final step in chapter.steps) {
          for (final id in step.sceneLinkIds) {
            final sceneId = links[id]?.sceneRef?.targetId;
            if (sceneId != null) {
              result.putIfAbsent(sceneId, () => {}).add(step.id);
            }
          }
        }
      }
    }
    return result;
  }

  Map<String, List<NarrativeOverviewReference>> get stepReferences {
    final result = <String, List<NarrativeOverviewReference>>{};
    for (final entry in sceneSteps.entries) {
      final scene = reference(NarrativeOverviewReferenceKind.scene, entry.key);
      for (final id in entry.value) {
        result.putIfAbsent(id, () => []).add(scene);
      }
    }
    return result;
  }

  NarrativeOverviewReference reference(
    NarrativeOverviewReferenceKind kind,
    String id,
  ) {
    final label = switch (kind) {
      NarrativeOverviewReferenceKind.step => steps[id]?.title,
      NarrativeOverviewReferenceKind.fact => factNames[id],
      NarrativeOverviewReferenceKind.dialogue => dialogueNames[id],
      NarrativeOverviewReferenceKind.scene => scenes[id]?.name,
      NarrativeOverviewReferenceKind.event => eventNames[id],
      NarrativeOverviewReferenceKind.cinematic => cinematics[id]?.title,
    };
    return NarrativeOverviewReference(kind, id, label ?? id, label == null);
  }

  ({String? mapId, String label, String when, String? missing}) source(
    NarrativeEventSourceRef? ref,
  ) {
    if (ref == null) {
      return (
        mapId: null,
        label: 'Événement avancé',
        when: 'Déclenchement non renseigné',
        missing: null,
      );
    }
    ({String? mapId, String label, String when, String? missing}) located(
      String map,
      String? id,
      bool entity,
    ) {
      final name = id == null ? null : (entity ? entities : triggers)[map]?[id];
      final type = id == null
          ? 'Arrivée sur une carte'
          : entity
          ? 'Personnage'
          : 'Zone de passage';
      final missing = !mapNames.containsKey(map)
          ? 'Carte source absente : $map'
          : id != null && openMaps.containsKey(map) && name == null
          ? '$type absent : $id'
          : null;
      final label = id == null
          ? type
          : name != null && name.isNotEmpty
          ? '$type · $name'
          : openMaps.containsKey(map)
          ? '$type · $id'
          : '$type — détails à charger · $id';
      return (
        mapId: map,
        label: label,
        when: id == null
            ? 'À l’arrivée sur la carte'
            : entity
            ? 'Quand le joueur parle au personnage'
            : 'Quand le joueur entre dans la zone',
        missing: missing,
      );
    }

    return ref.when(
      entityInteract: (map, id) => located(map, id, true),
      triggerEnter: (map, id) => located(map, id, false),
      mapEnter: (map) => located(map, null, false),
      outcomeReceived: (_) => (
        mapId: null,
        label: 'Événement avancé',
        when: 'À la réception d’un résultat',
        missing: null,
      ),
    );
  }
}
