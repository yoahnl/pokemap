# AC-12 — Passage et priorités de rendu

Date : 2026-10-12. Application : `apps/avelune_converter`. Ticket : [AC-12](https://app.notion.com/p/3f7197a7bfa581cc8625dfffa51a2cc5), domaine unique 14, Monde, exploration et narration — Post-bêta, hors gate.

## Résultat et périmètre

Route 9 de la source Kanto est convertie automatiquement par le vrai `ConverterWorkflow`, sans IA et sans exécuter Ruby. Le projet natif contient le personnage original, les collisions du profil cardinal statique et les éléments de décor dont la profondeur est représentable. Il a été ouvert dans un hôte Studio réel, essayé au clavier, renommé, enregistré puis rechargé depuis le disque par un hot restart du hôte debug.

Verdict technique : **PASS pour le sous-ensemble borné, avec gaps explicites et défauts de suites globales conservés**. La qualification de l'ensemble du jeu reste **PARTIAL**. Le ticket est proposé **TO REVIEW** ; `DONE` appartient à la décision de Yoahn. Les 536 transitions non qualifiées sont fermées, jamais comptées comme des comportements fidèles. La conversion complète de Kanto, les événements et les sauts ne sont pas certifiés.

Ce lot répond aux SEM-01 à SEM-04 du kit : règles de sortie et d'entrée, positions fixes d'occlusion, conservation des métadonnées et invariance des priorités mixtes. Aucun modèle, schéma ni moteur cible n'a été étendu. L'autorisation directe de continuer tous les lots et de committer entre eux prévaut sur le non-objectif du kit interdisant le travail implicite sur le lot suivant.

## Audit initial et décisions

État initial : branche `main`, HEAD `297072aa4c36ab5cfa60a593ce800bab5985d224`, index vide, périmètre Converter propre, 261 chemins étrangers modifiés/non suivis. Le reçu initial et son inventaire sont conservés dans l'Evidence Pack. Les commits parallèles `b88fe5107` puis `8d952dc5c` ont fait avancer HEAD pendant cette qualification. Ils ne sont pas des commits AC-12 et n'ont pas été réécrits.

L'audit a identifié la pile littérale, les tables de passage/priorité/terrain déjà normalisées, le writer canonique, la collision booléenne native et l'occlusion par éléments. Conserver les tables ou enregistrer une carte ne prouvait pas leur consommation par le runtime. Une projection bornée et une comparaison sur le projet réellement écrit étaient nécessaires.

L'oracle est l'archive Essentials exacte du corpus Kanto, SHA `3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d`. Les parseurs sûrs ont extrait 10 sections inertes, 188859 octets, depuis 402 sections. Aucun interpréteur Ruby n'a été lancé. Références de l'extraction : `Game_Character` section 44 lignes 237–257 (sortie et entrée opposée), `Game_Map` section 42 lignes 222–246 (pile Z2→Z0, modes, bits, priorité), `TilemapRenderer` section 72 lignes 421–428 et `Game_Character` section 44 lignes 331–342 / `Game_Player` section 46 lignes 33–35 (profondeur). PSDK a été consulté comme comparateur ; il ne remplace pas cet oracle Essentials.

Le profil exige le hash des scripts, le snapshot source et la normalisation attendus. Il admet seulement le joueur normal 1×1, la marche cardinale intra-carte et un état fixé. Il évalue A(direction) puis B(direction opposée), sans OR des couches. Pour cet état statique, les deux extrémités rendent les arcs réciproques ; aucun passage à sens unique n'est inventé à partir d'un masque isolé.

Les métadonnées bush `0x40` et counter `0x80` restent distinctes des bits directionnels. Ledge, Surf, vélo, pont actif, acteur/plugin non attesté et terrain inconnu sont des gaps. Les tags de réflexion 6/16 conservent leurs pixels dans la couche source et restent non certifiés. Les frontières FG-120/129 et FG-180/182 ont été consultées ; aucun statut de roadmap mécanique n'a été changé.

## Fichiers et zones du patch

Les SHA des 17 fichiers sont dans `index.json`. Les sources et le diff Git sont la preuve canonique ; aucun snapshot intégral de code n'est recopié ici.

| Fichier | Zones et impact |
| --- | --- |
| `packages/avelune_converter_core/lib/avelune_converter_core.dart` | Export du contrat sémantique pur. |
| `packages/avelune_converter_core/lib/src/source_semantics.dart` | Enums, profil, cellules et traces ; résolveur de passage lié aux hashes source, refus explicites et ordre de pile. |
| `packages/avelune_converter_core/test/source_semantics_test.dart` | 22 cas : directions/inverses, priorité, arrêt de pile, bits bush/counter, limites, tags et modes non qualifiés. |
| `packages/avelune_converter_adapters/lib/avelune_converter_adapters.dart` | Exports player/composer/projection. |
| `packages/avelune_converter_adapters/lib/src/source_player_character_import.dart` | `SourcePlayerCharacterImporter` ligne 114 ; PBS borné, PNG attesté, frames originales et animations natives. |
| `packages/avelune_converter_adapters/lib/src/source_semantics_projection.dart` | `SourceOcclusionLayout` ligne 14, `SourceCollisionProjection` ligne 77, `SourceSemanticsProjection` ligne 169, `SourceSemanticsProjector` ligne 265 ; barrières, profondeur, retrait des pixels promus, spawn sûr et gaps. |
| `packages/avelune_converter_adapters/lib/src/source_semantic_study_composer.dart` | `SourceSemanticStudyComposer` ligne 11 ; composition automatique et témoins. `SourceSemanticWitnessFiles` ligne 198 ; lecture inerte et quotas cumulés. |
| `packages/avelune_converter_adapters/lib/src/native_project_writer.dart` | Préparation ligne 764, admission/régénération lignes 853–880, consommateurs canoniques lignes 1007–1086, vérification sémantique ligne 1265 ; refus avant staging des mutations/témoins incohérents. |
| `packages/avelune_converter_adapters/lib/src/converter_workflow.dart` | Composition automatique ligne 1204 ; version/rules hash/capabilities AC-12, trois actions Character Studio admises, domaine maps/assets correct. |
| `packages/avelune_converter_adapters/tool/source_semantics_study.dart` | Validation des destinations fraîches ligne 15 et workflow réel ligne 52 ; chemins absolus, ancêtres sans symlink, sorties distinctes/hors source, oracle cardinal. |
| `packages/avelune_converter_adapters/test/source_player_character_import_test.dart` | PNG/PBS malformés, source modifiée, quotas, duplicats, pixels et huit animations. |
| `packages/avelune_converter_adapters/test/source_semantics_projection_test.dart` | Frontières, priorités, alpha/pixels, suppression du doublon, spawn, reflections et validation native des instances. |
| `packages/avelune_converter_adapters/test/source_semantic_study_composer_test.dart` | Source non qualifiée, archive réelle >1 Mio, budget avant lecture, ancêtres symlink, tampering cohérent refusé. |
| `packages/avelune_converter_adapters/test/support/literal_tile_fixture.dart` | Dimensions de fixture configurables pour vérifier la géométrie. |
| `packages/avelune_converter_adapters/test/support/native_writer_fixture.dart` | Approbation utilisant les mêmes domaines maps/assets que le workflow. |
| `apps/avelune_converter/lib/converter_app.dart` | Résumé automatique sans IA ligne 1421, instructions Studio, notice de qualification partielle ligne 1582, observations humaines avant création ligne 1614 et messages précis des gaps. |
| `apps/avelune_converter/test/converter_app_test.dart` | Test opt-in avec archive réelle : les gaps apparaissent avant création ; zéro écriture de staging et source intacte. |

Le personnage source 32×48 est copié pixel par pixel dans des cellules transparentes 64×64, à gauche 16/en haut 16 ; sheet finale 256×256, huit clips idle/walk S/W/E/N. Aucun redessin, resampling ou IA. Le bonus de profondeur utilise la hauteur originale de 48 px, pas le padding. Le timing de prévisualisation 150 ms n'est pas une qualification du timing source.

Les barrières appartiennent à une `TileLayer` vide valide ; la première tentative avec une `ObjectLayer` a été refusée avant staging puis corrigée avec un test de non-régression. Les éléments d'occlusion conservent les pixels et alpha exacts, avec padding transparent et décalage calculé par priorité. Les cellules promues sont retirées de la pile littérale. La substitution `libraryOnly` ne remplace pas une construction à priorités mixtes sans preuve.

Le writer reconstruit la composition et compare exactement artefacts, preuves, bindings et mutations ordonnées avant de créer le staging. Les scripts inertes volumineux sont découpés en chunks bruts ≤262144 octets, avec offsets, ordre et SHA. Les quotas de nombre d'artefacts, JSON, références et octets décodés cumulés sont vérifiés avant reconstruction pour empêcher l'amplification par aliases.

## Conversion et preuve native

Source : `/Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto`. Snapshot : `5bc0f5dd57e70951cb86fe7c71114e983827251830b2b11f23ef2dab48f1c8de`. Le workflow inventorie 383 cartes ; cette étude convertit seulement la source 98, Route 9.

Projet utilisateur : `/Users/karim/Documents/Avelune Converter Studies/Kanto Route 9 - test jouable 20261012/Projet pour Avelune Studio`. Écriture canonique puis relecture native stricte réussies ; source inchangée, IA 0, Ruby exécuté 0, publication false. Révision native `sha256:5ba015f3386dd9dd56e88773c9f5e5edd45f46e936222e6c28c2aa0bfc4dc92b`.

Carte native `map_35e885d2ecdb186a86d710638cb63ee105a337b2fce9687956f5c6c4`, 72×61, cinq layers, 315 instances (295 barrières, 20 éléments d'occlusion), un spawn sûr (35,22), un personnage avec huit clips. Aucun événement/warp/trigger créé. Hash canonique de la carte `17e9afc98e9f3c1cf22240970ed413e4c0a8033527cb865fae95a6022496077e`.

Le harness charge `loadRuntimeMapBundle` depuis le projet réellement écrit et appelle `stepGameplayWorld` pour toutes les 17568 transitions cardinales : **13722 allowed, 3310 blocked, 536 unqualified fermées, zéro différence**. Politique bornée : contact natif 12×8, départs alignés, pas de 32 px. Aucune modification/enrichissement du projet pour faire passer le test.

La copie QA initiale était identique octet par octet au livrable. Dans le vrai Studio debug : Down au spawn reste (35,22), Right atteint (36,22). Aux poses contrôlées (2,6) et (2,8), les captures natives montrent derrière la cime puis devant le bas de l'arbre. Ces poses ne sont pas présentées comme un trajet marchable : l'îlot de la cime n'est pas accessible au clavier.

Renommage par le vrai dialogue Studio en « Route 9 — test AC-12 », sauvegarde puis hot restart/relecture depuis disque. Révision QA `sha256:1884fbed48ba2ff5eb0e3c09ef9235e48fdfdc304ae47efac21eede9e964d2fa`. La comparaison du modèle montre uniquement le nom modifié ; collisions, profondeur, assets et personnage sont conservés. Ce rechargement n'est pas revendiqué comme un nouveau processus OS.

Le bridge d'accessibilité Flutter debug a produit des erreurs d'AXTree après hot restart et des actions sur un ancien nœud ; les actions finales ont utilisé des coordonnées issues de captures fraîches. Ce défaut du harness/bridge n'a pas été corrigé par ce lot et le parcours n'est pas annoncé sans erreurs de log. Les probes finaux confirment session prête, carte non dirty et aucune erreur de chargement projet. La seconde session Studio a été quittée normalement : exit 0, 1914.413 s, zéro signal et zéro survivant.

## Parité d'authoring

API directe, CLI JSONL et MCP lisent strictement le projet original et sa copie éditée : huit types de ressources, 20 requêtes par transport/projet, records identiques, diff de carte limité au nom, source et projets inchangés pendant la lecture. Le catalogue live contient les dix actions requises, dont `characterStudio.character.create`, `characterStudio.animationClip.upsert` et `characterStudio.character.setDefault`. Aucun nouvel endpoint n'est nécessaire : les sémantiques utilisent les éléments/categories et Character Studio canoniques.

Build MCP fraîchement effectué, catalogue `pokemap_describe` vérifié, hash `93f263e48ae35192dde318744dc6cad6e5d21cb0d202d0ea9fe041a6f3fce4eb`. Les deux snapshots de preuve isolent les changements étrangers non commités. Le second snapshot est basé sur HEAD `8d952dc5cc46ad2fe7dd4bc053149caab8e149b2` ; les 31 tests ciblés et les trois transports y passent aussi. Le format 2D v8 est toujours courant/admis par cette base, distinct du format spatial v9.

## Commandes et résultats

Les commandes complètes, cwd, exit codes, durées, SHA des logs, runners, signaux et survivants sont conservés dans `commands.json`. Elles sont exécutées package par package ; aucune CI coûteuse ajoutée.

| Vérification | Résultat exact |
| --- | --- |
| Core RED `dart test test/source_semantics_test.dart` | 5 PASS / 17 échecs attendus sur stubs, exit 1, 10.734 s. |
| Adapters focused après lint, trois nouvelles suites | 31 PASS, exit 0, 18.516 s ; archive réelle et symlink inclus. |
| Core focused après lint | 22 PASS, exit 0, 2.056 s. |
| Core complet `dart test` | 654 PASS, exit 0, 59.663 s ; avant les corrections mécaniques de braces, focused rejoué après. |
| App complète `flutter test --no-pub` | 80 PASS / 1 SKIP, exit 0, 224.862 s ; le test archive réelle est opt-in. |
| App archive réelle, test focused opt-in | 1 PASS, exit 0, 9.787 s. |
| `dart analyze` core/adapters après lint | No issues found, exit 0, 1.278 / 4.107 s. |
| `flutter analyze` app | No issues found, exit 0, 66.501 s. |
| Conversion réelle workflow run3 | exit 0, 150.383 s ; relecture stricte et source inchangée. |
| Probe runtime du vrai projet run2 | 1 PASS, exit 0, 22.432 s ; 17568 arcs, zéro différence. |
| Transports natifs run4 | exit 0, 32.901 s ; API/JSONL/MCP identiques. |
| Intégration HEAD 8d952, trois suites adapters | 31 PASS, exit 0, 22.829 s. |
| Intégration HEAD 8d952, API/JSONL/MCP | exit 0, 28.950 s ; relecture stricte et preuves inchangées. |
| Intégration HEAD 8d952, probe du projet écrit | 1 PASS, exit 0, 20.348 s ; 17568 arcs, zéro différence, aucun enrichissement. |
| `flutter build macos --release --no-pub` | exit 0, 98.318 s ; application réelle copiée et vérifiée, 374 fichiers identiques. |
| MCP `npm run build` | exit 0, 7.060 s ; seconde base build npm exit 0, 2.427 s incluant installation offline. |

La suite complète adapters ne passe pas globalement. Premier run : **453 PASS / 8 SKIP / 1 timeout**, 94.737 s ; test quota IA multiprocessus isolé **1 PASS**, 12.934 s. Second run à concurrence 2 : **452 PASS / 9 SKIP / 2 timeouts**, 520.547 s, dans `local_review_session_store_test.dart` (« two processes cannot publish the same expected stored version » et « two processes creating different IDs keep the global store quota »). Ces deux tests AC-10 inchangés passent isolément : **2 PASS**, 51.663 s. Leur timeout de readiness de cinq secondes reste documenté, pas remplacé par un faux résultat vert.

Suite protocole MCP : **7 PASS / 1 FAIL**, 4.120 s, catalogue de 17 tools alors que le test attend 15. Cet échec a été reproduit sur la base AC-11 antérieure. Aucune réparation MCP hors scope n'est intégrée.

Les trois premiers essais du harness de transports ont échoué sur des assertions erronées de QA (nom d'action et ancienne hypothèse de layers), corrigées dans le harness temporaire. La preuve finale est run4. Les premiers essais de widget ont révélé l'absence des observations dans l'écran de création et une fixture dont l'upper layer masquait le terrain inconnu ; le produit et la fixture ont été corrigés, puis le vrai test est passé.

Le probe opt-in est conservé dans `native_collision_probe.dart`. Pour le rejouer, le copier comme test dans un checkout Studio isolé, puis fournir `AC12_QUALIFICATION`, `AC12_ORACLE` et `AC12_COLLISION_RECEIPT` à `flutter test --no-pub test/ac12_native_collision_probe_test.dart --concurrency=1`. Les deux premières variables désignent les fichiers `qualification.json` et `source-transition-oracle.json` de l'étude réelle ; la dernière désigne un reçu neuf. Le projet source n'est pas enrichi pour cette exécution.

Build produit : `/Users/karim/Project/pokemonProject/apps/avelune_converter/build/ac12-qualified-release/Avelune Converter.app`, binaire SHA `3fb90dbf44db327d7387df60bda606883946594e85da2505c41252858c94cf27`. Ce build utilise la base qualifiée `297072aa4` plus les 17 fichiers AC-12. Il n'est pas présenté comme un build intégral des commits 3D arrivés ensuite. Les warnings Xcode/Keychain existants et une ligne Xcode contradictoire restent dans le log ; Flutter termine avec succès et l'artefact est vérifié. Aucune distribution signée/notarisée ni publication de feed n'est annoncée.

## Passes, processus et critique finale

| Passe | Verdict |
| --- | --- |
| Audit / architecture source | Oracle exact acquis ; profil cardinal statique possible, gameplay complet PARTIAL. |
| Implémentation core / player / projection | Contrats purs, pixels source exacts, barrières/occlusion natives ; limites explicites. |
| Tests | Focused et app passent ; suites complètes adapters et MCP ont les défauts décrits ci-dessus. |
| Build / validation native | Build release, ouverture/playtest/edit/reload Studio et transports acquis ; pas de preuve mobile/distribution. |
| Critique binding finale indépendante | Aucun nouveau P1/P2 dans les 17 pins ; P2 chunks/quotas/symlink/UI levés. |
| Critique post-lint indépendante | 17/17 hashes identiques snapshot/workspace ; quatre fichiers changés, treize identiques ; corrections mécaniques relues, aucun nouveau P1/P2. Pas de diff des octets pré-lint revendiqué car ces sources n'ont pas été conservées. |

Tous les runners ont été supervisés avec identité PID/uid/start/command. PIDs protégés 35037, 6272, 82303, 61161, 28620 laissés tranquilles. Aucun blanket kill. La première session Studio a atteint son timeout de 900 s : seul son runner confirmé a reçu SIGTERM. Le build release a laissé trois `ibtoold` confirmés (89006, 89008, 90600), terminés normalement après vérification d'identité. Les receipts finaux n'ont aucun survivant et les identités protégées sont inchangées ; « zéro signal pour tous les runs » serait faux.

Risques conservés : positions continues entre centres non exhaustivement qualifiées (égalité de profondeur au premier pixel d'une nouvelle ligne), sauts de rebord, états/modes/plugins dynamiques, reflections, timing d'animation source et événements. Les catégories/atlas techniques permettent l'édition native mais ne constituent pas une reconstruction complète de bibliothèques d'objets artistiques. L'étude est une carte ; elle ne certifie pas le voyage entre les régions.

L'état Git avant commit, les SHA étrangers et l'inventaire de fichiers d'Evidence Pack sont dans `index.json`. Seuls les 17 fichiers Converter et cet Evidence Pack sont autorisés dans le commit AC-12. Les changements restants liés au recorder/material spatial sont exclus. Le SHA effectif du commit est enregistré dans Notion après commit ; le document ne revendique pas connaître son propre SHA avant sa création.

Gate documentaire final : `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh`, exit 0, 1.797 s : « Markdown hygiene: 1 new Markdown file(s), all in canonical locations. » Cette borne correspond au rapport unique demandé pour la clôture de lot. `git diff --check` sur les 17 fichiers Converter : exit 0, aucune sortie. Le contrôle de l'index stagé est effectué avant le commit pour inclure aussi les fichiers nouvellement créés.

Suite autorisée : audit AC-13, grammaire étroite d'événements, dernières pages vraies même vides, self-switches par map/event/key, quarantine complète des branches inconnues, choix/cancel et warp connus, preuves EV-A/B/C et save/reload. Aucune évolution du schéma cible ni fidélité 100 % du jeu ne doit être inventée pour fermer ce lot.
