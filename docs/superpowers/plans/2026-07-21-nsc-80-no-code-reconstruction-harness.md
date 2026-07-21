# NSC-80 No-Code Reconstruction Harness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prouver qu’un projet possédant seulement une map et un PNJ physiques peut recevoir une tranche narrative canonique complète sans édition manuelle de JSON.

**Architecture:** Un harness de test orchestre les mêmes opérations typées que les écrans Narrative Studio, puis délègue toute écriture aux repositories et transactions Event V2. Il capture un diagnostic après chaque étape et recharge depuis disque avant comparaison. Un parcours widget du vrai shell ouvre successivement Storyline, Dialogue, Scene, Event et Validator au clavier.

**Tech Stack:** Dart/Flutter, `map_core` authoring operations, `FileProjectRepository`, `FileMapRepository`, `ProjectFileSystem`, Event V2 journaled persistence, Flutter widget tests.

---

## Frontières

- Le projet initial contient une map, un spawn et un PNJ, mais aucun Fact, Storyline, Dialogue, Scene, Cinematic, Event ou WorldRule canonique.
- Le harness ne décode, ne modifie et n’encode jamais lui-même `project.json`.
- Les modèles typés peuvent être construits en mémoire, comme le font les formulaires UI ; seule la persistance JSON est réservée aux repositories.
- Le seeder Selbrume complet reste une automatisation reproductible. Il expose désormais clairement qu’il ne constitue pas la preuve du workflow humain et renvoie vers le harness.
- Aucune modification de schema, runtime ou map physique Selbrume n’appartient à NSC-80.

### Task 1: Contrat RED du harness

**Files:**
- Create: `packages/map_editor/test/selbrume_narrative_reconstruction_test.dart`
- Create: `packages/map_editor/test/support/selbrume_narrative_authoring_harness.dart`

- [ ] **Step 1: écrire le test avant le harness**

Le test doit demander `SelbrumeNarrativeAuthoringHarness.createPhysicalFixture`, puis `authorVerticalSlice`, et vérifier les neuf étapes : Fact, Storyline/Chapter/Step, Dialogue/Yarn, Cinematic, Scene, WorldRule, Event publié, validation et reload.

- [ ] **Step 2: observer le RED**

```bash
cd packages/map_editor
/Users/karim/develop/flutter/bin/flutter test --no-pub test/selbrume_narrative_reconstruction_test.dart
```

Résultat attendu : échec de compilation, harness et types d’évidence absents.

- [ ] **Step 3: implémenter la frontière minimale**

Le harness doit utiliser `addNarrativeFact`, `createStoryline`, `CreateProjectDialogueUseCase`, `SaveDialogueYarnBodyUseCase`, `NarrativeAssetMutation.createCinematic`, les opérations Scene draft/node/edge, `addWorldRule`, `NarrativeEventBuilderV2UseCase.create`, puis `FileProjectRepository.loadProject`.

- [ ] **Step 4: prouver positive, négative et non-régression**

Le test couvre un parcours complet, le refus d’un second Event sur la même source sans consentement explicite, l’absence d’écriture directe dans le harness et l’égalité du domaine après reload.

### Task 2: Parcours widget réel du shell

**Files:**
- Create: `packages/map_editor/test/selbrume_narrative_vertical_widget_journey_test.dart`
- Modify: `packages/map_editor/test/support/narrative_studio_visual_harness.dart`

- [ ] **Step 1: écrire le parcours clavier RED**

Construire le projet avec le harness, pomper `NarrativeStudioProductShell`, ouvrir la palette via `Cmd/Ctrl+K`, puis rechercher et ouvrir Storyline, Dialogue, Scene et Event. Terminer sur Validator et vérifier le focus restauré ainsi que le compteur d’erreurs.

- [ ] **Step 2: ajouter uniquement le support de test partagé nécessaire**

Étendre le visual harness avec une fonction de host localisée et une projection de route testable ; ne pas introduire de widget produit parallèle.

- [ ] **Step 3: exécuter le test ciblé**

```bash
cd packages/map_editor
/Users/karim/develop/flutter/bin/flutter test --no-pub test/selbrume_narrative_vertical_widget_journey_test.dart
```

Résultat attendu : parcours vert sans souris et aucune exception Flutter.

### Task 3: Positionner le seeder sans mensonge

**Files:**
- Modify: `packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart`
- Modify: `packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart`

- [ ] **Step 1: ajouter une provenance de workflow vérifiable**

Le résultat du seeder expose `authoringContract: canonicalSeedAutomation` et `humanWorkflowProof: selbrume_narrative_reconstruction_test`, sans affirmer que la projection JSON historique simule l’UI.

- [ ] **Step 2: tester le garde-fou**

Le test du seeder vérifie cette provenance, l’idempotence et le maintien du contenu canonique existant.

### Task 4: Gate et commit NSC-80

**Files:**
- Create: `reports/narrativeStudio/completion/nsc_80_no_code_reconstruction_harness_evidence_pack.md`

- [ ] **Step 1: format, tests et analyse**

```bash
cd packages/map_editor
/Users/karim/develop/flutter/bin/cache/dart-sdk/bin/dart format --output=none --set-exit-if-changed test tool
/Users/karim/develop/flutter/bin/flutter test --no-pub \
  test/selbrume_narrative_reconstruction_test.dart \
  test/selbrume_narrative_vertical_widget_journey_test.dart \
  test/selbrume_canonical_narrative_seed_test.dart
/Users/karim/develop/flutter/bin/flutter analyze --no-pub \
  test/support/selbrume_narrative_authoring_harness.dart \
  test/selbrume_narrative_reconstruction_test.dart \
  test/selbrume_narrative_vertical_widget_journey_test.dart \
  tool/seed_selbrume_canonical_narrative_content.dart
```

- [ ] **Step 2: meilleure preuve build disponible**

Tenter `flutter build macos --debug --no-pub`. Si le SDK 3.41.6 échoue sur les API 3.44 préexistantes, consigner les symboles exacts et ne pas attribuer l’échec au harness.

- [ ] **Step 3: Evidence Pack et commit isolé**

Documenter audit, passes manuelles Architecture/Implémentation/Tests/Build/Critique, fichiers, zones, RED/GREEN, limites et états Git, puis commiter :

```bash
git commit -m "test(narrative): prove no-code Selbrume reconstruction"
```

## Self-review

- Couverture : toutes les familles requises par NSC-80 sont créées avant reload.
- Persistance : seules les frontières repository/transaction écrivent le manifest et les maps.
- Widget : le shell réel, sa palette, ses routes et son focus sont exercés.
- Scope : le contenu complet de `selbrume.md` reste propriétaire de NSC-81.
