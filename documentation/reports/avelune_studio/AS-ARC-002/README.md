# AS-ARC-002 — Socle exécutable et frontières de dépendance

## Résultat livré

Le 19 septembre 2026, `apps/avelune_studio` démarre comme application macOS
indépendante. Le parcours natif a ouvert une fixture réelle générée par le codec
`ProjectManifest`, affiché **Exemple Avelune Studio**, fermé le projet puis quitté
l’application. Le manifeste est resté identique : inventaire, taille, SHA-256 et
date de modification. **53 tests réussis**, analyse sans problème et build debug
réussi. Lot proposé prêt pour revue ; aucun statut Notion modifié.

Ce socle lit l’identité du projet. Il ne charge ni cartes ni assets et ne certifie
pas sa jouabilité. Aucun canevas, écriture du jeu, undo/redo, runtime, audio,
Narrative Studio, export ou 3D n’est livré. Aucun bouton factice.

## Audit initial et décisions

Base technique : les cinq documents AS-ARC-001, commit
`e019b0a60cae474d9676b65b9c9ad026dd37cab5`, branche `main`.
L’[état initial original](evidence/initial-git.txt) est propre : aucune différence
suivie, indexée ou non suivie. Le répertoire cible n’existait pas.
Les règles racine `AGENTS.md`, `codex_rule.md`, l’index des skills et les workflows
pertinents ont été consultés avant implémentation et rapport.

Le brief joint AS-ARC-002 est appliqué comme demande d’implémentation, et corrige
la suggestion précédente de simple clarification des contrats M1. Les six pages
Notion indiquées dans le brief ont été consultées en lecture seule : ticket,
programme V2, architecture, fluidité, sans calques et préparation 3D. Le ticket
était TODO ; il est laissé intact. L’instruction directe interdit toute écriture
Notion ou Git et prévaut sur la traçabilité habituelle du dépôt.

Précisions d’implémentation prises dans ce cadre :

- Un port pur et une projection immutable suffisent ; aucun nouveau domaine vide.
- Un contrôleur Dart avec écouteurs suffit ; aucune bibliothèque d’état ajoutée.
- L’identité ne nécessite que `project.json`, sans snapshot du projet complet.
- Le sélecteur `file_picker` 11.0.3 utilise SPM ; saisie du chemin aussi disponible.
- L’application macOS conserve son sandbox, avec accès utilisateur **read-only**.
- Le SDK Flutter présent a été utilisé, sans installation ni mise à jour globale.
  Aucun gestionnaire de version ni orchestrateur workspace n’a été trouvé.

Les versions originales sont dans [environment.txt](evidence/environment.txt) :
Flutter 3.48.0-0.4.pre beta, Dart embarqué 3.14.0-95.2.beta, hôte macOS arm64.
Le Dart autonome trouvé dans PATH était 3.12.1 ; les commandes Dart exécutées ont
utilisé celui du SDK Flutter découvert. Le minimum déclaré n’est pas une
certification de toutes les versions Flutter intermédiaires.

## Composition et responsabilités

Tous les chemins de code ci-dessous sont relatifs à `apps/avelune_studio/`.

| Zone | Responsabilité réelle |
|---|---|
| `lib/main.dart` | Initialise Flutter et injecte adaptateur/picker ; aucun accès disque au démarrage. |
| `lib/src/bootstrap/studio_app.dart` | Crée une seule session dans `initState`, possède la sortie native et la destruction ; thème/localisation français. |
| `features/project_session/application/project_session.dart` | Port `ProjectSessionPort.open/close`, identité et problèmes de lecture, sans dépendance externe. |
| `features/project_session/application/project_session_controller.dart` | Transitions idle/opening/ready/failed et générations ; libération de la session remplacée ou obsolète. |
| `features/project_session/application/project_session_state.dart` | Projection immutable de l’état observable. |
| `features/project_session/infrastructure/local_project_session_adapter.dart` | Un reader/store ; policy limitée au dossier choisi ; traduction bornée des erreurs ; fermeture ciblée du handle. |
| `features/project_session/infrastructure/native_project_directory_picker.dart` | Sélection native, résultat nullable. |
| `features/project_session/presentation/project_session_screen.dart` | Contrôleur de champ local, abonnement, intentions, attente/annulation, identité et erreurs ; aucun accès authoring. |
| `features/project_session/presentation/project_open_message.dart` | Messages français, sans affichage d’exception technique brute. |
| `shared/design_system/studio_theme.dart`, `studio_controls.dart`, `studio_surfaces.dart` | Tokens sombres, champs/boutons/focus, surfaces et notices réutilisées. |

Les chemins `features/` et `shared/` de la table sont sous `lib/src/`.
L’adaptateur emploie les exports publics de `map_authoring_local.dart` :
`WorkspacePolicy`, `LocalProjectFileReader`, `ProjectOpenService`,
`WorkspaceHandleStore`. `WorkspaceAccessException` est importée explicitement
du barrel public `map_authoring.dart`, exclusivement en infrastructure.
Ni application ni présentation n’importent ce graphe d’I/O. Aucun import `src`
inter-package, aucune dépendance `map_editor`, `map_runtime` ou Flame.

Le service lit/décode le manifeste et retourne son nom réel. Le probe préalable
ne lit pas son contenu ; il distingue notamment manifeste absent et accès refusé.
Les contrôles canoniques de racine et de symlink restent actifs. La fermeture
supprime le handle en mémoire, sans I/O, timer ou watcher. Le store canonique a
une expiration paresseuse ; aucun heartbeat n’est ajouté.

Le scope application possède le contrôleur et l’adaptateur ; le contrôleur possède
la session ouverte. Une ouverture B invalide A. Si A termine ensuite, seul son
handle est libéré. Fermeture/destruction invalident de même les résultats tardifs.
La lecture déjà engagée n’est pas physiquement interrompue ; elle se termine puis
son résultat est rejeté/libéré. Le rebuild ne recrée pas ces propriétaires.

Les futurs documents éditables seront possédés par le scope projet. Leurs commandes
seront des cas d’usage avec ports authoring, et le rendu consommera leurs projections
depuis une future feature de présentation. Aucun contrat vide n’a été créé dans ce
lot ; leurs premiers comportements devront justifier leurs interfaces.

## Fichiers et périmètre

L’[inventaire exhaustif](evidence/source-audit.txt) liste les **58 fichiers** livrés
dans l’application, dont 51 fichiers texte et 7 icônes Flutter générées. Il donne
aussi les tailles de chaque source manuelle : maximum **204 lignes**, aucune au-delà
de 300. Le projet Xcode et le lockfile sont des métadonnées générées, pas des fichiers
de logique soumis à cette granularité.

En plus des 12 fichiers Dart de production décrits ci-dessus :

- `test/application/{project_session_controller_test,project_session_races_test}.dart`
  et `test/support/controlled_project_session_port.dart` : lifecycle/concurrence.
- `test/infrastructure/{local_project_session_adapter_test,local_project_session_errors_test,project_fixture}.dart`
  : filesystem réel, fixtures, identité, erreurs, symlink et non-mutation.
- `test/presentation/studio_app_test.dart` : widgets, composition, clavier,
  dimensions, sélection tardive, attente et régression du champ désactivé.
- `test/architecture/{architecture_boundaries_test,dart_dependency_graph,dart_dependency_graph_test}.dart`
  : dépendances transitives, import/export/part, chemins relatifs et packages,
  auto-tests du garde et granularité.
- `tool/create_example_project.dart` : fixture explicitement nommée exemple,
  codec existant, cible existante refusée ; `tool/run_check.py` : logs originaux,
  vrais codes retour et suivi des processus de chaque commande.
- `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.metadata`, `.gitignore`,
  `README.md` et hôte `macos/` généré : configuration autonome.

Les modifications au template natif sont bornées : titre et dimensions dans
`MainFlutterWindow.swift`, nom produit dans `AppInfo.xcconfig`, accès aux fichiers
sélectionnés en lecture seule dans les deux entitlements. Le projet Xcode,
registrant et schéma utilisent le package SPM généré. Aucune cible mobile/web.

Exception locale documentée : `.gitignore` de cette nouvelle app contient
`!/pubspec.lock` pour livrer sa résolution reproductible malgré l’exclusion racine.
Le `.gitignore` racine et les autres lockfiles n’ont pas changé. Aucune exception
workspace. Les caches `.dart_tool/`, `build/`, plugins/paquets SPM éphémères et
fichiers IDE restent ignorés et ne font pas partie des sources à commiter.

Les seuls autres nouveaux fichiers sont ce rapport et son dossier `evidence/`.
L’audit AS-ARC-001, l’ancien éditeur, tous les packages partagés et les projets
utilisateur sont inchangés. `git diff` est vide car tout le lot est non suivi ;
l’inventaire non suivi est donc la preuve nécessaire, pas un diff vide isolé.

## Commandes et résultats

Les commandes Flutter/Dart suivantes ont été lancées depuis l’application.
Les paires `.txt`/`.json` conservent sortie originale, commande exacte, cwd, dates,
code réel et suivi des processus. Le logger retourne le statut du processus lancé.

| Commande / preuve | Résultat exact |
|---|---|
| `flutter create --empty --platforms=macos --no-pub --org app.avelune --project-name avelune_studio apps/avelune_studio` depuis la racine | exit 0, [sortie](evidence/flutter-create.txt) |
| `flutter pub get` une seule fois | exit 0, [sortie](evidence/pub-get.txt) |
| Dart du SDK : `dart format lib test tool/create_example_project.dart` | exit 0, `Formatted 23 files (2 changed)`, [dernier formatage](evidence/format-final.txt) |
| `flutter analyze --no-pub` | exit 0, `No issues found! (ran in 4.0s)`, [sortie](evidence/analyze-final.txt) |
| `flutter test --no-pub` | exit 0, `00:05 +53: All tests passed!`, [sortie](evidence/tests-final.txt) |
| `flutter build macos --debug --no-pub` | exit 0, `✓ Built build/macos/Build/Products/Debug/Avelune Studio.app`, [sortie](evidence/build-final.txt) |
| `flutter run -d macos --no-pub` | exit 0 après fermeture native, [sortie](evidence/native-run-final.txt) |
| Générateur via `dart run tool/create_example_project.dart` | exit 0, [chemin de fixture](evidence/example.txt) |
| Contrôle SPM, inventaire sources, comparaison fixture | exit 0 chacun : [SPM](evidence/spm-proof.txt), [sources](evidence/source-audit.txt), [fixture](evidence/fixture-after.txt) |
| Hygiène Markdown et contrôle final Git/processus | sorties originales : [hygiène](evidence/markdown-hygiene.txt), [état final](evidence/final-git.txt), [processus](evidence/process-final.txt) |

Répartition des 53 tests : **20 application/concurrence**, **15 infrastructure**,
**8 widgets/composition**, **10 frontières et auto-tests du garde**.
Les tests infrastructure comparent tous les octets et l’inventaire de fixtures,
comptent une seule lecture de `project.json` et référencent une carte absente pour
prouver qu’aucune carte n’est chargée. Les erreurs de permission sont injectées
au port lecteur, pas une certification de toutes les ACL natives.

Les tests rebuild/resize garantissent une seule création et ouverture, et la
destruction libère la session. Les tests de générations déterministes couvrent A
tardif après B, succès/échec tardifs après fermeture et destruction, et l’absence
de notifications à une vue détachée. Taille widget vérifiée : 480 × 360.

### Échecs conservés et correction native

Les RED [session](evidence/session-red.txt), [widgets](evidence/widgets-red.txt),
[adaptateur](evidence/adapter-red.txt) et [focus](evidence/focus-red.txt) ont tous
exit 1 attendu sur le comportement absent. Le premier analyze avait exit 1 :
ancienne syntaxe `FilePicker.platform` et quatre accolades manquantes ; corrigés
en API statique réelle et blocs, sans ignorer de diagnostic. Premier GREEN : 52
tests, puis 53 après la régression native.

Le [premier lancement](evidence/native-run.txt) a réellement crashé au retour du
sélecteur : `-[AXPlatformNodeCocoa startEditing]: unrecognized selector`.
**Son runner Flutter a renvoyé 0 malgré le crash** : ce code n’a pas été retenu
comme succès. La trace du moteur local montre un événement de valeur sur un
TextField désactivé : l’objet natif créé n’est pas le type auquel `startEditing`
est envoyé (`FlutterPlatformNodeDelegateMac.mm:30-58` et
`AccessibilityBridgeMac.mm:163-172` dans les sources du SDK).
Une [issue Flutter au même symptôme](https://github.com/flutter/flutter/issues/151428)
a aussi été consultée ; elle n’est pas une preuve de correction de ce SDK.

Correction strictement locale : le champ quitte l’arbre pendant l’attente, plutôt
que devenir désactivé puis recevoir le chemin choisi. Le focus est relâché ; nom
et emplacement utilisent `SelectionArea` + `Text`, sans champ éditable readonly.
Aucune modification de Flutter, désactivation d’accessibilité ou changement SDK.
Le test ajouté protège la transition ; le second parcours natif confirme le résultat.

L’automatisation a aussi conservé une ancienne référence après redémarrage : erreur
« App quit » sans crash du nouveau processus. Reconnexion du driver, puis parcours
complet sur le PID courant. Aucune réussite déduite de cette erreur transitoire.

## Preuves natives

Manipulation par Computer Use, sans instrumentation de production ni Marionette.
Le skill desktop Marionette a été consulté, mais son prérequis d’instrumentation
n’était pas présent ; le parcours réel a été exercé via l’UI native disponible.

- [Accueil natif](evidence/native-initial.jpg), capture du premier lancement.
- [Projet réellement ouvert](evidence/native-ready.jpg) et [arbre accessible](evidence/native-ready-ax.txt), version corrigée.
- [Projet fermé](evidence/native-closed.jpg) et [retour à l’accueil](evidence/native-closed-ax.txt).
- [Application arrêtée](evidence/native-exit-confirmed.json), après menu **Quit Avelune Studio**.
- [Empreinte avant](evidence/fixture-before.txt) et [après](evidence/fixture-after.txt) :
  un `project.json` de 2687 octets, même SHA-256 et mtime, aucun nouveau fichier.

Captures JPEG natives, ni images générées ni goldens. La première miniature de
Stage Manager et les observations intermédiaires sont conservées sans les prendre
pour une validation visuelle. Le fichier `native-opened-ax.txt` intermédiaire
montre encore l’accueil après le premier échec ; seule la preuve `native-ready`
fait foi pour l’ouverture. `native-exit-apps.json` est l’observation immédiate
avant arrêt ; `native-exit-confirmed.json` confirme ensuite `isRunning: false`.

Le dossier de smoke a été créé isolément dans le temporaire du système. Aucun
projet personnel n’a été utilisé. Le nom affiché est celui du codec sur disque,
différent du nom aléatoire du dossier. La fermeture a été commandée et observée,
pas simulée par un arrêt forcé du runner.

## Revues, limites et état final

Trois passes déléguées ont audité puis implémenté séparément le port/lifecycle,
l’adaptateur public et les gardes de frontières. Deux revues finales indépendantes
n’ont trouvé aucun blocage dans leur périmètre ; leurs réserves étaient la preuve
native encore manquante, le focus visuel non prouvé par le seul test widget, et
l’exemption framework `flutter_*` un peu large dans le garde présentation.
La passe native root a ensuite trouvé le crash décrit plus haut ; une passe
d’investigation indépendante a confirmé sa cause dans les sources moteur, puis
root a corrigé et rejoué tests, analyse, build et parcours natif.

Limites retenues : garde architectural ciblé et non analyseur universel ; lecture
manifeste uniquement ; erreurs disque parfois indifférenciées par le reader public ;
pas de benchmark ni certification mémoire ; pas de validation VoiceOver complète,
du focus visuel natif ou de toutes les tailles natives. La petite fenêtre est
couverte en widget. La qualité artistique du futur éditeur n’est pas acceptée ici.
Les historiques AS-ARC-001 concernant MCP et `environment_actions.dart` n’ont pas
été rejoués ni corrigés et ne sont pas des échecs de ces 53 tests.

Les runners de tests finaux ne laissent aucun descendant possédé. Le suivi du tout
premier RED était moins complet avant prise en compte d’un `exec` du wrapper ;
aucun processus d’identité incertaine n’a été tué. Les builds ont observé des
`ibtoold` Xcode détachés ; ce sont des auxiliaires de build, pas des processus
de session projet. Leur état final est consigné séparément. Aucun kill global.

État final attendu et vérifié dans les preuves : même branche/HEAD, index et diff
suivi vides ; uniquement nouveaux fichiers sous l’app et le rapport AS-ARC-002.
Les journaux Git complets listent aussi les fichiers non suivis. Deux nouveaux
Markdown explicitement demandés ; contrôle avec budget 2. Aucune écriture Git,
aucune mutation Notion, aucun fichier temporaire hors périmètre dans le dépôt.

Prochain comportement proposé après revue : premier document de carte et sa
projection de rendu, avec le ticket et ses critères à confirmer avant travail.
Ce comportement n’a pas été commencé ; arrêt à AS-ARC-002.
