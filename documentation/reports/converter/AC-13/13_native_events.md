# AC-13 — Sous-ensemble d’événements natifs

## Verdict et portée de la revue

Implémentation livrée pour revue, avec trois traces EV-A/B/C converties depuis des fichiers RMXP originaux synthétiques, relues strictement au format natif, exécutées par le vrai runtime puis sauvegardées et chargées par une nouvelle instance de `FileGameSaveRepository`. Le domaine reste PARTIAL : la conversion de jeu entier, les événements Kanto et la parité de toute instruction Essentials ne sont pas certifiés.


État actuel au 13 octobre : voir le complément « BGM attesté et pickup ETHER réel » en fin de rapport. Il ajoute la publication r4, le vrai parcours Studio et une sauvegarde/reprise disque ETHER ; les paragraphes de livraison initiale ci-dessous restent historiques. Domaine PARTIAL.
La grammaire porte textes, choix et annulation typée, pages conditionnelles, switches booléens, self-switches et transferts constants vers des cartes sélectionnées. Un bloc inconnu désactive l’événement entier. Les données sources restent conservées sous forme inerte, avec références et SHA, même pour une quarantaine intégrale. Ruby exécuté : 0 ; appels IA dans la conversion : 0. Les fixtures distribuées sont originales ; aucun asset Pokémon du corpus privé n’entre dans Git.

La politique native de choix/cancel et les capacités nécessaires pour avancer ont été approuvées explicitement par Yoahn dans le fil, avant extension du modèle cible. La commande secondaire rejoint une issue déclarée ou reste désactivée selon la source. L’autorisation de faire tous les lots et de commiter entre lots permet d’enchaîner AC-14 ; la restriction du kit sur une suite implicite ne remplace pas cette instruction directe. La règle directe sans commentaires prévaut sur le §3 de `codex_rule.md` ; aucun commentaire de code ajouté.

EV-B qualifie la frontière **après interaction terminée**. Le sac et les facts natifs restent transactionnels jusqu’à la fin de scène. Essentials ajoute l’objet avant ses messages : cette chronologie intermédiaire est explicitement non qualifiée (`sourceBagMutationTimingQualified=false`, `fullPickupParityQualified=false`). La conversion n’annonce pas cette différence comme une fidélité totale. Sauvegarder pendant les deux messages est refusé, sans créer de fichier.

## Audit initial et décisions

Base AC-12 : `0ec7e5b7f74e8e71bb49429ebea9cfed232dc25f`, branche `main`, index vide, périmètre Converter initialement propre. Les trois changements étrangers initiaux sont le recorder Studio, le matériel spatial et son test. D’autres chantiers Android/iOS/bordures ont évolué parallèlement et restent hors commit. La qualification finale utilise un snapshot de HEAD auquel seuls les 88 fichiers AC-13 sont superposés ; toutes les bibliothèques étrangères reprennent leur version HEAD.

L’IR antérieur conservait pages et commandes brutes mais ne qualifiait pas la sélection de la dernière page vraie, la page vide masquante, la touche cancel, le refus réel d’un gain ni le cycle complet de sauvegarde disque. Les contrats modernes `EventV2`, scenes, facts, authoring API et save repository sont les cibles retenues. Aucun adaptateur de compatibilité V1 n’est introduit. Une suspicion de perte globale des facts a été retirée après lecture du véritable repository de sauvegarde.

Le corpus autorisé est `/Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto`. Archive Scripts de 1 080 290 octets : `3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d`. Les sections Ruby sont décompressées statiquement en texte inerte hors Git, jamais interprétées. Oracles précis :

- `045 Game_Event`, SHA `8c11fb7f170df5ca2aff17725e1dbed031c94deebabdbbae69dd926e24acafa7`, lignes 78–84 : switch avec préfixe `s:` ; sélection et définition d’empreinte 16–18, `overTrigger?` 133–139.
- `034 Interpreter_Commands`, SHA `ec927a007bee1889223dbc8b3de115f062a5308ab4410f87dab965eef3032561`, lignes 224–277 : choix adjacents/hide/rename ; 395–401 : switches dynamiques. Une expression dynamique est refusée.
- `042 Game_Map`, lignes 222–249 : passages et test direction 0 ; 292–299 : counter. `044 Game_Character`, 43–44, 92–106, 249–251 : taille, coordonnées et collision des événements non vides. `046 Game_Player`, 330–363, 367–378, 387–410 : interaction courante/devant/counter/touch.
- Section `241`, lignes 668–719 : `pbItemBall`, gain avant messages, deux textes, couleur item, fanfare et icône sac. Les dépendances `items.dat`, `metadata.dat`, Windowskin et assets concernés sont lues et conservées avec leurs identités exactes.

La roadmap mécanique FG-080..094 et FG-014/067/068/083 a été consultée ; elle n’est pas modifiée et aucune clôture globale FG n’est proposée. Flame 2.0.0-dev.1 : documentation configurée recherchée sans résultat pertinent, puis patterns installés et existants inspectés. Les décisions gameplay restent hors Flame.

## Contrats et garanties obtenues

- Pages évaluées en priorité décroissante, même si la dernière vraie est vide ; guards exclusifs entre pages et fact predicates complémentaires `isTrue`/`isFalse` consommés par le runtime.
- Self-switches avec identité stable du projet source, de la carte, de l’événement et de la clé ; switches globaux partagés sans confondre deux self-switches.
- AST source étroit et littéral ; blocs inconnus, récompenses dépendantes et références dynamiques désactivés entièrement. Traces et raw data conservés.
- Arrivée d’un warp vérifiée sur la carte native finale : bounds, collisions, entités et direction ; direction 0 conservée, fade aller/retour qualifié, aucune boucle sur 120 ticks après arrivée.
- Empreintes non 1×1, contre-comptoir, interaction sans graphic ou through inadaptée, touch non équivalente : quarantaine explicite. Six régressions ont d’abord échoué, puis sont passées après correction ; pas de voisinage source approximatif présenté comme support natif.
- Gains d’objet : delta réellement appliqué, refus d’overflow, rollback du groupe entier. Au refus, aucun texte de succès, son, fact ou disparition. Après interaction réussie, objet exactement une fois, PNJ retiré, collision libérée et save/load sans duplication.
- Feedback typé : segments de texte, couleur qualifiée, icône source PNG, cadence 25 ms et délai automatique de 2 s après révélation. Cue audio non bouclée, volume source 0.8 consommé par l’adapter audio natif. Audibilité et parité de police/fenêtre non qualifiées.
- Import audio canonique `scene.dialogue.audioMedia.import` : handles fermés, probe audio MIME/durée, asset/media ID, logical path et refus précis. Les données mutables de Presentation ne sont pas un raccourci de cet import.
- Writer autonome : strict reopen, manifest/assets/maps/Yarn/media/catalogues et hashes contrôlés ; source chunks inertes bornés à 262 144 octets avec identité, offset, longueur et SHA. Dépendances conservées même lorsqu’aucun pickup ne peut être adapté. Les quotas sont conservateurs, sans les relâcher pour faire passer le corpus.

## Traces de référence et transports

| Référence | Preuve fraîche | Limite |
| --- | --- | --- |
| EV-A | Textes/choix/cancel, ordre des pages, switch global partagé, self-switch indépendant, save disque puis instance neuve | Allowlist littérale ; aucune expression Ruby exécutée |
| EV-B | Deux messages, icône/couleur/cadence/cue ; gain refusé sans effets ; gain réussi unique, self A, disparition/collision libérée ; save/load disque | Commit des conséquences à la fin de l’interaction ; pas de timing intermédiaire Essentials |
| EV-C | PNJ visible bloque puis warp constant, direction 0, fade, nouvel emplacement sauvegardé/rechargé et absence de boucle | Transferts constants vers cartes sélectionnées seulement |
| EVT-01..06 | Couvertes par core, adapters, six traces runtime sans skip, refus entiers et preuves de reload | Sous-ensemble déclaré ; aucune certification du jeu complet |
| API/JSONL | 26 tests, plans, discover, apply, refus et strict reload | Pas de preuve par simple persistance JSON générique |
| Éditeur | 7 tests gateway/dialog/inspector et parcours réel Studio EV-B | Cancel editor couvert par tests widgets ; pas de nouveau schéma caché dans l’UI |
| MCP vivant | Build/check ; describe expose les trois actions ; 3 tests stdio sans skip, idempotence, quatre refus, close/open/query | Suite MCP globale non certifiée |

## Application et preuves visibles

Le build release existe et a été lancé : `/Users/karim/Project/pokemonProject/apps/avelune_converter/build/ac13-qualified-release/Avelune Converter.app`. Le parcours réel dans cette application choisit le dossier Kanto, limite la sélection à Route 9, lance la conversion et obtient « Structure native vérifiée ». L’inventaire source compte 24 085 fichiers et 383 cartes. La sélection de toutes les cartes a rencontré un budget de reconnaissance, puis la sélection Route 9 a permis la conversion ; le rapport ne confond pas ce budget avec la qualification du jeu entier.

Le writer de cette conversion a produit un projet natif de 83 fichiers : une carte de 72×61, cinq couches, 315 décors placés, sept ressources de décor proposées, huit clips du personnage et son départ (35,22). Les 16 événements de Route 9 sont quarantinés, zéro adapté. Les cinq candidats pickup notamment requièrent une gestion de BGM actif non portée ici ; aucun entraînement, combat, récompense ou transfert Kanto n’est annoncé fonctionnel. Le fond largement vide correspond au fichier source ; ce n’est pas une reconstruction artistique.

Projet brut disponible : `/Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - AC13 20261012/Projet pour Avelune Studio`. La copie utilisée dans Studio a été renommée par le vrai workflow de carte « Route 9 — modifiée dans Studio AC13 », enregistrée, fermée puis relancée dans un nouveau processus. Le titre est retrouvé, et le mode test rend le vrai personnage Kanto et ses décors. Copie modifiée disponible : `/Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - AC13 20261012/Projet modifié dans Studio` (85 fichiers après journalisation authoring). Le titre de projet contient un doublon issu de la saisie d’automatisation ; le titre de carte est propre. Aucun correctif produit déduit de cette saisie.

Studio EV-B : processus 91063 puis nouveau processus 99196. Carte renommée « AC13 — ramassage modifié dans Studio » puis relue après fermeture. Dans le vrai mode test : déplacement vers le pickup, deux textes avec icône, confirmation, disparition, puis marche sur son ancienne cellule. Les captures et le log `npc_presence_applied=false` étayent la disparition. Les replays vidéo de 30 s ont respectivement 282/287 frames, 18/13 frames écartées, zéro erreur. Le save du bouton « Enregistrer le test » est seulement en mémoire pour la session ; la preuve de persistance disque est celle des tests `FileGameSaveRepository`, pas celle de ce bouton.

Studio Kanto : processus 6275 puis nouveau processus 17295. Projet actif exact contrôlé par extension, titre relu dans le nouveau processus et test réel affiché. Capture du projet rouvert : 29 frames, une écartée, zéro erreur ; capture du playtest : 30 frames, zéro écartée, zéro erreur. Un essai supplémentaire de marche CUA a échoué `noWindowsAvailable` : ce mouvement n’est pas annoncé qualifié. Le home a affiché une mention lecture seule au démarrage de la reprise ; le parcours de carte montre le titre enregistré et le bouton de test. Aucun nouveau changement de contenu après la reprise n’a été présenté comme preuve de modification.

Captures hors Git :

- `/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Converter AC13 captures 20261012/captures/studio-kanto-route9-reopened.png`.
- `/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Converter AC13 captures 20261012/captures/studio-kanto-route9-playtest.png`.
- Enregistrements : même racine, `recordings/take-o9H2tq`, `take-nlGwMi`, `take-p36cO3`, `take-JQm5m5`, `take-NZPvoN` et leurs `metadata.json`.

Le recorder de capture a été adapté uniquement dans le snapshot temporaire : une racine et son marqueur exacts, sans supprimer ses contrôles canoniques, de liens symboliques et de confinement. Le recorder host étranger reste hors scope. `captureActivity` force un cycle actif debug et indique `nativeLifecycleQualified=false`. La capture n’est pas une certification des pauses/reprises macOS. Les runs supervisés ont été terminés ou se sont terminés ; seul un PID appartenant au run, revérifié par UID/date/commande, a été ciblé. Aucune opération sur les PID protégés.

Contrôle final : hashes des 83 fichiers du projet source natif Kanto et des 97 fichiers EV-B inchangés après les parcours Studio. Reçu `/private/tmp/avelune-ac13-root-final-audit-20261012.json`. Les données RMXP d’origine sont restées en lecture seule. La staging du writer n’est pas encore une publication robuste AC-15 ; les copies visibles sont une matérialisation explicite de cette conversion, hors Git.

## Commandes et résultats exacts

Chaque commande suivante a son cwd, ses descendants, son log et ses hashes dans le reçu indiqué. Les réexécutions de mêmes suites ne sont pas additionnées en un faux total unique. Les suites complètes de tous les packages du monorepo n’ont pas été lancées ; cette qualification porte les zones modifiées et les parcours mentionnés.

### Core source : 84/84

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/packages/avelune_converter_core`

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/source_events_test.dart test/source_normalization_test.dart test/source_semantics_test.dart -r expanded
```

Résultat : exit 0 ; 8.236 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-converter-ac13-core-final-green-20261012-01.json`.

### Adapters/writer/workflow : 207/207

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/packages/avelune_converter_adapters`

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/source_event_study_composer_test.dart test/source_event_projection_test.dart test/source_event_arrival_validation_test.dart test/source_event_character_import_test.dart test/source_event_item_bindings_test.dart test/source_pickup_feedback_binding_test.dart test/native_audio_artifact_test.dart test/native_project_writer_test.dart test/converter_workflow_test.dart -r expanded
```

Résultat : exit 0 ; 40.349 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-converter-ac13-adapters-final-green-20261012-02.json`.

### Contrats map_core : 18/18

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/packages/map_core`

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/dialogue_line_feedback_test.dart test/scene_dialogue_choice_policy_test.dart test/scene_project_diagnostics_test.dart -r expanded
```

Résultat : exit 0 ; 3.57 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-converter-ac13-scene-contract-final-green-20261012-01.json`.

### API et JSONL : 26/26 après accolades

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/packages/map_authoring`

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/domains/narrative/dialogue_audio_media_actions_test.dart test/domains/narrative/dialogue_audio_media_jsonl_test.dart test/domains/narrative/scene_dialogue_choice_policy_actions_test.dart test/domains/narrative/scene_dialogue_line_feedback_actions_test.dart test/domains/narrative/scene_pre_session_actions_test.dart
```

Résultat : exit 0 ; 4.308 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-ac13-root-authoring-braces-green-20261012-01.json`.

### Runtime : 93/93, dont 6 traces source sans skip

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/packages/map_runtime`

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter test --no-pub test/source_converted_pickup_trace_test.dart test/source_converted_event_traces_test.dart test/dialogue_choice_cancellation_test.dart test/dialogue_line_feedback_test.dart test/dialogue_feedback_playback_test.dart test/scene_consequence_runtime_writer_test.dart test/playable_map_game_dialogue_outcome_scene_integration_test.dart test/narrative_scene_runtime_execution_test.dart test/phase_a_golden_battle_slice_smoke_test.dart --reporter expanded
```

Résultat : exit 0 ; 21.401 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-ac13-root-runtime-final-green-20261012-01.json`.

### Converter UI : 10/10

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/apps/avelune_converter`

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter test --no-pub test/converter_app_test.dart -r expanded
```

Résultat : exit 0 ; 36.974 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-converter-ac13-app-final-green-20261012-01.json`.

### Éditeur : 7/7

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/packages/map_editor`

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter test --no-pub test/application/scene_dialogue_choice_policy_authoring_gateway_test.dart test/ui/canvas/scenes/scene_dialogue_choice_policy_dialog_test.dart test/ui/canvas/scenes/scene_dialogue_choice_policy_inspector_test.dart --reporter expanded
```

Résultat : exit 0 ; 33.121 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-ac13-root-editor-final-green-20261012-01.json`.

### Player UI : 3/3

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/packages/map_player_ui`

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter test --no-pub test/player_dialogue_feedback_test.dart --reporter expanded
```

Résultat : exit 0 ; 20.775 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-ac13-root-player-ui-final-green-20261012-02.json`.

### MCP build

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/tools/pokemap_mcp`

```text
npm run build
```

Résultat : exit 0 ; 1.85 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-ac13-root-mcp-build-20261012-01.json`.

### MCP check

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/tools/pokemap_mcp`

```text
npm run check
```

Résultat : exit 0 ; 1.876 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-ac13-root-mcp-check-20261012-01.json`.

### MCP vivant : 3/3, sans skip

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/tools/pokemap_mcp`

```text
node --import tsx --test --test-concurrency=1 test/scene_dialogue_feedback_stdio.test.ts test/config.test.ts
```

Résultat : exit 0 ; 10.782 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-ac13-root-mcp-live-20261012-01.json`.

### Release Converter, 103.6 MB

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/apps/avelune_converter`

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter build macos --release --no-pub
```

Résultat : exit 0 ; 93.596 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-converter-ac13-app-release-build-20261012-01.json`.

### Studio EV-B premier lancement

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/apps/avelune_studio`

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter run -d macos --debug --no-pub -t dev/marionette_main.dart '--dart-define=MARIONETTE_PROJECT_PATH=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Converter AC13 pickup 20261012' '--dart-define=MARIONETTE_CAPTURE_ROOT=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Converter AC13 captures 20261012'
```

Résultat : exit 0 ; 423.007 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-ac13-studio-first-launch-20261012-01.json`.

### Studio EV-B nouveau processus

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/apps/avelune_studio`

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter run -d macos --debug --no-pub -t dev/marionette_main.dart '--dart-define=MARIONETTE_PROJECT_PATH=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Converter AC13 pickup 20261012' '--dart-define=MARIONETTE_CAPTURE_ROOT=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Converter AC13 captures 20261012'
```

Résultat : exit 0 ; 168.804 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-ac13-studio-second-launch-20261012-01.json`.

### Studio Kanto premier lancement

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/apps/avelune_studio`

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter run -d macos --debug --no-pub -t dev/marionette_main.dart '--dart-define=MARIONETTE_PROJECT_PATH=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Kanto Route 9 - AC13 20261012' '--dart-define=MARIONETTE_CAPTURE_ROOT=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Converter AC13 captures 20261012'
```

Résultat : exit 0 ; 379.442 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-ac13-studio-kanto-first-launch-20261012-01.json`.

### Studio Kanto nouveau processus

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/apps/avelune_studio`

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter run -d macos --debug --no-pub -t dev/marionette_main.dart '--dart-define=MARIONETTE_PROJECT_PATH=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Kanto Route 9 - AC13 20261012' '--dart-define=MARIONETTE_CAPTURE_ROOT=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Converter AC13 captures 20261012'
```

Résultat : exit 0 ; 126.384 s ; survivants confirmés 0 ; PID protégés inchangés true. Reçu : `/private/tmp/avelune-ac13-studio-kanto-reopen-20261012-01.json`.

### Analyses et échecs conservés dans les preuves

Core Converter, adapters, nouvel import audio authoring, editor et player UI : `No issues found!`, exit 0. Analyses root supplémentaires sur tous les fichiers modifiés : map_core conserve une INFO `unnecessary_library_name` présente à HEAD ; runtime conserve neuf INFO de style sur constructeurs/null-aware déjà présentes à HEAD, zéro warning/error, exit 0. L’INFO introduite par une accolade manquante dans l’import audio a été corrigée ; les 26 tests authoring ont été rejoués puis le fichier réanalysé sans issue. Aucun nettoyage des INFO étrangères au lot.

L’exécution Player UI initiale a échoué à la compilation : résolution isolée image 4.11.0 avec archive 4.0.9, `ZLibDecoder.decodeLazy` indisponible. Le snapshot a repris le lockfile existant non versionné de ce package, puis résolution offline (image 4.9.2), sans changer les dépendances produit. Nouvelle exécution : 3/3, exit 0. Reçus `avelune-ac13-root-player-ui-final-green-20261012-01.json` (exit 1) et `-02.json` (exit 0).

Les RED d’empreinte/interactions (3+1+2) et de prédicats booléens de présence ont été utiles, corrigés et rejoués. Les 207 tests adapters et 93 runtime correspondent aux corrections finales, sans skip des six traces source. Le test MCP global `conformance_security` possède une attente de catalogue antérieure aux actions déjà présentes à HEAD : sa passe de reconnaissance n’a pas été comptée comme verte. L’attente étrangère au lot n’a pas été modifiée. `get_logs` Marionette a renvoyé une erreur serveur ; logs des runners supervisés utilisés. Deux taps sur des boutons cachés par le tiroir de cartes ont échoué ; le tiroir a été fermé puis les boutons visibles employés. Une copie de capture a d’abord échoué car le sous-dossier destination n’existait pas ; création du sous-dossier appartenant à ce run puis copie réussie.

Build release : exit 0, bundle 103.6 MB et parcours réel prouvé. Avertissement macOS de dépréciation `kSecUseAuthenticationUI` visible dans la toolchain ; aucun échec de build présenté comme succès. Trois descendants `ibtoold` de ce build ont été arrêtés après vérification d’identité ; aucun survivant confirmé. Les autres reçus de test cités ont zéro signal et zéro survivant. Pas de kill par nom et pas de nettoyage de serveurs étrangers.

Les commandes d’analyse complètes sont conservées dans les reçus suivants :

- `/private/tmp/avelune-ac13-root-map_authoring-final-analyze-20261012-01.json` : `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib/map_authoring.dart lib/src/application/map_mutation_dispatcher.dart lib/src/domains/narrative/dialogue_source_guards.dart lib/src/domains/narrative/scene_actions.dart lib/src/parity/full_authoring_parity.dart lib/src/tooling/jsonl_worker.dart test/domains/narrative/scene_pre_session_actions_test.dart lib/src/domains/narrative/dialogue_audio_media_actions.dart test/domains/narrative/dialogue_audio_media_actions_test.dart test/domains/narrative/dialogue_audio_media_jsonl_test.dart test/domains/narrative/scene_dialogue_choice_policy_actions_test.dart test/domains/narrative/scene_dialogue_line_feedback_actions_test.dart` ; exit 0.

- `/private/tmp/avelune-ac13-root-map_core-final-analyze-20261012-01.json` : `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib/map_core_domain.dart lib/src/authoring/scene_authoring_operations.dart lib/src/diagnostics/scene_diagnostics.dart lib/src/dialogue/runtime_dialogue_document.dart lib/src/models/scene_asset.dart lib/src/operations/project_dialogue_refs.dart lib/src/runtime/scene_runtime_plan.dart lib/src/runtime/scene_runtime_plan_builder.dart test/scene_project_diagnostics_test.dart lib/src/dialogue/scene_dialogue_choice_policy_validation.dart lib/src/dialogue/scene_dialogue_line_policy_validation.dart lib/src/models/dialogue_line_feedback.dart test/dialogue_line_feedback_test.dart test/scene_dialogue_choice_policy_test.dart` ; exit 0.

- `/private/tmp/avelune-ac13-root-map_editor-final-analyze-20261012-01.json` : `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib/src/application/authoring_api/authoring_query_adapter.dart lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/application/authoring_api/scene_dialogue_choice_policy_authoring_gateway.dart lib/src/ui/canvas/scenes/scene_dialogue_choice_policy_dialog.dart test/application/scene_dialogue_choice_policy_authoring_gateway_test.dart test/ui/canvas/scenes/scene_dialogue_choice_policy_dialog_test.dart test/ui/canvas/scenes/scene_dialogue_choice_policy_inspector_test.dart` ; exit 0.

- `/private/tmp/avelune-ac13-root-map_player_ui-final-analyze-20261012-01.json` : `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib/src/player/player_dialogue_overlay.dart lib/src/player/player_dialogue_surface.dart test/player_dialogue_feedback_test.dart` ; exit 0.

- `/private/tmp/avelune-ac13-root-map_runtime-final-analyze-20261012-01.json` : `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib/map_runtime.dart lib/src/application/dialogue_runtime_models.dart lib/src/application/narrative_scene_runtime_execution.dart lib/src/application/parse_yarn_dialogue.dart lib/src/application/runtime_manifest_tilesets.dart lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart lib/src/presentation/flame/dialogue_overlay_component.dart lib/src/presentation/flame/playable_map_game.dart lib/src/presentation/flutter/dialogue_presentation_snapshot.dart test/narrative_scene_runtime_execution_test.dart test/playable_map_game_dialogue_outcome_scene_integration_test.dart test/scene_consequence_runtime_writer_test.dart lib/src/application/dialogue_feedback_playback_port.dart lib/src/presentation/flame/flame_dialogue_feedback_playback_adapter.dart test/dialogue_choice_cancellation_test.dart test/dialogue_feedback_playback_test.dart test/dialogue_line_feedback_test.dart test/source_converted_event_traces_test.dart test/source_converted_pickup_trace_test.dart` ; exit 0.

- `/private/tmp/avelune-ac13-root-authoring-braces-analyze-20261012-01.json` : `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib/src/domains/narrative/dialogue_audio_media_actions.dart` ; exit 0.

- `/private/tmp/avelune-converter-ac13-adapters-final-analyze-20261012-03.json` : `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib test/source_event_projection_test.dart` ; exit 0.

- `/private/tmp/avelune-converter-ac13-core-final-analyze-20261012-02.json` : `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib test/source_events_test.dart` ; exit 0.

## Inventaire complet et zones modifiées

Les 88 fichiers ci-dessous sont l’implémentation AC-13. Pour un fichier déjà suivi, les ancres `+ligne,nombre` sont les zones exactes de son diff par rapport à la base AC-12 ; pour un fichier créé, les déclarations structurantes et son nombre de lignes identifient les zones pertinentes. Le diff Git et les sources sont canoniques : aucun snapshot intégral de code recopié ici.

| Fichier | Zones / déclarations | Raison et impact attendu |
| --- | --- | --- |
| `apps/avelune_converter/lib/converter_app.dart` | Hunks +1137,2, +1428, +1431,4, +1602, +1605,4, +1626,13, +1660,13, +1935,2 | Rapport utilisateur des événements adaptés/quarantinés et des pertes ; aucun pourcentage global de gameplay. |
| `apps/avelune_converter/test/converter_app_test.dart` | Hunks +47,83, +715, +723 | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | Hunks +19,6 | Projection bornée vers les contrats natifs, admission des bindings/assets, writer/reopen et workflow de quarantaine. |
| `packages/avelune_converter_adapters/lib/src/converter_workflow.dart` | Hunks +11, +809, +1069,2, +1212,10, +1539, +1607, +1610,13, +1629, +1631, +1668,7, +1754, +1757,22, +1813, +1889,0 | Projection bornée vers les contrats natifs, admission des bindings/assets, writer/reopen et workflow de quarantaine. |
| `packages/avelune_converter_adapters/lib/src/native_project_writer.dart` | Hunks +13, +20,2, +72,3, +96,2, +115,24, +248,12, +597,11, +612,3, +653,10, +676,18, +727, +759,10, +775,3, +819,4, +923, +952, +956,20, +1009,2, +1036,2, +1060,8, +1073,2, +1080,2, +1100,2, +1173, +1182, +1187,10, +1227,43, +1271,3, +1378,19, +1412,7, +1425,8, +1439,18, +1460,10, +1491,2, +1499, +1515,4, +1540,36, +1676, +1703,12, +1752,10, +1767,2 | Projection bornée vers les contrats natifs, admission des bindings/assets, writer/reopen et workflow de quarantaine. |
| `packages/avelune_converter_adapters/pubspec.yaml` | Hunks +16,4 | Projection bornée vers les contrats natifs, admission des bindings/assets, writer/reopen et workflow de quarantaine. |
| `packages/avelune_converter_adapters/test/converter_workflow_test.dart` | Hunks +11, +18,85, +1342,3, +1362,3 | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/avelune_converter_adapters/test/support/literal_tile_fixture.dart` | Hunks +48, +67,32, +175, +183,5, +209,4, +301,2, +309,29 | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/avelune_converter_adapters/test/support/native_writer_fixture.dart` | Hunks +120 | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/avelune_converter_core/lib/avelune_converter_core.dart` | Hunks +26 | AST / normalisation littérale des pages et commandes, identités et brut conservés ; moteur source jamais exécuté. |
| `packages/avelune_converter_core/lib/src/source_normalization.dart` | Hunks +314, +319,7, +332, +348, +622,5, +652,16 | AST / normalisation littérale des pages et commandes, identités et brut conservés ; moteur source jamais exécuté. |
| `packages/map_authoring/lib/map_authoring.dart` | Hunks +92 | Actions et guards canoniques de scène/dialogue, import audio, plans/idempotence, discover et transport JSONL. |
| `packages/map_authoring/lib/src/application/map_mutation_dispatcher.dart` | Hunks +38, +299,6 | Actions et guards canoniques de scène/dialogue, import audio, plans/idempotence, discover et transport JSONL. |
| `packages/map_authoring/lib/src/domains/narrative/dialogue_source_guards.dart` | Hunks +13,2, +26,16, +51,44 | Actions et guards canoniques de scène/dialogue, import audio, plans/idempotence, discover et transport JSONL. |
| `packages/map_authoring/lib/src/domains/narrative/scene_actions.dart` | Hunks +1,2, +9,4, +33,30, +138,46, +188, +601,93, +1927,56 | Actions et guards canoniques de scène/dialogue, import audio, plans/idempotence, discover et transport JSONL. |
| `packages/map_authoring/lib/src/parity/full_authoring_parity.dart` | Hunks +512,22, +1594,12 | Actions et guards canoniques de scène/dialogue, import audio, plans/idempotence, discover et transport JSONL. |
| `packages/map_authoring/lib/src/tooling/jsonl_worker.dart` | Hunks +24, +399,18 | Actions et guards canoniques de scène/dialogue, import audio, plans/idempotence, discover et transport JSONL. |
| `packages/map_authoring/test/domains/narrative/scene_pre_session_actions_test.dart` | Hunks +15,2 | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_core/lib/map_core_domain.dart` | Hunks +120,3 | Contrats purs typés cancel/feedback, validation et plan runtime ; références natives strictes. |
| `packages/map_core/lib/src/authoring/scene_authoring_operations.dart` | Hunks +839,3 | Contrats purs typés cancel/feedback, validation et plan runtime ; références natives strictes. |
| `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` | Hunks +71, +503,12, +516 | Contrats purs typés cancel/feedback, validation et plan runtime ; références natives strictes. |
| `packages/map_core/lib/src/dialogue/runtime_dialogue_document.dart` | Hunks +5, +120, +124, +148, +156, +164, +168, +307, +316, +320,3 | Contrats purs typés cancel/feedback, validation et plan runtime ; références natives strictes. |
| `packages/map_core/lib/src/models/scene_asset.dart` | Hunks +5, +925,86, +1018,12, +1033, +1043,34, +1085,3, +1098,3, +1109,3, +1121,3, +1132,3 | Contrats purs typés cancel/feedback, validation et plan runtime ; références natives strictes. |
| `packages/map_core/lib/src/operations/project_dialogue_refs.dart` | Hunks +158,14 | Contrats purs typés cancel/feedback, validation et plan runtime ; références natives strictes. |
| `packages/map_core/lib/src/runtime/scene_runtime_plan.dart` | Hunks +1, +128,2, +144,2, +200,2, +209,2, +290,2, +352, +380 | Contrats purs typés cancel/feedback, validation et plan runtime ; références natives strictes. |
| `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart` | Hunks +274,2 | Contrats purs typés cancel/feedback, validation et plan runtime ; références natives strictes. |
| `packages/map_core/test/scene_project_diagnostics_test.dart` | Hunks +8,23 | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_editor/lib/src/application/authoring_api/authoring_query_adapter.dart` | Hunks +2, +5,2, +278,21 | Gateway, choix d’annulation no-code et inspection de scènes via authoring ; exposition de la capacité cible. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | Hunks +27, +1673,45 | Gateway, choix d’annulation no-code et inspection de scènes via authoring ; exposition de la capacité cible. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart` | Hunks +4, +11, +43,11, +146,2, +172,2, +221,2, +332,2, +356,2, +420,2, +829,2, +838,2, +898,13, +912,4 | Gateway, choix d’annulation no-code et inspection de scènes via authoring ; exposition de la capacité cible. |
| `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` | Hunks +6, +95,13, +257,2, +310,2, +936,17 | Gateway, choix d’annulation no-code et inspection de scènes via authoring ; exposition de la capacité cible. |
| `packages/map_player_ui/lib/src/player/player_dialogue_overlay.dart` | Hunks +41, +45, +95,30 | Consommation réelle des segments/icônes/cadence par le dialogue visible, et refus des références manquantes. |
| `packages/map_player_ui/lib/src/player/player_dialogue_surface.dart` | Hunks +40, +52, +296,2, +343,2, +596,2 | Consommation réelle des segments/icônes/cadence par le dialogue visible, et refus des références manquantes. |
| `packages/map_runtime/lib/map_runtime.dart` | Hunks +151,4 | Exécution des choix/cancel/feedback et conséquences transactionnelles, refus des gains, facts et présence/collision. |
| `packages/map_runtime/lib/src/application/dialogue_runtime_models.dart` | Hunks +1,2, +10,4, +17, +26, +28, +51,4, +58, +63, +66, +89,61, +153,64, +234, +240, +242, +254, +276, +287, +304, +336, +342, +345, +355, +383, +402,3 | Exécution des choix/cancel/feedback et conséquences transactionnelles, refus des gains, facts et présence/collision. |
| `packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart` | Hunks +5, +77, +85,2, +98,2, +101,11, +158,11, +175,0 | Exécution des choix/cancel/feedback et conséquences transactionnelles, refus des gains, facts et présence/collision. |
| `packages/map_runtime/lib/src/application/parse_yarn_dialogue.dart` | Hunks +25 | Exécution des choix/cancel/feedback et conséquences transactionnelles, refus des gains, facts et présence/collision. |
| `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart` | Hunks +163,12 | Exécution des choix/cancel/feedback et conséquences transactionnelles, refus des gains, facts et présence/collision. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart` | Hunks +19 | Exécution des choix/cancel/feedback et conséquences transactionnelles, refus des gains, facts et présence/collision. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart` | Hunks +307,8, +316,13 | Exécution des choix/cancel/feedback et conséquences transactionnelles, refus des gains, facts et présence/collision. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart` | Hunks +18,2, +27,2, +60,2 | Exécution des choix/cancel/feedback et conséquences transactionnelles, refus des gains, facts et présence/collision. |
| `packages/map_runtime/lib/src/presentation/flame/dialogue_overlay_component.dart` | Hunks +1,4, +7, +10, +25,3, +42,11, +90, +99, +108,9, +118,22, +154,39, +196, +198,20, +219,11, +231,2, +246, +267, +277,9, +289, +300,16, +359, +373,15, +438,17, +468, +474,5, +487, +491, +497, +510, +518, +521 | Exécution des choix/cancel/feedback et conséquences transactionnelles, refus des gains, facts et présence/collision. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Hunks +27, +140, +276,2, +683,3, +700,11, +3870,2, +4287,4, +10956,9, +11712, +11718,5, +11737,16 | Exécution des choix/cancel/feedback et conséquences transactionnelles, refus des gains, facts et présence/collision. |
| `packages/map_runtime/lib/src/presentation/flutter/dialogue_presentation_snapshot.dart` | Hunks +1,4, +37,3, +52,3, +63, +71, +74,2, +100,4, +175, +206,3 | Exécution des choix/cancel/feedback et conséquences transactionnelles, refus des gains, facts et présence/collision. |
| `packages/map_runtime/test/narrative_scene_runtime_execution_test.dart` | Hunks +9,293, +953,70 | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_runtime/test/playable_map_game_dialogue_outcome_scene_integration_test.dart` | Hunks +2, +21,9, +35,38, +135, +137, +158,2, +164, +206, +229,4, +271, +276,5, +294, +323, +328,6, +340,10, +376, +379, +387, +413, +417,2, +442,2, +446, +482,2, +486,2, +617,3, +622 | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_runtime/test/scene_consequence_runtime_writer_test.dart` | Hunks +691,107 | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/avelune_converter_adapters/lib/src/source_event_arrival_validation.dart` | Nouveau, 73 lignes ; SourceEventArrivalValidator | Projection bornée vers les contrats natifs, admission des bindings/assets, writer/reopen et workflow de quarantaine. |
| `packages/avelune_converter_adapters/lib/src/source_event_character_import.dart` | Nouveau, 401 lignes ; SourceEventCharacterImport, SourceEventCharacterImporter | Projection bornée vers les contrats natifs, admission des bindings/assets, writer/reopen et workflow de quarantaine. |
| `packages/avelune_converter_adapters/lib/src/source_event_item_bindings.dart` | Nouveau, 570 lignes ; SourceEventItemUseParity, SourceEventItemBindingLimits, SourceEventItemBinding, SourceEventItemBindings, SourceEventItemBindingResolver, _ItemInvalid, _ItemReader | Projection bornée vers les contrats natifs, admission des bindings/assets, writer/reopen et workflow de quarantaine. |
| `packages/avelune_converter_adapters/lib/src/source_event_projection.dart` | Nouveau, 1235 lignes ; SourceEventCharacterBinding, SourceEventProjection, SourceEventProjector, _Guard, _ProjectionBuilder, _SceneBuilder | Projection bornée vers les contrats natifs, admission des bindings/assets, writer/reopen et workflow de quarantaine. |
| `packages/avelune_converter_adapters/lib/src/source_event_study_composer.dart` | Nouveau, 492 lignes ; SourceEventStudyComposition, SourceEventStudyComposer | Projection bornée vers les contrats natifs, admission des bindings/assets, writer/reopen et workflow de quarantaine. |
| `packages/avelune_converter_adapters/lib/src/source_pickup_feedback_binding.dart` | Nouveau, 545 lignes ; SourcePickupBindingUnavailable, SourcePickupFeedbackBinding, SourcePickupFeedbackResolver | Projection bornée vers les contrats natifs, admission des bindings/assets, writer/reopen et workflow de quarantaine. |
| `packages/avelune_converter_adapters/test/native_audio_artifact_test.dart` | Nouveau, 55 lignes ; tests/fixtures et générateur | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/avelune_converter_adapters/test/source_event_arrival_validation_test.dart` | Nouveau, 262 lignes ; tests/fixtures et générateur | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/avelune_converter_adapters/test/source_event_character_import_test.dart` | Nouveau, 400 lignes ; _Files | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/avelune_converter_adapters/test/source_event_item_bindings_test.dart` | Nouveau, 425 lignes ; _Symbol, _Object, _Files | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/avelune_converter_adapters/test/source_event_projection_test.dart` | Nouveau, 1100 lignes ; _RubyObject, _RubyBytes, _RubyTable, _MarshalFixture, _Files | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/avelune_converter_adapters/test/source_event_study_composer_test.dart` | Nouveau, 226 lignes ; tests/fixtures et générateur | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/avelune_converter_adapters/test/source_pickup_feedback_binding_test.dart` | Nouveau, 489 lignes ; _Symbol, _Object, _Fixture | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/avelune_converter_adapters/tool/ac13_event_reference_fixtures.dart` | Nouveau, 287 lignes ; tests/fixtures et générateur | Génération rerunnable RMXP originale puis writer natif strict pour les traces de référence. |
| `packages/avelune_converter_adapters/tool/ac13_pickup_reference_fixture.dart` | Nouveau, 447 lignes ; Ac13PickupReferenceFixture, _Symbol, _Object | Génération rerunnable RMXP originale puis writer natif strict pour les traces de référence. |
| `packages/avelune_converter_core/lib/src/source_events.dart` | Nouveau, 1120 lignes ; SourceEventConditionKind, SourceEventProfile, SourceEventCondition, SourceEventSpan, SourceEventDiagnostic, SourceEventBlock, SourceEventNode, SourceTextNode, SourceChoiceBranch | AST / normalisation littérale des pages et commandes, identités et brut conservés ; moteur source jamais exécuté. |
| `packages/avelune_converter_core/test/source_events_test.dart` | Nouveau, 902 lignes ; _RubyObject, _RubyBytes, _RubyTable, _MarshalFixture, _Files, on | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_authoring/lib/src/domains/narrative/dialogue_audio_media_actions.dart` | Nouveau, 118 lignes ; DialogueAudioMediaActions | Actions et guards canoniques de scène/dialogue, import audio, plans/idempotence, discover et transport JSONL. |
| `packages/map_authoring/test/domains/narrative/dialogue_audio_media_actions_test.dart` | Nouveau, 173 lignes ; _Fixture | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_authoring/test/domains/narrative/dialogue_audio_media_jsonl_test.dart` | Nouveau, 162 lignes ; _Fixture | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_authoring/test/domains/narrative/scene_dialogue_choice_policy_actions_test.dart` | Nouveau, 174 lignes ; _Fixture | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_authoring/test/domains/narrative/scene_dialogue_line_feedback_actions_test.dart` | Nouveau, 457 lignes ; _Fixture | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_core/lib/src/dialogue/scene_dialogue_choice_policy_validation.dart` | Nouveau, 61 lignes ; SceneDialogueChoiceScope | Contrats purs typés cancel/feedback, validation et plan runtime ; références natives strictes. |
| `packages/map_core/lib/src/dialogue/scene_dialogue_line_policy_validation.dart` | Nouveau, 107 lignes ; SceneDialogueLineScope | Contrats purs typés cancel/feedback, validation et plan runtime ; références natives strictes. |
| `packages/map_core/lib/src/models/dialogue_line_feedback.dart` | Nouveau, 461 lignes ; DialogueLineAdvanceKind, DialogueLineAdvancePolicy, DialogueSegmentStyle, DialogueLineSegment, DialogueTextSegment, DialogueIconSegment, DialogueAudioCue, DialogueLineFeedback, SceneDialogueLinePolicy | Contrats purs typés cancel/feedback, validation et plan runtime ; références natives strictes. |
| `packages/map_core/test/dialogue_line_feedback_test.dart` | Nouveau, 136 lignes ; tests/fixtures et générateur | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_core/test/scene_dialogue_choice_policy_test.dart` | Nouveau, 112 lignes ; tests/fixtures et générateur | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_editor/lib/src/application/authoring_api/scene_dialogue_choice_policy_authoring_gateway.dart` | Nouveau, 202 lignes ; SceneDialogueChoiceOption, SceneDialogueChoiceScopeOption, SceneDialogueChoicePolicyEditorData, SceneDialogueChoicePolicyAuthoringGateway | Gateway, choix d’annulation no-code et inspection de scènes via authoring ; exposition de la capacité cible. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_dialogue_choice_policy_dialog.dart` | Nouveau, 288 lignes ; SceneDialogueChoicePolicyAuthoringButton, _SceneDialogueChoicePolicyAuthoringButtonState, SceneDialogueChoicePolicyDialog, _SceneDialogueChoicePolicyDialogState | Gateway, choix d’annulation no-code et inspection de scènes via authoring ; exposition de la capacité cible. |
| `packages/map_editor/test/application/scene_dialogue_choice_policy_authoring_gateway_test.dart` | Nouveau, 284 lignes ; _Fixture | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_editor/test/ui/canvas/scenes/scene_dialogue_choice_policy_dialog_test.dart` | Nouveau, 172 lignes ; tests/fixtures et générateur | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_editor/test/ui/canvas/scenes/scene_dialogue_choice_policy_inspector_test.dart` | Nouveau, 141 lignes ; tests/fixtures et générateur | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_player_ui/test/player_dialogue_feedback_test.dart` | Nouveau, 108 lignes ; tests/fixtures et générateur | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_runtime/lib/src/application/dialogue_feedback_playback_port.dart` | Nouveau, 93 lignes ; DialogueIconBytesLoader, ProjectDialogueIconLoader | Exécution des choix/cancel/feedback et conséquences transactionnelles, refus des gains, facts et présence/collision. |
| `packages/map_runtime/lib/src/presentation/flame/flame_dialogue_feedback_playback_adapter.dart` | Nouveau, 105 lignes ; FlameDialogueFeedbackPlaybackAdapter, _DialogueSound | Exécution des choix/cancel/feedback et conséquences transactionnelles, refus des gains, facts et présence/collision. |
| `packages/map_runtime/test/dialogue_choice_cancellation_test.dart` | Nouveau, 116 lignes ; tests/fixtures et générateur | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_runtime/test/dialogue_feedback_playback_test.dart` | Nouveau, 266 lignes ; _Driver | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_runtime/test/dialogue_line_feedback_test.dart` | Nouveau, 305 lignes ; _Port, _Launcher | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_runtime/test/source_converted_event_traces_test.dart` | Nouveau, 531 lignes ; _Reference, _ConvertedReferenceGame, _DiskSaveRepository | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `packages/map_runtime/test/source_converted_pickup_trace_test.dart` | Nouveau, 585 lignes ; _Reference, _AudioTrace, _ConvertedPickupGame, _DiskSaveRepository | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |
| `tools/pokemap_mcp/test/scene_dialogue_feedback_stdio.test.ts` | Nouveau, 180 lignes ; tests/fixtures et générateur | Preuve positive, refus et non-régression de la capacité correspondante ; fixtures originales et assertions de frontière. |

Le présent rapport est le seul nouveau Markdown, explicitement demandé par le livrable AC-13 du kit. `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` applique cette limite bornée ; `git diff --check` et le contrôle de l’index sont exécutés avant commit. Aucun log, cache, binaire ou corpus externe ajouté au commit.

## Passes et critique finale

| Passe / agent | Verdict | Évidence et critique |
| --- | --- | --- |
| Audit / Architecture — ac12_native_mapping + audit root | PASS pour les décisions bornées | Oracles Ruby statiques, modèles cibles et guards inspectés ; effets non qualifiés séparés des identités ; vrais pickups Route 9 refusés avec BGM actif |
| Implémentation — root + ac12_semantics | PASS pour la grammaire déclarée | AST fermé, projection/native API, politique cancel approuvée ; six empreintes refusées ; source timing intermédiaire explicitement exclu |
| Tests — ac12_validation_design + ac12_semantics | PASS pour EV-A/B/C | Générateurs RMXP originaux, writer strict, vraie boucle runtime, repository disque et instance neuve, négatifs sans effet, disparition et collision libre |
| Build / Validation — root | PASS pour les artefacts et parcours cités | Release Converter 103.6 MB lancée/conversion réelle ; Studio map edit/save/fresh-process reopen, feedback et disparition observés ; transports MCP vivants |
| Critique finale — ac12_semantics + root | PARTIAL au niveau domaine | Ancien factValue ambigu corrigé avec isTrue/isFalse et diagnostics ; aucune contamination de librairie étrangère, scopes/hashes contrôlés ; limites de timing/BGM et UI home lecture seule conservées |

L’alerte de mutation potentielle du binding IR a été retirée après vérification des types privés immuables et de la normalisation fermée. Le double coût quota des witnesses/source chunks est conservateur et peut réduire le volume convertible ; aucun contournement pour élargir artificiellement le corpus. La forme/collision exacte d’un événement n’est pas déduite de son seul texte. Le revenu bag/récompense est validé par le delta réellement observé, pas par un résultat `applied` trompeur.

Limites restant ouvertes : Ruby dynamique, trainer/battle, formes/catalogues complets, effet de tous les items, BGM actif/pause/reprise, timing du gain avant les textes, parité de police/window, source routes/counters/empreintes non représentables, tout Kanto non sélectionné, publication/recovery, distribution/offline. Les preuves de collision/profondeur AC-12 restent distinctes de ce lot de scènes ; elles ne certifient pas ses événements quarantinés.

## Git et suivi produit

La livraison est un commit local unique composé des 88 fichiers de code/tests listés et de ce rapport. Le SHA qui contient ce document constitue la preuve Git du lot ; le SHA exact est reporté dans le ticket et le chat après création. Aucun push, rebase ou amend. L’index initial était vide. L’état final attendu après commit ne contient que les chantiers étrangers ci-dessous ; ils ne sont ni staging ni modifiés par cette clôture.

Ticket canonique unique : [AC-13 — Sous-ensemble d’événements natifs](https://app.notion.com/p/3f7197a7bfa581dab5b9c551c806e2ce), grand domaine 14 Post Bêta, hors gate. Passage `TO REVIEW` avec preuve et SHA ; `DONE` réservé à Yoahn. Le domaine garde `PARTIAL`. La suite autorisée est AC-14, catalogues Essentials sélectionnés avec identités stables et effets explicitement séparés.

## Complément du 13 octobre 2026 — codes 0 internes RMXP

Les sections précédentes conservent la livraison initiale du commit `71c34d614`. Après le complément ressources `80cd5e8d978edb9eac6c87538189264923050f6a`, le parseur doit reconnaître les codes 0 sans effet placés à l'intérieur des branches RMXP. Il les refusait à tort comme terminaux invalides, ce qui quarantinait cinq pickups réels de Route 9 avant même d'atteindre les contrôles de catalogue, feedback et déclenchement.

### Audit initial et décision

Base `80cd5e8d978edb9eac6c87538189264923050f6a`, branche `main`, index vide, deux fichiers cibles propres et 42 chemins étrangers déjà modifiés/non suivis. La garde `/private/tmp/avelune-ac13-rmxp-zero-host-before-20261013-01.json` contient les SHA avant/après attendus et les empreintes/modes étrangers. Aucun travail de ressources, audio, runtime, combat ou UI n'est repris dans ce commit.

L'oracle est la section `034 Interpreter_Commands` de l'archive Kanto attestée : `/private/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-source-audit-m_nzr33l/outputs/034.rb`, SHA `ec927a007bee1889223dbc8b3de115f062a5308ab4410f87dab965eef3032561`. Les lignes 11–18 déterminent la fin par la position finale de la liste ; 117–122 traitent le code 0 sans effet. La lecture Ruby est une référence statique, jamais une exécution ni une copie de code.

Le correctif garde les contrôles d'indentation avant la dispatch. Un zéro interne n'est consommé qu'avec paramètres vides, à l'indentation du bloc courant, et un dernier zéro valide — code 0, indentation 0, paramètres vides. Il avance l'index puis poursuit la lecture ; il ne crée aucun nœud AST. Les fermetures 412/404 restent requises à la bonne indentation. Les inconnus, paramètres inattendus, scopes incomplets et terminaux malformés restent en quarantaine. Les commandes brutes, indices, références et spans sont conservés.

### Inventaire et diff utile

| Fichier | Zone et impact |
| --- | --- |
| `packages/avelune_converter_core/lib/src/source_events.dart` | Hunk 760–776, méthode privée du parser : vérifier le terminal final, consommer le no-op interne, arrêter seulement à la fin de liste. 11 lignes de diff. SHA avant `6f382b86d3e0952a342fba357ec0bd544ed4683f87057f9fb33ed9dcaf2b1223`, après `60d7ef445dc8cbb693b05fb903f752f2f3209512be50cbdbe50e30a1f335e34a`. |
| `packages/avelune_converter_core/test/source_events_test.dart` | Hunk 401–619 : sept régressions originales, 212 lignes ajoutées. SHA avant `7b5278a8a772d923b15df261244c531ee4734ecb9ff1f8838ed862030d8dee72`, après `7e89e30bb2b8ba50f533902a52f152218d35823498ede0a6091faf8dffe0c8ea`. |
| `documentation/reports/converter/AC-13/13_native_events.md` | Ce complément consolidé : audit, inventaire, preuve avant/après sur le vrai Kanto et limites restantes. Aucun nouveau Markdown. |

Patch qualifié : `/private/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-ac13-rmxp-zero-qualified-uf078tsl/rmxp-internal-zero.patch`, SHA `db8e338f8d3ecc1d57fcb8551253302c9ed7d8fbe6d9926d5d8a456c516056ab`. Le host a reçu exactement les deux fichiers gelés, après contrôle des deux SHA avant. Aucun modèle cible, schéma, API publique, action MCP, adapter, dépendance, configuration de build ou code UI/runtime n'est modifié.

Les sept tests couvrent : pickup avec `111 → 123/indent1 → 0/indent1 → 412 → 0` ; dernière page vide sous self-switch A ; branches imbriquées ; choix/options/annulation ; effets après no-ops racine ; sept structures malformées ; maintien d'une inconnue après un no-op. Le cas ancien `[0,123]`, sans terminal final valide, reste refusé.

### Vérifications fraîches

Tous les runners sont supervisés avec leurs descendants et leurs identités. Les reçus ci-dessous contiennent les commandes exactes, pins, sorties, SHA des logs et états de nettoyage ; zéro survivant/signal et `protectedUnchanged=true` sur ces runs.

| Commande / preuve | Résultat et reçu |
| --- | --- |
| RED isolé, `dart test test/source_events_test.dart --name RMXP --reporter expanded` | 1 PASS / 6 FAIL, exit 1, 3.419 s ; `/private/tmp/avelune-ac13-rmxp-zero-red-20261013-03.json`. Le premier essai antérieur de résolution package dans TEMP n'est pas un RED fonctionnel. |
| Host intégré, `dart test test/source_events_test.dart --reporter expanded` | `00:02 +31: All tests passed!`, exit 0, 4.025 s ; `/private/tmp/avelune-ac13-rmxp-zero-host-targeted-20261013-01.json`. |
| Host intégré, `dart test --reporter expanded` | `01:18 +754: All tests passed!`, exit 0, 79.931 s ; `/private/tmp/avelune-ac13-rmxp-zero-host-full-20261013-01.json`. |
| Host intégré, `dart analyze` | `No issues found!`, exit 0, 1.865 s ; `/private/tmp/avelune-ac13-rmxp-zero-host-analyze-20261013-01.json`. |
| `dart compile exe --packages=…/package_config.json -o …/route9-parser-probe …/route9_parser_probe.dart` | Exécutable AOT généré, exit 0, 7.982 s ; `/private/tmp/avelune-ac13-rmxp-zero-aot-build-20261013-01.json`. Toutes les bibliothèques core de ce gel correspondent au host intégré ; les dépendances adapters viennent du snapshot qualifié, pas des chantiers étrangers. |
| Exécutable AOT sur la vraie source Route 9, état après correctif | Exit 0, 8.557 s ; `/private/tmp/avelune-ac13-rmxp-zero-route9-real-20261013-01.json` : 16 événements analysés, six grammaires admises par le parser, zéro événement natif activé. |
| AOT témoin avec le core avant correctif | Build exit 0, 7.410 s ; `/private/tmp/avelune-ac13-rmxp-zero-baseline-aot-build-20261013-01.json`. |
| Exécutable témoin sur la même vraie source | Exit 0, 7.911 s ; `/private/tmp/avelune-ac13-rmxp-zero-route9-baseline-20261013-01.json` : une seule grammaire admise, refus attendu d'ETHER confirmé. Ce témoin positif du refus ancien n'est pas un test GREEN de la fonctionnalité corrigée. |

Le build AOT est la preuve de compilation pertinente pour ce correctif pur. Aucun nouveau comportement UI/runtime cible n'est implémenté ; le build macOS produit du complément ressources reste attribué à son commit. Aucune application graphique n'a été relancée pour le parser.

### Résultat réel Route 9 et provenance

Le probe reconstitue les contrats publics du snapshot conservé, vérifie son hash canonique `5bc0f5dd57e70951cb86fe7c71114e983827251830b2b11f23ef2dab48f1c8de`, puis utilise le vrai `MacOsSourceTree` et `SnapshotSourceFiles.bind`. Les métadonnées du corpus sont fraîchement rebondées, les bytes des témoins lus sont contrôlés contre leur SHA et taille, et `verifyUnchanged` est exécuté avant fermeture du port. Les bytes réels de `Data/Scripts.rxdata` correspondent au SHA `3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d`. Aucun nouveau scan complet des hashes des fichiers inutilisés n'est prétendu.

La normalisation fraîche de Map098 avec System reproduit exactement l'IR de carte et l'archive brute des preuves publiées. Les fichiers `source-snapshot.json` et `normalized-source.json` restent octet-identiques. Le probe après correctif et son témoin avant correctif lisent la même source et les mêmes témoins ; seul le core du parser diffère.

| Événement Map098 | Avant | Après, au niveau du parser uniquement |
| --- | --- | --- |
| 13, panneau Route 9 | Grammaire admise | Grammaire admise, inchangée. |
| 4, TM101 | Quarantaine | Grammaire admise ; binding du catalogue et feedback encore à qualifier. |
| 5, BURNHEAL | Quarantaine | Grammaire admise ; aucune récompense native annoncée. |
| 14, ETHER | Quarantaine | Grammaire admise ; page 0 initiale et page 1 vide sous self-switch A vérifiées. |
| 15, CHESTOBERRY | Quarantaine | Grammaire admise ; aucune récompense native annoncée. |
| 16, RARECANDY | Quarantaine | Grammaire admise ; aucune récompense native annoncée. |
| 1, 2, 3, 6, 7, 8, 9, 10, 11, 12 | Quarantaine | Quarantaine conservée. |

Preuves externes sous `/Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - chemins et arbres 20261013-r2/evidence` : `route9-parser-internal-zero.json`, SHA `2a42b680ac88761240bee5a80ad4b590ce2d1930b4a3a7ef3093946d1f49961c`, et `route9-parser-before-internal-zero-fix.json`, SHA `f449bcc294480d74d977b475e8c0fffc3967c9eed75af3b2160a0340d3da9d2d`. Elles conservent commandes/indents bruts, diagnostics et références, avec `nativeEventsActivated=false` et `fullGameplayCertified=false`. Le projet natif publié n'est pas modifié ; ses 16 événements restent quarantinés jusqu'à une nouvelle composition admise.

### Passes, parité et risques

| Passe | Verdict |
| --- | --- |
| Audit / Architecture, `ac12_native_mapping` et root | PASS borné : source primaire 034 revalidée, contrat parser existant et garde de terminal identifiés. |
| Implémentation, `ac12_native_mapping`, intégration root | PASS borné : deux fichiers exacts, aucun élargissement des commandes inconnues. |
| Tests, agent puis root | RED fonctionnel conservé ; host intégré 31/31 et 754/754, analyse sans issue. |
| Build / Validation, root | AOT compilé ; source réelle avant/après 1→6 grammaires comprises, port fermé et témoins intacts. |
| Critique finale, `ac12_native_mapping` et `ac12_validation_design` | PASS borné sur le patch exact, indents/fences/spans/inconnus et indépendance cible ; aucun P1/P2 de code identifié. Les sept reçus frais, les deux preuves réelles, les bibliothèques AOT et les vrais témoins source sont revalidés. Les deux clarifications documentaires sur les inventaires historiques et la concurrence Git sont intégrées avant commit. |

Parité MCP : aucune nouvelle sémantique native d'authoring ni aucun action/resource/transport cible n'est ajouté. Les preuves ciblées du contrat natif existant restent celles d'AC-13 et du complément ressources ; les relancer ne testerait pas ce correctif source privé. PMCP-085 global conserve son verdict PARTIAL. La roadmap FG-067/068 et FG-080/082/083/088/090 a été relue pour préserver les frontières ; aucun statut FG n'est modifié ou proposé DONE par ce correctif.

Auto-critique : cinq faux refus sont retirés sur une vraie source, mais une grammaire reconnue ne constitue pas un événement jouable. Le BGM actif, le bus de fanfare, la chronologie du gain source, le cas TM101, les triggers, les combats et les Ruby dynamiques gardent leurs contrôles distincts. L'autorité de combat reste Avelune. La comparaison réelle est statique ; elle ne prouve ni dialogue à l'écran, ni audibilité, ni gain/save/reload dans le jeu.

### Git et traçabilité du correctif

Ce complément est figé avant commit. Exactement trois chemins sont prévus : les deux fichiers core et ce rapport existant. La garde initiale de 42 chemins étrangers est historique : six chemins de bordures sont apparus pendant la qualification et `tools/nb2_modular_assets/test_directed_cliff_profiles.py` a évolué. L'état précommit observé contient 51 chemins modifiés/non suivis, dont trois du scope et 48 étrangers, avec index vide. Aucun de ces travaux concurrents n'est restauré, modifié ou ajouté au commit.

Les six chemins supplémentaires sont `packages/map_authoring/lib/src/domains/maps/border_actions.dart`, `packages/map_authoring/test/domains/maps/border_slot_override_actions_test.dart`, `packages/map_core/lib/src/operations/border_local_resolution_scope.dart`, `packages/map_core/lib/src/operations/border_locality.dart`, `packages/map_editor/test/authoring_api/border_slot_override_editor_test.dart` et `tools/pokemap_mcp/test/border_slot_override_stdio.test.ts`. Le test Python passe du SHA `a2c267fa606bd90c683e2bc31ee5175b2d1dad951db2bee92d280b7503b4a7ad` au SHA `2710159ac32f8688460312d36409cdfa2736a3ee5ad3cc9f8918c6107ecf1515`, sans changement de mode. Ce delta concurrent est enregistré ; il ne constitue pas une écriture du lot.

Une garde fraîche `/private/tmp/avelune-ac13-rmxp-zero-precommit-20261013-01.json` lie les trois fichiers du scope, HEAD, branche, index et bytes/modes des 48 fichiers étrangers immédiatement avant l'opération. Le reçu `/private/tmp/avelune-ac13-rmxp-zero-local-commit-20261013-01.json` sera écrit après le commit, comparé à cette garde fraîche puis reporté dans le ticket AC-13 existant. Aucun nouveau ticket de bug/carte, aucun nouveau grand domaine, aucune modification de gate bêta. Aucun push, rebase, amend ou changement de branche.

La livraison du correctif sera proposée TO REVIEW, avec domaine PARTIAL et décision DONE réservée à Yoahn. Suite du goal : binder le vrai BGM et qualifier le feedback des pickups admissibles, puis exécuter un événement réel avec sauvegarde/chargement sans répétition. Cette suite n'est pas incluse dans le commit parser.

## Inventaires historiques de la livraison initiale AC-13

Les inventaires ci-dessous concernent exclusivement le commit initial `71c34d614`. Ils ne décrivent pas le complément parser à trois fichiers du 13 octobre.

État Git historique avant le commit `71c34d614` (après implémentation et qualification initiales) :

```text
 M .github/workflows/avelune_android_release.yml
 M .github/workflows/pokemap_quick_checks.yml
 M "apps/Avelune iOS/AveluneiOS.xcodeproj/project.pbxproj"
 M "apps/Avelune iOS/AveluneiOS/Presentation/Views/SettingsView.swift"
 M "apps/Avelune iOS/project.yml"
 M apps/avelune_android/app/build.gradle.kts
 M apps/avelune_android/app/src/main/kotlin/com/yoahnl/avelune/player/presentation/SettingsScreen.kt
 M apps/avelune_android/tool/test_native_host_contracts.py
 M apps/avelune_android/tool/test_release_tools.py
 M apps/avelune_converter/lib/converter_app.dart
 M apps/avelune_converter/test/converter_app_test.dart
 M apps/avelune_studio/dev/spatial_frame_recorder.dart
 M apps/avelune_studio/lib/features/resources/data/border_resource_sources.dart
 M apps/avelune_studio/lib/features/resources/data/local_border_resource_adapter.dart
 M apps/avelune_studio/lib/features/resources/domain/resource_port.dart
 M apps/avelune_studio/lib/presentation/features/resources/border_creation_dialog.dart
 M apps/avelune_studio/lib/presentation/features/resources/border_pattern_panel.dart
 M apps/avelune_studio/test/presentation/spatial_border_editor_test.dart
 M apps/avelune_studio/test/resource_io/spatial_border_resource_adapter_test.dart
 M packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart
 M packages/avelune_converter_adapters/lib/src/converter_workflow.dart
 M packages/avelune_converter_adapters/lib/src/native_project_writer.dart
 M packages/avelune_converter_adapters/pubspec.yaml
 M packages/avelune_converter_adapters/test/converter_workflow_test.dart
 M packages/avelune_converter_adapters/test/support/literal_tile_fixture.dart
 M packages/avelune_converter_adapters/test/support/native_writer_fixture.dart
 M packages/avelune_converter_core/lib/avelune_converter_core.dart
 M packages/avelune_converter_core/lib/src/source_normalization.dart
 M packages/map_authoring/lib/map_authoring.dart
 M packages/map_authoring/lib/src/application/map_mutation_dispatcher.dart
 M packages/map_authoring/lib/src/domains/maps/border_catalog_actions.dart
 M packages/map_authoring/lib/src/domains/narrative/dialogue_source_guards.dart
 M packages/map_authoring/lib/src/domains/narrative/scene_actions.dart
 M packages/map_authoring/lib/src/parity/full_authoring_parity.dart
 M packages/map_authoring/lib/src/tooling/jsonl_worker.dart
 M packages/map_authoring/test/domains/narrative/scene_pre_session_actions_test.dart
 M packages/map_core/lib/map_core_domain.dart
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/dialogue/runtime_dialogue_document.dart
 M packages/map_core/lib/src/models/border_blueprint.dart
 M packages/map_core/lib/src/models/border_value_objects.dart
 M packages/map_core/lib/src/models/scene_asset.dart
 M packages/map_core/lib/src/operations/border_blueprint_json_codec.dart
 M packages/map_core/lib/src/operations/border_publication_readiness.dart
 M packages/map_core/lib/src/operations/project_dialogue_refs.dart
 M packages/map_core/lib/src/operations/spatial_border_resolution.dart
 M packages/map_core/lib/src/runtime/scene_runtime_plan.dart
 M packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart
 M packages/map_core/test/scene_project_diagnostics_test.dart
 M packages/map_editor/lib/src/application/authoring_api/authoring_query_adapter.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_player_ui/lib/src/player/player_dialogue_overlay.dart
 M packages/map_player_ui/lib/src/player/player_dialogue_surface.dart
 M packages/map_render_3d/lib/src/spatial_ground.dart
 M packages/map_render_3d/lib/src/spatial_pixel_material.dart
 M packages/map_render_3d/lib/src/spatial_scene_view.dart
 M packages/map_render_3d/lib/src/spatial_terrain_geometry.dart
 M packages/map_render_3d/test/spatial_relief_geometry_test.dart
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/dialogue_runtime_models.dart
 M packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart
 M packages/map_runtime/lib/src/application/parse_yarn_dialogue.dart
 M packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart
 M packages/map_runtime/lib/src/presentation/flame/dialogue_overlay_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/lib/src/presentation/flutter/dialogue_presentation_snapshot.dart
 M packages/map_runtime/test/narrative_scene_runtime_execution_test.dart
 M packages/map_runtime/test/playable_map_game_dialogue_outcome_scene_integration_test.dart
 M packages/map_runtime/test/scene_consequence_runtime_writer_test.dart
 M tools/pokemap_mcp/test/border_spatial_stdio.test.ts
?? apps/avelune_android/tool/read_app_version.py
?? apps/avelune_version.xcconfig
?? packages/avelune_converter_adapters/lib/src/source_event_arrival_validation.dart
?? packages/avelune_converter_adapters/lib/src/source_event_character_import.dart
?? packages/avelune_converter_adapters/lib/src/source_event_item_bindings.dart
?? packages/avelune_converter_adapters/lib/src/source_event_projection.dart
?? packages/avelune_converter_adapters/lib/src/source_event_study_composer.dart
?? packages/avelune_converter_adapters/lib/src/source_pickup_feedback_binding.dart
?? packages/avelune_converter_adapters/test/native_audio_artifact_test.dart
?? packages/avelune_converter_adapters/test/source_event_arrival_validation_test.dart
?? packages/avelune_converter_adapters/test/source_event_character_import_test.dart
?? packages/avelune_converter_adapters/test/source_event_item_bindings_test.dart
?? packages/avelune_converter_adapters/test/source_event_projection_test.dart
?? packages/avelune_converter_adapters/test/source_event_study_composer_test.dart
?? packages/avelune_converter_adapters/test/source_pickup_feedback_binding_test.dart
?? packages/avelune_converter_adapters/tool/ac13_event_reference_fixtures.dart
?? packages/avelune_converter_adapters/tool/ac13_pickup_reference_fixture.dart
?? packages/avelune_converter_core/lib/src/source_events.dart
?? packages/avelune_converter_core/test/source_events_test.dart
?? packages/map_authoring/lib/src/domains/narrative/dialogue_audio_media_actions.dart
?? packages/map_authoring/test/domains/maps/border_directed_contour_actions_test.dart
?? packages/map_authoring/test/domains/narrative/dialogue_audio_media_actions_test.dart
?? packages/map_authoring/test/domains/narrative/dialogue_audio_media_jsonl_test.dart
?? packages/map_authoring/test/domains/narrative/scene_dialogue_choice_policy_actions_test.dart
?? packages/map_authoring/test/domains/narrative/scene_dialogue_line_feedback_actions_test.dart
?? packages/map_core/lib/src/dialogue/scene_dialogue_choice_policy_validation.dart
?? packages/map_core/lib/src/dialogue/scene_dialogue_line_policy_validation.dart
?? packages/map_core/lib/src/models/dialogue_line_feedback.dart
?? packages/map_core/test/border/spatial_border_contour_direction_test.dart
?? packages/map_core/test/dialogue_line_feedback_test.dart
?? packages/map_core/test/scene_dialogue_choice_policy_test.dart
?? packages/map_editor/lib/src/application/authoring_api/scene_dialogue_choice_policy_authoring_gateway.dart
?? packages/map_editor/lib/src/ui/canvas/scenes/scene_dialogue_choice_policy_dialog.dart
?? packages/map_editor/test/application/scene_dialogue_choice_policy_authoring_gateway_test.dart
?? packages/map_editor/test/ui/canvas/scenes/scene_dialogue_choice_policy_dialog_test.dart
?? packages/map_editor/test/ui/canvas/scenes/scene_dialogue_choice_policy_inspector_test.dart
?? packages/map_player_ui/test/player_dialogue_feedback_test.dart
?? packages/map_render_3d/test/spatial_pixel_material_test.dart
?? packages/map_runtime/lib/src/application/dialogue_feedback_playback_port.dart
?? packages/map_runtime/lib/src/presentation/flame/flame_dialogue_feedback_playback_adapter.dart
?? packages/map_runtime/test/dialogue_choice_cancellation_test.dart
?? packages/map_runtime/test/dialogue_feedback_playback_test.dart
?? packages/map_runtime/test/dialogue_line_feedback_test.dart
?? packages/map_runtime/test/source_converted_event_traces_test.dart
?? packages/map_runtime/test/source_converted_pickup_trace_test.dart
?? tools/pokemap_mcp/test/scene_dialogue_feedback_stdio.test.ts
```

Fichiers étrangers exclus du commit historique `71c34d614` (34) :

- `.github/workflows/avelune_android_release.yml`.
- `.github/workflows/pokemap_quick_checks.yml`.
- `apps/Avelune iOS/AveluneiOS.xcodeproj/project.pbxproj`.
- `apps/Avelune iOS/AveluneiOS/Presentation/Views/SettingsView.swift`.
- `apps/Avelune iOS/project.yml`.
- `apps/avelune_android/app/build.gradle.kts`.
- `apps/avelune_android/app/src/main/kotlin/com/yoahnl/avelune/player/presentation/SettingsScreen.kt`.
- `apps/avelune_android/tool/test_native_host_contracts.py`.
- `apps/avelune_android/tool/test_release_tools.py`.
- `apps/avelune_studio/dev/spatial_frame_recorder.dart`.
- `apps/avelune_studio/lib/features/resources/data/border_resource_sources.dart`.
- `apps/avelune_studio/lib/features/resources/data/local_border_resource_adapter.dart`.
- `apps/avelune_studio/lib/features/resources/domain/resource_port.dart`.
- `apps/avelune_studio/lib/presentation/features/resources/border_creation_dialog.dart`.
- `apps/avelune_studio/lib/presentation/features/resources/border_pattern_panel.dart`.
- `apps/avelune_studio/test/presentation/spatial_border_editor_test.dart`.
- `apps/avelune_studio/test/resource_io/spatial_border_resource_adapter_test.dart`.
- `packages/map_authoring/lib/src/domains/maps/border_catalog_actions.dart`.
- `packages/map_core/lib/src/models/border_blueprint.dart`.
- `packages/map_core/lib/src/models/border_value_objects.dart`.
- `packages/map_core/lib/src/operations/border_blueprint_json_codec.dart`.
- `packages/map_core/lib/src/operations/border_publication_readiness.dart`.
- `packages/map_core/lib/src/operations/spatial_border_resolution.dart`.
- `packages/map_render_3d/lib/src/spatial_ground.dart`.
- `packages/map_render_3d/lib/src/spatial_pixel_material.dart`.
- `packages/map_render_3d/lib/src/spatial_scene_view.dart`.
- `packages/map_render_3d/lib/src/spatial_terrain_geometry.dart`.
- `packages/map_render_3d/test/spatial_relief_geometry_test.dart`.
- `tools/pokemap_mcp/test/border_spatial_stdio.test.ts`.
- `apps/avelune_android/tool/read_app_version.py`.
- `apps/avelune_version.xcconfig`.
- `packages/map_authoring/test/domains/maps/border_directed_contour_actions_test.dart`.
- `packages/map_core/test/border/spatial_border_contour_direction_test.dart`.
- `packages/map_render_3d/test/spatial_pixel_material_test.dart`.


## Complément du 13 octobre 2026 — BGM attesté et pickup ETHER réel

### Verdict, audit initial et portée

Complément AC-13 implémenté et vérifié pour revue, domaine **PARTIAL**. La publication réelle r4 réussit et le pickup ETHER du corpus est exécuté dans un vrai Studio puis, indépendamment, sauvegardé sur disque et chargé par une nouvelle instance du runtime. Ce complément ne certifie ni tout Kanto, ni la fidélité acoustique totale, ni le timing Essentials du gain avant les textes. Les livraisons initiales et inventaires plus haut sont historiques.

Base locale `main`, HEAD `2f07c5c7f58cc4da9f63739c3d69fb7000554f3a`, index vide. Le périmètre figé comporte32 chemins ; les autres changements mobile/bordures/render/dev sont exclus. La photographie initiale avant ce rapport comporte81 chemins dirty, dont32 possédés et49 étrangers. Le snapshot de qualification est `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-ac13-audio-studio-qualified-3ziazpub/repository` : HEAD plus les seuls chemins possédés. Contrôle frais avant rapport :64 hashes host/snapshot, zéro mismatch, reçu `/private/tmp/avelune-ac13-audio-inventory-20261013-01.json`. Le manifeste historique dit encore descriptivement exactly30 ; son `ownedCount` et ses32 pins sont corrects. Le dérivé `/private/tmp/avelune-ac13-audio-final-qualification-pins-20261013-01.json` corrige uniquement cette description sans réécrire l'original gelé.

Audit : le refus `bgm_active` empêchait les vrais pickups Route9 ; l'affectation map.audio.update n'était pas admise par le profil fermé du workflow. Un simple retrait du refus aurait importé un comportement sans contexte musical attesté. Le resolver exige au contraire source normalisée, snapshot, Map098, archive Scripts, Game.exe/configuration, fichier audio, options/gain/pitch attestés ; aucun script ni exécutable source lancé. Le writer recompose les mutations et artefacts exacts avant staging, puis le workflow vérifie une admission fraîche et publie exclusivement. Le profil audio versionné invalide les anciennes recettes au lieu d'ajouter une passerelle legacy.

Le BGM suit le gain source qualifié `0.8 × 0.8 = 0.64`. Le ME du pickup utilise le bus musique, son propre gain0.64 et une lease avec fondu nominal200ms puis reprise1000ms ; le service gère les générations, les chevauchements, les erreurs et les remplacements de piste. Les fades ne peuvent reprendre un ancien handle. Le temps restant jusqu'au retour LOOPSTART est suspendu pendant la pause. Le rôle effect reste autorisé seulement dans le contexte sans BGM déjà qualifié ; un BGM actif non attesté conserve le refus.

`MapMetadata.musicVolume` est nullable, finie0..1 ; null conserve le défaut natif0.8 et zero joue le silence. L'action canonique distingue omission/préservation et null/effacement. Le panneau legacy conserve une valeur exacte lors d'un edit indépendant et affiche80% sans activer silencieusement la surcharge. Le contrôle de volume du Studio moderne n'est pas livré par ce complément.

Instructions relues : codex_rule.md, index local, verification-before-completion, using-pokemap-mcp et Flame docs configurées (recherche disponible sans résultat pertinent ; lecture du driver/installations réelles). La consigne directe sans commentaires prévaut sur le§3 de codex_rule. Roadmap consultée : FG-067/068 DONE existants ; FG-080/088 TODO, FG-082/083/090 PARTIAL ; aucun statut modifié ou promu.

### Inventaire complet du commit et zones

32 chemins code/tests ci-dessous, plus ce rapport existant : **33 chemins**. Les zones sont les hunks exacts contre HEAD ; pour un nouveau fichier, totalité avec nombre de lignes. Aucun log, média source, binaire, cache, lockfile ni instrumentation dev externe entre au commit.

| Fichier | Zones du diff | Responsabilité et effet |
| --- | --- | --- |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | `-22,0 +23` | Export public du binding BGM attesté. |
| `packages/avelune_converter_adapters/lib/src/native_project_writer.dart` | `-995,0 +996 ; -1358,0 +1360,31 ; -1452,0 +1485,24` | Régénération exacte des imports audio et affectations après map.save ; rejet avant staging des artefacts, cibles, gains ou opérations altérés. |
| `packages/avelune_converter_adapters/lib/src/source_event_study_composer.dart` | `-10,0 +11 ; -15 +16,3 ; -17,0 +21 ; -74,0 +79,27 ; -106,0 +138 ; -377,0 +410 ; -396,0 +430 ; -411,0 +446,4 ; -425,0 +464 ; -438,0 +478` | Résolution BGM par carte, imports partagés dédupliqués, affectations individuelles et transmission du binding aux pickups. |
| `packages/avelune_converter_adapters/lib/src/source_map_music_binding.dart` | `new file, 430 lines` | SourceMapMusicResolver/Binding : profils, snapshot/bytes/quotas, gain natif, artefacts, mutations et preuves immuables. |
| `packages/avelune_converter_adapters/lib/src/source_pickup_feedback_binding.dart` | `-9,0 +10 ; -31,0 +33 ; -52,0 +55 ; -63,2 +66,11 ; -75,0 +88 ; -119 +132,13 ; -344,0 +370 ; -366,2 +392,5 ; -390 +419,5` | Admission du BGM actif uniquement avec binding exact ; rôle musicEffect et interruption200/1000ms ; gain0.64 et limites explicites. |
| `packages/avelune_converter_adapters/test/source_map_music_binding_test.dart` | `new file, 451 lines` | Positifs source et négatifs snapshot/profil/bytes/format/options/pitch/gain ; qualification sur archive Scripts exacte. |
| `packages/avelune_converter_adapters/test/source_pickup_feedback_binding_test.dart` | `-8,0 +9,7 ; -13,0 +21,2 ; -247,0 +257,68 ; -250,0 +328 ; -252,0 +331,3 ; -254,0 +336,184` | Pickup avec BGM, refus sans attestation et partage audio entre deux cartes sans fusionner leurs affectations. |
| `packages/avelune_converter_adapters/test/support/literal_tile_fixture.dart` | `-48,0 +49,4 ; -67,0 +72,4 ; -219 +227,7` | Paramètres BGM originaux inertes pour caractériser maps source sans copier le corpus. |
| `packages/avelune_converter_adapters/test/support/source_map_music_fixture.dart` | `new file, 128 lines` | Source originale contrôlée, identités et témoins audio/config pour tests du resolver. |
| `packages/map_authoring/lib/src/domains/project/runtime_audio_actions.dart` | `-20 +20 ; -36 +36 ; -56 +56,2 ; -57,0 +59,23 ; -79,0 +104,9` | Contrat canonique musicVolume ; omission préserve, null efface, valeur finie0..1 ; propriété sémantique discoverable. |
| `packages/map_authoring/test/domains/narrative/scene_dialogue_line_feedback_actions_test.dart` | `-38,0 +39,32` | Rôle ME/interruption traversent les actions natives du dialogue sans editing JSON parallèle. |
| `packages/map_authoring/test/domains/project/runtime_audio_actions_test.dart` | `-8,0 +9,86 ; -155,0 +242,47` | Gain, défaut, omission/effacement et refus sans mutation par API et persistance. |
| `packages/map_core/lib/src/models/dialogue_line_feedback.dart` | `-187,0 +188,48 ; -192,0 +241,2 ; -198,0 +249,3 ; -203,0 +257,2 ; -206 +261,5 ; -213,5 +272,22 ; -223,0 +300,2 ; -231 +309,3 ; -234 +314,2` | DialogueAudioCueRole et DialogueBgmInterruption typés, stricts et sérialisables. |
| `packages/map_core/lib/src/models/map_metadata.dart` | `-57,0 +58 ; -75,0 +77,8` | musicVolume nullable et gain effectif par défaut0.8, rejet du non-fini/hors bornes. |
| `packages/map_core/lib/src/models/map_metadata.freezed.dart` | `-22 +22 ; -41 +41 ; -46 +46 ; -50 +50 ; -61 +61 ; -78 +78 ; -83 +83,2 ; -174 +175 ; -177 +178 ; -195 +196 ; -198 +199 ; -215 +216 ; -218 +219 ; -230 +231 ; -239,0 +241 ; -272 +274 ; -277 +279 ; -281 +283 ; -292 +294 ; -309 +311 ; -314 +316,2` | Génération ciblée du seul modèle : constructeur, copie, égalité/hash du gain. |
| `packages/map_core/lib/src/models/map_metadata.g.dart` | `-13,0 +14 ; -30,0 +32` | Lecture/écriture JSON ciblée de musicVolume. |
| `packages/map_core/lib/src/validation/validators.dart` | `-3079,0 +3080,7` | Validation du seul gain dans _validateMapMetadata ; aucune édition des autres mécanismes. |
| `packages/map_core/test/dialogue_line_feedback_test.dart` | `-4,0 +5,156 ; -112,0 +269,8` | Roundtrip ME/politiques, valeurs invalides, anciennes formes cue courantes et document dialogue strict. |
| `packages/map_core/test/map_music_volume_test.dart` | `new file, 104 lines` | Null/défaut/zero/valeur exacte, copie/JSON et rejet des gains non finis. |
| `packages/map_editor/lib/src/ui/panels/map_properties_panel.dart` | `-8,0 +9,2 ; -33,0 +36 ; -129,0 +133,16 ; -254,0 +274 ; -305,0 +326` | Contrôle legacy via design system ; volume hérité80% et activation explicite, conservation de0.375 lors des autres edits. |
| `packages/map_editor/test/map_properties_music_volume_test.dart` | `new file, 124 lines` | Trois parcours widget du panneau ; compilation bloquée hors scope, jamais présentés comme PASS. |
| `packages/map_runtime/lib/map_runtime.dart` | `-353,0 +354` | Export du contrat pausable public pour drivers. |
| `packages/map_runtime/lib/src/player/runtime_music_service.dart` | `-32,4 +32,8 ; -42,0 +47,3 ; -45,0 +53 ; -47,3 +54,0 ; -52,7 +57,5 ; -68,0 +72,4 ; -73 +79,0 ; -85,0 +92,27 ; -89,0 +123,2 ; -101 +135,0 ; -102,0 +137 ; -110,0 +146,2 ; -112,6 +148,0 ; -120 +151,2 ; -122,0 +155 ; -127 +160 ; -130,0 +164,16 ; -133,12 +181,0 ; -152,7 +189,2 ; -161,10 +193,4 ; -173,2 +199,83 ; -179,5 +286,12 ; -190 +303,0 ; -193,4 +306,16 ; -202,0 +328,15 ; -205,0 +346,19 ; -208,3 +367,2 ; -213,2 +371 ; -215,0 +373 ; -216,0 +375 ; -217,0 +377 ; -219 +379 ; -246 +406 ; -249,0 +410,5` | Leases ME, envelope/générations, pause/reprise, suspension de deadline LOOPSTART et libération sur fin/erreur/dispose. |
| `packages/map_runtime/lib/src/presentation/flame/flame_cinematic_media_playback_adapter.dart` | `-0,0 +1,2 ; -33,0 +36,5 ; -35 +42,10 ; -42 +58 ; -46,5 +62,15 ; -61,2 +87,13 ; -69,4 +106,96 ; -84,3 +213,3 ; -150,4 +279 ; -195,4 +321 ; -240,2 +363,2` | Driver AudioPlayer pausable, relay completion/error immédiates, release robuste et ownership du handle. |
| `packages/map_runtime/lib/src/presentation/flame/flame_dialogue_feedback_playback_adapter.dart` | `-6,0 +7 ; -15,0 +17 ; -29,0 +32,2 ; -52,6 +56,28 ; -59 +85,5 ; -62 +92 ; -67,3 +97,17 ; -72,2 +116,3 ; -87 +132,6 ; -102 +152 ; -103,0 +154` | ME sur bus musique, gain propre et lease BGM libérée par completion réelle, erreur ou destruction. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | `-708,0 +709 ; -733,0 +735 ; -755,0 +758 ; -761 +764` | Injection du service BGM dans le feedback, gain natif pour carte/warp/restore. |
| `packages/map_runtime/test/dialogue_feedback_music_effect_test.dart` | `new file, 545 lines` | Vrais adaptateurs/services avec driver contrôlé : completion/error précoces, dispose/overlap et bus/gain. |
| `packages/map_runtime/test/playable_map_game_runtime_music_integration_test.dart` | `-7,0 +8 ; -15,0 +17 ; -29,13 +31,14 ; -43,3 +46,3 ; -47,3 +50,29 ; -73 +102 ; -90,3 +119 ; -108,0 +136` | Gain authoré exact, zero et défaut dans le vrai jeu et raccord feedback. |
| `packages/map_runtime/test/runtime_music_effect_interruption_test.dart` | `new file, 631 lines` | Pause/reprise, generations stale, remplacement de piste, volume bus et horloge de boucle suspendue. |
| `tools/pokemap_mcp/test/scene_dialogue_feedback_stdio.test.ts` | `-14,0 +15 ; -85 +86 ; -90,0 +92 ; -135,0 +138,16 ; -139 +157,2 ; -145,0 +165,4 ; -162,0 +186 ; -169 +193 ; -171 +195,2` | Transport stdio vivant : import cue/ME/gain, assignation musique carte, lecture et refus typés. |
| `packages/avelune_converter_adapters/lib/src/converter_workflow.dart` | `-1950,0 +1951 ; -1987 +1988 ; -1989 +1990 ; -2032,0 +2034,8` | Admission explicite map.audio.update et profil de capacités versionné, preuve test discoverable ; anciennes recettes invalidées. |
| `packages/avelune_converter_adapters/test/converter_workflow_test.dart` | `-15,0 +16 ; -18,0 +20,81` | RED policy.targetAction puis publication réelle de deux maps originales avec gain conservé après strict reopen. |
| `documentation/reports/converter/AC-13/13_native_events.md` | Présent complément consolidé et repère de statut en tête | Audit, preuve réelle, commandes, limites, passes, état Git et critique. |

### Publication réelle, Studio et sauvegarde disque

Source autorisée : `/Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto`, snapshot `5bc0f5dd57e70951cb86fe7c71114e983827251830b2b11f23ef2dab48f1c8de`, disponible383 cartes, sélection98 uniquement. La première tentative r3 a terminé exit2/1051.387s avec `policy.targetAction map.audio.update` ; elle n'est pas publiée comme réussite. Le RED fonctionnel du workflow reproduit ce refus ; l'admission/profil corrigés passent avec une publication et relecture native stricte de deux cartes originales.

La r4 termine exit0/1381.382s, `nativeStudyPublished`, `published=true`, `strictNativeReadPassed=true`, `sourceUnchanged=true`. Projet : `/Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - événements et musique 20261013-r4/output/Projet converti`. Route9 :72×61, cinq couches,315 décors,5 entités dont spawn+4 événements ;8 scènes natives. Les source events5/14/15/16 sont adaptedStaticSemantics sans gap final,12 autres sont whole-quarantined. Les projections historiques du composer de base ne constituent pas la projection finale des événements. BGM bytes identiques au source :591824 bytes, SHA `0d3ce709cb67e9b13a2c1b78e9133c56c7cd58e50aceb6cbb30c22fe28cccf2d`. Game.exe est attesté statiquement, jamais exécuté ; équivalence upstream totale non revendiquée.

GUI sur copie jetable sous le Container Studio : `/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Converter AC13 musique QA 20261013/Projet converti`. Copie initiale845 fichiers égale au publié. Le premier bootstrap GUI échoue sur le captureRoot historique Valbois du recorder ; réparation du seul guard dev dans le snapshot, en conservant path canonique/no-follow/marker stricts. Aucun fichier produit host32 ni recorder concurrent host modifié. Le second processus Studio réel PID59179 vérifie le projet exact, ouvre Carte puis Enregistrer et tester. Trajet au clavier depuis le spawn natif de prévisualisation(35,22), sans téléportation, jusqu'à(16,12) face ouest pour ETHER source(15,12). Le spawn n'est pas un départ de jeu Essentials certifié.

Les deux messages source sont affichés : `You found an Ether!`, puis le rangement dans la poche Medicine avec icône18×32 et couleurs. Cadence25ms, auto2s après révélation du premier, confirmation manuelle du second. Sac vide/selfA absent pendant les messages ; validation finale : Ether1 et selfAtrue ensemble. Réinteraction sans duplication. Le bouton Studio conserve explicitement un **checkpoint TEMP en mémoire** : déplacement puis Reprendre retrouve position/sac/fact sans duplication ; cela ne devient pas une preuve de sauvegarde disque. Recording3 :47 frames capturées/105 dropped/0 erreurs,10s ; autres prises conservées, aucune fluidité garantie à15fps.

Preuve distincte runtime : le vrai projet publié est chargé et l'événement98/14 exécuté via sa vraie scene/EventV2. Le harness externe utilise un état initial explicite(15,11) face sud, reachable depuis spawn par le graphe natif pixel-swept ; aucun teleport après boot, aucun parcours depuis spawn revendiqué pour ce harness. Save refusée pendant chacun des messages. Après complétion : Ether1+selfAtrue, vraie FileGameSaveRepository, nouveau bundle/jeu/repository, reload disque puis interaction sans texte/ME ni nouveau gain. Résultat `/private/tmp/avelune-ac13-route9-ether-runtime-result-20261013-01.json` passedtrue, SHA `42df69a8bd3391db8dc1e7c679f0cd249accc1015cc852fc0f2d459a140b1324`. Driver audio contrôlé, completion injectée pendant le premier message ; backend natif/acoustique non qualifiés par ce harness.

Les inventaires indépendants avant/après couvrent **tous845 fichiers**, y compris blobs/audit/locks, **51412503 bytes**, inventory SHA `f9b7608af518de6e8db4a063dcb6e4e46fb559f8415fe7c14dafd96c808c6ebf`. Fingerprint natif `sha256:64a75a8dc44638d5b19de52a7c2ddcaac1ae0f7e6312d33a689e2184f1d45f90` inchangé. Sauvegarde retained `/private/tmp/avelune-ac13-route9-runtime-qualified-h18ihcqe/ether-runtime-saves/run-D5dZCt/route9-ether-save.json`, SHA `d7998d2c24a695d08c9f29391c9ddd330db2111a90f690393c31addfcdd4a63a`. Le gel `/private/tmp/avelune-ac13-route9-runtime-final-pins-20261013-01.json` lie harness,7 pins produit, résultat, sauvegarde et incidents.

Preuve UI consolidée hors Git : `.../Kanto Route 9 - événements et musique 20261013-r4/evidence/studio-ether-qualification-20261013.json`,10 checkpoints et3 recordings. Lifecycle forcé uniquement pour capture debug ; `nativeLifecycleQualified=false`. Marionette get_logs a un défaut d'observabilité ; le journal possédé Flutter est conservé. Studio fermé par q, exit0/1078.188s, zéro survivant possédé et protégés inchangés. Aucun GUI laissé ouvert. Les autres suites/builds utilisent le superviseur ownership UID/start/command et ne nettoient que leurs propres descendants ; build release a réap trois ibtoold prouvés, aucun kill global.

### Observation native audio et limites

Observation BGM de60s :110 samples/0 erreurs, gain0.64 et deux retours de position35900→5531ms puis36062→5471ms, progression ensuite. Cela soutient deux boucles bornées du vrai player, sans clôturer la course native EOF/seek0/LOOPSTART ni une écoute acoustique.

La troisième observation pickup contient25 samples/0 erreurs VM, lease ME et envelope1→0.5→0→0.25→0.5→0.75→1, gains0.64×envelope. Pour le BGM stable playerId24c52254…,617ms écoulées et seulement133ms de progression au passage à pausedHandle : environ484ms de progression suspendue, suivies d'un offset stable après reprise. C'est une **inférence** qui soutient pause/reprise ; le sample lit service puis player/getters et timestamp en fin, donc n'est pas atomique et ne mesure pas AVPlayer.rate.

Les doubles réponses plugin ont une cause lue dans la dépendance installée : `audioplayers_darwin-6.5.0/.../AudioplayersDarwinPlugin.swift:262` répond à getDuration puis atteint `result(1)` ligne364 sans return. getCurrentPosition retourne correctement. Les appels de mesure provoquent le bruit de log ; aucune dépendance éditée. Le premier observer interrogeait aussi un ME détruit, causant une erreur getter ; corrigé dans l'outil externe pour ne lire les positions que du BGM vivant. La deuxième observation est arrivée trop tôt avant le pickup et ne qualifie donc pas ce dernier. Ces incidents ne sont pas effacés.

L'hypothèse Ogg tronqué a été retirée après FFmpeg/AVFoundation :1598125 frames BGM réelles, et AVPlayer muet traverse EOF complet avec options default/precise. Pas de transcodage produit inventé. Le risque distinct onComplete émis avant le seek0 interne Darwin contre seek(LOOPSTART)/resume n'est pas reproduit ni clôturé. `nativeMusicPlaybackQualified=false`, `sourceLoopPlaybackParityQualified=false` et aucune écoute audible certifiée restent explicites.

### Commandes, résultats exacts et incidents

Chaque reçu lie commande/cwd/log/hash, durée et ownership. Les suites recouvrent des tests et ne sont pas additionnées en un total artificiel. Les variables source des52 qualifiers sont AVELUNE_AUTOTILE_SCRIPTS_PATH, AVELUNE_AC13_SOURCE_SCRIPTS et AVELUNE_AC13_SOURCE_SNAPSHOT ; la reprise app12 utilise AVELUNE_AC12_SOURCE_SCRIPTS pointant sur l'archive source exacte. Les reçus sources sont au préfixe `/private/tmp/`.

| Reçu | Commande exacte | Résultat |
| --- | --- | --- |
| `avelune-ac13-audio-core-final-green-20261013-01.json` | `dart test test/map_music_volume_test.dart test/dialogue_line_feedback_test.dart test/map_delta_validator_test.dart test/narrative_project_validator_test.dart --reporter expanded` | 59 PASS ; exit0 /2.41s |
| `avelune-ac13-audio-core-models-final-analyze-20261013-02.json` | `dart analyze lib/src/models/map_metadata.dart lib/src/models/dialogue_line_feedback.dart test/map_music_volume_test.dart test/dialogue_line_feedback_test.dart` | No issues found ; exit0 /1.821s |
| `avelune-ac13-audio-core-analyze-20261013-01.json` | `dart analyze lib/src/models/map_metadata.dart lib/src/models/dialogue_line_feedback.dart lib/src/validation/validators.dart test/map_music_volume_test.dart test/dialogue_line_feedback_test.dart` | 3 infos préexistantes validators155–157 ; exit0 /1.793s |
| `avelune-ac13-audio-authoring-final-green-20261013-01.json` | `dart test test/domains/project/runtime_audio_actions_test.dart test/domains/narrative/scene_dialogue_line_feedback_actions_test.dart test/domains/narrative/dialogue_audio_media_jsonl_test.dart --reporter expanded` | 27 PASS ; exit0 /3.517s |
| `avelune-ac13-audio-authoring-analyze-20261013-01.json` | `dart analyze lib/src/domains/project/runtime_audio_actions.dart test/domains/project/runtime_audio_actions_test.dart test/domains/narrative/scene_dialogue_line_feedback_actions_test.dart` | No issues found ; exit0 /1.806s |
| `avelune-ac13-audio-editor-final-analyze-20261013-02.json` | `dart analyze lib/src/ui/panels/map_properties_panel.dart test/map_properties_music_volume_test.dart` | No issues found ; widget execution non acquis ; exit0 /5.756s |
| `avelune-ac13-active-music-root-final-green-20261013-01.json` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/source_pickup_feedback_binding_test.dart test/source_map_music_binding_test.dart --concurrency=2 --reporter expanded` | 48 PASS /1 SKIP avant variables source ; exit0 /13.08s |
| `avelune-ac13-active-music-root-final-analyze-20261013-01.json` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib/src/native_project_writer.dart lib/src/source_event_study_composer.dart lib/src/source_pickup_feedback_binding.dart lib/src/source_map_music_binding.dart test/source_pickup_feedback_binding_test.dart test/source_map_music_binding_test.dart test/support/source_map_music_fixture.dart` | No issues found ; exit0 /2.949s |
| `avelune-ac13-active-music-workflow-green-20261013-03.json` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/converter_workflow_test.dart --name 'AC13 workflow publishes attested map music' --reporter expanded` | 1 PASS ; publication/reopen exact ; exit0 /8.057s |
| `avelune-ac13-active-music-workflow-analyze-20261013-03.json` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib/src/converter_workflow.dart test/converter_workflow_test.dart` | No issues found ; exit0 /2.99s |
| `avelune-ac13-active-music-adapters-full-20261013-02.json` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test --concurrency=2 --reporter expanded` | 693 PASS /9 SKIP ; exit0 /235.97s |
| `avelune-ac13-active-music-skipped-qualifiers-20261013-01.json` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/literal_autotile_composer_test.dart test/literal_autotile_integration_test.dart test/source_map_music_binding_test.dart --concurrency=2 --reporter expanded` | 52 PASS /0 SKIP dont9 qualifications absentes ; exit0 /19.841s |
| `avelune-ac13-me-runtime-review-green-20261013-02.json` | `flutter test --no-pub test/runtime_music_effect_interruption_test.dart test/dialogue_feedback_music_effect_test.dart test/runtime_music_service_test.dart test/runtime_music_intro_loop_test.dart test/dialogue_feedback_playback_test.dart test/playable_map_game_runtime_music_integration_test.dart --concurrency 2 --reporter expanded` | 54 PASS ; exit0 /6.824s |
| `avelune-ac13-me-runtime-review-analyze-20261013-03.json` | `flutter analyze --no-pub lib/src/player/runtime_music_service.dart lib/src/presentation/flame/flame_cinematic_media_playback_adapter.dart lib/src/presentation/flame/flame_dialogue_feedback_playback_adapter.dart test/runtime_music_effect_interruption_test.dart test/dialogue_feedback_music_effect_test.dart test/playable_map_game_runtime_music_integration_test.dart` | No issues found sur6 fichiers ; exit0 /7.383s |
| `avelune-ac13-active-music-authoring-parity-20261013-01.json` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/parity/full_authoring_parity_test.dart --reporter expanded` | 20 PASS ; exit0 /18.074s |
| `avelune-ac13-active-music-mcp-build-20261013-01.json` | `npm run build` | tsc PASS ; exit0 /1.219s |
| `avelune-ac13-active-music-mcp-check-20261013-01.json` | `npm run check` | tsc noEmit PASS ; exit0 /1.241s |
| `avelune-ac13-active-music-mcp-live-20261013-02.json` | `node --import tsx --test test/scene_dialogue_feedback_stdio.test.ts` | 1 PASS stdio vivant ; exit0 /9.083s |
| `avelune-ac13-active-music-pmcp085-20261013-01.json` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart run tool/pmcp085_conformance.dart` | PARTIAL global, exit1 ;88 resources/410 actions,0 missing déclarées ; exit1 /7.411s |
| `avelune-ac13-route9-ether-runtime-green-20261013-06.json` | `flutter test --no-pub test/route9_published_ether_qualification_test.dart --concurrency 1 --reporter expanded` | 1/1 PASS, vrai reload disque ; exit0 /8.68s |
| `avelune-ac13-route9-runtime-harness-analyze-20261013-04.json` | `flutter analyze --no-pub test/route9_published_ether_qualification_test.dart` | No issues found ; exit0 /9.105s |
| `avelune-ac13-active-music-converter-build-20261013-02.json` | `/opt/homebrew/share/flutter-3.47.5/bin/flutter build macos --release --no-pub` | Built Avelune Converter.app70.4MB ; exit0 /80.89s |
| `avelune-ac13-active-music-cli-build-20261013-01.json` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart compile exe bin/avelune_converter.dart -o /private/tmp/avelune-ac13-audio-converter-cli-20261013-01` | Generated CLI AOT ; exit0 /26.406s |
| `avelune-ac13-active-music-converter-tests-20261013-01.json` | `/opt/homebrew/share/flutter-3.47.5/bin/flutter test --no-pub --concurrency 2 --reporter expanded` | 83 PASS /2 SKIP, source env absente ; exit0 /55.143s |
| `avelune-ac13-active-music-converter-source-qualifiers-20261013-01.json` | `/opt/homebrew/share/flutter-3.47.5/bin/flutter test --no-pub test/converter_app_test.dart --concurrency 2 --reporter expanded` | 12 PASS /0 SKIP dont2 qualifications app reprises ; exit0 /21.672s |
| `avelune-ac13-active-music-converter-analyze-20261013-01.json` | `/opt/homebrew/share/flutter-3.47.5/bin/flutter analyze --no-pub` | No issues found ; exit0 /8.062s |
| `avelune-ac13-active-music-cli-tests-20261013-01.json` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test --concurrency=2 --reporter expanded` | 28 PASS /3 SKIP, corpus2+nonmacOS1 ; exit0 /25.805s |
| `avelune-ac13-active-music-package-20261013-01.json` | `python3 tool/package_distribution.py --app '/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-ac13-audio-studio-qualified-3ziazpub/repository/apps/avelune_converter/build/macos/Build/Products/Release/Avelune Converter.app' --cli /private/tmp/avelune-ac13-audio-converter-cli-20261013-01 --fixture /Users/karim/Project/pokemonProject/apps/avelune_converter/build/distribution/AC16-local-20261013/payload/AveluneConverter-local-validation/fixture --output /Users/karim/Project/pokemonProject/apps/avelune_converter/build/distribution/AC13-audio-local-20261013` | Archive privée37,314,098 bytes, pas de notarisation/upload ; exit0 /4.037s |

Reçus de publication et GUI avec leurs commandes complètes : `/private/tmp/avelune-ac13-active-music-route9-publication-20261013-02.json`, `/private/tmp/avelune-ac13-route9-studio-ui-20261013-02.json`. Le catalogue externe `/private/tmp/avelune-ac13-audio-receipt-catalog-20261013-01.json` conserve les autres commandes et refus avant les gates finales ; aucun snapshot de code recopié.

Incidents gardés : premier build app --no-pub refuse package_config absent(exit1/1.241s), pub get --offline prépare seulement le snapshot puis build02 PASS ; premier lancement de CLI distribuée utilise un nom underscore au lieu du vrai nom avec tiret, Popen refuse avant tout enfant et seul son log reste ; reprise après inventaire du vrai nom. Le harness Ether a eu deux raccords de fixture incorrects et plusieurs lectures transitoires incomplètes/bloquées avant tout runtime ; les timeouts ne sont jamais PASS. Lecture globale Python puis run06 réussissent sans éditer le produit ou le natif ; les incidents antérieurs ne sont pas attribués individuellement. Les trois P2 découverts dans la revue runtime ont été corrigés et revérifiés : completion précoce du driver réel, nettoyage exhaustif après échec de démarrage en conservant l'erreur initiale, et nouvelle ME pendant une reprise en attente. La suspension du délai de boucle est également couverte par les tests. Leur preuve est le gel runtime final et la suite54.

Qualification de la nouvelle archive : build et packaging PASS, archive SHA `ac7dd92912dacc7d76d3842987562864a02328e0719d4de0cc15a6330ec1e797`, CLI packagée --help PASS0/0.679s, identique au binaire AOT. Sa commande verify sur le vrai r4 a toutefois terminé **timedOut=true /exit-15 en180.505s**, sans output, reçu `/private/tmp/avelune-ac13-active-music-distributed-verify-20261013-02.json`, signal TERM du seul runner possédé et zéro survivant. Ce résultat n'est pas PASS ; vérification distribuée sur l'original Documents **PARTIAL**, sans modification du produit ou du natif pour la masquer. Un blocage Gatekeeper au démarrage de ce binaire est écarté par --help. Le parser/runtime réel qui charge r4 et sa publication stricte sont des preuves distinctes.

Diagnostic final en lecture seule : `/private/tmp/avelune-ac13-native-verify-diagnosis-final-20261013-01.json`, SHA `16538ae355c3ec9e0a8ff768bc176961428143b3107593dd748f66420331feee`. Une sonde déléguée au vrai LocalProjectFileReader situe l'attente dans ProjectSnapshotLoader strict : un Yarn de109 bytes prend27.250295s, le Yarn suivant de112 bytes reste dans read() du noyau, descripteur recoupé par lsof. Il porte compressed,dataless. L'inventaire de métadonnées retrouve845 fichiers/51412503 bytes aux mêmes chemins/tailles, dont263 fichiers SF_DATALESS/11428678 bytes non locaux ; ce n'est pas une nouvelle empreinte de contenu. Le service File Provider responsable n'est pas identifié. Sonde70.522s/exit-15, zéro survivant, pins produit identiques. L'inventaire complet root encore bloqué sur un blob est arrêté par TERM après contrôle UID/start/commande/fichier ouvert ; reçu `/private/tmp/avelune-ac13-audio-inventory-cancelled-20261013-01.json`, verdict INCOMPLETE_CANCELLED. Aucune hydratation, copie ou reprise verify ; les preuves complètes antérieures restent distinctes de la disponibilité actuelle.

Discriminant local exécuté ensuite : la copie du projet utilisée par la GUI, `/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Converter AC13 musique QA 20261013/Projet converti`, conserve les845 fichiers intégralement locaux. Comparaison complète de chaque chemin, taille et SHA contre l'inventaire r4 après test disque : exactement identique,51412503 bytes, référence `f9b7608af518de6e8db4a063dcb6e4e46fb559f8415fe7c14dafd96c808c6ebf`, reçu `/private/tmp/avelune-ac13-native-local-copy-inventory-20261013-01.json`, exit0/1.242s. La vraie CLI de la nouvelle archive exécute verify --project sur cette copie existante --offline : **PASS**,1 carte/72 assets, révision `sha256:e701d17e88ec945cda72a95f974c59a1f047e7212b2957c71ab256ac76759495`, exit0/4.114s, reçu `/private/tmp/avelune-ac13-active-music-distributed-local-copy-verify-20261013-01.json`. Zéro signal, zéro descendant survivant, protégés inchangés ; aucun fichier source/natif écrit. La vérification distribuée sur les octets réels de r4 est acquise via cette copie exacte ; le timeout du dossier Documents dataless demeure conservé et sa disponibilité n'est pas réparée.

Replays frais juste avant commit, sur le même snapshot figé : core `dart test test/map_music_volume_test.dart test/dialogue_line_feedback_test.dart test/map_delta_validator_test.dart test/narrative_project_validator_test.dart --reporter expanded`,59 PASS/exit0/7.006s (`audio-precommit-core-20261013-01.json`) ; bindings `dart test test/source_map_music_binding_test.dart test/source_pickup_feedback_binding_test.dart --concurrency=2 --reporter expanded`,48 PASS/1 SKIP/exit0/13.431s avec archive Scripts exacte (`audio-precommit-bindings-20261013-02.json`), seul test inventory Route9 requiert le snapshot env et reste couvert par les qualifications réelles précédentes ; workflow musical exact1 PASS/exit0/8.876s (`audio-precommit-workflow-20261013-01.json`). Le premier filtre sans env donne1 PASS/4 SKIP (`audio-precommit-bindings-20261013-01.json`) et ne remplace pas la reprise source. Runtime : les mêmes six suites54 PASS/0 SKIP/exit0/25.499s, puis analyse des six fichiers No issues/exit0/9.240s (`me-runtime-precommit-green-20261013-01.json` et `me-runtime-precommit-analyze-20261013-01.json`) ; pub get --offline nécessaire seulement au snapshot, lockfile inchangé. Tous ces reçus sont sous `/private/tmp/avelune-ac13-`, zéro timeout, zéro survivant, protégés inchangés. Pins runtime18 host/snapshot identiques avant/après ;32 pins produit globaux recontrôlés au staging. Build/pack récents inchangés, aucune nouvelle modification produit après qualification.

### Parité, passes et auto-critique

Les mutations passent par map_authoring canonique : audioMedia.import, asset.import et map.audio.update. Rôle ME/interruption et gain sont testés en API, JSONL et stdio MCP vivant avec relecture/refus ; catalogue rebâti et relu. L'importeur source est privé au Converter, N/A comme commande d'édition native ; le contrôle moderne Studio volume reste absent. PMCP-085 global est PARTIAL et le test widget legacy échoue à compilation sur14 usages préexistants PaletteItem.elementId String? hors scope, listés dans audio-editor-red01 ; leurs fichiers étrangers restent intacts. L'analyse ciblée du panneau n'est pas une preuve de parcours widget. L'analyse du jeu complet conserve4 infos préexistantes ; pas d'annonce all-green globale.

| Passe | Verdict | Preuve et borne |
| --- | --- | --- |
| Audit/architecture — root + ac12_semantics | PASS borné | Archive Ruby/config/engine lus statiquement, BGM actif exige binding scellé, gain/pause/loop distingués des propriétés acoustiques. |
| Implémentation bindings/writer/workflow — root | PASS borné | Exact artifacts/mutations, import dédupliqué et affectation par map ; RED admission puis GREEN1, source réelle r4 publiée. |
| Implémentation contrats — ac12_native_mapping | PASS borné /UI legacy PARTIAL |12 chemins contracts authoring/core/editor figés, tests59/27 ; noIssues ciblées, compilation widget legacy non acquise. |
| Implémentation runtime — ac12_validation_design | PASS borné |7 chemins,54 tests après corrections de concurrence/leases/loop clock, pins identiques au snapshot root. |
| Tests/qualification réelle — ac12_validation_design + root | PASS ETHER seulement | Vrai projet/scène/items/icône/sourceME, save refusée en dialogue, nouveau runtime/repository disque sans duplication ; GUI root depuis previewspawn séparée. |
| Build/validation — root | PASS borné /release UI PARTIAL | Studio debug réel fermé, nouveau Converter release70.4MB et CLI/pack local ; interface release non pilotée. |
| Critique finale32 — ac12_native_mapping | PASS borné |64 hashes,0 mismatch, aucun P1/P2 concret nouveau ; manifest30/32 description corrigée dans dérivé, pas de faux Kanto complet. |
| Critique native audio — ac12_semantics | PASS borné /parité PARTIAL | Pause soutenue par offset de position, samples non atomiques ; défaut getter durée dans dépendance, course EOF distincte non close. |

Auto-critique : les preuves sont fortes pour publication, gain natif et ETHER après scène/reload. Elles restent étroites :1 map/4 events,12 quarantinés,536 transitions fermées, départ Essentials et liens région non exécutés, TM101 non lié, catalogues/rencontres/trainers/effets incomplets. Le sac est modifié transactionnellement en fin de scène, alors qu'Essentials le modifie avant les messages : sourceBagMutationTimingQualified=false et fullPickupParityQualified=false, aucune fidélité totale annoncée. Le combat conserve battleAuthority=aveluneNative ; aucun moteur/source script Essentials porté. AIcalls0, sourceScriptsExecuted0. La GUI uses capture lifecycle forcé ; capture drops et plugin logs rendent toute promesse de fluidité/acoustique excessive. La qualification sur snapshot évite les bordures/render/mobile étrangers mais ne remplace pas les appareils mobiles ou le contrôle d'une release installée.

### Git, Notion et suite autorisée

Commit local autorisé par le goal,33 chemins revus seulement, sans push/rebase/amend/branche. Garde fraîche juste avant staging : `/private/tmp/avelune-ac13-audio-precommit-20261013-01.json`, puis reçu SHA/index/foreign hashes après commit : `/private/tmp/avelune-ac13-audio-local-commit-20261013-01.json`. Les fichiers source et diffs Git restent canoniques. Avant clôture : diff scoped sans erreur, hygiène Markdown zéro nouveau fichier. Worktree final conserve les changements étrangers ; index doit être vide et leurs bytes/modes sont comparés avant/après, sans restore/cleanup.

Ticket existant unique [AC-13](https://app.notion.com/p/3f7197a7bfa581dab5b9c551c806e2ce), grand domaine Post Bêta Monde & narration, hors gate. Après commit/vérification du reçu : TO REVIEW pour ce complément, domaine PARTIAL ; DONE réservé à Yoahn. Le goal complet reste actif. Suite déjà autorisée : vraie carte voisine et parcours intercartes avec état/sauvegarde, puis événements/rencontres/dresseurs raccordés au combat Avelune ; pas de connexions ou succès de région inventés.
