# Character Studio — clôture S9

Date : 2026-08-11

Session : S9

Lots : CHS-050 à CHS-054

Branche : `codex/character-studio-s1`

Worktree : `/Users/karim/.config/superpowers/worktrees/pokemonProject/character-studio-s1`

## Verdict exécutif

| Lot | Verdict | Preuve principale |
|---|---|---|
| CHS-050 | DONE | Export déplacé et réimporté sans chemin source machine, catalogue fermé et blobs orphelins exclus |
| CHS-051 | DONE | Matrice responsive, clavier, sémantique, contrastes et deux goldens premium suivis |
| CHS-052 | DONE | Golden slice Élia/Surprise/Saluer de l’authoring au runtime exporté |
| CHS-053 | DONE | Serveur MCP réellement construit, décrit, muté, relu, fermé et testé en transport packagé |
| CHS-054 | DONE | Gates S9 vertes, build macOS vert, dettes globales non liées isolées ci-dessous |

La session S9 est proposée `DONE`. Le repository complet n’est pas globalement vert : plusieurs suites historiques dépendent encore de fichiers sous `reports/` ou de fixtures Selbrume absentes, et une suite éditeur contient un timeout de dix minutes. Aucun de ces échecs ne touche un fichier ou un comportement modifié par S9. Les gates Character Studio ont été rejouées séparément après les corrections de clôture.

## Audit initial

### Passe Audit et architecture — PASS

L’audit de départ a identifié quatre trous de certification :

1. La projection export ne fermait pas le catalogue d’assets Character Studio et pouvait copier des blobs physiques orphelins.
2. La densité maximale des animations débordait à hauteur minimale et le focus clavier pouvait s’entrelacer entre la bibliothèque, l’éditeur et l’inspecteur.
3. Les preuves existantes validaient les couches séparément sans scénario déterministe couvrant création, reload, export déplacé et lecture runtime.
4. Le test MCP ne prouvait pas encore le cycle live complet `describe → open → dry-run → apply → requery/resource → close`.

Les frontières retenues sont restées celles du produit : modèle et contrats dans `map_core`, mutations canoniques dans `map_authoring`, authoring no-code dans `map_editor`, consommation dans `map_runtime`, transport réel dans `tools/pokemap_mcp`.

### État Git initial de CHS-054

Après les commits CHS-050 à CHS-053, `git status --short --untracked-files=all` était vide. Aucun stash, reset, restore ou nettoyage destructif n’a été utilisé.

## CHS-050 — Export, installation et fermeture des assets

Commit : `75f1db05c fix(character-studio): close portable export assets`

### Changements

- La projection runtime embarque le catalogue canonique des assets.
- Quand le catalogue existe, seuls les blobs catalogués et référencés sont copiés.
- Les blobs physiques orphelins sont exclus.
- Le fallback historique `.pokemap-store/*.blob` est conservé uniquement pour les projets sans catalogue canonique.
- Un asset logique manquant produit un diagnostic avec son chemin logique précis.
- Le test déplace le projet exporté, le réimporte et résout portrait, animation de base et animation custom sans fuite du chemin source.

### Fichiers

| Fichier | Zone |
|---|---|
| `packages/map_editor/lib/src/features/game_export/application/runtime_project_projection_builder.dart` | fermeture, déduplication et projection portable des assets |
| `packages/map_editor/test/character_studio_export_asset_closure_test.dart` | export, orphelins, déplacement, réimport et résolution |

### Preuve

La gate focalisée du lot a passé 32 tests. La gate consolidée finale incluant export, responsive et golden slice éditeur passe 15/15.

## CHS-051 — Responsive, accessibilité et goldens premium

Commit : `aeba70ecc test(character-studio): certify responsive accessibility`

### Changements

- L’éditeur de source d’animation vide est borné et scrollable à 720 px de hauteur.
- Le focus est ordonné par zones : bibliothèque, éditeur, inspecteur.
- Les scénarios couvrent thèmes clair/sombre, largeurs 1672/1440/1280, hauteur minimale, 0/1/50 personnages, 20 états de portrait et 20 animations custom.
- Les longs libellés français, la sémantique lecteur d’écran, la visibilité du focus, les contrastes et l’absence d’action uniquement colorimétrique sont vérifiés.
- Deux goldens déterministes sont suivis.

### Fichiers

| Fichier | Zone |
|---|---|
| `packages/map_editor/lib/src/features/character_studio/presentation/animations/character_animation_source_editor.dart` | bornage et scroll du contenu vide |
| `packages/map_editor/lib/src/features/character_studio/presentation/character_studio_workspace_shell.dart` | ordre de focus par région |
| `packages/map_editor/test/shell_chrome_test_harness.dart` | prise en charge du thème clair |
| `packages/map_editor/test/features/character_studio/character_studio_responsive_accessibility_golden_test.dart` | responsive, densité, sémantique, clavier et contrastes |
| `packages/map_editor/test/goldens/character_studio/character_studio_dark-wide_1672x941.png` | golden sombre large |
| `packages/map_editor/test/goldens/character_studio/character_studio_light-medium_1280x941.png` | golden clair moyen |

### Preuve

La gate focalisée du lot a passé 29 tests. Les deux images ont été inspectées visuellement après génération.

## CHS-052 — Golden slice end-to-end

Commit : `9f4e8d358 test(character-studio): certify the golden slice`

### Scénario prouvé

1. Créer l’état global `Surprise`.
2. Créer Élia et définir son état par défaut.
3. Importer le portrait et la source sprite.
4. Assigner le portrait Surprise.
5. Créer l’animation directionnelle `Saluer`.
6. Configurer quatre clips Base et quatre clips Saluer.
7. Ajouter le portrait au dialogue et la commande d’animation à la cinématique.
8. Fermer puis rouvrir le workspace.
9. Requery et valider le personnage prêt.
10. Construire le package certifié, déplacer la projection et réimporter manifeste/catalogue/blobs.
11. Afficher Élia Surprise, jouer Saluer pendant 120 ms puis restaurer Base sud.

### Fichiers

| Fichier | Zone |
|---|---|
| `packages/map_editor/test/character_studio_golden_slice_e2e_test.dart` | authoring canonique, persistance, export et relocation |
| `packages/map_runtime/test/character_studio_golden_slice_runtime_test.dart` | dialogue, résolution portable, playback et restauration |

### Preuve

- Gate initiale : 14/14 `map_authoring`, 9/9 `map_editor`, 10/10 `map_runtime`.
- Gate consolidée finale : 15/15 éditeur et 17/17 runtime.
- Diagnostics Character Studio vides pour Élia prête.
- Aucune fuite du chemin source dans le package exporté.

## CHS-053 — Certification MCP live

Commit : `5b89cbd14 test(character-studio): certify live MCP lifecycle`

### Changements

Le test `CHS-053 live MCP certifies the complete Character Studio lifecycle` utilise le serveur MCP en mémoire et un worker `LocalAuthoringClient` réel. Il prouve :

- les actions Character Studio dans `pokemap_describe`, dont `cinematic.character_animation.upsert` ;
- les quatre familles de ressources Character Studio et le template catalogue ;
- l’ouverture d’un workspace autorisé ;
- un plan `dryRun` non applicable et non mutant ;
- le plan/apply révisionné ;
- la fermeture, réouverture, requery et lecture de ressource dynamique ;
- la fermeture finale du workspace.

### Fichier

| Fichier | Zone |
|---|---|
| `tools/pokemap_mcp/test/mutation_server.test.ts` | cycle MCP live Character Studio |

### Preuve

- `npm run check` : succès.
- Test CHS-053 isolé : 1/1.
- Compatibilité protocolaire : 6/6.
- `npm run build` : succès.
- Suite complète sérialisée : 40/40, 0 échec, 0 annulation, 160608 ms.

La première exécution parallèle de la suite complète avait produit 35 succès, 5 échecs et 1 annulation par timeouts de workers Dart. Les mêmes fichiers, y compris l’échange `stdio` packagé, passent tous avec `--test-concurrency=1`. Le problème est donc une contention de la gate parallèle, pas un défaut du transport Character Studio.

## CHS-054 — Validation complète

### Corrections découvertes pendant la validation

La validation globale a détecté deux matrices de preuve qui n’échantillonnaient pas encore la commande publiée `playCharacterAnimation` :

| Fichier | Correction |
|---|---|
| `packages/map_core/test/narrative_command_contract_parity_test.dart` | ajout du payload sérialisable et diagnostic-safe |
| `packages/map_runtime/test/narrative_command_runtime_parity_test.dart` | ajout de l’échantillon runtime et du handler déclaré |

Le diff de cette correction est limité à 19 insertions. Les gates focalisées passent respectivement 3/3 et 7/7, avec analyses ciblées propres.

### Commandes et résultats frais

| Package/gate | Commande | Résultat |
|---|---|---|
| `map_core` focalisé | `dart test test/narrative_command_contract_parity_test.dart` | 3/3 |
| `map_core` analyse focalisée | `dart analyze test/narrative_command_contract_parity_test.dart` | aucun diagnostic |
| `map_core` complet | `dart test --reporter=json` | 4472 succès, 1 failure, 4 errors hors S9 |
| `map_core` analyse | `dart analyze` | exit 0, 119 infos historiques |
| `map_authoring` complet | `dart test --reporter=json` | 635/635 |
| `map_authoring` analyse | `dart analyze` | aucun diagnostic |
| `map_editor` S9 | `flutter test test/character_studio_export_asset_closure_test.dart test/features/character_studio/character_studio_responsive_accessibility_golden_test.dart test/character_studio_golden_slice_e2e_test.dart` | 15/15 |
| `map_editor` complet | `flutter test --reporter=json` | interrompu après le timeout interne de 10 minutes décrit ci-dessous |
| `map_editor` analyse | `flutter analyze` | aucun diagnostic |
| `map_runtime` S9 | `flutter test test/character_studio_golden_slice_runtime_test.dart test/narrative_command_runtime_parity_test.dart test/character_custom_animation_runtime_test.dart test/cinematic_custom_character_animation_test.dart` | 17/17 |
| `map_runtime` complet | `flutter test --reporter=json` | 2580 succès, 1 failure hors S9 |
| `map_runtime` analyse focalisée | `flutter analyze test/narrative_command_runtime_parity_test.dart` | aucun diagnostic |
| `map_runtime` analyse | `flutter analyze` | exit 1, 3 infos historiques |
| `map_player_ui` complet | `flutter test --reporter=json` | 229/229 |
| `map_player_ui` analyse | `flutter analyze` | aucun diagnostic |
| MCP build | `npm run build` | succès |
| MCP complet sérialisé | `node --import tsx --test --test-concurrency=1 test/**/*.test.ts` | 40/40 |
| Host smoke | `flutter test test/phase_a_golden_slice_launch_test.dart` | 10/10 |
| Host analyse | `flutter analyze` | exit 1, 26 infos historiques |
| Build éditeur | `flutter build macos --debug` | succès, `PokeMap.app` produit |
| Markdown | `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` | 1 nouveau fichier, emplacement canonique |
| Diff | `git diff --check` | succès |

Une première commande runtime consolidée référençait par erreur le fichier inexistant `character_custom_animation_runtime_controller_test.dart`. Elle a échoué au chargement, puis a été corrigée vers `character_custom_animation_runtime_test.dart` ; la commande corrigée passe 17/17.

### Échecs globaux séparés

#### `map_core`

- L’inventaire Smart Tiles n’attend pas encore `smart_tile.layer.change_preset` et `smart_tile.layer.set_animation_activation`.
- `reports/gameplay/generated/battle_mvp_capability_gate_v0.json` est absent.
- `reports/gameplay/` est absent pour le test de cohérence de roadmap.
- `reports/gameplay/generated/battle_full_capability_gate_v0.json` est absent.
- `reports/product/pokemap_hub/phase_0/saves/examples/minimal-valid-save-envelope.json` est absent.

#### `map_editor`

La suite globale a rencontré plusieurs familles de dettes historiques avant de rester bloquée :

- `test/ui/canvas/narrative_event_map_banner_test.dart` atteint son timeout interne de dix minutes puis déclenche un appel `runAsync` réentrant ;
- plusieurs fixtures Selbrume attendues à la racine du worktree sont absentes ;
- plusieurs manifests de fixtures `v2` sont refusés par la précondition Smart Tiles `v6` ;
- plusieurs preuves visuelles historiques attendent des fichiers sous `reports/ui/` ;
- les erreurs précédentes provoquent ensuite des échecs widget en cascade.

La commande a été interrompue après le timeout de dix minutes ; aucun total final fiable n’est donc annoncé. L’analyse complète et toutes les gates S9 rejouées isolément restent vertes.

#### `map_runtime`

- `test/world_map_rotation_visual_evidence_test.dart` attend le golden absent `reports/ui/world_map_editor_gate_5_rotation_runtime.png`.
- L’analyse conserve trois infos historiques : deux `unnecessary_library_name` et un `unintended_html_in_doc_comment`.

#### Host jouable

L’analyse conserve 26 infos historiques `use_null_aware_elements` et `unnecessary_underscores`. Le smoke de lancement passe 10/10.

### Build

`flutter build macos --debug` produit `packages/map_editor/build/macos/Build/Products/Debug/PokeMap.app`. Les avertissements non bloquants sont :

- `gamepads_darwin` ne supporte pas encore Swift Package Manager ;
- l’AppIcon contient un enfant non assigné ;
- `AVKeyValueStatus` est déprécié dans `video_player_avfoundation`.

## Inventaire final S9

| Statut | Fichier |
|---|---|
| Modifié | `packages/map_editor/lib/src/features/character_studio/presentation/animations/character_animation_source_editor.dart` |
| Modifié | `packages/map_editor/lib/src/features/character_studio/presentation/character_studio_workspace_shell.dart` |
| Modifié | `packages/map_editor/lib/src/features/game_export/application/runtime_project_projection_builder.dart` |
| Ajouté | `packages/map_editor/test/character_studio_export_asset_closure_test.dart` |
| Ajouté | `packages/map_editor/test/character_studio_golden_slice_e2e_test.dart` |
| Ajouté | `packages/map_editor/test/features/character_studio/character_studio_responsive_accessibility_golden_test.dart` |
| Ajouté | `packages/map_editor/test/goldens/character_studio/character_studio_dark-wide_1672x941.png` |
| Ajouté | `packages/map_editor/test/goldens/character_studio/character_studio_light-medium_1280x941.png` |
| Modifié | `packages/map_editor/test/shell_chrome_test_harness.dart` |
| Ajouté | `packages/map_runtime/test/character_studio_golden_slice_runtime_test.dart` |
| Modifié | `tools/pokemap_mcp/test/mutation_server.test.ts` |
| Modifié | `packages/map_core/test/narrative_command_contract_parity_test.dart` |
| Modifié | `packages/map_runtime/test/narrative_command_runtime_parity_test.dart` |
| Ajouté | `documentation/reports/editor/character_studio_s9_closure_2026-08-11.md` |

## Non-goals respectés

- Aucun changement de schéma Character Studio en S9.
- Aucun nouveau transport parallèle au `map_authoring` canonique.
- Aucun contournement par édition JSON manuelle.
- Aucun push, merge, tag ou publication externe.
- Aucune correction opportuniste des dettes Smart Tiles, Selbrume, rotation ou lints historiques.

## Auto-critique et risques restants

### Passe Tests et build — PASS pour S9, baseline globale dégradée

Les preuves applicables de chaque lot S9 sont présentes et vertes. Le build produit l’application. La baseline globale doit cependant être réparée séparément avant de pouvoir exiger une commande monorepo entièrement verte.

### Passe critique finale — PASS avec réserves documentées

1. Les goldens Character Studio contrôlent le rendu Flutter déterministe, mais ne remplacent pas un test perceptuel sur plusieurs machines et polices système.
2. Le golden slice est séparé entre l’authoring/export et le contrôleur runtime pour respecter les frontières de packages ; il ne pilote pas une fenêtre macOS réelle de bout en bout.
3. Le MCP complet doit rester sérialisé tant que les workers Dart ne supportent pas la concurrence actuelle sans timeout.
4. Le runtime emploie encore l’énumération technique `idle` pour le concept produit affiché `Base` ; cette compatibilité est volontaire mais mérite d’être conservée dans toute évolution de migration.
5. Les suites globales cassées diminuent la valeur de signal de la CI. Leur remise en état doit être un chantier distinct, sans être mélangée au diff Character Studio.

## Décision

Les lots CHS-050, CHS-051, CHS-052, CHS-053 et CHS-054 satisfont leurs critères applicables avec preuves fraîches. S9 et la phase 5 Character Studio sont proposés `DONE`, avec les dettes globales ci-dessus explicitement hors périmètre et non masquées.
