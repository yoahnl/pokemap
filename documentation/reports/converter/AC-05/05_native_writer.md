# AC-05 — Writer natif minimal Avelune

Date : 12 octobre 2026. Application finale : `apps/avelune_converter`.
Périmètre : NAT-01, NAT-02, NAT-03 et NAT-04 du kit. Départ : `ec67aa009c67204f2fb71509a903c0dedd74be11`, branche `main`.

## Verdict et preuve utile

**PASS technique AC-05 ; TO REVIEW humain.** Le writer crée un projet Avelune vide 2D avec grille explicite de 32 px, importe un PNG, crée et sauvegarde une carte native puis ferme et rouvre une session stricte pour vérifier le contenu réellement persisté. Le reçu atteste `verified=true` et `published=false`.

Le code Studio actuel, exécuté dans le moteur Flutter de test, charge ce projet, décode le PNG 64×32, modifie une cellule et le nom de la carte, sauvegarde puis retrouve exactement les données et la révision avec de nouvelles instances. Le MCP connecté modifie ensuite les métadonnées avec un plan lié à une révision fraîche et confirme leur persistance après fermeture et réouverture.

Cette preuve porte sur une fixture originale 3×3, avec deux tuiles. Elle ne prouve ni la conversion visuelle de Kanto, ni le gameplay des événements, ni une observation de la fenêtre Studio. `uiObserved=false` ; aucune publication finale.

## Audit initial et décisions

L’objectif humain est une application indépendante convertissant RPG Maker XP / Pokémon Essentials en projets Avelune Studio éditables. Le kit fournit les critères du lot. L’autorisation humaine de réaliser tous les lots et de commiter entre lots est distincte de ces instructions documentaires.

L’index était vide. **257 chemins étrangers préexistants** étaient dirty ou untracked : aucun d’eux n’entre dans ce lot. Leurs SHA et le statut initial sont conservés dans `commands.json`. Les 15 contrats natifs audités sont issus du checkout local actuel, dont certains fichiers étaient déjà dirty. Ils sont restés identiques ; cette preuve ne certifie pas les autres modifications de ce checkout.

Services publics utilisés : `LocalProjectCreationService`, `ProjectOpenService`, `ProjectSnapshotLoader` et `LocalMapAuthoringMutationApi`. Les seules mutations du writer sont `tileset.import_image`, `map.create` et `map.save`, version 1. Les modèles cibles et les sept contrats core existants ne changent pas.

Un `NativeProjectDraft` immuable lie le hash de l’IR normalisé, les IDs source/cible, les artifacts, la destination et l’ordre exact des opérations avec leurs paramètres. Chaque opération du plan doit contenir la preuve `native-draft-sha256:<hash>`. L’admission et ce binding précèdent toute écriture, inflation PNG ou allocation de pixels.

La sortie est un enfant d’un staging privé sous le parent explicitement choisi. Le writer vérifie la source et la destination, refuse les destinations existantes, garde le staging en cas d’échec ou d’annulation et ne promeut jamais le résultat. Les gardes contrôlent aussi le projet enfant sans suivre un lien et la politique native autorise le staging validé. La promotion appartient à AC-15.

## Inventaire des fichiers et zones modifiées

| Fichier | Zone / responsabilité |
|---|---|
| `packages/avelune_converter_adapters/lib/src/native_project_writer.dart` | Nouveau, 1 159 lignes : limites et modèles immuables ; writer ligne 307 ; préflight ligne 541 ; confinement ligne 896 ; composition native ligne 943 ; validation PNG ligne 986. |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | Export public du writer ajouté. |
| `packages/avelune_converter_adapters/pubspec.yaml` | Dépendances publiques map_authoring/map_core/path/image ; image fixé à 4.10.1. |
| `packages/avelune_converter_adapters/test/native_project_writer_test.dart` | Nouveau, 909 lignes : 46 tests, NAT-01..04, admission, source/destination, corruption, annulation et quotas. |
| `packages/avelune_converter_adapters/test/support/native_writer_fixture.dart` | Nouveau, 509 lignes : RMXP original minimal, normalisation réelle, plan/draft et attendus natifs. |
| `packages/avelune_converter_adapters/tool/native_writer_probe.dart` | Nouveau, 68 lignes : qualification AOT originale offline, hashes source avant/après, résultat JSON. |
| `documentation/reports/converter/AC-05/05_native_writer.md` | Rapport consolidé du lot. |
| `documentation/reports/converter/AC-05/commands.json` | Commandes, résultats, audit initial, SHA et preuves natives/MCP. |
| `documentation/reports/converter/AC-05/index.json` | Index des preuves et SHA des artifacts. |

Le diff des deux fichiers suivis existants est limité à l’export et aux dépendances ci-dessus. Les quatre nouveaux fichiers Dart sont les seules additions de code. Aucun fichier du moteur, Studio, MCP ou corpus Kanto n’a été édité.

## Passes, défauts trouvés et critique indépendante

Les passes Audit/Architecture, Implementation, Tests, Build/Validation et Critique ont été menées séparément. Les agents `target_contracts`, `test_validation` et `runtime_contracts` ont conclu PASS sur le writer gelé SHA256 `4f12cf445fe5be5a057e87b22a43b4eea5420d3a4b77c4df5d0b4b53d1b1889c`. Le parent a consolidé les preuves, rejoué les suites core/CLI, les analyses et les transports ciblés.

Le premier échec de compilation était une incompatibilité réelle : image 4.11.0 appelle `decodeLazy`, absent de l’archive 4.0.9 fixé par les packages natifs. Le lot fixe uniquement sa dépendance image à 4.10.1 ; les manifestes cibles et leurs pins ne sont pas modifiés. L’inflation IDAT de cette version étant intégrale, le writer valide d’abord le flux avec `BoundedZlibDecoder` selon les scanlines attendues.

Le RED compilable NAT-01 a échoué sur le stub avec `UnimplementedError`. Il est distinct de l’échec de compilation initial. La critique a ensuite détecté deux défauts corrigés : le budget total de pixels contrôlé après le décodage du prochain PNG, et le projet enfant remplacé par un lien qui pouvait s’auto-autoriser hors staging. Des régressions vérifient maintenant l’ordre du refus et l’identité exacte du projet extérieur resté intact.

Le premier probe AOT a révélé une troisième erreur : `receipt.beforeRevision` est l’empreinte des ressources touchées, pas celle du snapshot global. Le writer contrôle désormais les IDs exacts plan/opération, statut/action/version et les empreintes du reçu, puis la vraie révision globale résultante et une lecture fraîche. Référence cible : `packages/map_authoring/lib/src/transactions/journaled_transaction.dart:145`.

Le premier full ciblé conserve 45 succès et un échec du harness, avec modification concurrente du writer pendant compilation. Le harness construisait un plan `approvedByHuman=false` avant son attendu alors que le contrat refuse immédiatement cette forme. Le refus de `source.canPlan=false` au constructeur du draft a également été attendu à son vrai point de contrôle. Les passages GREEN finaux portent sur des SHA stables avant/après.

## Vérifications fraîches

| Commande / preuve | Résultat exact | Durée |
|---|---|---:|
| Core : `dart test --reporter expanded --concurrency 1` | Exit 0, `00:19 +566: All tests passed!` | 20,700 s |
| Adapters : même commande | Exit 0, `00:07 +111: All tests passed!` ; 39 snapshot + 26 filesystem + 46 writer | 9,001 s |
| Writer ciblé : `dart test test/native_project_writer_test.dart --reporter expanded --concurrency 1` | Exit 0, `00:04 +46: All tests passed!` | 6,039 s |
| CLI : `dart test --reporter expanded --concurrency 1` | Exit 0, `00:11 +22 ~3: All tests passed!` | 17,064 s |
| `dart analyze`, core / adapters / CLI | Tous exit 0, `No issues found!` | 1,266 / 2,527 / 2,779 s |
| Format des cinq fichiers Dart du lot | Exit 0, `Formatted 5 files (0 changed) in 0.04 seconds.` | 0,388 s |
| `dart compile exe tool/native_writer_probe.dart -o /private/tmp/avelune-converter-ac05-native-probe-final` | Exit 0 | 20,891 s |
| Exécutable final `--offline --parent …/.dart_tool/avelune_converter_ac05` | Exit 0, source inchangée, vérifié, non publié | 0,206 s |
| Sonde Flutter avec vrais adapters Studio, `flutter test --no-pub --reporter expanded /private/tmp/avelune-converter-ac05-runtime-contracts-20261012/ac05_native_probe_test.dart` | Exit 0, `00:00 +1: All tests passed!` | 5,810 s |
| Authoring : `dart test test/parity/full_authoring_parity_test.dart --reporter expanded --concurrency 1` | Exit 0, `00:17 +20: All tests passed!` | 18,684 s |
| MCP : `npm run check` | Exit 0 | 3,535 s |
| MCP ciblé : `node --import tsx --test --test-concurrency=1 test/map_metadata_server.test.ts test/map_lifecycle_server.test.ts test/studio_resource_import.test.ts` | Exit 0, 3 pass / 0 fail | 26,132 s |

Les trois skips CLI sont explicites : deux qualifications locales demandent leur source via environnement et un scénario non-macOS ne s’applique pas à cet hôte. La qualification AC-05 utilise son probe AOT ; elle ne transforme pas ces skips en succès de corpus Kanto.

L’exécutable final fait 20 554 816 octets, SHA256 `ff7e7ec6a7f17d5b9575a94676f450ab4b5e5aef4f52f8aeef3c333211a67a6c`. Il n’est pas commité. Le projet frais est `/Users/karim/Project/pokemonProject/.dart_tool/avelune_converter_ac05/ac05-original-qualification-NV7mrs/.avelune-converter-stage-SFSer7/converted-fixture`. Sa carte initiale a le SHA `414a5adafa1e7c00daf31fbf03283de1a3e07a5f2dc7b0e0af6d62551a9c3dfe` ; le PNG original et logique a le SHA `cdf2d8a706a6f0c0dfc4f4b04fec03b42d83052dc75155e130ded42f1aee6890`.

La sonde Studio et le MCP ont exercé une autre création du même writer/fixture, avec les mêmes hashes initiaux, dans `/Users/karim/Project/pokemonProject/.dart_tool/avelune_converter_ac05/ac05-original-qualification-btVY5k/.avelune-converter-stage-axODER/converted-fixture`. Studio a modifié la cellule 0 de 1 à 2, sauvegardé et rechargé le SHA de carte `b12df8da3089f33f4c24c7556a9c8a669882bdf0df07739c2085a490a976dab3`. Manifeste et image sont restés identiques pendant ce save. Les champs `reads=1`, `decodes=1`, dimensions 64×32 et diagnostics vides proviennent du vrai `StudioMapResources`.

Le catalogue MCP live décrit `pokemap.authoring.v1`, 397 actions, dont les trois actions du writer et `map.update_metadata` v1. L’édition sémantique plan/apply/reopen de la fixture conserve palette, cellules, image et identité ; la révision globale finale est `sha256:5153aca01f48b10e775b9095bef10efdcb1a5b716c2ed29bfdea694480ff3d87`. Structure et références sont valides. La certification de capacités n’a pas été demandée ; la section capabilityTruth sans capacités promues ne constitue pas une certification Player.

Les runners et leurs descendants ont été identifiés et contrôlés. Aucun survivant confirmé ni signal envoyé pour les suites consolidées. La sonde Flutter a observé runner 85809, compiler 85895 et flutter_tester 85946 ; ses 17 processus owned ont terminé. Les PID protégés 6272/82303 et l’application 61161 sont inchangés.

## Parité et limites des gates générales

Aucun nouveau comportement d’authoring cible n’a été ajouté ; les trois actions canoniques existantes sont utilisées. La preuve directe/native, le golden API/JSONL du test de parité, la consommation Studio, les trois tests MCP ciblés et le MCP connecté couvrent ce périmètre. Le job de conversion est une composition propre au convertisseur, dont l’interface sera AC-09.

**La santé globale du MCP reste PARTIAL.** Le `npm test` général a fait son build puis s’est terminé exit 1 en 776,722 s, avec des échecs visibles sur les schémas stricts, le batch de modèles et le remplacement de modèle. Sa capture de sortie a été tronquée ; aucun total exact n’est revendiqué et aucune sortie intégrale n’est inventée. Aucun fichier de ce serveur n’a été modifié dans AC-05.

`dart run tool/pmcp085_conformance.dart` sort également 1 : catalogue complet, 397 mutations, 0 contrat bloqué/manquant ; seulement 103 mutations entièrement certifiées de bout en bout, certification globale et items false. Seul son résumé de fin est utilisable, la grande sortie catalogue ayant été tronquée. Ces résultats empêchent une déclaration de parité globale verte ; ils ne remplacent pas les preuves natives ciblées ci-dessus et n’ont pas été corrigés hors scope.

## Auto-critique finale, risques et suite

Le lot apporte la sortie native de staging, avec preuves de lecture et édition persistante. Il ne contient pas le remapping RMXP des tuiles, les autotiles, les collisions ou la traduction d’événements. Le desktop dans `apps/avelune_converter` reste à construire en AC-09.

La fraîcheur du filesystem source doit être contrôlée par la composition AC-04 avec `SnapshotSourceFiles.verifyUnchanged` avant/après le pipeline ; le writer reçoit l’IR et les artifacts immuables approuvés. `sourceRootPath` protège l’isolation, pas une relecture complète du corpus. Les cinq fichiers originaux de la qualification AOT ont exactement les mêmes hashes avant/après.

Les gardes de sortie pré/post ne sont pas un confinement atomique par FD contre une substitution concurrente du parent. Les quotas bornent les octets, les pixels et l’IDAT de notre décodeur actuel ; aucune garantie de RSS ou de comportement exhaustif ICC/métadonnées de tous les renderers n’est revendiquée. Un artifact PNG réutilisé pour deux atlas et des collisions d’IDs d’atlas par casse sont refusés conservativement.

Le trap HTTP du harness ne traverse pas l’isolate du bootstrap ; la branche locale `empty` et le lecteur de template piège apportent la preuve complémentaire. Aucun script Ruby source n’est exécuté. Aucune session Studio existante ni projet humain n’a été piloté pour cette preuve.

Le corpus Kanto reste le cas réel autorisé, avec sa confirmation de version requise et ses 33 diagnostics bloquants constatés en AC-04. La fixture originale de qualification ne vaut pas approbation humaine de conversion en production.

## Git, traceabilité et livraison

Contrôles finaux : `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` sort 0, `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.` ; `git diff --check -- <neuf fichiers du lot>` sort 0. L'index des artifacts a été relu et tous ses SHA correspondent aux fichiers. Le contrôle juste avant staging confirme neuf chemins propres au lot, un index vide et 257 chemins étrangers inchangés.

Avant les preuves finales : index vide, 6 chemins de code du lot dirty/untracked, **257 chemins étrangers identiques**, aucun ajout/retrait étranger, 15 hashes de contrats cibles identiques. `commands.json` conserve le statut complet, les hashes et le contrôle de préservation.

Le commit de livraison doit contenir exactement les neuf fichiers inventoriés, avec aucun autre path dans l’index. La vérification après commit exige un index vide et les mêmes 257 chemins étrangers, le scope convertisseur propre et une hygiène Markdown sans nouveau document restant. Le SHA réel et ce contrôle de livraison sont projetés dans le ticket Notion AC-05 après commit ; le commit Git contient les preuves techniques sans auto-référence circulaire de son propre SHA.

Ticket existant : https://app.notion.com/p/3f6197a7bfa581cba6f5fc29e76a947c, grand domaine 14 Monde, exploration et narration — Post Bêta. Statut prévu **TO REVIEW**, jamais DONE sans revue humaine. La bêta gelée n’est pas élargie. Aucun push/rebase/branche/worktree.

Prochain lot : **AC-06 — conversion littérale des tuiles**, selon TIL-01..04 et MAP-05 ; cartes éditables, trois couches, alpha et identité des sources, avec attendu indépendant et édition Studio réelle.
