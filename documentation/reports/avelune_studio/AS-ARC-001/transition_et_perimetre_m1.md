# Transition proposée et première carte utilisable

## Emplacement et coexistence

**Proposition : `apps/avelune_studio`**, dans le dépôt existant, avec son propre `lib/main.dart`, sa composition et son packaging. Aucun dossier applicatif n’est créé par cet audit.

Le dépôt utilise déjà `apps/pokemap_hub` pour une application assemblant des packages métier : `apps/pokemap_hub/lib/main.dart:1-9` initialise Flutter et Riverpod, puis `lib/app/app_root.dart:15-35` consomme une composition. `packages/map_editor/pubspec.yaml:1-5,11-44` décrit au contraire l’application historique avec ses dépendances très larges. Ranger la nouvelle application sous `apps/` rend son rôle explicite sans renommer les packages de moteurs.

Une alternative sous `packages/avelune_studio` n’apporte ici aucun avantage vérifié : il s’agit d’une application, pas d’une bibliothèque destinée à plusieurs hôtes. Ne pas créer simultanément une application et une forêt de nouveaux packages. Extraire un package seulement lorsqu’une responsabilité doit effectivement être partagée.

L’ancien `packages/map_editor/lib/main.dart` reste utilisable séparément. Ne pas monter son `EditorNotifier` dans la nouvelle application, ni importer `package:map_editor/src/...`. Le retour à l’ancien outil se fait par une session distincte : ne pas laisser deux autorités modifier le même document sans protocole de conflit. Les projets réellement utilisés ne servent pas de fixtures de migration.

## Architecture minimale à rendre concrète dans le lot suivant

La règle de dépendance est **présentation → application → domaine**, avec infrastructure implémentant les ports intérieurs et composition au point d’entrée. Elle n’impose pas quatre classes qui relaient chaque appel.

| Responsabilité | Autorité proposée | Réutilisation / frontière |
|---|---|---|
| Document auteur et révision | Session de travail, une autorité d’écriture par document | Réutiliser `MapData`, `ProjectManifest`, identités et données métier de `map_core`. Pas de second modèle JSON concurrent. |
| Session projet | Application : projet actif, génération, documents ouverts, état sale et conflits | Adapter les garanties de `ProjectSessionController`, sans Riverpod ni filesystem concret dans le port. |
| Commande de modification | Application, préconditions locales et delta sur révision identifiée | Regrouper un geste ; publier éléments/cartes touchés ; rendre ordre/déplacement/annulation testables hors widgets. |
| Historique local | Application, attaché à la session documentaire | Une seule histoire utilisateur ; ne pas additionner naïvement snapshots editor et journal disque authoring. |
| Sauvegarde et lecture externe | Infrastructure via API/ports publics ciblés | `map_authoring_api.dart` pour les contrats ; `map_authoring_local.dart` au point de composition local. L’import API n’est pas transitivement exempt d’I/O aujourd’hui. |
| État de vue | Présentation | Sélection, caméra, zoom, outils et navigation dans la pile ne rendent pas le document dirty. Une commande modifiant l’ordre visuel modifie en revanche le document et son historique. Riverpod peut rester ici. |
| Ressources graphiques | Adaptateur de rendu, cycle de vie lié à la session | Images, octets, miniatures, chunks et annulations ; budget par octets et références vivantes. Aucun cache propriétaire du travail non sauvegardé. |
| Raccordement Player | Adaptateur infrastructure/runtime | Utiliser les contrats publics du runtime ; garder Flutter/Flame hors commandes métier. |

Les dossiers `project_session`, `map_workspace`, `visual_order`, `resources` et `playtest` ne sont créés que lorsqu’ils accueillent un comportement réel. Narration et distribution arrivent avec leurs parcours. Les noms de futurs ports ne constituent pas des APIs déjà disponibles.

### Réutilisation des composants UI

Le design system historique est sous `packages/map_editor/lib/src/ui/design_system/design_system.dart:5-53` ; les tokens sous `src/theme/pokemap_color_tokens.dart:1-40`. Ce barrel interne comprend aussi des primitives narratives/cinématiques ; il ne constitue pas une bibliothèque publique indépendante.

`PokeMapButton` dépend de Flutter et du thème, `src/ui/design_system/pokemap_button.dart:1-2,51-66`. Cela rend une extraction ciblée plausible, pas gratuite pour tout le dossier. La composition M1 doit décider une exposition/extraction bornée des primitives et tokens nécessaires, sans importer globalement l’ancien éditeur ni copier sa présentation. `map_player_ui` est destiné au Player et dépend aussi du runtime (`packages/map_player_ui/pubspec.yaml:10-22`) : ce n’est pas automatiquement le design system de Studio.

### Taille des fichiers : état observé, aucune refonte effectuée

Comptage des fichiers Dart sous `lib/`, en excluant `*.g.dart` et `*.freezed.dart`, au SHA audité. Les lignes sont comptées par retours à la ligne. Cette convention n’identifie pas tous les éventuels autres fichiers générés ; il s’agit d’un inventaire, pas d’un jugement de complexité.

| Périmètre | Fichiers | ≤300 | 301–400 | >400 |
|---|---:|---:|---:|---:|
| `packages/map_editor` | 943 | 567 | 111 | 265 |
| `packages/map_authoring` | 184 | 100 | 21 | 63 |
| `apps/pokemap_hub` | 172 | 154 | 2 | 16 |

Exemples à ne pas transplanter : `editor_notifier.dart`, 15 840 lignes ; `cinematic_builder_workspace.dart`, 14 516 ; `project_query_service.dart`, 2 341. Ce comptage ne prouve aucune lenteur. La charte ≤300, revue jusqu’à 400 et exception nominative au-delà est une proposition pour la nouvelle production manuelle, à ratifier ; aucun découpage du code existant n’a été entrepris. Les `part` partageant le même état massif ne résoudraient pas la séparation des responsabilités.

## M0 et livraisons cohérentes nécessaires à M1

**Prochain lot recommandé : AS-ARC-002**, référencé par la charte d’architecture. Son contenu exact devra être confronté à sa fiche avant exécution ; cette fiche n’a pas été consultée ici. Proposition de périmètre : choisir l’emplacement, l’autorité documentaire, la frontière commandes locales/persistance, l’historique et les interfaces de rendu. Entrées : cet audit et les contrats Notion lus. Sortie : dépendances testables et contrats précis suffisants pour la première tranche verticale, pas des écrans vides.

AS-UX-001 doit arbitrer les interactions sans calques ; AS-PERF-001 doit qualifier fixtures, machines et budgets. Le présent lot prépare leurs questions et points de mesure, sans les exécuter. La préparation 3D doit rester une décision séparée et bornée.

Les lignes suivantes sont des **livraisons proposées**, pas des nouveaux tickets créés dans Notion :

| Livraison | Dépendances | Résultat cohérent et preuve de sortie |
|---|---|---|
| Socle et carte ouverte | Contrats de session/ports, accès projet, design system minimal | Ouvrir un projet, afficher une vraie carte et ses ressources ; fermer/réouvrir un panneau sans réouvrir le projet ; refuser une commande sur une carte en chargement. Tests de frontière et de non-rechargement. |
| Décor manipulable et historique | Socle, choix des décors M1, contrat de changement | Palette intégrée, placer, sélectionner, déplacer, annuler/refaire ; un geste = opération compréhensible. Tests de ciblage projet/carte/révision et annulation en changement de session. |
| Empilement cohérent | Contrat partagé core/authoring/runtime + arbitrages UX | Devant/derrière, pile des recouvrements, sélection d’un élément masqué ; ordre identique dans canvas et Player ; position, collision et interaction inchangées. API, JSONL, editor et MCP à prouver. |
| Sauvegarde, reprise et test | Historique, projection runtime, empilement stable | Sauvegarder/rouvrir sans perdre ordre ni autres propriétés ; rendre visible un conflit ou échec disque ; tester dans le runtime existant puis retrouver contexte et travail auteur. |

L’empilement est un contrat transversal à commencer avant le geste final, pas une décoration ajoutée après le socle. La tranche M1 doit inclure des ressources déjà préparées ; imports complexes et création de ressources appartiennent à M2. Le type exact de décor M1 doit être arrêté : une maison composée de tuiles brutes ne devient pas automatiquement un élément sélectionnable unique.

## Recette M1 proposée

Sur une fixture dédiée et révisionnée, avec au moins deux décors se recouvrant et un personnage :

1. Ouvrir le projet, choisir une carte et vérifier son identité ; l’édition reste désactivée tant que ses données ne sont pas prêtes.
2. Choisir un décor dans la palette intégrée, le placer et le déplacer sans créer ou sélectionner un calque manuellement.
3. Passer devant/derrière ; sélectionner depuis la pile le décor recouvert. Distinguer pile de sélection et profondeur du pinceau.
4. Vérifier extrémités, égalités et suppression ; aucune modification de coordonnées, collision ou comportement d’interaction.
5. Annuler/refaire placement, déplacement et ordre. Annuler un geste en cours à la fermeture/changement de carte.
6. Sauvegarder, fermer et rouvrir ; comparer ordre, identité, position, références et collisions. Simuler conflit et échec d’écriture sans perdre le document en mémoire.
7. Tester la carte dans le runtime existant : même ordre fixe, passage du personnage devant/derrière une ressource adaptée et collisions identiques ; retour au document auteur avec contexte conservé.
8. Activer plusieurs cartes déjà chaudes et ouvrir des outils contextuels ; démontrer absence de rechargement global, invalidation bornée et absence de résultat asynchrone appliqué à une ancienne session.

Les tests unitaires seuls ne ferment pas cette recette. UI réelle, sauvegarde/réouverture, parcours Player et traces profile sont attendus pour M1. Les budgets Notion restent des cibles à qualifier, pas des performances garanties par cet audit.

## M1 n’est pas M4

| Jalon | Capacités conservées au programme |
|---|---|
| M1 | Carte, ressources préparées, décors, sélection, ordre, historique, persistance et raccord Player minimal. |
| M2 | Peinture/terrain complets, Smart Tiles, surfaces, bordures, environnements, collisions éditables, connexions, imports et bibliothèque complète. |
| M3 | Personnages, dialogues, événements, scènes, cinématiques, progression et tests contextualisés. |
| M4 | Catalogues, configuration/personnalisation complète, export, couverture de remplacement, endurance et packaging. |

La [matrice de reprise](inventaire_reprise.md) maintient les fonctions différées visibles. Une fonction partagée nécessaire à M1 peut être intégrée plus tôt sans déplacer tout son domaine. La bascule définitive requiert la recette de couverture AS-QA-004, l’absence de perte de travail, la qualification runtime/export, les preuves de fluidité et l’accord explicite de Yoahn. L’ancien éditeur reste présent jusqu’à cette décision.

## Décisions encore ouvertes

- Ordre fixe de décor et profondeur dynamique acteur : contrat distinct, pas réordonnancement aveugle de `placedElements`.
- Pile locale ou globale, sens du compteur, comportement à égalité/extrémités, groupes et sélection multiple.
- Raccourcis à valider sur AZERTY/QWERTY et macOS/Windows, sans intercepter la saisie de texte.
- Propriétaire d’historique et sémantique de redo exposée publiquement ; arbitrage entre mémoire et journal de persistance.
- Politique d’activation/sauvegarde de cartes sales et de récupération ; budget de documents distinct des caches graphiques.
- Exposition du design system, ressources exactes du premier parcours et politique de coexistence sur les mêmes projets.
- Pour la 3D ultérieure : projection, unités, axes, représentation et sélection restent à spécifier ; aucun champ d’altitude ajouté maintenant.

Les modèles actuels de cellules, rectangles et positions 2D ne deviennent pas des volumes par renommage. Séparer le hit-test du choix de commande et la caméra du document protège une future vue 3D sans inventer de moteur universel.
