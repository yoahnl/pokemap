# AC-04 — Normalisation des maps et ressources

AC-04 produit une IR RMXP traçable et une archive inerte des données admises. Gate technique **PASS** : les tests MAP-01..04 et IR-04 sont couverts, les suites antérieures passent et le corpus Kanto normalise **383 maps sur 383**. Le projet Kanto complet reste **bloqué pour la planification** par 32 références d’images absentes et une incohérence de métadonnées de tuile. Le profil Essentials reste `requiresConfirmation`. Aucun projet cible ni comportement gameplay n’est attesté par ce lot.

## Scope et audit initial — Gate 0

Application finale : `apps/avelune_converter`. Le but humain est de convertir des jeux RPG Maker XP / Pokémon Essentials en projets natifs éditables Avelune Studio. Le kit fourni sert de spécification ; il n’autorise pas l’exécution de scripts Ruby provenant du jeu. Le goal humain autorise tous les lots et un commit entre lots ; aucun push, rebase ou changement de branche n’est autorisé.

Départ : branche `main`, HEAD `ab99297dc9204e4cc775d37ae54caaf97931a11a`, index vide, **257 chemins étrangers déjà modifiés ou non suivis**, scope convertisseur propre. Leurs empreintes figurent dans `commands.json` ; les 257 restent inchangées après implémentation. Les PID désignés par l’utilisateur ont été laissés tranquilles.

Audit des contrats : `SourceMapIr` impose trois couches, leurs tailles exactes, les coordonnées d’événements, des locators cohérents et des références d’inconnus. Il n’exprime ni la hiérarchie MapInfos ni les tables de tileset. Ces données sont portées par un catalogue typé autour de l’enveloppe existante. Les sept schémas ne changent pas. Oracle de structure lu, sans exécution ni copie de Ruby : `/Users/karim/Project/pokemonProject autre dossiers/pokemonsdk-development/scripts/0 Dependencies/1 LiteRGSS2/999 RMXP_DATA.rb`, Map lignes 149–175, MapInfo 176–183 et Tileset autour de 642.

Succès attendu : conserver IDs espacés, ordre des couches/pages/commandes, provenance de chaque entité et inconnus `preservedOnly` ; un média absent bloque précisément ; les extractions identiques ont le même hash canonique. Non-objectifs : writer natif, composition raster, reconnaissance d’assets, UI, gameplay, exécution de scripts et modification des sources.

## Implémentation et décisions

Les identités suivent namespace/domaine/ID source, avec un domaine d’événement limité à sa map. Le nom ne définit pas l’identité. Les parents MapInfos restent une hiérarchie non spatiale ; parents absents et cycles produisent des diagnostics. La sélection est figée avant toute lecture asynchrone et les maps non traitées après refus apparaissent explicitement.

Chaque fichier Marshal admis est stocké une fois avec ses bytes originaux, son SHA et son arène immuable. Les références lient fichier, contenu, nœud, politique du décodeur, localisation binaire et locator. Le roundtrip recontrôle SHA/base64 puis re-décode inertiellement ; il conserve alias, cycles, bytes inconnus et flottants non finis. L’archive est scellée avant retour.

Les maps gardent trois couches de cellules dans l’ordre X, Y, Z original, unités de tuile 32×32, événements, pages et commandes bruts. Une cellule signée négative bloque ; aucun clamp ou réinterprétation implicite n’est appliqué. Les tables passages/priorités/terrain restent source et leur interprétation gameplay relève d’AC-12.

Les paramètres scalaires, textes stricts et listes JSON projetables gardent leurs positions. Les autres paramètres sont référencés intégralement via `preservedParameterRefs`, index typé qui fait autorité. Un hash Ruby contenant déjà la clé `preservedDataRef` reste lui-même conservé brut. Les avertissements sont regroupés par fichier ; toutes les positions et données restent accessibles.

La résolution d’images utilise exclusivement l’inventaire admis : chemin original, fileId, SHA, owner et locator. Absence, ambiguïté, chemin invalide et slot vide utilisé bloquent. Les graphismes de tuiles d’événements participent aussi aux dépendances. Aucune image de substitution n’est créée.

Le lecteur lié au snapshot conserve les vrais nœuds autorisés par `MacOsSourceTree`. Il vérifie manifeste/politique avant lecture, réserve tentatives et bytes avant I/O, vérifie longueur/SHA et rend des bytes immuables. `verifyUnchanged()` encadre le batch. `crypto 3.0.7`, déjà transitif, devient direct dans adapters ; `dart pub get --offline` a changé uniquement cette classification.

Budgets distincts, validés et vérifiés avant les allocations pertinentes : bytes fichier/total, maps, cellules, événements, commandes, projection des paramètres, metadata de tilesets, nœuds/texte IR, diagnostics, archive/refs et représentation base64. Les quotas agrégés de graphe sont transmis au décodeur selon le reliquat. Le hasher du catalogue a des plafonds cohérents ; ceux des sept enveloppes restent inchangés.

## Fichiers et zones modifiées

| Fichier | Zones / rôle / impact |
|---|---|
| `packages/avelune_converter_core/lib/avelune_converter_core.dart` | Deux parts additives pour archive et normalisation. |
| `packages/avelune_converter_core/lib/src/source_archive.dart` | Lignes 3–40 budgets ; 42–80 fichier/ref ; 82–447 archivage, JSON, hash, seal et contrôles ; helpers jusqu’à 690. Conservation brute bornée. |
| `packages/avelune_converter_core/lib/src/source_normalization.dart` | Lignes 3–50 budgets ; 52–303 catalogue, locators, identité et hash ; 305–322 entrée ; 324–1290 normalizer, hiérarchie, maps/events/params, média, metadata et refus. |
| `packages/avelune_converter_core/test/source_archive_test.dart` | 633 lignes, **30 tests**, inertie/roundtrip, intégrité, quotas et ordre préallocation. |
| `packages/avelune_converter_core/test/source_normalization_test.dart` | 1008 lignes, **38 tests**, fixtures originales Marshal/PNG, MAP/IR et régressions adversariales. |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | Export additif de SnapshotSourceFiles. |
| `packages/avelune_converter_adapters/lib/src/snapshot_source_files.dart` | Lignes 6–133 bind/read/verify ; 135–265 admission/manifeste ; 269–287 records/sink. SourceFilePort lié au snapshot. |
| `packages/avelune_converter_adapters/test/snapshot_source_files_test.dart` | 538 lignes, **39 tests**, dont trois fixtures natives macOS, mutations/symlinks et quotas. |
| `packages/avelune_converter_adapters/pubspec.yaml` | Dépendance directe crypto, sans nouvelle version téléchargée. |
| `tools/avelune_converter_cli/test/native_normalization_corpus_test.dart` | 111 lignes, probe opt-in du corpus réel, couverture des IDs/refus, SHA et manifeste final. |
| `documentation/reports/converter/AC-04/04_source_normalization.md` | Rapport consolidé : audit, scope, zones, décisions, résultats, critique et limites. |
| `documentation/reports/converter/AC-04/commands.json` | Receipts exacts, stdout, PIDs observés, source, gates et empreintes. |
| `documentation/reports/converter/AC-04/index.json` | Inventaire/hash de l’Evidence Pack, sans hash récursif de soi. |

Diffs des fichiers suivis : deux lignes `part` core, un export adapters et une dépendance pubspec. Les fichiers créés contiennent uniquement le lot. Les sources et le diff Git sont les preuves canoniques ; aucun snapshot Markdown de code n’est créé.

## Tests, RED/GREEN, analyse et build

| Commande / cwd | Résultat final exact |
|---|---|
| `dart test --reporter json --concurrency 1` — core | Exit 0, **566 success / 0 skipped / 0 failure / 0 error**, 27.835 s, runner 16923. |
| Même commande — adapters | Exit 0, **65 success / 0 skipped / 0 failure / 0 error**, 7.857 s. |
| Même commande — CLI | Exit 0, **22 success / 3 skipped / 0 failure / 0 error**, 8.952 s. |
| `dart analyze` — chacun des trois packages | Exit 0, **No issues found!** pour chacun. |
| Format ciblé avec `--output=none --set-exit-if-changed` | Exit 0 ; core 5 fichiers, adapters 3, CLI 1 ; **0 changed**. |
| `git diff --check` | Exit 0, aucune sortie. |
| `dart pub get --offline` — adapters | Exit 0 ; crypto 3.0.7 passe de transitif à direct. |
| Probe corpus natif, variable `AVELUNE_CONVERTER_TEST_SOURCE` explicite | Exit 0, 41.124 s ; 1 test exécuté. |
| Compilation AOT du programme de normalisation | Exit 0, 3.665 s ; exécution réelle exit 0, 38.487 s, runner 16602. |

Les trois skips CLI par défaut sont les deux probes de corpus exigeant une source explicite et le cas de plateforme déjà présent. Le probe de normalisation a été exécuté séparément avec le chemin autorisé. Ils ne sont pas présentés comme des tests natifs exécutés sans source.

RED initial normalizer : 32 tests, 2 verts / 30 rouges exclusivement sur le stub, exit 1, 3.115 s, runner 95650. Deux findings supplémentaires reproduits rouges : sélection mutable et image d’event tile omise, exit 1, runner 296. Quatre autres : metadata/IR nodes/IR text et directory usurpant MapInfos, exit 1, runner 6842. Deux attentes de locator du harness ont été corrigées : un budget 1 nœud / 4 caractères bloque MapInfos avant lecture de Map001. Le replay global couvre les 38 tests et les assertions de scope ajoutées ensuite.

Archive : RED puis GREEN 30 tests, avec les quotas de graphes cumulés et garde avant base64. Adapter : RED 38 tests sur stub, puis 39 nouveaux verts, avec flux de chunks vides refusé en amont. Une compilation intermédiaire a croisé un scaffold core absent, puis un getter digest incorrect : elles ne sont pas comptées comme RED comportementales. Un info lint initial a été corrigé. Le premier corpus réel a refusé le quota de 10000 diagnostics à Map101 ; la correction regroupe seulement les messages répétés, sans supprimer les références.

Tous les receipts supervisés finaux montrent **aucun survivant confirmé et aucun signal envoyé**. Les PID/commandes/heures de démarrage et descendants figurent dans `commands.json`. Aucun processus étranger n’a été terminé.

Artefact AOT local : `/private/tmp/avelune-converter-ac04-bWfEjz/normalization-probe`, **6617616 bytes**, SHA `9f9f2cf61b2b9fde11d89c99ead2ca7250ae5d2528c7cc2284f1d538872e93f7`. Il compile et exerce réellement core+adapter. Aucun build Flutter desktop ni lecture native Studio n’est requis ou attesté avant les lots correspondants.

## Corpus Kanto — preuve et limites

Source exacte : `/Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto`. Snapshot frais identique à AC-02 : `5bc0f5dd57e70951cb86fe7c71114e983827251830b2b11f23ef2dab48f1c8de`. Métadonnées avant/après identiques : `e8d978ec0c595a62d359051af11e0c20dd4d0a2bba4f191dfffa45cac441e2cd`, 24273 entrées, 24085 fichiers, 188 dossiers, 627480323 bytes, aucun lien ni fichier spécial.

Normalisation complète des fichiers de maps : **383/383**, hiérarchie 383, 19 tilesets utilisés, **3941 events**, **59115 commands**, **1456380 cells**. Archive : **385 fichiers**, **7639106 bytes**, **35563 refs**, **20991 paramètres conservés bruts**, 2832 références d’images résolues. Aucun ID de map refusé ou non traité. Hash IR `08178e6eda9453bf10823a155259b67532a3ff522ff73a0e61705cae9e324377`.

Le résultat complet `canPlan=false` est correct : **33 diagnostics bloquants** (32 missing_image, 1 tile_metadata_missing). Les 309 avertissements de paramètres et 383 avertissements de champs conservés expriment une conservation, pas du gameplay supporté. La version Essentials n’est pas confirmée.

Le probe AOT sélectionne **1, 8, 120**, normalise exactement ces trois maps, conserve cinq fichiers, expose zéro map non traitée et zéro diagnostic bloquant AC-04 : `canPlan=true`, hash `a52d1e45694b795dacf8409b67fbf62c37f9a3e87de53942ace032cecea04bb7`. Cette admission de sous-ensemble ne qualifie pas le jeu complet.

`Data/PkmnAnimations.rxdata` reste refusé par quota de chemins lors d’AC-03 ; il est hors scope des fichiers map/tileset lus ici. Aucun script source n’a été exécuté, aucune ressource du jeu copiée dans le repo et aucune source modifiée.

## Passes, critique et auto-critique — Gate finale

Audit/Architecture : test_validation **PASS statique**. Implémentation : root normalizer, runtime_contracts archive, target_contracts lecteur. Tests : test_validation fixtures/RED ; owners focused et root replay global/build/corpus. Critiques croisées : test_validation normalizer **PASS**, target_contracts archive **PASS borné**, runtime_contracts adapter **PASS borné**. Les SHA relus sont ceux de l’inventaire final.

Findings corrigés : sélection mutée pendant await, event tile manquant, budgets metadata/IR/graph agrégés, required-file directory, ordre prébase64. Limite conservatrice acceptée et testée : un nouveau fichier exige au moins un lien de capacité restante, même un scalar zéro edge. Le SHA/ID assure l’intégrité des annotations, sans authentifier leur auteur ni prouver seul la sémantique d’un locator. Le normalizer fournit l’enveloppe snapshot/namespace.

La mémoire est bornée par les plafonds d’admission avec copies temporaires ; aucune mesure RSS n’est revendiquée. Le filesystem n’est pas un snapshot atomique : chaque fichier lu est rehashé, et le contrôle final compare tokens/manifeste, sans rehash de tous les fichiers non lus. Qualification native macOS arm64 seulement.

MCP parity : **N/A pour AC-04**, lecteur externe pur sans mutation de projet cible/commande d’authoring/UI/runtime. AC-05 doit réévaluer les API canoniques et transports lors du writer natif ; la persistance JSON ne prouvera pas à elle seule l’import natif.

Git pré-commit : toujours main/HEAD de départ, index vide, 267 chemins dirty dont 10 appartenant au lot, **257 étrangers intacts**. Après ajout des trois preuves, seul le lot de 13 fichiers sera staged/commité. Le SHA effectif et l’état Git post-commit sont projetés dans Notion afin d’éviter une référence récursive de commit dans le rapport.

Verdict : **AC-04 prêt techniquement à la review**, ticket **TO REVIEW** après commit/preuves. Le goal global reste actif. Prochain lot : **AC-05 — writer natif minimal**, sans considérer les 383 maps comme une conversion finale livrée.
