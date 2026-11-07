# Avelune Studio — Implementation Plan de la refonte UI/UX

> **For agentic workers — Opus :** exécuter ce plan lot par lot avec le workflow executing-plans du dépôt. Les cases servent au suivi, pas à déclarer une fonctionnalité livrée. Lire AGENTS.md, codex_rule.md et les règles les plus proches avant chaque lot. Aucune opération Git d’écriture n’est autorisée par ce document seul.

**Goal:** rendre la création et l’édition d’un jeu Avelune plus intuitives, en préservant toutes les fonctions natives existantes, une navigation stable, une carte centrale, des ressources liées au geste et des réglages dont la portée est explicite.

**Architecture:** conserver Flutter/Dart, les contrôleurs et ports de Studio, les contrats purs de map_core et les mutations canoniques de map_authoring. Adapter les écrans et compléter les frontières manquantes par petits lots. La maquette React est une référence d’ergonomie : ses tableaux, ses copies d’état et son rendu photographique ne sont pas une architecture à porter dans Flutter.

**Tech Stack:** Flutter >= 3.47.5, Dart >= 3.13, Avelune Studio 0.3.37+337 au relevé ; avelune_design_system, map_core, map_authoring, map_distribution, map_runtime et rendu 3D existants.

**Date du dossier :** 6 novembre 2026. **Base technique relue :** main, 33b45abf053488da2297b8e18c8b23207dc6dd11. Vérifier à nouveau HEAD et les changements concurrents au début de l’implémentation.

## 1. Consigne explicite pour Opus : liberté de conception

**Yoahn autorise Opus à prendre des libertés s’il juge qu’elles sont nécessaires.** Opus peut changer une disposition, un composant, un libellé, un raccourci, la granularité d’un lot ou un nom de fichier proposé si le code actuel, l’accessibilité, les performances ou un meilleur parcours le justifient.

Cette liberté doit servir le même objectif et préserver les fonctions. Pour chaque écart matériel, noter dans le ticket du lot : référence concernée, problème constaté, solution retenue, conséquence pour l’utilisateur et preuve de validation. Il n’est pas nécessaire de demander une approbation pour chaque ajustement réversible.

Les maquettes sont une direction de travail, pas un cahier de pixels intangible. Les comportements attendus et les invariants ci-dessous priment. Une nouvelle mécanique de jeu, un changement de contrat protégé, un coût CI supplémentaire, une opération Git ou une extension de périmètre restent régis par les instructions du dépôt.

**Exemple de liberté utile :** si le port audio ne sauvegarde qu’une association à la fois, remplacer un vague « Enregistrer les sons » par « Enregistrer cette association », en conservant les autres brouillons et leur signalement, plutôt que prétendre qu’ils ont tous été mémorisés.

## 2. Dossier, ordre de lecture et sources de vérité

1. Lire ce plan et ses invariants.
2. Lire les constats de l’audit du 3 novembre rattachés au lot (section 8) et la capture native « avant » correspondante.
3. Ouvrir [la galerie et le plan consultable](2026-11-06-refonte-studio/index.html).
4. Examiner les captures liées au lot, puis reproduire le parcours dans [la maquette actuelle](https://designs.magicpath.ai/v1/solid-river-1192).
5. Lire les propriétaires natifs et leurs tests avant de modifier un fichier.
6. Exécuter un lot complet, vérifier le résultat natif puis documenter le verdict.

**État de départ natif.** [L’audit ergonomique du 3 novembre 2026](../audit_ergonomie_studio_2026-11-03.md) recense 48 constats sur le Studio réel (préfixes G, C, M, N, R et T, dont 24 en P1), avec preuves et priorités. C’est la liste de ce qui ne va pas aujourd’hui ; la section 8 rattache chacun à un lot. Les 74 captures natives qui l’illustrent sont dans `/Users/karim/Project/Avelune Studio - Atlas UI/captures/`, hors dépôt : elles servent de référence « avant » à la revue de chaque lot. Ne pas les copier dans ce dossier.

[Projet MagicPath](codex://mcp-app/magicpath@personal/open_magicpath_canvas/projects/468495205939703808) — projet 468495205939703808. Ce lien ne s’ouvre que dans Codex ; ailleurs, utiliser les URL designs.magicpath.ai du tableau ci-dessous. La direction actuelle est le composant 468522639594491904, révision **468810522758889472**. Les captures ne figent pas la page distante : le manifeste conserve la révision de référence.

| Référence | Lien et révision | Usage |
|---|---|---|
| Carte, ressources, accueil, réglages | [solid-river-1192](https://designs.magicpath.ai/v1/solid-river-1192), 468810522758889472 | Référence principale |
| Histoire et personnages | [ready-pond-2660](https://designs.magicpath.ai/v1/ready-pond-2660), 468503558388600832 | Intentions et parcours historiques |
| Tester et exporter | [merrily-sky-9196](https://designs.magicpath.ai/v1/merrily-sky-9196), 468503550826287104 | Séparation test de carte / jeu / export |
| Direction carte précédente | [clearly-peak-2425](https://designs.magicpath.ai/v1/clearly-peak-2425), 468517798264578048 | Historique de conception |
| Première série | [calm-winter-3698](https://designs.magicpath.ai/v1/calm-winter-3698), 468503543205228544 | Historique, sans priorité sur la dernière direction |

Ordre de résolution d’un conflit : instructions de Yoahn et du dépôt ; contrats natifs et données protégées ; comportements de ce plan ; direction actuelle ; références historiques. Ne pas réintroduire « Monde » ou une organisation abandonnée uniquement parce qu’elle figure dans une ancienne capture.

### Ce que montrent les 217 captures

- 107 captures numérotées de parcours, menus, dialogues et variantes de la direction principale ; la fiche 059 couvre aussi la première des 55 fiches d’aide.
- 54 autres fiches d’aide, g002 à g055 : avec 059, les 55 familles sont photographiées.
- 34 vues d’ateliers ou du parcours d’import de source.
- 22 vues historiques des autres composants.
- Toutes mesurent **1 280 × 720**, taille native de la fenêtre du navigateur lors de la collecte ; aucune image n’a été recadrée ni agrandie. Les vues basses de panneaux et les étapes intermédiaires ont leurs propres captures.
- Les fichiers JPEG sont les octets capturés, sans transformation. Jusqu’à la décision D-04, ils étaient enveloppés dans des SVG et la galerie les incorporait une seconde fois en base64. Le manifeste contient dimensions, SHA-256 du JPEG, URL, groupe et rattachement aux lots.

Ce dossier couvre les écrans et états significatifs observés dans les prototypes, y compris leurs 55 fiches. Il ne certifie pas toutes les combinaisons possibles, tous les projets, tous les systèmes d’exploitation ni toutes les fonctions de l’application native. Une fiche décrivant une fonction n’est pas une maquette complète de son atelier.

Le registre précédent classe 55 familles : **15 parcours simulés, 12 réglages illustratifs, 28 parcours décrits**. Cette classification reste une mesure de la maquette, pas de l’état d’avancement du code natif.

## 3. Audit initial du code et conséquences pour le plan

| Zone relue | État observé | Conséquence |
|---|---|---|
| apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_primary_navigation.dart | Huit destinations natives existent déjà, avec les icônes d’origine | Préserver et harmoniser ; ne pas remplacer la navigation par quatre espaces |
| apps/avelune_studio/lib/presentation/features/home/studio_home_screen.dart et studio_home_hero.dart | Accueil, bannière, projets récents, cartes et reprise existent | Adapter les liens et conserver le chargement paresseux |
| apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_view_state.dart | StudioMapTool, paletteTab, prepareCharacterPlacement, prepareTerrainPainting et paletteResources existent | Faire converger intention, outil et palette ; réutiliser les canonicalKind |
| paletteResources | Décors → element/model3d ; Terrains → smartTilePreset ; Tuiles → tileset ; Personnages → character ; Bordures → borderBlueprint ; Environnements → environmentPreset | Ne pas créer une nouvelle taxonomie persistante issue des tableaux React |
| apps/avelune_studio/lib/features/map_workspace/application/spatial_terrain_stroke.dart | SpatialTerrainMode contient ground, relief, ramp | « Chemin » et « Eau » de la maquette ne sont pas des valeurs déjà présentes dans cet enum |
| apps/avelune_studio/lib/presentation/features/project_settings/project_settings_page.dart:139 | keepDraft sauvegarde avant certains changements de carte ou de portée ; l’atelier visuel dépend d’une carte 3D | Retirer les sauvegardes implicites de navigation et découpler les rubriques sans aperçu 3D |
| apps/avelune_studio/lib/features/project_visuals/application/project_visuals_controller.dart | Preview, gestes groupés, undo/redo, révisions, conflits et sauvegarde par port existent | Conserver ces garanties ; ajouter une coordination de session ciblée |
| packages/map_authoring/lib/src/documents/visual_settings_authoring.dart | Stockage project.visual.json et maps/<mapId>.visual.json ; contrôle de révision et reçus | Faire passer l’enregistrement par cette frontière, sans writer de widget |
| packages/map_core/lib/src/models/spatial_visual_profile.dart | SpatialVisualPatch, paramètres, merge et valeurs absentes existent | Retour à l’héritage par retrait du paramètre, pas copie du défaut courant |
| GamePackageExportProfileApiPort et LocalGamePackageExportProfileApi | read, validate, save et deux révisions existent déjà | Général et Export doivent partager ce profil ; ne pas inventer un second document d’identité |
| apps/avelune_studio/lib/features/game_export/data/studio_game_export_controller.dart | Métadonnées du profil lues et sauvegardées dans le parcours export | Extraire ou partager ce service pour éditer l’identité sans lancer un export |
| ProjectAudioPort | Sauvegarde par cue, bibliothèque paginée, import/adoption, résolution et preview existent | Clarifier le grain d’enregistrement et réutiliser les fichiers réels |
| ProjectFieldAbilityRegistry | Onze activations, dont des capacités sans mécanique complète | Ne pas transformer une activation en certification du gameplay |
| packages/avelune_design_system | Composants, thèmes et tokens partagés ; wrappers Studio déjà présents | Étendre le design system, pas multiplier les primitives locales |

### Défauts ou limites de la maquette à ne pas copier

- Le menu Projet décrit encore l’Accueil comme « parcours décrit » alors qu’un accueil est maintenant navigable.
- Les zones 2D sont désactivées dans Règles, mais le menu Ajouter les expose encore comme des choix ordinaires. Une seule politique de disponibilité doit alimenter tous les points d’entrée.
- La carte est une image fixe ; déplacer ou masquer un repère ne prouve pas un effet sur le rendu natif.
- Plusieurs panneaux d’ateliers sont des structures illustratives. Leurs boutons ne prouvent ni import, ni validation géométrique, ni publication réelle.
- Les références historiques ont des nomenclatures et des comptes d’exemple qui ne doivent pas être repris comme données actuelles de HGSS.
- Le son synthétique de la maquette ne représente ni un média HGSS ni le mixage du Player.
- Les 4 associations sonores d’exemple et les 2 cartes ne bornent pas les catalogues natifs.
- Les fenêtres de notification, le focus et les erreurs doivent être vérifiés dans Flutter ; le simple rendu React ne les certifie pas.
- « Masquer pour travailler », « verrouiller la sélection », « visible dans le jeu » et « variante conditionnelle » sont des notions différentes.
- La maquette ne connaît que deux cartes. Son sélecteur en modale (083) et sa colonne « Contenu de la carte » ne disent pas comment circuler parmi les 102 cartes et dossiers de HGSS, que l’arborescence native montre en permanence. Voir D-01.
- Histoire n’est maquettée que par un graphe à trois blocs, et Pokémon pas du tout. Ces espaces n’ont pas de direction de design. Voir D-02.
- L’accueil maquetté présente encore des outils (« Vos outils de création ») plutôt qu’un prochain objectif : c’est le constat G01 de l’audit. Voir D-03.

## 4. Invariants d’implémentation et critères communs

### Navigation et ergonomie

- Conserver Accueil, Carte, Carte régionale, Ressources, Histoire, Pokémon, Réglages du projet, Test du jeu et leurs repères iconographiques.
- La navigation globale indique où l’on travaille ; le contenu de carte indique ce qui existe ; les outils indiquent le geste ; l’inspecteur indique la cible et la portée.
- La palette suit l’intention et le profil réel 2D/3D. « Bibliothèque complète » est une sortie explicite, pas un moyen de désactiver discrètement les règles de compatibilité.
- Une action indisponible explique pourquoi et donne une prochaine action pertinente.
- Les commandes communes, leurs raccourcis, leurs menus et leurs boutons doivent utiliser le même état de disponibilité.
- Garder le graphe visuel des scènes comme éditeur principal. Un résumé lisible complète le graphe ; il ne le remplace pas.
- Tous les gestes usuels sont no-code : sélecteurs recherchables, aperçus, labels et erreurs guidantes ; aucun identifiant brut obligatoire.

### Données, coût et compatibilité

- Une édition locale ne déclenche ni snapshot global, ni relecture de toutes les cartes, ni décodage des ressources sans rapport, ni reconstruction du renderer, ni replay complet de journal.
- Avant chaque lot de mutation, déclarer l’unité stockée, les dépendances réellement affectées et les invalidations nécessaires.
- Cible d’acceptation pour une propriété simple : retour visible <= 100 ms et persistance durable <= 500 ms, au premier geste après ouverture comme aux suivants, sur un projet représentatif documenté. Ces chiffres sont des objectifs, pas des performances déjà prouvées.
- Mesurer le chargement initial séparément ; ne pas le repousser sur la première sauvegarde. Un cache chaud ou un isolate ne valide pas un travail disproportionné.
- Écrire par map_authoring, avec révision attendue, sûreté de crash, identité d’opération et sémantique d’annulation appropriées. Ne pas contourner les garanties avec des fichiers JSON écrits par un widget.
- Préserver la compatibilité cumulative des projets, exports et sauvegardes valides depuis Studio 0.3.31+331. Les lecteurs et conversions déterministes restent aux frontières de données.
- Une sauvegarde n’est annoncée qu’après la réussite de la persistance. Une erreur conserve le brouillon, les originaux et les valeurs inconnues.
- Les terrains, chemins, surfaces, Borders, arbres et environnements gardent leurs systèmes et propriétaires natifs. Pas de terrain assemblé par placement de fragments visuels.
- Aucun contrôle d’activation de capacité ne débloque automatiquement la progression du joueur. Les lots FG-120 et FG-129 restent PARTIAL au relevé de roadmap ; FG-121 à FG-128 sont différés. Ne pas changer ces statuts dans cette refonte UI.
- API directe, JSONL/CLI, Studio et MCP doivent exposer les mêmes changements sémantiques. Pour une modification de disposition pure, justifier N/A.

### Procédure commune de chaque lot

- [ ] Relire les propriétaires, les tests et les changements concurrents ; consigner HEAD.
- [ ] Reproduire le cas courant et un cas négatif avant de changer le code.
- [ ] Écrire le test comportemental du delta, constater son échec attendu.
- [ ] Implémenter la plus petite tranche utile, sans refactor des zones voisines.
- [ ] Exécuter tests ciblés et analyse du package ; étendre la vérification uniquement si le risque l’exige.
- [ ] Mesurer et vérifier la persistance réelle si le lot touche une mutation.
- [ ] Revoir le résultat natif avec les captures de référence et le clavier.
- [ ] Mettre à jour le ticket existant du bon domaine ; TO REVIEW après implémentation vérifiée, DONE uniquement après décision de Yoahn.
- [ ] Relever les PID du runner et de ses descendants pendant les tests, puis arrêter uniquement ses restes confirmés ; jamais de kill global.
- [ ] Nettoyer l’environnement QA de ce lot sous /Users/karim/Library/Caches/AveluneQA/ après contrôle de propriété et des consommateurs.

Les identifiants UX-* ci-dessous sont des **lots de ce plan**, pas de nouveaux tickets Notion. Les rattacher aux tickets existants avant l’exécution ; AS-UX-001 est le contexte de ce dossier. Ne créer aucun grand domaine silencieusement.

## 5. Ordre de livraison et dépendances

| Vague | Lots | Résultat utilisable |
|---|---|---|
| A — fondations | UX-00, UX-01, UX-02, UX-02.1, UX-03, UX-03.1 | Shell cohérent, accueil, navigation et commandes accessibles ; défauts isolés de l’audit corrigés tôt |
| B — édition de carte | UX-04 à UX-10 | Outil, palette, contenu, sélection et édition native cohérents |
| C — ressources | UX-11, UX-12, UX-12.1 à UX-12.5, UX-13 | Bibliothèque et ateliers raccordés, usages et diagnostics fiables |
| D — réglages | UX-14 à UX-20 | Brouillons par rubrique, identité partagée, héritage et sons réels |
| E — jeu et narration | UX-21, UX-22 | Test/export guidés et graphe de scène préservé |
| F — couverture spécialisée | UX-23.1 à UX-23.8 | Les familles décrites ont leur parcours natif détaillé |
| G — certification | UX-24, UX-25, UX-26 | Parité, coût borné, compatibilité et acceptation native |

Les vérifications de parité et de coût sont des critères de chaque lot ; UX-24 et UX-25 réunissent leurs preuves finales. Ne pas les repousser jusqu’à la fin pour des chemins déjà modifiés.

~~~mermaid
flowchart TD
  A[UX-00 Audit] --> B[UX-01 Design system]
  A --> P[UX-03.1 Correctifs isolés de l’audit]
  P --> M
  B --> C[UX-02 Navigation et accueil]
  C --> D[UX-04 Outil et intention]
  D --> E[UX-05 Palette]
  E --> F[UX-06 à UX-10 Carte]
  E --> G[UX-11 à UX-13 Ressources]
  C --> H[UX-14 Brouillons]
  H --> I[UX-15 à UX-20 Réglages]
  F --> J[UX-21 Test et export]
  I --> J
  F --> K[UX-22 Graphe]
  K --> L[UX-23 Parcours spécialisés]
  G --> M[UX-24 Parité]
  J --> M
  L --> M
  M --> N[UX-25 Coût]
  N --> O[UX-26 Acceptation]
~~~

Les fichiers indiqués comme « Créer » sont des points de découpage proposés. Opus peut déplacer ou réutiliser une abstraction existante s’il démontre que cela évite un doublon.

### Décisions produit à trancher avant les lots concernés

Ces choix appartiennent à Yoahn. Le 6 novembre 2026, il a retenu les recommandations de la revue pour D-01, D-02 et D-03, puis l’option b) pour D-04, appliquée le jour même. Un lot bloqué ne commence pas tant que sa décision reste ouverte. Consigner toute révision d’une décision et sa date dans le ticket, puis mettre à jour la colonne Statut.

| ID | Question | Options | Recommandation de la revue | Lots bloqués | Statut |
|---|---|---|---|---|---|
| D-01 | Où vit l’arborescence des cartes dans le nouveau shell ? | a) colonne gauche à deux onglets, Cartes et Contenu de la carte ; b) arborescence repliable au-dessus du contenu ; c) fil d’Ariane et modale seuls, comme la maquette | a). HGSS compte 102 cartes dans des dossiers imbriqués ; une modale conçue pour deux cartes ne tient pas cette échelle. L’audit (M05 et sa section 7) demande de garder l’arbre pour organiser et un sélecteur pour changer vite. | UX-02.1, UX-06 | **Tranchée le 6 novembre 2026 par Yoahn : option a)** |
| D-02 | Histoire et Pokémon entrent-ils dans la refonte visuelle ? | a) passe de design MagicPath dédiée avant les lots concernés ; b) hors refonte visuelle : corriger les constats de l’audit dans les écrans actuels, harmonisés par le design system | a) pour Histoire : N01 à N05 sont des P1 et la maquette n’en montre qu’un graphe à trois blocs. b) pour Pokémon, dont les écrans sont surtout des formulaires de données. | Refonte visuelle de UX-22 et UX-23.1 à UX-23.6 ; leurs étapes issues de l’audit n’en dépendent pas | **Tranchée le 6 novembre 2026 par Yoahn : a) pour Histoire, b) pour Pokémon** |
| D-03 | L’accueil présente-t-il des outils ou un prochain objectif ? | a) des outils, comme la maquette ; b) un parcours court lié à l’état réel du projet, accès directs conservés (G01) | b), à éprouver sur un vrai premier usage : l’audit précise que G01 n’est pas une preuve d’échec. | UX-02 | **Tranchée le 6 novembre 2026 par Yoahn : option b)** |
| D-04 | Les captures de ce dossier entrent-elles dans Git ? | a) en l’état, environ 40 Mo : 19 Mo de SVG plus une galerie de 21 Mo qui réintègre les mêmes images ; b) JPEG bruts référencés par la galerie ; c) hors dépôt, le manifeste conservant les empreintes | b) ou c) : le poids actuel est payé deux fois, et pour toujours dans l’historique. | Aucun lot ; avant tout commit de ce dossier | **Tranchée le 6 novembre 2026 par Yoahn : option b), appliquée** |

## 6. Les 41 lots d’implémentation

Les nouvelles cibles de test sont à créer pendant leur lot. Les fichiers listés comme existants ont été contrôlés sur disque. Les commandes ci-dessous décrivent la validation à exécuter pendant l’implémentation ; elles ne sont pas des résultats déjà obtenus.

### UX-00 — Geler le périmètre et les contrats de départ

**Priorité :** P0. **Dépendances :** aucune.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/shell/studio_shell.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_view_state.dart
- packages/map_authoring/lib/src/documents/visual_settings_authoring.dart

**Étapes d’implémentation :**

- [ ] 1. Rapprocher les 55 familles de l’annexe des écrans natifs ; classer chaque delta en adaptation UI, contrat manquant ou mécanique différée.
- [ ] 2. Relever les transports existants, les canonicalKind, les paramètres de profil et la persistance réelle de chaque commande.
- [ ] 3. Vérifier le projet représentatif HGSS sur une copie QA minimale autorisée et une fixture 2D ; séparer ouverture, premier geste et sauvegardes répétées.
- [ ] 4. Relever les tests actuels, les changements concurrents et les tickets existants ; attribuer chaque lot à un seul domaine.
- [ ] 5. Arrêter les décisions de portée : masquage d’édition versus visibilité en jeu ; identité de projet versus identité du jeu ; sélection de l’aperçu versus cible d’édition.
- [ ] 6. Vérifier que les décisions D-01 à D-04, tranchées le 6 novembre (section 5), restent compatibles avec le code au HEAD courant.
- [x] 7. Revérifier que chaque constat de l’audit du 3 novembre existe encore au HEAD courant ; marquer un constat déjà corrigé dans la table de la section 8 plutôt que de le traiter à nouveau.

**Tests comportementaux obligatoires :**

- Chaque famille a un propriétaire et un lot ; aucune fonction existante ne disparaît silencieusement.
- Chaque constat de l’audit a un lot, ou une raison écrite de ne pas le traiter.
- Les fonctions différées restent visibles avec disponibilité exacte, sans action factice.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/home/home_navigation_test.dart
- apps/avelune_studio/test/presentation/resource_library_intent_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/home/home_navigation_test.dart test/presentation/resource_library_intent_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Audit en lecture seule ; aucun projet ni schéma modifié.

**Sortie du lot :** Matrice propriétaire/commande/profil/transport validée ; décisions D-01 à D-04 confirmées au HEAD courant ; première tranche A sélectionnée sans reconstruire des fonctions déjà disponibles.

**Références visuelles :** [002-accueil](2026-11-06-refonte-studio/captures/002-accueil.jpg), [003-menu-projet](2026-11-06-refonte-studio/captures/003-menu-projet.jpg).


### UX-01 — Primitives, disposition, focus et états communs

**Priorité :** P0. **Dépendances :** UX-00.

**Modifier ou réutiliser les propriétaires existants :**

- packages/avelune_design_system/lib/presentation/theme/studio_tokens.dart
- packages/avelune_design_system/lib/presentation/shared/widgets/layout/studio_panel.dart
- apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_app_shell.dart
- apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_action_bar.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/presentation/studio_workspace_accessibility_test.dart

**Étapes d’implémentation :**

- [x] 1. Inventorier les primitives déjà exportées par avelune_design_system et les adaptateurs Studio avant d’en ajouter.
- [x] 2. Ajouter dans le design system les seules variantes nécessaires : provenance, brouillon, champ mixte, erreur, état vide et panneau repliable.
- [x] 3. Définir les rôles clavier et les noms accessibles des icônes ; rendre le focus visible en thème clair et sombre.
- [x] 4. Adapter les largeurs de panneaux et le mode Carte seule ; mémoriser les préférences de disposition comme préférences Studio, pas comme paramètres du jeu.
- [x] 5. Gérer une petite fenêtre par panneaux repliables ou défilement local, sans cacher une action de sauvegarde ou un message d’erreur.
- [x] 6. Relever dans la direction actuelle l’échelle typographique, les espacements, la densité des barres et des listes, les surfaces et les rayons ; les exprimer en tokens du design system avant d’adapter un écran, pour que les lots suivants n’inventent pas chacun leur style. Comparer avec les captures natives de l’Atlas pour nommer l’écart visé.
- [x] 7. Rendre partout les aperçus pixel art sans lissage, avec la même netteté (audit R11, à confirmer par comparaison avant de changer un rendu).

**Tests comportementaux obligatoires :**

- À 1280×720 puis sur une fenêtre plus étroite, navigation et action principale restent accessibles au clavier.
- Une modale rend le focus à son déclencheur ; Échap ferme la modale sans annuler un brouillon métier.
- La couleur seule ne porte ni l’erreur, ni la sélection, ni l’héritage.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/presentation/map_workspace_layout_responsive_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/presentation/studio_workspace_accessibility_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/presentation/map_workspace_layout_responsive_test.dart test/presentation/studio_workspace_accessibility_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Disposition et focus uniquement ; aucun auteur de données. Invalidation locale des panneaux.

**Sortie du lot :** Aucun débordement bloquant ; tous les états passent par les tokens et composants partagés ; pas de palette locale hardcodée.

**Références visuelles :** [056-menu-affichage](2026-11-06-refonte-studio/captures/056-menu-affichage.jpg), [057-carte-seule](2026-11-06-refonte-studio/captures/057-carte-seule.jpg), [106-reglages-sans-apercu](2026-11-06-refonte-studio/captures/106-reglages-sans-apercu.jpg).


### UX-02 — Préserver les huit destinations et l’accueil

**Priorité :** P0. **Dépendances :** UX-01.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_primary_navigation.dart
- apps/avelune_studio/lib/presentation/shell/studio_home_navigation.dart
- apps/avelune_studio/lib/presentation/features/home/studio_home_screen.dart
- apps/avelune_studio/lib/presentation/features/home/studio_home_hero.dart
- apps/avelune_studio/lib/presentation/features/home/studio_home_projects.dart
- apps/avelune_studio/lib/presentation/features/home/studio_home_tools.dart
- apps/avelune_studio/lib/presentation/features/home/studio_home_guidance.dart
- apps/avelune_studio/lib/presentation/features/project_session/project_open_controls.dart

**Décision :** D-03 tranchée, option b) : l’accueil propose un prochain objectif ; les outils restent en accès direct.

**Étapes d’implémentation :**

- [x] 1. Conserver l’ordre, les icônes et les labels des huit destinations natives ; activer Histoire pour scènes/dialogues/événements/cinématiques.
- [x] 2. Préserver la bannière originale, les projets récents, la reprise et les cartes ; utiliser les données natives chargées à la demande.
- [x] 3. Relier chaque carte à son identité stable et chaque outil d’accueil à une intention de création explicite.
- [x] 4. Faire revenir « Commencer par le sol » au geste Sol ; « Reprendre » restaure le contexte réel de la dernière carte.
- [x] 5. Corriger les descriptions et compteurs obsolètes de la maquette ; les états vide, fermé, en lecture seule et récupération utilisent les états natifs.
- [x] 6. Remplacer « Projet ouvert — lecture seule », affiché dès qu’un projet est ouvert (project_open_controls.dart:75), par l’état exact : nommer « lecture seule » seulement pour un document où l’écriture est réellement impossible, avec la raison et l’action possible (audit G03).
- [x] 7. Proposer après ouverture un parcours court lié à l’état réel (carte, départ, personnage, interaction, test). Il peut être ignoré, laisse les accès directs aux experts et n’affiche « fait » que sur preuve (audit G01).

**Tests comportementaux obligatoires :**

- Changer d’espace n’enregistre pas un brouillon de réglage et ne remplace pas la sélection d’une carte.
- Le retour Accueil conserve les brouillons ; un aperçu fermé ne continue pas à décoder ses images.
- Les comptes affichés viennent des données natives chargées à la demande (102 cartes, 426 scènes et 593 dialogues pour HGSS au relevé de l’audit) ; aucun n’est codé en dur.
- Un projet ouvert en écriture n’affiche aucune mention globale de lecture seule ; une vraie session en lecture seule nomme le document concerné et sa raison.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/home/home_navigation_test.dart
- apps/avelune_studio/test/home/home_lazy_collection_test.dart
- apps/avelune_studio/test/home/home_closed_preview_lifecycle_test.dart
- apps/avelune_studio/test/home/home_character_navigation_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/home/home_navigation_test.dart test/home/home_lazy_collection_test.dart test/home/home_closed_preview_lifecycle_test.dart test/home/home_character_navigation_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** État de navigation et préférences ; aucun rewrite du projet pour un changement d’espace.

**Sortie du lot :** Les huit destinations natives restent atteignables ; le bon état actif est annoncé ; l’accueil fonctionne avec ou sans carte 3D.

**Références visuelles :** [002-accueil](2026-11-06-refonte-studio/captures/002-accueil.jpg), [105-accueil-cartes](2026-11-06-refonte-studio/captures/105-accueil-cartes.jpg), [003-menu-projet](2026-11-06-refonte-studio/captures/003-menu-projet.jpg).


### UX-02.1 — Catalogue de cartes, dossiers et création guidée

**Priorité :** P1. **Dépendances :** UX-02.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/map_workspace/map_library_navigator.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_library_tree.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_library_navigator_forms.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_creation_tools.dart
- apps/avelune_studio/lib/presentation/features/project_creation/project_creation_dialog.dart
- apps/avelune_studio/lib/presentation/features/project_creation/project_creation_steps.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_catalogue_creation_dialog.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_library_row_tile.dart

**Décision :** D-01 tranchée, option a) : la colonne gauche de l’espace Carte porte deux onglets, Cartes et Contenu de la carte.

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/presentation/map_library_creation_context_test.dart

**Étapes d’implémentation :**

- [x] 1. Préserver la création de projet 2D/3D, les validations et le choix de destination ; ne pas coupler cette création aux données d’exemple.
- [x] 2. Conserver création, duplication, rôle, dimensions et classement des cartes via les commandes canoniques existantes.
- [x] 3. Rendre dossiers, recherche et sélection multiple explicites ; distinguer nom affiché et identité stable.
- [x] 4. Après création ou déplacement, ouvrir la bonne carte en gardant l’historique du document précédent.
- [x] 5. Traiter annulation du sélecteur natif, nom invalide, destination non admissible et conflit sans créer de projet ou carte partiel.
- [x] 6. Placer l’arborescence des cartes dans l’onglet Cartes de la colonne gauche, à côté de Contenu de la carte (D-01). Le fil d’Ariane et un sélecteur rapide restent des raccourcis, pas le seul accès. À l’échelle de HGSS, changer de carte ne passe pas par une modale bloquante et ne referme pas le dossier courant ; le nom complet et le chemin s’affichent au focus et à la sélection, et une recherche comprend noms et dossiers (audit M05).
- [x] 7. Au choix 2D/3D, montrer ce que chaque modèle contient réellement et ce qu’il manque avant un test ; « prêt à tester » seulement si un test le confirme (audit C01). Donner la priorité au nom du jeu, le dossier restant ajustable avec aperçu du chemin final et ses vérifications actuelles (audit C02).
- [x] 8. À la création de carte, dire à quoi sert la planche proposée et l’organiser par usage ; ne pas déclarer une ressource invalide sur la foi de son nom (audit C03).

**Tests comportementaux obligatoires :**

- Créer une carte puis l’ouvrir conserve ses dimensions, son rôle et son identité après réouverture.
- Avec un catalogue de la taille de HGSS, ouvrir une carte d’un autre dossier conserve l’arborescence ouverte et la carte précédente dans l’historique.
- Annuler une destination ne crée aucun dossier métier.
- Classer des cartes n’altère pas les passages qui les référencent.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/home/home_map_creation_entry_test.dart
- apps/avelune_studio/test/presentation/map_library_navigation_test.dart
- apps/avelune_studio/test/project_creation/home_creation_entry_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/presentation/map_library_creation_context_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/home/home_map_creation_entry_test.dart test/presentation/map_library_navigation_test.dart test/project_creation/home_creation_entry_test.dart test/presentation/map_library_creation_context_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Catalogue et carte créée ou classée ; création explicite distincte d’une édition locale. Aucun parcours de toutes les cartes pour un simple renommage.

**Sortie du lot :** Les projets, dossiers et cartes se créent et s’organisent depuis l’accueil ou la bibliothèque sans nouvelle architecture ni perte de référence.

**Références visuelles :** [083-cartes-projet](2026-11-06-refonte-studio/captures/083-cartes-projet.jpg), [059-guide-mode-emploi](2026-11-06-refonte-studio/captures/059-guide-mode-emploi.jpg), [h12-premiere-direction](2026-11-06-refonte-studio/captures/h12-premiere-direction.jpg).


### UX-03 — Commandes, aide contextuelle et raccourcis cohérents

**Priorité :** P1. **Dépendances :** UX-02.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_tool_strip_actions.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_tool_strip.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/lib/presentation/shared/widgets/dialogs/studio_command_palette.dart
- apps/avelune_studio/test/presentation/studio_command_palette_test.dart

**Étapes d’implémentation :**

- [x] 1. Décrire les commandes par identifiant stable, label, raccourci, disponibilité et exécuteur existant ; réutiliser le registre déjà présent s’il remplit ce rôle.
- [x] 2. Alimenter menus, barre d’outils et recherche avec ces mêmes commandes.
- [x] 3. Ajouter recherche d’intention et aide « Comment faire » liée au geste ; conserver les 55 familles comme couverture documentaire.
- [x] 4. Gérer ⌘/Ctrl K, focus initial, navigation fléchée, Entrée et Échap ; préserver la saisie dans un champ ou un graphe.
- [x] 5. Ouvrir les sélecteurs natifs depuis l’aide plutôt qu’un faux parcours ; qualifier les fonctions indisponibles par le profil.

**Tests comportementaux obligatoires :**

- Chercher « falaise » propose la commande et son aide ; une fonction différée n’obtient pas un bouton exécutable fictif.
- Un raccourci de suppression ne retire rien quand le focus édite du texte.
- Les mêmes préconditions s’appliquent depuis Ajouter, Règles et la palette de commandes.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/map_workspace/spatial_navigation_tools_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/presentation/studio_command_palette_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/map_workspace/spatial_navigation_tools_test.dart test/presentation/studio_command_palette_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Recherche dans les descripteurs déjà disponibles ; aucune lecture des fichiers de toutes les cartes à chaque frappe.

**Sortie du lot :** Commande, aide et disponibilité sont reliées sans dupliquer la logique métier ; nomenclature cohérente dans tous les points d’entrée.

**Références visuelles :** [058-commandes](2026-11-06-refonte-studio/captures/058-commandes.jpg), [059-guide-mode-emploi](2026-11-06-refonte-studio/captures/059-guide-mode-emploi.jpg), [008-menu-construire](2026-11-06-refonte-studio/captures/008-menu-construire.jpg), [022-menu-regles](2026-11-06-refonte-studio/captures/022-menu-regles.jpg).


### UX-03.1 — Correctifs isolés de l’audit du 3 novembre

**Priorité :** P1. **Dépendances :** UX-00.

Ces défauts ont été revérifiés dans le code le 6 novembre 2026. Ils ne dépendent pas du nouveau shell : les corriger tôt donne des gains visibles au lieu de les laisser attendre dans des lots P2. Ce sont des réparations : aucun nouveau ticket Notion (AGENTS.md, exclusions de création de tickets).

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/events/event_scene_effects.dart
- apps/avelune_studio/lib/presentation/features/cinematics/cinematic_inspector_actors.dart
- apps/avelune_studio/lib/presentation/features/presentations/presentation_library.dart
- apps/avelune_studio/lib/presentation/features/presentations/presentation_page_body.dart
- apps/avelune_studio/lib/presentation/features/project_settings/project_settings_page.dart
- apps/avelune_studio/lib/presentation/features/regional_map/regional_map_page.dart
- apps/avelune_studio/lib/features/regional_map/application/regional_map_controller.dart
- apps/avelune_studio/lib/presentation/features/pokemon/pokemon_commerce_page.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/presentation/audit_isolated_label_test.dart
- apps/avelune_studio/test/presentation/regional_map_explicit_map_link_test.dart

**Étapes d’implémentation :**

- [ ] 1. N06 — Une action de scène sans titre affiche « Action de scène · null » (event_scene_effects.dart:35). Afficher un libellé de secours lisible, par exemple « Action sans nom », et garder l’accès au bloc quand son identité est connue ; ne pas inventer la cause de la valeur manquante.
- [ ] 2. N09 — Appliquer la même règle aux acteurs et entités de cinématique qui affichent `null · <id>` (cinematic_inspector_actors.dart:23 et :71) ; l’identifiant reste visible pour le diagnostic.
- [ ] 3. N10 — Donner le même libellé et la même description aux deux commandes qui appellent la même création : « Nouvelle cinématique » (presentation_library.dart:145) et « Créer une présentation » (presentation_page_body.dart:87). Garder les deux points d’entrée s’ils servent des moments différents.
- [ ] 4. G04 — Renommer « Scène à tester » en « Carte à tester » tant que le sélecteur liste des cartes (project_settings_page.dart:197). Aucune donnée persistée n’est renommée.
- [ ] 5. M09 — Ne plus lier implicitement la première carte du projet (regional_map_page.dart:65) à la création d’un lieu ou à l’activation de Vol : demander ou confirmer la carte avec nom, dossier et aperçu. Les liens déjà enregistrés ne changent pas. Reproduire d’abord le parcours : l’audit l’a établi par le code seul.
- [ ] 6. R06 — Afficher des libellés lisibles pour les poches d’objets (`medicine`, `balls`, `key_items`, pokemon_commerce_page.dart) en conservant les identifiants dans les données et en détail. Le choix validé de la poche reste dans UX-23.6.

**Tests comportementaux obligatoires :**

- Un nœud d’action sans titre s’affiche « Action sans nom » ; aucun résumé d’événement ni inspecteur de cinématique ne contient le texte `null`.
- Les deux points d’entrée de création de présentation affichent le même libellé et créent le même type de document.
- Créer un lieu régional sans choisir de carte n’enregistre aucune liaison ; les liaisons d’un projet rouvert sont inchangées.
- Une poche connue s’affiche avec son libellé ; une poche inconnue garde son identifiant sans être effacée.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/application/regional_map_controller_test.dart
- apps/avelune_studio/test/presentation/regional_map_page_test.dart
- apps/avelune_studio/test/ui11_presentation_widget_test.dart
- apps/avelune_studio/test/pokemon/pokemon_commerce_host_test.dart
- apps/avelune_studio/test/project_visuals/project_settings_navigation_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/presentation/audit_isolated_label_test.dart
- apps/avelune_studio/test/presentation/regional_map_explicit_map_link_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/application/regional_map_controller_test.dart test/presentation/regional_map_page_test.dart test/ui11_presentation_widget_test.dart test/pokemon/pokemon_commerce_host_test.dart test/project_visuals/project_settings_navigation_test.dart test/presentation/audit_isolated_label_test.dart test/presentation/regional_map_explicit_map_link_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Libellés de présentation uniquement, sauf M09 : la création d’un lieu ou l’activation de Vol n’écrit que le catalogue régional ciblé, après un choix explicite. Aucune migration des liens existants. Parité : le changement de M09 porte sur le parcours Studio ; vérifier que l’API canonique exige déjà une carte explicite, sinon le signaler à UX-24.

**Sortie du lot :** Les six défauts sont corrigés et couverts par des tests ; aucun lien régional n’est plus créé sans choix explicite.

**Références visuelles :** captures natives de l’Atlas, hors dépôt : 39 (déclencheur, N06), 48 (acteurs, N09), 51 (présentations, N10), 32 (réglages, G04), 29 (objets, R06). M09 n’a pas de capture : reproduction requise.


### UX-04 — Une intention active commune à l’outil et à l’inspecteur

**Priorité :** P0. **Dépendances :** UX-02, UX-03.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_view_state.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_tool_strip.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_tool_strip_selection.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_inspector.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/lib/presentation/features/map_workspace/map_palette_intent.dart
- apps/avelune_studio/test/map_workspace/map_palette_intent_test.dart

**Étapes d’implémentation :**

- [x] 1. Établir la table native geste→outil→mode de terrain→ressource attendue→inspecteur→annulation ; conserver les enums et contrats existants.
- [x] 2. Organiser les entrées en Construire, Peupler, Règles et Ambiance ; garder Sélection et Déplacer accessibles.
- [x] 3. Résoudre Sol, Chemin et Eau avec les presets/patterns/capacités natives ; ne pas ajouter path/water dans SpatialTerrainMode par simple copie du prototype.
- [x] 4. Faire de l’intention un état de présentation unique ; dériver le panneau et la palette de cet état.
- [x] 5. Changer de geste invalide une ressource ou un brouillon de placement incompatible ; Échap quitte le geste sans effacer une édition déjà validée.
- [x] 6. Donner une place découvrable aux intentions Personnage, Départ, Interaction et Passages, aujourd’hui cachées dans le menu « … » qui répète aussi la barre ; une commande présente à plusieurs endroits garde le même nom, le même résultat et le même état (audit M02).
- [x] 7. Une consigne ne renvoie jamais vers un panneau absent : ouvrir le panneau attendu ou expliquer sur place pourquoi il manque et comment continuer. Reproduire d’abord dans un Studio normal, l’audit l’ayant observé dans un build de capture (audit M04).

**Tests comportementaux obligatoires :**

- Choisir un décor depuis la bibliothèque active son outil natif et garde le bon propriétaire.
- Passer de Falaise à Personnage ne conserve pas un profil de bordure comme ressource active.
- Les zones incompatibles sont indisponibles depuis tous les menus, y compris Ajouter.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/presentation/ui02_palette_test.dart
- apps/avelune_studio/test/map_workspace/spatial_navigation_tools_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/map_workspace/map_palette_intent_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/presentation/ui02_palette_test.dart test/map_workspace/spatial_navigation_tools_test.dart test/map_workspace/map_palette_intent_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** État d’outil en mémoire ; pas de mutation de projet pour ouvrir un menu.

**Sortie du lot :** Une commande ne peut plus afficher une palette ou des options correspondant au geste précédent.

**Références visuelles :** [001-carte-sol](2026-11-06-refonte-studio/captures/001-carte-sol.jpg), [004-carte-chemin](2026-11-06-refonte-studio/captures/004-carte-chemin.jpg), [005-carte-eau](2026-11-06-refonte-studio/captures/005-carte-eau.jpg), [018-menu-peupler](2026-11-06-refonte-studio/captures/018-menu-peupler.jpg), [082-menu-ajouter](2026-11-06-refonte-studio/captures/082-menu-ajouter.jpg).


### UX-05 — Palette de ressources strictement liée au geste

**Priorité :** P0. **Dépendances :** UX-04.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_view_state.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_palette_dock.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_palette_dock_filters.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_catalog.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/presentation/map_palette_context_compatibility_test.dart

**Étapes d’implémentation :**

- [x] 1. Filtrer d’abord les canonicalKind et capacités admissibles pour la carte active, puis les filtres de l’utilisateur.
- [x] 2. Utiliser les rôles natifs pour les sols/chemins/eau ; ne pas inférer la sémantique depuis le nom, les tags ou la famille libre.
- [x] 3. Exclure les pièces de contours du placement de décor et garder les arbres/environnements dans leur système natif.
- [x] 4. Mémoriser recherche, famille et défilement par intention ; séparer cet état des filtres de la bibliothèque.
- [x] 5. Rendre explicites les deux états vides : aucune ressource compatible prête, ou aucune correspondance avec les filtres.
- [x] 6. « Préparer les ressources » ouvre le bon atelier ; « Bibliothèque complète » ouvre volontairement le catalogue complet ; un reset de recherche ne désactive pas la compatibilité.
- [x] 7. Conserver la virtualisation des vignettes et les index de métadonnées ; aucun décodage de média pour un filtre textuel.
- [x] 8. Garder la recherche accessible dans un dock étroit (moins de 420 px), au besoin derrière une icône nommée, au lieu de la faire disparaître (audit M06).

**Tests comportementaux obligatoires :**

- Une recherche « lit » en bibliothèque ne masque pas les sols de la palette.
- Après un changement de carte 3D→2D, une ressource refusée n’est ni sélectionnée ni placée.
- Pièces sources, ressources non prêtes et références manquantes restent inspectables dans la bibliothèque, jamais utilisables par erreur.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/presentation/map_workspace_palette_dock_filters_test.dart
- apps/avelune_studio/test/presentation/map_workspace_resource_families_test.dart
- apps/avelune_studio/test/map_workspace/working_catalog_resource_scope_compatibility_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/presentation/map_palette_context_compatibility_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/presentation/map_workspace_palette_dock_filters_test.dart test/presentation/map_workspace_resource_families_test.dart test/map_workspace/working_catalog_resource_scope_compatibility_test.dart test/presentation/map_palette_context_compatibility_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** État de filtre local ; requêtes de métadonnées ciblées. Décodages et lectures de données non pertinentes : zéro lors d’une frappe.

**Sortie du lot :** Seules les ressources admissibles au geste sont présentées comme utilisables ; les filtres et la bibliothèque ne se contaminent pas.

**Références visuelles :** [001-carte-sol](2026-11-06-refonte-studio/captures/001-carte-sol.jpg), [004-carte-chemin](2026-11-06-refonte-studio/captures/004-carte-chemin.jpg), [005-carte-eau](2026-11-06-refonte-studio/captures/005-carte-eau.jpg), [019-palette-decors](2026-11-06-refonte-studio/captures/019-palette-decors.jpg), [020-palette-environnements](2026-11-06-refonte-studio/captures/020-palette-environnements.jpg), [021-palette-personnage-indisponible](2026-11-06-refonte-studio/captures/021-palette-personnage-indisponible.jpg).


### UX-06 — Contenu logique de carte et objets difficiles à retrouver

**Priorité :** P0. **Dépendances :** UX-04.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_inspector.dart
- apps/avelune_studio/lib/features/map_workspace/application/map_element_catalog.dart
- apps/avelune_studio/lib/features/map_workspace/application/map_workspace_element_order.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/map_workspace/map_content_logical_groups_test.dart

**Étapes d’implémentation :**

- [x] 1. Faire l’inventaire des catégories réelles : sols, surfaces, chemins, bordures, décors, personnages, environnements, enfants générés, passages, connexions, départ, zones et lumières.
- [x] 2. Conserver l’identité de chaque élément et afficher son propriétaire ; un arbre généré renvoie à sa zone d’environnement.
- [x] 3. Ajouter recherche, filtres Tous/Masqués/Verrouillés/Sélection et compteurs dérivés du même index.
- [x] 4. Permettre de retrouver un élément masqué ou sous un autre sans déplacer ses voisins ; synchroniser sélection et centrage du viewport.
- [x] 5. Présenter l’ordre logique et les possibilités devant/derrière sans imposer de calques manuels.
- [x] 6. Distinguer le masquage de travail et la visibilité en jeu dans labels, portées et données.
- [x] 7. Partager la colonne gauche avec l’onglet Cartes (D-01) : passer d’un onglet à l’autre conserve recherche, filtres, défilement et sélection de chacun.

**Tests comportementaux obligatoires :**

- Un enfant généré reste repérable et ne devient pas une copie indépendante à l’édition.
- Masquer un groupe ne perd ni les identités ni les références ; restaurer le filtre donne le même contenu.
- Le choix dans une liste et celui dans le viewport sélectionnent le même élément natif.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/map_workspace/selection_identity_test.dart
- apps/avelune_studio/test/map_workspace/locked_element_selection_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/map_workspace/map_content_logical_groups_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/map_workspace/selection_identity_test.dart test/map_workspace/locked_element_selection_test.dart test/map_workspace/map_content_logical_groups_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Index de la carte active ; seules les dépendances d’ordre et de visibilité concernées sont invalidées.

**Sortie du lot :** Tous les types natifs utiles sont trouvables ; aucune création de calque n’est nécessaire pour placer ou retrouver un décor.

**Références visuelles :** [051-selection-simple](2026-11-06-refonte-studio/captures/051-selection-simple.jpg), [053-element-masque](2026-11-06-refonte-studio/captures/053-element-masque.jpg), [054-filtre-masques](2026-11-06-refonte-studio/captures/054-filtre-masques.jpg), [086-calques-explication](2026-11-06-refonte-studio/captures/086-calques-explication.jpg).


### UX-07 — Sélection, édition multiple et historique contextuel

**Priorité :** P0. **Dépendances :** UX-06.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/map_workspace/map_selection_inspector.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_decor_inspector_tabs.dart
- apps/avelune_studio/lib/features/map_workspace/application/map_editing_commands.dart
- apps/avelune_studio/lib/features/map_workspace/application/map_workspace_history_destinations.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/map_workspace/map_selection_scope_regression_test.dart

**Étapes d’implémentation :**

- [x] 1. Montrer occurrence, propriétaire et portée ; séparer Sélection et Carte dans l’inspecteur.
- [x] 2. Afficher les champs mixtes sans valeur arbitraire ; expliquer quels éléments verrouillés seront préservés.
- [x] 3. Brancher déplacement, duplication, rotation, remplacement local et retrait sur les commandes ciblées existantes.
- [x] 4. Grouper un geste continu en une unité d’annulation et vider le rétablissement lors d’une nouvelle édition.
- [x] 5. Faire suivre Annuler/Rétablir au document actif sans fusionner historique de carte et de réglages.
- [x] 6. Bloquer une référence périmée ou supprimée après changement de carte ; conserver les conflits externes et leurs actions de résolution.

**Tests comportementaux obligatoires :**

- Lit et bureau ont X différent : le champ est mixte ; une saisie agit uniquement sur les éléments admissibles.
- Un élément verrouillé ne bouge pas avec la sélection multiple.
- Annuler puis éditer retire la branche de rétablissement ; remplacer ici ne modifie pas la définition partagée.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/map_workspace/inspector_fields_undo_test.dart
- apps/avelune_studio/test/map_workspace/locked_element_selection_test.dart
- apps/avelune_studio/test/map_workspace/resource_deleted_history_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/map_workspace/map_selection_scope_regression_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/map_workspace/inspector_fields_undo_test.dart test/map_workspace/locked_element_selection_test.dart test/map_workspace/resource_deleted_history_test.dart test/map_workspace/map_selection_scope_regression_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Occurrences de la carte et journal canonique touchés ; aucune réécriture du catalogue pour une coordonnée locale.

**Sortie du lot :** Champs, historique, sélection et persistance restent cohérents après annulation, conflit et changement de carte.

**Références visuelles :** [051-selection-simple](2026-11-06-refonte-studio/captures/051-selection-simple.jpg), [052-selection-multiple](2026-11-06-refonte-studio/captures/052-selection-multiple.jpg), [055-element-verrouille](2026-11-06-refonte-studio/captures/055-element-verrouille.jpg), [084-remplacer-occurrence](2026-11-06-refonte-studio/captures/084-remplacer-occurrence.jpg), [085-retirer-occurrence](2026-11-06-refonte-studio/captures/085-retirer-occurrence.jpg).


### UX-08 — Placement natif, environnements et décor extérieur

**Priorité :** P0. **Dépendances :** UX-05, UX-07.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/features/map_workspace/application/map_element_placement_commands.dart
- apps/avelune_studio/lib/features/map_workspace/application/environment_editing_commands.dart
- apps/avelune_studio/lib/features/map_workspace/application/map_exterior_decoration_controller.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_environment_tool_panel.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/map_workspace/map_placement_intent_journey_test.dart

**Étapes d’implémentation :**

- [x] 1. Relier sélection de ressource, prévisualisation du placement, validation et annulation au port natif.
- [x] 2. Conserver une ressource complète comme occurrence ; ne pas découper les arbres ni les bordures pour les poser séparément.
- [x] 3. Pour un environnement, montrer contour, répartition, ressources et propriété des éléments générés.
- [x] 4. Séparer Zone jouable et Décor extérieur dans la cible active ; afficher cette cible avant le premier placement.
- [x] 5. Renvoyer vers le propriétaire d’un objet généré ; présenter les exceptions locales uniquement si le contrat les supporte.
- [x] 6. Tester le résultat avec le vrai renderer puis rouvrir la carte pour vérifier les données sauvegardées.

**Tests comportementaux obligatoires :**

- Échap annule un placement non confirmé sans effacer le dernier objet validé.
- Deux placements créent deux identités distinctes ; les variantes de la ressource sont préservées.
- Une modification d’une zone d’environnement ne réimporte pas ni ne redécode les assets sans rapport.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/resource_io/environment_authoring_host_test.dart
- apps/avelune_studio/test/resource_io/exterior_decoration_selection_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/map_workspace/map_placement_intent_journey_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/resource_io/environment_authoring_host_test.dart test/resource_io/exterior_decoration_selection_test.dart test/map_workspace/map_placement_intent_journey_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Carte active, entité ou environnement propriétaire ; ressources partagées seulement en lecture à la sélection.

**Sortie du lot :** Un parcours palette→placement→annulation→reprise→sauvegarde→réouverture fonctionne avec rendu et données natifs.

**Références visuelles :** [019-palette-decors](2026-11-06-refonte-studio/captures/019-palette-decors.jpg), [020-palette-environnements](2026-11-06-refonte-studio/captures/020-palette-environnements.jpg), [g009](2026-11-06-refonte-studio/captures/g009.jpg), [g010](2026-11-06-refonte-studio/captures/g010.jpg).


### UX-09 — Sols, surfaces, pentes et parcours de falaise

**Priorité :** P0. **Dépendances :** UX-05, UX-08.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/map_workspace/map_terrain_tool_panel.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_border_tool_panel.dart
- apps/avelune_studio/lib/features/map_workspace/application/spatial_terrain_surface_editing_commands.dart
- apps/avelune_studio/lib/features/map_workspace/application/spatial_ramp_editing_commands.dart
- apps/avelune_studio/lib/features/map_workspace/application/map_border_drawing_draft.dart
- apps/avelune_studio/lib/features/map_workspace/application/map_border_editing_commands.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/map_workspace/map_relief_guided_flow_test.dart

**Étapes d’implémentation :**

- [x] 1. Découper le parcours en hauteur, profil, contour et revue ; réutiliser les modes terrain/ramp et l’auteur de Border.
- [x] 2. Montrer les niveaux bas/haut, l’effet sur les décors existants et le côté de la paroi ; ne pas convertir une hauteur en simple translation décorative.
- [x] 3. Choisir une définition de bordure prête, avec ses segments et coins ; un brouillon renvoie à l’atelier.
- [x] 4. Tracer, modifier un sommet, annuler un segment et préparer une prévisualisation native sur les seules dépendances concernées.
- [x] 5. Rendre disponibles pentes et surfaces depuis leur système actuel ; les chemins/eau restent liés à leur sol et à leurs règles natives.
- [x] 6. Avant application, vérifier raccords, coins, sens, trous et traversabilité ; après application, annuler/rétablir puis rouvrir.

**Tests comportementaux obligatoires :**

- Un profil non publié bloque l’application ; la hauteur haute invalide est signalée avant écriture.
- Un contour fermé et un contour ouvert gardent leurs extrémités/coins corrects.
- Rehausser une petite surface ne reconstruit ni les autres cartes ni toutes les définitions de Border.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/map_workspace/spatial_terrain_surface_tools_test.dart
- apps/avelune_studio/test/map_workspace/spatial_terrain_surface_stroke_test.dart
- apps/avelune_studio/test/presentation/spatial_border_editor_test.dart
- packages/map_authoring/test/domains/maps/spatial_terrain_surface_border_refresh_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/map_workspace/map_relief_guided_flow_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/map_workspace/spatial_terrain_surface_tools_test.dart test/map_workspace/spatial_terrain_surface_stroke_test.dart test/presentation/spatial_border_editor_test.dart test/map_workspace/map_relief_guided_flow_test.dart
flutter analyze

cd /Users/karim/Project/pokemonProject/packages/map_authoring
dart test test/domains/maps/spatial_terrain_surface_border_refresh_test.dart
dart analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Unités terrain/surface et contours réellement dépendants de la carte active ; patchs ciblés, aucun snapshot global.

**Sortie du lot :** Falaise et pente sont à la fois visuellement justes et nativement éditables ; l’illustration de la maquette est remplacée par le rendu réel.

**Références visuelles :** [006-carte-relief](2026-11-06-refonte-studio/captures/006-carte-relief.jpg), [007-carte-pente](2026-11-06-refonte-studio/captures/007-carte-pente.jpg), [009-falaise-etape-1](2026-11-06-refonte-studio/captures/009-falaise-etape-1.jpg), [011-falaise-etape-2](2026-11-06-refonte-studio/captures/011-falaise-etape-2.jpg), [012-falaise-profil-brouillon](2026-11-06-refonte-studio/captures/012-falaise-profil-brouillon.jpg), [013-falaise-etape-3](2026-11-06-refonte-studio/captures/013-falaise-etape-3.jpg), [015-falaise-etape-4](2026-11-06-refonte-studio/captures/015-falaise-etape-4.jpg), [017-falaise-ajoutee](2026-11-06-refonte-studio/captures/017-falaise-ajoutee.jpg).


### UX-10 — Collisions, passages, connexions, départ et zones

**Priorité :** P1. **Dépendances :** UX-04, UX-07.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/map_workspace/map_warp_inspector.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_zone_inspector.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_marker_inspector.dart
- apps/avelune_studio/lib/features/map_workspace/application/warp_editing_commands.dart
- apps/avelune_studio/lib/features/map_workspace/application/gameplay_zone_editing_commands.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/map_workspace/map_rules_profile_matrix_test.dart

**Étapes d’implémentation :**

- [x] 1. Réutiliser les commandes natives des collisions, passages, connexions et départ ; nommer la cible et la carte concernées.
- [x] 2. Fournir des sélecteurs de carte et de point d’arrivée recherchables, avec aperçu et référence non résolue conservée.
- [x] 3. Présenter les superpositions issues des vraies données, distinctes de l’image finale du jeu.
- [x] 4. Centraliser la disponibilité 2D/3D ; une zone non supportée n’est pas proposée depuis un autre menu.
- [x] 5. Rendre accessibles vélo, Corde Sortie, donjon et règles de carte via le panneau Carte, sans les confondre avec une occurrence.
- [x] 6. Vérifier un aller-retour de passage et une connexion de bord avec le runtime existant, sans changer ses règles de gameplay.

**Tests comportementaux obligatoires :**

- Destination supprimée ou point hors carte : erreur actionnable, aucune perte de référence.
- Une brosse de collision ne modifie pas la ressource partagée ; annuler restaure les cellules touchées.
- Le test du départ indique le contexte réellement utilisé et ne remplace pas une sauvegarde existante.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/presentation/map_warp_door_inspector_test.dart
- apps/avelune_studio/test/presentation/map_escape_rope_settings_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/map_workspace/map_rules_profile_matrix_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/presentation/map_warp_door_inspector_test.dart test/presentation/map_escape_rope_settings_test.dart test/map_workspace/map_rules_profile_matrix_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Champs et unités de carte ciblés ; les diagnostics examinent uniquement les destinations effectivement référencées.

**Sortie du lot :** Chaque règle est modifiable avec sa portée et son profil explicites ; les overlays correspondent aux données natives.

**Références visuelles :** [023-collisions](2026-11-06-refonte-studio/captures/023-collisions.jpg), [024-reperes-collisions](2026-11-06-refonte-studio/captures/024-reperes-collisions.jpg), [025-passages](2026-11-06-refonte-studio/captures/025-passages.jpg), [026-connexions](2026-11-06-refonte-studio/captures/026-connexions.jpg), [027-depart-joueur](2026-11-06-refonte-studio/captures/027-depart-joueur.jpg), [030-carte-regles-locales](2026-11-06-refonte-studio/captures/030-carte-regles-locales.jpg).


### UX-11 — Bibliothèque complète : trouver, organiser et sélectionner

**Priorité :** P0. **Dépendances :** UX-05.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/resources/resource_library_screen.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_library_layout.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_catalog_toolbar.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_family_tree.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_detail_panel.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/resource_io/resource_library_context_preservation_test.dart

**Étapes d’implémentation :**

- [x] 1. Conserver grille et liste sur la même sélection stable ; rechercher dans les métadonnées sans charger les médias.
- [x] 2. Conserver familles, types, dimension, disponibilité et pièces sources comme filtres distincts ; montrer les filtres actifs et leur remise à zéro.
- [x] 3. Distinguer Ressources utilisables et Bibliothèque complète ; les sources et brouillons restent gérables dans cette dernière.
- [ ] 4. Implémenter sélection multiple, classement et export de sélection avec comptes dérivés du même ensemble. *(Vague 3 : famille perdue au chargement d'une autre famille corrigée par 86bb44bb5 ; rangement ciblé du catalogue de travail par 6d8e088f7, prouvé par tests hôtes et banc HGSS ; parcours UI natif non revérifié, session macOS verrouillée.)*
- [ ] 5. Conserver les filtres et le défilement lors de l’ouverture d’un atelier ; rendre le retour à la carte explicite.
- [x] 6. Gérer chargement, vide, erreur et référence supprimée sans présenter la fiche précédente comme la nouvelle cible.
- [x] 7. Identifier le contexte des deux surfaces de bibliothèque (resource_workspace_pane.dart et la bibliothèque branchée par studio_workspace_host.dart) ; harmoniser recherche, résultats, fiche et action principale lorsque leurs capacités sont équivalentes, sans supposer qu’elles ont le même rôle (audit R04).

**Tests comportementaux obligatoires :**

- Une sélection reste attachée aux mêmes IDs après tri et changement grille/liste.
- Classer deux ressources ne modifie pas les autres ni les occurrences de carte.
- Les filtres de palette restent inchangés lorsqu’on filtre la bibliothèque.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/presentation/resource_catalog_ui03_test.dart
- apps/avelune_studio/test/presentation/resource_family_catalog_test.dart
- apps/avelune_studio/test/resource_io/resource_organization_host_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/resource_io/resource_library_context_preservation_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/presentation/resource_catalog_ui03_test.dart test/presentation/resource_family_catalog_test.dart test/resource_io/resource_organization_host_test.dart test/resource_io/resource_library_context_preservation_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Catalogue et unités d’organisation ciblées ; recherche indexée/paginée, vignettes demandées uniquement pour les cellules visibles.

**Sortie du lot :** Une ressource se trouve, se classe et s’ouvre sans perdre la carte ou la sélection active.

**Références visuelles :** [060-bibliotheque-grille](2026-11-06-refonte-studio/captures/060-bibliotheque-grille.jpg), [061-bibliotheque-liste](2026-11-06-refonte-studio/captures/061-bibliotheque-liste.jpg), [062-bibliotheque-filtres](2026-11-06-refonte-studio/captures/062-bibliotheque-filtres.jpg), [063-bibliotheque-vide](2026-11-06-refonte-studio/captures/063-bibliotheque-vide.jpg), [064-bibliotheque-selection-multiple](2026-11-06-refonte-studio/captures/064-bibliotheque-selection-multiple.jpg), [065-ressources-classer](2026-11-06-refonte-studio/captures/065-ressources-classer.jpg), [066-ressources-familles](2026-11-06-refonte-studio/captures/066-ressources-familles.jpg).


### UX-12 — Import, sources et packs : préflight puis publication

**Priorité :** P1. **Dépendances :** UX-11.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/resources/resource_image_import.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_pack_transfer_dialog.dart
- apps/avelune_studio/lib/features/map_workspace/application/map_workspace_catalog_preparation.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/resource_io/resource_import_context_flow_test.dart

**Étapes d’implémentation :**

- [ ] 1. Réutiliser les contrôleurs d’import et de préparation existants ; choisir le type à partir du fichier et de ses contrôles réels.
- [ ] 2. Distinguer sélection de source, préflight, conflits, confirmation, progression et résultat ; l’annulation ne publie rien.
- [ ] 3. Pour un pack, garder dépendances, identité, attribution et stratégie de conflit canoniques ; ne pas réutiliser les simples options illustratives comme validation.
- [ ] 4. Vérifier les octets, le format, les bornes, les références et les droits nécessaires ; conserver la source et l’état précédent en cas d’échec.
- [x] 5. Ouvrir le résultat dans son atelier ou le retrouver dans la bibliothèque ; proposer Utiliser seulement après publication admissible.
- [ ] 6. Séparer préparation explicite coûteuse et modification locale ultérieure ; la première édition ne doit pas déclencher un préflight global caché.

**Tests comportementaux obligatoires :**

- Fichier invalide, annulation et conflit d’identité ne laissent pas une définition partiellement publiée.
- Un pack réimporté conserve les identités prévues et ne détruit pas les références natives.
- Une source importée reste une source et n’est pas automatiquement proposée comme décor.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/presentation/resource_pack_transfer_dialog_test.dart
- apps/avelune_studio/test/resource_io/resource_pack_import_host_test.dart
- packages/map_authoring/test/domains/assets/resource_pack_reimport_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/resource_io/resource_import_context_flow_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/presentation/resource_pack_transfer_dialog_test.dart test/resource_io/resource_pack_import_host_test.dart test/resource_io/resource_import_context_flow_test.dart
flutter analyze

cd /Users/karim/Project/pokemonProject/packages/map_authoring
dart test test/domains/assets/resource_pack_reimport_test.dart
dart analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Transaction de préparation/import et unités de ressources affectées ; progression explicite pour les opérations globales.

**Sortie du lot :** La réussite annoncée correspond à une publication durable ; résultat, erreurs et annulation sont distincts et vérifiés.

**Références visuelles :** [070-import-etape-1](2026-11-06-refonte-studio/captures/070-import-etape-1.jpg), [071-import-etape-2](2026-11-06-refonte-studio/captures/071-import-etape-2.jpg), [072-import-etape-3](2026-11-06-refonte-studio/captures/072-import-etape-3.jpg), [073-creer-ressource](2026-11-06-refonte-studio/captures/073-creer-ressource.jpg), [090-export-pack](2026-11-06-refonte-studio/captures/090-export-pack.jpg), [092-import-pack](2026-11-06-refonte-studio/captures/092-import-pack.jpg), [w-image-source-import](2026-11-06-refonte-studio/captures/w-image-source-import.jpg).


### UX-12.1 — Ateliers des décors 2D et modèles 3D

**Priorité :** P1. **Dépendances :** UX-12.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/resources/decor_editor_screen.dart
- apps/avelune_studio/lib/presentation/features/resources/model_resource_library.dart
- apps/avelune_studio/lib/presentation/features/resources/model_collision_controls.dart
- apps/avelune_studio/lib/presentation/features/resources/model_ramp_controls.dart
- apps/avelune_studio/lib/presentation/features/resources/model_light_controls.dart
- apps/avelune_studio/lib/presentation/features/resources/model_shadow_controls.dart

**Étapes d’implémentation :**

- [ ] 1. Garder Général, Source, Collision, Animation, Ombres/Lumière, Usages et Avancé suivant le type réel de la ressource.
- [ ] 2. Préserver dimensions, origine, volume de collision, rampes/escaliers, animation, lumière, ombre et flamme déjà supportés.
- [x] 3. Montrer la définition partagée et ses usages avant une publication affectant des cartes ; l’occurrence reste éditée sur la carte.
- [x] 4. Réutiliser les aperçus natifs et leurs cycles de vie ; ne pas recréer le renderer à chaque frappe de champ.
- [ ] 5. Rendre lisibles les valeurs héritées et les exceptions de l’occurrence sans confondre cet héritage avec projet→carte.

**Tests comportementaux obligatoires :**

- Modifier le modèle utilisé par deux cartes demande une revue de portée et conserve les identités.
- Collision et rampe correspondent au modèle sauvegardé après réouverture.
- Changer de ressource pendant un chargement tardif ne remplace pas la nouvelle fiche par l’ancienne.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/resource_io/model_resource_adapter_test.dart
- apps/avelune_studio/test/project_visuals/model_light_workshop_test.dart
- apps/avelune_studio/test/resource_io/working_catalog_contact_shadow_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/resource_io/model_resource_adapter_test.dart test/project_visuals/model_light_workshop_test.dart test/resource_io/working_catalog_contact_shadow_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Définition du décor/modèle et médias réellement remplacés ; invalidation des usages concernés, pas de toutes les cartes.

**Sortie du lot :** Tous les réglages natifs actuels restent accessibles dans une structure progressive ; aucun volume ou comportement n’est perdu par simplification.

**Références visuelles :** [074-atelier-modele-general](2026-11-06-refonte-studio/captures/074-atelier-modele-general.jpg), [w-modele-1](2026-11-06-refonte-studio/captures/w-modele-1.jpg), [w-modele-2](2026-11-06-refonte-studio/captures/w-modele-2.jpg), [w-modele-3](2026-11-06-refonte-studio/captures/w-modele-3.jpg), [w-modele-4](2026-11-06-refonte-studio/captures/w-modele-4.jpg), [w-decor-2d-0](2026-11-06-refonte-studio/captures/w-decor-2d-0.jpg), [w-decor-2d-2](2026-11-06-refonte-studio/captures/w-decor-2d-2.jpg).


### UX-12.2 — Atelier terrain : motifs, pièces et règles de raccord

**Priorité :** P1. **Dépendances :** UX-12.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/resources/resource_terrain_management.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_terrain_preview.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_terrain_draft_list.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_terrain_owner_guard.dart

**Étapes d’implémentation :**

- [ ] 1. Présenter le preset, ses motifs et matériaux admissibles sans aplatir les modèles natifs dans une image unique.
- [ ] 2. Associer les sources à centre/bords/coins et conserver les règles d’animation ou de tampon déjà supportées.
- [x] 3. Exposer la distinction sol/chemin/eau par les capacités réelles, en documentant tout manque contractuel identifié en UX-00.
- [ ] 4. Fournir un terrain d’essai avec virage, intersection et effacement ; la validation doit examiner la définition effective.
- [ ] 5. Conserver brouillons et conflits d’owner ; une annulation ne supprime pas une définition publiée.

**Tests comportementaux obligatoires :**

- Motif incomplet refusé ; chemin avec virage et intersection se raccorde dans le viewport natif.
- Supprimer une source utilisée préserve la définition ou bloque avec un diagnostic.
- Publier ne change pas l’identité du terrain déjà utilisé.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/resource_io/terrain_management_host_test.dart
- apps/avelune_studio/test/resource_io/terrain_management_guards_host_test.dart
- apps/avelune_studio/test/resource_io/terrain_deleted_history_host_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/resource_io/terrain_management_host_test.dart test/resource_io/terrain_management_guards_host_test.dart test/resource_io/terrain_deleted_history_host_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Unités de preset/pattern/source effectivement modifiées ; les essais restent séparés des cartes utilisateur.

**Sortie du lot :** L’utilisateur prépare et valide une ressource réellement utilisable par UX-05 et UX-09.

**Références visuelles :** [w-terrain-0](2026-11-06-refonte-studio/captures/w-terrain-0.jpg), [w-terrain-1](2026-11-06-refonte-studio/captures/w-terrain-1.jpg), [w-terrain-2](2026-11-06-refonte-studio/captures/w-terrain-2.jpg), [g030](2026-11-06-refonte-studio/captures/g030.jpg).


### UX-12.3 — Atelier Border : pièces, contour, sauts et publication

**Priorité :** P1. **Dépendances :** UX-12, UX-09.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/resources/border_creation_dialog.dart
- apps/avelune_studio/lib/presentation/features/resources/border_source_panel.dart
- apps/avelune_studio/lib/presentation/features/resources/border_pattern_panel.dart
- apps/avelune_studio/lib/presentation/features/resources/border_sequence_controls.dart
- apps/avelune_studio/lib/presentation/features/resources/native_ledge_panel.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_border_draft_bar.dart

**Étapes d’implémentation :**

- [ ] 1. Distinguer la définition de Border et les pièces qu’elle possède ; celles-ci restent masquées du placement ordinaire.
- [ ] 2. Relier segments, coins intérieurs/extérieurs et extrémités aux emplacements compatibles.
- [ ] 3. Conserver motifs, séquences, hauteur, direction, sauts et métadonnées franchissables déjà supportés.
- [ ] 4. Afficher les pièces manquantes avant vérification ; autoriser un contour droit seulement lorsque ce mode est réellement choisi.
- [x] 5. Publier avec contrôle de révision et revue des usages ; conserver l’ancien contour si la publication échoue.

**Tests comportementaux obligatoires :**

- Segment seul refusé pour un contour exigeant des coins ; mode droit explicite testé séparément.
- Une publication conserve la capacité de saut et les séquences existantes.
- Après conflit d’owner, le brouillon reste disponible et aucune source n’est perdue.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/resource_io/border_management_host_test.dart
- apps/avelune_studio/test/resource_io/border_management_guards_host_test.dart
- apps/avelune_studio/test/resource_io/border_jump_behavior_preservation_test.dart
- apps/avelune_studio/test/resource_io/border_publication_retry_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/resource_io/border_management_host_test.dart test/resource_io/border_management_guards_host_test.dart test/resource_io/border_jump_behavior_preservation_test.dart test/resource_io/border_publication_retry_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Blueprint, pièces et séquences appartenant à la Border ; contours dépendants explicitement invalidés.

**Sortie du lot :** Le profil publié reste natif, complet et éditable ; sa présence dans la palette indique une vraie admissibilité.

**Références visuelles :** [w-bordure-0](2026-11-06-refonte-studio/captures/w-bordure-0.jpg), [w-bordure-1](2026-11-06-refonte-studio/captures/w-bordure-1.jpg), [w-bordure-2](2026-11-06-refonte-studio/captures/w-bordure-2.jpg), [w-bordure-3](2026-11-06-refonte-studio/captures/w-bordure-3.jpg), [101-bordure-validation-erreur](2026-11-06-refonte-studio/captures/101-bordure-validation-erreur.jpg), [102-bordure-pieces-associees](2026-11-06-refonte-studio/captures/102-bordure-pieces-associees.jpg), [103-bordure-validee](2026-11-06-refonte-studio/captures/103-bordure-validee.jpg), [104-bordure-publiee](2026-11-06-refonte-studio/captures/104-bordure-publiee.jpg).


### UX-12.4 — Atelier Environnement et objets générés

**Priorité :** P1. **Dépendances :** UX-12, UX-08.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/resources/environment_editor_screen.dart
- apps/avelune_studio/lib/presentation/features/resources/environment_editor_palette.dart
- apps/avelune_studio/lib/presentation/features/resources/environment_decor_picker.dart
- apps/avelune_studio/lib/presentation/features/resources/environment_library.dart

**Étapes d’implémentation :**

- [ ] 1. Rendre visibles les ressources sources, densité, répartition, variations et paramètres déjà pris en charge.
- [x] 2. Séparer définition réutilisable et zone placée sur une carte ; montrer la portée de toute édition.
- [ ] 3. Garder une prévisualisation déterministe pour une seed donnée et une explication du renouvellement.
- [ ] 4. Conserver le lien natif zone→objets générés pour la sélection, le retrait et le diagnostic.
- [ ] 5. Gérer ressource source retirée ou incompatible sans convertir les enfants en objets indépendants.

**Tests comportementaux obligatoires :**

- Même seed et mêmes paramètres produisent le même résultat représentatif.
- La suppression d’une zone retire ses enfants natifs, pas les arbres d’une autre zone.
- Une sélection d’enfant renvoie au propriétaire correct.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/resource_io/environment_authoring_host_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/resource_io/environment_authoring_host_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Définition ou zone d’environnement visée et ses enfants réels ; pas de répartition globale au changement d’un label.

**Sortie du lot :** Une forêt est simple à préparer et à poser tout en gardant son édition native et sa provenance.

**Références visuelles :** [w-environnement-0](2026-11-06-refonte-studio/captures/w-environnement-0.jpg), [w-environnement-1](2026-11-06-refonte-studio/captures/w-environnement-1.jpg), [w-environnement-2](2026-11-06-refonte-studio/captures/w-environnement-2.jpg), [020-palette-environnements](2026-11-06-refonte-studio/captures/020-palette-environnements.jpg).


### UX-12.5 — Atelier Personnage : identité, apparence et animations

**Priorité :** P1. **Dépendances :** UX-12.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/resources/resource_character_management.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_character_animation_import.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_character_portrait_import.dart
- apps/avelune_studio/lib/presentation/features/characters/character_palette.dart

**Étapes d’implémentation :**

- [ ] 1. Conserver une fiche réutilisable avec identité, feuille/sprite/modèle, animations et portraits.
- [ ] 2. Montrer la portée : personnage du projet versus présence sur la carte, conditions et interaction de cette présence.
- [ ] 3. Importer les animations via les contrôles existants ; ne pas supposer une grille 4×4 pour toutes les sources.
- [ ] 4. Prévisualiser directions, états, scale et ancrage compatibles avec le profil.
- [ ] 5. Présenter les références manquantes et interdire l’utilisation sans effacer la configuration ; relier les présences connues.
- [x] 6. Faire de la bibliothèque des personnages le panneau de sélection permanent et garder un seul onglet Identité ; ne conserver une vue Bibliothèque distincte que si elle répond à une vraie tâche (audit R01, P1 ; character_studio_page.dart).
- [x] 7. Choisir un seul mot pour les portraits, par exemple « expression », et distinguer créer une expression et lui associer une image ; vérifier la portée partagée par un essai d’écriture avant de l’annoncer (audit R03 ; character_studio_portrait_panel.dart).

**Tests comportementaux obligatoires :**

- Remplacer une feuille conserve les identités et signale les états d’animation manquants.
- Changer une occurrence ne renomme pas la fiche partagée.
- Une source perdue reste diagnostiquable et réparable sans recréer le personnage.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/characters/character_resource_index_test.dart
- apps/avelune_studio/test/characters/character_palette_compact_test.dart
- apps/avelune_studio/test/resource_io/character_removal_reconciliation_host_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/characters/character_resource_index_test.dart test/characters/character_palette_compact_test.dart test/resource_io/character_removal_reconciliation_host_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Définition personnage, médias importés et références concernées ; chargement des présences à la demande.

**Sortie du lot :** Personnage, présence et interaction ont des propriétaires lisibles, et les animations réelles sont préservées.

**Références visuelles :** [w-personnage-0](2026-11-06-refonte-studio/captures/w-personnage-0.jpg), [w-personnage-1](2026-11-06-refonte-studio/captures/w-personnage-1.jpg), [w-personnage-2](2026-11-06-refonte-studio/captures/w-personnage-2.jpg), [h04-personnages-ancienne](2026-11-06-refonte-studio/captures/h04-personnages-ancienne.jpg), [h-personnage-animations](2026-11-06-refonte-studio/captures/h-personnage-animations.jpg).


### UX-13 — Usages, remplacement, suppression et diagnostics actionnables

**Priorité :** P0. **Dépendances :** UX-11, UX-12.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/resources/resource_usage_dialog.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_usage_results.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_replacement_dialog.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_removal_dialog.dart
- apps/avelune_studio/lib/presentation/features/resources/resource_reconciliation_notice.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/resource_io/resource_diagnostic_owner_navigation_test.dart

**Étapes d’implémentation :**

- [ ] 1. Analyser les usages par le service canonique, avec progression, annulation et résultat lié à la révision.
- [ ] 2. Séparer Remplacer ici, modifier la définition et remplacer ses usages ; afficher la portée avant confirmation.
- [ ] 3. Bloquer ou guider la suppression d’une ressource utilisée selon les stratégies réellement disponibles.
- [x] 4. Donner une prochaine action à chaque incident connu : ouvrir l’atelier, sélectionner l’occurrence, retrouver une source ou réessayer.
- [x] 5. Conserver une erreur à cause inconnue comme telle ; ne pas fabriquer de réparation, d’import ou de cause.
- [ ] 6. Traiter une publication ou un remplacement interrompu avec le mécanisme existant de reprise et de conflit.

**Tests comportementaux obligatoires :**

- Un résultat d’usages périmé est refusé avant suppression.
- Annuler une analyse ou un remplacement ne modifie pas les fichiers.
- Une erreur de source pointe vers la bonne ressource et garde l’identité de la référence.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/resource_io/resource_usages_host_test.dart
- apps/avelune_studio/test/resource_io/resource_replacement_dialog_test.dart
- apps/avelune_studio/test/resource_io/resource_usage_cancellation_host_test.dart
- apps/avelune_studio/test/presentation/workspace_resource_diagnostics_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/resource_io/resource_diagnostic_owner_navigation_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/resource_io/resource_usages_host_test.dart test/resource_io/resource_replacement_dialog_test.dart test/resource_io/resource_usage_cancellation_host_test.dart test/presentation/workspace_resource_diagnostics_test.dart test/resource_io/resource_diagnostic_owner_navigation_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Index d’usages et unités effectivement remplacées ; une analyse globale est explicite et n’est jamais cachée dans une sélection.

**Sortie du lot :** Le diagnostic décrit ce qui est connu, la portée et l’action disponible ; les originaux sont conservés en cas de refus ou d’échec.

**Références visuelles :** [067-ressource-menu-actions](2026-11-06-refonte-studio/captures/067-ressource-menu-actions.jpg), [068-ressource-usages](2026-11-06-refonte-studio/captures/068-ressource-usages.jpg), [069-ressource-usages-resultats](2026-11-06-refonte-studio/captures/069-ressource-usages-resultats.jpg), [075-diagnostics](2026-11-06-refonte-studio/captures/075-diagnostics.jpg), [076-reference-manquante](2026-11-06-refonte-studio/captures/076-reference-manquante.jpg), [088-renommer-ressource](2026-11-06-refonte-studio/captures/088-renommer-ressource.jpg), [089-supprimer-ressource](2026-11-06-refonte-studio/captures/089-supprimer-ressource.jpg), [091-reference-diagnostic](2026-11-06-refonte-studio/captures/091-reference-diagnostic.jpg).


### UX-14 — Session de réglages et brouillons conservés par rubrique

**Priorité :** P0. **Dépendances :** UX-02.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/project_settings/project_settings_page.dart
- apps/avelune_studio/lib/features/project_visuals/application/project_visuals_controller.dart
- apps/avelune_studio/lib/features/project_audio/application/project_audio_controller.dart
- apps/avelune_studio/lib/features/project_surf/application/project_surf_controller.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/lib/features/project_settings/application/project_settings_session_controller.dart
- apps/avelune_studio/test/project_settings/project_settings_session_test.dart

**Étapes d’implémentation :**

- [x] 1. Créer un shell à six rubriques, chacune accessible sans dépendre de l’existence d’une carte 3D.
- [x] 2. Conserver les contrôleurs métier actuels et ajouter seulement la coordination de navigation, portée, brouillons et historique.
- [x] 3. Supprimer la sauvegarde implicite de keepDraft lors d’un changement de carte d’aperçu ou de rubrique.
- [x] 4. Conserver les brouillons par projet, rubrique et portée ; une réponse asynchrone d’un ancien contexte est ignorée.
- [x] 5. Définir Enregistrer, Annuler les modifications et les règles de sortie/fermeture ; ne pas effacer un brouillon lors d’une erreur.
- [x] 6. Réutiliser les protections contre conflit externe et les gestes groupés d’annulation ; n’annoncer enregistré qu’après persistance.

**Tests comportementaux obligatoires :**

- Modifier Image, passer à Sons puis revenir : brouillon identique et aucune écriture intermédiaire.
- Sauvegarder Image ne sauvegarde ni Météo ni Général ; annuler Image ne touche pas Sons.
- Changement de projet, fermeture et écriture en vol conservent les garanties de concurrence et de sortie.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/project_visuals/project_settings_navigation_test.dart
- apps/avelune_studio/test/project_visuals/project_visuals_controller_test.dart
- apps/avelune_studio/test/project_surf/project_surf_navigation_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/project_settings/project_settings_session_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/project_visuals/project_settings_navigation_test.dart test/project_visuals/project_visuals_controller_test.dart test/project_surf/project_surf_navigation_test.dart test/project_settings/project_settings_session_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Coordination en mémoire ; chaque sauvegarde reste dans son port canonique et son unité ciblée. Pas de snapshot de projet.

**Sortie du lot :** Navigation, portée et sauvegarde sont trois actions distinctes ; un brouillon ne disparaît ni ne se publie en naviguant.

**Références visuelles :** [037-reglages-general-erreur](2026-11-06-refonte-studio/captures/037-reglages-general-erreur.jpg), [038-reglages-general-brouillon](2026-11-06-refonte-studio/captures/038-reglages-general-brouillon.jpg), [049-reglages-verifications](2026-11-06-refonte-studio/captures/049-reglages-verifications.jpg), [094-reglages-enregistres](2026-11-06-refonte-studio/captures/094-reglages-enregistres.jpg).


### UX-15 — Général : une identité commune aux réglages et à l’export

**Priorité :** P0. **Dépendances :** UX-14.

**Modifier ou réutiliser les propriétaires existants :**

- packages/map_authoring/lib/src/ports/game_package_export_profile_api_port.dart
- packages/map_authoring/lib/src/domains/distribution/game_package_export_profile_api.dart
- apps/avelune_studio/lib/features/game_export/data/studio_game_export_controller.dart
- apps/avelune_studio/lib/presentation/features/game_export/studio_game_export_page.dart
- apps/avelune_studio/lib/presentation/features/game_export/studio_game_export_content.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/lib/features/project_settings/application/project_identity_controller.dart
- apps/avelune_studio/lib/presentation/features/project_settings/project_general_panel.dart
- apps/avelune_studio/test/project_settings/project_identity_shared_export_test.dart

**Étapes d’implémentation :**

- [x] 1. Utiliser GamePackageExportProfileApiPort.read/validate/save pour titre, auteur, version du contenu, langue et langues disponibles.
- [x] 2. Faire partager le même état/version aux réglages et au résumé d’export ; éviter deux formulaires possédant deux sources de vérité.
- [x] 3. Préserver gameId stable lors d’un changement de titre ; distinguer le nom du projet et son identité de jeu.
- [x] 4. Conserver expectedProfileRevision et expectedContextRevision ainsi que les refus de profil périmé.
- [x] 5. Sauvegarder Général sans lancer export, chargement de jeu ou validation globale sans rapport.
- [x] 6. Présenter l’identité technique à la demande ; suivre les contraintes canoniques au lieu d’inventer une règle SemVer.

**Tests comportementaux obligatoires :**

- Après changement de titre enregistré, Export reprend cette valeur avec le même gameId.
- Une langue principale absente des langues disponibles empêche l’enregistrement avec une erreur ciblée.
- Un profil externe modifié bloque une sauvegarde périmée et conserve les deux versions récupérables.

**Tests existants à relancer ou étendre :**

- packages/map_authoring/test/domains/distribution/export_profile_authoring_test.dart
- apps/avelune_studio/test/game_export/studio_game_export_project_switch_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/project_settings/project_identity_shared_export_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/packages/map_authoring
dart test test/domains/distribution/export_profile_authoring_test.dart
dart analyze

cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/game_export/studio_game_export_project_switch_test.dart test/project_settings/project_identity_shared_export_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** .pokemap/export-profile-v1.json et contexte explicitement requis par le contrat existant. La garantie actuelle n’est pas une atomicité multi-fichiers ; ne pas la surannoncer.

**Coût mesuré (agent Parité, 7 novembre 2026) :** `GamePackageExportProfileStore` ne lit plus que les métadonnées `maps` et `newGame` du catalogue de travail et calcule le contexte une seule fois par lecture ou par enregistrement (contrôle frais juste avant le renommage, conservé ; la base hors verrou n’est recalculée que sans révisions attendues). Test de comptage : `packages/map_authoring/test/domains/distribution/export_profile_context_cost_test.dart`. Banc AOT sans interface sur une copie HGSS : lecture 1,6 à 2,8 s → 81 à 100 ms, enregistrement 4,8 à 6,5 s → 78 à 103 ms. **PARTIAL** : la mesure native du Studio (enregistrer Général, ouvrir l’export) reste à faire, la session macOS était verrouillée.

**Sortie du lot :** L’identité se règle une fois ; export et jeux protégés gardent leurs identifiants et leurs métadonnées.

**Références visuelles :** [036-reglages-general](2026-11-06-refonte-studio/captures/036-reglages-general.jpg), [038-reglages-general-brouillon](2026-11-06-refonte-studio/captures/038-reglages-general-brouillon.jpg), [050-resume-export](2026-11-06-refonte-studio/captures/050-resume-export.jpg), [095-identite-technique](2026-11-06-refonte-studio/captures/095-identite-technique.jpg).


### UX-16 — Image et caméra : défauts projet et aperçu sans changement de portée

**Priorité :** P0. **Dépendances :** UX-14.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/project_settings/spatial_visual_controls.dart
- apps/avelune_studio/lib/features/project_visuals/application/project_visuals_controller.dart
- apps/avelune_studio/lib/features/project_visuals/domain/project_visuals_port.dart
- apps/avelune_studio/lib/features/map_workspace/data/local_project_visuals_adapter.dart
- packages/map_core/lib/src/models/spatial_visual_profile.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/lib/presentation/features/project_settings/project_image_panel.dart
- apps/avelune_studio/test/project_visuals/project_preview_scope_test.dart

**Étapes d’implémentation :**

- [x] 1. Regrouper caméra, ambiance visuelle et effets sans retirer les paramètres natifs qui dépassent l’exemple.
- [x] 2. Conserver les bornes de SpatialVisualParameter et les gestes de slider groupés.
- [x] 3. Conserver ou ajuster explicitement la compensation native distance/FOV qui maintient le cadrage ; regrouper ces champs dépendants dans le même geste d’annulation.
- [x] 4. La carte d’aperçu change seulement l’aperçu ; le formulaire garde sa cible Projet.
- [x] 5. Résoudre les valeurs effectives et afficher leur provenance ; une comparaison montre honnêtement les états mémorisés et brouillons.
- [x] 6. Brancher l’aperçu sur le renderer natif ciblé, avec mise à jour incrémentale des paramètres ; gérer l’absence de carte 3D. *(Vague 3 : effet réel prouvé en natif sur la copie HGSS — « Tester la carte » sur « Maison du joueur — chambre » avec l’inclinaison du projet à 34° puis à 48,7° enregistrée (55 ms) : le rendu du test change. Le test de carte ne démarrait plus sur HGSS faute de capacités accordées par Studio ; corrigé par 854037941 et f1ceb1e63.)*
- [x] 7. Garder projection et hauteur orthographique dans la caméra locale tant que le contrat projet ne les expose pas.

**Tests comportementaux obligatoires :**

- Changer de carte d’aperçu n’écrit rien et ne modifie pas le champ distance du projet.
- Une valeur invalide bloque la sauvegarde, conserve le texte édité et ne produit pas NaN dans le renderer.
- Le premier enregistrement suit le port ciblé ; erreur et conflit conservent brouillon et historique.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/project_visuals/spatial_visual_controls_test.dart
- apps/avelune_studio/test/project_visuals/project_visuals_controller_test.dart
- packages/map_authoring/test/documents/visual_settings_authoring_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/project_visuals/project_preview_scope_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/project_visuals/spatial_visual_controls_test.dart test/project_visuals/project_visuals_controller_test.dart test/project_visuals/project_preview_scope_test.dart
flutter analyze

cd /Users/karim/Project/pokemonProject/packages/map_authoring
dart test test/documents/visual_settings_authoring_test.dart
dart analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** project.visual.json, ou unité cartographique explicitement ciblée pour un aperçu local ; pas de traversal des autres cartes.

**Sortie du lot :** Portée, aperçu et provenance sont lisibles ; l’effet réel est visible sans reconstruction globale du renderer.

**Références visuelles :** [035-reglages-image](2026-11-06-refonte-studio/captures/035-reglages-image.jpg), [093-reglages-effets-avances](2026-11-06-refonte-studio/captures/093-reglages-effets-avances.jpg), [100-camera-invalide](2026-11-06-refonte-studio/captures/100-camera-invalide.jpg), [106-reglages-sans-apercu](2026-11-06-refonte-studio/captures/106-reglages-sans-apercu.jpg), [107-reglages-choix-apercu](2026-11-06-refonte-studio/captures/107-reglages-choix-apercu.jpg).


### UX-17 — Réglages locaux et retour réel à l’héritage

**Priorité :** P0. **Dépendances :** UX-16, UX-07.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/map_workspace/map_camera_panel.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_ambiance_panel.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_inspector.dart
- packages/map_core/lib/src/models/spatial_visual_profile.dart
- packages/map_authoring/lib/src/documents/visual_settings_authoring.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/project_visuals/map_project_inheritance_journey_test.dart

**Étapes d’implémentation :**

- [x] 1. Exposer Sélection / Carte puis Image / Temps / Jeu selon le profil natif. — **livré** par fab0ab2e3 : sans sélection, l’inspecteur montre les réglages de la carte par onglets Image (caméra, effets), Temps (jour et nuit), Jeu (taille, nom, sortie) ; une carte 2D n’a que Jeu ; avec une sélection, Sélection / Carte bascule sans la perdre et revient à Sélection quand un autre élément est choisi ; vérifié en natif.
- [x] 2. Pour chaque paramètre, afficher Suit le projet ou Propre à cette carte, la valeur effective et la source.
- [x] 3. Le reset retire la clé de SpatialVisualPatch avec sa sémantique existante ; ne pas remplacer l’override par la valeur du jour.
- [x] 4. Après modification du projet, rafraîchir uniquement les valeurs héritées ; préserver toute exception locale.
- [x] 5. Conserver les paramètres non visibles et inconnus lors d’un enregistrement partiel de caméra ou météo.
- [x] 6. Appliquer l’historique au bon contexte et vérifier les valeurs après fermeture/réouverture.

**Tests comportementaux obligatoires :**

- Projet 24, carte 10 ; projet 30, carte toujours 10 ; reset : 30 ; projet 32, carte 32.
- Annuler un reset restaure l’override 10, pas une copie 30.
- L’autre carte et les ombres d’occurrence restent inchangées.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/project_visuals/project_visuals_controller_test.dart
- apps/avelune_studio/test/presentation/map_atmosphere_settings_panel_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/project_visuals/map_project_inheritance_journey_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/project_visuals/project_visuals_controller_test.dart test/presentation/map_atmosphere_settings_panel_test.dart test/project_visuals/map_project_inheritance_journey_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** maps/<mapId>.visual.json et paramètres réellement possédés par la carte ; le document projet est lu comme dépendance, pas réécrit.

**Sortie du lot :** L’héritage reste dynamique après reset et après réouverture ; les deux relations projet→carte et ressource→occurrence restent distinctes.

**Références visuelles :** [028-menu-ambiance](2026-11-06-refonte-studio/captures/028-menu-ambiance.jpg), [029-carte-meteo-locale](2026-11-06-refonte-studio/captures/029-carte-meteo-locale.jpg), [031-carte-image-heritee](2026-11-06-refonte-studio/captures/031-carte-image-heritee.jpg), [032-carte-camera-derogation](2026-11-06-refonte-studio/captures/032-carte-camera-derogation.jpg), [033-carte-retour-heritage](2026-11-06-refonte-studio/captures/033-carte-retour-heritage.jpg), [034-carte-orthographique](2026-11-06-refonte-studio/captures/034-carte-orthographique.jpg).


### UX-18 — Temps et météo : sources, variantes et repli

**Priorité :** P1. **Dépendances :** UX-14, UX-17.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/project_settings/spatial_visual_controls.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_ambiance_panel.dart
- apps/avelune_studio/lib/features/map_workspace/application/map_atmosphere_controller.dart
- packages/map_core/lib/src/models/spatial_visual_profile.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/lib/presentation/features/project_settings/project_time_weather_panel.dart
- apps/avelune_studio/test/project_visuals/project_weather_mode_matrix_test.dart

**Étapes d’implémentation :**

- [x] 1. Séparer source de l’heure, valeur de départ ou heure imposée, météo et repli ; ne montrer que les champs applicables.
- [x] 2. Conserver tous les modes natifs et leurs paramètres, y compris ceux qui ne figurent pas dans la maquette.
- [x] 3. Pour météo réelle, décrire la dépendance Player, le refus de localisation et le repli ; ne pas déclencher une permission depuis un simple choix d’aperçu Studio.
- [x] 4. Valider durées et intervalles, minimum≤maximum et valeurs finies avec les règles canoniques.
- [x] 5. Appliquer les dérogations de carte avec UX-17 ; informer lorsque le contexte intérieur ou un scénario peut modifier le résultat.

**Tests comportementaux obligatoires :**

- Chaque mode sérialise puis recharge ses valeurs ; les paramètres des autres modes ne sont pas supprimés silencieusement.
- Service météo indisponible : repli déterministe sans erreur de chargement du jeu.
- Changer de mode avec un brouillon conserve l’historique et les champs nécessaires.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/project_visuals/map_weather_controls_test.dart
- packages/map_core/test/spatial_weather_settings_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/project_visuals/project_weather_mode_matrix_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/project_visuals/map_weather_controls_test.dart test/project_visuals/project_weather_mode_matrix_test.dart
flutter analyze

cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/spatial_weather_settings_test.dart
dart analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Patch visuel/atmosphérique propriétaire ; aucune relecture des ressources météo sans rapport.

**Sortie du lot :** L’utilisateur comprend quelle heure et quelle météo seront utilisées et dans quelles conditions le repli intervient.

**Références visuelles :** [043-reglages-temps](2026-11-06-refonte-studio/captures/043-reglages-temps.jpg), [044-reglages-meteo-reelle](2026-11-06-refonte-studio/captures/044-reglages-meteo-reelle.jpg), [045-reglages-meteo-occasionnelle](2026-11-06-refonte-studio/captures/045-reglages-meteo-occasionnelle.jpg), [096-heure-fixe](2026-11-06-refonte-studio/captures/096-heure-fixe.jpg), [097-heure-reelle](2026-11-06-refonte-studio/captures/097-heure-reelle.jpg), [098-meteo-automatique](2026-11-06-refonte-studio/captures/098-meteo-automatique.jpg).


### UX-19 — Capacités de terrain et conditions de Surf

**Priorité :** P1. **Dépendances :** UX-14.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/project_settings/project_cs_panel.dart
- apps/avelune_studio/lib/presentation/features/project_settings/project_surf_panel.dart
- apps/avelune_studio/lib/presentation/features/project_settings/project_surf_condition_editor.dart
- apps/avelune_studio/lib/features/project_cs/application/project_cs_controller.dart
- apps/avelune_studio/lib/features/project_surf/application/project_surf_controller.dart
- packages/map_core/lib/src/models/project_field_ability_registry.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/project_settings/project_field_ability_scope_test.dart

**Étapes d’implémentation :**

- [x] 1. Afficher les onze entrées du registre avec disponibilité de profil et degré de support réel.
- [x] 2. Séparer activation du jeu, connaissance de la capacité et condition de progression.
- [x] 3. Réutiliser l’éditeur de conditions Surf, ses sélecteurs de badges/états/objets et ses références stables.
- [x] 4. Valider une vitesse finie strictement positive, sans maximum artificiel de 30 ; conserver les règles d’objets et quantités existantes.
- [x] 5. Montrer un résumé lisible et un accès direct aux paramètres de la capacité sélectionnée.
- [x] 6. Préserver Escalade et Anti-Brume comme activation seule tant que leur exécution n’est pas disponible ; ne pas étendre FieldAbility.values ni le runtime par effet de refonte.

**Tests comportementaux obligatoires :**

- Activer Surf ne débloque pas le joueur ; une condition valide reste requise selon la configuration.
- Un chargement tardif de liste d’objets ne remplace pas une nouvelle sélection de condition.
- Désactiver une capacité ne supprime ni ses réglages ni les références de progression.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/project_settings/project_cs_audio_controller_test.dart
- apps/avelune_studio/test/project_surf/project_surf_condition_race_test.dart
- apps/avelune_studio/test/project_surf/project_surf_persistence_test.dart
- packages/map_authoring/test/domains/project/project_cs_audio_actions_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/project_settings/project_field_ability_scope_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/project_settings/project_cs_audio_controller_test.dart test/project_surf/project_surf_condition_race_test.dart test/project_surf/project_surf_persistence_test.dart test/project_settings/project_field_ability_scope_test.dart
flutter analyze

cd /Users/karim/Project/pokemonProject/packages/map_authoring
dart test test/domains/project/project_cs_audio_actions_test.dart
dart analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Paramètres CS/Surf canoniques et documents référencés ; mutations via field_ability.configure et les actions existantes de Surf, découvertes avant usage.

**Sortie du lot :** Activation et progression sont distinctes ; les limites de support ne sont jamais présentées comme des mécaniques terminées.

**Références visuelles :** [039-reglages-capacites](2026-11-06-refonte-studio/captures/039-reglages-capacites.jpg), [040-reglages-surf](2026-11-06-refonte-studio/captures/040-reglages-surf.jpg), [041-surf-condition-objet](2026-11-06-refonte-studio/captures/041-surf-condition-objet.jpg), [042-surf-vitesse-invalide](2026-11-06-refonte-studio/captures/042-surf-vitesse-invalide.jpg), [099-capacite-activation-seule](2026-11-06-refonte-studio/captures/099-capacite-activation-seule.jpg).


### UX-20 — Sons : bibliothèque réelle, associations et aperçu

**Priorité :** P1. **Dépendances :** UX-14, UX-12.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/project_settings/project_audio_panel.dart
- apps/avelune_studio/lib/features/project_audio/application/project_audio_controller.dart
- apps/avelune_studio/lib/features/project_audio/domain/project_audio_port.dart
- apps/avelune_studio/lib/features/map_workspace/data/local_project_audio_adapter.dart
- packages/map_core/lib/src/models/project_audio_settings.dart
- packages/map_authoring/lib/src/domains/project/runtime_audio_actions.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/project_settings/project_audio_binding_scope_test.dart

**Étapes d’implémentation :**

- [x] 1. Lister toutes les cues du contrat natif, par groupe, sans limiter le jeu aux quatre exemples React.
- [x] 2. Présenter héritage, intégré, silence et média personnalisé comme quatre intentions distinctes ; un binding absent signifie héritage.
- [x] 3. Réutiliser queryAudio paginé, import/adopt_asset, resolveAudio et ProjectAudioPreviewPort ; arrêter le lecteur au changement de contexte et à la fermeture.
- [x] 4. Régler le gain avec la conversion explicite 0..100 % vers 0..1 et conserver l’identité du média partagé.
- [x] 5. Rendre le grain de sauvegarde exact : utiliser l’association courante et libeller l’action en conséquence si le port reste par cue ; conserver et signaler les brouillons des autres cues.
- [x] 6. Préserver les contraintes de format, octets, MIME, taille et digest ; en cas de média absent, garder le binding et proposer le diagnostic.

**Tests comportementaux obligatoires :**

- Silence désactive l’écoute ; gain invalide empêche publication et lecture.
- Deux actions partageant le même média gardent des gains indépendants.
- Échec d’enregistrement d’une cue ne marque pas toute la rubrique comme enregistrée ; quitter l’écran arrête le lecteur réel.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/project_settings/project_cs_audio_controller_test.dart
- packages/map_authoring/test/workspace/audio_media_workshop_test.dart
- packages/map_authoring/test/domains/project/runtime_audio_actions_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/project_settings/project_audio_binding_scope_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/project_settings/project_cs_audio_controller_test.dart test/project_settings/project_audio_binding_scope_test.dart
flutter analyze

cd /Users/karim/Project/pokemonProject/packages/map_authoring
dart test test/workspace/audio_media_workshop_test.dart test/domains/project/runtime_audio_actions_test.dart
dart analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Association ciblée via project.audio.cue.configure ; média uniquement si import/remplacement explicite. Aucun réexport du jeu pour écouter.

**Sortie du lot :** La bibliothèque et les sons réellement exportés correspondent aux associations affichées ; aucun son synthétique de maquette n’est livré comme média du projet.

**Références visuelles :** [046-reglages-sons](2026-11-06-refonte-studio/captures/046-reglages-sons.jpg), [047-son-bibliotheque](2026-11-06-refonte-studio/captures/047-son-bibliotheque.jpg), [048-son-silencieux](2026-11-06-refonte-studio/captures/048-son-silencieux.jpg).


### UX-21 — Vérification, test de carte, test du jeu et export

**Priorité :** P0. **Dépendances :** UX-10, UX-15, UX-17, UX-19, UX-20.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/verification/verification_workspace_page.dart
- apps/avelune_studio/lib/presentation/features/game_export/studio_game_export_page.dart
- apps/avelune_studio/lib/presentation/features/game_export/studio_game_export_summary.dart
- apps/avelune_studio/lib/features/game_export/data/studio_game_export_controller.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/workspace_export_binding.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/game_export/studio_test_export_scope_journey_test.dart

**Étapes d’implémentation :**

- [x] 1. Distinguer erreurs de saisie, validation de ressources, capacités runtime, lancement et compatibilité des sauvegardes. — **livré** par a7b2999df : Réglages › Vérifications et export liste les cinq familles avec leur état honnête (rubriques invalides ou en brouillon ouvertes sur place, départ de nouvelle partie contrôlé, publication 3D en attente, ressources et sauvegardes « non vérifié ici ») ; vérifié en natif, dont la saisie invalide « À corriger ».
- [x] 2. Avant test, afficher carte/point de départ, documents et brouillons utilisés ; demander une action explicite pour un brouillon incompatible avec le lancement.
- [x] 3. Séparer Tester cette carte et Tester le jeu ; préserver les sauvegardes et indiquer la portée de la session de test. — revue « Tester cette carte » / « Tester le jeu » (c91ccab0f) et barre « Tester la carte » (e00375f66) ; revue et lancement vérifiés en natif.
- [x] 4. Au retour de test, restaurer carte, outil, sélection et panneaux sans recharger tout le projet.
- [x] 5. L’export reprend l’identité de Général ; différencier Test local et Publication, destination, écrasement confirmé, progression et annulation.
- [x] 6. Présenter les erreurs connues avec leur propriétaire ; une cause inconnue ne donne pas lieu à une réparation inventée. — **livré** par a7b2999df et 3e3638b0d : un échec d’export porte sa famille et son propriétaire (code canonique ou rapport de jouabilité) avec l’action qui l’ouvre ; un test qui ne démarre pas aussi pour les causes typées, une capacité non accordée est nommée ; une cause inconnue le dit, garde son détail technique et ne propose rien ; vérifié en natif (cause non déterminée, puis capacité nommée). Reste : l’échec d’un export réel n’a pas été provoqué en natif.
- [x] 7. Conserver les contrôles de projet courant pendant un export et la transaction d’activation du paquet.

**Tests comportementaux obligatoires :**

- Une erreur de ressource empêche le lancement concerné et pointe vers l’atelier exact.
- Changer de projet pendant un export ne publie pas le paquet de l’ancien contexte dans le nouveau.
- Annulation, échec, paquet futur et sauvegarde protégée laissent les originaux intacts.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/game_export/studio_game_export_control_test.dart
- apps/avelune_studio/test/game_export/studio_game_export_project_switch_test.dart
- apps/avelune_studio/test/game_export/studio_game_export_cancel_test.dart
- packages/map_distribution/test/avelune_compatibility_baseline_package_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/game_export/studio_test_export_scope_journey_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/game_export/studio_game_export_control_test.dart test/game_export/studio_game_export_project_switch_test.dart test/game_export/studio_game_export_cancel_test.dart test/game_export/studio_test_export_scope_journey_test.dart
flutter analyze

cd /Users/karim/Project/pokemonProject/packages/map_distribution
dart test test/avelune_compatibility_baseline_package_test.dart
dart analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Préparation et export explicites ; copie de test ou paquet en staging, jamais reconstruction déclenchée par une simple édition locale.

**Sortie du lot :** Le chemin carte→test→retour et le chemin projet→vérification→export sont réellement exécutés et récupérables.

**Références visuelles :** [049-reglages-verifications](2026-11-06-refonte-studio/captures/049-reglages-verifications.jpg), [050-resume-export](2026-11-06-refonte-studio/captures/050-resume-export.jpg), [080-test-portee](2026-11-06-refonte-studio/captures/080-test-portee.jpg), [081-test-carte](2026-11-06-refonte-studio/captures/081-test-carte.jpg), [h05-test-export](2026-11-06-refonte-studio/captures/h05-test-export.jpg), [h07-diagnostic-test](2026-11-06-refonte-studio/captures/h07-diagnostic-test.jpg), [h09-preparer-export](2026-11-06-refonte-studio/captures/h09-preparer-export.jpg).


### UX-22 — Scènes : conserver et affiner le graphe visuel

**Priorité :** P1. **Dépendances :** UX-03, UX-07.

**Prérequis (D-02, option a pour Histoire) :** une direction de design Histoire validée par Yoahn dans MagicPath avant la refonte visuelle de ce lot et de UX-23.1 à UX-23.5. Elle couvre au moins l’entrée Histoire, le graphe d’une scène réelle et longue, un événement et un dialogue avec choix. Les étapes issues de l’audit n’attendent pas cette direction.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/scenes/scene_builder_page.dart
- apps/avelune_studio/lib/presentation/features/scenes/scene_graph_canvas.dart
- apps/avelune_studio/lib/presentation/features/scenes/scene_library_panel.dart
- apps/avelune_studio/lib/features/scenes/application/scene_workspace_controller.dart
- apps/avelune_studio/lib/features/scenes/application/scene_edit_session.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/scenes/scene_graph_context_journey_test.dart

**Étapes d’implémentation :**

- [x] 1. Garder le graphe comme espace principal, avec bibliothèque de nœuds, canvas, liens et inspecteur.
- [x] 2. Rendre lisibles entrée, sortie, conditions, branches et types de liens ; conserver les nœuds natifs non montrés dans les quatre exemples.
- [x] 3. Ajouter recherche de scène/nœud, zoom, centrage et sélection sans modifier la structure métier.
- [x] 4. Montrer un résumé Quand/Si/Alors comme aide optionnelle, jamais comme remplacement imposé du graphe.
- [x] 5. Relier les sélecteurs de dialogues, événements et cinématiques à leurs documents sans fusionner leurs identités.
- [x] 6. Préserver les brouillons, révisions et historique du contrôleur ; rendre les erreurs de référence localisables sur le graphe.
- [ ] 7. Ce lot porte aussi l’entrée Histoire (narrative_overview_landing.dart). Y ajouter, à côté des accès directs, des entrées orientées résultat : « Faire parler un personnage », « Déclencher une scène en entrant », « Créer une quête », « Mettre en scène un déplacement ». Chaque parcours dit quels documents il crée et où les modifier, sans prétendre couvrir ce qui n’est pas pris en charge (audit N01, P1).
- [x] 8. Compléter zoom et mini-carte par le suivi des entrées et sorties et la lecture d’un chemin pas à pas ; les ports gardent leur cible de 28 × 28 quel que soit le zoom (audit N03, P1).
- [x] 9. Permettre de relier deux blocs au clavier (choisir la sortie, choisir la cible, confirmer), avec annonce et annulation, puis le prouver au lecteur d’écran (audit N04, P1).
- [x] 10. Réserver « Reprendre » à une vraie reprise ; avant la première vérification narrative, une explication et une action principale (audit N11).

**Tests comportementaux obligatoires :**

- Ajouter puis relier un nœud, annuler puis rétablir conserve IDs et connexions.
- Une liaison faite uniquement au clavier crée le même lien qu’au pointeur et s’annule en une étape.
- Une référence de dialogue supprimée reste visible comme erreur ; aucun remplacement silencieux.
- Tester une scène puis revenir restaure le même document et le même nœud sélectionné.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/scene_graph_canvas_test.dart
- apps/avelune_studio/test/scenes/scene_session_ui06_test.dart
- apps/avelune_studio/test/scenes/scene_history_ui06_test.dart
- apps/avelune_studio/test/scenes/scene_reconciliation_ui07_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/scenes/scene_graph_context_journey_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/scene_graph_canvas_test.dart test/scenes/scene_session_ui06_test.dart test/scenes/scene_history_ui06_test.dart test/scenes/scene_reconciliation_ui07_test.dart test/scenes/scene_graph_context_journey_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Document de scène et références liées, persistés via son propriétaire ; aucun journal local React copié dans l’application.

**Sortie du lot :** Le graphe reste puissant et complet ; les actions courantes sont plus lisibles et leurs références préservées.

**Références visuelles :** [077-scene-graphe](2026-11-06-refonte-studio/captures/077-scene-graphe.jpg), [078-scene-dialogue](2026-11-06-refonte-studio/captures/078-scene-dialogue.jpg), [079-scene-action](2026-11-06-refonte-studio/captures/079-scene-action.jpg), [h03-scene-ancienne](2026-11-06-refonte-studio/captures/h03-scene-ancienne.jpg), [g038](2026-11-06-refonte-studio/captures/g038.jpg).


### UX-23.1 — Présences, interactions et variantes conditionnelles

**Priorité :** P2. **Dépendances :** UX-08, UX-12.5, UX-22.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/map_workspace/map_decor_inspector_tabs.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_trigger_inspector.dart
- apps/avelune_studio/lib/presentation/features/narrative/narrative_conditions_editor.dart
- apps/avelune_studio/lib/features/map_workspace/application/map_entity_editing_commands.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/map_workspace/conditional_presence_scope_test.dart

**Étapes d’implémentation :**

- [x] 1. Décrire explicitement la présence sur la carte, sa ressource et ses variantes existantes. — **livré** par 9b2b9e85b (règle de présence en clair, variantes de dialogue décrites, marque dans le contenu de carte).
- [x] 2. Composer les conditions avec les sélecteurs natifs, sans ID obligatoire et sans écraser une référence inconnue. — **livré** par 9b2b9e85b (étape, état, badge ; chapitres et cinématiques décrits et conservés).
- [x] 3. Séparer apparence de la présence, condition de visibilité et interaction ; montrer la règle effective et son origine. — **en partie** par 9b2b9e85b : règle effective et origine affichées ; « Apparence selon les conditions » reste un panneau séparé, sans synthèse commune (attend UX-22, D-02).
- [x] 4. Relier une interaction à une scène depuis la sélection et permettre le retour au même élément. — **livré** par 961b1703d (travail de narration-restes repris par la session Carte) : « Ouvrir sa scène » depuis le PNJ sélectionné ouvre la scène jouée par son interaction à son départ et « Carte » revient au même personnage ; preuve `test/presentation/dialogue_event_owner_journey_test.dart`. Le blocage D-02 ne portait que sur le retour au nœud, livré par UX-22 (focusNode).
- [x] 5. Tester chaque branche d’un petit exemple avec un état du monde contrôlé, sans ajouter de nouvelle mécanique. — **livré** par 9b2b9e85b (test des deux branches dans l’inspecteur).

**Tests comportementaux obligatoires :**

- Modifier une variante locale ne change pas le personnage réutilisable.
- Une condition non résolue est conservée et signalée.
- Une variante inactive reste retrouvable dans le contenu de carte.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/map_workspace/field_obstacle_inspector_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/map_workspace/conditional_presence_scope_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/map_workspace/field_obstacle_inspector_test.dart test/map_workspace/conditional_presence_scope_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Entité ou présence native et conditions référencées ; pas de modification des documents de progression à l’édition d’un label.

**Sortie du lot :** Les apparitions et interactions sont compréhensibles sans mélanger leurs propriétaires.

**Références visuelles :** [g015](2026-11-06-refonte-studio/captures/g015.jpg), [g016](2026-11-06-refonte-studio/captures/g016.jpg), [g017](2026-11-06-refonte-studio/captures/g017.jpg), [h02-dialogue-parcours](2026-11-06-refonte-studio/captures/h02-dialogue-parcours.jpg).


### UX-23.2 — Dialogues, choix, résultats, événements et zones d’histoire

**Priorité :** P2. **Dépendances :** UX-22, UX-10.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/dialogues/dialogue_workspace_page.dart
- apps/avelune_studio/lib/presentation/features/dialogues/dialogue_inspector.dart
- apps/avelune_studio/lib/presentation/features/events/event_workspace_page.dart
- apps/avelune_studio/lib/presentation/features/events/event_scene_panel.dart
- apps/avelune_studio/lib/features/dialogues/application/dialogue_workspace_links.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/presentation/dialogue_event_owner_journey_test.dart

**Étapes d’implémentation :**

- [ ] 1. Conserver bibliothèque, graphe de dialogue, choix, résultats, portraits, variantes et sources externes prises en charge.
- [x] 2. Relier Quand/Si/Alors à l’événement réel et permettre d’ouvrir sa scène ou son dialogue sans dupliquer le document. — **livré** par 961b1703d : l’événement ouvre sa scène et les dialogues qu’elle joue dans leur propre document, sans copie, puis revient à l’événement ; preuve `dialogue_event_owner_journey_test.dart`.
- [ ] 3. Présenter ordre d’exécution, condition, répétition et politique de fin existants.
- [x] 4. Pour une zone d’histoire, montrer sa forme, son profil admissible et l’événement déclenché. — **livré** par 096c10f97 et 30a6ea0a0 : forme, événements déclenchés et déclenchements possibles (entrer, toucher) avec la raison canonique d’un refus ; vérifié en natif sur une zone créée par `trigger.create` dans la copie HGSS.
- [x] 5. Vérifier une branche de choix avec résultat, puis le retour à l’événement et à la carte d’origine. — **livré** par 961b1703d : une branche de choix est parcourue jusqu’à ses deux résultats (« attente », « embarquement ») puis le parcours revient à l’événement et à la carte, personnage resélectionné, sans écriture ; preuve `dialogue_event_owner_journey_test.dart`.
- [x] 6. Rendre la scène d’un événement recherchable par nom et par contexte disponible, la scène déjà liée en tête et l’identifiant en détail (audit N02, P1 ; event_scene_panel.dart). HGSS compte 426 scènes. — **livré** par 3ea3a966b.
- [x] 7. Montrer d’abord l’effet en jeu des options d’événement (une fois, à chaque visite, après une condition, quand ces règles existent) ; placer ordre, priorité et registre dans des options avancées, sans migration implicite (audit N05, P1 ; event_options_panel.dart). — **livré** par 3ea3a966b.
- [x] 8. Présenter « toutes les conditions » ou « au moins une condition » avec une phrase de résultat lisible, surtout avant une inversion ou un regroupement (audit N07 ; event_conditions.dart). — **livré** par 096c10f97.

Les étapes 6 et 7 portent des constats P1 sur les écrans actuels : elles peuvent être livrées avant le reste du lot, dès que UX-22 est engagé.

**Tests comportementaux obligatoires :**

- Une référence externe manquante conserve son identité et ne se transforme pas en dialogue vide.
- Une branche invalide est localisée ; sauvegarder une ligne ne republie pas toutes les scènes.
- Les profils refusés restent cohérents dans bibliothèque, menu Ajouter et inspecteur.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/dialogues_ui09_navigation_test.dart
- apps/avelune_studio/test/dialogues_ui09_nested_navigation_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/presentation/dialogue_event_owner_journey_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/dialogues_ui09_navigation_test.dart test/dialogues_ui09_nested_navigation_test.dart test/presentation/dialogue_event_owner_journey_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Document de dialogue ou événement courant et références réellement modifiées.

**Sortie du lot :** Un parcours personnage→interaction→dialogue avec choix→résultat→retour carte est complet, natif et sans perte de référence.

**Références visuelles :** [g039](2026-11-06-refonte-studio/captures/g039.jpg), [g040](2026-11-06-refonte-studio/captures/g040.jpg), [g041](2026-11-06-refonte-studio/captures/g041.jpg), [h02-dialogue-parcours](2026-11-06-refonte-studio/captures/h02-dialogue-parcours.jpg).


### UX-23.3 — Histoires, étapes et progression

**Priorité :** P2. **Dépendances :** UX-22, UX-23.2.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/stories/story_progression_page.dart
- apps/avelune_studio/lib/presentation/features/stories/story_graph_canvas.dart
- apps/avelune_studio/lib/presentation/features/stories/story_relation_details.dart
- apps/avelune_studio/lib/presentation/features/stories/story_document_commands.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/presentation/story_progression_scope_journey_test.dart

**Étapes d’implémentation :**

- [x] 1. Organiser les histoires, chapitres et étapes déjà supportés avec recherche et relation aux scènes. — **en partie** par 9cfe1aa5f : recherche dans chapitres et étapes ; relation aux scènes inchangée.
- [x] 2. Montrer préconditions, transitions et résultats de progression sans confondre configuration et progression d’une sauvegarde. — **livré** par 9cfe1aa5f et f9e029cd8 : configuration distinguée des sauvegardes, états nommés ; les résultats attendus se cochent par leur libellé et leur source (scène ou scénario de l’étape), un résultat disparu reste conservé et signalé ; vérifié en natif sur une histoire créée par `storyline.upsert`.
- [ ] 3. Conserver les graphes et les documents spécialisés ; un tableau synthétique reste un accès rapide. — **BLOCKED** : la forme du tableau relève de la direction de design Histoire (D-02).
- [ ] 4. Localiser les cycles ou références invalides avec l’action d’ouverture du bon document.
- [ ] 5. Exécuter un petit parcours de progression avec état initial contrôlé et vérifier ses effets existants.

**Tests comportementaux obligatoires :**

- Renommer une étape conserve son identifiant et les références des scènes.
- Un conflit externe conserve le brouillon.
- Le test ne remplace pas la progression d’une sauvegarde utilisateur.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/presentation/ui07_story_selection_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/presentation/story_progression_scope_journey_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/presentation/ui07_story_selection_test.dart test/presentation/story_progression_scope_journey_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Document d’histoire/étape courant ; les sauvegardes de joueur sont hors écriture pendant l’authoring.

**Sortie du lot :** Les liens entre histoire et scènes sont visibles, navigables et validés sans dépendance implicite à l’état du Player.

**Références visuelles :** [g042](2026-11-06-refonte-studio/captures/g042.jpg), [h01-histoire-ancienne-direction](2026-11-06-refonte-studio/captures/h01-histoire-ancienne-direction.jpg).


### UX-23.4 — Cinématiques sur carte et présentations animées

**Priorité :** P2. **Dépendances :** UX-22, UX-12.1.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/cinematics/cinematic_workspace_page.dart
- apps/avelune_studio/lib/presentation/features/cinematics/cinematic_page_timeline.dart
- apps/avelune_studio/lib/presentation/features/cinematics/cinematic_inspector_camera.dart
- apps/avelune_studio/lib/presentation/features/presentations/presentation_workspace_page.dart
- apps/avelune_studio/lib/presentation/features/presentations/presentation_page_preview.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/presentation/cinematic_presentation_return_journey_test.dart

**Étapes d’implémentation :**

- [ ] 1. Conserver les pistes, durées, acteurs, caméra, points et ressources des éditeurs actuels.
- [x] 2. Afficher la portée d’un changement de caméra de séquence séparément de la caméra de jeu et du projet. — **livré** par 70e9acd2a (une action caméra ne vaut que pendant la cinématique et ne modifie ni la caméra de la carte ni les réglages Image et caméra) ; prouvé par test, pas vérifié en natif.
- [ ] 3. Conserver le montage visuel et les propriétés avancées à la demande ; ne pas fusionner une présentation et une cinématique en un format nouveau.
- [x] 4. Relier le document à la scène déclenchante et revenir au bon nœud. — **livré** par 961b1703d : « Scène déclenchante » liste les scènes qui jouent la cinématique et ouvre l’une d’elles à son bloc, avec retour de part et d’autre ; preuve `test/presentation/cinematic_presentation_return_journey_test.dart`.
- [ ] 5. Prévisualiser, arrêter puis rouvrir en vérifiant positions, médias et durée ; les ressources requises doivent rester exportées hors ligne.
- [x] 6. Dans Séquence, sans étape sélectionnée, expliquer comment sélectionner ou ajouter une action plutôt que répéter les propriétés générales, qui restent accessibles (audit N08 ; cinematic_inspector.dart). — **livré** par 979120f23, avec écart : le guidage est dans Propriétés (l’onglet qui répétait les réglages), Séquence liste désormais les actions.
- [x] 7. Grouper les diagnostics identiques de l’aperçu, dire si la lecture est bloquée et permettre d’aller à l’acteur ou au bloc concerné (audit N09 ; cinematic_preview_status.dart). Le libellé `null · <id>` est corrigé tôt par UX-03.1. — **livré** par 979120f23 (la lecture n’est pas bloquée par le transport : le texte le dit).

**Tests comportementaux obligatoires :**

- L’arrêt d’une prévisualisation libère ses lecteurs et ne laisse pas un renderer orphelin.
- Un média absent reste une référence récupérable.
- Une édition de point n’invalide pas les séquences sans rapport.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/cinematics_ui10_nested_navigation_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/presentation/cinematic_presentation_return_journey_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/cinematics_ui10_nested_navigation_test.dart test/presentation/cinematic_presentation_return_journey_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Document cinématique/présentation et médias explicitement modifiés ; pas de nouvelle dépendance runtime externe.

**Sortie du lot :** Le créateur peut monter, prévisualiser, lier et reprendre un document sans modifier les réglages globaux par erreur.

**Références visuelles :** [g043](2026-11-06-refonte-studio/captures/g043.jpg), [g044](2026-11-06-refonte-studio/captures/g044.jpg).


### UX-23.5 — Rencontres et dresseurs : affectation explicite à la carte

**Priorité :** P2. **Dépendances :** UX-10, UX-13.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/pokemon/pokemon_combat_page.dart
- apps/avelune_studio/lib/presentation/features/pokemon/pokemon_combat_table_detail.dart
- apps/avelune_studio/lib/presentation/features/pokemon/pokemon_combat_trainer_detail.dart
- apps/avelune_studio/lib/presentation/features/map_workspace/map_zone_inspector.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/presentation/encounter_trainer_authoring_journey_test.dart

**Étapes d’implémentation :**

- [ ] 1. Conserver les tables, poids, niveaux, créneaux, variantes et équipes natives.
- [ ] 2. Fournir des sélecteurs d’espèce et de capacité recherchables avec détails utiles et références manquantes visibles.
- [x] 3. Distinguer créer une table et l’affecter à un terrain ou une zone ; afficher les usages. — **livré** par 628510049 (avertissement d’affectation distinct de l’invalidité ; usages complétés par les rencontres interactives).
- [x] 4. Relier un dresseur, son interaction et sa scène sans déplacer les règles de combat dans l’UI. — **livré** par 961b1703d : les usages d’un dresseur nomment le personnage et le bloc Combat et l’ouvrent, avec « Retour à Pokémon » ; aucune règle de combat dans l’UI ; preuve `test/presentation/encounter_trainer_authoring_journey_test.dart`.
- [ ] 5. Tester un exemple borné de rencontre et de dresseur avec les règles existantes ; préserver la distribution et les sauvegardes.

*Vague 3 (cout-carte) : l'analyse des usages de combat reste une lecture globale de toutes les cartes et scènes (~2 min 30 natif sur HGSS, mesure de la session Narration, non remesurée : session macOS verrouillée) ; elle est explicite et affiche désormais qu'elle est en cours — a80278960. La rendre proportionnelle demande un index des usages par table et par dresseur.*

**Tests comportementaux obligatoires :**

- Table valide mais non affectée : avertissement distinct d’une table invalide.
- Une référence d’espèce absente n’est pas supprimée au changement de filtre.
- Modifier une équipe ne modifie pas une autre définition portant un nom identique.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/map_workspace/interactive_encounter_inspector_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/presentation/encounter_trainer_authoring_journey_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/map_workspace/interactive_encounter_inspector_test.dart test/presentation/encounter_trainer_authoring_journey_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Documents de table/dresseur et affectation locale ; moteur de combat inchangé.

**Sortie du lot :** L’auteur sait où une table ou un dresseur sera utilisé et peut rejoindre ce contexte.

**Références visuelles :** [g045](2026-11-06-refonte-studio/captures/g045.jpg), [g046](2026-11-06-refonte-studio/captures/g046.jpg).


### UX-23.6 — Espèces, capacités, objets et règles de combat

**Priorité :** P2. **Dépendances :** UX-11, UX-13.

**Décision D-02, option b pour Pokémon :** pas de refonte visuelle dédiée. Ce lot corrige les constats de l’audit dans les écrans actuels, harmonisés par les composants et tokens du design system issus de UX-01.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/pokemon/pokemon_workspace_page.dart
- apps/avelune_studio/lib/presentation/features/pokemon/pokemon_species_detail.dart
- apps/avelune_studio/lib/presentation/features/pokemon/pokemon_move_detail.dart
- apps/avelune_studio/lib/presentation/features/pokemon/pokemon_commerce_page.dart
- apps/avelune_studio/lib/presentation/features/pokemon/pokemon_item_effects.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/presentation/pokemon_data_editor_scope_test.dart

**Étapes d’implémentation :**

- [ ] 1. Conserver les bibliothèques et les formulaires spécialisés actuels, avec recherche et chargement paginé.
- [ ] 2. Afficher la provenance importée, les corrections locales et les champs avancés sans dupliquer les données de catalogue.
- [ ] 3. Préserver formes, évolutions, learnsets, effets d’objet et paramètres de règles effectivement supportés.
- [ ] 4. Rendre la portée et les usages d’une modification partagée explicites ; conserver les références inconnues.
- [ ] 5. Séparer cette refonte d’interface des chantiers de recettes d’animations et de mécanique de combat en cours.
- [x] 6. Remplacer la saisie « Identifiants liés · séparés par une virgule » des formes (pokemon_species_forms.dart:81) par une recherche multi-sélection avec nom, aperçu et référence manquante visible ; identifiants en option avancée ; références existantes conservées même non résolues (audit R07, P1). — **livré** par 7529620f2.
- [x] 7. Séparer la description d’une évolution et la règle réellement comprise par le jeu ; choix guidés pour les seules méthodes prises en charge, les autres signalées sans perte de données (audit R08, P1 ; pokemon_evolution_entry.dart). Vérifier chaque mécanique avant toute promesse. — **livré** par 7529620f2.
- [x] 8. Dire « Ajouter » pour un rôle de média vide et « Remplacer » seulement si un parcours sûr existe ; localiser les rôles techniques comme `icon` et `party` ; signaler un média référencé mais absent (audits R09, P1, et R10 ; pokemon_species_media.dart). — **livré** par b6c657ed3.
- [x] 9. Remplacer la poche d’objet saisie librement par un choix validé des poches disponibles (audit R06 ; pokemon_item_overview.dart). Les libellés lisibles des poches sont corrigés tôt par UX-03.1. — **livré** par cd81aa24c (« Nouvelle poche… » explicite).
- [x] 10. Depuis combat et attaques, proposer l’aller-retour vers la carte ou la scène liée lorsque l’identité est connue, sans inventer de raccourci que l’architecture ne permet pas (audit R13). — **en partie** par 628510049 et cd81aa24c : marche à suivre d’affectation, références complétées, « Préparer la synchronisation » ; pas d’aller-retour direct vers une carte non encore choisie.

Les étapes 6 à 8 portent des constats P1 sur les écrans actuels : elles peuvent être livrées avant le reste du lot.

**Tests comportementaux obligatoires :**

- Modifier un champ d’espèce conserve les médias et champs non affichés.
- Un changement de sélection rapide ne publie pas le brouillon sur l’élément suivant.
- Une importation refusée ne réinitialise pas les corrections locales.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/pokemon/pokemon_draft_history_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/presentation/pokemon_data_editor_scope_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/pokemon/pokemon_draft_history_test.dart test/presentation/pokemon_data_editor_scope_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Document ou correction de catalogue ciblé ; aucune réimportation globale pour un champ local.

**Sortie du lot :** La richesse actuelle de données reste accessible dans des formulaires cohérents ; aucune règle de gameplay n’est changée pour simplifier l’écran.

**Références visuelles :** [g047](2026-11-06-refonte-studio/captures/g047.jpg), [g048](2026-11-06-refonte-studio/captures/g048.jpg), [h-premier-4](2026-11-06-refonte-studio/captures/h-premier-4.jpg).


### UX-23.7 — Carte régionale et arrivées de Vol

**Priorité :** P2. **Dépendances :** UX-02, UX-10.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/regional_map/regional_map_page.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/presentation/regional_map_arrival_scope_test.dart

**Étapes d’implémentation :**

- [x] 1. Conserver régions, illustration, lieux et correspondance avec les cartes natives. — **livré** par ac3cf899a : régions, image, lieux, cartes liées et destination conservés et relus après enregistrement et réouverture ; preuves `regional_map_page_test.dart`, `regional_map_arrival_scope_test.dart`, `regional_map_place_flight_test.dart`.
- [x] 2. Ajouter sélection et recherche de lieu, réglage de position et aperçu de destination. — **livré** par ac3cf899a : recherche de lieu par nom ou carte d’arrivée de Vol, position lisible en pourcentage avec le glisser-déposer existant, aperçu de l’arrivée de Vol (carte, point, coordonnées, regard).
- [x] 3. Distinguer lieu visible sur la carte régionale et arrivée autorisée de Vol. — **livré** par ac3cf899a : résumé séparé « visible sur la carte régionale » et « Vol autorisé vers … », section Vol indépendante de la visibilité.
- [x] 4. Préserver les conditions de progression et profils supportés ; la mécanique de Vol différée n’est pas déclarée livrée par le nouvel écran. — **livré** par ac3cf899a : visibilité, découverte et cartes liées inchangées ; aucun texte ne déclare Vol livré (FG-125 reste `DEFERRED`), l’aperçu dit seulement qu’une destination incomplète est refusée, comme `fly_action.dart`.
- [x] 5. Tester une destination existante et une référence manquante, puis la réouverture du document. — **livré** par ac3cf899a : destination existante, carte d’arrivée introuvable, point d’arrivée disparu ou non choisi, puis enregistrement et réouverture ; preuve `test/presentation/regional_map_place_flight_test.dart`. Non vérifié en natif.
- [x] 6. Lister les cartes liées avec recherche multi-sélection, dossier et résumé des choix, et expliquer pourquoi un retrait est refusé ; distinguer aperçu en attente, absent et en erreur (audit M10). La liaison implicite de la première carte (M09) est corrigée tôt par UX-03.1. — **livré** par b6f400d07. États « chargement », « absente » et « illisible » prouvés par tests à états forcés sur la vraie page régionale (ec6cf3584).

**Tests comportementaux obligatoires :**

- Renommer un lieu conserve la destination stable.
- Une arrivée supprimée n’est pas remplacée silencieusement par le départ du jeu.
- Le contrôle de capacité d’activation ne contourne pas une restriction de gameplay.

**Tests existants à relancer ou étendre :**

- Aucune cible existante spécifique n’est supposée ; créer le test du lot ci-dessous.

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/presentation/regional_map_arrival_scope_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/presentation/regional_map_arrival_scope_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Document régional et liens des lieux réellement édités ; pas de mutation de toutes les cartes.

**Sortie du lot :** Lieu, carte et arrivée ont des relations explicites et récupérables.

**Références visuelles :** [g049](2026-11-06-refonte-studio/captures/g049.jpg), [h-premier-0](2026-11-06-refonte-studio/captures/h-premier-0.jpg).


### UX-23.8 — Talus, plateformes et comportements avancés de déplacement

**Priorité :** P2. **Dépendances :** UX-09, UX-10, UX-12.1, UX-12.3.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/lib/presentation/features/map_workspace/spatial_platform_controls.dart
- apps/avelune_studio/lib/presentation/features/resources/native_ledge_panel.dart
- apps/avelune_studio/lib/presentation/features/resources/model_ramp_controls.dart
- apps/avelune_studio/lib/features/map_workspace/application/map_workspace_field_obstacles.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/map_workspace/advanced_traversal_authoring_journey_test.dart

**Étapes d’implémentation :**

- [ ] 1. Rattacher talus, franchissement, rampes, plateformes et obstacles à leurs propriétaires natifs existants.
- [x] 2. Présenter sens, niveau, trajet, durée et conditions seulement pour les capacités réellement supportées. — **livré** par 5c61cc0bf et 013546ea3 : saut d’un rebord Border (distance, durée, hauteur, côté), durée appliquée d’une plateforme en secondes, et pour un talus 3D une phrase sens, distance, durée, hauteur et retour bloqué ; vérifié en natif sur la Route 29 HGSS (talus natifs) et une plateforme sur trajet ajoutée par `map.platform.upsert` (CLI). Le panneau Border de rebord n’est pas vérifié en natif : HGSS n’a pas de Border de rebord à saut.
- [ ] 3. Distinguer une zone d’interaction, un déplacement d’objet et une règle de traversée du joueur.
- [ ] 4. Désactiver et expliquer une action non consommée par le runtime ; ne pas simuler un moteur manquant.
- [ ] 5. Vérifier visuellement le sens et les niveaux puis le passage réel dans un exemple minimal ; conserver les contrats différés de roadmap. — **en partie** : sens, niveaux et arrivée vérifiés en natif (Route 29) ; le passage réel est prouvé par `map_gameplay/test/spatial_ledge_movement_test.dart` (saut, atterrissage, retour bloqué), pas en marchant dans le test natif.

**Tests comportementaux obligatoires :**

- Un talus n’est franchissable que dans le sens configuré lorsque la mécanique est supportée.
- Une plateforme garde son trajet et sa durée après annulation et réouverture.
- Un profil non pris en charge conserve ses données et produit une erreur explicite.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/resource_io/ledge_border_metadata_test.dart
- packages/map_distribution/test/spatial_border_stair_support_compatibility_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/map_workspace/advanced_traversal_authoring_journey_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/resource_io/ledge_border_metadata_test.dart test/map_workspace/advanced_traversal_authoring_journey_test.dart
flutter analyze

cd /Users/karim/Project/pokemonProject/packages/map_distribution
dart test test/spatial_border_stair_support_compatibility_test.dart
dart analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Contour, modèle ou plateforme ciblés ; aucune reconstruction du monde pour un paramètre de déplacement.

**Sortie du lot :** Les fonctions avancées disponibles sont utilisables sans jargon inutile ; les fonctions différées restent honnêtement qualifiées.

**Références visuelles :** [g008](2026-11-06-refonte-studio/captures/g008.jpg), [g017](2026-11-06-refonte-studio/captures/g017.jpg), [g018](2026-11-06-refonte-studio/captures/g018.jpg), [g033](2026-11-06-refonte-studio/captures/g033.jpg).


### UX-24 — Parité API, JSONL/CLI, Studio et MCP

**Priorité :** P0. **Dépendances :** UX-03.1, UX-21, UX-22, UX-23.1, UX-23.2, UX-23.3, UX-23.4, UX-23.5, UX-23.6, UX-23.7, UX-23.8.

**Modifier ou réutiliser les propriétaires existants :**

- packages/map_authoring/lib/src/registry/action_registry.dart
- packages/map_authoring/lib/src/registry/resource_kind_registry.dart
- packages/map_authoring/lib/src/parity/full_authoring_parity.dart
- tools/pokemap_mcp/package.json

**Étapes d’implémentation :**

- [x] 1. Réunir la matrice des deltas sémantiques de chaque lot et justifier les opérations purement UI sans exposition supplémentaire. — **livré** : matrice ci-dessous, 49 commits de `d33da791b^..57377c648`.
- [x] 2. Découvrir les actions et schémas actuels ; réutiliser les endpoints canoniques de profil, visuels, Surf et audio. — **livré** : `pokemap_describe` sur le serveur reconstruit (471 actions, 60 outils) une fois la racine morte retirée de `.mcp.json` (3bf4fe8ff) ; chaque action citée est découverte avec son schéma.
- [x] 3. Ajouter des contrats versionnés seulement pour les sémantiques absentes ; ne pas les cacher dans des contrôleurs Flutter. — **sans objet** : aucune sémantique absente dans la plage ; aucun contrat ajouté.
- [ ] 4. Prouver le même résultat et les mêmes refus en API directe, JSONL/CLI et Studio, puis dans le transport MCP. — **en partie** : reçus de bout en bout sur les quatre transports pour la plupart des actions citées ; héritage d’un paramètre local, rejeu idempotent et refus hors racine prouvés par MCP (`tools/pokemap_mcp/test/visual_settings_stdio.test.ts`). Reçus ajoutés par la session Carte le 7 novembre : `warp.create` et `warp.update` (aaf1d087a, reçus existants enregistrés) ; `placed_element.place`, `.move`, `.clone`, `.delete` (6d0282f76 : API, JSONL, MCP stdio avec refus canoniques, parcours disque Studio) ; reçu Studio de `map3d.instance.upsert_batch`, `map3d.instance.delete_batch` et `map3d.edit_batch` (e2826f519). Ce travail a révélé que la duplication 2D du Studio perdait décalage, rotation, collision, opacité, animation, comportements, propriétés et calque ; corrigé par 5a0d59d43. Le Studio persiste toujours par l’enregistrement de carte entière : ses reçus prouvent le même résultat sur disque, pas l’envoi de l’action canonique. Restent sans reçu de bout en bout : `item.update`, `item.create`, `pokemon.species.write`, `pokemon.evolution.write`, `pokemon.media.import`, `environment.preset.upsert`, `border_layer.stroke_add` ; sans reçu Studio : `resource.classify_batch`.
- [x] 5. Exécuter la conformité, reconstruire/recharger le serveur appartenant à la session et consulter pokemap_describe sur le catalogue vivant. — **livré** : `full_authoring_parity_test.dart` 28/28 ; PMCP-085 : catalogue complet, 0 cellule bloquée ou manquante, sortie 1 seulement parce que les reçus de transport Item manquent (préexistant) ; `npm run check` propre ; `npm test` : 309 réussis, 71 échecs préexistants au HEAD 57377c648 (listes d’outils et schémas figés dans les tests, délais de 10 s), aucun lié à la configuration.
- [x] 6. Ne pas confondre sérialisation JSON et support sémantique ; classer une exposition absente comme PARTIAL. — **appliqué** : chaque ligne nomme une action canonique ou un motif N/A ; aucune ligne ne s’appuie sur la seule persistance JSON.

**Matrice des deltas sémantiques** (agent Parité, 7 novembre 2026, HEAD 57377c648). Classes : **D** disposition, lecture ou brouillon de présentation, N/A motivé ; **C** sémantique couverte par l’action canonique nommée ; **A** sémantique absente (aucune).

| Lot · commits | Delta | Classe | Action canonique ou motif |
|---|---|---|---|
| UX-00, plans · 14cdc23de, 3881b71ec, 712112d67, ab5d4f22e, fefd5341c | Documentation | D | Aucun code |
| UX-01, UX-02 · 66fbcea27, 1c91c4f96, 60f640327 (shell, mode carte seule) | Navigation clavier, accueil orienté objectif, lecture de `newGame` | D | Lecture seule |
| UX-02.1 · 4c552a318 | Dossiers et classement des cartes ; création guidée de carte et de projet | C | `map.library.reorganize` ; `map.create` (`groupId` ; la planche refusée en 3D l’est par `map.create`) ; `pokemap_project_create` et ses modèles. Recherche sans accents : D |
| UX-03, UX-03.1 · 48f70a09a, d33da791b | ⌘K, libellés ; carte régionale sans lien implicite à la première carte ; image de région admissible | C | `regionalMap.poi.upsert` et `regionalMap.region.upsert` : `mapIds` et `destination.mapId` sont toujours explicites, l’API n’en invente aucun ; `ProjectRegionDefinition.acceptsImagePath` publie la règle du décodeur canonique, refus identiques |
| UX-04, UX-05, UX-06, UX-08 · 0757a4ced, 66ea27452, e1f9f99d8, b7d544352 | Intention active, recherche par intention, contenu filtrable, cible et propriétaire des décors générés | D | Présentation |
| UX-07 · 06ac28ab8, 60f640327 | Déplacement, retrait, duplication et rotation groupés | C | 3D : `map3d.instance.upsert_batch`, `map3d.instance.delete_batch` ou `map3d.edit_batch` ; 2D : `placed_element.move`, `.delete`, `.clone`, `.place`. Le Studio persiste toujours par l’enregistrement de carte entière, chemin préexistant suivi par UX-25 |
| UX-09, UX-12.3 · d96ab8849, e1e5032eb | Revue des profils et contours de Border avant application ou republication | D | Revue en lecture ; l’application reste `border_layer.*` et `border.blueprint.draft.upsert` / `border.blueprint.publish` (republication spatiale en catalogue toujours non prise en charge, limite préexistante) |
| UX-10 · 641da2bfb | Destination d’un passage cherchée par carte et dossier | C | `warp.update`, `warp.create` (`warpDestinationContract`) ; le sélecteur est D |
| UX-11 · 641ab9706, e10d452f9 | Tri et rangement de plusieurs ressources ; export d’une sélection | C | `resource.classify_batch`, `resource.family.*` ; `pokemap_resource_pack` (`selection.patch`) ; sélection retirée nommée : D |
| UX-12, UX-12.1, UX-12.2, UX-12.4, UX-12.5 · f3f8ddfb6, 4351adf70, 2d6c5ed3e, ddda284c6, 078748ce7, ba222f6a5 | Import resté source, portée d’un modèle partagé, usage d’un terrain, environnement partagé, onglet identité | D | Lectures d’usage et libellés ; mutations inchangées : `asset.import`, `model3d.configure`, `environment.preset.upsert`, `characterStudio.*` |
| UX-13 · c49df5138 | Incident nommé par son propriétaire et sa prochaine action | D | Projection d’incidents existants |
| UX-14 · 59ab3a485 | Brouillons, enregistrement et annulation par rubrique | C | `pokemap_visual_settings_set` (patch complet de la portée, révision attendue ; la rubrique est le sous-ensemble composé sur l’état lu) ; `pokemap_visual_settings_undo` (dernier reçu) ; annulation avant enregistrement : brouillon D |
| UX-15 · 973e2544a | Identité de jeu réglée dans Général et reprise par l’export | C | `pokemap_game_export_profile_read` / `_validate` / `_save`, révisions attendues et refus `exportProfileStale` |
| UX-16 · 3bbdefa13 | Origine des valeurs ; refus d’une saisie caméra hors bornes | C | Bornes `SpatialVisualParameter.minimum` / `maximum`, refusées aussi par le modèle canonique ; aperçu sans enregistrer : D |
| UX-17 · d4bbe9242 | Retour d’une carte à l’héritage | C | `pokemap_visual_settings_set` sur la portée carte : retirer un paramètre du patch le rend hérité, les autres valeurs locales restent ; prouvé par MCP |
| UX-18, UX-21 · 49233ed43, c91ccab0f | Repli de la météo réelle ; revue des brouillons avant test | D | Explication et revue ; le test passe par `pokemap_playtest` |
| UX-19 · d02ed5dba | Autoriser, connaître, débloquer une capacité ; vitesse de Surf décimale | C | `field_ability.configure`, `surf.configure` ; la virgule décimale est une normalisation de saisie |
| UX-20 · 904c9a226 | Enregistrer une seule association sonore | C | `project.audio.cue.configure`, déjà une action par cue ; écoute : D |
| UX-23.1 · 9b2b9e85b, 57377c648 | Présence d’histoire composée par sélecteurs natifs | C | `npc.set_visibility_rule` (mode et prédicat étape, état ou badge) ; chargement des références avant jugement : D |
| UX-23.2 · 3ea3a966b, 096c10f97 | Scènes cherchables, options par effet ; « Toutes / Une seule suffit » | C | `event_v2.record_upsert` : `all` / `any` font déjà partie de `NarrativeEventConditionExpression` ; recherche et phrases : D |
| UX-23.3, UX-23.4, UX-23.8 · 9cfe1aa5f, 979120f23, 5c61cc0bf | Recherche d’histoires, guidage des cinématiques, durées de saut et de plateforme | D | Présentation |
| UX-23.5 · 628510049 | Table ou dresseur inutilisé distinct d’invalide ; usages par objets de carte | C | Diagnostic Studio D ; `campaign.encounter_table.delete` refusait déjà toute référence exacte dans les cartes, le Studio s’y aligne |
| UX-23.6 · cd81aa24c, 7529620f2, b6c657ed3 | Poche choisie ou créée explicitement ; liens de formes et règles d’évolution ; disponibilité des médias | C | `item.update` / `item.create` (`pocketId`), `bag.capacity.set` ; `pokemon.species.write`, `pokemon.evolution.write` ; `pokemon.media.import` ne remplace jamais ; sonde de médias : lecture D, même statut que la cohérence Pokémon canonique |
| UX-23.7 · b6f400d07 | Lier un lieu régional à une carte par recherche | C | `regionalMap.poi.upsert` (`mapIds` explicites) |
| 07a287cab | État des sections repliables | D | Présentation |

**Tests comportementaux obligatoires :**

- Même opération avec même identité : pas de double mutation ; révision périmée : refus cohérent.
- Un chemin hors racine est refusé sans élargir les racines autorisées.
- Une action disponible dans Studio est découvrable et documentée dans le catalogue vivant lorsqu’elle doit l’être.

**Tests existants à relancer ou étendre :**

- packages/map_authoring/test/parity/full_authoring_parity_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/packages/map_authoring
dart test test/parity/full_authoring_parity_test.dart
dart analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Catalogues et transports ; mutations uniquement sur fixtures QA appartenant au lot.

**Sortie du lot :** Toute nouvelle sémantique a ses preuves par transport ; N/A est motivé pour la disposition pure.

**Références visuelles :** [g050](2026-11-06-refonte-studio/captures/g050.jpg), [g052](2026-11-06-refonte-studio/captures/g052.jpg).


### UX-25 — Certification locale du coût et de la compatibilité

**Priorité :** P0. **Dépendances :** UX-24.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/test/project_visuals/project_visuals_controller_test.dart
- packages/map_authoring/test/documents/visual_settings_authoring_test.dart
- packages/map_distribution/test/avelune_compatibility_baseline_package_test.dart
- packages/map_core/test/save/avelune_compatibility_baseline_save_test.dart

**Créer, sauf réutilisation justifiée d’un équivalent existant :**

- apps/avelune_studio/test/project_settings/project_settings_work_counts_test.dart

**Étapes d’implémentation :**

- [x] 1. Instrumenter lectures, écritures, décodages et invalidations pour les gestes modifiés, sans dépendre d’un cache chaud. *(Vague 3, carte : lectures, définitions décodées, écritures et rechargement de sélection comptés pour la présence, la caméra et le déplacement de décor — 45d4e09cc. Réglages : lectures, sondes, définitions décodées, fichiers écrits, reconstructions de visuels de carte et notifications comptés pour le gain d'une action, l'inclinaison, la dérogation d'une carte et son retour à l'héritage, la météo, une capacité de terrain et Surf — 87463391d.)*
- [x] 2. Ajouter cartes, assets et historique sans rapport à une fixture ; les comptes de travail d’une propriété locale doivent rester bornés par ses dépendances. *(Vague 3, carte : prouvé par `map_save_work_counts_test.dart` — 45d4e09cc. Réglages : prouvé par `project_settings_work_counts_test.dart` avec 24, 25 et 48 cartes, modèles, médias, dialogues et historiques sans rapport rendus inouvrables — 87463391d.)*
- [ ] 3. Mesurer séparément ouverture, premier geste et gestes suivants sur machine et build documentés. *(Vague 3, carte : mesuré hors écran en JIT et AOT, voir « Mesures consignées — enregistrement d'une carte » ; mesure native UI manquante. Réglages : mesuré en natif (atlas Release) pour le gain et l'inclinaison, premier geste et suivants, voir « Mesures consignées — réglages du projet ».)*
- [ ] 4. Vérifier <=100 ms de retour visible et <=500 ms de durabilité pour les propriétés simples ; un échec de budget reste PARTIAL. *(Vague 3, réglages : retour visible tenu en natif (21 à 78 ms) ; durabilité tenue pour les réglages d'image, de temps et de météo (28 à 49 ms), pas pour le gain d'une action (450 à 731 ms natif) : PARTIAL.)*
- [ ] 5. Rouvrir les données sauvegardées, puis exécuter les fixtures protégées baseline et ultérieures et leurs sauvegardes. *(Vague 3, réglages : gain et inclinaison relus en natif après deux réouvertures, tous les gestes relus à froid dans le test ; fixtures protégées non rejouées par ce passage.)*
- [ ] 6. Vérifier refus d’un futur format ou échec de conversion sans modifier les octets originaux.

**Tests comportementaux obligatoires :**

- Une carte ajoutée sans rapport n’ajoute aucune lecture au changement de gain d’une action.
- Une édition de caméra de carte ne décode pas les médias d’une autre carte.
- Install/load/Continue d’un export protégé conserve la progression et les identités de sauvegarde.

**Tests existants à relancer ou étendre :**

- packages/map_distribution/test/avelune_compatibility_baseline_package_test.dart
- packages/map_core/test/save/avelune_compatibility_baseline_save_test.dart

**Nouvelles cibles proposées :**

- apps/avelune_studio/test/project_settings/project_settings_work_counts_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/packages/map_distribution
dart test test/avelune_compatibility_baseline_package_test.dart
dart analyze

cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/save/avelune_compatibility_baseline_save_test.dart
dart analyze

cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/project_settings/project_settings_work_counts_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Mesures locales opt-in et fixtures QA ; aucun soak ou runner macOS coûteux ajouté à la CI.

**Sortie du lot :** Coût premier/répété et compatibilité sont étayés par mesures et réouvertures, pas par la seule compilation.

**Mesures consignées — rangement des ressources (vague 3, 2026-11-07) :** clone de l'atlas HGSS (catalogue de travail, 2 586 classements, 9 715 modèles, 1 263 bordures), banc opt-in `apps/avelune_studio/test/resource_io/resource_classification_cost_bench_test.dart`, flutter_tester JIT sur Mac M-series ; pas encore de mesure Release native (session macOS verrouillée).

| Geste | Avant (natif, nuit du 7) | Après 6d8e088f7 (JIT) | Écritures après |
|---|---|---|---|
| Ouverture de la boîte « Ranger » | ~3 min | 3 à 6 ms | aucune |
| Premier rangement unitaire | ~12 min pour 2 entrées, 2 823 objets `catalog/` | 655 à 773 ms | 0 à 11 objets, 13 fichiers |
| Rangements suivants | idem | 418 à 520 ms | 0 à 10 objets, 13 fichiers |
| Rangement groupé de 2 | idem | 425 à 534 ms | 0 à 12 objets |
| « Charger les modèles de bordure » (non corrigé) | 1 à 6 min natif | 50 s pour la sélection du catalogue, 55 s avec le contrôleur | aucune |

Décomposition d'un rangement répété (JIT) : lecture ciblée ~77 ms, planification ~200 ms (relecture de la sélection, validation, préparation du patch), écriture transactionnelle ~140 ms ; le premier ajoute ~100 ms d'ouverture du contexte de mutation. Statut : budget de 500 ms durable tenu en JIT pour les gestes répétés, pas pour le premier ; mesure Release native à faire. Vider tous les champs d'un classement ou le réserver à une carte repasse par le chemin global ; créer ou renommer une famille aussi.

**Mesures consignées — enregistrement d'une carte (vague 3, 2026-11-07) :** clone de l'atlas HGSS (catalogue de travail, 102 cartes cataloguées, ~153 000 objets `catalog/`), carte Bourg Geon (`first-map`, 271 Ko, 11 entités, 163 instances 3D). Banc opt-in `apps/avelune_studio/test/map_workspace/map_save_cost_bench_test.dart` (session, contrôleur et adaptateur réels, flutter_tester JIT) et même chemin d'enregistrement map_authoring compilé en AOT (`dart compile exe`) ; Mac Apple Silicon partagé (charge ~7). Pas de mesure native UI : session macOS verrouillée.

| Enregistrement durable | Avant 45d4e09cc (JIT) | Après 45d4e09cc (JIT / AOT) | Après 979b2f49d (JIT / AOT) |
|---|---|---|---|
| Règle de présence, champ de caméra, déplacement de décor — 1er après ouverture | 57 à 65 s, 49 953 lectures | 4,6 s / 2,6 s, 3 360 lectures | 2,2 s / 1,0 s, 1 298 lectures |
| Mêmes gestes, suivants | 51 à 64 s | 3,7 à 4,3 s / 1,6 à 1,9 s | 1,9 à 2,2 s / 0,8 à 1,0 s, 1 288 à 1 298 lectures |
| Ouverture de la carte (non modifiée, mesurée à part) | 26 à 29 s, 23 938 lectures | idem | idem |

Cause (défaut antérieur aux deux nuits, chemin daté du catalogue partitionné d'octobre) : chaque enregistrement relisait toutes les métadonnées du projet (dialogues, scènes, cinématiques, entrées de toutes les cartes) environ sept fois, puis rechargeait le catalogue et la sélection deux fois. Après 45d4e09cc, 7244b14a8 et 979b2f49d : écriture inchangée (document de carte, HEAD, 11 objets catalogue, historique, 25 fichiers), relecture de la seule carte, rechargement de la sélection seulement si les dépendances de catalogue de la carte changent ; la planification de `map.save` lit les scènes, dialogues, faits et tables nommés par la carte au lieu de tout le projet. Validation identique sur les 102 cartes HGSS ; ne sont plus vérifiés à l'enregistrement d'une carte que ses propres références (les personnages d'acteurs de scènes et de cinématiques, et les points de la carte régionale visant une autre carte, relèvent de la validation du projet). Comptes stables : `apps/avelune_studio/test/map_workspace/map_save_work_counts_test.dart` (0, 24 puis 48 cartes, modèles, médias, dialogues et historique sans rapport : aucune autre carte ni média lu, mêmes définitions décodées, seules des pages d'index en plus). Budget de 500 ms non tenu (PARTIAL) : reste la fermeture de dépendances de la carte (~860 lectures, ~0,4 à 0,6 s AOT pour 80 modèles) ; retour visible au geste non mesuré en natif.

**Mesures consignées — réglages du projet (vague 3, 2026-11-07) :** clone de l'atlas HGSS (catalogue de travail, 102 cartes), Mac Apple Silicon partagé (charge 3 à 8). Natif : atlas Release `dev/ui_atlas_main.dart` construit au HEAD 31b86da91 (avant 87463391d), clics et frappe injectés par CGEvent ; durabilité = écriture du fichier final (`project.visual.json` ou `catalog/HEAD.json`) mesurée depuis le clic ; retour visible = premier changement des pixels de la zone éditée. Hors écran : banc opt-in `apps/avelune_studio/test/project_settings/project_settings_cost_bench_test.dart` (JIT) et même chemin map_authoring compilé en AOT.

| Geste | Unités écrites | Comptes (test, 24 à 48 cartes sans rapport) | Natif 1er geste | Natif suivants | Retour visible natif | AOT hors écran | Statut |
|---|---|---|---|---|---|---|---|
| Inclinaison du projet (UX-16) | `project.visual.json` + journal local | 0 lecture par le projet, 3 sondes, 0 définition, 10 à 11 fichiers | 32 ms (50 ms affichés) ; 31 ms après réouverture | 28 à 49 ms | 21 à 46 ms | 32 à 37 ms | tenu |
| Dérogation de carte puis retour à l'héritage (UX-17) | `maps/<id>.visual.json` + journal local | idem, aucune autre carte ni média | non mesuré | non mesuré | non mesuré | 30 à 38 ms | tenu hors écran |
| Heure ou météo (UX-18) | `project.visual.json` + journal local | idem | non mesuré | non mesuré | non mesuré | 31 à 35 ms | tenu hors écran |
| Gain d'une action (UX-20) | `catalog/HEAD.json`, ~11 objets catalogue, journal local | 127 lectures (HEAD ×63, IDENTITY ×21, project.json ×6, 37 objets), 11 définitions (enveloppe de publication), identiques à 24, 25 et 48 cartes | 731 ms ; 450 ms après réouverture | 466 à 564 ms | 55 à 78 ms | 266 à 336 ms | PARTIAL |
| Capacité de terrain, Surf (UX-19) | idem gain | idem gain | non mesuré | non mesuré | non mesuré | 266 à 311 ms | PARTIAL |

Ouverture mesurée à part (JIT) : espace de carte 17,5 s (non modifié), sons 124 ms, capacités 229 ms, image et météo 6 ms. Correctif 87463391d : chaque enregistrement par le catalogue relisait et vérifiait tout `audit.jsonl` (session de mutation neuve à chaque geste, index froid), soit environ 466 ms AOT par enregistrement à 20 000 entrées (12,6 Mo) ; l'audit d'une session à idempotence incrémentale est maintenant écrit entrée par entrée (0 ms à la même taille). Reste au-dessus du budget : les réglages enregistrés par le catalogue relisent cinq à huit fois les mêmes pages d'index et décodent dix fois l'enveloppe de publication (ouverture, rattachement, instantané, plan et contrôles de révision) ; la charge est bornée par la profondeur du catalogue et non par le contenu sans rapport, et ce chemin tourne sur l'isolat de l'interface. Projets non catalogués (`project.json` unique) non mesurés.

**Références visuelles :** [094-reglages-enregistres](2026-11-06-refonte-studio/captures/094-reglages-enregistres.jpg), [033-carte-retour-heritage](2026-11-06-refonte-studio/captures/033-carte-retour-heritage.jpg).


### UX-26 — Revue native finale et transmission pour acceptation

**Priorité :** P0. **Dépendances :** UX-25.

**Modifier ou réutiliser les propriétaires existants :**

- apps/avelune_studio/macos/Runner.xcodeproj/project.pbxproj
- tools/scripts/ensure_studio_qa_engine.py

**Étapes d’implémentation :**

- [ ] 1. Construire Studio en Release avec la qualification de moteur du dépôt ; ne pas contourner le garde-fou GPU ni appeler une fenêtre ouverte une preuve de rendu.
- [ ] 2. Exécuter les parcours de carte, ressources, réglages, scène, test et export sur les fixtures 2D/3D puis le projet représentatif autorisé.
- [ ] 3. Faire une comparaison à échelle apparente comparable avec les références ; vérifier les pixels natifs, les objets et leur édition séparément.
- [ ] 4. Revoir AZERTY, raccourcis, focus, lecteur d’écran, contraste, petite fenêtre, chargements, erreurs, vide et lecture seule.
- [ ] 5. Documenter les écarts de conception pris par Opus, les fonctions préservées et les limites encore ouvertes.
- [ ] 6. Nettoyer processus et environnements du lot, garder seulement les preuves utiles ; mettre les tickets vérifiés TO REVIEW et demander l’acceptation de Yoahn.

**Tests comportementaux obligatoires :**

- Création d’une zone de sol→falaise→décor→interaction→test→retour sans perte de contexte.
- Projet→carte avec override→changement projet→reset→réouverture montre les bonnes valeurs.
- Export protégé et sauvegarde existante chargent dans Player après les modifications pertinentes.

**Tests existants à relancer ou étendre :**

- apps/avelune_studio/test/release/macos_release_gate_test.dart
- apps/avelune_studio/test/presentation/map_workspace_layout_responsive_test.dart

**Commande de vérification ciblée :**

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test test/release/macos_release_gate_test.dart test/presentation/map_workspace_layout_responsive_test.dart
flutter analyze
~~~

Les nouvelles cibles ne sont exécutables qu’après leur création dans ce lot. Résultat attendu pour accepter le lot : tests ciblés passants, analyse sans nouveau diagnostic lié au lot, puis preuves natives indiquées. Les totaux ne sont pas prédits.

**Stockage et coût :** Environnement unique par tâche sous AveluneQA ; projet original et sauvegardes protégées préservés.

**Sortie du lot :** Revue utilisateur obtenue sur l’application native ; les critères non prouvés restent ouverts. Aucune livraison déclarée DONE sans décision explicite de Yoahn.

**Références visuelles :** [001-carte-sol](2026-11-06-refonte-studio/captures/001-carte-sol.jpg), [002-accueil](2026-11-06-refonte-studio/captures/002-accueil.jpg), [077-scene-graphe](2026-11-06-refonte-studio/captures/077-scene-graphe.jpg), [050-resume-export](2026-11-06-refonte-studio/captures/050-resume-export.jpg).

## 7. Matrice des 55 familles — aucun parcours oublié dans le découpage

Une entrée « Parcours décrit » n’est pas déclarée implémentée. Le lot indiqué doit soit adapter l’éditeur natif existant, soit compléter le parcours manquant après examen de sa capacité réelle. La première capture d’aide est 059 ; les suivantes sont g002 à g055.

| Famille de fonctions | Niveau de la maquette | Lots responsables | Capture d’aide |
|---|---|---|---|
| 01 · Créer et organiser les cartes | Parcours décrit | UX-02.1 | [059-guide-mode-emploi](2026-11-06-refonte-studio/captures/059-guide-mode-emploi.jpg) |
| 02 · Sélectionner, déplacer et dupliquer | Parcours simulé | UX-07 | [g002](2026-11-06-refonte-studio/captures/g002.jpg) |
| 03 · Retrouver un objet masqué ou verrouillé | Parcours simulé | UX-06 | [g003](2026-11-06-refonte-studio/captures/g003.jpg) |
| 04 · Comprendre les superpositions | Parcours décrit | UX-06, UX-07 | [g004](2026-11-06-refonte-studio/captures/g004.jpg) |
| 05 · Peindre un sol, un chemin ou de l’eau | Réglages illustratifs | UX-05, UX-09 | [g005](2026-11-06-refonte-studio/captures/g005.jpg) |
| 06 · Créer une falaise | Parcours simulé | UX-09 | [g006](2026-11-06-refonte-studio/captures/g006.jpg) |
| 07 · Modifier une surface et sa pente | Parcours décrit | UX-09 | [g007](2026-11-06-refonte-studio/captures/g007.jpg) |
| 08 · Ajouter un talus franchissable à sens unique | Parcours décrit | UX-23.8 | [g008](2026-11-06-refonte-studio/captures/g008.jpg) |
| 09 · Répartir une forêt ou un environnement | Réglages illustratifs | UX-08, UX-12.4 | [g009](2026-11-06-refonte-studio/captures/g009.jpg) |
| 10 · Éditer le décor extérieur | Réglages illustratifs | UX-08 | [g010](2026-11-06-refonte-studio/captures/g010.jpg) |
| 11 · Peindre et effacer les collisions | Réglages illustratifs | UX-10 | [g011](2026-11-06-refonte-studio/captures/g011.jpg) |
| 12 · Créer une porte ou un escalier entre cartes | Réglages illustratifs | UX-10 | [g012](2026-11-06-refonte-studio/captures/g012.jpg) |
| 13 · Relier deux bords de cartes | Réglages illustratifs | UX-10 | [g013](2026-11-06-refonte-studio/captures/g013.jpg) |
| 14 · Placer le départ du joueur | Réglages illustratifs | UX-10 | [g014](2026-11-06-refonte-studio/captures/g014.jpg) |
| 15 · Placer un personnage et son interaction | Parcours décrit | UX-12.5, UX-23.1 | [g015](2026-11-06-refonte-studio/captures/g015.jpg) |
| 16 · Changer l’apparence selon une condition | Parcours décrit | UX-23.1 | [g016](2026-11-06-refonte-studio/captures/g016.jpg) |
| 17 · Créer un arbre à couper ou un rocher | Parcours décrit | UX-23.8 | [g017](2026-11-06-refonte-studio/captures/g017.jpg) |
| 18 · Configurer une plateforme mobile | Parcours décrit | UX-23.8 | [g018](2026-11-06-refonte-studio/captures/g018.jpg) |
| 19 · Régler la caméra du jeu | Parcours décrit | UX-16, UX-17 | [g019](2026-11-06-refonte-studio/captures/g019.jpg) |
| 20 · Régler météo, lumière et atmosphère | Parcours décrit | UX-18 | [g020](2026-11-06-refonte-studio/captures/g020.jpg) |
| 21 · Régler vélo, donjon et Corde Sortie | Parcours décrit | UX-10 | [g021](2026-11-06-refonte-studio/captures/g021.jpg) |
| 22 · Dessiner une zone de jeu | Parcours décrit | UX-10 | [g022](2026-11-06-refonte-studio/captures/g022.jpg) |
| 23 · Trouver et classer les ressources | Parcours simulé | UX-11 | [g023](2026-11-06-refonte-studio/captures/g023.jpg) |
| 24 · Importer une image, un modèle ou un pack | Parcours simulé | UX-12 | [g024](2026-11-06-refonte-studio/captures/g024.jpg) |
| 25 · Modifier ici ou modifier la ressource partagée | Parcours simulé | UX-07, UX-13 | [g025](2026-11-06-refonte-studio/captures/g025.jpg) |
| 26 · Analyser les usages avant remplacement ou suppression | Parcours simulé | UX-13 | [g026](2026-11-06-refonte-studio/captures/g026.jpg) |
| 27 · Distinguer ressource prête et pièces sources | Parcours simulé | UX-05, UX-11 | [g027](2026-11-06-refonte-studio/captures/g027.jpg) |
| 28 · Préparer et publier un profil de bordure | Parcours simulé | UX-12.3 | [g028](2026-11-06-refonte-studio/captures/g028.jpg) |
| 29 · Préparer les motifs et animations de bordure | Parcours décrit | UX-12.3 | [g029](2026-11-06-refonte-studio/captures/g029.jpg) |
| 30 · Préparer les raccords automatiques d’un terrain | Réglages illustratifs | UX-12.2 | [g030](2026-11-06-refonte-studio/captures/g030.jpg) |
| 31 · Préparer un décor 2D et ses collisions | Parcours décrit | UX-12.1 | [g031](2026-11-06-refonte-studio/captures/g031.jpg) |
| 32 · Régler collision et taille d’un modèle 3D | Réglages illustratifs | UX-12.1 | [g032](2026-11-06-refonte-studio/captures/g032.jpg) |
| 33 · Rendre un escalier franchissable | Parcours décrit | UX-12.1, UX-23.8 | [g033](2026-11-06-refonte-studio/captures/g033.jpg) |
| 34 · Éclairage, ombres et flamme d’un modèle | Réglages illustratifs | UX-12.1 | [g034](2026-11-06-refonte-studio/captures/g034.jpg) |
| 35 · Préparer les images et animations d’un personnage | Parcours décrit | UX-12.5 | [g035](2026-11-06-refonte-studio/captures/g035.jpg) |
| 36 · Diagnostiquer une référence manquante | Parcours simulé | UX-13 | [g036](2026-11-06-refonte-studio/captures/g036.jpg) |
| 37 · Exporter et réutiliser un pack | Réglages illustratifs | UX-12 | [g037](2026-11-06-refonte-studio/captures/g037.jpg) |
| 38 · Assembler une scène en graphe visuel | Parcours simulé | UX-22 | [g038](2026-11-06-refonte-studio/captures/g038.jpg) |
| 39 · Écrire un dialogue avec choix et résultats | Parcours décrit | UX-23.2 | [g039](2026-11-06-refonte-studio/captures/g039.jpg) |
| 40 · Relier un événement à une scène | Parcours décrit | UX-23.2 | [g040](2026-11-06-refonte-studio/captures/g040.jpg) |
| 41 · Déclencher une scène dans une zone d’histoire | Parcours décrit | UX-23.2 | [g041](2026-11-06-refonte-studio/captures/g041.jpg) |
| 42 · Organiser histoires, étapes et progression | Parcours décrit | UX-23.3 | [g042](2026-11-06-refonte-studio/captures/g042.jpg) |
| 43 · Mettre en scène une cinématique sur carte | Parcours décrit | UX-23.4 | [g043](2026-11-06-refonte-studio/captures/g043.jpg) |
| 44 · Créer une présentation animée | Parcours décrit | UX-23.4 | [g044](2026-11-06-refonte-studio/captures/g044.jpg) |
| 45 · Préparer une table de rencontres | Parcours décrit | UX-23.5 | [g045](2026-11-06-refonte-studio/captures/g045.jpg) |
| 46 · Préparer un dresseur et son équipe | Parcours décrit | UX-23.5 | [g046](2026-11-06-refonte-studio/captures/g046.jpg) |
| 47 · Éditer espèces et capacités | Parcours décrit | UX-23.6 | [g047](2026-11-06-refonte-studio/captures/g047.jpg) |
| 48 · Régler les objets et les règles de combat | Parcours décrit | UX-23.6 | [g048](2026-11-06-refonte-studio/captures/g048.jpg) |
| 49 · Créer la carte régionale et les arrivées de Vol | Parcours décrit | UX-23.7 | [g049](2026-11-06-refonte-studio/captures/g049.jpg) |
| 50 · Régler le projet et ses valeurs par défaut | Parcours simulé | UX-14, UX-15, UX-16, UX-17, UX-18, UX-19, UX-20 | [g050](2026-11-06-refonte-studio/captures/g050.jpg) |
| 51 · Tester la carte ou tester le jeu | Réglages illustratifs | UX-21 | [g051](2026-11-06-refonte-studio/captures/g051.jpg) |
| 52 · Exporter le jeu pour Avelune Player | Parcours décrit | UX-21 | [g052](2026-11-06-refonte-studio/captures/g052.jpg) |
| 53 · Annuler et rétablir sans perdre le contexte | Parcours simulé | UX-07, UX-14 | [g053](2026-11-06-refonte-studio/captures/g053.jpg) |
| 54 · Afficher les panneaux utiles à la tâche | Parcours simulé | UX-01 | [g054](2026-11-06-refonte-studio/captures/g054.jpg) |
| 55 · Comprendre un problème et aller à sa source | Parcours simulé | UX-13 | [g055](2026-11-06-refonte-studio/captures/g055.jpg) |

## 8. Traçabilité de l’audit du 3 novembre — aucun constat sans lot

[L’audit ergonomique](../audit_ergonomie_studio_2026-11-03.md) décrit le Studio réel ; la matrice de la section 7 décrit la maquette. Les deux sont nécessaires : une famille couverte par la maquette ne prouve pas qu’un défaut natif est corrigé. Avant d’accepter un lot, vérifier que chacun de ses constats est résolu sur le Studio natif, ou consigner pourquoi il reste ouvert.

« Couvert » : déjà traité par le plan initial. « Complété » : en partie traité, étapes ajoutées. « Ajouté » : rattaché par l’amendement de la section 16. « Avancé » : sorti d’un lot tardif vers UX-03.1. « Livrable en avance » : étape P1 qui peut précéder le reste de son lot.

| Constat | Priorité | Résumé | Lot et étape | Statut |
|---|---|---|---|---|
| G01 | P2 | Accueil : des outils plutôt qu’un prochain objectif | UX-02, ét. 7 | Ajouté, D-03 tranchée ; **corrigé** par 1c91c4f96 (cinq prochaines étapes dérivées des données, « fait » seulement sur preuve, masquables, accès directs conservés) ; étape de départ « Non vérifié » par 60f640327, vérifiée en natif |
| G02 | P1 | « Tester » et « Tester le jeu » trop proches | UX-21, ét. 3 | **En partie corrigé** par UX-21 : la revue avant lancement s’intitule « Tester cette carte » ou « Tester le jeu » et dit ce que garde la session ; le libellé de la barre de la carte relève de la session Carte ; **corrigé** côté Carte : la barre dit « Tester la carte » et la carte d’accueil aussi depuis e00375f66 (UX-02), à côté de « Tester le jeu » ; vérifié en natif |
| G03 | P1 | « Lecture seule » ne dit pas ce qui l’est | UX-02, ét. 6 | Ajouté ; **corrigé** par 1c91c4f96 : « lecture seule » réservé au catalogue publié, avec la raison et le moyen d’éditer |
| G04 | P2 | « Scène à tester » liste des cartes | UX-03.1, ét. 4 ; lexique en UX-03 | Ajouté, avancé ; **corrigé** par d33da791b (« Carte à tester ») ; lexique commun (projet, jeu, carte, carte régionale, scène, événement, présentation, ressource, occurrence) avec exemples dans la palette ⌘K par 48f70a09a |
| C01 | P2 | Conséquences du choix 2D/3D montrées trop tard | UX-02.1, ét. 7 | Ajouté ; **corrigé** par 4c552a318 : le choix du modèle montre carte, personnage, départ, ressources et Pokémon réellement inclus et ce qu’il faut avant un test, sans « prêt à tester » ; vérifié en natif |
| C02 | P2 | Nom et dossier demandés avant l’intention | UX-02.1, ét. 7 | Ajouté ; **corrigé** par 4c552a318 : le nom d’abord, le dossier facultatif avec aperçu du chemin final ; vérifications de destination inchangées ; vérifié en natif |
| C03 | P2 | Planche par défaut sans usage explicite | UX-02.1, ét. 8 | Ajouté ; **corrigé** par 4c552a318 : usage expliqué, planches classées Décor / Personnage d’après les personnages qui les utilisent, champ retiré en 3D où `map.create` le refuse ; vérifié en natif (3D) |
| M01 | P1 | Palette et outil racontent deux intentions | UX-04, UX-05 | Couvert |
| M02 | P1 | Actions essentielles cachées dans « … » | UX-04, ét. 2 et 6 | Complété |
| M03 | P2 | Panneau inférieur sans rapport avec l’outil | UX-05 | Couvert |
| M04 | P1 | Consigne vers un panneau absent | UX-04, ét. 7 | Ajouté |
| M05 | P2 | Noms tronqués, recherches différentes | UX-02.1, ét. 6 | Ajouté, D-01 tranchée ; **corrigé** par 4c552a318 (nom complet et dossier au focus et à la sélection, recherche sans accents sur noms et dossiers) et 60f640327 (colonne 288/320 px) ; vérifié en natif |
| M06 | P2 | Recherche perdue dans un dock étroit | UX-05, ét. 8 | Ajouté ; **corrigé** par 66ea27452 : sous 420 px, la recherche reste derrière une icône nommée « Rechercher une ressource » |
| M07 | P2 | État vide de Bordures aux consignes concurrentes | UX-05, ét. 5 | Couvert ; **corrigé** par d96ab8849 : un seul état à la fois (aucun modèle publié, aucun prêt pour la carte, filtres, ou modèles non chargés en session partielle), une seule action, plus de consigne concurrente dans la palette ; vérifié en natif |
| M08 | P1 | Ambiance et sauvegarde à plusieurs endroits | UX-14, UX-17 | Couvert ; UX-14 : la portée « Cette carte » des réglages édite le même brouillon que l’Ambiance de la carte (plus de second contrôleur sur `maps/<id>.visual.json`), sans sauvegarde implicite ; UX-17 : la caméra et les effets de la carte disent quelles valeurs le projet ou une dérogation remplacent en jeu, et chaque valeur de la portée carte indique « Propre à cette carte » ou « Suit le projet » ; vérifié en natif. L’inspecteur Sélection / Carte puis Image / Temps / Jeu est **livré** par fab0ab2e3 (étape 1), vérifié en natif |
| M09 | P1 | Carte régionale : première carte liée d’office | UX-03.1, ét. 5 | Ajouté, avancé ; **corrigé** par d33da791b (choix explicite avec dossier ; pas d’aperçu) |
| M10 | P2 | Lieux régionaux difficiles à grande échelle | UX-23.7, ét. 6 | Ajouté ; **corrigé** par b6f400d07 (recherche, dossier, résumé, refus expliqué ; attente, absence et erreur de l’aperçu distinguées) |
| N01 | P1 | Histoire : apprendre le modèle avant de raconter | UX-22, ét. 7 | Ajouté, D-02 tranchée ; attend la direction de design Histoire |
| N02 | P1 | Scène d’événement introuvable parmi 426 | UX-23.2, ét. 6 | Ajouté, livrable en avance ; **corrigé** par 3ea3a966b |
| N03 | P1 | Graphe long : vue d’ensemble ou lecture | UX-22, ét. 3 et 8 | Complété ; **corrigé** par 7f3ffdd02 : entrées et sorties d’un bloc listées et suivies pas à pas (sélection et centrage), « Trouver un bloc », ports à 28 × 28 prouvés à tous les zooms ; vérifié en natif sur une scène HGSS de 53 blocs |
| N04 | P1 | Liaisons de blocs au clavier non prouvées | UX-22, ét. 9 | Ajouté ; **corrigé** par 7f3ffdd02 : liaison au clavier (L, Tab, Entrée, Échap) identique au pointeur, annulable en une étape et annoncée au lecteur d’écran (prouvé par test ; frappe injectée non transmise au natif) |
| N05 | P1 | Options d’événement : courant et avancé mêlés | UX-23.2, ét. 7 | Ajouté, livrable en avance ; **corrigé** par 3ea3a966b |
| N06 | P1 | `null` dans le résumé d’événement | UX-03.1, ét. 1 | Ajouté, avancé ; **corrigé** par d33da791b (« Action sans nom ») |
| N07 | P2 | Logique des conditions déduite d’icônes | UX-23.2, ét. 8 | Ajouté ; **corrigé** par 096c10f97 (phrase de résultat, choix « toutes » / « une seule », effet de l’inversion annoncé) |
| N08 | P2 | Deux onglets de cinématique identiques | UX-23.4, ét. 6 | Ajouté ; **corrigé** par 979120f23 (guidage dans Propriétés, Séquence liste les actions ; écart au libellé de l’audit consigné en UX-23.4) |
| N09 | P2 | Diagnostics de cinématique répétés, `null · id` | UX-03.1, ét. 2 ; UX-23.4, ét. 7 | Ajouté, en partie avancé ; `null · id` **corrigé** par d33da791b, diagnostics groupés avec accès à l’action ou à l’acteur **corrigés** par 979120f23 |
| N10 | P2 | Deux noms pour créer la même présentation | UX-03.1, ét. 3 | Ajouté, avancé ; **corrigé** par d33da791b (« Nouvelle présentation » aux deux entrées) |
| N11 | P3 | Vérification absente et récents répétés | UX-22, ét. 10 | Ajouté ; **corrigé** par 262f2efac : une explication et une action avant le premier contrôle, « Reprendre » réservé à une vraie reprise ; vérifié en natif |
| R01 | P1 | Bibliothèque et Identité : même contenu | UX-12.5, ét. 6 | Ajouté ; **corrigé** par ba222f6a5 (UX-12.5 ; onglet Bibliothèque retiré, la liste des personnages reste le panneau permanent) |
| R02 | P1 | Personnage : défaut global et local mêlés | UX-12.5, ét. 2 | Couvert ; **en partie corrigé** par ba222f6a5 (UX-12.5 ; défaut du projet « appliqué immédiatement » et réglage du personnage « enregistré avec Enregistrer » séparés et nommés) ; portée personnage / présence restante |
| R03 | P2 | Portraits : « état » ou « expression » | UX-12.5, ét. 7 | Ajouté ; **corrigé** par ba222f6a5 (UX-12.5 ; « expression » partout ; créer une expression et lui associer une image sont distincts ; portée commune au projet vérifiée par un essai d’écriture) |
| R04 | P2 | Deux bibliothèques de ressources différentes | UX-11, ét. 7 | Ajouté ; **corrigé** par 641ab9706 (UX-11 ; la recherche rapide nomme son contexte, même libellé de recherche, action « Ouvrir les ateliers » ; vérifié en natif sur HGSS) |
| R05 | P1 | Incidents sans action de réparation | UX-13 | Couvert ; **en partie corrigé** par c49df5138 (UX-13 ; nom du propriétaire, références regroupées, cause vérifiée ou non, « Ouvrir la ressource » quand elle existe, détails techniques repliés) ; « choisir un fichier » non proposé faute de parcours |
| R06 | P2 | Poches d’objets en identifiants anglais | UX-03.1, ét. 6 ; UX-23.6, ét. 9 | Ajouté, en partie avancé ; libellés **corrigés** par d33da791b, saisie libre **corrigée** par cd81aa24c |
| R07 | P1 | Formes Pokémon saisies en identifiants à virgules | UX-23.6, ét. 6 | Ajouté, livrable en avance ; **corrigé** par 7529620f2 |
| R08 | P1 | Condition d’évolution prise pour une règle | UX-23.6, ét. 7 | Ajouté, livrable en avance ; **corrigé** par 7529620f2 (validateur d’évolutions : correctif en attente hors de ce lot) |
| R09 | P1 | « Importer » ne dit pas s’il remplace | UX-23.6, ét. 8 | Ajouté, livrable en avance ; **corrigé** par b6c657ed3 |
| R10 | P2 | Média référencé mais peut-être absent | UX-23.6, ét. 8 ; UX-13 | Ajouté ; volet Pokémon **corrigé** par b6c657ed3, volet UX-13 non couvert ici |
| R11 | P3 | Netteté inégale des aperçus pixel art | UX-01, ét. 7 | Ajouté ; **corrigé** pour les vignettes et aperçus Pokémon par 60f640327 (`FilterQuality.none`), vérifié en natif ; recensement fait : cartes, ressources, atlas, dialogues, création de projet et carte régionale (mode pixel) échantillonnent sans lissage ; les illustrations de narration et les médias de présentation, qui ne sont pas forcément du pixel art, restent lissés faute de comparaison (propriétaire : Narration) |
| R12 | P3 | Listes vides sans aide pour démarrer | UX-01, ét. 2 | Couvert |
| R13 | P2 | Combat et attaques : suite du geste ailleurs | UX-23.6, ét. 10 | Ajouté ; **en partie** par 628510049 et cd81aa24c (affectation guidée, usages complétés, synchronisation annoncée) |
| T01 | P1 | Tester enregistre certains brouillons et en bloque d’autres | UX-21, ét. 2 | **Corrigé** par UX-21 : la revue liste les brouillons qui seront enregistrés et ceux qui bloquent, rien n’est enregistré sans confirmation ; vérifié en natif |
| T02 | P1 | Erreur de test sans prochaine action | UX-21, ét. 6 | **Corrigé** par UX-21 (a7b2999df, 3e3638b0d) : un test qui ne démarre pas montre sa famille et son propriétaire quand la cause est typée, nomme une capacité non accordée, et sinon dit que la cause n’est pas déterminée avec son détail, sans réparation inventée ; vérifié en natif |
| T03 | P1 | « Annuler » désigne deux portées | UX-14, ét. 5 | **Corrigé** par UX-14 : « Défaire » / « Rétablir » pour l’historique de la rubrique, « Abandonner les modifications » pour son brouillon ; vérifié en natif |
| T04 | P2 | Champ de vision et distance liés mais séparés | UX-16, ét. 3 | **Corrigé** par UX-16 : la compensation distance/champ de vision est annoncée sur place et revient en une seule annulation ; saisies numériques bornées ; vérifié en natif |
| T05 | P1 | Activer, disposer et débloquer une CS | UX-19 | **Corrigé** par UX-19 : support réel affiché pour les onze capacités, résumé séparant autorisation, connaissance et déblocage ; vérifié en natif |
| T06 | P2 | Deux chemins pour affecter un son | UX-20 | **Corrigé** par UX-20 : la bibliothèque et le sélecteur visent la même action courante, nommée sur chaque son ; toutes les actions listées avec leur intention, enregistrement par association ; vérifié en natif |
| T07 | P1 | Conséquences de l’export peu claires | UX-21, UX-15 | **En partie** : une seule identité réglée dans Général et reprise par l’export (UX-15) ; le reste du résumé d’export est inchangé |

Bilan : sur 48 constats, 15 étaient couverts par le plan initial, 2 en partie, et 31 n’avaient aucun lot. Sur les 24 constats P1, 12 n’avaient aucun lot et 2 l’étaient en partie : ils sont tous rattachés désormais. Trois constats dépendaient d’une décision, tranchée le 6 novembre : G01 (D-03), M05 (D-01) et N01 (D-02). N01 attend encore la direction de design Histoire exigée par D-02.

**Revérification au HEAD d33da791b (UX-00, étape 7, 6 novembre 2026).** Chaque constat a été relu dans le code courant, en lecture seule. Quatre sont corrigés (G04, M09, N06 et N10, tous par UX-03.1) et deux en partie (N09 et R06, reliquats dans leurs lots tardifs). Quarante restent présents. R11 et R12 ne se tranchent pas par le code : R11 est confirmé comme cause probable pour les vignettes Pokémon sans `filterQuality` (`pokemon_species_thumbnail.dart`, `pokemon_media_preview.dart`), à confirmer en natif. Aucun autre commit postérieur à la base de l’audit ne touche ces constats.

## 9. Recettes contractuelles et tests de référence

Ces exemples utilisent les noms réellement présents dans le code relu. Ce sont des recettes pour l’implémentation ; ils n’ont pas été ajoutés aux packages ni exécutés comme tests natifs pendant la préparation de ce dossier.

### Héritage : test minimal réutilisable

À intégrer dans la cible du lot UX-17 ou un test core pertinent, avec les fixtures de réouverture du lot en complément :

~~~dart
import 'package:map_core/map_core_domain.dart';
import 'package:test/test.dart';

void main() {
  test('reset removes the local camera override and follows future defaults', () {
    const parameter = SpatialVisualParameter.cameraDistance;
    final project24 = SpatialVisualPatch().set(parameter, 24.0);
    final local10 = SpatialVisualPatch().set(parameter, 10.0);

    expect(project24.overriddenBy(local10).number(parameter), 10.0);

    final project30 = project24.set(parameter, 30.0);
    expect(project30.overriddenBy(local10).number(parameter), 10.0);

    final inherited = local10.set(parameter, null);
    expect(inherited.toJson().containsKey('cameraDistance'), isFalse);
    expect(project30.overriddenBy(inherited).number(parameter), 30.0);

    final project32 = project30.set(parameter, 32.0);
    expect(project32.overriddenBy(inherited).number(parameter), 32.0);
  });

  test('resetting one field preserves unrelated local settings', () {
    final local = SpatialVisualPatch()
        .set(SpatialVisualParameter.cameraDistance, 10.0)
        .set(SpatialVisualParameter.windowsLit, false);

    final reset = local.set(SpatialVisualParameter.cameraDistance, null);

    expect(reset.number(SpatialVisualParameter.cameraDistance), isNull);
    expect(reset.enabled(SpatialVisualParameter.windowsLit), isFalse);
  });
}
~~~

Le test de modèle n’est pas suffisant : faire le même parcours via le formulaire, le port, l’API canonique et la réouverture du document. Ajouter le cas conflit externe et le cas échec d’écriture conservant le brouillon.

### Profil d’identité : contrat déjà disponible

| Appel existant | Entrées | Résultat à utiliser |
|---|---|---|
| GamePackageExportProfileApiPort.read | projectRoot | profile, profileRevision, contextRevision |
| validate | projectRoot, profile | validation et révisions du contexte contrôlé |
| save | projectRoot, profile, expectedProfileRevision, expectedContextRevision | profil sauvegardé ou refus explicite |
| JSONL | game_export_profile_read / validate / save | mêmes données et refus |
| MCP | pokemap_game_export_profile_read / validate / save | mêmes sémantiques découvertes avant usage |

Ne pas revalider un profil externe puis écraser ses valeurs avec un vieux brouillon en prenant simplement sa nouvelle révision. Comparer au contexte d’édition original et traiter le conflit. La garantie existante annonce un contrôle de préimage avant renommage du profil ; elle n’annonce pas une transaction atomique avec tous les documents du jeu.

### Palette : matrice de décision et refus à prouver

| Intention | Propriétaire admissible | Refus indispensables |
|---|---|---|
| Sol / Chemin / Eau | Preset, pattern, matériau ou Path natif réellement admissible à ce geste | Mauvais rôle, profil incompatible, définition non prête |
| Décor | element / model3d complet selon le profil | Pièce de Border, image source, ressource non résolue |
| Falaise | borderBlueprint et ses pièces possédées | Mauvais profil, coins manquants, définition non publiée |
| Environnement | environmentPreset et sa zone native | Conversion implicite des enfants en objets isolés |
| Personnage | character admissible au profil | Source manquante, apparition invalide, représentation incompatible |
| Collision / hauteur / sélection | Données et outils de la carte | Catalogue arbitraire sans lien avec la tâche |

Créer les fixtures avec les modèles natifs et les tests existants, pas avec les objets Asset de la maquette. La classification ne dépend jamais d’un nom tel que « eau », d’un tag ou d’un dossier libre.

### Annulation et durabilité

Les tests existants de ProjectVisualsController couvrent déjà le port ciblé, une sauvegarde en attente et l’échec conservant le brouillon. Les étendre avec la coordination des rubriques plutôt que les remplacer par un nouveau journal générique.

- Début/fin d’un slider : une annulation, même avec de nombreux échantillons.
- Écriture en attente : dirty reste vrai et aucune confirmation durable n’est affichée.
- Échec : mêmes valeurs, historique conservé, action Réessayer.
- Changement de rubrique : aucun appel save ; le brouillon et son erreur restent attachés à la rubrique.
- Réponse tardive : ne met pas à jour le projet, la carte ou la ressource nouvellement sélectionnés.
- Conflit externe : proposer rechargement/revue ; ne pas effacer le brouillon ni forcer une révision.

### Unités de stockage et dépendances à vérifier par lot

| Geste | Unité propriétaire attendue | Dépendances légitimes | Travail exclu |
|---|---|---|---|
| Navigation, sélection, recherche locale | État de présentation | Descripteurs ou index déjà nécessaires | Parcours de toutes les cartes et décodage des médias |
| Déplacement / rotation / retrait | Unités natives de la carte active | Ordre, collision ou rendu réellement affectés | Réécriture du catalogue global |
| Sol / pente / Border | Surface, stroke, contour et unités natives liées | Coins, raccords et objets ancrés concernés | Reconstruction du monde ou de toutes les bordures |
| Visuels du projet | project.visual.json | Résolution des valeurs de l’aperçu ciblé | Lecture de toutes les cartes avant publication |
| Visuels locaux | maps/<mapId>.visual.json et caméra possédée par la carte | Défauts projet et rendu de la carte | Réécriture des autres cartes |
| Général | .pokemap/export-profile-v1.json | Préimage/contexte du profil existant | Export implicite ou rebuild complet |
| CS / Surf | Paramètres canoniques projet/catalogue déjà possédés par leurs actions | Références de condition effectivement utilisées | Réécriture de progression des joueurs |
| Association sonore | Configuration audio et cue ciblée | Média référencé, si nécessaire | Réimport de bibliothèque ou export de jeu |
| Import / pack / analyse d’usages | Transaction explicite du service | Dépendances déclarées du travail demandé | Exécution cachée depuis une sélection ou un simple champ |

Si un propriétaire actuel réalise un travail global sur un chemin touché, le corriger dans sa frontière étroite et instrumenter sa preuve. Ne pas placer un cache ou un worker devant ce défaut pour le déclarer acceptable.

## 10. Inventaire visuel natif à préserver

Le modèle contient **61 paramètres visuels**, bien davantage que les champs exposés dans l’exemple React. Les supprimer ou restreindre leurs plages pour correspondre à la maquette serait une régression. Les organiser en sections progressives ; conserver les valeurs non éditées.

Les bornes ci-dessous viennent de SpatialVisualParameter au relevé. Les règles croisées de brume, de durées et de poids restent applicables ; reconsulter le normaliseur au moment de l’implémentation.

| Paramètre canonique | Type | Bornes ou choix |
|---|---|---|
| pitchDegrees | nombre fini | 1, 89 |
| yawDegrees | nombre fini | -360, 360 |
| fieldOfViewDegrees | nombre fini | 1.01, 119.99 |
| cameraDistance | nombre fini | .01, 10000 |
| lockVerticalFraming | booléen | valeurs du contrat, pas un texte libre |
| dayNightEnabled | booléen | valeurs du contrat, pas un texte libre |
| dayDurationSeconds | nombre fini | 10, 86400 |
| minuteOfDay | nombre fini | 0, 1439 |
| depthOfFieldEnabled | booléen | valeurs du contrat, pas un texte libre |
| depthOfFieldStrength | nombre fini | 0, 1 |
| depthOfFieldFocusRange | nombre fini | 2, 40 |
| halosEnabled | booléen | valeurs du contrat, pas un texte libre |
| haloStrength | nombre fini | 0, 2 |
| haloSpread | nombre fini | .1, 3 |
| depthFogEnabled | booléen | valeurs du contrat, pas un texte libre |
| fogOpacity | nombre fini | 0, .5 |
| fogStart | nombre fini | 0, 99999.99 |
| fogEnd | nombre fini | .01, 100000 |
| waterAnimated | booléen | valeurs du contrat, pas un texte libre |
| waterStrength | nombre fini | 0, 2 |
| waterSpeed | nombre fini | 0, 3 |
| windowsLit | booléen | valeurs du contrat, pas un texte libre |
| windowStrength | nombre fini | 0, 2 |
| fireflies | booléen | valeurs du contrat, pas un texte libre |
| fireflyDensity | nombre fini | 0, 2 |
| fireflyLighting | booléen | valeurs du contrat, pas un texte libre |
| fireflyYellowAmount | nombre fini | 0, 1 |
| fireflyGreenAmount | nombre fini | 0, 1 |
| fireflyBlueAmount | nombre fini | 0, 1 |
| fireflyPinkAmount | nombre fini | 0, 1 |
| fireflyLightStrength | nombre fini | 0, 1 |
| fireflyLightRadius | nombre fini | .25, 2.5 |
| weatherEnabled | booléen | valeurs du contrat, pas un texte libre |
| weatherKind | choix canonique | valeurs du contrat, pas un texte libre |
| weatherIntensity | nombre fini | 0, 1 |
| weatherDensity | nombre fini | 0, 1 |
| weatherSpeed | nombre fini | .1, 3 |
| weatherWindStrength | nombre fini | 0, 2 |
| weatherWindDirection | nombre fini | -180, 180 |
| weatherParticleSize | nombre fini | .25, 2 |
| weatherOpacity | nombre fini | 0, 1 |
| weatherCloudCover | nombre fini | 0, 1 |
| weatherFogStrength | nombre fini | 0, 1 |
| weatherTransitionSeconds | nombre fini | 0, 5 |
| weatherLightning | booléen | valeurs du contrat, pas un texte libre |
| weatherIndoors | booléen | valeurs du contrat, pas un texte libre |
| weatherSoundEnabled | booléen | valeurs du contrat, pas un texte libre |
| weatherRainVolume | nombre fini | 0, 1 |
| weatherWindVolume | nombre fini | 0, 1 |
| timeMode | choix canonique | valeurs du contrat, pas un texte libre |
| weatherMode | choix canonique | valeurs du contrat, pas un texte libre |
| weatherIntervalSeconds | nombre fini | 10, 86400 |
| weatherSequence | liste de météos | 1 à 20 entrées canoniques |
| weatherDryMinSeconds | nombre fini | 10, 86400 |
| weatherDryMaxSeconds | nombre fini | 10, 86400 |
| weatherEventMinSeconds | nombre fini | 10, 3600 |
| weatherEventMaxSeconds | nombre fini | 10, 3600 |
| weatherDrizzleWeight | nombre fini | 0, 100 |
| weatherRainWeight | nombre fini | 0, 100 |
| weatherDownpourWeight | nombre fini | 0, 100 |
| weatherStormWeight | nombre fini | 0, 100 |

Points particulièrement sensibles :

- La distance de caméra native accepte .01..10000, le FOV 1.01..119.99 et les angles ont leurs bornes natives. Les limites 3..150, 8..60 ou ±180 de la maquette sont des contraintes d’exemple, pas un nouveau contrat produit.
- Changer le FOV dans SpatialVisualControls compense déjà la distance par le rapport des tangentes pour maintenir le cadrage. Préserver cette relation ou la modifier explicitement avec un test et une explication.
- Les durées natives sont en secondes et l’heure en minuteOfDay. Une présentation en minutes/heures doit convertir et recharger sans arrondi destructif.
- La météo inclut les intensités, densités, vents, particules, nuages, brume, sons et poids d’épisodes ; les trois noms de météo de la maquette ne sont pas le catalogue natif.
- Des capacités de rendu peuvent dépendre du profil ou du runtime. L’interface présente leur état réel au lieu de les supprimer.
- L’héritage absent, une valeur false, une valeur 0 valide et une valeur par défaut explicite doivent rester distingués.

## 11. Vérifications de vague et commandes d’intégration

Les commandes sont à lancer dans le package indiqué après les modifications concernées. Ce plan n’annonce aucun résultat natif anticipé.

### Studio et design system

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test
flutter analyze
~~~

Une suite complète est pertinente après une vague touchant shell, navigation et contrôleurs partagés ; pendant un lot étroit, commencer par ses cibles. Relever le runner et ses descendants, puis reaper uniquement les processus confirmés appartenir à ce run, conformément à AGENTS.md.

~~~bash
cd /Users/karim/Project/pokemonProject/packages/avelune_design_system
flutter test
flutter analyze
~~~

Ces contrôles du design system sont requis si ses widgets ou tokens ont changé.

### Contrats et transports

~~~bash
cd /Users/karim/Project/pokemonProject/packages/map_authoring
dart test test/parity/full_authoring_parity_test.dart
dart run tool/pmcp085_conformance.dart
dart analyze

cd /Users/karim/Project/pokemonProject/tools/pokemap_mcp
npm run check
npm test
~~~

Les scénarios directs, JSONL, UI et MCP du delta restent nécessaires. Reconstruire et recharger le serveur selon la configuration de la session, puis vérifier le catalogue vivant avec pokemap_describe. Un binaire construit ou un test isolé ne prouve pas l’activation du serveur.

### Compatibilité et parcours joueur, lorsque touchés

~~~bash
cd /Users/karim/Project/pokemonProject/packages/map_distribution
dart test test/avelune_compatibility_baseline_package_test.dart test/game_package_compatibility_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/save/avelune_compatibility_baseline_save_test.dart test/save/save_compatibility_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test test/phase_a_golden_battle_slice_smoke_test.dart

cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart
~~~

Compléter par install/load/Continue sur les exports protégés et leurs sauvegardes. Une fixture actuelle seule ne certifie pas tous les jeux historiques.

### Build natif

~~~bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter build macos --release
~~~

C’est le mode natif de qualification connu du dépôt. Le hook Xcode appelle ensure_studio_qa_engine.py ; ne pas le désactiver et ne pas substituer une compilation Debug non qualifiée. Avant le build, préparer le workflow QA autorisé sous AveluneQA, relever ses sorties et la condition de retrait. Si l’outil impose une sortie temporaire différente, documenter cette exception étroite et ne nettoyer que les sorties possédées par ce run. Ne pas modifier globalement la configuration Flutter pour déplacer les builds d’autres sessions.

## 12. Grille de sortie et fiche de livraison de chaque lot

Pour chaque lot, fournir dans le ticket existant et la preuve technique :

- Périmètre et critères acceptés ; ID du lot de ce plan ; dépendances satisfaites.
- HEAD initial, fichiers déjà modifiés et fichiers réellement touchés.
- Propriétaires et unités de stockage, API utilisées et parité applicable.
- Scénario avant/après avec données et profils exacts.
- Tests lancés, résultats exacts et diagnostics préexistants distincts.
- Mesures premier/répété et comptes de travail lorsque la mutation est touchée.
- Preuve de réouverture/persistance et capture du résultat natif.
- Écarts de conception pris par Opus et justification.
- Limites, récupération, statut de compatibilité et prochain lot conseillé.
- Nettoyage des processus, caches et environnements possédés.
- Statut TO REVIEW après vérification ; DONE seulement après accord de Yoahn.

Critère général : pas de bouton « fonctionnel » dont l’effet réel ou le coût reste inconnu. Pas de faux retour de sauvegarde, de validation ou de compatibilité. Ne pas prétendre couvrir un système entier à partir d’un petit exemple.

## 13. Preuves de préparation de ce dossier

### Périmètre réellement réalisé

Préparation d’un plan et de références visuelles, sans implémentation native de la refonte. La révision MagicPath principale n’a pas été modifiée. Les interactions de capture ont changé uniquement les données en mémoire des prototypes ; la session principale a ensuite été rechargée et restituée sur Carte / Sol.

### Passes séparées de revue

| Passe | Verdict | Preuve et limites |
|---|---|---|
| Audit / architecture | Contrats existants et limites identifiés | Propriétaires natifs, tests, stockage et transports relus ; pas d’exécution des mutations HGSS |
| Planification | 40 lots actionnables | Dépendances, fichiers, étapes, cas négatifs, commandes et critères ; liberté d’Opus explicite |
| Captures / vérifications | 217 images capturées | Fenêtre complète 1280×720 ; 217 IDs et empreintes JPEG distincts ; parcours actuels, 55 fiches, ateliers et références historiques |
| Build / validation | Vérification documentaire et visuelle | Aucune compilation Flutter requise pour un plan ; les anciens builds MagicPath ne certifient pas Studio |
| Critique finale | Plan complet au niveau de transmission, acceptation native ouverte | Couverture des 55 familles reliée aux lots ; les illustrations et références anciennes restent qualifiées |

Ce sont des passes de revue successives, pas des avis indépendants de cinq agents. Aucun sub-agent n’a été lancé pour ce dossier.

### Fichiers produits et modifications

- documentation/reports/avelune_studio/plans/2026-11-06-refonte-studio.md : plan canonique, présent document.
- documentation/reports/avelune_studio/plans/2026-11-06-refonte-studio/index.html : lecture du plan, navigation des lots, galerie et liens MagicPath.
- documentation/reports/avelune_studio/plans/2026-11-06-refonte-studio/capture-manifest.json : inventaire exact des 217 captures, URLs, lots et empreintes.
- documentation/reports/avelune_studio/plans/2026-11-06-refonte-studio/captures/*.svg : 217 fichiers, noms exacts énumérés dans le manifeste.
- .gitignore : quatre lignes strictement limitées à ce plan et à son dossier ; la modification préexistante du fichier est conservée.
- Aucun fichier applicatif, projet HGSS, sauvegarde, moteur ou configuration CI modifié.

### Relevé Git initial et nettoyage

Branche main, HEAD initial 33b45abf053488da2297b8e18c8b23207dc6dd11. Deux chemins déjà modifiés au départ : .gitignore et documentation/reports/battle/plans/2026-11-06-import-groupe-animations-bw2.md. Ne pas attribuer ces changements préexistants à ce plan.

La collecte a utilisé un serveur mémoire local 127.0.0.1:60260 pour transférer les captures produites par le navigateur ; il a été fermé après la collecte. Aucun projet QA, export de jeu ou copie complète du workspace n’a été créé. Deux fichiers de bytecode Python apparus pendant l’inspection de l’outil de qualification ont été retirés après vérification des consommateurs et de leurs sources ; les autres caches n’ont pas été nettoyés.

### Limites et auto-critique

- Le projet natif évolue : le plan doit être réconcilié avec les nouveaux commits au début de chaque lot.
- Les tests et chemins existants ont été vérifiés sur disque ; les nouvelles cibles sont des propositions à créer, pas des tests déjà passants.
- Aucune mesure de performance native, compilation Flutter ou certification Player n’a été réalisée pour ce plan.
- La maquette ne couvre pas l’éditeur complet de toutes les familles ; les lots UX-23 complètent ces parcours avec leurs propriétaires natifs.
- Les captures historiques sont conservées pour l’intention ; elles ne remplacent ni le dernier shell ni les contrats de données actuels.
- Les 217 images couvrent les états significatifs observés ; elles ne constituent pas la preuve de toutes les combinaisons, tailles de fenêtre et situations d’erreur possibles.
- L’ergonomie doit être éprouvée avec Yoahn sur la première tranche utilisable. Éviter d’attendre la fin des 40 lots pour recevoir un retour.

## 14. Ordre conseillé à Opus pour commencer

Commencer par UX-00. Les décisions D-01 à D-04 sont tranchées (section 5). Lancer tôt, dans MagicPath et en parallèle de la vague A, la direction de design Histoire exigée par D-02 : elle doit être validée avant UX-22. UX-03.1 peut suivre aussitôt, en parallèle des fondations : ses correctifs ne dépendent pas du nouveau shell et donnent un premier résultat visible. Enchaîner UX-01, UX-02, UX-04 et UX-05, puis UX-06/UX-07. Cette tranche permet de juger la navigation, le contenu, le geste et les ressources dans un vrai parcours de carte ; la placer devant Yoahn sur le Studio natif avant de continuer.

Les étapes P1 de l’audit placées dans UX-23.2 (N02, N05) et UX-23.6 (R07, R08, R09) peuvent être livrées en avance sur les écrans actuels, sans attendre le reste de leur lot.

Ensuite réaliser UX-14, UX-15, UX-16 et UX-17 : c’est la tranche prioritaire pour les réglages du projet et leur relation avec les cartes.

Les ateliers, l’audio, la météo et les parcours spécialisés suivent leurs dépendances. Il est possible d’ajuster ce séquencement si l’audit prouve qu’un propriétaire existant permet un lot plus petit et plus sûr. Conserver les mécanismes de coût, de compatibilité et de parité comme critères permanents.

**Consigne finale pour Opus : préserver l’intention et les capacités, améliorer le détail quand c’est nécessaire, et toujours montrer la preuve du résultat natif.**

## 15. Reçu final de préparation et vérifications

### Intégrité du dossier

- 40 lots, 55 familles rattachées et 61 paramètres visuels natifs recensés.
- 234 chemins sources/tests existants vérifiés ; aucune référence manquante et aucune dérive de leur SHA-256 lors de la vérification finale. Le manifeste conserve cette base technique, sans recopier les sources.
- 38 cibles de nouveaux fichiers proposées ; aucune collision avec un fichier existant au relevé.
- Graphe des dépendances sans cycle ; aucune dépendance ni capture référencée manquante.
- 217 fichiers SVG valides contenant 217 JPEG intégraux de 1280×720 ; 217 identifiants uniques, 217 empreintes JPEG distinctes, aucune empreinte incorrecte.
- Galerie autonome : 217 cartes, images incorporées, recherche insensible aux accents, filtre, état vide et ouverture au clavier vérifiés. JavaScript valide ; lecture des images, recherche « heritage » et ouverture de la capture 033 vérifiées dans le navigateur. Aucun débordement horizontal de la page à 1422 pixels, y compris avec le plan déplié.
- Cinq références MagicPath identifiées avec leurs composants et révisions. Aucun changement distant du code des maquettes réalisé pour ce dossier.

Les contrôles d’intégrité sont des vérifications de préparation et de documentation. Aucun test Flutter, build natif, test de sauvegarde HGSS ni benchmark du moteur n’a été lancé ; leurs commandes et critères figurent dans les lots pour l’implémentation.

### Contrôle Markdown partagé

Commande exécutée : `env POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh`.

Résultat : **code de sortie 1**, trois diagnostics :

```text
Ignored Markdown is not allowed outside tool-owned generated directories: documentation/reports/avelune_player/plans/2026-10-31-avelune-ios-install-library-launch-perf.md
Ignored Markdown is not allowed outside tool-owned generated directories: documentation/reports/heartgold/audit-cartes-johto-2026-10-31.md
Markdown hygiene: 4 new Markdown files exceed the default limit of 1.
```

Le contrôle compte ce plan, le plan battle préexistant et les deux Markdown ignorés hors périmètre. Ce dossier crée un seul Markdown, sous le plafond de 262144 octets. Le budget n’a pas été augmenté pour masquer les travaux voisins et aucun rapport hors périmètre n’a été modifié.

### Git et ressources temporaires

- Branche : main. HEAD initial : 33b45abf053488da2297b8e18c8b23207dc6dd11. HEAD au contrôle final : 84c7c73a465ca598fc00037dd443dba3e8f375d4 ; l’avancement vient de commits concurrents. Aucune commande Git d’écriture exécutée pour cette tâche.
- État final : 222 chemins signalés, soit les 220 nouveaux fichiers du livrable, .gitignore modifié et le plan battle préexistant non suivi. Les 220 fichiers sont ce Markdown, index.html, capture-manifest.json et les 217 captures ; aucun fichier applicatif modifié par cette tâche.
- .gitignore : quatre lignes ajoutées pour exposer uniquement ce plan et son dossier. La ligne battle préexistante est conservée.
- Les serveurs mémoire possédés sur 127.0.0.1:60260 et 127.0.0.1:64674 sont fermés ; `lsof -nP -iTCP:60260 -iTCP:64674 -sTCP:LISTEN` ne retourne aucun écouteur, code 1 attendu.
- Onglet local de revue fermé. Onglet du prototype conservé sur Carte / Sol. Aucun override temporaire de viewport.
- Les deux bytecodes Python temporaires créés lors de l’inspection ont été supprimés après vérification de leur propriété ; sources conservées. Aucun environnement QA, copie de projet, export, build, serveur ni processus de test temporaire conservé. Seuls les livrables demandés sont retenus.

Verdict de transmission : **dossier prêt pour revue et implémentation lot par lot ; acceptation native ouverte**. Le ticket existant AS-UX-001 reste DOING tant que les critères du produit complet ne sont pas atteints.

## 16. Amendement du 6 novembre 2026 — couverture de l’audit natif

Revue de couverture demandée par Yoahn après la préparation initiale. Elle a comparé le plan au code au HEAD 84c7c73a465ca598fc00037dd443dba3e8f375d4, à l’audit du 3 novembre et aux 74 captures natives de l’Atlas UI. Les sections 13 et 15 restent le reçu de la préparation initiale (40 lots) ; elles ne sont pas recertifiées par cet amendement.

**Constats de la revue :**

- Le plan ne citait pas l’audit du 3 novembre : 31 de ses 48 constats n’avaient aucun lot, dont 12 P1.
- La maquette couvre en profondeur la carte, les ressources et les réglages (195 captures sur 217), mais n’a pas de direction pour Histoire et Pokémon.
- Le sélecteur de carte maquetté a été conçu pour deux cartes, alors que HGSS en compte 102.
- Les comptes 102/426/593 étaient présentés comme des exemples de maquette ; ce sont les vrais comptes HGSS du Studio natif.

**Modifications :**

- Section 2 : audit et captures natives ajoutés comme état de départ ; le lien MagicPath propre à Codex est signalé.
- Section 3 : trois limites de la maquette ajoutées (échelle des cartes, Histoire et Pokémon, accueil).
- Section 5 : UX-03.1 ajouté à la vague A et au graphe ; décisions produit D-01 à D-04.
- Section 6 : nouveau lot UX-03.1 (six défauts revérifiés dans le code), soit 41 lots ; étapes et tests ajoutés à UX-00, UX-01, UX-02, UX-02.1, UX-04, UX-05, UX-11, UX-12.5, UX-22, UX-23.2, UX-23.4, UX-23.6 et UX-23.7 ; UX-24 dépend aussi de UX-03.1.
- Section 8 : table de traçabilité des 48 constats ; les sections suivantes sont renumérotées.
- Section 14 : ordre de démarrage mis à jour.

**Non modifié par la revue de couverture :** le `lotCount` du manifeste, qui décrit toujours le dossier initial (UX-03.1 n’a pas de capture de maquette), le contenu des captures, et la copie du plan incluse dans la galerie, qui précède cet amendement et le signale en tête. Aucun fichier applicatif modifié, aucune opération Git d’écriture.

**Limites :** la table de traçabilité s’appuie sur les intitulés, preuves et propositions de l’audit, et sur une vérification ciblée du code pour les six défauts de UX-03.1. Les autres constats n’ont pas été reproduits dans un Studio en cours d’exécution ; UX-00, étape 7, les revérifie au HEAD courant.

**Décisions du 6 novembre 2026 :** Yoahn a retenu les recommandations de la revue : D-01 option a) (onglets Cartes et Contenu de la carte), D-02 option a) pour Histoire et b) pour Pokémon, D-03 option b) (accueil orienté prochain objectif). Pour D-04, la revue proposait deux options ; Yoahn a retenu l’option b). Les lots UX-00, UX-02, UX-02.1, UX-06, UX-22 et UX-23.6, la section 8 et la section 14 tiennent compte de ces décisions.

**Application de D-04 :** les 217 enveloppes SVG sont remplacées par les JPEG bruts qu’elles contenaient, chacun vérifié contre son `sha256Jpeg`. Les 234 liens de ce plan et les 451 liens de la galerie pointent vers ces fichiers, et la galerie référence les images au lieu de les incorporer en base64. Le dossier passe d’environ 42 Mo à 16 Mo. Le manifeste décrit la nouvelle disposition dans son champ `amendments` ; ses champs de vérification `svgXml`, `galleryBrowserReview` et `canonicalPlanSha256` décrivent la préparation initiale. Les mentions de SVG dans les sections 13 et 15 décrivent elles aussi l’état initial.
