import 'package:map_core/map_core_domain.dart';

final class GameBehaviourDependencies {
  GameBehaviourDependencies(
    ProjectManifest project,
    NarrativeEventRecord record,
  ) {
    final scenes = {for (final scene in project.scenes) scene.id: scene};
    final facts = {for (final fact in project.facts) fact.id};
    final dialogues = {for (final dialogue in project.dialogues) dialogue.id};
    final visited = <String>{};
    final pending = <NarrativeDependencyKey>[];
    void inspect({SceneAsset? scene, NarrativeEventRecord? event}) {
      final partial = ProjectManifest(
        name: project.name,
        maps: const [],
        tilesets: const [],
        scenes: [?scene],
        eventRegistry: event == null
            ? null
            : NarrativeEventRegistry(
                schemaVersion: 1,
                mode: EventSystemMode.v2Only,
                records: [event],
                legacyClaims: const [],
              ),
      );
      pending.addAll(
        buildNarrativeDependencyIndex(project: partial).usages
            .map((usage) => usage.target),
      );
    }

    inspect(event: record);
    while (pending.isNotEmpty) {
      final ref = pending.removeLast();
      switch (ref.kind) {
        case NarrativeDependencyTargetKind.scene:
          if (!visited.add(ref.id)) continue;
          final scene = scenes[ref.id];
          if (scene == null) {
            missingScene = true;
            problem = 'Une scène requise est absente. Choisissez une scène disponible dans Histoire.';
            return;
          }
          inspect(scene: scene);
        case NarrativeDependencyTargetKind.fact:
          if (!facts.contains(ref.id)) {
            problem = 'Un fait requis est absent. Réparez la référence dans Histoire.';
            return;
          }
        case NarrativeDependencyTargetKind.dialogue:
          if (!dialogues.contains(ref.id)) {
            problem = 'Un dialogue requis est absent. Réparez la scène dans Histoire.';
            return;
          }
          dialogueIds.add(ref.id);
        default:
          break;
      }
    }
  }

  final dialogueIds = <String>{};
  bool missingScene = false;
  String? problem;
}
