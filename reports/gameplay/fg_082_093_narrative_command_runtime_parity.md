# FG-082 / FG-093 — Narrative Command Runtime Parity

Date : 2026-07-23  
Lot exact : **Phase 4 / Task 4.4 — Audit de parité catalogue/runtime**  
Statut proposé du lot : **DONE fonctionnel, promotion canonique conservée PARTIAL**

## Résumé exécutif

La gate fonctionnelle de la Phase 4 est satisfaite : les 18 commandes que le
Narrative Studio déclare publiables possèdent toutes une représentation
canonique, un round-trip JSON, des diagnostics projet, un plan runtime et un
backend réellement invoqué par les tests. La répartition exhaustive est de 11
conséquences state-only, 3 commandes interactives et 4 nœuds Scene dédiés.

Le test fail-closed a révélé un défaut réel : une rencontre statique valide
était diagnostiquée à tort comme nécessitant un trainer. Le diagnostic distingue
désormais correctement une bataille trainer d'une rencontre statique et exige
un `battleTemplateId` pour cette dernière.

Le verdict de release global reste honnêtement **NO-GO** : la suite complète
Runtime échoue sur 71 anciennes fixtures de combat devenues incompatibles avec
les exigences progression/catalogues des lots précédents, et la suite Editor
échoue sur deux preuves Selbrume périmées. Les tests ciblés du présent lot, les
analyses et le build macOS sont verts. Ces échecs ont été reproduits isolément
et ne traversent aucun fichier modifié par la Task 4.4.

## Confirmation du scope

Le lot couvre uniquement la bijection catalogue → modèle → diagnostic → plan →
backend runtime, l'exclusion explicite des commandes différées et l'inscription
de la gate dans la matrice rapide. Il ne répare pas les fixtures de progression
de combat ni les reçus/digests Selbrume périmés : ces travaux sont indépendants
et leur intégration au lot aurait mélangé les scopes.

## Audit initial

### Fichiers et contrats inspectés

- `packages/map_core/lib/src/read_models/narrative_command_catalog.dart` :
  source canonique des descriptors et capacités.
- `packages/map_core/lib/src/models/scene_consequence.dart` et
  `scene_interactive_command.dart` : wires persistants.
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart` :
  transformation d'une Scene en intents runtime.
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` : validation
  des références projet et des payloads.
- `packages/map_runtime/lib/src/application/scene_runtime/` : writer,
  exécuteur interactif, callbacks host et exécuteur Scene.
- Tests catalogue, diagnostics, writer et intégrations Phase 4 existants.
- `reports/gameplay/fg_000_pokemap_mvp_closure_roadmap_2026-07-22.md`,
  `pokemap_roadmap_mecaniques_fangame.md` et la matrice FG-183.

### Risques identifiés avant implémentation

1. Un descriptor pouvait être ajouté comme publiable sans backend runtime.
2. Un payload pouvait sérialiser mais échouer au diagnostic ou au plan.
3. Une commande interactive pouvait renvoyer un port non déclaré.
4. Une pseudo-commande différée pouvait être exposée par erreur.
5. Une gate uniquement positive aurait laissé passer un nouveau descriptor non
   recensé ; l'égalité exacte des ensembles évite ce faux vert.

### État git initial

Branche `main`, HEAD `70c455b2b feat(editor): author executable gameplay
commands`, working tree propre. Les trois commits Phase 4 antérieurs étaient :

- `91d06e995 feat(runtime): execute interactive Scene commands`
- `6c50b7d13 feat(core): add canonical gameplay Scene consequences`
- `70c455b2b feat(editor): author executable gameplay commands`

## Passes séparées et verdicts

L'instruction supérieure de cette exécution interdisait la création de
sub-agents. Conformément au fallback de `codex_rule.md`, cinq passes séparées ont
donc été réalisées et nommées explicitement.

| Passe | Verdict | Signal principal |
|---|---|---|
| Audit / Architecture | PASS | Les 18 descriptors se répartissent sans ambiguïté entre 11 conséquences, 3 interactifs et 4 nœuds dédiés. |
| Implémentation | PASS | Deux gates exhaustives ajoutées ; diagnostic static encounter corrigé sans couplage Core → Runtime. |
| Tests | PASS ciblé / NO-GO global | `+76` Core et `+38` Runtime ciblés ; suites globales rouges sur dette externe détaillée ci-dessous. |
| Build / Validation | PASS | Trois analyses propres et host macOS Debug construit. |
| Critique finale | PASS avec réserves | Aucun descriptor supporté non couvert ; aucune commande différée publiée ; promotion canonique volontairement non surévaluée. |

## Inventaire complet des fichiers du lot

| Fichier | Zones modifiées | Raison | Impact attendu |
|---|---|---|---|
| `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` | `SceneDiagnosticCode`, branche `SceneBattlePayload` de `diagnoseSceneAgainstProject` | Distinguer trainer et static encounter, exiger le template statique | Supprime le faux positif trainer et bloque une rencontre statique inexécutable. |
| `packages/map_core/test/narrative_command_contract_parity_test.dart` | Nouveau fichier | Gate exhaustive Core | Tout nouveau descriptor publiable doit fournir wire, diagnostic et plan. |
| `packages/map_runtime/test/narrative_command_runtime_parity_test.dart` | Nouveau fichier | Gate exhaustive Runtime | Tout descriptor supporté doit atteindre un writer/handler/callback et une sortie valide. |
| `reports/gameplay/fg_183_regression_matrix_v0.md` | Date, gate rapide Core/Runtime, matrice fonctionnelle | Rendre les gates récurrentes | La dérive future échoue dans la matrice rapide de release. |
| `reports/gameplay/fg_000_pokemap_mvp_closure_roadmap_2026-07-22.md` | Task 4.4 et preuve fraîche | Clôturer la task avec limites | Trace le gate fonctionnel et les blockers globaux. |
| `pokemap_roadmap_mecaniques_fangame.md` | Lignes FG-082/085/089/090/091/093 | Mise à jour régulière demandée | Remplace « gate 4.4 restante » par la preuve obtenue, sans faux DONE. |
| `reports/gameplay/fg_082_093_narrative_command_runtime_parity.md` | Nouveau rapport | Evidence Pack du lot | Centralise audit, preuves, limites, diffs et contenu des nouveaux tests. |

## Diffs précis des fichiers modifiés

### `scene_diagnostics.dart`

```diff
 enum SceneDiagnosticCode {
   battleTrainerRefUnknown,
+  battleTemplateRefMissing,
 }

-if ((payload.battleKind == 'trainer' || payload.battleKind == 'static') && ...)
+if (payload.battleKind == 'trainer' && ...)

+if (payload.battleKind == 'static' &&
+    (payload.battleTemplateId?.trim().isEmpty ?? true)) {
+  // SceneDiagnosticCode.battleTemplateRefMissing, severity error.
+}
```

### `fg_183_regression_matrix_v0.md`

```diff
+test/narrative_command_contract_parity_test.dart
+test/narrative_command_runtime_parity_test.dart
+| Contrat no-code / runtime | ... |
```

### Roadmaps

La Task 4.4 passe de cinq cases non cochées à cinq cases cochées, avec la preuve
fraîche, les résultats ciblés et les limites globales. Les lots canoniques
restent `PARTIAL` tant que les suites package complètes ne sont pas restaurées.

## Tests créés et couverture

### Gate Core

- égalité exacte entre les 18 IDs publiables et les samples ;
- round-trip JSON de chaque payload ;
- diagnostics projet sans erreur ;
- plan runtime constructible et intent attendu ;
- diagnostics interactifs ;
- commande NPC différée non publiable/unsupported ;
- non-régression static encounter : template exigé, trainer non exigé.

### Gate Runtime

- égalité exacte des 11 conséquences et appel du writer atomique réel ;
- égalité exacte des 3 interactifs, appel du handler et port déclaré ;
- égalité exacte des 4 nœuds dédiés, callbacks host et exécution terminale ;
- exclusion runtime de la pseudo-commande NPC différée.

## Commandes et résultats exacts

### Tests ciblés verts

```text
cd packages/map_core
dart test test/narrative_command_contract_parity_test.dart test/narrative_command_catalog_test.dart test/scene_diagnostics_test.dart test/scene_consequence_model_test.dart test/scene_runtime_plan_test.dart
Résultat : +76: All tests passed!

cd packages/map_runtime
flutter test test/narrative_command_runtime_parity_test.dart test/scene_consequence_runtime_writer_test.dart test/scene_interactive_command_runtime_executor_test.dart test/narrative_command_save_load_integration_test.dart test/playable_map_game_scene_interactive_command_integration_test.dart
Résultat : +38: All tests passed!

Smoke final après rédaction du rapport :
dart test test/narrative_command_contract_parity_test.dart
Résultat : +3: All tests passed!

flutter test test/narrative_command_runtime_parity_test.dart
Résultat : +4: All tests passed!
```

### Suites complètes

```text
cd packages/map_core && dart test
Résultat : +4389: All tests passed! (1 min 59 s)

cd packages/map_runtime && flutter test
Résultat : +1977 ~1 -71: Some tests failed (2 min 06 s)

cd packages/map_editor && flutter test
Résultat : +4107 -2: Some tests failed (5 min 19 s)
```

Répartition exacte des 71 échecs Runtime :

| Fichier | Échecs | Cause reproduite |
|---|---:|---|
| `playable_map_game_qualified_outcome_v2_integration_test.dart` | 43 | `moves.json` absent de la fixture `/tmp/qualified_outcome_v2`. |
| `runtime_battle_combatant_seed_builder_test.dart` | 20 | espèces de fixture sans champ `progression`. |
| `playable_map_game_checkpoint_load_safety_integration_test.dart` | 4 | `moves.json` absent de `/tmp/checkpoint_load_safety`. |
| `playable_map_game_input_test.dart` | 3 | `missingGrowthRate` lors de l'hydratation progression. |
| `playable_map_game_whiteout_lite_test.dart` | 1 | `moves.json` absent de `/tmp/project`. |

Relances isolées :

```text
flutter test test/runtime_battle_combatant_seed_builder_test.dart
Résultat : +1 -20, progression absente.

flutter test test/playable_map_game_qualified_outcome_v2_integration_test.dart
Résultat : +0 -43, moves.json absent.

flutter test test/selbrume_event_v2_persistence_migration_test.dart --plain-name 'J2 autonomous Selbrume Event V2 fixture regenerates the versioned fixture byte-for-byte from the checkpoint'
Résultat : +0 -1, digests fixture/project/promotion périmés.

flutter test test/selbrume_narrative_validator_test.dart --reporter compact
Résultat : +0 -1, NarrativeRuntimeReceiptState.stale au lieu de freshPass.
```

Les chemins et historiques confirment que ces contrats stricts proviennent des
commits progression antérieurs (`caf97a2e1`, `f07362f0b`, `2bbba3ed8`,
`ce8812bdb`) et non des fichiers du présent lot.

### Analyse statique

```text
cd packages/map_core && dart analyze
Résultat : No issues found!

cd packages/map_runtime && flutter analyze
Résultat : No issues found!

cd packages/map_editor && flutter analyze
Résultat : No issues found!
```

### Build

```text
cd examples/playable_runtime_host
flutter build macos --debug
Résultat : ✓ Built build/macos/Build/Products/Debug/playable_runtime_host.app
```

## État git final attendu après commit

Branche `main`, commit proposé
`test(gameplay): enforce narrative command runtime parity`, working tree propre.
Le commit est créé seulement après la relecture finale de ce rapport et des
diffs.

## Limites conservées

- `setNpcPresence` reste volontairement différé et non publiable.
- La gate ne prétend pas simuler tout le jeu : elle prouve le raccordement du
  contrat, tandis que les tests métier spécialisés prouvent les mutations.
- Les anciennes fixtures de combat ne sont pas assouplies : le moteur garde ses
  exigences strictes, et les fixtures devront être mises à niveau séparément.
- Les preuves Selbrume ne sont pas régénérées silencieusement dans un lot de
  parité de commandes.
- Les statuts FG restent `PARTIAL` malgré la gate fonctionnelle, car les règles
  du repo interdisent un `DONE` tant que les suites package fraîches sont rouges.

## Auto-critique finale

La gate est volontairement explicite : chaque nouvelle commande nécessite un
sample manuel dans Core et Runtime. Cette duplication est un coût de maintenance,
mais elle constitue ici un garde-fou souhaité contre les descriptors « déclarés
supportés » sans backend. Dériver automatiquement les samples du catalogue
rendrait la preuve circulaire et moins utile.

Le writer est invoqué directement pour les conséquences state-only, pas via une
Scene complète pour chacune. Le chemin Scene complet est néanmoins couvert par
le test des intents et par les intégrations dédiées déjà présentes ; multiplier
18 scénarios E2E aurait alourdi le gate rapide sans augmenter proportionnellement
la confiance.

Risque restant principal : tant que les 73 régressions globales ne sont pas
fermées, une release ne peut pas être déclarée verte même si la Phase 4 est
fonctionnellement achevée.

## Prochaines étapes proposées, non implémentées

1. Lot de dette ciblé : enrichir les cinq familles de fixtures Runtime avec
   `progression`, `growthRate` et un catalogue moves canonique minimal.
2. Régénérer puis relire les digests Event V2 Selbrume.
3. Régénérer le reçu runtime Selbrume via le parcours officiel, jamais en
   modifiant son état à la main.
4. Relancer Core, Runtime et Editor complets ; seulement alors proposer le
   passage FG-082/085/089/090/091/093 à `DONE`.

## Contenu complet des fichiers créés

Le présent rapport n'est pas inclus récursivement dans lui-même. Les deux
nouveaux fichiers de test sont reproduits intégralement ci-dessous.

### `packages/map_core/test/narrative_command_contract_parity_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('every publishable command owns a serializable diagnostic-safe plan',
      () {
    final catalog = NarrativeCommandCatalog.canonical();
    final samples = _canonicalSamples();
    final project = _project();
    final mapsById = {'map_port': _map()};
    final publishableIds = {
      for (final command in catalog.publishable) command.id,
    };

    // This equality is the fail-closed part of the gate: adding a supported
    // descriptor requires proving its canonical wire in this test.
    expect(samples.keys, unorderedEquals(publishableIds));

    for (final command in catalog.publishable) {
      final payload = samples[command.id]!();
      final roundTrip = SceneNodePayload.fromJson(payload.toJson());
      final scene = _sceneFor(command.id, roundTrip);
      final diagnostics = diagnoseSceneAgainstProject(
        scene,
        project,
        mapsById: mapsById,
      );
      final plan = buildSceneRuntimePlan(scene);

      expect(roundTrip, payload, reason: command.id);
      expect(
        diagnostics.hasErrors,
        isFalse,
        reason: '${command.id}: '
            '${diagnostics.diagnostics.map((item) => item.code.name).join(', ')}',
      );
      expect(plan.canBuild, isTrue, reason: command.id);
      if (payload case SceneActionPayload(:final interactiveCommand?)) {
        expect(
          diagnoseInteractiveCommand(
            command: interactiveCommand,
            project: project,
          ),
          isEmpty,
          reason: command.id,
        );
      }
      expect(
        plan.plan!.nodes[1].intent.kind,
        _expectedIntent(payload),
        reason: command.id,
      );
    }
  });

  test('deferred commands cannot enter the publishable contract', () {
    final deferred = NarrativeCommandCatalog.canonical().byId(
      NarrativeCommandIds.setNpcPresence,
    )!;

    expect(deferred.isPublishable, isFalse);
    expect(
      deferred.capabilities.runtime,
      NarrativeCommandCapabilityStatus.unsupported,
    );
    expect(deferred.wireId, startsWith('unsupported.'));
  });

  test('static encounter diagnostics require a template, not a trainer', () {
    final valid = _sceneFor(
      'static.valid',
      SceneBattlePayload(
        battleKind: 'static',
        battleTemplateId: 'sproutle',
        declaredOutcomes: const ['victory'],
      ),
    );
    final missingTemplate = _sceneFor(
      'static.missing',
      SceneBattlePayload(
        battleKind: 'static',
        declaredOutcomes: const ['victory'],
      ),
    );

    expect(
      diagnoseSceneAgainstProject(valid, _project(), mapsById: {
        'map_port': _map(),
      }).byCode(SceneDiagnosticCode.battleTrainerRefUnknown),
      isEmpty,
    );
    expect(
      diagnoseSceneAgainstProject(missingTemplate, _project(), mapsById: {
        'map_port': _map(),
      }).byCode(SceneDiagnosticCode.battleTemplateRefMissing),
      hasLength(1),
    );
  });
}

Map<String, SceneNodePayload Function()> _canonicalSamples() => {
      NarrativeCommandIds.setFact: () => SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: 'fact_gate', value: true),
          ),
      NarrativeCommandIds.markEventConsumed: () =>
          SceneActionPayload.consequence(
            SceneConsequence.markEventConsumed(
              mapId: 'map_port',
              eventId: 'event_gate',
            ),
          ),
      NarrativeCommandIds.completeStoryStep: () =>
          SceneActionPayload.consequence(
            SceneConsequence.completeStoryStep(stepId: 'step_port'),
          ),
      NarrativeCommandIds.giveItem: () => SceneActionPayload.consequence(
            SceneConsequence.giveItem(itemId: 'potion', quantity: 1),
          ),
      NarrativeCommandIds.takeItem: () => SceneActionPayload.consequence(
            SceneConsequence.takeItem(itemId: 'ticket', quantity: 1),
          ),
      NarrativeCommandIds.giveMoney: () => SceneActionPayload.consequence(
            SceneConsequence.giveMoney(amount: 200),
          ),
      NarrativeCommandIds.givePokemon: () => SceneActionPayload.consequence(
            SceneConsequence.givePokemon(
              speciesId: 'sproutle',
              level: 5,
              currentHp: 18,
            ),
          ),
      NarrativeCommandIds.giveConfiguredStarter: () =>
          SceneActionPayload.consequence(
            SceneConsequence.giveConfiguredStarter(
              starterOptionId: 'starter_sproutle',
            ),
          ),
      NarrativeCommandIds.healParty: () => SceneActionPayload.consequence(
            SceneConsequence.healParty(),
          ),
      NarrativeCommandIds.awardBadge: () => SceneActionPayload.consequence(
            SceneConsequence.awardBadge(badgeId: 'badge_tide'),
          ),
      NarrativeCommandIds.unlockFieldAbility: () =>
          SceneActionPayload.consequence(
            SceneConsequence.unlockFieldAbility(ability: FieldAbility.surf),
          ),
      NarrativeCommandIds.warp: () => SceneActionPayload.interactive(
            SceneInteractiveCommand.warp(
              destinationMapId: 'map_port',
              warpId: 'warp_arrival',
            ),
          ),
      NarrativeCommandIds.openShop: () => SceneActionPayload.interactive(
            SceneInteractiveCommand.openShop(shopId: 'shop_port'),
          ),
      NarrativeCommandIds.openPc: () => SceneActionPayload.interactive(
            SceneInteractiveCommand.openPc(),
          ),
      NarrativeCommandIds.dialogue: () => SceneYarnDialoguePayload(
            dialogueId: 'dialogue_port',
          ),
      NarrativeCommandIds.trainerBattle: () => SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_port',
            declaredOutcomes: const ['victory'],
          ),
      NarrativeCommandIds.staticEncounter: () => SceneBattlePayload(
            battleKind: 'static',
            battleTemplateId: 'sproutle',
            declaredOutcomes: const ['victory'],
          ),
      NarrativeCommandIds.cinematic: () => SceneCinematicPayload(
            cinematicId: 'cinematic_port',
          ),
    };

SceneRuntimePlanIntentKind _expectedIntent(SceneNodePayload payload) =>
    switch (payload) {
      SceneActionPayload(:final consequence) when consequence != null =>
        SceneRuntimePlanIntentKind.applyConsequence,
      SceneActionPayload(:final interactiveCommand)
          when interactiveCommand != null =>
        SceneRuntimePlanIntentKind.executeInteractiveCommand,
      SceneYarnDialoguePayload() => SceneRuntimePlanIntentKind.showDialogue,
      SceneBattlePayload() => SceneRuntimePlanIntentKind.startBattle,
      SceneCinematicPayload() => SceneRuntimePlanIntentKind.playCinematic,
      _ => throw StateError('Unsupported parity sample ${payload.kind.name}'),
    };

SceneAsset _sceneFor(String commandId, SceneNodePayload payload) {
  final (port, edgeKind) = switch (payload) {
    SceneBattlePayload() => ('victory', SceneEdgeKind.battleVictory),
    SceneCinematicPayload() => ('completed', SceneEdgeKind.cinematicCompleted),
    SceneActionPayload() => ('completed', SceneEdgeKind.actionCompleted),
    _ => ('completed', SceneEdgeKind.defaultFlow),
  };
  return SceneAsset(
    id: 'scene.parity.$commandId',
    name: 'Parity $commandId',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'command', kind: payload.kind, payload: payload),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start-command',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'command',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'command-end',
          fromNodeId: 'command',
          fromPortId: port,
          toNodeId: 'end',
          kind: edgeKind,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'start', x: 0, y: 0),
        SceneNodeLayout(nodeId: 'command', x: 240, y: 0),
        SceneNodeLayout(nodeId: 'end', x: 480, y: 0),
      ],
    ),
  );
}

ProjectManifest _project() => ProjectManifest(
      name: 'Core parity',
      maps: const [
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port',
          relativePath: 'maps/port.json',
        ),
      ],
      tilesets: const [],
      facts: [
        NarrativeFactDefinition(id: 'fact_gate', label: 'Gate'),
      ],
      dialogues: const [
        ProjectDialogueEntry(
          id: 'dialogue_port',
          name: 'Dialogue Port',
          relativePath: 'dialogues/port.yarn',
        ),
      ],
      trainers: const [
        ProjectTrainerEntry(
          id: 'trainer_port',
          name: 'Dresseur du port',
          trainerClass: 'Marin',
          team: [
            ProjectTrainerPokemonEntry(speciesId: 'sproutle', level: 5),
          ],
        ),
      ],
      cinematics: [
        CinematicAsset(
          id: 'cinematic_port',
          title: 'Port',
          mapId: 'map_port',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'wait',
                kind: CinematicTimelineStepKind.wait,
                durationMs: 100,
              ),
            ],
          ),
        ),
      ],
      storylines: [
        StorylineAsset(
          id: 'story_port',
          type: StorylineType.main,
          status: StorylineStatus.active,
          title: 'Port',
          chapters: [
            StorylineChapter(
              id: 'chapter_port',
              title: 'Port',
              order: 0,
              steps: [
                StorylineStep(id: 'step_port', title: 'Port', order: 0),
              ],
            ),
          ],
        ),
      ],
      shops: const [
        ShopDefinition(id: 'shop_port', label: 'Boutique du port'),
      ],
      badges: const [
        BadgeDefinition(id: 'badge_tide', label: 'Badge Marée'),
      ],
      newGame: const ProjectNewGameConfig(
        starterOptions: [
          ProjectStarterOption(
            id: 'starter_sproutle',
            label: 'Sproutle',
            pokemon: PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              currentHp: 20,
            ),
          ),
        ],
      ),
    );

MapData _map() => MapData(
      id: 'map_port',
      name: 'Port',
      size: const GridSize(width: 4, height: 4),
      events: [
        MapEventDefinition(
          id: 'event_gate',
          position: const EventPosition(layerId: 'base', x: 1, y: 1),
          pages: const [MapEventPage(pageNumber: 0)],
        ),
      ],
      warps: const [
        MapWarp(
          id: 'warp_arrival',
          pos: GridPos(x: 1, y: 1),
          targetMapId: 'map_port',
          targetPos: GridPos(x: 2, y: 2),
        ),
      ],
    );
```

### `packages/map_runtime/test/narrative_command_runtime_parity_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('every supported consequence reaches an atomic runtime writer', () {
    final catalog = NarrativeCommandCatalog.canonical();
    final samples = _consequenceSamples();
    final declaredIds = {
      for (final command in catalog.publishable)
        if (command.backend == NarrativeCommandBackend.sceneConsequence)
          command.id,
    };
    final writer = SceneConsequenceRuntimeWriter(
      project: _project(),
      mapsById: {'map_test': _map()},
      maxHpByPartyIndex: const {0: 20},
      maxPpByPartyIndex: const {
        0: {'tackle': 35},
      },
    );

    // Adding a supported descriptor without a real writer sample must fail.
    expect(samples.keys, unorderedEquals(declaredIds));
    for (final entry in samples.entries) {
      final result = writer.applyOne(_gameState(), entry.value());
      expect(result.success, isTrue, reason: entry.key);
      expect(result.appliedConsequences, hasLength(1), reason: entry.key);
    }
  });

  test('every supported interactive command returns a declared output port',
      () async {
    final catalog = NarrativeCommandCatalog.canonical();
    final samples = _interactiveSamples();
    final declaredIds = {
      for (final command in catalog.publishable)
        if (command.backend ==
            NarrativeCommandBackend.interactiveRuntimeCommand)
          command.id,
    };
    final calls = <SceneInteractiveCommandKind>[];
    Future<String> handler(SceneInteractiveCommand command) async {
      calls.add(command.kind);
      return 'completed';
    }

    final executor = SceneInteractiveCommandRuntimeExecutor(
      warp: handler,
      openShop: handler,
      openPc: handler,
    );

    expect(samples.keys, unorderedEquals(declaredIds));
    for (final entry in samples.entries) {
      final command = entry.value();
      final output = await executor.execute(
        SceneRuntimePlanIntent.executeInteractiveCommand(command: command),
      );
      expect(command.outputPortIds, contains(output), reason: entry.key);
    }
    expect(calls, SceneInteractiveCommandKind.values);
  });

  test('every supported dedicated node reaches a runtime host callback',
      () async {
    final catalog = NarrativeCommandCatalog.canonical();
    final samples = _dedicatedSamples();
    final declaredIds = {
      for (final command in catalog.publishable)
        if (command.backend == NarrativeCommandBackend.dedicatedSceneNode)
          command.id,
    };
    final invoked = <SceneRuntimePlanIntentKind>[];
    String complete(SceneRuntimePlanIntent intent) {
      invoked.add(intent.kind);
      return switch (intent.kind) {
        SceneRuntimePlanIntentKind.startBattle => 'victory',
        _ => 'completed',
      };
    }

    final callbacks = SceneRuntimeHostCallbacks(
      evaluateCondition: complete,
      showDialogue: complete,
      startBattle: complete,
      playCinematic: complete,
    ).toExecutionCallbacks(applyConsequence: (_) => 'completed');

    expect(samples.keys, unorderedEquals(declaredIds));
    for (final entry in samples.entries) {
      final plan = buildSceneRuntimePlan(_sceneFor(entry.key, entry.value()));
      expect(plan.canBuild, isTrue, reason: entry.key);
      final result = await SceneRuntimeExecutor(callbacks: callbacks).execute(
        plan.plan!,
      );
      expect(
        result.status,
        SceneRuntimeExecutionStatus.completed,
        reason: entry.key,
      );
    }
    expect(
      invoked,
      containsAll([
        SceneRuntimePlanIntentKind.showDialogue,
        SceneRuntimePlanIntentKind.startBattle,
        SceneRuntimePlanIntentKind.playCinematic,
      ]),
    );
  });

  test('runtime parity excludes the deferred NPC presence pseudo-command', () {
    final descriptor = NarrativeCommandCatalog.canonical().byId(
      NarrativeCommandIds.setNpcPresence,
    )!;

    expect(descriptor.isPublishable, isFalse);
    expect(
      descriptor.capabilities.runtime,
      NarrativeCommandCapabilityStatus.unsupported,
    );
  });
}

Map<String, SceneConsequence Function()> _consequenceSamples() => {
      NarrativeCommandIds.setFact: () =>
          SceneConsequence.setFact(factId: 'fact_gate', value: true),
      NarrativeCommandIds.markEventConsumed: () =>
          SceneConsequence.markEventConsumed(
            mapId: 'map_test',
            eventId: 'event_gate',
          ),
      NarrativeCommandIds.completeStoryStep: () =>
          SceneConsequence.completeStoryStep(stepId: 'step_test'),
      NarrativeCommandIds.giveItem: () =>
          SceneConsequence.giveItem(itemId: 'potion', quantity: 1),
      NarrativeCommandIds.takeItem: () =>
          SceneConsequence.takeItem(itemId: 'ticket', quantity: 1),
      NarrativeCommandIds.giveMoney: () =>
          SceneConsequence.giveMoney(amount: 200),
      NarrativeCommandIds.givePokemon: () => SceneConsequence.givePokemon(
            speciesId: 'sproutle',
            level: 5,
            currentHp: 18,
          ),
      NarrativeCommandIds.giveConfiguredStarter: () =>
          SceneConsequence.giveConfiguredStarter(
            starterOptionId: 'starter_sproutle',
          ),
      NarrativeCommandIds.healParty: SceneConsequence.healParty,
      NarrativeCommandIds.awardBadge: () =>
          SceneConsequence.awardBadge(badgeId: 'badge_tide'),
      NarrativeCommandIds.unlockFieldAbility: () =>
          SceneConsequence.unlockFieldAbility(ability: FieldAbility.surf),
    };

Map<String, SceneInteractiveCommand Function()> _interactiveSamples() => {
      NarrativeCommandIds.warp: () => SceneInteractiveCommand.warp(
            destinationMapId: 'map_test',
            warpId: 'warp_arrival',
          ),
      NarrativeCommandIds.openShop: () =>
          SceneInteractiveCommand.openShop(shopId: 'shop_port'),
      NarrativeCommandIds.openPc: SceneInteractiveCommand.openPc,
    };

Map<String, SceneNodePayload Function()> _dedicatedSamples() => {
      NarrativeCommandIds.dialogue: () => SceneYarnDialoguePayload(
            dialogueId: 'dialogue_port',
          ),
      NarrativeCommandIds.trainerBattle: () => SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_port',
            declaredOutcomes: const ['victory'],
          ),
      NarrativeCommandIds.staticEncounter: () => SceneBattlePayload(
            battleKind: 'static',
            battleTemplateId: 'sproutle',
            declaredOutcomes: const ['victory'],
          ),
      NarrativeCommandIds.cinematic: () => SceneCinematicPayload(
            cinematicId: 'cinematic_port',
          ),
    };

ProjectManifest _project() => ProjectManifest(
      name: 'Runtime parity',
      maps: const [
        ProjectMapEntry(
          id: 'map_test',
          name: 'Map Test',
          relativePath: 'maps/map_test.json',
        ),
      ],
      tilesets: const [],
      facts: [
        NarrativeFactDefinition(id: 'fact_gate', label: 'Gate'),
      ],
      storylines: [
        StorylineAsset(
          id: 'story_test',
          type: StorylineType.main,
          status: StorylineStatus.active,
          title: 'Story Test',
          chapters: [
            StorylineChapter(
              id: 'chapter_test',
              title: 'Chapter',
              order: 0,
              steps: [
                StorylineStep(id: 'step_test', title: 'Step', order: 0),
              ],
            ),
          ],
        ),
      ],
      badges: const [
        BadgeDefinition(id: 'badge_tide', label: 'Badge Marée'),
      ],
      newGame: const ProjectNewGameConfig(
        starterOptions: [
          ProjectStarterOption(
            id: 'starter_sproutle',
            label: 'Sproutle',
            pokemon: PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              currentHp: 20,
            ),
          ),
        ],
      ),
    );

GameState _gameState() => const GameState(
      saveId: 'runtime_parity',
      trainerProfile: TrainerProfile(name: 'Leaf', money: 100),
      bag: Bag(
        entries: [
          BagEntry(itemId: 'ticket', categoryId: 'items', quantity: 2),
        ],
      ),
      party: PlayerParty(
        members: [
          PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            currentHp: 2,
            knownMoveIds: ['tackle'],
            currentPpByMoveId: {'tackle': 1},
          ),
        ],
      ),
    );

MapData _map() => const MapData(
      id: 'map_test',
      name: 'Map Test',
      size: GridSize(width: 4, height: 4),
      events: [
        MapEventDefinition(
          id: 'event_gate',
          position: EventPosition(layerId: 'base', x: 1, y: 1),
          pages: [MapEventPage(pageNumber: 0)],
        ),
      ],
    );

SceneAsset _sceneFor(String commandId, SceneNodePayload payload) {
  final (port, edgeKind) = switch (payload) {
    SceneBattlePayload() => ('victory', SceneEdgeKind.battleVictory),
    SceneCinematicPayload() => ('completed', SceneEdgeKind.cinematicCompleted),
    _ => ('completed', SceneEdgeKind.defaultFlow),
  };
  return SceneAsset(
    id: 'scene.runtime.parity.$commandId',
    name: 'Runtime parity $commandId',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'command', kind: payload.kind, payload: payload),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start-command',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'command',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'command-end',
          fromNodeId: 'command',
          fromPortId: port,
          toNodeId: 'end',
          kind: edgeKind,
        ),
      ],
    ),
  );
}
```
