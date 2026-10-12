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
