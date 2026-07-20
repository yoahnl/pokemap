# NSC-62 — Cinematics Library complète

Date : 2026-07-20

Statut proposé : **DONE**

## Lot et objectif

- Lot canonique : **NSC-62 — Cinematics Library complète**.
- Phase : **6 — Cinematics professionnelles**.
- Dépendances vérifiées : NSC-01, NSC-11 et baseline NSC-60.
- But livré : retrouver, classer, dupliquer, archiver et réutiliser une Cinematic sans saisir d’ID ni ouvrir chaque asset.

## Audit initial

La Library V0 séparait déjà CinematicAsset et bridges legacy, calculait durée/usages/diagnostics et proposait un CRUD de métadonnées minimal. Elle ne possédait toutefois ni requête scalable, ni arbre Storyline/Chapter/lieu, ni classement guidé complet, ni duplicate/archive/bulk atomique, ni navigation vers les Scenes consommatrices.

État Git initial : propre après le commit NSC-61 `fe38bea2`.

## Passes indépendantes

Aucun sub-agent n’a été lancé, l’instruction active interdisant la délégation sans demande explicite.

1. **Passe domaine** : query/sort/filter/grouping purs, labels humains, archive typée, usages avec outcomes.
2. **Passe authoring** : duplication avec IDs frais, archive/restauration, tags et archive bulk atomiques.
3. **Passe UI no-code** : recherche, arbres, thumbnails, filtres, tri, pickers map/storyline/chapter, tags, actions individuelles et groupées.
4. **Passe navigation** : usage Scene cliquable vers le nœud exact.
5. **Passe échelle/visuelle** : fixture 1 000 assets, liste lazy, responsive 1280×768, golden 1672×941 inspecté.

Verdict cumulé : **GO**.

## Fichiers modifiés

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/read_models/cinematics_library_read_model.dart`
- `packages/map_core/test/cinematics_library_read_model_test.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_dropdown_field.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_dropdown_field_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_studio_cinematics_route_test.dart`
- `packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_library_full_product_route_1672x941.png`

## Fichiers créés

- `packages/map_core/test/cinematic_library_authoring_operations_test.dart`
- `packages/map_core/test/cinematics_library_read_model_performance_test.dart`

## Zones précises modifiées

- `CinematicAsset` : copyWith nullable sûr et convention d’archive stable.
- Authoring : `duplicateCinematicAsset`, `setCinematicArchived`, `bulkTagCinematics`, `bulkSetCinematicsArchived`.
- Read model : `CinematicsLibraryQuery`, visibilité, tri, groupes et labels résolus.
- Usages : outcomes sortants et destination Scene/nœud.
- Library : recherche multi-termes, tri canonique-first, arbre, thumbnails générés, sélection bulk et suppression expliquée.
- Métadonnées : pickers map/storyline/chapter, tags et notes ; aucun ID libre.
- Responsive : métriques compactes sous 720 px de hauteur et cache lazy explicite.
- Design system : variante `compact` de `PokeMapDropdownField`, conservant les semantics.

## TDD

RED observé :

- APIs de query/grouping et archive inexistantes ;
- opérations duplicate/archive/bulk absentes ;
- variante dropdown compacte absente ;
- Library 1280×768 rendait sa première entrée canonique hors du viewport après enrichissement.

GREEN obtenu avec tests de domaine, widget, navigation, responsive, golden et build.

## Commandes et résultats exacts

```text
cd packages/map_core
dart analyze
No issues found!

dart test test/cinematics_library_read_model_test.dart test/cinematic_library_authoring_operations_test.dart test/cinematics_library_read_model_performance_test.dart
+9: All tests passed!
NSC-62 library baseline: buildMicros=24786, queryAndGroupMicros=13440, assets=1000, matches=500

cd packages/map_editor
flutter analyze [6 fichiers du lot]
No issues found!

flutter test --reporter compact test/cinematics_library_workspace_test.dart test/ui/design_system/pokemap_dropdown_field_test.dart test/ui/canvas/narrative_studio_cinematics_route_test.dart test/ui/canvas/narrative_studio_workspace_visual_test.dart
+95: All tests passed!

flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app

git diff --check
aucune sortie, code 0
```
Le `flutter analyze` global de map_editor reste non vert avec **11 warnings préexistants**, tous localisés dans `dialogue_studio_dialogs.dart` (unused/protected Riverpod/State). Aucun warning ne concerne les fichiers NSC-62 ; ils n’ont pas été corrigés hors périmètre.

## Preuve visuelle

Le golden `cinematics_library_full_product_route_1672x941.png` a été régénéré uniquement après validation fonctionnelle, puis inspecté visuellement. La Library conserve le shell Narrative Studio et expose désormais les actions et le classement sans rupture de layout. Les goldens Builder et Legacy restent inchangés.

## Non-objectifs

- Aucun changement de runtime cinématique.
- Aucun nouveau kind de commande.
- Aucun budget temporel strict inventé : NSC-00 confie la cible cross-machine à NSC-74. NSC-62 enregistre une baseline observationnelle et un timeout de sûreté de 10 secondes.
- Aucun effacement automatique de bridge legacy.

## Risques et limites

- Les archives reposent sur une clé metadata backward-compatible ; une future migration dédiée pourra en faire un champ de schéma si nécessaire.
- Les opérations bulk sont atomiques au niveau projet, mais l’UI de suppression multiple reste volontairement absente : chaque suppression doit expliquer ses usages.
- Le thumbnail est une synthèse déterministe de timeline, pas une frame rendue du runtime.
- Les warnings globaux Dialogue restent une dette distincte.

## Auto-critique

Le lot est plus large que les quatre fichiers indicatifs de la roadmap, parce qu’une archive ou duplication uniquement simulée dans le widget aurait contourné les transactions canoniques. L’extension du domaine reste ciblée, pure Dart et backward-compatible. Le compromis visuel privilégie la densité et la performance : l’arbre est aplati et virtualisé, plutôt qu’un widget de tree complexe chargé intégralement.

## État Git avant commit

Les seuls changements présents sont ceux listés dans cet Evidence Pack ; aucun changement utilisateur préexistant n’a été absorbé.

## Contenu complet des fichiers créés

### `packages/map_core/test/cinematic_library_authoring_operations_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('duplicates a cinematic with fresh asset and timeline ids', () {
    final project = _project();

    final result = duplicateCinematicAsset(
      project,
      cinematicId: 'cinematic_intro',
    );

    expect(result.cinematic.id, 'cinematic_intro_copy');
    expect(result.cinematic.title, 'Intro (copie)');
    expect(result.cinematic.timeline.steps.single.id, isNot('step_wait'));
    expect(project.cinematics, hasLength(1));
    expect(result.updatedProject.cinematics, hasLength(2));
  });

  test('archives and bulk-tags cinematics without dropping metadata', () {
    final archived = setCinematicArchived(
      _project(),
      cinematicId: 'cinematic_intro',
      archived: true,
    );
    expect(isCinematicArchived(archived.cinematic), isTrue);
    expect(archived.cinematic.metadata['custom'], 'preserved');

    final tagged = bulkTagCinematics(
      archived.updatedProject,
      cinematicIds: const ['cinematic_intro'],
      tags: const ['boss', 'port', 'boss'],
    );
    expect(tagged.cinematics.single.tags, ['boss', 'port']);
    expect(isCinematicArchived(tagged.cinematics.single), isTrue);

    final restored = bulkSetCinematicsArchived(
      tagged.updatedProject,
      cinematicIds: const ['cinematic_intro'],
      archived: false,
    );
    expect(isCinematicArchived(restored.cinematics.single), isFalse);
  });
}

ProjectManifest _project() => ProjectManifest(
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
      name: 'library',
      maps: const [],
      tilesets: const [],
      cinematics: [
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro',
          metadata: const {'custom': 'preserved'},
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_wait',
                kind: CinematicTimelineStepKind.wait,
                durationMs: 200,
              ),
            ],
          ),
        ),
      ],
    );
```
### `packages/map_core/test/cinematics_library_read_model_performance_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('characterizes search sort and grouping for 1000 cinematics', () {
    final project = ProjectManifest(
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
      name: 'cinematics_scale_fixture',
      maps: const [
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port Selbrume',
          relativePath: 'port.json',
        ),
      ],
      tilesets: const [],
      cinematics: [
        for (var index = 0; index < 1000; index++)
          CinematicAsset(
            id: 'cinematic_${index.toString().padLeft(4, '0')}',
            title: 'Plan $index',
            mapId: 'map_port',
            tags: [index.isEven ? 'rival' : 'ambiance'],
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'step_$index',
                  kind: CinematicTimelineStepKind.wait,
                  durationMs: 100 + index,
                ),
              ],
            ),
          ),
      ],
    );

    final stopwatch = Stopwatch()..start();
    final readModel = buildCinematicsLibraryReadModel(project);
    final builtMicros = stopwatch.elapsedMicroseconds;
    stopwatch.reset();
    final matches = readModel.queryEntries(
      const CinematicsLibraryQuery(
        searchText: 'rival port',
        sort: CinematicsLibrarySort.durationDescending,
      ),
    );
    final groups = readModel.groupEntries(
      const CinematicsLibraryQuery(
        searchText: 'rival port',
        sort: CinematicsLibrarySort.durationDescending,
      ),
    );
    final queryMicros = stopwatch.elapsedMicroseconds;
    stopwatch.stop();

    expect(readModel.canonicalEntries, hasLength(1000));
    expect(matches, hasLength(500));
    expect(matches.first.id, 'cinematic_0998');
    expect(groups, hasLength(1));
    expect(groups.single.entries, hasLength(500));
    // Observational baseline only. NSC-00 intentionally delegates the strict
    // cross-machine budget to NSC-74 instead of inventing one after the fact.
    // ignore: avoid_print
    print(
      'NSC-62 library baseline: buildMicros=$builtMicros, '
      'queryAndGroupMicros=$queryMicros, assets=1000, matches=500',
    );
  }, timeout: const Timeout(Duration(seconds: 10)));
}
```
