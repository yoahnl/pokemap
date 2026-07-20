# NSC-40 Event Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permettre de renommer, dupliquer, dépublier, activer/désactiver, supprimer de façon protégée et annuler la dernière mutation d’un Event V2 sans réintroduire le chemin d’authoring legacy.

**Architecture:** Les transformations de registre restent pures dans `map_core`; le use case de `map_editor` prépare une session attestée, invoque une seule transformation, puis la confie au writer journalisé existant. La suppression consulte le `NarrativeDependencyIndex` canonique construit depuis le même snapshot. L’UI expose les trois états réels du wire — brouillon, publié inactif, publié actif — et des actions Design System, sans inventer d’archive.

**Tech Stack:** Dart 3, Flutter, Riverpod, `package:test`, `flutter_test`, persistence JSON compare-and-swap journalisée.

---

### Task 1: Contrat pur du cycle de vie

**Files:**
- Modify: `packages/map_core/lib/src/authoring/narrative_event_authoring_contract.dart`
- Modify: `packages/map_core/lib/src/authoring/narrative_event_authoring_verification.dart`
- Modify: `packages/map_core/lib/src/operations/narrative_event_record_operations.dart`
- Create: `packages/map_core/test/narrative_event_record_operations_test.dart`
- Modify: `packages/map_core/test/narrative_event_draft_authoring_test.dart`
- Modify: `packages/map_core/test/narrative_event_publication_test.dart`

- [ ] **Step 1: écrire les tests rouges duplicate, unpublish et delete protégé**

```dart
final duplicate = duplicateNarrativeEvent(
  context: context,
  expectedRevision: revision,
  eventId: original.id,
  idGenerator: deterministicIds,
);
expect(duplicate.nextRecord!.id, isNot(original.id));
expect(duplicate.nextRecord!.draftOrNull!.source, original.definitionOrNull!.source);
expect(duplicate.nextRecord!.draftOrNull!.sceneId, original.definitionOrNull!.sceneId);
expect(duplicate.nextRecord!.draftOrNull!.name, 'Rencontre — copie');

final unpublished = unpublishNarrativeEvent(
  context: context,
  expectedRevision: revision,
  eventId: original.id,
);
expect(unpublished.nextRecord!.draftOrNull!.toJson(), containsPair('sceneId', 'scene_port'));

final rejected = deleteNarrativeEvent(
  context: context,
  expectedRevision: revision,
  eventId: original.id,
  dependencyIndex: indexWithConsumer,
);
expect(rejected.rejectionCode, 'eventReferenced');
expect(rejected.deletionPreview!.consumers, isNotEmpty);
```

- [ ] **Step 2: vérifier l’échec attendu**

Run: `cd packages/map_core && dart test test/narrative_event_record_operations_test.dart test/narrative_event_draft_authoring_test.dart test/narrative_event_publication_test.dart`

Expected: FAIL parce que `duplicateNarrativeEvent`, `unpublishNarrativeEvent`, `deleteNarrativeEvent` et le preview de suppression n’existent pas encore.

- [ ] **Step 3: implémenter les mutations minimales et leur replay**

```dart
enum NarrativeEventAuthoringMutation {
  createDraft,
  duplicate,
  delete,
  unpublish,
  selectSource,
  replaceSource,
  removeSource,
  rename,
  setConditions,
  setScene,
  removeScene,
  setReusePolicy,
  setPriority,
  setOrder,
  publish,
  activate,
  deactivate,
}

String? get eventId => nextRecord?.id ?? previousRecord?.id;
```

`duplicateNarrativeEvent` crée toujours un brouillon désactivé avec un nouvel ID et un nouvel ordre, copie source/conditions/Scene/reuse/priority, et laisse les références externes inchangées. `unpublishNarrativeEvent` convertit une définition configurée en draft complet sans perte. `deleteNarrativeEvent` refuse les usages dont l’owner est différent de l’Event cible, puis retire exactement un record.

- [ ] **Step 4: vérifier le contrat pur**

Run: `cd packages/map_core && dart test test/narrative_event_record_operations_test.dart test/narrative_event_draft_authoring_test.dart test/narrative_event_publication_test.dart && dart analyze`

Expected: PASS, puis `No issues found!`.

### Task 2: Transaction editor, recovery et undo

**Files:**
- Modify: `packages/map_editor/lib/src/application/models/narrative_event_registry_persistence_models.dart`
- Modify: `packages/map_editor/lib/src/infrastructure/repositories/narrative_event_registry_persistence.dart`
- Modify: `packages/map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart`
- Modify: `packages/map_editor/test/narrative_event_builder_v2_use_case_test.dart`

- [ ] **Step 1: écrire les tests rouges du use case**

```dart
final duplicate = await useCase.duplicate(
  projectPath: fixture.projectPath,
  eventId: eventId,
  environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
);
expect(duplicate.status, NarrativeEventBuilderV2WriteStatus.committed);
expect(duplicate.persistenceResult!.undoPath, isNotEmpty);

final undo = await useCase.undo(
  undoPath: duplicate.persistenceResult!.undoPath!,
);
expect(undo.status, NarrativeEventBuilderV2WriteStatus.committed);
```

Ajouter les mêmes preuves pour unpublish, suppression avec consumers, exception de persistence, état `recoveryRequired` et reload du registre committé.

- [ ] **Step 2: vérifier l’échec attendu**

Run: `cd packages/map_editor && flutter test test/narrative_event_builder_v2_use_case_test.dart`

Expected: FAIL sur les méthodes lifecycle et `undoPath` absentes.

- [ ] **Step 3: coordonner une seule mutation par transaction**

```dart
Future<NarrativeEventBuilderV2WriteResult> duplicate({...}) => _execute(
  projectPath: projectPath,
  environment: environment,
  author: (session) => duplicateNarrativeEvent(
    context: session.context,
    expectedRevision: session.projectRevision,
    eventId: eventId,
    idGenerator: _idGeneratorFactory(),
  ),
);
```

Construire l’index de suppression depuis `session.manifest` et `session.maps`, exposer le chemin d’undo produit par la persistence, mapper recovery/stale/IO sans adopter des bytes non attestés, puis recharger après succès.

- [ ] **Step 4: vérifier les transactions**

Run: `cd packages/map_editor && flutter test test/narrative_event_builder_v2_use_case_test.dart test/event_registry_recovery_test.dart test/event_registry_undo_test.dart`

Expected: PASS.

### Task 3: Projection et actions no-code

**Files:**
- Modify: `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_state.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_project_list.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart`
- Create: `packages/map_editor/test/narrative_event_lifecycle_authoring_test.dart`

- [ ] **Step 1: écrire le widget test rouge**

```dart
expect(find.text('Brouillon'), findsOneWidget);
expect(find.text('Publié · inactif'), findsOneWidget);
expect(find.text('Publié · actif'), findsOneWidget);
await tester.tap(find.byKey(const ValueKey('event-builder-v2-lifecycle-actions')));
expect(find.text('Dupliquer'), findsOneWidget);
expect(find.text('Dépublier'), findsOneWidget);
expect(find.text('Supprimer'), findsOneWidget);
```

Le test confirme aussi qu’un consumer produit une confirmation bloquée qui nomme sa provenance, qu’une suppression libre exige une confirmation destructive, que duplicate sélectionne le clone, et que l’action d’annulation recharge la liste.

- [ ] **Step 2: vérifier l’échec attendu**

Run: `cd packages/map_editor && flutter test test/narrative_event_lifecycle_authoring_test.dart`

Expected: FAIL sur les actions et libellés de cycle de vie absents.

- [ ] **Step 3: ajouter les actions avec les primitives PokeMap**

```dart
NarrativeEventLifecyclePresentation lifecycleFor(
  NarrativeEventProjectSummary event,
) => switch ((event.status, event.enabled)) {
  (NarrativeEventProjectStatus.draftIncomplete, _) =>
    const NarrativeEventLifecyclePresentation('Brouillon', 'Non publié'),
  (_, true) =>
    const NarrativeEventLifecyclePresentation('Publié · actif', 'Joué par le runtime'),
  _ => const NarrativeEventLifecyclePresentation(
    'Publié · inactif',
    'Prêt mais ignoré par le runtime',
  ),
};
```

Relayer les callbacks via `EventBuilderV2Workspace`, utiliser `showPokeMapPromptDialog`, `showPokeMapBinaryConfirmationDialog` et `PokeMapButton`/`PokeMapIconButton`. Ne jamais afficher ou écrire `MapEventDefinition` depuis cette route.

- [ ] **Step 4: vérifier l’authoring UI et la fidélité V2**

Run: `cd packages/map_editor && flutter test test/narrative_event_lifecycle_authoring_test.dart test/ui/canvas/event_builder_v2_flow_fidelity_test.dart test/ui/canvas/event_builder_v2_workspace_test.dart`

Expected: PASS.

### Task 4: Evidence Pack et commit NSC-40

**Files:**
- Create: `reports/narrativeStudio/completion/nsc_40_event_lifecycle_evidence_pack.md`

- [ ] **Step 1: exécuter les passes nommées**

Audit: contrôler `git diff --check`, l’absence de `MapEventDefinition` dans les nouveaux chemins et l’absence de couleurs brutes.

Tests: lancer les suites ciblées core/editor.

Build: lancer `dart analyze` dans `map_core` puis `flutter analyze` dans `map_editor`.

Critique: vérifier suppression référencée, clone d’un actif, unpublish sans perte, undo stale, journal recovery et sélection après reload.

- [ ] **Step 2: écrire l’Evidence Pack conformément à `codex_rule.md`**

Inclure état git initial/final, inventaire exact, zones/diffs, commandes et sorties exactes, verdict de chaque passe, limites, auto-critique et hashes des fichiers créés.

- [ ] **Step 3: committer uniquement NSC-40**

```bash
git add <fichiers NSC-40 uniquement>
git commit -m "feat(narrative): complete event lifecycle"
```

Expected: un commit isolé dont le parent est `d4c767aff`, sans push.
