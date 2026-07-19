# NSC-01 — Evidence Pack de l’index canonique des dépendances narratives

Date : 2026-07-19
Lot : `NSC-01 — Index canonique des dépendances narratives`
Branche : `main`
HEAD initial : `3789299bb24310642733c005b1124e635827b870`
Verdict : `PASS`

## Résultat

`map_core` expose désormais un index pur, immuable et déterministe des
définitions, usages et erreurs de références du Narrative Studio. Il couvre
New Game, maps et sources physiques, Event V2 et claims de migration, Scenes,
Storylines/Chapters/Steps, Dialogues, Cinematics, Facts, World Rules et
Scenarios/globalStory legacy.

L’index distingue `resolved`, `missing`, `ambiguous`, `unavailable` et
`legacyExternal`. Une map déclarée mais non chargée n’est jamais présentée
comme absente. Les requêtes par cible et par propriétaire sont pré-indexées,
les clés de source de map sont qualifiées par map/type/parent, et les cycles
Event/Scene sont détectés sans récursion de pile. Une fixture de 10 000 Events
confirme l’absence d’overflow et le déterminisme.

Cinq anciens walkers acceptent progressivement l’index via un paramètre
optionnel et conservent leur fallback historique. Le lot ne réalise pas encore
les mutations atomiques, l’undo/autosave, les routes UI ni l’indexation
incrémentale : ces responsabilités appartiennent respectivement à NSC-02,
NSC-10/11/13 et NSC-74.

## Audit initial

- les dépendances étaient réparties entre plusieurs walkers spécialisés ;
- les walkers n’avaient ni namespace commun, ni résolution commune, ni
  requête inverse exhaustive ;
- les suppressions, renommages et duplications futures ne pouvaient pas
  obtenir une liste canonique de consommateurs ;
- plusieurs familles étaient absentes de certains écrans : New Game, Event V2,
  claims legacy, conséquences Scene, Storyline relations, sources physiques de
  map, Cinematic bindings et Scenario actions ;
- `missing` et map non chargée étaient confondus selon le consumer ;
- les cycles et duplicats n’avaient pas de représentation commune ;
- les cinq read models historiques devaient rester compatibles pendant la
  migration.

### Inventaire préalable examiné

L’audit préalable a lu et comparé les sources existantes suivantes avant de
définir l’API ou les tests :

- contrat de lot :
  `docs/superpowers/plans/2026-07-19-nsc-01-narrative-dependency-index.md` ;
- matrice canonique :
  `reports/narrativeStudio/completion/ns_completion_capability_matrix.md` ;
- modèles source : `project_manifest.dart`, `project_new_game_config.dart`,
  `map_data.dart`, `map_event_definition.dart`,
  `narrative_event_definition.dart`, `narrative_event_registry.dart`,
  `narrative_event_source_ref.dart`, `scene_asset.dart`,
  `scene_consequence.dart`, `storyline_asset.dart`, `cinematic_asset.dart`,
  `world_rule.dart` et `scenario_asset.dart` ;
- walkers/read models existants : `project_dialogue_refs.dart`,
  `storyline_scene_links_read_model.dart`,
  `facts_world_rules_manager_read_model.dart`,
  `cinematics_library_read_model.dart` et
  `narrative_event_builder_project_read_model.dart` ;
- authoring/diagnostics utilisés pour trancher les frontières de domaine :
  `event_builder_authoring_operations.dart`,
  `narrative_scenario_authoring_draft.dart`,
  `cinematic_authoring_operations.dart`, `cinematic_diagnostics.dart`,
  `world_rule_diagnostics.dart` et `world_rule_projection.dart` ;
- tests de caractérisation correspondants :
  `project_dialogue_declared_outcomes_test.dart`,
  `storyline_scene_links_read_model_test.dart`,
  `facts_world_rules_manager_read_model_test.dart`,
  `cinematics_library_read_model_test.dart` et
  `narrative_event_builder_project_read_model_test.dart` ;
- rapport antérieur :
  `reports/gameplay/fg_000_narrative_studio_selbrume_capability_matrix.md`.

Cet inventaire explique notamment pourquoi deux alertes de la première passe
exhaustive ont été rejetées : elles contredisaient le contrat runtime et les
tests existants de WorldRule/Cinematic.

## Décisions et non-objectifs

- L’API vit dans `map_core` et n’importe ni Flutter, ni filesystem, ni routeur.
- Les clés sont structurées ; aucune concaténation de chaînes ne sert
  d’identité.
- Chapter et Step restent des namespaces globaux conformément au schema actuel.
- Les sources physiques sont qualifiées par map et type (`entity`, `event`,
  `trigger`, `gameplayZone`, `warp`).
- Les claims de migration ont leur propre propriétaire `legacySourceClaim` ;
  leurs sources, provenances et cibles Event V2 ne sont pas fusionnées avec le
  premier Event cible.
- Une configuration New Game désactivée reste indexée, avec criticité
  `authoringWarning`, car ses références persistent dans le projet.
- `WorldRuleSourceKind.consumedEvent` reste volontairement dans le namespace
  Map Event legacy. Le runtime lit `GameState.consumedEventIds`, pas la
  progression Event V2. Un support Event V2 demanderait un nouveau kind de
  schema explicite.
- `CinematicActorInitialPlacementKind.fromMapEntity` résout l’entité via
  `actorBindings[actorId].mapEntityId`. Un éventuel `placement.targetId` est une
  donnée superflue ignorée par le contrat courant et ne devient pas une fausse
  dépendance.
- Les références vers script de dialogue explicitement externalisé restent
  `legacyExternal` et ne ciblent pas à tort le registre Dialogue.
- Les cycles sont détectés par Kosaraju itératif O(V+E). L’index incrémental et
  les budgets temporels mesurés restent NSC-74.
- Aucun schema JSON, modèle runtime, fixture Selbrume ou donnée utilisateur
  n’est modifié par NSC-01.

## Fichiers du lot

### Créés

- `packages/map_core/lib/src/read_models/narrative_dependency_index.dart` :
  contrat public, builder, collecteurs, résolution, diagnostics et cycles.
- `packages/map_core/test/narrative_dependency_index_test.dart` : 38 tests du
  contrat, des collecteurs, des erreurs, de la charge et de la délégation.
- `reports/narrativeStudio/completion/nsc_01_narrative_dependency_index_evidence_pack.md` :
  le présent rapport.

Les contenus complets des deux fichiers code/test créés sont reproduits en
annexes A et B. Le présent Evidence Pack constitue lui-même le contenu complet
du troisième fichier créé.

### Modifiés

- `packages/map_core/lib/map_core.dart` : export public de l’index.
- `packages/map_core/lib/src/operations/project_dialogue_refs.dart` :
  délégation optionnelle du slice MapData.
- `packages/map_core/lib/src/read_models/storyline_scene_links_read_model.dart` :
  résolution canonique et gestion déterministe des Scenes dupliquées.
- `packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart` :
  usages Fact issus de l’index.
- `packages/map_core/lib/src/read_models/cinematics_library_read_model.dart` :
  usages Cinematic et résolutions canoniques.
- `packages/map_core/lib/src/read_models/narrative_event_builder_project_read_model.dart` :
  diagnostics canoniques Event Builder.
- `packages/map_core/test/storyline_scene_links_read_model_test.dart` :
  injection de l’index et ordre stable face aux duplicats.

### Délibérément inchangés

- tous les fichiers Selbrume préexistants, dont le test lighthouse déjà staged ;
- le schema `ProjectManifest` et ses codecs ;
- les packages Flutter `map_editor` et `map_runtime` ;
- la roadmap mécanique et les statuts FG ;
- le réaudit readiness non suivi du 19 juillet.

## Zones précises modifiées

| Fichier | Zone | Effet |
|---|---|---|
| `narrative_dependency_index.dart` | contrat public | kinds, résolutions, criticités, clés, définitions, usages, issues, navigation intent |
| `narrative_dependency_index.dart` | builder/collecteurs | New Game, maps, Events/claims, Scenes, Storylines, Cinematics, World Rules, legacy |
| `narrative_dependency_index.dart` | résolution | duplicats, missing/ambiguous/unavailable/legacyExternal et diagnostics |
| `narrative_dependency_index.dart` | cycles/tri | SCC itératives, ordre total et queries pré-indexées |
| `map_core.dart` | barrel | export de la nouvelle API publique |
| cinq walkers historiques | signatures/builders | `dependencyIndex` optionnel et fallback compatible |
| `storyline_scene_links_read_model_test.dart` | tests de délégation | résolution cassée et duplicats indépendants de l’ordre |

Le diff unifié des sept fichiers modifiés est reproduit en annexe C. Seuls les
espaces porteurs des lignes de contexte entièrement vides sont retirés afin que
le rapport passe `git diff --check` ; les zones et lignes modifiées sont
reproduites intégralement.

## Passes indépendantes

| Passe | Verdict | Résultat |
|---|---|---|
| Audit initial | `NEEDS_IMPLEMENTATION` | walkers fragmentés et familles omises |
| Implémentation TDD | `PASS` | 5 slices, 38 tests dédiés |
| Tests | `PASS` | 38 tests dédiés, 66 ciblés et 3 104 package |
| Build | `N/A` | `map_core` est une bibliothèque Dart pure sans cible applicative autonome |
| Validation | `PASS avec réserve de format globale` | analyse verte ; neuf fichiers du lot formatés ; dette préexistante hors lot |
| Revue spécification initiale | `NEEDS_CHANGES` | liens Chapter directs, zones/warps, overrides Dialogue, indisponibilité legacy |
| Revue qualité initiale | `NEEDS_CHANGES` | faux cycles, alias, collisions de clés, scans, edges fantômes, tri incomplet |
| Revue exhaustive intermédiaire | `NEEDS_CHANGES` | claims legacy, spawn, completeStep ; deux alertes domaine ensuite rejetées par preuve |
| Revue exhaustive finale | `NEEDS_CHANGES` puis `PASS` | New Game disabled et `sourceStorylineId` ajoutés ; aucun blocker restant |
| Revue spécification finale | `PASS` | contrat et frontières legacy/V2 conformes |
| Revue qualité finale | `PASS` | résolution, déterminisme, clés et 10 000 entrées conformes |

Toutes les passes finales ont été effectuées en lecture seule par trois agents
indépendants. Aucun de leurs runs n’a modifié les fichiers.

## TDD — preuves RED puis GREEN

### RED initial du contrat

Avant l’implémentation, le test dédié échouait au chargement car
`NarrativeDependencyIndex`, ses enums, ses clés et son builder n’existaient pas.
Les slices suivantes ont ajouté leurs assertions avant chaque collecteur.

### RED de la passe exhaustive

Commande :

```bash
cd packages/map_core && dart test test/narrative_dependency_index_test.dart
```

Résultat exact avant les trois corrections finales :

```text
Failed to load test/narrative_dependency_index_test.dart:
Member not found: NarrativeDependencyKey.legacySourceClaim
Couldn't find constructor NarrativeDependencyKey.legacyScenarioNode
exit_code=1
```

Après les premiers correctifs, les deux derniers tests RED donnaient :

```text
New Game ... keeps disabled New Game references as authoring dependencies [E]
Expected 5 chemins, Actual: []
Storyline ... indexes Storyline links, relationships, anchors and effects [E]
Bad state: No element pour relationships[0].sourceStorylineId
+36 -2: Some tests failed.
exit_code=1
```

### GREEN dédié final

```bash
cd packages/map_core && dart test test/narrative_dependency_index_test.dart
```

```text
+38: All tests passed!
exit_code=0
```

## Commandes et résultats exacts

### État Git initial

```text
 M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
A  examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart
 M examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart
 M packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart
 M packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart
 M selbrume/project.json
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md
```

Ces changements préexistaient avant NSC-01. Ils restent hors du commit. Le test
lighthouse pré-stagé reste staged et non commité grâce à `git commit --only`.

### Format limité au lot

```bash
cd packages/map_core && dart format --output=none --set-exit-if-changed \
  lib/map_core.dart \
  lib/src/read_models/narrative_dependency_index.dart \
  lib/src/operations/project_dialogue_refs.dart \
  lib/src/read_models/storyline_scene_links_read_model.dart \
  lib/src/read_models/facts_world_rules_manager_read_model.dart \
  lib/src/read_models/cinematics_library_read_model.dart \
  lib/src/read_models/narrative_event_builder_project_read_model.dart \
  test/narrative_dependency_index_test.dart \
  test/storyline_scene_links_read_model_test.dart
```

```text
Formatted 9 files (0 changed) in 0.05 seconds.
exit_code=0
```

### Suite ciblée de compatibilité

```bash
cd packages/map_core && dart test \
  test/narrative_dependency_index_test.dart \
  test/project_dialogue_declared_outcomes_test.dart \
  test/storyline_scene_links_read_model_test.dart \
  test/facts_world_rules_manager_read_model_test.dart \
  test/cinematics_library_read_model_test.dart \
  test/narrative_event_builder_project_read_model_test.dart
```

```text
+66: All tests passed!
exit_code=0
```

### Suite complète

```bash
cd packages/map_core && dart test
```

```text
+3104: All tests passed!
exit_code=0
```

### Analyse statique

```bash
cd packages/map_core && dart analyze
```

```text
Analyzing map_core...
No issues found!
exit_code=0
```

### Build applicatif

`N/A` : `packages/map_core` est une bibliothèque Dart pure. Elle ne contient
ni application, ni executable, ni bundle autonome à construire. Le dépôt ne
définit donc pas de commande de build applicatif pertinente pour ce lot. Les
validations alternatives exécutées sont la suite dédiée, la suite ciblée, la
suite complète `dart test` et `dart analyze`.

### Contrôle de format global — réserve préexistante

```bash
cd packages/map_core && dart format --output=none --set-exit-if-changed lib test
```

```text
Changed 67 fichiers hors lot.
Formatted 507 files (67 changed) in 2.38 seconds.
exit_code=1
```

Le mode `--output=none` n’a écrit aucun fichier. Les 67 fichiers signalés sont
hors du lot NSC-01 ; les reformater aurait créé un changement massif sans lien
avec l’objectif. Les neuf fichiers touchés par NSC-01 passent séparément le
même gate avec exit 0. Cette dette de format globale est une limite connue et
non un échec fonctionnel du lot.

### Diff check

```bash
git diff --check -- <sept fichiers modifiés>
git diff --no-index --check /dev/null packages/map_core/lib/src/read_models/narrative_dependency_index.dart
git diff --no-index --check /dev/null packages/map_core/test/narrative_dependency_index_test.dart
git diff --no-index --check /dev/null reports/narrativeStudio/completion/nsc_01_narrative_dependency_index_evidence_pack.md
```

```text
sept fichiers modifiés : aucune sortie, exit_code=0
fichier index créé       : aucune sortie, exit_code=1 attendu (diff présent)
fichier test créé        : aucune sortie, exit_code=1 attendu (diff présent)
Evidence Pack créé       : aucune sortie, exit_code=1 attendu (diff présent)
```

Pour `git diff --no-index --check`, le code `1` signifie que `/dev/null` et le
fichier créé diffèrent. Une erreur whitespace aurait produit un diagnostic et
un code supérieur ; aucune sortie n’a été produite pour ces trois commandes.

### Intégrité des annexes

Les contenus ont été extraits des fences du présent rapport et comparés aux
sources sans créer de fichier temporaire :

```text
narrative_dependency_index.dart
  source  : 9ad319d4e6105595c4de1bc38f97b10a0af42d0e7c38508523cab0bfa0fd6c94
  annexe A: 9ad319d4e6105595c4de1bc38f97b10a0af42d0e7c38508523cab0bfa0fd6c94
narrative_dependency_index_test.dart
  source  : f949baa03b6af2bb1776dde56aa3301bc0d6426a99ca3e34c8e52e9652c520b9
  annexe B: f949baa03b6af2bb1776dde56aa3301bc0d6426a99ca3e34c8e52e9652c520b9
diff des sept fichiers modifiés
  git diff: 609f03e39ffe058e4f2de664ca11eb2aea400fe626c4205b2a7fca5e36c76a21
  annexe C normalisée: 88e8e0d02bb74729d0cbd4690c0cb55825c7c8a4bca08179d7f2ffced6433207
```

## État Git final avant commit isolé

Commande :

```bash
git status --short --untracked-files=all
```

```text
 M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
A  examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart
 M examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/operations/project_dialogue_refs.dart
 M packages/map_core/lib/src/read_models/cinematics_library_read_model.dart
 M packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart
 M packages/map_core/lib/src/read_models/narrative_event_builder_project_read_model.dart
 M packages/map_core/lib/src/read_models/storyline_scene_links_read_model.dart
 M packages/map_core/test/storyline_scene_links_read_model_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart
 M packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart
 M packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart
 M selbrume/project.json
?? packages/map_core/lib/src/read_models/narrative_dependency_index.dart
?? packages/map_core/test/narrative_dependency_index_test.dart
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md
?? reports/narrativeStudio/completion/nsc_01_narrative_dependency_index_evidence_pack.md
```

Les neuf chemins code/test et l’Evidence Pack sont les seuls chemins destinés
au commit NSC-01. Les autres entrées restent explicitement exclues.

## Auto-critique et risques

- Le builder reconstruit tout l’index ; une mutation locale incrémentale reste
  NSC-74.
- Les navigation intents sont neutres et testables, mais leur traduction en
  routes UI appartient à NSC-10.
- Les cinq read models migrent progressivement ; leurs fallbacks demeurent
  pour compatibilité et pourront diverger si un nouveau type de référence est
  ajouté sans étendre simultanément NSC-01.
- `sourceMap` accueille aussi des identités legacy/migration faute de kinds
  publics supplémentaires. Les qualifiers structurés empêchent les collisions,
  mais les consumers doivent toujours comparer la clé complète.
- Les règles WorldRule Event V2 sont volontairement non inventées. Le besoin
  produit futur doit passer par un nouveau contrat runtime/schema.
- Le dépôt contient une dette de format globale sur 67 fichiers hors lot.
- Le lot rend les consommateurs visibles ; il ne rend pas encore les
  opérations de suppression/renommage atomiques. Cette garantie appartient à
  NSC-02.

## Statut proposé

`NSC-01 : DONE` — index canonique, collecteurs connus, résolutions,
diagnostics, queries, cycles stack-safe, délégation progressive, tests,
analyse et trois revues finales sont verts. Réserve indépendante : format
global préexistant hors lot.

## Annexe A — contenu complet du fichier créé

`packages/map_core/lib/src/read_models/narrative_dependency_index.dart` :

````dart
import 'dart:collection';

import 'package:meta/meta.dart' show immutable;

import '../authoring/storyline_legacy_import_preview.dart';
import '../models/map_data.dart';
import '../models/enums.dart';
import '../models/cinematic_asset.dart';
import '../models/map_entity_payloads.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/script_conditions.dart';
import '../models/storyline_asset.dart';
import '../models/world_rule.dart';

/// Canonical namespaces used by Narrative Studio dependency consumers.
enum NarrativeDependencyTargetKind {
  fact,
  eventV2,
  scene,
  dialogue,
  cinematic,
  storyline,
  chapter,
  step,
  worldRule,
  sourceMap,
}

enum NarrativeDependencyResolution {
  resolved,
  missing,
  ambiguous,
  unavailable,
  legacyExternal,
}

enum NarrativeDependencyCriticality {
  informational,
  authoringWarning,
  runtimeBlocking,
}

enum NarrativeDependencyIssueKind {
  missingReference,
  ambiguousReference,
  unavailableReference,
  duplicateId,
  forbiddenCycle,
}

@immutable
final class NarrativeDependencyKey {
  const NarrativeDependencyKey(
    this.kind,
    this.id, {
    this.scope,
    this.parentId,
    this.sourceKind,
  });

  final NarrativeDependencyTargetKind kind;
  final String id;
  final String? scope;
  final String? parentId;
  final String? sourceKind;

  const NarrativeDependencyKey.map(String mapId)
      : this(
          NarrativeDependencyTargetKind.sourceMap,
          mapId,
          scope: _physicalMapScope,
          parentId: mapId,
          sourceKind: 'map',
        );

  const NarrativeDependencyKey.mapSource({
    required String mapId,
    required String sourceKind,
    required String sourceId,
  }) : this(
          NarrativeDependencyTargetKind.sourceMap,
          sourceId,
          scope: _physicalMapScope,
          parentId: mapId,
          sourceKind: sourceKind,
        );

  const NarrativeDependencyKey.scene(String sceneId)
      : this(NarrativeDependencyTargetKind.scene, sceneId);

  const NarrativeDependencyKey.eventV2(String eventId)
      : this(NarrativeDependencyTargetKind.eventV2, eventId);

  const NarrativeDependencyKey.projectNewGame()
      : this(
          NarrativeDependencyTargetKind.sourceMap,
          'newGame',
          scope: 'project',
          sourceKind: 'newGame',
        );

  const NarrativeDependencyKey.legacyScenario(String scenarioId)
      : this(
          NarrativeDependencyTargetKind.sourceMap,
          scenarioId,
          scope: 'legacy',
          sourceKind: 'scenario',
        );

  const NarrativeDependencyKey.legacyScenarioNode({
    required String scenarioId,
    required String nodeId,
  }) : this(
          NarrativeDependencyTargetKind.sourceMap,
          nodeId,
          scope: 'legacy',
          parentId: scenarioId,
          sourceKind: 'scenarioNode',
        );

  const NarrativeDependencyKey.legacySourceClaim(String cohortId)
      : this(
          NarrativeDependencyTargetKind.sourceMap,
          cohortId,
          scope: 'migration',
          sourceKind: 'legacySourceClaim',
        );

  const NarrativeDependencyKey.legacyGlobalStoryPart({
    required String scenarioId,
    required String partKind,
    required String partId,
  }) : this(
          NarrativeDependencyTargetKind.sourceMap,
          partId,
          scope: 'legacy',
          parentId: scenarioId,
          sourceKind: partKind,
        );

  const NarrativeDependencyKey.synthetic({
    required String sourceKind,
    required String sourceId,
    String? parentId,
  }) : this(
          NarrativeDependencyTargetKind.sourceMap,
          sourceId,
          scope: 'synthetic',
          parentId: parentId,
          sourceKind: sourceKind,
        );

  /// Owning map for a physical map root or child source, if this key is one.
  String? get physicalMapId {
    if (kind != NarrativeDependencyTargetKind.sourceMap) return null;
    if (scope == _physicalMapScope) return parentId;
    return null;
  }

  bool get isPhysicalMapSource => physicalMapId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeDependencyKey &&
          other.kind == kind &&
          other.id == id &&
          other.scope == scope &&
          other.parentId == parentId &&
          other.sourceKind == sourceKind;

  @override
  int get hashCode => Object.hash(kind, id, scope, parentId, sourceKind);

  @override
  String toString() {
    final qualifiers = <String>[
      if (scope != null) 'scope=$scope',
      if (parentId != null) 'parent=$parentId',
      if (sourceKind != null) 'sourceKind=$sourceKind',
    ];
    return qualifiers.isEmpty
        ? '${kind.name}:$id'
        : '${kind.name}:$id (${qualifiers.join(', ')})';
  }
}

/// Package-neutral destination. The editor may translate it to its own route.
@immutable
final class NarrativeDependencyNavigationIntent {
  const NarrativeDependencyNavigationIntent({
    required this.kind,
    required this.assetId,
    this.parentId,
    this.context,
  });

  final NarrativeDependencyTargetKind kind;
  final String assetId;
  final String? parentId;
  final String? context;
}

@immutable
final class NarrativeDependencyDefinition {
  NarrativeDependencyDefinition({
    required this.key,
    required this.label,
    this.owner,
    this.path,
    this.navigationIntent,
    Map<String, String> metadata = const <String, String>{},
  }) : metadata = Map<String, String>.unmodifiable(metadata);

  final NarrativeDependencyKey key;
  final String label;
  final NarrativeDependencyKey? owner;
  final String? path;
  final NarrativeDependencyNavigationIntent? navigationIntent;
  final Map<String, String> metadata;
}

@immutable
final class NarrativeDependencyUsage {
  const NarrativeDependencyUsage({
    required this.target,
    required this.owner,
    required this.path,
    required this.criticality,
    this.resolution = NarrativeDependencyResolution.resolved,
    this.navigationIntent,
  });

  final NarrativeDependencyKey target;
  final NarrativeDependencyKey owner;
  final String path;
  final NarrativeDependencyCriticality criticality;
  final NarrativeDependencyResolution resolution;
  final NarrativeDependencyNavigationIntent? navigationIntent;

  NarrativeDependencyUsage withResolution(
    NarrativeDependencyResolution value,
  ) {
    return NarrativeDependencyUsage(
      target: target,
      owner: owner,
      path: path,
      criticality: criticality,
      resolution: value,
      navigationIntent: navigationIntent,
    );
  }
}

@immutable
final class NarrativeDependencyIssue {
  const NarrativeDependencyIssue({
    required this.kind,
    required this.target,
    required this.criticality,
    required this.message,
    this.owner,
    this.path,
  });

  final NarrativeDependencyIssueKind kind;
  final NarrativeDependencyKey target;
  final NarrativeDependencyCriticality criticality;
  final String message;
  final NarrativeDependencyKey? owner;
  final String? path;
}

@immutable
final class NarrativeDependencyIndex {
  factory NarrativeDependencyIndex({
    Iterable<NarrativeDependencyDefinition> definitions =
        const <NarrativeDependencyDefinition>[],
    Iterable<NarrativeDependencyUsage> usages =
        const <NarrativeDependencyUsage>[],
    Iterable<NarrativeDependencyIssue> issues =
        const <NarrativeDependencyIssue>[],
  }) {
    final sortedDefinitions = definitions.toList()..sort(_compareDefinitions);
    final sortedUsages = usages.toList()..sort(_compareUsages);
    final sortedIssues = issues.toList()..sort(_compareIssues);
    return NarrativeDependencyIndex._(
      definitions: sortedDefinitions,
      usages: sortedUsages,
      issues: sortedIssues,
      definitionsByKey: _groupDefinitionsByKey(sortedDefinitions),
      usagesByTarget: _groupUsagesByTarget(sortedUsages),
      usagesByOwner: _groupUsagesByOwner(sortedUsages),
    );
  }

  NarrativeDependencyIndex._({
    required List<NarrativeDependencyDefinition> definitions,
    required List<NarrativeDependencyUsage> usages,
    required List<NarrativeDependencyIssue> issues,
    required Map<NarrativeDependencyKey, List<NarrativeDependencyDefinition>>
        definitionsByKey,
    required Map<NarrativeDependencyKey, List<NarrativeDependencyUsage>>
        usagesByTarget,
    required Map<NarrativeDependencyKey, List<NarrativeDependencyUsage>>
        usagesByOwner,
  })  : definitions = UnmodifiableListView(definitions),
        usages = UnmodifiableListView(usages),
        issues = UnmodifiableListView(issues),
        _definitionsByKey = UnmodifiableMapView(definitionsByKey),
        _usagesByTarget = UnmodifiableMapView(usagesByTarget),
        _usagesByOwner = UnmodifiableMapView(usagesByOwner);

  final List<NarrativeDependencyDefinition> definitions;
  final List<NarrativeDependencyUsage> usages;
  final List<NarrativeDependencyIssue> issues;
  final Map<NarrativeDependencyKey, List<NarrativeDependencyDefinition>>
      _definitionsByKey;
  final Map<NarrativeDependencyKey, List<NarrativeDependencyUsage>>
      _usagesByTarget;
  final Map<NarrativeDependencyKey, List<NarrativeDependencyUsage>>
      _usagesByOwner;

  List<NarrativeDependencyDefinition> definitionsFor(
    NarrativeDependencyKey key,
  ) {
    return _definitionsByKey[key] ?? const <NarrativeDependencyDefinition>[];
  }

  List<NarrativeDependencyUsage> usagesFor(NarrativeDependencyKey key) {
    return _usagesByTarget[key] ?? const <NarrativeDependencyUsage>[];
  }

  List<NarrativeDependencyUsage> usagesOwnedBy(
    NarrativeDependencyKey owner,
  ) {
    return _usagesByOwner[owner] ?? const <NarrativeDependencyUsage>[];
  }
}

NarrativeDependencyIndex buildNarrativeDependencyIndex({
  required ProjectManifest project,
  List<MapData> maps = const <MapData>[],
}) {
  return _NarrativeDependencyIndexBuilder(project, maps).build();
}

final class _NarrativeDependencyIndexBuilder {
  _NarrativeDependencyIndexBuilder(this.project, List<MapData> maps)
      : maps = List<MapData>.unmodifiable(maps);

  final ProjectManifest project;
  final List<MapData> maps;
  final List<NarrativeDependencyDefinition> _definitions = [];
  final List<NarrativeDependencyUsage> _usages = [];
  final List<NarrativeDependencyIssue> _issues = [];
  final List<(String, String)> _eventCycleEdges = [];

  NarrativeDependencyIndex build() {
    _collectProjectDefinitions();
    _collectMaps();
    _collectNewGame();
    _collectEvents();
    _collectLegacyClaims();
    _collectScenes();
    _collectStorylines();
    _collectCinematics();
    _collectWorldRules();
    _collectLegacyScenarios();
    _collectCycleIssues();
    return _resolve();
  }

  void _collectProjectDefinitions() {
    for (final map in project.maps) {
      _definition(
        NarrativeDependencyTargetKind.sourceMap,
        map.id,
        map.name,
        path: 'maps[${map.id}]',
        scope: _physicalMapScope,
        parentId: map.id,
        sourceKind: 'map',
      );
    }
    for (final fact in project.facts) {
      _definition(
        NarrativeDependencyTargetKind.fact,
        fact.id,
        fact.label,
        path: 'facts[${fact.id}]',
      );
    }
    for (final dialogue in project.dialogues) {
      _definition(
        NarrativeDependencyTargetKind.dialogue,
        dialogue.id,
        dialogue.name,
        path: 'dialogues[${dialogue.id}]',
      );
    }
    for (final scene in project.scenes) {
      _definition(
        NarrativeDependencyTargetKind.scene,
        scene.id,
        scene.name,
        path: 'scenes[${scene.id}]',
      );
    }
    for (final cinematic in project.cinematics) {
      _definition(
        NarrativeDependencyTargetKind.cinematic,
        cinematic.id,
        cinematic.title,
        path: 'cinematics[${cinematic.id}]',
      );
    }
    for (final storyline in project.storylines) {
      final storylineKey = _definition(
        NarrativeDependencyTargetKind.storyline,
        storyline.id,
        storyline.title,
        path: 'storylines[${storyline.id}]',
      );
      for (final chapter in storyline.chapters) {
        final chapterKey = _definition(
          NarrativeDependencyTargetKind.chapter,
          chapter.id,
          chapter.title,
          owner: storylineKey,
          path: 'storylines[${storyline.id}].chapters[${chapter.id}]',
        );
        for (final step in chapter.steps) {
          _definition(
            NarrativeDependencyTargetKind.step,
            step.id,
            step.title,
            owner: chapterKey,
            path:
                'storylines[${storyline.id}].chapters[${chapter.id}].steps[${step.id}]',
          );
        }
      }
    }
    for (final rule in project.worldRules) {
      _definition(
        NarrativeDependencyTargetKind.worldRule,
        rule.id,
        rule.label,
        path: 'worldRules[${rule.id}]',
      );
    }
    for (final record
        in project.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
      final label = record.when(
        draft: (draft) => draft.name,
        configured: (definition, _) => definition.name,
      );
      _definition(
        NarrativeDependencyTargetKind.eventV2,
        record.id,
        label,
        path: 'eventRegistry.records[${record.id}]',
      );
    }
  }

  void _collectNewGame() {
    final config = project.newGame;
    final criticality = config.enabled
        ? NarrativeDependencyCriticality.runtimeBlocking
        : NarrativeDependencyCriticality.authoringWarning;
    final startMapId = config.startMapId.trim();
    if (startMapId.isNotEmpty) {
      _usage(
        target: _mapKey(startMapId),
        owner: _newGameOwner,
        path: 'newGame.startMapId',
        criticality: criticality,
      );
    }
    final startSpawnId = config.startSpawnId?.trim();
    if (startMapId.isNotEmpty &&
        startSpawnId != null &&
        startSpawnId.isNotEmpty) {
      _usage(
        target: _mapSourceChildKey(startMapId, 'entity', startSpawnId),
        owner: _newGameOwner,
        path: 'newGame.startSpawnId',
        criticality: criticality,
      );
    }
    final factIds = config.initialFacts.keys.toList()..sort();
    for (final factId in factIds) {
      if (factId.trim().isEmpty) continue;
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.fact,
          factId,
        ),
        owner: _newGameOwner,
        path: 'newGame.initialFacts[$factId]',
        criticality: criticality,
      );
    }
    final existingPartyFactId = config.existingPartyFactId?.trim();
    if (existingPartyFactId != null && existingPartyFactId.isNotEmpty) {
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.fact,
          existingPartyFactId,
        ),
        owner: _newGameOwner,
        path: 'newGame.existingPartyFactId',
        criticality: criticality,
      );
    }
    final starterSceneId = config.starterSelectionSceneId?.trim();
    if (starterSceneId != null && starterSceneId.isNotEmpty) {
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.scene,
          starterSceneId,
        ),
        owner: _newGameOwner,
        path: 'newGame.starterSelectionSceneId',
        criticality: criticality,
      );
    }
  }

  void _collectMaps() {
    for (final map in maps) {
      final mapKey = _mapKey(map.id);
      if (!project.maps.any((entry) => entry.id == map.id)) {
        _definition(
          NarrativeDependencyTargetKind.sourceMap,
          map.id,
          map.name,
          path: 'maps[${map.id}]',
          scope: _physicalMapScope,
          parentId: map.id,
          sourceKind: 'map',
        );
      }
      for (var index = 0; index < map.entities.length; index++) {
        final entity = map.entities[index];
        final owner = _definition(
          NarrativeDependencyTargetKind.sourceMap,
          entity.id,
          entity.inspectorHeadline,
          owner: mapKey,
          path: 'maps[${map.id}].entities[$index]',
          scope: _physicalMapScope,
          parentId: map.id,
          sourceKind: 'entity',
        );
        if (entity.kind == MapEntityKind.npc) {
          final npc = entity.npc;
          if (npc != null) {
            _collectAuthoredDialogueRef(
              npc.dialogue,
              owner,
              'maps[${map.id}].entities[$index].npc.dialogue',
            );
            _collectAuthoredDialogueRef(
              npc.defeatDialogueRef,
              owner,
              'maps[${map.id}].entities[$index].npc.defeatDialogueRef',
            );
            final visibilityPredicate = npc.visibilityRule?.predicate;
            if (visibilityPredicate != null) {
              _collectMapPredicate(
                visibilityPredicate,
                owner,
                'maps[${map.id}].entities[$index].npc.visibilityRule.predicate',
              );
            }
            for (var conditionalIndex = 0;
                conditionalIndex < npc.conditionalDialogues.length;
                conditionalIndex++) {
              final conditional = npc.conditionalDialogues[conditionalIndex];
              final prefix =
                  'maps[${map.id}].entities[$index].npc.conditionalDialogues[$conditionalIndex]';
              _collectMapPredicate(conditional.when, owner, '$prefix.when');
              _collectAuthoredDialogueRef(
                conditional.dialogue,
                owner,
                '$prefix.dialogue',
              );
            }
          }
        } else if (entity.kind == MapEntityKind.sign) {
          _collectAuthoredDialogueRef(
            entity.sign?.dialogue,
            owner,
            'maps[${map.id}].entities[$index].sign.dialogue',
          );
        }
      }
      for (var index = 0; index < map.placedElements.length; index++) {
        final element = map.placedElements[index];
        final owner = _definition(
          NarrativeDependencyTargetKind.sourceMap,
          element.id,
          element.id,
          owner: mapKey,
          path: 'maps[${map.id}].placedElements[$index]',
          scope: _physicalMapScope,
          parentId: map.id,
          sourceKind: 'element',
        );
        for (var behaviorIndex = 0;
            behaviorIndex < element.behaviors.length;
            behaviorIndex++) {
          _collectAuthoredDialogueRef(
            element.behaviors[behaviorIndex].effect.dialogue,
            owner,
            'maps[${map.id}].placedElements[$index].behaviors[$behaviorIndex].effect.dialogue',
          );
        }
      }
      for (var index = 0; index < map.gameplayZones.length; index++) {
        final zone = map.gameplayZones[index];
        _definition(
          NarrativeDependencyTargetKind.sourceMap,
          zone.id,
          zone.name.trim().isEmpty ? zone.id : zone.name,
          owner: mapKey,
          path: 'maps[${map.id}].gameplayZones[$index]',
          scope: _physicalMapScope,
          parentId: map.id,
          sourceKind: 'gameplayZone',
        );
      }
      for (var index = 0; index < map.triggers.length; index++) {
        final trigger = map.triggers[index];
        _definition(
          NarrativeDependencyTargetKind.sourceMap,
          trigger.id,
          trigger.name.trim().isEmpty ? trigger.id : trigger.name,
          owner: mapKey,
          path: 'maps[${map.id}].triggers[$index]',
          scope: _physicalMapScope,
          parentId: map.id,
          sourceKind: 'trigger',
        );
      }
      for (var index = 0; index < map.events.length; index++) {
        final event = map.events[index];
        final owner = _definition(
          NarrativeDependencyTargetKind.sourceMap,
          event.id,
          event.title.trim().isEmpty ? event.id : event.title,
          owner: mapKey,
          path: 'maps[${map.id}].events[$index]',
          scope: _physicalMapScope,
          parentId: map.id,
          sourceKind: 'event',
        );
        _definition(
          NarrativeDependencyTargetKind.sourceMap,
          event.id,
          event.title.trim().isEmpty ? event.id : event.title,
          owner: owner,
          path: 'maps[${map.id}].events[$index].globalAlias',
          scope: 'synthetic',
          sourceKind: 'legacyMapEvent',
        );
        for (var pageIndex = 0; pageIndex < event.pages.length; pageIndex++) {
          final page = event.pages[pageIndex];
          final prefix = 'maps[${map.id}].events[$index].pages[$pageIndex]';
          final sceneId = page.sceneTarget?.sceneId.trim();
          if (sceneId != null && sceneId.isNotEmpty) {
            _usage(
              target: NarrativeDependencyKey(
                NarrativeDependencyTargetKind.scene,
                sceneId,
              ),
              owner: owner,
              path: '$prefix.sceneTarget.sceneId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
          }
          final condition = page.condition;
          if (condition != null) {
            _collectScriptCondition(
              condition,
              owner,
              '$prefix.condition',
              mapId: map.id,
            );
          }
        }
      }
      for (var index = 0; index < map.warps.length; index++) {
        final warp = map.warps[index];
        final owner = _definition(
          NarrativeDependencyTargetKind.sourceMap,
          warp.id,
          warp.id,
          owner: mapKey,
          path: 'maps[${map.id}].warps[$index]',
          scope: _physicalMapScope,
          parentId: map.id,
          sourceKind: 'warp',
        );
        _usage(
          target: _mapKey(warp.targetMapId),
          owner: owner,
          path: 'maps[${map.id}].warps[$index].targetMapId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      }
      for (var index = 0; index < map.connections.length; index++) {
        _usage(
          target: _mapKey(map.connections[index].targetMapId),
          owner: mapKey,
          path: 'maps[${map.id}].connections[$index].targetMapId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
      }
    }
  }

  void _collectAuthoredDialogueRef(
    DialogueRef? reference,
    NarrativeDependencyKey owner,
    String path,
  ) {
    if (reference == null) return;
    final scriptPath = reference.scriptPathRelative.trim();
    if (scriptPath.isNotEmpty) {
      _usage(
        target: NarrativeDependencyKey.synthetic(
          sourceKind: 'legacyDialogueScript',
          sourceId: scriptPath,
          parentId: reference.dialogueId.trim().isEmpty
              ? null
              : reference.dialogueId.trim(),
        ),
        owner: owner,
        path: '$path.scriptPathRelative',
        criticality: NarrativeDependencyCriticality.informational,
        resolution: NarrativeDependencyResolution.legacyExternal,
      );
      return;
    }
    _collectDialogueRef(reference.dialogueId, owner, '$path.dialogueId');
  }

  void _collectDialogueRef(
    String? rawDialogueId,
    NarrativeDependencyKey owner,
    String path,
  ) {
    final dialogueId = rawDialogueId?.trim();
    if (dialogueId == null || dialogueId.isEmpty) return;
    _usage(
      target: NarrativeDependencyKey(
        NarrativeDependencyTargetKind.dialogue,
        dialogueId,
      ),
      owner: owner,
      path: path,
      criticality: NarrativeDependencyCriticality.runtimeBlocking,
    );
  }

  void _collectMapPredicate(
    MapEntityRuntimePredicate predicate,
    NarrativeDependencyKey owner,
    String path,
  ) {
    final kind = predicate.kind;
    final sourceId = predicate.refId.trim();
    if (sourceId.isEmpty) return;
    switch (kind) {
      case MapEntityRuntimePredicateKind.storyFlagSet:
      case MapEntityRuntimePredicateKind.storyFlagUnset:
        _collectLegacyFactRef(sourceId, owner, '$path.refId');
      case MapEntityRuntimePredicateKind.stepCompleted:
      case MapEntityRuntimePredicateKind.stepNotCompleted:
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.step,
            sourceId,
          ),
          owner: owner,
          path: '$path.refId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      case MapEntityRuntimePredicateKind.chapterCompleted:
      case MapEntityRuntimePredicateKind.chapterNotCompleted:
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.chapter,
            sourceId,
          ),
          owner: owner,
          path: '$path.refId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      case MapEntityRuntimePredicateKind.cutsceneCompleted:
      case MapEntityRuntimePredicateKind.cutsceneNotCompleted:
        _usage(
          target: NarrativeDependencyKey.legacyScenario(sourceId),
          owner: owner,
          path: '$path.refId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
          resolution: NarrativeDependencyResolution.legacyExternal,
        );
    }
  }

  void _collectLegacyFactRef(
    String sourceId,
    NarrativeDependencyKey owner,
    String path,
  ) {
    final matchingIds = project.facts
        .where((fact) => fact.id == sourceId || fact.legacyFlagName == sourceId)
        .map((fact) => fact.id)
        .toSet();
    if (matchingIds.length == 1) {
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.fact,
          matchingIds.single,
        ),
        owner: owner,
        path: path,
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
      return;
    }
    _usage(
      target: NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        sourceId,
        scope: matchingIds.isEmpty ? null : 'legacyAlias',
      ),
      owner: owner,
      path: path,
      criticality: NarrativeDependencyCriticality.authoringWarning,
      resolution: matchingIds.isEmpty
          ? NarrativeDependencyResolution.legacyExternal
          : NarrativeDependencyResolution.ambiguous,
    );
  }

  void _collectScriptCondition(
    ScriptCondition root,
    NarrativeDependencyKey owner,
    String rootPath, {
    String? mapId,
  }) {
    final pending = <(ScriptCondition, String)>[(root, rootPath)];
    for (var cursor = 0; cursor < pending.length; cursor++) {
      final (condition, path) = pending[cursor];
      switch (condition.type) {
        case ScriptConditionType.flagIsSet:
        case ScriptConditionType.flagIsUnset:
          final flag = condition.params[ScriptConditionParams.flagName]?.trim();
          if (flag != null && flag.isNotEmpty) {
            _collectLegacyFactRef(flag, owner, '$path.params.flagName');
          }
        case ScriptConditionType.eventIsConsumed:
          final eventId =
              condition.params[ScriptConditionParams.eventId]?.trim();
          if (eventId != null && eventId.isNotEmpty) {
            _usage(
              target: mapId == null
                  ? NarrativeDependencyKey.synthetic(
                      sourceKind: 'legacyMapEvent',
                      sourceId: eventId,
                    )
                  : _mapSourceChildKey(mapId, 'event', eventId),
              owner: owner,
              path: '$path.params.eventId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
          }
        case ScriptConditionType.playerOnMap:
          final targetMapId =
              condition.params[ScriptConditionParams.mapId]?.trim();
          if (targetMapId != null && targetMapId.isNotEmpty) {
            _usage(
              target: _mapKey(targetMapId),
              owner: owner,
              path: '$path.params.mapId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
          }
        default:
          break;
      }
      for (var index = 0; index < condition.children.length; index++) {
        pending.add((condition.children[index], '$path.children[$index]'));
      }
    }
  }

  void _collectEvents() {
    for (final record
        in project.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
      record.when<void>(
        draft: (draft) {
          final owner = _eventKey(draft.id);
          final source = draft.source;
          if (source != null) {
            _collectEventSource(owner, draft.id, source);
          }
          for (var index = 0; index < draft.conditions.length; index++) {
            _collectEventCondition(
              owner,
              draft.id,
              draft.conditions[index],
              index,
            );
          }
          final sceneId = draft.sceneId;
          if (sceneId != null) _collectEventScene(owner, draft.id, sceneId);
        },
        configured: (definition, _) {
          final owner = _eventKey(definition.id);
          _collectEventSource(owner, definition.id, definition.source);
          for (var index = 0; index < definition.conditions.length; index++) {
            _collectEventCondition(
              owner,
              definition.id,
              definition.conditions[index],
              index,
            );
          }
          _collectEventScene(owner, definition.id, definition.sceneId);
        },
      );
    }
  }

  void _collectEventSource(
    NarrativeDependencyKey owner,
    String eventId,
    NarrativeEventSourceRef source,
  ) {
    _collectNarrativeEventSource(
      owner,
      source,
      'eventRegistry.records[$eventId].source',
    );
  }

  void _collectNarrativeEventSource(
    NarrativeDependencyKey owner,
    NarrativeEventSourceRef source,
    String prefix,
  ) {
    source.when<void>(
      entityInteract: (mapId, entityId) {
        _usage(
          target: _mapKey(mapId),
          owner: owner,
          path: '$prefix.mapId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
        _usage(
          target: _mapSourceChildKey(mapId, 'entity', entityId),
          owner: owner,
          path: '$prefix.entityId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      },
      triggerEnter: (mapId, triggerId) {
        _usage(
          target: _mapKey(mapId),
          owner: owner,
          path: '$prefix.mapId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
        _usage(
          target: _mapSourceChildKey(mapId, 'trigger', triggerId),
          owner: owner,
          path: '$prefix.triggerId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      },
      mapEnter: (mapId) {
        _usage(
          target: _mapKey(mapId),
          owner: owner,
          path: '$prefix.mapId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      },
      outcomeReceived: (outcome) {
        final target = switch (outcome.producerKind) {
          NarrativeOutcomeProducerKind.scene => NarrativeDependencyKey(
              NarrativeDependencyTargetKind.scene,
              outcome.producerId,
            ),
          NarrativeOutcomeProducerKind.battle =>
            NarrativeDependencyKey.synthetic(
              sourceKind: 'battle',
              sourceId: outcome.producerId,
            ),
          NarrativeOutcomeProducerKind.legacyScenario =>
            NarrativeDependencyKey.legacyScenario(outcome.producerId),
        };
        _usage(
          target: target,
          owner: owner,
          path: '$prefix.outcome.producerId#${outcome.outcomeId}',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          resolution: outcome.producerKind == NarrativeOutcomeProducerKind.scene
              ? null
              : NarrativeDependencyResolution.legacyExternal,
        );
      },
    );
  }

  void _collectLegacyClaims() {
    final claims =
        project.eventRegistry?.legacyClaims ?? const <LegacySourceClaim>[];
    for (final claim in claims) {
      final prefix = 'eventRegistry.legacyClaims[${claim.cohortId}]';
      final owner = _definition(
        NarrativeDependencyTargetKind.sourceMap,
        claim.cohortId,
        'Migration claim ${claim.cohortId}',
        path: prefix,
        scope: 'migration',
        sourceKind: 'legacySourceClaim',
        metadata: <String, String>{
          'cohortFingerprint': claim.cohortFingerprint,
          'migrationReceiptId': claim.migrationReceiptId,
          'memberCount': '${claim.members.length}',
          'targetEventCount': '${claim.targetEventIds.length}',
        },
      );
      _collectNarrativeEventSource(owner, claim.source, '$prefix.source');
      for (var index = 0; index < claim.members.length; index++) {
        final provenance = claim.members[index].provenance;
        final provenancePath = '$prefix.members[$index].provenance';
        provenance.when<void>(
          mapEvent: (mapId, eventId) {
            _usage(
              target: _mapKey(mapId),
              owner: owner,
              path: '$provenancePath.mapId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
            _usage(
              target: _mapSourceChildKey(mapId, 'event', eventId),
              owner: owner,
              path: '$provenancePath.eventId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
          },
          scenarioSourceNode: (scenarioId, nodeId) {
            _usage(
              target: NarrativeDependencyKey.legacyScenario(scenarioId),
              owner: owner,
              path: '$provenancePath.scenarioId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
            _usage(
              target: NarrativeDependencyKey.legacyScenarioNode(
                scenarioId: scenarioId,
                nodeId: nodeId,
              ),
              owner: owner,
              path: '$provenancePath.nodeId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
          },
        );
      }
      for (final targetEventId in claim.targetEventIds) {
        _usage(
          target: _eventKey(targetEventId),
          owner: owner,
          path: '$prefix.targetEventIds[$targetEventId]',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      }
    }
  }

  void _collectEventCondition(
    NarrativeDependencyKey owner,
    String eventId,
    NarrativeEventCondition condition,
    int index,
  ) {
    condition.when<void>(
      fact: (factId, _) {
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            factId,
          ),
          owner: owner,
          path: 'eventRegistry.records[$eventId].conditions[$index].factId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      },
      narrativeEventConsumed: (consumedEventId, expectedValue) {
        _usage(
          target: _eventKey(consumedEventId),
          owner: owner,
          path: 'eventRegistry.records[$eventId].conditions[$index].eventId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
        if (expectedValue) {
          _eventCycleEdges.add((owner.id, consumedEventId));
        }
      },
    );
  }

  void _collectEventScene(
    NarrativeDependencyKey owner,
    String eventId,
    String sceneId,
  ) {
    _usage(
      target: NarrativeDependencyKey(
        NarrativeDependencyTargetKind.scene,
        sceneId,
      ),
      owner: owner,
      path: 'eventRegistry.records[$eventId].sceneId',
      criticality: NarrativeDependencyCriticality.runtimeBlocking,
    );
  }

  void _collectScenes() {
    for (final scene in project.scenes) {
      final owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.scene,
        scene.id,
      );
      final storylineId = scene.storylineId;
      if (storylineId != null) {
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.storyline,
            storylineId,
          ),
          owner: owner,
          path: 'scenes[${scene.id}].storylineId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
      }
      final chapterId = scene.chapterId;
      if (chapterId != null) {
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.chapter,
            chapterId,
          ),
          owner: owner,
          path: 'scenes[${scene.id}].chapterId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
      }
      for (var index = 0; index < scene.graph.nodes.length; index++) {
        _collectSceneNode(owner, scene.id, scene.graph.nodes[index], index);
      }
    }
  }

  void _collectStorylines() {
    for (final storyline in project.storylines) {
      final owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.storyline,
        storyline.id,
      );
      for (var chapterIndex = 0;
          chapterIndex < storyline.chapters.length;
          chapterIndex++) {
        final chapter = storyline.chapters[chapterIndex];
        for (var sceneIndex = 0;
            sceneIndex < chapter.directSceneLinkIds.length;
            sceneIndex++) {
          _usage(
            target: NarrativeDependencyKey.scene(
              chapter.directSceneLinkIds[sceneIndex],
            ),
            owner: owner,
            path:
                'storylines[${storyline.id}].chapters[$chapterIndex].directSceneLinkIds[$sceneIndex]',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          );
        }
        for (var stepIndex = 0; stepIndex < chapter.steps.length; stepIndex++) {
          final step = chapter.steps[stepIndex];
          final prefix =
              'storylines[${storyline.id}].chapters[$chapterIndex].steps[$stepIndex]';
          for (var sceneIndex = 0;
              sceneIndex < step.sceneLinkIds.length;
              sceneIndex++) {
            _usage(
              target: NarrativeDependencyKey(
                NarrativeDependencyTargetKind.scene,
                step.sceneLinkIds[sceneIndex],
              ),
              owner: owner,
              path: '$prefix.sceneLinkIds[$sceneIndex]',
              criticality: NarrativeDependencyCriticality.authoringWarning,
            );
          }
          final entryCondition = step.entryCondition;
          if (entryCondition != null) {
            _collectScriptCondition(
              entryCondition,
              owner,
              '$prefix.entryCondition',
            );
          }
          final completionCondition = step.completionCondition;
          if (completionCondition != null) {
            _collectScriptCondition(
              completionCondition,
              owner,
              '$prefix.completionCondition',
            );
          }
        }
      }
      for (var linkIndex = 0;
          linkIndex < storyline.sceneLinks.length;
          linkIndex++) {
        final link = storyline.sceneLinks[linkIndex];
        final prefix = 'storylines[${storyline.id}].sceneLinks[$linkIndex]';
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.chapter,
            link.chapterId,
          ),
          owner: owner,
          path: '$prefix.chapterId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
        final stepId = link.stepId;
        if (stepId != null) {
          _usage(
            target: NarrativeDependencyKey(
              NarrativeDependencyTargetKind.step,
              stepId,
            ),
            owner: owner,
            path: '$prefix.stepId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          );
        }
        final legacyTargetId = link.sceneRef?.targetId;
        if (legacyTargetId != null) {
          _usage(
            target: NarrativeDependencyKey.legacyScenario(legacyTargetId),
            owner: owner,
            path: '$prefix.legacy.sceneRef.targetId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
            resolution: NarrativeDependencyResolution.legacyExternal,
          );
        }
        for (var outcomeIndex = 0;
            outcomeIndex < link.outcomeLinks.length;
            outcomeIndex++) {
          final outcomeLink = link.outcomeLinks[outcomeIndex];
          for (var effectIndex = 0;
              effectIndex < outcomeLink.effects.length;
              effectIndex++) {
            _collectStorylineEffect(
              outcomeLink.effects[effectIndex],
              owner,
              '$prefix.outcomeLinks[$outcomeIndex].effects[$effectIndex]',
            );
          }
        }
      }
      for (var index = 0; index < storyline.relationships.length; index++) {
        final relationship = storyline.relationships[index];
        final prefix = 'storylines[${storyline.id}].relationships[$index]';
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.storyline,
            relationship.sourceStorylineId,
          ),
          owner: owner,
          path: '$prefix.sourceStorylineId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.storyline,
            relationship.targetStorylineId,
          ),
          owner: owner,
          path: '$prefix.targetStorylineId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
        final anchor = relationship.anchor;
        if (anchor != null) {
          _collectStorylineAnchor(anchor, owner, '$prefix.anchor');
        }
        final availability = relationship.availability;
        if (availability != null) {
          _collectStorylineAnchor(
            availability.startAnchor,
            owner,
            '$prefix.availability.startAnchor',
          );
          final endAnchor = availability.endAnchor;
          if (endAnchor != null) {
            _collectStorylineAnchor(
              endAnchor,
              owner,
              '$prefix.availability.endAnchor',
            );
          }
          final availabilityCondition = availability.availabilityCondition;
          if (availabilityCondition != null) {
            _collectScriptCondition(
              availabilityCondition,
              owner,
              '$prefix.availability.availabilityCondition',
            );
          }
          final expiresCondition = availability.expiresCondition;
          if (expiresCondition != null) {
            _collectScriptCondition(
              expiresCondition,
              owner,
              '$prefix.availability.expiresCondition',
            );
          }
        }
        final condition = relationship.condition;
        if (condition != null) {
          _collectScriptCondition(condition, owner, '$prefix.condition');
        }
      }
      final legacySource = storyline.legacySource;
      if (legacySource != null) {
        _usage(
          target: NarrativeDependencyKey.synthetic(
            sourceKind: legacySource.kind,
            sourceId: legacySource.sourceId,
          ),
          owner: owner,
          path: 'storylines[${storyline.id}].legacy.sourceId',
          criticality: NarrativeDependencyCriticality.informational,
          resolution: NarrativeDependencyResolution.legacyExternal,
        );
      }
    }
  }

  void _collectStorylineEffect(
    StorylineEffect effect,
    NarrativeDependencyKey owner,
    String path,
  ) {
    final target = switch (effect.type) {
      StorylineEffectType.activateStep ||
      StorylineEffectType.completeStep =>
        NarrativeDependencyKey(
          NarrativeDependencyTargetKind.step,
          effect.targetId,
        ),
      StorylineEffectType.unlockStoryline => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.storyline,
          effect.targetId,
        ),
      StorylineEffectType.emitFact => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.fact,
          effect.targetId,
        ),
      StorylineEffectType.setWorldRule => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.worldRule,
          effect.targetId,
        ),
      StorylineEffectType.affectRelationship =>
        NarrativeDependencyKey.synthetic(
          sourceKind: 'storylineRelationship',
          sourceId: effect.targetId,
        ),
    };
    _usage(
      target: target,
      owner: owner,
      path: '$path.targetId',
      criticality: NarrativeDependencyCriticality.runtimeBlocking,
      resolution: effect.type == StorylineEffectType.affectRelationship
          ? NarrativeDependencyResolution.legacyExternal
          : null,
    );
  }

  void _collectStorylineAnchor(
    StorylineAnchor anchor,
    NarrativeDependencyKey owner,
    String path,
  ) {
    final target = switch (anchor.kind) {
      StorylineAnchorKind.storyline => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.storyline,
          anchor.targetId,
        ),
      StorylineAnchorKind.chapter => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.chapter,
          anchor.targetId,
        ),
      StorylineAnchorKind.step => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.step,
          anchor.targetId,
        ),
      StorylineAnchorKind.sceneOutcome => NarrativeDependencyKey.synthetic(
          sourceKind: 'sceneOutcome',
          sourceId: anchor.targetId,
        ),
    };
    _usage(
      target: target,
      owner: owner,
      path: '$path.targetId',
      criticality: NarrativeDependencyCriticality.authoringWarning,
      resolution: anchor.kind == StorylineAnchorKind.sceneOutcome
          ? NarrativeDependencyResolution.legacyExternal
          : null,
    );
  }

  void _collectCinematics() {
    for (final cinematic in project.cinematics) {
      final owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.cinematic,
        cinematic.id,
      );
      final storylineId = cinematic.storylineId;
      if (storylineId != null) {
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.storyline,
            storylineId,
          ),
          owner: owner,
          path: 'cinematics[${cinematic.id}].storylineId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
      }
      final chapterId = cinematic.chapterId;
      if (chapterId != null) {
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.chapter,
            chapterId,
          ),
          owner: owner,
          path: 'cinematics[${cinematic.id}].chapterId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
      }
      final mapId = cinematic.mapId;
      if (mapId != null) {
        _usage(
          target: _mapKey(mapId),
          owner: owner,
          path: 'cinematics[${cinematic.id}].mapId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      }
      if (mapId != null) {
        for (var index = 0; index < cinematic.requiredActors.length; index++) {
          final entityId = cinematic.requiredActors[index].entityId;
          if (entityId != null) {
            _usage(
              target: _mapSourceChildKey(mapId, 'entity', entityId),
              owner: owner,
              path:
                  'cinematics[${cinematic.id}].requiredActors[$index].entityId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
          }
        }
        final bindings = cinematic.stageContext?.actorBindings ??
            const <CinematicActorBinding>[];
        for (var index = 0; index < bindings.length; index++) {
          final entityId = bindings[index].mapEntityId;
          if (entityId != null) {
            _usage(
              target: _mapSourceChildKey(mapId, 'entity', entityId),
              owner: owner,
              path:
                  'cinematics[${cinematic.id}].stageContext.actorBindings[$index].mapEntityId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
          }
        }
        final movementBindings =
            cinematic.stageContext?.movementTargetBindings ??
                const <CinematicMovementTargetBinding>[];
        for (var index = 0; index < movementBindings.length; index++) {
          final binding = movementBindings[index];
          final sourceId = binding.sourceId?.trim();
          final sourceKind = switch (binding.kind) {
            CinematicMovementTargetBindingKind.mapEntity => 'entity',
            CinematicMovementTargetBindingKind.mapEvent => 'event',
            CinematicMovementTargetBindingKind.abstractPoint ||
            CinematicMovementTargetBindingKind.stagePoint =>
              null,
          };
          if (sourceKind == null || sourceId == null || sourceId.isEmpty) {
            continue;
          }
          _usage(
            target: _mapSourceChildKey(mapId, sourceKind, sourceId),
            owner: owner,
            path:
                'cinematics[${cinematic.id}].stageContext.movementTargetBindings[$index].sourceId',
            criticality: NarrativeDependencyCriticality.runtimeBlocking,
          );
        }
      }
      final scenarioId = cinematic.legacyBridge?.scenarioId;
      if (scenarioId != null) {
        _usage(
          target: NarrativeDependencyKey.legacyScenario(scenarioId),
          owner: owner,
          path: 'cinematics[${cinematic.id}].legacyBridge.scenarioId',
          criticality: NarrativeDependencyCriticality.informational,
          resolution: NarrativeDependencyResolution.legacyExternal,
        );
      }
    }
  }

  void _collectWorldRules() {
    for (final rule in project.worldRules) {
      final owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.worldRule,
        rule.id,
      );
      final sourceTarget = switch (rule.source.kind) {
        WorldRuleSourceKind.fact => NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            rule.source.sourceId,
          ),
        WorldRuleSourceKind.storyStepCompletion => NarrativeDependencyKey(
            NarrativeDependencyTargetKind.step,
            rule.source.sourceId,
          ),
        WorldRuleSourceKind.consumedEvent => NarrativeDependencyKey.synthetic(
            sourceKind: 'legacyMapEvent',
            sourceId: rule.source.sourceId,
          ),
      };
      _usage(
        target: sourceTarget,
        owner: owner,
        path: 'worldRules[${rule.id}].source.sourceId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
      _usage(
        target: _mapKey(rule.target.mapId),
        owner: owner,
        path: 'worldRules[${rule.id}].target.mapId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
      final entityId = rule.target.entityId;
      if (entityId != null) {
        _usage(
          target: _mapSourceChildKey(rule.target.mapId, 'entity', entityId),
          owner: owner,
          path: 'worldRules[${rule.id}].target.entityId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      }
      final eventId = rule.target.eventId;
      if (eventId != null) {
        _usage(
          target: _mapSourceChildKey(rule.target.mapId, 'event', eventId),
          owner: owner,
          path: 'worldRules[${rule.id}].target.eventId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      }
      _collectDialogueRef(
        rule.effect.dialogueId,
        owner,
        'worldRules[${rule.id}].effect.dialogueId',
      );
    }
  }

  void _collectLegacyScenarios() {
    final globalStoryCandidates =
        <String, StorylineLegacyGlobalStoryImportCandidate>{
      for (final candidate
          in buildLegacyGlobalStoryImportPreview(project).candidates)
        candidate.sourceScenarioId: candidate,
    };
    for (final scenario in project.scenarios) {
      final owner = _definition(
        NarrativeDependencyTargetKind.sourceMap,
        scenario.id,
        scenario.name,
        path: 'scenarios[${scenario.id}]',
        scope: 'legacy',
        sourceKind: 'scenario',
        metadata: <String, String>{
          'scope': scenario.scope.name,
          'entryNodeId': scenario.entryNodeId,
          ...scenario.metadata,
        },
      );
      final globalStoryCandidate = globalStoryCandidates[scenario.id];
      if (globalStoryCandidate != null) {
        for (var chapterIndex = 0;
            chapterIndex < globalStoryCandidate.draftStoryline.chapters.length;
            chapterIndex++) {
          final chapter =
              globalStoryCandidate.draftStoryline.chapters[chapterIndex];
          final chapterKey = _definition(
            NarrativeDependencyTargetKind.sourceMap,
            chapter.id,
            chapter.title,
            owner: owner,
            path:
                'scenarios[${scenario.id}].metadata[authoring.globalStoryStudioDocument].chapters[$chapterIndex]',
            scope: 'legacy',
            parentId: scenario.id,
            sourceKind: 'globalStoryChapter',
            metadata: <String, String>{
              'legacyScenarioId': scenario.id,
              'legacyDocument': 'authoring.globalStoryStudioDocument',
              'order': '${chapter.order}',
            },
          );
          for (var stepIndex = 0;
              stepIndex < chapter.steps.length;
              stepIndex++) {
            final step = chapter.steps[stepIndex];
            _definition(
              NarrativeDependencyTargetKind.sourceMap,
              step.id,
              step.title,
              owner: chapterKey,
              path:
                  'scenarios[${scenario.id}].metadata[authoring.stepStudioDocument].steps[$stepIndex]',
              scope: 'legacy',
              parentId: scenario.id,
              sourceKind: 'globalStoryStep',
              metadata: <String, String>{
                'legacyScenarioId': scenario.id,
                'legacyDocument': 'authoring.stepStudioDocument',
                'order': '${step.order}',
              },
            );
          }
        }
      }
      final activationCondition = scenario.activationCondition;
      if (activationCondition != null) {
        _collectScriptCondition(
          activationCondition,
          owner,
          'scenarios[${scenario.id}].legacy.activationCondition',
        );
      }
      for (var index = 0; index < scenario.nodes.length; index++) {
        final node = scenario.nodes[index];
        _definition(
          NarrativeDependencyTargetKind.sourceMap,
          node.id,
          node.title.trim().isEmpty ? node.id : node.title,
          owner: owner,
          path: 'scenarios[${scenario.id}].legacy.nodes[$index]',
          scope: 'legacy',
          parentId: scenario.id,
          sourceKind: 'scenarioNode',
        );
        final binding = node.binding;
        final prefix = 'scenarios[${scenario.id}].legacy.nodes[$index].binding';
        final mapId = binding.mapId?.trim();
        final payloadCondition = node.payload.condition;
        if (payloadCondition != null) {
          _collectScriptCondition(
            payloadCondition,
            owner,
            'scenarios[${scenario.id}].legacy.nodes[$index].payload.condition',
            mapId: mapId,
          );
        }
        final actionKind = node.payload.actionKind?.trim();
        final payloadStepId = node.payload.params['stepId']?.trim();
        if (actionKind == 'completeStep' &&
            payloadStepId != null &&
            payloadStepId.isNotEmpty) {
          _usage(
            target: NarrativeDependencyKey(
              NarrativeDependencyTargetKind.step,
              payloadStepId,
            ),
            owner: owner,
            path:
                'scenarios[${scenario.id}].legacy.nodes[$index].payload.params.stepId',
            criticality: NarrativeDependencyCriticality.runtimeBlocking,
          );
        }
        if (mapId != null && mapId.isNotEmpty) {
          _usage(
            target: _mapKey(mapId),
            owner: owner,
            path: '$prefix.mapId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          );
        }
        _collectDialogueRef(binding.dialogueId, owner, '$prefix.dialogueId');
        final flagName = binding.flagName?.trim();
        if (flagName != null && flagName.isNotEmpty) {
          _collectLegacyFactRef(flagName, owner, '$prefix.flagName');
        }
        final entityId = binding.entityId?.trim();
        if (mapId != null &&
            mapId.isNotEmpty &&
            entityId != null &&
            entityId.isNotEmpty) {
          _usage(
            target: _mapSourceChildKey(mapId, 'entity', entityId),
            owner: owner,
            path: '$prefix.entityId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          );
        }
        final eventId = binding.eventId?.trim();
        if (mapId != null &&
            mapId.isNotEmpty &&
            eventId != null &&
            eventId.isNotEmpty) {
          _usage(
            target: _mapSourceChildKey(mapId, 'event', eventId),
            owner: owner,
            path: '$prefix.eventId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          );
        }
        final triggerId = binding.triggerId?.trim();
        if (mapId != null &&
            mapId.isNotEmpty &&
            triggerId != null &&
            triggerId.isNotEmpty) {
          _usage(
            target: _mapSourceChildKey(mapId, 'trigger', triggerId),
            owner: owner,
            path: '$prefix.triggerId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          );
        }
        final warpId = binding.warpId?.trim();
        if (mapId != null &&
            mapId.isNotEmpty &&
            warpId != null &&
            warpId.isNotEmpty) {
          _usage(
            target: _mapSourceChildKey(mapId, 'warp', warpId),
            owner: owner,
            path: '$prefix.warpId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          );
        }
      }
    }
  }

  void _collectCycleIssues() {
    final eventIds =
        project.eventRegistry?.records.map((record) => record.id).toSet() ??
            <String>{};
    final eventEdges = _eventCycleEdges
        .where(
          (edge) => eventIds.contains(edge.$1) && eventIds.contains(edge.$2),
        )
        .toList();
    for (final eventId in _cyclicNodes(eventIds, eventEdges)) {
      _issues.add(
        NarrativeDependencyIssue(
          kind: NarrativeDependencyIssueKind.forbiddenCycle,
          target: _eventKey(eventId),
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          message:
              'Event V2 "$eventId" belongs to a consumed-event dependency cycle.',
        ),
      );
    }

    for (final scene in project.scenes) {
      final nodeIds = scene.graph.nodes.map((node) => node.id).toSet();
      final edges = <(String, String)>[
        for (final edge in scene.graph.edges)
          if (nodeIds.contains(edge.fromNodeId) &&
              nodeIds.contains(edge.toNodeId))
            (edge.fromNodeId, edge.toNodeId),
      ];
      if (_cyclicNodes(nodeIds, edges).isEmpty) continue;
      _issues.add(
        NarrativeDependencyIssue(
          kind: NarrativeDependencyIssueKind.forbiddenCycle,
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.scene,
            scene.id,
          ),
          criticality: NarrativeDependencyCriticality.authoringWarning,
          message: 'Scene "${scene.id}" contains a graph cycle.',
        ),
      );
    }
  }

  void _collectSceneNode(
    NarrativeDependencyKey owner,
    String sceneId,
    SceneNode node,
    int index,
  ) {
    final path = 'scenes[$sceneId].graph.nodes[$index].payload';
    final payload = node.payload;
    if (payload is SceneYarnDialoguePayload) {
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.dialogue,
          payload.dialogueId,
        ),
        owner: owner,
        path: '$path.dialogueId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
    } else if (payload is SceneCinematicPayload) {
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.cinematic,
          payload.cinematicId,
        ),
        owner: owner,
        path: '$path.cinematicId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
    } else if (payload is SceneConditionPayload) {
      final source = payload.conditionSource;
      if (source != null) {
        _collectSceneCondition(owner, source, '$path.conditionSource');
      }
    } else if (payload is SceneActionPayload) {
      final consequence = payload.consequence;
      if (consequence != null) {
        _collectSceneConsequence(owner, consequence, '$path.consequence');
      }
    }
  }

  void _collectSceneCondition(
    NarrativeDependencyKey owner,
    SceneConditionSource source,
    String path,
  ) {
    if (source.sourceKind == SceneConditionSourceKind.factLikeStoryFlag) {
      _collectLegacyFactRef(source.sourceId, owner, '$path.sourceId');
      return;
    }
    final target = switch (source.sourceKind) {
      SceneConditionSourceKind.fact => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.fact,
          source.sourceId,
        ),
      SceneConditionSourceKind.storyStepCompletion ||
      SceneConditionSourceKind.storyStepActive =>
        NarrativeDependencyKey(
          NarrativeDependencyTargetKind.step,
          source.sourceId,
        ),
      SceneConditionSourceKind.consumedEvent =>
        NarrativeDependencyKey.synthetic(
          sourceKind: 'legacyMapEvent',
          sourceId: source.sourceId,
        ),
      SceneConditionSourceKind.dialogueOutcome => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.dialogue,
          source.sourceId,
        ),
      SceneConditionSourceKind.worldState => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.worldRule,
          source.sourceId,
        ),
      _ => NarrativeDependencyKey.synthetic(
          sourceKind: 'legacyCondition.${source.sourceKind.name}',
          sourceId: source.sourceId,
        ),
    };
    final usesCanonicalResolution =
        source.sourceKind == SceneConditionSourceKind.fact ||
            source.sourceKind == SceneConditionSourceKind.storyStepCompletion ||
            source.sourceKind == SceneConditionSourceKind.storyStepActive ||
            source.sourceKind == SceneConditionSourceKind.consumedEvent ||
            source.sourceKind == SceneConditionSourceKind.dialogueOutcome ||
            source.sourceKind == SceneConditionSourceKind.worldState;
    _usage(
      target: target,
      owner: owner,
      path: '$path.sourceId',
      criticality: NarrativeDependencyCriticality.runtimeBlocking,
      resolution: usesCanonicalResolution
          ? null
          : NarrativeDependencyResolution.legacyExternal,
    );
  }

  void _collectSceneConsequence(
    NarrativeDependencyKey owner,
    SceneConsequence consequence,
    String path,
  ) {
    if (consequence is SceneSetFactConsequence) {
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.fact,
          consequence.factId,
        ),
        owner: owner,
        path: '$path.factId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
    } else if (consequence is SceneMarkEventConsumedConsequence) {
      _usage(
        target: _mapKey(consequence.mapId),
        owner: owner,
        path: '$path.mapId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
      _usage(
        target: _mapSourceChildKey(
          consequence.mapId,
          'event',
          consequence.eventId,
        ),
        owner: owner,
        path: '$path.eventId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
    } else if (consequence is SceneCompleteStoryStepConsequence) {
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.step,
          consequence.stepId,
        ),
        owner: owner,
        path: '$path.stepId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
    }
  }

  NarrativeDependencyIndex _resolve() {
    final definitionsByKey =
        <NarrativeDependencyKey, List<NarrativeDependencyDefinition>>{};
    for (final definition in _definitions) {
      definitionsByKey.putIfAbsent(definition.key, () => []).add(definition);
    }
    for (final entry in definitionsByKey.entries) {
      if (entry.value.length < 2) continue;
      _issues.add(
        NarrativeDependencyIssue(
          kind: NarrativeDependencyIssueKind.duplicateId,
          target: entry.key,
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          message:
              '${entry.value.length} definitions share ${entry.key.kind.name} ID "${entry.key.id}".',
        ),
      );
    }

    final declaredMapIds = project.maps.map((entry) => entry.id).toSet();
    final loadedMapIds = maps.map((map) => map.id).toSet();
    final hasUnavailableDeclaredMaps =
        declaredMapIds.difference(loadedMapIds).isNotEmpty;
    final resolvedUsages = <NarrativeDependencyUsage>[];
    for (final usage in _usages) {
      NarrativeDependencyResolution resolution;
      if (usage.resolution == NarrativeDependencyResolution.legacyExternal ||
          usage.resolution == NarrativeDependencyResolution.ambiguous) {
        resolution = usage.resolution;
      } else {
        final definitionCount = definitionsByKey[usage.target]?.length ?? 0;
        final physicalMapId = usage.target.physicalMapId;
        final isGlobalLegacyMapEvent =
            usage.target.kind == NarrativeDependencyTargetKind.sourceMap &&
                usage.target.scope == 'synthetic' &&
                usage.target.sourceKind == 'legacyMapEvent';
        if (definitionCount > 1) {
          resolution = NarrativeDependencyResolution.ambiguous;
        } else if (isGlobalLegacyMapEvent &&
            definitionCount == 0 &&
            hasUnavailableDeclaredMaps) {
          resolution = NarrativeDependencyResolution.unavailable;
        } else if (physicalMapId != null &&
            declaredMapIds.contains(physicalMapId) &&
            !loadedMapIds.contains(physicalMapId)) {
          resolution = NarrativeDependencyResolution.unavailable;
        } else if (definitionCount == 1) {
          resolution = NarrativeDependencyResolution.resolved;
        } else {
          resolution = NarrativeDependencyResolution.missing;
        }
      }
      final resolved = usage.withResolution(resolution);
      resolvedUsages.add(resolved);
      if (resolution == NarrativeDependencyResolution.missing ||
          resolution == NarrativeDependencyResolution.ambiguous ||
          resolution == NarrativeDependencyResolution.unavailable) {
        final issueKind = switch (resolution) {
          NarrativeDependencyResolution.missing =>
            NarrativeDependencyIssueKind.missingReference,
          NarrativeDependencyResolution.ambiguous =>
            NarrativeDependencyIssueKind.ambiguousReference,
          NarrativeDependencyResolution.unavailable =>
            NarrativeDependencyIssueKind.unavailableReference,
          _ => throw StateError('Unsupported dependency issue resolution'),
        };
        _issues.add(
          NarrativeDependencyIssue(
            kind: issueKind,
            target: usage.target,
            owner: usage.owner,
            path: usage.path,
            criticality: usage.criticality,
            message: switch (resolution) {
              NarrativeDependencyResolution.missing =>
                '${usage.target} is missing.',
              NarrativeDependencyResolution.ambiguous =>
                '${usage.target} resolves to multiple definitions.',
              NarrativeDependencyResolution.unavailable =>
                '${usage.target} is declared but its map data is unavailable.',
              _ => throw StateError('Unsupported dependency issue resolution'),
            },
          ),
        );
      }
    }
    return NarrativeDependencyIndex(
      definitions: _definitions,
      usages: resolvedUsages,
      issues: _issues,
    );
  }

  NarrativeDependencyKey _definition(
    NarrativeDependencyTargetKind kind,
    String id,
    String label, {
    NarrativeDependencyKey? owner,
    String? path,
    String? scope,
    String? parentId,
    String? sourceKind,
    Map<String, String> metadata = const <String, String>{},
  }) {
    final key = NarrativeDependencyKey(
      kind,
      id,
      scope: scope,
      parentId: parentId,
      sourceKind: sourceKind,
    );
    _definitions.add(
      NarrativeDependencyDefinition(
        key: key,
        label: label,
        owner: owner,
        path: path,
        navigationIntent: NarrativeDependencyNavigationIntent(
          kind: kind,
          assetId: id,
          parentId: owner?.id,
          context: path,
        ),
        metadata: metadata,
      ),
    );
    return key;
  }

  void _usage({
    required NarrativeDependencyKey target,
    required NarrativeDependencyKey owner,
    required String path,
    required NarrativeDependencyCriticality criticality,
    NarrativeDependencyResolution? resolution,
  }) {
    _usages.add(
      NarrativeDependencyUsage(
        target: target,
        owner: owner,
        path: path,
        criticality: criticality,
        resolution: resolution ?? NarrativeDependencyResolution.resolved,
        navigationIntent: NarrativeDependencyNavigationIntent(
          kind: owner.kind,
          assetId: owner.id,
          context: path,
        ),
      ),
    );
  }
}

const _newGameOwner = NarrativeDependencyKey.projectNewGame();

NarrativeDependencyKey _eventKey(String id) =>
    NarrativeDependencyKey.eventV2(id);

NarrativeDependencyKey _mapKey(String mapId) =>
    NarrativeDependencyKey.map(mapId);

NarrativeDependencyKey _mapSourceChildKey(
  String mapId,
  String kind,
  String id,
) =>
    NarrativeDependencyKey.mapSource(
      mapId: mapId,
      sourceKind: kind,
      sourceId: id,
    );

const _physicalMapScope = 'map';

/// Iterative Kosaraju traversal. It deliberately avoids recursive DFS so a
/// large authoring project cannot overflow the VM stack while being indexed.
Set<T> _cyclicNodes<T>(
  Iterable<T> nodes,
  Iterable<(T, T)> edges,
) {
  final adjacency = <T, List<T>>{};
  final reverse = <T, List<T>>{};
  for (final node in nodes) {
    adjacency.putIfAbsent(node, () => <T>[]);
    reverse.putIfAbsent(node, () => <T>[]);
  }
  for (final (from, to) in edges) {
    adjacency.putIfAbsent(from, () => <T>[]).add(to);
    adjacency.putIfAbsent(to, () => <T>[]);
    reverse.putIfAbsent(to, () => <T>[]).add(from);
    reverse.putIfAbsent(from, () => <T>[]);
  }

  final visited = <T>{};
  final postorder = <T>[];
  for (final start in adjacency.keys) {
    if (visited.contains(start)) continue;
    final stack = <(T, bool)>[(start, false)];
    while (stack.isNotEmpty) {
      final (node, expanded) = stack.removeLast();
      if (expanded) {
        postorder.add(node);
        continue;
      }
      if (!visited.add(node)) continue;
      stack.add((node, true));
      final targets = adjacency[node]!;
      for (var index = targets.length - 1; index >= 0; index--) {
        final target = targets[index];
        if (!visited.contains(target)) stack.add((target, false));
      }
    }
  }

  final assigned = <T>{};
  final cyclic = <T>{};
  for (var index = postorder.length - 1; index >= 0; index--) {
    final start = postorder[index];
    if (!assigned.add(start)) continue;
    final component = <T>[];
    final stack = <T>[start];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      component.add(node);
      for (final target in reverse[node]!) {
        if (assigned.add(target)) stack.add(target);
      }
    }
    if (component.length > 1 ||
        adjacency[component.single]!.contains(component.single)) {
      cyclic.addAll(component);
    }
  }
  return cyclic;
}

Map<NarrativeDependencyKey, List<NarrativeDependencyDefinition>>
    _groupDefinitionsByKey(
  List<NarrativeDependencyDefinition> definitions,
) {
  final grouped =
      <NarrativeDependencyKey, List<NarrativeDependencyDefinition>>{};
  for (final definition in definitions) {
    grouped.putIfAbsent(definition.key, () => []).add(definition);
  }
  return <NarrativeDependencyKey, List<NarrativeDependencyDefinition>>{
    for (final entry in grouped.entries)
      entry.key: List<NarrativeDependencyDefinition>.unmodifiable(entry.value),
  };
}

Map<NarrativeDependencyKey, List<NarrativeDependencyUsage>>
    _groupUsagesByTarget(
  List<NarrativeDependencyUsage> usages,
) {
  final grouped = <NarrativeDependencyKey, List<NarrativeDependencyUsage>>{};
  for (final usage in usages) {
    grouped.putIfAbsent(usage.target, () => []).add(usage);
  }
  return <NarrativeDependencyKey, List<NarrativeDependencyUsage>>{
    for (final entry in grouped.entries)
      entry.key: List<NarrativeDependencyUsage>.unmodifiable(entry.value),
  };
}

Map<NarrativeDependencyKey, List<NarrativeDependencyUsage>> _groupUsagesByOwner(
  List<NarrativeDependencyUsage> usages,
) {
  final grouped = <NarrativeDependencyKey, List<NarrativeDependencyUsage>>{};
  for (final usage in usages) {
    grouped.putIfAbsent(usage.owner, () => []).add(usage);
  }
  return <NarrativeDependencyKey, List<NarrativeDependencyUsage>>{
    for (final entry in grouped.entries)
      entry.key: List<NarrativeDependencyUsage>.unmodifiable(entry.value),
  };
}

int _compareKeys(NarrativeDependencyKey left, NarrativeDependencyKey right) {
  final kind = left.kind.index.compareTo(right.kind.index);
  if (kind != 0) return kind;
  final id = left.id.compareTo(right.id);
  if (id != 0) return id;
  final scope = (left.scope ?? '').compareTo(right.scope ?? '');
  if (scope != 0) return scope;
  final parentId = (left.parentId ?? '').compareTo(right.parentId ?? '');
  if (parentId != 0) return parentId;
  return (left.sourceKind ?? '').compareTo(right.sourceKind ?? '');
}

int _compareDefinitions(
  NarrativeDependencyDefinition left,
  NarrativeDependencyDefinition right,
) {
  final key = _compareKeys(left.key, right.key);
  if (key != 0) return key;
  final owner = _compareOptionalKeys(left.owner, right.owner);
  if (owner != 0) return owner;
  final path = (left.path ?? '').compareTo(right.path ?? '');
  if (path != 0) return path;
  final label = left.label.compareTo(right.label);
  if (label != 0) return label;
  final navigation = _compareOptionalNavigationIntents(
    left.navigationIntent,
    right.navigationIntent,
  );
  if (navigation != 0) return navigation;
  return _compareStringMaps(left.metadata, right.metadata);
}

int _compareUsages(
  NarrativeDependencyUsage left,
  NarrativeDependencyUsage right,
) {
  final target = _compareKeys(left.target, right.target);
  if (target != 0) return target;
  final owner = _compareKeys(left.owner, right.owner);
  if (owner != 0) return owner;
  final path = left.path.compareTo(right.path);
  if (path != 0) return path;
  final criticality = left.criticality.index.compareTo(right.criticality.index);
  if (criticality != 0) return criticality;
  final resolution = left.resolution.index.compareTo(right.resolution.index);
  if (resolution != 0) return resolution;
  return _compareOptionalNavigationIntents(
    left.navigationIntent,
    right.navigationIntent,
  );
}

int _compareIssues(
  NarrativeDependencyIssue left,
  NarrativeDependencyIssue right,
) {
  final target = _compareKeys(left.target, right.target);
  if (target != 0) return target;
  final kind = left.kind.index.compareTo(right.kind.index);
  if (kind != 0) return kind;
  final owner = _compareOptionalKeys(left.owner, right.owner);
  if (owner != 0) return owner;
  final path = (left.path ?? '').compareTo(right.path ?? '');
  if (path != 0) return path;
  final criticality = left.criticality.index.compareTo(right.criticality.index);
  if (criticality != 0) return criticality;
  return left.message.compareTo(right.message);
}

int _compareOptionalNavigationIntents(
  NarrativeDependencyNavigationIntent? left,
  NarrativeDependencyNavigationIntent? right,
) {
  if (left == null) return right == null ? 0 : -1;
  if (right == null) return 1;
  final kind = left.kind.index.compareTo(right.kind.index);
  if (kind != 0) return kind;
  final assetId = left.assetId.compareTo(right.assetId);
  if (assetId != 0) return assetId;
  final parentId = (left.parentId ?? '').compareTo(right.parentId ?? '');
  if (parentId != 0) return parentId;
  return (left.context ?? '').compareTo(right.context ?? '');
}

int _compareStringMaps(Map<String, String> left, Map<String, String> right) {
  final leftEntries = left.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final rightEntries = right.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final length = leftEntries.length.compareTo(rightEntries.length);
  if (length != 0) return length;
  for (var index = 0; index < leftEntries.length; index++) {
    final key = leftEntries[index].key.compareTo(rightEntries[index].key);
    if (key != 0) return key;
    final value = leftEntries[index].value.compareTo(rightEntries[index].value);
    if (value != 0) return value;
  }
  return 0;
}

int _compareOptionalKeys(
  NarrativeDependencyKey? left,
  NarrativeDependencyKey? right,
) {
  if (left == null) return right == null ? 0 : -1;
  if (right == null) return 1;
  return _compareKeys(left, right);
}
````

## Annexe B — contenu complet du test créé

`packages/map_core/test/narrative_dependency_index_test.dart` :

````dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeDependencyIndex contract', () {
    test('builds an empty immutable index for an empty project', () {
      final index = buildNarrativeDependencyIndex(
        project: _project(),
      );

      expect(index.definitions, isEmpty);
      expect(index.usages, isEmpty);
      expect(index.issues, isEmpty);
      expect(
        () => index.definitions.add(
          NarrativeDependencyDefinition(
            key: const NarrativeDependencyKey(
              NarrativeDependencyTargetKind.fact,
              'fact.any',
            ),
            label: 'Any',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('sorts definitions and usages and supports both query directions', () {
      const factA = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'a',
      );
      const factB = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'b',
      );
      const scene = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.scene,
        'scene.main',
      );
      final index = NarrativeDependencyIndex(
        definitions: <NarrativeDependencyDefinition>[
          NarrativeDependencyDefinition(key: factB, label: 'B'),
          NarrativeDependencyDefinition(key: scene, label: 'Scene'),
          NarrativeDependencyDefinition(key: factA, label: 'A'),
        ],
        usages: const <NarrativeDependencyUsage>[
          NarrativeDependencyUsage(
            target: factB,
            owner: scene,
            path: 'graph.nodes[2].condition',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          ),
          NarrativeDependencyUsage(
            target: factA,
            owner: scene,
            path: 'graph.nodes[1].condition',
            criticality: NarrativeDependencyCriticality.runtimeBlocking,
          ),
        ],
      );

      expect(
          index.definitions.map((entry) => entry.key), [factA, factB, scene]);
      expect(index.usages.map((entry) => entry.target), [factA, factB]);
      expect(index.definitionsFor(factA), hasLength(1));
      expect(index.usagesFor(factB), hasLength(1));
      expect(index.usagesOwnedBy(scene), hasLength(2));
      expect(() => index.usages.clear(), throwsUnsupportedError);
    });

    test('exposes a neutral navigation intent', () {
      const intent = NarrativeDependencyNavigationIntent(
        kind: NarrativeDependencyTargetKind.scene,
        assetId: 'scene.main',
        parentId: 'story.main',
        context: 'chapter.intro',
      );

      expect(intent.kind, NarrativeDependencyTargetKind.scene);
      expect(intent.assetId, 'scene.main');
      expect(intent.parentId, 'story.main');
      expect(intent.context, 'chapter.intro');
    });

    test('fully orders equal-prefix entries independently of input order', () {
      const fact = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'fact.same',
      );
      const scene = NarrativeDependencyKey.scene('scene.same');
      final definitions = <NarrativeDependencyDefinition>[
        NarrativeDependencyDefinition(
          key: fact,
          label: 'Same',
          path: 'same.path',
          navigationIntent: const NarrativeDependencyNavigationIntent(
            kind: NarrativeDependencyTargetKind.fact,
            assetId: 'fact.same',
            context: 'z-context',
          ),
          metadata: const <String, String>{'z': '2'},
        ),
        NarrativeDependencyDefinition(
          key: fact,
          label: 'Same',
          path: 'same.path',
          navigationIntent: const NarrativeDependencyNavigationIntent(
            kind: NarrativeDependencyTargetKind.fact,
            assetId: 'fact.same',
            context: 'a-context',
          ),
          metadata: const <String, String>{'a': '1'},
        ),
      ];
      const usages = <NarrativeDependencyUsage>[
        NarrativeDependencyUsage(
          target: fact,
          owner: scene,
          path: 'same.path',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          resolution: NarrativeDependencyResolution.missing,
        ),
        NarrativeDependencyUsage(
          target: fact,
          owner: scene,
          path: 'same.path',
          criticality: NarrativeDependencyCriticality.authoringWarning,
          resolution: NarrativeDependencyResolution.resolved,
        ),
      ];
      const issues = <NarrativeDependencyIssue>[
        NarrativeDependencyIssue(
          kind: NarrativeDependencyIssueKind.missingReference,
          target: fact,
          owner: scene,
          path: 'same.path',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          message: 'z-message',
        ),
        NarrativeDependencyIssue(
          kind: NarrativeDependencyIssueKind.missingReference,
          target: fact,
          owner: scene,
          path: 'same.path',
          criticality: NarrativeDependencyCriticality.authoringWarning,
          message: 'a-message',
        ),
      ];

      List<String> snapshot(NarrativeDependencyIndex index) => <String>[
            for (final definition in index.definitions)
              'definition|${definition.key}|${definition.label}|'
                  '${definition.path}|${definition.navigationIntent?.context}|'
                  '${definition.metadata}',
            for (final usage in index.usages)
              'usage|${usage.target}|${usage.owner}|${usage.path}|'
                  '${usage.criticality.name}|${usage.resolution.name}|'
                  '${usage.navigationIntent?.context}',
            for (final issue in index.issues)
              'issue|${issue.target}|${issue.owner}|${issue.path}|'
                  '${issue.kind.name}|${issue.criticality.name}|${issue.message}',
          ];

      final forward = NarrativeDependencyIndex(
        definitions: definitions,
        usages: usages,
        issues: issues,
      );
      final reversed = NarrativeDependencyIndex(
        definitions: definitions.reversed,
        usages: usages.reversed,
        issues: issues.reversed,
      );

      expect(snapshot(forward), snapshot(reversed));
      expect(
        () => forward.definitions.first.metadata['forbidden'] = 'mutation',
        throwsUnsupportedError,
      );
    });
  });

  group('New Game, Event V2 and Scene collectors', () {
    test('indexes New Game facts, map and starter Scene with resolutions', () {
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(id: 'party.exists', label: 'Party exists'),
          NarrativeFactDefinition(id: 'intro.seen', label: 'Intro seen'),
        ],
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map.port',
          initialFacts: <String, bool>{
            'missing.fact': false,
            'intro.seen': true,
          },
          existingPartyFactId: 'party.exists',
          starterSelectionSceneId: 'scene.missing',
        ),
      );

      final index = buildNarrativeDependencyIndex(project: project);
      final usages = index.usagesOwnedBy(_newGameOwner);

      expect(
        usages.map((usage) => (usage.path, usage.resolution)),
        containsAll(<(String, NarrativeDependencyResolution)>[
          (
            'newGame.startMapId',
            NarrativeDependencyResolution.unavailable,
          ),
          (
            'newGame.initialFacts[intro.seen]',
            NarrativeDependencyResolution.resolved,
          ),
          (
            'newGame.initialFacts[missing.fact]',
            NarrativeDependencyResolution.missing,
          ),
          (
            'newGame.existingPartyFactId',
            NarrativeDependencyResolution.resolved,
          ),
          (
            'newGame.starterSelectionSceneId',
            NarrativeDependencyResolution.missing,
          ),
        ]),
      );
    });

    test('indexes the configured New Game spawn inside its start map', () {
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map.port',
          startSpawnId: 'spawn.player',
        ),
      );
      final map = MapData(
        id: 'map.port',
        name: 'Port',
        size: const GridSize(width: 5, height: 5),
        entities: const <MapEntity>[
          MapEntity(
            id: 'spawn.player',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 1, y: 1),
            spawn: MapEntitySpawnData(),
          ),
        ],
      );

      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[map],
      );
      final spawnUsage = index
          .usagesOwnedBy(_newGameOwner)
          .singleWhere((usage) => usage.path == 'newGame.startSpawnId');

      expect(
        spawnUsage.target,
        const NarrativeDependencyKey.mapSource(
          mapId: 'map.port',
          sourceKind: 'entity',
          sourceId: 'spawn.player',
        ),
      );
      expect(spawnUsage.resolution, NarrativeDependencyResolution.resolved);
    });

    test('distinguishes unavailable and missing New Game spawn data', () {
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map.port',
          startSpawnId: 'spawn.missing',
        ),
      );

      final unavailable = buildNarrativeDependencyIndex(project: project);
      final missing = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[_emptyMap('map.port')],
      );

      NarrativeDependencyResolution spawnResolution(
        NarrativeDependencyIndex index,
      ) =>
          index
              .usagesOwnedBy(_newGameOwner)
              .singleWhere((usage) => usage.path == 'newGame.startSpawnId')
              .resolution;

      expect(
        spawnResolution(unavailable),
        NarrativeDependencyResolution.unavailable,
      );
      expect(
        spawnResolution(missing),
        NarrativeDependencyResolution.missing,
      );
    });

    test('keeps disabled New Game references as authoring dependencies', () {
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(id: 'fact.ready', label: 'Ready'),
        ],
        scenes: <SceneAsset>[_emptyScene('scene.starter')],
        newGame: const ProjectNewGameConfig(
          enabled: false,
          startMapId: 'map.port',
          startSpawnId: 'spawn.player',
          initialFacts: <String, bool>{'fact.ready': true},
          existingPartyFactId: 'fact.ready',
          starterSelectionSceneId: 'scene.starter',
        ),
      );
      final map = MapData(
        id: 'map.port',
        name: 'Port',
        size: const GridSize(width: 5, height: 5),
        entities: const <MapEntity>[
          MapEntity(
            id: 'spawn.player',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 1, y: 1),
            spawn: MapEntitySpawnData(),
          ),
        ],
      );

      final usages = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[map],
      ).usagesOwnedBy(_newGameOwner);

      expect(
        usages.map((usage) => usage.path),
        containsAll(<String>[
          'newGame.startMapId',
          'newGame.startSpawnId',
          'newGame.initialFacts[fact.ready]',
          'newGame.existingPartyFactId',
          'newGame.starterSelectionSceneId',
        ]),
      );
      expect(
        usages.every(
          (usage) =>
              usage.criticality ==
                  NarrativeDependencyCriticality.authoringWarning &&
              usage.resolution == NarrativeDependencyResolution.resolved,
        ),
        isTrue,
      );
    });

    test('indexes Event V2 source, conditions and produced Scene', () {
      final event = _event(
        id: _eventA,
        sceneId: 'scene.event',
        source: NarrativeEventSourceRef.entityInteract('map.port', 'npc.rival'),
        conditions: <NarrativeEventCondition>[
          NarrativeEventCondition.fact('rival.ready', true),
        ],
      );
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(id: 'rival.ready', label: 'Rival ready'),
        ],
        scenes: <SceneAsset>[_emptyScene('scene.event')],
        eventRegistry: _registry(<NarrativeEventDefinition>[event]),
      );

      final index = buildNarrativeDependencyIndex(project: project);
      final owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.eventV2,
        _eventA,
      );
      final usages = index.usagesOwnedBy(owner);

      expect(
        index.definitionsFor(owner).single.label,
        'Event $_eventA',
      );
      expect(
        usages.map((usage) => usage.path),
        containsAll(<String>[
          'eventRegistry.records[$_eventA].source.mapId',
          'eventRegistry.records[$_eventA].source.entityId',
          'eventRegistry.records[$_eventA].conditions[0].factId',
          'eventRegistry.records[$_eventA].sceneId',
        ]),
      );
      expect(
        usages
            .firstWhere((usage) => usage.path.endsWith('.source.mapId'))
            .resolution,
        NarrativeDependencyResolution.unavailable,
      );
    });

    test('indexes legacy claim sources, provenances and Event V2 targets', () {
      final claim = _legacyClaim(
        targetEventIds: const <String>[_eventA, _eventB],
      );
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        scenes: <SceneAsset>[_emptyScene('scene.event')],
        scenarios: const <ScenarioAsset>[
          ScenarioAsset(
            id: 'scenario_arrival',
            name: 'Arrival',
            entryNodeId: 'source',
            nodes: <ScenarioNode>[
              ScenarioNode(id: 'source', type: ScenarioNodeType.reference),
            ],
          ),
        ],
        eventRegistry: _registry(
          <NarrativeEventDefinition>[
            _event(
              id: _eventA,
              sceneId: 'scene.event',
              source: NarrativeEventSourceRef.mapEnter('map_port'),
            ),
            _event(
              id: _eventB,
              sceneId: 'scene.event',
              source: NarrativeEventSourceRef.mapEnter('map_port'),
            ),
          ],
          legacyClaims: <LegacySourceClaim>[claim],
        ),
      );
      final map = MapData(
        id: 'map_port',
        name: 'Port',
        size: const GridSize(width: 5, height: 5),
        events: const <MapEventDefinition>[
          MapEventDefinition(
            id: 'lysa',
            title: 'Lysa',
            pages: <MapEventPage>[],
            position: EventPosition(layerId: 'base', x: 1, y: 1),
          ),
        ],
      );

      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[map],
      );
      final claimOwner = NarrativeDependencyKey.legacySourceClaim(
        claim.cohortId,
      );
      final usages = index.usagesOwnedBy(claimOwner);

      expect(index.definitionsFor(claimOwner), hasLength(1));
      expect(
        usages.map((usage) => usage.target),
        containsAll(<NarrativeDependencyKey>[
          const NarrativeDependencyKey.map('map_port'),
          const NarrativeDependencyKey.mapSource(
            mapId: 'map_port',
            sourceKind: 'event',
            sourceId: 'lysa',
          ),
          const NarrativeDependencyKey.legacyScenario(
            'scenario_arrival',
          ),
          const NarrativeDependencyKey.legacyScenarioNode(
            scenarioId: 'scenario_arrival',
            nodeId: 'source',
          ),
          const NarrativeDependencyKey.eventV2(_eventA),
          const NarrativeDependencyKey.eventV2(_eventB),
        ]),
      );
      expect(
        usages
            .singleWhere(
              (usage) => usage.path.endsWith('.targetEventIds[$_eventA]'),
            )
            .resolution,
        NarrativeDependencyResolution.resolved,
      );
      expect(
        usages
            .singleWhere(
              (usage) => usage.path.endsWith('.members[0].provenance.eventId'),
            )
            .resolution,
        NarrativeDependencyResolution.resolved,
      );
    });

    test('reports broken legacy claim dependencies in their own namespace', () {
      final claim = _legacyClaim(targetEventIds: const <String>[_eventA]);
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        scenarios: const <ScenarioAsset>[
          ScenarioAsset(
            id: 'scenario_arrival',
            name: 'Arrival',
            entryNodeId: 'other',
            nodes: <ScenarioNode>[
              ScenarioNode(id: 'other', type: ScenarioNodeType.reference),
            ],
          ),
        ],
        eventRegistry: _registry(
          const <NarrativeEventDefinition>[],
          legacyClaims: <LegacySourceClaim>[claim],
        ),
      );

      final index = buildNarrativeDependencyIndex(project: project);
      final owner = NarrativeDependencyKey.legacySourceClaim(claim.cohortId);
      final usages = index.usagesOwnedBy(owner);

      expect(
        usages
            .singleWhere(
              (usage) => usage.path.endsWith('.targetEventIds[$_eventA]'),
            )
            .resolution,
        NarrativeDependencyResolution.missing,
      );
      expect(
        usages.where((usage) => usage.target.physicalMapId == 'map_port').every(
              (usage) =>
                  usage.resolution == NarrativeDependencyResolution.unavailable,
            ),
        isTrue,
      );
      expect(
        usages
            .singleWhere(
              (usage) => usage.path.endsWith('.provenance.scenarioId'),
            )
            .resolution,
        NarrativeDependencyResolution.resolved,
      );
      expect(
        usages
            .singleWhere(
              (usage) => usage.path.endsWith('.provenance.nodeId'),
            )
            .resolution,
        NarrativeDependencyResolution.missing,
      );
      expect(
        usages.where(
          (usage) =>
              usage.path.contains('Fingerprint') ||
              usage.path.contains('migrationReceiptId'),
        ),
        isEmpty,
      );
    });

    test('indexes Scene parents, typed nodes, conditions and consequences', () {
      final scene = SceneAsset(
        id: 'scene.full',
        name: 'Full scene',
        storylineId: 'story.main',
        chapterId: 'chapter.intro',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'condition',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                  sourceKind: SceneConditionSourceKind.fact,
                  sourceId: 'intro.ready',
                  operator: SceneConditionOperator.isTrue,
                ),
              ),
            ),
            SceneNode(
              id: 'legacy-condition',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                  sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
                  sourceId: 'legacy.intro.ready',
                  operator: SceneConditionOperator.isTrue,
                ),
              ),
            ),
            SceneNode(
              id: 'dialogue',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(dialogueId: 'dialogue.intro'),
            ),
            SceneNode(
              id: 'cinematic',
              kind: SceneNodeKind.cinematic,
              payload: SceneCinematicPayload(cinematicId: 'cine.intro'),
            ),
            SceneNode(
              id: 'action',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.completeStoryStep(stepId: 'step.intro'),
              ),
            ),
          ],
        ),
      );
      final project = _project(
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(id: 'intro.ready', label: 'Intro ready'),
          NarrativeFactDefinition(
            id: 'intro.legacy-ready',
            label: 'Legacy intro ready',
            legacyFlagName: 'legacy.intro.ready',
          ),
        ],
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'dialogue.intro',
            name: 'Intro',
            relativePath: 'dialogues/intro.yarn',
          ),
        ],
        cinematics: <CinematicAsset>[
          CinematicAsset(
            id: 'cine.intro',
            title: 'Intro',
            timeline: CinematicTimeline(),
          ),
        ],
        storylines: <StorylineAsset>[_storyline()],
        scenes: <SceneAsset>[scene],
      );

      final index = buildNarrativeDependencyIndex(project: project);
      const owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.scene,
        'scene.full',
      );

      expect(
        index.usagesOwnedBy(owner).map((usage) => usage.target),
        containsAll(<NarrativeDependencyKey>[
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.storyline,
            'story.main',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.chapter,
            'chapter.intro',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            'intro.ready',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            'intro.legacy-ready',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.dialogue,
            'dialogue.intro',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.cinematic,
            'cine.intro',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.step,
            'step.intro',
          ),
        ]),
      );
      expect(
        index.usagesOwnedBy(owner).every(
              (usage) =>
                  usage.resolution == NarrativeDependencyResolution.resolved,
            ),
        isTrue,
      );
    });

    test('indexes mark-event-consumed map and event fields separately', () {
      final scene = SceneAsset(
        id: 'scene.consume',
        name: 'Consume legacy event',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'action',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.markEventConsumed(
                  mapId: 'map.port',
                  eventId: 'event.legacy',
                ),
              ),
            ),
          ],
        ),
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'map.port',
              name: 'Port',
              relativePath: 'maps/port.json',
            ),
          ],
          scenes: <SceneAsset>[scene],
        ),
      );
      final usages = index.usagesOwnedBy(
        const NarrativeDependencyKey.scene('scene.consume'),
      );

      expect(
        usages.singleWhere((usage) => usage.path.endsWith('.mapId')).target,
        const NarrativeDependencyKey.map('map.port'),
      );
      expect(
        usages.singleWhere((usage) => usage.path.endsWith('.eventId')).target,
        const NarrativeDependencyKey.mapSource(
          mapId: 'map.port',
          sourceKind: 'event',
          sourceId: 'event.legacy',
        ),
      );
    });

    test('keeps legacy consumed-event and World Rule condition namespaces', () {
      final scene = SceneAsset(
        id: 'scene.conditions',
        name: 'Condition namespaces',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'consumed',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                  sourceKind: SceneConditionSourceKind.consumedEvent,
                  sourceId: 'event.legacy',
                  operator: SceneConditionOperator.isTrue,
                ),
              ),
            ),
            SceneNode(
              id: 'world',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                  sourceKind: SceneConditionSourceKind.worldState,
                  sourceId: 'rule.story',
                  operator: SceneConditionOperator.isTrue,
                ),
              ),
            ),
          ],
        ),
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'map.pending',
              name: 'Pending map',
              relativePath: 'maps/pending.json',
            ),
          ],
          scenes: <SceneAsset>[scene],
          worldRules: <WorldRuleDefinition>[_worldRule()],
        ),
      );
      final usages = index.usagesOwnedBy(
        const NarrativeDependencyKey.scene('scene.conditions'),
      );
      final targets = usages.map((usage) => usage.target);

      expect(
        targets,
        containsAll(<NarrativeDependencyKey>[
          const NarrativeDependencyKey.synthetic(
            sourceKind: 'legacyMapEvent',
            sourceId: 'event.legacy',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.worldRule,
            'rule.story',
          ),
        ]),
      );
      expect(
        usages
            .singleWhere(
              (usage) => usage.target.sourceKind == 'legacyMapEvent',
            )
            .resolution,
        NarrativeDependencyResolution.unavailable,
      );
    });

    test('marks a duplicated definition as ambiguous', () {
      final project = _project(
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(id: 'fact.duplicate', label: 'First'),
          NarrativeFactDefinition(id: 'fact.duplicate', label: 'Second'),
        ],
        newGame: const ProjectNewGameConfig(
          enabled: true,
          initialFacts: <String, bool>{'fact.duplicate': true},
        ),
      );

      final index = buildNarrativeDependencyIndex(project: project);

      expect(index.usages.single.resolution,
          NarrativeDependencyResolution.ambiguous);
      expect(
        index.issues.where(
          (issue) => issue.kind == NarrativeDependencyIssueKind.duplicateId,
        ),
        hasLength(1),
      );
    });
  });

  group('Map, Storyline, Cinematic, WorldRule and legacy collectors', () {
    test('indexes loaded map sources and every authored dialogue reference',
        () {
      final map = MapData(
        id: 'map.port',
        name: 'Port',
        size: const GridSize(width: 10, height: 10),
        entities: <MapEntity>[
          MapEntity(
            id: 'npc.rival',
            kind: MapEntityKind.npc,
            pos: const GridPos(x: 1, y: 1),
            npc: const MapEntityNpcData(
              displayName: 'Rival',
              dialogue: DialogueRef(dialogueId: 'dialogue.default'),
              defeatDialogueRef: DialogueRef(dialogueId: 'dialogue.alt'),
              conditionalDialogues: <MapEntityConditionalDialogue>[
                MapEntityConditionalDialogue(
                  when: MapEntityRuntimePredicate(
                    kind: MapEntityRuntimePredicateKind.storyFlagSet,
                    refId: 'legacy.ready',
                  ),
                  dialogue: DialogueRef(dialogueId: 'dialogue.alt'),
                ),
              ],
            ),
          ),
        ],
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'chest',
            layerId: 'objects',
            elementId: 'element.chest',
            pos: const GridPos(x: 2, y: 2),
            behaviors: const <MapPlacedElementBehavior>[
              MapPlacedElementBehavior(
                effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.openDialogue,
                  dialogue: DialogueRef(dialogueId: 'dialogue.alt'),
                ),
              ),
            ],
          ),
        ],
        triggers: const <MapTrigger>[
          MapTrigger(
            id: 'trigger.arrival',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 0, y: 0),
              size: GridSize(width: 2, height: 2),
            ),
          ),
        ],
        gameplayZones: const <MapGameplayZone>[
          MapGameplayZone(
            id: 'zone.harbor',
            name: 'Harbor zone',
            kind: GameplayZoneKind.special,
            area: MapRect(
              pos: GridPos(x: 4, y: 4),
              size: GridSize(width: 2, height: 2),
            ),
          ),
        ],
        warps: const <MapWarp>[
          MapWarp(
            id: 'warp.exit',
            pos: GridPos(x: 9, y: 9),
            targetMapId: 'map.other',
            targetPos: GridPos(x: 0, y: 0),
          ),
        ],
        events: <MapEventDefinition>[
          MapEventDefinition(
            id: 'event.legacy',
            pages: <MapEventPage>[
              MapEventPage(
                pageNumber: 0,
                condition: ScriptConditionFactory.flagIsSet('legacy.ready'),
                sceneTarget: const MapEventSceneTarget(sceneId: 'scene.map'),
              ),
            ],
            position: const EventPosition(layerId: 'objects', x: 3, y: 3),
          ),
        ],
      );
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'dialogue.default',
            name: 'Default',
            relativePath: 'dialogues/default.yarn',
          ),
          ProjectDialogueEntry(
            id: 'dialogue.alt',
            name: 'Alternate',
            relativePath: 'dialogues/alt.yarn',
          ),
        ],
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(
            id: 'fact.ready',
            label: 'Ready',
            legacyFlagName: 'legacy.ready',
          ),
        ],
        scenes: <SceneAsset>[_emptyScene('scene.map')],
        scenarios: const <ScenarioAsset>[
          ScenarioAsset(
            id: 'scenario.warp',
            name: 'Warp consumer',
            entryNodeId: 'start',
            nodes: <ScenarioNode>[
              ScenarioNode(
                id: 'start',
                type: ScenarioNodeType.reference,
                binding: ScenarioNodeBinding(
                  mapId: 'map.port',
                  warpId: 'warp.exit',
                ),
              ),
            ],
          ),
        ],
      );

      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[map, _emptyMap('map.other')],
      );

      for (final key in <NarrativeDependencyKey>[
        const NarrativeDependencyKey.map('map.port'),
        const NarrativeDependencyKey(
          NarrativeDependencyTargetKind.sourceMap,
          'npc.rival',
          scope: 'map',
          parentId: 'map.port',
          sourceKind: 'entity',
        ),
        const NarrativeDependencyKey(
          NarrativeDependencyTargetKind.sourceMap,
          'trigger.arrival',
          scope: 'map',
          parentId: 'map.port',
          sourceKind: 'trigger',
        ),
        const NarrativeDependencyKey.mapSource(
          mapId: 'map.port',
          sourceKind: 'gameplayZone',
          sourceId: 'zone.harbor',
        ),
        const NarrativeDependencyKey.mapSource(
          mapId: 'map.port',
          sourceKind: 'warp',
          sourceId: 'warp.exit',
        ),
        const NarrativeDependencyKey(
          NarrativeDependencyTargetKind.sourceMap,
          'event.legacy',
          scope: 'map',
          parentId: 'map.port',
          sourceKind: 'event',
        ),
      ]) {
        expect(
          index.definitionsFor(key),
          hasLength(1),
        );
      }
      expect(
        index.usagesFor(
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.dialogue,
            'dialogue.alt',
          ),
        ),
        hasLength(3),
      );
      expect(
        index.usagesFor(
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            'fact.ready',
          ),
        ),
        isNotEmpty,
      );
      expect(
        index.usagesFor(
          const NarrativeDependencyKey.mapSource(
            mapId: 'map.port',
            sourceKind: 'warp',
            sourceId: 'warp.exit',
          ),
        ),
        hasLength(1),
      );
      expect(
        index.usages
            .where(
              (usage) => usage.owner.parentId == 'map.port',
            )
            .every(
              (usage) =>
                  usage.resolution == NarrativeDependencyResolution.resolved,
            ),
        isTrue,
      );
    });

    test('keeps explicit dialogue script overrides outside the registry', () {
      final map = MapData(
        id: 'map.override',
        name: 'Override map',
        size: const GridSize(width: 4, height: 4),
        entities: const <MapEntity>[
          MapEntity(
            id: 'npc.external',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(
              displayName: 'External NPC',
              dialogue: DialogueRef(
                dialogueId: 'external.node',
                scriptPathRelative: 'scripts/external.yarn',
              ),
            ),
          ),
        ],
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(),
        maps: <MapData>[map],
      );
      final usage = index
          .usagesOwnedBy(
            const NarrativeDependencyKey.mapSource(
              mapId: 'map.override',
              sourceKind: 'entity',
              sourceId: 'npc.external',
            ),
          )
          .single;

      expect(usage.target.kind, NarrativeDependencyTargetKind.sourceMap);
      expect(usage.target.sourceKind, 'legacyDialogueScript');
      expect(usage.target.id, 'scripts/external.yarn');
      expect(usage.resolution, NarrativeDependencyResolution.legacyExternal);
      expect(
        index.issues.where(
          (issue) => issue.target.id == 'external.node',
        ),
        isEmpty,
      );
    });

    test('indexes Storyline links, relationships, anchors and effects', () {
      final storyline = StorylineAsset(
        id: 'story.main',
        type: StorylineType.main,
        title: 'Main',
        chapters: <StorylineChapter>[
          StorylineChapter(
            id: 'chapter.main',
            title: 'Chapter',
            order: 0,
            directSceneLinkIds: const <String>['scene.chapter'],
            steps: <StorylineStep>[
              StorylineStep(
                id: 'step.main',
                title: 'Step',
                order: 0,
                sceneLinkIds: const <String>['scene.main'],
              ),
            ],
          ),
        ],
        sceneLinks: <StorylineSceneLink>[
          StorylineSceneLink(
            id: 'link.main',
            chapterId: 'chapter.main',
            stepId: 'step.main',
            label: 'Legacy bridge',
            state: StorylineSceneLinkState.linkedScenario,
            role: StorylineSceneLinkRole.primary,
            sceneRef: StorylineSceneRef(
              kind: StorylineSceneRefKind.scenario,
              targetId: 'scenario.legacy',
            ),
            order: 0,
            outcomeLinks: <StorylineSceneOutcomeLink>[
              StorylineSceneOutcomeLink(
                id: 'outcome.main',
                outcomeId: 'completed',
                effects: <StorylineEffect>[
                  StorylineEffect(
                    type: StorylineEffectType.emitFact,
                    targetId: 'fact.story',
                  ),
                  StorylineEffect(
                    type: StorylineEffectType.setWorldRule,
                    targetId: 'rule.story',
                  ),
                  StorylineEffect(
                    type: StorylineEffectType.unlockStoryline,
                    targetId: 'story.side',
                  ),
                ],
              ),
            ],
          ),
        ],
        relationships: <StorylineRelationship>[
          StorylineRelationship(
            id: 'relationship.side',
            kind: StorylineRelationshipKind.sideQuestUnlockedBy,
            sourceStorylineId: 'story.main',
            targetStorylineId: 'story.side',
            anchor: StorylineAnchor(
              kind: StorylineAnchorKind.step,
              targetId: 'step.main',
            ),
          ),
        ],
        legacySource: StorylineLegacySource(
          kind: 'globalStory',
          sourceId: 'scenario.legacy',
        ),
      );
      final project = _project(
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(
            id: 'fact.story',
            label: 'Story fact',
            legacyFlagName: 'legacy.story',
          ),
        ],
        scenes: <SceneAsset>[
          _emptyScene('scene.main'),
          _emptyScene('scene.chapter'),
        ],
        storylines: <StorylineAsset>[
          storyline,
          StorylineAsset(
            id: 'story.side',
            type: StorylineType.sideQuest,
            title: 'Side',
          ),
        ],
        worldRules: <WorldRuleDefinition>[_worldRule()],
        scenarios: const <ScenarioAsset>[
          ScenarioAsset(
            id: 'scenario.legacy',
            name: 'Legacy',
            scope: ScenarioScope.globalStory,
            entryNodeId: 'start',
            nodes: <ScenarioNode>[
              ScenarioNode(
                id: 'start',
                type: ScenarioNodeType.start,
                payload: ScenarioNodePayload(
                  condition: ScriptCondition(
                    type: ScriptConditionType.flagIsSet,
                    params: <String, String>{
                      ScriptConditionParams.flagName: 'legacy.story',
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      );

      final index = buildNarrativeDependencyIndex(project: project);
      const owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.storyline,
        'story.main',
      );

      expect(
        index.usagesOwnedBy(owner).map((usage) => usage.target),
        containsAll(<NarrativeDependencyKey>[
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.scene,
            'scene.main',
          ),
          const NarrativeDependencyKey.scene('scene.chapter'),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.storyline,
            'story.side',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.step,
            'step.main',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.chapter,
            'chapter.main',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            'fact.story',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.worldRule,
            'rule.story',
          ),
        ]),
      );
      expect(
        index
            .usagesOwnedBy(owner)
            .singleWhere(
              (usage) =>
                  usage.target ==
                  const NarrativeDependencyKey.scene('scene.chapter'),
            )
            .path,
        'storylines[story.main].chapters[0].directSceneLinkIds[0]',
      );
      expect(
        index
            .usagesOwnedBy(owner)
            .where(
              (usage) => usage.path.contains('legacy'),
            )
            .every(
              (usage) =>
                  usage.resolution ==
                  NarrativeDependencyResolution.legacyExternal,
            ),
        isTrue,
      );
      expect(
        index
            .usagesFor(
              const NarrativeDependencyKey(
                NarrativeDependencyTargetKind.fact,
                'fact.story',
              ),
            )
            .any(
              (usage) =>
                  usage.owner ==
                  const NarrativeDependencyKey.legacyScenario(
                    'scenario.legacy',
                  ),
            ),
        isTrue,
      );
      expect(
        index
            .usagesOwnedBy(owner)
            .singleWhere(
              (usage) => usage.path.endsWith(
                'relationships[0].sourceStorylineId',
              ),
            )
            .target,
        const NarrativeDependencyKey(
          NarrativeDependencyTargetKind.storyline,
          'story.main',
        ),
      );
    });

    test('indexes legacy global-story document structure and metadata', () {
      final scenario = ScenarioAsset(
        id: 'global_story',
        name: 'Legacy global story',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
        nodes: const <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
        metadata: const <String, String>{
          'authoring.owner': 'narrative-studio',
          'authoring.globalStoryStudioDocument': '''
{
  "chapters": [
    {
      "id": "chapter_intro",
      "name": "Intro chapter",
      "description": "Legacy chapter",
      "order": 2,
      "stepIds": ["step_intro"]
    }
  ]
}
''',
          'authoring.stepStudioDocument': '''
{
  "steps": [
    {
      "id": "step_intro",
      "name": "Intro step",
      "description": "Legacy step",
      "order": 3
    }
  ]
}
''',
        },
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(scenarios: <ScenarioAsset>[scenario]),
      );
      const scenarioKey = NarrativeDependencyKey.legacyScenario('global_story');
      const chapterKey = NarrativeDependencyKey.legacyGlobalStoryPart(
        scenarioId: 'global_story',
        partKind: 'globalStoryChapter',
        partId: 'chapter_intro',
      );
      const stepKey = NarrativeDependencyKey.legacyGlobalStoryPart(
        scenarioId: 'global_story',
        partKind: 'globalStoryStep',
        partId: 'step_intro',
      );

      final scenarioDefinition = index.definitionsFor(scenarioKey).single;
      final chapterDefinition = index.definitionsFor(chapterKey).single;
      final stepDefinition = index.definitionsFor(stepKey).single;

      expect(scenarioDefinition.metadata['scope'], 'globalStory');
      expect(scenarioDefinition.metadata['entryNodeId'], 'start');
      expect(
        scenarioDefinition.metadata['authoring.owner'],
        'narrative-studio',
      );
      expect(chapterDefinition.owner, scenarioKey);
      expect(
        chapterDefinition.metadata,
        containsPair(
          'legacyDocument',
          'authoring.globalStoryStudioDocument',
        ),
      );
      expect(chapterDefinition.metadata['order'], '2');
      expect(stepDefinition.owner, chapterKey);
      expect(
        stepDefinition.metadata,
        containsPair('legacyDocument', 'authoring.stepStudioDocument'),
      );
      expect(stepDefinition.metadata['order'], '3');
    });

    test('indexes Cinematic parents and WorldRule source, target and effect',
        () {
      final map = MapData(
        id: 'map.port',
        name: 'Port',
        size: const GridSize(width: 5, height: 5),
        entities: const <MapEntity>[
          MapEntity(
            id: 'npc.rival',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(displayName: 'Rival'),
          ),
        ],
      );
      final cinematic = CinematicAsset(
        id: 'cine.port',
        title: 'Port',
        storylineId: 'story.main',
        chapterId: 'chapter.intro',
        mapId: 'map.port',
        stageContext: CinematicStageContext(
          movementTargetBindings: <CinematicMovementTargetBinding>[
            CinematicMovementTargetBinding(
              targetId: 'target.entity',
              kind: CinematicMovementTargetBindingKind.mapEntity,
              sourceId: 'npc.rival',
            ),
            CinematicMovementTargetBinding(
              targetId: 'target.event',
              kind: CinematicMovementTargetBindingKind.mapEvent,
              sourceId: 'event.arrival',
            ),
            CinematicMovementTargetBinding(
              targetId: 'target.abstract',
              kind: CinematicMovementTargetBindingKind.abstractPoint,
            ),
          ],
        ),
        timeline: CinematicTimeline(),
        legacyBridge: CinematicLegacyBridge(
          sourceKind: CinematicLegacyBridgeSourceKind.scenarioAsset,
          scenarioId: 'scenario.legacy',
        ),
      );
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(id: 'fact.story', label: 'Story fact'),
        ],
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'dialogue.rival',
            name: 'Rival',
            relativePath: 'dialogues/rival.yarn',
          ),
        ],
        storylines: <StorylineAsset>[_storyline()],
        cinematics: <CinematicAsset>[cinematic],
        worldRules: <WorldRuleDefinition>[_worldRule()],
      );

      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[map],
      );
      const cinematicOwner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.cinematic,
        'cine.port',
      );
      const ruleOwner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.worldRule,
        'rule.story',
      );

      expect(
        index.usagesOwnedBy(cinematicOwner).map((usage) => usage.target),
        containsAll(<NarrativeDependencyKey>[
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.storyline,
            'story.main',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.chapter,
            'chapter.intro',
          ),
          const NarrativeDependencyKey.map('map.port'),
          const NarrativeDependencyKey.mapSource(
            mapId: 'map.port',
            sourceKind: 'entity',
            sourceId: 'npc.rival',
          ),
          const NarrativeDependencyKey.mapSource(
            mapId: 'map.port',
            sourceKind: 'event',
            sourceId: 'event.arrival',
          ),
        ]),
      );
      expect(
        index
            .usagesOwnedBy(cinematicOwner)
            .singleWhere(
              (usage) => usage.path.endsWith('legacyBridge.scenarioId'),
            )
            .resolution,
        NarrativeDependencyResolution.legacyExternal,
      );
      expect(
        index.usagesOwnedBy(ruleOwner).map((usage) => usage.target),
        containsAll(<NarrativeDependencyKey>[
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            'fact.story',
          ),
          const NarrativeDependencyKey.map('map.port'),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.sourceMap,
            'npc.rival',
            scope: 'map',
            parentId: 'map.port',
            sourceKind: 'entity',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.dialogue,
            'dialogue.rival',
          ),
        ]),
      );
    });

    test('uses the actor binding, not a placement decoy, for fromMapEntity',
        () {
      final cinematic = CinematicAsset(
        id: 'cine.spawn',
        title: 'Spawn',
        mapId: 'map.port',
        stageContext: CinematicStageContext(
          actorBindings: <CinematicActorBinding>[
            CinematicActorBinding(
              actorId: 'actor.rival',
              kind: CinematicActorBindingKind.mapEntity,
              mapEntityId: 'npc.rival',
            ),
          ],
          initialPlacements: <CinematicActorInitialPlacement>[
            CinematicActorInitialPlacement(
              actorId: 'actor.rival',
              kind: CinematicActorInitialPlacementKind.fromMapEntity,
              targetId: 'npc.decoy',
            ),
          ],
        ),
        timeline: CinematicTimeline(),
      );
      final map = MapData(
        id: 'map.port',
        name: 'Port',
        size: const GridSize(width: 5, height: 5),
        entities: const <MapEntity>[
          MapEntity(
            id: 'npc.rival',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(displayName: 'Rival'),
          ),
        ],
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'map.port',
              name: 'Port',
              relativePath: 'maps/port.json',
            ),
          ],
          cinematics: <CinematicAsset>[cinematic],
        ),
        maps: <MapData>[map],
      );
      const owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.cinematic,
        'cine.spawn',
      );

      final usages = index.usagesOwnedBy(owner);
      final usage = usages.singleWhere(
        (entry) => entry.path.endsWith('actorBindings[0].mapEntityId'),
      );
      expect(
        usage.target,
        const NarrativeDependencyKey.mapSource(
          mapId: 'map.port',
          sourceKind: 'entity',
          sourceId: 'npc.rival',
        ),
      );
      expect(usage.resolution, NarrativeDependencyResolution.resolved);
      expect(
        usages.where(
          (entry) =>
              entry.path.contains('initialPlacements') ||
              entry.target.id == 'npc.decoy',
        ),
        isEmpty,
      );
    });

    test('keeps consumed WorldRule sources in the legacy Map Event namespace',
        () {
      final event = _event(
        id: _eventA,
        sceneId: 'scene.event',
        source: NarrativeEventSourceRef.mapEnter('map.port'),
      );
      final rule = WorldRuleDefinition(
        id: 'rule.event',
        label: 'Event rule',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.consumedEvent,
          sourceId: _eventA,
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'map.port',
          entityId: 'npc.rival',
        ),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          scenes: <SceneAsset>[_emptyScene('scene.event')],
          eventRegistry: _registry(<NarrativeEventDefinition>[event]),
          worldRules: <WorldRuleDefinition>[rule],
        ),
      );
      const owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.worldRule,
        'rule.event',
      );

      final usage = index.usagesOwnedBy(owner).singleWhere(
            (entry) => entry.path.endsWith('.source.sourceId'),
          );
      expect(
        usage.target,
        const NarrativeDependencyKey.synthetic(
          sourceKind: 'legacyMapEvent',
          sourceId: _eventA,
        ),
      );
      expect(usage.resolution, NarrativeDependencyResolution.missing);
      expect(
        index
            .usagesFor(const NarrativeDependencyKey.eventV2(_eventA))
            .where((entry) => entry.owner == owner),
        isEmpty,
      );
    });

    test('indexes legacy Scenario completeStep payload parameters', () {
      final storyline = _storyline();
      const scenario = ScenarioAsset(
        id: 'scenario.complete',
        name: 'Complete',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'complete',
        nodes: <ScenarioNode>[
          ScenarioNode(
            id: 'complete',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: 'completeStep',
              params: <String, String>{'stepId': 'step.intro'},
            ),
          ),
        ],
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          storylines: <StorylineAsset>[storyline],
          scenarios: const <ScenarioAsset>[scenario],
        ),
      );
      const owner = NarrativeDependencyKey.legacyScenario('scenario.complete');

      final usage = index.usagesOwnedBy(owner).singleWhere(
            (entry) => entry.path.endsWith('.payload.params.stepId'),
          );
      expect(
        usage.target,
        const NarrativeDependencyKey(
          NarrativeDependencyTargetKind.step,
          'step.intro',
        ),
      );
      expect(usage.resolution, NarrativeDependencyResolution.resolved);
    });
  });

  group('diagnostics, cycles and load', () {
    test('reports consumed Event V2 cycles as runtime blocking', () {
      final project = _project(
        scenes: <SceneAsset>[_emptyScene('scene.event')],
        eventRegistry: _registry(<NarrativeEventDefinition>[
          _event(
            id: _eventA,
            sceneId: 'scene.event',
            source: NarrativeEventSourceRef.mapEnter('map.loaded'),
            conditions: <NarrativeEventCondition>[
              NarrativeEventCondition.narrativeEventConsumed(_eventB, true),
            ],
          ),
          _event(
            id: _eventB,
            sceneId: 'scene.event',
            source: NarrativeEventSourceRef.mapEnter('map.loaded'),
            conditions: <NarrativeEventCondition>[
              NarrativeEventCondition.narrativeEventConsumed(_eventA, true),
            ],
          ),
        ]),
      );

      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[_emptyMap('map.loaded')],
      );
      final cycles = index.issues.where(
        (issue) => issue.kind == NarrativeDependencyIssueKind.forbiddenCycle,
      );

      expect(cycles, hasLength(2));
      expect(
        cycles.every(
          (issue) =>
              issue.target.kind == NarrativeDependencyTargetKind.eventV2 &&
              issue.criticality ==
                  NarrativeDependencyCriticality.runtimeBlocking,
        ),
        isTrue,
      );
    });

    test('ignores false and mixed consumed Event conditions for cycles', () {
      NarrativeDependencyIndex buildWithExpectations(bool a, bool b) {
        return buildNarrativeDependencyIndex(
          project: _project(
            scenes: <SceneAsset>[_emptyScene('scene.event')],
            eventRegistry: _registry(<NarrativeEventDefinition>[
              _event(
                id: _eventA,
                sceneId: 'scene.event',
                source: NarrativeEventSourceRef.mapEnter('map.loaded'),
                conditions: <NarrativeEventCondition>[
                  NarrativeEventCondition.narrativeEventConsumed(_eventB, a),
                ],
              ),
              _event(
                id: _eventB,
                sceneId: 'scene.event',
                source: NarrativeEventSourceRef.mapEnter('map.loaded'),
                conditions: <NarrativeEventCondition>[
                  NarrativeEventCondition.narrativeEventConsumed(_eventA, b),
                ],
              ),
            ]),
          ),
          maps: <MapData>[_emptyMap('map.loaded')],
        );
      }

      for (final index in <NarrativeDependencyIndex>[
        buildWithExpectations(false, false),
        buildWithExpectations(true, false),
      ]) {
        expect(
          index.issues.where(
            (issue) =>
                issue.kind == NarrativeDependencyIssueKind.forbiddenCycle,
          ),
          isEmpty,
        );
      }
    });

    test('marks a multiply claimed legacy Fact alias as ambiguous', () {
      final map = MapData(
        id: 'map.alias',
        name: 'Alias',
        size: const GridSize(width: 2, height: 2),
        events: <MapEventDefinition>[
          MapEventDefinition(
            id: 'event.alias',
            pages: <MapEventPage>[
              MapEventPage(
                pageNumber: 0,
                condition: ScriptConditionFactory.flagIsSet('legacy.shared'),
              ),
            ],
            position: const EventPosition(layerId: 'objects', x: 0, y: 0),
          ),
        ],
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'map.alias',
              name: 'Alias',
              relativePath: 'maps/alias.json',
            ),
          ],
          facts: <NarrativeFactDefinition>[
            NarrativeFactDefinition(
              id: 'fact.first',
              label: 'First',
              legacyFlagName: 'legacy.shared',
            ),
            NarrativeFactDefinition(
              id: 'fact.second',
              label: 'Second',
              legacyFlagName: 'legacy.shared',
            ),
          ],
        ),
        maps: <MapData>[map],
      );
      final usage = index.usages.singleWhere(
        (usage) => usage.path.endsWith('.condition.params.flagName'),
      );

      expect(usage.resolution, NarrativeDependencyResolution.ambiguous);
      expect(
        index.issues.where(
          (issue) =>
              issue.kind.name == 'ambiguousReference' &&
              issue.owner == usage.owner &&
              issue.path == usage.path,
        ),
        hasLength(1),
      );
    });

    test('keeps slash-containing map scopes distinct for dialogue queries', () {
      MapData mapWithDialogue(String mapId, String dialogueId) => MapData(
            id: mapId,
            name: mapId,
            size: const GridSize(width: 2, height: 2),
            entities: <MapEntity>[
              MapEntity(
                id: 'npc',
                kind: MapEntityKind.npc,
                pos: const GridPos(x: 0, y: 0),
                npc: MapEntityNpcData(
                  dialogue: DialogueRef(dialogueId: dialogueId),
                ),
              ),
            ],
          );
      final foo = mapWithDialogue('foo', 'dialogue.foo');
      final fooBar = mapWithDialogue('foo/bar', 'dialogue.foo-bar');
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'foo',
              name: 'Foo',
              relativePath: 'maps/foo.json',
            ),
            ProjectMapEntry(
              id: 'foo/bar',
              name: 'Foo bar',
              relativePath: 'maps/foo-bar.json',
            ),
          ],
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'dialogue.foo',
              name: 'Foo',
              relativePath: 'dialogues/foo.yarn',
            ),
            ProjectDialogueEntry(
              id: 'dialogue.foo-bar',
              name: 'Foo bar',
              relativePath: 'dialogues/foo-bar.yarn',
            ),
          ],
        ),
        maps: <MapData>[foo, fooBar],
      );

      expect(
        collectDialogueIdsReferencedOnMap(foo, dependencyIndex: index),
        <String>{'dialogue.foo'},
      );
      expect(
        collectDialogueIdsReferencedOnMap(fooBar, dependencyIndex: index),
        <String>{'dialogue.foo-bar'},
      );
    });

    test('detects duplicated map manifest IDs without loaded map data', () {
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'map.duplicate',
              name: 'First',
              relativePath: 'maps/first.json',
            ),
            ProjectMapEntry(
              id: 'map.duplicate',
              name: 'Second',
              relativePath: 'maps/second.json',
            ),
          ],
        ),
      );

      expect(
        index.issues.where(
          (issue) =>
              issue.kind == NarrativeDependencyIssueKind.duplicateId &&
              issue.target.kind == NarrativeDependencyTargetKind.sourceMap &&
              issue.target.id == 'map.duplicate',
        ),
        hasLength(1),
      );
    });

    test('reports unavailable map data without a missing-reference issue', () {
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'map.pending',
              name: 'Pending',
              relativePath: 'maps/pending.json',
            ),
          ],
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map.pending',
          ),
        ),
      );

      expect(index.usages.single.resolution,
          NarrativeDependencyResolution.unavailable);
      expect(
        index.issues.where(
          (issue) => issue.kind.name == 'unavailableReference',
        ),
        hasLength(1),
      );
      expect(
        index.issues.where(
          (issue) =>
              issue.kind == NarrativeDependencyIssueKind.missingReference,
        ),
        isEmpty,
      );
    });

    test('resolves a known legacy event despite an unrelated unloaded map', () {
      final scene = SceneAsset(
        id: 'scene.known-event',
        name: 'Known event',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'condition',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                  sourceKind: SceneConditionSourceKind.consumedEvent,
                  sourceId: 'event.known',
                  operator: SceneConditionOperator.isTrue,
                ),
              ),
            ),
          ],
        ),
      );
      final loadedMap = MapData(
        id: 'map.loaded',
        name: 'Loaded',
        size: const GridSize(width: 4, height: 4),
        events: <MapEventDefinition>[
          MapEventDefinition(
            id: 'event.known',
            pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
            position: const EventPosition(layerId: 'objects', x: 1, y: 1),
          ),
        ],
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'map.loaded',
              name: 'Loaded',
              relativePath: 'maps/loaded.json',
            ),
            ProjectMapEntry(
              id: 'map.pending',
              name: 'Pending',
              relativePath: 'maps/pending.json',
            ),
          ],
          scenes: <SceneAsset>[scene],
        ),
        maps: <MapData>[loadedMap],
      );

      expect(
        index
            .usagesFor(
              const NarrativeDependencyKey.synthetic(
                sourceKind: 'legacyMapEvent',
                sourceId: 'event.known',
              ),
            )
            .single
            .resolution,
        NarrativeDependencyResolution.resolved,
      );
    });

    test('reports Scene graph cycles but invents no Storyline cycle rule', () {
      final cyclicScene = SceneAsset(
        id: 'scene.cycle',
        name: 'Cycle',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'merge', kind: SceneNodeKind.merge),
          ],
          edges: <SceneEdge>[
            SceneEdge(
              id: 'edge.a',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'merge',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'edge.b',
              fromNodeId: 'merge',
              fromPortId: 'completed',
              toNodeId: 'start',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      );
      final storyA = StorylineAsset(
        id: 'story.a',
        type: StorylineType.main,
        title: 'A',
        relationships: <StorylineRelationship>[
          StorylineRelationship(
            id: 'a-to-b',
            kind: StorylineRelationshipKind.requires,
            sourceStorylineId: 'story.a',
            targetStorylineId: 'story.b',
          ),
        ],
      );
      final storyB = StorylineAsset(
        id: 'story.b',
        type: StorylineType.sideQuest,
        title: 'B',
        relationships: <StorylineRelationship>[
          StorylineRelationship(
            id: 'b-to-a',
            kind: StorylineRelationshipKind.requires,
            sourceStorylineId: 'story.b',
            targetStorylineId: 'story.a',
          ),
        ],
      );

      final index = buildNarrativeDependencyIndex(
        project: _project(
          scenes: <SceneAsset>[cyclicScene],
          storylines: <StorylineAsset>[storyA, storyB],
        ),
      );
      final cycles = index.issues.where(
        (issue) => issue.kind == NarrativeDependencyIssueKind.forbiddenCycle,
      );

      expect(cycles, hasLength(1));
      expect(cycles.single.target.id, 'scene.cycle');
      expect(
        cycles.single.criticality,
        NarrativeDependencyCriticality.authoringWarning,
      );
    });

    test('detects Chapter and Step duplicates globally without double issue',
        () {
      StorylineAsset story(String id) => StorylineAsset(
            id: id,
            type: StorylineType.main,
            title: id,
            chapters: <StorylineChapter>[
              StorylineChapter(
                id: 'chapter.shared',
                title: 'Shared',
                order: 0,
                steps: <StorylineStep>[
                  StorylineStep(
                    id: 'step.shared',
                    title: 'Shared',
                    order: 0,
                  ),
                ],
              ),
            ],
          );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          storylines: <StorylineAsset>[story('story.a'), story('story.b')],
          scenes: <SceneAsset>[
            SceneAsset(
              id: 'scene.ambiguous',
              name: 'Ambiguous',
              chapterId: 'chapter.shared',
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: <SceneNode>[
                  SceneNode(id: 'start', kind: SceneNodeKind.start),
                ],
              ),
            ),
          ],
        ),
      );

      expect(
        index.issues.where(
          (issue) => issue.kind == NarrativeDependencyIssueKind.duplicateId,
        ),
        hasLength(2),
      );
      expect(
        index.issues.where(
          (issue) =>
              issue.kind == NarrativeDependencyIssueKind.missingReference &&
              issue.target.id == 'chapter.shared',
        ),
        isEmpty,
      );
      expect(
        index.usages
            .singleWhere(
              (usage) => usage.target.id == 'chapter.shared',
            )
            .resolution,
        NarrativeDependencyResolution.ambiguous,
      );
    });

    test('is stack safe and deterministic for 10000 Event dependencies', () {
      final events = <NarrativeEventDefinition>[];
      for (var index = 0; index < 10000; index++) {
        final id = _largeEventId(index);
        events.add(
          _event(
            id: id,
            sceneId: 'scene.event',
            source: NarrativeEventSourceRef.mapEnter('map.loaded'),
            conditions: index == 0
                ? const <NarrativeEventCondition>[]
                : <NarrativeEventCondition>[
                    NarrativeEventCondition.narrativeEventConsumed(
                      _largeEventId(index - 1),
                      true,
                    ),
                  ],
          ),
        );
      }
      final project = _project(
        scenes: <SceneAsset>[_emptyScene('scene.event')],
        eventRegistry: _registry(events),
      );

      final first = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[_emptyMap('map.loaded')],
      );
      final second = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[_emptyMap('map.loaded')],
      );

      expect(
        first.issues.where(
          (issue) => issue.kind == NarrativeDependencyIssueKind.forbiddenCycle,
        ),
        isEmpty,
      );
      expect(first.definitions, hasLength(10002));
      expect(
        first.usages.map((usage) => '${usage.target}|${usage.path}').toList(),
        second.usages.map((usage) => '${usage.target}|${usage.path}').toList(),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('progressive legacy read-model delegation', () {
    test('map dialogue collector delegates to the canonical map slice', () {
      final map = MapData(
        id: 'map.dialogue',
        name: 'Dialogue',
        size: const GridSize(width: 3, height: 3),
        entities: const <MapEntity>[
          MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 0, y: 0),
            npc: MapEntityNpcData(
              dialogue: DialogueRef(dialogueId: 'dialogue.default'),
              conditionalDialogues: <MapEntityConditionalDialogue>[
                MapEntityConditionalDialogue(
                  when: MapEntityRuntimePredicate(
                    kind: MapEntityRuntimePredicateKind.storyFlagSet,
                    refId: 'legacy.flag',
                  ),
                  dialogue: DialogueRef(dialogueId: 'dialogue.conditional'),
                ),
              ],
            ),
          ),
        ],
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'object',
            layerId: 'objects',
            elementId: 'object',
            pos: GridPos(x: 1, y: 1),
            behaviors: <MapPlacedElementBehavior>[
              MapPlacedElementBehavior(
                effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.openDialogue,
                  dialogue: DialogueRef(dialogueId: 'dialogue.object'),
                ),
              ),
            ],
          ),
        ],
      );
      final project = _project(
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'dialogue.default',
            name: 'Default',
            relativePath: 'default.yarn',
          ),
          ProjectDialogueEntry(
            id: 'dialogue.conditional',
            name: 'Conditional',
            relativePath: 'conditional.yarn',
          ),
          ProjectDialogueEntry(
            id: 'dialogue.object',
            name: 'Object',
            relativePath: 'object.yarn',
          ),
        ],
      );
      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[map],
      );

      expect(collectDialogueIdsReferencedOnMap(map), {'dialogue.default'});
      expect(
        collectDialogueIdsReferencedOnMap(map, dependencyIndex: index),
        {'dialogue.default', 'dialogue.conditional', 'dialogue.object'},
      );
    });

    test('Storyline links retain the canonical missing resolution', () {
      final project = _project(
        storylines: <StorylineAsset>[
          StorylineAsset(
            id: 'story.links',
            type: StorylineType.main,
            title: 'Links',
            chapters: <StorylineChapter>[
              StorylineChapter(
                id: 'chapter.links',
                title: 'Links',
                order: 0,
                steps: <StorylineStep>[
                  StorylineStep(
                    id: 'step.links',
                    title: 'Links',
                    order: 0,
                    sceneLinkIds: const <String>['scene.missing'],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final storyline = project.storylines.single;
      final chapter = storyline.chapters.single;
      final index = buildNarrativeDependencyIndex(project: project);

      final model = buildStorylineStepSceneLinksReadModel(
        project: project,
        storyline: storyline,
        chapter: chapter,
        step: chapter.steps.single,
        dependencyIndex: index,
      );

      expect(model.linkedScenes.single.exists, isFalse);
      expect(
        model.linkedScenes.single.referenceResolution,
        NarrativeDependencyResolution.missing,
      );
    });

    test('Facts manager sees New Game and Event V2 consumers', () {
      final project = _project(
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(id: 'fact.shared', label: 'Shared'),
        ],
        scenes: <SceneAsset>[_emptyScene('scene.event')],
        newGame: const ProjectNewGameConfig(
          enabled: true,
          initialFacts: <String, bool>{'fact.shared': true},
        ),
        eventRegistry: _registry(<NarrativeEventDefinition>[
          _event(
            id: _eventA,
            sceneId: 'scene.event',
            source: NarrativeEventSourceRef.mapEnter('map.loaded'),
            conditions: <NarrativeEventCondition>[
              NarrativeEventCondition.fact('fact.shared', true),
            ],
          ),
        ]),
      );
      final maps = <MapData>[_emptyMap('map.loaded')];
      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: maps,
      );

      final model = buildFactsWorldRulesManagerReadModel(
        project,
        maps: maps,
        dependencyIndex: index,
      );

      expect(
        model.facts.single.usages.map((usage) => usage.kind),
        containsAll(<FactManagerUsageKind>[
          FactManagerUsageKind.newGame,
          FactManagerUsageKind.eventV2,
        ]),
      );
      expect(
        model.facts.single.usages.every(
          (usage) =>
              usage.referenceResolution ==
              NarrativeDependencyResolution.resolved,
        ),
        isTrue,
      );
    });

    test('Cinematics library retains a broken reference resolution', () {
      final project = _project(
        scenes: <SceneAsset>[
          _sceneWithCinematic('scene.cinematic', 'cine.missing'),
        ],
      );
      final index = buildNarrativeDependencyIndex(project: project);

      final model = buildCinematicsLibraryReadModel(
        project,
        dependencyIndex: index,
      );

      expect(model.unknownUsages, hasLength(1));
      expect(
        model.unknownUsages.single.referenceResolution,
        NarrativeDependencyResolution.missing,
      );
    });

    test('Event builder receives canonical dependency diagnostics', () {
      final project = _project(
        scenes: <SceneAsset>[_emptyScene('scene.event')],
        eventRegistry: _registry(<NarrativeEventDefinition>[
          _event(
            id: _eventA,
            sceneId: 'scene.event',
            source: NarrativeEventSourceRef.mapEnter('map.loaded'),
            conditions: <NarrativeEventCondition>[
              NarrativeEventCondition.narrativeEventConsumed(_eventB, true),
            ],
          ),
          _event(
            id: _eventB,
            sceneId: 'scene.event',
            source: NarrativeEventSourceRef.mapEnter('map.loaded'),
            conditions: <NarrativeEventCondition>[
              NarrativeEventCondition.narrativeEventConsumed(_eventA, true),
            ],
          ),
        ]),
      );
      final maps = <MapData>[_emptyMap('map.loaded')];
      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: maps,
      );

      final model = buildNarrativeEventBuilderProjectReadModel(
        project: project,
        maps: maps,
        dependencyIndex: index,
      );

      expect(
        model.events
            .where((event) => event.origin == NarrativeEventProjectOrigin.v2)
            .every(
              (event) => event.diagnostics.any(
                (diagnostic) =>
                    diagnostic.code == 'canonicalDependency.forbiddenCycle',
              ),
            ),
        isTrue,
      );
    });
  });
}

ProjectManifest _project({
  List<ProjectMapEntry> maps = const <ProjectMapEntry>[],
  List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
  List<NarrativeFactDefinition> facts = const <NarrativeFactDefinition>[],
  List<SceneAsset> scenes = const <SceneAsset>[],
  List<StorylineAsset> storylines = const <StorylineAsset>[],
  List<CinematicAsset> cinematics = const <CinematicAsset>[],
  List<WorldRuleDefinition> worldRules = const <WorldRuleDefinition>[],
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  NarrativeEventRegistry? eventRegistry,
  ProjectNewGameConfig newGame = const ProjectNewGameConfig(),
}) {
  return ProjectManifest(
    name: 'Dependency index test',
    maps: maps,
    tilesets: const [],
    dialogues: dialogues,
    facts: facts,
    scenes: scenes,
    storylines: storylines,
    cinematics: cinematics,
    worldRules: worldRules,
    scenarios: scenarios,
    eventRegistry: eventRegistry,
    newGame: newGame,
  );
}

const _eventA = 'evt_00000000-0000-7000-8000-000000000001';
const _eventB = 'evt_00000000-0000-7000-8000-000000000002';

const _newGameOwner = NarrativeDependencyKey.projectNewGame();

NarrativeEventDefinition _event({
  required String id,
  required String sceneId,
  required NarrativeEventSourceRef source,
  List<NarrativeEventCondition> conditions = const <NarrativeEventCondition>[],
}) {
  return NarrativeEventDefinition(
    id: id,
    name: 'Event $id',
    source: source,
    conditions: conditions,
    sceneId: sceneId,
    reusePolicy: NarrativeEventReusePolicy.oneShot,
    priority: 0,
    order: 0,
  );
}

NarrativeEventRegistry _registry(
  List<NarrativeEventDefinition> events, {
  List<LegacySourceClaim> legacyClaims = const <LegacySourceClaim>[],
}) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      for (final event in events)
        NarrativeEventRecord.configuredStructurallyUnchecked(
          event,
          enabled: true,
        ),
    ],
    legacyClaims: legacyClaims,
  );
}

LegacySourceClaim _legacyClaim({required List<String> targetEventIds}) {
  return LegacySourceClaim(
    cohortId:
        'lsc_65e30267a6ef9fe6e351b4a3789377d563a35b7b8e3ccb47f7bc34f3499dcda3',
    source: NarrativeEventSourceRef.mapEnter('map_port'),
    members: <LegacySourceClaimMember>[
      LegacySourceClaimMember(
        provenance: LegacySourceRef.mapEvent('map_port', 'lysa'),
        sourceFingerprint:
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      ),
      LegacySourceClaimMember(
        provenance: LegacySourceRef.scenarioSourceNode(
          'scenario_arrival',
          'source',
        ),
        sourceFingerprint:
            'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      ),
    ],
    cohortFingerprint:
        'sha256:f24177958517d13922af29bc3e8a8b18cee0e4649ad6323144f61b45bb5fdb2f',
    targetEventIds: targetEventIds,
    migrationReceiptId: 'evmr_test',
  );
}

SceneAsset _emptyScene(String id) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
      ],
    ),
  );
}

SceneAsset _sceneWithCinematic(String id, String cinematicId) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'cinematic',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: cinematicId),
        ),
      ],
    ),
  );
}

MapData _emptyMap(String id) {
  return MapData(
    id: id,
    name: id,
    size: const GridSize(width: 1, height: 1),
  );
}

String _largeEventId(int index) {
  return 'evt_00000000-0000-7000-8000-${index.toString().padLeft(12, '0')}';
}

StorylineAsset _storyline() {
  return StorylineAsset(
    id: 'story.main',
    type: StorylineType.main,
    title: 'Main',
    chapters: <StorylineChapter>[
      StorylineChapter(
        id: 'chapter.intro',
        title: 'Intro',
        order: 0,
        steps: <StorylineStep>[
          StorylineStep(id: 'step.intro', title: 'Intro', order: 0),
        ],
      ),
    ],
  );
}

WorldRuleDefinition _worldRule() {
  return WorldRuleDefinition(
    id: 'rule.story',
    label: 'Story rule',
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact.story',
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.npcDialogue,
      mapId: 'map.port',
      entityId: 'npc.rival',
    ),
    effect: const WorldRuleEffect(
      kind: WorldRuleEffectKind.npcDialogueOverride,
      dialogueId: 'dialogue.rival',
    ),
  );
}
````

## Annexe C — diff des fichiers modifiés

Les espaces de contexte Git sur les lignes entièrement vides sont normalisés
comme annoncé dans la section « Zones précises modifiées ».

````diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index cfd5906b..79a03bc4 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -136,6 +136,7 @@ export 'src/authoring/narrative_validator_authoring_adapter.dart';
 export 'src/authoring/cinematic_authoring_operations.dart';
 export 'src/authoring/storyline_legacy_import_preview.dart';
 export 'src/read_models/narrative_reference_picker_read_models.dart';
+export 'src/read_models/narrative_dependency_index.dart';
 export 'src/read_models/narrative_event_source_index.dart';
 export 'src/read_models/narrative_event_validation_read_model.dart';
 export 'src/read_models/narrative_event_reachability_report.dart';
diff --git a/packages/map_core/lib/src/operations/project_dialogue_refs.dart b/packages/map_core/lib/src/operations/project_dialogue_refs.dart
index f14c370c..5a0ea71e 100644
--- a/packages/map_core/lib/src/operations/project_dialogue_refs.dart
+++ b/packages/map_core/lib/src/operations/project_dialogue_refs.dart
@@ -1,9 +1,34 @@
 import '../models/map_data.dart';
 import '../models/enums.dart';
-import '../models/map_entity_payloads.dart';
+import '../read_models/narrative_dependency_index.dart';

-/// Collecte les [DialogueRef.dialogueId] non vides utilisés sur une carte (NPC + panneaux).
-Set<String> collectDialogueIdsReferencedOnMap(MapData map) {
+/// Collecte les identifiants de dialogue référencés directement par les
+/// données de [map]. Les identifiants vides sont ignorés et les doublons
+/// éliminés.
+///
+/// Sans [dependencyIndex], conserve le scan historique borné aux dialogues
+/// principaux des PNJ et des panneaux.
+///
+/// Avec [dependencyIndex], l'index est la source de vérité et doit avoir été
+/// construit avec la version courante de [map]. Sont alors inclus les
+/// dialogues principaux, de défaite et conditionnels des PNJ, les panneaux et
+/// les effets de dialogue des éléments placés. Aucun fallback ni fusion avec
+/// le scan historique n'est effectué.
+///
+/// Les références appartenant à un autre asset, même s'il cible cette carte,
+/// ne sont pas incluses.
+Set<String> collectDialogueIdsReferencedOnMap(
+  MapData map, {
+  NarrativeDependencyIndex? dependencyIndex,
+}) {
+  if (dependencyIndex != null) {
+    return <String>{
+      for (final usage in dependencyIndex.usages)
+        if (usage.target.kind == NarrativeDependencyTargetKind.dialogue &&
+            usage.owner.physicalMapId == map.id)
+          usage.target.id,
+    };
+  }
   final ids = <String>{};
   for (final e in map.entities) {
     switch (e.kind) {
@@ -23,10 +48,18 @@ Set<String> collectDialogueIdsReferencedOnMap(MapData map) {
 }

 /// Fusionne les références de plusieurs cartes.
-Set<String> collectDialogueIdsReferencedOnMaps(Iterable<MapData> maps) {
+Set<String> collectDialogueIdsReferencedOnMaps(
+  Iterable<MapData> maps, {
+  NarrativeDependencyIndex? dependencyIndex,
+}) {
   final all = <String>{};
   for (final m in maps) {
-    all.addAll(collectDialogueIdsReferencedOnMap(m));
+    all.addAll(
+      collectDialogueIdsReferencedOnMap(
+        m,
+        dependencyIndex: dependencyIndex,
+      ),
+    );
   }
   return all;
 }
diff --git a/packages/map_core/lib/src/read_models/cinematics_library_read_model.dart b/packages/map_core/lib/src/read_models/cinematics_library_read_model.dart
index 7dce47c0..66599e9a 100644
--- a/packages/map_core/lib/src/read_models/cinematics_library_read_model.dart
+++ b/packages/map_core/lib/src/read_models/cinematics_library_read_model.dart
@@ -5,6 +5,7 @@ import '../models/cinematic_asset.dart';
 import '../models/project_manifest.dart';
 import '../models/scene_asset.dart';
 import 'linked_asset_public_contracts.dart';
+import 'narrative_dependency_index.dart';

 enum CinematicsLibraryEntryKind {
   canonical,
@@ -156,6 +157,7 @@ final class CinematicsLibraryUsage {
     required this.nodeId,
     required this.nodeTitle,
     required this.referenceStatus,
+    this.referenceResolution = NarrativeDependencyResolution.resolved,
   });

   final String cinematicId;
@@ -164,6 +166,7 @@ final class CinematicsLibraryUsage {
   final String nodeId;
   final String nodeTitle;
   final CinematicsLibraryReferenceStatus referenceStatus;
+  final NarrativeDependencyResolution referenceResolution;
 }

 @immutable
@@ -201,8 +204,9 @@ final class CinematicsLibraryMetrics {
 }

 CinematicsLibraryReadModel buildCinematicsLibraryReadModel(
-  ProjectManifest project,
-) {
+  ProjectManifest project, {
+  NarrativeDependencyIndex? dependencyIndex,
+}) {
   final contracts = buildCinematicPublicContracts(project);
   final bridgeContracts = {
     for (final contract in contracts)
@@ -217,6 +221,7 @@ CinematicsLibraryReadModel buildCinematicsLibraryReadModel(
     project.scenes,
     canonicalIds: canonicalIds,
     bridgeIds: bridgeIds,
+    dependencyIndex: dependencyIndex,
   );
   final diagnosticsByCinematicId = _groupCinematicDiagnostics(
     diagnoseCinematicsAgainstProject(project).diagnostics,
@@ -330,6 +335,7 @@ Map<String, List<CinematicsLibraryUsage>> _collectSceneUsages(
   List<SceneAsset> scenes, {
   required Set<String> canonicalIds,
   required Set<String> bridgeIds,
+  NarrativeDependencyIndex? dependencyIndex,
 }) {
   final usages = <String, List<CinematicsLibraryUsage>>{};
   for (final scene in scenes) {
@@ -339,17 +345,36 @@ Map<String, List<CinematicsLibraryUsage>> _collectSceneUsages(
         continue;
       }
       final cinematicId = payload.cinematicId;
+      final referenceStatus = _referenceStatusFor(
+        cinematicId,
+        canonicalIds: canonicalIds,
+        bridgeIds: bridgeIds,
+      );
+      final indexedUsages = dependencyIndex?.usagesFor(
+        NarrativeDependencyKey(
+          NarrativeDependencyTargetKind.cinematic,
+          cinematicId,
+        ),
+      );
+      final indexedSceneUsage = indexedUsages
+          ?.where(
+            (usage) => usage.owner == NarrativeDependencyKey.scene(scene.id),
+          )
+          .firstOrNull;
       final usage = CinematicsLibraryUsage(
         cinematicId: cinematicId,
         sceneId: scene.id,
         sceneTitle: scene.name,
         nodeId: node.id,
         nodeTitle: node.title ?? node.id,
-        referenceStatus: _referenceStatusFor(
-          cinematicId,
-          canonicalIds: canonicalIds,
-          bridgeIds: bridgeIds,
-        ),
+        referenceStatus: referenceStatus,
+        referenceResolution: referenceStatus ==
+                CinematicsLibraryReferenceStatus.bridgeLegacy
+            ? NarrativeDependencyResolution.legacyExternal
+            : indexedSceneUsage?.resolution ??
+                (referenceStatus == CinematicsLibraryReferenceStatus.canonical
+                    ? NarrativeDependencyResolution.resolved
+                    : NarrativeDependencyResolution.missing),
       );
       usages.putIfAbsent(cinematicId, () => []).add(usage);
     }
diff --git a/packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart b/packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart
index 745f4330..d5706e39 100644
--- a/packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart
+++ b/packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart
@@ -8,11 +8,16 @@ import '../models/scene_asset.dart';
 import '../models/scene_consequence.dart';
 import '../models/storyline_asset.dart';
 import '../models/world_rule.dart';
+import 'narrative_dependency_index.dart';

 enum FactManagerUsageKind {
   sceneCondition,
   sceneConsequence,
   worldRuleSource,
+  newGame,
+  eventV2,
+  storylineEffect,
+  legacySource,
 }

 final class FactsWorldRulesManagerReadModel {
@@ -86,6 +91,9 @@ final class FactManagerUsage {
     required this.ownerId,
     required this.ownerLabel,
     required this.details,
+    this.referenceResolution = NarrativeDependencyResolution.resolved,
+    this.dependencyPath,
+    this.dependencyOwner,
   });

   final FactManagerUsageKind kind;
@@ -93,6 +101,9 @@ final class FactManagerUsage {
   final String ownerId;
   final String ownerLabel;
   final String details;
+  final NarrativeDependencyResolution referenceResolution;
+  final String? dependencyPath;
+  final NarrativeDependencyKey? dependencyOwner;
 }

 final class WorldRuleManagerEntry {
@@ -182,11 +193,15 @@ final class WorldRuleDialoguePickerOption {
 FactsWorldRulesManagerReadModel buildFactsWorldRulesManagerReadModel(
   ProjectManifest project, {
   List<MapData> maps = const <MapData>[],
+  NarrativeDependencyIndex? dependencyIndex,
 }) {
   final usagesByFactId = <String, List<FactManagerUsage>>{
     for (final fact in project.facts) fact.id: <FactManagerUsage>[],
   };
-  for (final usage in _collectFactUsages(project)) {
+  final factUsages = dependencyIndex == null
+      ? _collectFactUsages(project)
+      : _collectFactUsagesFromDependencyIndex(dependencyIndex);
+  for (final usage in factUsages) {
     usagesByFactId.putIfAbsent(usage.factId, () => <FactManagerUsage>[]);
     usagesByFactId[usage.factId]!.add(usage);
   }
@@ -228,6 +243,58 @@ FactsWorldRulesManagerReadModel buildFactsWorldRulesManagerReadModel(
   );
 }

+Iterable<FactManagerUsage> _collectFactUsagesFromDependencyIndex(
+  NarrativeDependencyIndex index,
+) sync* {
+  for (final usage in index.usages) {
+    if (usage.target.kind != NarrativeDependencyTargetKind.fact) continue;
+    yield FactManagerUsage(
+      kind: _factManagerKindForDependency(usage),
+      factId: usage.target.id,
+      ownerId: usage.owner.id,
+      ownerLabel: _dependencyOwnerLabel(index, usage.owner),
+      details: usage.path,
+      referenceResolution: usage.resolution,
+      dependencyPath: usage.path,
+      dependencyOwner: usage.owner,
+    );
+  }
+}
+
+FactManagerUsageKind _factManagerKindForDependency(
+  NarrativeDependencyUsage usage,
+) {
+  switch (usage.owner.kind) {
+    case NarrativeDependencyTargetKind.scene:
+      return usage.path.contains('.consequence.')
+          ? FactManagerUsageKind.sceneConsequence
+          : FactManagerUsageKind.sceneCondition;
+    case NarrativeDependencyTargetKind.worldRule:
+      return FactManagerUsageKind.worldRuleSource;
+    case NarrativeDependencyTargetKind.eventV2:
+      return FactManagerUsageKind.eventV2;
+    case NarrativeDependencyTargetKind.storyline:
+      return FactManagerUsageKind.storylineEffect;
+    case NarrativeDependencyTargetKind.sourceMap:
+      return usage.owner == const NarrativeDependencyKey.projectNewGame()
+          ? FactManagerUsageKind.newGame
+          : FactManagerUsageKind.legacySource;
+    default:
+      return FactManagerUsageKind.legacySource;
+  }
+}
+
+String _dependencyOwnerLabel(
+  NarrativeDependencyIndex index,
+  NarrativeDependencyKey owner,
+) {
+  if (owner == const NarrativeDependencyKey.projectNewGame()) {
+    return 'New Game';
+  }
+  final definitions = index.definitionsFor(owner);
+  return definitions.length == 1 ? definitions.single.label : owner.id;
+}
+
 Iterable<FactManagerUsage> _collectFactUsages(ProjectManifest project) sync* {
   for (final scene in project.scenes) {
     for (final node in scene.graph.nodes) {
diff --git a/packages/map_core/lib/src/read_models/narrative_event_builder_project_read_model.dart b/packages/map_core/lib/src/read_models/narrative_event_builder_project_read_model.dart
index 3a2618dd..268516bf 100644
--- a/packages/map_core/lib/src/read_models/narrative_event_builder_project_read_model.dart
+++ b/packages/map_core/lib/src/read_models/narrative_event_builder_project_read_model.dart
@@ -19,6 +19,7 @@ import '../operations/build_narrative_event_project_catalog.dart';
 import '../operations/narrative_event_canonical_json.dart';
 import '../operations/narrative_event_registry_codec.dart';
 import 'narrative_event_read_deduplication.dart';
+import 'narrative_dependency_index.dart';

 enum NarrativeEventProjectStatus {
   draftIncomplete,
@@ -524,6 +525,7 @@ NarrativeEventBuilderProjectReadModel
     buildNarrativeEventBuilderProjectReadModel({
   required ProjectManifest project,
   required List<MapData> maps,
+  NarrativeDependencyIndex? dependencyIndex,
 }) {
   final registry = project.eventRegistry ??
       NarrativeEventRegistry(
@@ -561,6 +563,7 @@ NarrativeEventBuilderProjectReadModel
   final indexes = _ProjectReadIndexes(
     project: project,
     catalog: catalog,
+    dependencyIndex: dependencyIndex,
   );
   final legacyInputs = <_LegacyProjectionInput>[
     for (final projection in legacyMapEvents)
@@ -1191,6 +1194,7 @@ final class _ProjectReadIndexes {
   _ProjectReadIndexes({
     required this.project,
     required this.catalog,
+    this.dependencyIndex,
   })  : mapLabelsById = {
           for (final map in project.maps)
             map.id: _display(map.name, fallback: map.id),
@@ -1232,6 +1236,7 @@ final class _ProjectReadIndexes {

   final ProjectManifest project;
   final NarrativeEventProjectCatalog catalog;
+  final NarrativeDependencyIndex? dependencyIndex;
   final Map<String, String> mapLabelsById;
   final Map<String, ScenarioAsset> scenariosById;
   final Map<NarrativeEventSourceRef, List<NarrativeSpatialEventSourceOption>>
@@ -1395,8 +1400,28 @@ final class _ProjectReadIndexes {

   List<NarrativeEventProjectReadDiagnostic> diagnosticsForEvent(
     String eventId,
-  ) =>
-      _diagnosticsByEventId[eventId] ?? const [];
+  ) {
+    final eventKey = NarrativeDependencyKey.eventV2(eventId);
+    final diagnostics = <NarrativeEventProjectReadDiagnostic>[
+      ..._diagnosticsByEventId[eventId] ?? const [],
+      for (final issue
+          in dependencyIndex?.issues ?? const <NarrativeDependencyIssue>[])
+        if (issue.owner == eventKey || issue.target == eventKey)
+          NarrativeEventProjectReadDiagnostic(
+            code: 'canonicalDependency.${issue.kind.name}',
+            severity: switch (issue.criticality) {
+              NarrativeDependencyCriticality.informational =>
+                NarrativeEventProjectSummarySeverity.info,
+              NarrativeDependencyCriticality.authoringWarning =>
+                NarrativeEventProjectSummarySeverity.warning,
+              NarrativeDependencyCriticality.runtimeBlocking =>
+                NarrativeEventProjectSummarySeverity.error,
+            },
+            message: issue.message,
+          ),
+    ];
+    return _deduplicateDiagnostics(diagnostics);
+  }

   NarrativeEventProjectionSummary projectionSummary(String? sceneId) {
     return _projectionsBySceneId[sceneId] ??
diff --git a/packages/map_core/lib/src/read_models/storyline_scene_links_read_model.dart b/packages/map_core/lib/src/read_models/storyline_scene_links_read_model.dart
index 6bf5db7c..1f17cd28 100644
--- a/packages/map_core/lib/src/read_models/storyline_scene_links_read_model.dart
+++ b/packages/map_core/lib/src/read_models/storyline_scene_links_read_model.dart
@@ -3,6 +3,7 @@ import '../diagnostics/storyline_scene_link_diagnostics.dart';
 import '../models/project_manifest.dart';
 import '../models/storyline_asset.dart';
 import '../runtime/scene_runtime_plan_builder.dart';
+import 'narrative_dependency_index.dart';

 final class StorylineStepSceneLinksReadModel {
   StorylineStepSceneLinksReadModel({
@@ -44,6 +45,7 @@ final class StorylineStepSceneLinkView {
     required this.hasSceneErrors,
     required this.isRuntimeBuildable,
     required this.diagnostics,
+    this.referenceResolution = NarrativeDependencyResolution.resolved,
   });

   final String sceneId;
@@ -52,6 +54,7 @@ final class StorylineStepSceneLinkView {
   final bool hasSceneErrors;
   final bool isRuntimeBuildable;
   final List<StorylineSceneLinkDiagnostic> diagnostics;
+  final NarrativeDependencyResolution referenceResolution;
 }

 final class StorylineStepScenePickerOption {
@@ -73,6 +76,7 @@ StorylineStepSceneLinksReadModel buildStorylineStepSceneLinksReadModel({
   required StorylineAsset storyline,
   required StorylineChapter chapter,
   required StorylineStep step,
+  NarrativeDependencyIndex? dependencyIndex,
 }) {
   final sceneById = {
     for (final scene in project.scenes) scene.id: scene,
@@ -88,18 +92,35 @@ StorylineStepSceneLinksReadModel buildStorylineStepSceneLinksReadModel({
   final linkedScenes = [
     for (final sceneId in step.sceneLinkIds)
       () {
-        final scene = sceneById[sceneId];
+        final dependencyDefinitions = dependencyIndex?.definitionsFor(
+          NarrativeDependencyKey.scene(sceneId),
+        );
+        final isAmbiguousReference =
+            dependencyDefinitions != null && dependencyDefinitions.length > 1;
+        final scene = isAmbiguousReference ? null : sceneById[sceneId];
         final sceneDiagnostics = scene == null ? null : diagnoseScene(scene);
         final planResult = scene == null ? null : buildSceneRuntimePlan(scene);
+        final referenceResolution = dependencyDefinitions == null
+            ? scene == null
+                ? NarrativeDependencyResolution.missing
+                : NarrativeDependencyResolution.resolved
+            : dependencyDefinitions.isEmpty
+                ? NarrativeDependencyResolution.missing
+                : dependencyDefinitions.length == 1
+                    ? NarrativeDependencyResolution.resolved
+                    : NarrativeDependencyResolution.ambiguous;
         return StorylineStepSceneLinkView(
           sceneId: sceneId,
-          label: scene?.name ?? 'Scene introuvable',
-          exists: scene != null,
+          label: isAmbiguousReference
+              ? 'Scene ambiguë ($sceneId)'
+              : scene?.name ?? 'Scene introuvable',
+          exists: isAmbiguousReference || scene != null,
           hasSceneErrors: sceneDiagnostics?.hasErrors ?? false,
           isRuntimeBuildable: planResult?.canBuild ?? false,
           diagnostics: List<StorylineSceneLinkDiagnostic>.unmodifiable(
             diagnostics.where((diagnostic) => diagnostic.sceneId == sceneId),
           ),
+          referenceResolution: referenceResolution,
         );
       }(),
   ];
diff --git a/packages/map_core/test/storyline_scene_links_read_model_test.dart b/packages/map_core/test/storyline_scene_links_read_model_test.dart
index 50798def..665f258c 100644
--- a/packages/map_core/test/storyline_scene_links_read_model_test.dart
+++ b/packages/map_core/test/storyline_scene_links_read_model_test.dart
@@ -47,18 +47,87 @@ void main() {
       expect(model.diagnostics.single.code,
           StorylineSceneLinkDiagnosticCode.storylineStepUnknownSceneLink);
     });
+
+    test('keeps the legacy last-match fallback without a dependency index', () {
+      final project = _project(
+        sceneLinkIds: const ['scene_intro'],
+        scenes: [
+          _scene('scene_intro', 'First Scene'),
+          _invalidScene('scene_intro', 'Legacy Last Scene'),
+        ],
+      );
+      final storyline = project.storylines.single;
+      final chapter = storyline.chapters.single;
+
+      final model = buildStorylineStepSceneLinksReadModel(
+        project: project,
+        storyline: storyline,
+        chapter: chapter,
+        step: chapter.steps.single,
+      );
+
+      expect(model.linkedScenes.single.label, 'Legacy Last Scene');
+      expect(model.linkedScenes.single.exists, isTrue);
+      expect(model.linkedScenes.single.hasSceneErrors, isTrue);
+      expect(model.linkedScenes.single.isRuntimeBuildable, isFalse);
+      expect(
+        model.linkedScenes.single.referenceResolution,
+        NarrativeDependencyResolution.resolved,
+      );
+    });
+
+    test(
+        'exposes duplicate Scene ids as ambiguous without arbitrary details when indexed',
+        () {
+      StorylineStepSceneLinkView buildLink(List<SceneAsset> scenes) {
+        final project = _project(
+          sceneLinkIds: const ['scene_intro'],
+          scenes: scenes,
+        );
+        final storyline = project.storylines.single;
+        final chapter = storyline.chapters.single;
+
+        return buildStorylineStepSceneLinksReadModel(
+          project: project,
+          storyline: storyline,
+          chapter: chapter,
+          step: chapter.steps.single,
+          dependencyIndex: buildNarrativeDependencyIndex(project: project),
+        ).linkedScenes.single;
+      }
+
+      final valid = _scene('scene_intro', 'Valid Scene');
+      final invalid = _invalidScene('scene_intro', 'Invalid Scene');
+      final validThenInvalid = buildLink([valid, invalid]);
+      final invalidThenValid = buildLink([invalid, valid]);
+
+      for (final link in [validThenInvalid, invalidThenValid]) {
+        expect(link.label, 'Scene ambiguë (scene_intro)');
+        expect(link.exists, isTrue);
+        expect(link.hasSceneErrors, isFalse);
+        expect(link.isRuntimeBuildable, isFalse);
+        expect(
+          link.referenceResolution,
+          NarrativeDependencyResolution.ambiguous,
+        );
+      }
+    });
   });
 }

-ProjectManifest _project({required List<String> sceneLinkIds}) {
+ProjectManifest _project({
+  required List<String> sceneLinkIds,
+  List<SceneAsset>? scenes,
+}) {
   return ProjectManifest(
     name: 'Story Project',
     maps: const <ProjectMapEntry>[],
     tilesets: const <ProjectTilesetEntry>[],
-    scenes: [
-      _scene('scene_intro', 'Intro Scene'),
-      _scene('scene_resolution', 'Resolution Scene')
-    ],
+    scenes: scenes ??
+        [
+          _scene('scene_intro', 'Intro Scene'),
+          _scene('scene_resolution', 'Resolution Scene')
+        ],
     storylines: [
       StorylineAsset(
         id: 'story_main',
@@ -106,3 +175,16 @@ SceneAsset _scene(String id, String name) {
     ),
   );
 }
+
+SceneAsset _invalidScene(String id, String name) {
+  return SceneAsset(
+    id: id,
+    name: name,
+    graph: SceneGraph(
+      startNodeId: 'node_start',
+      nodes: [
+        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
+      ],
+    ),
+  );
+}
````
