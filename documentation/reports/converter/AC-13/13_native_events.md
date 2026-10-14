# AC-13 — Sous-ensemble d’événements natifs

## Verdict et portée de la revue

Implémentation livrée pour revue, avec trois traces EV-A/B/C converties depuis des fichiers RMXP originaux synthétiques, relues strictement au format natif, exécutées par le vrai runtime puis sauvegardées et chargées par une nouvelle instance de `FileGameSaveRepository`. Le domaine reste PARTIAL : la conversion de jeu entier, les événements Kanto et la parité de toute instruction Essentials ne sont pas certifiés.


État actuel au 14 octobre : les compléments qualifient Tone/SE, routes finies, visibilité, états d’instance, sortie du contact, contact natif, points d’arrivée de scène et autorun natif réévaluable. Les preuves ciblées des guides/transports et du Runtime restent distinctes d’une conversion source. L’IRv4 reconnaît le programme original, mais sa projection fidèle, sa cadence et ses attentes restent à fermer. Les portes source restent inactives ; dernier échantillon préparé :9événements adaptés sur44. Les preuves et captures anciennes restent historiques, sans disponibilité actuelle implicite. DomainePARTIAL.
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


## Complément du 14 octobre 2026 — Dialogue du Centre et orientation bornée

**Verdict : code et préparation réelle qualifiés, publication du nouveau dialogue en cours ; AC-13 reste PARTIAL à la revue.** Le goal AC-00 à AC-16 reste actif. Aucun jeu complet, parcours KAN-03, porte du Centre ou persistance du facing n'est déclaré certifié.

### Audit initial, portée et source

Base main51d82254108006dd982b4d274b43bd18e00429c3, index vide et64 chemins étrangers au début ; reçu static-dialogue-before-01.json. Le writer host étranger et les autres travaux bordures/spatial/mobile sont exclus. Le snapshot privé Q/repository contient le writer commité précédent, pas ces modifications étrangères. Q = /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac16-refresh-20261014-ftgqyeej.

Le vrai Map102/event14/page0 utilise le texte explicite b/n puis209 target0, route[25,0] non répétée/non skippable et509 copie du25. Le profile Scripts reste au SHA3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d. Les oracles statiques044/079/088 sont recomputés et ajoutés à kanto-events-static-v2. 079:9–12 fixe les couleurs homme/femme indépendamment du skin ;088:428–443 distingue nom d'acteur, newline et couleurs, sans exécution Ruby. 044:165–184 et033:65–69 tournent le PNJ vers le joueur avant son programme, sans restaurer son orientation après unlock.209/509 est adapté uniquement lorsque sa route finale est idempotente pendant une interaction frontale stationnaire.

Le chemin natif moderne playable_map_game_interactions.dart406 appelle déjà _faceNpcTowardPlayer avant le dispatch EventV2 ; playable_map_game.dart14814 applique le facing opposé du joueur au rendu, sans mutation persistée de world.npc.facing. Aucun nouveau modèle cible n'est introduit. Les lots FG-082/FG-092 sont pertinents ; aucun statut FG ou gate bêta n'est modifié, aucune proposition DONE.

### Inventaire complet et zones modifiées

| Fichier | Zones | Effet |
|---|---|---|
| packages/avelune_converter_core/lib/src/source_events.dart | Profil ligne37 ; SourceInteractionFacingNode252 ; parser932–1069 et transmission de rawPage | Node strict209+509, références admises et immuables, locators et graphes source exacts ; aucun mouvement générique. |
| packages/avelune_converter_core/test/source_events_test.dart | Fixtures annotées et tests autour451 | RED puis84 cas : forme réelle, paramètres/class/champs/annotations, copie absente ou altérée, profils/refs/indents invalides et conservation. |
| packages/avelune_converter_adapters/lib/src/source_event_projection.dart | Lexer44 ; evidence376 ; contexte558 ; gaps793 ; scene1183/1266 | Couleurs/ombre et newline via DialogueLineFeedback existant ; facing admis seulement pour une pagealways, texte sans choix puis route, PNJ2D1×1 immobiletrigger0/nonthrough/noDirectionFix. |
| packages/avelune_converter_adapters/test/source_event_projection_test.dart | Helpers de route et tests autour483–700 | Dialogue source réel, couleurs, uppercase, contexte interdit, contrôles inconnus, balises/entités et fermeture des effets dépendants. |
| documentation/reports/converter/AC-13/13_native_events.md | Présent complément | Source, décisions, preuves et limites consolidées. |
| documentation/reports/converter/AC-16/16_local_distribution.md | Actualisation de publication/distribution | Liens vers ce complément et nouveaux artefacts, sans réécrire les preuves anciennes. |

Les quatre fichiers source/test host et QA sont byte-identical au gel static-dialogue-final-pins-02.json. Source core SHA92636a027208100d4addaedaf4fef0c40253491349b791480d229c34d579254f ; test190abb258628f71d850d9f08474ac44e27efdde83a678fca977507039d7b9615 ; projection7674c2c287de8d563e7b98c17bc9f4a2fe1806b49f014ead1d1cd0d901ac4072 ; testprojectione4578e84f5f15e27654124c1720caf6e51f31c5b2beae719223169a9eff50215. Aucun commentaire, dependency/pub/lock host, code runtime/Studio/combats ou format natif modifié.

### Contrepreuves et commandes finales

Chaque reçu conserve argv/cwd, UID/start/command des descendants, pins avant/après et SHA des logs ; static-dialogue-verification-01.json les revalide. Les commandes s'exécutent dans les packages de Q/repository.

| Reçu | Commande / résultat exact | Durée |
|---|---|---|
| ac13-facing-red-01 | Core :31PASS/2FAIL, forme exacte encore quarantinée et profilv1 ; exit1 |3.682s|
| ac13-facing-symbol-red-02 | Symbole de champ étendu accepté à tort ; Expected true/Actual false, exit1 | Voir reçu |
| ac13-facing-green-02 | dart test test/source_events_test.dart --reporter expanded --concurrency=1 ;84PASS/0SKIP, exit0 |4.749s|
| static-text-red-02 | Deux dialogues colorés refusés ; Expected notnull/Actual null, exit1 |4.318s|
| static-text-edge-red-01 | Nom d'acteur n[1] admis à tort et uppercase refusé, exit1 |4.322s|
| static-facing-projection-red-01 | Vrai programme text+route encore fermé, exit1 |4.583s|
| static-formatting-red-01 | Programme coloré avec balise b admis à tort : Expected null/Actual NarrativeEventDefinition, exit1 |5.267s|
| static-dialogue-core-full-01 | dart test --reporter expanded --concurrency=2 ;880PASS/1SKIP, exit0 |65.796s|
| static-dialogue-adapters-full-02 | Même commande, AVELUNE_AC13_SOURCE_SCRIPTS attestés ;847PASS/40SKIP, exit0 |251.161s|
| static-dialogue-core-analyze-01 / adapters-analyze-01 | dart analyze ; No issues found, exit0/0 |1.032s/2.597s|
| static-dialogue-cli-build-01 | dart compile exe bin/avelune_converter.dart -o Q/bin/avelune-converter-static-dialogue-v2 ; AOTarm64, exit0 |27.513s|
| static-dialogue-app-build-01 | flutter build macos --release --no-pub ;71.1MB, lipo x86_64 arm64, exit0 |72.299s|
| static-dialogue-mcp-build-01 / check-01 | npm run build / npm run check, exit0/0 |1.780s/1.772s|
| static-dialogue-mcp-live-01 | node --import tsx --test --test-concurrency=1 test/scene_dialogue_feedback_stdio.test.ts ;1PASS/0SKIP, exit0 |13.792s|
| kan03-probe-run-06 | Workflow public sur98/100/102 : canApprove=true,44events,9adaptés/35quarantinés,79artefacts/431mutations, exit0 |208.745s|
| static-dialogue-package-01 / install-static-dialogue-v2-run-01 | ZIP/inventaire puis extraction, CLI help→plan→convert→verify, source intacte/verify read-only, exit0/0 |4.430s/1.297s|

Les SKIP sont des absences de preuve. Le premier test texte avait un const invalide sur DialogueTextSegment ; le premier test de symbole avait un getter de fixture sur le mauvais objet. Leurs logs sont conservés, puis des RED fonctionnels distincts précèdent les corrections. La première revalidation root utilisait une mauvaise clé pinsBefore au lieu de fileHashesBefore ; elle n'a écrit aucun reçu, le contrôle corrigé revalide tous les hashes. Le premier apply_patch de test supplémentaire ne trouvait pas la ligne reformattée et n'a effectué aucune mutation ; patch adapté ensuite. Aucune erreur n'est remplacée par une annonce de succès.

La critique indépendante a reproduit par lecture le P2 d'admission des balises/entités :087:75 définit21tokens et087:89–95 sept entités. RED réel puis garde final correspondant exactement aux deux ensembles. Inconnus thing et AMP majuscule restent littéraux ; onze formes connues non portées ferment tout l'événement, sans fact/scène/dialogue actif. Fulladapter01/probe05 précèdent ce garde ; leurs résultats ne sont pas substitués aux runs finaux02/06.

### Publication existante, nouveau plan et distribution

La publication3cartes du normalizerv4 précédent termine dans centre-native-convert-02.json : exit0/1138.108s, published=true, verified=true, sourceUnchanged=true, playableCertified=false ; révision sha256:76958a78264921e865c12bce028ded97051c3a66d7f76d81021c3dfa6aa4e22c. Elle a8events adaptés/36inactifs ; le nouveau PNJ n'y est pas actif. CopieStudio1333fichiers byte-identical sous /Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/AC16-Kanto-Centre-20261014-ftgqyeej/Projet converti. UI réelle : Centre20×20 à29%, capture Q/centre-studio-01.png SHA0e47a79a1a4afbffea1e48241dc61e12d7255d1b55f8083b823897d125bcc4c4. Copie/source intactes après consultation ; aucune édition revendiquée pour ce Centre. Fenêtre30153 fermée, run177.430s, aucun survivant, protégés intacts.

Préparation finale06 : source restaurée23720fichiers, snapshotfd1e6e73879d90d3dbedffcd703e5bac5b3b58c9fc8a9186ce1e5d98233dbe4e, mêmes3sorties hors sélection explicitement exclues. PNJ102/14 est adapté, aucun gap, raw209/509+span1..2 et persistentFacingCertified=false présents. Recette4167octets SHA467b842affac946a58eebf375c76fb4f1b4f847db78c2cc7bed0f3e3c7089d13 ; plan approuvé3fc3f8ee0acb4b8ddc1f24aba175c2d37056d8516e4777f07901c0ac901085c2. La CLI réelle restaure cette recette dans centre-dialogue-native-convert-01, borne2400s ; publication encore en cours lors de ce complément, aucune ouverture Player du nouveau PNJ annoncée.

Nouvelle archive privée locale : apps/avelune_converter/build/distribution/AC16-local-20261014-static-dialogue-v2/AveluneConverter-local-validation.zip,37791981octets, SHA2c831dbd5cb438e9d5f826c5c8e46f2ff7b3007e19c3e652dfb0a68a3a20ea16 ; inventaire SHA6d81595fe401f169968c260000d69964574502b3a0b182681a603db0a0658f58.38files/35dirs/9liensrelatifs/1NOTICE/0sidecarPods. App.framework SHA6965b8111d5cf13b024f837c822e9ef690ca3a5e5ba9a02dd433989dbf1d1ed9 ; CLIb33c6779b6aea639d68652310b68fdea368cb1a0f81d529ba825f52a046f5698. Extraction réelle :2maps/1atlas synthétiques, révision33c5734abe5ae4b953dd8c6f7851617628f31a3733dcfe37e1454c622d690aa4. Pas de média Pokémon/source obligatoire, notarisation, publication publique ou validation x86_64 d'exécution ; le binaire GUI release final n'est pas encore qualifié visuellement.

### Parité, passes et auto-critique

API source/workflow/CLI et projection canonique sont testés ; writer existant non modifié. Aucun nouveau contrat cible ou action à enregistrer. MCP rebâti/checké, vrai describe du catalogue choicePolicy/lineFeedback/audioMedia/map.audio, mutation/refus/reopen/query/close passés sur racine temporaire étroite. PMCP-085 global reste PARTIAL ; cela ne constitue pas un nouveau parcours GUI du PNJ. Aucune modification par édition directe de projetJSON.

| Passe | Verdict |
|---|---|
| Audit / Architecture — root + ac15_connection_review_fresh | Source et contrat natif relus, couleurs/premierlock/facing bornés ; aucune règle de combat modifiée. |
| Implémentation — ac13_static_facing + root | Parser strict et texte stylé, whole-quarantine, refs/evidence et limites explicites ;4fichiers source/tests. |
| Tests — agent core + root | RED réels puis84core ciblés/880full/847adapters finals ; source réelle9/44 ; SKIP40+1 déclarés. |
| Build / Validation — root | Release universelle/AOT/ZIP extrait PASS ; Centre antérieur visible et fermé ; exportdialogue encore en cours, Player non prouvé. |
| Critique — ac15_connection_review_fresh | P2balises/entités trouvé puis fermé sur gel02, ensembles comparés exactement ; aucun autre P1/P2 concret. |

Auto-critique : c'est une adaptation utile du vrai dialogue, pas une certification globale de l'Essentials. Cadre/police/préférences source, timing complet du scheduler et facing sauvegardé restent non qualifiés. La source demeure une restauration historique partielle, distincte de l'original incomplet.35événements restent inactifs, dont porte/soinsCentre ; pas d'arrivée directionnelle ni de garde de réentrée inventés. La suite conserve KAN03 départ/dialogue/warp/état/save et tous les lots restants.

Git avant commit :6chemins ci-dessus, index vide et64étrangers à revalider en bytes/modes avant staging. Le contrôle après commit produira static-dialogue-commit-after-01.json avec SHA/parent/blobs/index/étrangers. Aucun push/rebase/amend/branche/worktree. AC13 existant dans Monde & narration PostBêta, actuellementDOING/PARTIAL ; après commit, TO REVIEW pour le code, sans DONE ni réduction des critères KAN03. AC16 garde DOING/PARTIAL.

## Complément du 14 octobre 2026 — Passages natifs et qualification du Centre

**AC-13 / KAN-03 / FG-090 et FG-093 : extension native livrée pour revue, domaine PARTIAL.** Le goal AC-00–AC-16 reste actif. Cette tranche donne aux passages une direction d'arrivée explicite et une transition sans fondu. Elle ne convertit pas encore les portes source du Centre : leurs programmes exigent également ton du monde, sons, attente, routes, visibilité et garde temporaire de réentrée. Les refus `warpFacingUnsupported` et `warpFadeUnsupported` restent présents dans le convertisseur.

### Audit initial et frontières

Base `main`, HEAD `354e7dfb156f39586d0330986d496b1d1d5486c0`, index vide. `Q/warp-native-initial-01.json` conserve les SHA et modes des 64 chemins étrangers. Q désigne `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac16-refresh-20261014-ftgqyeej`. La copie privée `Q/repository` reprend HEAD et seulement les modifications de cette tranche ; writer, bordures, rendu spatial et plateformes étrangers sont exclus. Les 64 empreintes étrangères sont encore identiques lors de la vérification précédant la revue finale.

L'oracle source est l'archive Scripts SHA `3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d`, décodée comme données inertes. `034 Interpreter_Commands` distingue direction 0 et absence de fondu ; la sortie Map102/event1 transfère vers Map100 (13,25), conserve la direction et interdit le fondu interne. L'entrée Map100/event8 impose direction nord et aucun fondu, mais dépend aussi de mouvements et de `TempSwitch` locaux à l'instance. `034.rb:383–386/899–901/1051–1053`, `039.rb:38–46/75–81` et `065.rb:42/126` établissent attente, Tone/SE non bloquants, durée/20, interpolation et viewport du monde. Tone est additif et ne filtre pas le dialogue ; la section126, `GameData::Move`, n'est pas un oracle de viewport. Les effets manquants ne sont pas ignorés pour activer la porte.

L'extension du modèle cible est autorisée par la réponse explicite de Yoahn autorisant les modifications nécessaires à l'avancement. Les contrats restent dans `map_core`, l'auteur canonique dans `map_authoring`, les consumers dans `map_runtime` et les pickers dans les deux interfaces. Aucun moteur de combat, script Ruby exécuté, appel IA obligatoire, migration pré-1.0 ou roadmap modifiée.

### Publication et Player du vrai PNJ du Centre

La publication précédemment en cours est maintenant terminée : `centre-dialogue-native-convert-01`, exit0 / 1013.012s, `published/verified/sourceUnchanged=true`, `playableCertified=false`. Révision `sha256:8b9505a3b78c98b0364207c55180df6ec08496b8b527312dcb5d303b1891ea5a`, snapshot source `fd1e6e73879d90d3dbedffcd703e5bac5b3b58c9fc8a9186ce1e5d98233dbe4e`. Les trois cartes 98/100/102 comportent 9 événements adaptés sur 44, 35 inactifs. La source restaurée de 23720 fichiers reste une restauration partielle, distincte du dossier original incomplet.

La copie Studio de 1349 fichiers se trouve sous `/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/AC13-Centre-dialogue-20261014-ftgqyeej/Projet converti`. Le vrai `StudioBootstrap` puis « Enregistrer et tester » a ouvert le Player. Des touches `HardwareKeyboard` ont fait marcher le joueur de (9,9) à (16,7), devant le PNJ bloquant (16,8), sans téléportation de test. Interaction réelle : texte « I heard that ghosts haunt / Lavender Town. », bleu et retour de ligne source ; PNJ ouest→nord face au joueur ; déplacement ouest refusé pendant le dialogue ; fermeture puis seconde interaction réussies.

Preuves : `Q/centre-dialogue-player-trace-01.json`, `centre-dialogue-published-npc-01.json`, `centre-dialogue-after-player-inventory-01.json` et capture `captures/centre-real-npc-dialogue-01.png` à côté de la copie Studio. Export et copie inchangés après Player, aucun fichier manquant ou supplémentaire. La fenêtre QA PID48925 est fermée normalement : `centre-dialogue-studio-run-02`, exit0 / 852.666s, zéro survivant ou signal, protégés inchangés. Le save/reload de cette interaction, les soins, les portes et la disposition originale de la fenêtre ne sont pas qualifiés par cette trace.

### Inventaire complet du code de passage

Les diffs Git et fichiers source sont canoniques. Zones fonctionnelles de chacun des 25 fichiers source/tests, auxquelles s'ajoute le présent rapport :

| Fichier | Zone modifiée et raison |
|---|---|
| `packages/map_core/lib/src/models/scene_interactive_command.dart` | `SceneWarpTransition`, factory Warp, JSON, equality/hash : direction optionnelle et politique `mapDefault/none`, valeurs présentes strictement validées. |
| `packages/map_core/lib/src/models/narrative_command_descriptor.dart` | Type de paramètre Warp transition pour les formulaires guidés. |
| `packages/map_core/lib/src/read_models/narrative_command_catalog.dart` | Les quatre paramètres Warp, labels carte/point/direction/transition et valeurs neutres. |
| `packages/map_core/lib/src/authoring/scene_command_payload_builder.dart` | Construction typée des options et refus des valeurs malformées. |
| `packages/map_core/test/scene_interactive_command_test.dart` | Round-trip des quatre directions, défauts, identité et JSON invalide ; construction no-code. |
| `packages/map_authoring/lib/src/domains/narrative/scene_actions.dart` | Extensions découvrables du contrat ; set sémantique conserve metadata et valide le point réel de la carte cible. |
| `packages/map_authoring/test/domains/narrative/scene_warp_transport_test.dart` | API directe et JSONL plan/apply/query/reopen, absence d'écriture au plan et refus d'options/références invalides. |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_action_form.dart` | Pickers direction/transition, neutralité et remise à zéro d'une arrivée lorsque la carte change. |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_action_references.dart` | Lecture canonique de la destination et de ses vrais points ; erreurs et résultats tardifs gardés. |
| `apps/avelune_studio/test/presentation/scene_warp_form_test.dart` | Formulaire réel, options, références absentes, chargement tardif, erreur/retry et disposal. |
| `packages/map_editor/lib/src/application/services/narrative_template_catalog.dart` | Templates legacy alignés sur les valeurs neutres du contrat. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart` | Les points Warp portent leur carte propriétaire. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | Callback `EditorNotifier.loadMapSnapshotById`, racine et projet revérifiés avant/après lecture. |
| `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` | Transmission du callback jusqu'au véritable builder à travers ses quatre niveaux. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart` | Carte inactive chargée sans activation, pickers filtrés, loading/error bloquants, contrôle d'identité et disposal. |
| `packages/map_editor/test/narrative_template_catalog_test.dart` | Régressions des templates neutres. |
| `packages/map_editor/test/scene_action_builder_test.dart` | Options explicites/strictes et loader destination ; non-régression du catalogue moveNpc. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Consumer 2D : direction rendue, overlay absent pour `none`, collision du rectangle des pieds après revalidation et booléen de transfert effectif. |
| `packages/map_runtime/test/playable_map_game_connection_arrival_collision_test.dart` | 24 cas Warp/connexion, masques hors centre, PNJ, eau/surf, pose rendue et sauvegarde, refus d'un no-op concurrent. |
| `packages/map_runtime/lib/src/session/spatial_exploration_game_session_runtime.dart` | Consumer 3D physique avant dialogue, activation après commit parent, rollback, checkpoint et démontage garantis. |
| `packages/map_runtime/lib/src/spatial/spatial_exploration_session.dart` | Compensation dédiée sous pause, défaut strict pour les transferts ordinaires, validations physiques conservées. |
| `packages/map_runtime/lib/src/spatial/spatial_gameplay_events.dart` | Projection read-only de Scene et override de présence pour le host ; lecteur transactionnel global inchangé. |
| `packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart` | Projection des conséquences bufferisées installée pour la Scene entière, libérée en finally. |
| `packages/map_runtime/test/session/spatial_exploration_game_session_runtime_test.dart` | Directions, transitions, pose physique, commit/annulation, présence conditionnelle, récompense unique, stop/dispose. |
| `tools/pokemap_mcp/test/scene_warp_options_stdio.test.ts` | Vrai client MCP stdio : describe, plan read-only, mutation, refus, query et close/reopen sous racine étroite. |

Absence de direction signifie conserver la direction courante ; `mapDefault` conserve la transition de la carte. `none` supprime le fondu visuel, sans supprimer le verrou, chargement ou contrôle de collision. En 3D, les deux valeurs utilisent explicitement le transfert instantané natif actuel. La pose physique doit être vérifiée avant de retourner `completed` ; un transfert ignoré pendant une autre transition retourne `blocked`, même si la pose initiale coïncide déjà avec l'arrivée.

Les conséquences restent privées jusqu'au commit de la scène. Une projection read-only des facts peut faire apparaître ou disparaître un PNJ bloquant avant Warp sans les publier dans l'état global. La récompense de 25 avant Warp reste à zéro pendant le dialogue, puis vaut exactement 25 au commit. Stop/dispose compensent avec l'état committé et conservent Story jusqu'au démontage ; un échec de compensation ne saute pas l'unmount.

### Tests, analyse et build

Les commandes exactes, cwd, SHA des logs, pins de sources et UID/start/command des descendants sont conservés dans les reçus Q. Les runs indépendants ne sont pas additionnés en un faux nombre de tests uniques.

| Reçu | Commande dans son package | Résultat terminal |
|---|---|---|
| `warp-core-green-02` | `dart test test/scene_interactive_command_test.dart test/narrative_command_catalog_test.dart test/narrative_command_contract_parity_test.dart test/narrative_command_catalog_closure_test.dart --reporter expanded --concurrency=2` |34 PASS, exit0,2.726s|
| `warp-core-analyze-01` | `dart analyze lib/src/models/scene_interactive_command.dart lib/src/models/narrative_command_descriptor.dart lib/src/read_models/narrative_command_catalog.dart lib/src/authoring/scene_command_payload_builder.dart test/scene_interactive_command_test.dart` |No issues, exit0,3.025s|
| `warp-authoring-green-03` | `dart test test/domains/narrative/scene_warp_transport_test.dart test/domains/narrative/scene_graph_patch_transport_test.dart test/domains/narrative/scene_graph_patch_test.dart --reporter expanded --concurrency=2` |9 PASS, exit0,2.587s|
| `warp-authoring-analyze-01` | `dart analyze lib/src/domains/narrative/scene_actions.dart test/domains/narrative/scene_warp_transport_test.dart` |No issues, exit0,3.269s|
| `warp-studio-green02` | `flutter test test/presentation/scene_warp_form_test.dart test/presentation/ui06_scene_action_form_test.dart --reporter expanded` |14 PASS, exit0,5.577s|
| `warp-studio-analyze01` | `flutter analyze --no-pub lib/presentation/features/scenes/scene_action_form.dart lib/presentation/features/scenes/scene_action_references.dart test/presentation/scene_warp_form_test.dart` |No issues, exit0,5.086s|
| `warp-legacy-loader-final-tests-01` | `flutter test --no-pub test/scene_action_builder_test.dart test/narrative_template_catalog_test.dart --reporter expanded` |55 PASS, exit0,5.230s|
| `warp-legacy-loader-final-analyze-01` | `flutter analyze --no-pub` sur les sept fichiers |No issues, exit0,11.169s|
| `warp-runtime-final-03` | `flutter test --no-pub test/playable_map_game_connection_arrival_collision_test.dart test/scene_interactive_command_runtime_executor_test.dart test/narrative_command_save_load_integration_test.dart test/phase_a_golden_battle_slice_smoke_test.dart test/session/spatial_exploration_game_session_runtime_test.dart test/narrative_scene_runtime_execution_test.dart test/spatial_gameplay_events_test.dart --reporter expanded --concurrency=2` |142 PASS, exit0,10.310s|
| `warp-runtime-analyze-final-04` | `flutter analyze --no-pub --no-fatal-infos` sur les cinq sources runtime et deux tests |exit0,9.676s ; zéro error/warning,24 infos dont toutes les lignes existent dans HEAD ; pas « No issues ».|
| `warp-adapters-targeted-final-01` | `dart test test/source_event_projection_test.dart test/native_project_writer_test.dart --reporter expanded --concurrency=2` |105 PASS, exit0,21.897s|
| `warp-mcp-build-01` / `warp-mcp-check-01` | `npm run build` / `npm run check` |exit0/0,1.888s/1.396s|
| `warp-mcp-live-02` | `node --import tsx --test --test-concurrency=1 test/scene_warp_options_stdio.test.ts` |1 PASS /0 SKIP, exit0,8.447s|
| `warp-studio-debug-build-01` | `flutter build macos --debug --no-pub -t Q/warp_player_main.dart` avec les deux defines de copie QA/captures enregistrés dans le reçu |exit0,39.368s ; app réelle construite ; deux ibtoold descendants recontrôlés puis terminés normalement.|

Les RED fonctionnels sont distincts des erreurs de fixture/compilation : core 9PASS/6FAIL ; 2D 15PASS/8FAIL puis contre-exemple same-map `completed` attendu `blocked` ; legacy loader 1PASS/6FAIL ; 3D 6PASS/11FAIL puis cinq FAIL de présence/checkpoint/dispose. La critique a demandé le loader de carte inactive, la projection provisoire et l'ordre de disposal ; ces cas ont leurs GREEN spécifiques avant le run root final142.

Deux tests voisins échouent aussi avec le fichier Flame exact de HEAD : `Scene warp commits its parent before dispatching destination mapEnter` (timeout) et `connection mapEnter dispatch interlocks movement, transitions and checkpoints` (attendu0,0, réel2,0). Runs `warp-interlock-isolated-02` et `warp-interlock-baseline-01` :8PASS/2FAIL, exit1,18.039s/5.617s. Seul le fichier Flame privé a été remplacé temporairement ; restauration exacte SHA `6f2d7a680bcf64f1abf0a4a07392db0e942f2b51d305afefc571135d87ad4828` attestée par `warp-interlock-baseline-restoration-01`. Le checkout utilisateur n'a pas été restauré.

La suite native core complète `warp-native-core-full-01` n'est pas verte :3395PASS/1SKIP/9FAIL avant sortie255/201.079s. Les benchmarks CLI de la copie sans Git refusent leur précondition (exit64), deux attentes de dry-run/cataloque bêta restent rouges sans modification de leurs sources, puis deux compilations échouent faute d'espace. Aucun critère bêta n'a été élargi. L'unique kernel temporaire de ce run terminal,8759056291B, a été supprimé après contrôle UID, lsof vide, absence de référence de processus et SHA de log ; reçu `warp-native-core-owned-kernel-cleanup-01`. Aucune purge générale. RED spatial05 interrompu pour cette cause reste NON PASS malgré exit0 après SIGINT autorisé.

Les package_config privés ont ensuite disparu sans mutation des pubspec/locks ; analyze spatial03 produisant1477 imports inconnus et isolated01 sans flutter_test sont des vérifications invalides, non des preuves de code rouge ou vert. Récupérations offline runtime/Studio/adapters : exit0, pins pubspec/lock identiques, aucune résolution du host modifiée. L'analyse finale04 remplace ce diagnostic ; ses24 infos sont reliées à des lignes HEAD par `warp-runtime-analysis-info-provenance-01.json`.

### Parcours réel du passage natif dans Studio et Player

Copie distincte `/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/AC13-Warp-native-20261014-ftgqyeej/Projet QA`. L'initialisation est une copie exacte1349fichiers,163764809B de la publication précédente. Le helper JSONL interroge le catalogue courant406actions, puis ajoute huit mutations par `warp.create`, `entity.create`, `scene.upsert` et `event_v2.record_upsert`, avec révision fraîche, plan sans écriture native et apply. Réouverture dans une nouvelle session stricte, validation valide,99warnings Pokémon conservés. Révision `sha256:27580ba160afd8e0dcd67adc5f6154cfaa8534a80c5abb1facd19f50f4c4abf1`. `warp-native-authoring-run-01` : exit0,59.711s, huit pins stables, zéro signal/survivant, protégés inchangés. Ce helper qualifie API/JSONL ; le test MCP stdio séparé porte la preuve MCP.

Deux scènes et PNJ temporaires QA sont ajoutés sans réactiver un événement source : « QA native — Centre → extérieur », arrivée extérieur14,34 nord/none ; « QA native — extérieur → Centre », arrivéeCentre9,9 sud/mapDefault. Les deux points sont libres avec la hitbox pure12×8, sans eau. Ces personnages de test ne sont pas les portes Essentials.

Vraie fenêtre Studio PID91653, `StudioBootstrap` depuis le snapshot qualifié. Histoire → Voir toutes les scènes → recherche « QA native » → scène Centre → bloc Warp. Le formulaire charge la carte Route10-N et son point réel14,34 ; options Nord et Sans transition visibles. Changement Ouest → Appliquer l'action → Enregistrer : interface Enregistrée et lecture du payload sur disque confirmant west/none. Retour Nord avec les mêmes contrôles, enregistré puis relu sur disque. Capture `captures/warp-form-direction-transition-01.png`. Le tap initial par label de champ de recherche est refusé par Marionette ; le champ est ensuite ciblé par ses bounds réellement observées, aucun tap aveugle ni changement d'application.

Carte → Centre → Enregistrer et tester ouvre le vrai Player à9,9/sud. Touche E réelle : arrivée extérieur14,34/nord. E de nouveau : retourCentre9,9/sud. Troisième E : deuxième arrivée extérieur14,34/nord. Les trois transitions terminent ; les deux sorties `none` n'ont aucun fade dans le log, le retour mapDefault fait170ms out puis170ms in. Captures `captures/warp-player-exterior-north-01.png` et `warp-player-centre-south-01.png`, vues par le root ; direction et carte vérifiées par observations runtime, non par un faux GameState.

Preuves `warp-studio-player-trace-01.json` et `warp-studio-player-transition-log-01.json`. Le titre du playtest conserve le nom de la carte de lancement ; la carte réellement active est celle de l'observation runtime et de la capture. Aucun save/reload cross-process de cette QA n'est revendiqué. La fenêtre est fermée normalement via son extension de fermeture, puis Marionette déconnecté : `warp-studio-player-run-01`, exit0,508.716s, zéro survivant/signal, protégés inchangés. Le message « Failed to foreground app » est conservé ; la fenêtre, son arbre et le Player ont ensuite été effectivement observés et pilotés dans ce processus précis.

Inventaire final `warp-native-after-player-inventory-01.json` : publication1349fichiers inchangée, aucun manquant/extra. Les quatre payloads natifs de la QA restent byte-exacts après restitution Nord ; seuls les trois journaux d'authoring et un blob d'historique enregistrent les éditions UI voulues. Aucune mutation de Route9, médias, anciens événements ou scènes source. Ce résultat qualifie un aller-retour natif contrôlé ; sourceDoorCertified demeure false.

### Parité, critique et limites de livraison

API directe, JSONL, pickers et MCP disposent des mêmes options typées. Le catalog live expose `arrivalFacingValues`, `transitionValues` et leur valeur neutre. Le set sémantique refuse un warp absent de la destination ; les opérations génériques de brouillon `scene.upsert`/`scene.graph.patch` conservent leurs diagnostics de dépendance et ne promettent pas le même refus strict. PMCP-085 et la conformance globale restent PARTIAL, la compilation complète du parcours legacy n'est pas certifiée : son smoke historique rencontre des types/switches hors tranche et n'est pas utilisé comme preuve du gel final à sept fichiers.

| Passe | Verdict borné |
|---|---|
| Audit / Architecture — root + ac15_connection_review_fresh | Contrats source/cible et chaîne loader réels identifiés ; porte inconnue toujours entièrement inactive. |
| Implémentation — root + ac15_connection_review_fresh + ac13_warp_runtime_tests | Contrat, 2D/3D et les deux interfaces raccordés ; aucune conséquence double ni lecteur global provisoire. |
| Tests — agents + root | RED fonctionnels puis GREEN ciblés ;142 runtime et105 converter finals, incidents et suites voisines rouges séparés. |
| Build / Validation — root + ac15_connection_review_fresh | Studio debug compilé, QA authorée par API/JSONL et rouverte strictement ; formulaire sauvegardé et trois passages réels Player prouvés ; fenêtres propres fermées. |
| Critique finale — ac13_warp_final_review |14 fichiers gelés relus, SHA identiques avant/après ; trois P2 fermés et faux completed2D corrigé ; aucun nouveau P1/P2 démontré. |

Gel legacy : `warp-legacy-final-pins-02.json`, patch SHA `9dc8f5bbd8926387f18d5f9dbcaa8ee2a9e8b70e252c4b3ce9b999ecfcb0ab6a`. Gel spatial : `warp-spatial-freeze-04.json`, patch SHA `bfcb918626ee4cbc1f469c6b6db140ff8d0cc0194a582feae61cb7ddc3149159`. La critique est read-only ; ses résultats de tests sont ceux des reçus, pas de nouveaux runs inventés.

Auto-critique : le contrat de passage est utile mais ne suffit pas au programme des portes Essentials. Tone non bloquant, SE naturel, attentes/routes/visibilité et TempSwitch sont encore nécessaires. Aucun soin ni combat source n'est activé. Les tests/runtime, le build debug, le Player visible et une release installée restent des preuves distinctes. Les interfaces legacy complètes, parité globale et jeu complet restent PARTIAL. La suite conserve tous les lots du goal et KAN-03 ; FG-090/093 ne sont pas proposés DONE, FG-092 reste TODO dans la roadmap inchangée.

Commit local ciblé autorisé, aucun push/rebase/amend/branche/worktree. Avant staging : hygiène Markdown, diffcheck, index et26 chemins de tranche à contrôler,64 étrangers en SHA/mode. Le reçu privé après commit indiquera SHA/parent/blobs/index et conservation des étrangers. Notion existant AC-13, unique domaine Post Bêta Monde & narration, TO REVIEW pour l'implémentation et PARTIAL pour le résultat global ; DONE réservé à Yoahn. Aucun nouveau ticket de carte ou bug, aucune gate bêta modifiée.


## Complément du 14 octobre 2026 — Reconnaissance des commandes de présentation source

**AC-13 / KAN-03 : IR source livré pour revue, parcours complet toujours PARTIAL.** Le convertisseur reconnaît maintenant les commandes RMXP 106 (attente), 223 (Tone) et 250 (SE) du profil exact Kanto. Leur reconnaissance ne les active pas dans un projet Avelune. Les handlers, formulaires et transports natifs de présentation font l'objet de la tranche suivante ; aucun soin, combat ou porte source n'est annoncé fonctionnel.

### Audit et périmètre

HEAD initial `34012aede41c65c95850a68fac85e303a43d454d`, branche main, index vide. Le reçu `Q/presentation-root-initial-01.json` retrouve les 64 empreintes étrangères identiques au contrôle initial Warp. Les modifications Runtime de présentation en préparation sont exclues de ce commit. Q conserve le sens donné dans le complément précédent ; R est sa copie privée sans Git. Le writer étranger reste hors périmètre. L'autorisation de commits locaux entre lots vient du goal explicite de Yoahn ; aucune publication ou autre opération Git n'est ajoutée.

L'oracle demeure l'archive Scripts `3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d`, lue comme données. `034.rb:383–386/899–901/1051–1053` et `039.rb:38–46/75–81` établissent les attentes à 20 ticks/s et les effets non bloquants. Le SHA recalculé de 039 est `30a4141354d5580f777306d6d0ecdbb706c411ff445aec44afeb55f2c1f7dc0d`. Aucun Ruby n'est exécuté. Les besoins sont la conservation des valeurs littérales, durées, références brutes et locators, ainsi que le refus de toute activation partielle.

| Fichier | Zones modifiées et résultat |
|---|---|
| `packages/avelune_converter_core/lib/src/source_events.dart` | Profil `kanto-events-static-v3` et attestation 039 ; nouveaux `SourceToneNode`, `SourceWaitNode`, `SourceSoundEffectNode` ; dispatch 106/223/250 et helpers stricts de durée, Tone32B/f64 et AudioFile. |
| `packages/avelune_converter_core/test/source_events_test.dart` | 132 cas finaux incluant valeurs/durées, SE, Tone non fini ou invalide, arité/opcode/indent/locator/ref erronés, métadonnées d'encodage étendues, profil/hash, et non-régressions pages/dialogues/choix. |
| `packages/avelune_converter_adapters/lib/src/source_event_projection.dart` | `_blockGaps` conserve `sourcePresentationUnsupported` pour les trois nouveaux nœuds avant toute projection d'événement. |
| `packages/avelune_converter_adapters/test/source_event_projection_test.dart` | 35 cas finaux ; chacune des nouvelles commandes et leur séquence entière restent inactives, sans effet natif partiel ; evidence/hash du nouveau profil vérifiés. |
| `documentation/reports/converter/AC-13/13_native_events.md` | Note d'état actualisée et ce complément consolidé, sans nouveau Markdown. |

Tone exige exactement 32 octets, quatre doubles little-endian finis, RGB dans [-255,255] et gris dans [0,255]. Les ticks sont des entiers source non négatifs à 20 Hz, conservés avec leur conversion en ms. SE conserve le nom littéral, le volume entier [0,100] et le pitch [50,150] sans prétendre que le moteur cible consomme tout pitch. Les annotations d'encodage standard restent admissibles ; clés et valeurs passent par les gardes de nœud brut. Les autres extensions/classes/champs/references malformés sont refusés. Le profil v3 est le seul profil courant de cette archive ; aucun alias ou fallback v2 n'est ajouté. Le hash de profil et l'evidence de projection changent, même quand les octets normalisés source restent identiques.

### Preuve sur la sortie originale du Centre

`Q/presentation-ir-center-exit-run-01.json` : exit0,14.935s, pins stables, zéro signal/survivant, protégés inchangés. Le helper relit uniquement sept fichiers bruts archivés ; aucune lecture de la source vivante, publication ou script exécuté. Le snapshot `fd1e6e73879d90d3dbedffcd703e5bac5b3b58c9fc8a9186ce1e5d98233dbe4e`, normalization `e152056177a5d5cb0ca8c902a62748c88b27f9da00504e85404e7ad06f23d17f` et archive `8f7ea614cdd7b36bce09df3c62f014305aa7df2857275df8560c3345a945c734` sont inchangés. Profil v3 `284a13b6bb0b24b790bdec8c4bfd6cf2c1c76a193805f07ee28fd0470beea5ef`.

Map102/event1/page0 conserve exactement cinq nœuds : SE « Exit Door »,80/100 ; Tone[-255,-255,-255,0],6ticks→300ms ; Wait8ticks→400ms ; Warp100,(13,25),direction0,sansfade ; Tone[0,0,0,0],6ticks→300ms. Les spans et locators command0..4 sont exacts. La projection reste `quarantinedWholeEvent`, avec `sourcePresentationUnsupported`, `triggerContractUnsupported` et `warpFadeUnsupported`, `nativeEventId=null` et aucune commande adaptée. Résultat détaillé `Q/presentation-ir-center-exit-result-01.json`, SHA `b64988adf53e64a16d5fc6d88e3d9e4729ed16bca0b9f8eea68061748727cd6e`.

### Vérification et limites des preuves

Tous les runs utilisent `Q/run_owned.py` et consignent cwd, commandes exactes, PID/descendants, identités, hashes avant/après, logSHA et nettoyage. Les quatre fichiers host/R sont égaux au gel `Q/presentation-ir-freeze-01.json`.

| Reçu | Commande depuis le package R indiqué | Résultat exact |
|---|---|---|
| `presentation-ir-core-green-03` | core : `dart test test/source_events_test.dart --reporter expanded --concurrency=1` |132 PASS, exit0,4.695s|
| `presentation-ir-projection-green-02` | adapters : `dart test test/source_event_projection_test.dart --reporter expanded --concurrency=1` |35 PASS, exit0,6.815s|
| `presentation-ir-core-analyze-02` | core : `dart analyze lib/src/source_events.dart test/source_events_test.dart` |No issues found, exit0,1.371s|
| `presentation-ir-projection-analyze-02` | adapters : `dart analyze lib/src/source_event_projection.dart test/source_event_projection_test.dart` |No issues found, exit0,2.297s|
| `presentation-ir-core-full-green-01` | core : `dart test --reporter expanded --concurrency=1` |926 PASS/1 SKIP, exit0,76.709s ; checkpoint avant les deux dernières gardes d'encodage, pas suite complète des blobs finaux|
| `presentation-ir-cli-resolution-01` | CLI : `dart pub get --offline --enforce-lockfile` |exit0,1.035s ; manifeste/lock inchangés, résolution privée seulement|
| `presentation-ir-cli-build-01` | CLI : `dart compile exe bin/avelune_converter.dart -o Q/presentation-ir-converter-cli-01` |exit0,25.491s ; compilation AOT de la CLI privée, aucune release GUI installée ou publiée|

Le RED initial core117PASS/13FAIL comprend 12 contrepreuves fonctionnelles et une fixture Wait malformée, refusée plus tôt par le normalizer. La première GREEN intermédiaire129PASS/1FAIL conserve cet échec de fixture ; le test final vérifie maintenant `canPlan=false` et l'absence d'événement, sans relâcher la production. Les deux RED d'encodage ultérieurs sont fonctionnels. Le RED projection31PASS/4FAIL prouve la garde manquante. Le SKIP complet concerne le témoin réel Kanto CONN15. Aucune addition des totaux de runs ni certification globale n'est annoncée.

Aucun nouveau contrat authoring natif ou action MCP n'est introduit par cette seule IR. Le convertisseur continue de produire des événements entièrement en quarantaine ; les séquences source ne sont pas écrites par une sauvegarde générique de carte. API/UI/MCP de Tone/SE et leurs dépendances restent à qualifier dans la tranche native. Les fixtures n'ajoutent aucun asset Pokémon privé au dépôt.

| Passe | Verdict |
|---|---|
| Audit / Architecture — root + sourceagent | Timing du projet exact et références brutes établis ; pas de fallback depuis un autre moteur. |
| Implémentation — ac13_warp_runtime_tests | Trois IR strictes, nouveau profil et gardes entières ; quatre fichiers de code/tests. |
| Tests — agent source + root | RED distincts de la fixture malformée, 132+35 ciblés finaux, analyses sans issues, vraie sortie Centre relue. |
| Build / Validation — root | AOT CLI privée PASS ; résolutions privées à locks stables ; aucun nouveau Player lancé. |
| Critique finale — ac15_connection_review_fresh | Quatre fichiers relus en readonly, pins et oracle recalculés ; aucun nouveau P1/P2 dans le scope. |

Auto-critique : reconnaître le programme de la porte ne le rend pas jouable. Le renderer, le son naturel, la durée de vie après endScene, les routes/visibilité/TempSwitch d'entrée et le save/reload ne sont pas prouvés par ce commit. L'IR accepte une plage de pitch plus large que l'audio natif actuellement raccordé ; l'admission cible doit donc rester bornée et refuser les valeurs non prises en charge. La suite complète core finale n'est pas relancée après deux gardes locales déjà ciblées ; la distinction est explicite. Le goal AC00–16 reste actif, AC13/FG082/090/093 PARTIAL et FG092 TODO, roadmap inchangée. Notion AC13 existant sera actualisé avec ce commit, TO REVIEW pour le code et PARTIAL pour le résultat global ; aucune nouvelle famille ou gate bêta.

## Complément du 14 octobre 2026 — Présentation native 2D

**AC-13 / KAN-03 : tranche native à revoir ; conversion complète toujours PARTIAL.** Le Player 2D consomme maintenant les deux commandes natives worldTone et playSoundEffect. Le convertisseur reconnaît leurs homologues source, mais conserve sourcePresentationUnsupported : aucune porte Essentials n'est admise par cette tranche. Les scripts source, la logique de soins et les combats source ne sont pas activés. Les combats demeurent ceux d'Avelune.

### Audit, contrats et risques

Base host 957d244cd65b281f2911043fa6e20c7c7d0ed530, main, index vide. Le manifeste Q/native-presentation-host-publish-02.json atteste la copie de 35 sources/tests depuis R et la suppression de l'ancien adapter audio ; les 64 chemins étrangers conservent SHA et mode depuis Q/presentation-root-initial-01.json. Le writer Converter, le mobile, les bordures et le rendu spatial restent hors périmètre. Q et R gardent leurs définitions précédentes. Le snapshot privé permet de qualifier le scope sans incorporer les travaux étrangers ; il ne prouve pas une compilation de l'ensemble du worktree host.

L'audit a distingué programmation, début réel de lecture, fin naturelle et durée de vie des scènes. Tone ne doit pas teinter les contrôles du Player, sa durée doit avancer une seule fois par update, et un SE ne doit pas s'arrêter parce que sa scène se termine. Une fermeture pendant un démarrage sonore suspendu ne doit pas se convertir en sortie normale permettant un commit de récompense. La documentation et l'installation Flame 2.0.0-dev.1 ont guidé le montage : un PostProcessComponent sur la caméra, hors HUD ; aucun await ajouté à camera.add, qui retourne void.

worldTone conserve quatre nombres finis, RGB [-255,255], gris [0,255] et une durée entière [0,2147483647] ms. Son port completed signifie que l'effet est programmé. playSoundEffect conserve une référence unique à un média sound non bouclé et un gain fini [0,1] ; completed signifie que le démarrage du driver a réussi. Le pitch et les paramètres inconnus sont refusés. Ces effets sont transitoires ; ils ne deviennent pas des facts persistants. Le catalogue annonce explicitement « Disponible dans le Player 2D. » Le consumer spatial n'est pas annoncé compatible avec ces effets.

Le contrôleur Tone interpole les quatre canaux, reprend une nouvelle cible depuis la couleur réellement affichée et restaure un checkpoint au temps absolu courant sans rembobiner. La matrice applique la luminance .299/.587/.114, puis les offsets RGB, et conserve alpha. Le neutral fast path, le montage unique, le passage entre cartes et le reset au disposal sont testés. L'adapter audio est partagé par les feedbacks de dialogue et les SE natifs, avec le mixer existant et la gestion ME conservée. Les SE restent actifs jusqu'à leur EOF ; un handle reçu après disposal est arrêté et son démarrage ne rend pas completed.

### Inventaire et zones du diff

Le diff Git et les fichiers source sont les preuves canoniques ; aucun snapshot du contenu intégral n'est ajouté. Les 35 chemins source/tests, la suppression et le présent rapport composent cette tranche.

| Fichier | Zone modifiée, raison et effet |
|---|---|
| packages/map_core/lib/src/models/scene_interactive_command.dart | Kinds, factories, classes Tone/SE, JSON strict, equality/hash et ports déclarés. |
| packages/map_core/lib/src/models/narrative_command_descriptor.dart | Paramètres number et soundMediaReference pour les formulaires guidés. |
| packages/map_core/lib/src/read_models/narrative_command_catalog.dart | Descriptors, labels, paramètres, portée 2D et promotion editor/runtime après qualification native. |
| packages/map_core/lib/src/authoring/scene_command_payload_builder.dart | Construction depuis les champs no-code, bornes numériques et refus du pitch. |
| packages/map_core/lib/src/diagnostics/scene_diagnostics.dart | Référence SE unique, type sound, non-loop ; diagnostics contre les références absentes ou ambiguës. |
| packages/map_core/lib/src/read_models/narrative_dependency_index.dart | Dépendance Scene vers média, chemin du nœud précis et message propre aux médias indisponibles. |
| packages/map_core/test/scene_world_presentation_command_test.dart | Round-trip et valeurs invalides, durées, champs inconnus, gain et pitch refusé. |
| packages/map_core/test/scene_sound_effect_reference_test.dart | Références absentes, ambiguës, mauvais type, loop et messages de dépendance. |
| packages/map_core/test/narrative_command_catalog_closure_test.dart | Publication 2D des deux descriptors et cohérence catalogue/commande. |
| packages/map_core/test/narrative_command_contract_parity_test.dart | Deux nouveaux exemples et média valide pour la bijection contractuelle. |
| packages/map_authoring/lib/src/domains/narrative/scene_actions.dart | Extensions découvrables, bornes et validation sémantique de la scène éditée. |
| packages/map_authoring/test/domains/narrative/scene_world_presentation_transport_test.dart | API directe et JSONL, plan read-only, mutation, refus sans écriture, query et cold reopen. |
| tools/pokemap_mcp/test/scene_world_presentation_stdio.test.ts | Vrai serveur stdio et worker Dart, describe/plan/apply/refus/reopen sous racine étroite. |
| packages/map_runtime/lib/src/application/scene_runtime/scene_interactive_command_runtime_executor.dart | Dispatch typé Tone/SE et validation du port réellement reçu. |
| packages/map_runtime/lib/src/application/scene_runtime/scene_sound_effect_playback_port.dart | Port SE indépendant des cues de dialogue. |
| packages/map_runtime/lib/src/application/scene_runtime/scene_world_tone_controller.dart | Interpolation, retarget, checkpoint, reset et disposal. |
| packages/map_runtime/lib/src/presentation/flame/flame_world_tone_post_process.dart | Matrice du monde, alpha préservé, neutral fast path et absence de double tick. |
| packages/map_runtime/lib/src/presentation/flame/flame_narrative_sound_playback_adapter.dart | Adapter commun, gain par lecture, démarrage réel, durée naturelle et handle tardif arrêté. |
| packages/map_runtime/lib/src/presentation/flame/flame_dialogue_feedback_playback_adapter.dart | Suppression : responsabilité reprise par l'adapter commun ; aucun second chemin audio conservé. |
| packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart | Montage/update/disposal Tone, callbacks SE propriétaires de la session, références strictes et trois gardes lifecycle corrigées. |
| packages/map_runtime/lib/map_runtime.dart | Exports publics du port SE et de l'adapter audio commun. |
| packages/map_runtime/test/playable_map_game_connection_arrival_collision_test.dart | Tone/SE réels, fin de scène, fermeture pendant SE/load, pages de carte et absence de commit tardif. |
| packages/map_runtime/test/scene_interactive_command_runtime_executor_test.dart | Handlers absents, dispatch des commandes et sorties déclarées. |
| packages/map_runtime/test/dialogue_feedback_playback_test.dart | Adapter renommé, SE indépendant, gain et durée naturelle, cleanup des handles tardifs. |
| packages/map_runtime/test/dialogue_feedback_music_effect_test.dart | Non-régression ME, réservation, mixer et files de feedback audio. |
| packages/map_runtime/test/scene_world_tone_controller_test.dart | Temps, retarget, checkpoint, valeurs neutres et invalidation. |
| packages/map_runtime/test/flame_world_tone_post_process_test.dart | Pixels réels, RGB/gris/alpha et consommation unique du temps. |
| packages/map_runtime/test/narrative_command_runtime_parity_test.dart | Exemples Tone/SE et réparation des trois exemples préexistants manquants ; ports received/moved/completed conservés. |
| apps/avelune_studio/lib/presentation/features/scenes/scene_action_form.dart | Champs numériques, picker SE unique, refus d'une référence devenue ambiguë et conservation du payload avancé. |
| apps/avelune_studio/test/presentation/scene_world_presentation_form_test.dart | Formulaire de production, nombres, média absent/mauvais/loop, perte d'unicité et métadonnées. |
| packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart | Champs number, helper du picker SE filtré par unicité dans le registre entier et validation no-code. |
| packages/map_editor/lib/src/application/services/narrative_template_catalog.dart | Templates Tone/SE et vérification d'une référence unique dans le catalogue entier. |
| packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart | Passage du vrai catalogue média aux formulaires de scène. |
| packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart | Même catalogue média dans le builder des événements. |
| packages/map_editor/test/scene_action_builder_test.dart | Champs/strictness/picker, refus et non-régressions du builder. |
| packages/map_editor/test/narrative_template_catalog_test.dart | Valeurs et références des nouveaux templates, diagnostics et régressions. |
| documentation/reports/converter/AC-13/13_native_events.md | État actuel et complément consolidé ; aucun nouveau Markdown. |

### Contrepreuves et vérifications

Les reçus Q conservent commandes exactes, cwd, logSHA, pins avant/après et identités des descendants. Les trois défauts lifecycle ont été reproduits avant correction : fermeture pendant le startup SE V2, fermeture pendant le hook postcommit du load et fermeture dans une scène de page de carte V1. Le troisième RED passe par la page sceneTarget, le contrôle primaire et l'adapter audio réel avec seulement un driver contrôlé : il observe money=100 au lieu de 0. Le GREEN attend l'inactivité de la scène, l'arrêt du handle tardif et l'égalité du GameState entier. Une panne audio dans une session vivante conserve la branche blocked.

| Reçu | Commande ou portée réelle | Résultat terminal |
|---|---|---|
| world-presentation-lifecycle-red-02 | Deux contre-exemples V2/load avec tests positifs |2 PASS / 2 FAIL, exit1,4.999s|
| world-presentation-lifecycle-green-01 | Mêmes contrôles après les gardes |4 PASS, exit0,4.329s|
| world-presentation-map-event-dispose-red-02 | Page de carte et adapter réel |1 FAIL, exit1,6.205s|
| world-presentation-map-event-dispose-green-01 | Page de carte, deux gardes précédentes et panne vivante |5 PASS, exit0,4.923s|
| world-presentation-core-pinned-final-01 | map_core : dart test sur les sept suites Tone/command/catalogue/parité/référence/dépendance, reporter expanded, concurrency1 |109 PASS, exit0,3.162s ;35pins stables|
| world-presentation-runtime-targeted-05 | map_runtime : flutter test --no-pub sur connection/dispatcher/feedback/ME/Tone/pixels/phase_a_golden_battle_slice_smoke, reporter expanded, concurrency2 |95 PASS, exit0,7.280s|
| world-presentation-runtime-parity-promoted-02 | map_runtime : flutter test --no-pub test/narrative_command_runtime_parity_test.dart --reporter expanded --concurrency=1 |9 PASS, exit0,4.501s ; pin stable|
| world-presentation-runtime-analyze-04 | flutter analyze --no-pub --no-fatal-infos sur neuf chemins runtime |0 erreur,0 warning,4 infos préexistantes, exit0,8.518s|
| native-presentation-core-analyze-final-01 | map_core : dart analyze des dix chemins Core de la tranche |No issues, exit0,1.949s ; dix pins stables|
| native-presentation-parity-analyze-final-01 | flutter analyze --no-pub test/narrative_command_runtime_parity_test.dart |No issues, exit0,8.327s ;35pins stables|
| native-presentation-authoring-final-01 | map_authoring : dart test test/domains/narrative/scene_world_presentation_transport_test.dart --reporter expanded --concurrency=1 |8 PASS, exit0,3.741s ; pins Core/API stables|
| world-presentation-studio-pinned-final-01 | Studio : flutter test --no-pub des trois suites présentation/Warp/formulaire UI06, reporter expanded, concurrency1 |30 PASS, exit0,10.390s ;35pins stables avant le correctif picker|
| presentation-editor-promoted-01 | legacy : flutter test --no-pub test/scene_action_builder_test.dart test/narrative_template_catalog_test.dart --reporter expanded --concurrency=1 |70 PASS, exit0,10.257s ; checkpoint sans pins avant le correctif picker|
| native-presentation-mcp-final-01 | node --test --test-concurrency=1 dist/test/scene_world_presentation_stdio.test.js avec POKEMAP_TEST_DART explicite |1 PASS,0 SKIP, exit0,7.871s ; pins Core/API/MCP stables|
| native-sound-picker-studio-red-01 / legacy-red-01 | Tests --name 'ambiguous sound' avant correction |0 PASS/2 FAIL, exit1,9.595s ;0 PASS/4 FAIL, exit1,9.625s|
| native-sound-picker-studio-green-01 | Trois suites Studio précédentes sur le gel UI6 corrigé |32 PASS,0 SKIP, exit0,9.722s ; six pins stables|
| native-sound-picker-legacy-green-01 | Deux suites builder/template legacy sur le gel UI6 corrigé |74 PASS,0 SKIP, exit0,6.116s ; six pins stables|
| native-sound-picker-analyze-01 | flutter analyze --no-pub des six chemins UI/legacy |No issues, exit0,6.381s ; six pins stables|
| world-presentation-mcp-build-01 / check-01 | tools/pokemap_mcp : npm run build ; npm run check |exit0,1.582s / exit0,1.340s|
| presentation-studio-debug-build-01 | flutter build macos --debug --no-pub -t Q/presentation_player_main.dart avec chemins QA/captures explicites |exit0,42.189s ; checkpoint sans pins, un ibtoold propre réapé|
| native-presentation-studio-build-pinned-final-01 / 02 | Même build,35sources+helper pinés |exit1,12.863s / exit1,8.841s : diagnostic Sparkle conservé ; le second utilisait encore le graphe Xcode en cache|
| native-presentation-xcode-clean-01 | xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Debug -derivedDataPath R/apps/avelune_studio/build/macos clean |exit0,2.588s ;35pins stables ; cache privé uniquement|
| native-presentation-studio-build-pinned-final-03 | Même flutter build macos --debug --no-pub après reconstruction du cache |exit0,45.399s ;35sources+helper stables ; trois ibtoold possédés terminés normalement, zéro survivant|

La parité Runtime était déjà rouge avant promotion :7PASS/2FAIL sur trois exemples manquants giveItemGift/movePlatform/playModelAnimation. Leur réparation concerne les fixtures et leurs callbacks, pas le comportement des trois commandes. Les essais intermédiaires avec mauvais nom de test, imports manquants ou const invalide ne sont pas des contrepreuves fonctionnelles ; leurs reçus sont conservés. Les suites globales voisines déjà rouges, les deux menus Model3D Studio et les erreurs nullable du provider legacy restent hors scope. Aucun résultat ciblé ne devient une certification globale.

La résolution Xcode native-presentation-sparkle-resolve-01 est un échec d'option, exit64/0.404s ; resolve-02 utilise le vrai flag clonedSourcePackagesDirPath, exit0/2.252s, sans changement des fichiers résolus. Le cache référençait un framework absent. restore-01 refuse un dossier INSTALL inattendu avant extraction ; restore-02 extrait sous staging privé, contrôle chemins et liens et restaure uniquement le framework sous build. L'archive officielle Sparkle2.9.5 de11571026octets a le checksum34b9b2071f3de0012eca3faa3a9290bb94e62131e9a74f6dc91514a000097a6c, exact du Package.swift et du workspace-state. Restore-02 exit0/0.401s ; le framework était ensuite bien présent avec son Info.plist, mais Xcode reprenait son ancien graphe de build en erreur. Le clean de ce seul cache privé a levé cette incohérence ; le nouveau build final passe en45.399s. Aucun manifest source, version ou frontière de sécurité modifié. Les warnings Swift/AVFoundation tiers du build ne sont pas effacés.

La contre-revue finale a identifié un quatrième P2 avant commit : les pickers filtraient kind/loop, mais une référence sound partageant son ID avec un music pouvait encore être proposée. Core/API/Runtime la refusent déjà. Six tests nouveaux ont reproduit deux formes d'ambiguïté, sound+music et sound+sound, dans des brouillons réellement construisibles/fromJson. Les pickers comptent maintenant le registre entier avant le filtre kind/nonloop ; une référence devenue ambiguë désactive Apply/Submit et un autre son unique reste utilisable. Le template exige une seule définition avant type/loop. Aucun autre picker n'est refactoré. La contre-revue indépendante ferme ce quatrième P2 ; les checkpoints antérieurs 30/70 ne sont pas présentés comme preuves de cette garde.

### Scénario natif de QA et portée historique

La copie initiale Q/presentation-native-copy-01.json attestait1349fichiers/163764809octets depuis kan03-probe-06/Projet converti. Dix mutations canoniques ont importé le véritable Exit Door.wav par stage_artifact et scene.dialogue.audioMedia.import, puis posé un wait, deux arrivals, deux PNJ, deux scènes et deux événements V2. Aucun cue de dialogue factice ni écriture manuelle de JSON n'a remplacé l'API.

Les deux scènes de QA exécutent SE gain.8 → Tone noir300ms → Wait400ms → Warp none → Tone neutre300ms → End. Elles ont été ajoutées à la main pour qualifier les commandes natives. Elles ne sont pas une conversion de la porte originale. Centre(9,9)→extérieur(14,34)nord, puis retour Centre(9,9)sud.

presentation-native-authoring-run-03 a effectivement appliqué dix mutations et rouvert strictement, puis a échoué sur une assertion de catalogue entièrement inchangé malgré l'ajout audio légitime ; ce run n'est pas PASS. La reprise read-only presentation-native-qualification-run-01, exit0/20.626s, produit presentation-native-authoring-recovered-01.json : structure et références valides, dix mutations revérifiées, médias précédents/Route9/source inchangés au moment de ce contrôle. capabilityCertification=not_requested, capabilityTruth.status=fail avec noPromotedCapabilities et GUIPlayerCertified=false dans ce reçu : il prouve authoring/reopen, pas la certification du projet entier.

Les deux reçus presentation-native-recorded-outward-01.json et inward-01.json enregistrent ensuite le vrai Player, sans téléportation ou avance artificielle du clock : Tone atteint -255 pendant l'action, les arrivals/facing sont exacts et le retour est neutre. Un Timer privé échantillonne pendant l'attente de la touche ; des requêtes MCP envoyées seulement après cette attente avaient manqué la transition. Le programme démarre via l'adapter Flame réel, mais aucune mesure acoustique matérielle ou de queue audio n'est revendiquée.

Le run01 possède son reçu terminal propre, exit0/576.346s, zéro survivant confirmé, protégés inchangés. Le run03 termine en exit143 ; son application76895 est absente, mais son reçu de superviseur final manque. Aucune cause ou garantie de teardown propre n'est inventée. La tentative CUA de capture native échoue ScreenCaptureKit -3811/-10005 ; aucun réglage de permission n'est changé. Les tests widget qualifient les formulaires ; aucun parcours réel d'édition/sauvegarde/reouverture Tone/SE n'est revendiqué à partir de la navigation Histoire interrompue.

**Disponibilité actuelle : native-presentation-after-gui-availability-01.json constate que le projet QA, le projet source publié probe06 et les deux PNG darkCapture sont absents sur disque.** Les reçus de parcours restent disponibles dans Q ; les anciennes captures et vérifications d'intégrité sont des preuves historiques. Le root ne revendique pas une nouvelle comparaison byte-exact de ces dossiers absents, et ne fournit pas ces chemins comme artefacts utilisables. La source Kanto restaurée reste présente ; la prochaine qualification source doit republier un résultat actuel.

### Parité et critique

API directe et JSONL utilisent la même action sémantique ; upsert/graph.patch ne permettent pas de contourner les diagnostics SE de la scène éditée. Le describe live via stdio expose les paramètres, bornes, ports, fin après programmation/démarrage et pitch non supporté. La racine reste étroite. La parité globale PMCP-085/conformance demeure PARTIAL ; les preuves de cette tranche portent sur les commandes de présentation et non sur l'ensemble des actions authoring.

| Passe | Verdict borné |
|---|---|
| Audit / Architecture — root + ac15_connection_review_fresh | Source et cible distinguées ; effets transitoires et dépendances exactes ; porte native de QA explicitement manuelle. |
| Implémentation — root + ac15_connection_review_fresh | Core/API/formulaires/renderer/audio raccordés ; lifecycle corrigé après les RED. |
| Tests — root + agents | Reçus et pins contrôlés ; résultats ciblés, incidents et suites globales distingués. |
| Build / Validation — root | Build historique et Player natif observés ; build final piné PASS après restauration/checksum Sparkle et reconstruction du cache privé. Aucun nouveau Studio lancé. |
| Critique finale — ac13_warp_runtime_tests | Trois P2 lifecycle fermés dans gel04, aucun autre P1/P2 concret sur son delta ; pas de certification universelle du load/mount. |
| Critique finale — ac13_warp_final_review |35blobs host/R et64étrangers exacts ; pins109/30 levés ; P2 d'unicité SE UI fermé après six tests et gel UI6 ; aucun nouveau P1/P2 dans cette contre-revue. Rapport final soumis séparément. |

Auto-critique : la télémétrie de deux scènes manuelles ne qualifie aucune porte automatiquement convertie. La disparition des projets/captures réduit la preuve actuellement consultable ; elle est déclarée. Tone/SE ne couvrent pas la chorégraphie, les déclencheurs, les states d'instance ni la reprise du programme source. Les formulaires legacy complets et le support3D restent non certifiés. FG082/090/093 restent PARTIAL, FG092 TODO, roadmap inchangée. Le goal AC00–16 demeure actif.

Suite fidèle identifiée dans l'audit original : Map100/event8 doit conserver les poses de porte colonne3, les routes209 et toutes copies509, les barrières210, la visibilité208, le pas joueur borné et la condition exacte get_self.onEvent?. TempSwitchA appartient à l'instance Game_Event ; le MapFactory source est sauvegardé, donc il ne faut pas le perdre arbitrairement au chargement. La sortie102/event1 arrive exactement sur la porte(13,25), puis la page d'accueil déplace le joueur(13,26) ; décaler l'arrival supprimerait le programme. La SourceIR suivante conserve l'inactivité de l'événement entier jusqu'à ce que les primitives et les deux sens soient réellement qualifiés.

Git : commit local ciblé autorisé de37chemins, sans push/rebase/amend/branche/worktree. Les64travaux étrangers doivent rester hors index et byte-exacts. Les gels runtime04, promotion01 et UI6 sont réunis dans native-presentation-host-publish-02.json. Les pins35 du build final les relient au code compilé. L'hygiène Markdown, le diffcheck, l'index et les37blobs seront contrôlés avant staging ; le reçu après commit enregistrera SHA/parent/index et64empreintes étrangères conservées. Le ticket AC13 existant reste dans l'unique domaine Post Bêta Monde & narration, TO REVIEW pour les tranches implémentées et PARTIAL pour le résultat global ; DONE réservé à Yoahn, gate bêta inchangée.

## Complément du 14 octobre 2026 — Lecture du programme original de la porte

**AC-13 / KAN-03 : reconnaissance IR complète de cette porte, admission native toujours fermée.** Après le commit natif6a687e4dc93174aa3c536a2e2a1f8753d92b5c7b, le lecteur source reconnaît le programme original Map100/event8 et la sortie Map102/event1. Il conserve leurs routes, pages et références sans les transformer en scènes exécutables. nativeDoorProgramImplemented=false et sourceAdmission=false ; aucun parcours source jouable n'est déclaré.

### Audit, scope et règles source

Base host6a687e4dc, main, index vide. Les quatre fichiers Converter sont qualifiés dans R privé ; leurs baselines host proviennent du commitIR957d244cd et n'ont pas changé pendant le chantier natif. Q/door-ir-host-publish-01.json atteste leur publication et les64empreintes étrangères conservées ; le writer étranger reste exclu. La règle directe sans commentaires demeure prioritaire. Aucun nouveau Markdown, asset Pokémon ou script Ruby exécutable n'est ajouté.

Les bytes archivés du probe05 sont l'input effectivement disponible : le normalized possède exactement l'empreinte de l'input historique06. Les identités source et les locators bruts sont revérifiés, sans lire un dossier publié disparu. Scripts conserve3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d. L'oracle est lu comme texte inerte dans le dossier outputs de l'audit ledgeSource précédent :034.rb:848–875 pour208/209/210 ;033.rb:106–114 pour l'attente des routes joueur/événements/followers ;044.rb:427 pour leurs instructions ;045.rb:26/64/129–130 pour TempSwitch et position ;027.rb:63–66 pour la sauvegarde du MapFactory. Aucune exécution Ruby ni appel IA.

L'audit architectural indépendant confirme qu'aucun contrat natif actuel n'exprime intégralement TempSwitch. NarrativeFactDefinition est global et n'a pas de scope ; NarrativeEventProgress persiste consommation/reset mais son oneShot/onMapReentry ne représente pas un bool arbitraire d'instance modifiable au milieu d'une scène. Une nouvelle activation et une reprise de sauvegarde ne sont pas interchangeables. SceneConditionSourceKind ne porte pas la position exacte du joueur ; playerOnMap ne vérifie que la carte, et triggerEnter n'émet pas un front après spawn/load lorsque previous=null. Ces primitives ne sont pas détournées pour simuler onEvent?.

| Fichier | Zones modifiées et raison |
|---|---|
| packages/avelune_converter_core/lib/src/source_events.dart | Profilv4/oracle033 ; conditions tempSwitch/playerOnEvent, modèles routes/barrière/visibilité/setter ; dispatch208/209/210 ; raw route et toutes copies509 ; lecteurs de littéraux et branche111 stricts. Delta384+/5-. |
| packages/avelune_converter_core/test/source_events_test.dart | Programme synthétique fidèle, routes et flags, copies manquantes/divergentes/surnuméraires, cibles/indent/arity/terminator, visibilité, littéraux exacts, annotations et paramètres bruts ; collections immuables et évaluation inconnue. Delta465+/3-. |
| packages/avelune_converter_adapters/lib/src/source_event_projection.dart | sourceDoorProgramUnsupported et sourceTempSwitchUnsupported avant projection ; récursion des conditions/blocs conservée, aucune création de Fact temporaire. Delta10+/0-. |
| packages/avelune_converter_adapters/test/source_event_projection_test.dart | Six cas empêchent activation partielle, récompense dépendante et page inférieure ; profil/evidencev4. Delta98+/3-. |
| documentation/reports/converter/AC-13/13_native_events.md | État courant et ce complément consolidé ; anciennes preuves conservées et bornées. |

### Contrat de reconnaissance et preuve réelle

SourceForcedMoveRouteNode conserve la cible source0/self,-1/player ou l'ID positif, repeat/skippable, étapes typées, le terminateur0, le profileHash et les références de chaque copie509. Les étapes admises sont celles attestées ici : pas nord/sud, attente, quatre orientations, throughON/OFF et SE. Les autres opcodes restent inconnus. Les flags ne sont pas remplacés par des defaults. La route face-player déjà qualifiée garde ses exigences exactes ; aucun fallback de profil n'est ajouté.

Chaque copie509 doit avoir le bon opcode, index et indent, puis correspondre aux valeurs de son MoveCommand brut ; noms/classes/champs, arités, entiers et références sont contrôlés. La barrière210 décrit toutes les routes forcées, pas la dernière seulement.208 exige0/1 littéraux. Les expressions reconnues sont les formes exactes attestées de tsOffA/onEvent/setTempSwitchOnA ; aucune évaluation Ruby générale. TempSwitchA a lifetime=mapEventInstance, factId absent et saveResumeQualification=notImplemented. evaluate retourne null sans contexte ; aucune page de repli active n'est déduite de ce null.

Profil courant kanto-events-static-v4, hashc120cd79123b1aac91cb686f930818816a799aead10712ea3659949003cd66b8. Le changement de profil impose une recomposition des plans et de leur evidence ; v3 n'est pas un alias accepté.

Q/door-ir-source-proof-05.json, SHA2452a1b396f8814a4dbbc5433b2a51e8fbf5a26dc91842bd4a24a8e9302f7c7c, confirme l'entrée originale en douze nœuds et la page de retour en deux nœuds :

- Map100/event8/page0, trigger1, porte en13,25, OBJ_FRLG_Doors3, sud/pattern3. Ouverture avecfrlg_pcdoor100/100 et waits2ticks ; barrière ; route joueur throughON/nord/throughOFF ; barrière ; joueur invisible ; fermeture et barrière ; Tone noir300ms,Wait400ms,joueur visible,Warp102(9,10)nord sansfade,Tone neutre300ms.
- Page1, trigger3 et TempSwitchOffA : la branche get_self.onEvent? conserve le masquage, l'ouverture, le pas sud et la fermeture. SetterA à l'index26 après la fermeture de branche25, y compris lorsque le prédicat est faux. Les six routes du programme conservent repeat=false/skippable=true.
- Map102/event1 garde ses cinq nœudsSE/Tone/Wait/Warp/Tone. Les deux événements restent quarantinedWholeEvent, nativeEventId=null et adaptedCommands=[].

Snapshotfd1e6e73879d90d3dbedffcd703e5bac5b3b58c9fc8a9186ce1e5d98233dbe4e, normalizatione152056177a5d5cb0ca8c902a62748c88b27f9da00504e85404e7ad06f23d17f et archive8f7ea614cdd7b36bce09df3c62f014305aa7df2857275df8560c3345a945c734 sont inchangés. Le probe lit sept fichiers figés ; il ne publie ni projet ni scène et n'exécute pas le jeu source.

### RED, validation et compilation

Les quatre blobs host/R correspondent au gel Q/door-ir-freeze-01.json, SHAe12fbd686290567528b9acdac6d2e714a0c75c2ec460d19ef300db1aae7e35c4 ; patchba85603cc2c90a1e22871fab91edadff4785f6b9e2f8123aa4774c6803258c30. Les commandes exactes, cwd, logSHA et pins sont dans chaque reçu. Les runs finaux protégés sont stables et n'ont ni signal ni survivant confirmé.

| Reçu | Commande / portée | Résultat terminal |
|---|---|---|
| door-ir-core-red-02 | Core, tests nouveaux avant implémentation |1 PASS/3 FAIL,exit1,3.921s|
| door-ir-adapters-red-02 | Adapter, six gardes avant projection |0 PASS/6 FAIL,exit1,4.447s|
| door-ir-raw-guards-red-01 | Discriminateur brut annoté |1 FAIL,exit1,3.411s|
| door-ir-temp-raw-red-01 | NomSystem22 et paramètres111 annotés |2 FAIL,exit1,3.508s|
| door-ir-core-full-05 | core : dart test test/source_events_test.dart --reporter expanded |140 PASS,exit0,5.293s ; fichier complet ciblé|
| door-ir-adapters-full-05 | adapters : dart test test/source_event_projection_test.dart --reporter expanded |41 PASS,exit0,5.779s ; fichier complet ciblé|
| door-ir-core-analyze-04 | dart analyze lib/src/source_events.dart test/source_events_test.dart |No issues,exit0,1.339s|
| door-ir-adapters-analyze-04 | dart analyze lib/src/source_event_projection.dart test/source_event_projection_test.dart |No issues,exit0,2.233s|
| door-ir-source-probe-run-05 | adapters : dart --packages=.dart_tool/package_config.json Q/door-ir-source-probe-01.dart Q/kan03-probe-05 Q/door-ir-source-proof-05.json |PASS,exit0,15.086s ; pins4+input/helper stables|
| door-ir-package-core-final-01 | core : dart test --reporter expanded --concurrency=1 |936 PASS/1 SKIP,exit0,79.017s ; quatre pins finaux stables|
| door-ir-package-adapters-final-01 | adapters : dart test --reporter expanded --concurrency=1 |782 PASS/91 SKIP,exit0,235.319s ; quatre pins finaux stables|
| door-ir-adapters-qualified-final-01 | adapters : dart test des cinq suites music/pickup/eventStudy/catalogStudy/workflow, reporter expanded, concurrency1 ; AVELUNE_AC13_SOURCE_SCRIPTS pointe le vraiScripts restauré |122 PASS/4 SKIP,exit0,192.002s ; quatre pins+Scripts stables|
| door-ir-cli-build-final-01 | tools/avelune_converter_cli : dart compile exe bin/avelune_converter.dart -o Q/door-ir-converter-cli-final-01 |PASS,exit0,26.864s ; quatre pins stables, AOT privé seulement|
| door-ir-cli-help-final-01 | Binaire AOT privé --help |exit0,0.396s ; binaire piné, aucune conversion de jeu déduite|

Les totaux ne sont pas additionnés : plusieurs suites sont rejouées dans les packages complets. Core ignore le corpus opt-in CONN15. La suite adapters sans variables de source ignore91cas ; les cinq suites Source qualifiées sont donc relancées avec le vrai Scripts, toujours vérifié auSHA3cfd90e8. Quatre cas restent ignorés dans ce run, dont le snapshot Route9 non fourni. Ce n'est pas une couverture de tous les corpus ni une certification de toutes les animations.

REDCore01 comprenait une fixture float invalide, corrigée avant RED02 ; une analyse intermédiaire signalait cinq infos de braces, corrigées avant l'analyse finale. Probe04 est fonctionnel exit0, mais protectedUnchanged=false parce que l'ancienPID310, absent avant, a été réutilisé par powerdatadUID0 pendant le run. Aucun signal ne lui a été envoyé ; ce reçu n'est pas utilisé comme preuve de gardes stables. Probe05 l'est. Aucune application Studio n'est ouverte par cette tranche.

### Parité, critique et suite nécessaire

Ce changement porte le contrat SourceIR du convertisseur et ses diagnostics ; il n'introduit aucune commande authoring native ou action MCP de porte. La compilation CLI et le projector sont vérifiés, et la projection conserve les événements inactifs. Une persistance JSON de l'IR n'est pas revendiquée comme support sémantique natif. Les primitives de la tranche native suivante devront avoir leur propre API, UI, JSONL et MCP qualifiés avant admission.

| Passe | Verdict |
|---|---|
| Audit / Architecture — root + ac15_connection_review_fresh | Programme original, six routes, durée d'instance et arrivée occupée identifiés ; absence des contrats natifs prouvée. |
| Implémentation — ac13_warp_runtime_tests | Quatre fichiers, profilv4 et reconnaissance strictement bornée ; aucune activation source. |
| Tests — agent + root | RED fonctionnels,140/41ciblés,936/782runs packages avec SKIP déclarés,122qualifiés, analyses Noissues. |
| Build / Validation — root | CLI AOT compilée et --help exécuté ; aucun nouveau build/releaseGUI ou parcours Player source revendiqué. |
| Critique finale — ac15_connection_review_fresh | Quatre pins et oracles/logs recomputés ; les deux lecteurs bruts initialement ouverts sont corrigés ; aucun P1/P2 restant sur l'IR. |

Auto-critique : reconnaître douze nœuds ne les exécute pas. La chorégraphie native, la visibilité, le through borné, la condition de position et le state d'instance avec save/reprise restent à implémenter. L'arrivee doit rester13,25 et ne tolérer que la collision propriétaire attestée, avant le pas13,26 ; aucun décalage d'ancre ou bypass global n'est autorisé comme preuve de fidélité. La source est la restauration attestée, pas le Kanto original incomplet rendu autonome. Le goal AC00–16 demeure actif ; AC13/FG082/090/093 PARTIAL,FG092 TODO, roadmap inchangée.

Git : cinq chemins de tranche, local commit autorisé, aucun push/rebase/amend/branche/worktree. Le reçu de précommit vérifie les64empreintes étrangères, index vide, quatre blobs finaux et rapport ; celui d'après commit vérifiera SHA/parent/arbre/index. Le ticket AC13 existant sera actualisé avec ce SHA, TO REVIEW pour le code et PARTIAL global, unique domaine Monde & narration Post Bêta, aucune gate bêta changée.


## Complément du 14 octobre 2026 — Routes natives finies et visibilité visuelle

AC-13 / préparation KAN-03 : tranche native 2D à revoir, domaine PARTIAL. Les commandes actorRoute et actorVisibility sont consommées par le vrai Player 2D. Elles ne sont pas encore proposées dans l’éditeur : editorUnsupported et isPublishable=false restent explicites. Aucune porte source n’est admise et aucun événement Kanto n’est activé par ce commit. Le moteur de combat reste celui d’Avelune.

### Audit, périmètre et contrats

Base main 4bfe476250b264a9537cbf6a8138316cf8ef3e75, index vide, 64 chemins étrangers préexistants en SHA/mode. Les changements ont été préparés dans l’archive privée R de cette base ; aucune branche ou worktree Git n’a été créé. Les bibliothèques étrangères y gardent HEAD. Publication prévue : 30 sources/tests et ce rapport existant, aucun nouveau Markdown, aucun lockfile, asset Pokémon privé ou artefact de build. Les lots FG082/090/093 restent PARTIAL ; FG092 reste TODO dans la roadmap, non modifiée. Cette préparation permet seulement de proposer PARTIAL pour ce dernier après revue.

La route est une séquence finie et bloquante face/hold, move, wait, through et sound. Chaque await conserve le propriétaire et l’activation de carte. Le planner pur conserve les offsets du joueur, les empreintes des personnages et les réservations ; through ne retire que les obstacles de l’invocation, jamais les limites carte. Skippable ne masque que l’obstruction, pas une erreur ou une interruption. Les sons sont référencés explicitement, uniques, non bouclés, avec gain fini0..1 ; le démarrage du son est attendu avant l’étape suivante. Aucun délai de face source implicite n’est inventé.

La visibilité agit uniquement sur le rendu HasVisibility de Flame : elle conserve les collisions, la présence, les interactions et l’animation. Les tests rendent effectivement les pixels. Les cibles entités doivent résoudre un NPC et un Character connus uniques ; une référence directe invalide ne fait pas inventer de fallback trainer. Les cartes spatiales sont refusées. L’index distingue unavailable des définitions dupliquées ambiguous, y compris avant toute écriture via les trois actions Scene.

La revue a trouvé et fermé trois écarts : facing du sprite désynchronisé du monde, rollback MapEvent.sceneTarget après libération anticipée de session, patrouille concurrente pendant face/hold. Les compensations de route restaurent position et facing dans le scope local testé ; la session SceneTarget reste propriétaire jusqu’au commit/rollback. L’horloge et les interpolations avancent pendant la suspension de nouveaux lancements overworld. Les gardes cumulent présence de session et présence physique du monde ; un acteur invisible visuellement reste utilisable, un acteur physiquement absent est refusé.

### Inventaire et zones précises

Les zones ci-dessous sont les hunks complets contre la base, avec leur étendue dans les nouveaux fichiers. Git conserve le diff canonique.

| Chemin | Zones du diff ; delta | Rôle |
|---|---|---|
| `packages/map_authoring/lib/src/domains/narrative/scene_actions.dart` | @@ -57,6 +57,57 @@ ; @@ -83,6 +134,8 @@ ; @@ -123,6 +176,8 @@ ; @@ -875,19 +930,30 @@ ; +79/-13 | Validation canonique de scene.interactive_command.set, upsert et graph.patch. |
| `packages/map_authoring/test/domains/narrative/scene_actor_route_transport_test.dart` | @@ -0,0 +1,782 @@ ; +782/-0 | API directe/JSONL : write/reopen et refus avant mutation. |
| `packages/map_core/lib/map_core.dart` | @@ -1,4 +1,5 @@ ; +1/-0 | Export public du modèle natif. |
| `packages/map_core/lib/src/authoring/scene_command_payload_builder.dart` | @@ -1,6 +1,7 @@ ; @@ -138,6 +139,12 @@ ; @@ -245,6 +252,50 @@ ; +51/-0 | Builder typé route et champs guidables de visibilité. |
| `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` | @@ -3,10 +3,12 @@ ; @@ -52,6 +54,7 @@ ; @@ -466,6 +469,10 @@ ; @@ -671,9 +678,11 @@ ; @@ -1071,9 +1080,11 @@ ; @@ -1083,10 +1094,53 @@ ; @@ -1097,7 +1151,7 @@ ; +58/-4 | Cibles NPC/Character/2D et sons contrôlés avant écriture. |
| `packages/map_core/lib/src/models/narrative_command_descriptor.dart` | @@ -13,6 +13,10 @@ ; +4/-0 | Kinds de paramètres dédiés aux cibles et étapes. |
| `packages/map_core/lib/src/models/scene_actor_route.dart` | @@ -0,0 +1,293 @@ ; +293/-0 | Cibles carte/joueur/PNJ, étapes finies strictes et visibilité typée. |
| `packages/map_core/lib/src/models/scene_interactive_command.dart` | @@ -4,12 +4,15 @@ ; @@ -58,6 +61,17 @@ ; @@ -132,6 +146,10 @@ ; @@ -199,6 +217,119 @@ ; +131/-0 | Deux kinds fermés et intégration JSON/identité. |
| `packages/map_core/lib/src/operations/scene_actor_reference.dart` | @@ -0,0 +1,29 @@ ; +29/-0 | Helper pur partagé : Character direct prioritaire ou trainer unique avec Character unique. |
| `packages/map_core/lib/src/read_models/narrative_command_catalog.dart` | @@ -16,6 +16,8 @@ ; @@ -460,6 +462,73 @@ ; +69/-0 | Descriptions et capacités véritables : runtime2D, editorUnsupported, non publiables. |
| `packages/map_core/lib/src/read_models/narrative_dependency_index.dart` | @@ -16,11 +16,13 @@ ; @@ -2265,31 +2267,92 @@ ; @@ -2609,9 +2672,7 @@ ; @@ -2622,6 +2683,9 @@ ; @@ -2665,6 +2729,9 @@ ; +88/-21 | Références imbriquées, ambiguïtés et unavailable explicite conservé. |
| `packages/map_core/test/narrative_command_catalog_closure_test.dart` | @@ -25,6 +25,8 @@ ; @@ -92,6 +94,9 @@ ; +5/-0 | Bijection kinds/catalogue et représentation des nouveaux descripteurs. |
| `packages/map_core/test/scene_actor_route_authoring_test.dart` | @@ -0,0 +1,766 @@ ; +766/-0 | Diagnostics, dépendances, références invalides et contrôles directs/trainer positifs. |
| `packages/map_core/test/scene_actor_route_test.dart` | @@ -0,0 +1,310 @@ ; +310/-0 | Round-trip, immutabilité, bornes et refus de formes inconnues. |
| `packages/map_gameplay/lib/map_gameplay.dart` | @@ -1,4 +1,7 @@ ; +3/-0 | Exports executor et planner de mouvement. |
| `packages/map_gameplay/lib/src/actor_route_executor.dart` | @@ -0,0 +1,81 @@ ; +81/-0 | Exécution pure séquentielle, through local, obstruction et interruption. |
| `packages/map_gameplay/lib/src/actor_route_motion.dart` | @@ -0,0 +1,233 @@ ; +233/-0 | Planner pur cardinal, hitbox, réservations, eau et limites carte. |
| `packages/map_gameplay/lib/src/gameplay_world_state.dart` | @@ -697,6 +697,26 @@ ; @@ -728,8 +748,12 @@ ; +25/-1 | withEntityFacing et helper de reconstruction des caches partagé avec withEntityPosition. |
| `packages/map_gameplay/test/actor_route_executor_test.dart` | @@ -0,0 +1,305 @@ ; +305/-0 | Ports réellement attendus, skippable limité et erreurs propagées. |
| `packages/map_gameplay/test/actor_route_facing_test.dart` | @@ -0,0 +1,68 @@ ; +68/-0 | Facing authoritative, lecteurs d’entité, caches et partage du stockage statique. |
| `packages/map_gameplay/test/actor_route_motion_test.dart` | @@ -0,0 +1,510 @@ ; +510/-0 | Player/NPC, offsets, empreintes, contacts, bounds et absence de mutation. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_interactive_command_runtime_executor.dart` | @@ -27,6 +27,8 @@ ; @@ -42,6 +44,8 @@ ; @@ -99,6 +103,14 @@ ; +12/-0 | Dispatch dédié actorRoute/actorVisibility, refus sans consumer. |
| `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart` | @@ -6,7 +6,7 @@ ; +1/-1 | HasVisibility : indépendance entre pixels et présence gameplay. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | @@ -94,7 +94,6 @@ ; @@ -709,6 +708,8 @@ ; @@ -874,6 +875,7 @@ ; @@ -2897,6 +2899,21 @@ ; @@ -3935,6 +3952,12 @@ ; @@ -4439,6 +4462,7 @@ ; @@ -4515,7 +4539,10 @@ ; @@ -10345,30 +10372,25 @@ ; @@ -10431,6 +10453,10 @@ ; @@ -10566,6 +10592,15 @@ ; @@ -11162,6 +11197,366 @@ ; +420/-25 | Ports Flame, ownership de route, horloge, mouvement, facing, visibilité, rollback SceneTarget et suspension des patrouilles. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game_support.dart` | @@ -671,6 +671,68 @@ ; +62/-0 | Wait pending et adapter typé des ports vers le Player. |
| `packages/map_runtime/lib/src/presentation/flame/player_component.dart` | @@ -16,7 +16,7 @@ ; +1/-1 | HasVisibility : masque le rendu sans arrêter animation/mouvement. |
| `packages/map_runtime/test/playable_map_game_connection_arrival_collision_test.dart` | @@ -152,6 +152,179 @@ ; @@ -167,6 +340,185 @@ ; @@ -851,6 +1203,12 @@ ; @@ -862,6 +1220,7 @@ ; @@ -971,6 +1330,10 @@ ; @@ -1054,6 +1417,7 @@ ; @@ -1062,11 +1426,16 @@ ; @@ -1081,11 +1450,146 @@ ; +506/-2 | Vrais Game/Scenes/MapEvent : collisions, through, fermeture, son, rollback et patrouille. |
| `packages/map_runtime/test/scene_actor_visibility_render_test.dart` | @@ -0,0 +1,124 @@ ; +124/-0 | Pixels RGBA cachés/restaurés ; motion, feet, hit-test et présence conservés. |
| `packages/map_runtime/test/scene_interactive_command_runtime_executor_test.dart` | @@ -24,6 +24,8 @@ ; @@ -33,6 +35,8 @@ ; @@ -80,6 +84,8 @@ ; +6/-0 | Bijection fermée et consumer obligatoire. |
| `tools/pokemap_mcp/test/scene_actor_route_stdio.test.ts` | @@ -0,0 +1,204 @@ ; +204/-0 | MCP stdio réel : describe, plan/apply, références, refus 3D et réouverture. |
| documentation/reports/converter/AC-13/13_native_events.md | En-tête courant et présent complément | Audit, bornes, inventaire, résultats exacts et critique consolidés. |

### Contrepreuves et vérifications finales

TDD qualifiant : modèle Core4PASS/4FAIL ; executor18FAIL ; planner13PASS/20FAIL ; facing pur6FAIL ; rendu2FAIL ; presence physique1FAIL ; authoring18PASS/13FAIL, API10PASS/2FAIL, stdio0PASS/1FAIL ; SceneTarget/patrol0PASS/3FAIL puis3PASS. Les incidents de fixtures, l’index intermédiaire117PASS/13FAIL, les GREEN Runtime02/03 encore rouges et les premiers essais stdio spatiaux invalides ne sont pas des validations. Les corrections sont reprises par les tests finaux ci-dessous.

Q désigne le dossier QA privé ac16-refresh-20261014-ftgqyeej. Les reçus du gel union actor-route-union-freeze-final-01 conservent commandes/cwd, SHA des logs, pins avant/après et identité des descendants. Les quinze reçus ci-dessous sont terminaux exit0, avec pins encore courants, processus protégés inchangés et aucun survivant confirmé. Les totaux de suites rejouées ne sont pas additionnés.

| Reçu Q ; package | Commande exacte | Résultat |
|---|---|---|
| actor-route-core-model-final-01.json ; packages/map_core | `dart test test/scene_actor_route_test.dart test/scene_interactive_command_test.dart --reporter expanded --concurrency=1` | 25 PASS ; 1.967s ; exit0 |
| actor-route-push-gameplay-green-01.json ; packages/map_gameplay | `dart test test/actor_route_executor_test.dart test/actor_route_motion_test.dart test/actor_route_facing_test.dart test/gameplay_world_state_entity_move_test.dart test/gameplay_world_state_collision_storage_characterization_test.dart test/npc_map_presence_predicate_test.dart test/npc_default_collision_footprint_test.dart --reporter expanded --concurrency 1` | 74 PASS ; 3.451s ; exit0 |
| actor-route-push-gameplay-analyze-01.json ; packages/map_gameplay | `dart analyze lib/src/actor_route_executor.dart lib/src/actor_route_motion.dart lib/src/gameplay_world_state.dart lib/map_gameplay.dart test/actor_route_executor_test.dart test/actor_route_motion_test.dart test/actor_route_facing_test.dart` | 0 error/warning ; 1 info library_name baseline ; 1.941s ; exit0 |
| actor-route-runtime-tests-final-02.json ; packages/map_runtime | `/opt/homebrew/bin/flutter test --no-pub test/playable_map_game_connection_arrival_collision_test.dart test/scene_interactive_command_runtime_executor_test.dart test/scene_actor_visibility_render_test.dart --reporter expanded --concurrency=1` | 62 PASS, 0 SKIP ; 9.467s ; exit0 |
| actor-route-runtime-analyze-final-02.json ; packages/map_runtime | `/opt/homebrew/bin/flutter analyze --no-pub --no-fatal-infos lib/src/presentation/flame/playable_map_game.dart lib/src/presentation/flame/playable_map_game_support.dart lib/src/presentation/flame/player_component.dart lib/src/presentation/flame/overworld_actor_component.dart lib/src/application/scene_runtime/scene_interactive_command_runtime_executor.dart test/playable_map_game_connection_arrival_collision_test.dart test/scene_interactive_command_runtime_executor_test.dart test/scene_actor_visibility_render_test.dart` | 0 error/warning ; 8 infos baseline, --no-fatal-infos ; 8.682s ; exit0 |
| actor-route-runtime-regressions-final-01.json ; packages/map_runtime | `/opt/homebrew/share/flutter-3.47.5/bin/flutter test --no-pub test/player_component_test.dart test/overworld_actor_custom_animation_test.dart test/narrative_command_runtime_parity_test.dart test/phase_a_golden_battle_slice_smoke_test.dart --reporter expanded --concurrency=1` | 23 PASS ; 8.639s ; exit0 |
| actor-route-host-smoke-final-02.json ; examples/playable_runtime_host | `/opt/homebrew/share/flutter-3.47.5/bin/flutter test --no-pub test/phase_a_golden_slice_launch_test.dart --reporter expanded --concurrency=1` | 14 PASS ; 22.751s ; exit0 |
| actor-route-studio-build-final-02.json ; apps/avelune_studio | `/opt/homebrew/share/flutter-3.47.5/bin/flutter build macos --debug --no-pub` | Built Avelune Studio.app macOS debug ; 25.803s ; exit0 |
| actor-route-authoring-01/p2-core-green-final-02.json ; packages/map_core | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/scene_actor_route_authoring_test.dart test/narrative_command_catalog_closure_test.dart test/scene_sound_effect_reference_test.dart test/narrative_dependency_index_test.dart test/scene_diagnostics_test.dart --reporter expanded --concurrency=1` | 131 PASS :32 nouveaux+99 existants ; 2.829s ; exit0 |
| actor-route-authoring-01/p2-api-green-final-01.json ; packages/map_authoring | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/domains/narrative/scene_actor_route_transport_test.dart --reporter expanded --concurrency=1` | 12 PASS ; 4.981s ; exit0 |
| actor-route-authoring-01/p2-core-analyze-final-01.json ; packages/map_core | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib/src/read_models/narrative_command_catalog.dart lib/src/models/narrative_command_descriptor.dart lib/src/authoring/scene_command_payload_builder.dart lib/src/diagnostics/scene_diagnostics.dart lib/src/read_models/narrative_dependency_index.dart lib/src/operations/scene_actor_reference.dart test/narrative_command_catalog_closure_test.dart test/scene_actor_route_authoring_test.dart` | No issues found,8 fichiers ; 1.622s ; exit0 |
| actor-route-authoring-01/p2-api-analyze-final-01.json ; packages/map_authoring | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib/src/domains/narrative/scene_actions.dart test/domains/narrative/scene_actor_route_transport_test.dart` | No issues found,2 fichiers ; 2.537s ; exit0 |
| actor-route-authoring-01/p2-mcp-check-final-01.json ; tools/pokemap_mcp | `npm run check` | tsc check PASS ; 1.347s ; exit0 |
| actor-route-authoring-01/p2-mcp-build-final-01.json ; tools/pokemap_mcp | `npm run build` | tsc build PASS ; 1.347s ; exit0 |
| actor-route-authoring-01/p2-mcp-live-final-01.json ; tools/pokemap_mcp | `node --test --test-concurrency=1 dist/test/scene_actor_route_stdio.test.js` | MCP réel1 PASS/0 SKIP ; 8.258s ; exit0 |

L’exemple host n’avait pas de package_config dans R : le premier essai --no-pub a refusé l’exécution avant tout test. flutter pub get --offline a rétabli les dépendances sans changer manifest/lock, exit0/2.506s ; le deuxième essai est celui des14PASS. Le premier build Studio PASS/46.408s a été remplacé par le build final02 après retrait d’un import devenu inutilisé. Ses deux descendants ibtoold ont été identifiés, terminés avec SIGTERM et n’ont laissé aucun survivant. Le build final02 et les autres reçus finaux n’ont envoyé aucun signal. Aucun nouveau Studio ou Player graphique n’a été lancé.

Les huit informations Runtime sont reliées aux mêmes instructions de HEAD par baseline-analysis-correspondence-02, y compris l’accolade historique et ses lignes exactes. Aucun warning introduit n’est conservé. Le build final piné30, le host piné32 et les régressions pinées30 correspondent aux sources de la publication.

### Parité, revues et limites

L’action sémantique scene.interactive_command.set reste canonique ; upsert et graph.patch ne contournent pas les diagnostics. Les transports directs, JSONL et MCP stdio réel décrivent et exécutent les contrats avec refus avant mutation, puis réouverture. Leurs racines restent étroites. Les formulaires UI guidés actorRoute/visibility ne sont pas livrés ; le support éditeur et la conformité MCP globale demeurent PARTIAL, jamais déduits de persistence JSON.

| Passe / agent | Verdict borné |
|---|---|
| Audit / Architecture — root + agents | Core/gameplay purs et ports Flame ; oracle source conservé sans admission du programme original. |
| Implémentation — ac13_warp_runtime_tests, ac15_connection_review_fresh, root | Contrat7, planner2, facing2, Runtime8 et Authoring11 gelés ; aucune modification étrangère ou de combats. |
| Tests — ac13_warp_final_review + root + ac15 | Refus NPC/Character/3D, index, vrais Game/SceneTarget/patrol, pixels et golden slices prouvés par reçus distincts. |
| Build / Validation — root | Studio macOS debug PASS sur30 pins ; aucune preuve GUI ou acoustique matérielle. |
| Critique finale — indépendante | Authoring11 et Motion2/WorldFacing2 favorables par ac13_warp_runtime_tests ; Runtime8 final favorable sur c804e694…6f93, aucun P1/P2 restant ; Core7 indépendant favorable par ac15, propres fichiers Motion exclus. Limites Source/UI/3D/lifecycle conservées. |

Auto-critique : ces commandes natives ne suffisent pas à convertir la porte originale. La condition de position exacte, la durée de vie/save/reset du TempSwitch de l’instance logique et l’exception d’arrivée limitée au propriétaire restent nécessaires. La compensation locale testée ne qualifie pas une erreur après Warp complet/remontage. Aucun comportement de concurrence générale RMXP209/210, pitch audio ou support3D n’est revendiqué. Les anciens projets QA/captures absents ne sont pas réintroduits comme preuves disponibles. L’IR v4, ses refus sourceDoorProgramUnsupported/sourceTempSwitchUnsupported et les commandes adaptées vides restent inchangés. La suite Source sera admise uniquement après preuve sur les deux événements originaux, aller/retour, save/reload et Studio open/edit/save/reopen.

Git : Yoahn a explicitement autorisé commit et push directement sur main. Les47 commits précédents ont été poussés normalement jusqu’à4bfe47625, confirmé par ls-remote. Cette tranche prépare un commit séparé31 chemins, sans force-push/rebase/amend/branche/worktree. La garde de publication et les reçus après commit/push enregistreront arbre exact, index vide et64 empreintes étrangères préservées. AC13 existant reste dans l’unique domaine Post Bêta Monde & narration ; code proposé TO REVIEW, résultat global PARTIAL, DONE réservé à Yoahn. Le goal AC00–16 reste actif.


## Complément AC-13 — Instances natives et formulaires Actor, publication du 14 octobre 2026

### Résultat et audit initial

Cette tranche prépare les états temporaires locaux nécessaires à la porte originale : condition d’ancre exacte, booléen par instance logique, sauvegarde/rechargement et reset selon la transition, arrivée Warp limitée au propriétaire. ActorRoute/ActorVisibility disposent maintenant de formulaires guidés modernes et de création legacy pour le Player2D. L’admission des deux événements originaux reste fermée ; le profil SourceIR v4 et ses quarantines ne changent pas. AC13 global et goal AC00–16 restent PARTIAL/actifs. Combat Avelune conservé.

Audit initial : les routes et la visibilité existaient dans le moteur, sans guide ; aucun état natif ne représentait le TempSwitch de Game_Event et l’arrivée sur la porte13,25 était refusée. Les caches visuels et MapActivationId ne déterminent pas la durée de vie de cet état. L’oracle source est lu comme données inertes ; aucune exécution Ruby. Les scripts045/043/042/031/027 et les métadonnées compilées attestent setup différent, same-map préservé, viewport16×12 et marge6, save MapFactory. Le saut source et les modes safe/magic restent hors qualification. Les modèles et opérations restent Core/Gameplay purs ; les ports Flame restent Runtime.

### Contrats et comportements

MapInstanceWorldState schéma1 est strict, profondément immuable, avec IDs opaques uniques et booléens par owner natif. La zone est requise lors de la lecture GameState/SaveData ; les anciennes sauvegardes sans zone sont refusées, sans migration ni reader de compatibilité. L’enveloppe reste version1 et ItemV1 inchangé. Les fixtures natives ont été complétées ; le corpus historique et son checksum sont préservés.

La policy de rétention est opt-in : viewport logique et clamps déclarés, distincts de la caméra responsive/cache. Boot crée une instance, Warp same-map la préserve, Warp différent la recrée après validation d’arrivée, connexion conserve/recrée la voisine ; pruning uniquement au repos avec géométrie disponible. Load refuse avant mutation une carte active sans instance ou une référence inconnue. Le writer capture les scopes, refuse les scopes périmés et conserve l’atomicité des récompenses. Une référence invalide ne devient pas false sous NOT. Le solver symbolique reste UNKNOWN pour ce nouveau contrat.

L’arrivée Warp owner-only conserve terrain, eau/Surf, masks, bounds, autres NPC/présence ; elle ne change aucun flag global. Le retour13,25→13,26 original est une route moveDown sans Through. Son exemption de collision initiale demeure à implémenter et prouver avant admission source. Les routes finies restent le sous-ensemble natif déclaré.

Après Warp réellement achevé suivi d’échec de Scene, un snapshot spatial remonte la source avec état logique et pose des acteurs ; les compensations LIFO restaurent position/facing/visibilité et GameState. Les composants recréés sont admis seulement pour la même ref logique ou, sans policy, une activation source capturée non nulle exactement restaurée. Aucun commit narratif imbriqué dans la transaction V2. Le catch interne post-swap préexistant reste hors verdict.

Les guides Actor ciblent joueur/NPC+Character sur carte2D connue ; cinq étapes typées, ordre/ajout/suppression, valeurs validées, sons non loop, références uniques. Les réponses map tardives sont rejetées. Publication moderne prouvée par formulaire→scene.upsert→nouvel adaptateur→cold reopen. Création legacy qualifiée ; LegacyInspector editing, GUI native et3D non qualifiés. Les nouveaux guides de conditions/instance/Warp-owner et leur parité sémantique complète restent PARTIAL.

### Inventaire précis des fichiers

Les73 sources/tests ci-dessous et ce rapport existant constituent la publication. Le patch source final, les blobs et SHA/modes sont dans Q/map-instance-publication-union-final-01 ; Q est externe au dépôt. Aucun asset privé, lockfile, build ou nouveau Markdown ajouté.

| Fichier | Zones modifiées, raison et impact |
|---|---|
| `apps/avelune_studio/lib/presentation/features/events/event_simulation_dialog.dart` | Libellé explicite de la nouvelle raison locale, switch exhaustif Studio. |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_action_form.dart` | Raccord au formulaire Actor guidé moderne et chargement des ressources. |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_actor_action_form.dart` | Pickers typés, cinq étapes, ordre, validation et refus des réponses tardives. |
| `apps/avelune_studio/test/presentation/scene_actor_action_form_test.dart` | Tests ciblés du contrat nommé : cas positifs, refus, conservation et références natives. |
| `apps/avelune_studio/test/scenes/scene_actor_action_publication_test.dart` | Tests ciblés du contrat nommé : cas positifs, refus, conservation et références natives. |
| `examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json` | Fixture native : ajout de la zone vide mapInstanceWorldState, autres données conservées. |
| `examples/playable_runtime_host/p3_narrative_smoke_slice/runtime_host_launch_save.json` | Fixture native : ajout de la zone vide mapInstanceWorldState, autres données conservées. |
| `packages/map_core/lib/map_core.dart` | Export public des modèles et helpers natifs. |
| `packages/map_core/lib/src/authoring/narrative_event_configuration_validation.dart` | Condition, catalogue, diagnostics et index : nouvelles références de carte/owner, cardinalités et refus avant mutation. |
| `packages/map_core/lib/src/authoring/scene_authoring_operations.dart` | Condition, catalogue, diagnostics et index : nouvelles références de carte/owner, cardinalités et refus avant mutation. |
| `packages/map_core/lib/src/authoring/scene_command_payload_builder.dart` | Setter natif fermé et validation de ses références. |
| `packages/map_core/lib/src/catalogs/narrative_event_project_catalog.dart` | Condition, catalogue, diagnostics et index : nouvelles références de carte/owner, cardinalités et refus avant mutation. |
| `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` | Condition, catalogue, diagnostics et index : nouvelles références de carte/owner, cardinalités et refus avant mutation. |
| `packages/map_core/lib/src/models/game_state.dart` | Zone mapInstanceWorldState obligatoire à la lecture JSON. |
| `packages/map_core/lib/src/models/game_state.freezed.dart` | Génération ciblée des champs GameState/SaveData ou ProjectSettings ; stockage typé sans migration. |
| `packages/map_core/lib/src/models/game_state.g.dart` | Génération ciblée des champs GameState/SaveData ou ProjectSettings ; stockage typé sans migration. |
| `packages/map_core/lib/src/models/map_instance_retention_policy.dart` | MapInstanceRetentionPolicy : viewport/marge/clamps typés et stricts. |
| `packages/map_core/lib/src/models/map_instance_world_state.dart` | MapInstanceRef/RuntimeState/WorldState : schéma1 strict, scopes et booléens immuables. |
| `packages/map_core/lib/src/models/narrative_command_descriptor.dart` | ParameterKind.mapEntityReference, distinct des événements et acteurs NPC. |
| `packages/map_core/lib/src/models/narrative_event_definition.dart` | Condition de page native map/event/key/expected. |
| `packages/map_core/lib/src/models/project_manifest.dart` | ProjectSettings.mapInstanceRetentionPolicy nullable opt-in. |
| `packages/map_core/lib/src/models/project_manifest.freezed.dart` | Génération ciblée des champs GameState/SaveData ou ProjectSettings ; stockage typé sans migration. |
| `packages/map_core/lib/src/models/project_manifest.g.dart` | Génération ciblée des champs GameState/SaveData ou ProjectSettings ; stockage typé sans migration. |
| `packages/map_core/lib/src/models/save_data.dart` | Même zone native obligatoire ; enveloppe1 et ItemV1 conservés. |
| `packages/map_core/lib/src/models/save_data.freezed.dart` | Génération ciblée des champs GameState/SaveData ou ProjectSettings ; stockage typé sans migration. |
| `packages/map_core/lib/src/models/save_data.g.dart` | Génération ciblée des champs GameState/SaveData ou ProjectSettings ; stockage typé sans migration. |
| `packages/map_core/lib/src/models/scene_asset.dart` | Conditions playerAtEntityAnchor et mapEventInstanceBoolean. |
| `packages/map_core/lib/src/models/scene_consequence.dart` | Conséquence typée setMapEventInstanceBoolean. |
| `packages/map_core/lib/src/models/scene_interactive_command.dart` | Warp.arrivalCollisionOwnerEntityId : factory, parser fermé, JSON, égalité/hash. |
| `packages/map_core/lib/src/operations/build_narrative_event_project_catalog.dart` | Condition, catalogue, diagnostics et index : nouvelles références de carte/owner, cardinalités et refus avant mutation. |
| `packages/map_core/lib/src/operations/game_state_persistence.dart` | Bridges GameState/SaveData préservent toute la zone et les IDs. |
| `packages/map_core/lib/src/operations/narrative_event_dispatch_authority.dart` | Scope et cardinalité owner, trace spécifique, indisponible propagé sous NOT. |
| `packages/map_core/lib/src/operations/narrative_project_validator.dart` | Condition, catalogue, diagnostics et index : nouvelles références de carte/owner, cardinalités et refus avant mutation. |
| `packages/map_core/lib/src/operations/narrative_symbolic_reachability_solver.dart` | Nouveau booléen/setter restent UNKNOWN dans le solver symbolique. |
| `packages/map_core/lib/src/read_models/narrative_command_catalog.dart` | Setter non publiable ; deux commandes Actor editor/runtime2D publiables avec guides prouvés. |
| `packages/map_core/lib/src/read_models/narrative_dependency_index.dart` | Condition, catalogue, diagnostics et index : nouvelles références de carte/owner, cardinalités et refus avant mutation. |
| `packages/map_core/lib/src/read_models/narrative_event_validation_read_model.dart` | Reason/trace natifs booléen local, champs contextuels optionnels. |
| `packages/map_core/lib/src/read_models/narrative_map_events_read_model.dart` | Condition, catalogue, diagnostics et index : nouvelles références de carte/owner, cardinalités et refus avant mutation. |
| `packages/map_core/test/fixtures/item_system_v1_save.json` | Fixture native : ajout de la zone vide mapInstanceWorldState, autres données conservées. |
| `packages/map_core/test/map_instance_dispatch_authority_test.dart` | Tests ciblés du contrat nommé : cas positifs, refus, conservation et références natives. |
| `packages/map_core/test/map_instance_retention_policy_test.dart` | Tests ciblés du contrat nommé : cas positifs, refus, conservation et références natives. |
| `packages/map_core/test/map_instance_world_state_test.dart` | Tests ciblés du contrat nommé : cas positifs, refus, conservation et références natives. |
| `packages/map_core/test/narrative_event_legacy_corpus_test.dart` | Composition native de GameState ; corpus historique et checksum byte-exacts. |
| `packages/map_core/test/narrative_event_progress_codec_test.dart` | Fixtures JSON positives et null négatives : zone valide explicite, guards initiaux encore vérifiés. |
| `packages/map_core/test/narrative_fact_runtime_state_test.dart` | Fixtures JSON positives et null négatives : zone valide explicite, guards initiaux encore vérifiés. |
| `packages/map_core/test/rail_journey_persistence_test.dart` | Fixtures JSON positives et null négatives : zone valide explicite, guards initiaux encore vérifiés. |
| `packages/map_core/test/scene_actor_route_authoring_test.dart` | Tests ciblés du contrat nommé : cas positifs, refus, conservation et références natives. |
| `packages/map_core/test/scene_map_instance_contract_test.dart` | Tests ciblés du contrat nommé : cas positifs, refus, conservation et références natives. |
| `packages/map_core/test/scene_map_instance_references_test.dart` | Tests ciblés du contrat nommé : cas positifs, refus, conservation et références natives. |
| `packages/map_core/test/scene_warp_owner_arrival_test.dart` | Tests ciblés du contrat nommé : cas positifs, refus, conservation et références natives. |
| `packages/map_core/test/trainer_battle_receipt_persistence_test.dart` | Fixtures JSON positives et null négatives : zone valide explicite, guards initiaux encore vérifiés. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_simulation_sheet.dart` | Même raison de simulation exhaustive côté éditeur legacy. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | Même propagation vers la création d’action dans le canvas. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart` | Raccord au formulaire Actor legacy. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_actor_action_builder.dart` | Guide legacy typé avec mêmes contrôles de références et valeurs. |
| `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` | Propagation des loaders map/ressources dans la création de scène. |
| `packages/map_editor/test/scene_actor_action_builder_test.dart` | Tests ciblés du contrat nommé : cas positifs, refus, conservation et références natives. |
| `packages/map_gameplay/lib/map_gameplay.dart` | Export public des trois helpers purs ; aucun Flutter/Flame. |
| `packages/map_gameplay/lib/src/map_instance_lifecycle.dart` | Setup différent/same-map/retain/prune selon géométrie et viewport logique. |
| `packages/map_gameplay/lib/src/scene_map_instance_condition_evaluator.dart` | Position exacte et booléen local ; erreur de scope/ref distincte de false. |
| `packages/map_gameplay/lib/src/scene_warp_arrival.dart` | Arrivée 2D : exemption du seul NPC/Character propriétaire à son ancre exacte. |
| `packages/map_gameplay/test/map_instance_lifecycle_test.dart` | Tests ciblés du contrat nommé : cas positifs, refus, conservation et références natives. |
| `packages/map_gameplay/test/scene_map_instance_condition_evaluator_test.dart` | Tests ciblés du contrat nommé : cas positifs, refus, conservation et références natives. |
| `packages/map_gameplay/test/scene_warp_arrival_test.dart` | Tests ciblés du contrat nommé : cas positifs, refus, conservation et références natives. |
| `packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart` | Même projection dans NarrativeV2. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart` | missingMapInstanceScope/staleMapInstanceScope. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart` | Scopes capturés, setter strict, applyAll atomique sans récompense partielle. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart` | Projection des conséquences locales en attente pour la condition suivante. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Boot/load/connection/Warp/rétention ; callbacks conditions ; compensation spatial/Actor après remount. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game_support.dart` | RuntimeSpatialSnapshot partagé par load et rollback Scene. |
| `packages/map_runtime/test/narrative_command_runtime_parity_test.dart` | Deux callbacks et samples Actor publiables ; aucune logique de combat modifiée. |
| `packages/map_runtime/test/playable_map_game_connection_arrival_collision_test.dart` | Vrai Game : arrivée propriétaire, scopes/reset, load/save, conditions, rollback après Warp et gardes sans policy. |
| `packages/map_runtime/test/scene_map_instance_consequence_writer_test.dart` | Tests ciblés du contrat nommé : cas positifs, refus, conservation et références natives. |

### Vérifications exactes

Q désigne QA/ac16-refresh-20261014-ftgqyeej. Chaque reçu contient commande/cwd, SHA log, pins avant/après et ownership des processus. Les suites rejouées ne sont pas additionnées. Les commandes ci-dessous sont terminales exit0 ; sources gelées, protégés inchangés et aucun survivant confirmé. Les73 pins du build final correspondent aux sources de publication.

| Reçu Q ; cwd relatif à R | Commande exacte | Résultat ; durée |
|---|---|---|
| `map-instance-core-union-final-01.json` ; `packages/map_core` | `/opt/homebrew/bin/dart test test/map_instance_world_state_test.dart test/scene_map_instance_contract_test.dart test/map_instance_dispatch_authority_test.dart test/scene_map_instance_references_test.dart test/narrative_event_dispatch_authority_test.dart test/narrative_event_configuration_authoring_test.dart test/narrative_dependency_index_test.dart test/narrative_symbolic_reachability_solver_test.dart test/scene_authoring_operations_test.dart test/scene_diagnostics_test.dart test/game_state_persistence_test.dart test/save/game_state_save_envelope_mapper_test.dart test/save/save_envelope_codec_test.dart test/map_instance_retention_policy_test.dart test/scene_warp_owner_arrival_test.dart test/scene_interactive_command_test.dart test/bag_stack_identity_test.dart test/narrative_event_legacy_corpus_test.dart test/narrative_fact_runtime_state_test.dart test/narrative_event_progress_codec_test.dart test/rail_journey_persistence_test.dart test/trainer_battle_receipt_persistence_test.dart --reporter expanded` | 384 PASS,22 suites ; 4.835s ; exit0 |
| `map-instance-gameplay-union-final-01.json` ; `packages/map_gameplay` | `dart test test/scene_map_instance_condition_evaluator_test.dart test/map_instance_lifecycle_test.dart test/scene_warp_arrival_test.dart test/actor_route_motion_test.dart test/npc_map_presence_predicate_test.dart --reporter expanded --concurrency=1` | 99 PASS ; 3.798s ; exit0 |
| `map-instance-api-union-final-01.json` ; `packages/map_authoring` | `dart test test/domains/narrative/scene_actor_route_transport_test.dart --reporter expanded --concurrency=1` | 12 PASS,API et JSONL ; 6.627s ; exit0 |
| `map-instance-runtime-union-final-01.json` ; `packages/map_runtime` | `flutter test --no-pub test/scene_map_instance_consequence_writer_test.dart test/playable_map_game_connection_arrival_collision_test.dart test/scene_interactive_command_runtime_executor_test.dart test/scene_actor_visibility_render_test.dart test/narrative_command_runtime_parity_test.dart test/phase_a_golden_battle_slice_smoke_test.dart --reporter expanded --concurrency=1` | 99 PASS,6 suites,0 SKIP ; 15.101s ; exit0 |
| `map-instance-host-union-final-01.json` ; `examples/playable_runtime_host` | `flutter test --no-pub test/phase_a_golden_slice_launch_test.dart test/p3_narrative_smoke_slice_test.dart --reporter expanded --concurrency=1` | 15 PASS,GoldenBattle et P3 ; 9.742s ; exit0 |
| `map-instance-core-analyze-union-final-01.json` ; `packages/map_core` | `/opt/homebrew/bin/dart analyze lib/map_core.dart lib/src/models/map_instance_world_state.dart lib/src/models/scene_asset.dart lib/src/models/scene_consequence.dart lib/src/models/narrative_event_definition.dart lib/src/operations/narrative_event_dispatch_authority.dart lib/src/read_models/narrative_event_validation_read_model.dart lib/src/models/game_state.dart lib/src/models/game_state.freezed.dart lib/src/models/game_state.g.dart lib/src/models/save_data.dart lib/src/models/save_data.freezed.dart lib/src/models/save_data.g.dart lib/src/operations/game_state_persistence.dart lib/src/operations/build_narrative_event_project_catalog.dart lib/src/catalogs/narrative_event_project_catalog.dart lib/src/authoring/narrative_event_configuration_validation.dart lib/src/read_models/narrative_map_events_read_model.dart lib/src/operations/narrative_project_validator.dart lib/src/operations/narrative_symbolic_reachability_solver.dart lib/src/diagnostics/scene_diagnostics.dart lib/src/authoring/scene_authoring_operations.dart lib/src/read_models/narrative_dependency_index.dart lib/src/read_models/narrative_command_catalog.dart lib/src/models/narrative_command_descriptor.dart lib/src/authoring/scene_command_payload_builder.dart test/map_instance_world_state_test.dart test/scene_map_instance_contract_test.dart test/map_instance_dispatch_authority_test.dart test/scene_map_instance_references_test.dart lib/src/models/scene_interactive_command.dart test/scene_warp_owner_arrival_test.dart test/narrative_event_legacy_corpus_test.dart test/narrative_fact_runtime_state_test.dart test/narrative_event_progress_codec_test.dart test/rail_journey_persistence_test.dart test/trainer_battle_receipt_persistence_test.dart lib/src/models/map_instance_retention_policy.dart lib/src/models/project_manifest.dart test/map_instance_retention_policy_test.dart` | 0 error/warning,18 infos baseline ; 1.649s ; exit0 |
| `map-instance-gameplay-analyze-union-final-02.json` ; `packages/map_gameplay` | `dart analyze lib/map_gameplay.dart lib/src/map_instance_lifecycle.dart lib/src/scene_warp_arrival.dart lib/src/scene_map_instance_condition_evaluator.dart test/map_instance_lifecycle_test.dart test/scene_warp_arrival_test.dart test/scene_map_instance_condition_evaluator_test.dart` | 0 error/warning,1 info baseline ; 1.707s ; exit0 |
| `map-instance-runtime-analyze-union-final-01.json` ; `packages/map_runtime` | `flutter analyze --no-pub --no-fatal-infos lib/src/presentation/flame/playable_map_game.dart lib/src/application/narrative_scene_runtime_execution.dart lib/src/application/scene_runtime/scene_event_runtime_hook.dart lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart test/scene_map_instance_consequence_writer_test.dart test/playable_map_game_connection_arrival_collision_test.dart lib/src/presentation/flame/playable_map_game_support.dart test/narrative_command_runtime_parity_test.dart` | 0 error/warning,6 infos baseline ; 7.876s ; exit0 |
| `map-instance-simulation-studio-final-01.json` ; `apps/avelune_studio` | `flutter test --no-pub test/events_ui08_conditions_simulation_test.dart --reporter expanded --concurrency=1` | 5 PASS ; 8.119s ; exit0 |
| `map-instance-simulation-editor-final-01.json` ; `packages/map_editor` | `flutter test --no-pub test/event_builder_v2_simulation_test.dart --reporter expanded --concurrency=1` | 1 PASS ; 4.412s ; exit0 |
| `map-instance-simulation-analyze-final-01.json` ; `apps/avelune_studio` | `flutter analyze --no-pub lib/presentation/features/events/event_simulation_dialog.dart ../../packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_simulation_sheet.dart` | No issues found,2 fichiers ; 6.294s ; exit0 |
| `map-instance-arrival-test-cleanup-final-01.json` ; `packages/map_gameplay` | `dart test test/scene_warp_arrival_test.dart --reporter expanded` | 17 PASS ; 1.663s ; exit0 |
| `map-instance-arrival-test-analyze-final-01.json` ; `packages/map_gameplay` | `dart analyze test/scene_warp_arrival_test.dart` | No issues found ; 1.699s ; exit0 |
| `map-instance-studio-build-union-final-02.json` ; `apps/avelune_studio` | `flutter build macos --debug --no-pub` | Built Avelune Studio.app macOS debug ; 22.466s ; exit0 |
| `map-instance-mcp-check-final-01.json` ; `tools/pokemap_mcp` | `npm run check` | tsc check PASS ; 1.022s ; exit0 |
| `map-instance-mcp-build-final-01.json` ; `tools/pokemap_mcp` | `npm run build` | tsc build PASS ; 1.021s ; exit0 |
| `map-instance-mcp-live-final-01.json` ; `tools/pokemap_mcp` | `node --test --test-concurrency=1 dist/test/scene_actor_route_stdio.test.js` | MCP réel1 PASS,0 SKIP ; 8.594s ; exit0 |

UI11 gelé : Studio20 PASS22.646s (dont2 publication/cold reopen), Legacy18 PASS11.307s, Core32 PASS2.146s. Régressions Studio29 PASS13.463s et Legacy43 dans61PASS18.316s avant le delta uniquement accolades ; ce delta de5 paires dans2 fichiers est relu indépendamment et requalifié. Analyses Studio4/Legacy5/Core2 No issues5.693/12.435/1.647s. Les commandes exactes et logs se trouvent dans actor-ui-01/qualification-final-01.json et ses reçus.

Contrepreuves : contrats/refs/scopes rouges fonctionnels avant implémentation ; Core élargi379PASS/5FAIL avant ajout de la zone aux4 fixtures, puis384PASS ; rollback après Warp0PASS/2FAIL, puis3PASS, enfin cas sans policy1PASS/1FAIL puis5PASS avec vrai déplacement source et arrival observés. Le premier union Runtime91PASS/5FAIL révélait les2 samples Actor manquants et3 échecs sur la même save GoldenBattle ; corrigés puis99PASS. Le build final01 échouait sur le nouveau reason non exhaustif : les deux consommateurs Studio/legacy sont corrigés, tests5+1PASS et build final02 PASS. Les erreurs de fixture/filter/compilation intermédiaires ne sont pas des validations.

Les18 informations Core,1 Gameplay et6 Runtime correspondent à des instructions baseline conservées ; aucune erreur/warning restante dans ces analyses ciblées. Les2 infos nouvelles du test Arrival ont été retirées,17PASS et analyse sans issue. La réduction du churn de formatage conserve10/10 séquences lexèmes/commentaires, attestées par scanner Dart ;8 finals correspondent aux candidats02, les2 petits tests sont reconstruits baseline+seules additions nécessaires. Tous les tests terminés n’ont laissé aucun harness. Le build échoué avait2 descendants prouvés, terminés normalement ; le build final n’a envoyé aucun signal. Aucune nouvelle fenêtre de test ouverte.

### Revues, parité et limites

| Passe | Verdict borné |
|---|---|
| Audit / Architecture — root, ac15_connection_review_fresh | Oracle source, policy et géométrie attestés ; egress original explicitement ouvert. |
| Implémentation — root + ac13_warp_runtime_tests + ac15_connection_review_fresh + ac13_warp_final_review | Core33/policy7/UI11 gelés, Runtime/fixtures raccordés ; frontières conservées. |
| Tests — root et agents | Contrats/refus, save/reset, load avant mutation, vrais Game/Scene rollback, UI/API/JSONL/MCP par reçus distincts. |
| Build / Validation — root | Studio macOS debug final02 PASS ; pas de qualification GUI de projet original. |
| Critique finale — indépendante | Core/UI favorables ; P2 non-policy fermé par RED/GREEN réel ; aucun P1/P2 restant dans Root Runtime relu. Restauration de whitespace et gels relus, nouveau reason raccordé dans2 consommateurs. |

L’action scene.interactive_command.set reste canonique, avec refus par set/upsert/graph.patch, direct/JSONL/MCP puis réouverture. Le catalogue live et le build MCP sont vérifiés pour Actor ; le setter d’instance reste non publiable dans le catalogue tant que ses guides/parités manquent. Générique persistence JSON ne vaut pas exposition sémantique. FG082/090/093 restent PARTIAL ; FG092 TODO, roadmap inchangée.

Auto-critique : il s’agit de support natif vérifié, pas d’une qualification du programme original Map100/102. Egress owner-only, guides Warp/conditions/local setter, policy effectivement écrite par le convertisseur et nouvelle admission source sont encore nécessaires. Aller/retour original, save/reload et Studio open/edit/save/reopen restent à prouver sur le projet converti disponible. Aucun timing acoustique matériel, GUI,3D, safe/magic-save ou concurrence RMXP209/210 générale revendiqué.

### État Git et suivi

Autorisation directe de Yoahn : commit et push sur main. Initial : main `be9b1de9fc71545d44545a919a7db657be6c3957`, index vide, 35 chemins étrangers non stagés, empreintes SHA/modes enregistrées juste avant transfert. La tranche est préparée en archive privée depuis le main commité be9 et exclut les modifications étrangères ; aucun Git write n’est fait par les agents. Publication normale en un commit74 chemins, sans force-push/rebase/amend/branche/worktree. Le reçu de publication enregistre SHA exact, blobs, parent, index et empreintes après commit/push ; le SHA final est projeté dans le ticket Notion et la réponse finale. Le scope livré doit être propre même si les autres travaux restent dirty.

AC13 existant demeure dans l’unique domaine Post Bêta Monde & narration, Gate bêta false. Tranche proposée TO REVIEW avec verdict global PARTIAL ; DONE réservé à Yoahn. Goal AC00–16 actif. Markdown hygiene et diffcheck exécutés avant publication ; leurs sorties exactes sont conservées dans les reçus.


## Complément AC-13 — Sortie de contact initiale bornée, 14 octobre 2026

### Résultat, audit initial et frontières

Cette tranche ajoute `SceneActorMoveStep.initialCollisionOwnerEntityId` : une instruction de déplacement du joueur peut quitter le contact initial d'un PNJ déclaré sans activer Through. Le permis est local à cette instruction et à la paire carte/entité. Les collisions terrain, eau, limites, masques, autres occupants et réservations anonymes restent actives. Core/Gameplay demeurent purs ; la consommation physique est dans le Player2D, les formulaires utilisent les contrats canoniques. SourceIR v4, les quarantines et la projection des portes originales restent inchangés : `sourceAdmission=false`. Combat Avelune conservé. Aucune qualification de jeu entier ni de GUI originale n'est déduite des tests natifs.

Base fraîche `97c08700e723324fe0fb253e8921f5a6128d12e5`, branche main, index vide. Audit privé initial : 9289 fichiers suivis comparés, aucune dérive réelle ; 22 exclusions connues (deux écarts QA précédents et vingt pyc historiquement suivis absents de l'archive), hors livraison. Les travaux étrangers du host sont exclus. Le writer Converter, les bordures/spatial/mobile, les générateurs et les assets ne sont pas modifiés. La règle directe sans commentaires prévaut sur codex_rule §3. La clôture actualise ce rapport unique, sans nouveau Markdown.

Le risque principal était de transformer l'owner en exception générale aux collisions. L'authoring impose Player2D, carte et owner uniques et connus, NPC+Character réel, contact canonique 1×1 à l'ancre de l'entité, Through effectif false selon le préfixe de route. Le déplacement part du contact réel et finit hors de celui-ci, sans snap. Une sélection incompatible est conservée dans le brouillon et bloque Apply. La réservation du seul owner est filtrée par identité avant agrégation ; les autres réservations restent des obstacles. Pendant l'attente, le runtime revérifie propriétaire présent/stationnaire, position, contact, instance et activation. Une interruption restaure l'interpolation sur la position non commise et libère les verrous.

### Inventaire des 24 sources/tests et zones précises

| Fichier | Zones du diff contre 97c08700e | Raison et impact |
| --- | --- | --- |
| `packages/map_core/lib/src/models/scene_actor_route.dart` | @@ -67,0 +68 @@ ; @@ -94 +95,5 @@ ; @@ -97,0 +103,4 @@ ; @@ -150,2 +159,8 @@ ; @@ -153,0 +169 @@ ; @@ -160,0 +177,2 @@ ; @@ -166,3 +184,5 @@ ; @@ -253,0 +274,20 @@ | Champ optionnel strict, JSON omis si absent, égalité/hash et refus des valeurs invalides. |
| `packages/map_core/lib/src/models/scene_interactive_command.dart` | @@ -230 +230,14 @@ ; @@ -244,10 +257,14 @@ | Références owner liées au Player et au Through cumulatif ; aucune autre commande modifiée. |
| `packages/map_core/lib/src/operations/scene_actor_reference.dart` | @@ -3,0 +4,12 @@ | Helper partagé NPC/Character et contact1×1 à la même ancre ; ferme le P2 contact décalé. |
| `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` | @@ -8,0 +9 @@ ; @@ -59,0 +61 @@ ; @@ -1149,0 +1152,29 @@ | Diagnostic owner incompatible avant publication. |
| `packages/map_core/lib/src/read_models/narrative_dependency_index.dart` | @@ -6,0 +7 @@ ; @@ -2337,0 +2339,24 @@ ; @@ -2352,0 +2378,8 @@ | Dépendance owner qualifiée par carte et référence manquante. |
| `packages/map_core/lib/src/read_models/narrative_command_catalog.dart` | @@ -492 +492 @@ | Description seulement ; Actor ordinaire supported2D inchangé. |
| `packages/map_core/test/scene_actor_route_test.dart` | @@ -22,0 +23,193 @@ | Tests positifs, négatifs, transports ou publication/relecture, avec régressions conservées. |
| `packages/map_core/test/scene_actor_route_authoring_test.dart` | @@ -32,0 +33,13 @@ ; @@ -143,0 +157,396 @@ | Tests positifs, négatifs, transports ou publication/relecture, avec régressions conservées. |
| `packages/map_authoring/lib/src/domains/narrative/scene_actions.dart` | @@ -78 +78 @@ ; @@ -81,0 +82,18 @@ ; @@ -120 +138,4 @@ | Metadata du sous-contrat partial et guards canoniques, set/upsert/graph.patch. |
| `packages/map_authoring/test/domains/narrative/scene_actor_route_transport_test.dart` | @@ -58,0 +59 @@ ; @@ -65 +66,7 @@ ; @@ -105,0 +113,49 @@ ; @@ -138,0 +195,139 @@ ; @@ -777,0 +973,15 @@ | Tests positifs, négatifs, transports ou publication/relecture, avec régressions conservées. |
| `tools/pokemap_mcp/test/scene_actor_route_stdio.test.ts` | @@ -46 +46 @@ ; @@ -49 +49 @@ ; @@ -101,0 +102,6 @@ ; @@ -117 +123 @@ ; @@ -133,0 +140,18 @@ ; @@ -137 +161 @@ ; @@ -141,0 +166,4 @@ ; @@ -143 +171 @@ ; @@ -145 +173 @@ ; @@ -151,3 +179,6 @@ ; @@ -174,0 +206,13 @@ ; @@ -183,2 +227,3 @@ ; @@ -197,0 +243 @@ | Tests positifs, négatifs, transports ou publication/relecture, avec régressions conservées. |
| `packages/map_gameplay/lib/src/actor_route_motion.dart` | @@ -32,0 +33,2 @@ ; @@ -123,0 +126,48 @@ ; @@ -141,0 +192,7 @@ ; @@ -233,0 +291,8 @@ | Plan pur borné au contact initial, conservant obstacles et réservations. |
| `packages/map_gameplay/test/actor_route_initial_owner_egress_test.dart` | créé, 438 lignes | Tests positifs, négatifs, transports ou publication/relecture, avec régressions conservées. |
| `packages/map_gameplay/lib/src/actor_route_executor.dart` | @@ -12 +12,3 @@ ; @@ -44,0 +47 @@ | Port et forwarding de l’owner uniquement sur son étape. |
| `packages/map_gameplay/test/actor_route_executor_test.dart` | @@ -13,0 +14 @@ ; @@ -41 +42,3 @@ ; @@ -42,0 +46 @@ ; @@ -72,0 +77,29 @@ | Tests positifs, négatifs, transports ou publication/relecture, avec régressions conservées. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | @@ -11498 +11498,2 @@ ; @@ -11501,0 +11503,30 @@ ; @@ -11503,29 +11534,27 @@ ; @@ -11533,32 +11562,16 @@ ; @@ -11566 +11579 @@ ; @@ -11568,0 +11582,24 @@ ; @@ -11569,0 +11607,7 @@ ; @@ -11571 +11614,0 @@ | Lease live owner, filtrage de réservation par identité, revalidation et rollback de l’interpolation. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game_support.dart` | @@ -703,0 +704 @@ ; @@ -722 +723,3 @@ | Transmission de l’owner du port Scene au vrai mouvement Player. |
| `packages/map_runtime/test/playable_map_game_connection_arrival_collision_test.dart` | @@ -13,0 +14 @@ ; @@ -1456,0 +1458,173 @@ | Tests positifs, négatifs, transports ou publication/relecture, avec régressions conservées. |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_actor_action_form.dart` | @@ -83 +83,3 @@ ; @@ -123,0 +126,113 @@ ; @@ -192,0 +308 @@ ; @@ -226 +342 @@ ; @@ -435,0 +552,5 @@ ; @@ -480,0 +602 @@ ; @@ -483 +605,5 @@ ; @@ -491,0 +618,5 @@ | Picker Personnage à quitter/Aucun, guards et choix qualifié par carte. |
| `apps/avelune_studio/test/presentation/scene_actor_action_form_test.dart` | @@ -193,0 +194,20 @@ ; @@ -194,0 +215,411 @@ | Tests positifs, négatifs, transports ou publication/relecture, avec régressions conservées. |
| `apps/avelune_studio/test/scenes/scene_actor_action_publication_test.dart` | @@ -235 +235,3 @@ ; @@ -237 +239 @@ ; @@ -245,4 +247,3 @@ ; @@ -260,0 +262 @@ ; @@ -287,0 +290,12 @@ | Tests positifs, négatifs, transports ou publication/relecture, avec régressions conservées. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_actor_action_builder.dart` | @@ -79 +79,3 @@ ; @@ -119,0 +122,113 @@ ; @@ -188,0 +304 @@ ; @@ -222 +338 @@ ; @@ -483,0 +600,5 @@ ; @@ -531,0 +653 @@ ; @@ -534 +656,5 @@ ; @@ -542,0 +669,5 @@ | Même guide de création legacy et refus Apply ; Inspector legacy existant non qualifié. |
| `packages/map_editor/test/scene_actor_action_builder_test.dart` | @@ -194,0 +195,20 @@ ; @@ -195,0 +216,411 @@ | Tests positifs, négatifs, transports ou publication/relecture, avec régressions conservées. |
| `packages/map_core/test/narrative_command_catalog_closure_test.dart` | @@ -13,0 +14 @@ | Répare le set attendu omettant setMapEventInstanceBoolean introduit au commit précédent ; pas de promotion de ce setter. |

Le 25e chemin est ce rapport existant : seul ce complément est ajouté. Les gels Root5, Core12, Pure2 et UI5, leurs patches et qualifications sont sous Q=`/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac13-door-egress-20261014-ar2mp1gx`. R=`/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac16-refresh-20261014-ftgqyeej/repository`. Les hashes finaux des 25 blobs et les baselines sont dans `publication-final-01/manifest-before-copy-01.json`.

### Commandes exactes et résultats finaux

Chaque ligne correspond à un reçu/log SHA contrôlé et aux sources réellement consommées. Aucun rerun précédent n'est additionné aux compteurs finaux.

| Reçu dans Q ; cwd relatif à R | Commande exacte | Résultat |
| --- | --- | --- |
| `actor-route-owner-core-final-03.json` ; `packages/map_core` | `/opt/homebrew/bin/dart test test/scene_actor_route_test.dart test/scene_actor_route_authoring_test.dart test/scene_diagnostics_test.dart test/narrative_dependency_index_test.dart test/narrative_command_catalog_test.dart test/narrative_command_catalog_closure_test.dart test/scene_warp_owner_arrival_test.dart --reporter expanded` | 164 PASS ; 2.746s ; exit0 |
| `actor-route-owner-api-final-02.json` ; `packages/map_authoring` | `/opt/homebrew/bin/dart test test/domains/narrative/scene_actor_route_transport_test.dart --reporter expanded` | 28 PASS, API directe et JSONL ; 6.142s ; exit0 |
| `actor-route-owner-mcp-final-04.json` ; `tools/pokemap_mcp` | `node --import tsx --test --test-concurrency=1 test/scene_actor_route_stdio.test.ts` | 1 PASS, 0 SKIP, MCP réel et cold reopen ; 10.461s ; exit0 |
| `actor-route-egress-green-02.json` ; `packages/map_gameplay` | `/opt/homebrew/bin/dart test test/actor_route_initial_owner_egress_test.dart test/actor_route_motion_test.dart --reporter expanded --concurrency=1` | 76 PASS, 43 nouveaux et 33 régressions ; 3.544s ; exit0 |
| `root-executor-final-02.json` ; `packages/map_gameplay` | `dart test test/actor_route_executor_test.dart --reporter expanded --concurrency=1` | 19 PASS ; 1.721s ; exit0 |
| `root-runtime-union-final-02.json` ; `packages/map_runtime` | `flutter test --no-pub test/scene_map_instance_consequence_writer_test.dart test/playable_map_game_connection_arrival_collision_test.dart test/scene_interactive_command_runtime_executor_test.dart test/scene_actor_visibility_render_test.dart test/narrative_command_runtime_parity_test.dart test/phase_a_golden_battle_slice_smoke_test.dart --reporter expanded --concurrency=1` | 106 PASS, 6 suites ; 16.114s ; exit0 |
| `root-host-final-01.json` ; `examples/playable_runtime_host` | `flutter test --no-pub test/phase_a_golden_slice_launch_test.dart test/p3_narrative_smoke_slice_test.dart --reporter expanded --concurrency=1` | 15 PASS, GoldenBattle et P3 ; 51.876s ; exit0 |
| `actor-egress-ui-studio-green-final-01.json` ; `apps/avelune_studio` | `/opt/homebrew/share/flutter-3.47.5/bin/flutter test test/presentation/scene_actor_action_form_test.dart test/scenes/scene_actor_action_publication_test.dart --reporter expanded --concurrency=1` | 32 PASS, formulaire et publication/relecture froide ; 23.462s ; exit0 |
| `actor-egress-ui-legacy-green-final-01.json` ; `packages/map_editor` | `/opt/homebrew/share/flutter-3.47.5/bin/flutter test test/scene_actor_action_builder_test.dart --reporter expanded --concurrency=1` | 29 PASS ; 14.357s ; exit0 |
| `actor-route-owner-core-analyze-final-02.json` ; `packages/map_core` | `/opt/homebrew/bin/dart analyze lib/src/models/scene_actor_route.dart lib/src/models/scene_interactive_command.dart lib/src/operations/scene_actor_reference.dart lib/src/diagnostics/scene_diagnostics.dart lib/src/read_models/narrative_dependency_index.dart lib/src/read_models/narrative_command_catalog.dart test/scene_actor_route_test.dart test/scene_actor_route_authoring_test.dart test/narrative_command_catalog_closure_test.dart` | No issues, 9 fichiers ; 1.615s ; exit0 |
| `actor-route-owner-api-analyze-02.json` ; `packages/map_authoring` | `/opt/homebrew/bin/dart analyze lib/src/domains/narrative/scene_actions.dart test/domains/narrative/scene_actor_route_transport_test.dart` | No issues, 2 fichiers ; 4.09s ; exit0 |
| `actor-route-egress-analyze-02.json` ; `packages/map_gameplay` | `/opt/homebrew/bin/dart analyze lib/src/actor_route_motion.dart test/actor_route_initial_owner_egress_test.dart` | No issues ; 2.508s ; exit0 |
| `root-executor-analyze-final-01.json` ; `packages/map_gameplay` | `dart analyze lib/src/actor_route_executor.dart test/actor_route_executor_test.dart` | No issues ; 6.962s ; exit0 |
| `root-runtime-analyze-final-02.json` ; `packages/map_runtime` | `flutter analyze --no-pub --no-fatal-infos lib/src/presentation/flame/playable_map_game.dart lib/src/presentation/flame/playable_map_game_support.dart test/playable_map_game_connection_arrival_collision_test.dart` | 0 erreur/warning, 6 infos baseline ; 11.422s ; exit0 |
| `actor-egress-ui-studio-analyze-final-01.json` ; `apps/avelune_studio` | `/opt/homebrew/share/flutter-3.47.5/bin/flutter analyze lib/presentation/features/scenes/scene_actor_action_form.dart test/presentation/scene_actor_action_form_test.dart test/scenes/scene_actor_action_publication_test.dart` | No issues, 3 fichiers ; 6.962s ; exit0 |
| `actor-egress-ui-legacy-analyze-final-01.json` ; `packages/map_editor` | `/opt/homebrew/share/flutter-3.47.5/bin/flutter analyze lib/src/ui/canvas/scenes/scene_actor_action_builder.dart test/scene_actor_action_builder_test.dart` | No issues, 2 fichiers ; 5.074s ; exit0 |
| `actor-route-owner-mcp-check-final-03.json` ; `tools/pokemap_mcp` | `npm run check` | tsc check PASS ; 1.799s ; exit0 |
| `actor-route-owner-mcp-build-final-02.json` ; `tools/pokemap_mcp` | `npm run build` | tsc build PASS ; 1.428s ; exit0 |
| `root-studio-build-final-01.json` ; `apps/avelune_studio` | `flutter build macos --debug --no-pub` | Studio macOS debug build PASS ; 117.875s ; exit0 |

Les six informations Runtime sont baseline : initializing formals2, null-aware1, curly braces3 ; aucune erreur/warning dans l'analyse finale. Aucun nouveau harness ne survit. Le build a laissé deux ibtoold descendants prouvés, PID42877/42878, terminés normalement après vérification UID/start/commande ; aucun autre signal et PIDs protégés inchangés. Aucune nouvelle fenêtre de test n'a été lancée. Build réussi ne vaut pas ouverture/édition/reprise du projet original.

### Contrepreuves, corrections et revue indépendante

RED executor :18PASS/1FAIL, owner JSON perdu à l'appel du port ; GREEN19PASS après forwarding. Planner pur :RED0/1 avant garde dédiée, puis76PASS. Contrat/refs : RED fonctionnels de parsing et guards puis Core164PASS. Un P2 indépendant montrait qu'un PNJ visuel1×2 pouvait proposer un contact1×1 décalé de l'ancre ; helper corrigé, défaut tall et contact décalé refusés, cas visuel1×2 avec collision.height1/offsetY0 conservé positif. Guards API correspondants RED0/3 puis GREEN. Callback de picker d'une ancienne carte reproduit RED dans les deux éditeurs ; clés qualifiées par carte avec préfixe de longueur corrigées.

Runtime RED : une arrivée owner physique restait bloquée et deux cas n'atteignaient pas stepping ; correction consommée par le vrai Player. Les deux erreurs de fixture ultérieures sont conservées : obstacle custom sans collision override explicite, puis position debug NPC interprétée comme ancienne position pendant une réservation. Les fixtures sont corrigées sans changer la production ; sept cas owner passent, dont un autre NPC réellement en mouvement réservant C. Le premier Core élargi avait163PASS/1FAIL parce que la liste attendue du catalogue omettait le setter d'instance du précédent commit ; un seul ID de fixture ajouté,164PASS.

MCP finals01/02/03 échouaient à scene.upsert. L'isolation de la requête ET du contexte exact après sept mutations a trouvé `Invalid argument (afterBytes): must differ from beforeBytes`, change_set.dart:33→narrativeProjectDraft:66→SceneActions.build:355. JSON/ref/upsert typed passent ; l'upsert demandait exactement la scène déjà enregistrée. Le test demande maintenant deux mutations réelles (upsert owner actor, graph.patch trainer-actor), sans correctif de production pour le no-op. MCP04 est la preuve finale1PASS/0SKIP ; API28 inclut aussi l'upsert sparse. Les compilations de fixtures et captures diagnostiques ne sont pas comptées comme preuves positives.

| Passe | Verdict et périmètre |
| --- | --- |
| Audit / Architecture — root et agents | Contrats/Source/références/physique examinés ; permis owner local, aucune substitution au programme source. |
| Implémentation — Core12, Pure2, UI5, Root5 | 24 fichiers scindés par propriété ; pas de générateur, barrel, asset ou modification étrangère. |
| Tests — mêmes agents et root | RED/GREEN et refus réels ; finales Core164/API28/Pure76/Executor19/Runtime106/host15/Studio32/Legacy29/MCP1. |
| Build / Validation — root et Core | Studio macOS debug et MCP check/build PASS ; analyses bornées, pas de GUI originale. |
| Critique finale — ac13_warp_final_review + ac15_connection_review_fresh | Lecture indépendante des gels/diffs/reçus ; P2 contact décalé fermé, réservation réelle ajoutée ; aucun autre P1/P2 identifié dans le périmètre. |

### Oracle source, suite et auto-critique

L'audit statique exact garde ScriptsSHA `3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d`, Map100SHA `3a101f07319e797c0021212ce5e6adc5344128eaff4b1ea2c4712219289c47a0`. Pour Map100event8page0, trigger1 est le contact lors d'un mouvement refusé :032.rb:220–221 exclut USE pour trigger1 ;046.rb:172/387–408 le démarre après refus,045.rb:133–135 établit le caractère bloquant. La seconde page est autorun/TempA. Le retour Map102event1 arrive Map100(13,25) puis MoveDown(13,26), sans Through. Les six routes forcées source sont non répétées et skippable ; aucun Through, arrivée déplacée ou interaction manuelle n'est inventé.

La lacune suivante est une source native EventV2 de contact joueur/entité : entityInteract manuel, placedElement.onBump et warp.onBump ne reproduisent pas ce programme. L'audit `source-door-bump-audit-01/audit-01.json` conserve la proposition entityBump2D avec collector pur, revalidation Runtime, autorité EventV2 et transports/guides, sans implémentation ni admission Source dans ce commit. L'autorun doit aussi être raccordé fidèlement. Les guides conditions/état/Warp-owner/policy, le profilSource v5 et la projection complète restent ouverts.

La tranche est utile mais ne démontre pas l'original aller/retour, save/reload ou Studio open/edit/save/reopen du parcours converti. Champs/guides bornés au2D ; metadata owner partial conservée ; Inspector legacy et3D non qualifiés. FG082/090/093 restent PARTIAL et FG092 TODO dans la roadmap inchangée. AC13 global et goal AC00–16 restent PARTIAL/actifs. Les tests natifs ne font pas progresser seuls la couverture des9/44 événements du dernier échantillon original.

### Git et suivi

Yoahn autorise explicitement les commits et push directement sur main. Publication prévue en un commit limité aux25 chemins, sans force-push/rebase/amend/branche/worktree. Garde fraîche avant copie : HEAD97c et index vide, tous les blobs host propres du scope égaux à la base, toute dérive privée hors scope refusée sauf22 exclusions connues. Les SHA/modes des travaux étrangers sont contrôlés avant/après copie, commit et push ; leur saleté reste visible. Les reçus `publication-final-01` enregistrent arbre, parent, SHA final, index, remote et empreintes étrangères ; pas de SHA futur inventé dans ce rapport.

Le ticket existant AC13 demeure dans le seul grand domaine Post Bêta Monde & narration, Gate bêta false. Cette tranche est proposée TO REVIEW, verdict global PARTIAL ; DONE réservé à Yoahn. La suite reprend le même ticket en DOING pour le contact original et la projection, sans créer un ticket de carte ou de bug. Markdown hygiene et diffcheck doivent passer sur les seuls fichiers de livraison avant commit, avec reçus exacts.


## Complément AC-13 — Contact natif du joueur avec un PNJ bloquant, 14 octobre 2026

### Résultat et audit initial

La source EventV2 `entityBump(mapId, entityId)` est distincte de `entityInteract`. Studio la présente comme « Contact du joueur ». Elle démarre lors d'une tentative de marche bloquée par un PNJ qualifié, sans tourner ce PNJ et sans bouton primaire. Core et Gameplay restent purs, les guides utilisent les API canoniques. Cette tranche ne modifie pas SourceIR v4 ni la projection : `sourceAdmission=false`, portes originales et jeu Kanto complet encore PARTIAL. Combat Avelune conservé.

Base fraîche `fc0dd4b1d3affb2a2ed00c04707ea3be52d9fbfc`, main, index vide. Archive privée R : 9240 fichiers réguliers hors scope comparés, deux écarts QA connus (GeneratedPluginRegistrant Converter et rapport AC16) et vingt pyc historiquement suivis absents, exclus de la livraison. Les changements étrangers du host sont exclus. Règle humaine sans commentaires prioritaire sur codex_rule §3 ; ce rapport existant est le seul Markdown modifié.

L'audit a identifié trois seams : absence du type/cataloque, absence d'un collector pur, absence du dispatch Player. Une simple recherche de collision à +1 pixel est insuffisante : le Player refuse un pas atomique par case avant ce contact. Le collector rejoue exactement la distance de la tentative refusée, bornée à une case, et s'arrête au premier obstacle. Un owner unique n'est reconnu que si son seul retrait libère cet échantillon ; terrain, eau, masques, bounds, autres NPC et réservations anonymes restent actifs. Aucun clamp, snap, Through ni changement général du mouvement.

Le Runtime capture acteur, activation, instance logique, pose et distance ; il revalide avant Scene. Un owner mobile/retiré/remplacé est refusé. Le propre Move ou Warp intentionnel de la Scene ne provoque pas un faux stale après démarrage. Le verrou et la suppression des touches sont engagés avant le premier await. Contact n'a ni fallback Interaction/legacy ni support3D. Core accepte une vraie empreinte canonique générale ; il n'emprunte pas la restriction egress1×1.

### Inventaire et zones des 78 sources/tests

Les quatre gels immuables Core37/Pure8/UI25/Root8 donnent les blobs/baselines/SHA ; l'inventaire d'union les recompute. Le rapport ajoute le79e chemin. Aucun asset, generator ou writer Converter n'est modifié.

| Chemin | Zones du diff | Raison/impact |
| --- | --- | --- |
| `apps/avelune_studio/lib/features/narrative/application/narrative_interaction_opener.dart` | @@ -235,0 +236 @@ class NarrativeInteractionOpener { | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `apps/avelune_studio/lib/features/narrative/application/narrative_interaction_reader.dart` | @@ -25,0 +26 @@ NarrativeInteractionDraft? readStudioInteraction( | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `apps/avelune_studio/lib/features/narrative/application/narrative_overview_context.dart` | @@ -149,0 +150,9 @@ class NarrativeOverviewContext { | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `apps/avelune_studio/lib/presentation/features/events/event_context_map.dart` | @@ -119,0 +120,9 @@ class _EventContextMapState extends State<EventContextMap> { ; @@ -121,5 +130,2 @@ class _EventContextMapState extends State<EventContextMap> { ; @@ -127,4 +133,5 @@ class _EventContextMapState extends State<EventContextMap> { ; @@ -140 +147 @@ class _EventContextMapState extends State<EventContextMap> { | Choix guidé Contact, cibles canoniques et refus de callback périmé de carte/type. |
| `apps/avelune_studio/lib/presentation/features/events/event_labels.dart` | @@ -6,0 +7 @@ const eventSourceKinds = [ ; @@ -13,0 +15 @@ StudioTone eventKindTone(NarrativeEventSourceKind? kind) => switch (kind) { ; @@ -44,0 +47 @@ String? eventMapId(NarrativeEventSourceRef? source) => source?.when( ; @@ -52,0 +56 @@ String? eventTargetId(NarrativeEventSourceRef? source) => source?.when( ; @@ -60,0 +65 @@ String eventKindLabel(NarrativeEventSourceKind? kind) => switch (kind) { ; @@ -69,0 +75 @@ IconData eventKindIcon(NarrativeEventSourceKind? kind) => switch (kind) { | Libellé Contact du joueur et description française guidée. |
| `apps/avelune_studio/lib/presentation/features/events/event_outcome_picker.dart` | @@ -61,0 +62 @@ class EventOutcomeSummary extends StatelessWidget { | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `apps/avelune_studio/lib/presentation/features/events/event_source_identity.dart` | @@ -71 +71,2 @@ class _EventSourceIdentityState extends State<EventSourceIdentity> { ; @@ -78,0 +80,6 @@ class _EventSourceIdentityState extends State<EventSourceIdentity> { ; @@ -80 +87,2 @@ class _EventSourceIdentityState extends State<EventSourceIdentity> { | Identité map/entity qualifiée en conservant le type Contact ; guards de référence. |
| `apps/avelune_studio/lib/presentation/features/events/event_trigger_panel.dart` | @@ -87,0 +88,3 @@ class _EventTriggerPanelState extends State<EventTriggerPanel> { ; @@ -111,0 +115,2 @@ class _EventTriggerPanelState extends State<EventTriggerPanel> { ; @@ -122,0 +128,6 @@ class _EventTriggerPanelState extends State<EventTriggerPanel> { | Choix guidé Contact, cibles canoniques et refus de callback périmé de carte/type. |
| `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_event_binding.dart` | @@ -122 +122,2 @@ extension _WorkspaceEventBinding on _MapWorkspaceScreenState { | Identité map/entity qualifiée en conservant le type Contact ; guards de référence. |
| `apps/avelune_studio/test/events/entity_bump_authoring_test.dart` | Créé ; 585 lignes | Tests positifs/négatifs du contact typé, refus et transport réel dans ce package. |
| `packages/map_authoring/lib/src/domains/distribution/game_package_gameplay_readiness_gate.dart` | @@ -468,0 +469 @@ Set<String> _runtimeStartEventIds(ProjectManifest project) { | Catalogue/diagnostic/authoring raccordé explicitement au Contact2D, sans alias Interaction. |
| `packages/map_authoring/test/domains/narrative/narrative_entity_bump_transport_test.dart` | Créé ; 327 lignes | Tests positifs/négatifs du contact typé, refus et transport réel dans ce package. |
| `packages/map_core/lib/map_core_domain.dart` | @@ -390,0 +391,2 @@ export 'src/operations/ledge_line_border_resolver.dart'; | Export public du nouveau contrat/helper requis par les consommateurs. |
| `packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart` | @@ -38,0 +39,3 @@ NarrativeScenarioAuthoringSourceDraft | Catalogue/diagnostic/authoring raccordé explicitement au Contact2D, sans alias Interaction. |
| `packages/map_core/lib/src/authoring/narrative_event_source_operations_v2.dart` | @@ -477,0 +478,12 @@ NarrativeEventSourceImpactPreview _sourceImpact({ | Catalogue/diagnostic/authoring raccordé explicitement au Contact2D, sans alias Interaction. |
| `packages/map_core/lib/src/catalogs/narrative_event_project_catalog.dart` | @@ -196,0 +197 @@ final class NarrativeEventProjectCatalog { | Catalogue/diagnostic/authoring raccordé explicitement au Contact2D, sans alias Interaction. |
| `packages/map_core/lib/src/catalogs/narrative_spatial_event_source_catalog.dart` | @@ -148,0 +149,5 @@ final class NarrativeSpatialEventSourceOption { ; @@ -284,0 +290,4 @@ final class NarrativeSpatialEventSourceOption { ; @@ -306,0 +316 @@ final class NarrativeSpatialEventSourceOption { | Catalogue/diagnostic/authoring raccordé explicitement au Contact2D, sans alias Interaction. |
| `packages/map_core/lib/src/compatibility/legacy_map_event_projection.dart` | @@ -61 +61,5 @@ final class LegacyMapEventSourceCandidate { | Source distincte et refus des candidats/provenances/créations physiques legacy non équivalents. |
| `packages/map_core/lib/src/compatibility/legacy_scenario_source_projection.dart` | @@ -461,0 +462 @@ bool _claimMatchesUnqualifiedOutcome( ; @@ -573,0 +575 @@ bool _legacyScenarioNodeMayMatchSource( ; @@ -769,0 +772 @@ bool isCompatibleLegacyScenarioSourceChoice({ | Source distincte et refus des candidats/provenances/créations physiques legacy non équivalents. |
| `packages/map_core/lib/src/compatibility/narrative_event_migration_planner_impl.dart` | @@ -327,0 +328 @@ final class NarrativeEventMigrationPlanner { ; @@ -2131,0 +2133 @@ List<NarrativeOutcomeRef> _candidateOutcomeReferences( | Source distincte et refus des candidats/provenances/créations physiques legacy non équivalents. |
| `packages/map_core/lib/src/models/narrative_event_source_ref.dart` | @@ -21,0 +22 @@ enum NarrativeEventSourceKind { ; @@ -86,0 +88,2 @@ sealed class NarrativeEventSourceRef { ; @@ -93,0 +97,5 @@ sealed class NarrativeEventSourceRef { ; @@ -139,0 +148,19 @@ sealed class NarrativeEventSourceRef { ; @@ -213,0 +241 @@ sealed class NarrativeEventSourceRef { ; @@ -237,0 +266 @@ final class _EntityInteractSourceRef extends NarrativeEventSourceRef { ; @@ -262,0 +292,41 @@ final class _EntityInteractSourceRef extends NarrativeEventSourceRef { ; @@ -277,0 +348 @@ final class _ModelInteractSourceRef extends NarrativeEventSourceRef { ; @@ -316,0 +388 @@ final class _TriggerEnterSourceRef extends NarrativeEventSourceRef { ; @@ -354,0 +427 @@ final class _MapEnterSourceRef extends NarrativeEventSourceRef { ; @@ -387,0 +461 @@ final class _OutcomeReceivedSourceRef extends NarrativeEventSourceRef { | Kind/wire entityBump distinct, callback when obligatoire et sérialisation stricte. |
| `packages/map_core/lib/src/operations/build_narrative_event_project_catalog.dart` | @@ -373,0 +374,2 @@ NarrativeEventProjectResolutionStatus _resolveSource( | Catalogue/diagnostic/authoring raccordé explicitement au Contact2D, sans alias Interaction. |
| `packages/map_core/lib/src/operations/build_narrative_event_reachability_report.dart` | @@ -224,0 +225 @@ String? _mapId(NarrativeEventSourceRef source) => source.when( ; @@ -232,0 +234 @@ String? _ownerId(NarrativeEventSourceRef source) => source.when( | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `packages/map_core/lib/src/operations/build_narrative_event_validation_report.dart` | @@ -280,0 +281 @@ String? _recordSceneId(NarrativeEventRecord? record) { | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `packages/map_core/lib/src/operations/build_narrative_outcome_event_source_catalog.dart` | @@ -635,0 +636 @@ void _appendMissingReferences({ | Catalogue/diagnostic/authoring raccordé explicitement au Contact2D, sans alias Interaction. |
| `packages/map_core/lib/src/operations/build_narrative_spatial_event_source_catalog.dart` | @@ -11,0 +12,2 @@ import 'narrative_event_canonical_json.dart'; ; @@ -175,0 +178 @@ void _appendMapOptions({ ; @@ -269,0 +273 @@ void _appendEntityOptions({ ; @@ -305,0 +310,5 @@ void _appendEntityOptions({ ; @@ -309,0 +319,40 @@ void _appendEntityOptions({ ; @@ -694,0 +744 @@ String? _spatialSourceMapId(NarrativeEventSourceRef source) { | Catalogue/diagnostic/authoring raccordé explicitement au Contact2D, sans alias Interaction. |
| `packages/map_core/lib/src/operations/narrative_entity_bump_source_reference.dart` | Créé ; 43 lignes | Éligibilité canonique NPC bloquant/Character unique/2D et empreinte de collision valide. |
| `packages/map_core/lib/src/operations/narrative_event_dispatch_authority.dart` | @@ -189 +189 @@ final class NarrativeEventDispatchAuthorityReady ; @@ -243 +243,2 @@ final class NarrativeEventDispatchAuthorityReady ; @@ -1032,0 +1034 @@ String? _sourceMapId(NarrativeEventSourceRef source) { | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `packages/map_core/lib/src/operations/narrative_project_validator.dart` | @@ -17,0 +18 @@ import '../models/project_manifest.dart'; ; @@ -1294,0 +1296 @@ _solveNarrativeReachability(ProjectManifest project, List<MapData> maps) { ; @@ -1393,0 +1396 @@ bool _eventSourceStaticallyReachable( ; @@ -1400 +1403,5 @@ bool _eventSourceStaticallyReachable( ; @@ -1404 +1411 @@ bool _eventSourceStaticallyReachable( ; @@ -1408 +1415 @@ bool _eventSourceStaticallyReachable( ; @@ -1735 +1742 @@ List<NarrativeMapEventsView> _buildMapEventViews( ; @@ -2141,0 +2149 @@ List<NarrativeEventCondition> _recordConditions(NarrativeEventRecord record) => ; @@ -2151,0 +2160 @@ bool _sourceConnected( ; @@ -2157,0 +2167,5 @@ bool _sourceConnected( ; @@ -2185,0 +2200,11 @@ bool _sourceConnected( | Catalogue/diagnostic/authoring raccordé explicitement au Contact2D, sans alias Interaction. |
| `packages/map_core/lib/src/operations/narrative_symbolic_reachability_solver.dart` | @@ -9,0 +10 @@ import '../models/project_manifest.dart'; ; @@ -498,0 +500,4 @@ NarrativeSymbolicReachabilityReport solveNarrativeSymbolicReachability( ; @@ -596 +601 @@ NarrativeSymbolicReachabilityReport solveNarrativeSymbolicReachability( ; @@ -640 +645 @@ NarrativeSymbolicReachabilityReport solveNarrativeSymbolicReachability( ; @@ -944,0 +950 @@ _ProjectedSymbolicSeeds _projectSymbolicSeeds({ ; @@ -1145,0 +1152 @@ _NarrativeBatchFootprint _narrativeBatchFootprint({ ; @@ -1665,0 +1673,2 @@ bool? _sourceEligibility( ; @@ -1670,0 +1680,8 @@ bool? _sourceEligibility( | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart` | @@ -690,0 +691 @@ String? _sourceMapId(NarrativeEventSourceRef? source) => source?.when( | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `packages/map_core/lib/src/read_models/narrative_dependency_index.dart` | @@ -26,0 +27 @@ import '../operations/scene_actor_reference.dart'; ; @@ -1323,0 +1325,14 @@ final class _NarrativeDependencyIndexBuilder { | Identité map/entity qualifiée en conservant le type Contact ; guards de référence. |
| `packages/map_core/lib/src/read_models/narrative_event_builder_project_read_model.dart` | @@ -558,0 +559 @@ NarrativeEventBuilderProjectReadModel ; @@ -1914,0 +1916,10 @@ NarrativeEventSourceSummary _missingSourceSummary( | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `packages/map_core/lib/src/read_models/narrative_event_navigation_intent.dart` | @@ -410,0 +411 @@ final class NarrativeEventNavigationIndex { ; @@ -422,0 +424 @@ final class NarrativeEventNavigationIndex { ; @@ -541,0 +544 @@ final class NarrativeEventNavigationIndex { ; @@ -708,0 +712,13 @@ final class NarrativeEventNavigationIndex { ; @@ -913,0 +930 @@ String _missingSpatialReason(NarrativeEventSourceRef source) { ; @@ -928,0 +946,5 @@ Map<String, String> _sourceDebugReferences(NarrativeEventSourceRef source) { | Identité map/entity qualifiée en conservant le type Contact ; guards de référence. |
| `packages/map_core/lib/src/read_models/narrative_global_search_index.dart` | @@ -451,0 +452 @@ String _eventSourceKindKeyword(NarrativeEventSourceKind kind) => switch (kind) { ; @@ -517,0 +519 @@ String? _eventSourceMapId(NarrativeEventSourceRef? source) => source?.when( | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `packages/map_core/lib/src/read_models/narrative_map_events_read_model.dart` | @@ -463,0 +464 @@ String? _sourceMapId(NarrativeEventSourceRef source) => source.when( | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `packages/map_core/lib/src/read_models/narrative_world_state_simulation.dart` | @@ -429,0 +430 @@ String? _sourceMapId(NarrativeEventSourceRef? source) => source?.when( | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `packages/map_core/test/narrative_entity_bump_authority_test.dart` | Créé ; 247 lignes | Tests positifs/négatifs du contact typé, refus et transport réel dans ce package. |
| `packages/map_core/test/narrative_entity_bump_catalog_test.dart` | Créé ; 221 lignes | Tests positifs/négatifs du contact typé, refus et transport réel dans ce package. |
| `packages/map_core/test/narrative_entity_bump_source_test.dart` | Créé ; 121 lignes | Tests positifs/négatifs du contact typé, refus et transport réel dans ce package. |
| `packages/map_core/test/narrative_event_migration_integrity_closure_test.dart` | @@ -1023,0 +1024 @@ LegacyMapEventProjection _projection({ ; @@ -1243,0 +1245 @@ List<NarrativeOutcomeRef> _outcomesFrom( | Raccord obligatoire du nouveau callback/type et non-régressions du consommateur existant. |
| `packages/map_core/test/narrative_event_migration_planner_test.dart` | @@ -2939,0 +2940 @@ List<MapEntity> _entitiesForSources( ; @@ -2955,0 +2957 @@ List<MapEntity> _entitiesForSources( ; @@ -2986,0 +2989 @@ List<MapTrigger> _triggersForSources( ; @@ -3007,0 +3011 @@ List<MapTrigger> _triggersForSources( ; @@ -3064,0 +3069 @@ List<NarrativeOutcomeRef> _referencedOutcomes( ; @@ -3190,0 +3196 @@ ScenarioNode _scenarioNodeForSource( ; @@ -3206,0 +3213 @@ ScenarioNode _scenarioNodeForSource( ; @@ -3255,0 +3263 @@ void _addSourceMap(Set<String> result, NarrativeEventSourceRef? source) { ; @@ -3297,0 +3306 @@ LegacyMapEventProjection _projection({ ; @@ -3332,0 +3342 @@ LegacyMapEventProjection _projection({ ; @@ -3357,0 +3368 @@ LegacyMapEventProjection _projection({ ; @@ -3416,0 +3428 @@ GridPos _sourceFixturePosition(NarrativeEventSourceRef source) { | Raccord obligatoire du nouveau callback/type et non-régressions du consommateur existant. |
| `packages/map_core/test/narrative_event_source_ref_test.dart` | @@ -18,0 +19 @@ void main() { ; @@ -374,0 +376 @@ String _describeSource(NarrativeEventSourceRef source) => source.when( | Raccord obligatoire du nouveau callback/type et non-régressions du consommateur existant. |
| `packages/map_core/test/narrative_spatial_event_source_catalog_test.dart` | @@ -225 +225,5 @@ void main() { ; @@ -230 +234,8 @@ void main() { ; @@ -232 +243 @@ void main() { ; @@ -236 +247 @@ void main() { ; @@ -735 +746,2 @@ void main() { | Raccord obligatoire du nouveau callback/type et non-régressions du consommateur existant. |
| `packages/map_core/test/support/f1_runtime_catalog_fixture.dart` | @@ -73,0 +74 @@ NarrativeOutcomeRef? _outcomeOrNull(NarrativeEventSourceRef source) { ; @@ -117,0 +119 @@ NarrativeSpatialEventSourceOption _spatialOption( | Raccord obligatoire du nouveau callback/type et non-régressions du consommateur existant. |
| `packages/map_core/test/support/narrative_event_authoring_fixtures.dart` | @@ -199,0 +200 @@ NarrativeSpatialEventSourceOption spatialOption( | Raccord obligatoire du nouveau callback/type et non-régressions du consommateur existant. |
| `packages/map_editor/lib/src/application/models/narrative_event_spatial_link_journal_models.dart` | @@ -387,0 +388 @@ String? narrativeEventSpatialSourceMapId(NarrativeEventSourceRef source) { ; @@ -405,0 +407 @@ String narrativeEventSpatialSourceOwnerId(NarrativeEventSourceRef source) { | Source distincte et refus des candidats/provenances/créations physiques legacy non équivalents. |
| `packages/map_editor/lib/src/application/services/narrative_event_source_dependency_guard.dart` | @@ -126 +126,2 @@ final class NarrativeEventSourceDependencyGuard { ; @@ -133 +134,2 @@ final class NarrativeEventSourceDependencyGuard { ; @@ -148 +150,2 @@ final class NarrativeEventSourceDependencyGuard { ; @@ -243,0 +247 @@ String? _mapId(NarrativeEventSourceRef source) { ; @@ -263,0 +268,4 @@ bool _isResolvedByMap(NarrativeEventSourceRef source, MapData map) { | Identité map/entity qualifiée en conservant le type Contact ; guards de référence. |
| `packages/map_editor/lib/src/application/services/narrative_event_validation_coordinator.dart` | @@ -517,0 +518 @@ bool _matchesSpatialDestination( | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `packages/map_editor/lib/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart` | @@ -877,0 +878 @@ String? _proposalIssue(NarrativeEventCreatedSourceProposal proposal) { | Catalogue/diagnostic/authoring raccordé explicitement au Contact2D, sans alias Interaction. |
| `packages/map_editor/lib/src/application/use_cases/narrative_event_migration_preview_use_case.dart` | @@ -88,0 +89 @@ final class NarrativeEventMigrationPreviewUseCase { | Source distincte et refus des candidats/provenances/créations physiques legacy non équivalents. |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | @@ -3558,0 +3559 @@ class EditorNotifier extends _$EditorNotifier ; @@ -3923,0 +3925 @@ class EditorNotifier extends _$EditorNotifier ; @@ -3980,0 +3983 @@ class EditorNotifier extends _$EditorNotifier ; @@ -4137,0 +4141 @@ class EditorNotifier extends _$EditorNotifier ; @@ -4170,0 +4175 @@ class EditorNotifier extends _$EditorNotifier | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `packages/map_editor/lib/src/features/narrative/state/narrative_event_map_bridge_state.dart` | @@ -2204,0 +2205 @@ String _spatialMapId(NarrativeEventSourceRef source) { ; @@ -2233,0 +2235 @@ bool _mapOwnsSource(MapData map, NarrativeEventSourceRef source) { | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `packages/map_editor/lib/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart` | @@ -1106,0 +1107 @@ final class NarrativeEventSpatialLinkJournalRepository ; @@ -1153,0 +1155 @@ final class NarrativeEventSpatialLinkJournalRepository | Source distincte et refus des candidats/provenances/créations physiques legacy non équivalents. |
| `packages/map_editor/lib/src/ui/canvas/events/narrative_event_map_return_panel.dart` | @@ -252,0 +253 @@ String _mapId(NarrativeEventSourceRef source) { ; @@ -267,0 +269 @@ String _spatialSourceLabel( | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_authoring_sheets.dart` | @@ -57 +57,3 @@ List<EventBuilderV2SourceChoice> eventBuilderV2SourceChoices( | Libellé Contact du joueur et description française guidée. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart` | @@ -606,0 +607 @@ bool _isSpatialAndAvailable(NarrativeEventProjectSummary event) { | Raccord explicite du nouveau type/callback dans le contexte narratif existant. |
| `packages/map_editor/lib/src/ui/canvas/narrative_validator_workspace.dart` | @@ -1339,0 +1340 @@ String _sourceLabel(NarrativeMapEventEntry event) { | Catalogue/diagnostic/authoring raccordé explicitement au Contact2D, sans alias Interaction. |
| `packages/map_editor/test/entity_bump_source_authoring_test.dart` | Créé ; 209 lignes | Tests positifs/négatifs du contact typé, refus et transport réel dans ce package. |
| `packages/map_editor/test/narrative_event_explicit_source_creation_test.dart` | @@ -246,0 +247 @@ void main() { | Raccord obligatoire du nouveau callback/type et non-régressions du consommateur existant. |
| `packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart` | @@ -492,0 +493 @@ void _expectPlayerServicesContract( ; @@ -1002,0 +1004 @@ void _expectCanonicalEventProgression(ProjectManifest manifest) { ; @@ -1033,0 +1036 @@ void _expectCanonicalEventProgression(ProjectManifest manifest) { ; @@ -1439,0 +1443 @@ void _expectEventSourcesClose( | Raccord obligatoire du nouveau callback/type et non-régressions du consommateur existant. |
| `packages/map_gameplay/lib/map_gameplay.dart` | @@ -140 +140,2 @@ export 'src/grid_pathfinder.dart' ; @@ -146,0 +148 @@ export 'src/gameplay_step_result.dart' | Export public du nouveau contrat/helper requis par les consommateurs. |
| `packages/map_gameplay/lib/src/gameplay_step.dart` | @@ -21,0 +22,112 @@ GameplayStepResult stepGameplayWorld( ; @@ -124,0 +237,4 @@ GameplayStepResult _resolveMove(GameplayWorldState world, MoveIntent intent, | Capture premier obstacle du balayage refusé, sans modifier le déplacement atomique. |
| `packages/map_gameplay/lib/src/gameplay_step_result.dart` | @@ -4,0 +5 @@ import 'directed_jump_plan.dart'; ; @@ -52,0 +54,26 @@ final class Moved extends GameplayStepResult { ; @@ -56,0 +84 @@ final class Blocked extends GameplayStepResult { ; @@ -59,0 +88 @@ final class Blocked extends GameplayStepResult { | DTO immutable du contact : pose, rectangle, direction et distance de tentative. |
| `packages/map_gameplay/lib/src/gameplay_world_state.dart` | @@ -357 +357,3 @@ class GameplayWorldState { ; @@ -379,0 +382,3 @@ class GameplayWorldState { | Ignorer seulement un owner lors de la preuve pure ; défaut de collision inchangé. |
| `packages/map_gameplay/lib/src/validation/narrative_physical_reachability_validator.dart` | @@ -7,0 +8,4 @@ import '../gameplay_connection.dart'; ; @@ -137 +141 @@ NarrativePhysicalReachabilityReport validateNarrativePhysicalReachability({ ; @@ -294,0 +299 @@ NarrativePhysicalReachabilityReport validateNarrativePhysicalReachability({ ; @@ -333,0 +339 @@ NarrativePhysicalReachabilityIssue? _validateSourceReference( ; @@ -373,0 +380,21 @@ NarrativePhysicalReachabilityIssue? _validateSourceReference( ; @@ -518,0 +546,14 @@ _StateExploration _exploreSymbolicState({ ; @@ -612,0 +654,62 @@ _StateExploration _exploreSymbolicState({ ; @@ -918,0 +1022 @@ String? _sourceMapId(NarrativeEventSourceRef source) => source.when( | Replay physique du contact, indeterminate sans preuve ; aucune adjacency Interact empruntée. |
| `packages/map_gameplay/test/gameplay_entity_bump_test.dart` | Créé ; 589 lignes | Tests positifs/négatifs du contact typé, refus et transport réel dans ce package. |
| `packages/map_gameplay/test/narrative_physical_reachability_validator_test.dart` | @@ -113,0 +114,35 @@ void main() { | Raccord obligatoire du nouveau callback/type et non-régressions du consommateur existant. |
| `packages/map_gameplay/test/support/f1_runtime_catalog_fixture.dart` | @@ -72,0 +73 @@ NarrativeOutcomeRef? _outcomeOrNull(NarrativeEventSourceRef source) { ; @@ -112,0 +114,5 @@ NarrativeSpatialEventSourceOption _spatialOption( | Raccord obligatoire du nouveau callback/type et non-régressions du consommateur existant. |
| `packages/map_runtime/lib/src/application/narrative_event_runtime_snapshot.dart` | @@ -172,0 +173 @@ final class NarrativeEventRuntimeSnapshot { | Callback Contact explicite, sans outcomes legacy inventés. |
| `packages/map_runtime/lib/src/application/narrative_spatial_production_dispatch_bridge.dart` | @@ -178,0 +179 @@ final class NarrativeSpatialProductionDispatchBridge { ; @@ -181,0 +183,7 @@ final class NarrativeSpatialProductionDispatchBridge { ; @@ -219,0 +228,3 @@ final class NarrativeSpatialProductionDispatchBridge { ; @@ -237,0 +249,5 @@ final class NarrativeSpatialProductionDispatchBridge { ; @@ -299 +315,2 @@ final class NarrativeSpatialProductionDispatchBridge { ; @@ -347,0 +365 @@ final class NarrativeSpatialProductionDispatchBridge { ; @@ -353 +371 @@ final class NarrativeSpatialProductionDispatchBridge { | Guard physique requis et contrôlé avant Scene ; aucun fallback legacy pour Contact. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | @@ -1028,0 +1029 @@ class PlayableMapGame extends FlameGame with KeyboardEvents { ; @@ -1053,0 +1055 @@ class PlayableMapGame extends FlameGame with KeyboardEvents { ; @@ -1260,0 +1263 @@ class PlayableMapGame extends FlameGame with KeyboardEvents { ; @@ -4989,0 +4993,15 @@ class PlayableMapGame extends FlameGame with KeyboardEvents { ; @@ -10191,0 +10210,85 @@ class PlayableMapGame extends FlameGame with KeyboardEvents { | Dispatch sur input refusé, lease et revalidation live avant Scene, sans face NPC ni fallback. |
| `packages/map_runtime/lib/src/spatial/spatial_gameplay_events.dart` | @@ -357,0 +358 @@ final class SpatialGameplayEvents { ; @@ -764,0 +766 @@ final class SpatialGameplayEvents { | Consommateur 3D ferme explicitement la source Contact2D sans alias. |
| `packages/map_runtime/test/narrative_map_enter_production_dispatch_bridge_test.dart` | @@ -928,0 +929 @@ NarrativeEventProjectCatalog _catalog( | Raccord obligatoire du nouveau callback/type et non-régressions du consommateur existant. |
| `packages/map_runtime/test/narrative_spatial_production_dispatch_bridge_test.dart` | @@ -16,0 +17,166 @@ void main() { ; @@ -805,0 +972,9 @@ NarrativeEventProjectCatalog _catalog( ; @@ -845,0 +1021,3 @@ NarrativeEventProjectCatalog _catalog( | Guard obligatoire/stale, Scene qui change volontairement le contact, no-fallback et fixture NPC/Character. |
| `packages/map_runtime/test/playable_map_game_connection_arrival_collision_test.dart` | @@ -21,0 +22,239 @@ void main() { ; @@ -1877,0 +2117,3 @@ Future<({PlayableMapGame game, GameplayWorldState targetWorld})> _fixture({ ; @@ -1897 +2139 @@ Future<({PlayableMapGame game, GameplayWorldState targetWorld})> _fixture({ ; @@ -2015,2 +2257,2 @@ Future<({PlayableMapGame game, GameplayWorldState targetWorld})> _fixture({ ; @@ -2063,0 +2306,12 @@ Future<({PlayableMapGame game, GameplayWorldState targetWorld})> _fixture({ ; @@ -2108,0 +2363 @@ Future<({PlayableMapGame game, GameplayWorldState targetWorld})> _fixture({ ; @@ -2542,0 +2798 @@ final class _ConnectionGame extends PlayableMapGame { ; @@ -2691,0 +2948,114 @@ final class _SceneSoundPort implements SceneSoundEffectPlaybackPort { | Quatre directions, primaire, touche maintenue, owner mobile, Scene move/Warp, JSON save/cold load et one-shot. |
| `packages/map_runtime/test/playable_map_game_qualified_outcome_v2_integration_test.dart` | @@ -1604,0 +1605 @@ void main() { | Raccord obligatoire du nouveau callback/type et non-régressions du consommateur existant. |
| `tools/pokemap_mcp/test/narrative_entity_bump_stdio.test.ts` | Créé ; 119 lignes | Tests positifs/négatifs du contact typé, refus et transport réel dans ce package. |

### Commandes et preuves

R = `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac16-refresh-20261014-ftgqyeej/repository`. Q = `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac13-entity-bump-20261014-bct2cqdt`. Tous les reçus ci-dessous sont dans Q ; leurs cwd exacts, commandes, pins avant/après et logs SHA sont conservés. Aucun total ne somme les reruns.

| Reçu ; cwd relatif à R | Commande exacte | Résultat ; durée |
| --- | --- | --- |
| `entity-bump-core-final-01.json` ; `packages/map_core` | `/opt/homebrew/bin/dart test test/narrative_entity_bump_source_test.dart test/narrative_entity_bump_catalog_test.dart test/narrative_entity_bump_authority_test.dart test/narrative_event_source_ref_test.dart test/narrative_event_dispatch_authority_test.dart test/narrative_spatial_event_source_catalog_test.dart test/narrative_dependency_index_test.dart test/narrative_event_builder_project_read_model_test.dart test/narrative_global_search_index_test.dart test/narrative_event_navigation_intent_test.dart test/narrative_event_source_authoring_operations_test.dart test/narrative_world_state_simulation_test.dart test/narrative_symbolic_reachability_solver_test.dart test/narrative_event_reachability_report_test.dart test/legacy_map_event_projection_test.dart test/legacy_scenario_source_projection_test.dart test/narrative_event_migration_planner_test.dart test/narrative_event_migration_integrity_closure_test.dart --reporter expanded` | Core281PASS/18suites ; 4.557s ; exit0 |
| `entity-bump-core-analyze-02.json` ; `packages/map_core` | `/opt/homebrew/bin/dart analyze lib/src/models/narrative_event_source_ref.dart test/narrative_entity_bump_source_test.dart lib/src/compatibility/narrative_event_migration_planner_impl.dart lib/src/compatibility/legacy_scenario_source_projection.dart lib/src/operations/build_narrative_event_project_catalog.dart lib/src/operations/narrative_symbolic_reachability_solver.dart lib/src/operations/build_narrative_event_reachability_report.dart lib/src/operations/narrative_event_dispatch_authority.dart lib/src/operations/narrative_project_validator.dart lib/src/operations/build_narrative_outcome_event_source_catalog.dart lib/src/operations/build_narrative_spatial_event_source_catalog.dart lib/src/operations/build_narrative_event_validation_report.dart lib/src/authoring/narrative_event_source_operations_v2.dart lib/src/catalogs/narrative_spatial_event_source_catalog.dart lib/src/catalogs/narrative_event_project_catalog.dart lib/src/read_models/narrative_event_navigation_intent.dart lib/src/read_models/facts_world_rules_manager_read_model.dart lib/src/read_models/narrative_event_builder_project_read_model.dart lib/src/read_models/narrative_global_search_index.dart lib/src/read_models/narrative_map_events_read_model.dart lib/src/read_models/narrative_dependency_index.dart lib/src/read_models/narrative_world_state_simulation.dart test/narrative_event_source_ref_test.dart test/narrative_event_migration_integrity_closure_test.dart test/narrative_event_migration_planner_test.dart test/support/narrative_event_authoring_fixtures.dart test/support/f1_runtime_catalog_fixture.dart lib/src/authoring/narrative_event_source_authoring_operations.dart test/narrative_entity_bump_catalog_test.dart lib/src/operations/narrative_entity_bump_source_reference.dart lib/map_core_domain.dart test/narrative_entity_bump_authority_test.dart lib/src/compatibility/legacy_map_event_projection.dart test/narrative_spatial_event_source_catalog_test.dart` | 0 erreur/warning,70INFO baseline ; 3.352s ; exit0 |
| `entity-bump-authoring-final-01.json` ; `packages/map_authoring` | `/opt/homebrew/bin/dart test test/domains/narrative/narrative_entity_bump_transport_test.dart --reporter expanded` | API/JSONL7PASS ; 4.965s ; exit0 |
| `entity-bump-authoring-analyze-01.json` ; `packages/map_authoring` | `/opt/homebrew/bin/dart analyze lib/src/domains/distribution/game_package_gameplay_readiness_gate.dart test/domains/narrative/narrative_entity_bump_transport_test.dart` | No issues ; 3.259s ; exit0 |
| `entity-bump-mcp-final-01.json` ; `tools/pokemap_mcp` | `node --import tsx --test --test-concurrency=1 test/narrative_entity_bump_stdio.test.ts` | MCP1PASS/0SKIP ; 9.633s ; exit0 |
| `pure-bump-targeted-current-01.json` ; `packages/map_gameplay` | `/opt/homebrew/bin/dart test test/gameplay_entity_bump_test.dart test/narrative_physical_reachability_validator_test.dart test/runtime_movement_collision_regression_test.dart test/gameplay_world_state_collision_storage_characterization_test.dart test/npc_default_collision_footprint_test.dart test/border_collision_ownership_test.dart test/actor_route_motion_test.dart test/actor_route_initial_owner_egress_test.dart test/gameplay_directed_jump_test.dart test/narrative_outcome_outbox_processor_test.dart --reporter expanded --concurrency=1` | Pure208PASS/0SKIP ; 5.891s ; exit0 |
| `root-runtime-union-final-02.json` ; `packages/map_runtime` | `flutter test --no-pub test/scene_map_instance_consequence_writer_test.dart test/playable_map_game_connection_arrival_collision_test.dart test/scene_interactive_command_runtime_executor_test.dart test/scene_actor_visibility_render_test.dart test/narrative_command_runtime_parity_test.dart test/phase_a_golden_battle_slice_smoke_test.dart test/narrative_spatial_production_dispatch_bridge_test.dart test/narrative_map_enter_production_dispatch_bridge_test.dart test/playable_map_game_qualified_outcome_v2_integration_test.dart --reporter expanded --concurrency=1` | Runtime196PASS/9suites ; 18.952s ; exit0 |
| `root-runtime-analyze-final-02.json` ; `packages/map_runtime` | `flutter analyze --no-pub --no-fatal-infos lib/src/presentation/flame/playable_map_game.dart lib/src/application/narrative_event_runtime_snapshot.dart lib/src/spatial/spatial_gameplay_events.dart lib/src/application/narrative_spatial_production_dispatch_bridge.dart test/playable_map_game_qualified_outcome_v2_integration_test.dart test/narrative_map_enter_production_dispatch_bridge_test.dart test/narrative_spatial_production_dispatch_bridge_test.dart test/playable_map_game_connection_arrival_collision_test.dart` | 0 erreur/warning,82INFO baseline ; 10.895s ; exit0 |
| `root-host-final-02.json` ; `examples/playable_runtime_host` | `flutter test --no-pub test/phase_a_golden_slice_launch_test.dart test/p3_narrative_smoke_slice_test.dart --reporter expanded --concurrency=1` | Host15PASS ; 7.452s ; exit0 |
| `root-studio-build-final-01.json` ; `apps/avelune_studio` | `flutter build macos --debug --no-pub` | Studio macOS debug build PASS ; 29.587s ; exit0 |
| `entity-bump-ui-studio-final-03.json` ; `apps/avelune_studio` | `flutter test --no-pub test/events/entity_bump_authoring_test.dart test/events/event_sources_ui08_test.dart test/events_ui08_source_loading_test.dart test/presentation/ui08_event_sources_test.dart --reporter expanded` | Studio21PASS ; 15.418s ; exit0 |
| `entity-bump-ui-legacy-final-04.json` ; `packages/map_editor` | `flutter test --no-pub test/entity_bump_source_authoring_test.dart test/event_builder_v2_condition_expression_test.dart --reporter expanded` | Legacy8PASS borné ; 3.448s ; exit0 |
| `root-converter-adapter-regression-final-01.json` ; `packages/avelune_converter_adapters` | `dart test test/source_event_projection_test.dart test/source_event_study_composer_test.dart test/source_event_arrival_validation_test.dart test/native_project_writer_test.dart --concurrency=2 --reporter expanded` | Adapters126PASS/2SKIP, pins Runtime historiques non consommés ; 24.416s ; exit0 |

MCP npm check/build sont PASS (1.799s/1.423s), commandes `npm run check` et `npm run build` dans R/tools/pokemap_mcp, reçus référencés par core-bump-01/qualification-final-01.json. Le MCP stdio frais prouve discovery des sourceVariants, upsert configuré, create_draft avec initialSource, refus avant mutation et cold reopen ; il ne prouve pas un live publish/activate. L'API `record_upsert` CONFIGURÉ refuse les sources invalides ; les drafts réparables gardent leur comportement existant, `create_draft initialSource` exige found. Pas de persistance JSON générique utilisée comme preuve sémantique. PMCP085global demeure PARTIAL.

Analyses : Core0erreur/warning70INFO et Runtime0erreur/warning82INFO, lignes chacune byte-identiques aux baselines capturées ; aucun nouveau INFO restant, aucune analyse baseline rerun revendiquée. Pure analyse historique8fichiers exit0/2.631s,0erreur/warning,1INFO library_name ; sources8 inchangées et tests courants208. Analyses UI historiques Studio10NoIssues/8.791s et Legacy14NoIssues/14.404s : UI25 inchangé, dépendances internes Core/Game évoluées depuis, bornes explicites. Build Studio complet frais29.587s ne vaut pas une ouverture GUI. Adapters126/2SKIP : deux tests dépendant de scriptsPath optionnel non configuré ; les six pins Runtime antérieurs aux corrections de lint sont historiques et non consommés par ce package Dart, dépendances Core/Authoring/Gameplay inchangées.

Legacy global PARTIAL : une archive fraîche fc de10packages,5768 fichiers/121318953 octets, reproduit les deux suites monolithiques non compilables (0PASS/2loadFAIL,39.281s). Les14 erreurs `String?→String` sont identiques : hover resolver4, environment generator2, placement editing2, EditorNotifier6. Les trois fichiers étrangers sont byte-identiques à fc, EditorNotifier ne change que cinq callbacks et ses six lignes fautives sont inchangées (+5). Contrepreuve Q/legacy-baseline-fc-01/countercompile-01.json, logSHA e09e965919e3178f82ab7359f03ccbd406695ae869f3976815ca70f0dfdfa67f. Aucun correctif de ces anciens défauts ni PASS global legacy annoncé.

### RED, incidents et verdicts

Core : RED parsing0/3, disponibilité7/2, autorité/ref/legacy1/4, symbolic0/2 puis281PASS. Pure : collectorRED2/5 et normal-step0/1, reachability3/1 puis208PASS. RuntimeinputRED0/4 avant raccord, puis +1pixelGREEN1/3 révélant le pas atomique ; tentative balayée et distance revalidée donnent quatre directions. Les14acceptances couvrent aussi primaire, touche maintenue, owner mobile, propre Move/Warp, reprise JSON et one-shot, cinq guards du bridge. La sauvegarde est une sérialisation réelle GameState.toJson/fromJson via dépôt en mémoire et nouvel objet Game/loadGame public ; aucune preuve disque/app d'origine n'est déduite.

UI : vrais RED de libellé/type/overlay/guards et callback anciennecarte. Incidents séparés : import de fixture absent, Character semé après ouverture du workspace, I/O du WidgetTester sous FakeAsync (vrai callback StudioButton dans runAsync ensuite, pas de correctif production Save), pin relatif refusé avant Popen. Root acceptance01 avait une metadata bool dans Map<String,String> et un cold fixture forcé source ; seuls les tests corrigés, Warp natif déjà réussi. Root acceptance02 GREEN14 puis union finale196 après formatage et15nouveauxINFO fermés. Aucun test supprimé pour rendre vert.

Tous les derniers runs ont zéro survivant possédé et aucun signal ; aucune fenêtre lancée. Ancien input-green02 enregistrait protectedUnchanged=false parce que le PID numérique310 était le propre sous-processus ps d'observation (parent309, runner311), sorti normalement ; aucun signal envoyé, reçu inchangé et audit Q/root-protected-pid-observation-audit-01.json explicite. Aucun PID humain/préexistant terminé.

| Passe | Verdict borné |
| --- | --- |
| Audit/Architecture — root + agents | Type/physique/autorité/source originaux distingués, pas atomique conservé, aucune approximation de porte. |
| Implémentation — Core37/Pure8/UI25/Root8 | Contrats et consommateurs explicites,78fichiers, pas de Source admission. |
| Tests — owners + root | Core281/API7/MCP1/Pure208/Runtime196/Host15/Studio21/Legacy8 ; limites et incidents conservés. |
| Build/Validation — root + Core | Studio macOSdebug PASS29.587s, MCPcheck/buildPASS ; analyses bornées, legacy global rouge prouvé baseline. |
| Critique finale — indépendante | UI25 puis Root8 lus par ac15, Core37 par UIagent, Pure8 par Coreagent. Aucun P1/P2 identifié ; Rootdelta02 seulement braces/wildcards et analyses82/82 baseline revérifiées. |

### Auto-critique, suite et Git

Cette capacité native ne convertit pas encore la porte originale. SourceMap100event8 page0 trigger1, page1 autorunTempA, Map102event1 retour Map100(13,25) puis Down(13,26), sans Through : profilv5/projection complète, état temporaire/lifetime, position/visibility/routes209-210, guides et vraie preuve originale aller/retour/save disque/Studio open-edit-save-reopen restent ouverts. Ne pas remplacer autorun par mapEnter sans équivalence source démontrée. Scripts statiques exacts lus comme oracle, jamais exécutés. Dernier échantillon original9/44événements inchangé. FG082/090/093PARTIAL,FG092TODO, roadmap inchangée. Goal AC00–16 actif et globalPARTIAL.

Yoahn autorise commit et push directement sur main. Publication79chemins prévue, sans force-push/rebase/amend/branche/worktree. Garde fraîche avant copie : HEADfc,indexvide,blobs host scope égaux àbase, fichiers nouveaux absents ; SHA/modes des changements étrangers vérifiés avant/après. L'inventaire et les reçus publication-final-01 enregistrent parent/arbre exact/index/commit/remote et checks. Hygiene0nouveauMarkdown et scoped/staged diffcheck requis avantcommit. Aucun SHA futur inventé dans ce rapport. Ticket AC13 existant, unique grand domaine PostBêta Monde & narration, Gate bêta false : tranche TOREVIEW, résultatglobalPARTIAL, DONE réservé àYoahn ; audit Source suivant reprendDOING.


## Complément AC-13 — Points d’arrivée de scène sans déclenchement automatique, 14 octobre 2026

### Audit initial, périmètre et décision

Base main `11f761ff18b67864347354f3f78c7261597d7ee7`, index vide. Les derniers travaux natifs de contact sont livrés, mais `SourceProjector.arrival()` fabrique encore une arrivée `onBump`. Placée sur la même ancre que la porte bloquante, cette arrivée est prioritaire sur le contact joueur/PNJ et peut masquer la seconde entrée. L’admission de la porte source reste fermée pendant ce raccord ; aucun script Ruby n’est exécuté.

Le nouvel enum `MapWarpTriggerMode.sceneOnly`, fil `scene_only`, représente une destination nommée de Scene. Il garde les champs du modèle courant sous forme canonique locale : `targetMapId=map.id`, `targetPos=pos`. Sa présence ne déclenche aucun transport automatique. Les deux modes actifs gardent leurs valeurs exactes ; une valeur inconnue est refusée. Aucun reader legacy, migration, IA, asset source ou nouveau drapeau de sauvegarde.

Le guide permet la création sur une carte unique. Créer, déplacer et convertir vers le mode passif normalise les coordonnées locales ; une cible explicite incohérente est refusée. Le passage du mode passif vers un mode actif exige la carte et les deux coordonnées explicitement choisies, puis une application volontaire. Les anciens facings/paddings restent conservés et inactifs en mode passif. Les points sont exclus des arêtes automatiques et opérations réciproques, tout en restant sélectionnables par leur identité dans les commandes SceneWarp.

Les huit productions Studio et deux productions legacy emploient les primitives et tokens du design system existant. Le marqueur passif et l’inspecteur indiquent « Point d’arrivée » / « Utilisé par une scène », sans destination sortante inventée, flèche ou zone de déclenchement. Aucune nouvelle abstraction n’a été créée pour contourner les erreurs monolithiques legacy.

### Inventaire exact et zones

Manifest source `publication-final-01/code-manifest-final-01.json`, SHA `431bec1ab9f613d136326b6e2960a52b7385fad5a8b7fe27ca8c27f988e7b22a`, sous la racine QA indiquée ci-dessous. Il contient les baselines, blobs, SHA, modes et hunks : 31 fichiers de code/tests, dont six nouveaux tests, +2007/-347 lignes selon le regroupement difflib du manifest ; le présent rapport existant constitue le 32e chemin. Les zones suivantes sont les hunks contre la base, pas des copies de source.

| Groupe | Chemin | Zones de diff ; ajout/retrait |
|---|---|---|
| Core | `packages/map_core/lib/src/models/map_data.dart` | @@ -509,6 +509,8 @@ ; +2/-0 |
| Core | `packages/map_core/lib/src/models/map_data.g.dart` | @@ -438,6 +438,7 @@ ; +1/-0 |
| Core | `packages/map_core/lib/src/operations/map_warps.dart` | @@ -2,6 +2,37 @@; @@ -33,12 +64,23 @@; @@ -82,14 +124,19 @@; @@ -102,8 +149,23 @@ ; +69/-7 |
| Core | `packages/map_core/lib/src/validation/validators.dart` | @@ -2823,6 +2823,12 @@ ; +6/-0 |
| Core | `packages/map_authoring/lib/src/domains/maps/warp_connection_actions.dart` | @@ -183,6 +183,7 @@; @@ -242,7 +243,7 @@; @@ -252,7 +253,7 @@; @@ -298,7 +299,8 @@; @@ -332,7 +334,9 @@; @@ -378,6 +382,7 @@; @@ -552,8 +557,21 @@; @@ -718,7 +736,7 @@; @@ -738,11 +756,40 @@; @@ -894,6 +941,7 @@ ; +55/-7 |
| Core | `packages/map_authoring/lib/src/domains/maps/world_graph_queries.dart` | @@ -180,12 +180,22 @@ ; +16/-6 |
| Core | `packages/map_core/test/scene_only_warp_operations_test.dart` | @@ -0,0 +1,164 @@ ; +164/-0 |
| Core | `packages/map_authoring/test/domains/maps/scene_only_warp_transport_test.dart` | @@ -0,0 +1,311 @@ ; +311/-0 |
| Core | `tools/pokemap_mcp/test/scene_only_warp_destination_stdio.test.ts` | @@ -0,0 +1,117 @@ ; +117/-0 |
| Pure | `packages/map_gameplay/lib/src/spatial_warp_controller.dart` | @@ -49,6 +49,7 @@ ; +1/-0 |
| Pure | `packages/map_gameplay/test/spatial_warp_controller_test.dart` | @@ -42,9 +42,13 @@; @@ -59,6 +63,37 @@ ; +38/-3 |
| Pure | `packages/map_gameplay/lib/src/validation/narrative_physical_reachability_validator.dart` | @@ -585,6 +585,7 @@; @@ -860,9 +861,13 @@ ; +8/-3 |
| Pure | `packages/map_gameplay/test/narrative_physical_reachability_validator_test.dart` | @@ -210,6 +210,57 @@ ; +51/-0 |
| UI | `apps/avelune_studio/lib/features/map_workspace/application/warp_editing_commands.dart` | @@ -47,6 +47,17 @@ ; +11/-0 |
| UI | `apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_view_state.dart` | @@ -69,6 +69,7 @@; @@ -434,7 +435,11 @@ ; +6/-1 |
| UI | `apps/avelune_studio/lib/presentation/features/map_workspace/map_warp_palette.dart` | @@ -11,54 +11,80 @@ ; +58/-32 |
| UI | `apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_panels.dart` | @@ -122,7 +122,15 @@; @@ -316,6 +324,8 @@ ; +10/-0 |
| UI | `apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_palette_dock.dart` | @@ -169,6 +169,9 @@ ; +3/-0 |
| UI | `apps/avelune_studio/lib/presentation/features/map_workspace/map_character_gesture.dart` | @@ -104,12 +104,14 @@ ; +8/-6 |
| UI | `apps/avelune_studio/lib/presentation/features/map_workspace/map_warp_inspector.dart` | @@ -4,7 +4,9 @@; @@ -28,16 +30,70 @@; @@ -64,107 +120,152 @@ ; +180/-79 |
| UI | `apps/avelune_studio/lib/presentation/features/map_workspace/map_canvas_overlay.dart` | @@ -194,7 +194,9 @@ ; +3/-1 |
| UI | `packages/map_editor/lib/src/ui/panels/warp_properties_panel.dart` | @@ -7,6 +7,8 @@; @@ -30,6 +32,7 @@; @@ -64,7 +67,7 @@; @@ -129,7 +132,8 @@; @@ -153,7 +157,9 @@; @@ -161,7 +167,9 @@; @@ -245,13 +253,19 @@; @@ -280,6 +294,7 @@; @@ -297,12 +312,19 @@; @@ -311,22 +333,41 @@; @@ -354,23 +395,31 @@; @@ -386,10 +435,12 @@; @@ -407,127 +458,126 @@; @@ -538,7 +588,7 @@; @@ -559,7 +609,7 @@; @@ -572,7 +622,7 @@; @@ -580,7 +630,7 @@; @@ -597,24 +647,27 @@; @@ -645,46 +698,44 @@; @@ -966,6 +1017,7 @@ ; +242/-190 |
| UI | `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart` | @@ -1288,13 +1288,14 @@; @@ -1331,14 +1332,25 @@ ; +20/-8 |
| UI | `apps/avelune_studio/test/map_workspace/scene_only_warp_authoring_test.dart` | @@ -0,0 +1,336 @@ ; +336/-0 |
| UI | `apps/avelune_studio/test/map_workspace/warp_editing_test.dart` | @@ -143,4 +143,21 @@ ; +17/-0 |
| UI | `apps/avelune_studio/test/map_workspace/warp_disk_journey_test.dart` | @@ -1,4 +1,5 @@; @@ -65,6 +66,43 @@ ; +38/-0 |
| UI | `apps/avelune_studio/test/presentation/scene_warp_form_test.dart` | @@ -102,6 +102,37 @@ ; +31/-0 |
| UI | `packages/map_editor/test/scene_action_builder_test.dart` | @@ -364,6 +364,43 @@ ; +37/-0 |
| Root | `packages/map_core/test/scene_only_warp_destination_test.dart` | @@ -0,0 +1,34 @@ ; +34/-0 |
| Root | `packages/map_gameplay/test/scene_only_warp_destination_contact_test.dart` | @@ -0,0 +1,51 @@ ; +51/-0 |
| Root | `packages/map_runtime/test/playable_map_game_connection_arrival_collision_test.dart` | @@ -254,6 +254,78 @@; @@ -2107,6 +2179,8 @@; @@ -2162,6 +2236,7 @@; @@ -2231,12 +2306,16 @@ ; +83/-4 |


Le modèle/génération ne conserve que l’ajout de l’enum et sa correspondance JSON. La génération filtrée a capturé 487 fichiers Core : deux sorties Freezed reformatées ont été restaurées exactement depuis leurs captures privées du même run. Le ledger de génération et les gels gardent cette preuve. Aucun barrel n’a changé. Le résolveur physique 2D comparait déjà les modes exacts ; il n’a pas été modifié. Le switch spatial et l’exploration de portée ferment explicitement le nouveau cas passif.

### Tests, transports et build sur les octets gelés

Racine de preuves : `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac13-scene-arrival-20261014-md2ntt37`. R privé : `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac16-refresh-20261014-ftgqyeej/repository`. Les reçus JSON contiennent argv, cwd, identités des descendants, hashes avant/après et SHA de logs ; leurs bytes et pins courants sont revérifiés dans `root-qualification-final-02.json`.

| Reçu | cwd relatif à R ; commande exacte | Résultat |
|---|---|---|
| `root-core-regression-final-02.json` | `packages/map_core` ; `/opt/homebrew/bin/dart test test/scene_only_warp_operations_test.dart test/scene_only_warp_destination_test.dart test/map_core_test.dart test/map_delta_validator_test.dart test/scene_warp_owner_arrival_test.dart test/map_events_test.dart --reporter expanded` | Core34 PASS ; six suites ; 1.932s ; exit0 |
| `scene-arrival-api-final-01.json` | `packages/map_authoring` ; `/opt/homebrew/bin/dart test test/domains/maps/scene_only_warp_transport_test.dart test/domains/maps/warp_connection_transaction_test.dart --reporter expanded` | API directe + JSONL20 PASS ; 3.490s ; exit0 |
| `scene-arrival-mcp-final-01.json` | `tools/pokemap_mcp` ; `node --import tsx --test --test-concurrency=1 test/scene_only_warp_destination_stdio.test.ts` | MCP live1 PASS,0 SKIP ; 9.111s ; exit0 |
| `scene-arrival-core-analyze-final-01.json` | `packages/map_core` ; `/opt/homebrew/bin/dart analyze lib/src/models/map_data.dart lib/src/models/map_data.g.dart lib/src/operations/map_warps.dart lib/src/validation/validators.dart test/scene_only_warp_operations_test.dart` | 0 erreur/warning ;3 INFO baseline ; 1.368s ; exit0 |
| `scene-arrival-api-analyze-final-01.json` | `packages/map_authoring` ; `/opt/homebrew/bin/dart analyze lib/src/domains/maps/warp_connection_actions.dart lib/src/domains/maps/world_graph_queries.dart test/domains/maps/scene_only_warp_transport_test.dart` | No issues found ; 2.597s ; exit0 |
| `scene-arrival-mcp-check-final-01.json` | `tools/pokemap_mcp` ; `npm run check` | PASS ; 1.368s ; exit0 |
| `scene-arrival-mcp-build-final-01.json` | `tools/pokemap_mcp` ; `npm run build` | PASS ; 1.356s ; exit0 |
| `scene-only-pure-consumers-green-01.json` | `packages/map_gameplay` ; `/opt/homebrew/bin/dart test test/spatial_warp_controller_test.dart test/narrative_physical_reachability_validator_test.dart test/scene_only_warp_destination_contact_test.dart --reporter expanded --concurrency=1` | Pure30 PASS, dont Root2 ; 1.918s ; exit0 |
| `scene-only-pure-consumers-analyze-01.json` | `packages/map_gameplay` ; `/opt/homebrew/bin/dart analyze lib/src/spatial_warp_controller.dart test/spatial_warp_controller_test.dart lib/src/validation/narrative_physical_reachability_validator.dart test/narrative_physical_reachability_validator_test.dart` | No issues found ; 1.623s ; exit0 |
| `root-runtime-union-final-02.json` | `packages/map_runtime` ; `flutter test --no-pub test/scene_map_instance_consequence_writer_test.dart test/playable_map_game_connection_arrival_collision_test.dart test/scene_interactive_command_runtime_executor_test.dart test/scene_actor_visibility_render_test.dart test/narrative_command_runtime_parity_test.dart test/phase_a_golden_battle_slice_smoke_test.dart test/narrative_spatial_production_dispatch_bridge_test.dart test/narrative_map_enter_production_dispatch_bridge_test.dart test/playable_map_game_qualified_outcome_v2_integration_test.dart --reporter expanded --concurrency=1` | Runtime197 PASS ; neuf suites ; 19.030s ; exit0 |
| `root-host-final-02.json` | `examples/playable_runtime_host` ; `flutter test --no-pub test/phase_a_golden_slice_launch_test.dart test/p3_narrative_smoke_slice_test.dart --reporter expanded --concurrency=1` | Host15 PASS ; deux suites ; 12.372s ; exit0 |
| `root-converter-regression-final-01.json` | `packages/avelune_converter_adapters` ; `dart test test/source_event_projection_test.dart test/source_event_study_composer_test.dart test/source_event_arrival_validation_test.dart test/native_project_writer_test.dart --concurrency=2 --reporter expanded` | Adapters128 PASS,0 SKIP ; quatre suites ; 28.202s ; exit0 |
| `root-core-model-analyze-final-02.json` | `packages/map_core` ; `dart analyze test/scene_only_warp_destination_test.dart` | No issues found ; 1.760s ; exit0 |
| `root-pure-contact-analyze-final-02.json` | `packages/map_gameplay` ; `dart analyze test/scene_only_warp_destination_contact_test.dart` | No issues found ; 1.768s ; exit0 |
| `root-runtime-test-analyze-final-02.json` | `packages/map_runtime` ; `dart analyze test/playable_map_game_connection_arrival_collision_test.dart` | No issues found ; 6.688s ; exit0 |
| `scene-only-ui-studio-final-02.json` | `apps/avelune_studio` ; `flutter test --no-pub test/map_workspace/scene_only_warp_authoring_test.dart test/map_workspace/warp_editing_test.dart test/map_workspace/warp_canvas_test.dart test/map_workspace/warp_disk_journey_test.dart test/presentation/scene_warp_form_test.dart --reporter expanded --concurrency=1` | Studio31 PASS ; cinq suites ; 15.316s ; exit0 |
| `scene-only-ui-legacy-builder-final-02.json` | `packages/map_editor` ; `flutter test --no-pub test/scene_action_builder_test.dart --reporter expanded --concurrency=1` | Legacy builder44 PASS ; 6.826s ; exit0 |
| `scene-only-ui-modern-analyze-final-02.json` | `apps/avelune_studio` ; `dart analyze lib/features/map_workspace/application/warp_editing_commands.dart lib/presentation/features/map_workspace/map_workspace_view_state.dart lib/presentation/features/map_workspace/map_warp_palette.dart lib/presentation/features/map_workspace/map_workspace_panels.dart lib/presentation/features/map_workspace/map_workspace_palette_dock.dart lib/presentation/features/map_workspace/map_character_gesture.dart lib/presentation/features/map_workspace/map_warp_inspector.dart lib/presentation/features/map_workspace/map_canvas_overlay.dart test/map_workspace/scene_only_warp_authoring_test.dart test/map_workspace/warp_editing_test.dart test/map_workspace/warp_disk_journey_test.dart test/presentation/scene_warp_form_test.dart` | No issues found ;12 fichiers ; 7.543s ; exit0 |
| `scene-only-ui-legacy-analyze-final-02.json` | `packages/map_editor` ; `dart analyze lib/src/ui/panels/warp_properties_panel.dart lib/src/ui/canvas/map_canvas/map_grid_painter.dart test/scene_action_builder_test.dart` | No issues found ;3 fichiers ; 9.412s ; exit0 |
| `root-studio-build-final-01.json` | `apps/avelune_studio` ; `flutter build macos --debug --no-pub` | Studio macOS debug PASS ; aucune fenêtre lancée ; 31.992s ; exit0 |
| `root-pmcp085-final-01.json` | `packages/map_authoring` ; `dart run tool/pmcp085_conformance.dart` | PARTIAL : catalogue complet, certification transports incomplète ; 10.525s ; exit1 |
| `root-authoring-full-parity-final-01.json` | `packages/map_authoring` ; `dart test test/parity/full_authoring_parity_test.dart --reporter expanded` | Parité20 PASS ; 20.450s ; exit0 |
| `root-mcp-conformance-final-01.json` | `tools/pokemap_mcp` ; `node --import tsx --test --test-concurrency=1 test/conformance_security.test.ts` | 5 PASS /1 FAIL ; inventaire outils attendu12, réel14 ; 11.149s ; exit1 |


Core : les trois INFO de `validators.dart:155–157` correspondent aux mêmes lignes inchangées de la baseline, aucune nouvelle erreur/warning. Les analyses Root des trois tests sont propres. Les analyses UI portent sur les octets finaux et leurs 23 pins.

Le MCP ciblé effectue réellement describe/plan/apply : création sur carte unique sans cible sortante, déplacement, refus des destinations incohérentes et transition active incomplète, puis fermeture/réouverture. L’API et JSONL qualifient les mêmes refus avant mutation, graphes et portails réciproques. Ce n’est pas une preuve par simple persistance JSON générique.

Le parcours Studio testé passe par canvas/placement, déplacement/undo/redo, garde de coordonnées négatives, comparaison raster du marqueur passif, sauvegarde réelle sur disque puis destruction/recréation du contrôleur et sélection du même point par SceneWarp moderne/legacy. Ce sont des tests Flutter de production ; aucune GUI ni capture de cette tranche n’est présentée comme acquise. Le panneau et renderer legacy ont une lecture statique et une analyse propre ; leurs widgets monolithiques restent non certifiés. Les 14 erreurs nullable de la contrecompilation fc du complément précédent restent une preuve historique, sans nouveau passage global revendiqué.

Le cycle Runtime utilise l’entrée clavier au contact, une vraie SceneWarp vers le point intérieur, un retour SceneWarp sur la porte avec propriétaire de collision, une vraie route de sortie bornée à ce propriétaire, puis un deuxième contact qui exécute une seconde scène. Il n’y a ni mock de warp ni exemption globale Through. Ce test ne comporte pas encore le programme Map100/Map102 original, sa cadence ou sa sauvegarde disque complète. Les obstacles et règles de collision précédemment qualifiés restent dans l’union197.

Les deux anciens skips adapters ont été fermés en renseignant `AVELUNE_AC13_SOURCE_SCRIPTS` avec l’archive restaurée exacte : 1080290 octets, SHA `3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d`. Lecture statique seule, pin avant/après/courant intact. L’archive n’est pas ajoutée au dépôt.

### RED, incidents et limites globales

RED fonctionnels conservés : contrat JSON Root2PASS/1FAIL, contact physique Root1PASS/1FAIL, Core opérations0PASS/5FAIL, API2PASS/8FAIL, MCP0PASS/1FAIL ; guide Studio0PASS/3FAIL puis conversion passive→active3PASS/1FAIL. Le RED consommateurs Pure est distinct :0 test exécuté, deux loadFAIL dus à un switch non exhaustif après ajout de l’enum, pas une fausse contrepreuve fonctionnelle de trajet automatique.

Le premier formatage Root a reflué des zones anciennes du gros test Runtime. Le gel01 reste historique ; le gel02 reconstruit la baseline exacte plus le nouveau test et trois zones de fixture. La requalification Runtime197 et les analyses passent sur ce gel02. L’analyse legacy initiale a également trouvé un callback nullable incompatible avec InspectorEmbeddedPrimaryCapsule : le mécanisme `enabled` du design system existant a corrigé ce défaut avant les deux finales UI02. Aucun échec, log ou reçu n’a été effacé.

La commande PMCP-085 globale retourne exit1 :88 ressources/410 actions,0 bloquée/manquante et catalogue complet, mais138 actions avec preuve end-to-end et104 entièrement certifiées seulement ; transportCertificationComplete=false. Le test de parité passe20/20. La conformance MCP passe5/6 : son test inchangé de liste fermée attend12 outils alors que le serveur expose aussi les deux outils de création de projet. Les quatre fichiers tool/test/server/parité sont byte-identiques à11f ; la même dérive d’inventaire est documentée depuis AC15. Les nouveaux contrats ciblés ne réparent ni ne certifient le catalogue entier.

Tous les reçus finaux ont leurs pins avant/après/courants exacts et aucun survivant confirmé. Les tests n’ont envoyé aucun signal. Le build a réapé par SIGTERM deux descendants ibtoold réellement observés, avec UID/date/commande revérifiés, puis zéro survivant ; aucun processus protégé touché. Aucune nouvelle fenêtre de test laissée ouverte.

### Passes indépendantes, publication et suite réelle

| Passe | Verdict |
|---|---|
| Audit / Architecture Root et ac15_connection_review_fresh | Masquage du contact par fausse arrivée automatique reproduit ; point passif distinct, Source laissée fermée. |
| Implémentation Core ac13_warp_runtime_tests / Pure ac15_connection_review_fresh / UI ac13_warp_final_review | Contrats, opérations, graphes et guides gelés ; pas de modèle d’état parallèle ni d’exécution source. |
| Tests Root et propriétaires | RED observés puis finales sur octets actuels ; Core34/API20/Pure30/Runtime197/Host15/Adapters128/Studio31/Legacy44, sans additionner les cas rejoués. |
| Build / Validation Root | Build Studio debug et check/build MCP acquis ; catalogue global PARTIAL explicitement conservé. |
| Critique Core9 par ac15_connection_review_fresh ; Pure4 par ac13_warp_runtime_tests | Revues indépendantes favorables, aucun P1/P2 trouvé dans le périmètre inspecté. |
| Critique UI15 + Root3 par ac13_warp_runtime_tests | Blobs, patches, pins et logs revérifiés ; guides, vrai disque, cycle physique et limites legacy confirmés, aucun P1/P2 trouvé. |

Gels : Core9 `f9cf398a953c750f9bf2895ebc7a5342ada3516cb508f9b5a19b0a21e558fe96` ; Pure4 `27196077d24181c116a65bb3ea553489323fde19dafbdc767cc28f82c3e92f2d` ; UI15 `2aeacc6058e94831c01562922afc95f2e767056517d1c56bc9ad22e532bd666b` ; Root3 final02 `68068e775dc20ddc12efe427e2c6913e9b8a6eda70af89fc5771af4704b99b6d`.

Le contrôle Git initial avait56 chemins étrangers ;60 sont capturés au premier contrôle de publication, les autres sessions ayant continué leurs travaux. Deux fichiers du lot chevauchent ces travaux : map_data.dart et validators.dart. Ils ne doivent pas être copiés ou stagés en entier depuis le host. La publication prépare les seules modifications propres contre11f, les fusionne avec les octets étrangers capturés et prouve par fusion inverse la restitution exacte de ces octets. L’index reçoit les blobs propres qualifiés. Les autres chemins étrangers doivent conserver leurs SHA et modes. Les reçus `publication-final-01` enregistreront l’état juste avant/après copie, index, commit et push normal, après exécution de chaque étape ; pas de force, rebase, amend, stash ou nettoyage.

Le ticket existant AC13 reste DOING/PARTIAL dans son seul grand domaine Post Bêta Monde & narration, Gate bêta false. La tranche native est proposée à revue ; aucune clôture humaine DONE ni modification de roadmap. FG082/090/093 PARTIAL, FG092 TODO. Le goal complet AC00–16 reste actif.

Auto-critique : le point d’arrivée ferme un blocage natif concret, mais n’augmente pas les9/44 événements source adaptés. SourceAdmission=false. La vraie porte exige encore l’autorun TempA=false réévaluable puis A=true hors branche d’ancre, la cadence capturée avant verrou, les attentes/yields et le déclenchement de sortie après déplacement complet, puis projectionv5 et parcours original aller/retour/save-disque/reload/Studio. L’audit source montre que mapEnter revendique une activation avant await et ne reprend pas après AuthorityBlocked/SceneFailed ; l’assimiler à un autorun perdrait le programme. La suite doit porter une vraie source entityAutorun avec attente par instance active et conditions réévaluées, sans modifier le contrat at-most-once de mapEnter ni inventer un flag de sauvegarde global.

## Complément AC-13 — Événements automatiques natifs réévaluables, 14 octobre 2026

### Résultat et frontière produit

Le moteur natif possède maintenant entityAutorun : une source automatique liée à une entité logique et à sa carte 2D. Elle attend une autorité disponible, se réévalue après un échec transactionnel et s’arrête lorsque ses conditions deviennent fausses. Le guide Automatique permet de créer et retrouver cette référence sans exiger sprite, Character, collision ou présence visuelle. La capacité native est proposée à revue ; AC-13 et le goal AC-00–16 restent PARTIAL/actifs.

La porte originale Map100/event8 et la sortie Map102/event1 ne sont pas activées par cette livraison. SourceAdmission=false ; profil/projection source inchangés, dernier échantillon original toujours 9/44 événements adaptés et 35 inactifs. Cette tranche n’est ni un aller/retour original qualifié, ni une nouvelle conversion Kanto livrée, ni une preuve GUI. Le combat garde l’autorité Avelune, zéro Ruby exécuté et zéro IA requise.

### Audit initial et décisions

QA commencée sur main be43f49e891384e63ef1d20e6dce23dd806839c9, index vide, 60 chemins étrangers. Les preuves mapEnter montrent son contrat at-most-once par activation : un chargement occupé peut clamer cette activation sans reprendre le dispatch après libération. Le contrôle normal passe et le cas occupé échoue, 1 PASS/1 FAIL ; ce constat exclut l’assimilation d’un autorun à mapEnter et ne change pas le contrat mapEnter existant.

Oracles statiques du corpus autorisé : ledge-source-audit/outputs/045.rb:170–178,237–241,258–271 (démarrage trigger3 lors de refresh/update),033.rb:62–70,124–127 (interpréteur et événements en attente). Scripts SHA3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d, lu comme données inertes. La condition source playerOnEvent reste dans la branche de scène ; le setter TempA=true situé hors branche ne doit pas disparaître lorsque le joueur est ailleurs.

Le coordinateur transactionnel, le planner, les activités et la sauvegarde d’instances existants suffisent. Aucun scheduler générique, nouveau drapeau global, modèle de sauvegarde parallèle, fallback legacy ou nouvelle primitive DS. L’allocation des instances découle de sources automatiques typées valides indépendamment de leur éligibilité courante, pour éviter la circularité A=false sans instance. Sans policy, la durée de vie est limitée à la carte active ; avec policy, la rétention existante garde ses règles. Cette règle native ne certifie pas à elle seule le MapFactory source.

Pendant la qualification, un autre chantier a poussé main5780291030d9af575bae436a02912ec93cc7a8c3 : seule packages/map_distribution/pubspec.yaml fixe image4.10.1 au lieu de ^4.2.0. Aucun des 76 chemins possédés n’est touché. Le pin est admis dans R privé ; Studio/Converter utilisaient déjà image4.10.1/archive4.0.9 et leurs package_config restent byte-exacts. Runtime/Host restent inchangés. Authoring passe offline de image4.9.2 à4.10.1 ; API, analyse, MCP, parité et contrôles globaux sont relancés. Aucun fichier de dépendance de ce chantier n’entre dans notre commit. Parent de publication attendu :5780291, sans rebase ni merge Git.

### Contrats et exécution

- Wire strict entityAutorun/mapId/entityId, callback when requis. Propriétaire logique unique connu sur une carte 2D ; custom, spawn et PNJ sans Character ou blocage restent admissibles. Les variantes contact/interaction/entrée de carte gardent leurs identités.
- Core catalogue, diagnostics, références, dépendances, simulation et résolution symbolique ferment explicitement ce nouveau cas. Aucun candidat/provenance ou fallback legacy ne l’assimile à une source physique.
- Le pump ne démarre qu’à un update, sur la carte active, avec un seul automatique en vol. Les conditions fausses ne verrouillent ni n’effacent l’entrée du joueur. Une activité, un checkpoint, une transition ou un outbox occupé laisse le candidat réévaluable.
- Après la préparation asynchrone, activation, MapInstanceRef, propriétaire et sélection sont revérifiés avant Scene. Les candidats éligibles sont départagés par priorité décroissante, ordre croissant et identifiant UTF16, tous propriétaires confondus. La Scene garde ensuite le droit d’accomplir ses propres déplacements et Warps.
- Same-map Warp conserve l’instance ; different-map Warp la recrée. Une connexion garde une instance retenue avec policy ; sans policy elle remplace le contexte active-only. Le stockage sauvegardé ne reçoit aucun marqueur de scheduler : A=false restaure une attente, A=true reste silencieux.
- Le test de reprise a découvert une vraie erreur supplémentaire : une conséquence locale déjà validée était rejouée après destruction de son scope par le propre Warp de la Scene. Le retrait porte seulement sur le MapInstanceRef complet présent avant ce Warp completed vers la carte attendue, puis absent/remplacé après. Les nouvelles écritures, Warps bloqués et changements externes restent refusés ; les autres conséquences et leurs identifiants d’opérations restent alignés par indices.
- Guides Studio et legacy : sélection Automatique, référence exacte, localisation logique, refus des retours de carte périmés, protections delete/rename et conversion3D/v9. Le journal de création physique ne fabrique pas de provenance pour l’autorun. Sauvegarde via API canonique et réouverture avec nouveaux contrôleurs vérifiées.

### Inventaire et zones

76 sources/tests, dont8 nouveaux fichiers ; +4008/-87 selon le regroupement difflib du manifest. Le présent rapport existant est le77e chemin ; aucun Markdown nouveau. Gels Core39, Pure4, UI24 et Root9 ; aucun chevauchement entre owners. Le manifest code-manifest-final-01.json contient tous les SHA de baseline/blobs, les hunks complets et les modes d’existence. Les zones ci-dessous donnent les premiers hunks ; les autres restent dans ce manifest et les patches gelés.

| Groupe | Chemin | Premières zones du diff ; ajout/retrait |
|---|---|---|
| UI | `apps/avelune_studio/lib/features/narrative/application/narrative_interaction_opener.dart` | @@ -233,6 +233,7 @@ ; +1/-0 |
| UI | `apps/avelune_studio/lib/features/narrative/application/narrative_interaction_reader.dart` | @@ -23,6 +23,7 @@ ; +1/-0 |
| UI | `apps/avelune_studio/lib/features/narrative/application/narrative_overview_context.dart` | @@ -147,6 +147,24 @@ ; +18/-0 |
| UI | `apps/avelune_studio/lib/presentation/features/events/event_context_map.dart` | @@ -120,6 +120,8 @@ ; @@ -128,14 +130,21 @@ ; +12/-3 |
| UI | `apps/avelune_studio/lib/presentation/features/events/event_labels.dart` | @@ -5,6 +5,7 @@ ; @@ -12,6 +13,7 @@ ; @@ -44,6 +46,7 @@ ; +3 hunks au manifest ; +6/-0 |
| UI | `apps/avelune_studio/lib/presentation/features/events/event_outcome_picker.dart` | @@ -59,6 +59,7 @@ ; +1/-0 |
| UI | `apps/avelune_studio/lib/presentation/features/events/event_source_identity.dart` | @@ -46,6 +46,9 @@ ; @@ -69,13 +72,23 @@ ; @@ -85,7 +98,8 @@ ; +16/-2 |
| UI | `apps/avelune_studio/lib/presentation/features/events/event_trigger_panel.dart` | @@ -112,7 +112,8 @@ ; @@ -129,6 +130,12 @@ ; +8/-1 |
| UI | `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_event_binding.dart` | @@ -119,10 +119,13 @@ ; +7/-4 |
| UI | `apps/avelune_studio/test/events/entity_autorun_authoring_test.dart` | @@ -0,0 +1,605 @@ ; +605/-0 |
| Core | `packages/map_authoring/lib/src/domains/distribution/game_package_gameplay_readiness_gate.dart` | @@ -467,6 +467,7 @@ ; +1/-0 |
| Core | `packages/map_authoring/test/domains/narrative/narrative_entity_autorun_transport_test.dart` | @@ -0,0 +1,294 @@ ; +294/-0 |
| Core | `packages/map_core/lib/map_core_domain.dart` | @@ -390,3 +390,4 @@ ; +1/-0 |
| Core | `packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart` | @@ -36,6 +36,9 @@ ; +3/-0 |
| Core | `packages/map_core/lib/src/authoring/narrative_event_source_operations_v2.dart` | @@ -480,6 +480,18 @@ ; +12/-0 |
| Core | `packages/map_core/lib/src/catalogs/narrative_event_project_catalog.dart` | @@ -195,6 +195,7 @@ ; +1/-0 |
| Core | `packages/map_core/lib/src/catalogs/narrative_spatial_event_source_catalog.dart` | @@ -146,10 +146,11 @@ ; @@ -291,6 +292,10 @@ ; @@ -314,6 +319,7 @@ ; +8/-2 |
| Core | `packages/map_core/lib/src/compatibility/legacy_map_event_projection.dart` | @@ -59,8 +59,9 @@ ; +3/-2 |
| Core | `packages/map_core/lib/src/compatibility/legacy_scenario_source_projection.dart` | @@ -460,6 +460,7 @@ ; @@ -573,6 +574,7 @@ ; @@ -770,6 +772,7 @@ ; +3/-0 |
| Core | `packages/map_core/lib/src/compatibility/narrative_event_migration_planner_impl.dart` | @@ -326,6 +326,7 @@ ; @@ -2131,6 +2132,7 @@ ; +2/-0 |
| Core | `packages/map_core/lib/src/models/narrative_event_source_ref.dart` | @@ -20,6 +20,7 @@ ; @@ -87,6 +88,8 @@ ; @@ -98,6 +101,11 @@ ; +9 hunks au manifest ; +76/-0 |
| Core | `packages/map_core/lib/src/operations/build_narrative_event_project_catalog.dart` | @@ -373,6 +373,8 @@ ; +2/-0 |
| Core | `packages/map_core/lib/src/operations/build_narrative_event_reachability_report.dart` | @@ -223,6 +223,7 @@ ; @@ -232,6 +233,7 @@ ; +2/-0 |
| Core | `packages/map_core/lib/src/operations/build_narrative_event_validation_report.dart` | @@ -279,6 +279,7 @@ ; +1/-0 |
| Core | `packages/map_core/lib/src/operations/build_narrative_outcome_event_source_catalog.dart` | @@ -634,6 +634,7 @@ ; +1/-0 |
| Core | `packages/map_core/lib/src/operations/build_narrative_spatial_event_source_catalog.dart` | @@ -11,6 +11,7 @@ ; @@ -297,6 +298,11 @@ ; @@ -314,6 +320,49 @@ ; +1 hunks au manifest ; +50/-0 |
| Core | `packages/map_core/lib/src/operations/narrative_entity_autorun_source_reference.dart` | @@ -0,0 +1,22 @@ ; +22/-0 |
| Core | `packages/map_core/lib/src/operations/narrative_event_dispatch_authority.dart` | @@ -186,7 +186,8 @@ ; @@ -241,6 +242,7 @@ ; @@ -1032,6 +1034,7 @@ ; +4/-1 |
| Core | `packages/map_core/lib/src/operations/narrative_project_validator.dart` | @@ -16,6 +16,7 @@ ; @@ -1406,6 +1407,10 @@ ; @@ -2147,6 +2152,7 @@ ; +2 hunks au manifest ; +22/-0 |
| Core | `packages/map_core/lib/src/operations/narrative_symbolic_reachability_solver.dart` | @@ -8,6 +8,7 @@ ; @@ -948,6 +949,7 @@ ; @@ -1150,6 +1152,7 @@ ; +1 hunks au manifest ; +11/-0 |
| Core | `packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart` | @@ -689,6 +689,7 @@ ; +1/-0 |
| Core | `packages/map_core/lib/src/read_models/narrative_dependency_index.dart` | @@ -25,6 +25,7 @@ ; @@ -1336,6 +1337,20 @@ ; +15/-0 |
| Core | `packages/map_core/lib/src/read_models/narrative_event_builder_project_read_model.dart` | @@ -557,6 +557,7 @@ ; @@ -1923,6 +1924,16 @@ ; +11/-0 |
| Core | `packages/map_core/lib/src/read_models/narrative_event_navigation_intent.dart` | @@ -409,6 +409,7 @@ ; @@ -422,6 +423,7 @@ ; @@ -542,6 +544,7 @@ ; +3 hunks au manifest ; +22/-0 |
| Core | `packages/map_core/lib/src/read_models/narrative_global_search_index.dart` | @@ -450,6 +450,7 @@ ; @@ -517,6 +518,7 @@ ; +2/-0 |
| Core | `packages/map_core/lib/src/read_models/narrative_map_events_read_model.dart` | @@ -462,6 +462,7 @@ ; +1/-0 |
| Core | `packages/map_core/lib/src/read_models/narrative_world_state_simulation.dart` | @@ -428,6 +428,7 @@ ; +1/-0 |
| Core | `packages/map_core/test/narrative_entity_autorun_authority_test.dart` | @@ -0,0 +1,152 @@ ; +152/-0 |
| Core | `packages/map_core/test/narrative_entity_autorun_catalog_test.dart` | @@ -0,0 +1,138 @@ ; +138/-0 |
| Core | `packages/map_core/test/narrative_entity_autorun_source_test.dart` | @@ -0,0 +1,74 @@ ; +74/-0 |
| Core | `packages/map_core/test/narrative_entity_bump_source_test.dart` | @@ -9,6 +9,7 @@ ; @@ -20,6 +21,7 @@ ; +2/-0 |
| Core | `packages/map_core/test/narrative_event_migration_integrity_closure_test.dart` | @@ -1022,6 +1022,7 @@ ; @@ -1243,6 +1244,7 @@ ; +2/-0 |
| Core | `packages/map_core/test/narrative_event_migration_planner_test.dart` | @@ -2938,6 +2938,7 @@ ; @@ -2955,6 +2956,7 @@ ; @@ -2987,6 +2989,7 @@ ; +9 hunks au manifest ; +12/-0 |
| Core | `packages/map_core/test/narrative_event_source_ref_test.dart` | @@ -17,6 +17,7 @@ ; @@ -374,6 +375,7 @@ ; +2/-0 |
| Core | `packages/map_core/test/narrative_map_events_read_model_test.dart` | @@ -42,7 +42,7 @@ ; +1/-1 |
| Core | `packages/map_core/test/narrative_spatial_event_source_catalog_test.dart` | @@ -126,7 +126,8 @@ ; @@ -134,7 +135,8 @@ ; @@ -142,7 +144,8 @@ ; +2 hunks au manifest ; +11/-7 |
| Core | `packages/map_core/test/support/f1_runtime_catalog_fixture.dart` | @@ -72,6 +72,7 @@ ; @@ -117,6 +118,7 @@ ; +2/-0 |
| Core | `packages/map_core/test/support/narrative_event_authoring_fixtures.dart` | @@ -198,6 +198,7 @@ ; +1/-0 |
| UI | `packages/map_editor/lib/src/application/models/narrative_event_spatial_link_journal_models.dart` | @@ -385,6 +385,7 @@ ; @@ -404,6 +405,7 @@ ; +2/-0 |
| UI | `packages/map_editor/lib/src/application/services/narrative_event_source_dependency_guard.dart` | @@ -116,26 +116,30 @@ ; @@ -148,7 +152,8 @@ ; @@ -244,6 +249,7 @@ ; +1 hunks au manifest ; +25/-14 |
| UI | `packages/map_editor/lib/src/application/services/narrative_event_validation_coordinator.dart` | @@ -515,6 +515,7 @@ ; +1/-0 |
| UI | `packages/map_editor/lib/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart` | @@ -875,6 +875,7 @@ ; +1/-0 |
| UI | `packages/map_editor/lib/src/application/use_cases/narrative_event_migration_preview_use_case.dart` | @@ -86,6 +86,7 @@ ; +1/-0 |
| UI | `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | @@ -3556,6 +3556,7 @@ ; @@ -3922,6 +3923,7 @@ ; @@ -3980,6 +3982,7 @@ ; +2 hunks au manifest ; +5/-0 |
| UI | `packages/map_editor/lib/src/features/narrative/state/narrative_event_map_bridge_state.dart` | @@ -2202,6 +2202,7 @@ ; @@ -2232,6 +2233,7 @@ ; +2/-0 |
| UI | `packages/map_editor/lib/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart` | @@ -1104,6 +1104,7 @@ ; @@ -1152,6 +1153,7 @@ ; +2/-0 |
| UI | `packages/map_editor/lib/src/ui/canvas/events/narrative_event_map_return_panel.dart` | @@ -250,6 +250,7 @@ ; @@ -266,6 +267,7 @@ ; +2/-0 |
| UI | `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart` | @@ -604,6 +604,7 @@ ; +1/-0 |
| UI | `packages/map_editor/lib/src/ui/canvas/narrative_validator_workspace.dart` | @@ -1337,6 +1337,7 @@ ; +1/-0 |
| UI | `packages/map_editor/test/entity_autorun_source_authoring_test.dart` | @@ -0,0 +1,255 @@ ; +255/-0 |
| UI | `packages/map_editor/test/narrative_event_explicit_source_creation_test.dart` | @@ -244,6 +244,7 @@ ; +1/-0 |
| UI | `packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart` | @@ -490,6 +490,7 @@ ; @@ -1001,6 +1002,7 @@ ; @@ -1033,6 +1035,7 @@ ; +1 hunks au manifest ; +4/-0 |
| Pure | `packages/map_gameplay/lib/src/validation/narrative_physical_reachability_validator.dart` | @@ -375,6 +375,28 @@ ; @@ -518,6 +540,11 @@ ; @@ -1021,6 +1048,7 @@ ; +28/-0 |
| Pure | `packages/map_gameplay/test/narrative_event_dispatch_planner_test.dart` | @@ -31,6 +31,69 @@ ; @@ -90,3 +153,105 @@ ; +165/-0 |
| Pure | `packages/map_gameplay/test/narrative_physical_reachability_validator_test.dart` | @@ -146,6 +146,113 @@ ; +107/-0 |
| Pure | `packages/map_gameplay/test/support/f1_runtime_catalog_fixture.dart` | @@ -70,6 +70,7 @@ ; @@ -106,6 +107,11 @@ ; +6/-0 |
| Root | `packages/map_runtime/lib/src/application/narrative_event_runtime_snapshot.dart` | @@ -170,6 +170,7 @@ ; +1/-0 |
| Root | `packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart` | @@ -2,6 +2,7 @@ ; @@ -74,18 +75,48 @@ ; @@ -105,12 +136,7 @@ ; +3 hunks au manifest ; +59/-35 |
| Root | `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | @@ -868,7 +868,8 @@ ; @@ -881,6 +882,7 @@ ; @@ -1074,6 +1076,188 @@ ; +9 hunks au manifest ; +225/-12 |
| Root | `packages/map_runtime/lib/src/spatial/spatial_gameplay_events.dart` | @@ -355,6 +355,7 @@ ; @@ -763,6 +764,7 @@ ; +2/-0 |
| Root | `packages/map_runtime/test/narrative_map_enter_production_dispatch_bridge_test.dart` | @@ -926,6 +926,7 @@ ; +1/-0 |
| Root | `packages/map_runtime/test/narrative_scene_runtime_execution_test.dart` | @@ -6,6 +6,128 @@ ; @@ -948,6 +1070,126 @@ ; +242/-0 |
| Root | `packages/map_runtime/test/narrative_spatial_production_dispatch_bridge_test.dart` | @@ -969,6 +969,17 @@ ; +11/-0 |
| Root | `packages/map_runtime/test/playable_map_game_connection_arrival_collision_test.dart` | @@ -8,6 +8,7 @@ ; @@ -17,7 +18,848 @@ ; @@ -2190,6 +3032,7 @@ ; +6 hunks au manifest ; +1101/-3 |
| Root | `packages/map_runtime/test/playable_map_game_qualified_outcome_v2_integration_test.dart` | @@ -1602,6 +1602,7 @@ ; +1/-0 |
| Core | `tools/pokemap_mcp/test/narrative_entity_autorun_stdio.test.ts` | @@ -0,0 +1,112 @@ ; +112/-0 |

### RED, incidents et limites des preuves

Les RED fonctionnels précèdent les changements : Core kind/catalogue inconnus puis quatre gardes authority/legacy/symbolique ; Pure26PASS/2FAIL sur des propriétaires derrière un mur ; guide Automatique absent, identité/map incorrectes et trois dépendances legacy manquantes ; vrai Game0PASS/4FAIL avec A restantfalse ; scope de Scene4PASS/3FAIL sur disparition/recréation/aller-retour.

Incidents conservés séparément : doubles underscores rejetés par le langage du package Pure et premier Runtime RED non exécuté ; fixture planner sans contexte project/maps ; imports de fixture UI ; tap de test hors viewport corrigé par ensureVisible ; hypothèse de test exigeant sourceRef=null après Warp alors qu’une policy recharge déjà un voisin neuf ; helper de test utilisant copyWith absent et import Dialogue oublié ; premier appel superviseur avec pins relatifs mal résolus, aucun runner démarré. Aucun de ces incidents n’est un RED fonctionnel ajouté au bilan.

L’union Runtime finale couvre36 nouveaux cas Game et7 nouveaux cas scopes dans10 suites : autorité libre/occupée, propriétaire avec/sans sprite, policy absente/présente, attente Scene/checkpoint, une exécution par update, one-shot/réutilisation, priorité/ordre/id, condition réévaluée, destruction runtime, changement de carte pendant await, branche d’ancre, same/different Warp, connexion retenue/recréée, éviction, propres mouvements/Warps, rollback puis retry, sauvegarde fichier froide Atrue/Afalse et load en session. Le test d’éviction déplace l’ancre via le hook de test ; il ne constitue pas un parcours physique original filmé.

API/JSONL/MCP prouvent discovery, upsert configuré désactivé, draft, refus typés et cold reopen ; aucune publication/activation live n’est déduite de ces transports. Le Runtime utilise de vrais événements enabled dans ses fixtures natives. Les tests widgets Studio passent par les contrôles et la sauvegarde canonique, sans prétendre à une fenêtre GUI de cette tranche.

Legacy global reste NONPASS :14 erreurs de compilation String?→String dans4 fichiers monolithiques, six erreurs d’analyse dans EditorNotifier. Les six lignes sont identiques à la baseline be43 et les trois autres fichiers identiques aux blobs historiques, preuve legacy-preexisting-errors-01.json. Le focused13PASS est distinct de l’essai13PASS/1échec de chargement.

PMCPglobal : exit1, catalogue88ressources/410actions/0manquant complet, mais certification transports incomplète138actions E2E/104complètes. Conformance MCP :5PASS/1FAIL sur une ancienne liste12outils contre14réels, incluant project_create_preview/project_create ; server/test/outil PMCP sont byte-exacts à la baseline. Aucun correctif hors scope pour masquer ces résultats. Les suites complètes de tous les packages ou du monorepo ne sont pas revendiquées.

### Vérifications exactes

Les cwd sont relatifs à R=/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac16-refresh-20261014-ftgqyeej/repository. Q=/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac13-entity-autorun-20261014-mj280w2x. root-qualification-final-02.json lie23reçus retenus, chaque commande, log SHA et pins avant/après/courants vérifiés. Les réexécutions ne sont pas additionnées. Les INFO Core70 et Root71 sont toutes ancrées sur des lignes inchangées de baseline ; aucune analyse fraîche de la baseline n’est revendiquée. Tous les runs retenus, build compris, ont zéro signal et zéro survivant possédé ; PID protégés inchangés. Aucune fenêtre ouverte.

| cwd | Commande exacte et reçu | Résultat |
|---|---|---|
| `packages/map_core` | `/opt/homebrew/bin/dart test --reporter expanded test/narrative_entity_autorun_source_test.dart test/narrative_entity_autorun_catalog_test.dart test/narrative_entity_autorun_authority_test.dart test/narrative_entity_bump_source_test.dart test/narrative_entity_bump_catalog_test.dart test/narrative_entity_bump_authority_test.dart test/narrative_event_source_ref_test.dart test/narrative_spatial_event_source_catalog_test.dart test/narrative_event_dispatch_authority_test.dart test/map_instance_dispatch_authority_test.dart test/narrative_event_migration_integrity_closure_test.dart test/narrative_event_migration_planner_test.dart test/narrative_event_source_authoring_v2_test.dart test/narrative_event_source_authoring_operations_test.dart test/narrative_dependency_index_test.dart test/narrative_event_builder_project_read_model_test.dart test/narrative_global_search_index_test.dart test/narrative_map_events_read_model_test.dart test/narrative_world_state_simulation_test.dart test/narrative_event_navigation_intent_test.dart test/narrative_project_validator_test.dart test/narrative_event_reachability_report_test.dart test/narrative_symbolic_reachability_solver_test.dart test/narrative_outcome_event_source_catalog_test.dart test/facts_world_rules_manager_read_model_test.dart test/narrative_event_activation_test.dart test/narrative_event_publication_test.dart test/narrative_event_read_deduplication_test.dart` ; `entity-autorun-core-expanded-final-02.json` | exit0, 5.096s ;370PASS |
| `packages/map_core` | `/opt/homebrew/bin/dart analyze lib/map_core_domain.dart lib/src/authoring/narrative_event_source_authoring_operations.dart lib/src/authoring/narrative_event_source_operations_v2.dart lib/src/catalogs/narrative_event_project_catalog.dart lib/src/catalogs/narrative_spatial_event_source_catalog.dart lib/src/compatibility/legacy_map_event_projection.dart lib/src/compatibility/legacy_scenario_source_projection.dart lib/src/compatibility/narrative_event_migration_planner_impl.dart lib/src/models/narrative_event_source_ref.dart lib/src/operations/build_narrative_event_project_catalog.dart lib/src/operations/build_narrative_event_reachability_report.dart lib/src/operations/build_narrative_event_validation_report.dart lib/src/operations/build_narrative_outcome_event_source_catalog.dart lib/src/operations/build_narrative_spatial_event_source_catalog.dart lib/src/operations/narrative_entity_autorun_source_reference.dart lib/src/operations/narrative_event_dispatch_authority.dart lib/src/operations/narrative_project_validator.dart lib/src/operations/narrative_symbolic_reachability_solver.dart lib/src/read_models/facts_world_rules_manager_read_model.dart lib/src/read_models/narrative_dependency_index.dart lib/src/read_models/narrative_event_builder_project_read_model.dart lib/src/read_models/narrative_event_navigation_intent.dart lib/src/read_models/narrative_global_search_index.dart lib/src/read_models/narrative_map_events_read_model.dart lib/src/read_models/narrative_world_state_simulation.dart test/narrative_entity_autorun_authority_test.dart test/narrative_entity_autorun_catalog_test.dart test/narrative_entity_autorun_source_test.dart test/narrative_event_source_ref_test.dart test/narrative_event_migration_integrity_closure_test.dart test/narrative_event_migration_planner_test.dart test/narrative_entity_bump_source_test.dart test/support/narrative_event_authoring_fixtures.dart test/support/f1_runtime_catalog_fixture.dart test/narrative_spatial_event_source_catalog_test.dart test/narrative_map_events_read_model_test.dart` ; `entity-autorun-core-analyze-final-02.json` | exit0, 2.254s ;70INFO baseline,0error/warning |
| `packages/map_authoring` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/domains/narrative/narrative_entity_autorun_transport_test.dart --reporter expanded` ; `root-entity-autorun-api-newbase-final-01.json` | exit0, 9.468s ;7PASS |
| `packages/map_authoring` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib/src/domains/distribution/game_package_gameplay_readiness_gate.dart test/domains/narrative/narrative_entity_autorun_transport_test.dart` ; `root-entity-autorun-api-analyze-newbase-final-01.json` | exit0, 3.848s ;No issues found |
| `tools/pokemap_mcp` | `npm run check` ; `entity-autorun-mcp-check-final-01.json` | exit0, 1.469s |
| `tools/pokemap_mcp` | `npm run build` ; `entity-autorun-mcp-build-final-01.json` | exit0, 1.586s ;PASS |
| `tools/pokemap_mcp` | `node --import tsx --test --test-concurrency=1 test/narrative_entity_autorun_stdio.test.ts` ; `root-entity-autorun-mcp-newbase-final-01.json` | exit0, 11.644s ;1PASS |
| `packages/map_gameplay` | `/opt/homebrew/bin/dart test test/narrative_physical_reachability_validator_test.dart test/narrative_event_dispatch_planner_test.dart test/narrative_event_execution_coordinator_test.dart test/narrative_event_dispatch_truth_table_test.dart --reporter expanded --concurrency 1` ; `entity-autorun-pure-regressions-final-02.json` | exit0, 2.805s ;39PASS |
| `packages/map_gameplay` | `/opt/homebrew/bin/dart analyze lib/src/validation/narrative_physical_reachability_validator.dart test/narrative_physical_reachability_validator_test.dart test/support/f1_runtime_catalog_fixture.dart test/narrative_event_dispatch_planner_test.dart` ; `entity-autorun-pure-analyze-final-02.json` | exit0, 2.034s ;No issues found |
| `apps/avelune_studio` | `flutter test --no-pub test/events/entity_autorun_authoring_test.dart test/events/entity_bump_authoring_test.dart test/events/event_sources_ui08_test.dart --reporter expanded --concurrency=1` ; `entity-autorun-ui-studio-final-02.json` | exit0, 15.458s ;33PASS |
| `packages/map_editor` | `flutter test --no-pub test/entity_autorun_source_authoring_test.dart test/entity_bump_source_authoring_test.dart --reporter expanded --concurrency=1` ; `entity-autorun-ui-legacy-focused-green-01.json` | exit0, 5.029s ;13PASS |
| `apps/avelune_studio` | `dart analyze lib/features/narrative/application/narrative_interaction_opener.dart lib/features/narrative/application/narrative_interaction_reader.dart lib/features/narrative/application/narrative_overview_context.dart lib/presentation/features/events/event_labels.dart lib/presentation/features/events/event_outcome_picker.dart lib/presentation/features/events/event_context_map.dart lib/presentation/features/events/event_source_identity.dart lib/presentation/features/events/event_trigger_panel.dart lib/presentation/features/map_workspace/workspace_event_binding.dart test/events/entity_autorun_authoring_test.dart` ; `entity-autorun-ui-modern-analyze-01.json` | exit0, 6.879s ;No issues found |
| `packages/map_editor` | `dart analyze lib/src/application/models/narrative_event_spatial_link_journal_models.dart lib/src/application/services/narrative_event_source_dependency_guard.dart lib/src/application/services/narrative_event_validation_coordinator.dart lib/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart lib/src/application/use_cases/narrative_event_migration_preview_use_case.dart lib/src/features/editor/state/editor_notifier.dart lib/src/features/narrative/state/narrative_event_map_bridge_state.dart lib/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart lib/src/ui/canvas/events/narrative_event_map_return_panel.dart lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart lib/src/ui/canvas/narrative_validator_workspace.dart test/narrative_event_explicit_source_creation_test.dart test/selbrume_canonical_narrative_seed_test.dart test/entity_autorun_source_authoring_test.dart` ; `entity-autorun-ui-legacy-analyze-01.json` | exit3, 9.305s ;6erreurs baseline, NONPASS |
| `packages/map_editor` | `flutter test --no-pub test/entity_autorun_source_authoring_test.dart test/entity_bump_source_authoring_test.dart test/narrative_event_source_dependency_guard_test.dart --reporter expanded --concurrency=1` ; `entity-autorun-ui-legacy-green-01.json` | exit1, 14.469s ;13PASS/1loadFAIL(14erreurs baseline) |
| `packages/map_runtime` | `/opt/homebrew/share/flutter-3.47.5/bin/flutter test --no-pub --concurrency=1 test/scene_map_instance_consequence_writer_test.dart test/playable_map_game_connection_arrival_collision_test.dart test/scene_interactive_command_runtime_executor_test.dart test/scene_actor_visibility_render_test.dart test/narrative_command_runtime_parity_test.dart test/phase_a_golden_battle_slice_smoke_test.dart test/narrative_spatial_production_dispatch_bridge_test.dart test/narrative_map_enter_production_dispatch_bridge_test.dart test/playable_map_game_qualified_outcome_v2_integration_test.dart test/narrative_scene_runtime_execution_test.dart --reporter expanded` ; `root-entity-autorun-runtime-union-final-01.json` | exit0, 26.417s ;259PASS |
| `packages/map_runtime` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib/src/presentation/flame/playable_map_game.dart lib/src/application/narrative_event_runtime_snapshot.dart lib/src/spatial/spatial_gameplay_events.dart test/playable_map_game_qualified_outcome_v2_integration_test.dart test/narrative_map_enter_production_dispatch_bridge_test.dart test/narrative_spatial_production_dispatch_bridge_test.dart test/playable_map_game_connection_arrival_collision_test.dart lib/src/application/narrative_scene_runtime_execution.dart test/narrative_scene_runtime_execution_test.dart` ; `root-entity-autorun-analyze-final-01.json` | exit0, 7.300s ;71INFO baseline,0error/warning |
| `examples/playable_runtime_host` | `/opt/homebrew/share/flutter-3.47.5/bin/flutter test --no-pub --concurrency=1 test/phase_a_golden_slice_launch_test.dart test/p3_narrative_smoke_slice_test.dart --reporter expanded` ; `root-entity-autorun-host-final-01.json` | exit0, 10.221s ;15PASS |
| `packages/avelune_converter_adapters` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/source_event_projection_test.dart test/source_event_study_composer_test.dart test/source_event_arrival_validation_test.dart test/native_project_writer_test.dart --concurrency=2 --reporter expanded` ; `root-entity-autorun-converter-final-01.json` | exit0, 21.854s ;128PASS |
| `packages/map_authoring` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/parity/full_authoring_parity_test.dart --reporter expanded` ; `root-entity-autorun-full-parity-newbase-final-01.json` | exit0, 25.526s ;20PASS |
| `packages/map_authoring` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart run tool/pmcp085_conformance.dart` ; `root-entity-autorun-pmcp085-newbase-final-01.json` | exit1, 9.781s ;88/410/0manquant ;transportsfalse138/104 |
| `tools/pokemap_mcp` | `node --import tsx --test --test-concurrency=1 test/conformance_security.test.ts` ; `root-entity-autorun-conformance-newbase-final-01.json` | exit1, 10.695s ;5PASS/1FAIL12vs14 |
| `apps/avelune_studio` | `/opt/homebrew/share/flutter-3.47.5/bin/flutter build macos --debug --no-pub` ; `root-entity-autorun-studio-build-final-01.json` | exit0, 27.726s ;PASS |
| `packages/map_authoring` | `/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart pub get --offline` ; `root-authoring-newbase-pubget-01.json` | exit0, 0.835s ;image4.9.2→4.10.1 offline |

### Revues et passes

- Audit/Architecture : Root et relecture Pure confirment les frontières mapEnter/autorun, instance logique et réutilisation des transactions existantes.
- Implémentation : Core/Authoring/MCP39 par ac13_warp_runtime_tests, Pure4 par ac15_connection_review_fresh, UI24 par ac13_warp_final_review, Runtime9 par Root ; scopes gelés distincts.
- Tests : RED/GREEN par chaque owner ; Root vérifie directement les23reçus, SHA/log/pins et les76blobs courants. Root259, Host15 et Converter128 ne valent pas conversion complète.
- Build/Validation : build Studio macOS debug PASS,27.726s ; hygiène et publication sont gardées par les reçus ci-dessous.
- Critique indépendante : UI relit Core39, Core relit Pure4 et UI24 (dont Modern33 final02), Pure relit Root9 et ferme le P2 propre Warp. Tous favorables et bornés, aucun P1/P2 restant identifié ; pas d’autocertification par l’owner.

### Publication, auto-critique et suite

Publication explicitement demandée par Yoahn : commit ciblé des77chemins puis push normal du SHA sur main. Avant copie : main5780291, index vide et61changements étrangers SHA/modes sauvegardés dans publication-final-01/foreign-before-02.json. Aucun de ces chemins n’appartient au scope ; aucune restauration/stash/rebase/amend/force. Les contrôles copy/staged/precommit/commit-after/push sous cette racine enregistrent le SHA effectif, le scope, les61étrangers et l’état local/distant/index. Ces reçus sont la preuve terminale Git, sans hash autoréférentiel dans le rapport commité.

Auto-critique : la quantité de tests ne modifie pas la couverture source9/44. Le nouveau déclencheur natif ferme une dépendance concrète de la porte originale, mais son binding source, cadence capturée avant verrou, yields/attentes106/209/210 et sortie après fin du pas restent à qualifier. Puis viennent le profil/projectionv5 et le vrai parcours original entrée→sortie→réentrée/save disque/reload/Studio open-edit-save-reopen. SourceAdmission=false jusqu’à cette preuve. Ni 3D, ni parité temporelle/acoustique globale, ni import arbitraire Essentials100% annoncés.

Notion : ticket AC-13 existant3f7197a7-bfa5-81da-b5b9-c551c806e2ce, domaine Post Bêta Monde & narration, Gate bêtafalse ; composant natif proposé à revue, ticket global DOING/PARTIAL. FG082/090/093 restentPARTIAL,FG092TODO, roadmap inchangée. Le goal AC00–16 reste actif.

## Complément AC-13 — Attentes et cadence des scènes 2D, 14 octobre 2026

### Résultat, audit et frontière de livraison

La tranche native ajoute Scene.wait et le yield explicite des directions, puis retarde triggerEnter jusqu’à la fin physique du pas ou du saut. Le joueur ne peut pas sauvegarder au milieu de l’attente ; les routes NPC et le Tone indépendants continuent. Wait, Tone et SE sont réservés explicitement aux projets 2D dans les guides, diagnostics et transports. Cette livraison est proposée à revue ; AC-13 et le goal AC-00–16 restent DOING/PARTIAL. Elle n’admet pas les portes source originales et ne modifie pas le dernier échantillon publié de 9/44 événements adaptés, 35 inactifs. SourceAdmission=false. Combat Avelune, zéro Ruby exécuté et zéro IA requise.

Audit initial : main e7f89f8769111b9fbcd45c597bb1d4c8b8214b46, index vide ; 70 chemins étrangers au contrôle avant préparation du rapport. Les owners travaillent dans R privé, sans Git. Le report précédent et les modèles/handlers existants sont relus ; Core, Pure, Runtime, guides et API/MCP restent séparés. La consigne humaine sans commentaires prime sur la règle Codex contradictoire ; aucun commentaire de code ni nouveau Markdown ajouté.

Oracle source corrigé : pour les deux portes originales à pied, les pas forcés héritent 250 ms après arrêt/annulation des véhicules, y compris après course ; aucune API dynamique 125 ms n’est requise pour ce template. Sources inertes 044.rb:110–123,046.rb:94–98,500–510,032.rb:72–81,165–170 ; archive Scripts SHA3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d. Wait106 et attente de route utilisent /20.0 (034.rb:383–386,044.rb:475–477) : huit unités donnent400ms. Une direction source rend la main à une invocation de route ; elle ne prouve pas nécessairement une frame Graphics entière. Le nouveau yield natif signifie exactement prochain update, sans inventer50ms. L’équivalence de lecture originale, la barrière globale210 et le pas bloqué/skippable restent des qualifications distinctes.

### Contrats, consommateurs et cas couverts

- SceneWaitInteractiveCommand : entier0…2147483647, grammaire fermée, un port completed, Scene world2D. Attente nulle immédiate ; attente positive sur horloge Runtime, verrou distinct, interlock save/load et interruption propre à la fermeture.
- SceneActorFaceStep.yieldAfter : bool strict, false par défaut et omis du wire lorsqu’il est faux ; direction → prochain update → maintien → étape suivante. La fermeture pendant le yield empêche les effets suivants ; les erreurs ne sont pas avalées par skippable.
- Le drain des triggerEnter attend la fin de stepping/jumping, conserve la file et ses gardes d’activation. Les tests utilisent marche et course réelles, y compris un atlas64px avec clips de course.
- Guides Studio et legacy, catalogue et métadonnées API : durée, yield et borne2D découvrables. Une commande existante incompatible reste conservée comme brouillon sans Apply. Refus3D canonique de Wait/Tone/SE prouvé avant écriture via set/upsert/graph.patch ; aucune suppression implicite d’arête.
- Direct API, JSONL et MCP stdio réels : mutation, refus et réouverture froide. Les tests widgets ne sont pas une fenêtre GUI ni un parcours original Source.

### Inventaire et zones exactes

33 fichiers code/tests existants ; +1364/-43 selon le diff consolidé. Ce rapport existant est le34e chemin. Le manifest externe conserve tous les hunks complets, baselines, SHA et blobs. Les chemins ci-dessous et le diff Git sont les sources canoniques.

| Chemin | Zones du diff | Ajout/retrait |
|---|---|---|
| `apps/avelune_studio/lib/presentation/features/scenes/scene_action_form.dart` | @@ -40,6 +40,8 @@ ; @@ -61,6 +63,11 @@ ; @@ -160,6 +167,8 @@ ; @@ -199,7 +208,8 @@ ; @@ -423,6 +433,7 @@ | +12/-1 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_actor_action_form.dart` | @@ -301,6 +301,7 @@ ; @@ -549,6 +550,14 @@ ; @@ -600,7 +609,7 @@ ; @@ -610,6 +619,7 @@ ; @@ -654,5 +664,6 @@ | +12/-1 |
| `apps/avelune_studio/test/presentation/scene_actor_action_form_test.dart` | @@ -212,6 +212,29 @@ | +23/-0 |
| `apps/avelune_studio/test/presentation/scene_world_presentation_form_test.dart` | @@ -129,6 +129,40 @@ ; @@ -465,7 +499,8 @@ | +36/-1 |
| `packages/map_authoring/lib/src/domains/narrative/scene_actions.dart` | @@ -38,7 +38,19 @@ ; @@ -51,6 +63,7 @@ ; @@ -74,13 +87,14 @@ ; @@ -102,6 +116,8 @@ ; @@ -137,6 +153,9 @@ ; @@ -155,6 +174,7 @@ ; @@ -197,6 +217,7 @@ | +22/-1 |
| `packages/map_authoring/test/domains/narrative/scene_actor_route_transport_test.dart` | @@ -62,7 +62,7 @@ ; @@ -110,6 +110,18 @@ | +13/-1 |
| `packages/map_authoring/test/domains/narrative/scene_world_presentation_transport_test.dart` | @@ -28,7 +28,7 @@ ; @@ -38,6 +38,20 @@ ; @@ -50,6 +64,8 @@ ; @@ -94,6 +110,101 @@ ; @@ -275,11 +386,12 @@ ; @@ -293,12 +405,14 @@ | +119/-5 |
| `packages/map_core/lib/src/authoring/scene_command_payload_builder.dart` | @@ -139,6 +139,7 @@ ; @@ -225,6 +226,13 @@ | +8/-0 |
| `packages/map_core/lib/src/diagnostics/narrative_command_diagnostics.dart` | @@ -1,4 +1,5 @@ ; @@ -62,6 +63,17 @@ | +12/-0 |
| `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` | @@ -58,6 +58,7 @@ ; @@ -1112,6 +1113,22 @@ | +17/-0 |
| `packages/map_core/lib/src/models/scene_actor_route.dart` | @@ -61,6 +61,7 @@ ; @@ -83,13 +84,17 @@ ; @@ -134,10 +139,15 @@ ; @@ -145,14 +155,16 @@ | +18/-6 |
| `packages/map_core/lib/src/models/scene_interactive_command.dart` | @@ -9,6 +9,7 @@ ; @@ -49,6 +50,9 @@ ; @@ -147,6 +151,8 @@ ; @@ -352,6 +358,41 @@ | +41/-0 |
| `packages/map_core/lib/src/read_models/narrative_command_catalog.dart` | @@ -16,6 +16,7 @@ ; @@ -436,6 +437,24 @@ ; @@ -445,7 +464,7 @@ ; @@ -472,7 +491,7 @@ | +21/-2 |
| `packages/map_core/test/narrative_command_catalog_closure_test.dart` | @@ -24,6 +24,7 @@ ; @@ -92,6 +93,7 @@ | +2/-0 |
| `packages/map_core/test/narrative_command_contract_parity_test.dart` | @@ -231,6 +231,9 @@ ; @@ -238,6 +241,14 @@ | +11/-0 |
| `packages/map_core/test/scene_actor_route_test.dart` | @@ -20,6 +20,36 @@ | +30/-0 |
| `packages/map_core/test/scene_world_presentation_command_test.dart` | @@ -4,6 +4,89 @@ | +83/-0 |
| `packages/map_editor/lib/src/application/services/narrative_template_catalog.dart` | @@ -413,6 +413,11 @@ ; @@ -579,7 +584,8 @@ | +7/-1 |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart` | @@ -106,6 +106,11 @@ ; @@ -114,7 +119,9 @@ ; @@ -133,6 +140,10 @@ ; @@ -151,14 +162,21 @@ ; @@ -358,7 +376,8 @@ ; @@ -386,6 +405,7 @@ ; @@ -417,6 +437,8 @@ ; @@ -471,6 +493,13 @@ | +33/-4 |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_actor_action_builder.dart` | @@ -297,6 +297,7 @@ ; @@ -597,6 +598,14 @@ ; @@ -651,7 +660,7 @@ ; @@ -661,6 +670,7 @@ ; @@ -705,6 +715,7 @@ | +12/-1 |
| `packages/map_editor/test/narrative_template_catalog_test.dart` | @@ -3,6 +3,36 @@ | +30/-0 |
| `packages/map_editor/test/scene_action_builder_test.dart` | @@ -8,6 +8,55 @@ ; @@ -1213,6 +1262,8 @@ ; @@ -1228,6 +1279,8 @@ ; @@ -1258,7 +1311,8 @@ | +55/-1 |
| `packages/map_editor/test/scene_actor_action_builder_test.dart` | @@ -213,6 +213,29 @@ | +23/-0 |
| `packages/map_gameplay/lib/src/actor_route_executor.dart` | @@ -7,6 +7,7 @@ ; @@ -34,6 +35,12 @@ | +7/-0 |
| `packages/map_gameplay/test/actor_route_executor_test.dart` | @@ -49,6 +49,9 @@ ; @@ -179,6 +182,92 @@ ; @@ -336,3 +425,11 @@ | +97/-0 |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_interactive_command_runtime_executor.dart` | @@ -26,6 +26,7 @@ ; @@ -43,6 +44,7 @@ ; @@ -95,6 +97,10 @@ | +6/-0 |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | @@ -707,6 +707,7 @@ ; @@ -874,6 +875,7 @@ ; @@ -918,6 +920,7 @@ ; @@ -2949,6 +2952,9 @@ ; @@ -4152,7 +4158,7 @@ ; @@ -5437,7 +5443,9 @@ ; @@ -10897,6 +10905,8 @@ ; @@ -11580,15 +11590,18 @@ ; @@ -11603,7 +11616,7 @@ ; @@ -11918,6 +11931,8 @@ ; @@ -11968,6 +11983,42 @@ | +56/-5 |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game_support.dart` | @@ -690,6 +690,7 @@ ; @@ -705,6 +706,7 @@ ; @@ -725,6 +727,8 @@ | +4/-0 |
| `packages/map_runtime/test/narrative_command_runtime_parity_test.dart` | @@ -154,6 +154,7 @@ ; @@ -398,6 +399,7 @@ | +2/-0 |
| `packages/map_runtime/test/playable_map_game_connection_arrival_collision_test.dart` | @@ -105,6 +105,353 @@ ; @@ -3023,6 +3370,7 @@ ; @@ -3040,6 +3388,7 @@ ; @@ -3080,6 +3429,7 @@ ; @@ -3179,7 +3529,7 @@ ; @@ -3193,6 +3543,7 @@ ; @@ -3263,7 +3614,8 @@ ; @@ -3318,6 +3670,31 @@ ; @@ -3945,7 +4322,8 @@ | +381/-3 |
| `packages/map_runtime/test/scene_interactive_command_runtime_executor_test.dart` | @@ -1,3 +1,5 @@ ; @@ -14,6 +16,7 @@ ; @@ -33,6 +36,7 @@ ; @@ -82,6 +86,7 @@ ; @@ -89,6 +94,80 @@ ; @@ -231,13 +310,19 @@ ; @@ -255,9 +340,17 @@ | +95/-2 |
| `tools/pokemap_mcp/test/scene_actor_route_stdio.test.ts` | @@ -45,7 +45,7 @@ ; @@ -143,6 +143,9 @@ ; @@ -216,6 +219,9 @@ | +7/-1 |
| `tools/pokemap_mcp/test/scene_world_presentation_stdio.test.ts` | @@ -35,7 +35,7 @@ ; @@ -84,17 +84,27 @@ ; @@ -103,9 +113,10 @@ ; @@ -123,13 +134,64 @@ | +69/-7 |

### Vérifications terminales

R=/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac16-refresh-20261014-ftgqyeej/repository ; Q=/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac13-source-door-timing-20261014-83ui2yih. Les19reçus retenus ont leurs logs rehashés et pins avant/après/courants exacts, aucun timeout ni survivant, PID protégés inchangés. Le build Studio de production utilise lib/main.dart. Le harness Marionette privé et le futur test du programme original sont exclus de ce commit. Les sources bootstrap/Source privées présentes dans R restent également hors scope et non revendiquées comme livrées.

| Reçu ; cwd relatif à R | Commande exacte | Résultat |
|---|---|---|
| `native-timing-2d-presentation-core-green-02.json` ; `packages/map_core` | `dart test test/scene_world_presentation_command_test.dart test/scene_actor_route_test.dart test/narrative_command_catalog_closure_test.dart test/narrative_command_contract_parity_test.dart` | exit0, 1.646s ; 51PASS |
| `native-timing-2d-presentation-core-analyze-01.json` ; `packages/map_core` | `dart analyze lib/src/models/scene_interactive_command.dart lib/src/models/scene_actor_route.dart lib/src/read_models/narrative_command_catalog.dart lib/src/authoring/scene_command_payload_builder.dart lib/src/diagnostics/scene_diagnostics.dart lib/src/diagnostics/narrative_command_diagnostics.dart test/scene_world_presentation_command_test.dart test/scene_actor_route_test.dart test/narrative_command_catalog_closure_test.dart test/narrative_command_contract_parity_test.dart` | exit0, 1.385s ; No issues found |
| `native-timing-2d-presentation-api-green-01.json` ; `packages/map_authoring` | `dart test test/domains/narrative/scene_world_presentation_transport_test.dart test/domains/narrative/scene_actor_route_transport_test.dart` | exit0, 6.328s ; 42PASS |
| `native-timing-2d-presentation-api-analyze-01.json` ; `packages/map_authoring` | `dart analyze lib/src/domains/narrative/scene_actions.dart test/domains/narrative/scene_world_presentation_transport_test.dart test/domains/narrative/scene_actor_route_transport_test.dart` | exit0, 1.693s ; No issues found |
| `native-timing-2d-presentation-studio-green-01.json` ; `apps/avelune_studio` | `flutter test --no-pub test/presentation/scene_world_presentation_form_test.dart test/presentation/scene_actor_action_form_test.dart` | exit0, 13.911s ; 50PASS |
| `native-timing-2d-presentation-studio-analyze-01.json` ; `apps/avelune_studio` | `flutter analyze --no-pub lib/presentation/features/scenes/scene_action_form.dart lib/presentation/features/scenes/scene_actor_action_form.dart test/presentation/scene_world_presentation_form_test.dart test/presentation/scene_actor_action_form_test.dart` | exit0, 4.864s ; No issues found |
| `native-timing-2d-presentation-legacy-green-01.json` ; `packages/map_editor` | `flutter test --no-pub test/scene_action_builder_test.dart test/scene_actor_action_builder_test.dart test/narrative_template_catalog_test.dart` | exit0, 11.263s ; 111PASS |
| `native-timing-2d-presentation-legacy-analyze-01.json` ; `packages/map_editor` | `flutter analyze --no-pub lib/src/ui/canvas/scenes/scene_action_builder.dart lib/src/ui/canvas/scenes/scene_actor_action_builder.dart lib/src/application/services/narrative_template_catalog.dart test/scene_action_builder_test.dart test/scene_actor_action_builder_test.dart test/narrative_template_catalog_test.dart` | exit0, 4.845s ; No issues found |
| `native-timing-2d-presentation-mcp-check-01.json` ; `tools/pokemap_mcp` | `npm run check` | exit0, 1.462s |
| `native-timing-2d-presentation-mcp-build-01.json` ; `tools/pokemap_mcp` | `npm run build` | exit0, 1.438s |
| `native-timing-2d-presentation-mcp-stdio-green-01.json` ; `tools/pokemap_mcp` | `node --import tsx --test --test-concurrency=1 test/scene_world_presentation_stdio.test.ts test/scene_actor_route_stdio.test.ts` | exit0, 20.299s |
| `root-runtime-union-final-04.json` ; `packages/map_runtime` | `flutter test --no-pub --concurrency=1 test/scene_map_instance_consequence_writer_test.dart test/playable_map_game_connection_arrival_collision_test.dart test/scene_interactive_command_runtime_executor_test.dart test/scene_actor_visibility_render_test.dart test/narrative_command_runtime_parity_test.dart test/phase_a_golden_battle_slice_smoke_test.dart test/narrative_spatial_production_dispatch_bridge_test.dart test/narrative_map_enter_production_dispatch_bridge_test.dart test/playable_map_game_qualified_outcome_v2_integration_test.dart test/narrative_scene_runtime_execution_test.dart test/player_component_test.dart --reporter expanded` | exit0, 22.772s ; 280PASS |
| `root-analyze-final-03.json` ; `packages/map_runtime` | `dart analyze lib/src/presentation/flame/playable_map_game.dart lib/src/presentation/flame/playable_map_game_support.dart lib/src/application/scene_runtime/scene_interactive_command_runtime_executor.dart test/playable_map_game_connection_arrival_collision_test.dart test/narrative_command_runtime_parity_test.dart test/scene_interactive_command_runtime_executor_test.dart` | exit0, 6.425s ; 6INFO sur lignes baseline,0error/warning |
| `root-host-timing-final-01.json` ; `examples/playable_runtime_host` | `flutter test --no-pub --concurrency=1 test/phase_a_golden_slice_launch_test.dart test/p3_narrative_smoke_slice_test.dart --reporter expanded` | exit0, 9.728s ; 15PASS |
| `root-pure-timing-final-01.json` ; `packages/map_gameplay` | `dart test test/actor_route_executor_test.dart --reporter expanded` | exit0, 2.049s ; 24PASS |
| `root-pure-timing-analyze-final-01.json` ; `packages/map_gameplay` | `dart analyze lib/src/actor_route_executor.dart test/actor_route_executor_test.dart` | exit0, 1.209s ; No issues found |
| `root-full-authoring-parity-final-01.json` ; `packages/map_authoring` | `dart test test/parity/full_authoring_parity_test.dart --reporter expanded` | exit0, 18.54s ; 20PASS |
| `root-pmcp085-final-01.json` ; `packages/map_authoring` | `dart run tool/pmcp085_conformance.dart` | exit1, 8.29s ; catalogue88/410/0manquant, transports138/104, certificationfalse |
| `root-studio-production-build-final-01.json` ; `apps/avelune_studio` | `flutter build macos --debug --no-pub --target lib/main.dart` | exit0, 29.702s ; build Studio macOS debug PASS |

### Contrepreuves, revues et limites

RED fonctionnels : Warp triggerEnter avant fin du pas ; Wait sans consommateur ; face sans yield ; durée de maintien démarrant trop tôt. P2 trouvé par revue indépendante : Wait proposé en3D sans handler spatial ; la même cause existait pour Tone/SE introduits auparavant. RED Core/API/Studio/legacy/MCP puis gardes2D et brouillons conservés. Les compilations de fixture incorrecte, finder --plain-name avec pipe littéral, atlas32px ne permettant pas la vraie course, camera3D manquante et fenêtre de compilation du bootstrap privé restent des incidents distincts, pas des RED fonctionnels.

Une régression de timing de test a été observée sans changement de code : union03=279PASS/1timeout dans qualified outcome (activation encore en vol, helper360tours Duration.zero). Isolé=1PASS6.351s puis union04complet=280PASS22.772s sur les mêmes blobs. La cause de ce timeout intermittent n’est pas établie ; aucun ajustement du produit ou du délai de test n’a été ajouté pour le masquer. Les reruns ne sont pas additionnés.

Audit/Architecture : Root et peer distinguent attente monde, route acteur et fin de déplacement. Implémentation : Core/Authoring/UI/MCP25 par ac15_connection_review_fresh, Pure2+RuntimeTest1 par ac13_warp_runtime_tests, Runtime5 par Root. Tests : RED/GREEN owners puis requalification Root280/Pure24/Host15/parité20. Build/Validation : production Studio debug29.702s ; harness privé debug40.047s hors livrable, deux ibtoold descendants possédés terminés proprement, zéro survivant. Critique : Root5 et Pure3 relus indépendamment favorablement ; Core25 final02 relu indépendamment par ac13_warp_runtime_tests : favorable borné, aucun P1/P2 restant ; P2 Wait/Tone/SE3D fermé. Reçu independent-review-final-01.json SHA21c82b93d5a6c4316e8c3ce5b6faed8500c78cf766148c4205cf4fe9beec3713.

PMCPglobal reste NONPASS pour certification transports incomplète, malgré catalogue complet. La dernière conformance globale MCP documentée reste5PASS/1FAIL sur12outils attendus contre14réels ; elle n’est pas relancée dans cette tranche et n’est pas annoncée verte. Legacy ciblé111PASS et analyse6 fichiers sans issue ne certifient pas les anciens monolithes legacy globalement rouges. Le serveur Flame docs ne renvoie aucun résultat pour la recherche de cycle de vie ; version installée2.0.0-dev.1 et usages existants consultés. Aucune suite complète monorepo ni nouvelle CI coûteuse revendiquée.

### Publication et auto-critique

Publication directe sur main explicitement autorisée : seuls les33blobs qualifiés et ce rapport doivent être copiés/stagés puis committés et poussés normalement. native-timing-publication-01 conserve l’inventaire exact, les SHA étrangers juste avant/après, l’index et les contrôles précommit/commit/push ; aucun force, rebase, amend, stash, branche ou nettoyage étranger. La racine de travail reste sale pour les travaux d’autres sessions. Les reçus de publication contiennent le SHA réellement créé, sans hash autoréférentiel dans ce document.

Auto-critique : ce sont des prérequis natifs utiles, pas encore le résultat final du convertisseur. Le nouveau writer/profil Source v5 et le raccord typé de rétention sont encore privés. La matérialisation contrôlée Literal→Semantic→Events→NativeWriter des trois cartes originales vient de passer en674.139s, verified=true/sourceAdmission=false ; elle est privée et exclue de ce commit. Le workflow complet reste séparément bloqué par json.textQuota dans la tranche Catalogue/agrégation. Il reste à vérifier le programme original entrée→sortie→réentrée, sauver sur disque, reprendre dans un nouveau processus et ouvrir/modifier/sauver/rouvrir dans Studio. L’admission générale d’une barrière210 ou d’un déplacement skippable bloqué n’est pas prouvée par les tests natifs. AC-13 DOING/PARTIAL, ticket existant3f7197a7-bfa5-81da-b5b9-c551c806e2ce dans Post Bêta Monde & narration, Gate bêtafalse. FG082/090/093 PARTIAL, FG092 TODO dans la roadmap inchangée ; le goal AC00–16 reste actif.
