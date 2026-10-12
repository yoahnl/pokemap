# AC-09 — Assistant Flutter indépendant

## État et portée

État de livraison : **TO REVIEW**, gate technique **PASS borné**. Tests, qualification native, captures exactes et build du point d'entrée de production sont acquis. La revue humaine reste en attente ; le produit complet AC-00 à AC-16 n'est pas déclaré terminé.

L'application demandée est placée dans `apps/avelune_converter`. Elle expose Source → Analyse → Ressources → Vérification → Export sur les vrais traitements RPG Maker XP / Pokémon Essentials et le writer natif Avelune. Les résultats sont des projets d'étude vérifiés dans un staging, avec `published=false` et `playableCertified=false`.

L'objectif humain autorise tous les lots AC-00 à AC-16 et des commits entre lots. AC-09 dépend de AC-06, dont le commit est déjà acquis ; avancer l'interface avant AC-07/08 respecte ces dépendances et permet de qualifier le moteur. Les autotiles, la reconnaissance d'objets, la reprise durable, l'IA, les événements exécutables, les collisions et la publication restent dans leurs lots propres.

## Audit initial et décisions

HEAD initial du lot : `bc4706ae767621f3e6f806a193b590770026c66e`, branche `main`. L'index était vide. Les 257 chemins étrangers déjà modifiés sont conservés sous contrôle de hash ; les changements AC-06 sont commités avant ce lot. Aucun push, rebase, changement de branche ou nettoyage de travail étranger n'est autorisé ni réalisé ici.

Le moteur existant fournit l'inventaire en lecture seule, le décodage borné, la normalisation, la composition des tuiles ordinaires et l'écriture native canonique. Il manque l'orchestrateur desktop : travail hors thread UI, événements identifiés, préparation immutable, consentements liés à la révision et au hash, annulation observable et reprise sûre.

Le design system Studio possède les primitives et thèmes utiles sans imposer son bootstrap. Un barrel public étroit permet leur réutilisation. Le nouveau package dépend de Studio pour ces primitives ; cela conserve un coût de graphe transitif, accepté dans ce lot plutôt qu'une extraction globale de l'application existante.

Le dossier Kanto autorisé sert de référence en lecture seule. Son profil observé demande confirmation. L'accord d'étude sur une source et un snapshot ne transforme jamais ce profil en profil source confirmé. Les données originales de qualification permettent de prouver les écritures sans modifier Kanto.

Aucun contrat d'ouverture directe d'un projet par un CLI Studio n'a été trouvé. L'action disponible ouvre le dossier réel dans Finder et explique l'ouverture dans Studio. La comparaison utilise les données source reconstruites et les données cibles, sans les présenter comme une capture du moteur source.

Les instructions directes interdisent les commentaires de code ; elles prévalent sur la demande générique de commentaires de `codex_rule.md`. Aucun élargissement de modèle cible ni exécution Ruby n'est nécessaire au lot.

## Implémentation

Le `ConverterWorkflow` ouvre ses propres handles dans un worker, relie chaque événement au job et à sa révision, et rafraîchit la source avant préparation et écriture. L'annulation est coopérative ; aucun `Isolate.kill` ne peut interrompre brutalement le writer. Un retry reçoit un job, un token, un lecteur et un staging neufs.

La préparation sans accord d'étude permet l'inspection des blocages. La création exige l'accord d'étude exact puis un dialogue utilisateur dont la confirmation est fausse à chaque ouverture. L'accord de plan est à usage unique et lié à la source, aux cartes, aux dépendances, à la destination, au profil et aux capacités. Toute édition de texte ou décision pertinente invalide la préparation ; une sélection de texte ou un déplacement du curseur la conserve.

Les compteurs proviennent des maps et ressources réellement décodées. Les progressions non mesurables sont indéterminées. Les images sont les PNG et crops réels du plan, et les deux canvases partagent la transformation. Le résultat affiche le reçu native effectivement relu et la portée d'étude. Une annulation ou erreur de création expose le chemin conservé et un CTA d'ouverture sans afficher un faux succès.

Les layouts conservent une barre d'action utilisable, un minimum d'action de 44 et une navigation défilante quand le texte agrandi dépasse la hauteur disponible. Aucun raccourci global du canvas ne détourne les touches des champs.

Le scaffold macOS définit le produit Avelune Converter, le bundle `com.yoahnl.avelune.converter`, la fenêtre cible 1600×1000 et son minimum 1280×800. La sandbox conserve uniquement l'accès aux fichiers choisis ; release n'a pas d'entitlement réseau, debug ajoute le serveur VM/JIT nécessaire à l'outillage.

## Défauts trouvés et correction vérifiée

| Défaut | Cause et correction | Preuve |
|---|---|---|
| Préparation invalidée par caret/sélection | Les listeners des controllers étaient traités comme des éditions ; comparaison du tuple de textes avant invalidation | Test RED puis test réel de sélection, flèche, soumission et édition GREEN |
| Staging masqué après erreur/annulation | Le résultat absent cachait le dossier récupérable ; panneau recovery avec phase, chemin et ouverture | RED puis annulation réelle à afterBootstrap, ouverture et retry GREEN |
| Sidebar en overflow à 1280×800 avec texte 1.5 | Column/Spacer sans défilement ; contrainte de hauteur minimum dans une navigation scrollable | RED avec overflow de 95 px puis deux layouts GREEN |
| Analyse refusée dans la sandbox malgré dossier choisi | L'ouverture sûre lisait chaque ancêtre depuis / ; macOS n'accorde pas forcément la lecture des parents | Test de parent searchable non listable RED puis GREEN, et scan/préparation observés dans l'app native |
| Ouverture sûre compatible avec le grant macOS | `O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW_ANY` sur le chemin canonique refuse tout lien symbolique de la chaîne sans demander la lecture des ancêtres | SDK macOS et open(2), 28 cas macOS verts, sondes natives ; aucune extension de root ni fallback qui suit les liens |

Les opérations descendantes conservent `openat`, `O_NOFOLLOW`, validation des segments, identités et handles ancrés. Un dossier réel remplacé avant l'ouverture reste une limite antérieure, sans attestation d'identité fournie par le picker ; aucune nouvelle promesse d'attestation n'est faite.

## Inventaire complet des fichiers du lot

Les chemins sont relatifs au dépôt. Les hashes des sources gelées et la liste exhaustive figurent aussi dans `index.json`.

| Fichier | Zone, raison et impact |
|---|---|
| `apps/avelune_converter/.gitignore` | Création du fichier, configuration du nouveau package |
| `apps/avelune_converter/.metadata` | Création du fichier, configuration du nouveau package |
| `apps/avelune_converter/analysis_options.yaml` | Création du fichier, configuration du nouveau package |
| `apps/avelune_converter/lib/converter_app.dart` | ConverterApp, cinq étapes, champs/dirty 147–155, consentements 280–334, navigation 409–464, compteurs 615–628, résultat 875–892, recovery 1032–1052 |
| `apps/avelune_converter/lib/desktop_services.dart` | Pickers natifs de dossiers et ouverture du dossier réel via Finder |
| `apps/avelune_converter/lib/main.dart` | Entrypoint, workflow réel, thème Studio et démarrage de l'application |
| `apps/avelune_converter/lib/map_comparison.dart` | Chargement d'images réelles, couches littérales, deux canvases et transformation pan/zoom synchronisée |
| `apps/avelune_converter/pubspec.lock` | Résolution propre au nouveau package ; globalement ignorée, ajout ciblé nécessaire pour la reproductibilité |
| `apps/avelune_converter/pubspec.yaml` | Création du fichier, configuration du nouveau package |
| `apps/avelune_converter/test/converter_app_test.dart` | Huit tests widget du pipeline réel sur données originales, erreurs, approbation, clavier et layouts |
| `apps/avelune_studio/lib/avelune_design_system.dart` | Barrel public étroit des thèmes et primitives DS, sans bootstrap ni contrôleurs Studio |
| `apps/avelune_studio/lib/presentation/shared/widgets/dialogs/studio_review_dialog.dart` | StudioReviewDialog : approbation explicite réinitialisée, refus et bouton gardé |
| `apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_path_field.dart` | Paramètres label/enabled/error/onChanged pour réutiliser le champ DS, valeurs existantes conservées |
| `apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_action_bar.dart` | StudioActionBar : actions persistantes, thèmes et disposition adaptée à la largeur |
| `apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_panel.dart` | Rayon optionnel, valeur existante 8 conservée, variante Converter 16 |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | Export public ciblé de converter_workflow.dart |
| `packages/avelune_converter_adapters/lib/src/converter_workflow.dart` | États/jobs/progression, isolates, snapshot frais, préparation, consentement exact, writer et annulation coopérative |
| `packages/avelune_converter_adapters/lib/src/macos_source_tree.dart` | _rootDirectoryFlags et _openRootDirectory : ouverture directe sûre du dossier canonique avec O_NOFOLLOW_ANY, sans lecture des ancêtres |
| `packages/avelune_converter_adapters/test/converter_workflow_test.dart` | 35 tests sur disque du workflow, invalidation, limites, dépendances, annulation et retry |
| `packages/avelune_converter_adapters/test/macos_source_tree_test.dart` | 62–126 : source lisible sous parent searchable mais non listable, refus du dossier choisi non lisible ; 28 cas macOS conservés |

Le scaffold natif est créé uniquement pour la nouvelle application. Ses configurations Debug/Release et projets Xcode, manifests, app delegate, fenêtre, tests Runner, menus et icônes rendent cette application lançable. Les dix PNG d'icône réutilisent la source Avelune existante, avec provenance contrôlée par la passe native. Inventaire natif complet :

- `apps/avelune_converter/macos/.gitignore`
- `apps/avelune_converter/macos/Flutter/Flutter-Debug.xcconfig`
- `apps/avelune_converter/macos/Flutter/Flutter-Release.xcconfig`
- `apps/avelune_converter/macos/Flutter/GeneratedPluginRegistrant.swift`
- `apps/avelune_converter/macos/Runner.xcodeproj/project.pbxproj`
- `apps/avelune_converter/macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`
- `apps/avelune_converter/macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`
- `apps/avelune_converter/macos/Runner.xcworkspace/contents.xcworkspacedata`
- `apps/avelune_converter/macos/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`
- `apps/avelune_converter/macos/Runner/AppDelegate.swift`
- `apps/avelune_converter/macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `apps/avelune_converter/macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_128x128.png`
- `apps/avelune_converter/macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png`
- `apps/avelune_converter/macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_16x16.png`
- `apps/avelune_converter/macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png`
- `apps/avelune_converter/macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_256x256.png`
- `apps/avelune_converter/macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png`
- `apps/avelune_converter/macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_32x32.png`
- `apps/avelune_converter/macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png`
- `apps/avelune_converter/macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_512x512.png`
- `apps/avelune_converter/macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png`
- `apps/avelune_converter/macos/Runner/Base.lproj/MainMenu.xib`
- `apps/avelune_converter/macos/Runner/Configs/AppInfo.xcconfig`
- `apps/avelune_converter/macos/Runner/Configs/Debug.xcconfig`
- `apps/avelune_converter/macos/Runner/Configs/Release.xcconfig`
- `apps/avelune_converter/macos/Runner/Configs/Warnings.xcconfig`
- `apps/avelune_converter/macos/Runner/DebugProfile.entitlements`
- `apps/avelune_converter/macos/Runner/Info.plist`
- `apps/avelune_converter/macos/Runner/MainFlutterWindow.swift`
- `apps/avelune_converter/macos/Runner/Release.entitlements`
- `apps/avelune_converter/macos/RunnerTests/RunnerTests.swift`

Les trois fichiers de preuves de ce lot sont `documentation/reports/converter/AC-09/09_desktop_assistant.md`, `commands.json` et `index.json`. Un seul nouveau Markdown est créé au titre de l'Evidence Pack explicitement demandé par le kit.

## Commandes et résultats

Les commandes sont exécutées depuis leur package. `commands.json` conserve argv, durées, logs et reçus, en distinguant RED attendu, erreurs de harness, interruptions et preuves finales.

| Package et commande | Résultat exact |
|---|---|
| Converter — flutter pub get | exit 0 ; résolution propre au nouveau package |
| Adapters — dart test test/converter_workflow_test.dart --reporter expanded --concurrency 1 | 35 PASS dans la preuve initiale ; inclus dans la suite finale |
| Adapters — dart test test/macos_source_tree_test.dart --reporter expanded --concurrency 1 | `00:01 +28: All tests passed!`, exit 0, 4.127 s |
| Adapters — dart test --reporter expanded --concurrency 1 | `00:20 +201: All tests passed!`, exit 0, 21.875 s |
| Adapters — dart analyze | `No issues found!`, exit 0, 2.522 s |
| Converter — flutter test test/converter_app_test.dart --no-pub --reporter expanded --concurrency 1 | `00:12 +8: All tests passed!`, exit 0, 18.209 s, après correction scanner |
| Converter — flutter analyze --no-pub | `No issues found! (ran in 5.6s)`, exit 0, 6.936 s |
| Studio — flutter test test/presentation/studio_design_system_test.dart --no-pub --reporter expanded --concurrency 1 | `00:01 +11: All tests passed!`, exit 0, 6.804 s |
| Converter — flutter build macos --debug --no-pub, lib/main.dart / bundle production | exit 0, 34.086 s ; `✓ Built build/macos/Build/Products/Debug/Avelune Converter.app` |
| MCP — npm run check / npm run build | exits 0 ; 1.190 s / 1.131 s |
| MCP — trois tests metadata/lifecycle/import | exit 0 ; 3 pass / 0 fail, 24.407 s |
| MCP — golden map.create sélectionné | exit 0 ; 1 pass / 0 fail, 8.154 s |
| Probes TEMP — map.save MCP / JSONL | exits 0 ; 8.263 s / 8.241 s |
| POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh | exit 0 ; `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.` |

Les tests et analyses finales ont zéro survivant confirmé et aucun signal. Le build laisse un ibtoold attribué PID 9820 ; après vérification de son identité, le superviseur envoie SIGTERM. Une observation ultérieure `ps -p 9820` exit 1 confirme son absence. Aucun SIGKILL ni signal vers un processus étranger. Le warning Xcode Run Script sans outputs n'empêche pas le build. Les trois commentaires d'en-tête du registry Swift généré sont retirés après le dernier build ; code exécuté inchangé.

Deux premières tentatives widget ont été interrompues par SIGINT sur les runners attribués : le polling dans une unique zone runAsync empêchait le pumping fake-async. Le harness corrigé pompe à chaque observation. Leurs sorties 0 avec erreurs de shutdown ne sont pas des preuves PASS. Les erreurs FilePicker, import clavier et invariant debug Flutter sont également conservées comme échecs corrigés. Les deux probes de parité initiaux ont échoué avant plan pour champs query manquants, puis réussi après corrections TEMP uniquement.

## Couverture UX et qualification native

| Critère | Automatisé acquis | Observation native |
|---|---|---|
| UX-01 cinq étapes/vrais jobs | Deux cartes originales, préparation, consentements, writer/relecture et compteurs réels | PASS : scan → normalisation → composition → revue → création → résultat réel |
| UX-02 deux tailles/chemins longs | Cinq étapes aux 1280×800 et 1600×1000, texte 1.5, CTA et canvas utiles, aucun overflow | PASS borné : 25 PNG réelles exactes ; revue root des comparaisons, récupérations et résultats |
| UX-03 clavier/champs | Tab/Enter et Cmd+A réels dans widget, édition distincte de sélection, saisie non capturée par canvas | Focus DS visible ; sélection Flutter 0..18 sans invalidation. Cmd+A OS et Tab de sonde non acquis |
| UX-04 erreur/cancel/retry | Inaccessible, reprise, staging récupérable, nouvelle approbation | PASS : inaccessible/retry, annulation après bootstrap, récupération puis nouvelle création vérifiée |
| Offline sans clé | Pipeline local sur fichiers, aucune demande d'authentification | Parcours local réel sans clé ni client cloud ; aucune certification réseau AC-11 anticipée |

Reçu natif : `/private/tmp/avelune-converter-ac09-runtime-contracts-20261012/ac09-native-ui-qualification-receipt.json`, SHA256 `2f6633750f1bfdd44033e18226f189ea6a660078d3d4f23bcb7fb75d9f28ca56`. Il indexe 23 captures nommées parmi 25 PNG exactes, les logs, les commandes et le diff du wrapper QA. Les cinq fichiers de source originale et copie restent byte-identiques. Zéro survivant attribué et zéro signal de teardown.

Avant revue, le parent de sortie est vide. La confirmation non cochée est désactivée. Le writer réel est annulé à afterBootstrap et conserve `.avelune-converter-stage-Gx2QfQ`, sans résultat ni succès annoncé. La nouvelle revue/approbation produit `.avelune-converter-stage-AR7Ovi/avelune-study`, avec verified=true, sourceUnchanged=true, published=false et playableCertified=false.

| Reçu du projet natif | Valeur |
|---|---|
| Révision | `sha256:7f9b218f9c4e9429be8f57de1ab88f13ead6c35754abeaaca77618246a47c409` |
| Plan approuvé | `948a153e815aba1eee1a56a60fb4751e8ad97f598e5b76a0217d23ce2296a1d5` |
| Snapshot | `855ade33ae3f0adc80840343568aeb0231941632a5a4542a1b16ad6808a9da7c` |
| Carte | `4b7c8225cdd6be74238f5becf2ee8f2750d98f2a03038e304c08b1d5b54a1319` |
| Atlas original | `929db5ed6e3f0ac7a25533899f739fa170921f6347cc5118a100c0c6fe7b27cc` |

Captures inspectées par root : ui-6-037-0 / ui-6-035-0 comparaison, ui-7-064-0 / ui-7-062-0 récupération, ui-7-068-0 / ui-7-070-0 résultat. Chaque paire mesure 1280×800 et 1600×1000 ; CTA, lisibilité, cellules et portée annoncée passent la revue.

Le QA importe les vrais UI et workflow, initialise Marionette dans un entrypoint distinct et conserve le point d'entrée production sans instrumentation. Le CLI Marionette 0.6 déjà installé est utilisé avec le package_config Studio contrôlé ; aucune configuration Flutter globale n'est ajoutée. Le wrapper TEMP, borné par bundle et nonce, observe l'état, rend l'annulation accessible après bootstrap et permet les tailles exactes. Ses sources/diffs sont `qa-host-source-diffs.json`, SHA256 `027cffa9aa649e1f86102fbc5502a3ae3dab852fd4015fb62811a98660ea367f`.

Limites d'observation : macOS avait clampé le premier 1600×1000 à 1600×921. Le wrapper permet un vrai rendu 1600×1000 dépassant le visibleFrame de 953 px, sans réglage d'écran ni agrandissement d'image. Cua Cmd+A a échoué -10005 stageManagerProcessNotRunning ; pas de preuve OS. Marionette sélectionne le texte mais son Tab ne déplace pas le focus ; le critère clavier repose sur widget et revue. Le picker réel a été observé avant gel2. Le CTA Finder réel est exécuté sans erreur ; la fenêtre Finder n'est pas observée. Le PID LaunchServices 77945 non attribué reste intact. Une erreur de ciblage Marionette avant ouverture du dialogue reste dans les logs. Deux préflights QA ont échoué avant boot, corrigés dans TEMP sans pub get global.

Ces preuves ne certifient ni le rendu du moteur RGSS, ni le gameplay, ni la publication.

## Parité Avelune et MCP

Le writer réutilise tileset.import_image, map.create et map.save via LocalMapAuthoringMutationApi plan/apply, révision fraîche et loader strict. Aucun schéma cible ni nouvelle mutation d'authoring n'est ajouté ; aucun contournement par sauvegarde JSON générique. Le catalogue vivant annonce pokemap.authoring.v1, 397 mutations, 60 resources et les trois actions writer v1.

Les probes frais font un vrai delta /name et /layers/0/cells/4 de 0 à 3, correspondant au localTileId8 de palette. Plan sans effet, apply, query, validation structure/références, close puis fresh open conservent la révision et les octets exacts. Root MCP limité à la copie déjà autorisée, aucune configuration globale élargie.

| SHA de carte | Valeur |
|---|---|
| Avant, commun | `bf2d6c86b4ff4d3fb00af0b9374b7029b74fe8e93dd8bca92ef24de51a9cb545` |
| Après MCP | `f5f10a30576c3cbcb058042a2b33995ce277d9e61f15595fafceb5b42823072c` |
| Après JSONL | `f9a040761cd3a88ebd7b513d514c29fe451894969386f53885f383d343ef2e32` |

Reçu `/private/tmp/avelune-converter-ac09-parity-5cef9d_3/parity-receipts.json`, SHA256 `0e0984c7706d78f1424febbfe4d907434662315c086f6d443ae636aeabb59a6c`. Le projet original, PNG et manifestes restent inchangés ; map.save ne prouve pas de synchronisation du titre dans le manifeste. Huit runs, zéro survivant et signal.

Direct API writer / JSONL map.create et import_image MCP viennent d'AC-05 ; édition sémantique MCP et Studio édition/save/reopen viennent d'AC-06. La présente passe complète map.save MCP/JSONL. Les chemins CLI partagent le worker JSONL, sans revendication de CLI complet du convertisseur.

Certification globale MCP toujours PARTIAL : transportCertificationComplete=false et itemTransportCertificationComplete=false, preuves globales save/import non enregistrées malgré les tests locaux. Suite globale et PMCP-085 non rejouées ; limites AC-05 conservées. Orchestration converter.* hors catalogue, N/A pour l'assistant desktop AC-09 ; aucune revendication de conversion complète par MCP.

## Verdicts et auto-critique

| Passe | Verdict |
|---|---|
| Audit / Architecture — target_contracts | PASS borné : app indépendante, DS étroit, writer API canonique, parité ciblée fraîche ; global MCP PARTIAL |
| Implémentation — root et scaffold runtime_contracts | Réel pipeline/consentement/annulation/recovery, sans mock en production ni mélange des lots suivants |
| Tests — test_validation et root | PASS : 201 adapters, 8 widgets, 11 DS ; positifs/négatifs/garde-fous/non-régression, analyses propres |
| Build / Validation — runtime_contracts et root | PASS borné : parcours natif et captures exactes, lib/main.dart production construit ; limites OS/Finder/visibleFrame consignées |
| Critique finale — test_validation | PASS sur les hashes gelés, aucun finding résiduel concret ; observation native séparée |

Les huit tests ne couvrent pas toutes les combinaisons d'état erreur/progression/résultat avec textes longs aux deux tailles. La dépendance DS conserve le graphe transitif Studio. La comparaison n'est pas un oracle RGSS et ne couvre pas les autotiles. L'ouverture sûre macOS conserve la limite antérieure de remplacement d'un dossier réel avant ouverture. Les reçus TEMP identifient des preuves locales ; ils ne sont pas un package portable de distribution.

## Git, traçabilité et suite

Domaine unique existant : Post Bêta 14 Monde, exploration et narration, 3bf197a7-bfa5-81bb-b13a-df367721992f. Ticket https://app.notion.com/p/3f7197a7bfa5817bb2caf9c181a004ec, livraison TO REVIEW ; Gate bêta false, bêta gelée inchangée. DONE réservé à la décision humaine.

Validation Git finale avant indexation : 257 hashes étrangers et 15 contrats cibles inchangés ; neuf hashes gelés UI/workflow/scanner/tests identiques ; 51 fichiers source présents. Deux changements concurrents hors lot sont observés dans packages/map_render_3d/lib/src/spatial_scene_components.dart et packages/map_render_3d/test/spatial_scene_components_test.dart ; ils restent hors index. Périmètre de livraison : 51 fichiers source, lock propre du nouveau package incluse, et les trois fichiers de preuves. SHA réel et Git post-commit seront consignés dans Notion et le retour de clôture ; ce document ne s'auto-référence pas par son propre SHA.

La lock du nouveau package est globalement ignorée et est ajoutée explicitement pour la reproductibilité, sans lock étrangère. Hygiène : un nouveau Markdown autorisé avant commit, contrôle par défaut après commit.

Suite : commit AC-09 limité au lot puis implémentation AC-07 sur l'audit Kanto acquis. Le goal complet AC-00 à AC-16 reste actif.
