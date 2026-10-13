# AC-15 — Qualification Kanto et publication robuste

## Verdict et périmètre

Livraison technique proposée TO REVIEW ; verdict de domaine PARTIAL. PUB-01..04 et KAN-01/02 sont acquis sur macOS arm64 pour une étude native réelle de Route 9. KAN-03 reste BLOCKED : aucun parcours départ→dialogue→warp→état→sauvegarde gameplay n'a été exécuté et les 16 événements source restent quarantinés. Le lancement du mode test prouve son bootstrap et son affichage, pas ce parcours.

Les combats gardent les règles et le moteur natifs Avelune, selon l'instruction directe de Yoahn. Le convertisseur importe des données qualifiées ; il n'exécute aucun Ruby et ne porte pas le moteur Essentials. Zéro appel IA pour la conversion réelle ci-dessous. Les catalogues importés restent data-only tant qu'un déclencheur natif n'est pas qualifié.

La demande autorise tous les lots et un commit local entre les lots. Ni push, ni rebase, ni amend. Le kit demande un Evidence Pack ; ce document unique respecte ce livrable sous documentation/reports/converter. La règle directe interdisant les nouveaux commentaires de code prévaut sur l'instruction contraire de codex_rule.md. Aucun modèle cible nouveau, aucune mise à jour de roadmap FG, aucune extension du périmètre bêta.

Ticket existant : AC-15, 3f7197a7-bfa5-8165-8184-d87eca66b8b7. Grand domaine unique Post Bêta Monde & narration, 3bf197a7-bfa5-81bb-b13a-df367721992f ; Gate bêta false. DONE reste réservé à la décision de Yoahn.

## Audit initial et Gate 0

Base main AC-14 6b153da4ad1b2b7b9bfe629caa5b8789c909d8d0, index vide, 39 chemins étrangers. Le writer AC-14 crée et relit un staging, sans publication exclusive durable ; l'écran résultat ne peut donc pas honnêtement appeler ce staging un projet publié. Le workflow vérifie l'approbation, mais doit relire le contexte et la source après les derniers callbacks asynchrones et préserver les causes typées de refus.

Le writer canonique, les contrats de plan/approbation, les fixtures littérales, les tests de workflow et les preuves Studio AC-14 ont été audités. La publication est une frontière filesystem locale au-dessus du writer, pas un nouveau moteur d'import ni une nouvelle action de persistance native. Les mutations passent toujours par map_authoring ; aucune édition JSON de projet n'est utilisée comme voie d'écriture.

Risques identifiés : destination préexistante ou remplacée pendant la publication, symlinks, source imbriquée, approbation périmée, blob changé après relecture, interruption après rename avant receipt, journal tronqué, mémoire/quotas et fausse certification gameplay. Des checkpoints déterministes et une réservation annoncée au parent rendent ces fenêtres testables.

Snapshot de qualification : /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac15-qualified-cyrddcpc/repository. Archive Git de la base, superposition des seuls fichiers AC-15. Les 39 changements étrangers sont exclus ; leur contenu est comparé immédiatement avant/après le commit. Les anciens processus sont laissés tranquilles ; le superviseur ne nettoie que ses descendants dont UID, start et commande sont encore vérifiés.

## Fichiers et zones modifiés

| Fichier | Zones et raison | Impact |
| --- | --- | --- |
| apps/avelune_converter/lib/converter_app.dart | résultat publié, phase publishNative, panneau d'échec et action verify-publication-journal vers reconcile ; bloc de l'issue events.quarantined | Chemin final réel, statut de publication incertain explicite, contrôle volontaire du journal ; une accolade élimine l'info analyzer préexistante. |
| apps/avelune_converter/test/converter_app_test.dart | titres, chemins et published du résultat | Le rendu ne présente plus le receipt staging comme résultat final. |
| packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart | export native_project_publication | Contrat public commun au workflow et à l'interface. |
| packages/avelune_converter_adapters/lib/src/native_project_publication.dart | types publics 17–139 ; begin 141 ; reconcile ; NativePublicationJob/createStaging/publish ; journal hash-chain/inventaire ; couche Darwin open/fstatfs/renameatx_np/fsync | Journal durable, stage possédé, promotion exclusive sans overwrite, recovery borné et validation native/blobs. Nouveau fichier de 1 435 lignes ; le diff et la source sont les preuves canoniques. |
| packages/avelune_converter_adapters/lib/src/native_project_writer.dart | NativeStagingFactory 424, write 463, checkpoint et guard avant bootstrap | Le publisher réserve le stage ; le writer reste staging-only et son receipt ne peut pas être forgé en résultat publié. |
| packages/avelune_converter_adapters/lib/src/converter_workflow.dart | phases/result/failure, worker context request/ACK, réservation ; stagingFactory/recordWriteCheckpoint 1458 ; publicationCallback 1513 ; classification finale | Contexte source/révision/settings/approbation relu, chemins d'échec conservés avant callback, source_changed/cancelled restent typés. |
| packages/avelune_converter_adapters/test/native_project_publication_test.dart | 20 tests, crashes réels subprocess 406, enfant 452 | Refus, races, free-space, journaux, source/blobs, quatre fenêtres de crash sans replay destructif. |
| packages/avelune_converter_adapters/test/converter_workflow_test.dart | fresh reopen publication ; lost receipt ; source après seal 127 ; annulation avant bootstrap 160 ; résultats finals des assertions existantes | Expiration de préparation, annulation et recovery contrôlés de bout en bout. |
| packages/avelune_converter_adapters/test/publication_workflow_reproducibility_test.dart | PUB-04 26 ; comparaison fichiers 186 ; liste volatile fermée 12 ; project.create 243 ; lecture tree 561 | Même plan/draft/profils/décisions, IDs et octets natifs exacts hors métadonnées volatiles explicitement qualifiées. |
| packages/avelune_converter_adapters/test/converter_asset_workflow_test.dart | deux anciens cas positifs du writer | Relecture du chemin publié, receipt staging false et stage vide conservé, sans retirer les assertions map/asset/source. |
| packages/avelune_converter_adapters/tool/source_semantics_study.dart | validation chemins frais 15 ; workflow 52 ; receipts et source checks | Vraie qualification native publiée et preuves externes, plutôt qu'une copie manuelle de staging. |
| documentation/reports/converter/AC-15/15_kanto_publication.md | document consolidé | Audit, résultats, limites et inventaire de ce lot. |

## Invariants de publication

La politique refuse source/destination imbriquées, parents protégés, symlinks, targets préexistants et politiques contradictoires avant journaling. Répertoires de contrôle et stage 0700, journal 0600 ; fichiers réguliers à lien unique seulement. Les plafonds sont 32 768 fichiers, profondeur 32, 512 MiB/fichier, 2 GiB total, journal 4 MiB et 4 096 records. Ils sont des bornes, pas des valeurs de corpus inventées.

fstatfs mesure l'espace disponible du volume local avant réservation ; l'estimation inclut les artefacts, witnesses et marge de journal. Ce contrôle n'est pas une réservation d'espace et un ENOSPC tardif reste un refus sûr. APFS/HFS local et ABI Darwin arm64/x64 implémentées ; seule arm64 est exécutée. Les autres plateformes sont explicitement refusées, sans rename non protégé en fallback.

Les répertoires sont ancrés par FD, inode et device, avec nofollow. Le journal est append-only sous flock, hash-chain bornée et synchronisée ; stage et contrôle sont fsync avant F_FULLFSYNC du journal. Avant promotion, relecture stricte de la révision native, des assets conservés et de tous les fichiers de l'inventaire ; contexte et source relus après les derniers callbacks asynchrones. Contrôle final synchrone et renameatx_np(EXCL=4) sans nouvel await entre admission finale et rename.

Un échec après rename conserve le projet final et promotionMayHaveOccurred=true. Le recovery ne rejoue pas l'import, n'efface pas une destination, et ne répare que le journal possédé d'une publication exactement attestée. Un stage prepared est aussi relu complètement avant verdict. Le stage vide et le journal restent disponibles pour support ; aucune suppression globale implicite.

## PUB-01..04

PUB-01 PASS : ancienne préparation/approbation, contexte étranger et modification de source refusés. Les deux erreurs de propagation trouvées en critique ont été reproduites RED 0/2 puis corrigées GREEN 2/2 : callback publisher source/context, et callback writer beforeBootstrap. Elles préservent maintenant source_changed/cancelled, journal, destination et éventuelle promotion ; la préparation périmée est invalidée.

PUB-02 PASS : destination existante, symlink, parent protégé, source imbriquée et création au dernier intent ne sont pas écrasés. Les octets étrangers sont conservés. Quotas et espace libre refusent avant promotion.

PUB-03 PASS pour crash de processus : quatre subprocess sont réellement interrompus à beforeStage, beforeBootstrap, publishIntentDurable et promotedBeforeReceipt. Recovery distingue incomplet/prepared/publié/conflit/corrompu ; le dernier cas reconstitue le receipt sans rejouer ni détruire le projet. Ceci n'est pas une certification de coupure électrique matérielle.

PUB-04 PASS : un unique plan/draft/context source/profils/décisions est appliqué deux fois dans deux stages privés. Toute map, ID métier, asset, companion et fichier hors liste fermée doit être byte-identique, et chaque sortie est strictement relue. Les seuls journaux normalisés sont .pokemap/authoring/{idempotency,history,audit}.jsonl et cinq locks vides exacts. Hash-chains originales, ordre et statuts sont vérifiés avant normalisation bijective des dates, handles/op IDs ; les deux aggregateRevisionSet du bootstrap project.create sont reconstruits depuis ses octets originaux capturés puis recalculés. Aucun hash métier ou champ sémantique n'est ignoré. Six sabotages de données/blobs/métadonnées/revisions/chaîne/audit sémantique échouent. Publier deux fois sur une même destination existante reste interdit.

## Kanto réel et parcours Studio

Source autorisée en lecture seule : /Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto. Snapshot 24 273 entrées dont 24 085 fichiers, 383 cartes ; sélection [98], les 382 autres cartes hors conversion. Snapshot SHA 5bc0f5dd57e70951cb86fe7c71114e983827251830b2b11f23ef2dab48f1c8de. Source Scripts 1 080 290 octets, SHA 3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d ; lecture statique, aucune exécution.

Route 9 : 72×61, cinq couches natives, 315 décors placés, huit clips joueur, spawn de prévisualisation (35,22). Ce spawn n'est pas un départ de jeu Essentials certifié. Les projections collisions/depth AC-12 restent bornées ; 536 transitions source non qualifiées restent fermées. Les 16 événements quarantinés ne sont pas activés. Catalogues AC-14 : 52 espèces, sept trainers et aucune rencontre active ; autorité combat Avelune.

Le vrai scan→prepare→approbation→writer→publication→relecture stricte finit exit0 en 204.725s. Draft 0146a289f771993a6aeffa0ec509b244d4244591d47f37944f99e565fe10dd18 ; nativeRevision sha256:57fb7e2643d6e9c61042f12d95f51cf7440369cebe56d5d0b22b8bf44aa0f4df ; inventoryHash 523a17386457ff402867344e6a084345541ef56ae2299fb1ae9f8235c6b8b324. SourceUnchanged=true, strictNativeReadPassed=true, published=true, playableCertified=false.

Racine utilisateur : /Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - AC15 publié 20261012. Projet publié : Projet pour Avelune Studio/Projet converti (727 fichiers). Journal : Projet pour Avelune Studio/.avelune-converter-job-7517ae597d42b43edf4a54d07c6ed4373a41d678/journal.jsonl. Copie modifiable : Projet modifié dans Studio (729 fichiers). Aucun média Kanto entre dans Git.

Studio est le checkout QA gelé AC-13, avec les modèles natifs inchangés. Première instance indépendante PID runner 47253 : chemin exact contrôlé, Carte→Afficher les cartes→Renommer, nom «Route 9 — modifiée dans Studio AC15», Retour à la carte→Enregistrer, état Enregistré, Quit. Deuxième instance PID runner 54617 : même projet exact, nom et état sauvegardé retrouvés, puis bouton Enregistrer et tester ; le runtime charge la carte et le joueur et rend la scène au spawn. Les deux instances terminent exit0, aucun survivant possédé, PIDs protégés inchangés.

MapData ne diffère que par name ; aucun tile ni collision n'a été modifié pendant cette preuve. La copie user est identique à la copie QA modifiée et les 727 fichiers originaux sont inchangés. Captures réelles sous Preuves : studio-route9-enregistree.png et studio-route9-reouverte.png (SHA 232889b7fadda4cd85d85a92c52dcd8bcce5f8cfa3288f1cf7c5e3e99afc6c5f), studio-route9-test.png (SHA e43bf49a940797c952266071b8e3a41c37e52d2839f4620b4d12fda0c0bd939e). Preuves/qualification.json et studio-qualification.json donnent les contrôles exacts.

La conversion positive est qualifiée sur pins-02 ; les wrappers d'erreur additionnels pins-03 ne changent pas ses octets positifs, et pins-04 ajoute les assertions de test et une accolade UI. Les preuves négatives et suite complète portent les pins-04. Le build pins-03 précède seulement cette accolade UI sans changement de comportement.

### Lacune de bibliothèque soulevée par Yoahn

Le study livré compte quatre atlas et sept éléments : quatre fragments d'occlusion Source tile804/805/812/813, et trois masques invisibles de collision Source boundary10/2/8. L'atlas FRLG_Outside City 256×16192 conserve les pixels de sols/chemins mais paletteEntries et elementGroups sont vides. Ce résultat ne constitue donc pas encore une bibliothèque métier de chemins et d'arbres entiers réutilisables.

review-session.json du study vaut null : ces sept éléments viennent de la projection technique, pas de propositions approuvées. Un audit séparé du proposer sur la même source démontre une composante de map de 4 392 cases, toutes couches réunies, soit 8 167 parts ; le quota 4 096 est dépassé avec «Placement parts budget exceeded». L'alpha opaque du grand atlas est une seule composante de 4 047 cases. Les plans preview et approuvé du study conservent effectivement study-finding-5 / asset.proposal.quota ; le tool qualification n'en recopie pas les diagnostics de proposals dans qualification.json. La cause précise Placement parts budget exceeded est remplacée par un message générique au catch. Les deux constats sont liés, sans assimiler les fragments techniques à une bibliothèque approuvée.

La suite doit fournir des palettes natives et des propositions d'assemblage à partir des pixels d'origine. L'IA peut suggérer une reconnaissance avec consentement explicite, sans redessiner les ressources ni devenir une dépendance de conversion. Cette lacune reste déclarée PARTIAL ; relever les quotas aveuglément n'est pas une correction.

## Commandes et résultats frais

Chaque reçu du superviseur conserve la commande complète, cwd, durée, log/hash, runner/descendants et contrôles des processus. Les tests répétés ne sont pas additionnés en un total artificiel. Le package core inchangé et ses 696 PASS AC-14 ne sont pas présentés comme un rerun AC-15.

### Adapteurs complet final : 634 PASS / 0 FAIL / 0 SKIP

`cwd`: /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac15-qualified-cyrddcpc/repository/packages/avelune_converter_adapters

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test --concurrency=1 --reporter=expanded
```

Exit 0 ; 355.585s ; survivants 0 ; signaux possédés 0 ; protectedUnchanged=True. Reçu /private/tmp/avelune-ac15-root-adapters-full-20261012-04.json.

### Adapteurs ciblés : 61 PASS

`cwd`: /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac15-qualified-cyrddcpc/repository/packages/avelune_converter_adapters

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/native_project_publication_test.dart test/converter_workflow_test.dart test/publication_workflow_reproducibility_test.dart --concurrency=1 --reporter=expanded
```

Exit 0 ; 74.68s ; survivants 0 ; signaux possédés 0 ; protectedUnchanged=True. Reçu /private/tmp/avelune-ac15-root-focused-20261012-02.json.

### Analyse adapters : No issues found

`cwd`: /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac15-qualified-cyrddcpc/repository/packages/avelune_converter_adapters

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze
```

Exit 0 ; 4.106s ; survivants 0 ; signaux possédés 0 ; protectedUnchanged=True. Reçu /private/tmp/avelune-ac15-root-analyze-20261012-04.json.

### Widgets converter complet : 82 PASS / 0 SKIP

`cwd`: /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac15-qualified-cyrddcpc/repository/apps/avelune_converter

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter test --concurrency=1 --reporter=expanded
```

Exit 0 ; 77.311s ; survivants 0 ; signaux possédés 0 ; protectedUnchanged=True. Reçu /private/tmp/avelune-ac15-root-app-full-20261012-02.json.

### Analyse converter finale : No issues found

`cwd`: /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac15-qualified-cyrddcpc/repository/apps/avelune_converter

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter analyze --no-pub
```

Exit 0 ; 7.487s ; survivants 0 ; signaux possédés 0 ; protectedUnchanged=True. Reçu /private/tmp/avelune-ac15-root-app-analyze-20261012-04.json.

### Build macOS release : Built 104.5 MB

`cwd`: /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac15-qualified-cyrddcpc/repository/apps/avelune_converter

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter build macos --release --no-pub
```

Exit 0 ; 93.343s ; survivants 0 ; signaux possédés 1 ; protectedUnchanged=True. Reçu /private/tmp/avelune-ac15-root-build-20261012-03.json.

### Dépendances offline

`cwd`: /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac15-qualified-cyrddcpc/repository/apps/avelune_converter

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter pub get --offline
```

Exit 0 ; 2.432s ; survivants 0 ; signaux possédés 0 ; protectedUnchanged=True. Reçu /private/tmp/avelune-ac15-root-pubget-20261012-01.json.

### MCP build tsc

`cwd`: /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac15-qualified-cyrddcpc/repository/tools/pokemap_mcp

```text
npm run build
```

Exit 0 ; 1.309s ; survivants 0 ; signaux possédés 0 ; protectedUnchanged=True. Reçu /private/tmp/avelune-ac15-root-mcp-build-20261012-01.json.

### MCP check tsc

`cwd`: /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac15-qualified-cyrddcpc/repository/tools/pokemap_mcp

```text
npm run check
```

Exit 0 ; 1.98s ; survivants 0 ; signaux possédés 0 ; protectedUnchanged=True. Reçu /private/tmp/avelune-ac15-root-mcp-check-20261012-01.json.

### MCP vivant describe/catalogue : 2 PASS

`cwd`: /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac15-qualified-cyrddcpc/repository/tools/pokemap_mcp

```text
node --import tsx --test test/pokemon_authoring.test.ts
```

Exit 0 ; 18.309s ; survivants 0 ; signaux possédés 0 ; protectedUnchanged=True. Reçu /private/tmp/avelune-ac15-root-mcp-live-catalog-20261012-01.json.

### Conversion Kanto réelle

`cwd`: /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac15-qualified-cyrddcpc/repository/packages/avelune_converter_adapters

```text
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart run tool/source_semantics_study.dart /Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto /Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - AC15 publié 20261012/Projet pour Avelune Studio /Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - AC15 publié 20261012/Preuves 98 Kanto Route 9 - AC15 --approved-study
```

Exit 0 ; 204.725s ; survivants 0 ; signaux possédés 0 ; protectedUnchanged=True. Reçu /private/tmp/avelune-ac15-root-kanto-20261012-01.json.

### Studio première instance save/Quit

`cwd`: /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/apps/avelune_studio

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter run -d macos --debug --no-pub -t dev/marionette_main.dart --dart-define=MARIONETTE_PROJECT_PATH=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Kanto Route 9 - AC15 20261012 --dart-define=MARIONETTE_CAPTURE_ROOT=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Converter AC13 captures 20261012
```

Exit 0 ; 224.3s ; survivants 0 ; signaux possédés 2 ; protectedUnchanged=True. Reçu /private/tmp/avelune-ac15-root-studio-launch-20261012-01.json.

### Studio nouvelle instance reopen/test/Quit

`cwd`: /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-converter-ac13-qualified-r_bc23_c/repository/apps/avelune_studio

```text
/opt/homebrew/share/flutter-3.47.5/bin/flutter run -d macos --debug --no-pub -t dev/marionette_main.dart --dart-define=MARIONETTE_PROJECT_PATH=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Kanto Route 9 - AC15 20261012 --dart-define=MARIONETTE_CAPTURE_ROOT=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Converter AC13 captures 20261012
```

Exit 0 ; 168.657s ; survivants 0 ; signaux possédés 0 ; protectedUnchanged=True. Reçu /private/tmp/avelune-ac15-root-studio-reopen-20261012-01.json.

Les tests opt-in utilisent le vrai Scripts.rxdata via AVELUNE_AC12_SOURCE_SCRIPTS, AVELUNE_AC13_SOURCE_SCRIPTS et AVELUNE_AUTOTILE_SCRIPTS_PATH ; aucun skip dans le rerun final. Les quatre subprocess crash font partie des 634 tests.

Les échecs antérieurs ne sont pas effacés : focused-01 et les deux P2 RED de propagation ; adapters-full-03 = 632 PASS/2 FAIL/0 SKIP, uniquement deux anciens tests attendant un staging présent plutôt qu'un chemin publié ; app-analyze-03 = 1 INFO préexistante curly_braces_in_flow_control_structures, exit1. Corrections ciblées, asset workflow 14 PASS et rerun complet final 634 PASS, analyses finales zéro issue.

Le build et la première instance Studio ont respectivement un et deux ibtoold possédés terminés normalement par le superviseur après vérification d'identité. Les autres reçus de la table n'ont aucun signal. Aucun kill global, aucun ancien PID supprimé, aucun survivant confirmé de ces runs.

## Parité authoring et verdicts des passes

map_authoring reste la voie canonique de toutes les mutations natives. AC-15 ajoute publication/recovery filesystem ; aucune nouvelle sémantique d'authoring ni modèle cible ne justifie une action MCP nouvelle. Les contrats existants et les transports API/JSONL de la base AC-14 restent conservés et rejoués dans les tests de writer/workflow ; rebuild/check tools/pokemap_mcp et deux tests stdio vivants ont relu le catalogue et testé mutation/conflict. Recovery volontaire de journal est propre au convertisseur, N/A au catalogue d'édition de maps.

| Passe requise | Verdict et limite |
| --- | --- |
| Audit / Architecture | PASS pour la frontière publication/writer et les modèles natifs conservés. Les ressources métier restent PARTIAL ; l'audit ne certifie pas de gameplay. |
| Implémentation, ac12_native_mapping et root | PASS borné macOS : journal, identité, stage, seal, promotion exclusive et recovery conservateur. Source et moteur combat préservés. |
| Tests, ac12_validation_design et root | PASS frais : 634 adapters, 82 widgets, PUB-04 fermé et deux P2 RED/GREEN. Les anciens contrats staging sont actualisés sans masquer l'état publié. |
| Build / Validation, root | PASS release locale et deux vrais processus Studio. Distribution REL-02 non acquise : la dépendance design system via Studio embarque encore des médias runtime/Studio. |
| Critique finale, ac12_semantics | Deux P2 concrets trouvés puis fermés sur workflow SHA 51b49974a2544205f85308bb5f5d53918ba104858d7d1e59ea18f933c65d1d5d. Aucun défaut restant identifié dans ces deux points de propagation ; pas une preuve de tous les parcours gameplay. |

## Gate finale, Git et auto-critique

Les onze sources/tests host et snapshot sont byte-identiques aux pins /private/tmp/avelune-ac15-root-pins-20261012-04.json. Avant commit : index vide, 39 chemins étrangers conservés, seuls les 12 fichiers de la table sélectionnés. Commit local limité à ces chemins ; le reçu /private/tmp/avelune-ac15-root-close-20261012.json consigne SHA, inventaire du commit, index final, hashes étrangers avant/après et contrôles hygiene/diff. Aucun push/rebase/PR. État final attendu : index vide et les 39 chemins étrangers inchangés par ce commit ; le reçu fait autorité sur le résultat effectivement observé.

Limites : étude d'une carte, pas Kanto entier ; événements Kanto quarantinés et parcours KAN-03 bloqué ; bibliothèque de sols/objets encore incomplète ; source profile d'étude, pas identité/départ de jeu Essentials certifiés ; arm64 macOS réellement testé, x64 non exécuté ; crash de processus, pas panne matérielle ; free-space estimé, non réservé. Le build 104.5 MB actuel contient les assets transitifs Studio/runtime et ne doit pas être distribué comme logiciel seul.

Auto-critique : la publication est une frontière plus complexe que le writer, mais ses checkpoints et journaux bornés couvrent les fenêtres dangereuses plutôt que cacher un rename ordinaire. L'inventaire strict inclut les fichiers auxiliaires et blobs ; le normaliseur PUB-04 ne doit pas devenir une excuse pour retirer des champs natifs supplémentaires. Le succès Studio est tangible mais le bouton test n'atteste ni mouvement ni save gameplay. Le manque de ressources métier signalé par Yoahn limite directement l'utilité d'authoring et demeure explicite.

Suite autorisée par Yoahn, dans un commit séparé : AC-16, extraction minimale du design system sans médias transitifs, CLI et desktop sur le même plan, fixture originale offline, installation/build propres, inventaire/licences et archive locale. La lacune générique des ressources doit être traitée dans son contexte existant ; pas de ticket de contenu Route 9 ni d'extension bêta.

## Complément du 13 octobre — lookup des fichiers de map

Ce complément qualifie uniquement le cache local du fichier source utilisé par les propositions de ressources. Les résultats du 12 octobre ci-dessus sont historiques. L'application est désormais indépendante et la livraison locale AC-16 existe ; les compléments musique/ETHER et ressources natives ont leurs preuves dans AC-13/AC-16. Le raccord réel Route 9–Route 10 Nord, la bibliothèque complète et la qualification finale restent en cours, sans certification globale de Kanto.

### Audit initial et périmètre

Base `main`, HEAD `5f8c1568e7dda889e81cbd1fc17b1a03c6074f5b`, index vide. Les 50 chemins étrangers du garde `/private/tmp/avelune-ac15-connections-initial-guard-20261013-01.json` sont byte-identiques au contrôle frais. Les autres changements du complément AC-15 sont exclus du présent commit.

L'audit a localisé une recherche `snapshot.entries.singleWhere` dans la validation de chaque claim et dans la construction des candidats. L'expression recréait aussi le `sourceFileId` de la map pendant la recherche. Chaque carte normalisée et le snapshot sont immuables ; résoudre une fois l'entrée exacte ne change donc pas la provenance. Le cache vérifie encore l'unicité de cette entrée, puis conserve tous les contrôles map/hash/fichier/Z/cellule/crop/image/priorité/locator.

L'observation réelle avant correction est un timeout en phase `propose`, exit `-15` après `180.587s`, avec arrêt normal du seul runner possédé et zéro survivant. Aucun succès ni compteur complet n'est revendiqué pour ce run : `/private/tmp/avelune-ac15-proposals-pair-measurement-20261013-01.json`.

### Inventaire complet de ce commit

| Fichier | Zone modifiée et effet |
| --- | --- |
| `packages/avelune_converter_adapters/lib/src/local_asset_proposer.dart` | `_AssetInputs` résout une entrée unique par map sélectionnée dans `sourceMapEntries`. `validatePlacementClaims` et la construction des candidats consomment cette même entrée. IDs, clés, crops, hashes, quotas et formats inchangés. |
| `packages/avelune_converter_adapters/test/local_asset_proposer_test.dart` | Fixture originale à deux cartes, quatre candidats et six claims ; correspondance exacte des locators, refus des mauvaises identités/hashes/maps/Z, refus d'inventaire manquant/dupliqué et répétition déterministe. |
| `documentation/reports/converter/AC-15/15_kanto_publication.md` | Le présent complément consigne l'audit, les commandes, les preuves, les verdicts et les limites. Aucun nouveau Markdown. |

Les diffs Git sont l'inventaire des hunks ; aucun snapshot intégral de source n'est ajouté. Les deux sources host correspondent aux pins du ledger `/private/tmp/avelune-ac15-map-file-lookup-final-pins-20261013-01.json` : production `9d2175ce471cab565b4beec8549fe452998206255f0af0125c65ec728798a87d`, test `4f2ad2eb6b51fa8dc0a2dd014a526861269dbcb62b664579ed7b52489d5088ed`.

### Commandes et résultats frais

Les commandes Dart sont exécutées depuis `packages/avelune_converter_adapters` dans une copie privée qualifiée ; aucun worktree Git n'est créé. Le superviseur consigne le PID du runner, ses descendants et leurs identités, puis recontrôle les survivants. Les six reçus du ledger sont terminaux, sans signal ni enfant possédé survivant, processus protégés inchangés.

| Commande ou contrôle | Résultat exact | Reçu sous `/private/tmp/` |
| --- | --- | --- |
| `dart test test/local_asset_proposer_test.dart --name 'map file lookup' --reporter expanded`, avant cache | 4 PASS, exit 0, 9.332s | `avelune-ac15-map-file-lookup-characterization-before-20261013-01.json` |
| Même commande, après cache | 4 PASS, exit 0, 4.747s | `avelune-ac15-map-file-lookup-characterization-after-20261013-01.json` |
| `dart run tool/qa_map_file_lookup.dart /private/tmp/avelune-ac15-map-file-lookup-json-{before,after}-result-20261013-01.json`, deux exécutions distinctes | JSON de 9 494 octets byte-identique, SHA `c10fb21f7236ddbee59cbf9f5347a6512d8cc6536edcc306328c413d13e1bdc1` | `avelune-ac15-map-file-lookup-json-comparison-20261013-01.json` |
| `dart test test/local_asset_proposer_test.dart test/converter_asset_workflow_test.dart --reporter expanded` | 40 PASS, exit 0, 13.783s | `avelune-ac15-map-file-lookup-full-green-20261013-01.json` |
| `dart analyze lib/src/local_asset_proposer.dart test/local_asset_proposer_test.dart` | No issues found, exit 0, 4.779s | `avelune-ac15-map-file-lookup-analyze-20261013-01.json` |

Le contrôle réel utilise le même outil et les mêmes arguments que le timeout, avec le seul cache ajouté au proposer. Commande exacte du run après correction :

```text
dart run tool/qa_route9_pair_proposals_diagnostic.dart '/Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto' /private/tmp/avelune-ac15-fresh-source-snapshot-20261013-01.json '/Users/karim/Library/Application Support/AveluneConverterStudies/Kanto Route 9 - Route 10 Nord 20261013-r6/evidence/qualification.json' /private/tmp/avelune-ac15-proposals-pair-measurement-result-20261013-02.json
```

Exit 0, `25.031s`, sans timeout/signal/survivant, protégés inchangés : `/private/tmp/avelune-ac15-proposals-pair-measurement-20261013-02.json`. Résultat : 274 candidats, 11 519 claims, 252 600 nœuds, 3 606 772 unités de texte, plus grande chaîne 85 unités, normalisation `4431387f73fa4062b3ce403d64f8fbfb8193377f7db65ea1444ed54fbd451b92`, source inchangée, zéro appel IA et zéro script Ruby exécuté. L'outil privé garde le SHA `47c11514f4807fe937a5597114074793f22f311634742b1b5f5b76ed52ffa9e2` ; les arguments et pins des deux exécutions sont dans leurs reçus.

Le plafond de 512 candidats est explicite dans ce diagnostic, sous le plafond dur existant ; il ne modifie pas le défaut de l'application de 256. Le snapshot utilisé provient d'un scan antérieur attesté ; les fichiers lus sont liés et recontrôlés. Ce run n'est ni une publication, ni une reprise de revue, ni un nouveau scan complet, ni un benchmark isolé.

La compilation AOT du qualifier réel consommant le cache et les autres compléments a passé : `dart compile exe tool/qa_route9_route10_literal_pair.dart -o /private/tmp/avelune-ac15-route9-route10-literal-pair-20261013-02`, exit 0, 27.301s, zéro survivant. Reçu `avelune-ac15-literal-pair-arrival-build-20261013-01.json`. Ce build prouve la compilation du package intégré ; il ne remplace pas la reconstruction de l'application distribuée.

### Verdicts des passes et parité

| Passe | Verdict borné |
| --- | --- |
| Audit / Architecture, ac12_semantics et root | Cause du coût identifiée dans les recherches répétées de fichier ; immutabilité et provenance conservées. |
| Implémentation, ac12_semantics | Cache privé par map uniquement, aucun changement de contrat ni de quota. |
| Tests, ac12_semantics | Caractérisations fraîches avant/après et sortie byte-identique ; 40 tests PASS. Aucun RED unité de coût revendiqué. |
| Build / Validation, root | Mesure réelle après correction PASS et compilation AOT PASS. Aucun parcours Studio/runtime impliqué. |
| Critique finale, ac12_native_mapping | PASS borné ; aucun P1/P2 trouvé sur les deux pins et six reçus relus. Les refus missing/duplicate sont exercés en amont, pas chaque branche privée du cache. |

Le changement concerne une recherche interne de provenance dans le convertisseur. Il n'ajoute aucune action d'authoring, aucun modèle natif, aucune sémantique de carte ni commande Studio : nouvelle exposition MCP N/A. Le pipeline reste sur les API canoniques existantes. La qualification MCP des connexions et les mutations de publication sont suivies séparément ; ce cache ne les certifie pas.

### Git, limites et auto-critique

Le commit est limité aux trois chemins de l'inventaire ci-dessus. La preuve finale SHA/inventaire/index et le contrôle des 50 chemins étrangers sont enregistrés dans `/private/tmp/avelune-ac15-map-file-lookup-commit-20261013-01.json` après commit. Aucun push, rebase, changement de branche ou nettoyage étranger. Le reste du complément AC-15 demeure non commité et le ticket reste DOING/PARTIAL.

Auto-critique : la réduction des recherches est utile et la sortie est inchangée sur la fixture, mais la mesure réelle ne permet pas d'attribuer tout le temps à ce seul coût dans une machine partagée. Le compteur privé de 252 600 éléments inclut les clés ; il ne prouve pas un dépassement des 250 000 nœuds du validateur de recette, qui compte les valeurs. Relever le plafond candidat ne suffit pas à qualifier la reprise : la bibliothèque doit conserver tous les candidats par segments explicites, avec budgets et décisions revalidés. L'essai r7 de publication a révélé séparément `connections.arrival_mismatch` à Map100 `(0,16)` ; sa correction et la nouvelle tentative sont hors de ce commit et encore en cours au moment de cette preuve.

## Complément du 13 octobre — revue bornée par carte

### Audit, périmètre et état initial

Base `main`, HEAD `8246f4f8113977d7af9109a3503db63b3941f1a6`, index vide, 50 chemins étrangers. Le set de propositions agrégé dépasse le plafond enfant de 256 candidats sur la paire réelle. La tranche introduit une session privée par carte, conserve la sélection globale et borne l'ensemble avant toute partition. Elle ne constitue pas encore le raccord du workflow, de la recette, du stockage ou de l'interface.

La machine a redémarré le 13 octobre ; les anciens reçus `/private/tmp/avelune-*` ne sont plus disponibles. Les résultats historiques ci-dessus ne sont pas des reruns. Les projets publiés et leur dossier `evidence` persistent. Les nouvelles preuves sont sous `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5`. Le ledger `owner-and-pins.json` conserve la base, les 28 overlays intégrés initiaux et les hashes/modes des 50 chemins étrangers. Aucun worktree Git n'a été créé.

Une deuxième archive `repository-review-segments` contient uniquement HEAD et les cinq sources/tests/export ci-dessous. Elle exclut les compléments non commités sur les connexions, le writer et le runtime. `review-segments-standalone-pins.json` en conserve les hashes exacts ; le barrel privé contient uniquement le nouvel export de revue, pas `source_connection_study_composer`.

### Inventaire de cette tranche

| Fichier | Zones et effet |
| --- | --- |
| `packages/avelune_converter_adapters/lib/src/converter_asset_review_set.dart` | Nouveau contrat privé `ConverterAssetReviewSet` et limites cumulées ; contextes globaux et par carte, sessions enfant 1.2 inchangées, hashes compacts, admission JSON/octet et quotas d'historique, restauration stricte, remplacement CAS, mode commun atomique et validation de tous les claims. |
| `packages/avelune_converter_adapters/lib/src/local_asset_proposer.dart` | `proposeByMap` et extraction des tuiles statiques partagée ; compteurs globaux avant partition, plafond par carte de 256, record JSON global contrôlé, lectures/pixels/locators exacts conservés. Le défaut global de 256 n'est pas relevé. |
| `packages/avelune_converter_adapters/test/converter_asset_review_set_test.dart` | Fixtures originales à deux cartes ; restauration exacte, permutations, contextes, immutabilité, limites, CAS, historique/undo/redo, mode commun et claims historiques. Refus explicite du contournement du budget par undo. |
| `packages/avelune_converter_adapters/test/local_asset_proposer_test.dart` | Partition exacte, quotas globaux/per-map, identité avec l'API agrégée, source/cancellation et refus du contournement du quota JSON global. |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | Seul l'export `converter_asset_review_set` entre dans ce commit ; l'export de connexion reste hors staging. |
| `documentation/reports/converter/AC-15/15_kanto_publication.md` | Ce complément et correction de l'interprétation du compteur privé de nœuds. Aucun nouveau Markdown. |

### Critique indépendante et corrections

La première relecture `ac15_review_segments` a trouvé deux P2 : l'admission JSON était renouvelée par segment, et `maxTotalCandidates` ne comptait que la frame au curseur. Deux tests frais ont reproduit les refus manquants : 0 PASS / 2 FAIL, exit 1, 4.441s (`review-segments-quotas-red.json`).

Le proposer valide désormais le record global sous `jsonLimits` avant partition et réutilise ce hash pour l'API agrégée. Le set compte les identités de toutes les frames avec son registre global de propriétaires ; undo ne libère pas les identités conservées dans redo. Les mêmes tests passent : 2 PASS, exit 0, 5.229s (`review-segments-quotas-green.json`). La deuxième critique indépendante ferme les deux P2 et n'en identifie pas d'autre ; ce verdict ne certifie pas les consommateurs encore absents.

### Commandes et résultats frais sur la tranche isolée

`cwd` : `repository-review-segments/packages/avelune_converter_adapters` sous la racine QA durable. Tous les reçus ci-dessous sont terminaux, sans timeout, signal ni survivant possédé, PIDs protégés inchangés et pins avant/après identiques.

| Commande | Résultat exact | Reçu dans la racine QA |
| --- | --- | --- |
| `dart pub get --offline` | exit 0, 1.047s | `review-segments-standalone-pubget.json` |
| `dart test test/converter_asset_review_set_test.dart test/local_asset_proposer_test.dart test/converter_asset_workflow_test.dart --concurrency=1 --reporter=expanded` | 84 PASS, exit 0, 27.113s | `review-segments-standalone-tests.json` |
| `dart analyze lib/src/converter_asset_review_set.dart lib/src/local_asset_proposer.dart test/converter_asset_review_set_test.dart test/local_asset_proposer_test.dart lib/avelune_converter_adapters.dart` | No issues found, exit 0, 4.648s | `review-segments-standalone-analyze.json` |
| `dart compile exe tool/qa_review_set_round_trip.dart -o <QA>/bin/review-set-round-trip` | Generated executable, exit 0, 5.653s | `review-segments-standalone-aot.json` |

Le harnais AOT est privé dans l'archive QA ; il compile la restauration publique du set et compare sa représentation canonique sans approbation ni mutation native. Il n'entre pas dans Git. La suite complète du package et le rebuild de l'app n'ont pas été rejoués dans cette tranche interne ; ils restent des gates d'intégration après raccord des consommateurs. Les 82 PASS de l'archive intégrée initiale précèdent les deux P2 : ils ne sont pas additionnés aux 84 PASS isolés.

| Passe | Verdict borné |
| --- | --- |
| Audit / Architecture, root et ac15_review_segments | Sessions enfant existantes préservées, contexte global et quotas explicites ; aucun nouveau modèle natif. |
| Implémentation, ac12_semantics puis root | Partition locale et set immutable ; deux P2 corrigés sans relèvement des plafonds. |
| Tests, root | RED 2 FAIL puis GREEN 2 PASS ; tranche isolée 84 PASS avec non-régression du workflow asset initial. |
| Build / Validation, root | Analyse sans issue et AOT de restauration publique PASS sur base sans overlays connexions. |
| Critique finale, ac15_review_segments | Deux P2 fermés sur code, tests et reçus exacts ; aucun nouveau P1/P2 identifié. |

### Limites, parité et Git

Les sessions et propositions sont des contrats privés du convertisseur. Cette tranche ne change aucune sémantique native d'authoring, aucune action Studio ni aucun schéma de carte ; nouvelle action MCP N/A. Les mutations natives demeurent sur `map_authoring`. La suite de workflow existante est conservée ; aucun catalogue MCP live nouveau n'est revendiqué.

L'application utilise encore la revue agrégée : le set n'est pas présenté comme une capacité déjà disponible dans le parcours UI. La persistance portable, la revalidation des générations source et l'approbation fraîche doivent être raccordées avant qualification réelle multicarte. Aucun appel IA, aucune exécution Ruby, aucune ressource Pokémon dans ce commit. La mesure du corpus réel et le parcours intercartes ont leurs gates séparées.

Le contrôle actuel du dossier source constate `Data/Scripts.rxdata` absent ; Map098, Map100 et Tilesets sont présents. Le snapshot de publication reste historique : cette tranche ne prétend pas avoir rescanné ni validé aujourd'hui l'intégrité globale de la source. Le projet natif publié est autonome et sa vérification stricte fraîche conserve 2 cartes/75 entrées d'assets/1 160 fichiers inchangés (`native-r8-verify-result.json`). La session Studio fraîche a retrouvé le nom sauvegardé et l'état Enregistré, puis a été arrêtée par son timeout possédé à 900.525s ; aucune capture fraîche ni parcours de jeu complet n'est certifié par ce run.

Le commit local est limité aux six chemins de l'inventaire. `review-segments-commit.json` conserve son SHA final, l'inventaire et les hashes étrangers avant/après. Les compléments connexion/binding/projection/runtime restent non commités ; aucun push, rebase, amend ni changement de branche. AC-15 demeure DOING/PARTIAL, et la bêta reste inchangée.

Auto-critique : les budgets ne peuvent plus être multipliés par la partition ou rouverts par undo. Cela prouve un contrat borné et compilable, pas une bibliothèque complète de Kanto ni une interface multicarte terminée. Le coût de sérialisation et la taille de recette doivent être mesurés sur les segments réels avant choix de stockage ; augmenter arbitrairement la limite de recette serait une décision non justifiée.


## Complément du 13 octobre — connexions source attestées et admission native

### Audit initial et portée

Base `main`, HEAD `0fbbf6d5f2e2533da243d3b13fd4dd9c30d75369`, index vide. Avant ce complément, 74 chemins sont dirty : 24 du convertisseur et de l'arrivée runtime, 50 étrangers. `connection-tranche-initial-pins.json` puis `connection-tranche-final-code-pins.json` sous la racine QA durable conservent les hashes exacts du scope, les modes complets et hashes des 50 chemins étrangers, ainsi que la copie privée utilisée. Les 24 fichiers host et privés sont byte-identiques ; seul un import privé de test redondant a été retiré après la première analyse. Aucun worktree Git créé.

L'audit a distingué trois contrats : graphe compilé complet source, géométrie native à une connexion par bord, et admission d'une arrivée. Le cardinal inverse d'une marche n'est pas l'oracle d'arrivée Essentials : la destination de connexion utilise `passable?(x,y,0)`, bit zéro. Le profil source exact reste obligatoire ; événements de bord, voisins multiples, directions non opposées et références hors sélection ne sont pas inventés. Les sources restent inertes, sans exécution Ruby ni appel IA.

Le writer liait précédemment toute la liste de mutations et l'évidence dans un seul gros record JSON. Le complément garde leurs données complètes, valide chaque record sous les limites existantes et lie leurs hashes ordonnés dans un manifeste compact v2 ; un budget UTF-8 cumulé explicite empêche de contourner les quotas par cette partition. La recette passe strictement en v2 pour porter les deux budgets nouveaux, sans lecteur de compatibilité v1.

### Inventaire complet et zones du commit

| Fichier | Zone modifiée et effet |
| --- | --- |
| `packages/avelune_converter_core/lib/src/source_normalization.dart` | `SourceNormalizationLimits.maxConnections`, états d'extraction et `NormalizedMapConnection` ; lecture bornée du graphe compilé complet, identités/locators et conservation des voisins exclus. |
| `packages/avelune_converter_core/lib/src/source_semantics.dart` | `SourceConnectionEntryTilePassage` et `resolveConnectionEntryTile` : Z2→Z0, d0, full nibble, pont inactif/tag ignoré, profils/contextes inconnus explicitement fermés. |
| `packages/avelune_converter_core/test/source_normalization_test.dart` | Graphes originaux : six champs, offsets, limites, corruption, états d'extraction ; opt-in du vrai graphe Kanto avec neighbors conservés. |
| `packages/avelune_converter_core/test/source_connection_entry_semantics_test.dart` | d0 distinct du cardinal inverse, passages15/7, priorités, terrains, contexte/hash et preuve source exacts. |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | Export public de `source_connection_study_composer`. |
| `packages/avelune_converter_adapters/lib/src/source_connection_study_composer.dart` | Nouveau composer : hash du fichier complet, géométrie, multiplicité globale avant sélection, empreintes `size(w,h)` des événements, toutes arrivées bidirectionnelles et mutation canonique après sauvegarde des cartes. |
| `packages/avelune_converter_adapters/lib/src/source_event_arrival_validation.dart` | `validateConnections` : relecture de toutes les destinations source/native, hitbox finale et eau, liaison exacte source/map/offset/réciproque ; mismatch refusé avant staging. |
| `packages/avelune_converter_adapters/lib/src/source_semantics_projection.dart` | Une case cardinalement fermée ne devient pas un bloc solide quand l'oracle d0 source admet une arrivée. |
| `packages/avelune_converter_adapters/lib/src/source_semantic_study_composer.dart` | Compose les connexions après les cartes et conserve leurs preuves/diagnostics dans les sémantiques attestées. |
| `packages/avelune_converter_adapters/lib/src/source_event_study_composer.dart` | Propagation des connexions, limites et preuve finale lors de l'ajout des événements natifs. |
| `packages/avelune_converter_adapters/lib/src/converter_workflow.dart` | Extraction du graphe quand le fichier existe, budgets/maxConnections dans les settings, règle et capability d'action canonique, diagnostics de connexions dans le plan. |
| `packages/avelune_converter_adapters/lib/src/converter_study_plan_recipe.dart` | Recette stricte v2, maxConnections et maxTotalDraftJsonBytes revalidés ; anciennes versions refusées. |
| `packages/avelune_converter_adapters/lib/src/local_review_session_store.dart` | Persistance/reprise des budgets nouveaux et refus des configurations hors limites. |
| `packages/avelune_converter_adapters/lib/src/native_project_writer.dart` | Binding v2 ordonné, budget JSON total défaut64MiB/plafond256MiB et références bornées ; rebind avant staging, régénération exacte record par record ; action bidirectionnelle et validation des arrivées. |
| `packages/avelune_converter_adapters/lib/src/native_project_publication.dart` | Estimation de disque depuis `validatedJsonByteLength`, sans reconstruire un record agrégé non borné ; facteurs artefacts×3, metadata×2, journaux×2 conservés. |
| `packages/avelune_converter_adapters/tool/source_semantics_study.dart` | Graphe compilé et budgets explicites ; relecture stricte des cartes après connexions/audio/événements, flags de qualification non extrapolés. |
| `packages/avelune_converter_adapters/test/source_connection_study_composer_test.dart` | Positif réciproque/offsets, multiplicité incluant voisins exclus, bord/events/footprints, mismatch et données modifiées ; import redondant retiré. |
| `packages/avelune_converter_adapters/test/native_project_draft_binding_test.dart` | Records complets et ordonnés, manifestes distincts, quotas cumulés et références, refus avant mutation du port. |
| `packages/avelune_converter_adapters/test/source_semantics_study_tool_test.dart` | Tests du calcul des cartes attendues de l'outil après mutations ; garde-fous de sélection, géométrie et connexions. Le test n'exécute pas le main de la CLI. |
| `packages/avelune_converter_adapters/test/converter_study_plan_recipe_test.dart` | Round-trip v2 et garde-fous des nouveaux budgets, versions/champs invalides refusés. |
| `packages/avelune_converter_adapters/test/local_review_session_store_test.dart` | Settings exacts après reprise, limites/admission et refus des données persistées invalides. |
| `packages/avelune_converter_adapters/test/source_semantics_projection_test.dart` | Cas d0/cardinal divergents et non-régression des obstacles/depth. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | À l'arrivée d'une connexion, remplace le test de cellule par la vraie hitbox de collision et le garde eau/surf ; aucune logique Ruby dans Flame. |
| `packages/map_runtime/test/playable_map_game_connection_arrival_collision_test.dart` | Neuf scénarios réels d'arrivée, obstacles/hitbox/eau et aller-retour sur fixture originale. |
| `documentation/reports/converter/AC-15/15_kanto_publication.md` | Ce complément consolidé ; aucun nouveau Markdown. Les diffs Git restent la preuve des hunks. |

### Vérifications terminales fraîches

Racine des reçus : `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5`. Les commandes utilisent `repository/<package>` privé dont les sources correspondent exactement au host. Le superviseur conserve PID, descendants et identité, vérifie leur propriété avant terminaison et ne touche pas aux sessions étrangères. Tous les runs cités ci-dessous sont terminaux sans timeout/survivant et avec protections/pins identiques.

| Commande, depuis le package concerné | Résultat exact | Reçu |
| --- | --- | --- |
| Core : `dart test test/source_normalization_test.dart test/source_connection_entry_semantics_test.dart --concurrency=1 --reporter=expanded` | 74 PASS, 0 SKIP, exit0 /8.964s ; opt-in graphe Kanto actif | `connection-core-tests-03.json` |
| Adapters : `dart test test/source_connection_study_composer_test.dart test/source_event_arrival_validation_test.dart test/native_project_draft_binding_test.dart test/native_project_writer_test.dart test/native_project_publication_test.dart test/publication_workflow_reproducibility_test.dart test/converter_study_plan_recipe_test.dart test/local_review_session_store_test.dart test/review_session_resumer_test.dart test/source_semantics_projection_test.dart test/source_semantics_study_tool_test.dart test/converter_workflow_test.dart --concurrency=1 --reporter=expanded` | 299 PASS, 0 FAIL, 0 SKIP, exit0 /191.243s ; trois oracles Scripts opt-in actifs | `connection-adapters-tests-04.json` |
| Adapters : `dart analyze lib test tool/source_semantics_study.dart` | No issues found, exit0 /9.346s | `connection-adapters-analyze-02.json` |
| Core : `dart analyze lib/src/source_normalization.dart lib/src/source_semantics.dart test/source_normalization_test.dart test/source_connection_entry_semantics_test.dart` | No issues found, exit0 /2.455s | `connection-core-analyze-01.json` |
| Authoring : `dart test test/domains/maps/warp_connection_transaction_test.dart test/tooling/jsonl_connection_flow_test.dart test/parity/full_authoring_parity_test.dart --concurrency=1 --reporter=expanded` | 31 PASS, exit0 /29.554s | `connection-authoring-tests-02.json` |
| Runtime : `flutter test --no-pub --concurrency=1 --reporter=expanded test/playable_map_game_connection_arrival_collision_test.dart` | 9 PASS, exit0 /6.358s | `connection-runtime-tests-02.json` |
| Runtime : `flutter test --no-pub --concurrency=1 --reporter=expanded test/phase_a_golden_battle_slice_smoke_test.dart` | 3 PASS, exit0 /5.233s | `connection-runtime-smoke-01.json` |
| Runtime : `flutter analyze --no-pub --no-fatal-infos lib/src/presentation/flame/playable_map_game.dart test/playable_map_game_connection_arrival_collision_test.dart` | 0 erreur/warning, 4 infos préexistantes, exit0 /11.291s ; pas « No issues » | `connection-runtime-analyze-02.json` |
| Adapters : `dart compile exe tool/source_semantics_study.dart -o <QA>/bin/source-semantics-study-connections-final` | Generated executable, exit0 /25.566s | `connection-cli-aot-02.json` |
| MCP : `npm run check` puis `npm run build` | exit0 /2.333s puis exit0 /2.351s | `connection-mcp-check-01.json`, `connection-mcp-build-01.json` |
| MCP : `node --import tsx --test --test-concurrency=1 test/spatial_authoring.test.ts test/read_only_server.test.ts` | 6 PASS/1 FAIL, exit1 /44.490s ; connexion canonique et lectures graphe PASS | `connection-mcp-tests-01.json` |
| Authoring : `dart run tool/pmcp085_conformance.dart` | PARTIAL global, exit1 /11.174s :88 resources/405 actions,0 missing déclarées ; certification transport globale false | `connection-pmcp085-01.json` |
| MCP vivant reconstruit : `node qa_connection_read.mjs <projet r8> <QA>/connection-published-live-mcp-result-02.json` | 2 cartes/2 connexions, catalogue/action présents, validation structure valide ;1160 fichiers exacts, exit0 /25.732s | `connection-published-live-mcp-02.json` |

Le test MCP en échec attend une liste fermée d'outils qui omet les deux outils actuels de création de projet. Son fichier est exact contre HEAD, SHA `2f0aebdc535f807a58356e5759a5dc525c5015777e7345ad1535d3501851b716` ; aucun fichier serveur/test MCP n'est modifié par cette tranche. Le catalogue global ne possède pas tous les reçus end-to-end : les tests ciblés ne sont pas assimilés à sa certification. Les quatre infos runtime correspondent à des lignes inchangées de HEAD :281/296 initializing formals,9574 null-aware element,10625 braces. Aucun correctif étranger pour obtenir artificiellement un vert.

Incidents conservés : premier run adapters285 PASS/14 SKIP sans oracles ; deuxième298 PASS/1 FAIL avec support Game.exe absent du dossier privé ; après récupération attestée,299 PASS/0 SKIP puis rerun final identique. Premier authoring échouait au chargement sur image4.11/archive4.0.9 résolus sans lock ; la copie exacte du lock host (image4.9.2/archive4.0.9) dans QA ferme cet incident sans modifier les dépendances host. Première analyse adapters signalait1 import redondant ; retrait et analyse finale sans issue. Premier probe MCP privé omettait l'ID du worldGraph et avait un message assert invalide ; correction du harnais selon le contrat publié, pas du produit, puis preuve02 PASS. Les reçus d'échec restent disponibles.

### Témoins source retrouvés et parcours encore incomplet

Les témoins conservés dans la publication r8 permettent de reconstituer en privé `Data/Scripts.rxdata` (1080290 octets, SHA `3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d`) et `Graphics/Tilesets/FRLG_Outside.png` (305862 octets, SHA `fb9950c4130bf1201d924af4de2da65f744c7c663ac41993ce332867c24cdd81`). Le décodage des chunks contrôle leurs offsets, tailles et hashes contre le snapshot historique. `recovered-source-witnesses-01.json` vérifie avant/après les1160 fichiers publiés et l'absence des originaux. `source-oracle-support-recovery-01.json` consigne les configurations source présentes et un Game.exe Hoenn byte-identique au hash Kanto historique, copié dans QA uniquement et jamais exécuté. Aucun remplacement du backup PNG ni restauration silencieuse dans le dossier source.

Les copies privées attestées débloquent les oracles, pas une affirmation de nouveau scan global actuel. Les trois originaux restent absents de Kanto. La publication r8 est autonome ; sa révision native live est `sha256:d726bda92dbcd049ac93a5f3d85ccc149ed15fa313d2de0f1dacb3be97906ebf`.

L'audit source indépendant `ac12_validation_design`, gelé dans `ledge-source-audit/audit-result-final.json`, SHA `27fcb3d8d1f938b9c7b9244d6808e25370e6e8facee15a0ff7ddf4fb4680f2ef`, lit les402 sections du Ruby sans l'exécuter. `044.rb:237–257` admet sortie+entrée inverse avant que `046.rb:141–153` détecte le ledge ; `044.rb:767` contrôle l'atterrissage d0. Le Nord `(68,21)→(68,20)` est réellement interdit par la source. Le trajet légal vers la jointure exige des sauts vers le bas :1 depuis le spawn,3 depuis ETHER ; un retour légal comporte2 sauts. Cela établit l'oracle statique manquant, pas une nouvelle exécution runtime.

La qualification runtime réelle v5 reste0 PASS/1 FAIL : départ natif, marche jusqu'à ETHER, messages et gain/self-A, sauvegarde disque et nouvelle instance/load puis retour/réinteraction sans duplication sont acquis ; aucune connexion traversée. Les flags `sourceCrossingParityQualified`, `wholeSourceConnectivityQualified`, `realCrossingJourneyQualified` et certification gameplay globale restent false. Aucun spawn déplacé, obstacle ouvert ou position injectée pour masquer cet échec.

### Passes, parité et autocritique

| Passe | Verdict borné |
| --- | --- |
| Audit / Architecture, root et ac12_validation_design | d0/entrée connexion distincte de marche et saut ; graphe complet avant sélection ; autorité native Avelune conservée. |
| Implémentation, root et passes précédentes | Connexions canoniques et binding ordonné sous budgets cumulatifs, settings/recette propagés ; modification runtime limitée à admission d'arrivée. |
| Tests, root | Core74, adapters299 sans skip, authoring31, runtime arrivée9 et smoke3 ; garde-fous positifs/négatifs et non-régressions. |
| Build / Validation, root | AOT final PASS, MCP reconstruit et lu sur vrai r8 ;1160 fichiers inchangés ; analyse adapters sans issue, infos runtime et échec global MCP explicites. |
| Critique finale, ac15_connection_review_fresh | Aucun P1/P2 identifié sur les24 fichiers ; suspicion regex de footprint infirmée par code et probe privé. Verdict ne remplace pas la qualification réelle intercartes. |

Aucune nouvelle action native n'est créée : `connection.create_bidirectional_apply` et les ressources mapConnection/worldGraph existantes sont utilisées. Direct API/JSONL et MCP vivant sont éprouvés ; lecture/édition Studio historique de la paire reste distincte, aucun nouveau contrat d'interface ici. La suite complète du monorepo, le rebuild de l'application desktop et la distribution ne sont pas revendiqués par la compilation de la CLI.

Auto-critique : un graph nativement relisible et une validation d'arrivée ne rendent pas le bord accessible ; la preuve statique avec sauts identifie justement la capacité runtime manquante. Le binding compact ne dispense pas d'intégrer la revue multicarte, ni de mesurer sa recette portable. L'application garde les limites par défaut128 artefacts/256 mutations ; la paire utilise130/266 avec budget d'étude explicite, encore à intégrer au parcours normal. La bibliothèque chemins/arbres reste dans une autre sortie. Aucun all-green global ni conversion intégrale Kanto déclaré.

Le commit est limité aux25 chemins de l'inventaire. `connection-tranche-commit.json` sera produit après commit pour conserver SHA, parent, blobs exacts, index et preuve des50 chemins étrangers ; son existence et son contenu devront alors être vérifiés. Aucun push/rebase/amend/branche. Le ticket AC15 demeure DOING/PARTIAL dans son domaine Post Bêta existant, hors gate ; aucune roadmap FG ou famille bêta modifiée. La suite autorisée traite le saut dirigé natif puis le parcours réel avec sauvegarde, et les consommateurs de la revue multicarte dans leurs propres tranches.

## Complément AC-15 — propriété de saut sur Border, 13 octobre 2026

### Audit initial et portée

La demande utilisateur fixe la vraie Border comme source de vérité du saut. La tranche DATA porte une propriété nullable sur sa définition draft/pub, sans zone gameplay persistée ni surcharge indépendante par feature. Le plan runtime doit encore être dérivé de la géométrie placée et de la révision publiée. FG-120 reste PARTIAL ; FG-014/FG-067 ne reçoivent aucun statut DONE et la roadmap reste inchangée. Les règles de combat Avelune sont conservées.

Base `main`, HEAD `91bb4e7e58ce5ce65ff681b7f1c720246b705e6b`, index initial vide. `baseline-01.json` sous la racine QA ci-dessous conserve les dix sources initiales et67chemins étrangers, puis les baselines additionnelles/consumers. Les6fichiers du scope déjà modifiés par un autre chantier ne sont jamais copiés intégralement dans le commit. `implementation-code-pins-final-02.json` couvre22sources/tests ; inverser exactement nos insertions dans le host restitue leurs baselines étrangères byte-pour-byte. Le snapshot privé est HEAD plus nos seuls hunks, sans worktree Git.

L’audit du modèle/codec a fixé V6, le payload strict et la promotion des deux branches avant le retour spatial V5. La revue indépendante a identifié trois pertes du nouveau champ : copie du draft, candidat legacy et réédition ressource Studio. Chaque chemin reconstruit sa définition ; la correction copie uniquement le champ existant. Aucune géométrie, collision, interface ou source projet n’est modifiée dans ce commit.

### Inventaire complet et zones

| Fichier | Zone et effet |
| --- | --- |
| `packages/map_core/lib/map_core_domain.dart` | Export du modèle public. |
| `packages/map_core/lib/src/models/border_blueprint.dart` | Champ nullable draft/pub ; égalité et hash. |
| `packages/map_core/lib/src/models/border_catalog.dart` | Version catalogue V6. |
| `packages/map_core/lib/src/operations/border_blueprint_json_codec.dart` | Lecture/écriture fermée et refus avant V6. |
| `packages/map_core/lib/src/operations/border_format_version.dart` | Promotion draft/pub V6 avant retour spatial V5. |
| `packages/map_core/lib/src/operations/project_border_catalog_json_codec.dart` | Admission stricte V6. |
| `packages/map_core/lib/src/operations/border_fingerprints.dart` | Empreintes 2D liées aux paramètres. |
| `packages/map_core/lib/src/operations/border_publication_readiness.dart` | Empreinte du candidat de publication. |
| `packages/map_core/lib/src/operations/spatial_border_resolution.dart` | Empreinte spatiale liée au payload V6. |
| `packages/map_authoring/lib/src/domains/maps/border_catalog_actions.dart` | Publications 2D/3D et extension discoverable typée. |
| `packages/map_authoring/test/domains/maps/border_catalog_actions_test.dart` | Publication2D atomique avec payload et non-régression ordinaire. |
| `packages/map_core/test/border/project_border_catalog_json_codec_test.dart` | V6 admis ; future version7 refusée. |
| `packages/map_editor/lib/src/features/border_studio/application/border_studio_draft_controller.dart` | Conserver source.jumpBehavior dans _copyDefinition. |
| `packages/map_editor/lib/src/features/border_studio/application/border_publication_candidate_builder.dart` | Conserver draftDefinition.jumpBehavior lors de publication. |
| `apps/avelune_studio/lib/features/resources/data/local_border_resource_adapter.dart` | Conserver existing.draft.definition.jumpBehavior en réédition. |
| `packages/map_editor/test/border_studio/border_publication_candidate_builder_test.dart` | Conservation du candidat et régressions existantes. |
| `packages/map_core/lib/src/models/border_jump_behavior.dart` | Payload fermé side/distanceCells/durationMs/peakHeightPx et bornes. |
| `packages/map_core/test/border/border_jump_behavior_test.dart` | Roundtrip, fermeture, promotion, empreintes et résolution. |
| `packages/map_authoring/test/domains/maps/border_jump_behavior_actions_test.dart` | Descripteurs, publication canonique3D et matérialisation sans zone. |
| `packages/map_editor/test/border_studio/border_jump_behavior_preservation_test.dart` | Controller réel mounted ou Studio ResourcePort réel ; édition/save/reopen. |
| `apps/avelune_studio/test/resource_io/border_jump_behavior_preservation_test.dart` | Controller réel mounted ou Studio ResourcePort réel ; édition/save/reopen. |
| `tools/pokemap_mcp/test/border_jump_behavior_stdio.test.ts` | MCP stdio vivant, invalidité sans write, upsert/pub/query/reopen. |
| `documentation/reports/converter/AC-15/15_kanto_publication.md` | Ce complément consolidé ; aucun nouveau Markdown. |

### Contrat et limites

`jumpBehavior` absent conserve une Border ordinaire. Présent, il exige exactement `side` (primary/inverted), `distanceCells` (2), `durationMs` (1..60000) et `peakHeightPx` (1..1024). Défauts2/500/24. Les payloads incomplets, nuls présents, inconnus, mal typés ou hors bornes sont refusés ; aucune lecture/écriture antérieure à V6 ne perd silencieusement le réglage. Le champ modifie equality/hash et les empreintes2D/spatiales/publication. Les paramètres existent comme contrat DATA ; cette tranche ne prouve pas leur exécution dans le Player.

Le côté devra combiner la normale du contour et le lineSide de la feature ; angles ambigus, phase A/B/C et ownership de collision restent à qualifier. Deux cellules natives32px sont bornées au profil Essentials étudié. Le handoff Carillon projeté f6d75b177df1ab41ccba734cbd744ae6fac077b0ac83f6578eba285e6e4e36fa mesure une cellule verticale24.033px :153contacts sources plans valides,57paires seulement raccordables à deux cellules natives. Ces mesures ne certifient pas la distance retail HGSS et ne sont pas couvertes par ce profil. Aucun élargissement du sol ni déplacement de passerelle n’est autorisé par un mismatch.

### Vérifications fraîches

Racine durable : `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private`. Les commandes des reçus tournent dans son `repository/<package>` avec configurations qualifiées, image4.9.2/archive4.0.9 ; aucun lockfile host modifié. Le superviseur enregistre les descendants et vérifie PID/UID/date/commande avant nettoyage. Tous les reçus finaux cités ci-dessous sont terminaux, sans survivant ni signal et avec processus protégés inchangés. `final-proof-check-01.json` vérifie les hashes de logs et pins encore courants.

| Reçu | Résultat |
| --- | --- |
| core-contract-regressions-03 | 209PASS, exit0,14.903s. |
| authoring-contract-parity-03 | 35PASS, exit0,30.300s, dont publications2D/3D et suite parité. |
| consumer-editor-green-02 | 18PASS, exit0,5.225s. |
| consumer-studio-green-02 | 8PASS, exit0,15.506s. |
| mcp-jump-live-01 | 1PASS, exit0,1.928s : serveur reconstruit, catalogue vivant, vraie mutation/refus/reopen. |
| mcp-catalog-regressions-01 | 1PASS, exit0,16.310s. |
| authoring-cli-aot-01 | Build AOT authoring, exit0,22.239s. |
| mcp-check-01 / mcp-build-01 | TypeScript check/build exit0,1.361s/1.352s. |
| core-contract-analyze-01 | Exit0,4INFO préexistantes,3.841s ; correspondance HEAD exacte dans core-analysis-baseline-correspondence-01. |
| authoring-contract-analyze-01 | No issues found, exit0,6.227s. |
| consumer-editor-analyze-01 | No issues found, exit0,8.115s. |
| consumer-studio-analyze-01 | No issues found, exit0,9.311s. |
| authoring-pmcp085-01 | Exit1,15.133s :88resources/405actions,0missing ; certifications transport globale/item false. |

RED fonctionnels conservés : consumer-editor-red-03 échoue2cas avec actualnull (draft et publication) ; consumer-studio-red-02 échoue1cas avec actualnull après réédition. Les corrections produisent les GREEN finaux ci-dessus. Les premiers essais manquaient package_graph ou utilisaient une empreinte fixture invalide ; ils ne sont pas présentés comme RED fonctionnels. Le primitive du test controller exige ses metrics sprite ; le premier GREEN17PASS/1FAIL de fixture est conservé, suivi du GREEN18PASS final.

La suite historique complète `border_studio_draft_controller_test.dart` ne compile pas contre HEAD : consommateurs préexistants de String? dans editor_notifier, asset/publication services et environment use cases. Aucune réparation hors scope. Notre test monte le contrôleur de production dans un vrai ProviderContainer/NotifierProvider, avec teardown, sans importer ce graphe complet. Cela prouve les trois éditions ordinaires et saveDraft ; aucune UI visible revendiquée.

Commandes exactes des reçus terminaux (les tests Dart utilisent directement package:test pour garder le graphe qualifié) :

```text
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/repository/packages/map_core
dart --packages=.dart_tool/package_config.json /Users/karim/.pub-cache/hosted/pub.dev/test-1.31.1/bin/test.dart --reporter=expanded test/border/border_jump_behavior_test.dart test/border/border_blueprint_json_codec_test.dart test/border/border_catalog_operations_test.dart test/border/project_border_catalog_json_codec_test.dart test/border/border_fingerprints_test.dart test/border/spatial_border_resolution_test.dart test/border/border_publication_readiness_test.dart test/border/border_materialization_freshness_test.dart
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/repository/packages/map_authoring
dart --packages=.dart_tool/package_config.json /Users/karim/.pub-cache/hosted/pub.dev/test-1.31.2/bin/test.dart --reporter=expanded test/domains/maps/border_jump_behavior_actions_test.dart test/domains/maps/border_catalog_actions_test.dart test/domains/maps/border_spatial_behavior_actions_test.dart test/parity/full_authoring_parity_test.dart
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/repository/packages/map_editor
flutter test --no-pub --concurrency=1 --reporter=expanded test/border_studio/border_jump_behavior_preservation_test.dart test/border_studio/border_publication_candidate_builder_test.dart
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/repository/apps/avelune_studio
flutter test --no-pub --concurrency=1 --reporter=expanded test/resource_io/border_jump_behavior_preservation_test.dart test/resource_io/spatial_border_resource_adapter_test.dart
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/repository/tools/pokemap_mcp
node --import tsx --test test/border_jump_behavior_stdio.test.ts
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/repository/tools/pokemap_mcp
node --import tsx --test test/border_catalog_server.test.ts
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/repository/packages/map_authoring
dart compile exe --packages=.dart_tool/package_config.json bin/pokemap_authoring.dart -o '/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/authoring-cli'
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/repository/tools/pokemap_mcp
npm run check
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/repository/tools/pokemap_mcp
npm run build
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/repository/packages/map_core
dart analyze lib/src/models/border_jump_behavior.dart lib/src/models/border_blueprint.dart lib/src/models/border_catalog.dart lib/src/operations/border_blueprint_json_codec.dart lib/src/operations/border_format_version.dart lib/src/operations/project_border_catalog_json_codec.dart lib/src/operations/border_fingerprints.dart lib/src/operations/border_publication_readiness.dart lib/src/operations/spatial_border_resolution.dart test/border/border_jump_behavior_test.dart test/border/project_border_catalog_json_codec_test.dart
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/repository/packages/map_authoring
dart analyze lib/src/domains/maps/border_catalog_actions.dart test/domains/maps/border_jump_behavior_actions_test.dart test/domains/maps/border_catalog_actions_test.dart
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/repository/packages/map_editor
flutter analyze --no-pub --no-fatal-infos lib/src/features/border_studio/application/border_studio_draft_controller.dart lib/src/features/border_studio/application/border_publication_candidate_builder.dart test/border_studio/border_jump_behavior_preservation_test.dart test/border_studio/border_publication_candidate_builder_test.dart
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/repository/apps/avelune_studio
flutter analyze --no-pub --no-fatal-infos lib/features/resources/data/local_border_resource_adapter.dart test/resource_io/border_jump_behavior_preservation_test.dart
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-contract-private/repository/packages/map_authoring
dart --packages=.dart_tool/package_config.json tool/pmcp085_conformance.dart
```

### Passes et critique finale

| Passe | Verdict borné |
| --- | --- |
| Audit / Architecture root et ac15_connection_review_fresh | Propriété du Blueprint retenue ; source géométrique/propriétaire obligatoire ; aucun saut Carillon certifié. |
| Implémentation root | ContratV6 fermé, forwards2D/3D, empreintes et trois consumers ; aucun commentaire ajouté conformément à la consigne directe. |
| Tests root | RED/GREEN conservés ;209core/35API-parité/18editor/8Studio/2MCP. |
| Build / Validation root | CLI AOT et TScheck/build PASS ;4INFO core anciennes ; PMCP globalPARTIAL explicite. |
| Critique indépendante ac15_connection_review_fresh | P2 des trois consumers fermé sur ledgerfinal02 ;22hashes host/snapshot, RED/GREEN et MCP relus, aucun autre P1/P2 DATA. Runtime/arrivée et producteur non qualifiés par ce verdict. |

Auto-critique : un descripteur et un roundtrip ne constituent pas une capacité de gameplay. La propriété manque encore de producteur de plan, règles sur normales/angles/transforms, exception des seules contributions de collision de la Border, invalidation après déplacement/suppression/republication, picker Studio et parcours réel. Le prototype movementEffect/zone n’est pas retenu comme contrat d’auteur final. Le composer prototype garde son P2 manifeste incomplet ; aucune publication source nouvelle.

La compilation complète de Studio/Converter, GUI, distribution et parcours Kanto ne sont pas requis pour prouver cette tranche de données et ne sont pas revendiqués ; la meilleure validation alternative est la compilation AOT de l’API réelle et les tests Flutter des consommateurs. AC15 reste DOING/PARTIAL dans son domaine Post Bêta existant. Aucun ticket/famille/gate bêta créé ou étendu ; aucune roadmap modifiée. Le reçu externe border-data-commit-01.json sera créé puis vérifié après commit pour SHA/parent/blobs/index et conservation de tous les fichiers host avant/après. Aucun push/rebase/PR. La prochaine tranche raccorde le saut réel à la Border avant qualification Route9↔Route10 et le reste du workflow multicarte.


### Sous-tranche AC-15 — candidats topologiques de saut Border, 13 octobre 2026

Audit initial : le contrat DATA V6 est commité `fb4c8c27a292d8f87884faad6f3f5085cb5ce53f`. Les contours de région possèdent déjà une arête unitaire, son `interiorCell` et sa normale extérieure ; le lattice possède les directions canoniques des nœuds et arêtes et la lineage de parcours. Les transformations visuelles ConnectedLine 2D ne certifient pas une normale dirigée ; les slotKeys hashés ne permettent pas de retrouver une arête. Le futur producteur doit donc qualifier ses placements finaux et contacts propriétaires, au lieu de déduire un droit de saut d'une bounding box ou d'un nom de template.

Portée retenue : API descriptive pure `deriveBorderJumpFaceCandidates`. Elle ne choisit pas le carrier physique `gridEdges`, ne produit aucune permission ni arrivée et n'atteste aucune matérialisation. `topologicalNormal` et `potentialCarrierCells` rendent cette limite explicite. Régions : B potentiel égale interiorCell, cellules avec normales concurrentes omises, trous selon le contour original. CellCenters : angles omis, caps héritent de leur portion droite. GridEdges : un segment donne un candidat avec ses seuls carriers adjacents dans le domaine de carte. Inverser le saut conserve coordonnées et carriers potentiels. Géométrie/template/alignment/dimensions/publication et bornes portables sont vérifiées ; les blueprints spatiaux sont explicitement refusés par cette API 2D. Aucun commentaire ajouté conformément à la consigne directe.

Lot FG concerné : FG-120 reste PARTIAL. FG-014 et FG-067 sont les frontières d'arrivée/sauvegarde de la suite, sans modification de leurs statuts ni de la roadmap. Le contrat d'auteur reste la vraie Border ; aucune zone persistée nouvelle.

Inventaire exhaustif de cette tranche :

| Fichier | Zones / raison / impact |
| --- | --- |
| `packages/map_core/lib/src/operations/border_jump_faces.dart` | Nouveau fichier, lignes 17/37/168/252/259 : candidat immutable, dérivation strokes/régions, conversion pixel et refus du canvas non portable. Aucune permission physique. |
| `packages/map_core/lib/map_core_domain.dart` | Un seul export adjacent aux contours, vérifié par retrait byte-exact contre HEAD. |
| `packages/map_core/test/border/border_jump_faces_test.dart` | 14 nouveaux cas : quatre directions conservées, sides, caps, angles, trous, bandes minces, frontières de carte, tuiles impaires rectangulaires, immutabilité, refus géométrie/template/spatial/portable et Border ordinaire. |
| `documentation/reports/converter/AC-15/15_kanto_publication.md` | Cette section consolide audit, preuves et limites ; zéro nouveau Markdown. |

État Git initial : HEAD `fb4c8c27a292d8f87884faad6f3f5085cb5ce53f`, index vide. Inventaire exact conservé dans `git-initial-status-01.bin` du répertoire de preuve ; 85 chemins dirty préexistants à l'ajout de cette section, dont les 3 chemins de géométrie de cette tranche. Aucun nettoyage ni absorption des autres travaux.

Preuve privée : archive `HEAD fb4c + 3 chemins root uniquement`, pas un nouveau worktree Git. Runtime/zone/Converter et changements étrangers ne sont pas dans cette archive. Graphe de dépendances qualifié copié sans résolution Pub automatique. Répertoire : `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-geometry-private`.

Le premier RED est fonctionnel : 2 PASS / 7 FAIL avec le dériveur vide. Les noms ont ensuite été précisés pour distinguer candidats/permission, sans modifier la prémisse du RED. GREEN01 : 9 PASS. Extension des garde-fous puis GREEN02 : 14 PASS. Régressions finales : 78 PASS / 0 FAIL sur candidats, contours, lattice, canonicalisation, fraîcheur et contrat DATA. La suite complète map_core n'a pas été exécutée : la modification ajoute une API descriptive sans changer les algorithmes existants ; les six suites concernées sont vérifiées.

Commandes exactes et résultats (cwd package map_core de l'archive, fichiers/reçus/logs hashés) :

`faces-red-01.json` : exit1, 8.714 s.

```text
dart --packages=.dart_tool/package_config.json /Users/karim/.pub-cache/hosted/pub.dev/test-1.31.1/bin/test.dart test/border/border_jump_faces_test.dart --reporter=expanded
```

`faces-green-01.json` : exit0, 6.903 s.

```text
dart --packages=.dart_tool/package_config.json /Users/karim/.pub-cache/hosted/pub.dev/test-1.31.1/bin/test.dart test/border/border_jump_faces_test.dart --reporter=expanded
```

`faces-green-02.json` : exit0, 12.565 s.

```text
dart --packages=.dart_tool/package_config.json /Users/karim/.pub-cache/hosted/pub.dev/test-1.31.1/bin/test.dart test/border/border_jump_faces_test.dart --reporter=expanded
```

`faces-regressions-01.json` : exit0, 6.745 s.

```text
dart --packages=.dart_tool/package_config.json /Users/karim/.pub-cache/hosted/pub.dev/test-1.31.1/bin/test.dart test/border/border_jump_faces_test.dart test/border/border_region_contours_test.dart test/border/border_linear_lattice_test.dart test/border/border_stroke_canonicalization_test.dart test/border/border_materialization_freshness_test.dart test/border/border_jump_behavior_test.dart --reporter=expanded
```

`faces-analyze-01.json` : exit0, 2.852 s.

```text
dart analyze lib/src/operations/border_jump_faces.dart test/border/border_jump_faces_test.dart lib/map_core_domain.dart
```

`faces-kernel-01.json` : exit0, 3.459 s.

```text
dart compile kernel --packages=.dart_tool/package_config.json test/border/border_jump_faces_test.dart -o "/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-geometry-private/faces-kernel-01.dill"
```

L'analyse termine exit0 avec une INFO `unnecessary_library_name` dans le barrel : sa déclaration `library map_core;` est byte-identique à HEAD. Aucun warning/erreur. Compilation kernel de l'entrée de test et du barrel public PASS ; aucun build GUI complet ni compilation/distribution Converter revendiqués. Les reçus du supervisor vérifient stabilité des fichiers avant/après, logs SHA exacts, protectedUnchanged=true, confirmedSurvivors=[] ; aucun GUI ouvert, aucun signal nécessaire.

Ledger final `faces-final-pins-01.json`, SHA `47aef54552f108a8f4d45d908d2bee26e2096b9fb34b587febc53bed643dbae2` : 3 sources/tests host=archive, six reçus et hashes de logs. Correction de métadonnée `baseline-01-correction.json` : le premier reçu avait réutilisé la variable du chemin pubspec.lock dans son champ barrel ; les sources et le RED n'ont pas été modifiés par cette correction.

| Passe | Verdict borné |
| --- | --- |
| Audit / Architecture ac15_connection_review_fresh | Les carriers et normales sont topologiques ; contacts finaux et attribution resolver nécessaires. ConnectedLine q0/q1 ne prouve pas quatre faces visuelles. |
| Implémentation root | 3 chemins de code, aucune modification des données/projets, aucune admission de saut. |
| Tests root | RED fonctionnel puis 14 cas, 78 régressions PASS ; aucune extrapolation vers Player ou source. |
| Build / Validation root | Kernel PASS, analyse exit0 avec une INFO préexistante, reçus et pins exacts. |
| Critique indépendante ac15_connection_review_fresh | Aucun P1/P2 sur les 3 fichiers et la portée descriptive ; GREEN02/pins/analyse relus. Les régressions78 et kernel ont été vérifiés par root ; aucune exécution indépendante revendiquée. |

Évaluation MCP : cette API pure n'ajoute ni donnée auteur ni commande/transport. Le contrat jumpBehavior est déjà porté par l'action canonique attestée dans la tranche DATA. Une permission semantic native, son contrôle de fraîcheur et le picker Studio ne sont toujours pas exposés : couverture produit globale PARTIAL. Aucun generic save n'est utilisé comme preuve.

Auto-critique / limites : key est locale à feature/request et ne contient pas map/layer/révision/contexte de collision ; le binder doit lui ajouter ce contexte. Les deux carriers gridEdges ne sont pas deux ledges ; un unique B doit être prouvé par contacts. Le sens topologique ne garantit pas le dessin ConnectedLine. Le binder devra refuser conflits, overrides déplaçant la face, collisions inconnues et matérialisation périmée, puis vérifier B et C avec la hitbox entière. Ni Route9↔Route10, ni source Carillon projetée, ni saut spatial, ni nouveau corpus/import/IA ne sont qualifiés. La collision propriétaire développée en parallèle est une tranche séparée ; ses deltas de prototype restent exclus du présent commit.

État final attendu / tracé : commit local strict des 4 chemins ci-dessus, reçu externe `faces-commit-01.json` avec SHA/parent/blobs/index et hashes/modes host avant/après ; index vide après commit, travaux étrangers conservés. Aucune opération push/rebase/PR. AC15 reste DOING/PARTIAL dans son ticket Post Bêta existant, aucun nouveau ticket/famille/gate. Suite : terminer l'exception de collision propriétaire, puis le binder aux placements finaux et le producteur Border, réglage Studio et vrai parcours Route9 avec collisions/profondeur/save/load.


### Sous-tranche AC-15 — collisions propriétaires de Border, 13 octobre 2026

Audit initial : `WorldCollisionStorage` fusionnait les rectangles Border dans le masque générique et perdait leur propriétaire. Une exclusion par cellule entière pouvait donc retirer un obstacle étranger. La vraie Border doit conserver ses contributions layer/feature/placement ; seule la face sélectionnée peut être exemptée à B. Source générique et native ne doivent pas dupliquer la collision du rebord, et C reçoit toutes les collisions. FG-120 demeure PARTIAL ; aucun changement de roadmap, FG-014/067 ou logique de combat.

Portée : cinq chemins gameplay uniquement, plus cette section du rapport existant. Owner immuable (layer/feature/placement), exclusion copiée/non vide et limitée à une même Border, rectangle positif/borné/contenu dans une cellule. Plusieurs placements peuvent être sélectionnés par le futur binder. Masques génériques, supports, personnages, autres owners et pixels hors area restent bloquants. Montage sans manifest d'une carte2D portant des features Border explicitement refusé. Garanties de publication/fraîcheur/références/masques/transforms existantes conservées. Le profil collision actuel de project.elements reste l'autorité.

Le premier stockage propriétaire régressait en coût : les queries ordinaires parcouraient tous les owners pour chaque pixel. Critique indépendante P2, acceptée puis corrigée par une union OR calculée au montage. Query ordinaire/hors area/pixel union libre répond avant tout scan owners. Scan détaillé limité aux pixels solides dans l'exclusion. Test dense1024owners et allocations, buffers détachés du builder. Aucune mesure de latence revendiquée.

| Fichier | Zones / raison / impact |
| --- | --- |
| `packages/map_gameplay/lib/src/collision/border_collision_geometry.dart` | Types BorderCollisionOwner/Exclusion/MaterializedBorderCollisionRect et resolver contacts propriétaires ; resolver rect-only réutilise le même chemin. |
| `packages/map_gameplay/lib/src/collision/world_collision_storage.dart` | Masques propriétaires et union par chunk, validation area, clipping des seuls owners sélectionnés, copies au build et diagnostics d'allocations exacts. |
| `packages/map_gameplay/lib/src/gameplay_world_state.dart` | Paramètre/forwarding borderExclusion, manifest guard et stamp contacts ; requête et traitement inline des personnages de HEAD conservés. |
| `packages/map_gameplay/lib/map_gameplay.dart` | Export des cinq APIs collision uniquement ; aucun export Jumped/DirectedJumpPlan/arrival de prototype. |
| `packages/map_gameplay/test/border_collision_ownership_test.dart` | Onze tests nouveaux : owners exacts, clipping, placements superposés, autres layers/features, générique mêmeB, entités/eau/limites, offsets et masques, fraîcheur/contexte, immutabilité et1024owners. |
| `documentation/reports/converter/AC-15/15_kanto_publication.md` | Consolidation de la sous-tranche, aucun nouveau Markdown. |

Séparation de scope : archive HEADfb4 + ownership seule qualifiée48PASS, puis nouvelle archive propre HEAD80ed + mêmes cinq blobs, réappliqués réellement depuis le patch. `ignoredStaticCell`, extraction arrival, gameplay_step, DirectedJumpPlan et runtime restent exclus du commit ; aucun retrait du prototype dans le host. Trois chemins host restent également dirty après staging des seuls blobs propres. Le test combiné contient une assertion sur l'ancien guard, absente du blob commité ; pas d'attribution de ce test au commit strict.

Reçus gelés : patch `border-collision-ownership-only.patch` SHA80ef0f9192aef016fcd1c199931b88ea9c70df2d9adb21a8e810f5b2884b0e11 ; ledger ownership-only01 SHA0edbd67463f832fc89a6bcfe7cf2313ec4dba204c23a276467812fa482e65e40. Critique indépendante :5paths/5blobs/patch application exacts, aucun P1/P2, P2 coût fermé sur combined02 SHA1ba1d51a550d5e5368aa1d439c5b5d4263e67084c7a3dd8173adfe19d3e521b3. Combiné :65focused,791PASS/2FAIL reproduits sur baseline ; ces totaux ne sont pas attribués au patch strict.

Preuve finale HEAD80ed : `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/ownership-head80ed-private-odqpsxc0`. Ledger ownership-head80ed-final-pins-01 SHA bb089e8c918fd12b90d238bc73e5ff74817429db7888e02c748e319331c3dbfa, fermeture1145fichiers hashés SHA b3d8aad386801751e62e61d6c5977e430f6580d369908519cc01d5622ef266a9 ; lecture root de chaque fichier et reçu vérifie les pins. Patch dry-run et application réelle exit0/5blobs identiques. Aucun fichier source/host changé par cette requalification.

Commandes finales supervisées, cwd gameplay/core de la nouvelle archive :

`focused-green-01.json` : exit0, 8.951 s.

```text
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/ownership-head80ed-private-odqpsxc0/repository/packages/map_gameplay
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart test test/border_collision_ownership_test.dart test/materialized_border_collision_test.dart test/gameplay_world_state_collision_storage_characterization_test.dart test/moving_platform_gameplay_test.dart --reporter expanded
```

`analyze-01.json` : exit0, 4.958 s.

```text
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/ownership-head80ed-private-odqpsxc0/repository/packages/map_gameplay
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart analyze lib/src/collision/border_collision_geometry.dart lib/src/collision/world_collision_storage.dart lib/src/gameplay_world_state.dart lib/map_gameplay.dart test/border_collision_ownership_test.dart
```

`gameplay-kernel-01.json` : exit0, 4.932 s.

```text
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/ownership-head80ed-private-odqpsxc0/repository/packages/map_gameplay
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart compile kernel test/border_collision_ownership_test.dart -o "/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/ownership-head80ed-private-odqpsxc0/ownership-tests.dill"
```

`core-barrel-kernel-01.json` : exit0, 4.958 s.

```text
cwd: /Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/ownership-head80ed-private-odqpsxc0/repository/packages/map_core
/opt/homebrew/share/flutter-3.47.5/bin/cache/dart-sdk/bin/dart compile kernel test/border/border_jump_faces_test.dart -o "/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/ownership-head80ed-private-odqpsxc0/core-barrel-tests.dill"
```

Résultats :48PASS/8.951s sur nouveaux owners + materialized collisions/storage/moving platforms ; analyseexit0/4.958s avec la seule INFO unnecessary_library_name préexistante (barrel), aucune erreur/warning ; kernel gameplayPASS4.932s et nouveau barrel corePASS4.958s. Suite complète du strict-only non exécutée : sélection couvre les branches modifiées ; la suite combinée garde ses deux défauts de baseline (.git benchmark d'archive et spatial spawn). Tous pins avant/après/logSHA exacts ; protectedUnchanged=true, confirmedSurvivors=[], signals=[] ; aucun GUI.

| Passe | Verdict borné |
| --- | --- |
| Audit/Architecture root et ac12_native_mapping | Union globale perdait owner ; exception typée par contact retenue, B only, contexte frais nécessaire. |
| Implémentation ac12_native_mapping |5paths et strict-only séparés du prototype ; ordinary union préserver coût sans nouvelle abstraction gameplay runtime. |
| Tests ac12_native_mapping | RED03 4PASS/5FAIL puis GREEN ; P2 agrégat RED10PASS/1FAIL puis65focused ; strict-only48PASS sur fb4 puis80ed. |
| Build/Validation ac12_native_mapping + root | Patch application, kernels et analyse vérifiés sur archive propre ; root relit1145pins/reçus/logs et5host combinés. |
| Critique ac15_connection_review_fresh | Aucun P1/P2 fonctionnel, P2 coût fermé, séparation ownership01 acquise ; qualification ne couvre aucun binder, import ou parcours runtime. |

Parité MCP : API collision pure de runtime, aucune donnée auteur ni nouvelle action dans cette sous-tranche ; la sélection de face et validation sémantique seront exposées dans le prochain contrat canonique. Le descripteur jumpBehavior précédemment attesté reste la seule capacité auteur livrée. Generic save n'est pas considéré comme une preuve de saut ; globale PARTIAL.

Auto-critique : un caller peut fournir des owners ; la query n'atteste pas qu'ils portent la même face, seulement la même Border. Le binder doit le prouver depuis la revision publiée, placements finaux et profils collision courants. C doit appeler sans exclusion. L'import doit remplacer exclusivement le solide source du ledge par cette Border sans effacer les obstacles superposés. Le composer garde son finding de manifeste incomplet. Aucune permission Border, animation, source119sauts, Route9↔Route10 ni face visuelle/3D n'est qualifiée ici.

Git initial : HEAD80ed7fe80da12e04c5de4400d7e0551cd7950e52, index vide, inventaire NUL exact git-initial-status-01.bin. Commit local prévu sur les seuls six chemins ci-dessus, reçu externe ownership-commit-01.json : SHA/parent/blobs/index et hash/mode host avant/après. Staging des blobs privés, pas des fichiers host complets. Aucun push/rebase/PR, aucun nouveau ticket/famille/gate bêta ; AC15 DOING/PARTIAL. Suite : vrai profil de face fidèle aux modules source, attribution resolver→placements finaux→owners et admission A/B/C, puis UI et parcours réel.


## Tranche AC-15 — Rebord natif porté par un Border : core V7 et API canonique

Le saut à sens unique reste une propriété optionnelle de la définition Border. Le nouveau template `ledgeLine` représente un rebord de cellule avec un module natif complet par arête unitaire. Il ne transforme pas les autres Borders en passages franchissables. La qualification de cette tranche concerne le contrat core, la résolution et la publication, puis le descripteur et les transports canoniques. Le binder gameplay, l'animation, l'import source et le parcours réel restent des gates séparées. FG-120 reste PARTIAL ; la roadmap n'est pas modifiée.

Audit initial : HEAD `1ddeb9ad6e07d7daa7a22f267c9ffe0f27b3628d`, index vide, 82 entrées dirty au moment de l'intégration. Le modèle jumpBehavior et l'ownership de collision existent déjà, mais aucun resolver ne place encore un module natif complet en gardant le canvas et l'ancre. Les états source doivent distinguer normale physique, sens autorisé et vrai contact de collision. Le champ `structure` ne prouve pas l'ordre de rendu : le runtime dessine actuellement les couches Border en arrière-plan. Aucun nouveau draw band n'est introduit.

Le resolver exige `stroke/gridEdges`, une frame de la taille de cellule, `structureLarge`, une orientation cardinale native disponible, q0 sans flip/scale/jitter, depthRows1 et absence de ground. L'origine est celle de la cellule attendue ; targetAnchor = origine + ancre primitive. Changer jump.side ne tourne ni ne retourne le sprite. Les fixtures originales asymétriques 32×32 conservent leur alpha inférieur16 et ancre16,31. Les trois replacements explicites 1194/1212/1198 restent des identités stables ; cette preuve synthétique ne certifie pas les vrais PNG Kanto ni les 119 parcours source.

Après overrides, le resolver émet les endpoints typés, la normale physique, la cellule attendue et le placement final. Suppression totale et deux faces partageant le même carrier sont refusées. Les fingerprints+forme ne suffisent pas à établir la canonicité : les deux contrepreuves resealées sont fresh au sens du helper, mais rejetées par le replay canonique Apply. Le futur binder doit comparer la matérialisation complète au replay avant toute permission.

Un P2 de publication a été reproduit : une variante complète sélectionnée par variation0 cachait une autre variante trouée. La publication vérifie maintenant chaque variante admissible indépendamment du RNG, avec continuité tangentielle sur toute la cellule. RED35PASS/1FAIL fonctionnel, puis GREEN36PASS. Ce défaut est fermé ; aucune orientation source manquante n'est fabriquée.

Inventaire core et API — les blobs exacts HEAD+tranche sont la source du staging ; les fichiers host mixtes ne sont jamais stagés en entier :

| Chemin | Zone et conséquence |
| --- | --- |
| `packages/map_core/lib/map_core_domain.dart` | export des deux API de résolution et des preuves typées |
| `packages/map_core/lib/src/models/border_catalog.dart` | catalogue V7 et promotion par maximum des capacités |
| `packages/map_core/lib/src/models/border_value_objects.dart` | template ledgeLine et nom sérialisé |
| `packages/map_core/lib/src/operations/border_format_version.dart` | séparation catalogue V7 / couche V3 |
| `packages/map_core/lib/src/operations/border_blueprint_json_codec.dart` | validation de la politique de module natif lors du décodage |
| `packages/map_core/lib/src/operations/border_resolver.dart` | dispatch canonique vers ledgeLine |
| `packages/map_core/lib/src/operations/border_relink_operations.dart` | famille gridEdges et reprise du profil natif |
| `packages/map_core/lib/src/operations/border_materialization_freshness.dart` | contrôle intrinsèque de la géométrie finale, sans promesse de replay |
| `packages/map_core/lib/src/operations/border_publication_readiness.dart` | politique ledgeLine et continuité tangentielle de chaque variante |
| `packages/map_core/lib/src/operations/border_override_resolution.dart` | revalidation après overrides et contraintes natives |
| `packages/map_core/lib/src/operations/ledge_line_border_resolver.dart` | un module complet par arête, origine du carrier, evidence immuable après overrides |
| `packages/map_core/lib/src/operations/border_canonical_gallery.dart` | galerie des seules normales disponibles et réduction explicite de couverture |
| `packages/map_core/lib/src/operations/project_border_catalog_json_codec.dart` | catalogue V7 et validation des références |
| `packages/map_core/lib/src/operations/border_fingerprints.dart` | entrées du profil ledgeLine dans les fingerprints |
| `packages/map_core/lib/src/operations/border_layer_operations.dart` | promotion de couche lors de upsert |
| `packages/map_core/lib/src/operations/border_template_capabilities.dart` | capabilités ledgeLine et maximum de version |
| `packages/map_core/lib/src/operations/border_locality.dart` | dispatch full/local ; extraction étrangère de slots conservée dans le host |
| `packages/map_core/lib/src/validation/border_validation.dart` | famille gridEdges et contrat de template |
| `packages/map_core/test/border/ledge_line_border_test.dart` | tests des versions, formats et contrats Border courants |
| `packages/map_core/test/border/border_format_version_test.dart` | tests des versions, formats et contrats Border courants |
| `packages/map_core/test/border/border_catalog_test.dart` | tests des versions, formats et contrats Border courants |
| `packages/map_core/test/border/border_manifest_integration_test.dart` | tests des versions, formats et contrats Border courants |
| `packages/map_core/test/border/border_value_objects_test.dart` | tests des versions, formats et contrats Border courants |
| `packages/map_core/test/border/project_border_catalog_json_codec_test.dart` | tests des versions, formats et contrats Border courants |
| `packages/map_core/test/border/border_publication_readiness_test.dart` | tests des versions, formats et contrats Border courants |
| `packages/map_authoring/lib/src/domains/maps/border_catalog_actions.dart` | descripteur canonique upsert/publication avec propriété ledgeLine |
| `packages/map_authoring/test/domains/maps/border_catalog_actions_test.dart` | attente de la version courante lors de la publication |
| `packages/map_authoring/test/domains/maps/border_jump_behavior_actions_test.dart` | descripteur catalogue V7 |
| `packages/map_authoring/test/domains/maps/border_ledge_line_actions_test.dart` | descripteur, snapshots, publication et construction de mutation canonique native |
| `tools/pokemap_mcp/test/border_ledge_line_stdio.test.ts` | serveur/worker réels, refus sans writes, publication et réouverture |

Preuves gelées sous `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5` :

- `ledge-line-core-private-v2s2j7pz/ledge-line-core-final-ledger-02.json`, SHA438396840d7d85f040612ff2296b9de724ad54406747d8f0312ee2b35928a283 ; patch SHA961ee4c5bc6d14e4bc221647b4a2887a3c7d576b214f4733148a8c883f141e32 ; 25blobs,18prod+7tests,2créations. Deux archives ont la même fermeture972sources SHA6d8f2060e792e4e20bd2a1be723f3888739eeada2ca291847800e02bbe6a65aa.
- `ledge-authoring-private/ledge-authoring-final-ledger-02.json`, SHA80879857dc1f1de89226e683f671bbadf8b2cbff13954e38796a2f9682aa52d5 ; patch SHA7e10e1bb33c1bd725774b4cf1b1de182a625f871a1d94ee38a6731939d79ec7b ;5blobs,1063sources import/config qualifiées et952pointeurs d'evidence HEAD séparés. Les dépendances image4.10.1/archive4.0.9 appartiennent uniquement à la copie privée ; aucun pubspec/lock/config host changé.
- `ledge-host-integration-01/integration.json` : inverse du patch récupère exactement tous les bytes antérieurs sur les30chemins ; foreign before horsscope inchangés, index encore vide. La résolution locality garde l'extraction étrangère `_resolveBorderFeatureWithCapture` et y ajoute son dispatch, sans l'absorber dans le blob committé.

Commandes supervisées et résultats exacts, cwd des packages de ces copies privées, sauf la dernière ligne exécutée dans le host :

| Cwd relatif / commande | Résultat |
| --- | --- |
| map_core : `dart test test/border -r expanded` |1071PASS, exit0,119.315s |
| map_core archive d'application : `dart test test/border/ledge_line_border_test.dart test/border/border_format_version_test.dart -r expanded` |42PASS, exit0,7.128s |
| map_core archive d'application : compilation kernel du barrel public |exit0,3.191s ; argv exact dans patch-application-kernel-02.json |
| map_core : `dart analyze` sur25chemins |exit0,2.357s ;5INFO strictement identiques à HEAD |
| map_authoring : `dart test test/domains/maps/border_ledge_line_actions_test.dart test/domains/maps/border_jump_behavior_actions_test.dart test/domains/maps/border_catalog_actions_test.dart test/domains/maps/border_actions_test.dart --reporter expanded` |19PASS,exit0,2.279s |
| map_authoring : `dart analyze lib/src/domains/maps/border_catalog_actions.dart test/domains/maps/border_ledge_line_actions_test.dart test/domains/maps/border_jump_behavior_actions_test.dart test/domains/maps/border_catalog_actions_test.dart` |No issues found,exit0,3.776s |
| map_authoring : `dart compile exe bin/pokemap_authoring.dart -o <QA>/ledge-authoring-private/authoring-cli` |exit0,22.208s |
| map_authoring : `dart test test/parity/full_authoring_parity_test.dart --reporter expanded` |20PASS,exit0,17.359s |
| map_authoring : `dart run tool/pmcp085_conformance.dart` |exit1,9.514s ;88resources/405actions/0missing/catalogComplete=true ; item/global transportCertificationComplete=false |
| tools/pokemap_mcp : `node --import tsx --test --test-concurrency=1 test/border_ledge_line_stdio.test.ts test/border_jump_behavior_stdio.test.ts` |2PASS,exit0,1.950s ; vrais MCPstdio/worker AOTJSONL |
| tools/pokemap_mcp : `npm run check` |exit0,1.002s |
| tools/pokemap_mcp : `npm run build` |exit0,1.027s avec pin final du test |
| host map_core : `dart test test/border/ledge_line_border_test.dart test/border/border_format_version_test.dart --reporter expanded` |42PASS,exit0,2.859s, après combinaison avec les hunks étrangers |

Les reçus contiennent les argv absolus, cwd, PID observés, hashes avant/après et logs. Tous les runs finaux ont pins stables, protectedUnchanged=true, confirmedSurvivors=[], signals=[] ; aucun GUI lancé. Les premiers échecs authoring provenaient d'un graphe image privé incompatible et de fixtures incomplètes ; seul actions-red-04 est le RED fonctionnel du descripteur. Deux échecs de parité sur des fichiers d'evidence absents dans l'archive ont été fermés par copie exacte HEAD ; aucun code produit modifié pour cela. PMCP-085 exit1 reste un résultat PARTIAL, même avec20tests de parité verts.

Parité : le test direct construit une mutation canonique de matérialisation et relit son JSON ; il n'applique pas cette mutation sur disque. Le MCP réel vérifie live describe, refus invaliddistance3 sans writes, draft, stagePNG, publication, fermeture/réouverture et query, avec bytes PNG conservés ; il ne matérialise pas de Border sur une carte. Le nouveau parcours Editor/Studio et le Player ne sont pas certifiés par ces tests. Les actions génériques du catalogue ne constituent pas une preuve UI spécifique ledgeLine.

| Passe | Verdict borné |
| --- | --- |
| Audit/Architecture root et ac12_native_mapping | Module entier, normale physique distincte du sens ; anciennes branches exhaustives Editor à adapter avant commit. |
| Implémentation ac12_native_mapping / root |25core et5authoring/MCP, sans nouveau modèle de zone ; séparation mechanical HEAD+ours/foreign conservée. |
| Tests ac12_native_mapping / root | RED de la variante et du descripteur ; suites Border1071, API19, parité20, transports2, host42 attestés. |
| Build/Validation root | Kernel core et worker AOT ; TypeScript check/build pins finaux ; aucune build GUI déduite. |
| Critique ac15_connection_review_fresh | Aucun P1/P2 sur core25 et authoring5, P2variante fermé ; limitation de replay et de mutation sans disque explicitement retenue. |

Auto-critique : le binder peut seulement accorder la permission après preuve du vrai owner et du contact complet dans B, puis admission stricte A/C. Le rendu structure n'offre pas de garantie Y-sort. Les normales N/E/W synthétiques ne prouvent pas leur présence dans Kanto. L'ouverture native, la modification/réouverture Studio, le saut animé, la collision réelle et le bon affichage devant/derrière restent requis. Aucun traitement IA, changement de règle de combat, suppression d'obstacle source ou réparation silencieuse d'un autre chantier n'est introduit ici.


Raccord obligatoire des consommateurs `map_editor` avant commit : ajout du type aux switches exhaustifs, alignement de tracé, règles natives, rôle, analyse q0 et labels. Le picker cardinal existant est réutilisé ; une orientation non définie reste « À définir » et la publication la refuse. Aucun asset directionnel manquant n'est inventé. Le helper AssetsStep accepte désormais sourceElementId nullable : seule sa signature est ajustée, son libellé indisponible reste identique, afin de compiler ce fichier déjà édité. Les autres erreurs HEAD de PaletteItem nullable ne sont pas réparées.

| Chemin Editor | Zone |
| --- | --- |
| `packages/map_editor/lib/src/features/border_map_editing/application/border_feature_authoring_controller.dart` | géométrie stroke/gridEdges |
| `packages/map_editor/lib/src/features/border_map_editing/application/border_tool_availability.dart` | template admis et alignement canonique |
| `packages/map_editor/lib/src/features/border_map_editing/presentation/border_layer_inspector_panel.dart` | libellé Rebord |
| `packages/map_editor/lib/src/features/border_studio/application/border_studio_draft_controller.dart` | règles natives fixes lors de création ou changement du template |
| `packages/map_editor/lib/src/features/border_studio/border_studio_workspace.dart` | analyse du module avec q0 seulement |
| `packages/map_editor/lib/src/features/border_studio/presentation/border_assets_step.dart` | picker cardinal existant ; helper source nullable garde son libellé existant |
| `packages/map_editor/lib/src/features/border_studio/presentation/border_roles_step.dart` | rôle unique structureLarge et libellé |
| `packages/map_editor/lib/src/features/border_studio/presentation/border_rules_step.dart` | profils fixes/variantes sans jitter, gaps ni rotation |
| `packages/map_editor/lib/src/features/border_studio/presentation/border_studio_presentation.dart` | labels, description et rôle natif requis |
| `packages/map_editor/lib/src/features/border_studio/presentation/border_type_step.dart` | picker Rebord et refus de primitives incompatibles |
| `packages/map_editor/test/border_map_editing/border_tool_availability_test.dart` | mise à jour du consommateur existant et de ses attentes |
| `packages/map_editor/test/border_studio/border_type_step_test.dart` | mise à jour du consommateur existant et de ses attentes |
| `packages/map_editor/test/border_studio/ledge_line_consumers_test.dart` | six tests directs du controller/providers/widgets sans notifier global |

Ledger `ledge-editor-consumers-ppuv5r1l/ledge-editor-consumers-final-ledger-01.json` SHA19c5e1d1b9f7dd760e0f75fd5463cdea62f65c065db669a2fa614b7c943ad755 ; patch SHA18209ed804d93e6526074e02cbd89387d8d95bc2e874103324ca8788e7223dd6 ;13blobs/10prod+3tests,373ajouts/33suppressions et1nouveau test. Root relit5431sources/pins et les13blobs, puis inverse l'application host : récupération exacte de chaque état antérieur.

Cwd de la copie privée `packages/map_editor` :

- `flutter test --no-pub test/border_studio/ledge_line_consumers_test.dart test/border_studio/border_type_step_test.dart test/border_map_editing/border_tool_availability_test.dart -r expanded` :13PASS/exit0/4.447s, six nouveaux directs et sept existants.
- `dart analyze` sur les13chemins ci-dessus : No issues found/exit0/9.872s ; argv complet dans editor-analyze-02.json.
- Les essais initiaux reproduisent les switches manquants ; le gros harness controller/notifier importe aussi les erreurs PaletteItem String? HEAD, demeure PARTIAL et son fichier a été remis byte-exact avant gel. Aucune assertion de RED fonctionnel des defaults ni de build complète Editor/Studio.

Les reçus finaux Editor attestent protectedUnchanged, pins stables et aucun survivant ; aucun GUI. Critique indépendante finale ac15_connection_review_fresh : aucun P1/P2 sur les13chemins, pins/patch/inverse/closure5431 et reçus exacts. La paire de tests widgets/controllers n'est pas un parcours natif du produit. Le picker de l'application `apps/avelune_studio` et la réouverture/modification réelle du projet restent à qualifier.

Git de cette tranche :43chemins code/tests + ce rapport existant. Le staging doit être constitué des seuls blobs privés gelés ; les hunks foreign dans les fichiers mixtes et les prototypes gameplay/runtime/source restent dans le worktree. Le reçu externe `ledge-host-integration-01/ledge-commit-01.json` porte SHA/parent,44blobs, index final et hashes/modes avant/après du host. Aucun push/rebase/PR ; aucune création de Markdown. AC15 reste DOING/PARTIAL, sans nouvelle famille ni Gate bêta. Le binder gameplay est une tranche suivante distincte, bloquée sur son P2 de coût avant intégration ; aucun saut jouable n'est revendiqué dans ce commit.
