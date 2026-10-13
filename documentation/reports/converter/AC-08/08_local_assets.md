# AC-08 — Reconnaissance locale et assets approuvables

## État et portée

Le convertisseur propose des groupes de pixels traçables, demande une revue humaine et exporte les objets approuvés dans la bibliothèque native Avelune. Les cartes littérales restent intactes. L'application est `apps/avelune_converter`.

L'implémentation, les tests automatisés, le build macOS, le parcours réel Converter, la relecture native et les transports ciblés JSONL/MCP sont vérifiés. Le verdict technique est PASS dans les limites ci-dessous. La livraison est proposée en `TO REVIEW` après commit ciblé ; `DONE` reste une décision humaine.

Le scope signé couvre alpha/grille/usages répétés, parties disjointes, bibliothèque seulement et PNG exacts : AST-01 à AST-05. AC-10 porte les corrections géométriques, union/scission, undo/redo et reprise durable ; AC-12 porte passages/priorités ; AC-13/14 les événements et catalogues. Aucune conversion intégrale jouable de Kanto n'est certifiée par AC-08.

## Audit initial et décisions

- HEAD initial : `3a1209a6f8344d9826f0d5abbc509989ad4acab5`, branche `main`, index vide, 259 chemins déjà modifiés hors lot. Les travaux concurrents 3D restent exclus.
- AC-06/07 produisent déjà des cartes littérales et des atlas natifs ; AC-09 apporte l'application indépendante et ses jobs réels. AC-08 complète ces contrats sans introduire de modèle cible parallèle.
- `ProjectElementEntry` utilise un rectangle de grille natif. Les morceaux disjoints ne deviennent jamais des frames temporelles. Une image autonome assemblée permet leur représentation ; le mode atlas partagé refuse une géométrie incompatible.
- L'ancre source et les parties sont conservées dans un compagnon JSON inerte. Leur présence ne prouve pas une substitution native de placements ni une règle de collision/occlusion.
- Les actions existantes suffisent : `tileset.import_image`, `tileset.upsert`, `map.create`, `map.save`, `element_category.upsert`, `element.upsert`, `asset.import`.
- La reconnaissance locale ne déduit ni une catégorie métier certaine, ni le nombre réel d'objets dans un groupe ambigu. Les candidats arrivent en `needsReview`, catégorie `unclassified`, usage `libraryOnly`, sans approbation.
- L'instruction utilisateur interdisant les commentaires de code prime sur `codex_rule.md` §3, qui demande « Mettre un maximum de commentaires utiles ». Les invariants sont exprimés par les contrats, noms, tests et ce rapport.

Le corpus Kanto autorisé reste externe et en lecture seule : `/Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto`. Les fixtures originales de ce lot ne copient aucun média du corpus et n'exécutent aucun Ruby.

## Implémentation et invariants

`LocalAssetProposer` lit les sources approuvées par l'inventaire, contrôle leurs bindings et produit une géométrie déterministe depuis l'alpha, la grille ou les usages répétés. Les quotas précèdent les allocations : 32 images, 64 MiB source, 16 777 216 pixels, 1 048 576 cellules de maps, 4096 composants, 256 candidats, 4096 parties par candidat et 16 384 parties cumulées. Une limite dépassée ne retourne pas un jeu partiel de propositions.

`ConverterAssetReview` lie l'action humaine à l'ID et au hash exacts de la proposition. Le nom et la catégorie sont explicites ; garder les tuiles ne nécessite pas une classification inventée. Une revue périmée ou étrangère est refusée. Un changement de mode ou une édition invalide réellement préparation et approbation.

`ApprovedAssetLibraryComposer` compose uniquement les candidats actuellement approuvés. Les identités métier restent distinctes même lorsque des objets partagent les mêmes tuiles. En autonome, les parties sont copiées sans blend ; réflexion horizontale puis rotation par quarts de tour, offsets, trous et padding sont contrôlés. Les RGB sous alpha nul et l'alpha partiel sont conservés. Le mode partagé admet seulement un rectangle complet aligné sur la grille, sans transformation ni assemblage disjoint ; aucune bascule de mode implicite n'est effectuée.

Chaque objet ajoute quatre mutations natives : import d'image/tileset, catégorie, élément et compagnon JSON. Les operation IDs respectent la grammaire du gateway natif sans modifier les IDs métier. Les preuves transportent nom, catégorie, révision, sources, parties, canvas, ancre, incertitudes et décision humaine.

Le writer conserve les PNG témoins nécessaires à une recomposition avant staging. Il régénère les objets depuis ces témoins en mémoire et compare preuves, artefacts et mutations : rehasher un draft ou l'approuver de nouveau ne légitime pas une contradiction. Les consommateurs de candidats non régénérés sont refusés. Les quotas cumulés du draft sont vérifiés pendant la préparation et avant écriture ; les limites de reconnaissance sont bornées même quand le budget natif autorisé est plus large.

Les compagnons JSON sont lus par le handle natif confiné, vérifiés avec leurs blobs et relus après le dernier checkpoint. La révision du snapshot, qui ne fingerprint pas ces JSON, ne suffit pas à prouver leur intégrité. Une annulation de recomposition reste `native.cancelled`. Aucun chargement implicite d'une source sur disque ne remplace un témoin absent.

Le panneau Converter réutilise les primitives et tokens Studio. L'aperçu décode les PNG source, assemble les parties indépendamment de l'atlas exporté et libère ses images/codecs. Images absentes, quotas, état occupé ou catégorie manquante bloquent l'approbation. Le workflow conserve les cartes, leurs couches et leurs placements : l'ajout d'une bibliothèque n'en remplace aucune cellule.

## Inventaire complet des fichiers

Les 14 fichiers du lot comprennent 7 fichiers produit et 7 fichiers de tests/fixture : 5 fichiers existants modifiés et 9 nouveaux. Les hunks et SHA frais sont consignés dans `index.json`.

| Fichier | Zones finales | Raison et impact |
| --- | --- | --- |
| `apps/avelune_converter/lib/asset_review_panel.dart` | Nouveau, 1–387 ; état 40–324, painter 326–387 | Revue humaine, choix de mode, catégories, aperçu source et invalidation. |
| `apps/avelune_converter/lib/converter_app.dart` | État/callbacks 92–373 ; ressources 787–859 ; résultat/confirmation 987–1115 ; diagnostics 1329–1365 | Branche les candidats aux jobs réels, invalidation et nouveau compte de ressources vérifiées. |
| `apps/avelune_converter/test/asset_review_panel_test.dart` | Nouveau, 1–250 | Six tests : classification, garder les tuiles, renouvellement, image absente, état occupé, trou transparent. |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | 7–8 | Export public du proposer et du composer de bibliothèque. |
| `packages/avelune_converter_adapters/lib/src/approved_asset_library.dart` | Nouveau, 1–816 ; contrats 12–83, composer 85–599, géométrie/raster 601–730, preuves/PNG 732–816 | Artefacts exacts, identités distinctes, opérations natives et compagnon traçable. |
| `packages/avelune_converter_adapters/lib/src/converter_workflow.dart` | Revue/settings 97–296 ; PreparedStudy 298–336 ; invalidation 553–563 ; worker 1156–1298 ; hashes/merge/capacités 1536–1675 ; plan/contexte 1680–1863 | Transporte revues, candidats, preuves et budgets dans préparation, admission et writer. |
| `packages/avelune_converter_adapters/lib/src/local_asset_proposer.dart` | Nouveau, 1–782 ; contrats 11–95, propose/manual 97–400, inputs/géométrie 402–782 | Propositions locales déterministes, ambiguïtés et quotas avant allocations. |
| `packages/avelune_converter_adapters/lib/src/native_project_writer.dart` | Artefacts/draft 59–360 ; écriture/relecture 411–650 ; budgets/préflight 686–1146 ; recomposition 1148–1305 ; binding littéral 1381–1515 ; handle compagnon 1775–1834 | JSON inerte, témoins source, recomposition anti-falsification et relecture exacte. |
| `packages/avelune_converter_adapters/test/approved_asset_library_test.dart` | Nouveau, 1–777 | 39 tests : AST-01–05, géométries, pixels, transferts, limites, annulation et gateway IDs. |
| `packages/avelune_converter_adapters/test/asset_review_test.dart` | Nouveau, 1–98 | Cinq tests de revue exacte/périmée, confirmation, catégorie et hash ; import par le barrel public. |
| `packages/avelune_converter_adapters/test/converter_asset_workflow_test.dart` | Nouveau, 1–293 | Sept parcours réels : bibliothèque, refus, mode/revue, cycle et budgets cumulés. |
| `packages/avelune_converter_adapters/test/local_asset_proposer_test.dart` | Nouveau, 1–328 | 16 tests : placements répétés/disjoints, alpha, identité, refus, quotas et immutabilité. |
| `packages/avelune_converter_adapters/test/native_project_writer_test.dart` | Ajouts 21–94, 140–554 et 1411–1563 | 23 cas AC-08 dans 72 tests writer ; persistance, préflight, falsification et corruption tardive. |
| `packages/avelune_converter_adapters/test/support/original_asset_fixture.dart` | Nouveau, 1–290 | Cinq maps et PNG originaux, attentes arbre/maison, groupe ambigu et tuiles partagées. |

L'Evidence Pack comporte ce seul Markdown et deux fichiers JSON, `commands.json` et `index.json`. Les wrappers QA, captures, builds, caches, override de dépendances QA et projets temporaires ne sont pas versionnés.

## Qualification automatisée et isolation

Le checkout partagé a échoué au chargement pendant des changements 3D concurrents : getter/generated model `SmartTileModel3dSource.replacesGround` incohérent. La suite adapters hôte a donné exit 1 avant ses tests. La suite MCP globale a également donné exit 1, avec workers sortis au code 254 et une fixture étrangère absente `apps/hgss_first_map`. Ces essais ne sont pas des preuves vertes ni des RED métier AC-08 ; aucun code étranger n'a été corrigé pour les faire passer.

La qualification finale utilise une extraction en lecture seule de HEAD initial plus les 14 fichiers AC-08, dans `/private/tmp/avelune-converter-ac08-isolated-snapshot-runtime-9cg0yf11/repository`. Elle contient aussi le host runtime attendu par la configuration MCP. Une ancienne sauvegarde ephemeral et son symlink externe sont exclus, sans lecture de leur cible. Aucun worktree Git n'est créé.

Le reçu initial du snapshot porte SHA `4c3b989def076804599d97717dca7091b2859e1169fcb3e3a202ad212b097e06`. Après celui-ci, seul l'import du nouveau test `asset_review_test.dart` a été remplacé par le barrel public, sur hôte et copie. Son SHA final est `9d1b220f32c0fb28b8eb764fa01777536e9239627290af008de88a2a5a2c943f`, qualifié par cinq tests et l'analyse finale. Les 13 autres pins n'ont pas changé. Les 14 fichiers sont octet-identiques entre hôte et copie avant/après QA.

| Commande / contexte | Résultat exact |
| --- | --- |
| Proposer hôte : `dart test test/local_asset_proposer_test.dart --reporter expanded --concurrency 1` | Exit 0, 10.111 s, `00:03 +16: All tests passed!`, runner 99925. |
| Exporteur hôte : `dart test test/approved_asset_library_test.dart --reporter expanded --concurrency 1` | Exit 0, 5.127 s, `00:03 +39: All tests passed!`, runner 28459. |
| Writer hôte : `dart test test/native_project_writer_test.dart --reporter expanded --concurrency 1` | Exit 0, 18.511 s, 72 tests, runner 38439. |
| Workflow budgets hôte : `dart test test/converter_asset_workflow_test.dart --reporter expanded --name 'valid wider native budgets\|combined literal'` | Exit 0, 5.158 s, `00:03 +2: All tests passed!`, runner 27805 ; les deux RED précédents sont conservés. |
| Adapters isolés : `dart pub get --offline` | Exit 0, 1.163 s, runner 57489. |
| Adapters isolés : `dart test --reporter expanded --concurrency 1` | Exit 0, 54.177 s, `00:46 +315 ~8: All tests passed!`, runner 57962. |
| Revue publique isolée : `dart test test/asset_review_test.dart --reporter expanded` | Exit 0, 1.751 s, `00:00 +5: All tests passed!`, runner 60692. |
| Adapters isolés : `dart analyze` | Exit 0, 2.858 s, `No issues found!`, runner 61281. |
| App isolée : `flutter pub get --offline` | Exit 0, 1.728 s, runner 62177. |
| App isolée : `flutter test --reporter expanded --concurrency 1` | Exit 0, 30.781 s, `00:19 +15: All tests passed!`, runner 63143. |
| App isolée : `flutter analyze` | Exit 0, 6.763 s, `No issues found! (ran in 5.3s)`, runner 65245. |
| Build macOS debug QA : `flutter build macos --debug --no-pub -t <forwarder vers vrai main>` | Exit 0, 37.401 s, `✓ Built .dart_tool/ac08_ui_build_6a236af4/macos/Build/Products/Debug/Avelune Converter.app`, runner 70993. |
| Relecture fraîche : `dart --packages=<QA package_config> <readback_native.dart> <config> <état final>` | Exit 0, 8.684 s, runner 99428 ; cinq cartes, deux éléments et PNG/JSON exacts. |

Les huit skips de la suite isolée exigent l'opt-in `AVELUNE_AUTOTILE_SCRIPTS_PATH` pour l'attestation locale Kanto d'AC-07. Ils ne qualifient pas le corpus. Les suites proposer/exporteur/writer et leurs analyses ciblées complètent les runs finaux ; les argv, logs et reçus sont conservés dans `commands.json`.

Les RED réels ont trouvé des IDs d'opérations refusés par le gateway, un consommateur de candidat étranger admis trop loin, une mauvaise normalisation d'annulation, un JSON logique modifié après checkpoint encore déclaré vérifié, un budget reconnaissance trop strict pour un budget natif valide et un cumul de pixels insuffisamment préflighté. Ces défauts sont corrigés et couverts. Les ENOSPC et erreurs de chargement du harness ne sont jamais présentés comme des RED fonctionnels.

## Parcours natif et pixels

La qualification utilise le bundle distinct `com.yoahnl.avelune.converter.ac08qualification`, nonce `6a236af4-cb00-4f58-8288-dfc79ce5836f`. Le main produit reste sans Marionette. Le build forwarder appelle ce vrai main avec des métadonnées de bundle QA ; il ne certifie pas une release distribuable.

Les jobs réels inventorient neuf fichiers originaux et cinq cartes, puis proposent cinq groupes. Les boutons produit approuvent `Arbre QA AC08` / Nature et `Maison QA AC08` / Bâtiment. En partagé, la maison est refusée par `library.shared_atlas.geometry`, locator `Data/Map008.rxdata`, tile 436 : aucun draft admissible et destination vide. Le choix explicite « Une image par objet » efface les anciennes revues ; les cinq candidats reviennent à `needsReview`. Les deux objets sont revus de nouveau ; le groupe ambigu de map 12 reçoit « Garder les tuiles ».

Le consentement final passe par `approve-plan` puis `confirm-reviewed-plan`. Les 19 opérations produisent cinq cartes et cinq ressources vérifiées : un PNG littéral, deux PNG de bibliothèque et deux compagnons JSON. Résultat : `verified=true`, `sourceUnchanged=true`, `published=false`, `playableCertified=false`.

Projet conservé : `/Users/karim/Library/Containers/com.yoahnl.avelune.converter.ac08qualification/Data/Documents/avelune-converter-ac08-qualification-6a236af4-cb00-4f58-8288-dfc79ce5836f/output/.avelune-converter-stage-cnuc5l/avelune-study`. Révision fraîche : `sha256:ed3c0df62123a116257c662b1df031105803fa421d152801eaac67292d1a7468`, identique au reçu writer, aucun diagnostic de chargement. Les cinq cartes correspondent exactement aux données littérales prévues ; placements, couches et priorités ne sont pas substitués. Deux éléments, deux catégories, leurs PNG et les JSON logiques/blobs correspondent aux preuves approuvées.

L'oracle TEMP reconstruit les pixels avec des coordonnées inverses depuis les vraies sources, sans appeler le composer produit. Il compare aussi les buffers attendus de la fixture originale : arbre 64×96, RGBA SHA `35837cd38df7ab551fe441d75c91c4efa902ed67ebb0d1471c87853909861b16` ; maison 64×96, RGBA SHA `00278c7a7959f757e26a0c9f947ee63ef68b73a83cb9c3ad2dce82362bcb36c7`. Alpha partiel, RGB sous alpha zéro, trous et padding concordent. Les neuf fichiers source ont les mêmes inventaires et SHA avant/après.

Les captures réelles incluent le refus partagé 1600×1000 `ui-1-033-0.png`, ressources 1280×800 `ui-1-084-0.png`, consentement 1280×800 `ui-1-075-0.png` et résultat 1600×1000 / 1280×800 `ui-1-080-0.png` / `ui-1-078-0.png`, sous `/private/tmp/avelune-converter-ac08-ui-z2k0qe22`. Elles sont inspectées visuellement ; pas d'overflow produit observé. Root a également inspecté le résultat et la catégorie initiale : « À classer » est visible. Le hint dormant « Référence introuvable » présent dans l'arbre Marionette ne constitue pas un défaut raster.

Reçu UI consolidé : `/private/tmp/avelune-converter-ac08-ui-z2k0qe22/ac08-native-ui-final-receipt.json`, SHA `fc649906c01b652647e1c2a35c09a9a896e76a1250afe6536ddd7c836781c25a`. Relecture : `native-fresh-readback.json`, SHA `8d66a01dff50e6e87ffb83ec83a9ffdf21e5d03fe9b82ef6036ffff8ccca360b`.

Les incidents QA sont conservés séparément : lancement initial avec stdin fermé, mauvaise forme de finder, tap hors zone visible et nullabilité du probe TEMP avant sa correction. L'exception service Marionette « element not found » n'est pas un échec produit. La fermeture normale de Flutter 74459, app 75255 et client MCP 75268 laisse zéro survivant/signal. Le build a laissé trois `ibtoold` possédés, réidentifiés puis terminés par SIGTERM avec preuve dédiée. Les PID protégés 6272, 82303 et le Studio utilisateur 61161 sont préservés.

## Parité API, JSONL, éditeur et MCP

Le writer et le parcours Converter utilisent les actions natives existantes. Les catalogues interrogés décrivent ces sept actions v1 et les ressources `asset`, `element`, `elementCategory`, `tileset`. Cette découverte ciblée n'est pas une certification globale du catalogue.

La passe JSONL/MCP utilise deux copies indépendantes du projet natif et des racines étroites. Les trois tests passent, exit 0 en 17.460 s, runner 12843 ; JSONL 8.352 s et MCP 8.591 s. Chaque transport effectue 46 appels : découverte des sept contrats, queries de cinq assets, deux éléments, deux catégories et trois tilesets, validation structure/références, puis `element.upsert` pour renommer, fermer/rouvrir et restaurer le nom. Les plans ne modifient ni fichiers ni révision ; les apply sont idempotents. Les manifests concordent entre transports et la révision restaurée retrouve `sha256:ed3c0df62123a116257c662b1df031105803fa421d152801eaac67292d1a7468`. PNG, compagnons, cartes, palettes, timelines et catalogue restent exacts. Le projet QA original est inchangé. Seule `element.upsert` est exécutée dans cette passe ; les autres contrats sont découverts, tandis que les créations sont exercées séparément par le writer et l'UI. Aucun endpoint, modèle ou API d'éditeur n'est ajouté.

MCP : `npm ci --offline --ignore-scripts`, `npm run check` et `npm run build` donnent exit 0 en 1.160 / 1.413 / 1.281 s. La première tentative des transports échoue avant `describe` : résolution `image 4.11.0` / `archive 4.0.9`, méthode `ZLibDecoder.decodeLazy` absente. Le défaut du harness est conservé ; aucun appel métier ou write projet n'a été effectué. Un override QA temporaire `image 4.10.1`, version déjà qualifiée dans adapters/Converter, puis `dart pub get --offline` (exit 0, 0.943 s) ferme ce diagnostic. Pubspec produit, dépôt hôte et 14 overlays restent inchangés ; override, lock et package config sont liés au ledger. Cette preuve ne certifie pas la résolution défectueuse ni la suite MCP globale.

Reçu final transports : `/private/tmp/avelune-converter-ac08-parity-h_2os0tu/ac08-library-parity-final-receipt.json`, SHA `78949859ec79db17ff6b93bc2238235a6cd1e35dce718c39570bfdb83ad34f6b`. Tests : `node --test --test-concurrency=1 /private/tmp/avelune-converter-ac08-parity-h_2os0tu/library_parity.test.mjs`, trois pass, zéro fail, zéro survivant/signal et PID protégés inchangés.

L'écran modifié appartient au Converter et son transport UI est exercé réellement. AC-08 ne modifie aucun écran ni commande Studio ; la bibliothèque utilise les modèles et actions d'éléments existants. L'édition visible de cette bibliothèque dans Studio n'est pas certifiée par cette passe ; les métadonnées d'ancre restent explicites. La qualification de bout en bout Kanto/Studio appartient à AC-15.

## Verdicts, critique et risques

| Passe | Verdict courant |
| --- | --- |
| Audit / Architecture, root et agents | PASS : contrats natifs existants, périmètre bibliothèque, source inerte et ancre non certifiée identifiés. |
| Implémentation proposer — `test_validation` | PASS : 16 tests, analyse ciblée et ambiguïtés/quota explicites. |
| Implémentation exporteur — `target_contracts` | PASS : 39 tests, analyse ciblée, PNG indépendant et IDs natifs conformes. |
| Implémentation writer — `runtime_contracts` | PASS : 72 tests dont 23 AC-08, recomposition et relecture exacte. |
| Implémentation workflow/UI — root | PASS : revues liées aux hashes, jobs réels, budgets préparés avant approbation et 15 tests app. |
| Build / Validation UI — `target_contracts` | PASS borné avec incidents QA déclarés, build production main, pixels/source/cartes natifs exacts. |
| Critique finale — `test_validation` | PASS scope, inventaire et rapport après suppression d'un nombre global ambigu ; reçus natifs/transports et limites concordants. |
| API / JSONL / MCP — `runtime_contracts` | PASS ciblé, 3/3 : queries natives, rename/restore, plan sans écriture, idempotence et relecture concordante. |

La critique a fermé trois P2 : budget reconnaissance incompatible avec un budget natif valide, budget fusionné pas vérifié pendant préparation et libellé « images vérifiées » trompeur pour des PNG/JSON. Elle confirme les 14 pins hôte/copie et le delta d'import public requalifié.

Limites : propositions géométriques sans certitude sémantique ; approbation humaine obligatoire ; aucune substitution de placements ; ancre consommable native non certifiée ; animations/characters/packedObjects hors bibliothèque AC-08 ; géométries partagées disjointes refusées ; messages d'incertitude internes encore en anglais dans un panneau français. Pas de preuve de conversion complète Kanto, de Player/device QA, de distribution, de publication ni d'édition visible Studio de ces objets. Les pickers natifs ordinaires ne sont pas requalifiés ici : les chemins QA sont injectés par un entrypoint distinct.

## Git, traçabilité et suite

Aucune modification étrangère n'est reprise ni restaurée. Le contrôle avant commit compte 277 chemins : 17 dans le lot et 260 étrangers. Parmi les 259 chemins étrangers initiaux, 244 restent octet-identiques et 15 portent des deltas 3D concurrents ; le nouveau test étranger `packages/map_render_3d/test/spatial_ground_replacement_test.dart` est également exclu. Leur inventaire et le reçu de garde sont consignés dans `index.json`. L'index Git est vide et les 14 pins produit/test correspondent au gel qualifié. Les 14 fichiers source/test et les trois preuves constituent exactement le scope du add/commit autorisé.

`POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` retourne exit 0, `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.` L'override borné correspond à l'Evidence Pack du kit. `git diff --check` du scope est vert, les deux ledgers sont des JSON valides et les 14 hashes sont frais. Le contrôle après commit compare le scope et les empreintes étrangères à cette garde ; son état final et le SHA sont consignés dans Notion, sans SHA autoréférentiel ajouté aux preuves versionnées. Aucun push, rebase, branche ou PR n'est réalisé.

Ticket unique : [AC-08 — Reconnaissance locale et assets approuvables](https://app.notion.com/p/3f7197a7bfa5810e8c6cdee63832e61b), grand domaine Post-bêta 14, `Gate bêta=false`. L'implémentation qualifiée sera proposée en `TO REVIEW` avec le SHA ciblé, jamais `DONE` automatiquement.

Suite autorisée après clôture technique et commit AC-08 : AC-10, revue géométrique et reprise durable des décisions. Aucun travail AC-10 n'est inclus dans ce lot.

## Complément du 13 octobre 2026 — chemins peignables et arbres entiers

Les sections précédentes conservent la livraison initiale AC-08 du commit `1813ed8ab`. Ce complément répond à la demande de ressources réellement utiles pour éditer Route 9. Il produit un preset de chemin cardinal publié et un arbre entier, depuis les pixels originaux, sans IA requise et sans substitution des placements source. Le parcours visible Studio peinture, gomme, pose, sauvegarde, fermeture puis réouverture dans un nouveau processus est vérifié. Ce résultat ne certifie ni le jeu Kanto complet ni les collisions des nouvelles poses.

### Audit initial et frontières

Base : `00abd266a39094679ccf257d944f525bd2be9bf3`, branche `main`, index vide. La garde `/private/tmp/avelune-resources-final-turn-before-20261013-01.json` compte 61 chemins dirty : 19 du complément et 42 étrangers. Les travaux mobiles, bordures, rendu et recorder Studio sont exclus. La qualification utilise une archive de cette base avec seulement les 19 overlays du complément ; chacun correspond exactement au fichier hôte. Aucun changement de branche, push, rebase ou nettoyage étranger.

L'audit confirme que les pixels des chemins existaient dans l'atlas source, mais sans preset natif utilisable ; les propositions de tuiles seules ne fournissaient pas un pinceau. Un arbre complet 64×96 est également présent dans l'atlas. Ses deux tuiles inférieures ne sont pas utilisées sur Route 9 : ce candidat est explicitement lié à l'atlas, sans faux locator Map098 ni faux claims de placements. Les modèles SmartTile, catalogues et actions canoniques existants couvrent cette publication ; aucune extension du modèle de carte cible n'est nécessaire.

Le contrat `cardinal3x3` exige catégorie terrain, canvas 96×96, neuf cellules de 32 px couvertes exactement une fois, sans transformation et sans priorité source occlusive. La configuration ou une modification géométrique invalide l'approbation. Le compilateur prélève les quadrants RGBA exacts, y compris les RGB sous alpha nul, et produit un atlas 128×128 avec 16 variantes cardinales, 16 règles explicites, sans fallback. Le preset publié `sparse` ne remplit pas automatiquement la carte. Le writer régénère les artifacts et mutations depuis les témoins source et les décisions avant tout staging ; un preset altéré puis réapprouvé reste refusé.

La reprise Kanto a révélé `json.textQuota` : les six frames répétaient les 8 167 claims. La session privée passe à 1.2 et mutualise les listes ordonnées par leur SHA, sans relever les plafonds par défaut. La restauration contrôle références, hash, budgets et provenance ; 1.0/1.1 sont refusés. Deux régressions supplémentaires sur les limites JSON personnalisées et les hashes de frames compactes ont un RED puis un GREEN dédiés. Les pins du replay Kanto initial et ceux des derniers correctifs d'historique restent distincts dans les preuves ; la reprise du store est requalifiée sur le code final.

### Inventaire du complément

Les 19 SHA, nombres de lignes et hunks exacts figurent dans `index.json.resourceComplement20261013.sourceAndTestFiles`. Git et les fichiers source restent la preuve des diffs.

| Fichier | Zones et impact |
| --- | --- |
| `packages/avelune_converter_core/lib/src/models.dart` | Enum `AssetTerrainLayout`, lignes 50–51, et getter du candidat, 251–254. |
| `packages/avelune_converter_core/lib/src/schema_catalog.dart` | Schéma embarqué de candidat, ligne 4 : champ optionnel fermé `terrainLayout`. |
| `packages/avelune_converter_core/lib/src/domain_validation.dart` | Lignes 132–169 : catégorie, grille, couverture, transformations et priorités. |
| `packages/avelune_converter_core/lib/src/asset_review_session.dart` | Pool de claims, sérialisation/restauration 1.2 et hash de frame avec les limites de session ; `configureTerrainLayout` ligne 1063 ; invalidation sur edits/union/split/vision. |
| `packages/avelune_converter_core/test/terrain_layout_review_test.dart` | Nouveau, 359 lignes : configurations admissibles, erreurs de géométrie/priorité, approbation invalidée et reprise. |
| `packages/avelune_converter_core/test/asset_review_session_test.dart` | Hunks 131–197 et 606–942 : quotas, pool exact, formats rejetés, références/hash corrompus, custom limits et undo/redo. |
| `packages/avelune_converter_core/test/vision_assistance_test.dart` | Hunk 375–384 : attentes de schéma et provenance après le changement de format privé. |
| `packages/avelune_converter_adapters/lib/src/native_terrain_brush.dart` | Nouveau, 216 lignes : compilation RGBA, atlas, variantes et règles natives explicites. |
| `packages/avelune_converter_adapters/test/native_terrain_brush_test.dart` | Nouveau, 306 lignes : oracle indépendant de quadrants, alpha/RGB caché et contrats négatifs. |
| `packages/avelune_converter_adapters/lib/src/approved_asset_library.dart` | Budgets avant allocation, compilation du terrain, publication et metadata exactes des artifacts/candidats. |
| `packages/avelune_converter_adapters/lib/src/native_project_writer.dart` | Admission fermée des mutations SmartTile, recomposition fraîche avant staging et validation après relecture. |
| `packages/avelune_converter_adapters/lib/src/converter_workflow.dart` | Actions SmartTile autorisées dans le contrat de conversion de bibliothèque approuvée. |
| `packages/avelune_converter_adapters/test/approved_asset_library_test.dart` | Lignes 19–74 : export cardinal approuvé, PNG/règles exacts et budget avant I/O. |
| `packages/avelune_converter_adapters/test/native_project_writer_test.dart` | Lignes 242–303 et fixture : écriture réelle, réouverture et refus d'un preset altéré avant staging. |
| `packages/avelune_converter_adapters/test/converter_asset_workflow_test.dart` | Lignes 16–66 et fixture 545–552 : vrai workflow bibliothèque puis publication native. |
| `packages/avelune_converter_adapters/test/native_terrain_authoring_test.dart` | Nouveau, 513 lignes : API directe et JSONL, îlot/L/T, gomme, arbre, pixels et réouvertures. |
| `packages/avelune_converter_adapters/test/support/original_asset_fixture.dart` | Fixture originale 3×3, quadrants distincts et transparence, sans média Kanto copié. |
| `apps/avelune_converter/lib/asset_review_panel.dart` | Lignes 1476–1506 : sélection guidée objet/chemin et contraintes affichées. |
| `apps/avelune_converter/test/asset_review_session_panel_test.dart` | Lignes 108–143 : sélection, invalidation de revue et feedback. |

Les trois preuves AC-08 existantes sont actualisées : ce document, `commands.json` et `index.json`. Les instruments QA, scripts temporaires, projets Kanto et médias externes restent hors commit. Exactement 22 chemins sont prévus.

### Commandes et résultats finaux

Les commandes complètes, cwd, variables source, pins, PID descendants, sorties et SHA des logs sont conservés dans `commands.json.resourceComplement20261013.runs`. Les sous-suites se recouvrent ; leurs totaux ne sont pas additionnés.

| Commande / preuve | Résultat exact |
| --- | --- |
| Core, `dart test --reporter expanded`, gel final des budgets/hashes | `00:57 +747: All tests passed!`, exit 0, 58.747 s. |
| Core, `dart analyze` | `No issues found!`, exit 0, 1.783 s. |
| Adapters, suite complète avec les trois variables source opt-in | `04:18 +672: All tests passed!`, exit 0, 262.251 s, aucun skip. |
| Adapters, `dart analyze` final 03 | `No issues found!`, exit 0, 4.042 s. |
| App, `flutter test --no-pub --reporter expanded --concurrency 2`, source opt-in | `00:36 +85: All tests passed!`, exit 0, 40.821 s. |
| App, `flutter analyze --no-pub` final 03 | `No issues found! (ran in 6.1s)`, exit 0, 7.415 s. |
| App, `flutter build macos --debug --no-pub` final 02, vrai main produit | `✓ Built build/macos/Build/Products/Debug/Avelune Converter.app`, exit 0, 19.903 s. |
| MCP, `npm run check` / `npm run build` | Exit 0, respectivement 1.232 s / 1.225 s. |
| MCP SmartTiles ciblé | 2/2, exit 0, 17.577 s. |
| Parité authoring ciblée | 20/20, exit 0, 23.707 s. |
| PMCP-085 global | Exit 1, 8.051 s : catalogue découvert, certification des transports par item incomplète ; **PARTIAL**. |
| Replay Kanto final : scan, préparation, approbation, écriture, relecture, publication | Exit 0, 1099.951 s ; une Route 9 native publiée, source inchangée, zéro Ruby exécuté et zéro appel IA. |
| Reprise de revue sur les pins finaux | Exit 0, 19.329 s ; 71 candidats, deux approbations, 8 167 claims, six frames, undo/redo et nouvelle instance du store conservés. |
| MCP réel Route 9, peinture/pose/effacement/réouvertures | Exit 0, 18.317 s ; 24 appels, quatre mutations canoniques, carte originale préservée sauf ajouts explicites. |

Les RED fonctionnels et essais échoués restent dans les reçus. Le premier replay réel a refusé le dépassement JSON ; le premier probe MCP a échoué sur une comparaison QA incluant `resourceKind`, corrigée dans le probe seulement. Les premiers lancements Studio n'ont pas accompli le parcours d'édition. Ces sorties terminales ne sont pas assimilées à une preuve produit. L'analyse adapters 01 contenait un diagnostic info d'import relatif dans un probe QA, corrigé puis analysé sans issue aux runs suivants.

Le build final laisse deux descendants `ibtoold` appartenant au runner ; leurs UID, start et commande ont été revérifiés puis ils ont reçu SIGTERM. Le reçu termine avec zéro survivant. Aucun PID étranger n'a été arrêté. Les suites et les deux sessions Studio finales déclarent zéro survivant confirmé et `protectedUnchanged=true`.

### Conversion réelle et parcours Studio

Source : `/Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto`, snapshot `5bc0f5dd57e70951cb86fe7c71114e983827251830b2b11f23ef2dab48f1c8de`. Atlas FRLG Outside 256×16192, SHA `fb9950c4130bf1201d924af4de2da65f744c7c663ac41993ce332867c24cdd81`. Le chemin utilise le crop x32/y384, 96×96 ; l'arbre x128/y1664, 64×96, ancre (32,96). Les deux candidats sont approuvés par l'agent sous la délégation explicite de Yoahn ; `humanClickedResourceApproval=false`. Les autres 69 candidats ne deviennent pas automatiquement des ressources métier approuvées.

Projet publié : `/Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - chemins et arbres 20261013-r2/output/Projet converti`, 757 fichiers, révision `sha256:d3fcb29dd0eb48e28b7ec57c0dacccc730e218732c5e127524cb654481733d54`. Route 9 : 72×61, cinq couches, 315 décors, huit animations joueur. Les 536 transitions non qualifiées restent fermées ; les 16 événements source restent quarantinés. Le spawn (35,22) est une prévisualisation, pas le départ source certifié. L'autorité de combat reste Avelune.

Studio03 ouvre une copie possédée dans son container, PID 80329. Le parcours utilise les vrais outils visibles : Terrains, sélection du chemin, peinture de L/T/îlots, Gomme et effacement, Décors et pose de l'arbre entier (34,25), puis Enregistrer. Le checkpoint instantané avec `saving=true` n'est pas une preuve de fin ; le checkpoint suivant confirme `dirty=false`, `saving=false`, `error=null` et carte mémoire égale au fichier sauvegardé. Les 14 mutations aboutissent à 11 cellules de chemin et 316 décors. Retirer uniquement la nouvelle couche SmartTile et l'arbre rend exactement la carte initiale.

Après fermeture normale par `q`, Studio04 ouvre le même projet dans un nouveau processus, PID 82744. Sa carte mémoire, sa sauvegarde disque et l'état sauvegardé du premier processus sont exactement égaux ; les outils et les ressources sont visibles dans une vraie fenêtre native levée par CUA. Le deuxième processus est également fermé normalement, puis Marionette déconnecté. Reçus `/private/tmp/avelune-resources-studio-ui-20261013-03.json` et `-04.json` : exit 0, respectivement 240.948 s et 85.493 s, zéro survivant/signal.

Les probes d'observation sont uniquement dans le snapshot QA : extension 2D en lecture seule et guard de capture limité au dossier possédé. Ils n'ajoutent aucune voie de mutation. La bannière Home « lecture seule » vient de `project_open_controls.dart:74–75`, qui l'affiche pour tout projet ouvert ; elle ne décrit pas les permissions de l'éditeur. Aucun correctif UI étranger n'est inclus ici.

La copie livrée `/Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - chemins et arbres 20261013-r2/Projet modifié dans Studio` correspond exactement aux 757 fichiers du projet Studio fermé. Le projet publié original est inchangé. Les preuves sont sous le dossier sibling `evidence`, notamment `native-resource-studio.json`, `studio-resource-delivery.json`, les checkpoints et `studio-resource-captures/studio-reopened.png`, SHA `c957ee8d8d8b301b8cc8eda415cd5758ca7a7a44749430b7c3ae7c1243be750a`. L'enregistrement de dix frames a zéro erreur. Ses flags génériques `durableSaveObserved=false` et `persistenceScope=studioTestCheckpoint` restent conservés : la preuve durable vient des fichiers sauvegardés et de la réouverture, pas du flag de la vidéo.

### Passes séparées, critique et limites

| Passe | Verdict |
| --- | --- |
| Audit / Architecture, root | PASS borné : contrats SmartTile existants, source inerte, pixels d'origine et scope bibliothèque identifiés. |
| Implémentation, root | PASS borné : approbation explicite, 16 règles cardinales et arbre entier ; aucun remplacement des placements. |
| Tests, root et qualifications isolées | PASS sur les suites finales ci-dessus ; RED, essais QA et PMCP global non vert conservés séparément. |
| Build / Validation, root | PASS build produit debug et parcours natif Studio avec sauvegarde et nouveau processus ; aucun appareil mobile certifié. |
| Critique finale, `ac12_validation_design` | PASS borné sur les 19 fichiers figés, preuves source/pixels/writer/budgets/transports et les 757 fichiers Studio/livraison ; aucun nouveau P1/P2 identifié. |

L'arbre entier garde `collisionProfile=null` : pose et persistance sont prouvées, collision et occlusion en jeu restent non certifiées. Les SmartTiles peints ne qualifient pas la navigation gameplay ; ce complément ne rouvre aucune des 536 transitions fermées. Le contrat cardinal ne prétend pas couvrir Blob47. La revue sémantique de toute la bibliothèque, les 382 autres cartes Kanto, les événements, rencontres et le parcours KAN-03 restent à faire. La release AC-16 précédente n'est pas reconstruite par ce build debug.

Auto-critique : le résultat livre enfin des outils d'édition concrets, mais seuls deux candidats métier sont approuvés. Les motifs de chemin ajoutés sont des essais d'outils, pas une refonte artistique de Route 9. Zéro appel IA démontre l'indépendance du pipeline ; cela ne démontre pas une reconnaissance sémantique automatique à 100 %. Le gate global MCP reste PARTIAL, sans élargissement silencieux du chantier ni du gate bêta.

### Git et traçabilité du complément

Les preuves initiales restent historiques. Les nouveaux champs `resourceComplement20261013` des deux ledgers consignent la base, les 19 pins, les 22 chemins, les 34 reçus, les preuves externes et les limites. Ce document est figé avant le commit : la garde immédiatement avant/après commit et son SHA final seront enregistrés dans `/private/tmp/avelune-resources-local-commit-20261013-01.json`, puis dans le ticket AC-08 existant. L'index doit rester vide après ce commit et les 42 chemins étrangers doivent conserver leurs empreintes initiales ; cette vérification conditionne la clôture technique. Aucun SHA autoréférentiel ni nouvel artifact Markdown.

Ticket unique AC-08, grand domaine Post-bêta Monde & narration inchangé, Gate bêta false. Le complément qualifié est proposé `TO REVIEW`, jamais `DONE` sans décision de Yoahn. Suite autorisée après le commit ciblé : correction bornée des codes 0 internes RMXP, puis qualification des événements réels de Route 9. Ces changements ne sont pas inclus dans ce commit ressources.
