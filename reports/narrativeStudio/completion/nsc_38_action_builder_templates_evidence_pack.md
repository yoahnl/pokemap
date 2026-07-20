# NSC-38 — Action Builder no-code et templates narratifs

Date : 2026-07-20  
Verdict : **DONE proposé pour NSC-38 et la phase 3 Narrative Studio**  
Lots mécaniques associés : **FG-093/094 restent officiellement TODO tant que la roadmap FG n’est pas mise à jour explicitement**

## Résumé exécutif

Le Narrative Studio expose désormais le catalogue canonique de commandes sous forme de formulaires guidés, sans saisie d’ID ni JSON. Le Scene Builder peut créer les conséquences persistantes existantes ainsi que les commandes interactives prouvées. Le support, le lot FG, le backend, les paramètres manquants et le caractère persistant ou interactif restent visibles ; une commande `unsupported` ne peut pas être appliquée.

L’Event Builder propose dix compositions classiques : PNJ simple, PNJ conditionnel, item ball, objet caché, porte/warp, dresseur, boutique, infirmière, starter et récompense de badge. Chaque composition génère un Event qui référence une Scene ; aucune action n’est copiée dans l’Event. Les sources physiques restent la propriété de la Map : elles doivent exister et correspondre au type demandé. Si elles manquent, le studio ouvre le Map Editor et conserve un brouillon attaché au projet pour reprendre le gabarit au retour.

La prévisualisation produit exactement un Event et une Scene. Leur application utilise un journal durable adjacent à `project.json`, une écriture atomique par fichier, un contrôle de révision compare-and-swap, une reprise idempotente et un undo complet. Le test host génère réellement un template item ball, recharge le JSON, exécute Event→Scene→Action, recharge la sauvegarde et prouve qu’un second dispatch one-shot ne redonne pas la récompense.

## Confirmation du scope et non-objectifs

- Lot exact : `NSC-38 — Action Builder no-code et templates narratifs`.
- Dépendances consommées : NSC-11, NSC-13, NSC-37 ; contrats FG-093/094.
- Aucun second registre de commandes ni second exécuteur n’a été créé.
- Le Narrative Studio ne crée ni PNJ, ni objet, ni zone, ni warp physique.
- Infirmière et badge restent visibles mais non publiables, car les commandes `healParty` et `awardBadge` ne sont pas prouvées de bout en bout.
- Aucun statut de `pokemap_roadmap_mecaniques_fangame.md` n’est modifié par ce lot.
- Aucun fichier Selbrume, Dialogue concurrent, Border ou runtime hors test d’intégration n’est inclus dans le commit.

## Audit initial

### Contrats trouvés

- `NarrativeCommandCatalog` était la vérité canonique des commandes et de leur support depuis NSC-37.
- `SceneConsequence` était déjà le backend unique des effets persistants.
- `SceneActionPayload.interactiveCommand` portait les commandes awaitables prouvées.
- `NarrativeEventAuthoringSession` préparait déjà un snapshot projet/maps attesté.
- Le Map bridge existant était l’unique frontière autorisée pour naviguer vers les sources physiques.
- Aucun catalogue de gabarits, formulaire générique de commande ou transaction Event+Scene durable n’existait.

### Risques identifiés

- dupliquer les actions dans l’Event et la Scene ;
- afficher une mécanique non exécutable comme disponible ;
- créer une fausse source physique depuis le Narrative Studio ;
- laisser un Event sans Scene après une interruption d’écriture ;
- perdre le brouillon lorsque le workspace Event est démonté pour ouvrir la Map ;
- casser la géométrie et les goldens historiques du workspace Event.

### Décisions

- Le formulaire est dérivé de `NarrativeCommandCatalog`, jamais d’une liste UI parallèle.
- Les pickers sont alimentés par les catalogues projet réels.
- Un template est une composition Event→Scene ; le contenu et les actions appartiennent uniquement à la Scene.
- Le brouillon Map aller-retour vit dans un provider non auto-dispose et est qualifié par chemin de projet.
- Le journal est adjacent à `project.json` pour être lisible avant reconstruction de l’état de l’éditeur.
- L’entrée gabarit utilise la bibliothèque existante ; aucun nouveau bandeau ni changement de proportions du workspace n’est conservé.

## État Git initial

- Base du lot : `1e17f3f45 feat(narrative): add canonical command registry`.
- Le worktree était déjà sale avec un chantier Selbrume/Dialogue concurrent, notamment des tests host/runtime, `selbrume/project.json`, des fichiers Dialogue et un rapport de réaudit non suivi.
- `examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart` était déjà stagé avant NSC-38.
- Tous ces chemins sont exclus du commit NSC-38 au moyen d’un staging et d’un commit limités à l’inventaire ci-dessous.

## Inventaire complet et zones modifiées

### `map_core`

| Fichier | Zone précise | Raison et impact |
|---|---|---|
| `packages/map_core/lib/src/read_models/narrative_command_catalog.dart` | descripteur `markEventConsumed` | Exige `mapId` et `eventId`, donc le formulaire ne peut plus produire une référence Event ambiguë. |
| `packages/map_core/lib/src/authoring/scene_authoring_operations.dart` | `addSceneCommandActionNodeDraft` et helper commun d’ajout Action | Ajoute une commande interactive canonique sans contourner `SceneActionPayload`; refuse conséquence/legacy sur ce chemin. |
| `packages/map_core/test/narrative_command_catalog_test.dart` | contrat des paramètres consumed Event | Prouve les deux identités requises. |
| `packages/map_core/test/scene_authoring_operations_test.dart` | ajout Action interactive | Prouve payload, erreurs de backend et absence de mutation invalide. |

### `map_editor` — domaine, persistance et UI

| Fichier | Zone précise | Raison et impact |
|---|---|---|
| `packages/map_editor/lib/src/application/services/narrative_template_catalog.dart` | catalogue, validation, preview, payload builder, coordinateur de transaction | Définit les dix gabarits, génère Event+Scene, contrôle sources/IDs/paramètres et orchestre apply/recover/undo. |
| `packages/map_editor/lib/src/infrastructure/repositories/narrative_template_transaction_file_gateway.dart` | gateway fichier CAS + journal | Préserve les membres JSON inconnus, écrit par temp/flush/rename, refuse une révision concurrente et récupère durablement. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart` | formulaire catalogue-driven | Pickers guidés, champs bool/entier/texte, diagnostics inline et blocage des commandes non publiables. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_action_inspector.dart` | inspecteur réutilisable | Réutilise le même formulaire sans seconde vérité de paramètres. |
| `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` | ouverture et application Action Builder | Route conséquence persistante vers l’opération historique et interactive vers le payload canonique. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | constitution des options de pickers | Résout Facts, Events, Steps, items, espèces, starters, maps, trainers, Dialogues et Cinématiques depuis le projet réel. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_template_sheet.dart` | side sheet de gabarit | Choix template/source/paramètres, preview avant apply, intent Map et reprise du brouillon. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart` | composition production, provider brouillon, transaction, reload, undo | Branche les catalogues, filtre les sources physiques, applique atomiquement et resélectionne l’Event créé. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart` | callback et état pending template | Transporte l’entrée gabarit jusqu’à la bibliothèque existante. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_element_library.dart` | CTA créer/reprendre | Rend l’action découvrable sans modifier la géométrie lorsque le callback n’est pas disponible. |
| `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_product_route_1672x941.png` | golden route produit | Capture l’entrée gabarit dans la route réelle. |
| `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png` | golden shell complet | Capture la même intégration dans le shell north-star. |

### Tests créés et preuve host

| Fichier | Couverture |
|---|---|
| `packages/map_editor/test/scene_action_builder_test.dart` | commande persistante positive, picker vide, commande unsupported, résultat typé. |
| `packages/map_editor/test/narrative_template_catalog_test.dart` | dix patterns, support honnête, preview item ball/conditionnel, collisions, source absente ou incohérente, booléen et nom invalides. |
| `packages/map_editor/test/narrative_template_transaction_recovery_test.dart` | apply/undo mémoire, interruption/recovery idempotent, vrai fichier, reload, unknown root, restauration complète. |
| `packages/map_editor/test/event_builder_v2_template_sheet_test.dart` | parcours UI preview/apply et intent Map avec brouillon reprenable. |
| `examples/playable_runtime_host/test/narrative_action_template_runtime_integration_test.dart` | génération par le service éditeur, reload ProjectManifest, exécution Event V2→Scene→giveItem, reload GameState, non-double récompense. |

## Contenu des fichiers créés

Conformément au précédent Evidence Pack NSC-37, le contenu intégral canonique est le blob Git enregistré dans le même commit que ce rapport. Il est consultable sans ambiguïté avec `git show <commit-nsc-38>:<chemin>`. Les empreintes avant commit et les tailles sont données pour détecter toute divergence documentaire :

| Fichier | Lignes | SHA-256 avant commit |
|---|---:|---|
| `narrative_template_catalog.dart` | 692 | `83a91807c36a09aaa7377550c8b709ebe0153b15687e1d07f40ca966111e89ff` |
| `narrative_template_transaction_file_gateway.dart` | 121 | `09f1a7d8e0951be607a7eac62fb7b93b780853845594810852ac1cd4272d0e11` |
| `event_builder_v2_template_sheet.dart` | 354 | `31f40525d4252f4eaa42439fc9db712b45ffa6e627bd83e4c57968e9036ba03f` |
| `scene_action_builder.dart` | 283 | `f4979e88a0f2d188c567491ddb63654cce9b2b4c7ef25b1dfbe2aa6a76fb4bd6` |
| `scene_action_inspector.dart` | 77 | `f36587f4b8ce6c60f02f62d72c4cac6f3aaa553b1d59c948b3b9e32dae8c92c2` |
| `event_builder_v2_template_sheet_test.dart` | 142 | `c21d773539dff1e040b8f9cc9947c3c9f84b7a9fcbc234e483b64f704670aba3` |
| `narrative_template_catalog_test.dart` | 202 | `cf0e035b5e6118cee87ade9b27eef9ebb441ffa55c21939e89d073c2a81bca94` |
| `narrative_template_transaction_recovery_test.dart` | 191 | `0b421a70e2926221551b65e2c5114dba25ef8aa9740ae26f81345c5282e54f6b` |
| `scene_action_builder_test.dart` | 113 | `dc35c620ed33107d80f610b9003e1d3a28c4b3c35d25340def7f760a9941d6c7` |
| `narrative_action_template_runtime_integration_test.dart` | 157 | `9121e7298c679ee2a85726c0f305ae0e714ec1fb622942d45f22f000fe8ca9ad` |

Le présent Evidence Pack est lui-même le onzième fichier créé et contient son propre contenu intégral.

## Commandes et résultats exacts

### Tests ciblés

```text
cd packages/map_core
dart test test/narrative_command_catalog_test.dart test/scene_authoring_operations_test.dart test/scene_runtime_dry_run_preview_test.dart
+63: All tests passed!

cd packages/map_editor
flutter test test/narrative_template_catalog_test.dart test/narrative_template_transaction_recovery_test.dart test/scene_action_builder_test.dart test/event_builder_v2_template_sheet_test.dart test/ui/canvas/event_builder_v2_product_route_test.dart
+42: All tests passed!

flutter test test/scenes_workspace_shell_test.dart
+89: All tests passed!

flutter test test/ui/canvas/event_builder_v2_phase_k_visual_test.dart
+5: All tests passed!

cd examples/playable_runtime_host
flutter test test/narrative_action_template_runtime_integration_test.dart
+1: All tests passed!
```

Gate Phase 3 déjà relancé pendant le lot :

```text
cd packages/map_runtime
flutter test test/scene_branch_merge_runtime_integration_test.dart test/narrative_command_save_load_integration_test.dart
+3: All tests passed!
```

### Suites complètes et incidents isolés

```text
cd packages/map_editor
flutter test --reporter failures-only
+4000 -1: Some tests failed.
```

Le seul échec de la passe finale a produit les artefacts de `test/border_map_editing/border_visual_goldens_test.dart`, chantier extérieur à NSC-38. Relance immédiate :

```text
flutter test test/border_map_editing/border_visual_goldens_test.dart --reporter expanded
+3: All tests passed!
```

Une première suite complète `map_core` avait terminé `+4163 -2`; les dernières lignes concernaient les tests `stone_chain`. La relance isolée suivante a été verte :

```text
dart test test/border/stone_chain_line_border_resolver_test.dart --reporter expanded
+94: All tests passed!
```

La suite complète finale confirme que les deux échecs étaient transitoires et hors Narrative :

```text
dart test --reporter failures-only
+4165: All tests passed!
```

### Analyse

```text
cd packages/map_core && dart analyze
No issues found!

cd packages/map_runtime && flutter analyze
No issues found!

cd examples/playable_runtime_host && flutter analyze
No issues found! (ran in 7.1s)

cd packages/map_editor
flutter analyze lib/src/application/services/narrative_template_catalog.dart lib/src/infrastructure/repositories/narrative_template_transaction_file_gateway.dart lib/src/ui/canvas/events_v2 lib/src/ui/canvas/scenes/scene_action_builder.dart lib/src/ui/canvas/scenes/scene_action_inspector.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart
No issues found! (ran in 7.7s)
```

L’analyse complète éditeur trouve 12 diagnostics : une info NSC-38 corrigée immédiatement, puis 11 warnings dans `dialogue_studio_dialogs.dart`, fichier déjà modifié par le chantier concurrent et exclu du commit. L’analyse ciblée finale NSC-38 est donc verte ; le package complet conserve ces warnings externes.

### Build

```text
cd packages/map_editor
flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## Passes indépendantes exigées

| Passe locale nommée | Verdict |
|---|---|
| Audit / Architecture | PASS : une commande reste liée à un backend/wire canonique ; Event ne duplique aucune action et Map garde la propriété du physique. |
| Implémentation | PASS : formulaire, dix templates, preview, transaction durable, reprise Map et undo sont branchés sur la route produit. |
| Tests | PASS ciblé ; la suite complète éditeur conserve un échec Border non reproductible, isolé vert. |
| Build / Validation | PASS : analyses ciblées core/editor/runtime/host vertes et build macOS réussi. |
| Critique finale | PASS avec limites honnêtes : les mécaniques non prouvées restent bloquées et les statuts FG ne sont pas surévalués. |

## Gate de phase 3

La phase 3 peut être proposée **DONE** : les lots NSC-30 à NSC-38 sont committés séparément ; Dialogue outcome/Combat outcome, Branch/Merge/End, conséquences persistantes, commandes interactives et templates Event→Scene→Action disposent de preuves d’authoring, de sérialisation, de planification et d’exécution. Le test host ferme en plus la persistance et l’idempotence après reload.

## Limites et risques conservés

- Infirmière et badge reward sont des templates de découverte `unsupported`; les activer exige les lots mécaniques correspondants.
- Le catalogue boutique reste un contrat externe/legacy tant qu’un registre Shop projet canonique n’existe pas.
- Le brouillon reprend le formulaire après navigation Map, mais la sélection automatique de la source nouvellement créée dépend encore du bridge Map existant ; aucune source n’est créée silencieusement.
- La transaction est atomique au niveau du projet Event+Scene. La Map n’entre volontairement jamais dans cette transaction, puisqu’elle doit être enregistrée avant le retour au template.
- Les deux goldens Phase 1 sont des changements intentionnels de la route produit. Le golden historique Phase K reste byte-compatible lorsque l’action gabarit n’est pas proposée.
- Le host importe le service éditeur par chemin source dans un test uniquement afin de prouver l’identité du générateur sans ajouter une dépendance Flutter plugin au host de production.

## Auto-critique finale

- Le premier placement du CTA dans un bandeau supérieur cassait la géométrie de référence ; il a été retiré au profit de la bibliothèque existante.
- Un bouton désactivé initialement rendu sans callback modifiait le focus et le golden Phase K ; la critique finale l’a supprimé de ce cas et les tests isolés sont redevenus verts.
- Le provider de brouillon local au widget n’aurait pas survécu au changement de workspace ; il a été remplacé avant clôture par un provider qualifié par projet.
- Aucun statut mécanique ne doit être inféré du seul fait que l’UI sait afficher un template. Le support reste calculé depuis `NarrativeCommandCatalog`.

## État Git final attendu

- Un seul commit NSC-38 contient exclusivement les fichiers de cet inventaire et ce rapport.
- Les changements Selbrume/Dialogue/runtime concurrents restent présents et inchangés dans le worktree après le commit.
- Aucun push n’est effectué, car la demande porte sur un commit par lot et non sur la publication distante.

## Prochaine étape proposée, non implémentée

Commencer la phase 4 par `NSC-40 — Cycle de vie Event complet`, en conservant Event V2 comme unique chemin d’authoring et en ajoutant rename/duplicate/delete protégé/publish/unpublish/activation avec transaction, recovery et undo.
