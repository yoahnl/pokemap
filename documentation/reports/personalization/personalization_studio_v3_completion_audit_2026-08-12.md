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
