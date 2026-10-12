# AC-14 — Catalogues Essentials sélectionnés

## Verdict et décision produit

Livraison technique proposée TO REVIEW, domaine PARTIAL. PBS-01..04 sont qualifiés pour le profil Essentials 21.1 attesté et la sélection bornée ; une vraie conversion de Route 9 a passé le writer, la relecture native stricte et le parcours Studio modifier/enregistrer/fermer/rouvrir. Les catalogues importés restent des données d’étude avec leurs écarts explicites. Aucun jeu Kanto complet ni parcours de combat n’est certifié.

Décision directe de Yoahn : **les combats gardent le moteur et les règles natifs Avelune**. Le convertisseur ne porte ni n’exécute le moteur Essentials. `battleAuthority=aveluneNative`, `sourceBattleScriptsExecuted=false`, zéro script Ruby exécuté et zéro appel IA pendant cette conversion. Les attaques restent `catalogOnly`, sans effets inventés ni ShowdownRef déduite du symbole source. Une donnée importée n’est pas assimilée à une capacité de combat active.

Le kit autorise l’Evidence Pack de ce lot ; ce document unique satisfait cette demande. La règle directe sans commentaires prévaut sur `codex_rule.md`. La suite et les commits locaux sont explicitement autorisés par Yoahn ; ni push, ni rebase, ni amend, ni modification de roadmap FG. Le cockpit utilise le ticket existant AC-14, domaine unique Post Bêta Monde & narration, hors gate bêta : `3f7197a7-bfa5-81d8-85df-e5f55ea2eb10`.

## Audit initial et oracles

Base AC-13 `71c34d61430b7ead5b45f2d05eb7e07e39a06cdd`, branche main, index vide. 34 chemins étrangers initialement ; 39 au contrôle avant clôture. Cinq chemins préexistants ont évolué et cinq autres sont apparus dans les chantiers de bordures/spatial/mobile concurrents. Ils sont exclus du snapshot qualifié et du commit AC-14. Un lien généré historiquement suivi, absolu et inutilisable dans un snapshot, est écarté de l’extraction TEMP ; le checkout host n’est pas nettoyé.

La qualification part d’une archive Git de la base à laquelle seuls les 13 chemins AC-14 sont superposés. Aucun code étranger sale n’est une dépendance de la preuve. Snapshot : `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository`. Dart/Flutter 3.47.5 installés sous `/opt/homebrew/share/flutter-3.47.5` ; commandes package par package, dépendances résolues offline pour le build.

Source autorisée, en lecture seule : `/Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto`. L’inventaire contient 24 085 fichiers et 383 cartes. Essentials 21.1 et version du jeu 1.1.0 sont distincts. Archive Scripts de 1 080 290 octets, SHA `3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d`. Décompression statique en textes inertes hors Git, jamais interprétés.

Oracles du répertoire TEMP `avelune-converter-ac14-pbs-audit-lslub5eh/outputs` :

- `395.rb:72–76`, commentaire supprimé avant CSV ; `255–292`, lecteur CSV source et quotes ; `719`, champ string entier. Les backslashes PBS sont des caractères littéraux suivant ce contrat, pas un CSV RFC supposé.
- `395.rb:957–979`, variantes suffixées, basename le plus long parmi toutes les familles ; `pokemon_metrics` est exclu de la famille espèces. Une variante ne devient pas une forme par son numéro de fichier.
- `396.rb:452–478`, héritage des formes, champs Moves/Evolutions explicitement vides ; `723`, méthode de rencontre répétée remplaçant les slots précédents, raw data conservées.
- `129.rb:163–164` et `295.rb:347–370`, ordre d’insertion compilé des espèces form=0 pour le NationalDex ; aucun tri alphabétique, index sélectionné ou id_number supposé. L’offset de présentation n’est pas ajouté aux identités.
- `129.rb:78–79,197–198`, tableaux de capacités conservés ; `396.rb:294–322` déduplique les types, pas ces tableaux. Le validateur natif `pokemon_catalog_coherence_validator.dart:511–524` interdit une identité de capacité répétée entre rôles.

SHA `129.rb=182575a3e420dea614bec5cd3ee525ccbbef2f8538571885ab5ba93f59ee340c`, `396.rb=5430ace38cc5142e4b0cc66e34ee0ea9d5b0d4ba02dfdfec87015981daefbc96`. Les oracles décrivent le format importé ; ils ne dictent pas les règles de combat Avelune.

## Contrats, limites et refus

Le parser pur Dart expose un AST PBS versionné, borné, avec identité namespace/famille/clé source, champs/ordre/lignes/locators, formes, parties de trainer et slots de rencontres. Les champs inconnus et unités bloquées restent conservés. Le vrai corpus parse 21 documents supportés, 4 600 entrées, 74 entrées bloquées et 37 champs inconnus. Parmi les anomalies : valeur négative Moves incompatible avec ce profil et headers trainer tels que `[FRLG_YOUNGSTER],Cordell,0`. Aucune correction silencieuse du corpus.

La sélection remonte des cartes choisies aux espèces, formes, évolutions, capacités, moves, items et équipes nécessaires. Les clés viennent d’appels entiers étroitement littéraux : pbItemBall/pbReceiveItem, TrainerBattle.start et pbTrainerBattle. Les interpolations Ruby doubles `#{`, `#@`, `#$` et les échappements non qualifiés sont ignorés ; les mêmes caractères entre quotes simples restent littéraux. Aucun Ruby n’est exécuté pour trouver une clé.

Le writer régénère literal→semantics→events→catalogs à partir des witnesses exacts, puis compare evidence, ordre des mutations et artefacts. Catalogues/documents utilisent les contrats existants `pokemon.catalog.write`, `pokemon.configuration.set_enabled`, `pokemon.documents.write`, `campaign.trainer.upsert`, `campaign.encounter_table.upsert`, `asset.import`. Les familles de documents d’une espèce sont écrites atomiquement sans scinder un graphe de formes. Aucun nouveau modèle natif ni action de persistance générique ne remplace ces contrats.

Les capacités disponibles sont uniques par identité native ; les slots source intacts restent dans `sourceAbilitySlots`, avec `sourceAbilitySlotSemanticsQualified=false` et le diagnostic explicite correspondant. Aucun rôle ni probabilité de slot Essentials n’est inventé. Les limites de deux capacités normales/une cachée restent conservatrices.

Espèces sans médias qualifiés désactivées, variantes media vides ; bandes animées source non recadrées arbitrairement en image fixe. Moves de niveau zéro et méthodes d’évolution non portées conservés dans les preuves. Rencontres sans cadence qualifiée restent à chance zéro sans zone active, ou entièrement bloquées si une référence manque. Trainers sont data-only, sans déclencheur de combat ni récompense ajoutée.

Le preset d’étude est 128 artefacts, sous le hard cap existant 256 ; chaque JSON reste sous 1 MiB, les morceaux de source sous 262 144 octets, les autres plafonds restent inchangés. Le payload de projection utilise un index unique `sourceCatalogProjectionChunks` avec offsets contigus, handles, tailles et SHA global, reconstruit avant décodage UTF-8. Aucune double lecture de format legacy.

Le writer local reprend la politique canonique documentée d’acteur local non limitée à 60 opérations/minute. Les acteurs distants MCP conservent leur limite. Ce réglage ne relève aucun quota de ressources, tailles, mutations, fichiers ou lecture source.

## Vraie étude Route 9

Une carte sélectionnée sur 383 ; 382 hors conversion. Map98 : 72×61, cinq couches, 315 décors placés, huit clips du joueur et départ (35,22). Les 16 événements restent en quarantaine, zéro adapté ; le sous-ensemble EV-A/B/C original qualifié en AC-13 ne certifie pas ces événements Kanto.

La fermeture PBS contient 546 entrées : 383 moves, 57 espèces, 46 capacités, 28 items, 18 types, neuf trainers, quatre trainerTypes, une table source. Les unités importées sont 52 espèces et sept trainers ; cinq espèces, deux trainers et la table rencontrent des références dépendantes bloquantes. Le projet natif contient 52 documents dans chacune des familles species/learnsets/evolutions/media, sept trainers et zéro rencontre active. Les preuves source conservent les unités rejetées.

La table source `[098]` contient Land,11 et les poids 80/70/25/25, total 200 : RATTATA 14–17, SPEAROW 13–17, EKANS 11–17, SANDSHREW 11–17. Ni normalisation à 100 ni assimilation de 11 à un pourcentage certifié.

727 fichiers natifs ont été strictement relus après le vrai writer. Source inchangée. La correction finale du lecteur de strings a ensuite fait l’objet d’une recomposition réelle scan→prepare : snapshot et draft exacts identiques au fullwrite vérifié, sans répéter l’écriture.

Snapshot source `5bc0f5dd57e70951cb86fe7c71114e983827251830b2b11f23ef2dab48f1c8de` ; draft `c358ece989132997ea34d34eec4ff1bb37b70858c1c6e1b493085a54fa0ac260` ; révision native `sha256:81af04c36aa33dba1a3c813cca7b42f355ac9de9aedef6b357578eeec9a94471`. Draft : 59 artefacts, 113 mutations.

Les échecs réels précédents sont conservés : quota artefact (projection de 3 948 165 octets), rate_limited après plus de 60 opérations, puis quatre doublons de capacités détectés par le validateur natif. Chaque problème a un RED ciblé puis un GREEN ; aucun seuil natif n’a été masqué pour faire passer le corpus.

## Parcours Studio et artefacts

Studio de qualification utilise le snapshot AC-13 compatible avec les modèles natifs inchangés. PID runner 19290 : ouverture du chemin exact, Carte→bibliothèque→Renommer, nom « Route 9 — modifiée dans Studio AC14 », Enregistrer, fermeture. Deux taps ont été émis trop tôt pendant la fermeture asynchrone du dialogue et refusés par Marionette ; le parcours a repris depuis l’état courant, puis la mutation et les octets disque ont été constatés. Aucun correctif produit déduit de cette erreur d’automatisation.

Nouveau processus runner 24548 : même chemin exact contrôlé par extension, titre enregistré retrouvé, état « Enregistré », lancement du vrai mode test. Le runtime charge ses cinq images et le joueur au départ (35,22). Cette preuve porte l’ouverture/modification/save/reopen et le rendu réel ; aucun combat ni gameplay global n’est annoncé. Les sauvegardes de test de ce bouton sont temporaires, pas une preuve de save disque gameplay.

Copie livrée : `/Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - AC14 valide 20261012/Projet modifié dans Studio` (729 fichiers). Le staging original de 727 fichiers est resté strictement identique au contrôle final ; la copie modifiée comprend la mutation native et son journal. Les données RMXP d’origine restent en lecture seule.

Captures hors Git : `Preuves/studio-route9-reouverte.png` et `Preuves/studio-route9-test.png` sous la même racine Documents. Recomposition : `Preuves/corrected-literal-recomposition.json`. Contrôle des fichiers : `/private/tmp/avelune-ac14-root-studio-native-final-20261012.json`. Les deux lancements Studio se terminent exit0, zéro signal et zéro survivant possédé, PIDs protégés inchangés.

Le build release final est réel, 104.3 MB. Il n’est pas encore une distribution REL-02 : la dépendance actuelle du design system via Studio embarque des assets runtime, à retirer proprement en AC-16 avant archivage logiciel. Le writer reste staging-only ; une copie matérialisée pour Studio ne remplace pas la publication durable/crash recovery AC-15.

## Commandes et résultats frais

Les suites exécutées plusieurs fois ne sont pas additionnées en un total artificiel. Les reçus contiennent cwd, commande exacte, runner/descendants, hashes, log, nettoyage possédé et comparaison des PID protégés. Aucun kill global. Les harnesses Flutter possédés sont inspectés et reaped ; les anciens PID sont laissés tranquilles.

### Core complet : 696 PASS

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository/packages/avelune_converter_core`

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test --reporter expanded
```

Exit 0 ; 26.11 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-core-final-20261012-01.json`.

### Adapters complets : 589 PASS / 9 SKIP

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository/packages/avelune_converter_adapters`

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test --concurrency=1 --reporter expanded
```

Exit 0 ; 394.108 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-adapters-all-20261012-01.json`.

### Opt-in source/autotile/semantics : 32 PASS / 0 SKIP

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository/packages/avelune_converter_adapters`

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/source_semantic_study_composer_test.dart test/literal_autotile_composer_test.dart test/literal_autotile_integration_test.dart --reporter expanded
```

Exit 0 ; 13.811 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-source-opt-in-20261012-01.json`.

### Delta writer strict corrigé : 1 PASS

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository/packages/avelune_converter_adapters`

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/source_catalog_study_composer_test.dart --name writer --reporter expanded
```

Exit 0 ; 18.783 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-literal-native-delta-20261012-01.json`.

### Analyse adapters finale : No issues found

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository/packages/avelune_converter_adapters`

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib tool/ac14_catalog_reference_fixture.dart test/source_catalog_projection_test.dart test/source_catalog_study_composer_test.dart
```

Exit 0 ; 4.798 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-analysis-final-20261012-03.json`.

### API/JSONL/parité native : 38 PASS

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository/packages/map_authoring`

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/domains/gameplay/pokemon_catalog_authoring_test.dart test/domains/gameplay/pokemon_catalog_jsonl_test.dart test/domains/gameplay/pokemon_catalog_validation_transport_test.dart test/domains/gameplay/campaign_content_authoring_test.dart test/parity/full_authoring_parity_test.dart --reporter expanded
```

Exit 0 ; 40.466 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-native-transports-20261012-01.json`.

### MCP build tsc PASS

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository/tools/pokemap_mcp`

```text
npm run build
```

Exit 0 ; 2.761 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-mcp-build-20261012-01.json`.

### MCP check tsc PASS

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository/tools/pokemap_mcp`

```text
npm run check
```

Exit 0 ; 2.856 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-mcp-check-20261012-01.json`.

### MCP vivant describe/catalogues : 2 PASS

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository/tools/pokemap_mcp`

```text
node --import tsx --test test/pokemon_authoring.test.ts
```

Exit 0 ; 26.228 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-mcp-native-catalog-20261012-01.json`.

### Converter widgets complet : 82 PASS / 0 SKIP

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository/apps/avelune_converter`

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter test --no-pub --reporter expanded
```

Exit 0 ; 51.72 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-app-all-with-source-20261012-02.json`.

### Converter analyse : 1 INFO préexistante, exit1

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository/apps/avelune_converter`

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter analyze --no-pub
```

Exit 1 ; 11.681 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-app-analyze-20261012-01.json`.

### Release final : Built 104.3 MB

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository/apps/avelune_converter`

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter build macos --release --no-pub
```

Exit 0 ; 81.166 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-release-build-20261012-05.json`.

### Vrai Kanto04 strict PASS

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository/packages/avelune_converter_adapters`

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart run tool/source_semantics_study.dart /Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto /Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - AC14 valide 20261012/Projet pour Avelune Studio /Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - AC14 valide 20261012/Preuves 98 Kanto — Route 9 AC14 --approved-study
```

Exit 0 ; 277.035 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-kanto-study-20261012-04.json`.

### Kanto final recompose : même snapshot/draft

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac14-qualified-nzv1x2m9/repository/packages/avelune_converter_adapters`

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart run tool/ac14_literal_reprepare.dart
```

Exit 0 ; 87.684 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-kanto-literal-recomposition-20261012-01.json`.

### Studio ouverture/modification/save

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/apps/avelune_studio`

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter run -d macos --debug --no-pub -t dev/marionette_main.dart --dart-define=MARIONETTE_PROJECT_PATH=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Kanto Route 9 - AC14 20261012 --dart-define=MARIONETTE_CAPTURE_ROOT=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Converter AC13 captures 20261012
```

Exit 0 ; 237.414 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-studio-launch-20261012-01.json`.

### Studio nouveau processus/reopen/test

`cwd`: `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/apps/avelune_studio`

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter run -d macos --debug --no-pub -t dev/marionette_main.dart --dart-define=MARIONETTE_PROJECT_PATH=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Kanto Route 9 - AC14 20261012 --dart-define=MARIONETTE_CAPTURE_ROOT=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Converter AC13 captures 20261012
```

Exit 0 ; 97.144 s ; survivants 0 ; signaux 0 ; PIDs protégés inchangés `True`. Reçu `/private/tmp/avelune-ac14-root-studio-reopen-20261012-01.json`.

Les neuf skips adapters sont les préconditions source AC12/autotile absentes dans la première suite ; les trois fichiers concernés ont ensuite été rejoués avec les archives source attestées (32 PASS, aucun skip). Les deux widgets initialement sautés ont été rejoués avec AVELUNE_AC12_SOURCE_SCRIPTS (82 PASS, aucun skip).

L’INFO Converter `curly_braces_in_flow_control_structures` à converter_app.dart:1936 est attestée identique dans HEAD AC-13 ; exit1 d’analyse globale explicitement conservé. Aucun warning/erreur nouveau dans les zones modifiées. Le premier build a rencontré le package Flutter Swift non généré dans le snapshot ; pub get offline l’a régénéré, puis les builds suivants passent. Pas de dette attribuée sans comparaison.

## Cinq passes et critique indépendante

| Passe | Agent ou root | Verdict et preuve |
| --- | --- | --- |
| 1 Audit/oracle | ac12_native_mapping + root | Profil et parser bornés, longest basename, CSV/comment source, aucun Ruby exécuté ; 18 ciblés puis 696 core PASS |
| 2 Design/implémentation | ac12_semantics + root | Fermeture/IDs/dex source, documents natifs atomiques, séparation effets ; 23 projection PASS, analyse propre |
| 3 Tests/compilation | ac12_validation_design + root | 14 composition PASS, deux RED gros companion/>60 mutations et GREEN ; 11 literal trainer PASS ; builds réels |
| 4 Analyse/transports | root | Adapters No issues ; API/JSONL 38, MCP build/check et 2 clients vivants, 82 widgets PASS ; dette INFO séparée |
| 5 Critique finale | ac12_semantics + ac12_native_mapping + root | P2 interpolation trainer accepté et corrigé, RED4/7 puis GREEN11, writer strict final PASS et recomposition Kanto hash identique ; aucune finding P0/P1 active |

Revue de chunks par ac12_native_mapping : PASS pour offsets, bytes, enveloppes, quotas, witnesses et régénération. Une suspicion de double import Scripts a été retirée : les witnesses events ne sont pas des imports asset en double. Le finding preset UI 32→128 est corrigé dans les trois points fresh/resume/fallback.

Régressions exactes de l’agent validation : `/private/tmp/avelune-ac14-catalog-projection-companion-red-20261012-01.json` exit1/8.896s ; `/private/tmp/avelune-ac14-catalog-local-operations-red-20261012-01.json` exit1/35.058s ; suite14 GREEN exit0/146.574s, analyze exit0/4.161s. Projecteur de la suite14 antérieur à la normalisation de capacités : delta writer+gros companion 2 PASS/36.775s sur le projecteur final, puis la suite complète root589 inclut les 14 sur ce dernier.

Capacités : `/private/tmp/avelune-converter-ac14-ability-projection-red-20261012-01.json` +21/−2 exit1/18.670s ; GREEN23 exit0/12.086s ; analyze exit0/4.753s. Strings trainer : RED4PASS/7FAIL exit1/10.920s ; GREEN11 exit0/11.817s, analyze exit0/5.096s. Ces deltas ne requalifient pas rétroactivement les anciens pins : le vrai reprepare Kanto et le writer root final qualifient le code corrigé.

MCP parity : aucune nouvelle action produit, réutilisation des contrats catalogues/batch/campaign/assets canoniques existants. Tests directs et JSONL, suite de parité, widgets et vrai Studio ; rebuild/check MCP puis serveur vivant avec describe et opérations. Pas de whole-map JSON utilisé comme preuve de capacité sémantique. La suite MCP globale et tous les packages du monorepo ne sont pas revendiqués verts.

## Inventaire précis des fichiers du lot

- `apps/avelune_converter/lib/converter_app.dart` (1984 lignes), zone : trois presets fresh/resume/fallback 128 ; comportement UI inchangé. SHA256 `747639818f8287dac63259187c64c8738b5295e898fb6523d55ec5e70afa5a97`.
- `packages/avelune_converter_core/lib/avelune_converter_core.dart` (27 lignes), zone : part source_pbs exportée par le barrel pur Dart. SHA256 `306d5e4ea9d7f8b4e6ea0ff3dcbf4ce47d0682cfa0f1aaaeb7269706189bb0a1`.
- `packages/avelune_converter_core/lib/src/source_pbs.dart` (1050 lignes), zone : AST/identités/quotas, lecture projet, longest basename, scanner headers/CSV/champs/encounters et schémas versionnés. SHA256 `d34e39acbe00f95607967365294adfba830f7ba256a2c1f8657eb056b1766f32`.
- `packages/avelune_converter_core/test/source_pbs_test.dart` (388 lignes), zone : 18 cas syntaxe/quotas/identités et erreurs sources. SHA256 `268bbac2896dc95ddb164ad9dce2f1c19f008e78aa5a502324080e02824ad34a`.
- `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` (26 lignes), zone : exports projection/composer publics. SHA256 `5ae27c229630dae76540db0aa754ae3675990046c03cf3cc172d5eb1a442fcdc`.
- `packages/avelune_converter_adapters/lib/src/converter_workflow.dart` (1925 lignes), zone : preset/version AC14, composer après événements, profil d’actions et diagnostics catalogues. SHA256 `b8eb51d0b48ddfd3ad96dc70f3ce1f120a1d1f96566b6c7a5b992a73fa49ec56`.
- `packages/avelune_converter_adapters/lib/src/native_project_writer.dart` (2880 lignes), zone : allowlist, documents/catalogues/refs exactes, relecture stricte et regen catalogue, witnesses non-PNG chunkés, politique acteur local. SHA256 `e84e7282ec12378be4c343e8700825878d7be4c2321d2fe3781d57cb73bf9306`.
- `packages/avelune_converter_adapters/lib/src/source_semantic_study_composer.dart` (302 lignes), zone : contrôle maxArtifact appliqué aux PNG ; fichiers inertes source plus grands découpés sans relâcher le plafond JSON. SHA256 `8ae7e5001038c70275b7d23b39dee2ef98b8136e5ae383ea29cfa02596290e5b`.
- `packages/avelune_converter_adapters/lib/src/source_catalog_projection.dart` (1263 lignes), zone : sélection/transitivité, NationalDex compilé, formes/slots/source evidence, documents typed, effets séparés, talents uniques et quarantaines. SHA256 `1b8baf376afc8d9b3c5b0b37a49e7bd26fb0658ec46fb11a9c5c799bad2fd3ed`.
- `packages/avelune_converter_adapters/lib/src/source_catalog_study_composer.dart` (547 lignes), zone : compose source-bound, lots atomiques espèces, index/chunks, témoins, fusion items et lecteur de calls étroit corrigé. SHA256 `c43fb45da9f79a2cb5dfa06e6a57a583bfd1e7e54061d767d5fa67a05d116fcd`.
- `packages/avelune_converter_adapters/test/source_catalog_projection_test.dart` (615 lignes), zone : 23 tests projection/refs/dex/forms/slots natifs. SHA256 `b516656dec3411023d259f5d022b7d37cdffcd267eda167cabfd30c5aecdd4e4`.
- `packages/avelune_converter_adapters/test/source_catalog_study_composer_test.dart` (789 lignes), zone : 14 cas composition/writer/altération/quotas et 11 strings trainer ; opt-in archive exact pour le profil. SHA256 `9727ed77e1e164ab5b3631e0a5266f0dca55b2f33a82cb7065542c0f24312913`.
- `packages/avelune_converter_adapters/tool/ac14_catalog_reference_fixture.dart` (531 lignes), zone : fixture originale et builder, gros PBS/companion/>60 mutations, trainerCall optionnel ; aucune ressource Pokémon distribuée. SHA256 `852d42dd53a9474cb94f3a2414342b3aa6d3bdac2a897b529306052b2ce8df8f`.
- `documentation/reports/converter/AC-14/14_selected_catalogs.md` : Evidence Pack unique, audit/contrats/traces/commandes/passes/inventaire/critique.

## État Git, risques et suite

État avant livraison : main à la base71c34d614, 13 fichiers code/tests/fixture AC-14 et ce seul rapport, index initial vide ; 39 chemins étrangers conservés. Hashes host=snapshot des 13 fichiers établis dans `/private/tmp/avelune-ac14-root-close-pins-20261012.json`. Le commit doit inclure exactement ces 14 chemins, après diff/check/hygiène et contrôle de l’index. Le reçu de contrôle après commit porte le SHA final et la comparaison des chemins étrangers ; il ne faut pas déclarer le worktree global propre.

Auto-critique : le parser et le writer sont stricts, mais les règles data-only rendent des espèces et équipes éditables sans les rendre utilisables en combat. Types/growth/effets/médias demandent une qualification native avant activation. La table Route9 et deux équipes bloquées ne sont pas réparées artificiellement. Le protocole source est une allowlist versionnée, pas un import garanti de toute version ou plugin Essentials. La normalisation des talents garantit l’identité native, pas la sélection probabiliste des slots source.

Les preuves lourdes restent locales et opt-in, sans ajout de coût CI macOS. Les fixtures source versionnées sont originales ; les archives source locales et les 727 fichiers Kanto restent hors Git. Le build logiciel actuel doit encore perdre la dépendance transitive d’assets Pokémon en AC-16. La publication récupérable et reproductible AC-15 reste à implémenter avant distribution. Statut recommandé : AC-14 TO REVIEW/PARTIAL, prochaine étape AC-15 puis AC-16. DONE appartient à Yoahn.
