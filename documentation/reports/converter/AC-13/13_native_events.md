# AC-13 — Sous-ensemble d’événements natifs

## Verdict et portée de la revue

Implémentation livrée pour revue, avec trois traces EV-A/B/C converties depuis des fichiers RMXP originaux synthétiques, relues strictement au format natif, exécutées par le vrai runtime puis sauvegardées et chargées par une nouvelle instance de `FileGameSaveRepository`. Le domaine reste PARTIAL : la conversion de jeu entier, les événements Kanto et la parité de toute instruction Essentials ne sont pas certifiés.


État actuel au 14 octobre : voir les derniers compléments « Présentation native 2D », « Lecture du programme original de la porte » et « Routes natives finies et visibilité visuelle ». Tone/SE et les ports actorRoute/actorVisibility sont raccordés et testés dans le Player2D ; l’IR v4 reconnaît le programme original entier. La projection source des routes, la condition de position, l’état d’instance et l’arrivée propriétaire restent à qualifier. Les portes source restent inactives. L’éditeur des nouvelles routes reste unsupported. Les anciennes copies QA et captures absentes ne constituent pas des projets disponibles. Les livraisons initiales ci-dessous sont historiques. Domaine PARTIAL.
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
