# NS-EVENT-V2 — Phase G — Map Editor Integration — Rapport de clôture V0

## 1. Verdict exécutif

```text
Date d'audit : 2026-07-16
Branche : main
HEAD audité : 2f68328a38bf218c843e497940f8dd24a7a9c194

NS-EVENT-V2-23 : PASS fonctionnel
NS-EVENT-V2-24 : PASS fonctionnel
NS-EVENT-V2-25 : PASS fonctionnel après correctifs TDD

Phase G : IMPLEMENTATION FUNCTIONAL PASS / PHASE G FORMAL CLOSURE BLOCKED
```

La mission **Phase G — Map Editor Integration**, jalons
`NS-EVENT-V2-23` à `NS-EVENT-V2-25`, est fonctionnellement implémentée et sa
matrice ciblée finale est verte à **410/410**. Le pont relie une source
physique réelle du Map Editor à un Event V2, permet le focus et le retour exact,
et journalise la création d'une source manquante entre le commit map et le
commit du registre Event.

La Phase G n'est toutefois **pas déclarée `CLOSED / ACCEPTED`**. Trois gates
du plan de clôture restent objectivement rouges ou non prouvés :

1. le Visual Gate desktop réel est bloqué par Computer Use (`-10005`, puis
   `SCStreamErrorDomain Code=-3811`) ;
2. la suite complète `map_editor` termine à `+2963 -98` ;
3. l'analyse complète `map_editor` termine avec 451 diagnostics.

Le build macOS debug passe, le format des 32 fichiers Phase G ne produit aucun
changement et l'analyse directe des 32 items Phase G ne produit aucun
diagnostic. Ces preuves autorisent le verdict **functional pass**, mais pas une
clôture formelle contraire aux exit gates écrits.

Le détail reproductible, les hashes et le contenu complet des fichiers créés
se trouvent dans l'[Evidence Pack Phase G](ns_event_v2_phase_g_evidence_pack.md).
Les deux rapports Phase G eux-mêmes sont exclus des annexes de contenu afin
d'éviter une récursion documentaire.

## 2. Nom exact du lot, scope et décision sur la demande

- Mission roadmap : `Phase G — Map Editor Integration`.
- Jalons : `NS-EVENT-V2-23`, `NS-EVENT-V2-24`, `NS-EVENT-V2-25`.
- Package modifié : `packages/map_editor` uniquement.
- Demande interprétée : fermer proprement la Phase G déjà implémentée avant de
  poursuivre la séquence, en corrigeant les vrais blockers découverts par
  audit et en produisant les preuves attendues.

La demande était cohérente avec la roadmap, mais « fermer » ne pouvait pas être
interprété comme une autorisation de marquer la phase `CLOSED` sans preuves.
L'audit initial a établi que le code des trois jalons existait déjà dans le
worktree, alors que le rapport, l'Evidence Pack et le Visual Gate manquaient.
Une revue contradictoire V2-25 a ensuite trouvé deux défauts fonctionnels malgré
des tests ciblés déjà verts. L'interprétation retenue a donc été la plus petite
et la plus sûre :

- corriger seulement les deux défauts Phase G confirmés ;
- ajouter leurs régressions TDD ;
- relancer les gates ciblés et globaux ;
- documenter sans maquiller les blockers externes ou visuels ;
- ne modifier ni Git, ni roadmap, ni les chantiers voisins.

## 3. Règles, plans et roadmaps consultés

- `AGENTS.md` ;
- `codex_rule.md` ;
- `pokemap_roadmap_mecaniques_fangame.md` ;
- `MVP Selbrume/road_map_event_builder_v2.md` ;
- `docs/superpowers/plans/2026-07-15-event-builder-phase-g-map-bridge.md` ;
- les contrats Event V2 et les tests déjà présents dans `map_editor` ;
- les workflows locaux `subagent-driven-development`,
  `test-driven-development`, `requesting-code-review` et
  `verification-before-completion` ;
- le workflow Product Design Audit et Computer Use pour le Visual Gate.

Lots gameplay associés consultés : `FG-080`, `FG-081`, `FG-082`, `FG-093`,
`FG-183`, `FG-185`. Ils restent tous **`TODO`**. La Phase G n'implémente pas à
elle seule le command model gameplay, le builder complet, l'exécution runtime
globale, la matrice release ou le release gate fangame.

## 4. État Git initial et hygiène du worktree

État au début de la passe de clôture :

```text
Répertoire : /Users/karim/Project/pokemonProject
Branche : main
HEAD : 2f68328a38bf218c843e497940f8dd24a7a9c194
Tracked modified : 42
Untracked : 81
Total : 123
packages/map_editor/test/failures : absent
selbrume/*.lock : absent
```

Le worktree était déjà très agrégé : Phases F2, G, H, I, J, K et L y
coexistaient sans commit. Ces changements préexistants appartiennent à
l'utilisateur et ont été préservés. Aucune commande Git d'écriture n'a été
exécutée : pas de branche, worktree, add, commit, reset, restore, stash ou
push.

Les suites complètes ont généré 92 PNG sous
`packages/map_editor/test/failures/` et le lock
`selbrume/.pokemap-project-1f1a60297a27b0b0.lock`. Ces 93 artefacts étaient
absents de la baseline ; ils ont été inventoriés puis supprimés après arrêt de
l'application de validation. Avant création des deux rapports, le worktree
était revenu exactement à **42 tracked modifiés + 81 non suivis = 123**.

## 5. Audit initial

### 5.1 Contrats et implémentations déjà présents

L'audit a retrouvé :

- une identité spatiale unique `NarrativeEventSourceRef`, sans couple de
  champs libres map/source ;
- un intent de création source-first et la détection des liens existants ;
- une garde de dépendance pour les IDs map, entity et trigger ;
- un état de bridge séparé d'`EditorState`, avec token de retour, focus et
  modes `view`, `choose`, `create` ;
- un focus caméra one-shot et un highlight du vrai owner ;
- une proposition physique pure, sans mutation du document avant confirmation ;
- un journal durable `prepared → mapCommitted → eventCommitted` ;
- un commit map CAS/hash/rename, puis un commit du registre Event ;
- des chemins retry, cleanup et interlock ;
- l'intégration Map Inspector, Event workspace, MapCanvas et design system ;
- des tests unitaires, widget et infrastructure couvrant les trois jalons.

### 5.2 Risques identifiés

- un outil retained du Map Editor pouvait encore recevoir un drag pendant un
  mode guidé Event ;
- un gate dirty/saving pouvait effacer de l'état mémoire l'identité exacte
  d'une récupération durable ;
- la concurrence entre map write normal, cleanup et reload devait rester
  sérialisée ;
- un retour pouvait mentir en sélectionnant un autre Event ou une source stale ;
- un succès ciblé pouvait masquer des gates package ou visuels rouges ;
- le worktree agrégé rendait toute réécriture large dangereuse.

### 5.3 Frontières conservées

- aucun contrat wire ou modèle Event V2 de `map_core` modifié ;
- aucun bridge runtime modifié ;
- aucune création d'une source physique dans l'Event Builder ;
- aucun picker indépendant map/layer/coordonnées/source ;
- aucune `EventPosition` V2 ;
- aucun raw tile source ou `warpAttempt` V1 ;
- aucune promesse d'atomicité multi-fichiers ;
- aucun traitement des 98 échecs et 451 diagnostics étrangers ;
- aucune modification de la roadmap sans demande explicite.

## 6. Verdicts des sous-agents et passes séparées

| Passe | Rôle requis | Verdict | Preuve / conséquence |
|---|---|---|---|
| Audit V2-23 | Audit / Architecture | `PASS` | 56 tests ciblés ; 11 fichiers analysés sans diagnostic |
| Audit V2-24 | Audit / Architecture | `PASS fonctionnel` | 32 tests ciblés ; 11 fichiers analysés sans diagnostic |
| Audit V2-25 initial | Audit / Critique | `CHANGES_REQUIRED` | drag guidé non gardé ; recovery durable perdue sous dirty/saving ; copies divergentes |
| Correctif drag | Implémentation / TDD | `PASS` | deux régressions observées RED puis GREEN |
| Revue drag spec | Revue conformité | `PASS` | les quatre callbacks pan sont gardés avant toute mutation |
| Revue drag qualité | Critique | `PASS` | le test RED exclut un faux positif ; outils partagent la même frontière |
| Correctif recovery | Implémentation / TDD | `PASS` | retry et cleanup × trois gates ; copies exactes |
| Revue recovery spec | Revue conformité | `PASS` | journal, inspection et token exacts conservés |
| Revue recovery qualité | Critique | `PASS` avec limite mineure | matrice contrôleur complète ; pas de matrice widget dirty/saving dédiée |
| Matrice finale | Tests | `PASS` | `+410: All tests passed!` |
| Analyse/format ciblés | Build / Validation | `PASS` | 32 items, 0 diagnostic ; 32 fichiers, 0 changement |
| Build macOS debug | Build / Validation | `PASS` | bundle debug produit |
| Suite/analyse complètes | Build / Validation | `BLOCKED` | `+2963 -98` ; 451 diagnostics |
| Visual Gate desktop | Product audit | `BLOCKED` | `-10005 timeoutReached`, puis ScreenCaptureKit `-3811` |
| Critique finale initiale | Critique finale | `CHANGES_REQUIRED` sur les preuves | code ciblé sans blocker confirmé ; hash tronqué, commandes abrégées, traces transactionnelles et attestation roadmap manquantes |
| Corrections post-critique | Tests / Documentation | `PASS local` | traces ajoutées et vertes ; hashes, commandes, annexe et attestation régénérés |
| Contre-lecture corrective | Critique finale | `PASS` | quatre findings initiaux corrigés ; 26/26 annexes et hashes vérifiés ; aucun nouveau Important confirmé |

La première passe V2-25 est importante : ses 103 tests ciblés passaient, mais
la revue a tout de même trouvé deux comportements réellement incorrects. La
clôture ne repose donc pas sur le seul nombre de tests.

## 7. Résultat par jalon

### 7.1 NS-EVENT-V2-23 — Map Selection to Event Creation Bridge V0

Statut : **PASS fonctionnel**.

- une source entity, trigger ou map est transmise comme une référence atomique ;
- un draft V2 est créé avec cette source, en une seule écriture registre ;
- les liens existants incluent drafts, configured enabled et disabled, avec
  ordre déterministe ;
- créer un Event additionnel exige une action explicite ;
- dirty map, dirty project et save en cours bloquent avant toute préparation ;
- un résultat stale ou rejeté ne déclenche aucune duplication ;
- le registre déjà persisté est synchronisé en mémoire sans modifier map,
  sélection, dirty state ou historique ;
- rename/delete/kind incompatibles d'une source liée sont bloqués ;
- l'ancien `MapEventDefinition` reste séparé et marqué legacy.

Critères no-code confirmés : aucun `layerId`, aucune coordonnée, aucun ID brut
et aucune deuxième sélection de map ne sont demandés après l'action source.

### 7.2 NS-EVENT-V2-24 — See/Choose on Map Focus & Return Flow V0

Statut : **PASS fonctionnel**.

- le token conserve l'Event exact et son `NarrativeEventGroupContext` ;
- une navigation même-map ne recharge pas le document et préserve dirty,
  sélection, viewport et undo/redo ;
- une navigation cross-map dirty est refusée avant toute lecture ;
- une navigation cross-map clean lit une seule snapshot, revalide l'owner,
  active la map puis sélectionne la source exacte ;
- le focus entity/trigger porte des bounds exacts ; `mapEnter` couvre toute la
  map sans owner artificiel ;
- chaque request ID de caméra est consommé une fois ; un pan utilisateur
  ultérieur n'est pas écrasé ;
- le retour ne retombe jamais sur le premier Event si l'Event exact manque ;
- une source non spatiale n'affiche aucun CTA carte.

### 7.3 NS-EVENT-V2-25 — Explicit Spatial Source Creation V0

Statut : **PASS fonctionnel après TDD**.

- propositions PNJ, panneau, objet, élément invisible et zone Event 1×1 ;
- proposition pure : map active, dirty, historique et sélection inchangés ;
- l'élément invisible est une entity `custom` non bloquante ;
- la zone est un vrai `MapTrigger` Event 1×1 ;
- aucun `MapEvent` legacy et aucune `EventPosition` V2 ne sont créés ;
- ordre durable : journal prepared, map commit CAS/hash/rename, journal
  mapCommitted, session Event fraîche, registry commit, eventCommitted,
  acquittement ;
- une panne entre les commits conserve la source et le journal exacts ;
- retry lie la même source sans recréer owner ou Event ;
- cleanup exige confirmation, owner identique et fingerprint inchangé ;
- cleanup refuse un owner modifié ou déjà revendiqué ;
- les interlocks empêchent qu'un write/reload concurrent ressuscite l'owner ;
- dirty/saving conserve l'identité durable et interdit Annuler/Retour ;
- les copies produit sont exactement `Annuler` et `Enregistrer et lier`.

## 8. Correctifs TDD de la passe de clôture

### 8.1 Garde de drag en mode guidé

Tests ajoutés dans
`packages/map_editor/test/map_canvas_narrative_event_focus_test.dart` :

- `create mode ignores a tile-paint drag` ;
- `choose mode ignores a gameplay-zone drag`.

Preuve RED :

```bash
cd packages/map_editor
flutter test test/map_canvas_narrative_event_focus_test.dart \
  --plain-name 'NS-EVENT-V2-25 guided map drag guard'
```

```text
exit 1
+0 -2
la tuile 7 était peinte à l'index 215
une MapGameplayZone était créée en (11, 7)
```

Découpage précis du correctif dans `map_canvas.dart` :

```diff
+ final isNarrativeEventGuidedNavigation =
+     bridgeState.pendingReturn != null &&
+     (bridgeState.navigationMode == NarrativeEventMapNavigationMode.create ||
+      bridgeState.navigationMode == NarrativeEventMapNavigationMode.choose);

  onPanStart: (details) {
+   if (isNarrativeEventGuidedNavigation) return;
    ...
  }
  onPanUpdate: (details) {
+   if (isNarrativeEventGuidedNavigation) return;
    ...
  }
  onPanEnd: (_) {
+   if (isNarrativeEventGuidedNavigation) return;
    ...
  }
  onPanCancel: () {
+   if (isNarrativeEventGuidedNavigation) return;
    ...
  }
```

Preuve GREEN : test par nom `+2`, fichier complet `+7`, analyse des deux
fichiers sans diagnostic et `git diff --check` ciblé à exit 0.

### 8.2 Conservation de la récupération durable

Tests ajoutés dans
`packages/map_editor/test/narrative_event_source_creation_recovery_test.dart` :

- retry sous `mapDirty`, `projectDirty`, `saveInProgress` ;
- cleanup sous les trois mêmes gates ;
- identité `same(...)` du journal et de l'inspection ;
- zéro IO durable additionnelle ;
- token exact conservé ; Annuler, Retour et nouveau choix refusés.

Preuve RED : deux tests échouaient car le résultat était `blocked` au lieu de
`recoveryRequired` pour le premier cas `mapDirty`; les 26 tests précédents
passaient.

Découpage précis du correctif dans
`narrative_event_map_bridge_state.dart` :

```diff
  const transientCodes = {
    'inspectionException',
    'sourceInspectionException',
    'registryInspectionException',
    'registryRecoveryException',
    'cleanupException',
+   'mapDirty',
+   'projectDirty',
+   'saveInProgress',
  };
```

Le second comportement décrit en prose — il ne s'agit pas d'un commentaire
présent dans le fichier — conserve exactement le journal et l'inspection
`recoveryRequired` précédents quand le résultat entrant n'apporte aucune
identité durable. Le code et le message du gate entrant expliquent honnêtement
pourquoi l'action n'a pas été exécutée.
Résultat GREEN : `narrative_event_source_creation_recovery_test.dart` termine
à `+28`.

### 8.3 Copies produit exactes

Le test widget de la CTA source-less a été vu RED avec l'absence de `Annuler`.
Les deux remplacements sont localisés dans
`narrative_event_map_banner.dart` :

```diff
- Annuler l'aperçu
+ Annuler

- Créer et lier
+ Enregistrer et lier
```

Le test vérifie aussi l'absence des anciens libellés. Le fichier banner complet
termine à `+16`.

## 9. Inventaire complet des fichiers Phase G

### 9.1 Production créée — 14 fichiers

| Fichier | Classes / fonctions / zones | Raison et impact attendu |
|---|---|---|
| `packages/map_editor/lib/src/application/models/narrative_event_map_bridge_models.dart` | `NarrativeEventGroupContext`, modes, return token, focus request, creation intent/results | Contrats typés du bridge ; aucune identité spatiale partielle |
| `packages/map_editor/lib/src/application/models/narrative_event_spatial_link_journal_models.dart` | états/checkpoints du journal, commit request, journal, inspection, operation result | Schéma strict et inspectable entre les deux commits |
| `packages/map_editor/lib/src/application/models/narrative_event_spatial_source_creation_models.dart` | `NarrativeEventPhysicalSourceKind`, `NarrativeEventCreatedSourceProposal` | Porte before/after map, bounds, owner JSON et fingerprint sans muter l'éditeur |
| `packages/map_editor/lib/src/application/ports/narrative_event_spatial_source_creation_gateway.dart` | `commitMap`, `inspectProject`, `recoverProject`, `mark/acknowledge`, `cleanupSource` | Frontière testable pour CAS, recovery et cleanup durable |
| `packages/map_editor/lib/src/application/services/map_focus_viewport_resolver.dart` | `resolveMapFocusPanOffset`, `resolveNarrativeEventMapFocusBounds` | Centrage pur, zoom préservé et full-map bounds pour `mapEnter` |
| `packages/map_editor/lib/src/application/services/narrative_event_source_dependency_guard.dart` | décisions et inspections map/entity/trigger/transition | Empêche de casser une identité déjà référencée par un Event V2 |
| `packages/map_editor/lib/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart` | preflight, exact links, draft, write unique | Création/open source-first, gates avant session, aucune duplication |
| `packages/map_editor/lib/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart` | `inspect`, `createAndLink`, `retry`, `cleanup`, `acknowledge` | Orchestration map-first/registry-second et récupération honnête |
| `packages/map_editor/lib/src/application/use_cases/narrative_event_spatial_source_link_use_case.dart` | select/replace/no-op/persist | Lie ou remplace une source atomique sur le draft exact |
| `packages/map_editor/lib/src/features/narrative/state/narrative_event_map_bridge_state.dart` | état/controller, navigation, proposal, retry, cleanup, retour, busy ownership | État transitoire hors historique map ; cohérence project/token/journal |
| `packages/map_editor/lib/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart` | paths sûrs, journal flush/rename, hash/CAS, inspection/recovery/cleanup | Persistance crash-recoverable et fail-closed |
| `packages/map_editor/lib/src/ui/canvas/events/narrative_event_map_return_panel.dart` | `NarrativeEventMapReturnPanel` | Actions Event → Map et résumé source exact |
| `packages/map_editor/lib/src/ui/canvas/map_canvas/narrative_event_map_banner.dart` | banner modes view/choose/create/recovery | UX guidée, confirmation, retry/cleanup et copies exactes |
| `packages/map_editor/lib/src/ui/panels/narrative_event_map_bridge_panel.dart` | actions map/entity/trigger, existing links, recovery | Entrée no-code depuis le vrai Map Inspector, legacy séparé |

### 9.2 Production intégrée — 6 fichiers

| Fichier | Zones modifiées | Raison et impact attendu |
|---|---|---|
| `packages/map_editor/lib/src/app/providers/core/repository_providers.dart` | providers `FileProjectRepository`, registry gateway, spatial gateway | Réutilise la même repository registry et compose le journal gateway |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | registry sync, focus, proposal, adoption, leases/interlocks, dependency guard, undo/redo | Branche le bridge sur le vrai document tout en protégeant dirty, history et concurrence |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | branche `EditorWorkspaceMode.events` | Insère le return panel au-dessus du workspace Event existant |
| `packages/map_editor/lib/src/ui/canvas/map_canvas.dart` | tap guidé, garde pan, banner, focus caméra one-shot | Sélection/création sur le vrai canvas sans fuite vers les outils retained |
| `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart` | champs focus/proposal, paint highlight, `shouldRepaint` | Rend le vrai owner ou la proposition sans fausse sélection |
| `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart` | bridge panel ; section legacy renommée | Expose la source-first action et distingue le système historique |

### 9.3 Tests créés — 12 fichiers

| Fichier | Couverture positive, négative et non-régression |
|---|---|
| `packages/map_editor/test/narrative_event_map_creation_bridge_test.dart` | entity/trigger/map, existing links, dirty/saving, stale, exception, registry merge |
| `packages/map_editor/test/narrative_event_source_dependency_guard_test.dart` | rename/delete/kind, transitions, unlinked, undo/redo |
| `packages/map_editor/test/ui/panels/narrative_event_map_bridge_panel_test.dart` | actions éligibles, absence de picker/ID, existing links, legacy |
| `packages/map_editor/test/event_map_navigation_controller_test.dart` | même/cross-map, missing/nonspatial, exact return, stale project, one-shot |
| `packages/map_editor/test/map_focus_viewport_resolver_test.dart` | bounds, zoom, full map, map mismatch |
| `packages/map_editor/test/event_builder_map_focus_return_flow_test.dart` | CTA, choose, confirm, retour au draft exact |
| `packages/map_editor/test/map_canvas_narrative_event_focus_test.dart` | highlight, hit-test, repaint, caméra et garde de drag create/choose |
| `packages/map_editor/test/narrative_event_spatial_link_journal_repository_test.dart` | commit, CAS, crash, symlink, cleanup, owner/reference concurrente |
| `packages/map_editor/test/narrative_event_explicit_source_creation_test.dart` | cinq propositions, pureté, IDs, bounds, fingerprint, adoption stale |
| `packages/map_editor/test/narrative_event_source_creation_recovery_test.dart` | deux commits, retry, cleanup, races, exact journal et gates dirty/saving |
| `packages/map_editor/test/narrative_event_spatial_source_link_use_case_test.dart` | select/replace/no-op, disabled, nonspatial, dirty/saving, stale |
| `packages/map_editor/test/ui/canvas/narrative_event_map_banner_test.dart` | UX create/confirm/recovery, leases, cleanup, concurrence et copies |

Les contenus complets de ces **26 fichiers créés** sont annexés dans
l'Evidence Pack, avec un manifeste de hashes. Les six fichiers de production
intégrés étant modifiés et non créés, leurs zones précises sont décrites dans
les tableaux ci-dessus et dans les diffs. Les deux rapports sont exclus de
l'annexe pour éviter qu'ils ne s'incluent récursivement eux-mêmes.

### 9.4 Documentation créée par la clôture — 2 fichiers

| Fichier | Zone / raison | Impact attendu |
|---|---|---|
| `reports/narrativeStudio/events/ns_event_v2_phase_g_map_editor_bridge_closure_v0.md` | présent rapport, verdict, inventaire, commandes et critique | Rend le statut fonctionnel et les blockers formels explicites |
| `reports/narrativeStudio/events/ns_event_v2_phase_g_evidence_pack.md` | preuves détaillées, hashes et annexe des contenus complets | Rend la validation reproductible sans dupliquer 20 848 lignes dans le rapport principal |

Le contenu complet du premier fichier est le présent document ; celui du
second est directement disponible par le lien en section 1. Leur exclusion de
l'annexe générée est le seul moyen d'éviter une inclusion récursive sans fin.

## 10. Commandes de tests et résultats exacts

### 10.1 Baseline ciblée avant les correctifs

La première matrice de 20 fichiers terminait à :

```text
exit 0
+380: All tests passed!
real 36.61s
```

Elle ne couvrait pas encore les régressions trouvées par la revue V2-25.

### 10.2 Matrice Phase G finale

Commande exécutée depuis `packages/map_editor` :

```bash
flutter test --no-pub --reporter=compact --concurrency=1 \
  test/narrative_event_map_creation_bridge_test.dart \
  test/narrative_event_source_dependency_guard_test.dart \
  test/ui/panels/narrative_event_map_bridge_panel_test.dart \
  test/event_builder_draft_creation_notifier_test.dart \
  test/event_builder_workspace_test.dart \
  test/event_map_navigation_controller_test.dart \
  test/map_focus_viewport_resolver_test.dart \
  test/event_builder_map_focus_return_flow_test.dart \
  test/map_canvas_narrative_event_focus_test.dart \
  test/map_canvas_pointer_navigation_test.dart \
  test/editor_workspace_controller_test.dart \
  test/editor_project_session_controller_test.dart \
  test/narrative_event_spatial_link_journal_repository_test.dart \
  test/narrative_event_explicit_source_creation_test.dart \
  test/narrative_event_source_creation_recovery_test.dart \
  test/narrative_event_spatial_source_link_use_case_test.dart \
  test/ui/canvas/narrative_event_map_banner_test.dart \
  test/map_canvas_entity_properties_smoke_test.dart \
  test/event_registry_recovery_test.dart \
  test/event_registry_recovery_gate_test.dart \
  test/event_registry_repository_test.dart
```

Résultat frais :

```text
exit 0
+410: All tests passed!
real 48.10s
```

### 10.1 Empreintes avant/après des chemins durables

Les tests de la matrice émettent désormais trois traces JSON. Les commandes
`--plain-name`, les JSON bruts et l'interprétation complète figurent en section
15.1 de l'Evidence Pack.

| Scénario / étape | Hash map | Hash manifest | Journal |
|---|---|---|---|
| Annulation — avant | `6c126579ffc20248d1d8702d4e71a5eca864fe7202ec0463dd3a5d629a9854bf` | `bd0a6d7c0f2a5e4fe956871360f9d353b4616a63e316529a02b335c4d7b4775c` | absent |
| Annulation — après | identique | identique | absent |
| Transaction — avant | `625871bf887874b8f85534de40e1ce02ad6597700711af01aa610d40c1e7446e` | `59edd1f1f36814024ac5542e4f88b4d3b726bb00d294e29b65b29153f84bd2ea` | absent |
| Après commit map | `ba95794f0528827c54499b007c1c18cdf672b83e5b318156221eafbaad6ad247` | inchangé | `mapCommitted` |
| Après retry | inchangé depuis commit map | `2a0774047abc1c99d0469c69d3f2b546483acf726a874a1eae5cd141feaffc03` | `eventCommitted`, puis clear après acquittement |
| Après cleanup | `4907d7d3e6e551e9cd62c454b1337df5e84da4e45aea17281dbceb4287e7213b` | inchangé depuis avant | clear, `entities: 0` |

L'annulation compare le JSON canonique de l'état en mémoire et vérifie zéro
appel aux gateways. Retry et cleanup relisent les octets disque. Le cleanup
restaure le `MapData` complet, mais sa re-sérialisation normalise le JSON ; le
hash binaire final peut donc différer du fichier initial sans différence de
modèle.

## 11. Analyse, format et contrôle de diff

Analyse directe des 20 fichiers production/intégration et 12 tests Phase G,
soit **32 items**. La liste et les commandes ci-dessous sont celles réellement
relancées ; aucun placeholder n'est nécessaire pour les reproduire.

```zsh
cd packages/map_editor
phase_g_files=(
  lib/src/application/models/narrative_event_map_bridge_models.dart
  lib/src/application/models/narrative_event_spatial_link_journal_models.dart
  lib/src/application/models/narrative_event_spatial_source_creation_models.dart
  lib/src/application/ports/narrative_event_spatial_source_creation_gateway.dart
  lib/src/application/services/map_focus_viewport_resolver.dart
  lib/src/application/services/narrative_event_source_dependency_guard.dart
  lib/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart
  lib/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart
  lib/src/application/use_cases/narrative_event_spatial_source_link_use_case.dart
  lib/src/features/narrative/state/narrative_event_map_bridge_state.dart
  lib/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart
  lib/src/ui/canvas/events/narrative_event_map_return_panel.dart
  lib/src/ui/canvas/map_canvas/narrative_event_map_banner.dart
  lib/src/ui/panels/narrative_event_map_bridge_panel.dart
  lib/src/app/providers/core/repository_providers.dart
  lib/src/features/editor/state/editor_notifier.dart
  lib/src/ui/canvas/narrative_workspace_canvas.dart
  lib/src/ui/canvas/map_canvas.dart
  lib/src/ui/canvas/map_canvas/map_grid_painter.dart
  lib/src/ui/panels/map_inspector_panel.dart
  test/narrative_event_map_creation_bridge_test.dart
  test/narrative_event_source_dependency_guard_test.dart
  test/ui/panels/narrative_event_map_bridge_panel_test.dart
  test/event_map_navigation_controller_test.dart
  test/map_focus_viewport_resolver_test.dart
  test/event_builder_map_focus_return_flow_test.dart
  test/map_canvas_narrative_event_focus_test.dart
  test/narrative_event_spatial_link_journal_repository_test.dart
  test/narrative_event_explicit_source_creation_test.dart
  test/narrative_event_source_creation_recovery_test.dart
  test/narrative_event_spatial_source_link_use_case_test.dart
  test/ui/canvas/narrative_event_map_banner_test.dart
)
flutter analyze --no-pub "${phase_g_files[@]}"
dart format --output=none --set-exit-if-changed "${phase_g_files[@]}"
```

```text
exit 0
items=32
Analyzing 32 items...
No issues found! (ran in 4.3s)
real 5.05s
```

```text
exit 0
items=32
Formatted 32 files (0 changed) in 0.23 seconds.
real 0.27s
```

Contrôle whitespace :

```text
git diff --check : exit 0
26 fichiers non suivis contrôlés par diff --no-index --check : 0 erreur
```

Un superset de 44 items, incluant des régressions adjacentes, retourne dix
informations `prefer_const_constructors` dans
`test/editor_project_session_controller_test.dart`. Elles ne ciblent aucun
fichier Phase G direct et ne modifient pas le résultat de l'analyse directe.

## 12. Build macOS

```bash
cd packages/map_editor
flutter build macos --debug --no-pub
```

```text
exit 0
Built build/macos/Build/Products/Debug/map_editor.app
real 25.18s
```

Le bundle debug est donc constructible avec les changements agrégés présents.

## 13. Gates package complets

### 13.1 Suite complète `map_editor`

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact
```

```text
exit 1
+2963 -98: Some tests failed.
real 325.93s
98 lignes [E]
98 commandes de relance
```

Les premières racines observées incluent :

- `scene_cinematic_picker_test.dart`, screenshot V1-39 ; lors d'une passe, le
  diff golden observé était de 1,09 %, soit 22 593 pixels ;
- `pokemap_topbar_migration_test.dart`, dark theme ;
- `pokemap_sidebar_item_test.dart`, selected styles ;
- `pokemap_right_inspector_resize_test.dart` ;
- `narrative_event_authoring_snapshot_performance_test.dart` ;
- `encounter_tables_panel_test.dart` ;
- des goldens Facts, World Rules, Storylines, Scenes et Shadows.

Les 21 fichiers de la matrice Phase G passent ensemble. Le package complet
reste néanmoins rouge ; ce rapport ne prétend ni avoir catalogué ni corrigé
les 98 échecs. Leur traitement dépasserait le lot et risquerait d'écraser les
Phases H à L présentes dans le même worktree.

### 13.2 Analyse complète `map_editor`

```bash
cd packages/map_editor
flutter analyze --no-pub
```

```text
exit 1
451 issues found. (ran in 4.5s)
451 lignes diagnostics
0 ligne visant les fichiers Phase G directs
real 5.27s
```

Les diagnostics globaux se trouvent hors de la liste directe Phase G. Leur
correction n'est pas absorbée silencieusement dans ce lot.

## 14. Visual Gate réel

Le gate a été tenté sur une copie temporaire de l'application portant un nom
et un bundle ID uniques, afin d'éviter un conflit avec une autre app issue d'un
worktree. Le vrai projet Selbrume n'a pas été manipulé.

Premier parcours :

```text
copie unique lancée
→ fenêtre AX réelle
→ « Ouvrir un projet »
→ picker macOS
→ sélection explicite de /tmp/pokemap_phase_g_visual.HyeyA6
→ Open
→ -10005 timeoutReached
```

Seconde tentative :

```text
picker ouvert
→ Cancel pour fallback texte
→ com.apple.ScreenCaptureKit.SCStreamErrorDomain Code=-3811
  Failed to start stream due to audio/video capture failure
```

L'app a été quittée via Computer Use. La fixture temporaire est restée
byte-identique à la fixture repo ; `diff -rq` n'a retourné aucune différence et
les trois SHA-256 consignés dans l'Evidence Pack sont inchangés.

Aucune capture n'a été inventée. Les cinq flows suivants restent donc sans
preuve visuelle desktop réelle :

- source sélectionnée → create/open Event V2 ;
- Event → focus entity/trigger/map ;
- retour au draft exact ;
- création d'un invisible et d'une zone 1×1 ;
- échec du registry write → retry/cleanup.

Les tests widget ne remplacent pas ce gate. Ils prouvent le câblage et les
libellés, pas l'apparence ni l'utilisabilité du parcours desktop complet. De
même, la conformité pixel-perfect à l'image de référence globale fournie par
l'utilisateur n'est pas démontrée par la Phase G ; cette fermeture visuelle
globale relève notamment de la Phase K et d'une session de capture fiable.

## 15. État Git final

Après nettoyage des artefacts et création conjointe du présent rapport et de
l'Evidence Pack :

```text
Branche : main
HEAD : 2f68328a38bf218c843e497940f8dd24a7a9c194
Tracked modified : 42
Untracked : 83
Total : 125
Git write : aucune
```

Les deux seules entrées supplémentaires par rapport à la baseline de cette
passe sont :

```text
reports/narrativeStudio/events/ns_event_v2_phase_g_map_editor_bridge_closure_v0.md
reports/narrativeStudio/events/ns_event_v2_phase_g_evidence_pack.md
```

Le fichier `MVP Selbrume/road_map_event_builder_v2.md` était déjà modifié dans
le worktree, mais **cette passe ne l'a pas édité**. La règle du repository
autorise une mise à jour roadmap seulement sur demande explicite.

Attestation relue après les corrections documentaires :

```text
SHA-256 contenu : a7e5ddb327a46b5e527dbe1816f326be6eb744df4b2a33dd097b926aab1d3349
SHA-256 diff Git actuel : 680a91c1d3026b8a0b33c20d5b9731096cbd1be140e9f48715a0514a9b73e9a7
mtime : 2026-07-15T20:21:02+0200
taille : 95856 octets
diff numstat : 126 ajouts / 39 suppressions
```

La critique indépendante avait relevé le même hash de contenu avant cette
dernière passe. Aucun hash n'avait été enregistré au tout début du turn ; le
rapport n'invente donc pas de baseline cryptographique initiale. La répétition
du hash et le `mtime` antérieur à la clôture sont les preuves disponibles.

## 16. Limites et non-objectifs explicitement conservés

- l'Event Builder V2 à cinq panneaux est un chantier Phase H, pas Phase G ;
- le pixel closure global reste un chantier Phase K ;
- les commandes gameplay et leur release gate restent portés par les lots
  `FG-*` cités, toujours `TODO` ;
- le bridge ne crée pas de map, de layer, de coordonnée ou de géométrie depuis
  l'Event Builder ;
- les sources non spatiales restent globales et sans CTA map ;
- les sources physiques liées ne sont pas renommées automatiquement ;
- le cleanup n'est possible que sur l'owner exact, inchangé et confirmé ;
- il n'existe aucune transaction atomique prétendue entre map et manifest ;
- les échecs globaux étrangers ne sont ni masqués ni absorbés dans G.

## 17. Auto-critique finale et risques restants

1. **Visual Gate non prouvé.** C'est le blocker principal : l'implémentation
   peut être fonctionnellement correcte sans que le flow réel soit lisible ou
   fidèle au produit attendu.
2. **Gates package rouges.** Un succès ciblé ne remplace pas les commandes
   complètes explicitement exigées par le plan.
3. **Worktree agrégé.** La suite globale mesure plusieurs phases simultanées ;
   l'isolation ciblée de G est forte, mais la causalité des 98 échecs n'a pas
   été prouvée un par un.
4. **Couverture widget du recovery dirty/saving.** La matrice contrôleur est
   exhaustive pour retry et cleanup × trois gates. Chaque variante n'est pas
   répétée au niveau bouton widget ; c'est une amélioration de preuve possible,
   pas un défaut fonctionnel observé.
5. **Taille du contrôleur de bridge.** La coordination est volontairement
   centralisée pour protéger les tokens et l'ownership async, mais le fichier
   est devenu un hotspot. Toute extraction future devra garder les fences de
   session et les tests de races.
6. **Rapport fondé sur une liste ciblée.** L'analyse directe est propre ; elle
   ne permet pas d'affirmer que tout `map_editor` est sain, comme le confirment
   les 451 diagnostics globaux.

La critique finale initiale n'a confirmé aucun blocker fonctionnel Phase G
résiduel après les deux correctifs TDD, mais a demandé quatre corrections des
preuves. Elles sont intégrées et la contre-lecture corrective les valide sans
nouveau finding Important. Le verdict produit reste néanmoins
`IMPLEMENTATION FUNCTIONAL PASS / PHASE G FORMAL CLOSURE BLOCKED` : un rapport
ne transforme pas un gate indisponible ou rouge en succès.

## 18. Prochaines étapes proposées, sans les implémenter

1. Relancer Computer Use dans une session ScreenCaptureKit saine et capturer
   les cinq flows réels listés en section 14.
2. Décider explicitement du traitement des 98 échecs et 451 diagnostics :
   correction ciblée, baseline approuvée ou allowlist documentée ; aucune
   exemption implicite.
3. Relancer `flutter test --no-pub --reporter=compact`,
   `flutter analyze --no-pub`, la matrice 410 et le build après stabilisation.
4. Si tous les gates passent, demander explicitement la mise à jour de la
   roadmap et seulement alors proposer `Phase G : CLOSED / ACCEPTED`.

Statut recommandé en attendant :

```text
NS-EVENT-V2-23 : PASS fonctionnel
NS-EVENT-V2-24 : PASS fonctionnel
NS-EVENT-V2-25 : PASS fonctionnel
Phase G : FUNCTIONAL PASS / FORMAL CLOSURE BLOCKED
Roadmap : inchangée
```
