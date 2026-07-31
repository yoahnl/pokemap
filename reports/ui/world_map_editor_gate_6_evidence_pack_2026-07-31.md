# World Map Editor — Gate 6 Evidence Pack

## 1. Résumé exécutif et verdict

**Lot exact : Gate 6 — Validation produit du World Map Editor.**

**Verdict automatisé : `PASS`.**

**Verdict Gate 6 global : `PARTIAL/BLOCKED`.**

Le périmètre automatisable de Gate 6 est certifié par un parcours essentiel
transactionnel, la matrice clavier/accessibilité/responsive, la parité des
mutations, le crash recovery, la sauvegarde/réouverture Selbrume, le contrat de
lecture runtime, les budgets déterministes de grande carte, l’analyse statique
et un build macOS debug. La passe finale transmise par l’agent parent donne :

- agrégat Gate 6 : **169/169** ;
- crash recovery ciblé : **1/1** ;
- Selbrume save/reopen/runtime parity ciblé : **1/1** ;
- `flutter analyze` : **No issues found! (ran in 6.0s)** ;
- `flutter build macos --debug` : **PASS**, artefact
  `build/macos/Build/Products/Debug/PokeMap.app`.

Gate 6 n’est pourtant pas déclaré `DONE`. Les sept validations physiques du
protocole restent toutes `NOT_RUN` : Magic Mouse, trackpad, souris trois
boutons, clavier seul, VoiceOver, profil performance Retina et profil
performance non-Retina/DPR 1. Elles sont l’unique cause du verdict global
`PARTIAL/BLOCKED`. Aucun résultat matériel, ressenti périphérique, chiffre
CPU/GPU/frame timing ou mesure mémoire n’est inventé dans ce rapport.

## 2. Audit du prompt, interprétation et scope

### 2.1 Droit de remise en cause exercé

Le prompt est cohérent avec le dépôt sur le verdict et les preuves attendues.
Une précision Git supplémentaire est nécessaire : outre les quatre commits
concurrents explicitement nommés par le prompt, `74eb92b83` apparaît aussi dans
la plage chronologique et porte le sujet
`feat(mcp): complete authoring mutation runtime bridge`. Comme le prompt
verrouille les commits Gate 6 à cinq hashes exacts, ce commit MCP est également
exclu de l’attribution Gate 6. Cette précision ne change ni le scope ni le
verdict ; elle empêche seulement un inventaire mensonger.

La contrainte historique « 1 subagent-driven » a été interprétée comme un seul
sub-agent actif à la fois. Les rôles obligatoires de `codex_rule.md` ont été
exécutés séquentiellement : audit d’écart, lots d’implémentation, revues de
chaque lot, validation fraîche par l’agent parent, puis critique documentaire
indépendante. Aucun travail délégué n’a été exécuté en parallèle.

### 2.2 Sources de vérité relues

- `AGENTS.md` racine ;
- `codex_rule.md`, relu intégralement avant la rédaction ;
- `reports/ui/world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md`, en particulier sa définition Gate 6 ;
- `reports/ui/world_map_editor_gate_5_evidence_pack_2026-07-29.md`, pour la continuité de Gate ;
- les cinq commits Gate 6 listés en section 7 ;
- `packages/map_editor/test/manual/world_map_gate_6_device_protocol.md` ;
- les sources et tests des 16 chemins Gate 6 inventoriés en section 8.

### 2.3 Scope confirmé

Le lot certifie ou durcit uniquement :

- le parcours réel ouvrir/changer de calque/peindre/effacer/placer/
  sélectionner/déplacer/tourner/undo/redo/save/reopen ;
- l’accessibilité clavier et sémantique du canvas et du menu contextuel ;
- le responsive light/dark à `800×600` et `1280×800`, DPR 2 ;
- la persistance atomique et la réouverture depuis un nouveau repository et
  une nouvelle session ;
- la compatibilité du JSON durable avec validation/composition runtime ;
- le culling déterministe des cellules et placements hors viewport ;
- un protocole physique honnête, non exécuté.

### 2.4 Non-objectifs conservés

- aucune refonte de `EditorNotifier`, des autres workspaces ou du runtime ;
- aucun changement de schéma Gate 5 supplémentaire ;
- aucune réparation du chantier Smart Tiles concurrent ;
- aucune attribution des travaux Authoring/MCP aux commits Gate 6 ;
- aucune mesure physique ou performance profile simulée depuis un build debug ;
- aucune déclaration de suite Selbrume complète verte ;
- aucune implémentation des prochaines étapes proposées en section 14.

## 3. Audit initial

### 3.1 Fichiers et contrats existants identifiés

L’audit a confirmé les frontières suivantes :

- `WorldMapWorkspace` et `WorldMapToolbelt` portent le parcours no-code ;
- `WorldMapLayersInspector` doit garantir un scroll local borné sans imposer
  de scroll au toolbelt principal ;
- `MapCanvasInteractionController` reste l’arbitre d’un geste unique ;
- `EditorNotifier` reste propriétaire des mutations, dirty flags et piles
  Undo/Redo ;
- `MapContextMenuHost` et `PokeMapContextMenu` portent le modal/focus/
  semantics, sans créer de commande fictive ;
- `AuthoringMutationAdapter` est la frontière de sauvegarde authoring ;
- `AtomicMapDocumentPersistence` et `FileMapRepository` portent le recovery ;
- `MapData`, `MapValidator` et `buildMapVisualCompositionPlan` sont les
  contrats partagés avec le runtime ;
- `MapGridPainter` peut culler seulement les géométries bornées, tandis que
  ombres et overlays conservent volontairement leur entrée complète.

### 3.2 Tests et rapports existants

Les tests Gate 1–5 couvraient déjà ordre visuel, pointer arbitration,
manipulation directe, assets, rotation, shell adaptatif, context actions et
isolation des rebuilds. Gate 6 devait ajouter une preuve intégrée réaliste, les
garde-fous physiques explicites, une vraie réouverture persistée et un budget
grande carte indépendant des seules impressions visuelles.

### 3.3 Risques initiaux

- outils critiques hors écran ou exigeant un scroll principal ;
- tap de canvas intercepté par le chrome flottant ;
- navigation qui peint ou crée une entrée d’historique ;
- action clavier non annoncée ou focus non restauré ;
- sauvegarde acceptée en mémoire mais non durable après fermeture ;
- recovery rejoué deux fois ou revision fabriquée ;
- JSON imbriqué non strict refusé par la frontière Authoring ;
- itération de toutes les cellules d’une grande map à chaque frame ;
- culling d’un placement tourné qui coupe son empreinte ;
- faux `DONE` malgré l’absence de matériel réel et de profil macOS.

### 3.4 Verdict Audit / Architecture

**PASS pour le scope automatisé ; BLOCKED pour la clôture physique.**

L’architecture existante permet une certification chirurgicale sans nouvelle
dépendance de package. Les deux failles découvertes pendant la validation —
calques compacts insuffisamment atteignables et chrome « Aperçu lumière »
interceptant la cellule `(0,0)` — ont été corrigées dans les frontières UI
existantes. Aucun blocage architectural logiciel ne reste identifié. Le seul
blocage de Gate global est la matrice physique `NOT_RUN`.

## 4. État Git initial connu et protocole de cohabitation

### 4.1 Borne initiale de la passe documentaire

Photographie lue avant création du présent rapport :

```text
branche : main
HEAD : f93babcc107773116c55451497d7cd4626502997
15 fichiers suivis modifiés hors scope
23 fichiers non suivis hors scope
0 diff Gate 6 non commité
git diff --check : aucune sortie
```

Les 15 modifications suivies concernent uniquement :

- `examples/playable_runtime_host/pubspec.lock` ;
- sept chemins Smart Tiles dans `packages/map_core` ;
- sept chemins Smart Tiles Studio dans `packages/map_editor`.

Les 23 chemins non suivis concernent :

- 17 fichiers sous `.superpowers/brainstorm/32809-1785405902/smart-tiles-interactive/` ;
- six sources/tests Smart Tile Guide sous `packages/map_editor/`.

Cette photographie est l’état initial **connu de la passe de rapport**. Aucun
snapshot fiable du worktree exact avant le premier commit Gate 6 n’est inventé ;
les bornes auditables du lot sont les hashes et diffs de la section 7.

### 4.2 Règles de cohabitation appliquées

1. sélection des cinq commits Gate 6 par hash, jamais par plage brute ;
2. exclusion des commits Authoring/MCP intercalés ;
3. aucune édition des chemins Smart Tiles ou du lockfile ;
4. aucune opération `git add`, `commit`, `reset`, `restore`, `checkout` ou
   `push` ;
5. création du seul Evidence Pack via `apply_patch`.

## 5. Passes séparées et verdicts obligatoires

| Passe | Verdict | Preuve principale | Réserve |
|---|---|---|---|
| Audit / Architecture | PASS automatisé / BLOCKED physique | contrats existants préservés, 16 chemins Gate 6, aucun couplage runtime ajouté | sept validations physiques `NOT_RUN` |
| Implémentation | PASS | cinq commits Gate 6 ciblés, correctifs locaux layers/canvas/persistence/culling | chrome lumière corrigé après une boucle RED/GREEN supplémentaire |
| Tests | PASS automatisé | agrégat 169/169, recovery 1/1, Selbrume ciblé 1/1 | ancienne suite Selbrume complète non certifiée à cause du test 475 placements en timeout |
| Build / Validation | PASS automatisé / BLOCKED physique | analyze propre 6.0s, build macOS debug produit | debug build ne vaut ni profil performance ni validation matérielle |
| Critique finale | PASS pour publication avec verdict global PARTIAL/BLOCKED | scope, exclusions, limites et `NOT_RUN` explicités | Gate 6 ne doit pas être marqué `DONE` avant sept preuves humaines datées |

## 6. Décisions et implémentation

### 6.1 Parcours essentiel et scroll local

Le parcours Gate 6 exerce les vraies familles d’outils et les vraies
transactions à deux tailles d’écran. Le toolbelt ne devient jamais scrollable.
La liste de calques passe à un `CustomScrollView` identifié par
`world-map-layer-list`, ce qui rend les lignes et le diagnostic final
atteignables avec au plus un geste de scroll local dans l’inspecteur compact.

### 6.2 Accessibilité clavier, focus et menu modal

Le canvas possède un curseur cellule annoncé, déplaçable aux flèches. Entrée ou
Espace applique l’outil, `Shift+flèches` déplace une sélection, les raccourcis
de menu contextuel convergent vers une même requête et le focus est restauré.
`BlockSemantics` masque le workspace derrière le menu ouvert ; le tooltip d’une
raison disabled ne duplique pas la sémantique du menu.

### 6.3 Chrome lumière traversant mais boutons actifs

À `1280×800`, l’inspecteur docké réduisait le viewport canvas à 498 px. Le
sélecteur « Aperçu lumière » débordait à gauche : son `DecoratedBox`, puis son
`RenderParagraph`, absorbaient le tap de la cellule `(0,0)`. La preuve RED a
capturé `collision=false`, `undo=0`, `dirty=false`, `error=null`, puis un
hit-path `TextSpan > RenderParagraph > RenderPadding > RenderFlex` au point
réel d’intersection label/cellule.

Le fond décoratif et le seul bloc `Padding+Text` sont désormais sous
`IgnorePointer`. Les cinq `PokeMapButton` restent hors de cet IgnorePointer et
restent hit-testables, focusables et activables. Le test final prouve que le
même point atteint `map-canvas-gesture-detector`, peint `(0,0)` et crée une
seule entrée Undo.

### 6.4 Persistance et recovery

La frontière Authoring normalise `MapData.toJson()` par encode/decode JSON
avant de construire `Map<String, Object?>`, ce qui accepte les géométries
imbriquées sans transmettre des objets Dart non JSON. Le recovery testé part
d’un repository neuf, termine une écriture préparée une fois, nettoie les
artefacts, puis un second repository observe `clear` avec mêmes bytes et même
revision.

Le parcours Selbrume utilise une copie temporaire, un vrai `EditorNotifier`,
quatre transactions documentées (ordre de calque, collision 1×1, move,
rotation), sauvegarde, ferme la première session, recharge via repositories
neufs puis via une seconde session. Le JSON durable passe ensuite
`migrateMapDataJson`, `MapData.fromJson`, `MapValidator.validate` et
`buildMapVisualCompositionPlan`.

### 6.5 Grande carte et culling

`resolveEditorMapVisibleCellBounds` calcule des bornes demi-ouvertes, clampées,
avec marge et rejet des transforms invalides. Les boucles tile, collision,
terrain et path visitent uniquement ces bornes. Les placements sont filtrés
par intersection de leur empreinte tournée. Les ombres et overlays ne sont pas
cullés sans preuve de bornes, afin d’éviter de couper une extension visuelle.

Les compteurs de debug test-only prouvent le nombre de cellules visitées sans
prétendre mesurer CPU/GPU. Un test pixel alpha protège le masquage d’un
placement tourné au bord du viewport. Le long scénario pan/zoom/hover/drag
vérifie aussi qu’une navigation ne salit pas la map et ne crée pas d’historique.

### 6.6 Verdict Implémentation

**PASS.** Les corrections sont localisées, réutilisent les primitives PokeMap
et les contrats transactionnels existants, et n’étendent pas le modèle de
données. Le culling reste volontairement conservateur pour les visuels dont
l’extension n’est pas bornée.

## 7. Commits Gate 6 et exclusions

### 7.1 Commits attribués à Gate 6

| Commit | Date | Sujet | Rôle |
|---|---|---|---|
| `5c44a43b91a7adac4910546a40b0dacfbd0674e5` | 2026-07-31 21:35 CEST | `test(map-editor): certify Gate 6 essential journey` | parcours essentiel et scroll local des calques |
| `11e6bf6ad6231da0c1e51c7cc6cb1a99e1b0301d` | 2026-07-31 22:06 CEST | `feat(map-editor): certify Gate 6 input accessibility` | clavier, focus, semantics, responsive et protocole physique |
| `0c23018dfecf6f4acd4333c3f980079d3aa80f3f` | 2026-07-31 22:27 CEST | `test(map-editor): certify Gate 6 map persistence` | JSON strict, recovery et Selbrume save/reopen/runtime contract |
| `99d1a774b86cd1bc7e4e98d3101972a982a95de8` | 2026-07-31 22:53 CEST | `perf(map-editor): cull offscreen world map cells` | culling déterministe et protocole profile physique |
| `f93babcc107773116c55451497d7cd4626502997` | 2026-07-31 23:17 CEST | `fix(map-editor): keep light preview chrome click-through` | non-régression hit-test du chrome lumière |

### 7.2 Commits concurrents explicitement exclus

| Commit | Sujet | Motif d’exclusion |
|---|---|---|
| `ca5c6c72d` | `feat(editor): read projects through authoring snapshots` | migration Authoring read, hors Gate 6 |
| `5f534dc40` | `feat(editor): route mutations through authoring receipts` | migration Authoring write, hors Gate 6 |
| `61042cab7` | `feat(mcp): establish protocol compatibility gate` | MCP, hors Gate 6 |
| `6476680c4` | `feat(mcp): expose read-only authoring resources` | MCP, hors Gate 6 |
| `74eb92b83` | `feat(mcp): complete authoring mutation runtime bridge` | MCP intercalé supplémentaire, hors des cinq hashes Gate 6 |

Le fait que `0c23018df` modifie deux fichiers initialement créés par le chantier
Authoring ne transforme pas les commits Authoring parents en commits Gate 6.
Seuls les hunks du commit `0c23018df` sont attribués au présent lot.

## 8. Inventaire complet des fichiers Gate 6 et zones précises

Légende : `A` créé dans Gate 6, `M` modifié. Les zones indiquent les symboles
actuels et, entre parenthèses, les hunks principaux des commits Gate 6.

| Statut | Fichier | Commit(s) | Zones / diff précis | Raison et impact |
|---|---|---|---|---|
| M | `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_layers_inspector.dart` | `5c44a43b9` | `WorldMapLayersInspector.build`, lignes ~81–159 ; hunks `@@ -84...`, `@@ -113...`, `@@ -130...` | remplace Column/ListView par un CustomScrollView à slivers ; rend header, lignes et diagnostic atteignables par scroll local |
| M | `packages/map_editor/test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart` | `5c44a43b9` | test `compact inspector keeps layer rows reachable by local scroll` ligne 55 ; harness `pump(size:)` ~1039 ; hunks `@@ -54...`, `@@ -1004...` | prouve scroll compact, contenu final et tailles de harness |
| A | `packages/map_editor/test/ui/world_map/world_map_gate_6_essential_journey_test.dart` | `5c44a43b9`, `f93babcc1` | fichier créé 1–512 puis hunks autour des lignes 71–104 et 213–265 ; actuel 596 lignes | parcours essentiel aux deux tailles, budgets de clic/scroll, transaction/dirty/history, hit-test exact du chrome lumière |
| M | `packages/map_editor/lib/src/features/editor/presentation/world_map/map_context_menu_host.dart` | `11e6bf6ad` | `MapContextMenuHost.build`, ligne 49 ; hunk `@@ -49,37 +49,39` | enveloppe le menu ouvert dans `BlockSemantics`, évite que le lecteur d’écran traverse le modal |
| M | `packages/map_editor/lib/src/ui/canvas/map_canvas.dart` | `11e6bf6ad`, `f93babcc1` | état clavier lignes 494–497 ; activation ~1181 ; focus/semantics ~1641 ; navigation controls ~1952 ; `_resolveKeyboardCursor` ~2568 ; `_keyboardContextMenuRequest` ~2704 ; `_shadowLightPreviewSelector` 2033–2093 | clavier complet, curseur annoncé, move/context menu/focus, contrôles viewport DS et chrome lumière traversant |
| M | `packages/map_editor/lib/src/ui/design_system/pokemap_context_menu.dart` | `11e6bf6ad` | tooltip disabled autour de la ligne 466 ; hunk `@@ -243...` du commit puis ligne actuelle 466 | `excludeFromSemantics: true` évite une annonce dupliquée tout en gardant la raison visuelle |
| M | `packages/map_editor/test/features/editor/presentation/world_map/map_context_menu_host_test.dart` | `11e6bf6ad` | test `open menu blocks the workspace behind it from semantics` lignes 104–127 ; harness semantics ~392 | prouve modal sémantique et masquage du canvas arrière |
| A | `packages/map_editor/test/manual/world_map_gate_6_device_protocol.md` | `11e6bf6ad`, `99d1a774b` | matrice physique lignes 12–20 ; profil VAL-04 lignes 22–68 ; règle de clôture lignes 70–77 | verrouille cinq périphériques/aides et deux profils comme preuves humaines distinctes, toutes `NOT_RUN` |
| M | `packages/map_editor/test/ui/world_map/world_map_workspace_accessibility_test.dart` | `11e6bf6ad` | tests lignes 298, 356, 409, 454, 491 ; helpers/fixtures ~838 et ~984 | curseur cellule, Enter/Espace, resynchronisation pointer, move/rejet clavier, presets lumière sémantiques |
| M | `packages/map_editor/test/ui/world_map/world_map_workspace_responsive_test.dart` | `11e6bf6ad` | matrice DPR 2 ligne 145 ; `_expectLightPreviewAction` ~352 ; `devicePixelRatio` du harness ~502 | light/dark × 800/1280, contrôles entièrement visibles, hit-testables et activables |
| M | `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart` | `0c23018df` | `saveMap` ligne 212 ; `_strictJsonMap` lignes 271–273 | garantit un arbre JSON strict à la frontière Authoring, y compris géométries imbriquées |
| M | `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart` | `0c23018df` | test `saveMap accepts gameplay zones with nested geometry`, lignes 91–127 | non-régression d’écriture/réouverture d’une `MapGameplayZone` imbriquée |
| M | `packages/map_editor/test/infrastructure/repositories/atomic_map_document_persistence_test.dart` | `0c23018df` | test `fresh repository completes a prepared crash once and later recovery is clear`, lignes 423–482 | prouve target inchangée avant recovery, completion unique, nettoyage, seconde reprise clear et revision stable |
| M | `packages/map_editor/test/selbrume_editor_repository_roundtrip_test.dart` | `0c23018df` | dialogues fixture ~26–53 ; test Gate 6 lignes 278–453 ; helpers ~455–465 | vrai projet réaliste, quatre mutations, save/close/reopen, repositories neufs, seconde session et contrat runtime |
| M | `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart` | `99d1a774b` | `EditorMapVisibleCellBounds` lignes 192–218 ; resolver 221–274 ; debug snapshot 277–303 ; calcul/filtrage ~434–742 ; boucles ~2045, 2569, 2606, 2658 | culling borné des cellules et empreintes tournées, compteurs test-only, ombres/overlays conservateurs |
| M | `packages/map_editor/test/ui/world_map/world_map_large_map_performance_test.dart` | `99d1a774b` | bounds tests 21–116 ; culling 121–183 ; pixel rotation 189–197 ; long journey 201–389 ; fixtures 391+ | garde-fous bornes invalides, visites visibles, bord tourné, navigation sans mutation et budgets build/paint |

## 9. Tests créés ou modifiés et couverture

### 9.1 Comportements positifs

- accès en un clic aux outils critiques et au changement de calque ;
- peinture collision, effacement exact 1×1, placement asset, sélection, drag,
  rotation, Undo/Redo et réouverture ;
- curseur clavier annoncé et activation Enter/Espace ;
- menu contextuel clavier/pointer modal avec restauration de focus ;
- mutation nested JSON, recovery, save/reopen et composition runtime ;
- culling d’une carte `128×128` avec placement tourné au bord.

### 9.2 Cas négatifs et garde-fous

- déplacement clavier hors bornes : aucune mutation ni history, erreur sobre ;
- navigation seule : map identique, piles vides, `isDirty == false` ;
- transforms de viewport invalides : bornes visibles vides ;
- cellules/placements hors viewport : non visités ;
- seconde reprise après crash : statut `clear`, pas de nouvelle revision ;
- chrome décoratif et label : ne capturent plus le canvas ;
- boutons lumière : restent eux-mêmes hit-testables et activables ;
- menu modal : sémantique arrière absente.

### 9.3 Non-régressions

- ordre de calques et diagnostic final restent atteignables ;
- empreinte collision peinture puis gomme respecte l’historique ;
- placement tourné masque la tile exactement une fois ;
- pixels/runtime contract consomment le document durable attendu ;
- source Selbrume est protégée par snapshot avant/après.

### 9.4 Verdict Tests

**PASS pour la matrice automatisée Gate 6.** Le signal final est 169/169 plus
les deux scénarios de persistance ciblés 1/1. Cette phrase ne signifie pas que
la suite Selbrume complète a été certifiée : voir section 10.3.

## 10. Commandes, résultats exacts et limites de suite

Toutes les commandes Flutter ci-dessous sont exécutées depuis
`packages/map_editor`. Les résultats finaux sont les preuves fraîches
transmises par la passe parent Build/Validation.

### 10.1 Agrégat Gate 6

```bash
flutter test \
  test/ui/world_map/world_map_gate_6_essential_journey_test.dart \
  test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart \
  test/ui/world_map/world_map_workspace_accessibility_test.dart \
  test/ui/world_map/world_map_workspace_responsive_test.dart \
  test/features/editor/presentation/world_map/map_context_menu_host_test.dart \
  test/map_canvas_pointer_navigation_test.dart \
  test/map_canvas_interaction_arbitration_test.dart \
  test/ui/world_map/world_map_rotation_shortcuts_test.dart \
  test/authoring_api/editor_mutation_parity_test.dart \
  test/ui/world_map/world_map_large_map_performance_test.dart \
  test/map_grid_painter_test.dart \
  test/map_grid_painter_layer_order_test.dart \
  test/map_visual_stack_parity_test.dart
```

Résultat : **PASS — 169/169**.

### 10.2 Persistance ciblée

```bash
flutter test \
  test/infrastructure/repositories/atomic_map_document_persistence_test.dart \
  --plain-name 'fresh repository completes a prepared crash once and later recovery is clear'
```

Résultat : **PASS — 1/1**.

```bash
flutter test \
  test/selbrume_editor_repository_roundtrip_test.dart \
  --plain-name 'Gate 6 session saves and reopens exact layer collision move and rotation edits'
```

Résultat : **PASS — 1/1**. Ce test inclut la validation du document durable et
la parité du contrat de lecture/composition runtime ; il ne simule pas une
capture physique du renderer.

### 10.3 Timeout historique Selbrume — limite conservée

L’ancienne exécution complète de
`test/selbrume_editor_repository_roundtrip_test.dart` a rencontré le timeout du
test :

```text
real EditorNotifier sessions retain all 475 placements after an edit
```

Ce cas volumique historique n’est pas lié au scénario Gate 6 ciblé ajouté par
`0c23018df`. Le nouveau test ciblé passe 1/1, mais aucune relance fraîche de la
suite Selbrume complète n’est déclarée verte. Le présent Evidence Pack ne
masque donc ni le timeout ni l’absence de preuve full-suite.

### 10.4 Analyse

```bash
flutter analyze
```

Résultat exact : **`No issues found! (ran in 6.0s)`**.

### 10.5 Build

```bash
flutter build macos --debug
```

Résultat : **PASS**. Artefact produit :
`build/macos/Build/Products/Debug/PokeMap.app`.

Ce build debug prouve la compilation/assemblage macOS. Il ne fournit aucune
preuve profile CPU/GPU/mémoire et ne remplace aucun périphérique physique.

### 10.6 Hygiène diff

```bash
git diff --check
```

Résultat au début de la passe documentaire : **exit 0, aucune sortie**.

## 11. Matrice physique et statut de clôture

| ID | Validation | Statut | Conséquence |
|---|---|---|---|
| `G6-PHY-01` | Magic Mouse | `NOT_RUN` | bloque Gate 6 global |
| `G6-PHY-02` | Trackpad | `NOT_RUN` | bloque Gate 6 global |
| `G6-PHY-03` | Souris 3 boutons | `NOT_RUN` | bloque Gate 6 global |
| `G6-PHY-04` | Clavier seul physique | `NOT_RUN` | bloque Gate 6 global |
| `G6-PHY-05` | VoiceOver macOS | `NOT_RUN` | bloque Gate 6 global |
| `G6-PERF-01` | Profil macOS Retina, DPR 2 | `NOT_RUN` | bloque Gate 6 global |
| `G6-PERF-02` | Profil macOS non-Retina/externe, DPR 1 | `NOT_RUN` | bloque Gate 6 global |

Le passage novice demandé par l’audit initial est intégré au parcours complet à
faire pendant cette matrice humaine ; il n’est pas présenté comme une huitième
ligne exécutée ni comme une preuve déjà acquise.

## 12. Verdict Build / Validation

**PASS automatisé / BLOCKED physique.** L’analyse et le build macOS sont
propres ; la matrice de tests Gate 6 ciblée est verte. La build debug ne prouve
pas le rendu VoiceOver, le ressenti d’une Magic Mouse, les gestes natifs d’un
trackpad, le bouton milieu matériel ni les performances profile sur deux
affichages. Le statut global reste donc `PARTIAL/BLOCKED`.

## 13. État Git final

La photographie finale exacte est capturée après écriture et vérification du
présent rapport en section 13.1. Aucun fichier source/test n’est modifié par la
passe documentaire.

### 13.1 Photographie finale horodatée

Snapshot capturé le **2026-07-31 à 23:31:59 CEST** ; les chantiers concurrents
peuvent continuer à faire évoluer le worktree après cette photographie.

```text
branche : main
HEAD : f93babcc107773116c55451497d7cd4626502997
21 fichiers suivis modifiés hors scope
31 fichiers non suivis au total
0 fichier indexé
git diff --check : aucune sortie
```

Les 15 modifications suivies et les 23 fichiers non suivis déjà présents dans
la photographie initiale n’ont pas été touchés par Gate 6. Six fichiers suivis
concurrents se sont ajoutés :

- `packages/map_authoring/lib/map_authoring.dart` ;
- `packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart` ;
- `packages/map_authoring/lib/src/tooling/jsonl_worker.dart` ;
- `packages/map_editor/test/authoring_api/editor_write_boundary_test.dart` ;
- `tools/pokemap_mcp/src/server.ts` ;
- `tools/pokemap_mcp/src/tools/read_only.ts`.

Huit fichiers non suivis s’ajoutent au snapshot final :

- le présent Evidence Pack, seul fichier créé par cette passe documentaire ;
- `packages/map_authoring/lib/src/parity/full_authoring_parity.dart` ;
- `packages/map_authoring/test/fixtures/pmcp085_golden_receipt.json` ;
- `packages/map_authoring/test/parity/full_authoring_parity_test.dart` ;
- `packages/map_authoring/tool/pmcp085_conformance.dart` ;
- `packages/map_editor/test/authoring_api/no_bypass_guardrail_test.dart` ;
- `tools/pokemap_mcp/src/request_guard.ts` ;
- `tools/pokemap_mcp/test/conformance_security.test.ts`.

Les treize chemins hors rapport sont des changements concurrents Authoring/MCP,
hors scope et non modifiés par cette passe. Le HEAD et la branche n’ont pas
changé ; aucune opération Git d’écriture n’a été effectuée.

## 14. Limites, auto-critique, risques et prochaines étapes

### 14.1 Limites explicitement conservées

- sept validations physiques restent `NOT_RUN` ;
- la suite Selbrume complète n’a pas de preuve fraîche verte ;
- les budgets de test comptent visites/builds/paints, pas temps CPU/GPU ;
- la parité runtime ciblée valide le contrat durable partagé, pas une capture
  pixel réelle de l’application ;
- le build est debug, pas profile ;
- aucune mesure d’utilisabilité novice datée n’est inventée.

### 14.2 Auto-critique finale

- Le Gate 6 automatisé couvre bien les invariants reproductibles, mais son nom
  « Validation produit » peut inviter à surévaluer des widget tests. Le verdict
  global bloqué corrige explicitement ce risque de langage.
- Le test intégré utilise une petite map réaliste synthétique tandis que
  Selbrume couvre le document réel uniquement dans le scénario ciblé. Cette
  combinaison est utile, mais ne remplace pas une session humaine longue.
- Le culling réduit les visites des géométries bornées ; il n’établit aucune
  garantie chiffrée de frame time ou mémoire.
- Le correctif du chrome lumière a nécessité deux revues : rendre le fond
  traversant ne suffisait pas, car `RenderParagraph` du label participait
  encore au hit-test. Le test au point d’intersection exact empêche de répéter
  cette erreur de raisonnement.
- L’interleaving de commits Authoring/MCP rendrait une plage Git brute
  trompeuse ; l’inventaire par cinq hashes est plus fiable mais demande une
  discipline durable.

### 14.3 Risques restants

- différences d’événements natifs entre Magic Mouse, trackpad et souris ;
- ordre de focus ou annonce VoiceOver différent du moteur de test semantics ;
- jank GPU/raster, pression mémoire ou dégradation longue non visibles dans
  les compteurs déterministes ;
- comportement sur écran externe/DPR 1 non observé ;
- timeout du test Selbrume 475 placements à diagnostiquer dans un lot de
  performance de fixture séparé, sans le confondre avec Gate 6 ;
- churn Smart Tiles concurrent toujours présent dans le worktree.

### 14.4 Verdict Critique finale

**PASS pour publication de l’Evidence Pack, avec Gate 6 global
`PARTIAL/BLOCKED`.** Aucun fichier hors scope n’est attribué au lot, aucun
résultat physique n’est fabriqué et aucune suite incomplète n’est déclarée
verte. Le rapport ne propose pas `DONE`.

### 14.5 Prochaines étapes proposées, non implémentées

1. exécuter `G6-PHY-01` à `G6-PHY-05` sur matériel réel, avec date, machine,
   OS et observations ;
2. exécuter `G6-PERF-01` et `G6-PERF-02` via
   `flutter run -d macos --profile` et DevTools, sans recycler les chiffres du
   build debug ;
3. joindre les artefacts VoiceOver/performance au protocole ;
4. relancer ensuite la même matrice automatisée et `flutter analyze`/build ;
5. seulement si les sept lignes sont humaines, datées et acceptées, proposer
   Gate 6 comme `DONE` ;
6. diagnostiquer séparément le timeout du test Selbrume 475 placements.

## 15. Contenu intégral des fichiers créés

Cette section satisfait `codex_rule.md`. Les deux fichiers créés par Gate 6
sont reproduits intégralement dans leur état à `f93babcc`. Le présent Evidence
Pack n’est pas reproduit récursivement dans lui-même.

### 15.1 `packages/map_editor/test/ui/world_map/world_map_gate_6_essential_journey_test.dart`

~~~~dart
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/editor/editor_asset_cache_providers.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_toolbelt.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  for (final size in <Size>[
    const Size(800, 600),
    const Size(1280, 800),
  ]) {
    testWidgets(
      'Gate 6 essential journey stays one-click and transactional at '
      '${size.width.toInt()}×${size.height.toInt()}',
      (tester) async {
        final harness = await _pumpJourney(tester, size);
        final editor = harness.notifier;

        const criticalKeys = <String>[
          'world-map-command-save',
          'world-map-command-undo',
          'world-map-command-redo',
          'world-map-command-plus',
          'world-map-tool-selection',
          'world-map-tool-paint',
          'world-map-tool-erase',
          'world-map-tool-place',
          'world-map-tool-layers',
        ];
        final viewport = Offset.zero & size;
        for (final key in criticalKeys) {
          final finder = find.byKey(ValueKey<String>(key));
          expect(finder, findsOneWidget, reason: '$key must require no scroll');
          expect(finder.hitTestable(), findsOneWidget);
          final rect = tester.getRect(finder);
          expect(viewport.contains(rect.topLeft), isTrue, reason: key);
          expect(viewport.contains(rect.bottomRight), isTrue, reason: key);
        }
        expect(
          find.ancestor(
            of: find.byKey(const ValueKey<String>('world-map-tool-slot')),
            matching: find.byType(Scrollable),
          ),
          findsNothing,
          reason: 'the primary toolbelt must never require main scrolling',
        );

        var inspectorScrolls = 0;
        await _activateFamily(tester, harness, 'layers');
        inspectorScrolls += await _activateLayerIfNeeded(tester, 'collision');
        expect(editor.state.activeLayerId, 'collision');

        await _activateFamily(tester, harness, 'paint');
        expect(editor.state.activeTool, EditorToolType.collisionPaint);
        final paintCell = _cellCenter(tester, const GridPos(x: 0, y: 0));
        final canvasGesture = find.byKey(
          const ValueKey<String>('map-canvas-gesture-detector'),
        );
        final canvasRect = tester.getRect(canvasGesture);
        final canvasRenderObject = tester.renderObject(canvasGesture);
        final hitResult = tester.hitTestOnBinding(paintCell);
        final hitPath = hitResult.path.take(12).map((entry) {
          final target = entry.target;
          return target is RenderObject
              ? '${target.runtimeType}(${target.debugCreator})'
              : target.runtimeType.toString();
        }).join(' > ');
        printOnFailure(
          'paint target: surface=$size canvas=$canvasRect global=$paintCell '
          'pan=${editor.state.panOffset} zoom=${editor.state.zoom} '
          'hits=$hitPath',
        );
        expect(canvasRect.contains(paintCell), isTrue);
        expect(
          hitResult.path.any(
            (entry) => identical(entry.target, canvasRenderObject),
          ),
          isTrue,
          reason: 'the exact target cell must hit the map gesture surface',
        );
        await tester.tapAt(paintCell);
        await tester.pump();
        printOnFailure(
          'paint result: collision00=${_collisionAt(editor.state, 0, 0)} '
          'undo=${editor.state.mapUndoStack.length} '
          'stroke=${editor.state.mapStrokeStart != null} '
          'dirty=${editor.state.isDirty} error=${editor.state.errorMessage}',
        );
        expect(_collisionAt(editor.state, 0, 0), isTrue);
        expect(_collisionAt(editor.state, 1, 0), isTrue);
        expect(_collisionAt(editor.state, 0, 1), isTrue);
        expect(editor.state.mapUndoStack, hasLength(1));
        expect(editor.state.isDirty, isTrue);

        await _activateFamily(tester, harness, 'erase');
        expect(editor.state.activeTool, EditorToolType.eraser);
        await tester.tapAt(paintCell);
        await tester.pump();
        expect(_collisionAt(editor.state, 0, 0), isFalse);
        expect(
          _collisionCount(editor.state),
          2,
          reason: 'the erase footprint must remain exactly 1×1',
        );
        expect(_collisionAt(editor.state, 1, 0), isTrue);
        expect(_collisionAt(editor.state, 0, 1), isTrue);
        expect(editor.state.mapUndoStack, hasLength(2));
        expect(
          editor.state.isDirty,
          isFalse,
          reason: 'paint then exact erase restores the saved map',
        );

        await _activateFamily(tester, harness, 'layers');
        inspectorScrolls += await _activateLayerIfNeeded(tester, 'objects');
        expect(editor.state.activeLayerId, 'objects');

        await _activateFamily(tester, harness, 'place');
        expect(editor.state.activeTool, EditorToolType.tilePaint);
        editor.state = editor.state.copyWith(
          activeBrush: const EditorBrush.projectElement(elementId: 'tree'),
        );
        await tester.pump();
        final placementCell = _cellCenter(tester, const GridPos(x: 2, y: 2));
        await tester.tapAt(placementCell);
        await tester.pump();
        expect(editor.state.activeMap!.placedElements, hasLength(2));
        final placed = editor.state.activeMap!.placedElements.singleWhere(
          (entry) => entry.id != 'manual-tree',
        );
        expect(placed.elementId, 'tree');
        expect(placed.layerId, 'objects');
        expect(placed.pos, const GridPos(x: 2, y: 2));
        expect(editor.state.mapUndoStack, hasLength(3));
        expect(editor.state.isDirty, isTrue);

        await _activateFamily(tester, harness, 'selection');
        final manualCell = _cellCenter(tester, const GridPos(x: 4, y: 2));
        await tester.tapAt(manualCell);
        await tester.pump();
        expect(editor.state.selectedPlacedElementInstanceId, 'manual-tree');

        final drag = await tester.startGesture(
          manualCell,
          kind: ui.PointerDeviceKind.mouse,
        );
        await drag.moveBy(const Offset(32, 0));
        await tester.pump();
        await drag.up();
        await tester.pump();
        expect(
          _manualTree(editor.state).pos,
          const GridPos(x: 5, y: 2),
        );
        expect(editor.state.mapUndoStack, hasLength(4));
        expect(editor.state.isDirty, isTrue);

        const movedGridCell = GridPos(x: 5, y: 2);
        await _rightClickCell(tester, movedGridCell);
        await tester.tap(find.text('Rotation 90° horaire'));
        await tester.pump();
        expect(_manualTree(editor.state).quarterTurns, 1);
        expect(editor.state.mapUndoStack, hasLength(5));
        expect(editor.state.isDirty, isTrue);

        await tester.tap(
          find.byKey(const ValueKey<String>('world-map-command-undo')),
        );
        await tester.pump();
        expect(_manualTree(editor.state).quarterTurns, 0);
        expect(editor.state.mapUndoStack, hasLength(4));
        expect(editor.state.mapRedoStack, hasLength(1));
        expect(editor.state.isDirty, isTrue);

        await tester.tap(
          find.byKey(const ValueKey<String>('world-map-command-redo')),
        );
        await tester.pump();
        expect(_manualTree(editor.state).quarterTurns, 1);
        expect(editor.state.mapUndoStack, hasLength(5));
        expect(editor.state.mapRedoStack, isEmpty);
        expect(editor.state.isDirty, isTrue);

        await _rightClickCell(tester, movedGridCell);
        expect(find.text('Rotation 90° horaire'), findsOneWidget);
        expect(editor.state.mapUndoStack, hasLength(5));
        expect(editor.state.isDirty, isTrue);
        expect(
          inspectorScrolls,
          lessThanOrEqualTo(1),
          reason:
              'the essential journey allows at most one local inspector scroll',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'light preview label lets a valid canvas cell receive the pointer at '
    '1280×800',
    (tester) async {
      final harness = await _pumpJourney(tester, const Size(1280, 800));
      final editor = harness.notifier;
      await _activateFamily(tester, harness, 'layers');
      await _activateLayerIfNeeded(tester, 'collision');
      await _activateFamily(tester, harness, 'paint');

      final canvasGesture = find.byKey(
        const ValueKey<String>('map-canvas-gesture-detector'),
      );
      final canvasRect = tester.getRect(canvasGesture);
      final labelRect = tester.getRect(find.text('Aperçu lumière'));
      final cellRect = Rect.fromLTWH(
        canvasRect.left + editor.state.panOffset.dx,
        canvasRect.top + editor.state.panOffset.dy,
        32 * editor.state.zoom,
        32 * editor.state.zoom,
      );
      final overlap = labelRect.intersect(cellRect);
      expect(
        overlap.isEmpty,
        isFalse,
        reason: 'the regression requires the light label to cover cell 0,0',
      );
      final target = overlap.center;
      final canvasRenderObject = tester.renderObject(canvasGesture);
      final hitResult = tester.hitTestOnBinding(target);
      printOnFailure(
        'label target: label=$labelRect cell00=$cellRect overlap=$overlap '
        'global=$target hits=${hitResult.path.take(4).map(
              (entry) => entry.target.runtimeType,
            ).join(' > ')}',
      );
      expect(
        hitResult.path.any(
          (entry) => identical(entry.target, canvasRenderObject),
        ),
        isTrue,
        reason: 'the exact point inside the label must hit the map canvas',
      );

      expect(_collisionAt(editor.state, 0, 0), isFalse);
      await tester.tapAt(target);
      await tester.pump();
      expect(_collisionAt(editor.state, 0, 0), isTrue);
      expect(editor.state.mapUndoStack, hasLength(1));
      expect(editor.state.errorMessage, isNull);
    },
  );
}

Future<void> _rightClickCell(WidgetTester tester, GridPos cell) async {
  final gesture = await tester.startGesture(
    _cellCenter(tester, cell),
    kind: ui.PointerDeviceKind.mouse,
    buttons: kSecondaryButton,
  );
  await gesture.up();
  await tester.pump();
}

Future<int> _activateLayerIfNeeded(
  WidgetTester tester,
  String layerId,
) async {
  final scrollable = find.descendant(
    of: find.byKey(const ValueKey<String>('world-map-layer-list')),
    matching: find.byType(Scrollable),
  );
  final position = tester.state<ScrollableState>(scrollable).position;
  final beforeOffset = position.pixels;
  Finder active() => find.byKey(
        ValueKey<String>('world-map-layer-active-$layerId'),
      );
  Finder activation() => find.byKey(
        ValueKey<String>('world-map-layer-activate-$layerId'),
      );
  var scrollGestures = 0;
  if (active().evaluate().isEmpty && activation().evaluate().isEmpty) {
    await tester.drag(scrollable, const Offset(0, -240));
    await tester.pumpAndSettle();
    scrollGestures += 1;
  }
  if (active().evaluate().isNotEmpty) {
    return scrollGestures;
  }
  expect(activation(), findsOneWidget);
  if (activation().hitTestable().evaluate().isEmpty) {
    expect(scrollGestures, 0, reason: 'one local scroll gesture is the budget');
    await tester.ensureVisible(activation());
    await tester.pumpAndSettle();
    scrollGestures += 1;
  }
  if (scrollGestures > 0) {
    expect(position.pixels, isNot(beforeOffset));
  }
  await tester.tap(activation());
  await tester.pump();
  return scrollGestures;
}

Future<void> _activateFamily(
  WidgetTester tester,
  _JourneyHarness harness,
  String family,
) async {
  await tester.tap(
    find.byKey(ValueKey<String>('world-map-tool-$family')),
  );
  await tester.pumpAndSettle();
  expect(
    harness.container.read(worldMapWorkspaceSessionProvider).activeFamily.name,
    family,
    reason: '$family must activate in one click',
  );
}

Offset _cellCenter(WidgetTester tester, GridPos cell) {
  final origin = tester.getTopLeft(find.byType(MapCanvas));
  return origin + Offset(cell.x * 32 + 16, cell.y * 32 + 16);
}

bool _collisionAt(EditorState state, int x, int y) {
  final layer = state.activeMap!.layers
      .whereType<CollisionLayer>()
      .singleWhere((candidate) => candidate.id == 'collision');
  return layer.collisions[y * state.activeMap!.size.width + x];
}

int _collisionCount(EditorState state) {
  final layer = state.activeMap!.layers
      .whereType<CollisionLayer>()
      .singleWhere((candidate) => candidate.id == 'collision');
  return layer.collisions.where((value) => value).length;
}

MapPlacedElement _manualTree(EditorState state) =>
    state.activeMap!.placedElements
        .singleWhere((entry) => entry.id == 'manual-tree');

Future<_JourneyHarness> _pumpJourney(
  WidgetTester tester,
  Size size,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 64, 32),
    Paint()..color = const Color(0xFF5D8D36),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 32);
  picture.dispose();
  final harness = _JourneyHarness(image);
  addTearDown(harness.dispose);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  final session = harness.container.read(
    worldMapWorkspaceSessionProvider.notifier,
  );
  harness.notifier.state = harness.notifier.state.copyWith(
    activeLayerId: 'collision',
  );
  expect(
    session
        .activateTool(
          harness.notifier,
          const ActivateWorldMapPaint(WorldMapPaintSubtool.collision),
        )
        .accepted,
    isTrue,
  );
  harness.notifier.state = harness.notifier.state.copyWith(
    activeLayerId: 'objects',
  );
  expect(
    session
        .activateTool(
          harness.notifier,
          const ActivateWorldMapPlacement(WorldMapPlacementSubtool.object),
        )
        .accepted,
    isTrue,
  );
  expect(
    session
        .activateTool(harness.notifier, const ActivateWorldMapSelection())
        .accepted,
    isTrue,
  );
  harness.notifier.state = harness.notifier.state.copyWith(
    activeLayerId: 'objects',
    activeBrush: const EditorBrush.projectElement(elementId: 'tree'),
    selectedPlacedElementInstanceId: 'manual-tree',
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Material(
          child: WorldMapWorkspace(
            onTargetEditorRequested: (_) async {},
            toolSlot: WorldMapToolbelt(
              onSave: () {},
              onUndo: harness.notifier.undoMap,
              onRedo: harness.notifier.redoMap,
              onNewProject: () {},
              onOpenProject: () {},
              onProjectSettings: () {},
              onExportGame: () {},
              onNewMap: () {},
              onResizeMap: () {},
            ),
            stageHeaderSlot: const SizedBox(height: 36),
            explorerBuilder: (context, onCollapse) => Align(
              alignment: Alignment.topLeft,
              child: PokeMapButton(
                onPressed: onCollapse,
                size: PokeMapButtonSize.compact,
                child: const Text('Réduire'),
              ),
            ),
            explorerRailBuilder: (context, onReopen) => PokeMapIconButton(
              onPressed: onReopen,
              size: 36,
              tooltip: 'Rouvrir',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return harness;
}

final class _JourneyHarness {
  _JourneyHarness(ui.Image image)
      : container = ProviderContainer(
          overrides: <Override>[
            editorImageCacheProvider.overrideWith(
              (ref, projectRoot) => _ImmediateEditorImageCache(
                projectRoot,
                image,
              ),
            ),
          ],
        ),
        _image = image {
    keepAlive = container.listen<EditorState>(
      editorNotifierProvider,
      (_, __) {},
      fireImmediately: true,
    );
    notifier.state = _initialState;
  }

  final ProviderContainer container;
  final ui.Image _image;
  late final ProviderSubscription<EditorState> keepAlive;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  void dispose() {
    keepAlive.close();
    container.dispose();
    _image.dispose();
  }
}

final class _ImmediateEditorImageCache extends EditorImageCache {
  _ImmediateEditorImageCache(String sessionKey, this._image)
      : super(sessionKey: sessionKey);

  final ui.Image _image;

  @override
  Future<EditorImageLoadResult> load(
    String? path, {
    String variantKey = 'original',
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
    EditorImageBytesTransform? transformBytes,
  }) {
    return Future<EditorImageLoadResult>.value(
      EditorImageLoadResult.success(_image.clone()),
    );
  }
}

final _map = MapData(
  id: 'gate-6-map',
  name: 'Gate 6 realistic map',
  version: ProjectVersion.v3,
  visualStack: MapVisualStackConfig.canonicalV1,
  size: const GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Sol',
      tilesetId: 'village',
      tiles: List<int>.filled(64, 0, growable: false),
    ),
    TileLayer(
      id: 'objects',
      name: 'Éléments',
      tilesetId: 'village',
      tiles: List<int>.filled(64, 0, growable: false),
    ),
    CollisionLayer(
      id: 'collision',
      name: 'Collisions',
      collisions: <bool>[
        for (var index = 0; index < 64; index += 1) index == 1 || index == 8,
      ],
    ),
  ],
  placedElements: const <MapPlacedElement>[
    MapPlacedElement(
      id: 'manual-tree',
      layerId: 'objects',
      elementId: 'tree',
      pos: GridPos(x: 4, y: 2),
    ),
  ],
);

final _initialState = EditorState(
  projectRootPath: '/tmp/pokemap-gate-6-certification',
  activeMapPath: '/tmp/pokemap-gate-6-certification/maps/gate-6-map.json',
  project: const ProjectManifest(
    name: 'Gate 6 certification',
    version: ProjectVersion.v3,
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'gate-6-map',
        name: 'Gate 6 realistic map',
        relativePath: 'maps/gate-6-map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'village',
        name: 'Village',
        relativePath: 'assets/village.png',
      ),
    ],
    elements: <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'tree',
        name: 'Arbre défini',
        tilesetId: 'village',
        categoryId: 'vegetation',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
          ),
        ],
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
  ),
  workspaceMode: EditorWorkspaceMode.map,
  activeMap: _map,
  activeLayerId: 'objects',
  activeBrush: const EditorBrush.projectElement(elementId: 'tree'),
  selectedPlacedElementInstanceId: 'manual-tree',
  savedMapSnapshot: _map,
);
~~~~

### 15.2 `packages/map_editor/test/manual/world_map_gate_6_device_protocol.md`

~~~~markdown
# Gate 6 — Protocole manuel périphériques et VoiceOver

Ce protocole complète les tests Flutter automatisés. Il ne constitue pas une preuve d’exécution : chaque ligne reste `NOT_RUN` tant qu’une personne n’a pas réalisé le parcours sur le matériel indiqué et renseigné la date, la machine et le résultat.

## Projet et parcours de référence

- Projet : Selbrume, ou un projet réaliste équivalent comportant au moins un calque de tuiles, un calque de collisions et un calque d’objets.
- Parcours : ouvrir une carte, changer de calque, peindre une cellule, l’effacer, placer un asset PokeMap défini dans un tileset, le sélectionner, le déplacer d’une cellule, le tourner de 90°, annuler, rétablir, enregistrer, fermer puis rouvrir.
- Critère ergonomique : les outils principaux restent accessibles sans défilement ; chaque changement de contexte demande au plus un défilement local dans l’inspecteur.
- Critère de sécurité : un geste de navigation ne doit jamais peindre, effacer, déplacer ou placer un contenu.

## Matrice d’exécution physique

| ID | Matériel / aide | Scénario spécifique | Statut | Date | Machine / OS | Observations |
|---|---|---|---|---|---|---|
| G6-PHY-01 | Magic Mouse | Défilement vertical/horizontal, zoom avec modificateur, clic secondaire et parcours complet | NOT_RUN | — | — | À exécuter physiquement |
| G6-PHY-02 | Trackpad | Pan à deux doigts, pincement, clic secondaire et parcours complet | NOT_RUN | — | — | À exécuter physiquement |
| G6-PHY-03 | Souris 3 boutons | Molette, bouton milieu pour pan, clic droit et parcours complet | NOT_RUN | — | — | À exécuter physiquement |
| G6-PHY-04 | Clavier seul | Tab, flèches du canvas, Entrée/Espace, Shift+flèches, R, Menu/Shift+F10, Échap et parcours complet | NOT_RUN | — | — | À exécuter physiquement |
| G6-PHY-05 | VoiceOver macOS | Lecture de l’outil/calque actifs, curseur cellule, presets lumière, menu contextuel modal, erreurs et parcours complet | NOT_RUN | — | — | À exécuter physiquement |

## Profil performance macOS — VAL-04

Ce profil reste une certification physique distincte des budgets déterministes
du test Flutter. Aucun chiffre CPU, GPU, frame timing ou mémoire ne doit être
recopié depuis une exécution debug ni estimé : les cellules restent `—` tant
qu'une session `--profile` réelle n'a pas été enregistrée.

Préparation :

1. Depuis `packages/map_editor`, lancer `flutter run -d macos --profile` et
   ouvrir Flutter DevTools Performance et Memory.
2. Ouvrir Selbrume ou une copie réaliste équivalente comportant une carte
   128 × 128 ou plus, plusieurs calques visibles, des collisions et des assets
   PokeMap multi-tuiles.
3. Noter le modèle du Mac, la version de macOS, le commit testé, le moniteur,
   sa définition, son DPR et la version Flutter. Ne pas mélanger deux machines
   ou deux configurations d'écran dans une même ligne.
4. Après deux minutes de chauffe, remettre à zéro les enregistrements DevTools.

Parcours mesuré, à exécuter une fois sur écran Retina puis une fois sur écran
non-Retina ou externe à DPR 1 :

1. Pendant dix minutes, alterner pan molette/trackpad, pan bouton milieu,
   zoom ancré sous le pointeur et survol continu des quatre quadrants.
2. Pendant dix minutes supplémentaires, alterner sélection, drag d'un objet
   défini, rotation, peinture/effacement d'une cellule, undo/redo, puis revenir
   à la navigation. Vérifier que la navigation seule ne crée aucune entrée
   d'historique et ne salit pas le document.
3. Capturer séparément les timelines UI/raster, le résumé CPU/GPU fourni par
   les outils, et les valeurs mémoire au début, au pic et après deux minutes
   d'inactivité. Joindre les captures ou leur chemin d'artefact.
4. Relever tout jank visible, image manquante, ordre de couche incorrect,
   saut mémoire non résorbé ou dégradation progressive. Ne pas convertir une
   observation subjective en mesure chiffrée.

| ID | Affichage | Statut | Date | Machine / OS / Flutter | CPU | GPU / frames UI-raster | Mémoire début / pic / fin | Artefacts / observations |
|---|---|---|---|---|---|---|---|---|
| G6-PERF-01 | Retina, DPR 2 | NOT_RUN | — | — | — | — | — | Profil physique requis |
| G6-PERF-02 | Non-Retina / externe, DPR 1 | NOT_RUN | — | — | — | — | — | Profil physique requis |

## Formats d’écran à couvrir

Répéter au minimum le parcours sur :

- 800 × 600, DPR 2, thème clair ;
- 800 × 600, DPR 2, thème sombre ;
- 1280 × 800, DPR 2, thème clair ;
- 1280 × 800, DPR 2, thème sombre.

## Règle de clôture

Gate 6 ne peut être déclaré entièrement validé que lorsque les sept lignes
`G6-PHY-01` à `G6-PHY-05` et `G6-PERF-01` à `G6-PERF-02` portent un résultat
humain daté. Les tests automatisés peuvent certifier les invariants
reproductibles, mais ne remplacent ni le ressenti d’un périphérique physique,
ni la restitution réelle de VoiceOver, ni un profil macOS en mode profile.
~~~~
