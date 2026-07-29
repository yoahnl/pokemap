# Phase 0 — Implémentation des gates de vérité et des contrats

Date : 2026-07-28

Branche auditée : `main`

Commit candidat au début et à la fin de l’intervention : `a3d741818c1961ac2f653da235bb30c20df75b00`

Nature du travail : implémentation, tests, revue et clôture prudente de la phase 0

Commit, tag, push ou release : aucun

## 1. Résumé exécutif

La phase 0 a matériellement renforcé les preuves et les contrats du produit :

- le parcours Avelune installé sur iOS couvre désormais l’identité publique, une
  sauvegarde confirmée, le retour au titre, `Continuer`, la fin du jeu, les
  crédits et le retour au Hub ;
- le test de crash des sauvegardes Avelune est découpé en processus réellement
  indépendants et couvre sept points de rupture ;
- le smoke runtime ne dépend plus d’un chemin absolu local ni d’une écriture
  hors sandbox ;
- les tests de performance editor sont isolés dans une lane explicite, avec
  budgets conservés et trois répétitions ;
- la rencontre statique possède maintenant un contrat distinct de celui d’un
  trainer, un authoring guidé, une validation, une projection runtime et des
  tests ;
- l’export PokeMap échoue désormais avant construction du package quand la
  projection réellement publiée ne prouve pas une partie démarrable et
  terminable ;
- le dashboard FG sait lire des reçus structurés, filtrer par SHA candidat,
  signaler les preuves manquantes ou périmées et consommer un répertoire de
  reçus externe au checkout.

Verdict de phase : `PARTIAL`.

Ce verdict n’annule pas les résultats verts. Il signifie que la gate de sortie
complète n’est pas atteinte :

1. la suite fonctionnelle complète de `map_editor` conserve un échec concurrent
   hors phase 0 et son analyse complète conserve un avertissement concurrent ;
2. la CI ne produit pas encore de reçus post-checkout, ne les archive pas avec
   leurs logs et n’active pas le mode strict ;
3. la rencontre statique ne possède pas encore une preuve générique complète
   `oneShot → save → reload → non-réapparition` ;
4. l’export ne lance pas automatiquement le package produit dans Avelune et ses
   diagnostics ne renvoient pas encore vers les écrans d’authoring.

La phase 0 est donc utilisable comme socle, mais elle ne doit pas être déclarée
terminée ni transformée en statut FG `DONE` global.

## 2. Périmètre et méthode

### 2.1 Références lues avant intervention

- `AGENTS.md` racine, intégralement ;
- `codex_rule.md`, intégralement ;
- `skills/README.md` ;
- skills locaux applicables : orchestration read-only, investigation parallèle,
  TDD, débogage systématique, exécution de plan, revue et vérification avant
  clôture ;
- `pokemap_roadmap_mecaniques_fangame.md` ;
- audit produit :
  `reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md` ;
- roadmap produit :
  `reports/gameplay/avelune_pokemap_product_roadmap_2026-07-28.md`.

### 2.2 Lots traités

| Lot opérationnel | Lots FG reliés | Résultat |
|---|---|---|
| T0-1a — smoke iOS Avelune | gates de confiance | parcours installé et sauvegarde publique prouvés |
| T0-1b — atomicité des saves | FG-014 par proximité, sans promotion | sept crash stages hermétiques |
| T0-1c — smoke runtime hermétique | FG-016 par proximité, sans promotion | suppression du chemin machine et smoke pixel versionné |
| T0-1d — lane performance editor | gate de confiance | tests lents explicitement tagués et répétés |
| T0-2 — rencontre statique | FG-087, FG-102 | chaîne modèle/éditeur/runtime partielle mais réelle |
| T0-3 — gate de jouabilité avant export | FG-146, FG-147, FG-180, FG-185 | export fail-closed sur la projection publiée |
| T0-4 — reçus et dashboard | FG-184 | protocole structuré prêt, producteur CI absent |

### 2.3 Passes indépendantes

Trois investigations read-only/implémentations bornées ont été conduites en
parallèle, puis revues par l’agent principal :

1. Avelune, runtime et gates editor ;
2. contrats `map_core`, export et dashboard ;
3. validation indépendante des tests et des régressions.

Une revue finale indépendante a notamment trouvé puis fait corriger deux
failles du premier gate d’export :

- `starterSelectionSceneId` était utilisé comme fausse preuve de
  déclenchement runtime alors que le runtime ne le consommait pas ;
- une party pouvait référencer une espèce absente ou une configuration Pokémon
  désactivée.

La revue finale du dashboard a confirmé les trois corrections demandées
(reçus externes, filtrage par candidat avant contradictions, provenance rendue)
et a maintenu un verdict `PARTIAL` faute de producteur CI strict.

### 2.4 Règles de preuve appliquées

Une présence de modèle ou de bouton n’a jamais été considérée comme une preuve
de complétude. Les chaînes ont été évaluées selon :

```text
modèle → authoring → validation → runtime → persistance → UI joueur → E2E
```

Les anciennes roadmaps servent de contexte, jamais de preuve unique. Les
contradictions entre roadmap, rapports, code, tests et exécution courante sont
conservées au lieu d’être arbitrées silencieusement.

## 3. État Git initial

Branche : `main`

HEAD : `a3d741818c1961ac2f653da235bb30c20df75b00`

État exact relevé avant les modifications de phase 0 :

```text
 M reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json
 M tool/pokemap_product_certification/pubspec.lock
?? packages/gamepads_darwin/macos/gamepads_darwin/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/gamepads_ios/ios/gamepads_ios/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
?? reports/gameplay/avelune_pokemap_product_roadmap_2026-07-28.md
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/01-empty-world-map-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/02-port-open-overview-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/03-inspector-scroll-layer-context-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/04-layers-expanded-truncated-actions-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md
```

Ces éléments ont été préservés. Aucun nettoyage, stash, reset, checkout ou
réécriture n’a été effectué.

## 4. Matrice de clôture

| Produit | Fonctionnalité | Statut | Preuves exactes | Fonctionne | Manque | Impact | Priorité | Effort restant | Dépendances | Prochain test/lot |
|---|---|---|---|---|---|---|---|---|---|---|
| Avelune iOS | parcours installé avec identité et sauvegarde | `COMPLETE` | `runtime_owned_player_flow_test.dart`, iPhone simulator `53A65644-3BE1-4AF0-9AF3-CD792CA62612`, `+1` | installation, identité Camille, shop, soin, sauvegarde confirmée, retour titre, continuer, fin, crédits, Hub | preuve physique App Store/TestFlight hors scope | forte confiance joueur iOS | P0 | S | simulateur iOS et fixture certifiée | conserver en Xcode Cloud et sur cold install |
| Avelune | crash-safe save harness | `COMPLETE` | `hub_save_store_atomic_test.dart`, ciblé `+13`, suite Hub `+196` | sept crash stages dans des processus frais, récupération vérifiée | mesure filesystem réelle sur appareils à maintenir | évite pertes de progression | P0 | S | filesystem Hub | exécuter Android/iOS réels en release |
| Runtime | smoke de rendu hermétique | `COMPLETE` | suppression de `le_train_m00_external_runtime_smoke_test.dart`, ajout `rendered_map_pixel_smoke_test.dart`, ciblé `+1` | fixture versionnée, rendu non noir, temp système supprimé | pas un benchmark GPU | rend la CI reproductible | P0 | S | Golden Slice versionnée | ajouter un smoke release empaqueté |
| PokeMap | lane de performance dédiée | `PARTIAL` | `dart_test.yaml`, 6 tags `performance`, workflow, trois exécutions `+10` | budgets et warmups conservés, `--concurrency=1`, trois runs | suite fonctionnelle globale encore rouge sur un test concurrent | évite faux rouges et faux verts | P0 | S | correction navigation Events | réparer le test/contrat Events puis exécuter la lane CI |
| PokeMap/Core | contrat de rencontre statique | `PARTIAL` | type de paramètre dédié, `BattlePublicContract.battleTemplateId`, builders et diagnostics, 105 core + 183 editor + 21 runtime ciblés | sélection guidée, template stable, payload static, lancement runtime distinct | capture/fuite V0, E2E générique oneShot-save-reload-nonrespawn | débloque boss/rencontre scriptée | P0 | M | consommation narrative et save | lot FG-087/102 de persistance E2E |
| PokeMap | validation de jouabilité avant export | `PARTIAL` | `GamePackageGameplayReadinessGate`, tests `game_export` `+38` | projection exacte, manifest/map/narratif/Pokémon, départ, party/starter, source runtime, fin symbolique, fail-closed | navigation vers erreurs, traversabilité physique, lancement automatique Avelune | empêche de publier un package manifestement injouable | P0 | M | runtime host + Avelune install | export→install→play→credits E2E |
| Gouvernance | reçus FG structurés | `PARTIAL` | schéma v1, CLI `--candidate-sha`, `--evidence-directory`, `--require-fresh-evidence`, tests `+24` | filtrage candidat, freshness, chemins/sources/commandes/digests visibles | producteur CI, logs archivés, digest recalculé, sourcePaths obligatoires | empêche les roadmaps de faire foi seules | P0 | M | GitHub Actions | producteur de reçu post-checkout |
| Roadmap FG-184 | statut documentaire versus preuve courante | `CONTRADICTORY` | roadmap `DONE`, dashboard strict `40` erreurs de preuve fraîche | générateur présent et testé | aucun reçu frais pour le SHA candidat, CI non stricte | risque de faux sentiment de release readiness | P0 | M | lot GOV-01 | ne conserver `DONE` qu’après CI stricte |
| Map editor | suite fonctionnelle complète | `CONTRADICTORY` | run final : un seul échec `Events child navigation...`; isolé : attendu `map`, obtenu `events` | tous les tests phase 0 ciblés verts | contrat UI concurrent non stabilisé | empêche une gate editor globale verte | P0 | S | changements map lifecycle/navigation hors phase 0 | corriger dans le lot propriétaire |
| Map editor | analyse complète | `CONTRADICTORY` | `flutter analyze --no-pub` : 1 info à `editor_shell_page.dart:365` ; ciblé phase 0 : 0 | les 18 éléments phase 0 sont propres | async context warning concurrent | CI analyze globale potentiellement rouge | P0 | S | changement `editor_shell_page.dart` hors phase 0 | corriger dans le lot propriétaire |

## 5. T0-1 — Gates de confiance

### 5.1 GATE-01 — Parcours iOS Avelune

Le test d’intégration utilise l’identité publique Avelune et non un nom mobile
PokeMap. Il saisit `Camille`, ferme proprement le clavier iOS natif via
`SystemChannels.textInput`, attend que le bouton de confirmation soit réellement
`hitTestable`, puis poursuit le parcours.

La sauvegarde est maintenant prouvée par les clés publiques :

- `runtime-save-confirm` ;
- état `saving` puis `paused` ;
- `runtime-save-receipt`.

Le retour au Hub utilise le même helper de scroll/tap que les autres actions
joueur afin de ne plus cliquer un contrôle hors viewport.

Échecs rencontrés et non masqués :

1. premier correctif : bouton final « Retour au Hub » hors écran ;
2. tap d’identité raté à cause du clavier natif ;
3. `tester.testTextInput.hide()` invalide car le test input n’était pas
   enregistré ;
4. `FocusManager` seul insuffisant ;
5. solution finale : fermeture native + attente `hitTestable`.

### 5.2 GATE-02 — Atomicité des sauvegardes

Le test monolithique a été remplacé par sept tests indépendants. Chaque cas :

- crée une racine fraîche ;
- démarre un vrai sous-processus ;
- force un arrêt code `86` à un point de commit précis ;
- recrée le store ;
- vérifie la récupération et l’état visible.

Aucun timeout n’a été augmenté et aucun crash stage n’a été supprimé.

### 5.3 GATE-03 — Smoke runtime hermétique

Le test supprimé dépendait d’un chemin `Desktop` spécifique à une machine et
écrivait hors de la racine de test. Le remplacement :

- charge une fixture Selbrume versionnée ;
- rend en `320×240` ;
- vérifie assets, éléments placés, tuiles non nulles et pixels non noirs ;
- n’écrit que sous `Directory.systemTemp` ;
- supprime sa racine temporaire.

### 5.4 GATE-04 — Performance editor

Six tests sont tagués `performance` et ignorés par défaut via
`packages/map_editor/dart_test.yaml`. La CI possède :

- une lane fonctionnelle ;
- une lane performance explicite ;
- `--tags performance --run-skipped --concurrency=1` ;
- trois répétitions sans relâcher budgets, warmups ou échantillons.

Mesures p95 observées :

| Groupe | Run 1 | Run 2 | Run 3 | Budget |
|---|---:|---:|---:|---:|
| Map Events | 524279 µs | 659054 µs | 685098 µs | 3000000 µs |
| Storyline | 3141 µs | 2925 µs | 2980 µs | 20000 µs |
| Cinematics | 5344 µs | 5412 µs | 5584 µs | 30000 µs |
| Timeline | 1241 µs | 1252 µs | 1325 µs | 10000 µs |

La lane performance est verte. La gate globale reste `PARTIAL` car la suite
fonctionnelle complète de l’éditeur n’est pas encore verte.

## 6. T0-2 — Rencontre statique

### 6.1 Modèle et contrat public

- ajout de `NarrativeCommandParameterKind.staticEncounter` ;
- le paramètre `staticEncounterId` du catalogue canonique n’est plus un trainer
  générique ;
- `BattlePublicContract` transporte un `battleTemplateId` nullable mais distinct ;
- les contrats statiques sont dérivés des `SceneBattlePayload` réellement
  présents ;
- sans scène existante, fallback déterministe `static:<trainerId>` ;
- une scène statique sans template est indisponible avec
  `missingBattleTemplateRef` ;
- plusieurs templates pour le même profil produisent
  `ambiguousBattleTemplateRef`.

Le code ne force pas le template à égaler `static:<trainerId>` : Selbrume
conserve correctement `battle_lighthouse_pokemon`.

### 6.2 Authoring no-code

- template canonique « Rencontre statique » dans Event Builder ;
- réutilisation `oneShot` ;
- picker guidé depuis les contrats publics ;
- paramètres cachés `trainerId` et `battleTemplateId`, sans saisie d’ID ;
- Event Builder, Narrative Workspace, Scenes et inspector propagent le template ;
- re-sélection d’un même profil statique préserve le template historique ;
- preview et diagnostics vérifient la disponibilité et la cohérence des IDs.

### 6.3 Runtime

L’adapter :

- distingue `trainer` et `static` ;
- exige un `trainerId` pour les deux ;
- exige un `battleTemplateId` non vide pour `static` ;
- renvoie `missingStaticBattleTemplateId` sinon ;
- transmet le template stable au lanceur de combat.

Limite de nommage : la méthode de lancement existante s’appelle encore
`startTrainerBattle`, même lorsqu’elle transporte un combat statique.

### 6.4 Persistance et preuve manquante

La fixture Selbrume prouve un vrai combat de boss avec défaite, retry et victoire.
Elle ne remplace pas un test de contrat générique qui prouve :

```text
interaction → combat → victoire/capture → oneShot consommé
→ sauvegarde → reload → interaction impossible / non-réapparition
```

FG-087 et FG-102 doivent donc rester `PARTIAL` ou `CONTRADICTORY` par rapport à
leurs anciens `TODO`, jamais `DONE`.

## 7. T0-3 — Gate de jouabilité avant export

`GamePackageGameplayReadinessGate` analyse la
`RuntimeProjectProjection` exacte transmise au package builder, pas le projet
éditeur brut.

Contrôles fail-closed :

1. `ProjectValidator` ;
2. `MapValidator` pour chaque map projetée ;
3. `validateNarrativeProject` avec les catalogues projetés ;
4. `NewGame` activé ;
5. map et spawn de départ ;
6. party initiale ou starter exploitable ;
7. configuration Pokémon activée et espèces connues ;
8. source Event V2 runtime-consommable sur la map de départ :
   `mapEnter`, `triggerEnter` ou `entityInteract` ;
9. chemin narratif symbolique vers `FinishGame`.

Le service exécute aussi le vrai `PokemonProjectValidator` via
`FilePokemonReadRepository`. Une erreur du validator bloque l’export au lieu
d’être convertie en succès.

En cas d’échec :

- `GamePackageExportException` ;
- code `gameplayReadinessFailed` ;
- rapport créateur canonique ;
- aucun appel au package builder.

La certification finale exige le rapport jouable et zéro diagnostic de
compatibilité.

Limites :

- la preuve est symbolique, pas une preuve de traversabilité des tuiles ;
- les diagnostics ne sont pas encore navigables vers l’écran fautif ;
- le package exporté n’est pas automatiquement installé et lancé dans Avelune ;
- l’E2E final `authoring UI → export → install → play → credits` reste à faire.

## 8. T0-4 — Reçus et dashboard FG

### 8.1 Protocole livré

Le schéma v1 contient :

- `lotIds` ;
- `statusByLot` ;
- `candidateSha` ;
- `capturedAt` ;
- commandes et `outputDigest` ;
- `sourcePaths`.

Le dashboard :

- découvre récursivement Markdown et `*.fg-evidence.json` ;
- filtre les reçus par candidat avant de calculer conflits et échecs ;
- distingue warnings et errors ;
- expose statuts, contradictions, preuves manquantes et périmées ;
- affiche reçus, rapports, chemins couverts, SHA, commandes, digests et fraîcheur.

Le CLI accepte :

```text
--check
--candidate-sha SHA
--require-fresh-evidence
--evidence-directory PATH
```

Le répertoire externe résout l’auto-référence : la CI peut tester un checkout,
produire ensuite le reçu dans un dossier externe, puis certifier le même SHA sans
modifier ce checkout.

### 8.2 Vérité du dashboard courant

| Mode | Exit | Erreurs | Warnings | Verdict |
|---|---:|---:|---:|---|
| structurel `--check ../..` | 0 | 0 | 0 | structure lisible, 114 entrées sans reçu courant |
| candidat non strict | 0 | 0 | 40 | 40 lots `DONE` sans preuve fraîche |
| candidat strict | 1 | 40 | 0 | certification refusée |

### 8.3 Limites bloquantes

- la CI actuelle reste explicitement en mode migration non strict ;
- aucun job ne produit ou télécharge un reçu externe post-checkout ;
- les logs ne sont pas archivés avec le reçu ;
- `outputDigest` et `candidateSha` sont seulement non vides ;
- aucun digest n’est recalculé ;
- `sourcePaths` peut être vide ;
- le mode structurel sans candidat peut mélanger des reçus historiques.

La roadmap canonique présente FG-184 comme `DONE`, mais la vérité courante est
`CONTRADICTORY`.

## 9. Fichiers phase 0 modifiés

### 9.1 Avelune

- `.github/workflows/pokemap_hub_product_certification.yml`
- `apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart`
- `apps/pokemap_hub/test/saves/hub_save_store_atomic_test.dart`

### 9.2 `map_core`

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/models/narrative_command_descriptor.dart`
- `packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart`
- `packages/map_core/lib/src/read_models/narrative_command_catalog.dart`
- `packages/map_core/lib/src/tooling/gameplay_roadmap_dashboard.dart`
- `packages/map_core/lib/src/tooling/gameplay_roadmap_evidence.dart` — créé
- `packages/map_core/test/gameplay_roadmap_dashboard_test.dart`
- `packages/map_core/test/linked_asset_public_contracts_test.dart`
- `packages/map_core/test/narrative_command_catalog_test.dart`
- `packages/map_core/test/narrative_command_contract_parity_test.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `packages/map_core/tool/generate_gameplay_roadmap_dashboard.dart`

### 9.3 `map_editor`

- `packages/map_editor/dart_test.yaml` — créé
- `packages/map_editor/lib/game_export.dart`
- `packages/map_editor/lib/src/application/services/narrative_template_catalog.dart`
- `packages/map_editor/lib/src/features/game_export/application/game_package_gameplay_readiness_gate.dart` — créé
- `packages/map_editor/lib/src/features/game_export/application/game_package_export_profile.dart`
- `packages/map_editor/lib/src/features/game_export/application/game_package_export_service.dart`
- `packages/map_editor/lib/src/features/game_export/presentation/game_package_export_controller.dart`
- `packages/map_editor/lib/src/features/game_export/presentation/game_package_export_dialog.dart`
- `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/test/cinematic_builder_characterization_performance_test.dart`
- `packages/map_editor/test/event_builder_v2_template_sheet_test.dart`
- `packages/map_editor/test/event_registry_persistence_performance_test.dart`
- `packages/map_editor/test/game_export/game_export_test_fixture.dart`
- `packages/map_editor/test/game_export/game_package_export_controller_test.dart`
- `packages/map_editor/test/game_export/game_package_export_dialog_test.dart`
- `packages/map_editor/test/game_export/game_package_export_service_test.dart`
- `packages/map_editor/test/game_export/runtime_project_projection_builder_test.dart`
- `packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart`
- `packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart`
- `packages/map_editor/test/narrative_global_search_performance_test.dart`
- `packages/map_editor/test/narrative_large_project_workspace_performance_test.dart`
- `packages/map_editor/test/narrative_template_catalog_test.dart`
- `packages/map_editor/test/personalization/phase_6_personalization_studio_export_e2e_test.dart`
- `packages/map_editor/test/scene_action_builder_test.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart`
- `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart`

### 9.4 `map_runtime`

- `packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart`
- `packages/map_runtime/test/le_train_m00_external_runtime_smoke_test.dart` — supprimé
- `packages/map_runtime/test/narrative_command_runtime_parity_test.dart`
- `packages/map_runtime/test/rendered_map_pixel_smoke_test.dart` — créé
- `packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart`

### 9.5 Gouvernance

- `reports/gameplay/evidence/README.md` — créé
- `reports/gameplay/phase_0_truth_and_contract_gates_implementation_2026-07-28.md` — créé

Le contenu intégral des fichiers créés est reproduit en annexes. Le présent
rapport ne peut pas contenir récursivement son propre contenu ; cette exception
auto-référentielle est explicitement documentée.

## 10. Fichiers locaux hors phase 0 préservés

Les éléments présents avant l’intervention et les changements apparus
concurremment n’ont pas été nettoyés ni revendiqués. Ils comprennent notamment :

- le reçu PH-007 et le lock de l’outil de certification ;
- les fichiers Xcode utilisateur ;
- l’audit et la roadmap du 2026-07-28 ;
- l’audit UI World Map et ses captures ;
- les changements de lifecycle des maps :
  `map_use_cases.dart`, `editor_notifier.dart`, `project_filesystem.dart`,
  politiques d’ID, activation coordinator/guard, panneaux et tests associés ;
- les changements concurrents de navigation narrative :
  `narrative_event_map_bridge_state.dart`,
  `narrative_event_map_return_panel.dart`,
  `editor_shell_page.dart` et composants voisins.

Le seul point de contact diagnostique est que ces derniers maintiennent
`EditorWorkspaceMode.events` quand un test historique attend
`EditorWorkspaceMode.map`. Aucun correctif n’a été appliqué hors périmètre.

## 11. Zones de diff

| Zone | Nature exacte |
|---|---|
| workflow | ajout jobs fonctionnel/performance editor et check dashboard migration |
| test iOS | scroll/taps visibles, fermeture clavier native, assertions save receipt |
| save atomic | un test par crash stage, processus frais |
| core narrative | type de paramètre static, catalogue canonique, diagnostics |
| core contracts | `battleTemplateId`, détection missing/ambiguous/fallback |
| editor templates | template static oneShot et picker guidé |
| editor scenes | propagation du template statique dans builder/inspector |
| runtime | validation distincte static et forwarding du template |
| export | readiness gate sur projection, validator Pokémon, fail-closed |
| dashboard | schéma receipt, ingestion, freshness, candidat, provenance |
| smokes | suppression chemin machine, ajout smoke pixel hermétique |
| tests | caractérisation, RED puis GREEN, performances séparées |

## 12. Commandes exécutées et résultats

### 12.1 Avelune

```text
cd apps/pokemap_hub
flutter test --no-pub integration_test/runtime_owned_player_flow_test.dart \
  -d 53A65644-3BE1-4AF0-9AF3-CD792CA62612 -r expanded
```

Résultat final : exit `0`, `+1`, Xcode build `22.8s`.

```text
flutter test --no-pub -r expanded test/saves/hub_save_store_atomic_test.dart
```

Résultat : exit `0`, `+13`, environ `25s`.

```text
flutter test --no-pub --timeout 2m -r compact
```

Résultat : exit `0`, `+196`, tous les tests passés.

```text
flutter analyze --no-pub
```

Résultat : exit `0`, aucun problème.

### 12.2 `map_core`

```text
dart test -r compact
dart analyze
```

Résultat final autonome : exit `0`, `+4516`, tous les tests passés ; analyse
sans problème.

Deux exécutions complètes concurrentes antérieures avaient produit `-1` puis
`-2` sur les tests de performance stone-chain. Le fichier isolé a passé `+94`,
puis la suite complète autonome est passée. Cette sensibilité à la charge est
conservée comme signal, pas requalifiée en succès permanent.

```text
dart test test/gameplay_roadmap_dashboard_test.dart -r compact
```

Résultat : exit `0`, `+24`.

```text
dart test <tests core ciblés static/catalogue/authoring>
```

Résultat groupé : exit `0`, `+105`.

### 12.3 `map_editor`

```text
flutter test --no-pub -r expanded test/game_export
```

Résultat : exit `0`, `+38`.

```text
flutter test --no-pub <tests phase 0 ciblés>
```

Résultat groupé final : exit `0`, `+183`.

```text
flutter test --no-pub -r expanded \
  test/personalization/phase_6_personalization_studio_export_e2e_test.dart
```

Résultat après correction de la fixture Pokémon : exit `0`, `+1`.

```text
flutter test --no-pub --timeout 2m -r json
```

Résultat final : exit `1`, `294488ms`, exactement un test en échec :

```text
Events child navigation opens Map Events without leaving Events
Expected: EditorWorkspaceMode.map
Actual:   EditorWorkspaceMode.events
```

Ce test isolé reproduit le même échec. Il porte sur un changement concurrent
hors phase 0.

```text
flutter analyze --no-pub
```

Résultat : exit `1`, un seul diagnostic :

```text
info • use_build_context_synchronously
lib/src/ui/editor_shell_page.dart:365:18
```

Le fichier est un changement concurrent hors phase 0.

```text
flutter analyze --no-pub <18 éléments phase 0>
```

Résultat : exit `0`, aucun problème.

Lane performance, exécutée trois fois :

```text
flutter test --no-pub --tags performance --run-skipped \
  --concurrency=1 -r expanded
```

Résultats : trois exits `0`, `+10` à chaque run.

### 12.4 `map_runtime` et Golden Slice

```text
cd packages/map_runtime
flutter test --no-pub --timeout 2m -r compact
flutter analyze --no-pub
```

Résultat complet : exit `0`, `+2242`, `1` skipped, tous les autres tests
passés ; analyse sans problème. Après l’extension finale du contrat statique,
les 21 tests runtime directement concernés ont été relancés et sont verts.

```text
flutter test --no-pub test/phase_a_golden_battle_slice_smoke_test.dart \
  -r expanded
```

Résultat : exit `0`, `+3`.

```text
cd examples/playable_runtime_host
flutter test --no-pub test/phase_a_golden_slice_launch_test.dart -r expanded
flutter analyze --no-pub
```

Résultat : tests exit `0`, `+1` ; analyse sans problème.

### 12.5 Format, workflow et diff

```text
dart format --output=none --set-exit-if-changed <51 fichiers phase 0>
```

Résultat : `Formatted 51 files (0 changed) in 0.22 seconds.`

```text
ruby -e 'require "yaml"; YAML.load_file(
  ".github/workflows/pokemap_hub_product_certification.yml",
  aliases: true
); puts "YAML_OK"'
```

Résultat : exit `0`, `YAML_OK`.

```text
git diff --check
```

Résultat après écriture du rapport : exit `0`, aucune sortie.

### 12.6 Commandes impossibles ou non exécutées

- aucun build Android release, signature Play, notarisation desktop ou archive
  Xcode Cloud : hors périmètre technique de la phase 0 et absence de secrets de
  production ;
- aucun cold install TestFlight/App Store : le simulateur iOS installé est la
  preuve disponible ;
- aucun test manuel physique Android/iOS ;
- aucun commit, tag, push ou GitHub Release, conformément à la demande.

## 13. Contradictions découvertes

1. FG-184 est `DONE` dans la roadmap, mais aucun reçu frais n’existe pour le SHA
   courant et le mode strict échoue sur 40 lots `DONE`.
2. FG-180 est `DONE` dans la roadmap, mais le nouveau gate prouve seulement une
   fin symbolique et ne prouve ni traversabilité physique ni lancement Avelune.
3. FG-087 et FG-102 sont encore `TODO` dans la roadmap alors qu’une chaîne
   statique réelle existe désormais ; le statut honnête est `PARTIAL`.
4. Des rapports historiques annoncent une couverture Golden Slice plus large
   que la preuve fraîche générique de persistance d’une rencontre statique.
5. La lane performance est verte, mais la suite editor par défaut ne l’est pas
   à cause d’un contrat de navigation concurrent.
6. Les 18 fichiers phase 0 sont propres à l’analyse, mais l’analyse package est
   rouge sur un fichier concurrent.

## 14. Risques et dette réellement bloquante

### P0

- absence de producteur CI de reçus vérifiables et de gate stricte ;
- suite editor globale rouge ;
- absence d’E2E générique static encounter avec save/reload/nonrespawn ;
- absence d’E2E export→Avelune→fin.

### P1

- diagnostics export non navigables ;
- digest de reçu non recalculé et logs non liés cryptographiquement ;
- méthode runtime `startTrainerBattle` trompeuse pour `static` ;
- validation de fin symbolique sans preuve de traversabilité ;
- tests `map_core` de performance sensibles à la concurrence CPU.

### P2

- mode dashboard structurel sans candidat pouvant mélanger l’historique ;
- `sourcePaths` non obligatoire ;
- aucune mesure GPU réelle du smoke pixel.

## 15. Fonctionnalités à ne pas prioriser maintenant

- profondeur post-MVP : doubles, Méga/Tera/Z/Dynamax, concours, Battle Frontier ;
- polish visuel sans lien avec une gate de jouabilité ;
- rematch trainers ;
- extension de la rencontre statique à de nouveaux modes avant la persistance
  générique ;
- dashboard visuel supplémentaire avant le producteur de preuves ;
- nouveaux formats d’export avant l’E2E du format déjà supporté.

## 16. Prochain découpage recommandé

### Lot P0-A — Remettre `map_editor` globalement vert

Objectif : stabiliser le contrat « Events → Map Events » et supprimer
l’avertissement async concurrent.

Définition de terminé :

- suite fonctionnelle editor exit `0` ;
- analyse editor exit `0` ;
- performance lane toujours trois fois verte.

### Lot P0-B — Producteur CI de reçus

Objectif : produire une preuve post-checkout non auto-référentielle.

Périmètre :

- capturer stdout/stderr et exit code ;
- SHA-256 des logs ;
- reçu externe avec SHA exact ;
- archive reçus + logs ;
- vérification des digests ;
- dashboard `--require-fresh-evidence`.

Définition de terminé :

- un checkout frais produit et vérifie son reçu sans modifier Git ;
- un log altéré fait échouer la gate ;
- un reçu ancien n’affecte pas le candidat courant.

### Lot P0-C — Static encounter persistant

Objectif : fermer FG-087/102 sans surpromesse.

Définition de terminé :

- authoring guidé ;
- victoire et capture/fuite selon politique explicitement supportée ;
- consommation oneShot ;
- save/reload ;
- non-réapparition ;
- E2E Selbrume et fixture générique.

### Lot P0-D — Export installé dans Avelune

Objectif : transformer la preuve symbolique en preuve produit.

Définition de terminé :

- projet créé depuis l’éditeur ;
- export accepté par le gate ;
- installation réelle dans Avelune ;
- nouvelle partie ;
- progression jusqu’à `FinishGame` ;
- sauvegarde/reprise ;
- crédits ;
- retour Hub ;
- diagnostic négatif navigable pour chaque invariant du gate.

## 17. Proposition de statuts FG

La roadmap n’a pas été modifiée.

| Lot | Statut documentaire actuel | Proposition fondée sur cette intervention |
|---|---|---|
| FG-087 | `TODO` | `PARTIAL` |
| FG-102 | `TODO` | `PARTIAL` |
| FG-146 | `TODO` | `PARTIAL` |
| FG-147 | `TODO` | `PARTIAL` |
| FG-180 | `DONE` | `CONTRADICTORY` |
| FG-184 | `DONE` | `CONTRADICTORY` |
| FG-185 | `PARTIAL` | `PARTIAL` |

## 18. État Git final

État relevé après implémentation, validations et création du rapport :

```text
 M .github/workflows/pokemap_hub_product_certification.yml
 M apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart
 M apps/pokemap_hub/test/saves/hub_save_store_atomic_test.dart
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/models/narrative_command_descriptor.dart
 M packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
 M packages/map_core/lib/src/read_models/narrative_command_catalog.dart
 M packages/map_core/lib/src/tooling/gameplay_roadmap_dashboard.dart
 M packages/map_core/test/gameplay_roadmap_dashboard_test.dart
 M packages/map_core/test/linked_asset_public_contracts_test.dart
 M packages/map_core/test/narrative_command_catalog_test.dart
 M packages/map_core/test/narrative_command_contract_parity_test.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_core/tool/generate_gameplay_roadmap_dashboard.dart
 M packages/map_editor/lib/game_export.dart
 M packages/map_editor/lib/src/application/services/narrative_template_catalog.dart
 M packages/map_editor/lib/src/application/use_cases/map_use_cases.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_profile.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_service.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_controller.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_dialog.dart
 M packages/map_editor/lib/src/features/narrative/state/narrative_event_map_bridge_state.dart
 M packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart
 M packages/map_editor/lib/src/ui/canvas/events/narrative_event_map_return_panel.dart
 M packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/narrative_event_map_banner.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/map_connections_panel.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer/widgets/tree/world_tree_nodes.dart
 M packages/map_editor/lib/src/ui/shared/map_workspace_empty_state.dart
 M packages/map_editor/test/cinematic_builder_characterization_performance_test.dart
 M packages/map_editor/test/event_builder_v2_template_sheet_test.dart
 M packages/map_editor/test/event_registry_persistence_performance_test.dart
 M packages/map_editor/test/game_export/game_export_test_fixture.dart
 M packages/map_editor/test/game_export/game_package_export_controller_test.dart
 M packages/map_editor/test/game_export/game_package_export_dialog_test.dart
 M packages/map_editor/test/game_export/game_package_export_service_test.dart
 M packages/map_editor/test/game_export/runtime_project_projection_builder_test.dart
 M packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart
 M packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart
 M packages/map_editor/test/narrative_global_search_performance_test.dart
 M packages/map_editor/test/narrative_large_project_workspace_performance_test.dart
 M packages/map_editor/test/narrative_template_catalog_test.dart
 M packages/map_editor/test/personalization/phase_6_personalization_studio_export_e2e_test.dart
 M packages/map_editor/test/scene_action_builder_test.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart
 D packages/map_runtime/test/le_train_m00_external_runtime_smoke_test.dart
 M packages/map_runtime/test/narrative_command_runtime_parity_test.dart
 M packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart
 M reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json
 M tool/pokemap_product_certification/pubspec.lock
?? packages/gamepads_darwin/macos/gamepads_darwin/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/gamepads_ios/ios/gamepads_ios/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/map_core/lib/src/tooling/gameplay_roadmap_evidence.dart
?? packages/map_editor/dart_test.yaml
?? packages/map_editor/lib/src/application/services/project_map_id_policy.dart
?? packages/map_editor/lib/src/features/editor/application/map_activation_coordinator.dart
?? packages/map_editor/lib/src/features/editor/presentation/map_activation_guard.dart
?? packages/map_editor/lib/src/features/game_export/application/game_package_gameplay_readiness_gate.dart
?? packages/map_editor/test/application/services/project_map_id_policy_test.dart
?? packages/map_editor/test/application/use_cases/map_lifecycle_use_cases_test.dart
?? packages/map_editor/test/features/editor/application/map_activation_coordinator_test.dart
?? packages/map_editor/test/features/editor/presentation/map_activation_guard_test.dart
?? packages/map_editor/test/features/editor/state/editor_notifier_map_activation_test.dart
?? packages/map_editor/test/infrastructure/filesystem/project_filesystem_map_path_confinement_test.dart
?? packages/map_runtime/test/rendered_map_pixel_smoke_test.dart
?? reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
?? reports/gameplay/avelune_pokemap_product_roadmap_2026-07-28.md
?? reports/gameplay/evidence/README.md
?? reports/gameplay/phase_0_truth_and_contract_gates_implementation_2026-07-28.md
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/01-empty-world-map-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/02-port-open-overview-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/03-inspector-scroll-layer-context-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/04-layers-expanded-truncated-actions-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md
```

Aucune opération Git d’écriture n’a été exécutée.

## 19. Auto-critique

### Ce que l’intervention prouve bien

- commandes et résultats frais, package par package ;
- comportement iOS installé et non simple widget test ;
- crash recovery par sous-processus ;
- chaîne statique réelle sur plusieurs packages ;
- export bloqué avant packaging ;
- contradictions du dashboard visibles et non masquées ;
- indépendance entre fichiers phase 0 et modifications locales concurrentes.

### Ce qu’elle ne prouve pas

- production App Store, Play Internal ou desktop signé ;
- fiabilité sur appareils physiques ;
- aventure complète créée intégralement par UI sans fixture ;
- traversabilité de toutes les maps ;
- persistance générique de la rencontre statique ;
- authenticité cryptographique des reçus ;
- stabilité editor globale tant que le test concurrent reste rouge.

### Biais possibles

- les tests existants reflètent les contrats codés, pas nécessairement toute
  l’expérience humaine ;
- le smoke iOS utilise un simulateur et une fixture certifiée ;
- les tests ciblés peuvent sous-estimer les interactions entre packages ;
- les tests de performance dépendent de la charge machine, même avec
  `concurrency=1` dans leur propre runner ;
- la séparation des changements concurrents repose sur l’état Git initial,
  l’ordre d’apparition observé et les zones fonctionnelles, pas sur des commits
  isolés puisque ceux-ci étaient interdits.

## Annexe A — Contenu intégral des fichiers créés

Les fichiers créés par la phase 0 sont reproduits ci-dessous. Le présent rapport
est exclu de sa propre annexe pour éviter une récursion infinie.

### A.1 `packages/map_editor/dart_test.yaml`

```yaml
# Wall-clock budgets are deliberately absent from the functional lane. They
# run in a dedicated, single-process lane that opts back into skipped tests.
tags:
  performance:
    skip: >-
      Run with --tags performance --run-skipped --concurrency=1 in the
      dedicated performance lane.
```

### A.2 `reports/gameplay/evidence/README.md`

````markdown
# Preuves structurées des lots FG

Les rapports Markdown restent des documents d’ingénierie, mais ils ne prouvent
pas à eux seuls qu’un lot est valide pour la révision candidate courante.

Le dashboard FG charge récursivement les fichiers versionnés
`reports/gameplay/**/*.fg-evidence.json`. Pour certifier le commit courant sans
créer de référence circulaire, la CI doit générer les reçus **après** le
checkout et les validations, dans un dossier d’artefacts externe au dépôt,
puis fournir ce dossier avec `--evidence-directory`. Un reçu peut couvrir
plusieurs lots et doit respecter ce contrat :

```json
{
  "schemaVersion": 1,
  "lotIds": ["FG-180", "FG-181"],
  "statusByLot": {
    "FG-180": "DONE",
    "FG-181": "PARTIAL"
  },
  "candidateSha": "git-sha-exact",
  "capturedAtUtc": "2026-07-28T10:00:00Z",
  "commands": [
    {
      "command": "dart test",
      "exitCode": 0,
      "outputDigest": "sha256:digest-of-preserved-output"
    }
  ],
  "sourcePaths": [
    "packages/map_core",
    "reports/gameplay/fg_180_project_gameplay_readiness_report_v0.md"
  ]
}
```

Règles :

- `candidateSha` doit être exactement la révision certifiée ;
- chaque commande doit conserver son code de sortie réel ;
- `outputDigest` identifie la sortie complète archivée par la CI ;
- un code de sortie non nul ne peut jamais prouver un lot ;
- deux reçus du **même candidat** proposant des statuts différents pour le
  même lot sont contradictoires ; les reçus historiques ne contaminent pas le
  candidat courant ;
- un lot `DONE` sans reçu frais apparaît `MISSING`, et le mode strict le bloque ;
- les fichiers Markdown historiques ne promeuvent jamais un statut.

Validation structurelle :

```bash
cd packages/map_core
dart run tool/generate_gameplay_roadmap_dashboard.dart --check ../..
```

Certification stricte d’une révision :

```bash
cd packages/map_core
dart run tool/generate_gameplay_roadmap_dashboard.dart \
  --check \
  --candidate-sha "$GITHUB_SHA" \
  --evidence-directory "$RUNNER_TEMP/fg-evidence" \
  --require-fresh-evidence \
  ../..
```

Le mode strict doit être activé seulement lorsque les lots `DONE` exigés par la
release possèdent leurs reçus externes. Un reçu versionné ne peut pas certifier
le commit qui l’ajoute, car l’ajout du reçu modifie le SHA ; il reste une preuve
historique. Les sorties complètes désignées par `outputDigest` doivent être
conservées dans le même artefact CI.
````

### A.3 `packages/map_runtime/test/rendered_map_pixel_smoke_test.dart`

```dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:path/path.dart' as p;

import 'support/selbrume_event_v2_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders repository-owned Selbrume pixels into a temporary PNG',
      () async {
    final fixture = SelbrumeEventV2RuntimeFixture.locate();
    final outputDirectory = await Directory.systemTemp.createTemp(
      'pokemap_rendered_map_pixel_smoke_',
    );
    addTearDown(() async {
      if (await outputDirectory.exists()) {
        await outputDirectory.delete(recursive: true);
      }
    });

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: fixture.projectPath,
      mapId: selbrumePortMapId,
    );
    final transparentColors = <String, TilesetTransparentColor>{
      for (final tileset in bundle.manifest.tilesets)
        if (tileset.transparentColor != null)
          tileset.id: tileset.transparentColor!,
    };
    final images = await loadTilesetImagesById(
      bundle.tilesetAbsolutePathsById,
      transparentColorByTilesetId: transparentColors,
    );
    final component = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: images,
    );
    final rendered = await _renderOverview(
      component,
      worldWidth: (bundle.map.size.width * bundle.cellWidth).round(),
      worldHeight: (bundle.map.size.height * bundle.cellHeight).round(),
    );
    final png = await rendered.toByteData(format: ui.ImageByteFormat.png);

    expect(fixture.isCanonicalProject, isFalse);
    expect(bundle.map.id, selbrumePortMapId);
    expect(bundle.map.placedElements, isNotEmpty);
    expect(
      bundle.map.layers
          .whereType<TileLayer>()
          .expand((layer) => layer.tiles)
          .where((tileId) => tileId > 0),
      isNotEmpty,
    );
    expect(
      images,
      contains('ts_selbrume_port_reference_v3'),
    );
    expect(
      images,
      contains('ts_selbrume_port_ground_v3'),
    );
    expect(await _containsNonBlackPixel(rendered), isTrue);
    expect(png, isNotNull);

    // The smoke may read the versioned project, but it must never mutate it.
    // Keeping the only write below under system temp protects fresh checkouts
    // and developer-authored projects from preview artifacts.
    final output = File(p.join(outputDirectory.path, 'selbrume_port.png'));
    expect(p.isWithin(fixture.root.path, output.path), isFalse);
    for (final assetPath in bundle.tilesetAbsolutePathsById.values) {
      expect(
        p.isWithin(fixture.root.path, assetPath),
        isTrue,
        reason: 'Runtime asset escaped the versioned fixture: $assetPath',
      );
    }
    await output.writeAsBytes(png!.buffer.asUint8List(), flush: true);
    expect(await output.length(), greaterThan(1000));
  });
}

Future<ui.Image> _renderOverview(
  MapLayersComponent component, {
  required int worldWidth,
  required int worldHeight,
}) {
  const viewportWidth = 320;
  const viewportHeight = 240;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(
      0,
      0,
      viewportWidth.toDouble(),
      viewportHeight.toDouble(),
    ),
    ui.Paint()..color = const ui.Color(0xff000000),
  );

  final scale = math.min(
    viewportWidth / worldWidth,
    viewportHeight / worldHeight,
  );
  final offsetX = (viewportWidth - (worldWidth * scale)) / 2;
  final offsetY = (viewportHeight - (worldHeight * scale)) / 2;
  component.update(0);
  canvas
    ..save()
    ..translate(offsetX, offsetY)
    ..scale(scale, scale);
  component.render(canvas);
  canvas.restore();
  return recorder.endRecording().toImage(viewportWidth, viewportHeight);
}

Future<bool> _containsNonBlackPixel(ui.Image image) async {
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (pixels == null) {
    throw StateError('Could not read rendered pixels.');
  }
  for (var offset = 0; offset < pixels.lengthInBytes; offset += 4) {
    if (pixels.getUint8(offset) != 0 ||
        pixels.getUint8(offset + 1) != 0 ||
        pixels.getUint8(offset + 2) != 0) {
      return true;
    }
  }
  return false;
}
```

### A.4 `packages/map_core/lib/src/tooling/gameplay_roadmap_evidence.dart`

```dart
import 'dart:convert';

enum GameplayRoadmapEvidenceState {
  fresh,
  missing,
  stale,
  failed,
  contradictory,
}

final class GameplayRoadmapEvidenceCommand {
  const GameplayRoadmapEvidenceCommand({
    required this.command,
    required this.exitCode,
    required this.outputDigest,
  });

  final String command;
  final int exitCode;
  final String outputDigest;

  bool get succeeded => exitCode == 0;
}

/// Machine-readable proof attached to one or several canonical FG lots.
///
/// Markdown reports remain useful documentation, but only this receipt carries
/// the candidate revision and exact command outcomes needed for freshness.
final class GameplayRoadmapEvidenceReceipt {
  GameplayRoadmapEvidenceReceipt({
    required Iterable<String> lotIds,
    required Map<String, String> statusByLot,
    required this.candidateSha,
    required this.capturedAtUtc,
    required Iterable<GameplayRoadmapEvidenceCommand> commands,
    required Iterable<String> sourcePaths,
  })  : lotIds = List<String>.unmodifiable(lotIds),
        statusByLot = Map<String, String>.unmodifiable(statusByLot),
        commands = List<GameplayRoadmapEvidenceCommand>.unmodifiable(commands),
        sourcePaths = List<String>.unmodifiable(sourcePaths);

  factory GameplayRoadmapEvidenceReceipt.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Evidence receipt root must be an object.');
    }
    return GameplayRoadmapEvidenceReceipt.fromJson(decoded);
  }

  factory GameplayRoadmapEvidenceReceipt.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException(
        'Evidence receipt schemaVersion must be 1.',
      );
    }
    final lotIds = _stringList(json['lotIds'], 'lotIds');
    if (lotIds.isEmpty || lotIds.toSet().length != lotIds.length) {
      throw const FormatException(
        'Evidence receipt lotIds must be non-empty and unique.',
      );
    }
    for (final lotId in lotIds) {
      if (!RegExp(r'^FG-\d{3}$').hasMatch(lotId)) {
        throw FormatException('Invalid evidence lot id: $lotId.');
      }
    }

    final rawStatuses = json['statusByLot'];
    if (rawStatuses is! Map<String, dynamic>) {
      throw const FormatException('statusByLot must be an object.');
    }
    final statusByLot = <String, String>{};
    for (final lotId in lotIds) {
      final status = rawStatuses[lotId];
      if (status is! String ||
          !_supportedStatuses.contains(status.toUpperCase())) {
        throw FormatException(
          'statusByLot must define a supported status for $lotId.',
        );
      }
      statusByLot[lotId] = status.toUpperCase();
    }
    if (rawStatuses.keys.toSet().difference(lotIds.toSet()).isNotEmpty) {
      throw const FormatException(
        'statusByLot cannot contain lots absent from lotIds.',
      );
    }

    final candidateSha = _requiredString(json['candidateSha'], 'candidateSha');
    final capturedAtSource =
        _requiredString(json['capturedAtUtc'], 'capturedAtUtc');
    final capturedAt = DateTime.tryParse(capturedAtSource);
    if (capturedAt == null || !capturedAt.isUtc) {
      throw const FormatException(
        'capturedAtUtc must be an ISO-8601 UTC timestamp.',
      );
    }

    final rawCommands = json['commands'];
    if (rawCommands is! List || rawCommands.isEmpty) {
      throw const FormatException('commands must be a non-empty array.');
    }
    final commands = <GameplayRoadmapEvidenceCommand>[];
    for (final rawCommand in rawCommands) {
      if (rawCommand is! Map<String, dynamic>) {
        throw const FormatException('Each command must be an object.');
      }
      final exitCode = rawCommand['exitCode'];
      if (exitCode is! int) {
        throw const FormatException('Command exitCode must be an integer.');
      }
      commands.add(
        GameplayRoadmapEvidenceCommand(
          command: _requiredString(rawCommand['command'], 'command'),
          exitCode: exitCode,
          outputDigest: _requiredString(
            rawCommand['outputDigest'],
            'outputDigest',
          ),
        ),
      );
    }

    return GameplayRoadmapEvidenceReceipt(
      lotIds: lotIds,
      statusByLot: statusByLot,
      candidateSha: candidateSha,
      capturedAtUtc: capturedAt,
      commands: commands,
      sourcePaths: _stringList(json['sourcePaths'], 'sourcePaths'),
    );
  }

  final List<String> lotIds;
  final Map<String, String> statusByLot;
  final String candidateSha;
  final DateTime capturedAtUtc;
  final List<GameplayRoadmapEvidenceCommand> commands;
  final List<String> sourcePaths;

  bool get commandsSucceeded => commands.every((command) => command.succeeded);
}

const _supportedStatuses = <String>{
  'DONE',
  'PARTIAL',
  'BLOCKED',
  'TODO',
  'DEFERRED',
};

List<String> _stringList(Object? value, String field) {
  if (value is! List) {
    throw FormatException('$field must be an array.');
  }
  return [
    for (final item in value)
      if (item is String && item.trim().isNotEmpty)
        item.trim()
      else
        throw FormatException('$field must contain non-empty strings.'),
  ];
}

String _requiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return value.trim();
}
```

### A.5 `packages/map_editor/lib/src/features/game_export/application/game_package_gameplay_readiness_gate.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import '../../../application/models/pokemon_validation_report.dart';
import 'runtime_project_projection_builder.dart';

/// Evaluates the exact runtime projection that will be handed to the package
/// builder. It only orchestrates canonical map_core validators and adds the
/// publication invariants that are intentionally stricter than authoring.
final class GamePackageGameplayReadinessGate {
  const GamePackageGameplayReadinessGate();

  NarrativeProjectValidationReport evaluate(
    RuntimeProjectProjection projection, {
    PokemonValidationReport? pokemonValidationReport,
    Object? pokemonValidationFailure,
  }) {
    final project = projection.project;
    final diagnostics = <NarrativeProjectDiagnostic>[];

    try {
      ProjectValidator.validate(project);
    } on Object catch (error) {
      diagnostics.add(
        _diagnostic(
          code: 'exportProjectStructureInvalid',
          message: 'La structure du projet est invalide : $error',
          path: 'project.json',
        ),
      );
    }

    final maps = <MapData>[];
    for (final entry in project.maps) {
      final logicalPath = _projectPayloadPath(entry.relativePath);
      final bytes = projection.payloadFiles[logicalPath];
      if (bytes == null) {
        diagnostics.add(
          _diagnostic(
            code: 'exportMapPayloadMissing',
            message:
                'La map « ${entry.name} » est absente de la projection joueur.',
            path: entry.relativePath,
            domain: NarrativeProjectDiagnosticDomain.map,
            destination: NarrativeProjectDiagnosticDestination.map,
            mapId: entry.id,
          ),
        );
        continue;
      }

      final MapData map;
      try {
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is! Map) {
          throw const FormatException('map JSON root must be an object');
        }
        map = MapData.fromJson(Map<String, dynamic>.from(decoded));
      } on Object catch (error) {
        diagnostics.add(
          _diagnostic(
            code: 'exportMapPayloadInvalid',
            message: 'La map « ${entry.name} » ne peut pas être lue : $error',
            path: entry.relativePath,
            domain: NarrativeProjectDiagnosticDomain.map,
            destination: NarrativeProjectDiagnosticDestination.map,
            mapId: entry.id,
          ),
        );
        continue;
      }

      maps.add(map);
      if (map.id != entry.id) {
        diagnostics.add(
          _diagnostic(
            code: 'exportMapIdMismatch',
            message: 'La map « ${entry.name} » annonce l’identifiant '
                '« ${map.id} » au lieu de « ${entry.id} ».',
            path: '${entry.relativePath}.id',
            domain: NarrativeProjectDiagnosticDomain.map,
            destination: NarrativeProjectDiagnosticDestination.map,
            mapId: entry.id,
          ),
        );
      }
      try {
        MapValidator.validate(
          map,
          projectDialogueContext: project,
        );
      } on Object catch (error) {
        diagnostics.add(
          _diagnostic(
            code: 'exportMapStructureInvalid',
            message: 'La map « ${entry.name} » est invalide : $error',
            path: entry.relativePath,
            domain: NarrativeProjectDiagnosticDomain.map,
            destination: NarrativeProjectDiagnosticDestination.map,
            mapId: entry.id,
          ),
        );
      }
    }

    final speciesIds =
        project.pokemon.enabled ? _projectedSpeciesIds(projection) : null;
    final moveIds =
        project.pokemon.enabled ? _projectedMoveIds(projection) : null;
    _appendPokemonValidationDiagnostics(
      project: project,
      report: pokemonValidationReport,
      failure: pokemonValidationFailure,
      target: diagnostics,
    );
    NarrativeProjectValidationReport? narrativeReport;
    try {
      narrativeReport = validateNarrativeProject(
        project,
        maps: maps,
        knownSpeciesIds: speciesIds,
        knownMoveIds: moveIds,
        requirePokemonCatalogs: project.pokemon.enabled,
      );
      diagnostics.addAll(narrativeReport.diagnostics);
    } on Object catch (error) {
      diagnostics.add(
        _diagnostic(
          code: 'exportNarrativeValidationUnavailable',
          message:
              'La validation de jouabilité n’a pas pu être exécutée : $error',
          path: 'project.json',
        ),
      );
    }

    final runtimeReachability = _runtimeEntryReachability(
      project: project,
      maps: maps,
      narrativeReport: narrativeReport,
      target: diagnostics,
    );
    _appendPublicationInvariants(
      project: project,
      maps: maps,
      runtimeReachability: runtimeReachability,
      target: diagnostics,
    );

    final unique = <String, NarrativeProjectDiagnostic>{};
    for (final diagnostic in diagnostics) {
      unique.putIfAbsent(diagnostic.stableKey, () => diagnostic);
    }
    final sorted = unique.values.toList(growable: false)
      ..sort((left, right) => left.stableKey.compareTo(right.stableKey));
    return NarrativeProjectValidationReport(
      diagnostics: sorted,
      mapEventViews:
          narrativeReport?.mapEventViews ?? const <NarrativeMapEventsView>[],
      symbolicReachability: runtimeReachability,
    );
  }
}

void _appendPublicationInvariants({
  required ProjectManifest project,
  required List<MapData> maps,
  required NarrativeSymbolicReachabilityReport? runtimeReachability,
  required List<NarrativeProjectDiagnostic> target,
}) {
  final newGame = project.newGame;
  if (!newGame.enabled) {
    target.add(
      _diagnostic(
        code: 'exportNewGameDisabled',
        message:
            'Activez Nouvelle Partie avant de publier un jeu certifié jouable.',
        path: 'newGame.enabled',
        suggestedFixLabel: 'Activer et configurer Nouvelle Partie.',
      ),
    );
  }

  final startMapId = newGame.startMapId.trim();
  final mapsById = <String, MapData>{
    for (final map in maps) map.id: map,
  };
  if (newGame.enabled &&
      (startMapId.isEmpty || !mapsById.containsKey(startMapId))) {
    target.add(
      _diagnostic(
        code: 'exportNewGameStartMapUnavailable',
        message: startMapId.isEmpty
            ? 'Choisissez une map de départ pour Nouvelle Partie.'
            : 'La map de départ « $startMapId » n’est pas disponible dans la '
                'projection joueur.',
        path: 'newGame.startMapId',
        domain: NarrativeProjectDiagnosticDomain.map,
        destination: NarrativeProjectDiagnosticDestination.map,
        mapId: startMapId.isEmpty ? null : startMapId,
        suggestedFixLabel: 'Choisir une map de départ existante.',
      ),
    );
  }

  final startSpawnId = newGame.startSpawnId?.trim();
  if (newGame.enabled && (startSpawnId == null || startSpawnId.isEmpty)) {
    target.add(
      _diagnostic(
        code: 'exportNewGameStartSpawnRequired',
        message: 'Choisissez un point de départ joueur pour Nouvelle Partie.',
        path: 'newGame.startSpawnId',
        domain: NarrativeProjectDiagnosticDomain.map,
        destination: NarrativeProjectDiagnosticDestination.map,
        mapId: startMapId.isEmpty ? null : startMapId,
        suggestedFixLabel: 'Choisir un Spawn de rôle playerStart.',
      ),
    );
  }

  final hasInitialParty = newGame.initialParty.isNotEmpty;
  final hasStarterOptions = newGame.starterOptions.isNotEmpty;
  if (newGame.enabled &&
      (hasInitialParty || hasStarterOptions) &&
      !project.pokemon.enabled) {
    target.add(
      _diagnostic(
        code: 'exportPlayablePartyPokemonUnavailable',
        message: 'La création de l’équipe joueur exige le catalogue Pokémon '
            'canonique du projet.',
        path: 'pokemon.enabled',
        suggestedFixLabel: 'Activer et valider les données Pokémon du projet.',
      ),
    );
  }
  if (newGame.enabled && !hasInitialParty && !hasStarterOptions) {
    target.add(
      _diagnostic(
        code: 'exportPlayablePartyUnavailable',
        message: 'Nouvelle Partie ne fournit ni équipe initiale ni choix de '
            'starter : le joueur ne peut pas commencer à jouer.',
        path: 'newGame.initialParty',
        suggestedFixLabel: 'Ajouter une équipe initiale ou un starter.',
      ),
    );
  }
  final starterSceneId = newGame.starterSelectionSceneId?.trim();
  if (newGame.enabled &&
      !hasInitialParty &&
      hasStarterOptions &&
      (starterSceneId == null ||
          starterSceneId.isEmpty ||
          !project.scenes.any((scene) => scene.id == starterSceneId))) {
    target.add(
      _diagnostic(
        code: 'exportStarterSelectionSceneUnavailable',
        message: 'Les starters sont configurés mais aucune Scene de sélection '
            'valide n’est disponible.',
        path: 'newGame.starterSelectionSceneId',
        domain: NarrativeProjectDiagnosticDomain.scene,
        destination: NarrativeProjectDiagnosticDestination.scene,
        sceneId: starterSceneId,
        suggestedFixLabel: 'Choisir une Scene de sélection de starter.',
      ),
    );
  }

  if (!_hasReachableGameEnding(project, runtimeReachability)) {
    target.add(
      _diagnostic(
        code: 'exportStoryEndUnreachable',
        message: 'Aucune conséquence « Terminer le jeu » n’est atteignable '
            'depuis les points d’entrée narratifs du projet.',
        path: 'scenes',
        domain: NarrativeProjectDiagnosticDomain.scene,
        destination: NarrativeProjectDiagnosticDestination.scene,
        suggestedFixLabel:
            'Relier une conséquence Terminer le jeu au parcours principal.',
      ),
    );
  }
}

bool _hasReachableGameEnding(
  ProjectManifest project,
  NarrativeSymbolicReachabilityReport? symbolic,
) {
  if (symbolic == null ||
      symbolic.verdict != NarrativeSymbolicVerdict.pass ||
      symbolic.terminalStates.isEmpty) {
    return false;
  }
  final finishNodes = <String>{
    for (final scene in project.scenes)
      for (final node in scene.graph.nodes)
        if (node.payload
            case SceneActionPayload(
              consequence: SceneFinishGameConsequence(),
            ))
          '${scene.id}\u001f${node.id}',
  };
  if (finishNodes.isEmpty) return false;
  final runtimeStartEventIds = _runtimeStartEventIds(project);
  if (runtimeStartEventIds.isEmpty) return false;
  return symbolic.terminalStates.any(
    (state) {
      final provenance = state.provenance;
      return provenance.any(
            (entry) =>
                finishNodes.contains('${entry.sceneId}\u001f${entry.nodeId}'),
          ) &&
          provenance.any(
            (entry) => runtimeStartEventIds.contains(entry.eventId),
          );
    },
  );
}

Set<String> _runtimeStartEventIds(ProjectManifest project) {
  final startMapId = project.newGame.startMapId.trim();
  if (startMapId.isEmpty) return const <String>{};
  final result = <String>{};
  for (final record
      in project.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
    final definition = record.definitionOrNull;
    if (record.enabledOrNull != true || definition == null) continue;
    final startsOnInitialMap = definition.source.when(
      entityInteract: (mapId, _) => mapId == startMapId,
      triggerEnter: (mapId, _) => mapId == startMapId,
      mapEnter: (mapId) => mapId == startMapId,
      outcomeReceived: (_) => false,
    );
    if (startsOnInitialMap) result.add(definition.id);
  }
  return result;
}

NarrativeSymbolicReachabilityReport? _runtimeEntryReachability({
  required ProjectManifest project,
  required List<MapData> maps,
  required NarrativeProjectValidationReport? narrativeReport,
  required List<NarrativeProjectDiagnostic> target,
}) {
  final starterSceneId = project.newGame.starterSelectionSceneId?.trim();
  if (starterSceneId == null || starterSceneId.isEmpty) {
    return narrativeReport?.symbolicReachability;
  }

  try {
    // The runtime dispatches Event V2 sources, but it does not launch a Scene
    // merely because its id is stored in starterSelectionSceneId. Re-run the
    // symbolic proof without that authoring hint so certification requires an
    // actual runtime-consumable Event source.
    return solveNarrativeSymbolicReachability(
      project.copyWith(
        newGame: _withoutImplicitStarterSceneEntry(project.newGame),
      ),
      maps: maps,
    );
  } on Object catch (error) {
    target.add(
      _diagnostic(
        code: 'exportRuntimeEntryValidationUnavailable',
        message:
            'La route de départ réellement consommée par le runtime n’a pas '
            'pu être validée : $error',
        path: 'eventRegistry',
        suggestedFixLabel:
            'Relier le parcours principal à une source Event V2 valide.',
      ),
    );
    return null;
  }
}

ProjectNewGameConfig _withoutImplicitStarterSceneEntry(
  ProjectNewGameConfig source,
) =>
    ProjectNewGameConfig(
      enabled: source.enabled,
      startMapId: source.startMapId,
      startSpawnId: source.startSpawnId,
      playerName: source.playerName,
      playerAvatarCharacterIds: source.playerAvatarCharacterIds,
      playerPronounSet: source.playerPronounSet,
      startingMoney: source.startingMoney,
      initialBag: source.initialBag,
      initialParty: source.initialParty,
      initialFacts: source.initialFacts,
      initialFactValues: source.initialFactValues,
      existingPartyFactId: source.existingPartyFactId,
      starterSelectionSceneId: null,
      starterOptions: source.starterOptions,
    );

void _appendPokemonValidationDiagnostics({
  required ProjectManifest project,
  required PokemonValidationReport? report,
  required Object? failure,
  required List<NarrativeProjectDiagnostic> target,
}) {
  if (!project.pokemon.enabled) return;
  if (report == null) {
    target.add(
      _diagnostic(
        code: 'exportPokemonValidationUnavailable',
        message: 'Les données Pokémon du projet n’ont pas pu être validées'
            '${failure == null ? '.' : ' : $failure'}',
        path: 'pokemon',
        suggestedFixLabel: 'Réparer puis revalider les données Pokémon.',
      ),
    );
    return;
  }

  for (final issue in report.issues) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'pokemon.${issue.code}',
        severity: switch (issue.severity) {
          PokemonValidationSeverity.error =>
            NarrativeProjectDiagnosticSeverity.error,
          PokemonValidationSeverity.warning =>
            NarrativeProjectDiagnosticSeverity.warning,
        },
        domain: NarrativeProjectDiagnosticDomain.runtime,
        message: issue.message,
        path: issue.location,
        destination: NarrativeProjectDiagnosticDestination.overview,
        suggestedFixLabel: 'Corriger les données Pokémon indiquées.',
      ),
    );
  }
}

Set<String>? _projectedSpeciesIds(RuntimeProjectProjection projection) {
  final directory = projection.project.pokemon.speciesDir.trim();
  if (directory.isEmpty) return null;
  final prefix = '${_projectPayloadPath(directory)}/';
  final ids = <String>{};
  try {
    for (final entry in projection.payloadFiles.entries) {
      if (!entry.key.startsWith(prefix) ||
          !entry.key.toLowerCase().endsWith('.json')) {
        continue;
      }
      final decoded = jsonDecode(utf8.decode(entry.value));
      if (decoded is! Map || decoded['id'] is! String) continue;
      final id = (decoded['id'] as String).trim();
      if (id.isNotEmpty) ids.add(id);
    }
    return ids;
  } on Object {
    return null;
  }
}

Set<String>? _projectedMoveIds(RuntimeProjectProjection projection) {
  final relativePath = projection.project.pokemon.catalogFiles['moves']?.trim();
  if (relativePath == null || relativePath.isEmpty) return null;
  final bytes = projection.payloadFiles[_projectPayloadPath(relativePath)];
  if (bytes == null) return null;
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map || decoded['entries'] is! List) return null;
    return <String>{
      for (final entry in decoded['entries'] as List)
        if (entry is Map && entry['id'] is String)
          if ((entry['id'] as String).trim().isNotEmpty)
            (entry['id'] as String).trim(),
    };
  } on Object {
    return null;
  }
}

String _projectPayloadPath(String relativePath) {
  final normalized =
      p.posix.normalize(relativePath.trim().replaceAll(r'\', '/'));
  return PackagePathPolicy.normalizeNfc('project/$normalized');
}

NarrativeProjectDiagnostic _diagnostic({
  required String code,
  required String message,
  required String path,
  NarrativeProjectDiagnosticDomain domain =
      NarrativeProjectDiagnosticDomain.runtime,
  NarrativeProjectDiagnosticDestination destination =
      NarrativeProjectDiagnosticDestination.overview,
  String? suggestedFixLabel,
  String? mapId,
  String? sceneId,
}) =>
    NarrativeProjectDiagnostic(
      code: code,
      severity: NarrativeProjectDiagnosticSeverity.error,
      domain: domain,
      message: message,
      path: path,
      destination: destination,
      suggestedFixLabel: suggestedFixLabel,
      mapId: mapId,
      sceneId: sceneId,
    );
```
