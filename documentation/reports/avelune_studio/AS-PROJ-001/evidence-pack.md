# AS-PROJ-001 V2 — Evidence Pack

Date : 30 septembre 2026. Base technique : `f559e55c6815844ad0e0c08b2ed661733156e703`, branche `main`, plus diff local non commité. Ticket unique : [AS-PROJ-001](https://app.notion.com/p/3ea197a7bfa5817297c6dece52e32eab).

## Résultat et périmètre

Le gros bouton « Nouveau projet » est intégré sous le titre du panneau **Projets récents** existant. Il ouvre un dialogue Studio en cinq étapes : Informations, Modèle, Paramètres, Destination, Création. Aucun deuxième panneau de récents, aucun nouvel accueil, aucun exporteur ou Player parallèle.

Le modèle jouable crée une carte, son atlas original, un personnage animé, un départ praticable et le contrat New Game actuel. Le projet vide conserve les paramètres et reste explicitement non jouable tant qu’il n’est pas complété. Le choix 16/32/48 est persisté dans la grille, l’atlas et les coordonnées des frames ; `displayScale` reste 2.0, ce choix n’est pas un zoom.

Les brouillons du projet courant restent montés. La création ne les publie pas. Le basculement vers le nouveau projet passe par la garde habituelle ; annuler cette garde conserve le projet initial et le nouveau dossier réellement créé. Une ancienne réponse ne s’ouvre pas dans une autre session.

Aucun commit, staging, push, changement de branche, version, release ou CI déclenchée. Aucun projet original du Train modifié. Aucun commentaire ajouté au code. Aucun contrôle, assertion, test ou timeout affaibli.

## Audit initial et arbitrages

Lecture intégrale de `PROMPT_EXECUTION.md`, lecture des références techniques, inspection visuelle réelle des deux PNG du pack, puis lecture des instructions applicables, `codex_rule.md`, compétences locales et roadmap mécanique. Les références fixent la composition ; elles ne prouvent pas les capacités des modèles.

Gate initial exécuté : `git rev-parse --show-toplevel`, `git branch --show-current`, `git rev-parse HEAD`, `git status --short --untracked-files=all`, `git diff`, `git diff --cached`.

```text
/Users/karim/Project/pokemonProject
main
f559e55c6815844ad0e0c08b2ed661733156e703
?? documentation/reports/ci/post_ci_001_quick_checks_evidence_pack.md
diff et diff --cached vides
```

Le rapport POST-CI-001 non suivi était présent avant le lot ; il est préservé, exclu des sources du lot et n’est jamais utilisé comme preuve de ces changements.

| Besoin | Propriétaire existant | Réemploi | Delta nécessaire | Preuve |
| --- | --- | --- | --- | --- |
| CTA accueil | StudioHomeRecentProjects / hôte session | Layout et récents paresseux | Bouton + callback | Vrai hôte et captures |
| Création | ProjectManifest / ProjectSettings / validateurs | Contrats v8 actuels | Port public pur et service bootstrap borné | Tests direct API et relecture |
| Écriture | JournaledAuthoringTransaction / assets canoniques | Plans, préimages, ledger et store | Réservation OS exclusive d’un nouveau dossier | Collisions, erreurs et fichiers conservés |
| Projet courant | ProjectSessionController / HomeNavigation / gardes workspace | Garde normale de publication | Dialogue conservant le workspace et identité d’origine | Brouillons carte et narratif |
| Destination | Adaptateurs plateforme / bridge natif existant | NSOpenPanel et bookmarks | Grant temporaire parent distinct | Sélecteur macOS réel + handshake contrôlé |
| Jeu | New Game / PlayableMapGame / HubInProcessSessionFactory | Runtime et commandes Player publics | Kit de départ actuel et cohérent | Trois installations et déplacement |
| Distribution | CanonicalGamePackageExportService / map_distribution | Export, inspecteur, installateur et launch resolver | Aucun nouveau format | Source auteur rendue inaccessible |
| Parité | Bootstrap JSONL et MCP | Transport, politique de racines et confirmation opaque | Deux commandes/outils découvrables | Serveur MCP neuf réel |

L’ancien CreateProjectUseCase ne reçoit ni preset de grille ni kit jouable. Il est une référence de comportement ; aucune dépendance Studio → map_editor ou import privé inter-package n’est ajouté. Les primitives communes sont StudioButton, StudioPanel, StudioDraftField et une carte de choix dans le design system. Le contrôleur utilise `map_authoring_project_creation.dart`, façade pure étroite : la façade API historique a des dépendances transitives E/S, conservées hors lot.

L’interdiction directe de commentaires et la demande directe d’une annexe exhaustive priment sur les prescriptions contraires de `codex_rule.md`. L’annexe est un fichier texte séparé, sans récursion du rapport ni copie de secret.

Roadmap : FG-010 / FG-011 sont les repères du démarrage et des choix de début de partie. Le lot prouve un démarrage sans Pokémon ; il ne clôt pas le starter Pokémon ni toute la certification New Game. Aucun statut roadmap modifié.

## Choix techniques et garanties réelles

### Requêtes, fichiers et permissions

Le nom affiché et le nom de dossier sont distincts. Le nom de dossier suggéré cesse d’être régénéré après saisie manuelle. Les erreurs sont rattachées au champ concerné ; les saisies invalides sont conservées.

Le parent natif est utilisé exactement, espaces compris, puis canonicalisé. Un chemin absolu est requis ; un fichier parent, dossier disparu, collision existante, alias redirigé après confirmation ou remplacement tardif sont refusés. Le lecteur partagé ne tronque plus le chemin par `trim()` avant canonicalisation. Un test couvre deux parents homonymes différant par espaces.

La réservation exclusive POSIX `mkdir` / Windows `CreateDirectoryW` protège la collision au dernier instant. La requête est figée. `expectedDestination` est transmis par le contrôleur, pas uniquement par les transports. Les PNG et JSON sont préparés en isolate ; pas d’E/S dans les widgets.

Le grant du dossier parent macOS est distinct des grants des projets ouverts. Lors de l’ouverture, ScopedProjectSessionAdapter acquiert le grant du nouveau projet après mémorisation et avant libération du parent. Ce handshake est testé par le véritable adaptateur avec frontière MethodChannel contrôlée. La recette native ci-dessous utilise l’entrée debug existante et son LocalProjectSessionAdapter : elle ne certifie pas indépendamment la reprise security-scoped de production après redémarrage macOS.

### Annulation et erreurs

Avant la réservation, une annulation acceptée interdit toute écriture. L’opération reste active jusqu’à son nettoyage ; un double lancement reste refusé. Après le passage à l’écriture, elle n’est plus annulable : boutons, fermeture et état l’annoncent.

La transaction n’est **pas** une visibilité atomique de tous les fichiers. En cas d’échec, le nettoyage est limité aux sorties reconnues et non modifiées ; les préimages et résidus de transaction restent inspectables. Une donnée introduite ou modifiée par un autre acteur n’est pas supprimée. Un résidu est annoncé avec son chemin ; aucun faux reçu de succès.

La réservation et les contrôles de révision ne protègent pas contre tout processus hostile remplaçant un ancêtre pendant les appels système. Aucun verrou global de filesystem ou nouvelle garantie d’atomicité n’est annoncé. Une interruption brutale pendant l’écriture peut laisser un résidu transactionnel, jamais prétendument un jeu utilisable.

La création réussie et l’ouverture réussie sont deux états distincts. Une garde annulée, ouverture refusée ou remplacement du propriétaire ne supprime pas le nouveau projet valide et ne prétend pas qu’il est ouvert. Les documents et l’historique du propriétaire initial sont conservés.

### Modèles, ressources et grille

Le kit est original, produit déterministement pour ce lot : sol, chemin et voyageur. Aucun asset du Train, de PSDK, média généré fictif de maquette ou catalogue externe n’est recopié. Le PNG physique et son blob content-addressed ont les mêmes octets et sont déclarés dans le catalogue canonique d’assets.

Le modèle jouable configure le contrat actuel de frame : `sourceAssetId` et rectangles pixels, idle/walk pour les quatre directions. Les tests Player résolvent toutes les frames et vérifient leurs bornes dans les images installées. La carte est de 20 × 15 par défaut ; les réglages avancés modifient les dimensions/defaults, pas le zoom.

Pokémon est explicitement indisponible dans cet amorçage : aucun catalogue, équipe ou starter fictif. `pokemon.enabled=false` et ruleset explicite `pokeMapBetaV1`. Le personnage est requis pour le modèle jouable. Le projet vide ne crée ni carte artificielle ni personnage caché.

### UI et comparaison visuelle

Comparaison réelle aux deux références : symboles, wordmark, tokens, surfaces sombres, accents bleus, densité et panneau de récents existants conservés. La duplication centrale de la planche est volontairement rejetée conformément au mandat. Pas de labels « qualité » sur les presets ni promesse Pokémon non supportée.

Dialogue borné à 960 × 720 avec marges extérieures et pied/en-tête fixes. Corps défilant localement lorsque nécessaire. Aperçu réel secondaire replié en petite largeur ou texte agrandi ; pas de réduction artificielle des polices. Focus et Échap sont explicitement raccordés et testés. Chemins sélectionnables par SelectionArea : cela conserve copie/sélection sans exposer les EditableText readonly qui ont déclenché le crash natif décrit plus bas.

Captures widget du véritable hôte : 1536 × 960, 1280 × 800, 1024 × 640, et 1024 × 640 à 150 %. Elles prouvent un rendu exécuté et des contrôles atteignables ; elles ne valent pas validation artistique indépendante de Yoahn.

## Critères et verdicts

| Critère | Verdict | Preuve / portée |
| --- | --- | --- |
| Gros CTA dans le panneau récents, accueil conservé | PASS | home_creation_entry_test + captures home ; aucun doublon |
| Cinq étapes, saisies conservées, focus et fermeture | PASS | creator_ui_test sur quatre configurations |
| Validation nom/dossier/collision/alias | PASS | tests contrôleur et service ; destination confirmée transmise |
| Annulation acceptée avant écriture / double clic | PASS | Completer beforeReservation ; zéro destination / pas de reçu |
| Écriture engagée non annulable, erreur/residu honnête | PASS | afterReservation et injections transactionnelles |
| Brouillon carte/histoire et garde d’ouverture | PASS | creation_draft_guard_host_test / creation_session_safety_host_test |
| Sauvegarde refusée préserve le brouillon | PASS | Port de sauvegarde refusant au vrai raccordement de garde |
| Résultat tardif pour autre propriétaire | PASS | Service canonique retenu, session remplacée, vraie Future attendue |
| Projet vide paramétré et non jouable | PASS | Tests directs 16/32/48, relecture indépendante |
| Projet jouable autonome, première carte et personnage | PASS | Studio → relecture indépendante → export → installation → Player |
| Grille 16 × 16 | PASS | tileWidth/Height=16 ; atlas 256 × 64 ; déplacement 32 px à scale=2 |
| Grille 32 × 32 | PASS | tileWidth/Height=32 ; atlas 512 × 128 ; déplacement 64 px à scale=2 |
| Grille 48 × 48 | PASS | tileWidth/Height=48 ; atlas 768 × 192 ; déplacement 96 px à scale=2 |
| Paramètres dans paquet, source auteur inaccessible | PASS | Manifeste installé, atlas et frames relus ; source renommée .offline |
| Pokémon prêt à jouer | NON VÉRIFIÉ / NON PROPOSÉ | Option indisponible expliquée ; aucun starter fictif |
| Publication certifiée | NON VÉRIFIÉ | Paquets recette exportés en Test local, contrôles Publication non affaiblis |
| NSOpenPanel + création + premier playtest macOS | PASS | Manipulation native avec parent temporaire hors container |
| Reprise native du bookmark de production après relance | NON VÉRIFIÉ | Handshake MethodChannel contrôlé ; entrée native debug LocalAdapter |
| Windows / Linux natifs | NON VÉRIFIÉ | Branche FFI relue, pas de lancement natif sur ces plateformes |
| Refus OS réel d’un parent sans permission d’écriture | NON VÉRIFIÉ | Erreurs/fichiers conservés testés ; pas de recette ACL native dédiée |
| Parité direct API / CLI JSONL / MCP neuf | PASS | Tests réels, confirmation opaque, trois grilles et racine étroite |
| Serveur MCP configuré déjà vivant | PARTIAL | Catalogue lu ; nouvelles commandes absentes avant rechargement |
| Analyse et build macOS | PASS | Journaux de sources finales |
| Suite Studio / règle des 300 lignes | FAIL | Résultats exacts plus bas, défauts antérieurs prouvés sans assouplissement |
| Acceptation visuelle de Yoahn et Player installé manipulé à la main | NON VÉRIFIÉ | Captures exécutées + recettes automatisées, validation utilisateur restante |

## Recette native réellement exécutée

Flutter épinglé `3.48.0-0.4.pre`, révision `e3005e3402d9cfa2043114c8bc53c59d12e9b98e`, Dart 3.14 beta. Node v26.3.1, npm 11.16.0. SDK global 3.47.5 non modifié. Aucun nouvel essai CI distant.

Entrée native existante :

```bash
cd apps/avelune_studio
/tmp/avelune-flutter-3.48/bin/flutter run --no-pub -t dev/marionette_main.dart -d macos --debug --dart-define=MARIONETTE_PROJECT_PATH=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/as-proj001-native-a8c27d9e-73b5-4925-8fa9-9e09983e7fd7/initial
```

Sur le build debug propre : ouverture du CTA, saisie « Création native 32 », modèle jouable, sélection 32 × 32, NSOpenPanel par le vrai bouton Parcourir, choix du parent `/Users/karim/Downloads/as-proj001-native-evidence-a8c27d9e`, création et ouverture du nouveau projet. Vérification observée du projet actif puis clic réel Tester la carte. Le loader a relu manifeste/carte/assets ; New Game a démarré sur first-map à (10, 7). Le personnage, le sol et le chemin sont visibles dans le runtime monté. Aucune partie d’un projet personnel utilisée.

Projet conservé pour inspection :
`/Users/karim/Downloads/as-proj001-native-evidence-a8c27d9e/création-native-32`.

Deux premières tentatives ont reproduit un crash Objective-C après retour de NSOpenPanel : `-[AXPlatformNodeCocoa startEditing]: unrecognized selector`, avec les chemins en SelectableText. Une tentative sans hot reload reproduit également le problème. Remplacement local de ces affichages readonly par SelectionArea + Text, puis nouveau lancement frais : sélection, création et premier runtime réussis. Le test widget vérifie le maintien de deux SelectionArea et l’absence de SelectableText dans la destination ; il ne simule pas une assertion du moteur macOS. Rapports système : `Avelune Studio-2026-09-30-160957.ips` et `Avelune Studio-2026-09-30-161803.ips` dans DiagnosticReports.

Un échec initial de compilation Swift venait de PCM ignorés/inactifs du build existant. Seul le répertoire confirmé `build/macos/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules` a été retiré. Aucun clean global ni modification de source native pour masquer ce cache. Build normal final réussi.

Captures natives PNG affichées et transmises dans la conversation, distinctes des fichiers widget du pack :
- destination native : 1920 × 1080, 316240 octets, SHA-256 `02fd781a1b0f209390f3d1656da4cdbc83c64c1b7536b5c353b65c33e2614a79` ;
- premier runtime natif : 1920 × 1080, 36556 octets, SHA-256 `9035df3646faf2062ffe5e1ad44dbd52ebfa9233a66017f96d4eb069cfc5cfbc`.

Ces deux bitmaps sont des pièces de conversation ; ils ne sont pas présentés comme des fichiers présents dans captures/. Les fichiers persistants ci-dessous sont identifiés comme captures widget ou Player automatisé.

Session Marionette déconnectée, flutter run terminé normalement avec q. Application installée existante et processus des autres projets laissés intacts. Le projet temporaire et les trois paquets de preuve sont conservés.

## Vérifications et résultats

Toutes les commandes Flutter emploient le SDK ci-dessus. Les commandes de test passent par `/tmp/avelune_merge_flutter_test.py`, qui lance `flutter test --no-pub`, suit le PID du runner et ses descendants, puis ne termine que des reliquats dont la commande et la propriété sont reconfirmées. Aucun kill par nom de processus. Les nettoyages observés des runs finaux n’ont pas trouvé de reliquat.

| Cwd | Commande effective | Résultat exact / log |
| --- | --- | --- |
| Studio | flutter test --no-pub test/project_creation --concurrency=2 | +14 All tests passed!, exit 0, 33.5 s ; as-proj-creator-completion-final.log |
| Studio | flutter test --no-pub test/app/studio_bootstrap_test.dart test/home/recent_projects_test.dart test/project_session/scoped_project_session_adapter_test.dart test/presentation/studio_app_test.dart test/map_workspace/map_tool_strip_state_host_test.dart --concurrency=2 | +27 All tests passed!, exit 0, 19.0 s ; as-proj-studio-quick-final.log |
| Studio | flutter test --no-pub test/game_export --concurrency=2 | +27 All tests passed!, exit 0, 41.5 s ; as-proj-export-regressions-final.log |
| Studio | flutter test --no-pub test/project_creation/creation_draft_guard_host_test.dart --concurrency=1 | +3 All tests passed!, exit 0, 24.0 s ; as-proj-final-result-captures.log |
| Studio | flutter test --no-pub test/architecture --concurrency=2 | +11 -1 Some tests failed., exit 1, 6.3 s ; as-proj-architecture-final.log |
| Studio | flutter analyze --no-pub | No issues found! (ran in 25.7s), exit 0 ; as-proj-studio-analyze-final.log |
| Studio | flutter build macos --debug --no-pub | Built build/macos/Build/Products/Debug/Avelune Studio.app, exit 0 ; as-proj-build-final.log |
| Hub | flutter test --no-pub test/features/installation/as_project_creation_player_e2e_test.dart test/features/installation/avelune_studio_export_player_e2e_test.dart --concurrency=1 | +4 All tests passed!, exit 0, 31.4 s ; as-proj-player-all-final.log |
| Hub | flutter test --no-pub test/release/ci_cost_workflow_test.dart test/release/desktop_platform_release_gate_test.dart test/release/intro_codec_fixture_test.dart test/release/mobile_platform_release_gate_test.dart test/release/performance_observation_workflow_test.dart --concurrency=2 | +12 All tests passed!, exit 0, 7.6 s ; as-proj-quick-hub.log |
| Hub | flutter analyze --no-pub lib test/release | No issues found! (ran in 18.3s), exit 0 ; as-proj-hub-analyze-final.log |
| map_editor | flutter test --no-pub --timeout=2m test/release/github_distribution_workflow_test.dart test/tileset_grid_metrics_test.dart test/map_editing_controller_test.dart --concurrency=2 | +20 All tests passed!, exit 0, 13.2 s ; as-proj-quick-editor.log |
| map_editor | flutter analyze --no-pub lib test/release | No issues found! (ran in 63.6s), exit 0 ; as-proj-editor-analyze-final.log |
| map_core | dart test test/gameplay_roadmap_dashboard_test.dart test/gameplay_roadmap_dashboard_cli_test.dart test/gameplay_roadmap_repository_consistency_test.dart | +33 All tests passed!, exit 0 ; as-proj-core-quick-final.log |
| map_core | dart analyze lib/src/tooling/gameplay_roadmap_dashboard.dart tool/generate_gameplay_roadmap_dashboard.dart test/gameplay_roadmap_dashboard_test.dart test/gameplay_roadmap_dashboard_cli_test.dart test/gameplay_roadmap_repository_consistency_test.dart | No issues found!, exit 0 ; as-proj-core-analyze-final.log |
| map_authoring | dart test test/workspace/project_creation_facade_test.dart test/workspace/project_creation_test.dart test/workspace/project_creation_safety_test.dart test/tooling/project_creation_jsonl_test.dart --concurrency=2 | +28 All tests passed!, exit 0 ; authoring_creation_final.log |
| map_authoring | dart test test/security test/domains/assets/asset_security_test.dart --concurrency=2 | +25 All tests passed!, exit 0 ; authoring_security_tests.log |
| map_authoring | dart analyze | No issues found!, exit 0 ; authoring_final_analyze.log |
| MCP | npm run build / npm run check | exit 0 / exit 0 ; as-proj-mcp-build-final.log / as-proj-mcp-check-final.log |
| MCP | node --import tsx --test test/project_creation.test.ts test/game_export_server.test.ts | 2 tests, pass 2, fail 0, exit 0 ; mcp_project_creation.log |
| Racine | dart format --output=none --set-exit-if-changed sur les 46 fichiers Dart du diff, suivis et non suivis | Formatted 46 files (0 changed), exit 0 |
| Racine | git diff --check | exit 0 ; contrôle final plus bas |

Les trois recettes de création passent par le vrai hôte Studio et l’action de création. L’export est déclenché depuis Accueil et utilise le service canonique, sans construction manuelle d’un paquet dans le test. Le dossier auteur est renommé .offline avant installation et reste inaccessible à son ancien chemin. L’installateur, les contrôles de compatibilité et InstalledGameLaunchResolver ne sont pas simulés. Le Player charge les fichiers installés ; le mouvement fait passer (10,7) à (11,7), avec delta physique grid × displayScale, puis capture un checkpoint. La recette existante dialogue → passage entre cartes reste verte.

La frontière de destination native peut être remplacée dans ces tests ; cela ne remplace ni construction du paquet, ni installation, ni runtime. Les captures Player proviennent d’un vrai GameWidget monté dans un test automatisé. Ce n’est pas une manipulation manuelle de l’application Player installée.

### Échecs intermédiaires conservés et corrections

- Red initial home : CTA absent avant ajout, test en échec.
- Un export des frames a révélé des coordonnées d’animation incompatibles : le kit utilise désormais les rectangles pixels du contrat actuel ; les trois Player installés vérifient toutes les frames.
- Contrôle d’architecture du nouveau contrôleur : import transitif vers filesystem via ancien barrel ; façade pure étroite ajoutée avec test de graphe.
- Erreurs de focus/Échap et scrolling de fixture : corrigées et retestées ; aucune suppression d’assertion.
- Scope macOS : handshake testé rouge puis vert après activation du grant enfant mémorisé.
- Premier run large du créateur : +40 -1, la réponse tardive n’était pas terminée après 30 frames. La fin réelle du port canonique est maintenant attendue par un wrapper traçant ; assertion du reçu inchangée. Le run ciblé final est +14 vert.
- Première suite Studio : +1084 ~3 -27, exit 1, 1105.8 s. Elle précède la dernière correction de protocole du test tardif et n’est pas la preuve finale des sources.
- Un run authoring élargi initial comportait un chemin de test inexistant et un golden antérieur en échec. Il n’est pas utilisé comme commande finale verte.
- Le run authoring +159 précédait les derniers ajouts de redaction JSONL/façade ; la vérification élargie sur sources finales est consignée ci-dessous.

### Baselines indépendantes et contrôles non affaiblis

Une archive git indépendante de f559e55 a été préparée dans /private/tmp, sans checkout/reset ni symlink vers les sources du worktree. Les package_config temporaires ont été ajustés aux URI canoniques /private/tmp après un premier échec tooling lié à /tmp. Aucun source baseline modifié.

UI10 représentatif :
`flutter test --no-pub test/cinematics_ui10_error_recovery_test.dart --concurrency=1`
→ exit 1, +0 -1, 20.9 s. Même MapWorkspaceFailure dans LocalMapWorkspaceAdapter.loadMap:162 → seedUi10Visuals:124 → fixture, **avant pumpWidget**, puis null secondaire test:19. Sources concernées inchangées.

Carte :
`flutter test --no-pub test/presentation/map_inspector_ui02_test.dart test/presentation/map_workspace_journey_test.dart test/map_workspace/map_connection_host_test.dart --concurrency=2`
→ exit 1, +7 -4, 11.6 s : Position 3 / 3 absent, identité placement différente, lien attendu=1/obtenu=0, message de garde absent. Quatre échecs également présents sur HEAD intact.

Architecture Studio : six dépassements de 300 lignes, tous byte-identiques au HEAD initial et hors lot :
- map_editing_commands.dart : 310 ;
- local_map_workspace_adapter.dart : 305 ;
- map_workspace_canvas.dart : 474 ;
- map_workspace_tool_strip.dart : 306 ;
- home_visual_test.dart : 312 ;
- decor_transform_host_test.dart : 389.

Cette preuve de taille est une comparaison mécanique avec git show, pas une exécution Flutter historique de la suite architecture. Tous les fichiers Dart Studio de ce lot sont ≤300 ; le home_screen antérieur de 317 lignes est passé à 288 via extraction de guidance, sans assouplir la règle.

map_authoring sur archive HEAD :
`dart test test/package_boundary_test.dart --concurrency=1` → +7 -2, exit 1 (freezed_annotation absent de l’attendu ; EnvironmentActions 1304 lignes >1300).
`dart test test/tooling/jsonl_worker_test.dart --plain-name 'golden describe and malformed input' --concurrency=1` → +0 -1, exit 1, Regional map absent du golden.
Ces échecs restent ouverts ; aucune règle ou golden n’a été changé pour masquer le lot.

### Vérification finale complémentaire

Sur les **sources finales** :
- `flutter test --no-pub --concurrency=2` : **+1085 ~3 -26: Some tests failed.**, exit 1, **770.1 s**. Runner 14710, 326 descendants tracés, reaped=[] ; log complet [as-proj-studio-full-sources-final.log](logs/as-proj-studio-full-sources-final.log).
- 26 échecs : 21 cinématiques partageant le chargement défaillant de fixture, 4 Carte reproduits sur HEAD intact, 1 règle de taille (six fichiers inchangés). Aucun test de création ne figure dans les échecs. La reproduction historique UI10 porte sur un cas représentatif du même défaut ; les 21 tests n’ont pas chacun été rejoués sur archive.
- Skips existants : **3** ; aucun skip créé pour ce lot.
- `dart test test/workspace test/transactions test/tooling/project_creation_jsonl_test.dart test/tooling/cli_golden_test.dart --concurrency=2` : **+161 All tests passed!**, exit 0 sur sources finales ; [as-proj-authoring-broad-sources-final.log](logs/as-proj-authoring-broad-sources-final.log). Ce run remplace l’antérieur +159 comme preuve élargie.
- Formatage : 46 fichiers Dart du lot suivis/non suivis, zéro changement nécessaire. Analyse Studio, authoring et quick-checks consommateurs sans issue ; build normal macOS debug réussi.
- `POKEMAP_MARKDOWN_MAX_NEW=2 bash tools/scripts/check_markdown_hygiene.sh` : **Markdown hygiene: 2 new Markdown file(s), all in canonical locations.**, exit 0. Le budget de deux comprend le seul rapport AS-PROJ demandé et le rapport POST-CI-001 déjà présent avant intervention ; aucun deuxième rapport AS-PROJ créé.
- `git diff --check` : exit 0 ; zéro commentaire nouveau dans les fichiers manuels créés/modifiés ; les 50 empreintes source correspondent à l’annexe finale.

Liste exacte des tests rouges :
```text
test/cinematics/cinematic_viewport_parity_ui10_test.dart: scrub applies camera and fade while stop restores the work view [E]
test/cinematics/cinematic_spatial_gestures_ui10_test.dart: map clicks and point drag respect pan zoom resize at 16 px [E]
test/cinematics/cinematic_spatial_gestures_ui10_test.dart: map clicks and point drag respect pan zoom resize at 32 px [E]
test/cinematics_ui10_error_recovery_test.dart: UI10 recovers missing actor through real controls and preserves invalid fields [E]
test/cinematics_ui10_responsive_test.dart: UI10 1440.0x900.0 inspector edit keyboard save and reopen [E]
test/cinematics_ui10_spatial_test.dart: UI10 destination uses 16 pixel cells after actual zoom pan and publication [E]
test/cinematics_ui10_responsive_test.dart: UI10 1280.0x800.0 inspector edit keyboard save and reopen [E]
test/cinematics_ui10_spatial_test.dart: UI10 destination uses 32 pixel cells after actual zoom pan and publication [E]
test/cinematics_ui10_responsive_test.dart: UI10 1024.0x640.0 inspector edit keyboard save and reopen [E]
test/cinematics_ui10_widget_test.dart: UI10 full Studio frame early composition with isolated real project [E]
test/architecture/architecture_boundaries_test.dart: fichiers Dart manuels limites a 300 lignes [E]
test/cinematics_ui10_parity_viewport_test.dart: preview camera zoom shake fade uses playback transform and Stop restores author view [E]
test/cinematics_ui10_nested_navigation_test.dart: UI10 nested events → scene → cinematic → dialogue returns to dirty owners [E]
test/cinematics_ui10_nested_navigation_test.dart: UI10 nested stories → scene → cinematic → dialogue returns to dirty owners [E]
test/cinematics_ui10_renderer_test.dart: UI10 real map paints inside a new RepaintBoundary with unbounded recording clip [E]
test/cinematics_ui10_renderer_test.dart: UI10 canonical actor renderer selects walk frames at absolute time and rewinds exactly [E]
test/cinematics_ui10_runtime_test.dart: UI10 real Flame cinematic animates before Scene continuation and restores authoring bytes [E]
test/cinematics_ui10_runtime_test.dart: UI10 leaving real runtime cancels cinematic without continuation or event consumption [E]
test/cinematics_ui10_preview_runtime_parity_test.dart: preview matches real Flame actors camera shake fade at 16x16 reset=false [E]
test/cinematics_ui10_preview_runtime_parity_test.dart: preview matches real Flame actors camera shake fade at 32x24 reset=false [E]
test/cinematics_ui10_preview_runtime_parity_test.dart: preview matches real Flame actors camera shake fade at 32x32 reset=true [E]
test/cinematics_ui10_timeline_gesture_test.dart: UI10 timeline drag reorders and duration handle commits once with undo redo [E]
test/presentation/map_inspector_ui02_test.dart: local stack selects a hidden instance and respects order command limits [E]
test/presentation/map_workspace_journey_test.dart: place move stack undo redo save and runtime return preserve document [E]
test/map_workspace/map_connection_host_test.dart: the real map workspace links and unlinks both borders [E]
test/map_workspace/map_connection_host_test.dart: a draft blocks the link without losing its changes [E]
```

Verdict : **périmètre AS-PROJ-001 utilisable et prêt à revue, certification Studio globale FAIL**. Les réserves historiques, natives et de Publication sont conservées ; aucune preuve de ce lot ne marque un besoin mécanique indépendant DONE.

## Relectures et auto-critique

Trois agents indépendants ont réellement travaillé :
1. creation_audit : audit/architecture et implémentation canonique partagée ; aucun moteur reconstruit ; façade pure et transport bootstrap explicitement bornés. Verdict : tests création/transports verts ; baselines authoring non vertes séparées.
2. creation_player_tests : vrais parcours hôte, propriétaires, réouverture indépendante et Player installé. Verdict : création 16/32/48 + recette dialogue/passage vertes ; pas de combat Pokémon promis.
3. creation_final_review : revue indépendante, défaut de grant macOS détecté et test rouge/vert, propagation expectedDestination vérifiée, baselines UI10 et Carte exécutées. Verdict : aucun blocage AS-PROJ supplémentaire identifié ; réserves historiques non masquées.

Deux passes du même agent principal, clairement non indépendantes : implémentation UI/composition ; build/validation native et Evidence Pack. Cela ne constitue pas cinq agents indépendants.

Auto-critique : le kit est volontairement minimal et son aperçu correspond à son vrai contenu, pas à une illustration de village promettant des assets inexistants. Les tests de session retenue utilisent le service canonique, pas une copie des callbacks du workspace. La revue visuelle personnelle de Yoahn, la reprise native de bookmarks après relance, les plateformes Windows/Linux et la Publication restent ouvertes. La suite complète non verte interdit de qualifier toute la livraison Studio de verte, même si le périmètre création passe. Le serveur MCP persistant doit être rechargé pour exposer le bootstrap ; aucun processus d’une autre session n’a été tué pour obtenir cette mise à jour.

Notion : DOING lors du démarrage réel ; seule la fiche AS-PROJ-001 reçoit les précisions V2, résultats et réserves. TO REVIEW écrit puis relu avec succès à livraison : section « Livraison V2 — 30 septembre 2026 » présente, objectif initial conservé. Jamais DONE, aucun autre ticket/domain/backlog créé ou modifié.

## Inventaire exact du lot et zones

Les 50 fichiers source ci-dessous sont inclus **intégralement** dans [sources-integrales.txt](sources-integrales.txt). Journaux séparés dans logs/ ; aucun rapport recopié dans sa propre annexe. Les chemins longs restent locaux, sans secret de production.

| Fichier | Zones / types principaux | Motif et impact |
| --- | --- | --- |
| `apps/avelune_studio/lib/app/di/project_creation_providers.dart` | exports / raccordement | Composition et port unique de création. |
| `apps/avelune_studio/lib/app/di/providers.dart` | exports / raccordement | Composition et port unique de création. |
| `apps/avelune_studio/lib/app/studio_app.dart` | StudioApp, _StudioAppState | Garde de fenêtre, dépendances et parent natif. |
| `apps/avelune_studio/lib/app/studio_bootstrap.dart` | StudioBootstrap | Garde de fenêtre, dépendances et parent natif. |
| `apps/avelune_studio/lib/features/project_creation/application/project_creation_controller.dart` | ProjectCreationController | Requête figée, générations async, destination confirmée et annulation. |
| `apps/avelune_studio/lib/platform/files/native_project_creation_picker.dart` | NativeProjectCreationPicker | Sélecteur parent et reprise du grant propre au projet. |
| `apps/avelune_studio/lib/platform/files/scoped_project_session_adapter.dart` | ScopedProjectSessionAdapter | Sélecteur parent et reprise du grant propre au projet. |
| `apps/avelune_studio/lib/presentation/features/home/studio_home_guidance.dart` | StudioHomeGuidance | CTA dans le panneau existant ; extraction de guidance sans refonte. |
| `apps/avelune_studio/lib/presentation/features/home/studio_home_hero.dart` | StudioHomeHero | CTA dans le panneau existant ; extraction de guidance sans refonte. |
| `apps/avelune_studio/lib/presentation/features/home/studio_home_projects.dart` | StudioHomeRecentProjects, StudioHomeResume, StudioHomeMapCard | CTA dans le panneau existant ; extraction de guidance sans refonte. |
| `apps/avelune_studio/lib/presentation/features/home/studio_home_screen.dart` | StudioHomeScreen, _StudioHomeScreenState | CTA dans le panneau existant ; extraction de guidance sans refonte. |
| `apps/avelune_studio/lib/presentation/features/project_creation/project_creation_dialog.dart` | ProjectCreationDialog, _ProjectCreationDialogState | Cinq étapes, formulaire local, focus, preview et reçu. |
| `apps/avelune_studio/lib/presentation/features/project_creation/project_creation_preview.dart` | ProjectCreationPreview | Cinq étapes, formulaire local, focus, preview et reçu. |
| `apps/avelune_studio/lib/presentation/features/project_creation/project_creation_progress.dart` | ProjectCreationProgress | Cinq étapes, formulaire local, focus, preview et reçu. |
| `apps/avelune_studio/lib/presentation/features/project_creation/project_creation_stepper.dart` | ProjectCreationStepper | Cinq étapes, formulaire local, focus, preview et reçu. |
| `apps/avelune_studio/lib/presentation/features/project_creation/project_creation_steps.dart` | ProjectCreationSteps | Cinq étapes, formulaire local, focus, preview et reçu. |
| `apps/avelune_studio/lib/presentation/features/project_session/project_session_screen.dart` | ProjectSessionScreen, _ProjectSessionScreenState | Projet courant monté, garde de basculement, identité de session. |
| `apps/avelune_studio/lib/presentation/shared/widgets/buttons/studio_choice_card.dart` | StudioChoiceCard | Cartes de choix et erreur locale de champ. |
| `apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_draft_field.dart` | StudioDraftField, _StudioDraftFieldState | Cartes de choix et erreur locale de champ. |
| `apps/avelune_studio/macos/Runner/StudioProjectAccessBridge.swift` | StudioProjectAccessBridge | Grant parent distinct, NSOpenPanel et libération ciblée. |
| `apps/avelune_studio/test/project_creation/creation_draft_guard_host_test.dart` | _FailingSavePort | Tests du véritable hôte, protocole concurrent et responsivité. |
| `apps/avelune_studio/test/project_creation/creation_session_safety_host_test.dart` | _ObservedCreationPort | Tests du véritable hôte, protocole concurrent et responsivité. |
| `apps/avelune_studio/test/project_creation/creator_ui_test.dart` | exports / raccordement | Tests du véritable hôte, protocole concurrent et responsivité. |
| `apps/avelune_studio/test/project_creation/home_creation_entry_test.dart` | exports / raccordement | Tests du véritable hôte, protocole concurrent et responsivité. |
| `apps/avelune_studio/test/project_creation/project_creation_controller_test.dart` | exports / raccordement | Tests du véritable hôte, protocole concurrent et responsivité. |
| `apps/avelune_studio/test/project_session/scoped_project_session_adapter_test.dart` | _RecordingProjectSessionPort | Tests du véritable hôte, protocole concurrent et responsivité. |
| `apps/avelune_studio/test/support/project_creation_workspace_fixture.dart` | ProjectCreationWorkspaceFixture, _CreationIo, _SessionIo, _CreatedWorkspace, _CreatedWorkspaceState, CreationStudioAssets | Tests du véritable hôte, protocole concurrent et responsivité. |
| `apps/pokemap_hub/test/features/installation/as_project_creation_player_e2e_test.dart` | exports / raccordement | Création Studio réelle, export canonique, installation et Player. |
| `apps/pokemap_hub/test/features/installation/as_project_creation_player_support.dart` | exports / raccordement | Création Studio réelle, export canonique, installation et Player. |
| `packages/map_authoring/bin/pokemap_authoring.dart` | _CliOptions, _CliUsageException | Composition CLI sans faux workspace. |
| `packages/map_authoring/lib/map_authoring.dart` | exports / raccordement | Façades publiques de contrats et composition locale. |
| `packages/map_authoring/lib/map_authoring_api.dart` | exports / raccordement | Façades publiques de contrats et composition locale. |
| `packages/map_authoring/lib/map_authoring_local.dart` | exports / raccordement | Façades publiques de contrats et composition locale. |
| `packages/map_authoring/lib/map_authoring_project_creation.dart` | exports / raccordement | Façades publiques de contrats et composition locale. |
| `packages/map_authoring/lib/src/ports/exclusive_project_directory.dart` | exports / raccordement | Réservation OS exclusive et identité exacte du chemin natif. |
| `packages/map_authoring/lib/src/ports/project_file_reader.dart` | WorkspaceAccessException, ProjectResourceIdentity, ProjectResourceProbeStatus, ProjectResourceProbe, class, class, class, class, class, LocalProjectFileReader | Réservation OS exclusive et identité exacte du chemin natif. |
| `packages/map_authoring/lib/src/tooling/jsonl_worker.dart` | JsonlWorker, _CapabilityInput, _WorkerRequestException, _UnsupportedWorkerCommand | Commandes JSONL bootstrap et nettoyage/timeout sans faux arrêt d’écriture. |
| `packages/map_authoring/lib/src/workspace/local_project_creation_service.dart` | LocalProjectCreationService | Bootstrap borné, modèle original, prévisualisation et transaction canonique. |
| `packages/map_authoring/lib/src/workspace/project_creation_atlas.dart` | exports / raccordement | Bootstrap borné, modèle original, prévisualisation et transaction canonique. |
| `packages/map_authoring/lib/src/workspace/project_creation_bootstrap_api.dart` | class, ProjectCreationBootstrapApi, _PreparedCreation | Bootstrap borné, modèle original, prévisualisation et transaction canonique. |
| `packages/map_authoring/lib/src/workspace/project_creation_contracts.dart` | ProjectCreationTemplate, ProjectCreationPhase, ProjectCreationCheckpoint, ProjectCreationRequest, ProjectCreationCancelled, ProjectCreationReceipt, ProjectCreationException, class | Bootstrap borné, modèle original, prévisualisation et transaction canonique. |
| `packages/map_authoring/lib/src/workspace/project_creation_kit.dart` | ProjectCreationKit | Bootstrap borné, modèle original, prévisualisation et transaction canonique. |
| `packages/map_authoring/lib/src/workspace/project_creation_transaction.dart` | exports / raccordement | Bootstrap borné, modèle original, prévisualisation et transaction canonique. |
| `packages/map_authoring/test/tooling/project_creation_jsonl_test.dart` | exports / raccordement | Contrats purs, sécurité, préimages, fichiers et transport réel. |
| `packages/map_authoring/test/workspace/project_creation_facade_test.dart` | exports / raccordement | Contrats purs, sécurité, préimages, fichiers et transport réel. |
| `packages/map_authoring/test/workspace/project_creation_safety_test.dart` | exports / raccordement | Contrats purs, sécurité, préimages, fichiers et transport réel. |
| `packages/map_authoring/test/workspace/project_creation_test.dart` | exports / raccordement | Contrats purs, sécurité, préimages, fichiers et transport réel. |
| `tools/pokemap_mcp/src/server.ts` | PokeMapMcpServerDependencies | Deux outils bootstrap, découverte et vraie chaîne MCP → JSONL → service. |
| `tools/pokemap_mcp/src/tools/project_creation.ts` | exports / raccordement | Deux outils bootstrap, découverte et vraie chaîne MCP → JSONL → service. |
| `tools/pokemap_mcp/test/project_creation.test.ts` | exports / raccordement | Deux outils bootstrap, découverte et vraie chaîne MCP → JSONL → service. |

Le diff des fichiers suivis est fourni dans [diff-suivi.txt](diff-suivi.txt). Pour les nouveaux fichiers, l’annexe intégrale et le registre d’empreintes couvrent le contenu non suivi que git diff ne peut pas montrer.

## Captures, paquets et empreintes

Les captures information/model/settings/destination proviennent du véritable hôte Studio widget, exécuté avec les polices desktop. home montre le CTA à son emplacement réel. creation-result-preserved-project montre le reçu de B après annulation de basculement et conservation de A ; creation-opened-map montre la carte B ouverte après décision explicite. player-created-* montre le GameWidget du Player installé pendant les trois tests, pas une application native Player manipulée manuellement.

[Accueil](captures/home-1536-960-1.0.png) · [Paramètres](captures/settings-1536-960-1.0.png) · [Destination à 150 %](captures/destination-1024-640-1.5.png) · [Résultat conservé](captures/creation-result-preserved-project.png) · [Carte ouverte](captures/creation-opened-map.png).

Paquets réellement exportés et installés :
[16](packages/created-16.avelunegame) · [32](packages/created-32.avelunegame) · [48](packages/created-48.avelunegame).
Le manifeste du paquet et les fichiers d’atlas ont été inspectés après construction ; leur grille est identique à celle de l’auteur.

| Fichier | Dimensions / contrat | Octets | SHA-256 |
| --- | --- | ---: | --- |
| `captures/creation-opened-map.png` | 1536 × 960 | 93977 | `c940852b155f289bb30c7a8abe3350e1b9a118dc1610c5637b044a0470a0e7ce` |
| `captures/creation-result-preserved-project.png` | 1536 × 960 | 178879 | `e6a69a509d92aa08ca6be21602926152b86e96d6743b08d8c0b0c66edc1a5e08` |
| `captures/destination-1024-640-1.0.png` | 1024 × 640 | 97361 | `d484ead8a2c437e163ea0584bfd61d886bfb7f59bd3207a80ae94a4b6b677356` |
| `captures/destination-1024-640-1.5.png` | 1024 × 640 | 91772 | `43aa484540f693f6be45045386b95b635b125630aaa995760f185b3cd95e6bfb` |
| `captures/destination-1280-800-1.0.png` | 1280 × 800 | 130481 | `52beb4aef6703143570ab947774c6d7d8c53d5a32821f96e8ffa0e9dd469269b` |
| `captures/destination-1536-960-1.0.png` | 1536 × 960 | 177451 | `a818da32039c371145a46f8d1abf79560b444f0b6a7e36b3d5b2e43040300d8f` |
| `captures/home-1024-640-1.0.png` | 1024 × 640 | 315181 | `e8d093b6b26ee80fa7994b4dbf88e4d74554c35d5c88264d2a539554e8e9c362` |
| `captures/home-1024-640-1.5.png` | 1024 × 640 | 369025 | `de5cfd8248328c9ff5466edea1c9e0d81f3846ae8b825c6fd28a959f738d6424` |
| `captures/home-1280-800-1.0.png` | 1280 × 800 | 303307 | `d5502dda7cacfcff04ad182afb49ad19da1ce1df97fe852f7e6cbd54f4e64de0` |
| `captures/home-1536-960-1.0.png` | 1536 × 960 | 405536 | `cbe896fb4635c9522ef3bca9925ccbbcef75da1c440030c2b6313ce0332174cd` |
| `captures/information-1024-640-1.0.png` | 1024 × 640 | 64511 | `5052f17391e29496bd6b83c94d8422cfe64b33030971d2570a63b3e36ad6bd49` |
| `captures/information-1024-640-1.5.png` | 1024 × 640 | 71328 | `a079c0a1231ebb5f070a9feae5605c1a1de7ee864457b04ab82242aac9abce45` |
| `captures/information-1280-800-1.0.png` | 1280 × 800 | 91854 | `b7455e9814e02a36b8c24f70ebc64bdeb26f06f67b508c54b6f9ba0311ec655a` |
| `captures/information-1536-960-1.0.png` | 1536 × 960 | 137643 | `ada534b0782d09266b7ffea414efa2f139d3bb75b454567744c65d0ccfb05cb9` |
| `captures/model-1024-640-1.0.png` | 1024 × 640 | 78805 | `f5cc1f1dc02ee1cb31b0c0a0955a2f31b917d303be592b3d8db4133a92487bbb` |
| `captures/model-1024-640-1.5.png` | 1024 × 640 | 92787 | `1ad5bbbc2d72b009caafc02970072002603c801e8ef6cc0ff92be485432327e1` |
| `captures/model-1280-800-1.0.png` | 1280 × 800 | 106247 | `94f540da3628d862ec4a646c948e93b9fbe0cc191f7d57eaba5a1f1b55ed32dc` |
| `captures/model-1536-960-1.0.png` | 1536 × 960 | 152289 | `9e9443509245c351f0a29e79bfd4ad1d7daa685c45a618af2f68d6a89d0bebd7` |
| `captures/player-created-16.png` | 1536 × 960 | 12884 | `08999ead124563734fd5cbf55f3a021f130eb650cce9ffab4386914c42a464ad` |
| `captures/player-created-32.png` | 1536 × 960 | 12889 | `e8b0aa0976c13307cc9cce19e94851e5baee5b7343a5f1946e30f7112ea9404d` |
| `captures/player-created-48.png` | 1536 × 960 | 12290 | `806fbcf69ff5dfa8db0a2121f9489de1b24da29b7d74e054d4912b021504dd14` |
| `captures/settings-1024-640-1.0.png` | 1024 × 640 | 82343 | `0c2d3af423344ae0ef5f052c1d0c8c8839a0b74d739dc713c0a4f686396ab62b` |
| `captures/settings-1024-640-1.5.png` | 1024 × 640 | 80582 | `0bec661a9e9042bf076b6919edf367fc8c5e9efaef219d57f7b133e453db0bf5` |
| `captures/settings-1280-800-1.0.png` | 1280 × 800 | 126461 | `dc2e9be2038085331b7ada37e72ebc55682462fa9ad1605e45fd3e2c1b07e076` |
| `captures/settings-1536-960-1.0.png` | 1536 × 960 | 172747 | `e20a5d85ade4c3c9b4398341bd7dd704cfc3772b76e5667b594837687f0dcf15` |
| `packages/created-16.avelunegame` | paquet 16 px ; atlas 256 × 64 ; displayScale=2 | 12385 | `2eab934c5b866815312fa92e0197ab87cdb848c19a433e8395da6d68d62e702c` |
| `packages/created-32.avelunegame` | paquet 32 px ; atlas 512 × 128 ; displayScale=2 | 13278 | `002ce8b02d3d88e1842f2031af42613c628be592dc97252166ca1b7aa3738702` |
| `packages/created-48.avelunegame` | paquet 48 px ; atlas 768 × 192 ; displayScale=2 | 14414 | `71c95efc3bdf26a66ef6c724afde1d7a903b7a7ae243d56a590d798711c70949` |

## État Git et hygiène finale

Le HEAD et la branche restent inchangés. Index non modifié. 18 fichiers suivis modifiés : 299 insertions, 70 suppressions ; 32 sources nouvelles complètent les 50 fichiers du lot. Les fichiers de preuves non suivis sont listés ci-dessous. Le rapport POST-CI-001 est la seule modification préexistante, préservée.

Sortie exacte de `git status --short --untracked-files=all`, suivie de `git diff --stat` :

```text
 M apps/avelune_studio/lib/app/di/providers.dart
 M apps/avelune_studio/lib/app/studio_app.dart
 M apps/avelune_studio/lib/app/studio_bootstrap.dart
 M apps/avelune_studio/lib/platform/files/scoped_project_session_adapter.dart
 M apps/avelune_studio/lib/presentation/features/home/studio_home_hero.dart
 M apps/avelune_studio/lib/presentation/features/home/studio_home_projects.dart
 M apps/avelune_studio/lib/presentation/features/home/studio_home_screen.dart
 M apps/avelune_studio/lib/presentation/features/project_session/project_session_screen.dart
 M apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_draft_field.dart
 M apps/avelune_studio/macos/Runner/StudioProjectAccessBridge.swift
 M apps/avelune_studio/test/project_session/scoped_project_session_adapter_test.dart
 M packages/map_authoring/bin/pokemap_authoring.dart
 M packages/map_authoring/lib/map_authoring.dart
 M packages/map_authoring/lib/map_authoring_api.dart
 M packages/map_authoring/lib/map_authoring_local.dart
 M packages/map_authoring/lib/src/ports/project_file_reader.dart
 M packages/map_authoring/lib/src/tooling/jsonl_worker.dart
 M tools/pokemap_mcp/src/server.ts
?? apps/avelune_studio/lib/app/di/project_creation_providers.dart
?? apps/avelune_studio/lib/features/project_creation/application/project_creation_controller.dart
?? apps/avelune_studio/lib/platform/files/native_project_creation_picker.dart
?? apps/avelune_studio/lib/presentation/features/home/studio_home_guidance.dart
?? apps/avelune_studio/lib/presentation/features/project_creation/project_creation_dialog.dart
?? apps/avelune_studio/lib/presentation/features/project_creation/project_creation_preview.dart
?? apps/avelune_studio/lib/presentation/features/project_creation/project_creation_progress.dart
?? apps/avelune_studio/lib/presentation/features/project_creation/project_creation_stepper.dart
?? apps/avelune_studio/lib/presentation/features/project_creation/project_creation_steps.dart
?? apps/avelune_studio/lib/presentation/shared/widgets/buttons/studio_choice_card.dart
?? apps/avelune_studio/test/project_creation/creation_draft_guard_host_test.dart
?? apps/avelune_studio/test/project_creation/creation_session_safety_host_test.dart
?? apps/avelune_studio/test/project_creation/creator_ui_test.dart
?? apps/avelune_studio/test/project_creation/home_creation_entry_test.dart
?? apps/avelune_studio/test/project_creation/project_creation_controller_test.dart
?? apps/avelune_studio/test/support/project_creation_workspace_fixture.dart
?? apps/pokemap_hub/test/features/installation/as_project_creation_player_e2e_test.dart
?? apps/pokemap_hub/test/features/installation/as_project_creation_player_support.dart
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/creation-opened-map.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/creation-result-preserved-project.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/destination-1024-640-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/destination-1024-640-1.5.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/destination-1280-800-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/destination-1536-960-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/home-1024-640-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/home-1024-640-1.5.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/home-1280-800-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/home-1536-960-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/information-1024-640-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/information-1024-640-1.5.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/information-1280-800-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/information-1536-960-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/model-1024-640-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/model-1024-640-1.5.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/model-1280-800-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/model-1536-960-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/player-created-16.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/player-created-32.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/player-created-48.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/settings-1024-640-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/settings-1024-640-1.5.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/settings-1280-800-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/captures/settings-1536-960-1.0.png
?? documentation/reports/avelune_studio/AS-PROJ-001/diff-suivi.txt
?? documentation/reports/avelune_studio/AS-PROJ-001/empreintes-sources.txt
?? documentation/reports/avelune_studio/AS-PROJ-001/evidence-pack.md
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-architecture-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-authoring-broad-sources-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-build-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-core-analyze-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-core-quick-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-creator-completion-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-creator-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-editor-analyze-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-export-regressions-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-final-result-captures.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-home-red.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-hub-analyze-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-map-families-head-f559e55-baseline.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-mcp-build-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-mcp-check-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-player-all-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-quick-editor.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-quick-hub.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-scoped-green.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-scoped-red.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-studio-analyze-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-studio-full-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-studio-full-sources-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-studio-quick-final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/as-proj-ui10-head-f559e55-baseline-retry.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/authoring_boundary_tests.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/authoring_creation_final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/authoring_creation_jsonl_final.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/authoring_final_analyze.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/authoring_final_tests.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/authoring_head_boundary.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/authoring_head_golden.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/authoring_security_tests.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/mcp_project_creation.log
?? documentation/reports/avelune_studio/AS-PROJ-001/logs/native_fixture_bootstrap.log
?? documentation/reports/avelune_studio/AS-PROJ-001/packages/created-16.avelunegame
?? documentation/reports/avelune_studio/AS-PROJ-001/packages/created-32.avelunegame
?? documentation/reports/avelune_studio/AS-PROJ-001/packages/created-48.avelunegame
?? documentation/reports/avelune_studio/AS-PROJ-001/sources-integrales.txt
?? documentation/reports/ci/post_ci_001_quick_checks_evidence_pack.md
?? packages/map_authoring/lib/map_authoring_project_creation.dart
?? packages/map_authoring/lib/src/ports/exclusive_project_directory.dart
?? packages/map_authoring/lib/src/workspace/local_project_creation_service.dart
?? packages/map_authoring/lib/src/workspace/project_creation_atlas.dart
?? packages/map_authoring/lib/src/workspace/project_creation_bootstrap_api.dart
?? packages/map_authoring/lib/src/workspace/project_creation_contracts.dart
?? packages/map_authoring/lib/src/workspace/project_creation_kit.dart
?? packages/map_authoring/lib/src/workspace/project_creation_transaction.dart
?? packages/map_authoring/test/tooling/project_creation_jsonl_test.dart
?? packages/map_authoring/test/workspace/project_creation_facade_test.dart
?? packages/map_authoring/test/workspace/project_creation_safety_test.dart
?? packages/map_authoring/test/workspace/project_creation_test.dart
?? tools/pokemap_mcp/src/tools/project_creation.ts
?? tools/pokemap_mcp/test/project_creation.test.ts
 apps/avelune_studio/lib/app/di/providers.dart      |  1 +
 apps/avelune_studio/lib/app/studio_app.dart        |  6 ++
 apps/avelune_studio/lib/app/studio_bootstrap.dart  | 11 ++++
 .../files/scoped_project_session_adapter.dart      |  1 +
 .../features/home/studio_home_hero.dart            | 11 ----
 .../features/home/studio_home_projects.dart        | 47 ++++++++++++-
 .../features/home/studio_home_screen.dart          | 65 +++++-------------
 .../project_session/project_session_screen.dart    | 56 +++++++++++++++-
 .../shared/widgets/inputs/studio_draft_field.dart  |  7 +-
 .../macos/Runner/StudioProjectAccessBridge.swift   | 32 +++++++++
 .../scoped_project_session_adapter_test.dart       | 37 +++++++++++
 packages/map_authoring/bin/pokemap_authoring.dart  |  4 ++
 packages/map_authoring/lib/map_authoring.dart      |  3 +
 packages/map_authoring/lib/map_authoring_api.dart  |  3 +
 .../map_authoring/lib/map_authoring_local.dart     |  2 +
 .../lib/src/ports/project_file_reader.dart         |  4 +-
 .../lib/src/tooling/jsonl_worker.dart              | 77 ++++++++++++++++++++--
 tools/pokemap_mcp/src/server.ts                    |  2 +
 18 files changed, 299 insertions(+), 70 deletions(-)
```

Le diff ne comptabilise que les fichiers suivis ; l’annexe exhaustive, les tests, le contrôle de formatage et [empreintes-sources.txt](empreintes-sources.txt) incluent les 32 sources nouvelles. `git diff --check` est vert. Le contrôle Markdown est vert avec le budget explicite décrit plus haut.

Recommandation de suite, sans implémentation ici : validation visuelle du créateur par Yoahn ; relecture des réserves historiques séparées ; reprise bookmark production et parcours Player natif installé si une certification native complète est souhaitée. Aucune extension de scope automatique.

## Livraison Git et préparation de la version 0.3.17

Autorisation supplémentaire de Yoahn : commit, push, vérification de la synchronisation avec origin et publication d’Avelune Studio via les workflows GitHub existants. Après `git fetch origin`, `HEAD...origin/main` vaut `0 0` sur la base `f559e55c6815844ad0e0c08b2ed661733156e703` ; aucune intégration ni réécriture d’historique n’est nécessaire. Le rapport CI préexistant `documentation/reports/ci/post_ci_001_quick_checks_evidence_pack.md` reste hors staging et conservé.

Commit fonctionnel : `a27b20420` — `feat(avelune-studio): add guided project creation`. Il contient les 50 sources vérifiées par empreinte et les preuves AS-PROJ-001, dont les captures et les trois paquets. Les espaces de fin de ligne produits par les outils et les lignes finales superflues des archives texte ont été normalisés pour le commit ; aucun résultat ou contenu métier n’a été modifié. `git diff --cached --check` est ensuite vert.

Nouvelle vérification avant livraison : `PATH=/tmp/avelune-flutter-3.48/bin:$PATH python3 /tmp/avelune_merge_flutter_test.py /tmp/as-proj001-delivery-release-tests.log test/release test/project_creation --concurrency=2`, depuis Studio : `+24: All tests passed!`, code 0, 56,8 secondes ; 12 descendants suivis, aucun harness résiduel à terminer. Cette exécution ne remplace pas la suite complète décrite ci-dessus et ses 26 échecs conservés.

La dernière release publique avant livraison était `pokemap-v0.3.16`, publiée le 30 septembre 2026 à 00:13:59 UTC. La version Studio devient `0.3.17+317`. Le workflow utilise explicitement le pubspec Studio pour le contrat de version ; le pubspec de l’ancien éditeur reste inchangé. La validation, les builds des trois plateformes, la signature/notarisation macOS, le téléchargement de contrôle et la promotion du feed stable restent ceux du workflow existant.

Commit de version et de préparation : `acd4abe887c24aaab7c2ccb7f24aba488e71b474`. Push normal sur main réussi (`f559e55c6..acd4abe88`), sans force, merge, rebase ni changement de branche. Validation locale : `dart run tool/release/validate_release_version.dart --tag pokemap-v0.3.17 --pubspec ../../apps/avelune_studio/pubspec.yaml --previous-build 316`, depuis map_editor avec le SDK épinglé : `Validated PokeMap Editor 0.3.17 build 317.`, code 0. Le libellé du validateur historique ne change pas le pubspec Studio réellement passé.

Publication : `gh workflow run pokemap_desktop_release.yml --ref main -f mode=release -f version=0.3.17 -f confirmation=RELEASE`. [Run 36736784272](https://github.com/yoahnl/pokemap/actions/runs/36736784272), sur le commit `acd4abe887c24aaab7c2ccb7f24aba488e71b474` : **success**. Les neuf jobs effectifs sont verts : validate-release, linux-release, windows-release, macos-release, assemble-release, create-draft-release, smoke-download-draft, publish-release, promote-stable-feed. Le job macOS inclut signature, notarisation, stapling et assessment ; ce n’est pas une manipulation native du produit. Les tests et analyses de distribution sont exécutés par les jobs existants, sans affaiblissement du workflow.

[Quick checks 36736740694](https://github.com/yoahnl/pokemap/actions/runs/36736740694), sur le même SHA : **success**. Aucune nouvelle certification coûteuse ni dépendance de CI n’a été ajoutée.

[Release publique Avelune Studio 0.3.17](https://github.com/yoahnl/pokemap/releases/tag/pokemap-v0.3.17), publiée le 30 septembre 2026 à 15:42:04 UTC, non draft et dernière release selon l’API GitHub. Sept assets présents : archives Linux et macOS, DMG, installeur Windows, appcast, index et SHA256SUMS. Les notes françaises relient les preuves et conservent les limites de la suite complète et de la validation native.

Vérification HTTP indépendante après le workflow : téléchargement public de l’index et de l’appcast du tag stable, avec cache désactivé ; index schemaVersion 1, canal stable, version 0.3.17, tag pokemap-v0.3.17 ; appcast version 0.3.17, build 317, signature Ed25519 présente, URL immuable du ZIP macOS, longueur 68 652 353 octets. Les métadonnées stable et release sont identiques octet pour octet. Leur présence ne constitue pas une deuxième validation cryptographique locale des binaires : les téléchargements, hashes et signatures des vrais assets ont été vérifiés par smoke-download-draft en CI.

SHA-256 publics du paquet de distribution :

| Asset | SHA-256 |
| --- | --- |
| PokeMap-Editor-0.3.17-linux-x64.tar.gz | f523c2989d2f13625add9ddea7b7e0b8f46117a7880338fda75cce11b5957efa |
| PokeMap-Editor-0.3.17-macOS.app.zip | 17c94b370749a93fe60a35ca62024d8796a5b0f3245d0a5d52b93e57ee90e95b |
| PokeMap-Editor-0.3.17-macOS.dmg | 778c8c79206782852be9b39b4bc00f6cbb144b3cf98313f99880a2d605c641f2 |
| PokeMap-Editor-Setup-0.3.17.exe | d43f6ed89a7e90d271d7f12b7a17fc6a087d78b9e47a40acaac6c8471ee8dc3c |

La livraison Git et l’application distribuée sont vérifiées ; elles ne ferment pas les réserves AS-PROJ-001 précédentes. Le suivi reste TO REVIEW, jamais DONE automatiquement. Le rapport CI initial hors périmètre demeure non suivi et préservé ; les 50 empreintes de sources ont été revérifiées après commit, toutes identiques.
## Recette Clairbois → export → Player — 1er octobre 2026

### Verdict et périmètre

La réserve ciblée de la revue du 30 septembre est levée par une nouvelle recette automatisée du véritable hôte. Clairbois reste exclusivement en 32 × 32 avec ses deux cartes. Aucun fichier de production ni interface n’a été modifié. L’acceptation produit et visuelle de Yoahn est conservée. DONE est proposé pour AS-PROJ-001 à sa décision ; le statut reste TO REVIEW.

Ce résultat remplace uniquement la réserve concernant la recette obsolète. Il ne transforme pas les anciennes suites complètes, limitations natives ou autres réserves historiques en nouvelles preuves vertes.

### Audit initial et cause

HEAD initial et final : `02d3e389bd997176428e74d4494aeea41604c7da`, branche `main`. Le worktree initial n’avait aucune modification suivie. Le seul fichier non suivi était `documentation/reports/ci/post_ci_001_quick_checks_evidence_pack.md`, conservé sans modification.

Les instructions du dépôt, `codex_rule.md`, les compétences de diagnostic/vérification et les raccordements ciblés ont été lus. Le SDK utilisé est celui épinglé par la CI : Flutter `3.48.0-0.4.pre`, révision `e3005e3402d9cfa2043114c8bc53c59d12e9b98e`, disponible dans `/tmp/avelune-flutter-3.48`.

Avant modification, depuis `apps/pokemap_hub` :

```bash
/tmp/avelune-flutter-3.48/bin/flutter test --no-pub test/features/installation/as_project_creation_player_e2e_test.dart
```

Résultat : exit 1, `+0 -3: Some tests failed.`, durée totale mesurée 15,81 s. Journal : `/tmp/as-proj-recipe-before.log`.

Les cas 16/48 recherchaient des contrôles absents pour Clairbois. Le cas 32 utilisait `maps.single` et échouait avec trop d’éléments. La recette attendait également une carte 20 × 15 et un départ 10,7 issus de l’ancien modèle local. Il s’agissait d’attentes produit obsolètes, pas d’un défaut démontré du créateur.

### Fichiers et zones modifiés

| Fichier | Modification |
| --- | --- |
| `apps/pokemap_hub/test/features/installation/as_project_creation_player_e2e_test.dart` | Un parcours Clairbois 32 réel remplace les variantes UI obsolètes ; deux cartes, export, fermeture de l’auteur, suppression de son seul répertoire temporaire, lancement installé. |
| `apps/pokemap_hub/test/features/installation/as_project_creation_player_support.dart` | Vérifications du paquet, de l’installation, des deux cartes, de tous les atlas et du personnage ; parcours via l’adaptateur d’entrée du Hub. |
| `apps/avelune_studio/test/support/clairbois_player_recipe.dart` | Parcours commun réutilisable avec le Player installé ; déplacements, dialogue, passages aller-retour et collision avec l’eau. Le wrapper StudioPlaytestView reste distinct. |
| `apps/avelune_studio/test/support/project_creation_workspace_fixture.dart` | Sélection explicite de Petit projet jouable dans le véritable créateur ; API du helper conservée. |
| `apps/pokemap_hub/pubspec.yaml` | Dépendance de développement explicite vers `map_authoring`, nécessaire aux assertions sur ses contrats publics. |
| `apps/pokemap_hub/pubspec.lock` | `map_authoring` devient direct dev ; version de la dépendance locale Studio alignée sur 0.3.18+318. Aucun upgrade externe. |
| `documentation/reports/avelune_studio/AS-PROJ-001/evidence-pack.md` | Cette mise à jour ciblée des preuves. |
| `documentation/reports/avelune_studio/AS-PROJ-001/recette-clairbois-sources.txt` | Annexe contenant intégralement les six fichiers techniques modifiés, demandée explicitement par le mandat. |

Le diff technique comporte 6 fichiers, 223 ajouts et 126 retraits. Les quatre fichiers Dart manuels restent sous 300 lignes (139, 283, 137 et 293). Aucun commentaire ajouté, aucun skip ni assouplissement des contrôles de sécurité/autonomie.

La comparaison du manifeste exporté tient compte de la projection canonique Yarn → JSON réalisée par l’exporteur existant ; aucun JSON n’est corrigé dans le test. Les chemins sont vérifiés après résolution des liens de macOS (`/var` et `/private/var`), sans élargir les racines autorisées.

### Preuve d’autonomie

Le test traverse Accueil → Nouveau projet → Petit projet jouable/Clairbois 32 → création → Accueil/Exporter le jeu → Test local → export réel.

Il utilise la fixture d’archive existante, le service canonique d’export, `GamePackageInstaller`, `InstalledGameLaunchResolver`, `HubInProcessSessionFactory` et les sauvegardes temporaires du Hub. Le sélecteur de destination est contrôlé par la fixture, mais ni le paquet ni l’installateur ne sont simulés. Aucun contenu n’est reconstruit après création.

La session auteur est fermée et son workspace disposé. Le répertoire auteur, vérifié comme descendant du dossier temporaire du test, est supprimé avant l’installation et reste absent après le parcours. Les octets auteur sont comparés avant/après export (hors profil d’export selon la règle existante). Aucun projet personnel original n’est touché.

Depuis l’installation, les assertions vérifient :

- grille 32 × 32, village `first-map` de 32 × 26 et maison `maison` de 12 × 10 ;
- chemins de ressources contenus dans la bibliothèque installée, fichiers présents, décodage des 30 atlas et dimensions du personnage ;
- départ 16,16, déplacement réel à 16,15 et delta de 64 px avec l’échelle d’affichage 2 ;
- dialogue réel de bienvenue d’Émile, ses trois répliques et retour au jeu ;
- passage dans la maison à 6,8, puis retour au village à 15,7 ;
- blocage par l’eau à 11,18.

Les commandes d’entrée passent par l’adaptateur du Player installé. Une relâche de touche pendant le verrou légitime de fermeture du dialogue n’est pas assimilée à un nouvel ordre accepté ; les déplacements et interactions restent assertés.

### Commandes sur les sources finales

Toutes les commandes Flutter/Dart ci-dessous utilisent le SDK épinglé. Les tests Flutter ont été exécutés via `/tmp/run_avelune_owned.py` pour relever les PID du runner et ses descendants ; seuls les éventuels descendants encore possédés par la session peuvent être terminés. Aucune terminaison globale par nom de processus.

| Répertoire / commande | Résultat exact | Journal |
| --- | --- | --- |
| Hub : `flutter test --no-pub test/features/installation/as_project_creation_player_e2e_test.dart` | exit 0 ; `00:19 +1: All tests passed!` | `/tmp/as-proj-recipe-final.log` |
| Studio : `flutter test --no-pub test/project_creation --concurrency=2 --reporter=expanded` | exit 0 ; `00:33 +17: All tests passed!` | `/tmp/as-proj-fixtures-sources-final.log` |
| map_authoring : `dart test test/workspace/project_creation_test.dart test/workspace/clairbois_creation_test.dart test/workspace/clairbois_creation_bootstrap_test.dart` | exit 0 ; `00:09 +19: All tests passed!` | `/tmp/as-proj-models-final.log` |
| Hub : `flutter analyze --no-pub` | exit 0 ; `No issues found! (ran in 24.9s)` | `/tmp/as-proj-hub-analyze-final.log` |
| Studio : `flutter analyze --no-pub` | exit 0 ; `No issues found! (ran in 19.6s)` | `/tmp/as-proj-studio-analyze-final.log` |
| Racine : `dart format --output=none --set-exit-if-changed` sur les quatre fichiers Dart modifiés | exit 0 ; `Formatted 4 files (0 changed)` | contrôle final exécuté |
| Racine : `git diff --check` | exit 0 | contrôle final exécuté |
| Hub : `flutter pub get --offline` | exit 0 ; `Changed 2 dependencies!` | résolution locale des seules métadonnées concernées |
| Racine : `bash tools/scripts/check_markdown_hygiene.sh` | exit 1 ; `Markdown hygiene: 1 new Markdown files exceed the default limit of 0.` | `/tmp/as-proj-markdown-hygiene-final.log` |

Le contrôle Markdown échoue sur le rapport CI non suivi déjà présent à l’audit initial. Cette intervention ne crée aucun Markdown supplémentaire et ne supprime ni ne masque ce travail concurrent.

Le run E2E final avait le runner PID 22574, 30 descendants relevés, durée totale du superviseur 42,43 s. Le run Studio final avait le PID 27741, 8 descendants relevés, durée totale 38,39 s. Aucun descendant restant appartenant à ces runs n’a été signalé au nettoyage.

Les modèles local playable et vide 16/32/48 gardent leur couverture indépendante côté authoring ; le projet vide 48 reste couvert dans les tests UI. Ils ne deviennent pas des variantes de Clairbois.

Pendant l’adaptation, des essais intermédiaires ont détecté la projection du dialogue, les liens de chemin macOS, un import public manquant puis l’acceptation d’une relâche pendant le verrou du dialogue. Ils ont conduit aux assertions conformes ci-dessus, sans modification du code produit. Le premier passage réussi intermédiaire ne remplace pas le nouveau run final.

### Artefacts réellement produits

Paquet exporté par le run final :

`/tmp/as-proj-clairbois-proof/packages/clairbois-32.avelunegame`

Taille : 1 536 849 octets. SHA-256 :

`cfd01a40f69f1f3646b3cbfe3c0b3359c9877d6aef82abf7d93d0e3f409974ad`

Capture du Player installé, produite et ouverte visuellement :

`/tmp/as-proj-clairbois-proof/captures/player-created-32.png`

Cette capture est un rendu widget/hôte automatisé, pas une manipulation native indépendante. Les artefacts et journaux sous /tmp sont locaux et temporaires ; aucune mise en ligne ni release n’a été faite.

### Passes indépendantes et auto-critique

- Audit/architecture : cause obsolète reproduite ; aucun correctif produit nécessaire, dépendances publiques et diff borné.
- Implémentation : parcours réel du créateur jusqu’au Hub, suppression uniquement temporaire, couverture des autres modèles conservée.
- Tests : échec initial +0/-3 ; nouvelle preuve +1, +17 et +19, avec source auteur inaccessible.
- Build/validation : SDK identique à la CI, analyses propres ; pas de nouveau build macOS requis pour ce diff de tests uniquement. Le hôte Flutter a bien été compilé/exécuté.
- Critique finale : favorable ; dépendance de test déclarée, lockfile limité à deux métadonnées, API du helper conservée, aucun contrôle affaibli.

Les audits/passes sont en lecture seule ; les résultats d’exécution ci-dessus ont été obtenus dans cette intervention. Aucun nouveau scan MCP : parité N/A, puisque aucune sémantique auteur, commande, donnée produit ou transport n’est modifié.

Limites : réseau contrôlé par l’archive de test, donc pas une nouvelle certification du téléchargement GitHub ; pas de replay clavier natif ni nouvelle acceptation artistique ; pas de nouvelle suite Studio globale, de build macOS, de release ou de clôture mécanique FG. Le mandat cible la recette et ses consommateurs concernés, pas ces chantiers.

### État final

HEAD et branche inchangés. Sept fichiers suivis modifiés (les six fichiers techniques plus ce rapport), une annexe texte non suivie créée pour le livrable, et le rapport CI non suivi préexistant conservé. Aucun commit, push, checkout, reset ou release. La mise à jour Notion concerne uniquement AS-PROJ-001 et conserve TO REVIEW avec proposition DONE.

### Livraison Git autorisée le 1er octobre 2026

Après autorisation explicite de Yoahn pour commit/push, `git fetch origin` puis `git rev-list --left-right --count HEAD...origin/main` confirment `0 0` à la base. Livraison limitée aux six fichiers techniques, au rapport et à son annexe intégrale. Le rapport CI non suivi préexistant reste exclu. Les sources techniques sont celles vérifiées ci-dessus ; aucune release n’est demandée dans cette autorisation.
