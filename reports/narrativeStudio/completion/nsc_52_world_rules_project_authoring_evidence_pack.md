# NSC-52 — World Rules projet et authoring complet — Evidence Pack

## Résumé exécutif

NSC-52 rend les World Rules réellement project-wide dans l'éditeur : toutes les maps du manifeste sont chargées, la map active dirty gagne sur le disque et une erreur de snapshot bloque honnêtement l'édition. Les règles restent reconfigurables après création via des pickers no-code de source, prédicat, comparaison typée, cible, effet et dialogue. `mapEvent` legacy et `narrativeEvent` V2 ont désormais des namespaces, labels, diagnostics et dépendances distincts. Les effets V2 enabled/disabled/hidden sont appliqués par l'autorité de dispatch runtime et survivent au save/load.

**Verdict proposé : DONE.**

## Scope et audit initial

- État Git initial : branche `main`, HEAD `b984fc718 feat(narrative): add typed facts v2 runtime`, arbre propre après NSC-51.
- Contrats inspectés : `WorldRuleDefinition`, authoring/diagnostics/projection, `NarrativeDependencyIndex`, autorité Event V2, hook runtime, workspace Facts/World Rules et chargement des maps.
- Risques identifiés : données limitées à la map active, écrasement de la map dirty par le disque, confusion Map Event/Event V2, règle visible dans l'éditeur mais sans effet sur le dispatch, priorité égale ambiguë, cible disparue, type Fact incompatible et édition post-création incomplète.
- Non-objectifs : aucune migration automatique des sources `consumedEvent` legacy vers la progression Event V2 ; aucun retrait du format `mapEvent` historique.

## Passes locales équivalentes aux sub-agents

Les sub-agents sont interdits par le mode de collaboration actif ; les passes imposées par `codex_rule.md` ont donc été réalisées localement, séparément et avec leurs propres verdicts.

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — le snapshot reste dans map_editor, les modèles/projections purs dans map_core et le raccord runtime dans map_runtime. |
| Implémentation | PASS — les pickers et callbacks utilisent le snapshot complet ; aucune saisie d'ID n'a été ajoutée. |
| Tests | PASS — 100 tests core, 5 gameplay, 37 runtime et 8 editor pertinents sont verts. |
| Build / Validation | PASS avec réserve connue — core/gameplay/runtime sans issue ; editor conserve 11 warnings préexistants dans Dialogue Studio. |
| Critique finale | PASS — le churn de formatage hors scope a été retiré, le golden intentionnel a été inspecté et les namespaces legacy/V2 sont explicites. |

## Inventaire complet des fichiers modifiés

| Fichier | Zone précise et impact |
|---|---|
| `packages/map_core/lib/src/models/world_rule.dart` | Ajout du target `narrativeEvent` distinct et compatibilité des trois effets Event. |
| `packages/map_core/lib/src/authoring/world_rule_authoring_operations.dart` | Validation projet-wide des sources/cibles, authoring cross-map et résolution Event V2 dans le registry. |
| `packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart` | Cibles V2 absentes, type Fact, conflits/priorités et identité de cible distincte. |
| `packages/map_core/lib/src/operations/narrative_event_dispatch_authority.dart` | Projection World Rules avant sélection, activation d'un record désactivé, blocage disabled/hidden et raisons de simulation. |
| `packages/map_core/lib/src/read_models/event_builder_read_model.dart` | Switch exhaustif pour la nouvelle cible V2. |
| `packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart` | Pickers projet-wide, prédicats positifs/négatifs et labels sans ambiguïté legacy/V2. |
| `packages/map_core/lib/src/read_models/narrative_dependency_index.dart` | Dépendances `mapEvent` legacy et `eventV2` séparées. |
| `packages/map_core/lib/src/read_models/narrative_event_validation_read_model.dart` | Raisons `worldRuleDisabled` et `worldRuleHidden`. |
| `packages/map_core/lib/src/read_models/narrative_map_events_read_model.dart` | Disponibilité des targets V2 distincte des Map Events. |
| `packages/map_core/lib/src/read_models/world_rule_target_context_read_model.dart` | Contexte et libellé V2 exhaustifs. |
| `packages/map_core/test/facts_world_rules_manager_read_model_test.dart` | Maps inactives et labels/targets legacy/V2. |
| `packages/map_core/test/narrative_dependency_index_test.dart` | Collision d'ID prouvant la séparation des deux namespaces. |
| `packages/map_core/test/narrative_event_dispatch_authority_test.dart` | Dispatch disabled, hidden et réactivation par priorité supérieure. |
| `packages/map_core/test/world_rule_authoring_operations_test.dart` | Authoring Event V2 et cible sur map inactive. |
| `packages/map_core/test/world_rule_diagnostics_test.dart` | Target V2 absent et comparaison Fact de type incompatible. |
| `packages/map_core/test/world_rule_test.dart` | Round-trip et distinction structurelle `mapEvent`/`narrativeEvent`. |
| `packages/map_editor/lib/src/application/services/narrative_project_snapshot_loader.dart` | Nouveau snapshot immuable multi-map, priorité dirty et garde-fous de chemin/identité. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_simulation_sheet.dart` | Libellés des blocages World Rule dans la simulation Event. |
| `packages/map_editor/lib/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart` | Consommation de toutes les maps et édition complète source/prédicat/cible/effet/dialogue. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | Chargement du snapshot, branchement des opérations avec toutes les maps et erreur fail-closed. |
| `packages/map_editor/test/facts_world_rules_manager_test.dart` | Test widget de reconfiguration complète après création. |
| `packages/map_editor/test/narrative_project_snapshot_loader_test.dart` | Map inactive disque, map active dirty prioritaire et path traversal refusé. |
| `packages/map_runtime/lib/src/application/world_rules/runtime_world_rule_projection_hook.dart` | États Event V2 séparés et API `canDispatchNarrativeEvent`. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Injection du projet et du snapshot maps dans l'autorité de dispatch réelle. |
| `packages/map_runtime/test/world_rules_runtime_projection_hook_test.dart` | Séparation legacy/V2 et masquage V2 conservé après save/load. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.png` | Golden actualisé et inspecté pour la nouvelle carte Configuration. |
| `docs/superpowers/plans/2026-07-20-nsc-52-world-rules-project-wide.md` | Micro-plan TDD et gate du lot. |

## Découpage précis des modifications

- Snapshot : lecture de chaque `ProjectMapEntry`, validation du chemin sous la racine, validation de l'ID chargé, fusion de la map active dirty et ajout temporaire d'une nouvelle map non encore manifestée.
- Authoring : les mêmes pickers no-code servent à la création et à l'édition ; une règle existante peut changer de source, prédicat, opérateur/valeur typée, target, effet et dialogue.
- Namespaces : `mapEvent` ne résout que `MapData.events`; `narrativeEvent` ne résout que `eventRegistry.records`; les labels UI, diagnostics et clés de dépendance ne disent plus seulement « Event ».
- Runtime : l'autorité prend les candidats configurés même désactivés afin qu'une règle `eventEnabled` puisse les activer, puis applique les World Rules triées par priorité avant l'éligibilité.
- Diagnostics : cible absente, target/effect incompatible, Fact de mauvais type et effets opposés à priorité égale échouent fermé.

## Tests créés ou modifiés

- Positifs : map inactive, dirty active, cross-map, Event V2 authoré, réactivation V2 prioritaire, reconfiguration UI complète, save/load V2 hidden.
- Négatifs : chemin sortant du projet, cible V2 absente, type Fact incompatible, disabled/hidden au dispatch.
- Non-régression : Map Events legacy conservent leur projection et leur namespace ; le bridge map-enter reste vert.
- Visuel : golden Facts/World Rules régénéré avec `--update-goldens`, puis ouvert en résolution originale et contrôlé manuellement.

## Commandes et résultats exacts

### Core

```text
cd packages/map_core
/opt/homebrew/bin/dart test test/world_rule_test.dart test/world_rule_authoring_operations_test.dart test/world_rule_diagnostics_test.dart test/world_rule_projection_test.dart test/narrative_event_dispatch_authority_test.dart test/narrative_dependency_index_test.dart test/facts_world_rules_manager_read_model_test.dart
All tests passed! (+100)
/opt/homebrew/bin/dart analyze
No issues found!
```

### Gameplay

```text
cd packages/map_gameplay
/opt/homebrew/bin/dart test test/narrative_event_condition_eligibility_test.dart
All tests passed! (+5)
/opt/homebrew/bin/dart analyze
No issues found!
```

### Runtime

```text
cd packages/map_runtime
/opt/homebrew/bin/flutter test test/world_rules_runtime_projection_hook_test.dart test/scene_runtime_state_persistence_gate_test.dart test/narrative_map_enter_production_dispatch_bridge_test.dart
All tests passed! (+37)
/opt/homebrew/bin/flutter analyze
No issues found! (ran in 4.1s)
```

### Editor

```text
cd packages/map_editor
/opt/homebrew/bin/flutter test test/narrative_project_snapshot_loader_test.dart test/facts_world_rules_manager_test.dart
All tests passed! (+8)
/opt/homebrew/bin/flutter analyze
11 issues found — 11 warnings préexistants, tous dans lib/src/ui/canvas/dialogue_studio/dialogs/dialogue_studio_dialogs.dart ; aucune erreur et aucune issue NSC-52.
```

### Golden et hygiène

```text
cd packages/map_editor
/opt/homebrew/bin/flutter test --update-goldens test/facts_world_rules_manager_test.dart --plain-name 'writes V1-35 Facts and World Rules manager screenshot'
All tests passed! (+1)

git diff --check
aucune sortie
```

Un `dart format packages/map_core/lib` trop large a momentanément reformaté 18 fichiers hors scope. La passe de critique finale les a identifiés et toutes ces modifications mécaniques ont été retirées avant le commit.

## État Git final avant commit

- Seuls les fichiers NSC-52 listés ci-dessus, le golden intentionnel, le micro-plan et ce rapport restent modifiés/créés.
- Aucun artefact `build/`, `.dart_tool/` ou failure golden n'est inclus.
- `git diff --check` est propre.

## Limites conservées et risques

- `WorldRuleSourceKind.consumedEvent` reste le contrat des Map Events legacy ; la progression Event V2 possède déjà son propre modèle de condition et n'est pas fusionnée silencieusement ici.
- Le snapshot est chargé à l'ouverture/reconstruction du workspace ; une future optimisation pourra le mettre en cache sans changer son contrat.
- Les 11 warnings Dialogue Studio restent hors scope.
- Les règles invalides restent visibles avec diagnostics mais sont exclues de la projection runtime.

## Auto-critique

Le lot traverse core/editor/runtime et augmente donc la surface de review. La séparation explicite des namespaces, les tests avec collision d'ID, la projection fail-closed et le bridge runtime réduisent le risque principal. L'UI d'édition est plus haute et requiert le scroll déjà fourni par le panneau ; le golden confirme que la carte Configuration reste lisible. Le chargement de maps échoue volontairement en bloc plutôt que de présenter une fausse vue partielle.

## Prochaine étape

NSC-53 — simulateur d'état du monde expliquant les règles applicables, les winners et la projection résultante sans lancer le jeu.

## Contenu complet des fichiers créés

Le présent rapport ne peut pas s'inclure récursivement ; tous les autres fichiers créés par le lot sont reproduits ci-dessous.

<details>
<summary>Contenu complet — docs/superpowers/plans/2026-07-20-nsc-52-world-rules-project-wide.md</summary>

```markdown
# NSC-52 — World Rules projet et authoring complet

## Objectif

Permettre aux World Rules de lire et cibler tout le projet, de rester entièrement modifiables après création et d'agir réellement sur les Narrative Events V2 au runtime.

## Frontières

- La map active non sauvegardée remplace sa version disque dans le snapshot.
- Les autres maps restent chargées depuis le manifeste projet.
- `mapEvent` désigne uniquement `MapData.events` legacy.
- `narrativeEvent` désigne uniquement le registre Event V2 projet.
- Aucun ID manuel n'est demandé dans l'authoring normal.
- Les erreurs de chargement projet bloquent l'édition au lieu de masquer une vue partielle.

## Plan TDD

1. Tester le snapshot multi-map, la priorité de la map active dirty et les chemins hors projet.
2. Tester l'authoring cross-map et la cible Event V2 distincte.
3. Étendre diagnostics et index de dépendances pour les namespaces legacy/V2.
4. Appliquer enabled/disabled/hidden à l'autorité de dispatch Event V2.
5. Raccorder le runtime réel et la persistance save/load.
6. Ajouter les pickers source/prédicat/cible/effet dans l'éditeur post-création.
7. Régénérer et inspecter le golden Facts/World Rules, puis exécuter le gate multi-package.

## Gate

Une règle peut cibler une map inactive ou un Event V2, être entièrement reconfigurée sans ID manuel, produire des diagnostics honnêtes et modifier le dispatch runtime après save/load.
```
</details>

<details>
<summary>Contenu complet — packages/map_editor/lib/src/application/services/narrative_project_snapshot_loader.dart</summary>

```dart
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../domain/repositories/repositories.dart';

/// Immutable project-wide input shared by narrative diagnostics and pickers.
///
/// The active editor document deliberately wins over its disk counterpart so
/// authoring never diagnoses stale data while the other maps remain visible.
final class NarrativeProjectSnapshot {
  NarrativeProjectSnapshot({
    required this.project,
    required List<MapData> maps,
  }) : maps = List<MapData>.unmodifiable(maps);

  final ProjectManifest project;
  final List<MapData> maps;

  MapData? mapById(String mapId) =>
      maps.where((map) => map.id == mapId).firstOrNull;
}

final class NarrativeProjectSnapshotLoader {
  const NarrativeProjectSnapshotLoader({
    required MapRepository mapRepository,
  }) : _mapRepository = mapRepository;

  final MapRepository _mapRepository;

  Future<NarrativeProjectSnapshot> load({
    required ProjectManifest project,
    required String projectRootPath,
    MapData? activeMap,
  }) async {
    final root = p.normalize(p.absolute(projectRootPath.trim()));
    if (projectRootPath.trim().isEmpty) {
      throw ArgumentError.value(
        projectRootPath,
        'projectRootPath',
        'must not be empty',
      );
    }
    final maps = <MapData>[];
    final seen = <String>{};
    for (final entry in project.maps) {
      if (!seen.add(entry.id)) {
        throw StateError('Duplicate project map id "${entry.id}".');
      }
      if (activeMap?.id == entry.id) {
        maps.add(activeMap!);
        continue;
      }
      final path = _resolveWithinRoot(root, entry.relativePath);
      final map = await _mapRepository.loadMap(path);
      if (map.id != entry.id) {
        throw StateError(
          'Map "${entry.id}" loaded "${map.id}" from ${entry.relativePath}.',
        );
      }
      maps.add(map);
    }
    if (activeMap != null && !seen.contains(activeMap.id)) {
      // A newly created unsaved map can briefly precede its manifest entry.
      maps.add(activeMap);
    }
    return NarrativeProjectSnapshot(project: project, maps: maps);
  }
}

String _resolveWithinRoot(String root, String relativePath) {
  final relative = relativePath.trim();
  if (relative.isEmpty || p.isAbsolute(relative)) {
    throw ArgumentError.value(
      relativePath,
      'relativePath',
      'must be a non-empty project-relative path',
    );
  }
  final candidate = p.normalize(p.join(root, relative));
  if (candidate != root && !p.isWithin(root, candidate)) {
    throw ArgumentError.value(
      relativePath,
      'relativePath',
      'must stay within the project root',
    );
  }
  return candidate;
}
```
</details>

<details>
<summary>Contenu complet — packages/map_editor/test/narrative_project_snapshot_loader_test.dart</summary>

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_project_snapshot_loader.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  test('loads inactive maps from disk and lets the dirty active map win',
      () async {
    const diskActive = MapData(
      id: 'map_active',
      name: 'Disk active',
      size: GridSize(width: 4, height: 4),
    );
    const dirtyActive = MapData(
      id: 'map_active',
      name: 'Dirty active',
      size: GridSize(width: 5, height: 5),
    );
    const inactive = MapData(
      id: 'map_inactive',
      name: 'Inactive disk map',
      size: GridSize(width: 6, height: 6),
    );
    final repository = _FakeMapRepository({
      '/project/maps/active.json': diskActive,
      '/project/maps/inactive.json': inactive,
    });
    final snapshot = await NarrativeProjectSnapshotLoader(
      mapRepository: repository,
    ).load(
      project: _project(),
      projectRootPath: '/project',
      activeMap: dirtyActive,
    );

    expect(snapshot.maps, [dirtyActive, inactive]);
    expect(snapshot.mapById('map_active')?.name, 'Dirty active');
    expect(repository.loadedPaths, ['/project/maps/inactive.json']);
  });

  test('rejects a manifest path escaping the project root', () async {
    final project = _project().copyWith(
      maps: const [
        ProjectMapEntry(
          id: 'map_active',
          name: 'Escape',
          relativePath: '../escape.json',
        ),
      ],
    );

    expect(
      () => NarrativeProjectSnapshotLoader(
        mapRepository: _FakeMapRepository(const {}),
      ).load(project: project, projectRootPath: '/project'),
      throwsArgumentError,
    );
  });
}

ProjectManifest _project() => const ProjectManifest(
      name: 'Snapshot project',
      maps: [
        ProjectMapEntry(
          id: 'map_active',
          name: 'Active',
          relativePath: 'maps/active.json',
        ),
        ProjectMapEntry(
          id: 'map_inactive',
          name: 'Inactive',
          relativePath: 'maps/inactive.json',
        ),
      ],
      tilesets: [],
    );

final class _FakeMapRepository implements MapRepository {
  _FakeMapRepository(this.mapsByPath);

  final Map<String, MapData> mapsByPath;
  final List<String> loadedPaths = <String>[];

  @override
  Future<MapData> loadMap(String path) async {
    loadedPaths.add(path);
    return mapsByPath[path] ?? (throw StateError('Missing fake map $path'));
  }

  @override
  Future<void> deleteMap(String path) => throw UnimplementedError();

  @override
  Future<void> renameMap(String oldPath, String newPath) =>
      throw UnimplementedError();

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) =>
      throw UnimplementedError();
}
```
</details>
