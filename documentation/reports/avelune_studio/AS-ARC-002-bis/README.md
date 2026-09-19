# AS-ARC-002-bis — Préservation de la cible d’ouverture

Le correctif local et les tests sont livrés pour revue. La régression déterministe est reproduite avant correction, puis corrigée : les chemins non préservables sont refusés avant consultation du manifeste. La recette native reste **partielle et non validée**, avec une observation ambiguë conservée ci-dessous. Aucun statut Notion n’a été modifié ; aucune écriture Git n’a été effectuée.

## État initial et périmètre

Travail du 19 septembre 2026 dans `/Users/karim/Project/pokemonProject`, branche `main`, HEAD `a0a6da30d8bc360b96c847c0bc12b0f881ae7902`. Arbre et index initialement propres, sans fichier non suivi. Les commandes originales et versions figurent dans [initial-state.txt](evidence/initial-state.txt).

Sources relues : brief AS-ARC-002-bis, instructions du dépôt, `codex_rule.md`, README application et rapport AS-ARC-002, session Studio et tests, puis lecteur, politique et service d’ouverture partagés en lecture seule. Les rapports AS-ARC-001/002 restent inchangés. Aucun projet utilisateur n’a servi de fixture.

## Cause et décision

Trois nettoyages se cumulaient : `_path.text.trim()` dans l’écran, `directoryPath.trim()` dans l’adaptateur, et `_requirePath` dans le lecteur partagé. Le test RED retourne réellement `Projet témoin sans espace` en demandant le dossier voisin terminé par U+0020 : [neighbor-red.txt](evidence/neighbor-red.txt).

La saisie et le résultat natif restent désormais intacts jusqu’au port. L’adaptateur refuse une valeur différente de son `trim()`, sans employer la valeur nettoyée. Il applique cette garde à l’entrée, puis à la racine canonique autorisée, avant probe ou ouverture du service. Le refus typé `pathNotPreserved` possède un message français ; le champ conserve sa valeur pour correction.

La seconde garde est nécessaire : `MonJeu /` et un alias ordinaire peuvent résoudre vers une racine terminée par un espace. `WorkspacePolicy.create` (ligne 24) et `authorizeProjectRoot` (ligne 39) canonicalisent l’entrée. Ensuite, `probeResource` réutilise la racine et appelle `_requirePath` (lecteur ligne 223). `ProjectOpenService.openProject` réautorise aussi cette racine (ligne 62), puis lit le manifeste (ligne 63), via les chemins nettoyés du lecteur (lignes 266 et 292 ; helper ligne 350). La garde intervient avant ces réutilisations dangereuses.

La canonicalisation légitime reste permise : aucun test d’égalité textuelle entre entrée et racine résolue. Les liens sûrs, accents et espaces internes passent. La politique publique et les protections contre les liens sortants sont conservées. Aucune lecture JSON alternative, aucun handle artificiel, aucune nouvelle abstraction de filesystem.

## Inventaire des changements

Chemins relatifs à `apps/avelune_studio/`. Le [diff complet des sources et tests](evidence/source-diff.txt) inclut les deux nouveaux fichiers via `git diff --no-index` (code 1 attendu pour une différence).

| Fichier | Zone modifiée ou créée | Taille finale |
|---|---|---:|
| `lib/src/features/project_session/application/project_session.dart` | enum `ProjectOpenProblem`, nouveau refus | 32 lignes |
| `lib/src/features/project_session/infrastructure/local_project_session_adapter.dart` | entrée `open`, garde après autorisation, helper de refus | 103 |
| `lib/src/features/project_session/presentation/project_session_screen.dart` | `_open`, retrait du nettoyage du texte | 185 |
| `lib/src/features/project_session/presentation/project_open_message.dart` | message français du refus | 17 |
| `test/infrastructure/project_fixture.dart` | nom de manifeste optionnel distinct du dossier | 76 |
| `test/infrastructure/project_path_identity_test.dart` | nouveau : 7 scénarios réels, lecteur observé, snapshots | 246 |
| `test/presentation/project_path_submission_test.dart` | nouveau : 11 scénarios de transmission et cycle UI | 206 |
| `README.md` | note de limitation locale | — |

Livrables supplémentaires : ce README et `evidence/` du bis. Aucun commentaire, DartDoc ou TODO ajouté au code manuel. Aucun changement dans `packages/**`, dépendances/lockfiles, native/SPM, Player, MCP, formats, contrôleur ou design system.

## Tests et preuves fraîches

Les fixtures réelles créent deux entrées distinctes `MonJeu` et `MonJeu ` et deux manifestes valides via le codec existant. Le lecteur observé délègue au vrai `LocalProjectFileReader` et enregistre **racine + chemin relatif**, pour lectures et probes. Les refus exigent zéro lecture/probe et aucune session retournée. Les snapshots comparent octets, inventaire et cibles des liens.

Couverture filesystem : voisins, dossier risqué isolé, séparateur final, alias vers racine risquée, alias sûr, accents/espaces internes, appel direct entouré d’espaces. Les cas ne sont pas ignorés si le filesystem ne les représente pas : les assertions de distinction échoueraient.

Couverture UI : espaces finaux et périphériques, saisie uniquement composée d’espaces, guillemets, Unicode décomposé/espace insécable et `~` transmis exactement ; résultat natif intact ; champ vide ; annulation préservant session et brouillon ; refus français sans projet prêt/exception brute, correction puis fermeture ; résultat tardif après destruction. Les doubles UI ne constituent pas la preuve filesystem.

Toutes les commandes ci-dessous sont exécutées depuis `apps/avelune_studio`. Chaque paire `.txt`/`.json` conserve sortie originale, arguments, cwd, dates, code retour et processus suivis.

| Preuve | Commande / résultat exact utile | Code |
|---|---|---:|
| [regressions-red](evidence/regressions-red.txt) | `flutter test --no-pub test/infrastructure/project_path_identity_test.dart test/presentation/project_path_submission_test.dart` avant correction : 9 réussites, 8 échecs | 1 |
| [neighbor-red](evidence/neighbor-red.txt) | test voisin ciblé avant correction : `Expected: null`, `Actual: 'Projet témoin sans espace'` | 1 |
| [infrastructure-green](evidence/infrastructure-green.txt) | 7 tests filesystem, `All tests passed!` | 0 |
| [regressions-green](evidence/regressions-green.txt) | les deux fichiers ciblés après correction : 18 tests, `All tests passed!` | 0 |
| [format](evidence/format.txt) | Dart embarqué Flutter, formatage des 7 fichiers Dart du lot : 2 changés | 0 |
| [format-check](evidence/format-check.txt) | mêmes fichiers, `--output=none --set-exit-if-changed` : `Formatted 7 files (0 changed) in 0.03 seconds.` | 0 |
| [tests-final](evidence/tests-final.txt) | `flutter test --no-pub` : `00:06 +72: All tests passed!` | 0 |
| [analyze-final](evidence/analyze-final.txt) | `flutter analyze --no-pub` : `No issues found! (ran in 10.6s)` | 0 |
| [build-final](evidence/build-final.txt) | `flutter build macos --debug --no-pub` : `✓ Built build/macos/Build/Products/Debug/Avelune Studio.app` | 0 |

Les 72 tests comprennent les 53 historiques, les 18 nouveaux et un cas supplémentaire du test existant paramétré sur l’enum. Aucun test historique supprimé, ignoré ou affaibli, aucun timeout augmenté. Le cas UI complet de correction/reprise a été ajouté après RED ; sa première exécution est GREEN, sans prétendre à une preuve RED propre.

SDK inchangé : Flutter `3.48.0-0.4.pre` beta, Dart embarqué `3.14.0-95.2.beta`. Le Dart autonome `3.12.1` a seulement été identifié ; le formatage utilise `/opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart`. Aucun téléchargement ou changement de dépendances. Le build a attendu le verrou de démarrage Flutter lors de commandes concurrentes, puis réussi.

Capture : outil existant `tool/run_check.py`, chargé avec remplacement **en mémoire** du répertoire `AS-ARC-002/evidence` par `AS-ARC-002-bis/evidence`. Son fichier reste inchangé ; aucun nouvel outil de collecte n’est livré. Les tests emploient son option `--reap-tests`. Le [contrôle final des processus](evidence/process-final.txt) retrouve zéro descendant identifié restant pour RED/GREEN, suite finale, analyse, build et lancement natif ; aucun arrêt global n’a été effectué.

## Recette native : réserve explicite

Lancement réel par `flutter run -d macos --no-pub`, journal [native-run.txt](evidence/native-run.txt). Seules les fixtures sous `/private/tmp/avelune-bis-native-uMg3wu/fixtures` ont été ouvertes. Elles ont été créées avec le codec public par un script temporaire hors dépôt : [native-fixtures](evidence/native-fixtures.txt).

Parcours observé : lancement, sortie du plein écran, choix du dossier ordinaire dans le sélecteur natif, affichage de `Projet témoin sans espace` avec sa bonne racine, puis retour à l’accueil après fermeture. Preuves : [capture initiale](evidence/native-initial.jpg), [état AX du projet ordinaire](evidence/native-valid-first-ax.txt), [état AX après fermeture](evidence/native-closed-first-ax.txt).

**Observation non résolue :** après `setValue` du pilote d’accessibilité sur le chemin terminé par un espace, l’arbre AX affichait cette valeur, mais le clic d’ouverture a de nouveau affiché le projet ordinaire. L’[état observé](evidence/native-ax-setvalue-observation.txt) est conservé. Une désynchronisation entre la valeur AX native et le contrôleur Flutter est une hypothèse, pas une cause démontrée. Ce parcours ne prouve donc ni la transmission réelle de la nouvelle chaîne, ni le refus natif ; il empêche de déclarer cette recette validée.

Les tentatives de saisie réelle et reconnexion ont ensuite échoué avec `Computer Use server error -10005: noWindowsAvailable` et `timeoutReached`. Le lancement suivi a terminé par `Lost connection to device.` avec code 0, ce qui **ne prouve pas une fermeture normale ni l’absence de crash**. Aucun nouveau diagnostic Avelune correspondant à cette exécution n’a été trouvé ; cela n’établit pas la cause de la déconnexion. Un autre processus Avelune (PID 62177, parent 1) a été observé ; faute de propriété établie, il n’a pas été terminé.

Manquent donc la capture native du refus, la reprise valide après ce refus, la validation du focus/champ et la fermeture normale finale. À rejouer manuellement sur ces fixtures lorsque le pilote natif est utilisable. La preuve automatisée du vrai adaptateur et celle des widgets sont disponibles séparément ; elles ne remplacent pas cette recette.

La comparaison [avant](evidence/fixture-before.txt) / [après](evidence/fixture-after.txt) des fixtures natives confirme inventaire, SHA-256, tailles et dates de modification identiques. Les tests filesystem vérifient également leurs propres fixtures avant/après.

## Passes, critique et verdict

| Passe | Responsable | Résultat |
|---|---|---|
| Audit initial des frontières et de la chaîne | agent `bis_architecture` | deux gardes locales nécessaires ; aucune modification partagée |
| Régression filesystem | agent `bis_filesystem_tests`, exécution racine | vrai lecteur, mauvaise identité reproduite, 7 cas corrigés |
| Régression UI | agent `bis_widget_tests`, exécution racine | transmission exacte, refus et reprise, 11 cas |
| Implémentation | agent racine | quatre fichiers de production ciblés |
| Tests / analyse / build / recette | agent racine | commandes vertes ; recette native partielle ci-dessus |
| Relecture finale indépendante du code et des tests | agent `bis_architecture` | favorable, aucun défaut actionnable identifié ; ne certifie pas la recette native |

Autocritique : ce lot livre un **refus explicite**, pas le support des noms terminés par un espace. Le lecteur partagé conserve son nettoyage. La protection vise la transformation déterministe identifiée, sans promesse contre toute course filesystem. L’observation native ambiguë demeure une réserve à lever avant acceptation native ; aucun statut DONE n’est revendiqué.

Le [contrôle final Git](evidence/final-git.txt) distingue les six fichiers suivis modifiés, les deux nouveaux tests et le dossier de preuves/rapport. Index et HEAD inchangés ; aucune modification préexistante à préserver. Le [contrôle d’hygiène Markdown](evidence/markdown-hygiene.txt) utilise le budget explicite d’un nouveau document demandé par le lot. Aucun travail sur l’affichage de carte ni lot suivant.

## Rejouer

Depuis `apps/avelune_studio` : `flutter test --no-pub`, `flutter analyze --no-pub`, `flutter build macos --debug --no-pub`, puis `flutter run -d macos --no-pub`. Les preuves JSON fournissent les arguments exacts des ciblages et du formatage. Ne pas renommer les fixtures ni choisir un projet personnel pour compléter la recette.
