# Refonte de l’onglet Histoire — plan d’implémentation

**Objectif :** remplacer la présentation actuelle d’Histoire par l’espace Histoire de la maquette Avelune, en raccordant les écrans aux données et commandes réelles du Studio.

**Architecture :** conserver le shell du Studio, le brouillon narratif unique et les frontières de publication. Recomposer les vues, rendre les contextes de navigation explicites et ajouter les projections applicatives nécessaires aux catalogues ; réutiliser le graphe existant et les opérations des comportements.

**Technologies :** Dart, Flutter desktop, Riverpod, `avelune_design_system`, `map_core`, `map_authoring`, tests Flutter et QA macOS Release.

**Statut au 15 novembre 2026 :** plan uniquement, révisé pour intégrer le multilingue obligatoire des dialogues. Treize lots au total ; aucune implémentation commencée et aucune validation fonctionnelle exécutée pour cette livraison.

**Exécution prévue :** suivre les cases de chaque lot dans cette session, avec tests ciblés avant changement de comportement, puis vérification du résultat. Aucun sous-agent, commit, push ou changement de branche n’est autorisé par ce plan. Une éventuelle délégation ou livraison Git fera l’objet d’une instruction distincte.

**Règle actualisée avant passage de relais :** le commit `a0a6db611` impose la section « Native Studio verification » des politiques après chaque lot qui change un écran, une interaction, la sauvegarde, l’annulation ou l’ouverture du Studio. Cette règle prime sur les anciens points de contrôle espacés du plan et sur le prompt historique de Claude. Le premier lot confié à la nouvelle session est H0, premier dans l’ordre du tableau ; la création de ce chat est explicitement demandée par Yoahn et n’autorise aucune opération Git.

## 1. Référence et périmètre retenus

La référence est [la maquette Avelune complète](https://designs.magicpath.ai/v1/finely-dusk-9230), puis l’entrée **Histoire**, icône livre dans le rail. Ce lien démarre sur Carte ; il contient aussi l’espace Histoire.

Révision inspectée : composant `470322378581372928`, révision `472787618355089408`, projet MagicPath `470322374529675264`. La proposition séparée `quietly-stone-2857` ne sert pas de référence pour ce chantier.

La hiérarchie, les surfaces bleu sombre, la densité, les sélections, la navigation et l’inspecteur de la bonne maquette guident l’implémentation. Ses données d’exemple, boutons illustratifs et textes de statut ne définissent pas des capacités du moteur.

### Écrans livrés

| Entrée | Résultat attendu |
|---|---|
| Trame | Histoires, chapitres, jalons, conditions prises en charge, scènes liées, journal et indices. |
| Comportements | Catalogue intercartes et fiche éditable, cas ordonnés, réponse simple ou scène, simulation et accès à Carte. |
| Scènes | Catalogue indépendant des porteurs, filtres de classement, usages connus, aperçu à la demande et ouverture du graphe existant. |
| Dialogues | Accès contextuel aux textes et édition de leurs variantes linguistiques, partagée avec les répliques simples et les dialogues des scènes. |
| Faits | Liste, recherche, fiche, création et modification déjà permises, usages distinguant lectures et écritures. |
| Règles du monde | Liste et édition des règles déjà prises en charge, cibles explicites et accès aux sources. |
| Vérification | Analyse globale enregistrée à la demande, couverture, fraîcheur, gravités réelles et navigation vers les objets. |

### Hors périmètre de cette livraison

- Cinématiques : ni catalogue dédié, ni restauration des anciens éditeurs, ni nouvelle timeline. Leur entrée n’apparaît pas dans la navigation Histoire de ce chantier. Les étapes et références existantes continuent de passer par leurs chemins actuels.
- Réécriture complète de l’éditeur de structure des dialogues, traduction automatique et traduction manuelle de tout le contenu existant. Le support des variantes linguistiques et leur identité durable font en revanche partie de cette livraison.
- Reconstruction du graphe de scènes, palette en neuf familles et nouveaux types d’étapes.
- Changement de sémantique de progression du journal, des conditions ou des rattachements de scènes. Aucune rupture du format des sauvegardes Player n’est prévue pour ajouter la sélection des textes localisés.
- Nouvel outil de remplacement global, migration de projet, réorganisation générale du Studio ou du moteur.
- Import des données fictives de MagicPath dans un projet réel.

Le multilingue demandé concerne les textes du jeu, indépendamment de la langue de l’interface Studio : répliques simples, narration et libellés de choix. Les langues prises en charge par le projet, sa langue de référence et le repli sont explicites. Changer la langue affichée ne change ni les faits, ni l’ordre des cas, ni les identifiants de résultats de choix.

L’entrée Dialogues conserve ses accès contextuels, mais n’est plus une simple page de renvoi : l’édition des variantes doit être possible depuis les champs partagés des comportements et des scènes. Aucun nouveau langage de script n’est demandé au créateur.

## 2. Décisions qui encadrent l’implémentation

| Sujet | Décision retenue pour cette refonte |
|---|---|
| Projet sans trame | Afficher un état vide et proposer une création explicite. Ne rien déduire automatiquement des cartes. |
| Types d’histoires | Permettre principale et secondaire par les commandes existantes ; conserver et rendre accessibles les autres types déjà présents. Ne pas ajouter une contrainte d’unicité des principales. |
| Ordre des chapitres et jalons | Conserver la sémantique actuelle : cet ordre influe sur le jalon présenté comme en cours dans le journal. Il ne déclenche pas automatiquement les scènes. |
| Conditions des chapitres | Ne pas proposer de conditions persistées à un niveau que `StorylineChapter` ne porte pas. |
| Conditions des jalons | Afficher fidèlement les conditions déclarées. Ajouter une édition guidée des formes simples par les opérations existantes ; conserver les formes complexes sans perte. |
| Conditions ET / OU | Le moteur connaît les deux. L’éditeur simple reste limité aux formes qu’il sait représenter ; les expressions complexes sont conservées et signalées comme telles. |
| Visibilité du journal | Préserver la règle actuelle, y compris le fait qu’une condition d’entrée ne masque pas automatiquement le jalon en cours. Ne pas afficher « quête verrouillée » sur cette seule base. |
| Lien scène / jalon | Conserver la commande actuelle qui déplace le rattachement entre jalons. Si une scène est déjà liée ailleurs, afficher l’origine et obtenir une confirmation de déplacement avant mutation. |
| Liens multiples déjà enregistrés | Les lire et les afficher tous quand les contrats les portent. Ne pas normaliser les données ni supprimer des rattachements à la lecture. |
| Partage d’une scène | Distinguer usages par plusieurs comportements et classement dans la trame. Présenter les deux sans les confondre. |
| Sauvegarde | Un seul brouillon et un seul Enregistrer pour Carte et Histoire. L’échec conserve les données en mémoire et les originaux sur disque. |
| Annuler / refaire | Utiliser l’historique existant et sa prochaine transaction. Ne pas sauter une transaction appartenant à un autre objet pour en annuler une plus ancienne. |
| Vérification | Globale sur la version enregistrée ; locale dans le graphe ouvert. Aucune analyse globale déclenchée par sélection, frappe, modification ou sauvegarde. |
| Gravités | Conserver celles du moteur. Une sortie obligatoire non reliée n’est pas promue artificiellement en erreur. |
| Suppression | Activer seulement une opération réellement supportée et sûre. Les faits existants restent protégés si la publication ne permet pas leur suppression. |
| Compatibilité | Les contrats de localisation nécessaires sont définis dans D1, avec lecture compatible des anciens projets et jeux, versionnement explicite et préservation des originaux. Aucun format n’est modifié simplement pour refaire l’interface ; aucune rupture des sauvegardes Player n’est prévue. |
| Diagnostics éditoriaux | Réutiliser les contrôles existants, avec un libellé distinct ; ne pas lancer une nouvelle analyse de jouabilité ou de contradictions. |

Les corrections du journal et des gravités sont des écarts assumés avec les textes illustratifs de la maquette. Les cinématiques sont exclues par décision explicite de Yoahn.

## 3. Point de départ vérifié et propriétaires du code

Racine de tous les chemins ci-dessous : `/Users/karim/Project/pokemonProject`.

État initial : branche `main`, commit `688708ef4` — `Format Studio sources and exclude build output`. `git status --short --untracked-files=all` était vide au début de la préparation du plan. Cet état doit être relu avant toute implémentation, le dépôt étant partagé avec d’autres sessions.

| Responsabilité | Sources à réutiliser |
|---|---|
| Cadre global et sauvegarde | `apps/avelune_studio/lib/presentation/features/map_builder/map_builder_page_layout.dart`, `map_builder_header.dart`. |
| Entrée Histoire | `apps/avelune_studio/lib/presentation/features/story/story_page.dart`, `story_page_navigation.dart`. |
| Navigation vers Carte et scène | `apps/avelune_studio/lib/presentation/features/map_builder/map_builder_page_story.dart`, `map_builder_page_scene.dart`. |
| Trame | `apps/avelune_studio/lib/features/storyline/application/storyline_trame_controller.dart`, `storyline_trame_edits.dart`, `storyline_trame_view.dart`. |
| Journal et indices | `apps/avelune_studio/lib/features/storyline/application/storyline_journal_edits.dart`, présentation `trame_journal.dart` et `trame_clues.dart`. |
| Catalogue des comportements | `apps/avelune_studio/lib/features/game_behaviours/application/game_behaviours_controller.dart`, `game_behaviour_rows.dart`, `game_behaviour_groups.dart`, `game_behaviour_summary.dart`. |
| Opérations des comportements | `apps/avelune_studio/lib/features/events/application/behaviour/` et `apps/avelune_studio/lib/features/map_workspace/application/map_story_behaviours.dart`. |
| Coordination actuelle de l’édition | `apps/avelune_studio/lib/presentation/features/map_builder/map_builder_story_binding.dart` et ses fichiers `part`. |
| Brouillon et transactions | `apps/avelune_studio/lib/features/story_draft/application/story_draft.dart`, `story_draft_history.dart`, `story_publication_gateway.dart`. |
| Index narratif | `apps/avelune_studio/lib/features/game_memory/domain/narrative_index_port.dart` et son adaptateur `data/local_narrative_index_adapter.dart`. |
| Documents de scènes | `apps/avelune_studio/lib/features/scenes/domain/scene_document.dart`, `features/scenes/application/scene_focus_controller.dart`. |
| Graphe et miniature | `apps/avelune_studio/lib/presentation/features/scene_focus/`, notamment `graph/scene_graph_preview.dart`. |
| Faits et règles | `apps/avelune_studio/lib/features/game_memory/application/game_memory_controller.dart`, `game_memory_rules.dart`. |
| Vérification | `apps/avelune_studio/lib/features/verification/application/project_verification_controller.dart`, `verification_problems.dart`, et le port de vérification. |
| Traductions | `apps/avelune_studio/lib/l10n/app_fr.arb`, `app_en.arb`, puis `flutter gen-l10n`. |

### Manques applicatifs identifiés

1. L’édition des comportements utilise encore implicitement `maps.active.current`. Ce contexte doit devenir explicite pour éditer depuis Histoire sans changer silencieusement la carte active.
2. `StorylineOutline` décrit les jalons mais n’expose pas toutes les relations structurées de la trame. Le classement exhaustif du catalogue de scènes doit aussi lire les métadonnées de trame par le port existant.
3. `StorylineTrameView.milestoneOfScene` fournit un résultat unique. Ce raccourci ne suffit pas pour afficher tous les rattachements existants.
4. Les usages d’un fait proviennent d’un index enregistré. Leur présentation doit intégrer les changements locaux pertinents, ou annoncer explicitement que leur couverture du brouillon est incomplète.
5. La navigation d’un diagnostic de scène passe actuellement par un comportement. Il faut une ouverture directe des scènes sans porteur.
6. `VerificationProblem` ne transporte pas une identité précise d’étape de graphe. `stepId` n’est pas un substitut générique à `nodeId` : on ne doit pas centrer un bloc en inventant une correspondance.
7. Les lectures de titres sont paginées côté authoring mais l’adaptateur actuel les agrège en liste. Une ouverture de catalogue peut lire ses titres ; chaque modification locale doit rester indépendante de cette lecture complète.

## 4. Organisation des fichiers à créer

Les chemins indiqués comme « nouveaux » sont des propositions d’implémentation, pas des API déjà présentes. Chaque fichier porte une responsabilité ; cible de 300 lignes, plafond de 350 lignes pour Dart manuel et tests.

| Nouveaux fichiers | Responsabilité |
|---|---|
| `apps/avelune_studio/lib/features/story_workspace/application/story_workspace_state.dart` | Section, sélection par section, requêtes, filtres et contexte de retour sous forme de données pures. |
| `apps/avelune_studio/lib/features/story_workspace/application/story_history_scope.dart` | Décider si la prochaine transaction appartient au contexte édité, sans créer un second historique. |
| `apps/avelune_studio/lib/presentation/features/story/story_workspace.dart` | Composition navigation / contenu / inspecteur. |
| `apps/avelune_studio/lib/presentation/features/story/story_navigation.dart` | Navigation secondaire et compteur de vérification. |
| `apps/avelune_studio/lib/presentation/features/story/story_inspector.dart` | Cadre d’inspecteur partagé, états vide / chargement / indisponible. |
| `apps/avelune_studio/lib/presentation/features/story/story_breadcrumb.dart` | Fil d’Ariane lié au contexte réel. |
| `apps/avelune_studio/lib/presentation/features/story/trame_chapter_list.dart` | Sélection des chapitres et actions d’ordre. |
| `apps/avelune_studio/lib/presentation/features/story/trame_milestone_list.dart` | Liste des jalons du chapitre choisi. |
| `apps/avelune_studio/lib/presentation/features/story/trame_conditions.dart` | Affichage et édition guidée des conditions de jalon prises en charge. |
| `apps/avelune_studio/lib/features/scenes/application/scene_catalog_controller.dart` | Chargement, sélection, cache et invalidations du catalogue. |
| `apps/avelune_studio/lib/features/scenes/application/scene_catalog_rows.dart` | Projection des titres enregistrés et des scènes du brouillon. |
| `apps/avelune_studio/lib/features/scenes/application/scene_catalog_memberships.dart` | Relations scène / histoire / chapitre / jalon, sans singulariser les usages. |
| `apps/avelune_studio/lib/presentation/features/story/scenes/scene_catalog_view.dart` | Liste virtualisée et filtres de scènes. |
| `apps/avelune_studio/lib/presentation/features/story/scenes/scene_catalog_inspector.dart` | Fiche, rattachements et ouverture du graphe. |
| `apps/avelune_studio/lib/features/game_behaviours/application/game_behaviour_editing.dart` | Exécution partagée des opérations sur un contexte carte explicite, avec transaction et refus structurés. |
| `apps/avelune_studio/lib/presentation/features/map_builder/map_builder_story_catalog_binding.dart` | Préparation ciblée du contexte d’édition Histoire, via les dépendances injectées existantes. |
| `apps/avelune_studio/lib/presentation/features/story/behaviours/game_behaviour_inspector.dart` | Sélection du cas, déclencheur, conditions, réponse, conséquences et actions. |
| `apps/avelune_studio/lib/presentation/features/story/behaviours/game_behaviour_cases.dart` | Présentation et déplacement des cas ordonnés. |
| `apps/avelune_studio/lib/presentation/features/story/behaviours/game_behaviour_response.dart` | Réplique simple, partage de texte et accès à une scène. |
| `apps/avelune_studio/lib/presentation/features/story/behaviours/game_behaviour_simulation.dart` | Simulation depuis Histoire, sans bascule vers Carte. |
| `apps/avelune_studio/lib/features/game_memory/application/game_memory_draft_usages.dart` | Ajuster les usages pour les objets narratifs modifiés localement et conserver la couverture connue. |
| `apps/avelune_studio/lib/presentation/features/story/dialogues/story_dialogues_view.dart` | Renvois contextuels, sans deuxième document éditable. |
| `apps/avelune_studio/lib/features/verification/application/verification_snapshot.dart` | Révision analysée, couverture et fraîcheur du dernier résultat global. |

Les widgets actuels de faits, règles, journal, conditions et répliques sont adaptés ou extraits avant de créer un doublon. Les composants génériques manquants appartiennent à `packages/avelune_design_system`, pas à une nouvelle bibliothèque privée de widgets Histoire.

## 5. Séquence et dépendances

| Lot | Contenu | Prérequis | Point de contrôle visible |
|---|---|---|---|
| H0 | Référence, contrats et baseline | Aucun | Matrice des écarts confirmée. |
| D1 | Contrats multilingues et compatibilité | H0 | Identité durable des textes, langues et repli définis et testés. |
| H1 | Structure visuelle et navigation secondaire | H0 | Tous les écrans sont accessibles dans le nouveau cadre. |
| H2 | Continuité, brouillon et portée d’historique | H1 | Aller-retour sans perte et annulation sûre. |
| H3 | Trame, journal et indices | H2, D1 | Création et édition complète d’une trame simple, avec conservation de la localisation existante. |
| H4 | Catalogue des scènes et usages | H2, H3 | Scènes avec ou sans porteur, classement fiable. |
| H5 | Contexte explicite des comportements | H2, D1 | Même opération depuis Carte et Histoire. |
| D2 | Édition multilingue des textes | D1, H2, H5 | Langue de saisie, variantes, repli et traductions périmées visibles dans les champs partagés. |
| H6 | Interface des comportements | H4, H5, D2 | Réplique conditionnelle et scène éditables sans quitter Histoire. |
| H7 | Faits, règles et usages | H3, H6 | Dépendances lisibles dans le brouillon. |
| D3 | Export et lecture multilingue Player | D1, D2, H3, H6 | Textes et choix localisés effectivement lus dans les jeux exportés. |
| H9 | Vérification et destinations | H4, H6, H7 | Analyse honnête et accès aux objets en erreur. |
| H10 | Parcours complets, performance et retrait de l’ancien rendu | H1–H7, H9, D1–D3 | Acceptation finale du périmètre. |

H5 et H7 sont séparés des lots visuels parce qu’ils touchent des invariants de cohérence. Aucun développement parallèle dans les mêmes fichiers n’est prévu.

Le lot H8 de la première version du plan est remplacé par D1, D2 et D3 : onze lots moins un, plus trois, soit treize. D1 intervient avant de figer les champs d’édition des textes ; les travaux d’interface ne doivent pas installer un second modèle monolingue à migrer ensuite.

## 6. H0 — fixer la référence et caractériser le comportement existant

**Fichiers existants à relire :** `AGENTS.md`, les sections déclenchées de `documentation/architecture/product_and_architecture_policies.md`, les propriétaires de la section 3 et les tests ci-dessous.

- [ ] Relever le statut Git, la branche et le commit immédiatement avant l’implémentation ; identifier toute modification concurrente.
- [ ] Reconfirmer la révision MagicPath et les sept entrées retenues. Ne créer ni troisième maquette ni données réelles de trame pour remplir un écran vide.
- [ ] Exécuter les tests existants du journal, des rattachements et des conditions ; ajouter une caractérisation seulement si le cas concerné n’est pas déjà couvert.
- [ ] Caractériser le maintien des expressions complexes après modification d’un autre champ, le déplacement d’un rattachement et l’ordre consommé par le journal.
- [ ] Établir la baseline d’architecture réelle. Les deux échecs historiques cités par Claude ne sont pas une dérogation et ne sont pas supposés encore présents.
- [ ] Relever les lectures nécessaires à l’ouverture de chaque écran et séparer préparation initiale, sélection d’un objet et modification locale.

**Commandes ciblées :**

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/player_journal_projection_test.dart test/storyline_step_scene_link_ids_meaning_test.dart test/storyline_milestone_scene_operations_test.dart
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/presentation/map_builder_story_conditions_test.dart test/narrative/narrative_history_guard_test.dart
flutter test --no-pub test/architecture -r failures-only
```

**Sortie du lot :** les hypothèses du plan sont reliées à des comportements caractérisés. Tout échec est nommé et relancé seul ; aucun résultat rouge n’est assimilé à une validation.

## 7. H1 — installer le nouvel espace Histoire

**Modifier :** `presentation/features/story/story_page.dart`, `map_builder/map_builder_page_story.dart`, les deux fichiers ARB. Créer les quatre widgets de structure de la section 4 et `story_workspace_state.dart`.

- [ ] Conserver le rail et la barre supérieure existants ; remplacer la barre de quatre onglets par la navigation secondaire à sept entrées.
- [ ] Réutiliser `StudioSidebar`, `StudioNavigationEntry`, `StudioPageHeader`, les boutons, badges, champs et états du design system. Étendre une primitive seulement lorsqu’une variante manque réellement.
- [ ] Installer un contenu central extensible et un inspecteur à droite. Une seule surface possède le défilement principal de chaque liste ; l’inspecteur conserve son défilement propre.
- [ ] Utiliser des panneaux de navigation et d’inspection d’environ 240 et 320 pixels au format bureau, puis ajuster avec les tokens et contraintes existants. Tester à 1280×800, 1440×900 et 1920×1080 ; à largeur réduite, rendre l’inspecteur repliable sans masquer ses commandes.
- [ ] Monter les contrôleurs à la demande. Une visite de Trame ne doit pas lire tous les documents de scène, charger les dialogues ou lancer la vérification.
- [ ] Brancher provisoirement les vues existantes dans le nouveau cadre pour conserver un parcours utilisable pendant la progression des lots.
- [ ] Ajouter les états communs : sélection absente, vide réel, aucun résultat, chargement, erreur avec Réessayer et consultation seule.
- [ ] Traduire les nouveaux textes en FR/EN et générer les localisations par la commande officielle.

**Nouveaux tests :** `test/presentation/story_workspace_layout_test.dart`, `test/story_workspace/story_workspace_state_test.dart`.

**Cas à prouver :** navigation clavier vers les sept entrées ; absence de Cinématiques ; aucun débordement aux trois tailles ; focus visible ; chargement paresseux ; lecture seule sans mutation ; changement de langue sans clé manquante ; état vide sans création de données.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter gen-l10n
flutter test --no-pub test/presentation/story_workspace_layout_test.dart test/story_workspace/story_workspace_state_test.dart test/presentation/story_memory_states_test.dart
flutter analyze --no-pub
```

**Sortie du lot :** captures natives du cadre et de ses états principaux ; toutes les entrées retenues sont accessibles. La présence d’un écran ne vaut pas validation de ses futures commandes.

## 8. H2 — préserver le contexte, le brouillon et l’historique

**Modifier :** `story_page_navigation.dart`, `map_builder_page_story.dart`, `map_builder_page_scene.dart`, `map_builder_header.dart`, `map_builder_story_history.dart`, et l’état applicatif Histoire. Créer `story_history_scope.dart`.

- [ ] Conserver séparément pour chaque section la sélection stable, la requête, les filtres, le regroupement et la position de liste. Les offsets et contrôleurs de défilement restent en présentation ; les identifiants et filtres sont des données pures.
- [ ] Transporter un contexte d’origine lors des ouvertures Carte et scène. Un retour depuis une scène puis depuis une carte doit rétablir l’histoire, le chapitre, le jalon et la liste d’origine, sans reconstruire une sélection arbitraire.
- [ ] Avant de quitter un champ, terminer sa transaction de saisie selon les conventions actuelles. Ne pas perdre un texte parce que le champ change de propriétaire.
- [ ] Pour plusieurs porteurs, proposer la liste des usages et laisser choisir la destination. Ne pas sélectionner silencieusement le premier comportement.
- [ ] Si la destination disparaît pendant le chargement ou dans une autre session, conserver le brouillon, annoncer l’indisponibilité et revenir au parent connu.
- [ ] Définir une portée d’annulation à partir des références de la sélection et de ses dépendances réellement modifiées. Interroger `StoryDraft.nextStep`, puis autoriser seulement une transaction entièrement incluse dans cette portée.
- [ ] Conserver une transaction composite entière : création d’un fait + condition, réplique + source de dialogue, déplacement de rattachement entre deux trames. Ne jamais annuler seulement une partie du groupe.
- [ ] Utiliser les mêmes décisions pour les boutons et Cmd/Ctrl+Z. Si la prochaine transaction concerne un autre contexte, désactiver l’action avec une explication ; ne pas parcourir l’historique pour la contourner.
- [ ] Vérifier qu’Enregistrer utilise toujours le brouillon global actuel, avec le même état d’erreur, et qu’un échec n’efface ni saisie ni sélection.

**Nouveaux tests :** `test/presentation/story_workspace_navigation_test.dart`, `test/story_workspace/story_history_scope_test.dart`.

**Cas à prouver :** retour avec filtres et défilement ; navigation imbriquée ; cible supprimée ; changement rapide de cible ; annulation sur la bonne scène ; transaction d’un autre objet refusée ; groupe composite entièrement restauré ; nouvelle session de projet sans ancien contexte.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/presentation/story_workspace_navigation_test.dart test/story_workspace/story_history_scope_test.dart test/presentation/map_builder_story_history_test.dart test/presentation/map_builder_story_draft_test.dart test/narrative/narrative_publication_test.dart
```

**Sortie du lot :** un aller-retour ne provoque aucune perte de saisie et aucune annulation invisible sur un autre objet. La sauvegarde reste commune.

## 9. H3 — reconstruire la Trame et exposer le journal existant

**Modifier :** `trame_view.dart`, `trame_detail.dart`, `trame_milestone_detail.dart`, `trame_start.dart`, `trame_journal.dart`, `trame_clues.dart`, `trame_outside.dart`, les contrôleurs et éditions de `features/storyline/application/`.

**Créer :** listes de chapitres et jalons, `trame_conditions.dart`. Conserver `TrameSelection` ou le migrer dans l’état Histoire sans double source de sélection.

- [ ] Présenter l’histoire choisie, ses chapitres, les jalons du chapitre sélectionné et leur fiche dans l’inspecteur. Proposer un sélecteur si plusieurs histoires principales ou d’autres types existent déjà.
- [ ] Dans un projet vide, proposer « Créer une histoire » avec nom, type et premier chapitre explicites. Réutiliser `startStoryline` ; ne pas créer un objet caché lors de l’ouverture.
- [ ] Raccorder créer, renommer, réordonner et archiver aux méthodes existantes. Conserver les éléments archivés accessibles par filtre et préserver leurs références.
- [ ] Afficher les conditions au niveau du jalon. Pour une forme simple prise en charge, construire une condition par les opérations canoniques existantes ; pour une forme complexe, afficher une synthèse fidèle et conserver son expression intacte.
- [ ] Expliquer que les liens organisent la trame et que les comportements exécutés déclenchent les scènes. Ne pas présenter la condition d’entrée comme une garantie de verrouillage du journal ou du jeu.
- [ ] Lier une scène par sélection guidée. Si l’action déplace un lien existant, annoncer les jalons concernés avant d’appliquer la transaction ; Annuler restaure les deux côtés.
- [ ] Réutiliser l’édition du texte du journal et des indices, avec aperçu du texte enregistré dans le brouillon. Conserver les traductions existantes lorsque le texte de repli est modifié.
- [ ] Afficher les éléments hors trame sans trame inventée. Les anomalies éditoriales existantes restent distinctes d’un blocage moteur.
- [ ] Conserver une lecture limitée aux métadonnées narratives nécessaires ; aucune carte ne doit être décodée pour renommer un chapitre ou écrire le journal.

**Adapter les tests existants :** `test/storyline/storyline_trame_page_test.dart`, `storyline_trame_controller_test.dart`, `storyline_trame_catalog_test.dart`, `storyline_journal_page_test.dart`, `storyline_journal_edits_test.dart`, `storyline_journal_catalog_test.dart`.

**Nouveaux tests :** `test/storyline/storyline_workspace_conditions_test.dart`, `test/storyline/storyline_link_move_confirmation_test.dart`.

**Cas à prouver :** projet sans histoire ; plusieurs types conservés ; création et réouverture ; déplacement de chapitre et jalon ; journal et indices préservés après sauvegarde ; condition complexe inchangée après renommage ; déplacement de lien annulable ; refus sans modification ; zéro lecture de carte pour une édition de métadonnée.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/storyline -r failures-only
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/player_journal_projection_test.dart test/player_journal_storyline_json_test.dart test/storyline_step_scene_link_ids_meaning_test.dart
```

**Sortie du lot :** créer une trame, écrire un journal, lier une scène, enregistrer et rouvrir fonctionne par les vrais adaptateurs. Capture native du projet vide et d’une histoire remplie.

## 10. H4 — construire le catalogue des scènes

**Créer :** les trois fichiers applicatifs du catalogue et les deux vues `story/scenes/` indiqués dans la section 4.

**Réutiliser :** `NarrativeIndexPort.titles`, `sceneDocument`, `StorylineReadPort.storylines`, `StoryDraft`, `SceneFocusController`, `SceneFocusPage` et `SceneGraphPreview`.

- [ ] Construire la liste avec les titres enregistrés et le delta du brouillon : ajouts visibles, renommages immédiats et suppressions locales explicites. Un manifeste partiel n’est jamais la seule source d’existence.
- [ ] Lire les métadonnées de trame à l’ouverture du catalogue et mettre en cache les relations. Distinguer les `sceneLinkIds` de jalon qui désignent des scènes des identifiants de `StorylineSceneLink` structurés ; résoudre les liens directs de chapitre par leur contrat propre.
- [ ] Projeter tous les rattachements connus dans une relation un-vers-plusieurs. Un lien cassé doit apparaître comme cassé, et non comme absence de rattachement.
- [ ] Ajouter recherche, histoire/quête, chapitre, Sans chapitre et Hors trame. Sans chapitre est évalué dans le périmètre des histoires sélectionnées ; un filtre ne crée aucune nouvelle forme de rattachement dans les données.
- [ ] Dédupliquer les scènes dans la liste. Le détail peut présenter plusieurs rattachements sans dupliquer les données sources.
- [ ] Charger `SceneDocument` seulement pour la sélection ou l’aperçu effectivement visible. Ne pas ouvrir 443 documents pour afficher 443 titres.
- [ ] Limiter les miniatures aux éléments visibles, avec cache par scène et version, invalidation de la seule scène modifiée et annulation des résultats devenus obsolètes.
- [ ] Afficher les comportements connus, leurs lieux et les rattachements à la trame en précisant les limites de couverture. Une scène sans porteur reste ouvrable.
- [ ] Ouvrir le graphe existant dans le même shell, avec contexte de retour. Conserver son avertissement de partage et la copie indépendante déjà proposée pour un comportement.
- [ ] Garder la création de scène dans les parcours existants de comportement. La maquette retenue ne nécessite pas d’ajouter une création autonome de scène orpheline.

**Nouveaux tests :** `test/scenes/scene_catalog_controller_test.dart`, `scene_catalog_memberships_test.dart`, `scene_catalog_work_counts_test.dart`, `test/presentation/story_scene_catalog_test.dart`.

**Cas à prouver :** scène hors carte ; scène seulement dans le brouillon ; manifeste partiel ; lien direct de chapitre ; rattachements multiples enregistrés ; références cassées ; filtres combinés ; sélection disparue ; aucune carte lue pour la liste ; une scène chargée pour sa fiche ; aucune relecture des autres scènes après renommage.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/scenes/scene_catalog_controller_test.dart test/scenes/scene_catalog_memberships_test.dart test/scenes/scene_catalog_work_counts_test.dart test/presentation/story_scene_catalog_test.dart test/scenes/scene_focus_catalog_test.dart test/presentation/map_builder_story_graph_preview_test.dart
```

**Sortie du lot :** trouver et ouvrir toute scène connue sans passer par une carte ; aucun faux « introuvable » lié au manifeste partiel.

## 11. H5 — rendre le contexte d’édition des comportements explicite

**Modifier :** `map_builder_story_behaviour_editing.dart`, `map_builder_story_conditions_binding.dart`, `map_builder_story_cases_binding.dart`, `map_builder_story_line_binding.dart`, `map_builder_story_simulation_binding.dart` et les points de composition nécessaires.

**Créer :** `features/game_behaviours/application/game_behaviour_editing.dart`, `presentation/features/map_builder/map_builder_story_catalog_binding.dart`.

- [ ] Extraire le noyau transactionnel commun de l’édition vers une fonction ou un objet applicatif pur recevant explicitement projet, carte de contexte et brouillon partagé. Conserver la sémantique de refus, regroupement, désactivation/réactivation et rollback du chemin actuel.
- [ ] Garder les opérations pures existantes de `features/events/application/behaviour/`. Ne pas réimplémenter le calcul des cas, des conditions, de « Après » ou des répliques dans le nouvel inspecteur.
- [ ] Faire appeler ce noyau par Carte avant de brancher Histoire, puis prouver que les parcours Carte existants restent identiques.
- [ ] Pour Histoire, préparer l’atelier narratif et résoudre le porteur sélectionné. Réutiliser `WorldMapSelectionPort.loadMap` pour la seule carte nécessaire ; si cette carte est déjà éditée en mémoire, utiliser sa version courante.
- [ ] Ne pas appeler `_maps.activate` pour rendre la fiche éditable. L’onglet Carte conserve sa carte active, sa sélection et sa caméra tant que l’utilisateur ne demande pas « Voir sur la carte ».
- [ ] Charger uniquement les scènes, faits et sources de dialogue requis par le comportement et ses dépendances ; appliquer leur delta au même `StoryDraft`.
- [ ] Faire rejeter les mutations d’un porteur absent, d’un contexte incomplet ou d’une révision devenue obsolète. Une lecture échouée ne crée pas de comportement de remplacement.
- [ ] Éviter les mutations de porteur dans la fiche d’un comportement hors carte ou cassé ; y proposer les chemins de réparation déjà disponibles et les limites réelles.
- [ ] Brancher la simulation sur le même contexte explicite, avec valeurs temporaires et aucune écriture de faits.

**Nouveaux tests :** `test/game_behaviours/game_behaviour_editing_test.dart`, `game_behaviour_cross_map_test.dart`, `game_behaviour_edit_work_counts_test.dart`.

**Cas à prouver :** même résultat depuis Carte et Histoire ; modification sur carte B alors que Carte affiche A ; version non enregistrée de B utilisée ; refus et rollback atomique ; porteur disparu ; modification rapide A/B sans résultat tardif appliqué au mauvais objet ; une carte pertinente lue et aucune autre ; aucun enregistrement ou export automatique.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/game_behaviours/game_behaviour_editing_test.dart test/game_behaviours/game_behaviour_cross_map_test.dart test/game_behaviours/game_behaviour_edit_work_counts_test.dart test/presentation/map_builder_story_authoring_test.dart test/presentation/map_builder_story_cases_test.dart test/presentation/map_builder_story_conditions_test.dart test/presentation/map_builder_story_line_test.dart
```

**Sortie du lot :** Histoire et Carte partagent les mêmes opérations sans couplage implicite à la carte affichée. Aucune nouvelle dépendance Flutter, filesystem ou adaptateur dans l’application ou le domaine.

## 12. H6 — livrer le catalogue et l’inspecteur des comportements

**Modifier :** `game_behaviours_view.dart`, `game_behaviour_row.dart`, `features/game_behaviours/application/game_behaviours_controller.dart`, `game_behaviour_rows.dart`, `game_behaviour_groups.dart`.

**Créer :** les quatre widgets `story/behaviours/` de la section 4. Extraire les champs déjà présents dans `map_builder_story_*` quand une même interaction doit servir aux deux écrans.

- [ ] Présenter porteur, carte, déclencheur, résumé de réponse, nombre de cas, état et modification locale. Nommer « non chargé » distinctement de « hors carte » ou « supprimé ailleurs ».
- [ ] Conserver la recherche existante et ajouter les filtres carte, personnage, fait et chapitre à partir des index réellement disponibles. Ne pas annoncer une recherche plein texte des dialogues si aucun index ne la fournit.
- [ ] Conserver les regroupements carte, personnage et fait, puis ajouter chapitre avec les relations de H4. Une scène partagée peut faire apparaître un comportement dans plusieurs groupes sans dupliquer sa source.
- [ ] Sélectionner une ligne ouvre la fiche dans l’inspecteur, sans navigation automatique vers Carte.
- [ ] Présenter les cas dans l’ordre exécuté, avec « Le premier cas valable est joué ». Raccorder ajouter, modifier et déplacer aux fonctions pures existantes ; conserver les conditions complexes en lecture fidèle.
- [ ] Pour une réplique simple, éditer le texte directement. Pour un texte partagé, afficher l’impact et conserver la possibilité de copie indépendante existante. Un document Yarn non représentable par la saisie simple ne doit pas être réécrit.
- [ ] Pour une réponse par scène, ouvrir le graphe existant. Raccorder déclencheur, activation et « Après » aux commandes déjà prises en charge et à leurs refus réels.
- [ ] Simuler les conditions dans Histoire, avec valeurs temporaires et résultat contextualisé. Ne pas présenter cette simulation comme une partie jouée.
- [ ] Ajouter « Voir sur la carte » avec choix du bon porteur et retour à la fiche. Création d’un nouveau porteur et placement restent dans Carte · Scénario.

**Nouveaux tests :** `test/presentation/story_behaviour_inspector_test.dart`, `story_behaviour_simulation_test.dart`.

**Adapter :** `test/game_behaviours/`, `test/presentation/story_world_page_test.dart`, `map_builder_story_line_widget_test.dart`, `map_builder_story_line_catalog_test.dart`.

**Cas à prouver :** phrase simple sans écran de graphe ; cas conditionnel avant défaut ; ordre modifié puis annulé ; expression complexe conservée ; texte partagé protégé ; simulation sans mutation ; chargement de fiche en erreur puis réessai ; filtre sur fait du brouillon ; navigation retour sans perte.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/game_behaviours test/presentation/story_behaviour_inspector_test.dart test/presentation/story_behaviour_simulation_test.dart test/presentation/map_builder_story_line_widget_test.dart test/presentation/map_builder_story_line_catalog_test.dart -r failures-only
```

**Sortie du lot :** écrire une réplique conditionnelle sur trois cartes sans quitter Histoire, puis enregistrer et rouvrir avec les mêmes données. Capture native du catalogue, d’un cas et de sa simulation.

## 13. H7 — séparer Faits et Règles du monde et fiabiliser les usages

**Modifier :** les widgets `game_memory_*` de `presentation/features/story/`, `GameMemoryController`, `GameMemoryRules`, et leurs projections de noms et d’usages.

**Créer :** `features/game_memory/application/game_memory_draft_usages.dart`.

- [ ] Exposer Faits et Règles du monde comme deux entrées du même contrôleur et du même brouillon ; ne pas doubler les copies modifiables des données.
- [ ] Pour les faits, conserver type et identité stables, créer les types déjà pris en charge et renommer le libellé par la commande actuelle. Un renommage de libellé ne devient pas un remplacement global d’identifiant.
- [ ] Dans la fiche, distinguer valeur initiale du projet et valeurs temporaires de simulation. Ne pas suggérer qu’une modification de valeur initiale réécrit une sauvegarde Player existante.
- [ ] Construire les usages à partir de l’index canonique enregistré, puis corriger la contribution des seuls objets modifiés localement : enlever leur contribution enregistrée et ajouter leur contribution actuelle, par objet et rôle.
- [ ] Réutiliser les extracteurs canoniques pour ces contributions ; ne pas écrire un second parseur de conditions ou de Yarn dans le Studio. Si une source n’est pas couverte, conserver `notCovered` et expliquer la limite.
- [ ] Faire pointer les usages vers fait, règle, comportement, scène ou jalon précis. Un résultat incomplet n’autorise ni suppression ni affirmation « aucun usage ».
- [ ] Conserver la suppression d’un fait enregistré désactivée avec explication lorsque le chemin de publication ne la permet pas. L’abandon d’un fait créé dans le brouillon suit la commande existante et ses dépendances.
- [ ] Pour les règles, réutiliser `GameMemoryRules.create/update`, les sélecteurs et compatibilités actuels. Préserver les règles complexes non éditables sans les convertir en règle simple.
- [ ] Charger les cibles cartographiques à la demande. Ne pas utiliser `WorldPort.loadMaps` pour remplir chaque fiche ou chaque sélecteur.

**Nouveaux tests :** `test/game_memory/game_memory_draft_usages_test.dart`, `test/presentation/story_facts_rules_workspace_test.dart`.

**Cas à prouver :** changement de condition reflété dans lectures ; changement d’écriture reflété dans modifications ; annulation rétablit les usages ; couverture incomplète visible ; types et traductions préservés ; suppression non supportée impossible ; règle incompatible refusée ; aucune lecture de carte pour consulter un fait.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/game_memory test/presentation/story_facts_rules_workspace_test.dart test/presentation/story_memory_page_test.dart test/presentation/story_memory_states_test.dart -r failures-only
```

**Sortie du lot :** identifier où un fait est lu ou modifié dans la couverture déclarée, ouvrir les objets concernés et retrouver leur brouillon actuel.

## 14. D1 à D3 — rendre les dialogues multilingues de bout en bout

### D1 — contrats, identité durable et compatibilité

**Propriétaires à examiner :** `packages/map_core/lib/src/dialogue/`, `packages/map_core/lib/src/localization/project_locale_resolver.dart`, `packages/map_authoring/lib/src/dialogue/`, les entrées de dialogue du projet, `features/narrative/domain/dialogue_draft.dart` et les codecs existants.

- [ ] Caractériser les chemins actuels : identité de document, bloc et choix, sources Yarn, compilation des dialogues exportés et résolution de langue du projet. Les identifiants d’édition actuels ne sont pas supposés constituer des clés de traduction persistantes.
- [ ] Définir une identité durable pour chaque unité traduisible, réplique et choix compris. Une modification de texte ou un déplacement conserve l’identité ; une duplication indépendante en crée une nouvelle. Les choix conservent leurs résultats et branchements indépendamment de leur libellé traduit.
- [ ] Définir le stockage des variantes, la langue source, les langues disponibles et le repli en réutilisant `ProjectLocaleResolver` et les contrats existants chaque fois qu’ils couvrent le besoin.
- [ ] Prévoir l’état « traduction absente » et l’état « traduction à revoir » après modification du texte source. Une variante absente ne se transforme pas silencieusement en texte vide.
- [ ] Ajouter le chemin compatible de lecture ou de conversion déterministe nécessaire pour les anciens documents monolingues, sans réécriture à la simple ouverture et sans perte de syntaxe ou de source.
- [ ] Définir les capacités et versions nécessaires pour qu’un contenu multilingue ne soit pas accepté puis silencieusement ignoré par un lecteur incompatible. Ne pas ajouter des tags `#line:` en supposant qu’ils sont compris par tous les lecteurs.
- [ ] Préserver les textes de journal déjà localisés et conserver un seul mécanisme de sélection de langue au niveau du projet.

**Preuves de sortie :** round-trip monolingue et multilingue ; identité stable sous édition et réorganisation ; copie indépendante ; choix dont le résultat reste invariant entre langues ; repli déterministe ; ancienne source conservée après échec de lecture ou de conversion. Le contrat précis et ses fichiers propriétaires sont arrêtés dans ce lot avant d’implémenter D2.

### D2 — édition des variantes dans le Studio

**Créer :** `presentation/features/story/dialogues/story_dialogues_view.dart`. Modifier la navigation Histoire et les localisations.

- [ ] Ajouter aux champs de dialogue partagés une langue de saisie explicite, distincte de la langue de l’interface Studio.
- [ ] Permettre de consulter et modifier la variante choisie sans écraser le texte source ni une autre langue. Changer de langue termine ou conserve proprement la saisie courante dans le brouillon.
- [ ] Afficher les traductions absentes, le repli effectivement utilisé et les traductions à revoir ; ne pas présenter le texte de repli comme une traduction existante.
- [ ] Appliquer ces contrôles aux répliques simples, aux textes de narration et aux libellés des choix, via les mêmes composants depuis Histoire, Carte et le graphe.
- [ ] Afficher une explication courte : les répliques simples s’éditent dans les comportements et les dialogues à choix dans leurs scènes ; les variantes linguistiques appartiennent au même document.
- [ ] Proposer deux accès : « Répliques des comportements » et « Dialogues des scènes », en conservant les sélections et filtres déjà définis pour ces catalogues.
- [ ] Depuis une fiche ouverte, réutiliser exactement l’édition de H6 ou le formulaire de dialogue existant dans le graphe ; ne pas créer un texte synchronisé à la main dans cette page.
- [ ] Ne pas afficher de compteur exhaustif ni de recherche sur les 620 dialogues de référence sans lecture et index adaptés.
- [ ] Conserver les textes avancés, choix et traductions inchangés lors d’une simple navigation.
- [ ] Tester l’annulation/refaire et la sauvegarde d’une variante, le partage d’un dialogue, sa copie indépendante et le retour à l’autre langue sans perte de modifications.

**Nouveaux tests Studio :** `test/presentation/story_dialogues_navigation_test.dart`, `test/narrative/dialogue_localization_editing_test.dart`, `test/presentation/story_dialogue_language_fields_test.dart`.

**Cas à prouver :** les deux destinations s’ouvrent ; le retour restaure le contexte ; aucune lecture de tous les fichiers Yarn à l’ouverture ; texte avancé inchangé ; pas de création de scène pour une phrase simple.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/presentation/story_dialogues_navigation_test.dart test/narrative/dialogue_localization_editing_test.dart test/presentation/story_dialogue_language_fields_test.dart test/narrative/dialogue_draft_codec_test.dart test/presentation/map_builder_story_line_catalog_test.dart
```

**Sortie du lot :** des variantes réellement éditables et sauvegardables dans les parcours courants, sans réimplémenter la structure ni la logique des dialogues.

### D3 — export et lecture par le Player

**Propriétaires à raccorder :** compilation et documents de dialogue dans `packages/map_core/lib/src/dialogue/`, export canonique dans `packages/map_authoring`, export Studio et résolution/chargement des dialogues dans `packages/map_runtime/lib/src/application/`.

- [ ] Exporter les variantes et leur identité par le chemin canonique, en conservant les contrats de compatibilité définis dans D1.
- [ ] Résoudre les répliques et libellés de choix avec la langue effective du jeu, puis son repli. Réutiliser le mécanisme de préférence linguistique déjà présent ; ne pas introduire une langue différente propre au seul système de dialogue.
- [ ] Conserver interpolations, portraits, métadonnées et règles de feedback lorsqu’un texte change de langue ; valider les contraintes qui dépendent du texte réellement affiché.
- [ ] Tester une traduction absente, un tag régional comme `fr-CA`, une langue non disponible et une ancienne exportation monolingue.
- [ ] Exécuter un parcours natif Studio → sauvegarde/réouverture → export → Player dans deux langues, avec une réplique simple et un dialogue à choix. Le résultat d’un choix doit rester identique quelle que soit la langue.
- [ ] Vérifier que la langue choisie est réappliquée correctement lors d’une nouvelle session par le mécanisme existant ; ne pas modifier le format de progression sauvegardée pour stocker les traductions.

**Preuves de sortie :** variantes réellement visibles dans le Player, repli correct, progression identique et contenu historique monolingue toujours lisible. Les fichiers précis de tests de contrat et de runtime suivent le contrat arrêté dans D1 ; aucune déclaration de prise en charge ne repose uniquement sur les champs de traduction du Studio.

## 15. H9 — rendre la vérification complète sur son périmètre et navigable

**Modifier :** `verification_view.dart`, `story_page_navigation.dart`, `ProjectVerificationController`, `verification_problems.dart`. Créer `verification_snapshot.dart`.

- [ ] Conserver le lancement explicite sur les données enregistrées, la progression et l’annulation du travail appartenant à cette analyse.
- [ ] Conserver dans le résultat applicatif les informations de couverture nécessaires du rapport et la révision enregistrée analysée. Marquer les résultats périmés si cette révision change ; signaler séparément un brouillon non enregistré.
- [ ] Après annulation, erreur de lecture ou dimension non vérifiée, afficher un état partiel ou incomplet. La présence d’une liste vide ne suffit pas pour afficher « Aucun problème ».
- [ ] Présenter gravité, objet, emplacement, message compréhensible et action disponible. Utiliser un compteur de navigation qui indique aussi l’absence d’analyse ou sa péremption.
- [ ] Ouvrir directement une scène sans porteur, une fiche de fait, une règle ou un jalon. Ne pas convertir une destination de scène en premier comportement arbitraire.
- [ ] Sélectionner une étape de graphe seulement si le diagnostic fournit une identité fiable. Sinon, ouvrir la scène et ses diagnostics locaux ; ne pas réutiliser `stepId` de trame comme identifiant de bloc.
- [ ] Conserver les gravités de `diagnoseScene` et la distinction entre diagnostic local et publication refusée. Une scène refusée à l’enregistrement reste dans le brouillon avec une erreur explicite.
- [ ] Ne pas modifier le moteur pour faire correspondre ses résultats aux exemples fictifs de la maquette.

**Nouveaux tests :** `test/verification/verification_snapshot_test.dart`, `test/presentation/story_verification_navigation_test.dart`.

**Adapter :** `test/verification/project_verification_controller_test.dart`, `project_verification_catalog_test.dart`, `verification_page_test.dart`.

**Cas à prouver :** révision qui change pendant ou après analyse ; brouillon non vérifié clairement indiqué ; source illisible ; annulation ; résultats vides mais incomplets ; scène sans porteur ; cible supprimée ; sélection et modification sans déclenchement d’analyse ; gravité inchangée.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/verification test/presentation/story_verification_navigation_test.dart test/scenes/graph/scene_graph_checks_test.dart -r failures-only
```

**Sortie du lot :** chaque résultat annonce sa portée et sa fraîcheur, et chaque destination disponible mène au bon objet sans perte de contexte.

## 16. H10 — parcours complets, performance et retrait de l’ancien rendu

**Modifier :** les seules intégrations encore nécessaires ; supprimer les anciens widgets devenus sans appelant au fil de leur remplacement, avec leurs seules clés l10n effectivement inutilisées.

**Nouveaux tests :** `test/presentation/story_workspace_journey_test.dart`, `test/narrative/story_workspace_catalog_journey_test.dart`, `test/narrative/story_workspace_work_counts_test.dart`.

- [ ] Réaliser le parcours projet vide → histoire → chapitre → jalons → liens → journal → sauvegarde → fermeture → réouverture par les vrais adaptateurs.
- [ ] Réaliser le parcours trois cartes → trois comportements → répliques et cas → fait commun → scène partagée → annulation/refaire → enregistrement → export sur copie → lecture Player.
- [ ] Vérifier les refus : projet en lecture seule, conflit d’écriture externe, dialogue manquant, publication refusée, scène partagée et expression complexe. Aucun original ni brouillon ne doit être réinitialisé.
- [ ] Vérifier que les cinématiques existantes et leurs références traversent ce parcours sans être modifiées par le retrait de leur entrée Histoire.
- [ ] Contrôler le journal dans le vrai Player : texte, indices conditionnels, ordre courant, sauvegarde/reprise au format actuel. Ne pas vendre un test de projection comme preuve de ce parcours.
- [ ] Vérifier clavier, focus, tabulation, lecteur d’écran et taille de texte augmentée sur les commandes principales. Les raccourcis de champ restent prioritaires pendant la saisie.
- [ ] Rechercher les appelants avant de retirer l’ancien rendu à quatre onglets et les composants remplacés ; ne supprimer aucun codec, fixture historique utile ou test de compatibilité pour faciliter le nettoyage.
- [ ] Exécuter la campagne de performance ci-dessous, puis les suites de non-régression pertinentes. Relancer seul tout fichier en échec et indiquer s’il est lié au chantier.

**Parcours d’acceptation obligatoires :**

| Parcours | Preuve attendue |
|---|---|
| Rencontrer un PNJ puis changer sa réplique | Le premier cas valable change avec le fait simulé ; sauvegarde et réouverture conservent l’ordre et les textes. |
| Scène partagée | Les usages sont annoncés ; modifier la scène concerne ses utilisateurs ; une copie indépendante suit le chemin existant. |
| Scène sans carte | Elle apparaît, s’ouvre et revient au catalogue sans porteur inventé. |
| Rattachement déplacé | Origine annoncée, transaction explicite, retour arrière complet. |
| Journal | Le Player lit les textes exportés et ses règles de progression actuelles ; aucune nouvelle sémantique implicite. |
| Retour Carte / Histoire | Même filtre, même objet et même position de liste ; brouillon identique. |
| Écriture concurrente | Refus explicite, données originales préservées et édition locale récupérable. |
| Vérification incomplète | Aucun faux statut sain et aucune suppression débloquée. |

### Performance : comptages structurels puis mesures natives

Les objectifs 100 ms de retour visible et 500 ms de persistance durable restent des critères d’acceptation des modifications simples. Les anciens chiffres de sauvegarde de scène cités dans le prompt ne sont pas une mesure de cette version.

1. Utiliser une fixture petite et une fixture à deux fois la taille narrative, avec cartes non pertinentes présentes. Mesurer lectures, écritures, décodages et invalidations pour les mêmes opérations.
2. Pour renommer un fait ou un chapitre et éditer un texte de journal : zéro décodage de carte, zéro lecture de dialogue non concerné et zéro validation globale.
3. Pour ouvrir le catalogue : lecture des titres et relations nécessaires, sans ouvrir tous les documents ; pour ouvrir une fiche : seulement son document et ses dépendances.
4. Pour modifier un comportement sur une carte inactive : au plus la carte pertinente si elle n’est pas déjà courante en mémoire, puis aucune relecture non pertinente aux modifications suivantes.
5. Vérifier que doubler les données non liées n’augmente pas le nombre d’unités de stockage touchées par une mutation locale. Une transaction commune légitime reste atomique.
6. Mesurer en Release la première opération après préparation et les opérations répétées : temps de retour visible, de persistance réellement acquittée, recherche après index prêt et ouverture de fiche. Distinguer préparation initiale, chargement froid et cache chaud.
7. Consigner machine, taille réelle, échantillon et p50/p95. La recherche locale vise également moins de 300 ms au p95 et l’ouverture de fiche moins de 500 ms au p95 après préparation ; aucun résultat `flutter test` n’est présenté comme performance utilisateur.
8. Si un seuil échoue, localiser le travail dans la frontière propriétaire et corriger ce chemin ciblé avant de déclarer le critère atteint. Une non-régression ne transforme pas un seuil déjà dépassé en réussite ; aucune refonte générale du stockage n’est lancée silencieusement.

## 17. Validation native et protection des projets

### Environnement

- Un environnement appartenant à cette exécution sous `/Users/karim/Library/Caches/AveluneQA/histoire-refonte/` pour builds et comptages ; aucun environnement de validation n’est créé lors de la rédaction du présent plan.
- Pour l’atlas macOS sandboxé : copie du projet sous `/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Library/Caches/AveluneQA/histoire-refonte/project/` et dossier frère `captures/`, conformément au harness existant.
- La copie provient d’une source de référence lue sans modification. Ne pas réutiliser ou nettoyer le clone d’une autre session sur la seule foi de son nom.
- Les nombres 440 événements, 443 scènes, 620 dialogues, 100 faits et 57 règles restent des volumes historiques de dimensionnement jusqu’à leur recomptage sur la copie utilisée. Ne pas affirmer qu’ils décrivent encore le projet actuel.
- Marqueur de capture attendu : `.avelune-studio-capture-owner`, contenu exact `avelune-studio-capture@1`, sans saut de ligne.
- En cas de `history.preparation_required`, diagnostiquer puis préparer la copie par le chemin canonique. Ne pas réécrire automatiquement les empreintes d’un projet original ni supprimer l’historique.

### Build et captures

Configurer l’emplacement de build dans le `XDG_CONFIG_HOME` propre au harness, sans toucher à la configuration globale de Yoahn. Depuis `apps/avelune_studio`, construire avec :

```bash
XDG_CONFIG_HOME=/Users/karim/Library/Caches/AveluneQA/histoire-refonte/config flutter build macos --release --no-pub -t dev/ui_atlas_main.dart --dart-define=AVELUNE_ATLAS_PROJECT_PATH=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Library/Caches/AveluneQA/histoire-refonte/project --dart-define=MARIONETTE_CAPTURE_ROOT=/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Library/Caches/AveluneQA/histoire-refonte/captures
```

Le build doit passer par le mécanisme `tools/scripts/ensure_studio_qa_engine.py` et produire le reçu du moteur Release épinglé. Le script utilise l’environnement du build Xcode ; l’exécuter seul sans cet environnement ne qualifie pas le moteur.

Lancer uniquement le bundle appartenant à ce build, enregistrer son PID, puis capturer sa fenêtre. Après chaque lot qui change un écran, une interaction, la sauvegarde, l’annulation ou l’ouverture du Studio, effectuer une vraie passe native conformément à la section « Native Studio verification » des politiques. H1, H3, H6, H9 et H10 restent des points de comparaison visuelle particulièrement utiles, mais ne remplacent pas cette obligation pour les autres lots concernés. Un lot purement documentaire ou un relevé de baseline sans changement applicable ne nécessite pas une compilation cérémonielle.

Pour chaque lot concerné : utiliser les parcours d’acceptation dans l’application, couvrir les états pertinents, essayer annuler/refaire puis sauvegarder, fermer et rouvrir, relever les temps et examiner les textes et l’ergonomie. Séparer observations et déductions. Corriger les défauts bloquants dans le même lot avec une non-régression, puis refaire la passe après une correction risquée ou annoncer que le contrôle n’a pas été répété. Un écran non essayé réellement ne peut pas être annoncé terminé.

Les captures conservées montrent : cadre, projet vide, trame complète, réplique et cas, scène partagée, fait avec usages, règle, résultats incomplets et retour depuis Carte. Elles servent à comparer la maquette au résultat natif ; elles ne prouvent pas à elles seules le comportement du Player.

### Nettoyage

Enregistrer PID du runner et descendants pendant les tests ; arrêter seulement les survivants de cette exécution après vérification de leur identité. Ne jamais tuer un processus par nom.

Retirer seulement les admissions de catalogue et préférences réellement créées ou modifiées par ce harness, en vérifiant qu’aucune session concurrente ne les a reprises. Supprimer la copie, les exports et le build temporaires appartenant au chantier ; garder seulement les preuves utiles dans un emplacement accepté pour la livraison.

## 18. Commandes finales et critères de sortie

Les commandes suivantes sont prévues pour l’implémentation ; elles n’ont pas été exécutées pendant la rédaction du plan.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/story_workspace test/storyline test/game_behaviours test/game_memory test/verification test/scenes test/narrative -r failures-only
flutter test --no-pub test/presentation/story_workspace_journey_test.dart test/presentation/story_workspace_layout_test.dart test/presentation/story_workspace_navigation_test.dart test/presentation/story_scene_catalog_test.dart test/presentation/story_behaviour_inspector_test.dart test/presentation/story_behaviour_simulation_test.dart test/presentation/story_facts_rules_workspace_test.dart test/presentation/story_dialogues_navigation_test.dart test/presentation/story_verification_navigation_test.dart test/presentation/map_builder_story_publication_test.dart test/presentation/map_builder_story_catalog_save_test.dart
flutter test --no-pub test/game_export/studio_game_export_service_test.dart
flutter test --no-pub test/architecture -r failures-only
flutter analyze --no-pub
```

Si une primitive du design system est modifiée :

```bash
cd /Users/karim/Project/pokemonProject/packages/avelune_design_system
flutter test --no-pub -r failures-only
flutter analyze --no-pub
```

Pour le parcours journal, export et Player :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/player_journal_projection_test.dart test/player_journal_storyline_json_test.dart test/storyline_step_scene_link_ids_meaning_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test --no-pub test/player/runtime_player_journal_pause_test.dart test/phase_a_golden_battle_slice_smoke_test.dart
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host
flutter test --no-pub test/phase_a_golden_slice_launch_test.dart
```

Le périmètre d’analyse statique est étendu à chaque package réellement modifié. Les tests purement Dart exécutés sous `dart test` restent distincts des preuves natives.

### Checklist de clôture de l’implémentation

- [ ] Sept entrées Histoire opérationnelles sur leur périmètre déclaré ; aucune entrée Cinématiques ajoutée par ce chantier.
- [ ] Dialogues multilingues pris en charge pour répliques simples, narration et choix, de l’édition jusqu’au Player exporté ; langues manquantes et repli explicitement vérifiés.
- [ ] Aucun nouvel objet de projet créé par simple navigation.
- [ ] Même brouillon et mêmes sources de données depuis Carte et Histoire.
- [ ] Cas ordonnés, textes simples et expressions complexes conservés.
- [ ] Rattachements, partage, lecture seule et refus affichés fidèlement.
- [ ] Filtres, sélection et retour restaurés ; historique sans mutation cachée d’un autre objet.
- [ ] Pas de régression sur les projets depuis Studio `0.3.31+331` ; fixtures et lecteurs existants conservés.
- [ ] Sauvegarde/réouverture, export et parcours Player vérifiés sur une copie, sans promesse de fidélité non testée.
- [ ] Zéro lecture ou reconstruction globale déclenchée par une modification locale ; budgets mesurés et résultats annoncés sans exception implicite.
- [ ] Tests ciblés et analyse statique exécutés ; tout échec restant identifié avec sa portée.
- [ ] Graphe et anciens formats conservés ; ancien rendu remplacé retiré seulement après preuve d’absence d’appelants.
- [ ] Aucun fichier Dart manuel ou test ajouté au-dessus de 350 lignes ; aucun commentaire de code ajouté ; aucun affaiblissement d’`analysis_options.yaml`.
- [ ] Captures natives utiles partagées, processus possédés arrêtés et environnement QA nettoyé.
- [ ] Statut Git final relu ; les changements d’autres sessions sont explicitement distingués.

## 19. Parité MCP et limites de l’engagement

La parité MCP reste N/A pour les lots limités à la présentation, à la navigation et aux projections applicatives. Les contrats et opérations de localisation introduits par D1 à D3 exigent une vérification de parité dès qu’ils touchent un contrat de données ou une action canonique `map_authoring` : le chantier complet ne peut plus être annoncé globalement « MCP parity: N/A ».

Une insuffisance avérée d’une requête ou action canonique doit être isolée et décrite avant de modifier son contrat. Cette évolution déclencherait le skill `skills/using-pokemap-mcp/SKILL.md`, ses preuves de parité et un ajustement ciblé du plan. Elle ne sera pas contournée par un écrivain de fichiers privé du Studio.

Ce plan ne valide pas encore la jouabilité, les performances, la compatibilité en exécution ou les anciennes assertions de tests rouges. Il fixe les preuves nécessaires pour pouvoir les annoncer ensuite.

## 20. Livraison du plan et prochaine étape

Revue de cohérence effectuée par le même agent : référence MagicPath, responsabilités, dépendances entre lots, conservation des sémantiques, fichiers proposés et couverture des parcours. Il ne s’agit pas d’une revue indépendante.

Modifications prévues pour cette seule livraison : ce document et son entrée d’autorisation dans `.gitignore`. Aucun fichier de production ou de test n’est modifié.

La prochaine étape proposée est H0, puis D1 avant de figer l’édition des textes. Le présent échange s’arrête à la planification : aucune case d’implémentation n’est annoncée terminée.

### Contrôles réellement exécutés pour le document

| Contrôle | Résultat observé |
|---|---|
| `git status --short --untracked-files=all` au démarrage | Arbre propre sur `main`, commit `688708ef4`. |
| Vérification des chemins des commandes de test | Les cibles absentes correspondent aux nouveaux tests ou répertoires explicitement prévus par les lots. Les cibles existantes ont été retrouvées. |
| Relecture de couverture | Première version de onze lots, révisée à treize avec D1 à D3 en remplacement de H8 ; cinématiques exclues, multilingue obligatoire et sémantiques de progression conservées. |
| `git diff --check` | Code de sortie 0, aucune erreur affichée. |
| `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` | Code de sortie 1 : le contrôle compte aussi deux README ignorés préexistants, en plus du seul document ajouté. |
| Tests Dart / Flutter, analyse statique, build et QA native | Non exécutés pour cette livraison documentaire. Les commandes du plan sont des validations futures. |

Les deux fichiers qui font échouer le contrôle Markdown global sont `apps/avelune_android/flutter_runtime/.ios/Flutter/README.md` et `apps/avelune_android/flutter_runtime/.ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`. Leur date de modification observée est le 18 septembre 2026. Ils ne sont ni créés ni modifiés par cette tâche et restent intacts ; le budget de nouveaux documents n’a pas été augmenté pour masquer cet état.

État Git final de la livraison : `.gitignore` modifié pour autoriser le document, et `documentation/reports/avelune_studio/plans/2026-11-15-refonte-histoire.md` ajouté sans staging. Aucun commit, fichier applicatif, fichier de test, processus persistant ou environnement QA créé.
