import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const scene = NarrativeDependencyKey.scene('scene.port');
  const dialogue = NarrativeDependencyKey(
    NarrativeDependencyTargetKind.dialogue,
    'dialogue.lysa',
  );
  const fact = NarrativeDependencyKey(
    NarrativeDependencyTargetKind.fact,
    'fact.port.open',
  );

  NarrativeDependencyIndex sourceIndex() => NarrativeDependencyIndex(
        definitions: [
          NarrativeDependencyDefinition(key: scene, label: 'Port'),
          NarrativeDependencyDefinition(key: dialogue, label: 'Lysa'),
          NarrativeDependencyDefinition(key: fact, label: 'Port ouvert'),
        ],
        usages: const [
          NarrativeDependencyUsage(
            target: dialogue,
            owner: scene,
            path: 'scenes[scene.port].nodes[dialogue].dialogueId',
            criticality: NarrativeDependencyCriticality.runtimeBlocking,
          ),
          NarrativeDependencyUsage(
            target: fact,
            owner: scene,
            path: 'scenes[scene.port].nodes[condition].factId',
            criticality: NarrativeDependencyCriticality.runtimeBlocking,
          ),
        ],
      );

  group('NarrativeAssetClonePlan', () {
    test('shallow clone preserves resolved external references', () {
      final index = sourceIndex();
      final plan = previewNarrativeAssetClone(
        sourceProjectIdentity: 'selbrume',
        destinationProjectIdentity: 'selbrume',
        sourceIndex: index,
        destinationIndex: index,
        root: scene,
        mode: NarrativeAssetCloneMode.shallow,
        requestedRootId: 'scene.port.copy',
      );

      expect(plan.canApply, isTrue);
      expect(plan.cloneKeys, [scene]);
      expect(plan.idRewrites[scene], 'scene.port.copy');
      expect(
        plan.references.map((reference) => reference.disposition).toSet(),
        {NarrativeAssetCloneReferenceDisposition.preserved},
      );
      expect(plan.unresolvedDependencies, isEmpty);
    });

    test('deep clone rewrites selected dependencies and reports collisions',
        () {
      final source = sourceIndex();
      final destination = NarrativeDependencyIndex(
        definitions: [
          ...source.definitions,
          NarrativeDependencyDefinition(
            key: const NarrativeDependencyKey.scene('scene.port.copy'),
            label: 'Collision',
          ),
        ],
      );
      final plan = previewNarrativeAssetClone(
        sourceProjectIdentity: 'selbrume',
        destinationProjectIdentity: 'selbrume',
        sourceIndex: source,
        destinationIndex: destination,
        root: scene,
        mode: NarrativeAssetCloneMode.deep,
        requestedRootId: 'scene.port.copy',
        deepCloneDependencies: {dialogue},
        requestedDependencyIds: {dialogue: 'dialogue.lysa.copy'},
      );

      expect(plan.canApply, isFalse);
      expect(plan.collisions, [
        const NarrativeDependencyKey.scene('scene.port.copy'),
      ]);
      expect(plan.cloneKeys, containsAll([scene, dialogue]));
      expect(
        plan.references
            .singleWhere((reference) => reference.before == dialogue)
            .disposition,
        NarrativeAssetCloneReferenceDisposition.rewritten,
      );
      expect(
        plan.references
            .singleWhere((reference) => reference.before == fact)
            .disposition,
        NarrativeAssetCloneReferenceDisposition.preserved,
      );
    });

    test('cross-project clipboard refuses unresolved preserved dependencies',
        () {
      final plan = previewNarrativeAssetClone(
        sourceProjectIdentity: 'selbrume',
        destinationProjectIdentity: 'other',
        sourceIndex: sourceIndex(),
        destinationIndex: NarrativeDependencyIndex(
          definitions: [
            NarrativeDependencyDefinition(key: dialogue, label: 'Lysa'),
          ],
        ),
        root: scene,
        mode: NarrativeAssetCloneMode.shallow,
        requestedRootId: 'scene.port.copy',
      );
      final clipboard = NarrativeAssetClipboard.fromPlan(
        plan,
        payloads: {
          scene: {'type': 'scene', 'id': 'scene.port'},
        },
      );
      final rejected = validateNarrativeAssetClipboardPaste(
        clipboard,
        destinationProjectIdentity: 'other',
        destinationIndex: NarrativeDependencyIndex(
          definitions: [
            NarrativeDependencyDefinition(key: dialogue, label: 'Lysa'),
          ],
        ),
      );
      final accepted = validateNarrativeAssetClipboardPaste(
        clipboard,
        destinationProjectIdentity: 'other',
        destinationIndex: NarrativeDependencyIndex(
          definitions: [
            NarrativeDependencyDefinition(key: dialogue, label: 'Lysa'),
            NarrativeDependencyDefinition(key: fact, label: 'Port ouvert'),
          ],
        ),
      );

      expect(rejected.canPaste, isFalse);
      expect(rejected.unresolvedDependencies, [fact]);
      expect(accepted.canPaste, isTrue);
    });
  });

  test('bulk project mutation applies and undoes atomically', () {
    final before = _project('Avant');
    final after = _project('Après');
    final mutation = NarrativeBulkProjectMutation(
      operationId: 'bulk.archive.cinematics',
      kind: NarrativeBulkMutationKind.archive,
      before: before,
      after: after,
      assetKeys: const [
        NarrativeDependencyKey(
          NarrativeDependencyTargetKind.cinematic,
          'cinematic.intro',
        ),
      ],
    );

    expect(mutation.apply(before), after);
    expect(mutation.undo(after), before);
    expect(() => mutation.apply(after), throwsStateError);
    expect(() => mutation.undo(before), throwsStateError);
  });
}

ProjectManifest _project(String name) => ProjectManifest(
      name: name,
      maps: const [],
      tilesets: const [],
    );
