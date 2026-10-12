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
