# POST-UI-MENU-001 — Audit et livraison du lot 1 / MENU-A

Audit du 6 septembre 2026. Ticket de rattachement : [POST-UI-MENU-001](https://app.notion.com/p/3d2197a7bfa581c09e65ed7418fc0ea3), domaine **Systèmes transverses**, hors gate bêta. Contrat commun : [POST-UI-MENU-000](https://app.notion.com/p/3d2197a7bfa58133a723d4d62d69fe70).

## État courant après implémentation

Le lot 1 demandé ensuite par Yoahn correspond à **MENU-A / POST-UI-MENU-001** : les contrats et mappings sont implémentés. La livraison est détaillée en section 11 ; la validation finale conditionnelle demandée par Yoahn et les preuves rejouées avant commit figurent en section 12. Les sections 1 à 10 ci-dessous conservent l’audit initial et ses constats historiques ; elles ne décrivent pas l’état du code après implémentation.

## Verdict initial avant autorisation d’implémenter

**Oui, le projet est suffisamment cadré pour commencer. Le bon premier travail est l’intégration de MENU001, puis les primitives de MENU002 et les ressources de MENU003.** Le moteur de menus existe ; sa réécriture serait inutile et risquerait les fonctions déjà opérationnelles. La cible visuelle demande de vraies compositions, des projections de données plus riches et des images résolues. Recolorer les cartes actuelles ne suffira pas.

Cet audit ne lance pas l’implémentation. Aucun code, test, catalogue Pokémon, projet de jeu ou réglage de l’application n’a été modifié par cette tâche. Aucun commit, changement de branche, push, rebase ou import d’assets n’a été effectué.

Les points déterminants sont les suivants :

1. Le chemin réel Avelune → session → shell → détail est identifié. La preview auteur partage déjà le shell et, pour les sections prises en charge, le vrai routeur de détail.
2. **196 tests ciblés passent dans 24 fichiers**. L’analyse du package UI et l’analyse ciblée du Player runtime ne signalent aucun problème. Cette preuve porte sur le socle actuel, pas sur la refonte.
3. Le modèle média Pokémon possède déjà `icon`, `party` et `portrait`. La collection HOME de `sprites-master` couvre les **1 025 espèces nationales de base**. Le lien avec le catalogue est faisable, mais les formes exigent une correspondance explicite et le menu ne reçoit pas encore ces références.
4. La racine et Profil ont besoin d’une projection du joueur courant. Les données existent dans la session, mais ne sont pas encore exposées au menu dans leur ensemble.
5. La Carte illustrée nécessite un contrat région/points d’intérêt. Le journal Quêtes dépend du contrat fonctionnel **FS-NAR-004**, encore `TODO` et bloqué dans Notion.
6. Les preuves visuelles du Player installé et la parité MCP live restent à établir. Le Hub ouvert appartient à un autre worktree ; le worker MCP échoue au démarrage avec le code 78.

**Statut lors de l’audit : DOING, réalisation PARTIAL.** L’audit était livré pour examen ; les adaptateurs et mappings demandés par MENU001 n’étaient pas encore implémentés. La livraison complémentaire est décrite en section 11. Aucun statut bêta n’est modifié.

## 1. Demande, sources et limites

La demande de Yoahn est un gros audit avant de commencer la refonte, à partir des tickets, des spécifications locales, de l’image fournie et de `sprites-master`. Les passages des documents qui demandent de coder, importer, clôturer un lot ou produire des assets décrivent les futurs lots ; ils ne sont pas interprétés comme une instruction de les exécuter pendant cet audit.

Sources consultées :

- Les quatorze pages Notion `POST-UI-MENU-000` à `013`, leurs propriétés, leurs critères et leurs relations.
- [Spécification intégrale](</Users/karim/Downloads/menu/specification-integrale.md>) : 828 lignes, 13 503 mots ; [dossier illustré](</Users/karim/Downloads/menu/dossier-illustre.html>) ; archive `PokeMap_Menus_Tickets_et_References.zip` dans le même dossier.
- L’image jointe de 1 536 × 1 024 et les sept images contenues dans l’archive : planche originale et six recadrages.
- Le checkout `/Users/karim/Project/pokemonProject`, branche `main`, SHA initial `9b997491d618d1527d3011f3ed1eb62495acc6c2` ; il correspond au snapshot cité par les specs.
- Le dossier [sprites-master](</Users/karim/Project/pokemonProject autre dossiers/sprites-master/>), en lecture seule.
- Les catalogues de jeux locaux utilisés comme témoins de raccordement, notamment [Le Train de 17h42](</Users/karim/Desktop/pokeMap Project/le_train_de_17h42/data/pokemon/species/>). Ce témoin n’est pas désigné comme destination d’un futur import global.
- [FS-NAR-004](https://app.notion.com/p/3c6197a7bfa58154a1ecfa2e17e0fa1e), [BETA-SYS-003](https://app.notion.com/p/3b9197a7bfa58172939df0f83e90337d), la roadmap mécanique et le précédent audit de parité du 24 août.
- `AGENTS.md`, `codex_rule.md`, l’index des skills, les workflows de recherche Notion, d’audit visuel, de parité PokeMap MCP et de vérification. Une passe de repérage de l’application réelle a été effectuée ; aucun replay Marionette n’est revendiqué.

Le Markdown et le HTML libres sont identiques, octet pour octet, à leurs exemplaires dans le ZIP. Le PNG joint a un encodage différent de celui de l’archive, mais **leurs pixels RGBA décodés sont identiques**. Le dossier HTML contient les sept ressources en base64 dans son script, réutilisées par quatorze balises image. Les liens `images/...` du Markdown libre ne se résolvent pas tant que le dossier d’images du ZIP n’est pas extrait ; le HTML autonome reste la référence pratique pour la lecture illustrée.

Il n’existe dans cette livraison ni calques, ni Figma, ni police identifiée dans la maquette, ni bibliothèque de sprites de production découpables. Les dimensions à 1 440 × 900, les tokens et les interactions sont une normalisation écrite, explicitement distinguée des pixels de la planche.

### Cohérence du backlog

Les treize tickets de réalisation sont initialement `TODO`, tous hors gate bêta. Le graphe interne contient 19 relations `Bloqué par`, sans cycle dans la famille. Il suit `001 → 002 → 003 → 004`, puis les branches d’écran, `005 → 006`, `011 → 012`, et enfin `013`.

La dépendance de MENU008 à FS-NAR-004 est documentée comme dépendance externe : FS-NAR-004 appartient à un autre backlog. Elle ne doit pas disparaître sous prétexte qu’elle ne figure pas dans la relation interne à la base MENU. FS-NAR-004 est lui-même bloqué par FS-NAR-001.

BETA-SYS-003 possède des propriétés `DONE` et un constat corrigé indiquant que la configuration auteur est réellement consommée. Son corps conserve un ancien encart `TODO` contradictoire. Le code et les tests existants relancés confirment l’intégration ; cet encart historique n’autorise pas à rouvrir la bêta. Aucun changement n’a été apporté à cette page.

### Arbitrages déjà suffisamment définis

- « Pokémon » désigne l’équipe ; le doublon « Équipe » devient « Pokédex ». « Profil » est au singulier.
- Ordre par défaut : Pokémon, Sac, Pokédex, Quêtes, Carte, Profil, Sauvegarder, Options. Les overrides auteur et narratifs restent prioritaires ; Reprendre demeure accessible.
- Les chiffres, noms, attaques et PP de l’image sont illustratifs. La sauvegarde et les catalogues sont les sources réelles.
- Le logo PokeMap et les légendes de la planche ne deviennent pas le branding de chaque jeu.
- L’œuf de la maquette ne rouvre pas la reproduction ; un emplacement vide ou un membre réellement supporté le remplace.
- « Se téléporter » ne constitue pas une autorisation de voyage rapide.
- Pokédex, Profil et Sauvegarde ont des spécifications textuelles, mais pas de maquettes détaillées déjà validées. Leurs premières captures devront recevoir une revue distincte.

## 2. Chemin d’intégration réel

| Étape | Preuve du checkout | Conséquence |
| --- | --- | --- |
| Application installée | [hub_installed_game_player.dart:372](/Users/karim/Project/pokemonProject/apps/pokemap_hub/lib/presentation/features/player/pages/hub_installed_game_player.dart:372) | Le point d’entrée est `PokeMapPlayerSessionView`, pas l’ancien menu de l’exemple runtime. |
| Session partagée | [pokemap_player_session_view.dart:512](/Users/karim/Project/pokemonProject/packages/map_player_ui/lib/src/player/pokemap_player_session_view.dart:512) | La session fournit le snapshot et les commandes au routeur de surface. |
| Pause | [runtime_player_surface_router.dart:178](/Users/karim/Project/pokemonProject/packages/map_player_ui/lib/src/player/runtime_player_surface_router.dart:178) | Composition par `RuntimePlayerPauseShell` et `RuntimePlayerDetailRouter`. |
| Autorité applicative | [runtime_player_coordinator.dart:247](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/player/runtime_player_coordinator.dart:247) | Révisions, disponibilité, commandes et transitions restent centralisées. |
| Preview auteur | [personalization_player_surface_adapter.dart:138](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/personalization/presentation/personalization_player_surface_adapter.dart:138) | L’éditeur fournit une preview via `PlayerPausePreviewShell`. |
| Composants réellement partagés | [player_pause_preview_shell.dart:103](/Users/karim/Project/pokemonProject/packages/map_player_ui/lib/src/player/player_pause_preview_shell.dart:103), puis ligne 176 | Même shell et vrai routeur pour équipe/sac/Pokédex/carte/options. Le risque de divergence vient des fixtures et des mappings, pas d’un second routeur complet. |

Frontières à conserver : modèles communs et sérialisation dans `map_core`, décisions pures dans `map_gameplay`, orchestration dans `map_runtime`, widgets/thème dans `map_player_ui`, adaptation no-code dans `map_editor`, sémantiques auteur dans `map_authoring`. Aucun import du design system Editor dans le Player, aucun second bus de menus, aucune lecture réseau déclenchée par `build`.

### Quatre familles d’enums à raccorder

Quêtes et Profil sont absents des quatre familles actuelles : `ProjectPauseActionId`, `PlayerPauseAction`, `RuntimePlayerAction`, `RuntimePlayerPauseSection`. L’ajout devra traverser présentation, disponibilité, coordonnées de navigation, localisation, sérialisation applicable, diagnostics, preview et export. Les types de surface et profils de présentation devront aussi être évalués.

Ancres : `map_core/lib/src/models/project_presentation_profile.dart:206`, `map_player_ui/lib/src/player/player_pause_surface.dart:13`, `map_runtime/lib/src/player/runtime_player_models.dart:29`, `map_runtime/lib/src/player/runtime_player_pause_data.dart:8`. Les mappings de preview concernés sont dans `player_pause_preview_shell.dart:250–285` ; l’éditeur de labels possède sa propre liste dans `project_menu_labels_editor.dart:143–183`.

Les petits contrats de lecture nécessaires appartiennent à MENU001. Les favoris, POI, préférences supplémentaires et autres opérations spécifiques restent dans les lots propriétaires. Un bouton actif sans contrat métier n’est pas un raccordement acceptable.

## 3. Matrice de raccordement par surface

| Surface / identité | Données et propriétaire existants | Commandes / état | Manque précis et politique d’absence | Lot |
| --- | --- | --- | --- | --- |
| Racine / `root` | `RuntimePlayerSnapshot.gameTitle`, actions, préférences, receipt ; joueur dans `GameState.trainerProfile` | Navigation locale ; aucune mutation à l’ouverture | Projection du joueur courant, lieu, temps, argent/devise, badges, compteurs, fond et objectif public. Masquer les blocs optionnels absents ; pas de valeurs de maquette. | 001, 003, 004 |
| Équipe / `party` | Résumé runtime : identité individuelle, nom, niveau, sexe, shiny, PV, stats, talent, objet, capacités/PP/provenance | `reorderPartyMember`, `setPartyLead`, `equipHeldItem`, `unequipHeldItem` ; sauvegarde canonique | Ajouter espèce/forme/types et références média. États normal/KO/vide, silhouette si média manquant. Identité du membre conservée après déplacement. | 001, 005 |
| Résumé membre | `RuntimePokemonSummary` et feuille de résumé existante | Sous-navigation, retour au membre déclencheur | Préserver les informations secondaires déjà présentes ; le détail enrichi ne doit pas les supprimer. | 005 |
| Sac / `bag` | Catalogue, quantité, poche, disponibilité et motifs ; projection actuelle souvent aplatie en libellés | `useBagItem` et flux atomiques existants | Exposer poche/ordre/quantité/description/image comme données typées ; ne pas parser `subtitle` pour reconstruire le métier. Favoris absents du canal actuel, à traiter dans 006. | 001, 006 |
| Ciblage objet | Identités stables objet/membre ; cibles éligibles | `partyMember`, `partyMove`, `partyMoveReplacement` | Réutiliser les pickers et décisions métier ; annulation sans consommation, commande unique pendant pending. | 005, 006 |
| PP / remplacement capacité | Moves et PP runtime, règles CT/CS | Commande existante et résultat applicatif | Maintenir ciblage de capacité, remplacement, incompatibilité et motif ; ne pas réduire le Sac au seul soin PV. | 006 |
| Pokédex / `pokedex` | Projection publique depuis catalogue activé et progression vue/capturée | Consultation et filtres UI, sans mutation de progression | Enrichir état de connaissance et image. Une miniature identifiable ne doit pas révéler une espèce inconnue. Recherche sur données publiques uniquement. | 001, 009 |
| Carte / `map` | `RuntimeMapProjection` : mapId, nom, current/discovered/unknown ; visites persistées | Consultation actuelle ; aucun voyage rapide exposé | Région, image, POI, coordonnées normalisées, descriptions et vignettes à créer dans le propriétaire canonique. Image absente : message et liste autorisée. | 007 |
| Quêtes / nouvelle entrée | Pas de journal public runtime/UI identifié ; structures narratives existantes en amont | Suivi et états doivent venir de FS-NAR-004 | Dépendance fonctionnelle explicite ; pas de lecture de facts bruts ni de reducer/reward dans les widgets. Masquer/désactiver avec raison tant que la capacité manque. | 001, FS-NAR-004, 008 |
| Profil / nouvelle entrée | `TrainerProfile`, progression et session active | Lecture seule ; aucune donnée de compte Avelune | Projection du joueur et résolution portrait. Pas de badges, durée ou total inventés. | 001, 010 |
| Sauvegarder / `save` | Adresse de sauvegarde active, phase saving, receipt, diagnostic | Confirmation actuelle puis canal de sauvegarde ; barrières transactionnelles | Harmoniser états idle/pending/success/failure sans nouvelle persistance ; une erreur n’annonce jamais un succès cosmétique. | 011 |
| Options / `options` | `PlayerPreferencesSnapshot`, gateway, audioMix, locale, accessibilité, hints, opacité tactile | Canal de préférences existant ; remapping disponible sur les Options du titre | Catégories et contrôles à raccorder aux consommateurs réels ; ne pas inventer plein écran/luminosité/vitesse si non exposés. | 012 |
| Reprendre / `resume` | Disponibilité et back policy du coordinateur | Retour modalité → détail → racine → reprise | Toujours accessible, même quand toutes les autres entrées sont masquées ; aucun input vers le monde pendant la pause. | 004, 013 |
| Retour titre / `returnToTitle` | Action runtime et orchestration de sortie | Depuis paused : demande un checkpoint avant la sortie | Expliciter la politique existante avant d’ajouter la confirmation proposée ; ne pas la transformer silencieusement en sortie sans sauvegarde. | 011, 012 |

Ancres principales : [runtime_player_pause_data.dart:120](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/player/runtime_player_pause_data.dart:120), [runtime_player_models.dart:253](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/player/runtime_player_models.dart:253), [runtime_pokemon_summary.dart:42](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/player/runtime_pokemon_summary.dart:42), [runtime_player_pause_data_builder.dart:345](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/player/runtime_player_pause_data_builder.dart:345), [runtime_map_projection.dart:10](/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/runtime_map_projection.dart:10).

### Racine et Profil : exposer la session courante

`TrainerProfile` contient notamment `name`, `avatarCharacterId`, `pronounSet`, `badgeIds`, `money`, `playtimeSeconds` (`map_core/lib/src/models/save_data.dart:672`). Cela ne signifie pas que le menu peut afficher correctement la durée en lisant le dernier enregistrement.

La session maintient le temps courant par `_basePlayTimeSeconds + _playWatch.elapsed.inSeconds` (`playable_map_game_session_runtime.dart:385`) et arrête le chronomètre lors de la pause. Il faut exposer cette source applicative. Les totaux de badges et de Pokédex doivent correspondre au jeu configuré ; les compteurs nationaux de la source d’assets ne constituent pas le total du Pokédex du jeu.

### Sauvegarde : respecter une sémantique déjà définie

Le routeur ne traite spécialement que `save` pour ouvrir la confirmation (`runtime_player_surface_router.dart:291–303`). `returnToTitle` passe directement au coordinateur ; celui-ci demande `checkpoint: phase == paused` (`runtime_player_coordinator.dart:621–632`). Les tests de course couvrent l’attente, le refus des doubles sauvegardes et le départ sécurisé.

La nouvelle confirmation de sortie est une décision d’interaction à expliciter dans MENU011. Elle ne justifie ni de supprimer le checkpoint actuel, ni de quitter après son échec, ni d’ajouter une deuxième orchestration concurrente.

## 4. Écart visuel et ressources de présentation

Le langage approuvé est précis : grand cadre nuit, grandes illustrations, listes denses, sélection bleu clair avec texte sombre, hiérarchie calme hors sélection. Les références se déclinent en six compositions distinctes. Un thème Material bleu conserverait les mauvais volumes.

| Écart | État du code | Action nécessaire |
| --- | --- | --- |
| Racine sans résumé illustré | Le shell affiche un `PlayerEmptyState` à la racine, ligne 558. | Vraie composition racine avec projection de session et média. |
| Cadre trop étroit pour la cible | Plafond 820 dans la branche sans width factor, `runtime_player_pause_shell.dart:410`. | Preset adapté à la référence 1344 × 804 dans un viewport 1440 × 900, avec contraintes réellement responsive. |
| Rail général conservé dans les détails larges | La branche `_twoPane` conserve navigation + détail, lignes 429–444. | Les détails utilisent le cadre complet ; ne pas juxtaposer rail général et seconde liste dense. |
| Seuils responsive différents | `runtime_player_layout.dart:15–24` : expanded dès 900 × 560, portrait selon largeur/orientation. | Intégrer les seuils 1100 × 650 / largeur 700 aux profils existants, en évaluant les autres consommateurs. Aucun second classificateur concurrent. |
| Médias de pause non représentés | `RuntimePlayerPresentation.fromRuntime` résout titleHero/titleLogo, mais la pause ne reçoit que présentation/labels. | Fond et portrait de pause explicites, partagés avec la preview et exportés. Ne pas réutiliser le hero du titre sans décision explicite. |
| Typography et primitives disponibles | `PlayerPanel`, `PlayerPortraitFrame`, `PlayerActionButton`, `PlayerBadge`, états vides et thèmes existent ; chiffres tabulaires déjà prévus. | Étendre ces primitives, centraliser matériaux/focus/tailles ; ne pas recréer un design system. |

La famille DM Sans est déjà embarquée sous `PokeMapSplashDMSans` dans le pubspec UI. Le thème de base utilise encore `Avenir Next`, avec des profils typographiques configurables. MENU002 doit choisir explicitement une police distribuée et la tester hors macOS ; il n’est pas nécessaire de chercher une police prétendument extraite du PNG.

Le préchargeur `PlayerAssetPreloader` borne une liste de chemins à 32 par défaut. **Ce n’est pas une preuve de budget de mémoire des images décodées**, ni une preuve d’évitement de décodage par frame. Le cache Flutter et la durée de vie des résolveurs doivent être mesurés dans MENU003/013.

### État de la vérification visuelle

La planche fournie et cinq ressources Pokémon locales de Flamajou ont été inspectées visuellement : HOME, gen6, dex, preview gen9 et portrait déjà importé dans le Train. Aucun écran de la nouvelle UI n’existe encore à comparer.

Le Hub déjà ouvert affiche la bibliothèque Avelune et un jeu MEDIA-03. Le processus provient de `/Users/karim/.config/superpowers/worktrees/pokemonProject/media-01-contracts/.../PokeMap Hub.app`, pas du checkout audité. Aucune action sur ce jeu n’a été effectuée. Cette observation est un contrôle d’environnement ; elle n’est pas une capture recevable du menu de `main`.

Ainsi, cet audit est **un audit des sources, des contrats, des ressources et des preuves automatisées**, avec analyse de la référence visuelle. Il ne prétend pas être un audit UX manuel exhaustif des six parcours du Player. Les captures de menu actuel, la navigation réelle dans une copie de jeu, les annonces lecteur d’écran, les effets audio et les mesures de performance restent à réaliser sur un build identifié.

## 5. Miniatures Pokémon : approche retenue

### Ressources disponibles et différence d’usage

La collection HOME sous `src/minisprites/pokemon/home/` contient 1 345 PNG : 1 340 identités nationales espèce/forme, quatre variantes à suffixe femelle et `xEgg`. Les 1 025 espèces de base sont couvertes. Il n’y a pas de collection shiny correspondante dans ce dossier.

| Famille source | Fichiers | Couverture dans la table source locale | Dimensions natives effectives |
| --- | --- | --- | --- |
| `src/minisprites/pokemon/gen6` | 1 639 PNG | 1 025 bases, dont 216 via variantes fournisseur ; 1 413 des 1 443 identités nationales espèce/forme | 10–40 × 10–30 |
| `src/minisprites/pokemon/home` | 1 345 PNG | 1 025 bases ; 1 340 identités espèce/forme, plus quatre suffixes femelles et un œuf | 38–124 × 46–126 |
| `src/previews/gen9` | 3 046 PNG | 1 025 bases en normal et shiny ; 1 387 identités espèce/forme standard | 170–502 × 164–508 |
| `src/dex` | 2 177 PNG | 808 bases standard ; 1 064 identités espèce/forme standard | 24–128 × 20–128 |
| `src/models` | 5 967 GIF | 1 004 numéros nationaux représentés | 26–368 × 15–219 |
| `src/sprites/gen1` à `gen5` | 21 381 fichiers | Sprites de combat selon génération/source, pas une famille uniforme de portraits | Variables |

Le nom du dossier `gen6` ne signifie donc pas « seulement les Pokémon de génération 6 ». Les PNG HOME, gen6 et previews/gen9 ont tous un canal alpha ou une transparence PNG. L’union inventoriée des catégories PNG/GIF hors `afd` représente les 1 443 IDs nationaux positifs de la table ; ce constat ne certifie pas qu’un fallback entre toutes ces catégories serait visuellement homogène.

Les fichiers HOME effectivement stockés mesurent de 38 à 124 pixels de large et de 46 à 126 de haut ; le README évoque un canvas source de 128 × 128. Ce sont des images détourées/croppées. Elles conviennent mieux aux portraits de ligne que les miniatures pixel art, mais ne constituent pas les grandes illustrations 512 × 512 recommandées dans les specs.

Exemple inspecté : Flamajou/Pansear, numéro 513, identifiant source `s16416`.

- [Portrait HOME](</Users/karim/Project/pokemonProject autre dossiers/sprites-master/src/minisprites/pokemon/home/s16416.png>) : personnage détouré, adapté à une ligne d’équipe.
- [Miniature pixel art gen6](</Users/karim/Project/pokemonProject autre dossiers/sprites-master/src/minisprites/pokemon/gen6/s16416.png>) : pixels très petits ; agrandissement nearest seulement si cette direction est retenue.
- [Ressource dex](</Users/karim/Project/pokemonProject autre dossiers/sprites-master/src/dex/s16416.png>) : rendu pixel art distinct du portrait HOME, à ne pas mélanger implicitement.

Le dépôt ne se limite pas aux miniatures : `src/previews/gen9/` contient aussi **3 046 PNG de grandes illustrations**, avec les 1 025 espèces de base et des variantes shiny. Les dimensions effectives montent jusqu’à 502 × 508. Le [Flamajou gen9](</Users/karim/Project/pokemonProject autre dossiers/sprites-master/src/previews/gen9/s16416.png>) inspecté mesure 332 × 496 et présente un rendu 3D.

Le jeu témoin du Train possède déjà **698 portraits alpha de 475 × 475**, pour environ 88,72 MiB. Le [portrait de Flamajou déjà importé](</Users/karim/Desktop/pokeMap Project/le_train_de_17h42/assets/pokemon/portraits/pansear.png>) est une illustration 2D visuellement plus proche de la planche. Il serait contre-productif de remplacer automatiquement cette bibliothèque par des miniatures ou une autre famille graphique.

**Proposition : préserver les portraits de qualité déjà assignés, compléter les rôles de liste avec HOME lorsque ce choix est cohérent, et utiliser les grandes sources comme compléments explicitement choisis.** La présence d’une source de grande taille ne valide pas à elle seule sa cohérence artistique avec les portraits déjà importés. Un agrandissement de miniature reste une variante pixel art à assumer, pas un substitut implicite à ces illustrations. Aucun asset n’est généré ni retouché pendant cet audit.

### État du raccordement

`PokemonMediaVariant` possède déjà les rôles `icon`, `party`, `portrait`. Il ne possède pas de rôle `iconShiny` ni de discriminant média de sexe. Les champs appelés `iconPath` dans la présentation Player désignent le branding/logo, pas un résolveur de Pokémon.

Dans le catalogue témoin du Train : 782 espèces distinctes, 1 118 variantes média déclarées, dont 336 entièrement sans visuel. `icon` et `party` sont renseignés sur 84 variantes ; `portrait` sur 698. **Une variante déclarée vide n’est pas la preuve que la source correspondante manque dans sprites-master.** L’inventaire des références actuelles et la couverture de la source sont deux mesures différentes.

Les 84 miniatures existantes correspondent par SHA-256 exact à 44 fichiers gen8 et 40 gen6 du dossier fourni. Tous les chemins de ces miniatures et des 698 portraits existent. Face/dos statiques sont assignés aux 782 espèces, avec face/dos shiny pour 698. Le `selbrume/` de ce checkout est un autre témoin limité à 18 espèces : 18 portraits et aucune assignation icon/party ; il ne faut pas l’utiliser comme mesure du catalogue global.

Dans le Train, 698 fiches ont `base` comme forme par défaut et 84 utilisent leur ID d’espèce. Imposer `variants.base` à tous écraserait une convention valide de ces catalogues. Exemples : `data/pokemon/species/0006-charizard.json:74` et `0164-noctowl.json:41` ; les rôles média correspondants sont dans `data/pokemon/media/charizard.json:11–14` et `noctowl.json:13–16`.

Le snapshot de ligne du menu (`RuntimePlayerDetailEntrySnapshot`) ne transporte pas de référence d’image. Le résumé Pokémon manque également d’identité d’espèce/forme exploitable pour ce raccordement. Copier les PNG et renseigner le catalogue serait donc insuffisant pour les afficher dans le Player.

### Correspondances de formes et variantes

`data/species.json` contient 1 540 entrées : 1 443 identités nationales positives, 96 négatives et une de numéro zéro. Aucun ID, sid ou couple positif numéro/forme n’est dupliqué. Sur les entrées positives, `sid = "s" + (num × 32 + formeNum)` ; `formeNum` va de 0 à 27. Les entrées négatives ne suivent pas cette convention naïve ; exclure explicitement les 97 entrées de numéro non positif de la jointure nationale. Le suffixe `-a` signifie une icône orientée à gauche, pas une forme alternative (`ps-pokemon.sheet.mjs:623–634`).

La jointure d’audit des 1 118 variantes du Train utilise numéro national, forme par défaut explicitement déclarée, puis comparaison normalisée des libellés de forme. Elle reste une aide à la construction d’une table explicite ; elle ne vaut pas approbation automatique de toutes les correspondances.

| Famille | Correspondance non ambiguë avec fichier présent | Forme mappée, fichier absent de cette famille | Ambiguïtés |
| --- | --- | --- | --- |
| HOME | 1 040 | 76 | 2 |
| gen6, fournisseurs inclus | 1 095 | 21 | 2 |
| previews/gen9 | 1 072 | 44 | 2 |

**Les 782 formes par défaut du catalogue témoin sont couvertes dans les trois familles.** Les écarts concernent les formes alternatives. Les ambiguïtés à traiter sont concrètes :

- `zygarde / 10` : les sources `s22977` et `s22978` ont toutes deux le libellé `10%` (`data/species.json:8130–8145`).
- `minior / meteor` : sept sources `s24768` à `s24774` portent le libellé `Meteor` (à partir de `data/species.json:8890`).

Ne jamais choisir le premier résultat d’un rapprochement de noms. Les formes absentes d’une famille peuvent exister ailleurs sans justifier un mélange silencieux de styles. Les 44 formes du Train sans preview gen9 se répartissent en 37 Mega, six costumes Pikachu et Pichu `spiky-eared`. Les 21 absentes des miniatures gen6 sont : Raticate/Marowak `alola-totem`, Gumshoos/Vikavolt/Ribombee/Araquanid/Lurantis/Salazzle/Togedemaru `totem`, Rockruff `dusk`, Pichu `spiky-eared`, Mimikyu `busted`/`totem`/`busted-totem`, Pumpkaboo/Gourgeist `small`/`large`/`super`, Greninja `bond`.

HOME ne possède que quatre suffixes femelles, pour Unfezant, Frillish, Jellicent et Pyroar, et aucun shiny. Previews/gen9 possède 202 fichiers avec suffixe femelle et 1 522 fichiers avec suffixe shiny, catégories qui peuvent se recouper. L’individu sauvegardé possède déjà `speciesId`, `formId`, `gender`, `isShiny` (`save_data.dart:157–184`) ; c’est le contrat média des rôles menu qu’il faut décider, pas ajouter ces attributs une seconde fois au Pokémon.

### Import existant et garde-fous manquants

L’import externe actuel cherche des portraits official-artwork, puis HOME en remplacement, ainsi que des sprites de combat et des cris ; il ne propose pas de candidat miniature (`map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart:905–997`). Cela explique les champs icon/party vides d’une grande partie du catalogue témoin. L’import JSON média seul ne copie pas les ressources et ne fournit pas le plan d’association massive recherché (`import_pokemon_media_json_use_case.dart:8–68`). Le générateur de stubs construit des chemins plausibles ; il ne constitue pas une preuve que les images sont présentes.

Le résolveur de combat actuel accepte espèce/côté joueur, sélectionne la variante par défaut/base/première et lit front/dos. Il ne résout pas la forme de l’individu, le sexe, le shiny ou les rôles de menu ([battle_pokemon_sprite_resolver.dart:45](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_pokemon_sprite_resolver.dart:45)). Le recycler tel quel afficherait potentiellement la mauvaise variante ; sa refonte combat n’est pas exécutée dans cette tâche.

Les actions `asset.import` et `pokemon.media.write` existent côté authoring ; la seconde écrit un document média entier. Leur combinaison ne démontre pas encore un import sémantique massif et réexécutable. Le chargeur de cohérence vérifie déjà sur disque les références icon/party/portrait (`pokemon_catalog_coherence_loader.dart:119–155`) et l’export valide la projection Pokémon.

**Point à couvrir avant l’import massif : les dépendances de suppression.** [deriveAssetUsages](/Users/karim/Project/pokemonProject/packages/map_authoring/lib/src/domains/assets/asset_store.dart:18) parcourt manifest et maps, pas les documents média Pokémon séparés. `asset.delete` utilise cette collecte pour refuser les suppressions d’assets référencés (`asset_actions.dart:348–369`). Une image nouvellement enregistrée dans le store et référencée seulement par un média Pokémon doit rester protégée par le contrat d’usage ; cette protection manque dans le parcours source inspecté. Aucun asset n’a été supprimé pour le démontrer et aucune corruption réelle n’est revendiquée. Ce raccord doit être traité et testé dans le lot d’import/preset ; la bêta reste intacte.

### Provenance et reproductibilité des mesures

Le dossier fourni n’a pas de `.git`. Empreinte SHA-256 de `data/species.json` : `211f574ead3ad0c8c8eed941d4b8ddc4ee2a5354e8e718137cd079ef75a6f064`.

Le README identifie le dépôt Smogon/Showdown. Sa section License distingue le code sous MIT des sprites et renvoie les crédits PMD à SpriteCollab (`README.md:96–102`). Elle n’attribue pas automatiquement une licence MIT à tous les PNG. Ce constat provient des fichiers fournis ; aucune analyse juridique ou validation individuelle des licences n’a été menée.

Mesures effectuées en Python via `ctx_execute` : parcours des fichiers, parsing JSON, contrôles IDs/couples/collisions, jointure des variantes, présence des fichiers référencés, lecture des dimensions IHDR/transparence et comparaison SHA-256 des 84 miniatures. Cinq exemples ont été visualisés par la passe principale et un exemple supplémentaire Noctowl par la passe assets. Il ne s’agit pas d’une inspection artistique de milliers de fichiers.

### Import futur, déterministe et vérifiable

1. Inventorier uniquement le catalogue canonique réellement visé ; annoncer séparément la couverture des espèces de base, des formes et des variantes de sexe/shiny.
2. Utiliser les numéros/identités canoniques et `data/species.json` de la source. L’identité source `sNN` encode numéro et forme ; ne pas mapper par nom français, surnom de membre ou simple ordre de fichier.
3. Établir une table explicite des formes. Une forme ambiguë ou sans correspondance produit un diagnostic ; pas de retour silencieux à la forme de base.
4. Générer un manifeste de provenance : source exacte/version ou empreinte, identité source, rôle, taille, sampling, empreinte du PNG, destination relative et résultat de correspondance.
5. Passer par les use cases/actions canoniques de média et préserver les visuels personnalisés. Préparer un dry-run listant chaque ajout/remplacement avant application.
6. Affecter les références existantes `icon`/`party`/`portrait` selon leur contrat. Si sexe/shiny demandent une extension persistante, la traiter explicitement avec version, validation et round-trip ; ne pas surcharger un champ avec une convention cachée.
7. Propager les références par les projections runtime, le résolveur, les widgets réels et les fixtures de preview. Tester les états inconnus du Pokédex pour éviter tout spoiler par l’image.
8. Vérifier export/install hors ligne, seconde exécution sans duplication, formes ambiguës, médias absents/corrompus et rétention des personnalisations.

Il n’est pas demandé de réimporter les statistiques, attaques, espèces ou règles du Pokédex dans MENU009. Le pipeline de ressources relève de MENU003 ; MENU005 et MENU009 en consomment les résultats.

## 6. Parité auteur, transport et packaging

Le source expose déjà `presentation.update`, les presets et `scene.pause_menu_visibility.set`. Le contrat de visibilité existant est vérifié par un test API directe + JSONL. Toute nouvelle propriété authorable devra passer par la même API canonique et ses validations.

Le gate de ressources utilise `_presentationReferences` dans `packages/map_authoring/lib/src/domains/assets/presentation_actions.dart:425`. Le packaging possède `GamePackagePausePresentation` dans [map_authoring — game_package_export_service.dart:280](/Users/karim/Project/pokemonProject/packages/map_authoring/lib/src/domains/distribution/game_package_export_service.dart:280). Les nouvelles images et propriétés de pause devront être évaluées dans ces parcours ; leur seule présence dans le JSON de projet ne prouverait pas leur inclusion ni leur résolution après installation.

`pokemap_describe` a été appelé pendant l’audit et renvoie exactement : `worker.exited: The canonical Authoring worker exited unexpectedly (code 78).` Aucun workspace mutable n’a été ouvert ni modifié. L’inventaire sémantique côté source ne remplace pas le catalogue live. Le diagnostic/rétablissement du worker et la conformance complète du MCP sont un prérequis de vérification des futurs changements authorables, pas un motif pour contourner l’API avec des modifications de JSON.

La documentation Flame configurée a été interrogée : la recherche `pauseEngine` retrouve `flame://flame/game`. La version verrouillée du runtime est 1.38.0. Les conclusions sur la pause reposent sur le code et les tests PokeMap ; aucune nouvelle API Flame n’a été supposée ou ajoutée.

## 7. Tests exécutés et résultats exacts

Aucun test n’a été créé ou modifié : la demande porte sur l’audit préalable, sans comportement ajouté. Les tests existants suivants ont été relancés sur leur package. Les commandes Flutter utilisent `--no-pub` afin d’éviter une résolution de dépendances hors scope.

### UI Player — 94 tests

Répertoire : `/Users/karim/Project/pokemonProject/packages/map_player_ui`.

```bash
flutter test --no-pub --reporter expanded test/player_pause_menu_test.dart test/player/runtime_player_pause_shell_test.dart test/player/runtime_player_detail_router_test.dart test/player/runtime_player_input_navigation_test.dart test/player/player_responsive_layout_matrix_test.dart test/player/runtime_player_resize_stress_test.dart test/player/player_pokemon_summary_parity_test.dart test/player/player_control_remapping_panel_test.dart test/player/player_save_recovery_surface_test.dart test/player/runtime_player_gamepad_bridge_test.dart
```

Résultat : `00:06 +94: All tests passed!` — exit 0.

### Runtime — 59 tests

Répertoire : `/Users/karim/Project/pokemonProject/packages/map_runtime`.

```bash
flutter test --no-pub --reporter expanded test/player/runtime_player_coordinator_pause_test.dart test/player/runtime_player_pause_data_builder_test.dart test/player/runtime_player_save_race_test.dart test/player/runtime_player_pause_pokedex_test.dart test/player/runtime_player_input_test.dart test/player/runtime_player_back_policy_test.dart test/player/runtime_player_models_test.dart test/runtime_pokemon_summary_test.dart
```

Résultat : `00:01 +59: All tests passed!` — exit 0.

### Gameplay — 39 tests

Répertoire : `/Users/karim/Project/pokemonProject/packages/map_gameplay`.

```bash
dart test --reporter expanded test/player_item_use_service_test.dart test/held_item_operations_test.dart test/party_bag_heal_operations_test.dart test/item_capability_matrix_test.dart
```

Résultat : `00:00 +39: All tests passed!` — exit 0.

### Core — 3 tests ; authoring — 1 test

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test --reporter expanded test/player_pause_menu_state_test.dart
```

Résultat : `00:00 +3: All tests passed!` — exit 0.

```bash
cd /Users/karim/Project/pokemonProject/packages/map_authoring
dart test --reporter expanded test/domains/narrative/pause_menu_visibility_transport_test.dart
```

Résultat : `00:00 +1: All tests passed!` — exit 0. Ce test couvre API directe et JSONL, pas le worker MCP live.

### Analyses et build

| Répertoire | Commande | Résultat |
| --- | --- | --- |
| `packages/map_player_ui` | `flutter analyze --no-pub` | `No issues found! (ran in 5.7s)` — exit 0 |
| `packages/map_runtime` | `flutter analyze --no-pub lib/src/player test/player` | `No issues found! (ran in 7.5s)` — exit 0 |

**Build application non lancé.** Audit sans changement produit ; `map_player_ui` n’est pas une application exécutable isolément. Les `flutter test` ont compilé les chemins exercés, ce qui constitue la validation de compilation disponible pour cette passe. Cela ne prouve ni un build release de l’application, ni le packaging, ni le lancement d’un export. Les suites complètes du monorepo, les goldens et les parcours installés n’ont pas été relancés.

Les harnesses Flutter ont été réapés avant/après les exécutions Flutter avec `pkill -9 -f flutter_tester`, `pkill -9 -f frontend_server_aot`, `pkill -9 -f 'flutter_tools.snapshot test'`. Le contrôle des MCP anciens n’a trouvé aucun serveur de plus de deux heures à réaper ; aucun MCP récent n’a été tué.

### Ce que ces tests ne couvrent pas encore

| Axe | Couverture actuelle | Travail nécessaire pour la cible |
| --- | --- | --- |
| Formats | Portrait/paysage, resize, focus, texte ×2 déjà présents. La matrice responsive injecte un détail vide (`player_responsive_layout_matrix_test.dart:116`). | Chaque vrai écran rempli à 800×600, 1280×720, 1440×900, 1920×1080, 844×390, 390×844 ; texte ×1/1,5/2. Le FHD actuel n’est pas exercé à toutes ces échelles. |
| Focus | Clavier, souris, tactile, intentions manette, restauration logique et rotation. | Retour exact au déclencheur des nouvelles modales, navigation liste/détail, tabs Sac/Quêtes, carte et catégories Options. |
| Async | Rejet de révision obsolète et courses de sauvegarde runtime ; UI de sauvegarde souvent alimentée par résultat immédiat dans les fixtures. | Pending/erreur/retry, fermeture/dispose, réponse tardive, sélection rapide et double activation sur les nouvelles surfaces. |
| Accessibilité | Flags, bordure de focus et cibles minimum déjà testés. | Contrastes composés mesurés, ordre lecteur d’écran, labels PV/PP/statuts, annonces uniques, images décoratives exclues. |
| Assets | Fixtures/goldens de présentation existants. | Correspondance globale des espèces/formes, pixels réellement décodés, fallback et export hors ligne avec ressources réelles. |
| Fidélité | Goldens historiques du design actuel. | Comparaison des six compositions au vrai Player ; revue séparée Pokédex/Profil/Sauvegarde. |
| Performance | Aucun benchmark de cette refonte. | Baseline puis profile avec appareil/mode déclarés, p95 build/raster et mémoire après cycles ; aucun chiffre de garantie inventé. |

Le test `pokemap_player_session_view_test.dart` couvre déjà le blocage du gameplay pendant une transition Menu asynchrone ; il n’a pas été relancé ici. L’audit ne conclut donc pas à une absence générale de protections async ou d’effets de préférences.

## 8. Ordre de réalisation et critères de passage

### Découpage pratique demandé le 6 septembre 2026

**14 tickets dans la série POST-UI-MENU : 000 pour le pilotage, puis 001 à 013 pour la réalisation.** Le prérequis narratif FS-NAR-004 appartient à un autre chantier et n'entre pas dans ce total.

Les 13 tickets de réalisation sont regroupés en **11 lots de travail, MENU-A à MENU-K**. Ces noms servent à demander une session bornée ; ils ne créent pas de nouveaux tickets et ne changent pas leurs critères. L'ordre ci-dessous est l'ordre conseillé.

| Lot à demander | Tickets POST-UI-MENU | Résultat attendu | Prérequis |
| --- | --- | --- | --- |
| **MENU-A — Contrats et raccordements** | 001 | Terminer les projections et mappings identifiés dans l'audit : session courante, profil, identité des médias, disponibilités et tests. Réemployer les commandes existantes. | Audit déjà livré ; implémentation restante. |
| **MENU-B — Système visuel** | 002 | Tokens et primitives partagés, galerie représentative avec sélection, focus, typographie, états et adaptations aux petits écrans. | A. |
| **MENU-C — Miniatures et ressources** | 003 | Catalogue des espèces/formes, import reproductible, liens aux médias du Pokédex, preset configurable par l'auteur et ressources identiques en preview/Player/export hors ligne. | A et B. |
| **MENU-D — Menu principal** | 004 | Racine illustrée, résumé du joueur actif, entrées réellement disponibles et navigation retour/reprise correcte. Première composition complète à revoir dans le Player. | A à C. |
| **MENU-E — Équipe Pokémon** | 005 | Liste et résumé avec vraies images, PV, statistiques et capacités ; déplacement et actions sur les objets conservés. | D. |
| **MENU-F — Sac** | 006 | Poches, liste et détail ; consommation, ciblages, PP, CT-CS, objets tenus et favoris selon le contrat retenu. | E. |
| **MENU-G — Pokédex et Profil** | 009 puis 010 | Deux écrans de consultation cohérents : aucun dévoilement des Pokémon inconnus et données du joueur de la session active. Les déclinaisons sans maquette détaillée passent en revue visuelle. | D ; E fournit une référence utile. |
| **MENU-H — Sauvegarde et Options** | 011 puis 012 | Sauvegarde avec attente/erreur/retry et sortie sûre ; catégories de réglages dont chaque contrôle applique un effet réel. | D ; 011 est réalisé et vérifié avant 012. |
| **MENU-I — Carte régionale** | 007 | Carte illustrée et POI configurables par l'auteur, lieux connus/inconnus, sélection et détail ; commandes limitées aux possibilités réelles du jeu. | D et ressources cartographiques qualifiées. |
| **MENU-J — Quêtes** | 008 | Journal branché au contrat narratif canonique, objectifs et suivi réels, états vide/terminé/indisponible. | D et contrat fonctionnel de FS-NAR-004 disponible. |
| **MENU-K — Certification finale** | 013 | Comparaison aux références dans le bon Player installé, parcours de jeu/rechargement, preview/export, formats, accessibilité et performance ; corrections ciblées des écarts. | E à J implémentés et vérifiés ; aucune certification complète tant que J est bloqué. |

**Premier lot conseillé : MENU-A.** L'audit ne clôture pas 001 : les raccordements et leurs preuves restent à réaliser. Aucun autre lot d'implémentation n'a démarré dans cette tâche.

MENU-G et MENU-H regroupent chacun deux tickets proches, exécutés et tracés séparément. Si le premier ticket est livré mais que le second reste ouvert, le lot reste partiel. Les lots G, H et I ne sont pas bloqués par le chantier Quêtes ; J peut attendre sans immobiliser ces écrans. Les contrôles de qualité restent nécessaires à chaque lot, K porte la certification transversale finale.

**MENU-C comporte trois étapes de contrôle :** C1 établir le manifeste et qualifier les correspondances espèces/formes/variantes ; C2 réaliser l'import canonique et les liens aux médias sans écraser les choix existants ; C3 compléter le preset auteur, la résolution des ressources et la preuve d'export hors ligne. On peut demander seulement C1, C2 ou C3 ; 003 reste partiel jusqu'à la livraison des trois. Les illustrations propres au jeu sont qualifiées à cette étape ; une image absente ne sera pas remplacée silencieusement par une composition inventée.

### Formulation pour lancer un lot

> Tom, fais le lot MENU-A de la refonte des menus, selon le découpage de POST-UI-MENU-000. Va jusqu'aux vérifications et à la mise à jour Notion, puis arrête-toi avant le lot suivant.

Pour une session plus courte sur les médias : « Tom, fais uniquement MENU-C1 : le manifeste et la qualification des correspondances. »

À chaque démarrage : relire les tickets concernés, vérifier le checkout et les changements concurrents, puis reprendre les preuves existantes. À la fin : conserver la portée du lot, rapporter les résultats et limites, synchroniser chacun de ses tickets et le proposer en `TO REVIEW` seulement après implémentation et vérification. `DONE` reste réservé à la validation de Yoahn. Une demande de lot n'autorise aucune opération Git d'écriture ; l'autorisation doit être explicite. Aucun lot suivant n'est lancé automatiquement.

### État des tickets après l'audit préalable

| Lot | Première réalisation vérifiable | État après cet audit |
| --- | --- | --- |
| 001 | Projections racine/profil et identité média ; mappings typés ; contrats d’absence ; tests associés. | `DOING` / réalisation `PARTIAL`, audit livré, code non commencé. |
| 002 | Galerie des primitives nuit/bleu clair avec états, opacité, focus, texte ×2 et police distribuée. | `TODO`, attend les contrats stabilisés. |
| 003 | Manifeste d’import média, table de formes, preset, résolution preview/runtime, export hors ligne. | `TODO`, miniatures et grandes illustrations disponibles ; préserver les portraits existants, compléter et raccorder les rôles manquants, qualifier les assets propres au jeu. |
| 004 | Racine illustrée reliée à la session réelle et au retour/reprendre. | `TODO`. |
| 005 | Équipe et résumé enrichis, déplacement/objets conservés. | `TODO`. |
| 006 | Poches et détail du Sac, tous les ciblages, favoris selon contrat explicite. | `TODO`, après 005. |
| 007 | Région/POI authorables et surface illustrée, sans faux voyage rapide. | `TODO`, travail de données réel à prévoir. |
| 008 | Consommation du journal public et du suivi canonique. | `TODO`, dépendance FS-NAR-004 bloquante. |
| 009 | Pokédex enrichi en préservant Inconnu/Vu/Capturé et recherche sans divulgation. | `TODO`, nouvelle déclinaison à revoir. |
| 010 | Profil de la sauvegarde active, lecture seule. | `TODO`, nouvelle déclinaison à revoir. |
| 011 | Sauvegarde/receipt et sortie cohérentes avec la politique runtime existante. | `TODO`, nouvelle déclinaison à revoir. |
| 012 | Catégories de réglages avec effet, portée, défaut et disponibilité par ligne. | `TODO`, après 011 pour sortie sûre. |
| 013 | Captures comparées, replay installé, export, accessibilité et performance. | `TODO`, aucune certification anticipée. |

Pour démarrer sans mélanger les lots : établir d’abord les petits modèles de lecture et leurs tests ; construire ensuite une preuve visuelle représentative de la racine et de l’équipe avec des données réelles avant de décliner tous les écrans. La revue artistique reste une condition distincte de la réussite des tests.

Lots mécaniques liés : FG-026/027/028 (équipe/résumé/ordre), FG-061/062/063/072/073 (Sac/objets/CT-CS), FG-160/161/162/163/164/165 (menus/options/carte/verrouillage). La roadmap contient des statuts historiques parfois plus anciens que les preuves du code. **Aucun FG n’est reclassé dans cet audit** : son statut documentaire est conservé, et aucun `DONE` supplémentaire n’est proposé sans recertification dédiée. MENU008 garde la dépendance narrative explicitement ouverte.

## 9. Fichiers, Git et traçabilité

### État initial

`git branch --show-current` : `main`.

`git rev-parse HEAD` : `9b997491d618d1527d3011f3ed1eb62495acc6c2`.

Aucun changement suivi au début de la passe. Quinze `.pyc` non suivis étaient déjà présents sous `plugins/pokemap-reference-builder/skills/pokemap-reference-builder/scripts/__pycache__/` : `asset_contract`, `asset_resolver`, `blueprint_quality`, `blueprint_tool`, `path_atlas_builder`, `reference_analyzer`, `test_asset_contract`, `test_asset_resolver`, `test_blueprint_quality`, `test_blueprint_tool`, `test_path_atlas_builder`, `test_reference_analyzer`, `test_reference_builder_cli`, `test_visual_quality`, `visual_quality`, tous suffixés `.cpython-314.pyc`. Ils n’ont pas été supprimés ou ajoutés à Git.

### Modification de cette tâche

Un seul fichier créé : `documentation/reports/player/menus/post_ui_menu_001_integration.md`.

Zones : verdict et scope ; sources/backlog ; architecture et matrice de contrats ; analyse visuelle ; inventaire et stratégie média ; parité ; commandes/preuves ; ordre des lots ; Git et critique. Raison : conserver l’audit explicitement demandé dans le document canonique prévu pour MENU001. Impact produit : aucun.

Le ticket Notion MENU001 est mis à jour dans le domaine existant, avec scope, SHA, commandes, résultats, limites et prochaine action. Aucun grand domaine ni nouveau ticket n’est créé. L’epic et les autres lots conservent leurs critères et leur statut.

La relecture via le connecteur confirme une seule section « Audit préalable du 6 septembre 2026 », le complément sur les formes/dépendances média, le lien au rapport, les 196 tests, `Statut=DOING`, `Domaine=Systèmes transverses`, `Gate bêta=false` et le SHA initial. L’écriture Notion est donc vérifiée, pas seulement tentée.

### Complément de planification demandé après l'audit

Le décompte de 14 tickets et le découpage en 11 lots de travail sont ajoutés à la section 8 de ce même fichier, puis rattachés au ticket de pilotage POST-UI-MENU-000, dans le domaine existant Systèmes transverses et hors gate bêta. Ce complément n'ajoute aucun fichier, aucun ticket et aucun changement produit. Les périmètres, relations de dépendance et statuts d'implémentation des tickets sont conservés. Les étapes C1/C2/C3 bornent des sessions au sein de 003 ; elles ne valent pas clôture du ticket.

L'état Git initial de ce complément comporte les huit fichiers suivis modifiés par le travail concurrent, ce rapport non suivi et les quinze `.pyc` déjà recensés ci-dessous. Les 196 tests et deux analyses restent les preuves de l'audit préalable ; ils ne sont pas relancés ni présentés comme une validation fraîche du découpage documentaire.

Vérifications de ce complément : la recherche Notion `POST-UI-MENU-` retrouve les 14 titres 000–013 ; le contrôle du tableau trouve 11 lots et 13 tickets de réalisation, sans oubli, doublon ni espace en fin de ligne. La relecture de MENU000 confirme une seule section d'organisation pratique, les onze lots et des propriétés inchangées. `git diff --check` : exit 0, aucune sortie. `bash tools/scripts/check_markdown_hygiene.sh` : exit 1, avec les deux mêmes lignes de budget documentaire reproduites plus bas. L'état Git final de ce complément est identique à son état initial quant aux chemins modifiés/non suivis ; branche `main`, SHA `9b997491d618d1527d3011f3ed1eb62495acc6c2`.

### Travail concurrent observé

Pendant la passe, des modifications suivies sont apparues dans plusieurs fichiers de scènes, de session runtime et de démarrage du Hub. Elles ne proviennent d’aucun agent de cet audit et ont été laissées intactes. Les tests ciblés ont été exécutés avant ce travail concurrent : ils constituent une baseline de l’audit, pas une validation de l’état final de ces autres modifications.

Relevé après rédaction :

```text
 M apps/pokemap_hub/lib/features/session/application/services/hub_in_process_session_factory.dart
 M apps/pokemap_hub/lib/features/session/application/services/hub_runtime_startup_bootstrap.dart
 M examples/playable_runtime_host/lib/main.dart
 M packages/map_core/lib/src/models/scene_execution_capabilities.dart
 M packages/map_core/test/scene_execution_profile_test.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/lib/src/session/playable_map_game_session_runtime.dart
 M packages/map_runtime/test/playable_map_game_event_v2_boot_integration_test.dart
?? documentation/reports/player/menus/post_ui_menu_001_integration.md
```

Les quinze `.pyc` initiaux non suivis sont toujours présents en plus de ces lignes. `HEAD` reste `9b997491d618d1527d3011f3ed1eb62495acc6c2`. Les ancres de code sont celles du snapshot initial ; le travail concurrent a notamment déplacé la pause de session vers la ligne 309 et le calcul de durée vers la ligne 389, sans que cette tâche modifie ces fichiers.

`git diff --check` : exit 0, aucune sortie. Ce contrôle concerne les diffs suivis ; le rapport non suivi a aussi été contrôlé séparément pour ses liens locaux, ses blocs Markdown et l’absence de marqueurs de conflit. Aucun lien local manquant n’a été détecté.

### Hygiène documentaire

`bash tools/scripts/check_markdown_hygiene.sh` a été exécuté après création du rapport : exit 1, avec exactement `Markdown hygiene: 1 new Markdown files exceed the default limit of 0.` puis `Use POKEMAP_MARKDOWN_MAX_NEW only when the user explicitly approved a bounded bulk documentation task.`

L’unique nouveau Markdown est cet audit explicitement demandé, placé dans le répertoire canonique attendu. Le script applique néanmoins son budget par défaut de zéro ; aucun override ni modification du garde-fou n’a été effectué. Ce contrôle n’est donc pas déclaré vert. Le livrable demandé est conservé et le décalage entre l’autorisation documentaire et le budget mécanique reste explicite.

## 10. Verdicts des passes et autocritique

| Passe | Verdict |
| --- | --- |
| Audit / Architecture | Favorable au démarrage de MENU001, avec réemploi du coordinateur, du shell, du routeur et de la preview. Quêtes reste dépendant du chantier narratif. |
| Faisabilité de l’implémentation | Projections et mappings ciblés nécessaires ; aucun second moteur ou bus. Implémentation volontairement non exécutée conformément à la demande d’audit préalable. |
| Assets et catalogue | Sources de miniatures réutilisables ; mapping et projection encore à compléter. Couverture des espèces de base distincte de celle des formes et des variantes. La passe spécialisée a relu et validé les chiffres et la transcription finale de la section 5. |
| Tests | 196 tests ciblés réussis ; nouveaux écrans et nouveaux contrats non livrés. |
| Build / Validation | Compilation via tests et analyses réussies sur leurs périmètres ; build installé, rendu final, packaging et MCP live non certifiés. |
| Critique finale | Relecture indépendante favorable à la livraison de l’audit. Totaux/commandes/ancres et limites contrôlés ; formulation sur les tests existants, chemin de packaging et relevé concurrent précisés. Aucun accord implicite pour implémenter ou importer. |

Le principal risque n’est pas l’absence de moteur : c’est de confondre données existantes, projections disponibles et rendu réellement livré. Le même piège existe pour les assets : une correspondance de fichiers ne prouve ni la bonne forme, ni le rendu, ni l’export.

Autres risques à conserver visibles : perte d’un flux PP/CT-CS/objet tenu pendant la refonte, double navigation générale sur les détails, rupture des overrides narratifs, fuite du nom ou du visuel d’une espèce inconnue, image de titre réutilisée comme fond de pause par convention implicite, statistiques de la dernière sauvegarde présentées comme état courant, et amélioration visuelle du mode desktop non reproduite en portrait.

L’audit est volontairement borné : pas d’exécution exhaustive du monorepo, pas de validation légale des ressources, pas de mesure de performance, pas d’inspection manuelle des milliers d’images ni de certification des parcours installés. Les versions, compteurs et états rapportés correspondent aux sources locales et aux lectures Notion de cette passe.

## 11. Livraison MENU-A après demande explicite du lot 1

### Résultat, périmètre et décisions

Les nouveaux contrats alimentent les snapshots existants et les commandes du coordinateur. Aucun second moteur de menus, bus d’état, routeur global ou dépendance Flutter dans le cœur métier n’est introduit.

- **Racine/Profil** partagent le même `RuntimePlayerProfileSnapshot` : joueur courant, lieu courant, argent, badges, progression Pokédex et identité/portraits du personnage sélectionné. La durée provient du temps de session et du checkpoint, jamais de l’ancien compteur du profil sauvegardé.
- **Pokémon** expose une identité média structurée (espèce, forme, forme par défaut du catalogue, genre, shiny et référence média) ainsi que types, talent, objet tenu, statut et types de capacités. Aucun fichier de miniature n’est chargé par ce contrat.
- **Sac** expose ID, quantité, ordre, poche et description sans remplacer les commandes d’usage existantes.
- **Pokédex** distingue inconnu/vu/capturé. Une entrée inconnue ne divulgue ni identité média ni types. Les collections de snapshots sont immuables.
- **Quêtes/Profil** traversent core, runtime, UI, personnalisation auteur, export et transports. L’ordre par défaut contient Pokédex → Quêtes → Carte → Profil. Quêtes reste désactivé avec une raison explicite tant que FS-NAR-004 ne fournit pas le journal ; la preview applique la même règle et ne déclenche pas de callback.
- La visibilité configurée et les overrides narratifs restent appliqués. Le Profil possède un premier consommateur générique ; son écran visuel final appartient à MENU010.
- Une réponse tardive de chargement de menu, d’usage du sac ou de réorganisation de l’équipe est ignorée après fermeture/changement de session. Le retour au titre efface les anciens détails et le profil.

**Version de contrat :** schéma de `ProjectPresentationProfile` maintenu à **10**, `presentation.update` maintenu à **v1**. Les identifiants d’action et libellés optionnels étendent le modèle existant sans nouvelle structure persistée. La normalisation canonique projette les libellés dans `pause.actions`. Il n’existe aucune promesse de lecture des nouvelles actions par un ancien binaire, ni nouvelle migration de compatibilité.

**Politique des données absentes :** sans catalogue, les totaux Pokédex restent absents ; sans durée injectée, aucune durée sauvegardée n’est substituée. Le libellé de monnaie reste absent puisque le modèle canonique n’en définit pas. Le fond de pause relève du preset MENU003 et ne reprend pas implicitement l’image de titre. L’objectif actif reste absent sans contrat de journal. L’illustration du sac attend un contrat média d’objet, sans inventer un chemin à partir du nom. Les formes, miniatures, résolution des assets et protections de références sont réservées à MENU003. Le contrat régional/points d’intérêt et ses actions relèvent de MENU007 ; aucun voyage rapide n’est ajouté ici.

FG160–FG165 restent les repères de la roadmap mécanique : cette livraison ne recertifie pas leurs parcours complets et ne modifie aucun statut de roadmap. Les changements esthétiques, imports, nouveaux écrans et certification du Player installé restent dans les lots suivants.

### Inventaire des fichiers et zones modifiées

39 fichiers de code/tests dans ce lot (37 suivis modifiés et 2 nouveaux tests), plus la mise à jour du présent rapport déjà créé pour l’audit. Les chemins suivants sont relatifs à la racine `/Users/karim/Project/pokemonProject`. Le diff Git reste la preuve canonique des modifications exactes ; la dernière colonne identifie la responsabilité modifiée.

| Fichier | Zone / changement |
| --- | --- |
| `packages/map_authoring/lib/src/domains/distribution/game_package_export_service.dart` | Export des libellés Quêtes/Profil |
| `packages/map_authoring/test/domains/assets/presentation_authoring_test.dart` | Persistance des nouvelles actions |
| `packages/map_authoring/test/domains/narrative/pause_menu_visibility_transport_test.dart` | Visibilité narrative des deux actions |
| `packages/map_authoring/test/tooling/jsonl_presentation_cinematic_flow_test.dart` | Transport JSONL des libellés/actions |
| `packages/map_core/lib/src/models/project_presentation_profile.dart` | Actions, icône person, libellés et ordre par défaut |
| `packages/map_core/lib/src/models/project_presentation_profile.freezed.dart` | Génération ciblée des libellés |
| `packages/map_core/lib/src/models/project_presentation_profile.g.dart` | Codec généré des libellés/actions |
| `packages/map_core/test/project_presentation_profile_test.dart` | Defaults, ordre et roundtrip |
| `packages/map_distribution/lib/src/game_package_manifest.dart` | Libellés exportables |
| `packages/map_distribution/lib/src/game_package_manifest_codec.dart` | Lecture/écriture des deux libellés |
| `packages/map_distribution/test/game_package_manifest_codec_test.dart` | Roundtrip du package |
| `packages/map_editor/lib/src/features/personalization/presentation/personalization_player_surface_adapter.dart` | Adaptation de la preview commune |
| `packages/map_editor/lib/src/features/personalization/presentation/project_menu_labels_editor.dart` | Champs no-code des libellés |
| `packages/map_editor/lib/src/features/personalization/presentation/project_pause_actions_editor.dart` | Libellés/icône des nouvelles actions |
| `packages/map_editor/test/game_export/game_package_export_service_test.dart` | Export auteur des libellés |
| `packages/map_editor/test/personalization/personalization_player_surface_adapter_test.dart` | Actions et profil de démonstration |
| `packages/map_editor/test/personalization/project_menu_labels_editor_test.dart` | Édition des libellés |
| `packages/map_player_ui/lib/src/localization/player_localizations.dart` | Libellés Quêtes/Profil |
| `packages/map_player_ui/lib/src/player/player_pause_preview_shell.dart` | Fixture explicite et Quêtes inactif |
| `packages/map_player_ui/lib/src/player/player_pause_surface.dart` | Conversions des actions et icône person |
| `packages/map_player_ui/lib/src/player/runtime_player_detail_router.dart` | Route Profil générique |
| `packages/map_player_ui/lib/src/player/runtime_player_pause_shell.dart` | Actions Quêtes/Profil |
| `packages/map_player_ui/lib/src/player/runtime_player_presentation.dart` | Mappings des identifiants canoniques |
| `packages/map_player_ui/lib/src/player/runtime_player_surface_router.dart` | Mapping de surface existante |
| `packages/map_player_ui/test/player/runtime_player_detail_router_test.dart` | Route Profil |
| `packages/map_player_ui/test/player/runtime_player_pause_shell_test.dart` | Aucune activation de Quêtes |
| `packages/map_player_ui/test/player/runtime_player_presentation_test.dart` | Conversions et libellés |
| `packages/map_player_ui/test/player_localizations_test.dart` | Libellés localisés |
| `packages/map_runtime/lib/src/player/runtime_player_coordinator.dart` | Actions, capacités, garde de session et nettoyage au titre |
| `packages/map_runtime/lib/src/player/runtime_player_models.dart` | Actions et accès au profil partagé |
| `packages/map_runtime/lib/src/player/runtime_player_pause_data.dart` | Snapshots immuables profil/sac/Pokédex |
| `packages/map_runtime/lib/src/player/runtime_player_pause_data_builder.dart` | Projection des données réelles, masquage des inconnus |
| `packages/map_runtime/lib/src/player/runtime_pokemon_summary.dart` | Identité média et identifiants métier bruts |
| `packages/map_runtime/lib/src/session/playable_map_game_session_runtime.dart` | UNIQUEMENT badges/personnages du bundle et durée de session injectés |
| `packages/map_runtime/test/player/runtime_player_coordinator_pause_test.dart` | Navigation, overrides, lifecycle et réponses tardives |
| `packages/map_runtime/test/player/support/runtime_player_test_harness.dart` | Chargeur différable pour les courses de session |
| `packages/map_runtime/test/session/playable_map_game_session_runtime_test.dart` | Profil du checkpoint courant et binding de test |
| `packages/map_runtime/test/player/runtime_player_menu_contracts_test.dart` | NOUVEAU : données réelles, absence de catalogues et immutabilité |
| `tools/pokemap_mcp/test/live_menu_contracts.test.ts` | NOUVEAU : serveur MCP packagé réel sur stdio |

Pour le fichier de session partagé avec le travail concurrent, le lot ajoute seulement les champs `_projectBadges` et `_projectCharacters`, leur initialisation depuis le manifeste et les arguments `playtimeSeconds`, `projectBadges`, `projectCharacters` du builder. Les changements de lecteur cinématique et les autres modifications de runtime préexistantes ne font pas partie de MENU-A.

### Vérification fonctionnelle fraîche

Les commandes suivantes ont été exécutées depuis le package indiqué. Chaque total correspond au dernier passage complet de cette sélection ; les relances antérieures ne sont pas additionnées.

| Package | Résultat final |
| --- | --- |
| map_runtime, 12 fichiers | `00:03 +91: All tests passed!`, exit 0 |
| map_player_ui, 7 fichiers | `00:06 +94: All tests passed!`, exit 0 |
| map_editor, 5 fichiers | `00:12 +58: All tests passed!`, exit 0 |
| playable_runtime_host, golden slice | `00:00 +11: All tests passed!`, exit 0 |
| map_core, 2 fichiers | `00:00 +27: All tests passed!`, exit 0 |
| map_distribution, codec | 36 tests passés, exit 0 |
| map_authoring, API/transport/JSONL | 20 tests passés, exit 0 |

Soit **337 tests ciblés réussis**, distincts des suites MCP/parité ci-dessous.

```sh
# packages/map_runtime
flutter test --no-pub --reporter expanded test/player/runtime_player_menu_contracts_test.dart test/player/runtime_player_models_test.dart test/runtime_pokemon_summary_test.dart test/player/runtime_player_pause_data_builder_test.dart test/player/runtime_player_pause_pokedex_test.dart test/player/runtime_player_coordinator_pause_test.dart test/player/runtime_pause_bag_item_service_test.dart test/player/runtime_pause_party_reorder_service_test.dart test/player/runtime_player_save_race_test.dart test/session/playable_map_game_session_runtime_test.dart test/player/runtime_player_coordinator_lifecycle_test.dart test/phase_a_golden_battle_slice_smoke_test.dart
# packages/map_player_ui
flutter test --no-pub --reporter expanded test/player/runtime_player_presentation_test.dart test/player/runtime_player_detail_router_test.dart test/player/runtime_player_pause_shell_test.dart test/player_localizations_test.dart test/player/player_pokemon_summary_parity_test.dart test/player/pokemap_player_session_view_test.dart test/player_pause_menu_test.dart
# packages/map_editor
flutter test --no-pub --reporter expanded test/personalization/project_menu_labels_editor_test.dart test/personalization/personalization_player_surface_adapter_test.dart test/game_export/game_package_export_service_test.dart test/personalization/personalization_runtime_preview_test.dart test/personalization/personalization_pause_inspector_test.dart
# examples/playable_runtime_host
flutter test --no-pub --reporter expanded test/phase_a_golden_slice_launch_test.dart
# packages/map_core
dart test --reporter expanded test/project_presentation_profile_test.dart test/player_pause_menu_state_test.dart
# packages/map_distribution
dart test test/game_package_manifest_codec_test.dart
# packages/map_authoring
dart test test/domains/assets/presentation_authoring_test.dart test/domains/narrative/pause_menu_visibility_transport_test.dart test/tooling/jsonl_presentation_cinematic_flow_test.dart --reporter expanded
```

Les deux régressions « late pause data / returning to title clears » puis les deux régressions « refresh cannot replace a disposed snapshot » ont d’abord échoué (réponse acceptée au lieu d’annulée, ou ancien profil conservé), avant correction et passage vert dans les 91 tests. Un premier passage runtime avait 74 succès et 1 échec lié au binding Flutter absent dans le test de fin de session : ajout de `TestWidgetsFlutterBinding.ensureInitialized()` dans le test. Une tentative avec deux options `--plain-name` a produit exit 79 sans exécuter de tests ; le sélecteur a été corrigé en expression régulière. Deux chargements Dart de la passe déléguée ont initialement échoué sans diagnostic exploitable ; les relances séquentielles passent, sans attribuer une cause non démontrée.

Les processus de harness Flutter ont été nettoyés après les runs, en coordonnant les suites pour ne pas interrompre un test concurrent.

### Analyse et génération

```sh
# packages/map_runtime
flutter analyze --no-pub lib/src/player lib/src/session/playable_map_game_session_runtime.dart test/player test/runtime_pokemon_summary_test.dart test/session/playable_map_game_session_runtime_test.dart
# packages/map_player_ui
flutter analyze --no-pub
# packages/map_editor
flutter analyze --no-pub lib/src/features/personalization test/personalization/project_menu_labels_editor_test.dart test/personalization/personalization_player_surface_adapter_test.dart test/game_export/game_package_export_service_test.dart
# packages/map_distribution
dart analyze lib/src/game_package_manifest.dart lib/src/game_package_manifest_codec.dart test/game_package_manifest_codec_test.dart
# packages/map_authoring
dart analyze lib/src/domains/distribution/game_package_export_service.dart test/domains/assets/presentation_authoring_test.dart test/domains/narrative/pause_menu_visibility_transport_test.dart test/tooling/jsonl_presentation_cinematic_flow_test.dart
# packages/map_core
dart analyze lib/src/models/project_presentation_profile.dart test/project_presentation_profile_test.dart
dart run build_runner build --delete-conflicting-outputs --build-filter='lib/src/models/project_presentation_profile.*.dart'
```

Les analyses runtime/UI/editor/distribution/authoring donnent **No issues found!**, exit 0 (respectivement 14,2 s, 10,1 s et 14,4 s pour les trois runs Flutter finaux). L’analyse core donne **6 issues found**, exit 0 : six informations préexistantes (`prefer_interpolation_to_compose_strings` et `use_null_aware_elements`), aucune erreur ni warning. La génération ciblée indique **Built with build_runner/aot in 1s; wrote 3 outputs** ; seuls les deux fichiers générés suivis du profil changent. Le log ne permet pas d’attribuer le troisième output à un fichier précis.

La compilation est prouvée par les tests Flutter et le build TypeScript MCP. Aucun build de distribution installé ni verdict visuel de la nouvelle interface n’est revendiqué.

### Parité API, JSONL, éditeur et MCP

La preuve utilise les contrats existants `presentation.update` et `scene.pause_menu_visibility.set`, avec planification, application, requêtes et validation. Les tests directs/JSONL et la preview auteur figurent dans les suites ci-dessus.

Le nouveau `tools/pokemap_mcp/test/live_menu_contracts.test.ts` lance réellement `dist/src/index.js` par `Client/StdioClientTransport`, avec une copie temporaire isolée de la fixture golden item system et une racine autorisée étroite. Il vérifie le catalogue/schema 10, les libellés et actions Quêtes/Profil, leur visibilité narrative, la persistance sur disque, le refus d’un ID inconnu sans écriture, la validation et la fermeture du workspace.

- `npm run check` et `npm run build`, depuis `tools/pokemap_mcp` : exit 0.
- Nouveau test MCP live isolé : **1 test passé, 0 échec**, exit 0, environ 9,5 s.
- `npm test`, depuis `tools/pokemap_mcp` : **75 tests, 73 passés, 2 échecs, exit 1**, durée 576 859 ms. Le test MENU-A passe également dans cette suite (13,58 s). Les deux échecs sont des `worker.timeout` au describe initial dans `mutation_server.test.ts` : « MCP persists a typed pause menu visibility consequence » et « CIN-033 certifies preSession and Presentation through live MCP ». Le timeout RPC context-mode de 300 s a interrompu l’attente du résultat, pas le processus ; le résultat final a été récupéré après sa terminaison. Ce run global n’est pas déclaré vert.
- Relance ciblée des deux scénarios sans rebuild ni correction de production : **2/2 passés, exit 0**, durée 17 970,807 ms. Commande : `node --import tsx --test --test-name-pattern='MCP persists a typed pause menu visibility consequence|CIN-033 certifies preSession and Presentation through live MCP' test/mutation_server.test.ts`. Les timeouts ne sont pas reproduits isolément ; ce résultat ne transforme pas rétroactivement la suite complète en run vert.
- `dart test test/parity/full_authoring_parity_test.dart`, depuis `packages/map_authoring` : **18 tests passés**, exit 0, environ 30 s.
- `dart run tool/pmcp085_conformance.dart`, depuis `packages/map_authoring` : **exit 1**, `catalogComplete=true`, 83 ressources, 341 actions, aucune cellule bloquée/manquante. La condition globale `itemTransportCertificationComplete=false` exige les receipts Items absents de cette exécution. Les deux actions MENU-A annoncent bien `cli/directApi/editor/mcp`. Le test de parité existant « PMCP tool refuses an Item transport claim without receipts » vérifie précisément ce refus. Le JSON intégral local est conservé dans `/tmp/menu-a-pmcp085-conformance.json` (preuve temporaire, non versionnée).

Le test live a d’abord ajusté deux assertions de test : les libellés relus sont normalisés dans `pause.actions`, et les erreurs exposées sont `invalid_request / worker.request_invalid`, pas le texte Dart interne. Aucun changement de production n’a été nécessaire pour faire passer ce transport.

**Limite du connecteur configuré :** le `pokemap_describe` de la connexion habituelle échoue toujours avec `worker.exited`, code 78. Son ancien argument `--root /Users/karim/Desktop/pokeMap Project/pokemon_sdk_showcase_v2` pointe vers un chemin supprimé (ENOENT). La policy canonise toutes les racines au démarrage ; l’échec survient avant describe. Cette configuration n’a pas été modifiée, aucune racine n’a été élargie. La preuve live ci-dessus utilise un processus neuf sur une racine de fixture valide ; elle ne prétend pas avoir réparé cette connexion.

### Revues indépendantes et autocritique de livraison

| Passe | Résultat |
| --- | --- |
| Architecture | Réemploi des snapshots/coordinateur validé ; pas de moteur ou bus concurrent. |
| Mappings / implémentation déléguée | Chaîne core → runtime/UI → éditeur → export couverte. Un import direct editor → runtime introduit pendant la passe a été retiré ; la fixture partagée reste dans l’UI. |
| Audit de tests | Sélections par package, export, lifecycle et golden slice identifiées puis exécutées. |
| Revue de conformité | Deux réserves initiales : ordre Quêtes/Carte et Quêtes activable dans la preview. Corrigées et revues à nouveau : conforme, aucune réserve de spécification restante. |
| Revue de qualité | Réponses tardives après sac/réorganisation reproduites en rouge, garde ajoutée, suite verte. Relecture : réserve levée, aucun finding restant. |
| Revue du test MCP | Test stdio packagé relu favorablement ; aucun contournement par écriture directe du projet cible. |
| Build / validation | Compilation et analyses ciblées démontrées ; les limites PMCP globale/configuration et absence de verdict visuel sont explicites. |

Le lot fournit des contrats consommables et vérifiés ; il ne garantit pas encore la fidélité graphique à la maquette. Les données optionnelles absentes doivent rester absentes dans les futurs écrans. L’import de miniatures devra conserver une correspondance explicite des formes et protéger les références média existantes. Le verdict technique de MENU-A ne vaut ni certification globale des Items, ni validation visuelle du Player installé.

### État Git et hygiène de la livraison

Départ de l’implémentation : branche `main`, HEAD `9b997491d618d1527d3011f3ed1eb62495acc6c2`, huit fichiers suivis déjà modifiés, le présent rapport non suivi et quinze `.pyc` non suivis. Les huit fichiers étaient les deux services Hub, le main du host, `scene_execution_capabilities.dart`, son test, `playable_map_game.dart`, le fichier de session et le test d’intégration event-v2 (inventaire détaillé dans la section 9 historique).

Le travail concurrent a ensuite ajouté des modifications de `scenes_workspace.dart` et de son test, puis du `pubspec.yaml`/`pubspec.lock` du host et un `dev/marionette_main.dart` non suivi. Ces ajouts Marionette ne proviennent pas du lot MENU-A et sont préservés. Pendant la suite MCP, trois autres fichiers ont été modifiés hors lot : `tools/pokemap_mcp/src/config.ts`, `tools/pokemap_mcp/src/index.ts`, `tools/pokemap_mcp/test/config.test.ts`. Les résultats MCP sont rattachés au build exécuté au démarrage de la suite et ne certifient pas ces edits concurrents ultérieurs. Le fichier de session est partagé : seule la projection des trois arguments décrite plus haut appartient au lot.

`git diff --check` : **exit 0**, aucune sortie. `bash tools/scripts/check_markdown_hygiene.sh` : **exit 1**, exactement les deux lignes déjà consignées en section 9. Le seul Markdown nouveau par rapport à HEAD est toujours ce rapport d’audit explicitement demandé puis actualisé ; aucun nouveau Markdown d’implémentation ni override de budget n’est ajouté. Le rapport ne contient pas de marqueurs de conflit et ses blocs de code sont équilibrés.

Aucune opération Git d’écriture n’a été effectuée : pas de commit, indexation, rebase, changement de branche ou push. Le SHA désigne donc la base de travail, jamais un commit de livraison.

Relevé Git de livraison du 6 septembre 2026 à 00:57 UTC : **51 fichiers suivis modifiés, 19 fichiers non suivis, aucun fichier indexé**. Les 19 non suivis sont les deux nouveaux tests MENU-A, le rapport, le point d’entrée Marionette concurrent et les quinze `.pyc` initiaux. HEAD reste `9b997491d618d1527d3011f3ed1eb62495acc6c2` sur `main`. Ce relevé inclut les changements concurrents listés ci-dessus, sans les attribuer au lot.

La relecture indépendante du rapport est favorable après précision du schéma concerné (`ProjectPresentationProfile`) et correction de deux descriptions de fichiers. Les limites de preuve sont conservées.

### Décision de suivi

MENU-A / POST-UI-MENU-001 est livré pour revue utilisateur : **TO REVIEW**, readiness **Prêt réel**, verdict technique **PASS sur le périmètre MENU-A**. La validation utilisateur reste attendue ; aucun passage à DONE. Les limites du run MCP global, de la connexion configurée et de l’hygiène documentaire restent consignées. Le prochain lot prévu est **MENU-B / POST-UI-MENU-002**, primitives et thème visuel, à lancer sur demande de Yoahn. Aucun autre ticket ni statut bêta n’est modifié.

## 12. Validation finale et autorisation de commit — 6 septembre 2026

Yoahn a ensuite demandé de valider le lot **uniquement s’il est bon**, de corriger les défauts éventuels avant validation, et a explicitement autorisé le commit. Cette section remplace le statut d’attente de revue de la section 11. Elle ne change pas le périmètre de MENU-A.

### Décision

**PASS : les six critères de POST-UI-MENU-001 sont satisfaits.** La revue finale indépendante du diff actuel n’a identifié aucun défaut bloquant ; aucun correctif de production supplémentaire n’a été nécessaire. La validation demandée porte sur les contrats/mappings du lot 1. Les prochains écrans, l’import des miniatures et leur validation graphique restent dans leurs lots propriétaires.

| Critère du ticket | Preuve de validation |
| --- | --- |
| Chemin application → coordinateur → shell → détail tracé | Matrice et ancres de l’audit, confirmées par la revue du diff ; golden slice du host et runtime rejouées. |
| Source, propriétaire et absence de chaque champ | Matrice initiale complétée par les contrats et politiques d’absence de la section 11 ; données réelles, temps de session et absence de catalogues testés. |
| Quêtes/Profil typés ou dépendance explicite | Mappings core/runtime/UI/éditeur/export et transport MCP testés ; Quêtes désactivé sans journal, Profil alimenté par le snapshot courant. |
| Autorité des commandes et overrides conservée | Tests sac, réordonnancement, disponibilité et visibilité narrative rejoués ; aucune mutation déplacée dans le widget. |
| Mappings, disponibilités, lecture pure, réponses obsolètes testés | Sélection runtime et contrats, UI, core et authoring repassée ; refus des réponses après fermeture et nettoyage au titre couverts. |
| Rapport distinguant lu/modifié/exécuté | Sections historiques conservées, inventaire de 39 fichiers, résultats frais ci-dessous, limites globales toujours explicites. |

### Nouvelle exécution des preuves avant commit

Les **mêmes sept commandes de tests ciblés** intégralement consignées en section 11 ont été relancées, depuis leurs packages respectifs :

| Sélection | Nouvelle sortie finale | Code |
| --- | --- | --- |
| Runtime, 12 fichiers | `00:02 +91: All tests passed!` | 0 |
| UI, 7 fichiers | `00:05 +94: All tests passed!` | 0 |
| Éditeur, 5 fichiers | `00:10 +58: All tests passed!` | 0 |
| Host, golden slice | `00:00 +11: All tests passed!` | 0 |
| Core, 2 fichiers | `00:00 +27: All tests passed!` | 0 |
| Distribution, codec | `00:00 +36: All tests passed!` | 0 |
| Authoring, API/JSONL | `00:02 +20: All tests passed!` | 0 |

**337 tests ciblés repassés.** Nettoyage des harnesses après les runs Flutter, sans interruption de la passe MCP.

Les six commandes d’analyse de la section 11 ont également été relancées : runtime/UI/editor donnent `No issues found!` en 9,4 s / 5,8 s / 10,4 s ; distribution et authoring donnent `No issues found!` ; core conserve ses six informations préexistantes et aucune erreur ni warning. Toutes terminent avec exit 0. Aucune régénération supplémentaire n’est nécessaire puisque le code généré n’a pas changé depuis la livraison.

Preuves MCP fraîches depuis `tools/pokemap_mcp` :

```sh
npm run check
npm run build
node --import tsx --test test/live_menu_contracts.test.ts
node --import tsx --test --test-name-pattern='MCP persists a typed pause menu visibility consequence|CIN-033 certifies preSession and Presentation through live MCP' test/mutation_server.test.ts
```

Les quatre commandes terminent avec **exit 0** ; **1/1 puis 2/2 tests passés**, respectivement 8 874 ms et 20 506 ms. Log temporaire intégral : `/tmp/menu-a-final-mcp-validation.log`. Le test MENU-A a été relu contre les sources MCP de HEAD : il n’utilise pas l’option de timeout ajoutée concurremment ; les trois fichiers concurrents ne sont pas des dépendances du commit.

La suite npm globale précédente reste historiquement à 73/75, exit 1 ; elle n’a pas été relancée intégralement, les deux scénarios concernés ayant été rejoués en sélection ciblée sans reproduire de défaut. La certification globale Items sans receipts, le connecteur configuré et la preuve visuelle installée ne sont pas requalifiés par cette validation.

### Revues et contrôle du commit

- **Audit / Architecture et critique finale** : PASS indépendant sur les six critères, pas de dépendance au chantier cinéma, pas de donnée optionnelle inventée, pas de fuite d’identité des inconnus.
- **Implémentation** : contrôle du diff indexé ; aucun correctif supplémentaire requis. Les snapshots et mappings livrés restent inchangés.
- **Tests** : 337 cas ciblés repassés et 3 cas MCP passés dans cette validation.
- **Build / Validation** : compilations Flutter par les suites, analyses et build TypeScript frais ; limites de distribution et d’apparence conservées.
- **Critique du commit** : allowlist de 39 fichiers de code/tests, sans omission ni fichier inattendu. Dans la session partagée, seules huit lignes d’ajout MENU-A sont indexées ; les quatre ajouts cinématiques restent dans l’arbre de travail.

État Git initial de cette validation : `main`, HEAD `9b997491d618d1527d3011f3ed1eb62495acc6c2`, 51 fichiers suivis modifiés, 19 non suivis, index vide. Le commit ajoute à l’allowlist le présent rapport : **40 fichiers au total**. Les changements Hub/cinéma, host/Marionette, scènes auteur et timeout MCP restent exclus, de même que les quinze `.pyc` préexistants.

La préparation du patch partiel de session a d’abord été refusée comme patch mal formé (exit 128, dernière ligne de contexte tronquée). Aucune modification de l’index de session n’a été appliquée lors de ce refus ; le compte de lignes du patch temporaire a été corrigé, puis `git apply --cached --check` et `git apply --cached` ont réussi. Le fichier de travail n’a pas été réécrit.

`git diff --cached --check` et `git diff --check` terminent sans sortie, exit 0. Avant commit, le garde Markdown conserve son exit 1 pour l’unique rapport explicitement demandé au chemin canonique et le budget automatique zéro ; aucun override n’est utilisé. Ce signal documentaire ne révèle pas un défaut de contrat MENU-A et n’est pas présenté comme vert.

La validation et le commit sont autorisés par le dernier message de Yoahn. Le SHA du commit contenant cette section sera enregistré dans Notion, avec **DONE / Terminé / PASS** sur POST-UI-MENU-001 seulement. Aucune opération de push ou rebase n’est autorisée ni prévue.
