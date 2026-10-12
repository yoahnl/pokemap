# AC-10 — Revue humaine et reprise de session

## État de livraison et périmètre

État : **TO REVIEW — PASS_BOUNDED**. Les suites core, adapters et application, leurs analyses, le build du point d’entrée de production, le parcours macOS réel et la lecture API/JSONL/MCP sont acquis sur les versions gelées décrites dans `index.json`. La dernière critique a trouvé une course entre deux créations de sessions distinctes à la limite `maxSessions` : RED fonctionnel, verrou global du store, GREEN28 store +16 resumer et analyse ciblée finale la ferment. Le parcours natif précède ce dernier correctif ; sa qualification reste séparée de celle du store final et du build de production final après quota (exit 0, 21.392 s).

Le lot signé est « Revue humaine et reprise de session », dépendant de AC-08 et AC-09. Il couvre canvas et inspecteur, correction manuelle des parties, nom et catégorie, approbation exacte, refus sans disparition des placements, union/scission, undo/redo, révisions, conflits et persistance. L’application reste dans `apps/avelune_converter` et convertit des projets RPG Maker XP / Pokémon Essentials vers les contrats natifs Avelune.

Ce lot produit des projets d’étude en staging. Il ne certifie ni le gameplay, ni les collisions ou priorités dépendantes de l’acteur, ni la substitution des placements, ni la publication, ni la V1 complète. Aucun modèle cible parallèle, exécution Ruby, écriture dans le jeu source, appel IA ou persistance de clé BYOK n’est introduit. La qualification finale du vrai corpus Kanto reste dans AC-15.

Le kit indique `reports/converter/AC-10/` ; la convention canonique du dépôt place l’Evidence Pack sous `documentation/reports/converter/AC-10/`, comme AC-09. Ce document, `commands.json` et `index.json` sont les seuls livrables de preuve créés. Les instructions directes interdisant les commentaires de code prévalent sur la règle générique contraire de `codex_rule.md`, relue avant cette rédaction.

## Audit initial et décisions d’architecture

HEAD initial : `1813ed8abdb55386aff0409a4fdc67727d9262af`, branche `main`, index vide. Le guard initial contient 260 chemins étrangers déjà modifiés. Les PID 35037, 6272, 82303, 61161 et 28620 sont protégés ; aucune ancienneté ou absence de CPU ne constitue une autorisation de les arrêter.

AC-08 sait proposer des objets locaux, leurs parties et leurs incertitudes ; AC-09 sait scanner, préparer et écrire un projet natif avec approbation humaine d’un plan exact. La revue ancienne repose sur de simples décisions de renommage/classification appliquées aux propositions. Elle ne suffit pas au scope AC-10 : géométrie, historique, candidats superseded, union/scission, provenance des placements et reprise durable exigent une session de domaine complète.

La vérité active devient `AssetReviewSession`, pure Dart. Le worker régénère les propositions sur une source fraîche puis contrôle namespace, snapshot, génération, hashes des propositions, images source et claims contre les IR réels. Il projette uniquement les candidats et décisions actifs ; le journal historique ne passe pas directement dans `admitPlan`. Le chemin `ConverterAssetReview` est supprimé, sans bridge ou fallback legacy.

Une frame immuable porte candidats, décisions, hashes approuvés et claims. Undo/redo retrouve exactement le contenu d’une frame tout en faisant avancer la révision du document. Union et scission créent de nouvelles identités, conservent les versions superseded dans l’historique et ne masquent aucune map. Une union de claims partagés déduplique seulement les claims réellement identiques ; une source différente, des usages incomplets ou des parties incohérentes restent refusés.

Le store IO reste dans adapters. Une enveloppe version 1 whitelist porte la session, les settings explicites de reprise et une révision de stockage distincte. Le CAS attend la révision **et le hash de toute l’enveloppe**, y compris son contexte. Source, destination, options, politiques, limites et receipts sont typés ; cartes et mode se déduisent de la session. Aucun fournisseur, secret, job, handle ouvert, PNG, draft non appliqué ou approbation globale d’export n’est enregistré.

La racine normale provient de `path_provider` Application Support. Les noms de fichiers dérivent du SHA des identités, la lecture et la découverte sont bornées, les liens et relations source/destination sont contrôlés. La publication utilise un temporaire du même filesystem, flush et rename. Les tests prouvent la sérialisation dans le même isolate et un CAS concurrent entre deux processus ; aucune garantie cross-isolate ou atomicité universelle fondée sur les FD n’est revendiquée. Le quota global entre IDs distincts est désormais protégé par un verrou du store qui englobe comptage et publication ; les tests prouvent son refus dans le même isolate et entre deux processus, séparément du CAS de chaque session.

La reprise rescane avec le namespace et la politique exacts, retrouve les vrais locators de dépendance et lie les receipts par snapshot, sélection, locator hash et target map. La découverte est progressive et bornée, sans enrichir automatiquement le scope. Toute décision inconnue, étrangère ou introuvable fait échouer la reprise en conservant le document. Une source inaccessible reste visible en lecture seule et demande une re-sélection exacte.

## Inventaire complet des 28 fichiers du lot

Les chemins sont relatifs au dépôt ; `index.json` contient leur SHA gelé. Pour les fichiers nouveaux, les zones indiquent les responsabilités ; pour les fichiers modifiés, `git diff` reste la preuve canonique. Aucun snapshot complet du code n’est recopié ici.

| Fichier | Zones et raison | Impact attendu |
|---|---|---|
| `apps/avelune_converter/lib/asset_review_panel.dart` | 45–260 : sélection/drafts/réconciliation ; 338–660 : commandes, métadonnées, géométrie, revue ; 674–1370 : cellules, catégories, union/scission ; 1390–2112 : toolbar/inspecteur responsive | Revue manuelle complète, drafts invalides conservés, actions liées au hash courant |
| `apps/avelune_converter/lib/asset_review_canvas.dart` | Nouveau : 11–208 canvas, pan/zoom, fit, gestes ; 337–420 painter et surbrillance des parties | Sélection de cellules source avec conversion exacte des coordonnées, sans déplacement lors d’une édition de texte |
| `apps/avelune_converter/lib/converter_app.dart` | 98–478 : session/store/lifecycle ; 587–642 : revalidation de la revue active et garde du hash ; ressources/navigation/actions | Sauvegarde CAS, chargement verrouillé, reprise sans approbation globale et confirmation de fermeture |
| `apps/avelune_converter/lib/desktop_services.dart` | 13–18 : `openConverterReviewSessionStore` | Store privé normal sous Application Support, sans picker de session ID manuel |
| `apps/avelune_converter/pubspec.yaml` | Dépendance directe `path_provider: 2.1.6` | Localisation du store dans le vrai host macOS |
| `apps/avelune_converter/pubspec.lock` | Statut de `path_provider` transitive vers direct main | Résolution reproducible de la dépendance réellement utilisée |
| `apps/avelune_converter/test/asset_review_panel_test.dart` | Tests existants adaptés à la session active et à la lecture des images originales | Préserve les preuves AC-08/09 sans le modèle de revue supprimé |
| `apps/avelune_converter/test/asset_review_canvas_test.dart` | Nouveau : centrage, pan/zoom, rectangle, Escape | Précision des sélections et non-régression géométrique |
| `apps/avelune_converter/test/asset_review_session_panel_test.dart` | Nouveau : commandes/domain, drafts invalides, manuel, union/scission, claims, mode, tailles et noms longs | Preuve widget des opérations de revue et du layout minimum |
| `apps/avelune_converter/test/converter_session_lifecycle_test.dart` | Nouveau : harness réel IO, sauvegarde/reprise, exit, contexte invalide, verrou list, revue active S1 | Échecs de sauvegarde sans fermeture, CAS conservé et plan conforme aux corrections visibles |
| `apps/avelune_studio/lib/avelune_design_system.dart` | Export public ciblé `studio_tool.dart` | Réutilisation d’une primitive DS existante par le canvas |
| `apps/avelune_studio/lib/presentation/shared/widgets/dialogs/studio_review_dialog.dart` | Labels cancel/secondary et callback secondaire | Dialogue Rester/Abandonner/Enregistrer sans changer les usages existants |
| `apps/avelune_studio/test/presentation/studio_review_dialog_test.dart` | Nouveau : labels et action secondaire | Contrat de la primitive DS étendue |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | Exports ciblés store/resumer | API publique utilisable par l’application |
| `packages/avelune_converter_adapters/lib/src/converter_workflow.dart` | 97–261 : settings/prepared avec session ; worker vers 1090–1240 : génération fraîche et claims ; hash génération/projection | Une seule vérité de revue, plan invalidé après correction et refus des contextes périmés |
| `packages/avelune_converter_adapters/lib/src/local_asset_proposer.dart` | ProposalSet sourceImages/claims ; 498–520 validation publique ; 703 et suite validation contre IR/usages | Sélections manuelles sans masquer la map, claims ancrés à la vraie source |
| `packages/avelune_converter_adapters/lib/src/local_review_session_store.dart` | Nouveau : 30–337 DTO/enveloppe ; 354–468 load/list/create/CAS ; 469–727 guards/locks/publication ; validation whitelist/budgets | Reprise durable privée, refus des conflicts et des données excessives ; quota global sérialisé |
| `packages/avelune_converter_adapters/lib/src/review_session_resumer.dart` | Nouveau : `resume` 10–103 et settings 105–129 | Re-scan/rebind exact des décisions, overrides source/destination étroits, stockage original intact |
| `packages/avelune_converter_adapters/test/asset_review_test.dart` | Projection actuelle du domaine, révision/hash, refus et catégories | Non-régression après retrait de `ConverterAssetReview` |
| `packages/avelune_converter_adapters/test/converter_asset_workflow_test.dart` | Session éditée reprise dans le worker, provenance/claims, modes et approbations | Refus d’une correction ou source étrangère, source intacte |
| `packages/avelune_converter_adapters/test/local_asset_placement_claims_test.dart` | Nouveau : mutations de locators/cellules, coverage, conflits et source IR | Claims réels et refus des preuves fabriquées ou incomplètes |
| `packages/avelune_converter_adapters/test/local_review_session_store_test.dart` | Nouveau : 28 preuves, IO/quotas/symlink/whitelist/CAS, deux instances/processus | Enveloppe durable et échec sans écrasement ; quota global entre IDs distincts couvert |
| `packages/avelune_converter_adapters/test/review_session_resumer_test.dart` | Nouveau : 16 preuves, nouveau workflow, décisions include/exclude, stale/inaccessible, destination déjà utilisée | Aucune perte de receipts ou mutation stockée lors d’un refus ; nouveau dossier reprend la même revue |
| `packages/avelune_converter_core/lib/avelune_converter_core.dart` | Export ciblé `asset_review_session.dart` | Session et opérations accessibles dans le core pur Dart |
| `packages/avelune_converter_core/lib/src/models.dart` | 261 : factory stricte publique `SourceImage.fromJson` | Sources sélectionnables sans reconstruire arbitrairement une référence |
| `packages/avelune_converter_core/lib/src/asset_review_session.dart` | Nouveau : 103 claims ; 249 frames ; 289–718 document/serialization/context ; 820–1245 commandes/undo/redo/union/scission | Historique immuable, révisions monotones, invalidation d’approbation et conflits explicites |
| `packages/avelune_converter_core/test/asset_review_session_test.dart` | Nouveau : mutations négatives, roundtrip, frames, union/scission, provenance partagée et stale hash | Domaine complet prouvé avant implémentation et renforcé après critique |
| `packages/avelune_converter_core/test/source_image_test.dart` | Nouveau : factory SourceImage valide/invalide | Whitelist et coordonnées/références typées |

Les trois fichiers de preuve ajoutent un périmètre de livraison de 31 chemins. Les scripts, probes, fixture, logs, captures et harnesses de qualification restent en TEMP ou dans le container QA ; ils n’élargissent pas l’inventaire produit.

## Critiques, défauts et RED/GREEN

| Défaut réel trouvé | Correction et preuve | État |
|---|---|---|
| Destination déjà utilisée empêchant la reprise avant rebind des dépendances | Resumer avec overrides destination/projectName/folderName explicites ; document CAS original conservé ; RED `native.destination.exists`, puis GREEN16 | Corrigé |
| Contexte saisi invalide lançant une exception dans build ou avant le try de sauvegarde | `_formValid` valide via DTO et capture son échec ; `_resumeSettings` de sauvegarde reste dans try ; RED fonctionnel contexte, puis suite lifecycle et app | Corrigé |
| List/dialog de reprise laissant la revue éditable pendant un await | `_loadingSession` couvre toute la découverte, la sélection et la restauration ; RED loading, GREEN lifecycle | Corrigé |
| Revalidation préparant S0 stockée alors que S1 corrigée reste visible | Vue temporaire de StoredReviewSession avec revue active + settings courants ; `_storedReview` original demeure pour CAS ; garde preparedSession hash == active avant dirty=false ; RED1 17.004 s, GREEN dans app48 | Corrigé |
| Union de candidats partageant une preuve source exacte | Déduplication des claims strictement identiques, contrôle contre IR et propagation historique ; RED puis core593/claims/workflow | Corrigé |
| Overflow Ressources à 1280×800, texte 1.5 et noms longs | Toolbar/inspecteur responsive et contraintes corrigées ; test du nom long inclus dans app48 | Corrigé |
| Quota global de sessions concurrentes d’IDs différents | REDv2 : deux fichiers publiés pour maxSessions=1, même isolate et deux processus ; verrou global `.sessions.lock` autour de count/publish, puis GREEN44 (store28 + resumer16), analyse No issues | Corrigé |

Les premières tentatives lifecycle suspendues sur Save ne constituaient pas un RED fonctionnel : le harness Flutter empêchait les IO réels de progresser dans sa zone fake-clock. Le polling corrige le pumping en alternant `runAsync` et `pump`. Les import/compile/load failures initiaux, analyses intermédiaires avec infos braces, et tentatives interrompues ou non finales restent indexés ; leur exit ne remplace jamais une preuve finale.

Une tentative `dart analyze` dans le package core du snapshot sans `.dart_tool/package_config.json` a produit des URIs/lints non résolus. C’est un échec de setup ; le core du dépôt hôte possède une analyse complète finale avec configuration valide. Aucun correctif produit n’est déduit de cet échec de snapshot.

## Commandes et preuves automatisées acquises

`commands.json` conserve les argv, working directories réels, durées, PID, signaux, hashes des logs et chemins des reçus. Les exécutions du snapshot qualifié sont distinguées de celles du dépôt hôte : HEAD1813 plus overlay owned gelé, jamais les 260 chemins étrangers.

| Commande depuis son package | Résultat exact acquis |
|---|---|
| Core — `dart test --reporter expanded --concurrency 1` | `00:19 +593: All tests passed!`, exit 0, 20.698 s |
| Core — `dart analyze` | `No issues found!`, exit 0, 1.221 s, reçu shared-claim-union-analyze |
| Adapters — `dart test --reporter expanded --concurrency 1` | `01:20 +375 ~8: All tests passed!`, exit 0, 83.445 s ; 8 skips conservés |
| Adapters — `dart analyze` | `No issues found!`, exit 0, 4.604 s |
| Converter — `flutter test --no-pub --reporter expanded --concurrency 1` | `00:55 +48: All tests passed!`, exit 0, 59.338 s |
| Converter — `flutter analyze --no-pub` | `No issues found! (ran in 5.7s)`, exit 0, 7.006 s |
| Converter — `flutter build macos --debug --no-pub -t lib/main.dart` | `✓ Built build/macos/Build/Products/Debug/Avelune Converter.app`, exit 0, 21.392 s après le dernier correctif quota ; build précédent 42.108 s conservé |
| Store + resumer — ciblé final quota | `00:42 +44: All tests passed!`, exit 0, 44.650 s ; store28 + resumer16 |
| Store — analyse finale source/test | `No issues found!`, exit 0, 4.116 s |
| Resumer — ciblé avec override destination | `00:06 +16: All tests passed!`, exit 0 |
| MCP — `npm run build` | exit 0, 1.939 s ; `tsc -p tsconfig.json` |
| Parité TEMP — `node transports_read.mjs config.json` | exit 0, 25.063 s ; 13 queries par transport, reçus exacts |
| Hygiène — `bash tools/scripts/check_markdown_hygiene.sh` | exit 0, 2.354 s ; `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.` |

Les tests/analyses finaux listés ont zéro survivant confirmé et aucun signal vers les PID protégés. Le build initial de production a laissé trois `ibtoold` attribués : PID 11927, 11928 et 13284 ; le build final après quota en a laissé deux, PID 44884 et 44885. Le superviseur a vérifié leur identité puis envoyé SIGTERM ; zéro survivant confirmé dans chaque reçu. Aucun SIGKILL ni signal de nom global. Les warnings de dépendances AVFoundation et de phase Xcode sans outputs ne changent pas l’exit 0, et ne sont pas annoncés comme supprimés.

La tentative core du snapshot sans configuration reste un échec de setup ; les deux nouveaux tests quota sont un complément ciblé à la suite complète antérieure. Le build final après quota et l’hygiène possèdent leurs reçus exit 0 séparés. Aucun nouveau worker Dart/Flutter n’a été lancé pour rédiger ce document.

## Qualification macOS réelle et reprise

La qualification utilise la vraie application dans une copie TEMP indépendante, le bundle `com.yoahnl.avelune.converter.ac10qualification`, Marionette 0.6 déjà installé et des données originales sous le Documents du container. Le store reste celui de `path_provider` ; aucune mémoire de test ou injection de store ne remplace la persistance réelle. Le fixture est créé une seule fois, jamais au boot.

Source contrôlée : 9 fichiers, 6 267 octets ; maps source 1, 8, 12, 20 et 21 ; fingerprint `e310fbd05292d59067c9636627c82a3843a27d221e1bff540e1275e836764f8f`. Snapshot de scan : `a25846d9c2b8afae34c3e4d14a83d0f92e6d22d0b9b3e8d55b02f8d67660dcf4`.

Le premier parcours observe renommage « Maison AC10 corrigée », catégorie building, approbation exacte, correction de géométrie et approbation périmée. Undo rétablit le hash approuvé du candidat et redo retrouve la géométrie corrigée avec approval vide, tandis que la révision du document avance. L’ancrage bottomCenter x=60 est refusé sans mutation ; le crop source est ensuite corrigé à x=64 et approuvé.

Le menu natif Quit ouvre le dialogue ; Rester conserve la fenêtre. Un second Quit suivi d’Enregistrer et fermer sauvegarde réellement puis fait disparaître le PID application 17312. Le nouveau lancement recharge la session depuis Application Support : hash `a1dc38437131a184040cca72f59579a7a4e37952dfa3824cdb6dbb297473d859` identique avant fermeture et après relance, source revalidée, storedRevision 1 et aucune approbation globale d’export restaurée.

Le second parcours passe en standaloneObjects, revalide l’objet, coche l’approbation du plan et exporte. Il produit cinq maps, un objet libraryOnly corrigé et trois ressources relues : l’atlas source original, le PNG autonome et son compagnon. La sauvegarde finale utilise CAS et donne storedRevision 2, sessionHash `1bb2b22ef784de41e4a1e054e4e4b9004dff3ade3c70fde593218f5eaf223505`, envelopeHash `38f261f23b7ef06912e3067ee9ce8fc8194f293a9225a83d5c7c214b20a0a733`, sessionUnsaved=false. Le Quit natif final termine normalement.

| Reçu export | Valeur |
|---|---|
| Projet réel | `/Users/karim/Library/Containers/com.yoahnl.avelune.converter.ac10qualification/Data/Documents/ac10-qa-e2495cd0-3dc8-43a8-8376-cec70d232e5d/output/.avelune-converter-stage-Mn8CDq/avelune-study` |
| Révision native | `sha256:0311c4c55d66108e84ed40c00677acc867dfdc2fe40486e21b9afdb1e236de13` |
| Préparation | `0bb34c3570ae9f931b59c78c164d9dc29b4e2a85fe31dfebb31d43161d6cbd7c` |
| Plan approuvé | `c96722cc51f930de55080930c04630ffdd5fe7cc593bd6969946dd77931eee1c` |
| PNG autonome | `7edb953e25ab6beb7e7f3510edad8a0dd8e6e700816d7ef7fccda2b570dc65b2` |
| RGBA | `45dffa7a8a449eafef08e0b028320a919c5d8a1658088ce2747391c0c8cfd937` |
| Compagnon | `ccf13ee57c59a2aa343561829296ad6760f035591dd5e9b8c9159af2cabf629e` |
| Limites | sourceUnchanged=true, libraryOnly=true, placementsSubstituted=false, published=false, playableCertified=false |

Les deux reçus `native-first-launch-20261012.json` et `native-second-launch-20261012.json` donnent exit 0, respectivement 709.667 s et 403.584 s, aucun signal, aucun survivant et protectedUnchanged=true. Les observations, les probes, les hashes de maps/assets et la capture réelle `native-export-20261012.png` sont indexés avec SHA dans `index.json`.

Limites observées : `get_logs` Marionette renvoie Server error ; il n’y a donc pas de certification générale de logs runtime sans erreur. Le scroll imbriqué Marionette ne retrouve pas le bouton d’inspecteur : le scroll CUA réel et le modal de toolbar permettent l’action. Sur la seconde fenêtre, certaines actions CUA renvoient `noWindowsAvailable`, alors que le menu applicatif natif fonctionne. Le bouton rouge de fermeture n’a pas été qualifié ; Quit/Rester/Enregistrer et fermer puis Quit final l’ont été. Union/scission native n’a pas été jouée : ses preuves restent celles du core et des widgets.

## REV-01 à REV-05 et parité native

| Critère | Preuve acquise | Limite conservée |
|---|---|---|
| REV-01 approbation puis géométrie | Core/widget et observation native : correction invalide l’approbation ; revalidation explicite | Ancrage préservé en compagnon ; substitution native non certifiée |
| REV-02 garder les tuiles | Core/worker et comparaison des maps natives exactes ; candidat libraryOnly sans disparition de map | Aucun remplacement implicite des placements |
| REV-03 union/scission/rename undo/redo | Core et widgets pour union/scission ; undo/redo réellement observés sur géométrie/approval | Union/scission non rejouées en app native |
| REV-04 fermer/rouvrir | Quit/Rester/SaveClose, PID disparu, nouvelle app et hash retrouvé ; CAS final rev2 | Force quit non interceptable ; seule la dernière sauvegarde durable est garantie |
| REV-05 conflit de placements | Claims against IR, conflits et substitution bloquée dans les tests | Bibliothèque possible sans certifier replacePlacements |

Les lectures directes `map_authoring`, JSONL et MCP interrogent le même projet exporté, avec 13 queries par transport. Les records canoniques, hashes et révision `0311…` sont identiques ; les cinq maps et l’unique objet corrigé, ses IDs element/category/tileset/image, PNG/RGBA/companion et provenance sont vérifiés. Le live `pokemap_describe` expose les sept contrats concernés, catalog hash `93f263e48ae35192dde318744dc6cad6e5d21cb0d202d0ea9fe041a6f3fce4eb`.

Reçu transports : `/private/tmp/avelune-converter-ac10-transports-yvne5y0r/transports-final.json`, SHA `ea12d26e4ee123ee0bdf05cd7a1e453e49e877789e1581a4eb3258310b87755d`. Les 47 fichiers natifs et les neuf témoins source restent inchangés ; aucun secret détecté dans les records. Ce test est en lecture seule : il ne prétend pas une nouvelle qualification de toutes les mutations MCP ou une certification globale Studio/Player. Les mutations de création/export sont celles du writer canonique déjà couvert par les suites natives et les lots précédents ; aucun nouveau contrat cible n’est nécessaire à la session locale du convertisseur.

## Verdicts des passes et état Git

| Passe / agent | Verdict |
|---|---|
| Audit / Architecture — root, ac10_core, ac10_storage, ac10_ui | Scope complet signé, frontières conservées ; domaine unique et reprise exacte |
| Implémentation core — ac10_core | Session, frames, claims IR, union partagée, sourceImages ; suites et analyse complètes PASS |
| Implémentation stockage/reprise — ac10_storage | Enveloppe/CAS/private store/rebind exact ; tests acquis ; quota global concurrent corrigé et prouvé par ac10_ui (REDv2/GREEN44/analyse) |
| Implémentation UI — ac10_ui et root | Canvas/inspecteur/drafts/union/scission/undo/redo et lifecycle ; app48 PASS, layout corrigé |
| Tests — agents et root | RED fonctionnels puis GREEN ; erreurs de setup/harness distinguées ; 8 skips adapters visibles |
| Build / Validation — root, préparation ac10_storage | Production main build final après quota et parcours macOS antérieur acquis, contrôles de PID attribués et source intacte |
| Parité — ac10_core | PASS borné API/JSONL/MCP sur la sortie native réelle et le catalogue live |
| Critique finale — ac10_storage/ac10_core/ac10_ui | P2 source active S1 corrigée et testée ; P2 quota global trouvée tardivement, corrigée et testée ; aucun P1/P2 restant dans les chemins examinés |

Guard avant création des trois preuves : HEAD1813 sur main, 28 fichiers owned modifiés, 261 étrangers, index vide, zéro suppression étrangère et 84 pins sans dérive. Les 261 étrangers comprennent les 260 initiaux et le nouveau fichier concurrent `apps/avelune_studio/test/map_workspace/spatial_terrain_painting_test.dart`. Huit chemins initiaux ont changé dans d’autres sessions : terrain_brush, map_canvas_stroke, smart_tile_cell_actions, jsonl_smart_tile_native_flow_test, smart_tile_layer_operations, son test, model3d_source_replace_stdio et smart_tile_model3d_source_test. Ces changements restent hors overlay, hors livraison et hors index AC-10. Il serait incorrect de déclarer tous les hashes étrangers inchangés.

Le rapport est précommit : aucune opération Git d’écriture n’est exécutée par sa rédaction. Le commit du lot, l’état postcommit, la synchronisation du ticket Notion existant et le dernier guard après correctif quota appartiennent à la finalisation root. Le guard final avant staging compte 31 chemins livrés et 261 étrangers, avec index vide. L’hygiène est PASS. `index.json` réserve la synchronisation Notion et l’état postcommit à root ; le SHA du commit est consigné hors du paquet qui le contient.

## Auto-critique et suite

La qualification distingue domaine pur, IO, widgets, host macOS et transports. Le rendu natif prouve le parcours cité et un objet corrigé ; il ne transforme pas les suites automatisées union/scission en parcours natifs observés. Le paquet de preuves conserve les échecs et limites d’outillage, et la P2 quota tardive possède son REDv2/GREEN ciblé et des pins finaux explicites. Le parcours natif antérieur ne lui est pas attribué rétrospectivement.

La source externe peut nécessiter une nouvelle sélection après perte du grant sandbox ; aucun bookmark n’est enregistré. Le store borné refuse les données hors contrat plutôt que de les migrer. La publication flush/rename et les locks sont qualifiés sur la machine et les processus testés ; pas de promesse universelle de crash/power-loss ou cross-isolate. Les artefacts TEMP sont référencés avec leurs hashes ; leur conservation longue durée dépend du stockage local, sans copie implicite dans le dépôt.

Le build après quota, l’hygiène et le guard final sont acquis. Root synchronise le ticket Notion TO REVIEW puis consigne le commit scoped dans Notion et le message de livraison ; le paquet précommit ne contient pas son propre SHA. La revue humaine reste nécessaire pour DONE. Après le commit AC-10, la priorité directe est Route 9 Kanto : conversion, ouverture réelle dans Studio, modification visible, sauvegarde et réouverture avant AC-11. La qualification complète AC-15 et la distribution AC-16 conservent leurs critères propres.
