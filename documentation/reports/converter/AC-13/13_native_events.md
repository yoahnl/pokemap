# AC-13 — Sous-ensemble d’événements natifs

## Verdict et portée de la revue

Implémentation livrée pour revue, avec trois traces EV-A/B/C converties depuis des fichiers RMXP originaux synthétiques, relues strictement au format natif, exécutées par le vrai runtime puis sauvegardées et chargées par une nouvelle instance de `FileGameSaveRepository`. Le domaine reste PARTIAL : la conversion de jeu entier, les événements Kanto et la parité de toute instruction Essentials ne sont pas certifiés.

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

État Git avant ce commit (après implementation et qualification) :

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

Fichiers étrangers exclus de ce commit (34) :

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
