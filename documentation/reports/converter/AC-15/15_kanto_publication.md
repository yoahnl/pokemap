# AC-15 — Qualification Kanto et publication robuste

## Verdict et périmètre

État courant au 15 octobre 2026 : DOING / PARTIAL. Une publication normale réunit Route 9, Route 10 Nord, le Centre et la bibliothèque r9 approuvée : pinceau de chemin à seize règles et arbre entier. La livraison de 1 433 fichiers a maintenant été réellement ouverte, peinte, modifiée, enregistrée puis rouverte dans un nouveau processus Studio. Le Player natif a parcouru Route 9 depuis son spawn de prévisualisation (35,22), rejoint Route 10, franchi la porte du Centre et affiché le dialogue du PNJ. Les preuves moteur antérieures conservent la sauvegarde et la reprise dans un second processus. Les 11 événements adaptés sur 44 et les 33 quarantaines restent inchangés. Audibilité matérielle, physique du nouvel arbre, trajectoire du saut, profondeur complète et fin du parcours Player visible restent explicitement ouverts. Aucun départ Source/NewGame ni Kanto complet annoncé.

Les combats gardent les règles et le moteur natifs Avelune, selon l'instruction directe de Yoahn. Le convertisseur importe des données qualifiées ; il n'exécute aucun Ruby et ne porte pas le moteur Essentials. Zéro appel IA pour la conversion réelle ci-dessous. Les catalogues importés restent data-only tant qu'un déclencheur natif n'est pas qualifié.

La demande courante autorise tous les lots, les commits ciblés entre les lots et les pushes normaux directement sur main. Aucun rebase ni amend. Le kit demande un Evidence Pack ; ce document unique respecte ce livrable sous documentation/reports/converter. La règle directe interdisant les nouveaux commentaires de code prévaut sur l'instruction contraire de codex_rule.md. Aucun modèle cible nouveau, aucune mise à jour de roadmap FG, aucune extension du périmètre bêta.

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


## Complément AC-15 — admission gameplay des rebords natifs, 13 octobre 2026

Portée : permission de saut issue d'un Border `ledgeLine` V7 matérialisé et canonique, dans `map_gameplay` pur Dart. Cette tranche remplace le prototype à zones dans le gameplay. Elle ne livre pas encore l'animation Player, la réservation runtime d'arrivée, le composer Kanto, le picker de la nouvelle application Studio ni une qualification visuelle. Le but complet Kanto ouvrable, modifiable et jouable demeure inchangé ; AC-15 reste DOING/PARTIAL et FG-120 PARTIAL. La roadmap n'est pas modifiée ; frontières FG-014 et FG-067 conservées.

Audit initial : HEAD `a0dd22006751a71e9f1bf9da92967802b1a4f9bb`, branche main, index vide, 82 chemins dirty. Quatre fichiers de production gameplay et trois fichiers de prototype/test déjà présents appartenaient à cette conversion ; les autres chantiers mobile, Studio/3D et transports sont préservés. Le binder privé gel02 part de `1ddeb9ad6e07d7daa7a22f267c9ffe0f27b3628d` avec les 18 dépendances core exactes du commit a0dd220. Aucun patch 3D étranger n'entre dans cette tranche.

Le binder valide ProjectManifest et MapData avant d'admettre les références. Il re-résout le tracé ledgeLine et compare exactement la matérialisation finale complète, plutôt que de faire confiance au seul statut fresh d'un receipt recalculé. Une permission lie map, couche, feature, placement final, arête typée, carrier entier, normale physique, direction permise et fingerprints. Une collision propriétaire doit couvrir exactement toute la cellule B ; contact extérieur, trou, owner inconnu, ambiguïté ou deux owners du même carrier sont refusés. Les suppressions et keep-outs ne laissent aucune permission fantôme. Les maps de saut sont capturées en profondeur avant de garder les bindings statiques.

Le déplacement évalue A, B et C avec le décalage et les footprints réels du joueur. A et C ne bénéficient d'aucune exclusion. En B, seul le owner sélectionné est ignoré, uniquement dans son aire ; collisions de base, autres Borders, éléments, entités, eau et réservations restent actives. Un saut sélectionné puis bloqué ne retombe pas sur une marche ordinaire. La permission inversée ne change aucun placement visuel. Jumped porte un plan pur ; les effets d'arrivée sont différés au consommateur runtime, tandis que la marche conserve le helper canonique d'arrivée.

Deux P2 de la critique ont été fermés avant intégration :

- Matching quadratique : index local construit une fois à partir des endpoints/carriers typés ; un lookup par edge, sans parsing des clés opaques. Huit caractérisations sur dix arêtes, quatre directions et deux côtés passent avant/après. Ce résultat ne mesure pas la latence totale d'un grand monde.
- Collision superposée : un PNJ après un panneau au même C masquait le contact du panneau. Contrepreuve fonctionnelle 1PASS/1FAIL, Expected Blocked / Actual Jumped ; cache désormais immutable de toutes les entités bloquantes par cellule, avec query des contacts exacts. Présence et déplacement reconstruisent la liste, ignorer un ID laisse les autres bloqueurs actifs. Le cache d'interaction reste inchangé. Les régressions couvrent les deux ordres, offset -20px et marche ordinaire.

Inventaire complet des dix fichiers de cette tranche ; le diff Git est l'autorité des zones précises :

| Chemin | Zones et résultat |
| --- | --- |
| `packages/map_gameplay/lib/map_gameplay.dart` | exports binding/plan/Jumped/helper arrivée ; API publique pure |
| `packages/map_gameplay/lib/src/border_directed_jump_binding.dart` | nouveau binder, replay canonique exact, index typé et union couvrant B |
| `packages/map_gameplay/lib/src/directed_jump_plan.dart` | nouveau plan immuable lié au binding Border, positions A/B/C et présentation |
| `packages/map_gameplay/lib/src/gameplay_step.dart` | évaluation prioritaire du saut, admission stricte A/B/C et extraction resolveGameplayArrival |
| `packages/map_gameplay/lib/src/gameplay_step_result.dart` | résultat Jumped distinct des conséquences d'arrivée |
| `packages/map_gameplay/lib/src/gameplay_world_state.dart` | capture map, bindings statiques partagés, query owner-exclusion et cache complet des entités |
| `packages/map_gameplay/test/border_directed_jump_binding_test.dart` | nouveaux cas canonicalité, quatre normales, overrides, ambiguïté, références et aliasing |
| `packages/map_gameplay/test/gameplay_arrival_test.dart` | nouveaux tests du helper d'arrivée : warp/connection/hazard/event et marche |
| `packages/map_gameplay/test/gameplay_directed_jump_test.dart` | nouvelle matrice de déplacement, garde-fous collisions/eau/bounds/offsets/réservations et overlap |
| `packages/map_gameplay/test/support/border_jump_fixture.dart` | nouveau fixture de vrais Borders natifs synthétiques, sans média source ni production dépendant des tests |
| `documentation/reports/converter/AC-15/15_kanto_publication.md` | ce complément consolidé, aucune nouvelle documentation |

Nettoyage possédé hors diff commit : les cinq lignes non commitées du prototype dans `test/border_collision_ownership_test.dart` qui appelaient ignoredStaticCell ont été supprimées après un échec de compilation du run host. Le fichier est maintenant byte-exact HEAD, sans perte des onze tests d'ownership strict. Le reçu `binder-host-integration-01/obsolete-test-cleanup-01.json` atteste avant/après ; aucun fichier étranger n'a été remplacé par ce nettoyage.

Preuves gelées sous `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-jump-gameplay-private-h_hwe48d` : pins02 SHA `9bb6a281161aca363965d10e68478c742c39ee1e83ba9997f6b7bada06bd7272`, patch02 SHA `32888e23afb5437130cd4118333f382709163e31a52c5a4a3b99739ad2852c2b`, ledger02 SHA `8ebb37b2d8d7edf57f5da2eb829f003664262b0c1591b2f398c1cc40577266ce`. Dix blobs propres, 18 core, fermeture production 555 fichiers SHA `9d3487d249bd180fb3eb05dade7d7d70f2a68ce0ce20d4266a09dc0c078b957e`. Root et reviewer recomputent pins, reçus, logs et fermeture ; l'inversion du patch restitue les quatre baselines et retire exactement les six nouveaux fichiers.

Depuis `packages/map_gameplay` de la copie privée, puis du host pour les deux dernières lignes :

| Commande / reçu | Résultat exact |
| --- | --- |
| `dart test test/border_directed_jump_binding_test.dart test/gameplay_directed_jump_test.dart test/gameplay_arrival_test.dart test/border_collision_ownership_test.dart test/npc_map_presence_predicate_test.dart test/npc_default_collision_footprint_test.dart test/gameplay_world_state_entity_move_test.dart test/gameplay_world_state_collision_storage_characterization_test.dart test/runtime_movement_collision_regression_test.dart --concurrency=1 --reporter expanded` | gel02 :109PASS, exit0,4.601s ;82matrice+27régressions |
| `dart analyze` | gel02 :exit0,1.912s ;0erreur/0warning/1INFO unnecessary_library_name préexistante |
| `dart compile kernel tool/qa_border_jump_kernel.dart -o <QA>/border-jump-kernel-02.dill` puis `dart <QA>/border-jump-kernel-02.dill` | compilation exit0/3.128s ; quatre traces cardinales synthétiques exit0/0.749s ; meilleur build alternatif du package pur, pas une build GUI |
| même commande ciblée de neuf suites sur le host, reçu `binder-host-integration-01/host-focused-02.json` |109PASS, exit0,4.290s ; test ownership byte-exact HEAD |
| `dart analyze lib/map_gameplay.dart lib/src/border_directed_jump_binding.dart lib/src/directed_jump_plan.dart lib/src/gameplay_step.dart lib/src/gameplay_step_result.dart lib/src/gameplay_world_state.dart test/border_directed_jump_binding_test.dart test/gameplay_arrival_test.dart test/gameplay_directed_jump_test.dart test/support/border_jump_fixture.dart` sur host |exit0,2.783s ; unique INFO unnecessary_library_name, aucune erreur/warning |

La suite complète historique reste 827PASS/2FAIL en67.913s, antérieure aux derniers correctifs et PARTIAL. Le benchmark refuse l'archive sans racine Git (exit64) ; aucun .git factice créé. L'autre échec `spatial_map_navigation_test.dart:112`, Expected StateError / Actual SpatialMovementController, est reproduit frais par root sur archive pure HEAD a0dd220 puis avec le candidat exact : exit1/6.138s et exit1/1.605s, logs byte-identiques SHA `d8160587a19b61a15881af462c000c0f8723ae3290cbb2456e60ef877468d463`. Ce diagnostic est distinct du saut ; aucun correctif 3D/spatial n'est ajouté. Premier run host98PASS/1loadingFAIL est conservé comme preuve du test prototype obsolète ; le rerun final109PASS ne maquille pas ce premier résultat. Aucun full GREEN revendiqué.

Tous les runs finaux ont pins avant/après stables, protectedUnchanged=true, aucun timeout/signal/survivant confirmé. Chaque runner et ses descendants ont été observés et aucune application GUI n'a été ouverte. Les opérations Git autorisées restent le seul commit local de ces dix blobs et du rapport ; aucun push/rebase/PR. Le reçu externe `binder-host-integration-01/binder-commit-01.json` porte parent, SHA, onze blobs exacts, index final et conservation des fichiers host avant/après commit.

Parité : le binder ne crée pas une nouvelle action d'auteur ou un transport. Il consomme les contrats Border V7 déjà publiables par l'API et le MCP du commit a0dd220 ; aucune modification `map_authoring`/serveur dans cette tranche. La preuve précédente publish/reopen ne qualifie toujours pas la matérialisation map via MCP, ni le picker Studio moderne, ni un déplacement Player. PMCP-085 global demeure PARTIAL. Ces bornes restent requises lors du composer final et de la qualification réelle.

| Passe | Verdict borné |
| --- | --- |
| Audit/Architecture root et ac12_semantics | owner matériel réel, replay complet, empreintes A/B/C et snapshot canonique obligatoires |
| Implémentation ac12_semantics | dix blobs gel02, deux P2 fermés, aucun code zone ajouté |
| Tests ac12_semantics / root |109privés et109host ; contrepreuve overlap réelle ; spatial baseline isolée fraîche identique |
| Build/Validation ac12_semantics / root | kernel pur quatre traces et analyse package/host ; pas de build Flutter/GUI attribuée |
| Critique indépendante ac15_connection_review_fresh | aucun P1/P2 dans gel02 ; patch/inverse/pins/closure et reçus vérifiés, intégration host vérifiée ensuite par root |

Auto-critique : la permission pure ne prouve ni disponibilité des trois médias source, ni passage animé, ni réservation NPC runtime, ni son/image/profondeur de Route9. Les autres prototypes zone restent non committés et doivent être remplacés par les consommateurs définitifs. Les 119 décisions source statiques ne sont pas 119 parcours Player. Prochaine tranche distincte : port runtime et réception réservée, composition native des trois modules source avec Z1 consommé précisément et tous les masques conservés, puis parcours réel Studio/Player fermé après usage. AC15 reste DOING/PARTIAL, Gate bêta inchangée.


## Complément AC-15 — animation Player des rebords natifs, 13 octobre 2026

Portée : consommation runtime des plans Border du commit gameplay `171a55cfcef27ec51e8632d5dc8362f8c2ef9f1f`. Le but complet Kanto éditable et jouable reste requis ; AC-15 reste DOING/PARTIAL, FG-120 PARTIAL, roadmap et Gate bêta inchangées. Ce commit ne qualifie ni le composer source, ni l’édition Studio moderne, ni un parcours Route 9 réel.

Audit initial root : branche main, HEAD171a55cfc, index vide,74chemins dirty. Les quatre chemins runtime étaient des prototypes de ce chantier ; aucun hunk étranger dans ces quatre fichiers. Intégration conditionnée aux hashes attendus des prototypes, puis copie des quatre blobs gelés. Le reçu `runtime-host-integration-01/integration-01.json` atteste71autres chemins surveillés, hashes/modes inchangés. Les travaux mobile, Studio/3D, render3D, transports et source restent hors commit.

| Chemin | Zones modifiées et effet |
| --- | --- |
| `packages/map_runtime/lib/src/presentation/flame/player_component.dart` | start/cancelDirectedJump, update, élévation du sprite enfant ; interpolation A→C au sol et footPoint/depth stables, callback unique |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | pending lié à activation/map/positions ; verrous input/checkpoint, annulation lifecycle, conséquences d’arrivée différées ; réservation immutable de l’union des rectangles mouvement/contact de C avant exception activeFollowLeader dans query et enumeration NPC |
| `packages/map_runtime/test/player_directed_jump_component_test.dart` | nouvelle fixture de Border natif ; durée500ms/pic24px, affichage à échelle, dt long/fractionné, annulation et callback unique |
| `packages/map_runtime/test/playable_map_game_directed_jump_test.dart` | nouveau binder Border, conséquences uniquement C, verrous clavier/touch/menu/save/load, callback périmé, réservation C et contact adjacent, régression de l’exception leader suivi |
| `documentation/reports/converter/AC-15/15_kanto_publication.md` | ce complément consolidé ; aucun nouveau Markdown |

Le RED réservation NPC est fonctionnel : une requête publique activeFollowLeader accepte indûment une route vers C et le contact adjacent ; enumeration omet la réservation. Reçu privé `npc-landing-red-02.json` :6PASS/3FAIL,6.967s. Le correctif capture les cellules du footprint d’arrivée une fois, les conserve dans Set.unmodifiable et les consulte avant l’exception du leader suivi dans les deux chemins. Les ticks NPC restent gelés pendant le saut : le RED n’est pas une preuve de déplacement physique d’un NPC en C.

Gel privé `border-jump-runtime-private-1h92fycg` : ledger01 SHA `dcc746fd78a122b747646f47ba6c4b4ca2093548fcb6cf41893c4da11cbfe481`, patch01 SHA `bb4f1f5fcc5cfdd4e0856b186657053b7871dfd7119709d11ba0f3fa590a3fd3`, quatre blobs et18core/10gameplay exacts. La base runtime a0dd220 est byte-identique à171a55cfc. Reviewer indépendant ac15_connection_review_fresh vérifie6059sources,14deltas limités aux10gameplay dépendants et4runtime, inverse du patch, reçus/logs/pins et kernel. Verdict : aucunP1/P2 dans cette borne. Complément `runtime-completion-evidence-01.json` SHA `0d2bea8f6092068af10c0a673351af4c6d8f053f82fa049d614ebd866c94fc37` pour6NPC et hygiene.

Vérification fraîche root après intégration des quatre blobs :

| Cwd / commande | Résultat exact |
| --- | --- |
| `packages/map_runtime` : `flutter test --no-pub --concurrency=1 test/player_directed_jump_component_test.dart test/playable_map_game_directed_jump_test.dart test/playable_map_game_input_test.dart test/phase_a_golden_battle_slice_smoke_test.dart test/scripted_npc_runtime_interaction_test.dart test/scripted_npc_anchor_passability_test.dart --reporter expanded` |83PASS,exit0,12.468s ; host-focused-02.json/logSHA005fc819717677ab61cfd9c5d4b7ef56e92064178551a53346c92cc04e39d0e2 |
| `examples/playable_runtime_host` : `flutter test --no-pub --concurrency=1 test/phase_a_golden_slice_launch_test.dart --reporter expanded` |14PASS,exit0,10.847s ; host-golden-01.json |
| `packages/map_runtime` : `flutter analyze --no-pub --no-fatal-infos lib/src/presentation/flame/playable_map_game.dart lib/src/presentation/flame/player_component.dart test/player_directed_jump_component_test.dart test/playable_map_game_directed_jump_test.dart` |exit0,7.497s ;0erreur/0warning/4INFO strictement préexistantes, host-analyze-01.json |
| Copie privée `packages/map_runtime` : `flutter build bundle --debug --no-pub --target=<QA>/border-jump-runtime-private-1h92fycg/runtime_jump_contract_kernel.dart` |exit0,9.533s ; barrel runtime complet et contrat saut/checkpoint compilés, kernel SHAa60827e76437d5a70bf4a42fe5179bfd8687beb3aa137e98933af03cd9a1c7bf ; meilleur build alternatif de package, pas une build macOS de Studio |

Premier batch root conservé :77PASS/1loadingFAIL,12.492s, car la commande root contenait un nom de suite NPC inexistant. Le nom a été corrigé d’après les suites réelles et le rerun83PASS ci-dessus inclut leurs6tests. Aucun correctif de production associé à cet incident. Les incidents privés initiaux de fixture et de timeout concurrent sont conservés ; runs finaux isolés qualifiés. Aucune suite runtime complète revendiquée.

Tous les runs retenus utilisent run_owned.py : pins stables,protectedUnchanged=true,aucun timeout/signal/descendant survivant. Aucun GUI ouvert ; seuls les descendants observés des propres runners sont susceptibles de cleanup. Aucun ancien PID touché.

| Passe | Verdict borné |
| --- | --- |
| Audit/Architecture root et ac12_native_mapping | consommation du binder natif ; pied au sol, arrivée différée et réservée |
| Implémentation ac12_native_mapping | quatre blobs gelés, pas de contrat zone consommé |
| Tests ac12_native_mapping / root |18sauts+59input/golden+6NPC privés, puis83host frais ;14host golden frais séparés |
| Build/Validation ac12_native_mapping / root | kernel runtime privé exact, analyse host quatreINFO baseline ;97tests ciblés host |
| Critique indépendante ac15_connection_review_fresh | aucunP1/P2 ; gel/inverse/closure/reçus vérifiés ; limites réelles conservées |

Parité : cette consommation runtime n’ajoute aucune action d’auteur ni transport. Les contrats Border V7 restent ceux déjà exposés au commit a0dd220 ; publication/réouverture MCP précédente n’atteste toujours pas une matérialisation de carte MCP ni l’UX Studio moderne. PMCP-085 global restePARTIAL. La recherche configurée flame_docs n’a renvoyé aucun résultat ; version installée2.0.0-dev.1 et patterns existants utilisés.

Auto-critique : fixtures natives synthétiques orientées sud, aucune preuve de trajet source réel, de visuel Route9 ou de modification/réouverture dans Studio. Les hazards restent typés sans dispatch dégâts dans ce scope. La réservation NPC est prouvée par refus de planification et enumeration, pas par contact physique pendant l’animation. Le commit local ne contient que ces quatre blobs et ce rapport ; index vide et conservation du worktree doivent être vérifiés dans le reçu `runtime-host-integration-01/runtime-commit-01.json`. Aucunpush/rebase/PR. Tranches suivantes : composer source fidèle aux trois variantes et119unitEdges, édition/republication des rebords avec régénération explicite, puis parcours réel fermé après usage.


## Complément AC-15 — édition Studio des rebords natifs et régénération explicite, 13 octobre 2026

Portée : rendre éditable dans Studio un Rebord 2D `ledgeLine` existant. Le nom et le côté du saut existant sont modifiables ; toutes les primitives et frames source, leurs IDs, ancres, orientations, poids, transforms et métriques restent conservés. Un rebord sans saut reste sans saut. La publication de la ressource ne modifie aucune carte ; une préparation puis une application explicite régénèrent le tracé complet avec ses overrides et keep-outs. AC-15 reste DOING/PARTIAL, FG-120 PARTIAL, Gate bêta et roadmap inchangées. Le but complet Kanto demeure requis.

Audit root : HEAD `73a70d9fab89b1e85ce0494a6b532cfa0a824b69`, main, index vide. La préparation d’intégration constate72chemins dirty, dont quatre fichiers Studio mixtes étrangers. Deux nouveaux scripts étrangers sont apparus depuis le relevé70 du commit runtime ; ils ne sont pas absorbés. Le dialogue générique attendait seulement cap/straight/corner et pouvait enregistrer un brouillon en perdant les variantes natives ; la régénération existante était limitée à3D. Base privée171a55cfc : les11fichiers de cette tranche sont comparés au HEAD73a et leurs baselines sont exactes.

| Chemin | Zones et effet |
| --- | --- |
| `apps/avelune_studio/lib/features/resources/domain/resource_port.dart` | BorderCreationRequest : côté existant et record attendu typés |
| `apps/avelune_studio/lib/features/resources/data/border_resource_sources.dart` | branche dédiée native ; lecture de chaque frame/tileset original, chemins et symlinks contrôlés, compiler avec ancre originale, métriques identiques obligatoires avant mutation |
| `apps/avelune_studio/lib/features/resources/data/local_border_resource_adapter.dart` | contrôle du record avant préparation, refus d’ajout implicite de saut, seuls side/name changés, payload et publication canoniques conservés |
| `apps/avelune_studio/lib/features/map_workspace/application/map_border_editing_commands.dart` | previewExisting2D résout la feature entière puis Apply lié à identité carte/projet ; record existant recherché même déprécié, dimension/géométrie/scope vérifiés |
| `apps/avelune_studio/lib/presentation/features/map_workspace/map_border_tool_panel.dart` | diagnostic et préparation2D, aperçu/cancel/Apply explicites ; publication seule sans mutation du document |
| `apps/avelune_studio/lib/presentation/features/resources/border_creation_dialog.dart` | mode existant native2D, dirty/completeness dédiés, record capturé, side typé, reprise après brouillon réellement sauvegardé et reçu partiel |
| `apps/avelune_studio/lib/presentation/features/resources/native_ledge_panel.dart` | nouveau panneau DS, tous les modules source en lecture seule, côté affiché seulement si jumpBehavior existe |
| `apps/avelune_studio/test/resource_io/ledge_border_metadata_test.dart` | huit tests fichiers : metadata/publication/reopen, pixels et cartes identiques, stale refusé, sans-saut conservé, toutes les frames animées conservées |
| `apps/avelune_studio/test/application/native_ledge_regeneration_test.dart` | trois tests : intent/overrides/keep-outs, undo/redo/save/reopen/binder, concurrence, record existant déprécié republié puis régénéré |
| `apps/avelune_studio/test/presentation/native_ledge_regeneration_panel_test.dart` | preview/cancel/Apply et undo explicites sur vraie fixture fichiers |
| `apps/avelune_studio/test/presentation/native_ledge_editor_test.dart` | neuf tests : publication native et aperçus, sources complètes, frames, dirty, sans-saut, indisponibilité, stale et reprise du brouillon partiel |
| `documentation/reports/converter/AC-15/15_kanto_publication.md` | ce seul complément consolidé, aucun nouveau Markdown |

RED fonctionnels conservés sous `ledge-studio-private-jfl3u2ur` : métadonnées5FAIL avant conservation native, régénération2FAIL avant support2D, panneau1FAIL sans bouton, UI2FAIL sans mode natif. La critique trouve ensuiteP2 : le helper publishedLines exclut les ressources dépréciées pour les nouveaux tracés, et bloquait à tort une feature existante. Premier run deprecated-red01 échoue au setup de confirmation d’une mutation destructive, pas au comportement testé ; la fixture représente ensuite un record existant légalement déprécié. `deprecated-ledge-red-02` :0PASS/1FAIL fonctionnel,4.847s, erreur « Cette bordure publiée n’est plus disponible ». Lookup direct du record + contrôles publication/dimension/stroke/scope corrigent le cas ; publishedLines reste filtré pour les nouveaux traits.

Gel final privé11blobs : `joint-final-pins-02.json` SHA68912b49247ad91c280f92590a30b507dedb31e6bb991719052edb145d202cd2 ; ledger privé final02 SHA584c0033de427f7a5d889af573aa7383a46d98ec5731171a284309fd1702c9cf. Rootpins02 huit blobs, UIledger01 trois blobs SHA4d85970888173af49799133737b04d334c33298a4dd74d0920c6e5d2aa81fdc3. La suitejointe03 remplace le checkpoint02 qui capturait huit pins :03 capture les onze pins exacts avant/après. Sources/artefacts/logs/hashes relus par root et critique fraîche.

Intégration host : `.final` privé pour le staging ciblé, `.merged` dans le worktree pour conserver les contrôles3D étrangers. Les conflits de champs sont résolus par ajout des deux champs ; la préparation générique après la branche native reste byte-identique ; la requête générique du dialogue reste byte-identique hormis expectedRecord. Les états/contrôles/dirty/completeness et paramètres de contour/sol étrangers restent présents et consommés. L’inverse3way automatique n’est pas exact sur trois mélanges ; le patch propre `.before→.merged` revu, appliqué en inverse sur onze blobs privés, restaure exactement les onze fichiers avant intégration, y compris retrait des nouveaux fichiers. Reçu `inverse-own-patch-proof-01.json`, patchSHA30a8a18d0fa1565fec28d426a4099ac51b12dc97ec30938b6afac6d1e922832b. `host-apply-proof-01` :68autres fichiers surveillés, hashes/modes inchangés, index toujours vide après copie.

Vérifications fraîches (cwd `apps/avelune_studio`, copie privée ou host explicitement indiqué) :

| Commande / reçu | Résultat |
| --- | --- |
| `flutter test --no-pub --concurrency=1 test/resource_io/ledge_border_metadata_test.dart test/application/native_ledge_regeneration_test.dart test/presentation/native_ledge_regeneration_panel_test.dart test/presentation/native_ledge_editor_test.dart --reporter expanded` ; `native-joint-final-03.json` | copie privée,21PASS,exit0,14.438s |
| `flutter analyze --no-pub lib/features/resources/domain/resource_port.dart lib/features/resources/data/border_resource_sources.dart lib/features/resources/data/local_border_resource_adapter.dart lib/features/map_workspace/application/map_border_editing_commands.dart lib/presentation/features/map_workspace/map_border_tool_panel.dart test/resource_io/ledge_border_metadata_test.dart test/application/native_ledge_regeneration_test.dart test/presentation/native_ledge_regeneration_panel_test.dart lib/presentation/features/resources/border_creation_dialog.dart lib/presentation/features/resources/native_ledge_panel.dart test/presentation/native_ledge_editor_test.dart` ; `native-joint-analyze-02.json` | copie privée,11fichiers,No issues found,exit0,7.486s |
| `flutter build bundle --debug --no-pub --target=/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/ledge-studio-private-jfl3u2ur/native_ledge_joint_kernel.dart` ; `native-joint-kernel-02.json` | copie privée,kernel joint UI/panel/commands compilé,exit0,18.961s |
| `flutter test --no-pub --concurrency=1 test/resource_io/ledge_border_metadata_test.dart test/application/native_ledge_regeneration_test.dart test/presentation/native_ledge_regeneration_panel_test.dart test/presentation/native_ledge_editor_test.dart test/presentation/border_pattern_panel_test.dart test/presentation/border_creation_journey_test.dart test/presentation/border_creation_failure_journey_test.dart test/presentation/spatial_border_editor_test.dart test/application/spatial_border_commands_test.dart test/resource_io/border_jump_behavior_preservation_test.dart test/resource_io/border_publication_retry_test.dart --reporter expanded` ; `host-integration-02/host-focused-01.json` | host fusionné,48PASS/1SKIP GPU opt-in,exit0,53.296s |
| `flutter analyze --no-pub lib/features/resources/domain/resource_port.dart lib/features/resources/data/border_resource_sources.dart lib/features/resources/data/local_border_resource_adapter.dart lib/features/map_workspace/application/map_border_editing_commands.dart lib/presentation/features/map_workspace/map_border_tool_panel.dart test/resource_io/ledge_border_metadata_test.dart test/application/native_ledge_regeneration_test.dart test/presentation/native_ledge_regeneration_panel_test.dart lib/presentation/features/resources/border_creation_dialog.dart lib/presentation/features/resources/native_ledge_panel.dart test/presentation/native_ledge_editor_test.dart` ; `host-integration-02/host-analyze-01.json` | host fusionné,11fichiers,No issues found,exit0,9.09s |

Kernel joint privé :135854256bytes,SHA5892633e6e45cf69a7cc329f4ff718e507c97f830af16dc353396cb3e6a5464e. Meilleur build alternatif du graphe édité ; aucune build desktop Studio complète ni fenêtre réelle attribuée à cette tranche. Régression UI privée distincte16PASS/1SKIP GPU35.860s ; la suitehost48PASS ci-dessus est la preuve fraîche sur mélange, sans certifier tout le chantier3D. Tous les runs retenus sont supervisés par run_owned.py : pins stables,protectedUnchanged=true,aucun timeout/signal/survivant. Aucun GUI ouvert, aucun ancien PID touché.

| Passe | Verdict borné |
| --- | --- |
| Audit/Architecture root | mode natif dédié et publication sans perte ; régénération explicite conservant intent |
| Implémentation root + ac12_native_mapping | huit blobs root + troisUI, contrats canoniques existants, aucun nouveau modèle ni action |
| Tests root + ac12_native_mapping |21privés frais et48host frais/1SKIP, REDP2 réel puis GREEN ; variantes/frames/intent/concurrence/reopen couverts |
| Build/Validation root + ac12_native_mapping | analyse11privés ethost sans problème, kernel joint privé, régression générique bornée |
| Critique indépendante ac15_connection_review_fresh | aucunP1/P2 dans11privés puis quatre deltas mixtes ; conservation étrangère vérifiée, aucune qualification GUI/global attribuée |

Parité : ResourcePort reste un adapter interne qui emploie border.blueprint.draft.upsert/publish avec expectedRevision canonique ; jumpBehavior est le contrat publicV7 déjà exposé. Le preview conserve les opérations map_core existantes et la sauvegarde canonique. Aucun nouveau transport/action dans cette tranche. La preuve MCP précédente draft/publish/reopen n’incluait pas la matérialisationmap ; cette admission appliquée et les remplacements s’effectuent dans la tranche composer suivante. PMCP-085 global demeurePARTIAL. Aucune persistance JSON brute invoquée comme preuve sémantique.

Auto-critique : les pixels d’aperçu du widget sont représentés par un thumbnail de test recevant les éléments exacts, pas par une fenêtre Studio. Le reçu partiel qualifié correspond à un brouillon effectivement sauvegardé avec incident injecté ensuite, pas à tous les incidents de publication. Le panel recalcule une résolution complète pour son diagnostic stale ; coût non mesuré, sansP2 établi. Pas de suite Studio complète, de testGPU, de création nouvelle native, de remplacement/orientation manuelle, ni de parcoursRoute9/Kanto réel. La source32² et ses119rebords sont encore dans la qualification composer séparée. Prochaine tranche : seam replacement canonique + vraie sortie native du pair98/100, workflow/budgets visibles, puis parcours Studio/Player réellement ouvert, modifié, sauvegardé/réouvert et fermé après usage.

Clôture Git attendue dans `host-integration-02/studio-commit-01.json` : douze blobs (onze privés + ce rapport), parent73a70d9fa, index final vide, worktree étranger conservé. Aucunpush/rebase/PR. Le ticket AC15 existant conserve DOING/PARTIAL dans son grand domaine Post Bêta ; aucune famille ou ticket de contenu créé.


## Complément AC-15 — conversion automatique des rebords source et publication, 13 octobre 2026

Portée : convertir les rebords source qualifiés en Borders natifs `ledgeLine`, conserver leurs variantes exactes et publier leurs snapshots avec des témoins distincts du catalogue d’assets. Le raccord workflow et l’interface constituent la tranche suivante. AC-15 reste DOING/PARTIAL et FG-120 PARTIAL ; aucun changement de roadmap ou de Gate bêta. Les combats restent ceux d’Avelune et aucun Ruby source ni appel IA n’est exécuté.

Audit initial : main, HEAD `e02f2559db53ea909c06e786a4fa4c95e79df1bc`, index vide, 72 chemins dirty. Les cinq contrats converter_core nécessaires étaient déjà des prototypes de ce chantier. Le writer confondait aussi les chemins des PNG Border avec les IDs du catalogue d’assets : la première vérification de publication refusait systématiquement ces sorties. Le fichier authoring contient une autre implémentation non committée du même remplacement, avec des actions de slots et du support 3D étrangers : son contenu host reste byte-exact. Le staging utilise uniquement le blob 2D canonique privé. L’ancien domaine gameplay_zone du writer est conservé dans le host comme unique ligne supplémentaire, absent du blob propre committé.

L’oracle fermé reprend les sections Ruby inertes 042 Game_Map:222–247/302–316, 044 Game_Character:237–257/767–801 et 046 Game_Player:141–153. Admission de la sortie et de l’entrée inverse, terrain effectif, puis réception d0 ; les passages ordinaires continuent de refuser les ledges. Profil non attesté, pont actif, joueur non 1×1, orientation inconnue ou empreinte événementielle ne donnent aucune permission implicite. Les trois carriers source sud 1194/1212/1198 conservent les pixels complets 32×32, creux alpha, ancre (16,31), orientation q0, sans flip ni rotation. Seules les cellules Z1 des rebords admis sont consommées ; Z0, Z2, autres Z1, placements et masques génériques restent conservés.

Inventaire des 18 chemins code/tests ; le diff Git reste l’autorité des zones exactes :

| Chemin | Zones et effet |
| --- | --- |
| `packages/avelune_converter_core/lib/avelune_converter_core.dart` | export du contrat pur directed jumps |
| `packages/avelune_converter_core/lib/src/source_semantics.dart` | permission ledge explicite dans le seul trajet dédié ; marche inchangée |
| `packages/avelune_converter_core/lib/src/source_directed_jump_semantics.dart` | nouveau contrat, traces typées terrain/passages et résolution A/B/C fermée |
| `packages/avelune_converter_core/test/source_directed_jump_semantics_test.dart` | contrats, géométrie, contextes, ordres et profils |
| `packages/avelune_converter_core/test/source_directed_jump_resolver_test.dart` | refus terrain/passage/landing et non-régression de la marche |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | export composer et erreur typée |
| `packages/avelune_converter_adapters/lib/src/source_directed_jump_study_composer.dart` | nouveau composer, trois modules source, unitEdges, replacements exacts et preuve par cellule |
| `packages/avelune_converter_adapters/lib/src/source_semantic_study_composer.dart` | appel du composer et consommation précise Z1 ; masques conservés |
| `packages/avelune_converter_adapters/lib/src/source_event_study_composer.dart` | ordre des sauvegardes conservant les Borders ajoutés avant les événements |
| `packages/avelune_converter_adapters/lib/src/native_project_writer.dart` | domaine border_layer et reçu immutable snapshots path→longueur/SHA brut distinct des assets |
| `packages/avelune_converter_adapters/lib/src/native_project_publication.dart` | journal v2 strict, seal et vérification snapshots sur les quatre voies publication/reprise |
| `packages/avelune_converter_adapters/test/source_directed_jump_study_composer_test.dart` | pixels/alpha/variants, contexte, orientation et exclusions |
| `packages/avelune_converter_adapters/test/source_directed_jump_writer_test.dart` | writer canonique, publication, reprise préparée/publiée et altérations PNG/reçu/journal |
| `packages/map_authoring/lib/src/domains/maps/border_actions.dart` | action feature_set_replacement 2D stricte ; slot résolu et primitive publiable obligatoires |
| `packages/map_authoring/test/domains/maps/border_replacement_action_test.dart` | API directe, préservation d’intent et refus |
| `packages/map_authoring/test/tooling/jsonl_border_replacement_flow_test.dart` | transport CLI/JSONL et réouverture |
| `packages/map_authoring/test/support/border_replacement_fixture.dart` | fixture originale de rebord publié, sans média de production |
| `tools/pokemap_mcp/test/border_replacement_stdio.test.ts` | action découverte, refus, remplacement, republication r2, materialize resolver3 et reopen |
| `documentation/reports/converter/AC-15/15_kanto_publication.md` | ce seul rapport consolidé |

Le P2 publication a un RED fonctionnel : 0PASS/3FAIL, exit1,17.063s, refus native.changed puis absence de seal/reprise prepared. `assetHashes` reste ID-only ; `borderSnapshotFiles` exige l’ensemble exact des références du manifeste, des chemins directs bornés, une identité physique stable avant/après lecture, la longueur exacte et le SHA brut. Ces gardes couvrent avant seal, après intention durable, reprise prepared et reprise published. Le journal v1 est refusé ; aucune migration, faux record de catalogue, hausse de quota ou suppression de vérification.

Preuves privées gel03/04 dans `<QA>/source-border-conversion-private-b57zk3zh`, avec QA=`/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5`. Pins finaux04 SHA `f8fdd9a5288694111fa6af2ed8d96952ccbb5c57c78d08681ea06aadae840918`, ledger06 SHA `278a3639be5689419a561f7f1e85fb5532c6b0daf3b100a7fc89615d8d6ee6f8`, patch Source13 SHA `255335d1eac26f02bb88d47e2ace153076537a3b890838b5908a53855d4f806e`. Root relit les pins, patches, reçus, logs et leurs invariants ; reviewer vérifie fermeture1998, 13blobs et15dépendances, application13/13 sur a0dd220 et e02f2559. Les dix overlays gameplay sont déjà committés ; seuls les cinq converter_core sont ajoutés à cette tranche.

| Cwd / commande | Résultat exact |
| --- | --- |
| converter_core privé : `dart test test/source_directed_jump_semantics_test.dart test/source_directed_jump_resolver_test.dart test/source_semantics_test.dart --concurrency=1 --reporter expanded` | root51PASS,exit0,5.207s ; analyse des cinq chemins No issues,1.021s |
| adapters privé : `dart test test/source_directed_jump_study_composer_test.dart test/source_directed_jump_writer_test.dart test/native_project_publication_test.dart --concurrency=1 --reporter expanded` |35PASS,exit0,84.305s ; seule correction d’accolades du test ensuite |
| adapters privé : `dart test test/source_directed_jump_writer_test.dart --name 'Border.*(publication\|prepared\|snapshot)' --concurrency=1 --reporter expanded` |3PASS sur bytes finaux,exit0,14.164s ; analyse complète No issues,3.599s |
| adapters host : même commande combinée de trois suites | root35PASS,exit0,79.697s ; `root-host-integration-03/host-focused-01.json`, logSHAb6a34290769c0e604c296054ac58a08adbfcf2f66fc296251356a42943bec2b2 |
| adapters host : `dart analyze` | No issues found,exit0,4.922s ; mêmes production pins que le run35 |
| authoring privé : `dart test test/domains/maps/border_replacement_action_test.dart test/tooling/jsonl_border_replacement_flow_test.dart --concurrency=1 --reporter expanded` |7PASS,exit0,2.876s ; analyse des quatre chemins No issues,2.272s |
| MCP privé : `npm run build`, `npm run check`, puis `node --import tsx --test test/border_replacement_stdio.test.ts` |build exit0/1.301s,check exit0/0.999s,stdio1PASS/8.845s ; RED frais 7!==3,exit1/9.144s |
| probe QA Dart après ce dernier stdio : `seed-border-replacement-fixture-resolver3.dart verify <fixture> <result>` |exit0/8.370s ; replay matériel canonique exact, catalogue7/résolveur3/révision2, binding1 et Jumped (3,2)→(3,3)→(3,4), owner/fingerprints exacts |
| adapters privé : `dart compile kernel --packages=<package_config> <QA>/real-border-conversion-probe-01.dart -o <QA>/source-border-final03.dill` |exit0/6.071s, compilation des production pins finaux ; pas une build GUI |
| root : `bash tools/scripts/check_markdown_hygiene.sh` |exit0, aucun nouveau Markdown |

Le premier test MCP passait 7 comme version de résolveur en confondant le catalogueV7 avec resolver3. Sa preuve historique est géométrique ; le nouveau RED puis GREEN ci-dessus remplace cette borne et le probe strict vérifie la permission gameplay sur une fixture originale. Aucun parcours animé Kanto n’en est déduit. PMCP-085 global demeure PARTIAL ; refus authoring privés et réussite du writer host sont deux preuves séparées, sans attribuer les refus canoniques au fichier host étranger.

Les preuves corpus réelles restent historiques et bornées : 480 évaluations cardinales,119qualifiées sud,118bindings statiques (91map98+27map100), une exclusion pour event9 map98/B(14,16)/A(14,15). Root/reviewer recomparent sur disque les listes complètes de placements :315+168=483, tous champs égaux au r8. Les295+134 objets ac12-wall ne sont qu’un sous-ensemble. La bibliothèque enrichie r8 n’est pas qualifiée : son propre reçu indique assetCandidateCount0, resourceLibraryQualified=false et nativePathsAndWholeTreeLibraryImported=false, avec quota274>256. Aucun corpus233s rejoué après les deltas publication ou test MCP ; aucune bibliothèque complète, musique ou événements réels intégrés par ce writer seul.

Nouvelle source QA : copie APFS séparée du dossier Downloads,23 707fichiers originaux inchangés hashes/modes. Onze fichiers nécessaires absents sont récupérés seulement dans la copie depuis les témoins exacts conservés : Scripts,Outside,Game.exe jamais exécuté, BGM Route03 et sept Data/PBS. Copie finale23 718fichiers, scan réel ConverterWorkflow complet383cartes/0diagnostic,exit0/34.538s ; snapshot `448e76b43bea176dd96ec2376823b2418dd42b3d0bf8de9ba375a3b812225468`. `qualified-source-copy-post-scan-integrity-02.json` vérifie après scan l’original et la copie attendue,exit0/10.012s. Cela ne restaure pas tous les médias historiques :367chemins historiques restent absents. Les prochains plans doivent être fraîchement préparés et approuvés sur cette empreinte ; aucune recette historique réutilisée implicitement.

| Passe | Verdict borné |
| --- | --- |
| Audit/Architecture root et ac12_validation_design | oracle Ruby attesté ; carriers source exacts, consommation Z1 précise et événements fermés |
| Implémentation ac12_semantics |13blobs Source +5core ; P2 publication fermé ; seul test MCP révisé ensuite |
| Tests root et ac12_semantics |51core,35adapters privés puis35host,7API/JSONL,stdio1 et binder1 ; pas de suite globale revendiquée |
| Build/Validation root et ac12_semantics | analyse adapters privée/host, analyse core/authoring, kernel pur, rebuild/check MCP ; scan et intégrité source séparés |
| Critique indépendante ac15_connection_review_fresh | aucunP1/P2 restant sur Source18 ; pins/patch/reçus et limite host étranger vérifiés |

Auto-critique : une admission statique n’est pas une animation, un rendu ni une session Studio réelle. La fixture MCP n’est pas Route9. Le helper de publication continue de refuser toute modification incohérente plutôt que de récupérer une sortie altérée. Les JSON de métadonnées intermédiaires invalides sont conservés et remplacés par ledger05/06 valides ; aucun code ou reçu de test maquillé. Prochaine tranche : workflow/capability/diagnostics et compteurs explicites, puis banque réelle de chemins/arbres entiers, nouvelle publication98/100 et parcours Studio/Player fermé après usage.

Git : dix-huit blobs propres et ce rapport, sans hunks mobile/3D/render3D ni ancien prototype zone. `root-host-integration-03/prepared-blobs-04.json` et `host-apply-proof-03.json` attestent la conservation de62chemins préexistants non possédés et de border_actions host byte-exact, index vide avant staging. Le reçu de commit local doit confirmer parent e02f2559,19blobs exacts,index final vide et hashes/modes host conservés ; aucunpush/rebase/PR. Le ticket existant AC15 reste DOING/PARTIAL jusqu’au résultat complet, sans nouveau ticket ou domaine.

## Complément AC-15 — workflow et interface des rebords natifs, 13 octobre 2026

Portée : raccorder la conversion des rebords au workflow existant, exposer les exclusions et les budgets déclarés avant approbation, puis produire l’application macOS Converter. Le commit source précédent est acquis : `b19e12810aab708daebe972d742acec678374748`, parent `e02f2559db53ea909c06e786a4fa4c95e79df1bc`, dix-neuf chemins, index final vide, quatre-vingt-un témoins host hashes/modes conservés et soixante-quatre chemins étrangers encore dirty. Reçu `source-border-conversion-private-b57zk3zh/root-host-integration-03/source-commit-01.json`, SHA256 `44e68539ca9fcc7b32e83ad885aaf0e0b470b0fd48eb14b50166fb7908038d8a`. Aucune publication jouable ni fenêtre Route9 attribuée à ce commit.

Audit initial : le composer/writer possède désormais les Borders natifs et les snapshots typés, mais le profil workflow et les écrans de préparation ne les exposaient pas encore. Les actions canoniques existantes suffisent ; aucun nouveau modèle, transport ou plafond par défaut n’est requis. La review globale des ressources demeure séparée : elle ne qualifie encore ni une banque de chemins ni un arbre entier. Quatre blobs privés ont été gelés puis appliqués après contrôle du parent et des hashes de base ; soixante-quatre chemins préexistants étrangers restent exacts.

| Fichier de cette tranche | Zones modifiées, raison et effet |
| --- | --- |
| `packages/avelune_converter_adapters/lib/src/converter_workflow.dart` | profil `avelune-converter-native-study-ac15-border-ledgeline-v1`, manifeste v2, cinq actions Border autorisées explicitement ; résumé des imports/exclusions et diagnostics localisés ; progression incluant les snapshots Border ; fusion append-only de bibliothèque sans remplacement des cartes |
| `packages/avelune_converter_adapters/test/converter_workflow_test.dart` | préparation/reprise avec nouveau profil, rejet des recettes antérieures et des actions inconnues, budgets conservés, publication et relecture native stricte des snapshots, conservation des cartes lors de l’ajout de bibliothèque |
| `apps/avelune_converter/lib/converter_app.dart` | compteurs du draft déclarés face aux plafonds, rebords importés/conservés sans saut, cellule/carte/direction et motif d’exclusion visibles ; parcours animé explicitement restant à tester ; primitives du design system conservées |
| `apps/avelune_converter/test/converter_app_test.dart` | assertions sur compteurs et libellés, exclusion située et lisible, petite fenêtre/chemins longs, fixtures originales ; aucun média de production généré |
| `apps/avelune_converter/macos/Flutter/GeneratedPluginRegistrant.swift` | régénération depuis le graphe Converter déjà déclaré : seul `file_picker` reste enregistré, cinq anciens plugins Studio transitoires retirés ; header généré seul supprimé pour conserver la convention du fichier et la demande humaine sans commentaires |
| `documentation/reports/converter/AC-15/15_kanto_publication.md` | ce complément consolide audit, fichiers, preuves, défaut de cache, clôture Git et limites |

Les compteurs de préparation désignent les artifacts et JSON du draft déclaré, pas tous les futurs fichiers de staging. Le résumé final des ressources dénombre les vrais assets du catalogue ; les snapshots Border gardent leur reçu distinct. Les plafonds du caller sont conservés, aucune augmentation silencieuse. Les anciennes recettes au hash de profil différent sont rejetées avant scan plutôt que recyclées.

Preuves privées gelées : workflow `workflow-qualification-ledger-final-01.json` SHA256 `297ad01dd8fb7d7f5a269f68778ef175cc6eea6fdf394a0244737095ca7261b1` ; gel UI `converter-app-ui-final-pins-01.json` SHA256 `5cc287302538d70522ccbe92b8becedaf80bb6332c2f1b796db95bbae8dc146c`. Les quatre blobs host concordent avec ces gels. UI privée 14PASS/46.573s, analyse sans problème/8.405s, kernel 116567792bytes/15.866s ; les runs host ci-dessous constituent la preuve fraîche sur le checkout partagé.

Répertoire de reçus host : `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/border-converter-workflow-private-d2luex84/root-host-integration-01`. Les commandes sont lancées depuis le package indiqué, sous `run_owned.py`.

| Package et commande exacte | Résultat frais |
| --- | --- |
| adapters : `dart test test/converter_workflow_test.dart test/converter_asset_workflow_test.dart test/converter_study_plan_recipe_test.dart --concurrency=1 --reporter expanded`, témoins AC12 et AC13 activés ; `host-regressions-01.json` | 96PASS/0SKIP, exit0,41.066s ; ligne finale `00:39 +96: All tests passed!` |
| adapters : `dart analyze lib/src/converter_workflow.dart test/converter_workflow_test.dart` ; `host-analyze-01.json` | `No issues found!`, exit0,4.3s |
| Converter : `flutter test --no-pub --concurrency=1 test/converter_app_test.dart --reporter expanded` ; `host-ui-tests-01.json` | premier run exit1,7.374s : chargement impossible car package_config ancien ne contenait pas `avelune_design_system` déjà déclaré ; aucune assertion exécutée |
| Converter : `flutter pub get --offline` ; `host-pubget-01.json` | `Got dependencies!`, exit0,1.643s ; pubspec et lockfile hashes inchangés ; cache et registrant natif régénérés |
| Converter : `flutter test --no-pub --concurrency=1 test/converter_app_test.dart --reporter expanded` ; `host-ui-tests-02.json` | 14PASS, exit0,41.273s ; ligne finale `00:24 +14: All tests passed!` |
| Converter : `flutter analyze --no-pub lib/converter_app.dart test/converter_app_test.dart` ; `host-ui-analyze-01.json` | `No issues found! (ran in 6.0s)`, exit0,7.368s |
| Converter : `flutter build macos --debug --no-pub --target=lib/main.dart` ; `host-macos-build-01.json` | exit0,35.695s ; `✓ Built build/macos/Build/Products/Debug/Avelune Converter.app` |

Le log du build contient le message SwiftCompile « failed with exit code 0 » puis la build réussie, ainsi que le warning de dépréciation `kSecUseAuthenticationUIFail` dans `MainFlutterWindow.swift:30`. Ces lignes sont conservées ; aucun correctif Swift hors scope ajouté. Le retrait ultérieur du header de commentaires seul ne modifie aucune instruction du registrant compilé. Il n’y a pas de suite globale revendiquée.

Tous les runs de tests/analyse/pub-get retenus terminent sans signal ni survivant et avec processus protégés inchangés. Le build a laissé deux descendants possédés `ibtoold`, PIDs78442/78443 ; UID/start/commande recontrôlés, SIGTERM normal envoyé à chacun, aucun survivant confirmé après nettoyage. Aucun ancien PID ou session concurrente arrêté, aucune fenêtre ouverte pour ces preuves.

| Passe | Verdict borné |
| --- | --- |
| Audit/Architecture root + ac12_native_mapping | workflow et UI réemploient les contrats natifs ; raccord de review multi-carte audité séparément, sans relèvement des défauts ni changement ici |
| Implémentation root | quatre blobs gelés exacts appliqués, registrant régénéré après cache périmé ; six chemins possédés avec ce rapport |
| Tests root | 96workflow et14widget PASS frais sur host ; défaut de chargement initial explicite, pas de preuve graphique Route9 |
| Build/Validation root | analyses sans problème et application macOS réelle produite ; deux helpers possédés reapés, pubspec/lock inchangés |
| Critique indépendante ac15_connection_review_fresh | aucunP1/P2 sur les quatre blobs workflow/UI et le registrant final ; pins/logSHA/graphe natif et cleanup host revérifiés ; retrait du header seul post-build signalé explicitement |

Parité : les cinq mutations Border utilisent le contrat canonique map_authoring. La fixture MCP de la tranche source prouve le cycle draft/publish/materialize/reopen et le resolver3 ; cette UI ne crée aucune action supplémentaire. PMCP-085 global reste PARTIAL, une recette persistée seule ne constitue pas une preuve sémantique. FG-120 reste PARTIAL, AC-15 DOING/PARTIAL, sans modification de roadmap ou Gate bêta.

Auto-critique : tests widget et build desktop ne prouvent pas une animation dans le Player. La review synthétique approuvée ne remplace pas une bibliothèque réutilisable sur le vrai pair98/100 ; r8 conserve `nativePathsAndWholeTreeLibraryImported=false`. La nouvelle copie source QA contient 23718fichiers et le scan complet 23906entrées/383maps/0diagnostic, snapshot `448e76b43bea176dd96ec2376823b2418dd42b3d0bf8de9ba375a3b812225468` ; original23707fichiers exacts, mais 367chemins de l’ancien inventaire historique restent absents. Ne pas confondre scan complet et récupération de tous les anciens médias. La suite doit raccorder la review segmentée sous budgets explicites, approuver chemin/arbre entier, republier la paire réelle, puis peindre/placer/enregistrer/réouvrir dans Studio et exécuter le Player avec collisions/profondeur/sauts.

Git : parent attendu `b19e12810aab708daebe972d742acec678374748`, index vide avant staging, six chemins de cette tranche exclusivement. Le reçu `workflow-ui-commit-01.json` doit attester blobs exacts, index final vide et conservation de tous les témoins host hashes/modes. Ni writer mixte, Border actions étrangers, mobiles, 3D, caches ou lockfile inclus ; aucunpush/rebase/PR. Le ticket AC15 existant sera actualisé avec les deux commits et ces preuves sans être clôturé.


## Complément AC-15 — revue segmentée réelle et transport compact, 13 octobre 2026

Portée : terminer le raccord workflow, UI, recette et stockage de la revue de ressources pour toutes les cartes sélectionnées. Les cartes natives restent littérales ; les ressources approuvées sont ajoutées à la bibliothèque sans substituer les placements source. AC-15 demeure DOING/PARTIAL, FG-120 PARTIAL et PMCP-085 global PARTIAL. Aucune règle de combat, roadmap, Gate bêta ou donnée de chantier étranger modifiée.

Audit initial : parent `31ac268173466041f757ba3c5cd8ab14463fdeef`, branche main, index vide. Le plafond enfant256 faisait refuser les274propositions réelles des maps98/100 lorsqu’elles étaient traitées comme une seule session. Le set existant devait devenir le contrat unique du workflow, de l’interface et des reprises. La première sérialisation complète faisait4471924octets ; l’export de recette limité à4MiB et le changement de mode échouaient. L’ancienne UI et son test de cycle de vie dépendaient encore de reviewSession. Soixante-quatre fichiers étrangers sont protégés par SHA+mode dans host-baseline-01.json ; gel15 et contrôle indépendant confirment leur identité.

Décisions : settingsv2, recettev3 et document storev2 utilisent le set entier. Le wire du set devient2.0 ; les sessions core restent à leur contrat canonique existant. Chaque claim garde ses neuf champs, par contexte source partagé et tuple de placement. Les compteurs sémantiques continuent de compter toute l’histoire ; index et total sont bornés avant expansion, puis le codec core et le repack exact valident le contenu. Les plafonds JSON/core, enfant256 et recette4194304octets ne sont pas relevés ; aucun lecteur legacy, migration, alias ni fallback n’est ajouté. Le budget global derive du maxMutations explicitement choisi ; la paire utilise512, les valeurs par défaut restent conservées. Une approbation n’autorise pas une première frame incomplète ni un rollback enfant lors d’un CAS global.

### Inventaire des seize fichiers de cette tranche

| Chemin | Zones et résultat attendu |
|---|---|
| `packages/avelune_converter_adapters/lib/src/converter_workflow.dart` | Settings v2 et hash compact ; préparation de toutes les propositions par carte ; admission globale, complétude du seed et fusion append-only de la bibliothèque. Zones du diff : `@@ -8,0 +9 @@ import 'approved_asset_library.dart'; ; @@ -113 +114 @@ final class ConverterStudySettings { ; @@ -158,4 +159,3 @@ final class ConverterStudySettings { ; autres hunks dans le diff Git` |
| `packages/avelune_converter_adapters/lib/src/converter_asset_review_set.dart` | Wire2.0, table de contextes et tuples de claims ; bornes avant expansion, reconstruction core, repack canonique. Zones du diff : `@@ -101 +101 @@ final class ConverterAssetReviewSet { ; @@ -118,2 +118,3 @@ final class ConverterAssetReviewSet { ; @@ -270 +271 @@ final class ConverterAssetReviewSet { ; autres hunks dans le diff Git` |
| `packages/avelune_converter_adapters/lib/src/converter_study_plan_recipe.dart` | Recette v3 embarquant le set entier ; limites portables 4MiB conservées et admission dérivée des limites natives. Zones du diff : `@@ -5,0 +6 @@ import 'converter_workflow.dart'; ; @@ -82 +83 @@ final class ConverterStudyPlanRecipe { ; @@ -92,0 +94,15 @@ final class ConverterStudyPlanRecipe { ; autres hunks dans le diff Git` |
| `packages/avelune_converter_adapters/lib/src/local_review_session_store.dart` | Document v2 et checksum entier ; stockage/relecture de toutes les cartes ; CAS global et par enfant, refus de rollback ou divergence à révision égale. Zones du diff : `@@ -9,0 +10,2 @@ import 'native_project_writer.dart'; ; @@ -18 +19,0 @@ final class LocalReviewSessionStoreLimits { ; @@ -26 +26,0 @@ final class LocalReviewSessionStoreLimits { ; autres hunks dans le diff Git` |
| `packages/avelune_converter_adapters/lib/src/review_session_resumer.dart` | Restauration du mode seed pour découverte des dépendances, puis du mode et du set entier après nouvelle lecture source. Zones du diff : `@@ -18 +18 @@ final class ConverterReviewSessionResumer { ; @@ -114 +114 @@ final class ConverterReviewSessionResumer { ; @@ -123,4 +123,3 @@ final class ConverterReviewSessionResumer {` |
| `packages/avelune_converter_adapters/test/converter_asset_workflow_test.dart` | Régression quota globale, présence de toutes les cartes, seed incomplet signé refusé et bibliothèque issue des approbations exactes. Zones du diff : `@@ -6,0 +7 @@ import 'package:map_authoring/map_authoring_local.dart'; ; @@ -9,0 +11 @@ import 'support/original_asset_fixture.dart'; ; @@ -15,0 +18,69 @@ void main() { ; autres hunks dans le diff Git` |
| `packages/avelune_converter_adapters/test/converter_asset_review_set_test.dart` | Corpus dense274/12360claims ; intégrité du round trip et mutations négatives des contextes/tuples ; wire obsolète et expansion excessive refusés. Zones du diff : `@@ -11,2 +11 @@ final _normalized = Sha256Hash('b' * 64); ; @@ -165 +164,2 @@ ConverterAssetReviewSet _set({ ; @@ -168,4 +168,8 @@ AssetReviewSession _manySession(int mapId, int count) { ; autres hunks dans le diff Git` |
| `packages/avelune_converter_adapters/test/converter_workflow_test.dart` | Assertions du workflow migrées au set entier et aux propositions par carte. Zones du diff : `@@ -29 +29 @@ void main() { ; @@ -44,2 +44,8 @@ void main() { ; @@ -355,2 +361 @@ void main() { ; autres hunks dans le diff Git` |
| `packages/avelune_converter_adapters/test/converter_study_plan_recipe_test.dart` | Recette de plusieurs segments, quotas, décisions et reprise dans un workflow neuf. Zones du diff : `@@ -9,0 +10 @@ import 'support/literal_tile_fixture.dart'; ; @@ -134,0 +136,164 @@ void main() { ; @@ -156,2 +321,2 @@ void main() { ; autres hunks dans le diff Git` |
| `packages/avelune_converter_adapters/test/local_review_session_store_test.dart` | Round trip du set, intégrité documentaire, CAS enfant monotone, refus sans changement du fichier stocké et sécurité du stockage. Zones du diff : `@@ -48,2 +48,2 @@ void main() { ; @@ -58,0 +59,145 @@ void main() { ; @@ -67,5 +212,5 @@ void main() { ; autres hunks dans le diff Git` |
| `packages/avelune_converter_adapters/test/review_session_resumer_test.dart` | Reprise multi-cartes, changements de mode, décisions source et conservation des corrections/approbations. Zones du diff : `@@ -11,0 +12,62 @@ void main() { ; @@ -15,2 +77,2 @@ void main() { ; @@ -21 +83 @@ void main() { ; autres hunks dans le diff Git` |
| `packages/avelune_converter_adapters/tool/source_semantics_study.dart` | Export review-set.json et propositions indexées par sourceMapId ; retrait du chemin mono-session. Zones du diff : `@@ -228,2 +228,6 @@ Future<void> main(List<String> args) async {` |
| `apps/avelune_converter/lib/converter_app.dart` | Sélecteur de carte et set global ; callbacks liés à la carte et aux deux hashes ; drafts non appliqués conservés ; sauvegarde/reprise et mode atomiques. Zones du diff : `@@ -122 +122,2 @@ class _ConverterWindowState extends State<ConverterWindow> { ; @@ -149,0 +151 @@ class _ConverterWindowState extends State<ConverterWindow> { ; @@ -264,2 +266,2 @@ class _ConverterWindowState extends State<ConverterWindow> { ; autres hunks dans le diff Git` |
| `apps/avelune_converter/test/converter_app_test.dart` | Cinq nouveaux parcours multi-cartes, callbacks obsolètes, champs non appliqués, mode et persistance du set entier. Zones du diff : `@@ -5,0 +6 @@ import 'package:avelune_converter/converter_app.dart'; ; @@ -6,0 +8 @@ import 'package:avelune_converter/desktop_services.dart'; ; @@ -7,0 +10 @@ import 'package:avelune_converter_adapters/avelune_converter_adapters.dart'; ; autres hunks dans le diff Git` |
| `apps/avelune_converter/test/converter_session_lifecycle_test.dart` | Six scénarios conservés ; correction via replaceSegment et assertions sur le set complet, le segment corrigé et le document stocké. Zones du diff : `@@ -31,0 +32,3 @@ void main() { ; @@ -38,0 +42,6 @@ void main() { ; @@ -71,2 +80,6 @@ void main() { ; autres hunks dans le diff Git` |
| `documentation/reports/converter/AC-15/15_kanto_publication.md` | Ce complément consolide les preuves, aucun nouveau Markdown. |

### Preuves exécutées sur le gel final

Racine externe R : `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/review-set-integration-01`. `freeze-15-01.json` SHA67d645c8d00971556181e51663cfec339505dcbf522a5cb8d166de7f4ef1a0aa fixe les quinze fichiers de code. Les deux témoins `AVELUNE_AC12_SOURCE_SCRIPTS` et `AVELUNE_AC13_SOURCE_SCRIPTS` pointent sur Scripts.rxdata de la copie source pour les deux runs de tests finaux ; aucun test corpus ne reste skipped.

| cwd et commande exacte | Résultat et reçu |
|---|---|
| `packages/avelune_converter_adapters` : `dart test test/converter_asset_workflow_test.dart test/converter_workflow_test.dart test/converter_study_plan_recipe_test.dart test/local_review_session_store_test.dart test/review_session_resumer_test.dart test/converter_asset_review_set_test.dart test/local_asset_proposer_test.dart --reporter expanded --concurrency=2` |253PASS/0SKIP,80.135s ; adapters-targeted-02.json, logSHA0039cfef1d87cc347347aa9255995eb4dc2ab8b6c7a2681752aceef4ee91023c|
| `packages/avelune_converter_adapters` : `dart analyze` |No issues found,5.308s ; adapters-analyze-02.json|
| `apps/avelune_converter` : `flutter test --no-pub --concurrency=2` |92PASS/0SKIP,54.392s ; app-full-tests-01.json, logSHA7cd4f51087c24a524cd23a6c07585e7d416702f2dd685681dc4838bf66a7e630|
| `apps/avelune_converter` : `flutter analyze --no-pub` |No issues found,6.633s ; app-analyze-02.json|
| `apps/avelune_converter` : `flutter build macos --debug --no-pub` |exit0,31.148s, Avelune Converter.app produit ; app-macos-build-01.json|
| `tools/pokemap_mcp` : `npm run build` puis `npm run check` |exit0,1.304s/1.041s ; mcp-build-01.json / mcp-check-01.json|
| `tools/pokemap_mcp` : `node R/live_catalog_probe.mjs R` |exit0,8.751s ; mcp-live-catalog-run-01.json ; describe live410actions, douze actions bibliothèque/Border présentes et extensions ledgeLineV7 attestées|

Les runs utilisent run_owned.py : identité PID/UID/start/commande et descendants observés, pins avant/après, zéro survivant confirmé, zéro signal et protectedUnchanged=true pour les huit reçus finaux ci-dessus. Le build Mac et le build MCP capturent le gel14 ; les fichiers de production sont exactement ceux du gel15, qui ajoute uniquement le test existant de cycle de vie. Aucun GUI ne découle de ces preuves.

Défaillances conservées : root-red-02 reproduit le clamp global renvoyant0candidats au lieu280 ; root-seed-red-01 reproduit le seed incomplet resigné admis. compact-claims-red-02 reproduit4980975octets au-delà2MiB ; le premier compact-red ne prouvait que la version wire. Une mutation négative était un no-op car la valeur se trouvait déjà dans la première claim triée ; le test incrémente maintenant la valeur et son cas isolé passe, sans changement produit. adapters-targeted-01 reste247PASS/5SKIP/1FAIL dans son reçu historique. app-analyze-01 conserve dix erreurs d’ancien API dans le test lifecycle ; migration ciblée et fullapp/analyse finaux les ferment. Aucun résultat intermédiaire n’est réécrit en réussite.

### Corpus réel et limite de la preuve

real-pair-03 prépare274candidats :69/8167claims pour map98 et205/3352claims pour map100, soit11519claims. Le wire2.0 occupe898155octets, contre4471924 auparavant, sourceSnapshotHash448e76b43bea176dd96ec2376823b2418dd42b3d0bf8de9ba375a3b812225468. real-bank-review-02 compose276candidats/deux approbations/1741322octets. Le chemin utilise le rectangle source(32,384,96,96), l’arbre complet(128,1664,64,96) de FRLG_Outside.png ; aucun pixel redessiné. Les deux ajouts de bibliothèque n’inventent aucun claim de placement. Tous les11519claims initiaux restent conservés et map100 reste exacte après le changement commun de mode puis les ajouts dans map98. Ces helpers ne publient pas encore une banque native et ne prouvent pas la reprise réelle via store/recette ou un parcours GUI.

Passes : audit/root identifie le quota et la représentation trop grosse ; implémentation/root livre workflow/codec et contrôles ; ac12_native_mapping livre recette/store/resumer et ferme son P2 de CAS enfant ; ac10_ui livre UI et migration ciblée du lifecycle ; tests/build/root exécutent les preuves jointes. La critique indépendante ac15_connection_review_fresh recompute les quinze hashes, les sept premiers reçus/logs et les64hashes+modes étrangers : aucun P1/P2 restant dans la tranche, verdict favorable borné ; AC15 globale demeurePARTIAL. Aucun sous-agent ne revendique de GUI ou de publication à partir des helpers de revue.

Auto-critique : la bibliothèque préparée ne remplace pas sa publication native et son usage dans Studio. Le nombre de tests ne qualifie ni Route9 jouable, ni la totalité de Kanto. Réglages d’ancre et catégorie dans les compagnons ne prouvent pas collision/profondeur d’un nouvel objet placé. La récupération de tous les anciens médias, le parcours Player, les dépendances externes exclues de la paire et la distributionAC16 restent ouverts. Suite concrète : publier la paire avec les deux ressources, modifier/sauvegarder/réouvrir dans Studio, puis vérifier Player collisions/profondeur/sauts avant extension Kanto.

Git : commit local autorisé de ces seuls seize chemins, gel15 contrôlé avant staging, rapport existant seul en plus ; aucun push/rebase/PR ou changement de branche. La preuve finale de commit et le test d’hygiène seront enregistrés après ce complément ; les64fichiers étrangers restent hors index. Le ticket AC15 existant resteDOING/PARTIAL dans Monde & narration PostBêta, sans création de ticket de contenu ni changement du périmètre bêta.


### Publication réelle de la banque : préparation durable et interruption du superviseur

Le helper `real-native-bank-01` apporte maintenant un reload effectif du store réel et un decode de la recette réelle : set276 entier identique, deux ressources approuvées, recette1745824octets sous4MiB, document store hash3d52dcf49e341848d3a5fa75aebf3f319fa1cf70709ffc262e19bee6ab1e45cd et recette hash070b7d22f95c79ecc486d2a0f92528011ef28fc0a9eefd1b5a65de5161dffaa3. `prepared-bank.json` atteste406mutations/80artifacts. La critique indépendante confirme ces round trips et le catalogue live ; aucunP1/P2 relevé. Cette preuve lève la limite store/recette des deux anciens helpers, sans constituer une publication ou une qualification GUI.

La première commande du helper a échoué à la compilation (exit254,7.807s) sur une sérialisation de reçu inexistante ; correction du helper QA externe uniquement. Le second run `real-bank-publish-run-02.json` a été interrompu par le timeout600s du superviseur : exit-15,timedOut=true,600.215s. Préparation261307ms, début écriture312330ms ; journal non scellé et dernier audit natif192, destination finale absente. Le délai QA trop court est la cause observée de cet arrêt ; aucun échec fonctionnel du writer n'est déduit. Une seule SIGTERM du runner49910, identité revérifiée, zéro survivant, protégés inchangés. Le stage incomplet reste conservé et ne doit pas être présenté comme une livraison.

La reprise QA est lancée via `restart_publish_bank.dart`, dans un workflow neuf depuis la recette exacte enregistrée, avec superviseur1800s. Elle doit réconcilier le journal incomplet, reconstruire et vérifier les hashes de la recette puis effectuer une nouvelle publication exclusive ; le contrôle précédent reste intact. Reçu terminal attendu `real-bank-restart-run-01.json`, preuves sous `real-native-bank-restart-01`. Aucun résultat de cette commande encore en cours n'est anticipé dans ce commit.

Le build Studio debug `studio-macos-build-01.json` est PASS (exit0,46.222s), avec point d'entrée Marionette et chemin de copie QA explicite. Deux descendants ibtoold propres au build ont été terminés normalement après vérification d'identité ; zéro survivant et protégés inchangés. La copie du nouveau projet, la fenêtre Studio et le Player n'ont pas encore été lancés. La preuve Studio historique du12octobre porte sur la première étude Route9 modifiée/enregistrée/rouverte ; elle ne certifie pas la nouvelle paire avec chemins, arbre entier, rebords et collisions.

La tranche code est reviewable et vérifiée ; AC-15 global reste DOING/PARTIAL jusqu'à la publication et aux parcours réels. Les15pins de code, parent31ac268 et index vide sont revérifiés avant staging. Aucun changement du writer étranger ni des64chemins hors scope n'est inclus.


## Complément du 14 octobre 2026 — cadence, saut et son après essai humain

Yoahn a testé la conversion et confirmé qu’elle fonctionne. Il signale un personnage trop rapide, un saut étrange et l’absence du petit son de saut ; il demande une comparaison avec des vidéos des jeux originaux. Ce correctif reste dans AC-15, FG-120 PARTIAL. Aucun nouveau ticket de réparation ni changement de roadmap.

### Audit et décision

Le runtime utilisait 120 ms/case en marche et 75 ms/case en course. Le témoin Essentials Kanto extrait et attesté, `ledge-source-audit/outputs/044.rb:110–139`, fixe respectivement 250 et 125 ms/case. Les lignes 321–325, 783 et 935–962 confirment la translation linéaire et la parabole de deux cases à 500 ms / 24 px. Les lignes 990–1020 continuent les frames pendant le saut. Ces durées, hauteur, collisions, réservation et conséquences d’atterrissage sont conservées ; les jambes passent à l’animation de marche pendant le saut.

La vidéo [Route 9, Rouge Feu, PokeTeckers](https://www.youtube.com/watch?v=X5IohZcJ3_M&t=86s) a été ouverte dans le navigateur et examinée par vingt avancées d’images autour de 85,9–86,58 s. Les images successives montrent une ombre au sol distincte du personnage élevé. Le lecteur était muet : aucune écoute du son de cette vidéo n’est revendiquée. Le téléchargement ordinaire du média blob a échoué ; aucune autre méthode ni contournement employé.

Les sources primaires [event_object_movement.c](https://github.com/pret/pokefirered/blob/master/src/event_object_movement.c#L5741) et [field_player_avatar.c](https://github.com/pret/pokefirered/blob/master/src/field_player_avatar.c#L905) recoupent ombre et son au départ du saut. Le projet de test PSDK configure `Data/configs/sound_design_config.json:54–58` vers `audio/se/jump.wav`, volume/pitch 100 ; le moteur PSDK `scripts/4 Systems/003 Map Engine/2 Logic/50 RMXP/400 Game_Player.rb:135–139` le joue à la première update du saut. Import rerunnable depuis ce corpus autorisé : WAV PCM16 stéréo 44100 Hz, 29612 octets, 167,619 ms, SHA256 `38c2e846c2c0b387167a8c32ef64eae99dba4298622458198f83eee8ead4f779`. Aucune exécution Ruby, création IA ou modification source.

### Fichiers et zones modifiés

| Fichier sous `packages/map_runtime/` | Zone et rôle |
| --- | --- |
| `lib/src/presentation/flame/player_component.dart` | Constantes marche/course ; motion du saut ; ellipse rendue au pied au sol, avant l’acteur élevé. |
| `lib/src/presentation/flame/playable_map_game.dart` | Injection du lecteur d’effets overworld ; son une fois après admission du saut ; fermeture du lecteur avec le game. |
| `lib/src/player/overworld_sfx_player.dart` | Nouveau lecteur réutilisable : asset WAV, mixer complet, échecs audio contenus, arrêt et disposal indépendants. |
| `lib/src/player/runtime_audio_mixer.dart` | Route native `overworldEffects` dans le bus effects. |
| `lib/map_runtime.dart` | Export du port et du lecteur. |
| `pubspec.yaml` | Inclusion de `assets/audio/overworld/`. |
| `tool/import_overworld_jump_audio.py` | Import depuis la configuration PSDK, confinement source et reçu SHA/format. |
| `assets/audio/overworld/jump.wav` | Son source exact importé par l’outil. |
| `assets/audio/overworld/jump.source.json` | Provenance, hash, format et paramètres source. |
| `test/player_component_test.dart` | Cadence de référence et interpolation existante. |
| `test/player_directed_jump_component_test.dart` | Motion walk et pixels de l’ombre au sol ; disparition après atterrissage. |
| `test/playable_map_game_directed_jump_test.dart` | Son une fois ; aucun son sur refus ; disposal avec le game ; fake audio des parcours. |
| `test/playable_map_game_input_test.dart` | Deux durées de témoins ajustées à la marche plus lente ; commandes et enchaînement conservés. |
| `test/player/runtime_audio_mixer_test.dart` | Route effects du nouveau son. |
| `test/player/overworld_sfx_player_test.dart` | Source embarquée, voix unique, volume/ducking, stale async, refus backend et teardown. |

Le seul autre fichier versionné modifié est ce rapport existant. Le formatteur a initialement reformaté des zones anciennes ; ce churn a été retiré en reconstruisant les fichiers propres depuis HEAD plus les seuls remplacements du correctif. Les 64 chemins étrangers présents avant la tâche sont conservés SHA et permissions compris.

### Vérification et passes

Racine des reçus : `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac15-post-restart-20261013-sk83jcu5/movement-feel-01`.

- **Audit / architecture** : comparaison vidéo réelle, Ruby Essentials extrait attesté et PSDK en lecture seule ; défaut de cadence et absence d’ombre/son identifiés. Valeurs Essentials retenues explicitement, sans prétendre reproduire tous les profils PSDK/GBA.
- **Implémentation** : 15 fichiers runtime physiques, aucun changement de modèle gameplay/core/converter, aucune nouvelle permission de passage et aucune logique de combat modifiée.
- **Tests** : `player-red-02.json` = 13 PASS / 2 FAIL fonctionnels sur cadence et motion ; premier red avait aussi un import de test mal placé, corrigé. Premier green = 93 PASS / 3 FAIL : un champ de fake audio en conflit et deux témoins à l’ancienne cadence ; corrigés. Un import mal renommé pendant le retrait du churn a été corrigé avant green03. `runtime-green-03.json` = 99 PASS. Deux contrepreuves audio `audio-red-01.json` = 4 PASS / 2 FAIL : ducking initial contourné et erreurs de teardown propagées. Ces deux défauts sont corrigés.
- **Vérification finale** : `runtime-final-01.json` = **101 PASS / 0 FAIL / 17,189 s**, exit0. Commande : `flutter test --no-pub --concurrency=1 test/player_component_test.dart test/player_directed_jump_component_test.dart test/playable_map_game_directed_jump_test.dart test/player/overworld_sfx_player_test.dart test/player/runtime_audio_mixer_test.dart test/battle_sfx_audio_mix_test.dart test/playable_map_game_input_test.dart test/phase_a_golden_battle_slice_smoke_test.dart --reporter expanded`. Après le seul ajout de diagnostics dans les catches, `audio-final-02.json` = **6 PASS / 8,110 s**, exit0.
- **Analyse** : `flutter analyze --no-pub --no-fatal-infos` sur les onze fichiers Dart concernés ; `analyze-final-02.json` = **exit0 / 10,606 s / 0 erreur / 0 warning / 6 INFO préexistantes**. Aucune INFO nouvelle conservée.
- **Build / validation** : Studio macOS debug compilé puis lancé sur la copie QA via `flutter run --debug --no-pub -t movement_main.dart -d macos` avec les deux defines projet/captures exacts. Les dernières méthodes audio sont appliquées par deux hot reloads réussis, une bibliothèque chacun ; aucun cold restart final revendiqué.
- **MCP** : comportement runtime par défaut et effet audio interne, aucun nouveau contrat d’authoring ou champ de projet. API/JSONL/editor/MCP de la permission native restent inchangés ; nouveaux transports de réglage N/A. `npm run build` et `npm run check` exit0 ; `pokemap_describe` vivant via serveur construit : **410 actions**, contrats rebords/imports toujours découverts. Les tests runtime exécutent le consommateur du même Border natif.
- **Critique indépendante** : audit de références et revue du delta par `ac15_connection_review_fresh`. Deux P2 audio relevés et fermés par contrepreuves ; vérification finale des pins/reçus consignée séparément dans le reçu de preuve, aucun verdict positif anticipé.

Les résultats précédents sont des checkpoints sans pins enregistrés durant ces runs. Clôture sur le gel final : `runtime-pinned-final-01.json` = **101 PASS / 0 FAIL / 20,397 s / exit0** ; `analyze-pinned-final-01.json` = **exit0 / 9,856 s / six INFO préexistantes / zéro erreur et warning**. Chacun enregistre les 16 SHA (15 fichiers runtime + helper QA) avant et après, tous identiques au gel `freeze-final-02.json`. Les logs SHA sont respectivement `32c195fab4b4987c0957c34b3afa7b3d674ebc248c7d6d80223322008a05d2f6` et `ea1177dad8d02db122b75bcaf823cd877542bc2bfadd359c1aefa2aafb0f20b9`.

Tous les reçus terminaux de tests/analyse/MCP ont zéro survivant et leurs processus protégés inchangés. `git diff --check` et Markdown hygiene passent, zéro nouveau Markdown.

### Studio réel, reprise humaine et limites

La copie QA contient 1324 fichiers byte-exacts depuis le projet modifié en Studio : `…/ConverterQA-20261013-movement-r10/Projet converti`. Route 9 a été ouverte et lancée dans le vrai Player avec les changements. Le joueur, le chemin et l’arbre entier sont rendus à l’écran. Les observations initiales au clavier sont conservées, mais ne certifient pas un parcours automatisé : Yoahn jouait dans la même fenêtre et ses touches se mélangeaient aux contrôles. Il a confirmé vouloir continuer à jouer ; aucune autre touche de déplacement envoyée après cette confirmation. Un démarrage de capture à 30 fps a été refusé (plage autorisée 10–20) : aucun film de saut n’en est déduit.

La fenêtre et sa session debug vivante sont donc **conservées à la demande de Yoahn**, exception explicite à la fermeture des seules applications de test. Marionette déconnectée, activité de capture désactivée, watchdog propre suspendu avant son délai afin de ne pas interrompre le jeu humain ; identité et descendants exacts enregistrés dans `studio-user-handoff-01.json`. Flutter stdin hérité du heredoc était fermé : `d\n` n’a pas détaché l’app et n’est pas présenté comme une réussite. Quand Yoahn termine : fermeture normale de l’app vérifiée, reprise du superviseur puis contrôle/reap des seuls descendants enregistrés. Aucun PID étranger ciblé.

Le projet d’origine de cette copie reste byte-exact sur ses 1324 fichiers. Le correctif ralentit les defaults natifs de tous les projets ; les durées explicitement fournies aux appels restent conservées. Le saut garde 500 ms/24 px et ses règles d’admission ; le son natif PSDK n’est pas une certification acoustique exacte de chaque jeu source. AC-15 et FG-120 restent **PARTIAL** : trajet contrôlé collisions/profondeur/sauts/transfert/save/load et Kanto entier toujours à qualifier. Cette réparation est prête pour revue technique, jamais marquée DONE à la place de l’utilisateur.

Git initial : main `d8d0ec3c96e33618c816ced7c283f7d17f61c7c2`, index vide, 64 chemins étrangers dirty. Livraison locale prévue : les 15 fichiers ci-dessus plus ce rapport, SHA et état Git terminal consignés dans le reçu de commit ; aucun push/rebase/PR.

## Actualisation du 15 octobre — dialogue, portes et sauvegarde dans le même trajet

**Verdict : parcours borné du vrai moteur acquis, validation visible encore PARTIAL.** Le projet natif issu du workflow normal Source30 est joué dans un vrai `GameWidget<PlayableMapGame>`. Dans deux processus OS séparés, le joueur entre dans le Centre, rejoint le vrai PNJ 102/14, lit sa réplique, revient à la porte, sort et sauvegarde sur disque. Aucun appel direct de scène ni changement artificiel de pose pendant le trajet. Cette preuve ne déclare pas la fin d'AC-15 ou du goal AC-00 à AC-16.

### Audit initial, décisions et fichiers

Base hôte : `53480e9960a463037de1470712f50fab819b3465`, main et origin/main synchronisés, index vide, 96 chemins étrangers conservés en hash dans les contrôles de cette session. Source produit : cohorte Source30 publiée par `63577610e`, puis correction legacy `eec7ae856` hors dépendances de ce harness. Les règles Codex, le kit KAN-03, les skills de vérification/debug et les vrais harness précédents sont relus. La recherche Flame docs sur le lifecycle GameWidget ne retourne aucun résultat ; les patterns existants fonctionnels sont réutilisés, sans nouvelle API moteur inventée.

Seul ce rapport existant est modifié dans le dépôt : en-tête courant et présent complément. Aucun code produit, modèle, ressource de jeu, test permanent, commande MCP, roadmap FG ni workflow CI changé pour ce trajet. Le harness de qualification reste externe sous `T/source/cohort-isolated-02/repository/examples/playable_runtime_host/test/qa_kan03_combined_journey_test.dart`, où `T=/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac13-source-door-timing-20261014-83ui2yih/native-global-routes-01`. Préparations, gels, reçus et sauvegardes sont dans `T/kan03-combined-01` ; la source Kanto restaurée reste distincte du paquet original incomplet.

Le projet testé est `T/source/normal-workflow-01/Original door global routes QA`, créé par `ConverterWorkflow.writeApproved`, vérifié et publié, sans Writer de substitution. Son inventaire de 1 403 fichiers reste identique au reçu Source30 et à la copie utilisateur `Documents/Avelune Converter Studies/Kanto - Route 9 Route 10 et Centre - 20261015/Projet Avelune`.

### Parcours réellement exécuté

Départ QA déclaré : extérieur Map100, `(13,26)`, sans certifier le départ d'une nouvelle partie Essentials. Une entrée cardinale monte vers la vraie porte `(13,25)` ; la scène originale mène dans Map102 `(9,10)`. Le joueur marche sept cases à droite puis une vers le haut jusqu'à `(16,9)`, devant le PNJ source `(16,8)`. Le contact seul n'ouvre pas son dialogue `entityInteract` ; l'entrée primaire ouvre exactement la réplique sur les fantômes de Lavender Town.

Le vrai `DialogueOverlayComponent` est monté, le texte intégral est présent et reste affiché pendant 45 frames de test, avec contexte d'entrée dialogue. Sauvegarder pendant le dialogue est refusé. Une confirmation ferme le dialogue une seule fois, puis le joueur revient à pied en `(9,10)` et sort par contact avec le terrain bloquant `(9,11)`. Retour extérieur `(13,26)`, visibilité/ton/input rétablis et état d'instance `A=true`. Trois requêtes SE uniques aux gains 0,48 / 0,384 / 0,48 sont contrôlées ; aucune audibilité matérielle inférée. Aucun soin ou récompense ajouté au PNJ.

Après une période sans entrée vérifiant l'absence de boucle, `game.saveGame()` écrit le vrai `FileGameSaveRepository`. La seconde invocation exige un PID distinct, le SHA exact du fichier précédent et l'égalité de son état décodé avant montage. Au boot `saveRestore`, elle compare l'état strict entier, y compris les instances retenues, leurs IDs, `A` et les consommations, en autorisant seulement le jeton d'activation natif exact prévu par le contrat. Elle rejoue ensuite le même trajet complet et sauvegarde à nouveau. Les 1 403 fichiers du projet restent inchangés après chaque phase.

### Erreurs de qualification conservées et contrat de reprise

L'essai 01 échoue avant toute entrée, 0 PASS / 1 FAIL, 11,802 s : la baseline est capturée avant le montage asynchrone du voisin Map98. Son arrivée ajoute une instance vide pendant l'idle. Le gel 02 attend les voisins réels déclarés dans `bundle.map.connections`, puis une mise à jour normale de réconciliation, avant de comparer les baselines. Aucun loader, reconcile ou déplacement n'est invoqué directement.

Prepare02 passe 1/0 en 44,578 s ; Restore02 échoue 0/1 en 9,239 s avant entrée sur le seul jeton `appliedNarrativeResetTokens` ajouté au chargement. Le store complet, les IDs et `A` ont déjà passé leur comparaison. Le bridge `beforePlan` appelle `applyMapActivationReset` pour chaque activation ; `saveRestore` garde `resetEligible=false`, mais ajoute son jeton sans réarmer les oneShot. Les tests existants du bridge et de l'authority confirment ce contrat.

Le gel 03 exige une seule activation achevée, la raison et carte exactes, le token de `debugLastCompletedMapActivation`, le préfixe sauvegardé intact et exactement un append unique. Il reconstruit l'état attendu avec ce seul champ ajouté, puis compare tout `strictGameStateSaveJson`. Les comparaisons idle/save restent inchangées. Les gels 01/02, leurs échecs et leurs copies de harness sont conservés ; aucun ancien FAIL n'est réétiqueté PASS.

### Commandes, preuves et résultat actuel

Depuis l'archive privée, cwd `examples/playable_runtime_host`, deux invocations indépendantes exécutent `flutter test --no-pub --concurrency=1 test/qa_kan03_combined_journey_test.dart --reporter expanded`. Variables : `QA_KAN03_PREPARATION=T/kan03-combined-01/preparation-03.json`, `QA_KAN03_SAVE_ROOT=T/kan03-combined-01/disk-save-03`, et `QA_KAN03_PHASE=prepare` puis `restore`. Les argv exacts de `preparation-03.json` utilisent `Q/run_owned.py`, timeout 300 s, 40 pins produit/harness et la préparation elle-même ; Q=T.parent.

| Phase gel 03 | Résultat | Preuve |
|---|---|---|
| Prepare | exit 0, 1 PASS / 0 SKIP, 42,422 s ; PID test 93056, 134 états tracés | `combined-prepare-03.json` SHA `b714b7dfc1961a9bc984d743493f175a2a2d6bc0402f9901de373e55d13a5033` |
| Restore, nouveau processus | exit 0, 1 PASS / 0 SKIP, 42,311 s ; PID test 93366, 133 états tracés | `combined-restore-03.json` SHA `9776438c6112519bbdd70defa2540c166249a07f960b883fe5df07adb61c2d0c` |

Harness final SHA `64894f99fa62e661d06e564641f04c5a117dd1d9729b9daea53f6a6870359b84` ; préparation SHA `41a7e9ee21e146290aa7f02ea3de0cc17d89d4060c486b7b184a5e58b939cdab` ; gel `frozen-03/manifest.json` SHA `be8d164fb93e3b254b0fa0a7300d34423b0349025e0a71f0e9479f7f8f683809`. Preuve Root consolidée `qualification-03.json` SHA `6982db1f9c9e630415f2a1bfa7ac74f0f0a42d03079db91996f3ddbfaccd4b4a`. Chaque reçu terminal garde ses pins avant/après, son log SHA, ses descendants et l'absence de survivant/signal ; les PID protégés sont inchangés.

Audit/Architecture : contrat d'activation et différence entre état de jeu et journal interne vérifiés. Implémentation : seule instrumentation QA externe corrigée. Tests : deux vrais trajets gel03 ; Build/Validation : chaque invocation compile et monte le vrai GameWidget, sans nouveau build monolithique de Studio revendiqué. Critique indépendante du gel03, `harness-independent-review-03.json` SHA `55a303053fb00b1ab4c4f29314af3873dd2a5586a511d07beac9cc9773a2d928`, puis contre-revue des preuves `final-evidence-review-03.json` SHA `94e14fe7072055adc82c694e6b4f90683dbc9c2342438a10ccd1b69f42232df5` : favorable bornée, aucun P1/P2. L'analyse finale `dart analyze test/qa_kan03_combined_journey_test.dart` passe No issues found en 9,039 s ; reçu `T/evabc-refresh-20261015/kan03-final-analyze-01.json` SHA `c488b6b7f46173f8dc6691a00fded4e462bf7bef64977441ad3a445534fd372b`, 42 pins exacts, aucun signal/survivant et protections inchangées. La passe indépendante relit les PID test réellement observés, la chaîne de sauvegarde, les 1 403 hashes et le seul delta autorisé au cold boot ; les deux jetons Warp du trajet rejoué sont des événements ultérieurs normaux.

Auto-critique : KAN-03 dispose désormais d'une preuve moteur continue sur ce parcours, avec départ QA explicite et reprise OS réelle. La fenêtre Studio de la livraison Source30, la revue du rendu/son, les chemins/arbres réutilisables et le trajet Route 9 pickup/sauts/collisions/profondeur restent ouverts. Aucune cadence Source entière, soin, combat importé, nouvelle partie Source ou conversion universelle certifiés ; `sourceAdmission` et `globalPlayabilityCertified` restent false. Parité MCP nouvelle N/A pour ce seul complément de qualification, aucune sémantique d'authoring modifiée. Le ticket AC-15 existant reste DOING/PARTIAL dans Monde & narration Post Bêta, Gate bêta false ; le goal conserve tous ses lots. SHA/index/empreintes étrangères finaux consignés dans le reçu externe de publication après contrôle ciblé.


## Complément du 15 octobre — Trois cartes et ressources réunies dans la publication normale

### Audit, périmètre et écriture

Audit initial : main `4578ccca1c51a1a3dfbc4845d98836f135c53eed`, index vide et 96 chemins étrangers empreintés. La production utilisée est l'archive propre eec7ae856 ; le diff jusqu'au HEAD ne change que tests, outils de qualification et rapports. Le hunk étranger `gameplay_zone` du writer host est conservé hors cohorte et hors commit. Les instructions ultérieures de Yoahn autorisent le push normal sur main ; la restriction historique de push en début de rapport ne décrit plus l'autorisation courante. Aucun rebase, amend, force, stash ou branche créée.

Le résultat précédent Source30 et la banque r9 étaient distincts. Le helper externe construit un nouveau scan de la même source `fd1e6e73879d90d3dbedffcd703e5bac5b3b58c9fc8a9186ce1e5d98233dbe4e`, garde les trois cartes 98/100/102 et les trois décisions statiques d'exclusion, puis rattache les deux candidats approuvés à la session fraîche. Il restaure ensuite la recette dans un autre `ConverterWorkflow`, exige l'identité du plan complet et demande une nouvelle approbation avant `writeApproved`. Les décisions de pixels déjà approuvées sont réutilisées dans le cadre de la livraison autorisée ; aucun clic humain sur ce nouveau draft n'est revendiqué. Zéro Ruby exécuté, zéro appel IA, aucun greffage JSON natif.

B désigne `/Users/karim/Library/Application Support/AveluneConverterStudies/QA/ac13-source-door-timing-20261014-83ui2yih/native-global-routes-01/combined-kanto-bank-20261015-01`. L'outil QA privé `qa_kanto_combined_bank_01.dart` est lié au gel `frozen-01/manifest.json`, source SHA `f35d1f8addf462d272c755dd8123e93a122684fc2ebecca04fe6a62b7e6d4912`, binaire AOT SHA `2c0d9df1d276af2d535e633751383f968f341c3c18aae3bd50fddb6befa278a6`. Ces outils et les projets avec médias restent externes au dépôt. Le seul fichier versionné modifié par ce complément est ce rapport : en-tête courant et présente section. Aucune sémantique produit ou API d'authoring nouvelle ; parité MCP nouvelle N/A pour cette qualification du workflow canonique existant.

### Composition et vérification physique

- Les 455 mutations Source sont conservées avant les 12 mutations de bibliothèque, soit 467 mutations et 93 artefacts. Recette de 2 140 214 octets, SHA canonique `1fa753086ba21e5fa3a8168ee8c85af881b74b221db2cc251b315784c0de73cf`, restaurée à l'identique dans le workflow frais.
- Le projet final comporte 1433 fichiers et 174264357 octets, révision `sha256:5a03512529826de6c661818f7a7a9c43772b38b2c592ea050120098c4037ba89`. Les trois fichiers de carte restent byte-identiques, ainsi que tous les champs existants du manifeste hors nom et ajouts de bibliothèque. Deux objets, trois images/tilesets et deux catégories sont ajoutés ; toutes leurs définitions et le catalogue SmartTile entier correspondent à la banque r9 approuvée. Le chemin publié possède seize règles et aucun fallback.
- Les pixels, dimensions, parties et ancres sont exacts : chemin 96×96, ancre (48,96), atlas du pinceau 128×128 ; arbre 64×96, ancre (32,96). Les deux candidats restent `libraryOnly`, sans substitution de placements. L'arbre garde `collisionProfile=null` : sa physique n'est pas certifiée par cette composition.
- La projection finale est exactement celle de la préparation fraîche avant ajout des ressources. Comparée à l'ancienne Source30, seul le champ explicite `doorExecutionQualification.sourceExecutionContext.baseDraftHash` change avec le nouveau contexte. Les trois exclusions conservent leurs records complets ; leur ordre d'évidence 6/7/13 devient 7/6/13, conformément au tri par hash du constructeur `ConverterStudySettings` (`converter_workflow.dart:173`). Aucune exclusion supplémentaire et aucun quatrième transfert inventé.
- L'ancien projet de 1 403 fichiers, modes inclus, reste intact sur disque. Une nouvelle publication régénère ses journaux et blobs : elle n'est pas présentée comme une copie identique des 1 403 anciens fichiers.

Qualification physique `B/native-qualification-01.json`, SHA `95d9e9101b382b49e545870707ac57596170c1039f5c27357e7b0121e75bef1f` ; résultat `B/publication-01/result.json`, SHA `33694e18ec7cb8967bbec604eac3a2763387ee43ff6edb9b5fb202210a9df2d8`. Relecture stricte native comprise avant publication et réexécutée sur le résultat final.

### Commandes et preuves terminales

Les argv exacts sont dans les reçus supervisés. L'analyse `dart analyze tool/qa_kanto_combined_bank_01.dart`, la compilation `dart compile exe tool/qa_kanto_combined_bank_01.dart -o B/combined-bank-01`, puis `python3 -B B/run_combined_02.py publish` utilisent les fichiers gelés, le corpus restauré, la qualification r9 et la baseline Source30. Analyse : No issues found, 3,894 s ; AOT : exit 0, 24,520 s. Publication : exit 0 sans timeout en 2 186,785 s, 140 pins avant/après/courants exacts. Cette durée mesure une séquence QA avec plusieurs préparations et une reprise fraîche, pas un benchmark isolé du parcours utilisateur. Reçu `B/publish-run-01.json`, SHA `b1b310d3892f03af17566766895817a5347ccd6beb865f5ae73daaf514728cde`.

`python3 -B B/prepare_runtime_01.py --result B/publication-01/result.json --inventory B/publication-01/published-inventory.json` garde les 33 pins de code/configuration historiques et le harness KAN-03 exact `64894f99fa62e661d06e564641f04c5a117dd1d9729b9daea53f6a6870359b84`. Chaque phase exécute séparément `flutter test --no-pub --concurrency=1 test/qa_kan03_combined_journey_test.dart --reporter expanded` dans `N2/examples/playable_runtime_host` (N2 = B.parent/source/cohort-isolated-02/repository), avec les nouvelles variables `QA_KAN03_PREPARATION`, `QA_KAN03_SAVE_ROOT` et `QA_KAN03_PHASE` de `B/preparation-01.json`.

| Phase sur la sortie enrichie | Résultat | Processus observés et preuve |
|---|---|---|
| Prepare | 1 PASS / 0 SKIP, exit 0, 42,550 s ; 134 états | tester 47215, descendant du runner 47156 ; `runtime-prepare-01.json` |
| Restore dans un second processus | 1 PASS / 0 SKIP, exit 0, 42,755 s ; 133 états | tester 47620, descendant du runner 47471 ; `runtime-restore-01.json` |

Les 43 pins des reçus sont exacts avant/après et encore courants. Le trajet reste celui du Centre : départ QA Route10(13,26), porte physique, marche au PNJ102/14, vrai overlay et texte, retour, sortie par contact contre le terrain bloqué, état A et sauvegarde. Le SHA prepare est celui lu par restore ; l'état froid entier garde seulement l'ajout du jeton natif exact prévu par `saveRestore`, avant toute entrée. Trois demandes SE par phase, six IDs distincts ; aucune audibilité matérielle inférée. Les 1 433 fichiers projet restent inchangés. Les reçus terminalement réussis n'ont aucun signal ni survivant ; les processus protégés restent inchangés.

Qualification runtime `B/qualification-runtime-01.json`, SHA `a2391ad8ca408b1ae9b258ed3580ca614d9f46693d08ccccf07b295fc933edab`. Contre-revue indépendante `B/combined-final-review-01.json`, SHA `388143dd09e1ace536247e26e8fcd3d747a6955c299bb4abe7d0e621cacb3ede` : favorable bornée, aucun P1/P2. Audit/Architecture : mêmes contrats et plan frais ; Implémentation : composition canonique sans changement produit ; Tests : deux trajets sur la nouvelle sortie ; Build/Validation : analyses, AOT et compilation effective du GameWidget ; Critique : fichiers, graphes, PID, hashes et chaîne de sauvegarde relus.

### Livraison, incidents QA et limites

`python3 -B B/deliver_project_01.py` crée deux destinations neuves, exige les références et hashes des qualifications/reçus/logs/pins, compare chaque inventaire complet puis rehash la source. Copie utilisateur : `/Users/karim/Documents/Avelune Converter Studies/Kanto - Route 9 Route 10 Centre et ressources - 20261015/Projet Avelune` ; copie QA Studio : `/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/AC15-combined-bank-20261015-01/Projet modifiable`. Les deux inventaires de 1 433 fichiers sont byte-exacts au projet publié. Reçu `B/delivery-01.json`, SHA `0b518efad29d32d51ade11621952fa469b32146be585562a52c80ecf3112a7ca` ; manifeste identique SHA `ca8cdb578eb60ee8427d068dca2ca2ea2a028918068868d058bf733248381620`. L'ancien dossier utilisateur reste conservé. Contre-revue indépendante après copie `B/delivery-final-review-01.json`, SHA `a283a6f146241d7541dfec4473f14376e831c849b89bc71a4bfa20f5a73fd4f6` : les deux destinations et l'origine sont rehashées intégralement, ainsi que la sauvegarde QA finale, les références et les pins ; favorable bornée sans P1/P2.

Les refus initiaux des comparateurs QA sont préservés avec leurs scripts : métadonnée mode de l'ancien inventaire, permutation des trois décisions complètes, regex de compteur qui prenait une date de chemin pour un échec Flutter, puis ordre des `Path` différent du tri des chemins relatifs. Les corrections vérifient les modes, les records complets distincts, les compteurs de préfixe et les inventaires triés par leur chemin exact ; aucun champ de jeu ignoré, résultat de test modifié ou invariant natif relâché. Aucun refus de copie n'avait créé de destination. Les cinq contre-exemples du parseur vérifient chargement daté, PASS, FAIL et SKIP ; la contre-revue relit aussi absence de test et compte supérieur à un.

Le Studio compatible a été construit sans lancement (51,810 s) ; les trois ibtoold restants, identifiés comme descendants de ce build, ont été terminés normalement après revérification. La session macOS a été relue verrouillée via `ioreg`, sans tentative de déverrouillage ni capture GUI. La copie QA et son dossier de captures sont prêts ; aucune fenêtre n'a été laissée ouverte.

Auto-critique : le cycle visible Studio ouvrir/modifier/peindre/poser/save/cold-reopen, la collision du nouvel arbre, le rendu/son du Player, le départ Source NewGame, les soins, les combats convertis et la traversée Route9→Route10→Centre ne sont pas acquis par ce complément. EVT-04 choix/cancel intégré est identifié séparément par l'audit des 17 lots et reste en qualification. Les 11/44 événements ne constituent pas une couverture du langage Essentials ; 33 quarantaines restent complètes. `sourceAdmission`, `globalPlayabilityCertified` et `goalComplete` restent false. AC-15 reste DOING/PARTIAL dans le ticket existant, grand domaine unique Post Bêta Monde & narration, Gate bêta false. Aucune roadmap FG modifiée. Le commit/push ciblé et l'état final des 96 chemins étrangers seront consignés dans le reçu externe de publication.


## Complément du 15 octobre — Connexion physique Route 9 vers le Centre et reprise

### Audit et périmètre

Audit initial : main `cabb0aa868443b93f55c7af4d6ff885c00d9aded`, index vide et 96 chemins étrangers dont les hashes restent ceux de la publication précédente. Seul ce rapport change dans le dépôt. Les fichiers du jeu et le harness QA restent externes ; aucune modification produit, de schéma, de roadmap ou de comportement d'authoring. J désigne `T/kan-route9-centre-20261015`, avec T défini dans le complément précédent.

Le harness `test/qa_route9_centre_journey_test.dart`, SHA `62971fffa3188c7165abaa4c648aebc39d9c3ed21c638accd94aff9b63296854`, ajoute au parcours KAN-03 trente-sept intentions de déplacement. Départ QA Route9(66,16), deux cases est, une nord, trois est, franchissement est depuis (71,15) vers Route10(0,15), seize est, onze sud et trois ouest jusqu'à (13,26). Le franchissement doit achever une activation `MapActivationReason.connection` avec offset zéro. Les entrées passent par `RuntimeInputEvent` : aucun appel direct de scène, téléportation, changement de position ou chargement intermédiaire ne remplace ce trajet.

Les assertions du Centre restent conservées : contact physique des portes, dialogue exact du PNJ102/14, une ouverture et une fermeture de dialogue, sauvegarde refusée pendant l'interaction, trois demandes SE avec identités distinctes, état persistant strict et sortie par contact contre le terrain bloqué. Le second processus reprend la sauvegarde en Route10, rejoue le Centre et attribue explicitement le passage Route9 au processus précédent ; il ne prétend pas l'avoir rejoué lui-même.

Le contexte privé emploie les sources N2/N4 identiques sur les 31 fichiers Dart de production examinés. Le lock N2 utilise image4.10.1, celui N4 image4.9.1 : aucune identité de lock ni nouvelle résolution de dépendances n'est revendiquée. Les trois hashes de cartes, quatre programmes natifs, résultat de publication et inventaire de 1 433 fichiers restent exacts.

### Exécution réelle et incident conservé

READY01 échoue en 0,699 s avant compilation car son contexte privé ne possède pas `.dart_tool/package_graph.json`. Aucun corps de test ni tester n'avait démarré. READY02 ajoute la copie byte-exacte du graphe N2 (172 packages, SHA `7985a536338139faf512191ff5e0be08e483e3e3ad30562f9ceaa682513c5a67`) et neuf pins, sans modifier le harness, exécuter pub/clean ou toucher N2/N4. Onze fichiers READY01 sont conservés dans `frozen-ready-01/manifest.json`, SHA `9562b8c16da8581842b73399fe82a334a331b7d6ac1cf3a6f3e2e5d380af96bf`.

Préparation exécutée : `J/preparation-ready-02.json`, SHA `540ddc3c43f72d4e50133f64239b1beee9fb80b67536ab48834da59e5b7d336a`. Ses argv complets, variables et 104 pins sont conservés ; le superviseur ajoute la préparation elle-même, soit 105 pins par commande. Chaque phase dispose d'un reçu et d'un log distincts.

| Commande, cwd J | Résultat exact | Reçu et processus |
|---|---|---|
| `flutter analyze --no-pub test/qa_route9_centre_journey_test.dart` | exit 0, No issues found, 8,099 s | `harness-analyze-ready-02.json`, runner57295 |
| `flutter test --no-pub --concurrency=1 test/qa_route9_centre_journey_test.dart --reporter expanded`, phase prepare | exit 0, 1 PASS / 0 SKIP, 69,459 s ; 211 états tracés | `route9-centre-prepare-ready-02.json`, tester57809 descendant57626 |
| même commande, phase restore et nouveau processus | exit 0, 1 PASS / 0 SKIP, 43,478 s ; 133 états tracés | `route9-centre-restore-ready-02.json`, tester58619 descendant58553 |

La sauvegarde prepare SHA `fdfbba0c924487296e1d69371f2a106926740ffcb9513c9cd1b610c5e0f27a8b` est exactement l'entrée restore ; la sauvegarde finale SHA `b7e35f84066a5358b2848fa12505c30ef5ba2a3dfa8044c70f1b874865a4d794` correspond à l'état final. La reprise froide conserve tout l'état, avec seul ajout du jeton natif exact `saveRestore` avant les entrées suivantes. Les deux Warp du parcours rejoué ajoutent ensuite leurs jetons normaux. Les 1 433 fichiers restent inchangés ; 105 pins identiques avant/après et courants, aucun timeout, signal ou survivant, PID protégés inchangés. Aucun son matériel ni fenêtre native déduit des requêtes audio et du GameWidget de test.

### Passes et limites

Audit/Architecture : graphe de collisions, connexion réciproque et contrats des portes examinés. Implémentation : seul harness privé de qualification, aucun code produit changé. Tests : deux parcours terminaux réels avec sauvegarde liée. Build/Validation : analyse fraîche et compilation effective du GameWidget par Flutter, aucun nouveau build complet de Studio nécessaire pour ce rapport. Revue indépendante du delta READY02 `independent-review-ready-02.json`, SHA `4e9ebd86922a0bcc781361891b1087d1e9d41399537b8cc7c3848ecf7be84440` : favorable bornée sans P1/P2. Sa chronologie indique que Root avait déjà lancé analyse et prepare pendant la lecture ; elle n'est pas présentée comme une approbation antérieure. Contrôle Root final `root-qualification-ready-02.json`, SHA `9f18af876e9829c93c45188b35dd5fba077eb6d9c94815bbbd9fc13b9d8c660c`, avec rehash des pins, logs, sauvegarde et inventaire complet.

Contre-revue terminale des deux phases `J/qualification-final-ready-02.json`, SHA `e0b272b1fd6e2fceb75deb6e2600ef0df630ec462dc7046ef111cfbe13ba7e8d` : favorable bornée sans P1/P2. Les trente-sept destinations, la sauvegarde décodée entière, les six identités audio et les 1 433 fichiers sont relus. L'auteur du harness a effectué cette consolidation ; la revue indépendante du code et du delta relève de l'autre agent, et cette séparation est explicite.

Auto-critique : ce trajet qualifie un accès depuis le point QA (66,16), pas le départ original du jeu ni toute l'exploration de Route9. Pickup, sauts, profondeur visuelle, collision du nouvel arbre, peinture dans Studio et son audible restent séparés. Les 33 quarantaines restent complètes. `sourceAdmission`, `globalPlayabilityCertified` et `goalComplete` restent false. Aucune sémantique d'authoring nouvelle : parité MCP nouvelle N/A ; les preuves des transports existants restent celles des lots précédents. AC-15 reste DOING/PARTIAL dans son ticket Post Bêta existant, sans changement de gate. Le reçu de publication consignera SHA, index et conservation finale des 96 chemins étrangers après commit/push ciblé.


## Complément du 15 octobre — Édition et parcours dans la fenêtre native actuelle

### Audit, isolation et build

Audit initial de cette passe : main `dcc8ff00ad26ecfdb04e4f1b771cc823c055753b`, index vide, 101 chemins étrangers recensés dans `G/turn-git-initial-06.json`. G désigne `T/native-gui-20261015-01`. Ce complément modifie seulement l'en-tête courant et la présente section de ce rapport ; aucun code produit, schéma, test versionné, roadmap FG ou média source ajouté. Les anciens résultats restent attribués à leurs révisions.

La première tentative partageait l'identité macOS du Studio humain. Le contrôleur a ciblé les fenêtres de façon ambiguë et la fermeture semble avoir atteint l'autre instance ; ces sessions 01–03 sont exclues de la qualification. Le contexte privé N4 utilise ensuite l'identité `com.yoahnl.pokemap.converterqa.ac15`, le nom et la fenêtre « AC15 Studio QA », un bundle de chemin distinct et son propre conteneur. Aucun sandbox désactivé ni override de lifecycle/input appliqué. Les quatre adaptations privées concernent `dev/spatial_frame_recorder.dart`, `macos/Runner/Configs/AppInfo.xcconfig`, `macos/Runner/Info.plist` et `macos/Runner/MainFlutterWindow.swift` ; elles ne sont pas intégrées au dépôt.

Build exécuté dans `N4/apps/avelune_studio` : `flutter build macos --debug --no-pub -t dev/marionette_main.dart`, avec les deux `--dart-define=MARIONETTE_PROJECT_PATH=...` et `MARIONETTE_CAPTURE_ROOT=...` exacts du reçu `G/studio-build-03.json`. Exit 0 en 48,038 s ; SHA du reçu `90f4d70cf76880f64e20dd1c615022122e8abd91ddc64de7139a277097685aef`. Les deux descendants ibtoold 4226/4227 ont été revérifiés puis terminés normalement ; zéro survivant. Bundle exécuté `G/AC15 Studio QA.app`, exécutable SHA `4a10f614330f1d090003ad45bcfb8dfbd5926d8b7c9a4d563de38d59568b5a9d`.

### TIL-03 et portion Studio de KAN-02 acquises

Projet QA exact : `/Users/karim/Library/Containers/com.yoahnl.pokemap.converterqa.ac15/Data/Documents/Kanto-20261015-03/Projet modifiable`. Depuis les vrais contrôles Studio : sélection « Chemin de terre Kanto », peinture des cellules (22,7), (23,7), (24,7), annulation/rétablissement et Enregistrer. Sélection « Arbre entier Kanto », pose en (27,8), déplacement en (28,8), annulation/rétablissement et nouvelle sauvegarde. Fermeture par le menu natif du PID6322, exit 0, aucun signal ni survivant ; nouvelle instance PID9587 et réouverture de Route 9 avec chemin et arbre retrouvés.

Un seul des 1 433 fichiers diffère : `maps/map_35e885d2ecdb186a86d710638cb63ee105a337b2fce9687956f5c6c4.json`, SHA brut sauvegardé `07343be0822f9be05d7ee2473a5da1412583a5b3d432633c2e0a50656593980a`. Les six anciennes couches, 315 placements et autres champs de map sont identiques. Ajout d'une couche native SmartTile de chemin, trois `field.semanticCells` non vides aux indices 526–528 ; ajout du placement d'arbre `studio-1792053398557780-0` en (28,8). Son `applyCollision=true` ne certifie aucune physique : la définition garde `collisionProfile=null`.

L'inventaire complet des 1 433 fichiers après fermeture est identique après réouverture. La livraison utilisateur originale sous Documents est intégralement rehashée et reste byte-identique à la publication B ; les modifications sont seulement dans la copie QA. Validation externe `G/studio-edit-qualification-05.json`, SHA `72a5a8101cb84c3e71014fe4da452143da153ed08d135a401797ea32e77b1155` ; réouverture `G/studio-cold-reopen-05.json`, SHA `739135ca9b549bb6f0f7b0b1374746b9296e330f193e97befdd4cae5c5b52eb6` ; contrôle livraison `G/user-delivery-after-studio-05.json`, SHA `ae431cf5288a0b78ab2a96aa6c2c2d9151ce79e706ccaf30ce0caa46664af995`.

Les captures sont des PNG du vrai arbre Flutter natif, sans émulation de lifecycle. Sous le dossier `Preuves/recordings` du même conteneur, `take-wJcBBo/frame_000004.png` montre l'arbre enregistré en (28,8) et `take-pgEKEh/frame_000018.png` le chemin et l'arbre après relance. Contre-revue indépendante `G/studio-independent-review-05.json`, SHA `56da3d85d324cb9cac608051a31d42cad3a1adf355540b1272feb403fdd74c57` : 288 PNG rehashés, deux captures inspectées visuellement et tous les fichiers projet relus, verdict favorable borné, aucun P1/P2. Cette réouverture de map n'est pas la reprise de session de revue Converter REV-04.

### Player natif : trajet aller et limites observées

Yoahn a donné le focus à la fenêtre isolée. Les déplacements sont des touches macOS maintenues, avec lecture de la fenêtre entre les étapes ; aucun appel direct de scène, position imposée ou override d'activité. Le départ reste le spawn de prévisualisation Route9(35,22), avec `newGame.enabled=false`. Les coordonnées intermédiaires déduites des repères et du graphe ne sont pas présentées comme des mesures VM.

Le joueur s'arrête contre la paroi sud et devant la Pokéball bloquante. Un dialogue « You put the Burn Heal in your Bag’s Medicine pocket. » est observé puis fermé avec E ; cela ne prouve pas à lui seul le delta persistant du sac ni toute la causalité du pickup. Le détour par le nord franchit le rebord vers le sud, rejoint physiquement Route10, descend au Centre et entre par sa porte animée. L'interaction du PNJ affiche exactement « I heard that ghosts haunt\nLavender Town. », avec E · Fermer.

Prise `take-bIV1fG` du même dossier : 1 146 PNG rehashés. Frames 000101/000102 : avant/après rebord ; 000800 : extérieur Centre ; 000858/000862/000866/000872 : porte fermée, ouverte, seuil puis transition sombre ; 000885 : intérieur ; 001144/001145 : face au PNJ puis texte complet. Aucun PNG aérien exploitable de ce saut : trajectoire, durée et ombre non certifiées. De fines lignes rouges hors de la pièce sur le fond noir sont consignées comme observation visuelle, sans cause diagnostiquée ni certification d'absence d'overlay.

Le superviseur a atteint son délai de 1 800,390 s juste après ouverture du dialogue : `G/studio-session-05.json`, exit −15, SIGTERM limité au PID9587 après revérification de son identité, zéro survivant et protections inchangées. Aucun `metadata.json` finalisé pour cette dernière prise ; aucun timestamp/FPS individuel inventé. La fermeture du dialogue, le retour, la sauvegarde et la reprise Player visibles ne sont pas acquis par cette session interrompue. Les deux processus moteur antérieurs restent une preuve distincte de save/restore.

Contre-revue indépendante `G/player-independent-review-05.json`, SHA `57b99067cea1b2c4a26070a580d501fc67f2ddde5f514f870148706f6de09e48` : pixels, log terminal, transitions et nettoyage relus ; favorable pour le seul trajet aller observé. Ni requête SE ni capture silencieuse ne certifient l'audibilité matérielle. La physique du nouvel arbre, la profondeur complète toit/arbre et SourceNewGame restent ouverts. La connexion et la porte ne certifient ni soins ni combat importé.

### Passes, auto-critique et statut

Audit/Architecture : identités natives, projet exact, spawn et invariants de persistance vérifiés. Implémentation : instrumentation QA privée uniquement ; aucun changement produit. Tests : gestes Studio, diff strict et inventaires ; parcours clavier réel et captures avant/après. Build/Validation : build frais exit 0, fermeture/relaunch Studio, contrôles de processus et hashes. Critique finale : deux contre-revues indépendantes favorables bornées, sans confusion entre GUI, moteur et son matériel.

Parité MCP nouvelle N/A : aucune sémantique d'authoring ajoutée, les contrôles Studio canoniques sont utilisés ; les validations des transports précédents restent séparées. Aucun nouveau test Flutter versionné ni rerun de suites déjà acquises pour ce complément de qualification. AC-15 reste DOING/PARTIAL dans le ticket Post Bêta existant, Gate bêta false ; aucun DONE ni clôture globale. Le reçu externe de publication consignera commit/push ciblé, hygiène Markdown et état final des chemins étrangers.
