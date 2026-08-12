# Personalization Studio V3 — audit de complétude et roadmap de clôture

Date : 2026-08-12

Branche auditée : `feature/personalization-studio-v3-phase-e`

HEAD audité : `1e59f648f`

## 1. Verdict exécutif

**Verdict global : PARTIAL, proche d’une bêta technique mais pas d’une livraison produit acceptée.**

Le cœur promis existe réellement : profil de présentation V10, six scènes guidées, contexte projet, widgets player partagés, sauvegarde canonique, export, installation Hub, standalone, responsive, accessibilité de base, manipulation directe, presets, historique et MCP de mutation.

La livraison ne peut toutefois pas être déclarée terminée pour cinq raisons :

1. la branche n’est pas rebasée sur les onze commits récents de `main`, principalement la clôture Character Studio S13 ;
2. la suite complète du serveur MCP échoue sur une attente de version obsolète (`9` au lieu de `10`) ;
3. le lancement desktop automatisé du projet d’acceptation n’est pas reproductible avec l’application sandboxée et le MCP Marionette installé reste en `0.5.0` face au binding `0.6.0` ;
4. les 36 goldens passent techniquement, mais l’acceptation visuelle humaine demandée par PERS3-33 n’est pas enregistrée ;
5. le chantier cumulé n’est pas consolidé : 132 fichiers suivis modifiés, 38 fichiers non suivis et 7 995 insertions pour 1 690 suppressions.

Il serait donc faux de déclarer PERS3-30, PERS3-33 ou PERS3-34 `DONE`. PERS3-31 et PERS3-32 sont techniquement solides, sous réserve de la réintégration avec `main`.

## 2. Audit initial

### 2.1 État Git

- Branche : `feature/personalization-studio-v3-phase-e`.
- Divergence : `main` possède 11 commits absents de la branche ; la branche possède 23 commits absents de `main`.
- Les 11 commits entrants touchent Character Studio, les références de dialogue, `map_core` et `map_authoring`.
- État du worktree : 132 fichiers suivis modifiés et 38 fichiers non suivis.
- Diff cumulé : 132 fichiers, 7 995 insertions, 1 690 suppressions.
- Aucun commit, rebase, merge ou push n’a été effectué pendant cet audit.

### 2.2 Passes d’audit

| Passe | Verdict | Conclusion |
|---|---|---|
| Architecture | CHANGES_REQUIRED | La verticale V10 existe, mais l’intégration Character Studio/main et la dépendance transitive `map_editor -> map_player_ui -> map_runtime` doivent être assumées ou resserrées. |
| Produit / UX | PARTIAL | Le shell trois colonnes et les scènes sont compréhensibles ; les previews sont fidèles. La preuve desktop complète et l’approbation visuelle manquent. |
| Tests | CHANGES_REQUIRED | Les suites ciblées sont vertes, mais la suite MCP complète est rouge sur une assertion V9 obsolète. |
| Livraison | BLOCKED | Rebase, consolidation des fichiers, parcours desktop et acceptation produit manquent. |
| Auto-critique | PARTIAL | L’audit a inspecté code, goldens et parcours automatisés ; il n’a pas pu piloter le Studio réel via Marionette à cause du mismatch 0.5.0/0.6.0. |

## 3. Matrice de complétude

| Domaine | Statut | Preuve ou manque principal |
|---|---|---|
| Contrat V10 | DONE technique | `ProjectPresentationProfile.supportedSchemaVersion == 10`; Title, Intro, thèmes, palettes, typo, fenêtres, layouts, Pause, Dialogue et Combat sont persistés et validés. |
| Vérité des contrôles | DONE technique | Registre de 39 capacités : 28 persistées, 9 preview-only, 2 navigation. Le build vérifie l’égalité avec les contrôles visibles. |
| Contexte projet | DONE technique | Ressource `presentationPreviewContext` V2 ; cartes, lignes/choix de dialogue, portraits et rencontres projetés sans persistance de la sélection. |
| Preview avec widgets réels | DONE technique | Titre, Intro, Dialogue et Combat montent les surfaces player partagées ; Pause monte `RuntimePlayerPauseShell` via `PlayerPausePreviewShell`. |
| Style global | DONE technique | Couleurs sémantiques, palettes de surface, métriques typographiques et fenêtres sont appliquées par `RuntimePlayerPresentation.applyTo`. |
| Écran titre / Intro | DONE technique | Copie, actions, médias, motion, vidéo/poster, focal point, reduced motion et contrôles de test sont couverts. |
| Menu Pause | DONE technique | Actions, labels, icônes, ordre, visibilité, layout et fenêtres sont utilisés par le shell runtime ; les détails de preview sont simulés et marqués comme tels. |
| Dialogue | PARTIAL intégration | La surface complète et les scénarios réels existent. Le bridge doit être revalidé après les commits Character Studio S13 et la résolution récente des références de dialogue. |
| Combat | DONE technique | Commandes, HUD/PV, capacités, cible, message, layout et scènes projet réelles sont couverts par V10 et `PlayerBattleScene`. |
| Manipulation directe | DONE technique | Cibles visuelles, drag/snap, actions clavier, presets par scène et historique atomique sont présents et testés. |
| Save / restart / export | DONE technique | Sauvegarde, redémarrage, export, package hashé et préflight passent. |
| Hub / standalone | DONE technique | Les deux construisent `RuntimePlayerPresentation`, appliquent le thème et montent `PokeMapPlayerSessionView` avec Dialogue et Combat canoniques. |
| MCP | PARTIAL | Mutation `presentation.update` et tests presentation passent ; suite complète : 43/44, assertion de ressource encore à V9. Le `pokemap_describe` live du checkout audité n’est pas prouvé. |
| Responsive / a11y | DONE ciblé | Matrice 720/1024/1440, texte 100/150/200 %, semantics, clavier/manette et alternatives aux gestes sont testés. |
| Goldens | PARTIAL produit | 18 goldens éditeur et 18 player passent. Inspection humaine explicite non enregistrée. |
| Desktop réel | BLOCKED | Sandbox macOS bloque le bootstrap direct du projet ; après ad-hoc signing, Marionette refuse la connexion car MCP 0.5.0 et binding 0.6.0. |
| Intégration Git | BLOCKED | Rebase et consolidation finale non réalisés ; état Git très sale. |

## 4. Évaluation des anciens lots PERS3

| Phase historique | Lots | Statut audité |
|---|---|---|
| V3-A — Vérité et contexte | PERS3-00 à 04 | DONE technique |
| V3-B — Langage visuel | PERS3-05 à 08 | DONE technique |
| V3-C — Titre et Intro | PERS3-09 à 12 | DONE technique |
| V3-D — Pause | PERS3-13 à 15 | DONE technique |
| V3-E — Dialogue / Character | PERS3-16 à 20 | PARTIAL jusqu’au rebase et à la recertification S13 |
| V3-F — Combat | PERS3-21 à 25 | DONE technique |
| V3-G — Manipulation directe | PERS3-26 à 29 | DONE technique |
| V3-H — Certification | PERS3-30 à 34 | PARTIAL ; PERS3-30, 33 et 34 restent ouverts |

## 5. Roadmap de clôture

### Phase R1 — Réintégration et vérité du checkout

Objectif : obtenir une base unique, propre et compatible avec le Character Studio final.

| Lot | Travail | Gate de sortie |
|---|---|---|
| PERS3-R1.1 | Inventorier et regrouper les 170 changements par lots A à H, puis créer les commits manquants sans mélanger les domaines. | Chaque fichier appartient à un commit explicable ; aucun asset ou golden orphelin. |
| PERS3-R1.2 | Rebaser sur `main` et résoudre explicitement les conflits V10/V8-V9, Dialogue, Character Studio et authoring preview contexts. | Rebase terminé, aucun conflit, schéma V10 conservé, fixture V10 validée. |
| PERS3-R1.3 | Adapter le bridge Personalization aux contrats Character Studio S13 : imports atomiques, références dialogue résolues, identité/portrait durable. | Les pickers utilisent les ressources S13 et un remplacement de portrait est visible sans référence stale. |
| PERS3-R1.4 | Rejouer `map_core`, `map_authoring`, `map_editor`, `map_player_ui`, distribution, Hub et standalone après rebase. | Toutes les suites ciblées vertes et état Git borné. |

### Phase R2 — Fermeture MCP et frontières

Objectif : certifier le même contrat sur les transports et clarifier la dépendance runtime.

| Lot | Travail | Gate de sortie |
|---|---|---|
| PERS3-R2.1 | Mettre à jour l’attente `projectPresentationProfile.version` de 9 à 10 dans `read_only_server.test.ts` et ajouter une assertion de non-régression centralisée. | `npm test` : 44/44. |
| PERS3-R2.2 | Construire le serveur du worktree et exécuter un `pokemap_describe` live réellement connecté à ce checkout. | Versions V10/V2, transports `directApi/cli/editor/mcp`, zéro cellule personalization bloquée ou manquante. |
| PERS3-R2.3 | Décider et documenter la frontière `map_editor -> map_player_ui -> map_runtime`. Extraire un barrel preview-safe si l’interdiction de dépendance transitive est maintenue. | Test de frontière sémantique, pas seulement recherche textuelle d’import direct. |
| PERS3-R2.4 | Vérifier qu’aucun champ V10 n’est schema-only par une matrice automatisée modèle → contrôle → preview → runtime → export → MCP. | Chaque champ est consommé ou explicitement marqué N/A avec justification. |

### Phase R3 — Parcours desktop reproductible

Objectif : faire de l’application réelle la preuve finale, pas uniquement les widget tests.

| Lot | Travail | Gate de sortie |
|---|---|---|
| PERS3-R3.1 | Corriger le bootstrap QA macOS : accès sandbox sûr via sélection utilisateur/bookmark ou copie contrôlée, et résolution canonique `/tmp`/`/private/tmp`. | Le projet d’acceptation s’ouvre sans ad-hoc signing ni exception de chemin. |
| PERS3-R3.2 | Aligner `marionette_mcp` et `marionette_flutter` en 0.6.0 dans l’environnement de test. | Connexion Marionette réussie sur le binaire exact construit. |
| PERS3-R3.3 | Écrire un parcours desktop lecture seule : ouvrir Personalization, visiter les six scènes, changer les contextes, portrait/choix/états Combat, portrait/paysage et 200 %. | Captures réelles horodatées, aucun overflow, aucun contrôle mort, projet non dirty tant qu’aucun réglage n’est modifié. |
| PERS3-R3.4 | Écrire un parcours desktop de mutation : changer un label, une couleur, une forme, une disposition et un portrait ; sauvegarder, redémarrer, exporter. | Valeurs identiques après redémarrage et dans le package installé. |

### Phase R4 — Acceptation visuelle et simplicité UX

Objectif : valider que l’interface est réellement simple, pas seulement testable.

| Lot | Travail | Gate de sortie |
|---|---|---|
| PERS3-R4.1 | Produire deux contact sheets 6 scènes, Editor et Player, en paysage/portrait, plus les variantes Dialogue et Combat. | 36 goldens lisibles regroupés et référencés par scène. |
| PERS3-R4.2 | Organiser la revue humaine avec la maquette cible : hiérarchie, labels, densité, correspondance de chaque réglage et visibilité des effets. | Acceptation explicite de Yoahn ou liste d’écarts signée scène par scène. |
| PERS3-R4.3 | Corriger uniquement les écarts acceptés, en conservant navigation gauche, preview centrale et inspecteur droit. | Aucun contrôle avancé imposé dans le premier niveau ; huit décisions maximum par vue Combat. |
| PERS3-R4.4 | Ajouter les goldens du shell complet aux trois largeurs de référence, pas seulement le canvas de preview. | Shell complet certifié à 1440×900, 1024×768 et 720×900 avec texte 200 %. |

### Phase R5 — Release candidate

Objectif : rendre PERS3-30 à PERS3-34 réellement fermables.

| Lot | Travail | Gate de sortie |
|---|---|---|
| PERS3-R5.1 | Lancer les suites complètes des packages touchés et les analyses statiques. | Zéro échec lié au chantier ; toute dette préexistante est séparée et documentée. |
| PERS3-R5.2 | Construire Editor, Hub et standalone depuis le même commit. | Trois builds réussis, chemins et hashes enregistrés. |
| PERS3-R5.3 | Exécuter la recette complète Editor → restart → export → Hub → standalone sur la fixture V10 rebasée. | Un seul profil produit les mêmes view-data sur les deux runtimes. |
| PERS3-R5.4 | Supprimer les résidus de test, vérifier Markdown, `git diff --check`, assets, licences et état Git. | Worktree propre, aucun fichier failure/temp, aucune fixture production mensongère. |
| PERS3-R5.5 | Refaire la revue de clôture PERS3-00 à 34 et marquer les statuts dans la roadmap canonique. | PERS3-30 à 34 ne passent `DONE` qu’avec preuves fraîches et acceptation humaine. |

## 6. Ordre recommandé

| Session | Lots groupés | Résultat attendu |
|---|---|---|
| S1 | R1.1 à R1.3 | Branche rebasée et Character Studio S13 intégré |
| S2 | R1.4 + R2.1 à R2.2 | Tests de base et MCP complètement verts |
| S3 | R2.3 à R2.4 | Frontières et couverture de champs certifiées |
| S4 | R3.1 à R3.2 | Environnement desktop reproductible |
| S5 | R3.3 à R3.4 | Parcours desktop réel et persistance prouvés |
| S6 | R4.1 à R4.4 | Acceptation visuelle et derniers écarts UX |
| S7 | R5.1 à R5.5 | Release candidate propre et clôture finale |

La séquence critique est **R1 → R2 → R3 → R4 → R5**. Il ne faut pas polir les écarts visuels avant le rebase Character Studio, ni déclarer l’acceptation avant le parcours desktop reproductible.

## 7. Commandes et résultats de l’audit

| Commande | Résultat |
|---|---|
| `map_core`: trois tests de contrat/profil/layout | 29 tests, tous passés |
| `map_authoring`: presentation, preview context, full parity | 31 tests, tous passés |
| `map_editor`: goldens + fixture + truth guard | 24 tests, tous passés |
| `map_editor`: restart/export/recovery | 3 tests, tous passés |
| `map_player_ui`: goldens + shared surfaces | 23 tests, tous passés |
| `map_distribution`: codec, preflight, release receipt, preset pack | 56 tests, tous passés |
| `pokemap_hub`: startup adapter, packaging E2E, golden gate | 5 tests, tous passés |
| `playable_runtime_host`: launch slice + battle overlay | 15 tests, tous passés |
| `tools/pokemap_mcp`: suite complète | 43 passés, 1 échec : attendu V9, obtenu V10 |
| `tools/pokemap_mcp`: check TypeScript + tests presentation | check vert, 2 tests passés |
| `git diff --check` | succès |
| `check_markdown_hygiene.sh` avant ce rapport | succès, aucun nouveau Markdown avant l’audit |

Une première commande `map_player_ui` et une première commande `map_distribution` ont référencé des noms de tests inexistants. Elles ont été immédiatement corrigées avec l’inventaire réel ; les suites corrigées sont vertes. Ces erreurs de commande ne sont pas des défauts produit.

## 8. Risques et non-objectifs

- Les goldens prouvent la stabilité du rendu, pas sa qualité subjective ; Yoahn reste l’autorité d’acceptation.
- La preview Pause utilise le vrai shell mais fournit des snapshots de détail de test ; elle ne lance pas une vraie sauvegarde ou un vrai inventaire depuis le Studio.
- Les boutons de viewport, text scale, reduced motion, comparaison et données de test restent session-only par conception.
- Cet audit n’introduit aucune nouvelle capacité de personnalisation ; il ferme d’abord la livraison de celles déjà promises.
- Le HUD d’exploration n’est pas réintroduit : le périmètre reste Style global, Titre, Intro, Pause, Dialogue et Combat.

## 9. Auto-critique finale

L’audit apporte des preuves fraîches sur les contrats, goldens et verticales de livraison. Il a aussi trouvé un échec MCP reproductible et deux blocages de QA desktop. Sa limite principale est l’absence de navigation Marionette sur l’application réelle, provoquée par le mismatch d’outil 0.5.0/0.6.0 ; la revue UX repose donc sur les widgets exécutés, les 36 images générées et l’inspection du shell, pas sur un parcours souris complet. Cette limite justifie à elle seule de conserver le verdict `PARTIAL`.

## 10. Exécution Phase R5

### PERS3-R5.1 — Suites complètes et analyses

Source testée : `967ab262d149ed6ad5b97c050b6a3c5aa1337fab`.

| Périmètre | Commande | Résultat frais |
|---|---|---|
| `map_core` | `dart test --concurrency=1` | `4167` succès, `1` skip, `5` échecs préexistants : deux rapports gameplay générés absents, une fixture de save absente, un dossier de rapports gameplay absent et l’inventaire Smart Tiles déjà désynchronisé. Aucun échec Personalization. |
| `map_core` | `dart analyze` | code `0`, `121` infos préexistantes. |
| `map_authoring` | `dart test --concurrency=1` | `591` succès, `2` timeouts à `30 s`. Les deux scénarios repassent isolément avec un timeout de `2 min`, dont `PMCP-085` en `14 s`. |
| `map_authoring` | `dart analyze` | code `0`, aucun problème. |
| `map_distribution` | `dart test --concurrency=1` | `109` succès, aucun échec. |
| `map_distribution` | `dart analyze` | code `0`, `1` info préexistante. |
| `map_player_ui` | `flutter test --concurrency=1` | `267` succès, aucun échec. |
| `map_player_ui` | `flutter analyze` | code `0`, aucun problème. |
| `map_runtime` | `flutter test --concurrency=1` | `2317` succès, `1` skip, `1` échec préexistant : golden `reports/ui/world_map_editor_gate_5_rotation_runtime.png` absent. Aucun échec Personalization. |
| `map_runtime` | `flutter analyze` | code `1`, `7` infos préexistantes. |
| `pokemap_hub` | `flutter test --concurrency=1` | interrompu par la limite d’exécution après `143` succès et aucun échec observé ; preuve complète non acquise dans ce lot. |
| `tools/pokemap_mcp` | `npm run check` | code `0`. |
| `tools/pokemap_mcp` | `npm test` | interrompu par la limite d’exécution ; les deux tests Presentation live sont passés, tandis que des scénarios Smart Tiles, Bag, runtime et playtest hors chantier ont échoué ou expiré. |

Le premier passage a été invalidé par `ENOSPC`. Trois builds Flutter régénérables du worktree et des répertoires temporaires `dart_test.kernel.*` orphelins, vérifiés sans processus propriétaire, ont été nettoyés. Les relances ont utilisé un `TMPDIR` isolé et supprimé après chaque suite. Aucun source ni travail concurrent n’a été supprimé.

Verdict R5.1 : `PARTIAL`. Les verticales Personalization sont vertes, mais le gate demande les suites complètes sans échec lié au chantier et une séparation explicite de la dette. Cette séparation est maintenant versionnée ; Hub et MCP devront être découpés en commandes bornées lors de la clôture R5.5 pour obtenir une preuve complète.

### PERS3-R5.2 — Builds release communs

Source commune construite : `5c9995f5da5a9e4d6fd2e60633a53bc05d172425`.

| Produit | Commande | Binaire | SHA-256 |
|---|---|---|---|
| Editor | `flutter build macos --release` | `packages/map_editor/build/macos/Build/Products/Release/PokeMap.app/Contents/MacOS/PokeMap` | `1f1fbdfa6e5478ada0eca2b8e2da8944e7fb9948e9b74801e99ce2221d9bde7c` |
| Hub | `flutter build macos --release` | `apps/pokemap_hub/build/macos/Build/Products/Release/PokeMap Hub.app/Contents/MacOS/PokeMap Hub` | `eaa7294d802a3c7cb259e50978b5422b761b9f06f893993ea44116508ca29963` |
| Standalone | `flutter build macos --release` | `examples/playable_runtime_host/build/macos/Build/Products/Release/PokeMap Selbrume.app/Contents/MacOS/PokeMap Selbrume` | `59bde173169cf61845de9b17206bdef591be598e69d30d1a07a5605bdedaa373` |

Les trois commandes ont terminé avec le code `0`. Les avertissements Xcode concernent l’icône 1024 non assignée, `AVKeyValueStatus` déprécié et la phase Flutter Assemble sans outputs ; aucun n’empêche la production des bundles.

Le contrôle de politique a trouvé des références CocoaPods historiques dans le projet standalone. Elles ont été supprimées des xcconfig, du workspace, du projet Xcode et du gitignore. Le nouveau test `macos_dependency_manager_policy_test.dart` prouve l’activation SPM, les overrides `gamepads_darwin` et l’absence de toute intégration Pods ; test et analyse ciblée sont verts, puis le standalone a été reconstruit avec succès.

Verdict R5.2 : `DONE`.

### PERS3-R5.3 — Recette V10 de bout en bout

Base de la recette : `d2a21fd2bca47e56912c057b7a94aedf49a208da`.

| Étape | Commande ou preuve | Résultat frais |
|---|---|---|
| Editor restart | `flutter test test/personalization/phase_6_personalization_studio_restart_e2e_test.dart --reporter expanded` | `1/1`, succès. |
| Editor export | `POKEMAP_PHASE6_PACKAGE_OUTPUT=/tmp/pokemap-phase-d-r53.avelunegame flutter test test/personalization/phase_6_personalization_studio_export_e2e_test.dart --reporter expanded` | `1/1`, succès ; package SHA-256 `f11e2c779e4dcf47b592d27cb0b114a3ea6c364568c8efa8c53796c61aed7583`. |
| Hub install + launch | `POKEMAP_PHASE6_PACKAGE_INPUT=/tmp/pokemap-phase-d-r53.avelunegame flutter test test/presentation/features/player/phase_6_personalization_packaging_e2e_test.dart --reporter expanded` | `1/1`, succès sur le package réellement exporté par Editor. |
| Standalone | `flutter test test/phase_a_golden_slice_launch_test.dart --plain-name 'standalone forwards the complete V10 presentation'` | `1/1`, succès. |
| Parité de projection | `flutter test test/player/runtime_player_presentation_test.dart --reporter expanded` | `8/8`, succès ; le vrai `golden_personalization_v3/project.json` V10 produit exactement le même `RuntimePlayerPresentationViewData` par les chemins Hub et standalone. |
| Analyse parité | `flutter analyze lib/src/player/runtime_player_presentation.dart test/player/runtime_player_presentation_test.dart` | code `0`, aucun problème. |
| Analyse Hub E2E | `flutter analyze test/presentation/features/player/phase_6_personalization_packaging_e2e_test.dart` | code `0`, aucun problème. |

Le premier passage Hub a révélé une hypothèse incorrecte dans le test : `branding.titleMusic` était forcé comme obligatoire alors que le contrat et l'export Editor l'autorisent à être absent. Le harness résout désormais ce média uniquement lorsqu'il existe. Le produit n'a pas été élargi et l'export sans musique reste valide.

`RuntimePlayerPresentationViewData` constitue le snapshot canonique des données effectivement projetées vers les widgets player : copie du titre, typographie chargée, thème, palettes, fenêtres, layouts, Dialogue, Combat et Pause. Les identités d'`ImageProvider`, dépendantes du loader, sont volontairement exclues ; leur résolution reste couverte par l'E2E Hub sur le package réel.

Verdict R5.3 : `DONE`.

### PERS3-R5.4 — Hygiène de la release candidate

| Contrôle | Résultat frais |
|---|---|
| Truth guard production élargi | `6/6` avec la fixture contract : aucune fixture démo, faux personnage, faux Pokémon ou promesse « Preview réelle » dans Editor, `map_player_ui`, Hub ou standalone. |
| Assets et licences | `15/15` sur le preflight package et le preset pack : hashes, codecs, médias responsives, assets référencés et licences redistribuables sont certifiés ; les licences manquantes sont rejetées. |
| Politique macOS standalone | `2/2` et analyse ciblée sans problème : Swift Package Manager actif, overrides natifs présents, aucune intégration CocoaPods. |
| Résidus | Aucun fichier `*.actual.*`, `*.diff.*`, `*.tmp` ou `*.temp` hors répertoires générés. Les deux PNG contenant `failure` dans leur nom sont des preuves historiques suivies de Web Cockpit, pas des sorties orphelines de cette phase. |
| Fichier temporaire R5.3 | `/tmp/pokemap-phase-d-r53.avelunegame` supprimé après la recertification Hub. |
| Markdown | `bash tools/scripts/check_markdown_hygiene.sh` : succès, aucun nouveau Markdown. |
| Diff | `git diff --check` : succès ; aucun lockfile modifié par la résolution de dépendances. |

Le garde-fou de vérité inspectait auparavant uniquement le feature folder Personalization de l'Editor. Il couvre désormais toutes les surfaces de production susceptibles de rendre la preview ou le player, sans scanner les fixtures de test légitimes.

Verdict R5.4 : `DONE`.

### PERS3-R5.5 — Revue de clôture PERS3-00 à PERS3-34

La roadmap canonique possède maintenant un tableau autoritatif lot par lot. PERS3-00 à PERS3-32 sont `DONE` techniquement. PERS3-33 et PERS3-34 restent `PARTIAL` : les images et le nettoyage sont présents, mais l'implémentation visuelle actuelle n'a pas encore reçu l'acceptation humaine explicite requise par le plan.

| Gate frais | Résultat |
|---|---|
| Authoring Presentation, preview context et PMCP-085 | `37/37`, analyse ciblée sans problème. |
| MCP Presentation live local | `3/3`, `npm run check` vert après `npm ci`. |
| Catalogue du checkout | V10, preset V2, transports `cli/directApi/editor/mcp`, serveur et commit exacts ; worktree propre au moment du contrôle. |
| Registre de capacités Editor | `7/7`. |
| Accessibilité publication | `5/5`. |
| Responsive et inputs Studio | `9/9`. |
| Contact sheets | `23/23`, six planches Editor/Player paysage, portrait et variantes régénérées. |
| Player responsive et goldens | `42/42`, analyse ciblée sans problème. |

Le connecteur MCP ambiant configuré dans l'application a retourné `Transport closed`. Il ne prouve donc rien et n'est pas compté. La preuve MCP retenue lance le serveur local du worktree, tandis que `verify:checkout-catalog` lie explicitement l'entrypoint, le commit, les versions et les transports au checkout certifié.

Verdict R5.5 : `DONE` pour le travail de revue. Verdict produit Personalization Studio V3 : `PARTIAL` jusqu'à la revue visuelle humaine de PERS3-33 ; PERS3-34 reste mécaniquement ouvert avec elle.

## 11. Exécution Phase R6 — finition visuelle

### PERS3-R6.8 — Certification ciblée et build Editor

Périmètre certifié : previews, contextes projet, Dialogue, Combat, Titre, Pause, responsive, goldens Editor/Player et harness desktop Marionette. Aucun contrat persistant, schéma ou transport d'authoring n'a changé ; la parité MCP est donc `N/A` pour ce lot.

| Gate | Résultat frais |
|---|---|
| Editor ciblé | `133/133`, succès en concurrence `1`. |
| Player ciblé | `93/93`, succès en concurrence `1`. |
| Analyse Editor | `8` périmètres analysés, aucun problème. |
| Analyse Player | `9` fichiers analysés, aucun problème. |
| Build Editor | `flutter build macos --release`, code `0`, bundle de `70,4 Mo`. |
| Binaire | `packages/map_editor/build/macos/Build/Products/Release/PokeMap.app/Contents/MacOS/PokeMap`, SHA-256 `5d1d9ce31115b957ef75cc5e34432e337dee613075f39faea54e36d246444df1`. |

Le premier passage Editor a produit `129` succès et `4` échecs exclusivement sur les goldens du shell complet : `1440x900`, `1024x768`, `720x900` à texte `200 %`, et Dialogue à `1672x941`. Ces quatre références dataient d'avant la simplification de l'en-tête de preview. Les rendus actuels ont été inspectés avant régénération : options secondaires repliées, scroll visible, canvas plus haut et aucun overflow. La relance complète est ensuite passée à `133/133`. Tous les artefacts temporaires de comparaison Flutter ont été supprimés.

Verdict R6.8 : `DONE`.
