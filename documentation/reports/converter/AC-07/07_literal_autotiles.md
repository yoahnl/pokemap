# AC-07 — Autotiles et animations littérales RMXP

## État et portée

Le convertisseur conserve les variantes RMXP stockées, assemble leurs pixels dans un atlas natif et écrit les timelines dans le modèle Avelune existant. L'application reste `apps/avelune_converter`. Ce lot dépend d'AC-06 et utilise l'interface indépendante livrée en AC-09.

Le lot est implémenté et vérifié : oracle indépendant, pipeline natif, build final, parcours Converter et Studio, enregistrement et réouverture. Le verdict technique est PASS dans les limites décrites ci-dessous. La livraison est proposée en `TO REVIEW` après commit ciblé ; `DONE` reste une décision humaine.

Périmètre : variantes, géométries simple/standard/extended admises, clocks attestées, ressources natives, aperçu indépendant, écriture et relecture. Événements, collisions, occlusion des acteurs, gameplay et qualification complète de Kanto restent dans les lots suivants. Aucun Ruby n'est exécuté, aucun média ni script du corpus n'est ajouté au dépôt.

## Audit initial et source de référence

- HEAD initial : `f8ed3c57b0617023710f675b172a1e2ed0556bc7`, branche `main`, index vide et 259 fichiers déjà modifiés hors lot. Les fichiers concurrents, dont le travail 3D, sont exclus du commit.
- AC-06 avait différé les IDs 48–383 ; AC-07 les admet par slot et variante stockée. Les IDs 1–47 restent réservés, 0 reste vide et les tuiles ordinaires commencent à 384.
- `ProjectRegularAtlasTilesetSource.tileAnimations`, `ProjectRegularAtlasTileAnimation` et le resolver temporel canonique existent déjà. Importer puis appliquer `tileset.upsert` suffit ; aucun nouveau schéma cible ou modèle parallèle n'est nécessaire.
- Studio peignait avec `renderer.update(0)`. Un ticker limité aux ressources animées visibles alimente maintenant le renderer et déclenche une peinture quand une frame change.
- Le corpus externe autorisé est `Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto`. L'archive `Data/Scripts.rxdata` a le SHA-256 `3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d` et contient 402 sections décodées inertes.

| Fait source | Référence dans l'archive | SHA-256 de la section |
| --- | --- | --- |
| Table des 48 variantes | 75, `TileDrawingHelper`, lignes 5–18 | `2a94034ce77b68faeb8c7620e4a9cf2ceea81580992db7c86424cc3b63393bc7` |
| Géométries et overrides extended | 74, `AutotileExpander`, lignes 9–65, overrides 25–48 | `c40587686d2176794b79aa926e0adc5fdb67db102dd6f14a7e54a1618635e597` |
| Durée, suffixe et progression temporelle | 72, `TilemapRenderer`, lignes 24–26, 148–152 et 191–196 | `321f334b2eeee0f1fa45d16f52117feb7ea765e17643b88c09a69285ada4bdef` |

Le profil attesté utilise 250 ms par défaut, ou le suffixe numérique `[x]` multiplié par 50 ms. Les espaces admis par la source sont conservés ; zéro et débordements sont refusés. L'animation suit `floor(elapsed / duration) % frameCount`. L'origine locale du renderer et la vitesse de base 1× sont préservées ; les toggles de vitesse dynamiques du plugin Essentials et une phase absolue commune ne sont pas certifiés.

## Implémentation et invariants

`LiteralAutotileComposer` vérifie les bindings snapshot/fichier/profil avant lecture, les tailles et quotas avant raster, puis assemble les quarts sans blend ni colorkey. Standard : `96*N × 128`, extended : `96*N × 192`, simple : `32*N × 32`. L'atlas produit mesure `256 × 192*N` ; `localTileId = frame*48 + storedVariant`. Les voisins ne recalculent jamais une variante forcée.

L'oracle original est produit indépendamment des constantes de production : rectangles explicites et 432 goldens RGBA, soit trois formats, trois frames et 48 variantes. Les recettes originales contiennent alpha nul avec RGB caché, alpha partiel, opaque et magenta opaque. Les tests comparent les buffers, les hashes et les sources intactes.

Sans clock attestée, une image à plusieurs frames reste bloquée. Le choix d'étude explicite `allowFirstFrameAutotiles` produit une ressource statique dégradée, avec `animationVerified=false`. Toutes les frames restent dans l'atlas pour conserver les pixels ; aucune timeline vérifiée n'est inventée. Le changement de choix invalide les approbations précédentes.

Le writer admet quatre actions exactes : `tileset.import_image`, `tileset.upsert`, `map.create`, `map.save`. Les upserts sont limités aux timelines des atlas importés, précèdent les cartes et conservent identité, géométrie et propriétés. Les ressources préparées sont triées comme l'API canonique. La relecture vérifie le manifeste complet, les timelines et les cellules.

La provenance d'autotile est liée au snapshot, au fichier, au nom source normalisé, au slot, au PNG généré et au profil. Un hash de composition recalculé et une nouvelle approbation core ne suffisent pas à légitimer une contradiction. Les timelines de 48 variantes doivent correspondre aux frames exactes et à la durée dérivée du vrai nom source.

L'aperçu gauche décode le PNG original et ses rectangles source ; l'aperçu droit utilise l'atlas natif. Un test altère volontairement les pixels natifs et prouve que la gauche reste intacte. La comparaison affiche explicitement la première frame. Studio apporte séparément la preuve de mouvement.

Le ticker Studio couvre chargement, remplacement du renderer, pause/reprise, `TickerMode`, `Offstage`, opacité nulle, clip géométrique et destruction. Les cartes statiques ne programment pas de frames autonomes. Le temps passe au centre de la milliseconde canonique pour éviter le décalage flottant constaté à 1001 ms.

## Inventaire complet des fichiers

Les chemins sont relatifs au dépôt ; les hashes et hunks précis sont dans `index.json`. Les nouveaux fichiers sont entièrement dans le scope.

| Fichier | Zones finales | Raison et impact |
| --- | --- | --- |
| `apps/avelune_converter/lib/converter_app.dart` | État 96–231 ; réglage 652–664 ; ressources 751–784 | Choix de première frame explicite, réinitialisation et invalidation, compte de frames et état de dégradation visibles avec le design system. |
| `apps/avelune_converter/lib/map_comparison.dart` | Chargement/disposal 28–112 ; aperçu 247–438 ; painters 450–597 | PNG source indépendant, lecture des parties originales, colonnes réelles de l'image, limite de première frame annoncée. |
| `apps/avelune_converter/test/map_comparison_autotile_test.dart` | Nouveau, 1–142 | Témoin peint indépendant : une corruption native change seulement la cible. |
| `apps/avelune_studio/lib/platform/rendering/studio_map_visual_widgets.dart` | État/ticker 50–455 ; cycle de vie 469–565 ; painter 641–663 | Animation native visible, peinture aux changements de frame et pauses cohérentes sans timer permanent statique. |
| `apps/avelune_studio/test/platform/rendering/studio_map_visual_animation_test.dart` | Nouveau, 1–676 | 18 tests de frames, frontières, pause/reprise, visibilité, remplacement et destruction. |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | Ligne 5 | Expose le composer d'autotiles par le barrel public. |
| `packages/avelune_converter_adapters/lib/src/converter_workflow.dart` | Settings 103–189 ; worker 756–1028 ; hashes/capacités 1319–1388 ; plan 1488–1566 | Transporte le choix explicite dans le worker, l'admission et les hashes ; déclare les quatre actions réelles. |
| `packages/avelune_converter_adapters/lib/src/literal_tile_composer.dart` | Contrats 100–285 ; run 310–375 ; IDs 602–616 ; autotiles 767–870 ; palettes/mutations 881–975 ; preuves 1070–1125 | Compose les slots utilisés, préserve Z et variantes, ajoute import/timeline avant les cartes et lie la provenance. |
| `packages/avelune_converter_adapters/lib/src/native_project_writer.dart` | Préflight 605–883 ; preuves 968–1194 | Upsert strict, ordre canonique, garde de provenance avant staging et relecture complète des timelines. |
| `packages/avelune_converter_adapters/lib/src/literal_autotile_composer.dart` | Nouveau, 1–689 | Raster borné, profil attesté, parts source, atlas natif, clock partagée et provenance immuable. |
| `packages/avelune_converter_adapters/test/converter_workflow_test.dart` | 169–252 ; harness 1217–1271 | Parcours réel bloqué puis dégradation consentie, approbation courante et source intacte. |
| `packages/avelune_converter_adapters/test/literal_tile_composer_test.dart` | 284–315 | Remplace le diagnostic différé par le diagnostic géométrique et son locator source exact. |
| `packages/avelune_converter_adapters/test/native_project_writer_test.dart` | 79–174 | Timeline persistée, upsert invalide refusé et corruption de relecture détectée. |
| `packages/avelune_converter_adapters/test/literal_autotile_composer_test.dart` | Nouveau, 1–438 | 18 tests : oracle, clocks, suffixes, limites, annulation, provenance et fallback. |
| `packages/avelune_converter_adapters/test/literal_autotile_integration_test.dart` | Nouveau, 1–271 | Pipelines natifs, variantes forcées, opt-in et contradictions réapprouvées refusées avant écriture. |
| `packages/avelune_converter_adapters/test/support/literal_tile_fixture.dart` | 139–194 | Support de PNG d'autotiles originaux et copie d'archive explicitement fournie dans les tests locaux. |
| `packages/avelune_converter_adapters/test/support/native_writer_fixture.dart` | Ligne 121 | Déduit les actions de la vraie liste de mutations pour l'approbation des fixtures. |
| `packages/avelune_converter_adapters/test/support/autotile_quadrant_oracle.json` | Nouveau, 1–4973 | Table de faits source, rectangles, 432 hashes originaux et échantillons temporels indépendants. |
| `packages/avelune_converter_adapters/test/support/original_autotile_fixture.dart` | Nouveau, 1–255 | Génère les sources originales et reconstruit les attentes depuis l'oracle indépendant. |
| `packages/avelune_converter_adapters/tool/literal_autotile_probe.dart` | Nouveau, 1–134 | Probe reproductible offline, source contrôlée, attestation locale, writer réel et fingerprints avant/après. |

Trois fichiers de preuves constituent l'Evidence Pack : ce rapport, `commands.json` et `index.json`. Un seul nouveau Markdown est créé. Aucun cache, build, wrapper QA, script Ruby ni PNG du corpus n'est versionné.

## Commandes et résultats exacts

Les commandes sont exécutées depuis leur package. `commands.json` conserve les argv, durées, PIDs attribués, reçus et hashes de logs. L'opt-in local `AVELUNE_AUTOTILE_SCRIPTS_PATH` est explicite pour les tests d'attestation ; il n'ajoute aucune dépendance au corpus dans la CI publique.

| Commande / contexte | Résultat final |
| --- | --- |
| adapters : `dart test --reporter expanded`, archive locale explicitement fournie | Exit 0, 13.561 s, `00:11 +233: All tests passed!`, runner 97289. |
| adapters : `dart analyze` | Exit 0, 2.393 s, `No issues found!`, runner 2336. |
| composer seul : `dart test test/literal_autotile_composer_test.dart --reporter expanded --concurrency 1`, archive opt-in | Exit 0, 6.587 s, `00:04 +18: All tests passed!`, runner 91021. |
| composer seul : `dart analyze lib/src/literal_autotile_composer.dart test/literal_autotile_composer_test.dart` | Exit 0, 1.478 s, `No issues found!`, runner 91105. |
| Converter : `flutter test --no-pub test/map_comparison_autotile_test.dart test/converter_app_test.dart --reporter expanded` | Exit 0, 17.356 s, `00:12 +9: All tests passed!`, runner 86456. |
| Converter : `flutter analyze --no-pub` | Exit 0, 8.497 s, `No issues found! (ran in 7.1s)`, runner 93308. |
| Converter : `flutter build macos --debug --no-pub` | Exit 0, 22.004 s, `✓ Built build/macos/Build/Products/Debug/Avelune Converter.app`, runner 97288. |
| Studio : `flutter test --no-pub test/platform/rendering/studio_map_visual_animation_test.dart test/infrastructure/studio_map_resources_test.dart --reporter expanded` | Exit 0, 5.187 s, `00:01 +25: All tests passed!` : 18 nouveaux et 7 existants, runner 73786. |
| Studio : `flutter analyze --no-pub lib/platform/rendering/studio_map_visual_widgets.dart test/platform/rendering/studio_map_visual_animation_test.dart` | Exit 0, 6.155 s, `No issues found! (ran in 5.0s)`, runner 74625. |
| adapters : `dart compile exe tool/literal_autotile_probe.dart -o /private/tmp/avelune-converter-ac07-probe-b52195763dff1` | Exit 0, 25.703 s, exécutable AOT produit, runner 6656. |
| Probe AOT : `--offline --parent /private/tmp --scripts <archive locale attestée>` | Exit 0, 1.774 s, source intacte, projet vérifié, 48 timelines × 3 frames à 250 ms ; runner 8634. |
| Oracle original : extraction inerte de table/clock, puis qualification | Exits 0 ; 0.688 s / 0.677 s / 1.828 s ; 432/432 attentes indépendantes vérifiées. Analyse fixture exit 0, 0.821 s. |
| MCP : `npm run check`, `npm run build` | Exits 0, 1.218 s / 1.308 s. |
| MCP : `node --import tsx --test --test-concurrency=1 test/map_metadata_server.test.ts test/map_lifecycle_server.test.ts test/studio_resource_import.test.ts` | Exit 0, 27.749 s, 3 pass / 0 fail. |
| Probe `tileset.upsert` MCP stdio / JSONL | Exits 0, 9.293 s / 8.771 s, plan sans modification puis apply/query/validate/close/reopen concordants. |

Les runs finaux ci-dessus n'ont aucun survivant attribué et aucun signal de nettoyage. Les runs historiques interrompus ou erronés sont distingués des preuves vertes : RED du ticker absent, RED frontière 1001 ms, ordre d'atlas non canonique, ancien locator de test, chemin d'oracle dans le harness, syntaxe transitoire et assert journal incomplet. Un test Studio interrompu n'est pas qualifié vert malgré son exit 0 après TERM. Des descendants `ibtoold` d'un build intermédiaire ont été réidentifiés puis terminés ; aucun PID étranger n'est arrêté.

## Projets et transports natifs

Le probe AOT final écrit `/private/tmp/ac07-original-qualification-ZCLsuw/.avelune-converter-stage-6Osw1w/converted-autotile-fixture`. Le projet contrôlé contient une carte 8×6, les 48 variantes sur Z0 et la variante 31 forcée sur Z1. `verified=true`, `sourceUnchanged=true`, `animationVerified=true`, `degraded=false`, trois frames de 250 ms. `published=false` et `playableCertified=false` restent explicites.

Les probes MCP et JSONL utilisent des copies indépendantes de la fixture native précédente. Ils changent les 144 durées de 250 à 300 ms par l'action native, puis rouvrent le projet. Les localTileIds, géométries, PNG et cartes restent identiques ; seul `project.json` change dans les données produit. Les journaux `.pokemap/authoring` sont enregistrés séparément. Cette édition de 300 ms prouve le transport natif ; elle ne prétend pas préserver une clock source de 250 ms.

Manifeste avant : `75092d42e9b8cac8d461a59c5d99097a33762b7c852270447fcd3d691e8bfe5a`. Après : `d5cc2b9d5006294e41fd1e67e66823cdc9c519c25858c4c17c8beb72b91766ed`. La révision après apply est exactement celle de réouverture. La validation structure/références est verte ; aucune certification de capacités ou de jouabilité n'est demandée ni promue.

Le catalogue live expose les quatre actions v1 utilisées. Son audit global reste `PARTIAL` : 397 actions de mutation, 88 ressources dans le résumé du catalogue, `transportCertificationComplete=false` et `itemTransportCertificationComplete=false`. Cette preuve ciblée n'étend pas la certification aux autres actions.

## Parcours en fenêtres natives

Studio isolé, bundle `com.yoahnl.pokemap.editor.ac07qualification` : trois phases observées, puis séquence `0 → 1 → 2 → 0` après navigation Accueil → Carte. La première et la quatrième capture ont le même SHA PNG. Les quatre centres opaques des quarts de la cellule forcée correspondent exactement à la variante 31 sur Z1 pour chaque phase, au-dessus de Z0. Les semi-transparences restent compositées par Studio.

Le parcours peint réellement `localTileId=18` en `(7,5,Z2)`, constate `dirty=true`, clique Enregistrer puis constate `dirty=false`. Après fermeture normale et nouvelle instance, le nom `AC07 native timeline saved`, la cellule `19` et la variante forcée `32` sont retrouvés. Les 48 animations × 3 frames × 250 ms, le record complet d'atlas et son PNG sont intacts. La carte sauvegardée porte le SHA `54a7b6ff13093e92d8151a01c80a67ef07c41e8210d5386fb64096910270e493`.

Studio a produit 31 PNG natifs, dont 20 liés à une timeline persistée ; viewport réel 1600×921. Le build utilise une copie propre de HEAD avec seulement le widget et son test superposés, sans les deltas 3D concurrents. Le binaire qualifié porte le SHA `7b3870ea33ce2e2ab398ab071426869093567fe7058bda942e79b5b1ac9170e2`. Les deux lancements produisent `✓ Built build/macos/Build/Products/Debug/Avelune Studio.app` et les hot restarts retournent `code:0`. Les horodatages de peinture et latences d'encodage prouvent les phases, pas une cadence de capture exactement à 250 ms. Le masque de pause a persisté après un timeout transport ; la reprise debug Offstage a été refusée par une boundary dirty et n'a aucun verdict natif PASS. Les tests déterministes portent séparément ces garanties de cycle de vie.

Converter isolé, bundle `com.yoahnl.avelune.converter.ac07qualification` : préparation bloquée sans clock ; accusé de lecture seul toujours insuffisant ; choix explicite de première frame puis préparation admissible à la révision 5. Les trois frames et le badge de dégradation sont visibles. L'état final garde `approvalHash=null`, `result=null`, zéro checkpoint d'écriture et une destination vide. Les ressources et comparaisons ont des captures réelles 1600×1000 et 1280×800. Son hot restart, bootId changé, reconnexion MCP, nonce et racines sont vérifiés.

Le probe Flutter des painters publics, alimenté par le workflow réel, produit zéro pixel différent à 1× (256×192, SHA RGBA commun `b15b902eeb86f6d0860975bf9d54d68b04aca5304aecd9bdff93d8d9c071e5fd`) et 2× (512×384, SHA commun `2c92d5492a122eed7f435960d47e82e99b5c60bc9cd4eb03d3ecb153ef2aeec2`). À `284/192`, 3848 pixels diffèrent dans le témoin hors écran : sampling par quarts contre tuiles. La barre UI ne fournit pas de preset entier exact ; cette preuve à 1×/2× reste un rendu hors écran distinct des captures UI. Aucune égalité pixel d'écran à zoom fractionnaire n'est affirmée. Une référence source optionnelle vide s'affiche actuellement comme image manquante dans Ressources ; cette observation est conservée, sans correction hors lot.

Reçus complets : Studio `/private/tmp/avelune-converter-ac07-ui-runtime-contracts-20261012/ac07-native-studio-receipt.json`, SHA `bb80a208c3b83c8cbe8cdec10b8c64d46bf71ec83e55ecb733aba49206e47faf` ; Converter `/private/tmp/avelune-converter-ac07-ui-0lu9qp08/ac07-converter-ui-qualification-receipt.json`, SHA `76b83d11aeae3f54515d30f5c1bf859fd52b113998644f8d456acfd105cf5ed2`. Les wrappers Marionette restent temporaires et séparés des entrypoints de production. Les sources originales, stages originaux et pins produits restent inchangés ; les deux qualifications se terminent sans signal et sans processus possédé survivant.

## Verdicts, critique et limites

| Passe / agent | Verdict courant |
| --- | --- |
| Audit / Architecture | PASS : source inerte, clocks et contrats natifs identifiés ; pas de nouveau schéma. |
| Implémentation raster — `target_contracts` | PASS : 18 tests finaux, suffixe borné, source et goldens indépendants. |
| Tests / oracle — `test_validation` | PASS : 432 attentes et source de clock ; aucune table de production importée. |
| Implémentation Studio — `runtime_contracts` | PASS : 25 tests, analyse des deux fichiers, phases natives, boucle, variante forcée, peinture, sauvegarde et réouverture. |
| Build / Validation — root | PASS : 233 tests adapters, 9 widgets, analyses, build Converter et AOT finaux. |
| Critique finale — `test_validation` | PASS statique après fermeture de trois P2 ; ne remplace pas les tests exécutés. |
| Delta UI Converter — `target_contracts` | PASS borné : workflow et captures réels, option explicite, zéro écriture ; limite du zoom fractionnaire qualifiée. |
| Critique du rapport — `test_validation`, consolidation root | PASS : inventaire et scope relus contre le code gelé ; reçus natifs, JSON et captures consolidés séparément. |

La critique a trouvé trois problèmes concrets, tous corrigés et vérifiés : un aperçu source alimenté par l'atlas natif ; une provenance interne contradictoire acceptée après recalcul des hashes ; une durée uniforme arbitraire pouvant se faire passer pour la clock source. Les tests altèrent réellement les pixels, rehashent et réapprouvent les drafts falsifiés pour prouver le refus avant staging.

Limites conservées : profil de clock lié à l'archive attestée, vitesse 1×, phase du preview réinitialisée au remplacement du renderer ; fallback statique explicite pour les profils inconnus ; visibilité géométrique/framework sans déduction d'occlusion par macOS ou par un widget opaque superposé. Les géométries atypiques sont refusées. Pas de preuve de conversion intégrale de Kanto, de Player/device QA, de gameplay ou de publication.

## Git, traçabilité et suite

Avant commit : les 259 fichiers étrangers initiaux sont byte-identiques, les 20 fichiers source/test du lot ont leurs hashes gelés et l'index était initialement vide. Le scope attendu est exactement ces 20 fichiers plus les trois preuves. Le header régénéré du registrant macOS a été remis à ses octets initiaux ; il est exclu du lot. Les PID protégés 6272, 82303 et le Studio utilisateur ne sont pas touchés.

`POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` retourne exit 0, `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.` L'override borné correspond à l'Evidence Pack du kit. Le run sans override du sous-agent Studio retourne exit 1 sur ce même rapport créé en parallèle par root ; il ne signale aucun Markdown écrit par cette qualification. Les JSON sont valides, les 20 hashes concordent et `git diff --check` du scope est vert. L'état final après commit est contrôlé et consigné dans Notion avec le SHA, sans modifier les preuves pour introduire un SHA autoréférentiel.

Ticket unique : `AC-07 — Autotiles et animations littérales RMXP`, https://app.notion.com/p/3f7197a7bfa581f4b486c386429eb1e9, grand domaine Post-bêta 14, `Gate bêta=false`. Le SHA du commit contenant ce rapport et l'état final doivent être consignés dans le ticket après commit ciblé. Aucun push, rebase ou PR n'est effectué.

Suite proposée après le commit AC-07 : AC-08, propositions locales de décors et bibliothèque approuvée, en conservant intégralement les cartes littérales. Son audit en lecture seule confirme les actions existantes `element.upsert`, `element.batch_upsert`, `element_category.upsert` et `tileset.import_image`. Les parties disjointes ne seront pas encodées comme des frames temporelles, et l'ancrage du candidat ne sera pas présenté comme consommé par une définition native qui ne le supporte pas.
