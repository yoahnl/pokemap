# AC-02 — Inventaire sûr en lecture seule

Statut technique : **PASS, prêt pour revue humaine**. Le lot produit un inventaire borné, un lecteur macOS et la commande locale `scan`. L’application Flutter reste prévue dans `apps/avelune_converter`. Ce lot ne produit pas encore de projet Avelune.

Le ticket Notion existant est [AC-02 — Inventaire sûr en lecture seule](https://app.notion.com/p/3f6197a7bfa581b990f4efb81008ad9b), rattaché au domaine Monde & narration et à la famille 14 Post Bêta. Il passe à `TO REVIEW` après vérification et commit ; `DONE` reste réservé à Yoahn.

## Gate 0 et audit initial

Demande directe : réaliser les lots du kit avec commits intermédiaires. Yoahn a confirmé le dossier `Downloads/The-PMon-World-Project-main`, avec Kanto comme priorité. Les PID 6272 et 82303 doivent rester intacts.

Base du lot : branche `main`, HEAD `9b7b795d5d3995a22b9a0009f4d22670185fcd07`. L’état initial contient 257 chemins étrangers au lot. Leurs empreintes ont été capturées avant modification et comparées à nouveau avant livraison.

L’audit a établi que le core AC-01 doit rester indépendant de Flutter, du filesystem et de `map_core`. Le port de lecture porte l’IO. La canonisation JSON AC-01, limitée à 4 Mi code units, ne peut pas servir directement à hasher un inventaire de 100 000 entrées. Le hash du manifeste est donc calculé en flux. Un quota cumulé des chemins complète les limites d’entrées, profondeur, octets, probes, diagnostics et preuves de profil.

Le code de case folding Unicode 17 existant dans `packages/map_distribution/lib/src/unicode_case_folding.dart` a servi de source à une table privée pure dans le convertisseur. Aucun import de `map_distribution` ni changement de ce package. Les chemins originaux restent les locators ; NFC + full case folding servent uniquement aux collisions. La version résolue localement de `unorm_dart` est 0.3.3.

L’audit a également écarté des contrôles de chemins avant/après lecture comme seule protection contre les substitutions. Sur macOS, chaque composant descendant est ouvert relativement à un descripteur avec `openat` et no-follow. Le lecteur source ne dispose d’aucune opération d’écriture.

## Périmètre et décisions

- Le scan énumère les répertoires et fichiers, identifie les familles/formats et hashe intégralement tous les fichiers inclus, notamment Data, PBS, scripts, plugins, Graphics et Audio.
- Les exclusions sont appliquées aux segments NFC/foldés et incluses dans la politique hashée. Leurs bytes ne sont pas ouverts. Les exclusions ne certifient pas la source entière.
- Les chemins absolus, traversants, avec NUL/contrôle/backslash/colon ou Unicode invalide sont refusés. Liens, fichiers spéciaux et collisions produisent un inventaire non complet avec locators.
- Les IDs de fichiers dépendent du namespace logique, du chemin original et du type. Ils survivent à une modification des bytes. L’empreinte du snapshot représente le contenu inclus et les faits de scan, indépendamment du namespace et des tokens natifs.
- Les diagnostics bloquants et l’état participent à l’empreinte. Un profil d’inventaire incomplet ne peut pas être confirmé. Une confirmation complète exige accord humain, motif, source hash et evidence hash exacts.
- Le scanner contrôle les quotas avant les lectures, vérifie les volumes réellement reçus et compare un second inventaire. Progression et annulation sont explicites.
- La CLI requiert source absolue, namespace et `--offline`. Elle émet un JSON ou un résumé sur stdout ; elle ne crée pas encore de workspace persistant. Usage invalide : 2 ; scan incomplet/non disponible : 3 ; annulation : 130.

Les références sémantiques contenues dans les données RPG Maker seront décodées par AC-03/AC-04. AC-02 ne prétend pas extraire les noms de tilesets, les événements ou les dépendances sérialisées sans parseur.

## Fichiers et zones

| Fichier | Zone ou responsabilité |
|---|---|
| `packages/avelune_converter_core/lib/avelune_converter_core.dart` | Import de normalisation et parts inventaire/table privée. |
| `packages/avelune_converter_core/pubspec.yaml` | Dépendance pure `unorm_dart`. |
| `packages/avelune_converter_core/lib/src/inventory.dart` | 9 : limites ; 63 : politique ; 134 : port ; 172 : entrée ; 277 : profil ; 337 : snapshot ; 424 : hash en flux ; 494 : chemins ; 551 : observations lazy ; 596 : scanner. |
| `packages/avelune_converter_core/lib/src/source_unicode_case_folding.dart` | Table Unicode 17 privée, 914 lignes, provenant du code interne identifié lors de l’audit. |
| `packages/avelune_converter_core/test/inventory_test.dart` | 114 scénarios SRC-01 à SRC-05, fake stream, quotas, collisions, profils, immutabilité et régressions de critique. |
| `packages/avelune_converter_adapters/pubspec.yaml` | Dépendances core/FFI, sans Flutter. |
| `packages/avelune_converter_adapters/analysis_options.yaml` | Lints recommandés. |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | Export public du port macOS. |
| `packages/avelune_converter_adapters/lib/src/macos_source_tree.dart` | 19 : racine ; 84 : parcours ; 157 : autorisation d’émission ; 178 : lecture ; 278 : token ; 388 : bindings natifs. |
| `packages/avelune_converter_adapters/test/macos_source_tree_test.dart` | 26 tests de filesystem, races, quotas, replay et probe du SDK. |
| `tools/avelune_converter_cli/pubspec.yaml` | Composition args/core/adapters. |
| `tools/avelune_converter_cli/analysis_options.yaml` | Lints recommandés. |
| `tools/avelune_converter_cli/lib/avelune_converter_cli.dart` | Parsing, admission des arguments, scan local, codes de sortie et fermeture du lecteur. |
| `tools/avelune_converter_cli/bin/avelune_converter.dart` | Entrypoint et transmission du code de sortie. |
| `tools/avelune_converter_cli/test/scan_cli_test.dart` | 23 cas, dont invocation réelle de dart run et un cas non-macOS ignoré sur ce Mac. |
| `documentation/reports/converter/AC-02/02_safe_inventory.md` | Rapport consolidé du lot. |
| `documentation/reports/converter/AC-02/commands.json` | Reçus des commandes et preuves source/Git. |
| `documentation/reports/converter/AC-02/index.json` | Manifeste SHA-256, état Git final avant commit et checks de livraison. |

Les sources et le diff Git sont les preuves canoniques. Aucun snapshot Markdown de leur contenu intégral, aucun asset Kanto, aucun cache, lockfile ou binaire généré n’est ajouté.

## Passes et critique indépendante

| Passe | Auteur | Verdict et preuve |
|---|---|---|
| Audit / Architecture | `target_contracts` | Exigences d’identité, quotas, Unicode, profil et confinement définies avant implémentation. |
| Implémentation native | `runtime_contracts` | PASS sur macOS arm64 ; 26 tests et analyse propre. |
| Tests | `test_validation` | RED comportemental observé pour le scaffold puis les contournements et la CLI. Aucun fichier d’implémentation modifié par cette passe. |
| Implémentation core/CLI, Build / Validation | Tom | 345 tests core, 26 adaptateur, 22 CLI + 1 skip ; trois analyses propres ; AOT et Kanto réel. |
| Critique finale indépendante | `target_contracts` | PASS après lecture directe des corrections. Cette passe n’a pas relancé les commandes du parent. |

Quatre findings P2 ont été corrigés avant livraison :

1. Un lien ajouté pouvait laisser la même empreinte et réutiliser un reçu de profil complet. L’état et les faits de refus sont hashés, et les profils incomplets ne sont pas confirmables.
2. Un nœud pouvait être rejoué entre deux lecteurs sur la même racine. Un registre faible privé à l’instance autorise uniquement l’objet effectivement émis comme fichier admissible, avant toute ouverture.
3. Le constructeur public pouvait accepter une collision dans un snapshot complet. Il vérifie maintenant tous les préfixes de chemin, comme le scanner.
4. Les observations de version étaient matérialisées avant le quota. Leur génération est paresseuse et s’arrête au plafond avec un diagnostic.

Les régressions de hash/confirmation/collision ont été observées rouges puis vertes. Le test dense seul vérifie le résultat borné ; la revue du `sync*` atteste le déplacement de la borne avant la matérialisation de tous les DTO.

## Commandes et résultats exacts

Chaque commande Dart est exécutée dans son package. `commands.json` conserve commandes, stdout, codes, durées et descendants des runs supervisés.

| Commande | Résultat |
|---|---|
| Core : `dart pub get --offline` | exit 0 ; unorm_dart 0.3.3 résolu depuis le cache. |
| Core : `dart test --reporter expanded` | exit 0 ; `00:15 +345: All tests passed!` |
| Core : `dart analyze` | exit 0 ; `No issues found!` |
| Adaptateurs : `dart test --reporter expanded` | exit 0 ; `00:00 +26: All tests passed!` |
| Adaptateurs : `dart analyze` | exit 0 ; `No issues found!` |
| CLI : `dart pub get --offline` | exit 0. |
| CLI : `dart test --reporter expanded` | exit 0 ; `00:04 +22 ~1: All tests passed!` |
| CLI : `dart analyze` | exit 0 ; `No issues found!` |
| CLI : `dart compile exe bin/avelune_converter.dart -o /private/tmp/avelune-converter-ac02-01a12c88-5b5pgsvf/avelune-converter` | exit 0 ; exécutable local de 6 207 216 octets. |
| Exécutable : `--help` | exit 0 ; commande scan et paramètres documentés. |
| Exécutable : deux scans Kanto `scan --source … --namespace pmon-world-kanto --offline --json` | exit 0 chacun ; 38.241 s puis 36.083 s sur cet hôte. |

Les RED pertinents : `00:00 +6 -70: Some tests failed.` sur le scaffold ; `00:15 +106 -8: Some tests failed.` sur les contournements core ; `00:00 +0 ~1 -22: Some tests failed.` sur la CLI scaffold. Aucun de ces RED ne provenait d’une erreur de compilation. Une erreur de harness antérieure au premier RED a été corrigée avant la preuve comportementale.

Tous les runs supervisés finaux ont `confirmedSurvivors: []` et `signals: []`. Les PID étrangers, dont 6272/82303, n’ont pas été touchés.

## Preuve Kanto et source inchangée

Source autorisée : `/Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto`, avec le nom Unicode effectivement présent sur disque.

- 24 273 entrées : 24 085 fichiers et 188 répertoires ; 627 480 323 octets de fichiers.
- Aucun lien, fichier spécial, exclusion ou diagnostic observé sur ce corpus.
- Deux snapshots `complete` identiques, y compris les 6 876 031 octets de JSON.
- Hash canonique : `5bc0f5dd57e70951cb86fe7c71114e983827251830b2b11f23ef2dab48f1c8de`.
- Hash des bytes JSON : `f0f9919c56d800a45dd154cb2eab175ad4f36e8a05c7109f32018aabff19e296`.
- Politique : `b3311e2d98bbee76606618e84058e3933983b82bf6937e3beb92722c7a929d36`.
- Métadonnées indépendantes avant/après : `e8d978ec0c595a62d359051af11e0c20dd4d0a2bba4f191dfffa45cac441e2cd`, inchangées.

Le contrôle indépendant inclut structure, type, taille des fichiers réguliers, mtime/ctime en nanosecondes, inode et device, y compris la racine. L’atime est exclu : le filesystem peut le mettre à jour lors d’une lecture. Les deux hashes de contenu identiques et cette comparaison attestent les bytes et l’arborescence observés ; aucune commande n’a écrit dans la source.

Quatre mentions statiques de versions 19.1, 20, 21 et 21.1 apparaissent dans des plugins. Ce sont des indices de compatibilité, pas la preuve de la version du moteur. Le profil reste `requiresConfirmation`, sans sélection implicite. AC-03 devra fournir de meilleures preuves depuis les données sérialisées ; aucun code Ruby n’a été exécuté.

## Parité PokeMap MCP

Évaluation effectuée conformément à `skills/using-pokemap-mcp/SKILL.md`. La nouvelle sémantique concerne l’inventaire d’un format externe dans un logiciel indépendant. Aucun changement de commande Studio, de données natives, de serializer Avelune ou de `map_authoring` n’est introduit.

API directe et CLI : prouvées. Editor et MCP : N/A à AC-02, aucune sémantique d’authoring nouvelle à exposer. Le serveur/catalogue MCP n’a pas changé ; rebuild et live catalog N/A pour ce lot. Les lots d’écriture devront réévaluer cette frontière et utiliser les API natives auditées.

## État Git et livraison

L’état initial complet, les 257 empreintes étrangères et l’état final avant commit sont conservés dans les JSON du lot. Comparaison finale : 257 chemins vérifiés, aucun changement étranger. Seuls les 18 fichiers énumérés ci-dessus sont admis au commit AC-02.

`git diff --check` et l’hygiène Markdown sont vérifiés avant staging. Le budget d’un rapport consolidé correspond au livrable AC-02/Evidence Pack du kit explicitement demandé. Aucun autre Markdown n’est créé. Le SHA du commit et l’état post-commit sont synchronisés dans Notion et le compte rendu du chat.

## Auto-critique, limites et prochaine étape

Le lecteur a une preuve d’exécution sur macOS arm64. La branche x64 est présente et fondée sur le SDK, mais n’a pas été exécutée sur x64 ; Windows/Linux ne sont pas disponibles. Les vérifications par descripteurs et le second parcours ne constituent pas un snapshot global atomique du volume. Les futurs lots doivent revalider les composants utilisés avant écriture.

Le hash ne certifie ni les bytes exclus ni les cibles de liens refusés. Les probes de profil sont bornés et statiques. Une confirmation humaine choisit un profil sans certifier le support des plugins. Aucun parseur Marshal, décodage raster, map convertie, projet ouvrable dans Studio ou parcours Player n’est livré ici.

Le lot peut passer à `TO REVIEW`. Prochain lot autorisé : **AC-03**, décodeur Marshal/Table borné, fixtures originales et données Kanto, sans exécution Ruby source. L’objectif global AC-00 à AC-16 reste actif.
