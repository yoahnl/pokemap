# NSC-60 — Baseline de caractérisation Cinematic Builder

Date : 2026-07-20
Phase : 6 — Cinematics
Lot : NSC-60
Verdict proposé : **DONE**

## Résumé exécutif

Le comportement actuel du Cinematic Builder monolithique est désormais figé par une baseline reproductible avant toute modularisation. Aucun fichier de production, modèle, codec ou comportement runtime n’a été modifié.

La baseline couvre les frontières palette, stage/preview, timeline et inspecteur, les routes Library/Builder/Legacy, la sémantique du retour, les trois goldens canoniques, les états volontairement read-only et des budgets généreux de chargement/rebuild sur une fixture de 120 blocs.

## Scope confirmé

Inclus :

- inventaire reproductible des tests existants ;
- caractérisation des frontières à extraire au lot NSC-61 ;
- contrôle sémantique du shell et de la navigation ;
- vérification des trois goldens Cinematics à 1672 × 941 ;
- mesure du cold load, de l’ouverture du Builder et des rebuilds après stabilisation ;
- inventaire des couleurs/imports legacy à ratcheter au lot NSC-61 ;
- documentation des capacités read-only existantes.

Exclus :

- aucune extraction de widget ou controller ;
- aucune nouvelle commande Cinematic ;
- aucune modification visuelle ;
- aucune modification de modèle, preview ou runtime ;
- aucune mise à jour de statut FG, la caméra/FX avancés restant hors MVP mécanique.

## Audit initial

État Git initial :

- branche : main ;
- HEAD : 7e02a5432 ;
- arbre de travail : propre.

Constats :

- cinematic_builder_workspace.dart contient 13 548 lignes et concentre controller implicite, palette, stage, timeline et inspecteur ;
- cinematic_builder_workspace_test.dart contenait déjà 292 déclarations de tests avant ce lot ;
- la route Cinematics possédait déjà trois goldens versionnés : Library, Builder et Legacy ;
- Dialogue, FX et Son étaient visibles mais verrouillés dans la palette ;
- les blocs non authoring restaient en lecture seule ;
- la preview supportait déjà caméra, fade, mouvements et emotes, sans parité audio/FX ;
- des couleurs directes et un token legacy existaient encore et devaient être enregistrés, pas corrigés dans ce lot.

## Passes indépendantes

L’instruction d’orchestration active interdit les sub-agents. Les verdicts demandés par codex_rule.md ont donc été obtenus par cinq passes locales séparées, sans prétendre qu’un sub-agent a été utilisé.

| Passe | Vérification | Verdict |
|---|---|---|
| Audit / Architecture | frontières, contrats, tests, goldens, contraintes read-only | Conforme |
| Implémentation | tests uniquement, aucun fichier de production | Conforme |
| Tests | baseline, route, semantics, goldens, budgets | Conforme |
| Build / Validation | analyse ciblée et build macOS debug | Conforme |
| Critique finale | diff, scope, couleurs legacy, absence de mutation | Conforme |

## Inventaire reproductible

Commande :

    rg -n '^\s*(test|testWidgets)\(' test/cinematic_builder_workspace_test.dart test/ui/canvas/narrative_studio_cinematics_route_test.dart test/ui/canvas/narrative_studio_workspace_visual_test.dart test/cinematic_builder_characterization_performance_test.dart | awk -F: '{count[$1]++} END {for (file in count) print file, count[file]}' | sort

Résultat après lot :

| Fichier | Déclarations |
|---|---:|
| test/cinematic_builder_workspace_test.dart | 293 |
| test/ui/canvas/narrative_studio_cinematics_route_test.dart | 8 |
| test/ui/canvas/narrative_studio_workspace_visual_test.dart | 12 |
| test/cinematic_builder_characterization_performance_test.dart | 1 |

Les boucles paramétrées peuvent produire plusieurs cas runtime ; le total réel de la commande ciblée est donc supérieur à ce compteur lexical.

## Matrice de caractérisation

| Domaine | Preuve |
|---|---|
| Palette | labels, commandes supportées, Dialogue/FX/Son visibles mais non actionnables |
| Stage / Preview | clé stable cinematic-builder-preview-placeholder et absence de mutation |
| Timeline | clé stable cinematic-builder-timeline-placeholder, ordre et sélection déjà couverts |
| Inspector | clé stable cinematic-builder-inspector-placeholder et lecture seule des blocs non authoring |
| Route | un seul ProductShell, une WorkspacePage et un Builder |
| Semantics | retour bibliothèque exposé avec un label lisible |
| Persistence | suite route existante couvre transaction, no-op et conflit |
| Diagnostics | suite builder existante couvre fallback, drift, assets et état stage |
| Goldens | Library, Builder et Legacy comparés et vérifiés en 1672 × 941 |
| Performance | fixture 120 blocs, cold load, ouverture, constructions et rebuilds stabilisés |

## Baseline mesurée

Environnement :

- macOS local ;
- Flutter 3.46.0-0.3.pre beta ;
- Dart 3.13.0-167.1.beta ;
- surface 1672 × 941 ;
- fixture de 120 blocs répartis entre camera, actorMove, dialogueLine et wait ;
- exécution Flutter widget test en mode debug/assertions.

Mesure lors de la suite ciblée complète :

- coldLoadMs : 861 ;
- builderOpenMs : 834 ;
- openFirstBuilds : 6263 ;
- openRebuilds : 0 ;
- settledFirstBuilds : 0 ;
- settledRebuilds : 0.

Une exécution isolée a mesuré 825 ms et 730 ms. Cette variation justifie les budgets de garde-fou volontairement larges :

- cold load inférieur à 5 secondes ;
- ouverture Builder inférieure à 5 secondes ;
- 1 à 10 000 constructions initiales ;
- moins de 5 000 rebuilds pendant l’ouverture ;
- aucune nouvelle construction et au plus 10 rebuilds après stabilisation.

Ces budgets détectent une régression catastrophique ; ils ne constituent pas un benchmark microseconde portable.

## Ratchet couleurs et imports legacy

Commande reproductible :

    rg -n 'Color\(0x|Colors\.|PokeMapLegacyColors' lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart

Baseline :

- 2 occurrences de Color(0x33000000) ;
- 1 occurrence de Color(0x0A000000) ;
- 11 occurrences de Colors.transparent ;
- 1 occurrence de PokeMapLegacyColors.transparent ;
- import direct de theme.dart ;
- import du design system existant.

NSC-61 devra réduire ces dettes sans en introduire de nouvelles et sans modifier les goldens.

## États read-only enregistrés

- Dialogue, FX et Son sont affichés dans la palette mais verrouillés.
- Aucun bouton palette exécutable n’existe pour dialogueLine, fx ou sound.
- Un bloc existant non authoring affiche « Durée non éditable — bloc en lecture seule. »
- Les commandes média ne doivent pas devenir publiables avant NSC-66/67.
- Marker reste un élément éditorial et non une commande runtime dans les lots ultérieurs.
- Le lot n’interprète pas un fallback visuel comme une preuve de support runtime.

## Fichiers modifiés

### packages/map_editor/test/cinematic_builder_workspace_test.dart

Zone : début de main.

Modification : ajout d’une caractérisation explicite des quatre frontières, des clés stables, des commandes verrouillées et de l’inspecteur read-only.

Impact : NSC-61 dispose d’un garde-fou de comportement avant extraction.

### packages/map_editor/test/ui/canvas/narrative_studio_cinematics_route_test.dart

Zone : après la matrice responsive et avant les goldens.

Modification : ajout de la baseline semantics et shell ownership de la route Builder.

Impact : une extraction ne pourra pas dupliquer le shell, perdre la page partagée ou rendre le retour muet.

### packages/map_editor/test/ui/canvas/narrative_studio_workspace_visual_test.dart

Zones : début de main et helper PNG.

Modification : vérification que les trois goldens versionnés existent et portent exactement les dimensions canoniques.

Impact : le contrat visuel est explicite sans régénération ni modification d’image.

## Fichier créé

### packages/map_editor/test/cinematic_builder_characterization_performance_test.dart

Rôle : baseline reproductible du cold load, de l’ouverture et des rebuilds.

Contenu complet :

~~~~dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_builder_workspace.dart';

import 'shell_chrome_test_harness.dart';

/// NSC-60 records intentionally generous regression budgets around the
/// current monolithic builder. The measured values are emitted by the test;
/// the limits protect NSC-61 from catastrophic regressions without pretending
/// that wall-clock timings are deterministic across developer machines.
void main() {
  testWidgets('characterizes cold load, builder open and settled rebuilds', (
    tester,
  ) async {
    var firstBuilds = 0;
    var rebuilds = 0;
    final previousRebuildObserver = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (builtOnce) {
        rebuilds += 1;
      } else {
        firstBuilds += 1;
      }
      previousRebuildObserver?.call(element, builtOnce);
    };
    addTearDown(() => debugOnRebuildDirtyWidget = previousRebuildObserver);

    final coldLoad = Stopwatch()..start();
    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        project: _characterizationProject(),
        workspaceMode: EditorWorkspaceMode.cutscene,
      ),
      surfaceSize: const Size(1672, 941),
    );
    coldLoad.stop();

    firstBuilds = 0;
    rebuilds = 0;
    final builderOpen = Stopwatch()..start();
    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_baseline')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
    );
    await tester.pumpAndSettle();
    builderOpen.stop();

    expect(find.byType(CinematicBuilderWorkspace), findsOneWidget);
    final openFirstBuilds = firstBuilds;
    final openRebuilds = rebuilds;

    firstBuilds = 0;
    rebuilds = 0;
    await tester.pump(const Duration(milliseconds: 16));
    final settledFirstBuilds = firstBuilds;
    final settledRebuilds = rebuilds;

    debugPrint(
      'NSC-60 cinematic baseline: '
      'coldLoadMs=${coldLoad.elapsedMilliseconds}, '
      'builderOpenMs=${builderOpen.elapsedMilliseconds}, '
      'openFirstBuilds=$openFirstBuilds, openRebuilds=$openRebuilds, '
      'settledFirstBuilds=$settledFirstBuilds, '
      'settledRebuilds=$settledRebuilds',
    );

    expect(coldLoad.elapsed, lessThan(const Duration(seconds: 5)));
    expect(builderOpen.elapsed, lessThan(const Duration(seconds: 5)));
    expect(openFirstBuilds, inInclusiveRange(1, 10000));
    expect(openRebuilds, lessThan(5000));
    expect(settledFirstBuilds, 0);
    expect(settledRebuilds, lessThanOrEqualTo(10));
    expect(tester.takeException(), isNull);
  });
}

ProjectManifest _characterizationProject() {
  return ProjectManifest(
    name: 'Cinematic characterization',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    cinematics: <CinematicAsset>[
      CinematicAsset(
        id: 'cinematic_baseline',
        title: 'Baseline cinématique',
        requiredActors: <CinematicActorRef>[
          CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
        ],
        timeline: CinematicTimeline(
          steps: <CinematicTimelineStep>[
            for (var index = 0; index < 120; index++)
              CinematicTimelineStep(
                id: 'step_$index',
                kind: switch (index % 4) {
                  0 => CinematicTimelineStepKind.camera,
                  1 => CinematicTimelineStepKind.actorMove,
                  2 => CinematicTimelineStepKind.dialogueLine,
                  _ => CinematicTimelineStepKind.wait,
                },
                label: 'Bloc $index',
                durationMs: 250 + (index % 5) * 100,
                actorId: index % 4 == 1 || index % 4 == 2 ? 'actor_lysa' : null,
              ),
          ],
        ),
      ),
    ],
  );
}
~~~~

## Commandes et résultats exacts

### Tests de mise au point

- Première compilation du test performance : échec attendu de fixture, CinematicActorRef utilisé dans une liste const.
- Fixture corrigée sans modification de production.
- Test performance isolé : 1 test réussi ; mesure 825/730 ms.
- Tests NSC-60 filtrés : 3 tests réussis après correction de la fermeture explicite du SemanticsHandle.

### Suite ciblée roadmap

Commande :

    cd packages/map_editor
    flutter test test/cinematic_builder_workspace_test.dart test/ui/canvas/narrative_studio_cinematics_route_test.dart test/cinematic_builder_characterization_performance_test.dart

Résultat :

- 304 tests réussis ;
- 0 échec ;
- baseline finale : 861/834 ms, 6263 constructions, 0 rebuild résiduel.

### Suite visuelle

Commande :

    flutter test test/ui/canvas/narrative_studio_workspace_visual_test.dart

Résultat :

- 56 tests réussis ;
- 0 échec ;
- goldens Scenes/Storylines/Step inchangés ;
- manifeste des trois goldens Cinematics valide.

### Analyse

Première analyse ciblée :

- 1 info unnecessary_import dans le nouveau test ;
- import supprimé.

Analyse ciblée finale :

    flutter analyze test/cinematic_builder_workspace_test.dart test/ui/canvas/narrative_studio_cinematics_route_test.dart test/ui/canvas/narrative_studio_workspace_visual_test.dart test/cinematic_builder_characterization_performance_test.dart

Résultat : No issues found! (ran in 2.7s).

### Build

Commande :

    flutter build macos --debug

Résultat : Built build/macos/Build/Products/Debug/map_editor.app.

## État Git de clôture avant commit

Le diff du lot contient uniquement :

- trois fichiers de tests modifiés ;
- un test de performance créé ;
- le présent rapport créé.

Aucun fichier de production ni golden n’est modifié. Le hash du commit et l’état post-commit sont consignés dans le handoff final afin d’inclure ce rapport dans le même commit sans référence circulaire.

## Auto-critique et risques restants

- La mesure wall-clock varie selon la machine ; les limites sont donc des garde-fous larges, pas un SLA.
- Le compteur firstBuilds mesure les éléments construits dans la route entière pendant l’ouverture, pas uniquement les widgets Cinematic privés.
- La baseline enregistre 6263 constructions initiales, valeur élevée qui justifie la modularisation mais ne doit pas être présentée comme une fuite.
- Le builder reste monolithique et conserve ses couleurs legacy jusqu’à NSC-61, conformément à l’interdiction de mélanger caractérisation et refactor.
- Les commandes Dialogue/Audio/FX restent volontairement verrouillées ; aucun support runtime n’est revendiqué.
- Les goldens existants sont réutilisés et vérifiés, pas régénérés.

## Prochaine étape proposée

NSC-61 : extraire controller, palette, stage, timeline et inspecteur à comportement constant, puis comparer tests, goldens, semantics et budgets à cette baseline.

## Proposition de statut mécanique

- NSC-60 : DONE.
- FG-082 : reste PARTIAL, aucune nouvelle commande runtime dans ce lot.
- FG-145 : reste PARTIAL, aucune nouvelle template de cutscene scénarisée dans ce lot.
