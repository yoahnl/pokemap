# Refonte de l’onglet Histoire — plan d’implémentation

**Objectif :** remplacer la présentation actuelle d’Histoire par l’espace Histoire de la maquette Avelune, en raccordant les écrans aux données et commandes réelles du Studio.

**Architecture :** conserver le shell, `StoryDraft`, les commandes canoniques et les frontières de publication. Carte · Interactions porte le placement et les propriétés physiques ; Histoire · Déclencheurs édite les règles qui lancent les scènes ; Scènes orchestre les actions ; Dialogues édite les documents et leurs traductions. Faire évoluer le graphe Flutter existant vers la présentation Blueprint de la référence, sans deuxième moteur.

**Technologies :** Dart, Flutter desktop, Riverpod, `avelune_design_system`, `map_core`, `map_authoring`, tests Flutter et QA macOS Release.

**Statut réconcilié le 16 novembre 2026 :** H0, D1 et H1–H5 ont été livrés sur leur périmètre historique, jusqu’à `3c3fb8109`. La nouvelle maquette n’est pas rétroactivement livrée par ces commits. D2, H6, la coordination locale, la reprise Blueprint, H7, D3, H9 et H10 restent à réaliser selon le découpage ci-dessous. Cette révision modifie seulement ce plan.

**Exécution prévue :** suivre les sous-lots bornés, avec tests ciblés avant changement de comportement, puis preuve native lorsqu’elle s’applique. Ce document n’autorise aucun démarrage applicatif, sous-agent, commit, push ou changement de branche. Les autorisations éventuelles restent celles de la tâche d’implémentation concernée.

**Règle de livraison :** appliquer la section « Native Studio verification » des politiques après chaque sous-lot qui change un écran, une interaction, la sauvegarde, l’annulation ou l’ouverture du Studio, avant son éventuel commit autorisé. Les anciens points de contrôle espacés et prompts historiques ne remplacent pas cette obligation. La prochaine étape fonctionnelle est D2a ; cette révision documentaire ne nécessite pas de build Flutter.

## 1. Référence et périmètre retenus

La référence est [la maquette Avelune complète](https://designs.magicpath.ai/v1/finely-dusk-9230). Le lien démarre sur Construction : naviguer vers **Histoire**, icône livre, ou vers **Carte → Interactions** pour la vue locale.

Révision intégrée et vérifiée dans la conversation de conception : `473066952324173824`, composant `470322378581372928`, projet MagicPath `470322374529675264`. Elle remplace la révision `472787618355089408` citée dans le premier plan. `clearly-road-3126` est un prototype historique désormais intégré ; ni lui ni l’ancienne proposition `quietly-stone-2857` ne sont des références parallèles d’implémentation.

La hiérarchie, les surfaces bleu sombre, la densité, les sélections et les gestes guident l’implémentation. L’éditeur principal des déclencheurs est central et large ; le petit inspecteur générique n’en est plus le propriétaire. Les données de démonstration, boutons illustratifs et textes de statut ne définissent pas les capacités du moteur.

### Références visuelles durables et portée des preuves

Les six captures suivantes ont été ouvertes lors de cette révision. Leur racine est `/Users/karim/.codex/visualizations/2026/11/15/01a1e09e-da9e-76b0-91f6-83f4e9334633/`.

| Capture | Intention à reproduire | Lots propriétaires |
|---|---|---|
| [Déclencheurs intégrés](/Users/karim/.codex/visualizations/2026/11/15/01a1e09e-da9e-76b0-91f6-83f4e9334633/histoire-declencheurs-integres.jpg) | Liste compacte, QUAND/SI/ALORS au centre, contexte repliable. | H6a, H6b, H6d. |
| [Bibliothèque Dialogues](/Users/karim/.codex/visualizations/2026/11/15/01a1e09e-da9e-76b0-91f6-83f4e9334633/histoire-dialogues-integres.jpg) | Documents, recherche, aperçu par langue et états. | D2a. |
| [Texte et traductions](/Users/karim/.codex/visualizations/2026/11/15/01a1e09e-da9e-76b0-91f6-83f4e9334633/histoire-traductions-integrees.jpg) | Source et traduction côte à côte sur le même document. | D2b. |
| [Interactions : propriétés](/Users/karim/.codex/visualizations/2026/11/15/01a1e09e-da9e-76b0-91f6-83f4e9334633/carte-interactions-proprietes.jpg) | Responsabilité spatiale locale et Propriétés au premier plan. | H6c. |
| [Interactions : déclencheurs](/Users/karim/.codex/visualizations/2026/11/15/01a1e09e-da9e-76b0-91f6-83f4e9334633/carte-interactions-declencheurs.jpg) | Cartes récapitulatives et passage précis vers Histoire. | H6c, H6d. |
| [Graphe Blueprint et couleurs](/Users/karim/.codex/visualizations/2026/11/15/01a1e09e-da9e-76b0-91f6-83f4e9334633/unreal-blueprint-histoire-couleurs.jpg) | Graphe, palette, structure, connecteurs, navigation et couleurs harmonisées. | G1, G2. |

Les builds MagicPath et parcours navigateur à 1280×720 rapportés par la conversation de conception couvrent conditions, répétition, annulation partagée, accès au graphe, gestion des règles, création inactive, document partagé, langues manquantes et traductions à revoir, allers-retours Bourg Geon/Luth et Maison du joueur/Maman, propriétés physiques et carte vide. Ce sont des preuves de maquette, distinctes des captures natives H5 ; elles ne prouvent ni sauvegarde durable, ni contrats Yarn natifs, ni export ou lecture Player. Cette révision n’a pas relancé ces parcours navigateur.

### Écrans visés par le chantier complet

| Entrée | Résultat attendu |
|---|---|
| Trame | Histoires, chapitres, jalons, conditions prises en charge, scènes liées, journal et indices. |
| Déclencheurs | Règles de déclenchement : liste intercartes compacte, édition centrale QUAND/SI/ALORS, répétition séparée, cas ordonnés, simulation et retour à Carte. |
| Scènes | Catalogue indépendant des porteurs, filtres, usages, aperçu ciblé et graphe existant repris visuellement selon Blueprint. |
| Dialogues | Bibliothèque de documents ; aperçu par langue, source et traduction côte à côte, usages et édition du même document depuis tous ses accès. |
| Faits | Liste, recherche, fiche, création et modification déjà permises, usages distinguant lectures et écritures. |
| Règles du monde | Liste et édition des règles déjà prises en charge, cibles explicites et accès aux sources. |
| Vérification | Analyse globale enregistrée à la demande, couverture, fraîcheur, gravités réelles et navigation vers les objets. |
| Carte · Interactions | Placements et propriétés des personnages, objets et zones ; résumés et gestion des déclencheurs, dont l’édition détaillée reste dans Histoire. |

Les sept entrées d’Histoire restent Trame, Déclencheurs, Scènes, Dialogues, Faits, Règles du monde et Vérification. La huitième entrée Cinématiques visible dans certaines captures est exclue par décision de Yoahn.

### Hors périmètre de cette livraison

- Cinématiques : ni catalogue dédié, ni restauration des anciens éditeurs, ni nouvelle timeline. Leur entrée n’apparaît pas dans la navigation Histoire de ce chantier. Les étapes et références existantes continuent de passer par leurs chemins actuels.
- Réécriture complète de l’éditeur de structure des dialogues, traduction automatique et traduction manuelle de tout le contenu existant. Le support des variantes linguistiques et leur identité durable font en revanche partie de cette livraison.
- Réécriture du moteur ou du modèle de graphe, nouveau langage Scratch, boucles générales, nouveau type de routine et nouveaux types d’étapes. La reprise visuelle Blueprint et l’harmonisation des catégories/couleurs existantes font partie de G1/G2.
- Changement de sémantique de progression du journal, des conditions ou des rattachements de scènes. Aucune rupture du format des sauvegardes Player n’est prévue pour ajouter la sélection des textes localisés.
- Nouvel outil de remplacement global, migration de projet, réorganisation générale du Studio ou du moteur.
- Import des données fictives de MagicPath dans un projet réel.

Le multilingue demandé concerne les textes du jeu, indépendamment de la langue de l’interface Studio : répliques simples, narration et libellés de choix. Les langues prises en charge par le projet, sa langue de référence et le repli sont explicites. Changer la langue affichée ne change ni les faits, ni l’ordre des cas, ni les identifiants de résultats de choix.

L’entrée Dialogues devient une bibliothèque de documents. « Texte et traductions » depuis un déclencheur et l’ouverture depuis la bibliothèque ciblent exactement le même document. Une scène simple conserve son chemin minimal Début → Dialogue → Fin ; son déclencheur ne stocke aucun nouveau texte monolingue et n’offre pas de destination « dialogue » parallèle au `sceneId`.

## 2. Décisions qui encadrent l’implémentation

| Sujet | Décision retenue pour cette refonte |
|---|---|
| Vocabulaire auteur | « Déclencheurs » ou « Déclencheurs de scènes » dans Histoire, « Interactions » côté carte. Conserver `NarrativeEventDefinition`, `behaviours`, les identifiants de modes et les contrats persistés. |
| Responsabilités | Le déclencheur associe événement/source, conditions, un `sceneId`, activation, priorité/ordre et politique de répétition/réarmement. La scène orchestre actions et branches ; le document de dialogue porte répliques, choix et traductions. |
| ALORS | Toujours choisir une scène à lancer. Changer cette association ne modifie ni ne duplique la scène ou son dialogue. L’aperçu éventuel du texte est en lecture seule et mène à son document. |
| Répétition | Section distincte d’ALORS ; « Après » désigne l’ancienne présentation de la politique, jamais une action suivante. Préserver notamment le réarmement sur résultat explicite et les contraintes des événements parallèles. |
| Cas et ordre | Plusieurs définitions d’une même source, ordonnées selon le moteur ; dans le dispatch ordinaire, le premier cas éligible est retenu. Conserver priorité et ordre, sans inventer de séquence d’actions entre cas. |
| Création | Nouveau déclencheur désactivé, à compléter tant que ses références obligatoires manquent. Refuser l’activation sans scène valide ou résultat attendu nécessaire ; ne pas rendre les contrats facultatifs ni fabriquer de référence pour contourner un refus. |
| Carte locale | Propriétés physiques en premier, résumés narratifs et actions de gestion ; aucun deuxième formulaire QUAND/SI/ALORS ni deuxième persistance locale. Retirer une association ne supprime pas sa scène ou son dialogue. |
| Origine et carte vide | Le lien local ouvre l’identité exacte et sa carte ; le retour restaure carte, sélection et contextes. La vue d’ensemble filtre cette carte. Aucune sélection de repli sur une autre carte ; une carte vide invite à créer une source dans Interactions. |
| Dialogue partagé | Même identité depuis bibliothèque, scène et déclencheur ; usages et impact visibles. Une copie indépendante passe par les opérations localisées canoniques, jamais par une chaîne synchronisée à la main. |
| Langues | Langues du contenu distinctes de la langue Studio ; source, traduit, manquant, à revoir et repli visibles. Modifier la source conserve les variantes et les marque à revoir selon D1. Les exemples FR/EN/ES ne limitent pas le nombre de langues. |
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

État initial historique du plan : `main`, `688708ef4`. État au début de cette révision : `main`, `165dde0e9` — `Plan the Story workspace redesign`, arbre propre selon `git status --short --untracked-files=all`. Relire cet état avant chaque implémentation, le dépôt étant partagé.

### Acquis natifs et limites de leur preuve

| Lot historique | Commit retrouvé dans l’historique actuel | Acquis à préserver ; suite de la nouvelle maquette |
|---|---|---|
| H0 | `d4b3f019c` | Caractérisation des contrats ; nouvelle référence à appliquer sans recommencer l’ancien lot. |
| D1 | `14a3cead2` | Identités et variantes durables, gardes d’authoring ; D2 et D3 restent nécessaires. |
| H1 | `29cd3b884` | Cadre à sept entrées ; nouveau vocabulaire et composition centrale à livrer en H6a. |
| H2 | `304ef09be` | Contexte et portée d’historique ; nouveaux liens précis et carte vide à éprouver en H6d. |
| H3 | `82e67ac3b` | Chapitres, jalons, journal ; aucune nouvelle sémantique de progression. |
| H4 | `c0a77dfb7` | Catalogue, filtres et aperçus ; la reprise Blueprint reste G1/G2. |
| H5 | `3c3fb8109` | Contexte explicite Carte/Histoire, transactions et lectures ciblées ; nouvelle présentation à livrer en H6. |

Ces commits attestent les livraisons historiques, pas l’exécution fraîche de leurs tests pendant cette tâche. Les preuves natives et journaux H3, H4 et H5 restent respectivement sous `/Users/karim/Library/Caches/AveluneQA/histoire-h3-evidence-01a1e117/`, `/Users/karim/Library/Caches/AveluneQA/histoire-h4-evidence-01a1e117/` et `/Users/karim/Library/Caches/AveluneQA/histoire-h5-evidence-01a1e117/`. Ne pas les effacer lors de cette révision.

La livraison H5 rapportait 398 tests larges, puis 29 tests ciblés et deux tests de champ après les corrections natives ; architecture : 47 réussites et deux échecs de baseline ; analyse globale : huit informations préexistantes. Ce ne sont pas de nouveaux résultats. Le seuil de sauvegarde de 500 ms n’était pas certifié : un premier marqueur durable scène + texte était observé vers 549 ms. La refonte actuelle ne transforme pas cette limite en succès.

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
| Graphe Blueprint | Dans ce même répertoire : `graph/scene_graph_card_tile.dart`, `scene_graph_painters.dart`, `scene_graph_canvas.dart`, `scene_graph_toolbar.dart`, `scene_graph_step_menu.dart`, `scene_focus_workspace.dart`, `scene_focus_side.dart` ; projections et éditions sous `features/scenes/application/graph/`. |
| Interactions physiques et fiche locale | `apps/avelune_studio/lib/presentation/features/map_builder/map_builder_story_panel.dart`, `map_builder_story_inspector.dart`, `map_builder_story_properties_tab.dart`, `map_builder_story_element_editing.dart`, `map_builder_page_story_navigation.dart`. |
| Documents de dialogue | `apps/avelune_studio/lib/features/dialogues/domain/dialogue_port.dart`, `data/local_dialogue_adapter.dart`, `features/narrative/domain/dialogue_draft.dart`, `features/narrative/application/dialogue_draft_codec.dart`. |
| Localisation canonique D1 | `packages/map_core/lib/src/dialogue/`, `packages/map_authoring/lib/src/dialogue/dialogue_localization_document.dart`, `src/domains/narrative/dialogue_actions.dart`, `dialogue_localization_guards.dart`. |
| Faits et règles | `apps/avelune_studio/lib/features/game_memory/application/game_memory_controller.dart`, `game_memory_rules.dart`. |
| Vérification | `apps/avelune_studio/lib/features/verification/application/project_verification_controller.dart`, `verification_problems.dart`, et le port de vérification. |
| Traductions | `apps/avelune_studio/lib/l10n/app_fr.arb`, `app_en.arb`, puis `flutter gen-l10n`. |

### Écarts restant à traiter ou à préserver

1. H5 a rendu le contexte explicite : ne pas réintroduire `maps.active.current` comme source implicite en recomposant H6. Le champ simple historique crée encore une entrée monolingue ; il ne constitue pas D2.
2. H4 possède les projections de catalogue et de rattachements. Réutiliser leurs relations multiples, plutôt que singulariser via `milestoneOfScene` ou reconstruire le classement dans la vue.
3. Le panneau local possède déjà placement et propriétés. H6c réorganise leur présentation et remplace l’édition narrative détaillée, sans retirer leurs commandes.
4. Les usages d’un fait proviennent d’un index enregistré. Leur présentation doit intégrer les changements locaux pertinents, ou annoncer explicitement que leur couverture du brouillon est incomplète.
5. La navigation d’un diagnostic de scène passe actuellement par un comportement. Il faut une ouverture directe des scènes sans porteur.
6. `VerificationProblem` ne transporte pas une identité précise d’étape de graphe. `stepId` n’est pas un substitut générique à `nodeId` : on ne doit pas centrer un bloc en inventant une correspondance.
7. Les lectures de titres sont paginées côté authoring mais l’adaptateur actuel les agrège en liste. Une ouverture de catalogue peut lire ses titres ; chaque modification locale doit rester indépendante de cette lecture complète.
8. L’export refuse actuellement un document localisé avec `dialogueLocalizationRuntimeUnsupported`, dans `packages/map_authoring/lib/src/domains/distribution/runtime_project_projection_builder.dart`. D1 n’est pas une preuve de lecture multilingue Player ; garder ce refus jusqu’à D3.
9. Le catalogue canonique de titres prend déjà en charge `dialogues`, mais `NarrativeTitleKind` du Studio ne l’expose pas. D2a étend ce port et son adaptateur vers cette requête existante, sans inventer une nouvelle action ni lire tous les fichiers Yarn. Les titres seuls ne fournissent pas une recherche plein texte ni des états de traduction exhaustifs.

## 4. Organisation des fichiers acquis et à créer

Les propriétaires existants de la section 3 et les fichiers H0–H5 sont à modifier, pas à recréer. Les chemins « à créer » ci-dessous sont des propositions, pas des API présentes. Chaque fichier porte une responsabilité ; cible de 300 lignes, plafond de 350 lignes pour Dart manuel et tests. Tous les chemins de cette section partent de `apps/avelune_studio/lib/`.

| Fichiers et état | Responsabilité |
|---|---|
| Existants : `features/story_workspace/application/story_workspace_state.dart`, `story_history_scope.dart` | Sélections, filtres, origine et portée de la prochaine transaction ; extensions H6d sans deuxième historique. |
| Existants : `presentation/features/story/story_workspace.dart`, `story_navigation.dart`, `story_inspector.dart`, `story_breadcrumb.dart` | Composition par section ; H6a réserve le centre aux déclencheurs. |
| Existants : `features/scenes/application/scene_catalog_controller.dart`, `scene_catalog_memberships.dart`, `presentation/features/story/scenes/` | Catalogue H4, filtres et usages ; ne pas recréer le contrôleur. |
| Existants : `features/game_behaviours/application/game_behaviour_editing.dart`, `presentation/features/map_builder/map_builder_story_catalog_binding.dart` | Transactions et résolution de carte explicites acquises en H5. |
| À créer D2a : `features/dialogues/application/dialogue_catalog_controller.dart`, `dialogue_catalog_rows.dart`, `presentation/features/story/dialogues/story_dialogues_view.dart` | Catalogue de documents, recherche réellement couverte, états des langues et aperçu ciblé. |
| À créer D2b : `features/dialogues/application/dialogue_localization_editing.dart`, `presentation/features/story/dialogues/story_dialogue_editor.dart`, `story_dialogue_language_fields.dart` | Édition du même document, source/traduction côte à côte et statut/repli. Les données métier restent dans le brouillon partagé. |
| À créer H6a : `presentation/features/story/behaviours/game_behaviour_workspace.dart`, `game_behaviour_list.dart` | Liste compacte et éditeur central ; nommage interne conservé. |
| À créer H6b : `presentation/features/story/behaviours/game_behaviour_when.dart`, `game_behaviour_conditions.dart`, `game_behaviour_scene.dart`, `game_behaviour_repeat.dart` | QUAND, SI, association de scène/aperçu non éditable, répétition séparée. |
| À créer H6b : `presentation/features/story/behaviours/game_behaviour_cases.dart`, `game_behaviour_simulation.dart`, `game_behaviour_context.dart` | Ordre des cas, simulation sans écritures et contexte secondaire repliable. |
| À créer H6c : `presentation/features/map_builder/map_builder_interaction_triggers.dart` | Cartes de résumé et actions de gestion locales, projetées depuis les mêmes définitions. |
| À créer G1 : `presentation/features/scene_focus/graph/scene_graph_palette.dart` | Palette visuelle des familles natives, réutilisant les templates et commandes existants. |
| À créer G2 : `presentation/features/scene_focus/graph/scene_graph_outline.dart` | Recherche et navigation des étapes/usages du graphe courant. |
| À créer H7 : `features/game_memory/application/game_memory_draft_usages.dart` | Delta ciblé des usages du brouillon, couverture explicite. |
| À créer H9 : `features/verification/application/verification_snapshot.dart` | Révision analysée, couverture et fraîcheur du résultat global. |

Les widgets actuels de faits, règles, journal, conditions et répliques sont adaptés ou extraits avant de créer un doublon. Les composants génériques manquants appartiennent à `packages/avelune_design_system`, pas à une nouvelle bibliothèque privée de widgets Histoire.

## 5. Séquence et dépendances

| Lot | État et contenu | Prérequis | Point de contrôle visible |
|---|---|---|---|
| H0, D1, H1–H5 | Acquis historiques détaillés en section 3 | Dépendances historiques des sections 6–11 | Ne pas refaire ni requalifier leurs preuves. |
| D2a | À faire : bibliothèque des documents | D1, H2, H4, H5 | Un document et ses langues retrouvés sans ouvrir tous les Yarn. |
| D2b | À faire : édition localisée partagée | D2a | Même document depuis bibliothèque et accès contextuel ; source/traduction, sauvegarde/réouverture. |
| H6a | À faire : vocabulaire et espace central | H4, H5, D2b | Déclencheurs accessibles dans la bonne composition, états et sélection stables. |
| H6b | À faire : édition des règles et simulation | H6a | QUAND/SI/ALORS/RÉPÉTITION fidèles, activation protégée et expressions complexes conservées. |
| H6c | À faire : panneau local Interactions | H6b | Propriétés physiques conservées, résumés et gestion réversible des règles. |
| H6d | À faire : navigation locale/globale et cohérence | H6c, H2, H5 | Identité exacte, carte vide, contexte croisé, brouillon et historique communs. |
| G1 | À faire : rendu Blueprint et palette harmonisée | H4, H2 | Graphe existant lisible et fidèle, sans changer sa sémantique. |
| G2 | À faire : outils, navigation et accès aux documents | G1, D2b, H6d | Gestes préservés, recherche, accès au même dialogue et retour au bon déclencheur. |
| H7 | À faire : faits, règles et usages | H3, H6b, D2b | Dépendances du brouillon et accès précis, sans expansion globale. |
| D3 | À faire : export et Player multilingues | D1, D2b, H3, H6d | Répliques/choix localisés réellement lus ; garde retirée seulement pour le chemin pris en charge. |
| H9 | À faire : vérification et destinations | H4, H6d, H7, G2, D2b | Analyse honnête, accès aux règles, scènes et documents concernés. |
| H10 | À faire : parcours, performance et retrait ciblé | H0–H7, G1, G2, D1–D3, H9 | Acceptation native et Player du périmètre complet. |

Ordre restant conseillé : **D2a → D2b → H6a → H6b → H6c → H6d → G1 → G2 → H7 → D3 → H9 → H10**. G1 peut être traité dès H4/H2 sans changer les dépendances ; ne pas mener simultanément des modifications des mêmes fichiers. D2 n’attend pas H6 : il expose d’abord l’éditeur de document partagé que H6 consommera.

H8 reste remplacé par D1–D3. H6a–H6d séparent composition, règles, panneau spatial et navigation ; G1/G2 rendent explicite la reprise du graphe auparavant exclue ; D2a/D2b séparent bibliothèque et édition. Aucune de ces divisions n’introduit de nouveau modèle métier. Chaque sous-lot a ses tests, sa preuve native Release sur copie et sa clôture propre ; une coque visuelle ne suffit pas à déclarer le lot parent terminé.

## 6. H0 — fixer la référence et caractériser le comportement existant

**État :** livré historiquement par `d4b3f019c`. Dans les sections H0–H5, les cases décrivent le protocole de revalidation à reprendre lorsqu’un chemin est retouché ; elles ne remettent pas ces lots à zéro et ne constituent pas des résultats fraîchement exécutés. La nouvelle référence est fixée par la section 1, sans relancer H0 pour cette tâche documentaire.

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

**État :** cadre natif livré par `29cd3b884`. Les nouveaux libellés et la grande composition centrale relèvent de H6a ; la huitième entrée Cinématiques de la maquette ne devient pas un acquis H1.

**Modifier :** `presentation/features/story/story_page.dart`, `map_builder/map_builder_page_story.dart`, les deux fichiers ARB. Créer les quatre widgets de structure de la section 4 et `story_workspace_state.dart`.

- [ ] Conserver le rail et la barre supérieure existants ; remplacer la barre de quatre onglets par la navigation secondaire à sept entrées.
- [ ] Réutiliser `StudioSidebar`, `StudioNavigationEntry`, `StudioPageHeader`, les boutons, badges, champs et états du design system. Étendre une primitive seulement lorsqu’une variante manque réellement.
- [ ] Conserver un contenu central extensible et un inspecteur pour les sections qui l’utilisent. H6a compose liste compacte + grand éditeur de Déclencheurs + contexte secondaire repliable ; ne pas enfermer QUAND/SI/ALORS dans l’inspecteur générique. Une seule surface possède le défilement principal de chaque liste.
- [ ] Conserver les dimensions de navigation et d’inspection autour de 240 et 320 pixels là où elles restent pertinentes. Comparer aussi à 1280×720, taille vérifiée pour la maquette, puis 1280×800, 1440×900 et 1920×1080 ; rendre le contexte repliable sans masquer l’édition centrale ni ses commandes.
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

**État :** livré par `304ef09be`. H6d prolonge ces garanties pour le lien exact Interactions → Déclencheurs, les filtres de carte, les sources absentes et le retour spatial ; ces nouveaux parcours ne sont pas annoncés déjà prouvés par H2.

**Modifier :** `story_page_navigation.dart`, `map_builder_page_story.dart`, `map_builder_page_scene.dart`, `map_builder_header.dart`, `map_builder_story_history.dart`, et l’état applicatif Histoire. Créer `story_history_scope.dart`.

- [ ] Conserver séparément pour chaque section la sélection stable, la requête, les filtres, le regroupement et la position de liste. Les offsets et contrôleurs de défilement restent en présentation ; les identifiants et filtres sont des données pures.
- [ ] Transporter un contexte d’origine lors des ouvertures Carte et scène. Un retour depuis une scène puis depuis une carte doit rétablir l’histoire, le chapitre, le jalon et la liste d’origine, sans reconstruire une sélection arbitraire.
- [ ] Pour le complément H6d, transporter projet, carte, identité de source et identité de règle, puis restaurer la sélection spatiale et les contextes d’origine. Ne pas convertir un changement de filtre ou d’écran en copie de document ; une carte sans source n’hérite pas de la sélection d’une autre carte.
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

**État :** livré par `82e67ac3b`, preuves historiques conservées en section 3. La nouvelle conception des déclencheurs ne change ni ordre de journal, ni liens, ni conditions de jalons.

**Modifier :** `trame_view.dart`, `trame_detail.dart`, `trame_milestone_detail.dart`, `trame_start.dart`, `trame_journal.dart`, `trame_clues.dart`, `trame_outside.dart`, les contrôleurs et éditions de `features/storyline/application/`.

**Créer :** listes de chapitres et jalons, `trame_conditions.dart`. Conserver `TrameSelection` ou le migrer dans l’état Histoire sans double source de sélection.

- [ ] Présenter l’histoire choisie, ses chapitres, les jalons du chapitre sélectionné et leur fiche dans l’inspecteur. Proposer un sélecteur si plusieurs histoires principales ou d’autres types existent déjà.
- [ ] Dans un projet vide, proposer « Créer une histoire » avec nom, type et premier chapitre explicites. Réutiliser `startStoryline` ; ne pas créer un objet caché lors de l’ouverture.
- [ ] Raccorder créer, renommer, réordonner et archiver aux méthodes existantes. Conserver les éléments archivés accessibles par filtre et préserver leurs références.
- [ ] Afficher les conditions au niveau du jalon. Pour une forme simple prise en charge, construire une condition par les opérations canoniques existantes ; pour une forme complexe, afficher une synthèse fidèle et conserver son expression intacte.
- [ ] Expliquer que les liens organisent la trame et que les déclencheurs lancent les scènes. Ne pas présenter la condition d’entrée comme une garantie de verrouillage du journal ou du jeu.
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

**État :** catalogue livré par `c0a77dfb7`, preuves historiques conservées en section 3. Réutiliser `scene_catalog_controller.dart`, `scene_catalog_memberships.dart`, `scene_catalog_view.dart`, `scene_catalog_inspector.dart` et `scene_catalog_filters.dart` existants. G1/G2 ci-dessous sont des travaux restants, pas une livraison rétroactive de H4.

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
- [ ] Dans H6b/G2, utiliser ce catalogue pour choisir uniquement une association de scène, puis ouvrir son graphe. Les usages emploient le libellé auteur Déclencheurs ; aucun porteur n’est inventé pour une scène sans carte.
- [ ] Garder la création de scène dans les parcours existants de comportement. La maquette retenue ne nécessite pas d’ajouter une création autonome de scène orpheline.

**Nouveaux tests :** `test/scenes/scene_catalog_controller_test.dart`, `scene_catalog_memberships_test.dart`, `scene_catalog_work_counts_test.dart`, `test/presentation/story_scene_catalog_test.dart`.

**Cas à prouver :** scène hors carte ; scène seulement dans le brouillon ; manifeste partiel ; lien direct de chapitre ; rattachements multiples enregistrés ; références cassées ; filtres combinés ; sélection disparue ; aucune carte lue pour la liste ; une scène chargée pour sa fiche ; aucune relecture des autres scènes après renommage.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/scenes/scene_catalog_controller_test.dart test/scenes/scene_catalog_memberships_test.dart test/scenes/scene_catalog_work_counts_test.dart test/presentation/story_scene_catalog_test.dart test/scenes/scene_focus_catalog_test.dart test/presentation/map_builder_story_graph_preview_test.dart
```

**Sortie du lot :** trouver et ouvrir toute scène connue sans passer par une carte ; aucun faux « introuvable » lié au manifeste partiel.

### G1 — reprendre le rendu Blueprint et harmoniser la palette

**État :** à réaliser après H4/H2. **Modifier :** sous `apps/avelune_studio/lib/presentation/features/scene_focus/`, `scene_focus_workspace.dart`, `scene_focus_side.dart`, `graph/scene_graph_card_tile.dart`, `scene_graph_painters.dart`, `scene_graph_labels.dart`, `scene_graph_toolbar.dart`, `scene_graph_step_menu.dart`. **Créer :** `graph/scene_graph_palette.dart`.

- [ ] Caractériser les projections et ports des étapes actuelles avant le changement de rendu. Reprendre grille, cartes, bandeaux de catégories, liens, sélection, barre d’outils et palette de la capture Blueprint en conservant `SceneFocusController` et les éditions canoniques.
- [ ] Utiliser les tokens du design system pour harmoniser catégories, états, ports et liens ; les couleurs de QUAND/SI/ALORS, des scènes et des dialogues doivent rester cohérentes sans confondre leurs responsabilités. Adapter une primitive du design system si nécessaire, sans couleur codée dans un écran.
- [ ] Grouper les types réellement authorables dans les familles visuelles de la référence. Une palette illustrée en neuf familles ne prouve ni neuf nouvelles capacités ni l’exhaustivité des actions natives ; garder accessibles les types existants non illustrés.
- [ ] Conserver identités, sorties, ordre, branchements et métadonnées de disposition déjà portées par les contrats. Un connecteur de données illustratif ne devient pas une nouvelle sémantique d’exécution ; aucun AST Blueprint/Scratch n’est créé.
- [ ] Les cadres/groupes décoratifs de la maquette ne justifient pas un nouveau format : utiliser les métadonnées déjà prises en charge, ou annoncer précisément l’écart restant au lieu de prétendre les sauvegarder.
- [ ] Comparer les quatre exemples de la référence : dialogue à choix, combat de dresseur, quête sur plusieurs cartes et mise en scène. Les représenter avec les étapes natives réellement prises en charge sur copie/fixture ; « mise en scène » ne réintroduit ni catalogue Cinématiques ni nouvelle timeline. Un exemple fictif ne constitue pas une preuve de jouabilité.
- [ ] Charger la seule scène ouverte ; conserver le cache et l’invalidation ciblée des miniatures H4. Comparer à 1280×720 et aux tailles natives de H1, y compris une scène de 99 étapes.

**Adapter :** `test/scenes/graph/scene_graph_view_test.dart`, `scene_graph_canvas_test.dart`, `scene_graph_inspector_test.dart`. **Créer :** `test/scenes/graph/scene_graph_blueprint_layout_test.dart`, `scene_graph_palette_test.dart`, tous sous `apps/avelune_studio/`.

**Commande prévue :** depuis `apps/avelune_studio`, `flutter test --no-pub test/scenes/graph -r failures-only`, puis `flutter analyze --no-pub`.

**Preuve native de sortie :** ouvrir depuis le catalogue une scène à choix, comparer sa structure et ses couleurs à la capture, sélectionner et déplacer un bloc, annuler/refaire, enregistrer puis rouvrir avec les mêmes liens et positions pris en charge. Présenter séparément fidélité visuelle, sauvegarde observée et écarts décoratifs restants ; aucune promesse de nouvelle capacité moteur.

### G2 — compléter les outils du graphe et ses accès contextuels

**État :** à réaliser après G1/D2b/H6d. **Modifier :** dans le même répertoire, `graph/scene_graph_canvas.dart`, `scene_graph_canvas_pointer.dart`, `scene_graph_canvas_edits.dart`, `scene_graph_camera.dart`, `scene_graph_toolbar.dart`, `scene_graph_inspector.dart`, `scene_focus_workspace.dart`, `scene_step_form.dart`, `scene_step_form_fields.dart`. **Créer :** `graph/scene_graph_outline.dart`.

- [ ] Reprendre « Ma scène / Palette », recherche des étapes de la scène courante, usages connus, focus de sélection, zoom, cadrage et minicarte/aperçu de navigation selon la référence ; utiliser les projections existantes plutôt qu’un deuxième document.
- [ ] Préserver les gestes natifs d’ajout, connexion, déplacement, sélection multiple, suppression, copie/collage, clavier et annulation. Les liens proposés et leurs refus restent ceux des ports natifs ; un changement de couleur ou d’outil ne crée pas d’action implicite.
- [ ] Raccorder l’aperçu de langue et « Texte et traductions » à D2b sur le document réellement référencé par l’étape. Pour une étape avancée non représentable par un champ simple, ouvrir son éditeur pris en charge sans réécriture de source.
- [ ] Depuis ALORS, ouvrir la scène exacte ; revenir au même déclencheur, à ses filtres et à son origine locale. Depuis un diagnostic fiable, focaliser le bloc ; sans identité de bloc fiable, ouvrir la scène et ses diagnostics.
- [ ] Préserver les usages et avertissements de partage, les sorties obligatoires non reliées, les étapes non prises en charge et leurs gravités. Ne pas convertir une vérification locale du graphe en analyse globale ou en simulation Player.

**Correspondance Unreal / maquette / natif à établir puis éprouver :** la demande couvre aussi les clics, raccourcis et gestes adaptés au projet. Au démarrage de G2, relever dans la maquette et les handlers natifs le geste exact, son contexte de focus, ses modificateurs par plateforme, l’action canonique appelée et son résultat attendu. Compléter cette correspondance dans la livraison du sous-lot, sans nouveau rapport obligatoire. Les observations de code ci-dessous ne sont pas des preuves d’interaction native exécutée pendant cette révision.

| Action | Base native observée dans le code, à préserver et revérifier | Raccordement maquette et écarts à qualifier en G2 |
|---|---|---|
| Sélection simple/multiple/rectangle | Dans `scene_graph_canvas_pointer.dart` : clic principal, ajout/retrait avec Shift, rectangle sur fond et base additive. | Vérifier sélection depuis liste/outline, rectangle, multi-sélection et état visible ; ne pas attribuer un autre modificateur à Unreal sans l’avoir relevé. |
| Déplacement des blocs | Glissement principal des blocs sélectionnés, validation à la fin du geste. | Garder déplacement multiple, seuil de glissement et transaction d’annulation unique ; ne pas muter le graphe pour un clic de sélection. |
| Déplacement de la vue | Glissement secondaire ou bouton du milieu ; le clic secondaire immobile est distingué du déplacement. | Vérifier souris et pavé tactile, et l’absence de menu après déplacement ; annoncer toute adaptation nécessaire plutôt que copier un binding supposé. |
| Zoom/cadrage | Handlers de molette/pincement et caméra existants, commande de cadrage dans `scene_graph_toolbar.dart`. | Relever les modificateurs, point d’ancrage, limites, cadrage et éventuel aperçu de navigation ; aucun raccourci de zoom n’est présumé. |
| Clic droit/menu/ajout depuis un port | Menu après clic secondaire sans déplacement ; opérations d’ajout existantes dans `scene_graph_canvas_edits.dart` et `scene_graph_step_menu.dart`. | Vérifier menu sur fond/bloc, ajout depuis un port et conservation de l’origine du lien ; raccorder seulement les templates et ports compatibles. |
| Connexions | Glissement depuis une sortie ; Alt sur sortie appelle la déconnexion, Échap annule un lien en cours. | Prouver création, suppression et refus de lien, annulation, cible invalide et absence de mutation après abandon ; aucun nouveau port de données ou branchement fictif. |
| Copier/couper/coller/dupliquer/supprimer | Handler du canevas : Meta ou Control + C/X/V/D, Delete/Backspace pour la sélection, gardes d’édition et de presse-papiers. | Vérifier sélection multiple, entrées/sorties, identités nouvelles et refus ; les opérations restent canoniques. Distinguer preuve du handler et usage réel macOS/Windows. |
| Annuler/refaire/enregistrer | Raccourcis du shell dans `map_builder_page_layout.dart`, portée commune H2/H5. | Relever les bindings réels par OS, puis prouver qu’une commande ne s’exécute qu’une fois et ne saute aucune transaction ; ne pas inventer Ctrl+Y ou un raccourci propre au graphe. |
| Recherche/focus d’étape | Outline/recherche G2 à raccorder aux projections ; demande de focus du canevas déjà présente dans `scene_focus_workspace.dart`. | Relever le raccourci de recherche retenu par la référence et son conflit éventuel avec le shell ; en l’absence de binding vérifié, garder la commande visible sans en annoncer un. |
| Focus et saisie de texte | `FocusNode` du canevas et raccourcis de page sensibles à la saisie existent. | Avant le premier clic, vérifier les commandes applicables avec sélection connue ; dans un champ, copier/couper/coller, suppression, sélection de texte et annulation de saisie gardent leur sens, sans supprimer/dupliquer de bloc ni perdre le texte. |

- [ ] Séparer dans le relevé final : gestes déjà présents à préserver, interactions de maquette effectivement raccordées, et écarts dont les contrats ne permettent pas la copie directe. Une ressemblance visuelle ou un handler existant ne valide pas la correspondance.
- [ ] Vérifier macOS et Windows au niveau des bindings, modificateurs, boutons de souris et conflits avec les raccourcis du shell. Un parcours natif macOS ne prouve pas l’usage Windows : fournir sa preuve sur la plateforme si disponible, sinon annoncer explicitement ce contrôle non exécuté et ne pas déclarer la parité de gestes Windows acquise.

**Adapter :** `test/scenes/graph/scene_graph_canvas_keyboard_test.dart`, `scene_graph_canvas_edit_test.dart`, `scene_graph_camera_test.dart`, `scene_graph_clipboard_test.dart`, `scene_graph_edits_test.dart`. **Créer :** `test/scenes/graph/scene_graph_outline_test.dart`, `test/presentation/story_scene_trigger_round_trip_test.dart`, sous `apps/avelune_studio/`.

**Commande prévue :** depuis `apps/avelune_studio`, `flutter test --no-pub test/scenes/graph test/presentation/story_scene_trigger_round_trip_test.dart -r failures-only`, puis `flutter analyze --no-pub`.

**Preuve native de sortie :** déclencheur → graphe à choix → document de dialogue partagé → retour graphe → retour déclencheur → carte d’origine. Éprouver chaque ligne de la correspondance par clics/gestes/raccourcis réels, y compris connexion refusée, menu depuis un port, copie/coupe/collage/duplication/suppression, raccourcis applicables avant le premier clic, focus de recherche et saisie dans les champs. Vérifier qu’aucun raccourci de canevas ne vole la saisie ou n’est exécuté deux fois par le shell ; déplacer/annuler puis sauvegarder/rouvrir. Aucune modification des branchements ou références par simple navigation ou changement de langue. Fournir les écarts et limites par plateforme ; ne pas annoncer la correspondance complète tant qu’une ligne obligatoire reste non éprouvée.

## 11. H5 — rendre le contexte d’édition des comportements explicite

**État :** livré par `3c3fb8109`. Le mot « comportements » reste ici celui des contrats internes ; le libellé auteur devient Déclencheurs en H6a. H5 ne livre ni l’éditeur central, ni le panneau local résumé, ni l’édition multilingue D2.

**Modifier :** `map_builder_story_behaviour_editing.dart`, `map_builder_story_conditions_binding.dart`, `map_builder_story_cases_binding.dart`, `map_builder_story_line_binding.dart`, `map_builder_story_simulation_binding.dart` et les points de composition nécessaires.

**Créer :** `features/game_behaviours/application/game_behaviour_editing.dart`, `presentation/features/map_builder/map_builder_story_catalog_binding.dart`.

- [ ] Extraire le noyau transactionnel commun de l’édition vers une fonction ou un objet applicatif pur recevant explicitement projet, carte de contexte et brouillon partagé. Conserver la sémantique de refus, regroupement, désactivation/réactivation et rollback du chemin actuel.
- [ ] Garder les opérations pures existantes de `features/events/application/behaviour/`. Ne pas réimplémenter le calcul des cas, des conditions ou de répétition/réarmement, historiquement présentés sous « Après ». La réplique simple utilise déjà une scène minimale et un document, jamais une chaîne portée par la règle.
- [ ] Faire appeler ce noyau par Carte avant de brancher Histoire, puis prouver que les parcours Carte existants restent identiques.
- [ ] Pour Histoire, préparer l’atelier narratif et résoudre le porteur sélectionné. Réutiliser `WorldMapSelectionPort.loadMap` pour la seule carte nécessaire ; si cette carte est déjà éditée en mémoire, utiliser sa version courante.
- [ ] Ne pas appeler `_maps.activate` pour rendre la fiche éditable. L’onglet Carte conserve sa carte active, sa sélection et sa caméra tant que l’utilisateur ne demande pas « Voir sur la carte ».
- [ ] Charger uniquement les scènes, faits et sources de dialogue requis par le comportement et ses dépendances ; appliquer leur delta au même `StoryDraft`.
- [ ] Faire rejeter les mutations d’un porteur absent, d’un contexte incomplet ou d’une révision devenue obsolète. Une lecture échouée ne crée pas de comportement de remplacement.
- [ ] Éviter les mutations de porteur dans la fiche d’un comportement hors carte ou cassé ; y proposer les chemins de réparation déjà disponibles et les limites réelles.
- [ ] Brancher la simulation sur le même contexte explicite, avec valeurs temporaires et aucune écriture de faits.
- [ ] En H6b/H6d, préserver ces transactions lors du choix d’une scène et de la navigation vers D2b. Conserver les corrections natives H5 : soumission de texte unique, navigation sûre sans porteur et inspecteur éditable après sauvegarde.

**Nouveaux tests :** `test/game_behaviours/game_behaviour_editing_test.dart`, `game_behaviour_cross_map_test.dart`, `game_behaviour_edit_work_counts_test.dart`.

**Cas à prouver :** même résultat depuis Carte et Histoire ; modification sur carte B alors que Carte affiche A ; version non enregistrée de B utilisée ; refus et rollback atomique ; porteur disparu ; modification rapide A/B sans résultat tardif appliqué au mauvais objet ; une carte pertinente lue et aucune autre ; aucun enregistrement ou export automatique.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/game_behaviours/game_behaviour_editing_test.dart test/game_behaviours/game_behaviour_cross_map_test.dart test/game_behaviours/game_behaviour_edit_work_counts_test.dart test/presentation/map_builder_story_authoring_test.dart test/presentation/map_builder_story_cases_test.dart test/presentation/map_builder_story_conditions_test.dart test/presentation/map_builder_story_line_test.dart
```

**Sortie du lot :** Histoire et Carte partagent les mêmes opérations sans couplage implicite à la carte affichée. Aucune nouvelle dépendance Flutter, filesystem ou adaptateur dans l’application ou le domaine.

## 12. H6 — Déclencheurs centraux et coordination avec Interactions

**État :** à réaliser ; D2a/D2b sont des dépendances réelles. Les noms de fichiers `behaviour` restent internes. Aucun contrat, identifiant persisté, nouveau type de routine ou interpréteur Scratch n’est introduit pour reproduire les blocs visuels. Tous les chemins de tests ci-dessous partent de `apps/avelune_studio/`.

### H6a — installer la liste compacte et le grand éditeur

**Modifier :** sous `apps/avelune_studio/lib/presentation/features/story/`, `story_navigation.dart`, `story_workspace.dart`, `story_page.dart`, `game_behaviours_view.dart`, `game_behaviour_row.dart`, et `features/game_behaviours/application/game_behaviours_controller.dart`, `game_behaviour_rows.dart`, `game_behaviour_groups.dart`. **Créer :** `behaviours/game_behaviour_workspace.dart`, `game_behaviour_list.dart`. Modifier les deux ARB, puis `flutter gen-l10n`.

- [ ] Afficher Déclencheurs, son rôle « Quand lancer les scènes », la liste compacte filtrable par carte/recherche et les états actif, désactivé, à compléter ou référence indisponible. Distinguer non chargé, hors carte et supprimé ailleurs.
- [ ] La sélection ouvre la grande surface centrale QUAND/SI/ALORS, avec répétition séparée et contexte secondaire repliable ; ne pas dupliquer l’édition dans un inspecteur de 320 px.
- [ ] Préserver recherche et regroupements existants ; fait et chapitre reposent sur les index réellement couverts et les relations H4. Pas de recherche plein texte de tous les dialogues sans index adapté ; pas de copie de règle pour l’afficher dans plusieurs groupes.
- [ ] Garder les autres sections et la navigation clavier opérationnelles, sans Cinématiques ; aucun changement de filtre ne crée d’objet ou n’active une autre carte. Les icônes et blocs inspirés de Scratch restent une présentation de règles natives.

**Créer :** `test/presentation/story_trigger_workspace_test.dart`. **Adapter :** `test/presentation/story_workspace_layout_test.dart`, `story_world_page_test.dart`, `test/story_workspace/story_workspace_state_test.dart`.

**Commande prévue :** `flutter test --no-pub test/presentation/story_trigger_workspace_test.dart test/presentation/story_workspace_layout_test.dart test/presentation/story_world_page_test.dart test/story_workspace/story_workspace_state_test.dart`, puis `flutter analyze --no-pub`.

**Preuve native de sortie :** comparer liste, éditeur et contexte à la capture à 1280×720, puis aux tailles H1 ; chercher une règle, changer de carte filtrée, replier le contexte, naviguer au clavier. Projet vide, aucun résultat, lecture seule et erreur doivent rester compréhensibles et sans création cachée. Ce sous-lot ne certifie pas encore toutes les commandes H6b.

### H6b — éditer QUAND, SI, ALORS et RÉPÉTITION

**Modifier :** les points de composition H6a et les bindings H5 existants de déclencheur, conditions, cas, scène, activation et simulation. **Créer :** les sept widgets `behaviours/` H6b listés en section 4.

- [ ] QUAND choisit l’événement et sa source guidée ; SI réutilise les opérations natives, avec ET/OU et conservation des expressions complexes qu’une présentation simple ne sait pas éditer. Modifier un libellé, une scène ou une répétition ne doit pas aplatir ces expressions.
- [ ] ALORS choisit toujours une scène. Le changement ne touche que l’association `sceneId` ; l’ouverture mène au graphe existant, les suites d’actions restant dans Scènes. Une scène minimale affiche au plus un aperçu de dialogue non éditable, une langue d’aperçu, le repli, les états et « Texte et traductions » vers D2b. Aucun dialogue n’est une destination parallèle.
- [ ] Conserver l’action existante de création de scène depuis ce parcours. Pour une scène simple, la transaction crée/référence Début → Dialogue → Fin et son document éditable par D2b, avec les identités D1 ; ne pas introduire une alternative « dire un dialogue » dans ALORS. Une scène avancée n’affiche pas arbitrairement sa première réplique comme si elle résumait toute son exécution.
- [ ] Présenter RÉPÉTITION séparément, avec toutes les politiques natives, notamment le réarmement sur un résultat explicite. Conserver les contrats des événements parallèles ; ne pas les convertir en boucles générales.
- [ ] Conserver les cas d’une même source dans l’ordre consommé par le moteur, les priorités et la désactivation ; expliquer la sélection du premier cas valable dans le dispatch ordinaire. Ajouter, renommer, réordonner et retirer utilisent les commandes existantes et leurs transactions.
- [ ] Créer désactivé et afficher « à compléter » si une référence manque. Caractériser le refus canonique de publication et le brouillon existant avant de brancher la création ; ne pas assouplir `sceneId`, persister une référence inventée ou créer un personnage factice. L’incomplétude reste dans le brouillon du projet, sans état métier privé de vue.
- [ ] Refuser l’activation sans scène valide ou sans résultat de réarmement requis. Un refus, une source désactivée, un porteur disparu ou une révision obsolète ne doivent déclencher ni remplacement automatique ni perte d’édition.
- [ ] Le contexte repliable contient source, carte, priorité, usages et liens de ressources. La simulation utilise les valeurs temporaires H5, sans écrire de faits ni se présenter comme une partie jouée.

**Créer :** `test/presentation/story_trigger_editor_test.dart`, `story_trigger_activation_test.dart`, `story_behaviour_simulation_test.dart`. **Adapter :** `test/game_behaviours/`, les tests `map_builder_story_cases_test.dart`, `map_builder_story_conditions_test.dart`, `map_builder_story_line_widget_test.dart`, `map_builder_story_line_catalog_test.dart` de `test/presentation/`.

**Commande prévue :** `flutter test --no-pub test/game_behaviours test/presentation/story_trigger_editor_test.dart test/presentation/story_trigger_activation_test.dart test/presentation/story_behaviour_simulation_test.dart test/presentation/map_builder_story_cases_test.dart test/presentation/map_builder_story_conditions_test.dart test/presentation/map_builder_story_line_widget_test.dart test/presentation/map_builder_story_line_catalog_test.dart -r failures-only`, puis `flutter analyze --no-pub`.

**Preuve native de sortie :** modifier une règle conditionnelle, sa scène et sa répétition ; réordonner les cas puis annuler/refaire ; ouvrir le dialogue partagé en deux langues ; simuler sans écrire ; sauvegarder, fermer et rouvrir. Essayer un brouillon incomplet, une scène manquante, un résultat attendu absent et une expression complexe. Comparer chaque identité/référence avant/après ; une ressource liée ne disparaît pas lors d’un renommage ou retrait de règle.

### H6c — recentrer le panneau local sur Interactions

**Modifier :** sous `apps/avelune_studio/lib/presentation/features/map_builder/`, `map_builder_story_panel.dart`, `map_builder_story_panel_items.dart`, `map_builder_story_inspector.dart`, `map_builder_story_properties_tab.dart`, `map_builder_story_cases.dart`, `map_builder_story_selection.dart`, `map_builder_space.dart`, `map_builder_space_panel.dart`, `map_builder_page_layout.dart` et les ARB. **Créer :** `map_builder_interaction_triggers.dart`.

- [ ] Remplacer le libellé visible Histoire/Scénario du mode local par Interactions partout où la barre Construction / Jeu / Interactions / Ambiance est composée. Conserver les identifiants internes/persistés, le rail Histoire global et les commandes existantes.
- [ ] Montrer Propriétés en premier : position, apparence, orientation, collision, déplacements de base, emprise de zone et références physiques déjà prises en charge. Préserver personnages, objets, zones, placements et choix Cette carte / Tout le projet.
- [ ] Remplacer le formulaire narratif complet local et son aperçu simplifié de conditions par des cartes événement, conditions fidèles, état, scène liée, répétition et « Modifier dans Histoire » / « Compléter dans Histoire ». Une expression complexe est signalée, jamais réinterprétée comme une condition simple.
- [ ] Conserver ajouter, renommer, réordonner et retirer un déclencheur avec annulation ; retirer une association ne supprime ni scène ni dialogue. Ajouter crée le brouillon inactif H6b et ouvre son identité exacte pour le compléter.
- [ ] Projeter les mêmes définitions et `StoryDraft`. Ne pas déplacer les commandes physiques dans Histoire ou conserver un deuxième formulaire narratif local caché ; les helpers partagés encore appelés restent disponibles.

**Créer :** `test/presentation/map_builder_interactions_panel_test.dart`, `map_builder_interaction_trigger_cards_test.dart`. **Adapter :** `test/presentation/map_builder_story_authoring_test.dart`, `map_builder_story_cases_test.dart`, les tests de propriétés et placement existants retrouvés avant modification.

**Commande prévue :** `flutter gen-l10n`, puis `flutter test --no-pub test/presentation/map_builder_interactions_panel_test.dart test/presentation/map_builder_interaction_trigger_cards_test.dart test/presentation/map_builder_story_authoring_test.dart test/presentation/map_builder_story_cases_test.dart`, puis `flutter analyze --no-pub`.

**Preuve native de sortie :** comparer les deux captures locales ; sélectionner/placer personnage, objet et zone, modifier les propriétés supportées, déplacer la vue et zoomer, annuler/refaire les mutations physiques. Ajouter/renommer/réordonner/retirer une règle puis annuler ; vérifier que les références de scène et dialogue restent intactes, sauvegarder et rouvrir. Les liens vers Histoire doivent déjà atteindre leur règle ; H6d approfondit la matrice de contextes.

### H6d — éprouver la navigation et le contexte commun

**Modifier :** `features/story_workspace/application/story_workspace_state.dart`, `story_history_scope.dart`, `presentation/features/story/story_page_navigation.dart`, `story_behaviour_context.dart`, et sous `presentation/features/map_builder/`, `map_builder_page_story_navigation.dart`, `map_builder_story_catalog_binding.dart`, `map_builder_story_history.dart`. Tous ces chemins sont sous `apps/avelune_studio/lib/`.

- [ ] Le bouton local ouvre projet + carte + source + règle exacts. « Vue dans Histoire » conserve le filtre de cette carte ; le retour restaure la carte d’origine, la sélection, la caméra et les contextes de liste, sans perte de saisie ni activation silencieuse de B pendant l’édition depuis A.
- [ ] Une carte sans source ne sélectionne pas la règle d’une autre carte. Une création depuis un filtre de carte ne propose que des sources appartenant à ce contexte ; une carte vide invite à créer une source dans Interactions.
- [ ] Les modifications sont visibles des deux côtés via le brouillon commun. Un changement d’écran, de filtre ou de langue ne recrée ni règle, ni scène, ni document ; les contrôles de révision, verrous et lectures ciblées de H5 restent en place.
- [ ] La prochaine transaction commune garde les décisions H2 pour boutons et raccourcis. Ne pas sauter une modification physique pour annuler une ancienne règle ; une transaction composite reste entière. Lecture seule, conflit externe et référence disparue conservent les originaux et le brouillon.

**Créer :** `test/presentation/story_interactions_round_trip_test.dart`, `story_trigger_map_context_test.dart`. **Adapter :** `test/presentation/story_workspace_navigation_test.dart`, `test/game_behaviours/game_behaviour_cross_map_test.dart`, `game_behaviour_edit_work_counts_test.dart`, `test/story_workspace/story_history_scope_test.dart`, `test/presentation/map_builder_story_catalog_save_test.dart`.

**Commande prévue :** `flutter test --no-pub test/presentation/story_interactions_round_trip_test.dart test/presentation/story_trigger_map_context_test.dart test/presentation/story_workspace_navigation_test.dart test/game_behaviours/game_behaviour_cross_map_test.dart test/game_behaviours/game_behaviour_edit_work_counts_test.dart test/story_workspace/story_history_scope_test.dart test/presentation/map_builder_story_catalog_save_test.dart`, puis `flutter analyze --no-pub`.

**Preuve native de sortie :** Bourg Geon/Luth → sa règle → dialogue → retour carte, puis Maison du joueur/Maman, puis carte vide. Conserver une édition sur A pendant la consultation/édition de B, vérifier sélection/zoom/déplacement/placement et emprise de zone, conflit de révision et source supprimée. Sauvegarder, fermer et rouvrir par les vrais adaptateurs ; relever les unités lues/écrites si ce chemin change. H6 n’est terminé qu’après les quatre sous-lots, sans retirer les gardes D3.

## 13. H7 — séparer Faits et Règles du monde et fiabiliser les usages

**État :** à réaliser après H3/H6b/D2b. Les destinations auteur deviennent Déclencheurs et documents de dialogue, avec les mêmes identités internes. Le calcul d’usages ne doit pas dépendre de la langue d’aperçu.

**Modifier :** les widgets `game_memory_*` de `presentation/features/story/`, `GameMemoryController`, `GameMemoryRules`, et leurs projections de noms et d’usages.

**Créer :** `features/game_memory/application/game_memory_draft_usages.dart`.

- [ ] Exposer Faits et Règles du monde comme deux entrées du même contrôleur et du même brouillon ; ne pas doubler les copies modifiables des données.
- [ ] Pour les faits, conserver type et identité stables, créer les types déjà pris en charge et renommer le libellé par la commande actuelle. Un renommage de libellé ne devient pas un remplacement global d’identifiant.
- [ ] Dans la fiche, distinguer valeur initiale du projet et valeurs temporaires de simulation. Ne pas suggérer qu’une modification de valeur initiale réécrit une sauvegarde Player existante.
- [ ] Construire les usages à partir de l’index canonique enregistré, puis corriger la contribution des seuls objets modifiés localement : enlever leur contribution enregistrée et ajouter leur contribution actuelle, par objet et rôle.
- [ ] Réutiliser les extracteurs canoniques pour ces contributions ; ne pas écrire un second parseur de conditions ou de Yarn dans le Studio. Si une source n’est pas couverte, conserver `notCovered` et expliquer la limite.
- [ ] Faire pointer les usages vers fait, règle, comportement, scène ou jalon précis. Un résultat incomplet n’autorise ni suppression ni affirmation « aucun usage ».
- [ ] Présenter « Déclencheur » pour un usage d’événement et ouvrir sa règle exacte, sans premier cas arbitraire. Pour un dialogue partagé/localisé, conserver la distinction document, scène utilisatrice et règle déclenchante ; ne pas multiplier les usages par langue ou déduire une référence de la seule phrase d’aperçu.
- [ ] Conserver la suppression d’un fait enregistré désactivée avec explication lorsque le chemin de publication ne la permet pas. L’abandon d’un fait créé dans le brouillon suit la commande existante et ses dépendances.
- [ ] Pour les règles, réutiliser `GameMemoryRules.create/update`, les sélecteurs et compatibilités actuels. Préserver les règles complexes non éditables sans les convertir en règle simple.
- [ ] Charger les cibles cartographiques à la demande. Ne pas utiliser `WorldPort.loadMaps` pour remplir chaque fiche ou chaque sélecteur.

**Nouveaux tests :** `test/game_memory/game_memory_draft_usages_test.dart`, `test/presentation/story_facts_rules_workspace_test.dart`.

**Cas à prouver :** changement de condition reflété dans lectures ; changement d’écriture reflété dans modifications ; annulation rétablit les usages ; couverture incomplète visible ; types et traductions préservés ; suppression non supportée impossible ; règle incompatible refusée ; aucune lecture de carte pour consulter un fait ; mêmes usages après changement de langue ; règle désactivée ou source absente encore identifiable ; navigation vers la bonne carte et règle.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/game_memory test/presentation/story_facts_rules_workspace_test.dart test/presentation/story_memory_page_test.dart test/presentation/story_memory_states_test.dart -r failures-only
```

**Sortie du lot :** identifier où un fait est lu ou modifié dans la couverture déclarée, ouvrir les objets concernés et retrouver leur brouillon actuel.

## 14. D1 à D3 — rendre les dialogues multilingues de bout en bout

### D1 — contrats, identité durable et compatibilité

**État :** livré par `14a3cead2`. Les cases suivantes rappellent le contrat historique à préserver, sans nouvelle certification pendant cette révision. Les gardes de localisation, de conservation des identités et de refus d’export existent déjà ; ne pas recréer un format à partir du store React.

**Propriétaires à examiner :** `packages/map_core/lib/src/dialogue/`, `packages/map_core/lib/src/localization/project_locale_resolver.dart`, `packages/map_authoring/lib/src/dialogue/`, les entrées de dialogue du projet, `features/narrative/domain/dialogue_draft.dart` et les codecs existants.

- [ ] Caractériser les chemins actuels : identité de document, bloc et choix, sources Yarn, compilation des dialogues exportés et résolution de langue du projet. Les identifiants d’édition actuels ne sont pas supposés constituer des clés de traduction persistantes.
- [ ] Définir une identité durable pour chaque unité traduisible, réplique et choix compris. Une modification de texte ou un déplacement conserve l’identité ; une duplication indépendante en crée une nouvelle. Les choix conservent leurs résultats et branchements indépendamment de leur libellé traduit.
- [ ] Définir le stockage des variantes, la langue source, les langues disponibles et le repli en réutilisant `ProjectLocaleResolver` et les contrats existants chaque fois qu’ils couvrent le besoin.
- [ ] Prévoir l’état « traduction absente » et l’état « traduction à revoir » après modification du texte source. Une variante absente ne se transforme pas silencieusement en texte vide.
- [ ] Ajouter le chemin compatible de lecture ou de conversion déterministe nécessaire pour les anciens documents monolingues, sans réécriture à la simple ouverture et sans perte de syntaxe ou de source.
- [ ] Définir les capacités et versions nécessaires pour qu’un contenu multilingue ne soit pas accepté puis silencieusement ignoré par un lecteur incompatible. Ne pas ajouter des tags `#line:` en supposant qu’ils sont compris par tous les lecteurs.
- [ ] Préserver les textes de journal déjà localisés et conserver un seul mécanisme de sélection de langue au niveau du projet.

**Preuves de référence :** round-trip monolingue et multilingue ; identité stable sous édition et réorganisation ; copie indépendante ; choix dont le résultat reste invariant entre langues ; repli déterministe ; ancienne source conservée après échec. Réutiliser `readLocalizedDialogue`, `writeLocalizedDialogue`, `duplicateLocalizedDialogue` dans `packages/map_authoring/lib/src/dialogue/dialogue_localization_document.dart`, les gardes de `dialogue.update` et les codecs D1. Tests existants : `packages/map_core/test/dialogue_localization_test.dart`, `packages/map_authoring/test/dialogue/dialogue_localization_document_test.dart`, `packages/map_authoring/test/domains/narrative/dialogue_localization_actions_test.dart`, `apps/avelune_studio/test/dialogues/dialogue_localization_contract_test.dart`.

### D2a — bibliothèque de documents et aperçu par langue

**État :** à réaliser avant D2b/H6. **Créer :** les fichiers D2a de la section 4. **Modifier :** `apps/avelune_studio/lib/features/game_memory/domain/narrative_index_port.dart`, `data/local_narrative_index_adapter.dart`, `presentation/features/story/story_dialogue_links.dart`, `story_page_navigation.dart`, `story_workspace.dart` et les ARB. Ne pas créer un second catalogue métier pour les « répliques simples ».

- [ ] Étendre `NarrativeTitleKind` pour exposer `dialogues` via la requête canonique existante `narrativeTitle`, filtre `kind: dialogues`, en respectant pagination, révision, préparation et refus déjà présents. Le serveur sait déjà lire ces titres ; un changement de son contrat n’est pas nécessaire pour ce raccordement.
- [ ] Présenter la bibliothèque des documents : identité, titre, usages couverts, recherche sur les champs effectivement indexés, langue d’aperçu et états source/traduit/manquant/à revoir. Les titres seuls ne contiennent pas tous ces états : charger les métadonnées nécessaires aux lignes visibles/sélectionnées par les lectures ciblées existantes, avec couverture annoncée, sans parcourir toutes les sources Yarn.
- [ ] Un aperçu de texte lit uniquement le document demandé/visible, avec cache par identité, révision et langue. Un contenu avancé non interprétable conserve sa source et un accès explicite à l’éditeur pris en charge ; il n’est pas converti pour remplir la liste.
- [ ] Conserver filtres, sélection et origine. L’ouverture transporte l’identité du document, non une copie de texte ou la première règle qui l’utilise. Une ressource partagée n’est pas dupliquée par entrée ou par langue.
- [ ] Afficher séparément aucun document, aucun résultat, préparation requise, erreur de lecture, langue manquante et couverture partielle. Un compteur « à compléter » ne devient exhaustif que si sa lecture le prouve ; les 620 dialogues historiques ne sont pas un décompte courant.

**Créer :** sous `apps/avelune_studio/`, `test/dialogues/dialogue_catalog_controller_test.dart`, `dialogue_catalog_work_counts_test.dart`, `test/presentation/story_dialogue_catalog_test.dart`, `test/presentation/story_dialogues_navigation_test.dart`. **Adapter :** les tests existants de l’adaptateur d’index.

**Commande prévue :** depuis `apps/avelune_studio`, `flutter gen-l10n`, puis `flutter test --no-pub test/dialogues test/presentation/story_dialogue_catalog_test.dart test/presentation/story_dialogues_navigation_test.dart -r failures-only`, puis `flutter analyze --no-pub`.

**Preuve native de sortie :** bibliothèque avec document partagé, aperçu FR puis langue absente, recherche et accès au document exact depuis la bibliothèque et un accès contextuel existant. Comparer à la capture Dialogues, vérifier que navigation/aperçu ne créent aucune règle/scène, et qu’ouvrir la liste ne lit pas toutes les sources. Le rendu de bibliothèque seul ne vaut pas édition localisée D2b.

### D2b — éditeur de document et traductions partagés

**État :** à réaliser après D2a et avant H6a. **Créer :** les fichiers D2b de la section 4. **Modifier :** sous `apps/avelune_studio/lib/`, `features/narrative/domain/dialogue_draft.dart`, `features/narrative/application/dialogue_draft_codec.dart`, `features/dialogues/domain/dialogue_port.dart` et son adaptateur si leur contrat ne transporte pas encore les informations D1 nécessaires ; réutiliser `features/story_draft/` pour les transactions. Raccorder `presentation/features/story/story_page_navigation.dart`, les accès de dialogue du graphe et `presentation/features/map_builder/map_builder_story_line_binding.dart` au même document. Aucune nouvelle commande canonique n’est supposée avant examen de `dialogue.update` et de la copie localisée existants.

- [ ] Afficher source et traduction côte à côte, avec langue source explicite, sélecteur de langue du contenu indépendant de la langue Studio, états source/traduit/manquant/à revoir, repli visible et usages. Le nombre de langues vient du projet, pas des exemples FR/EN/ES.
- [ ] Modifier une variante sans écraser source, autre langue ou identité d’unité. Modifier la source conserve les variantes et les marque à revoir par D1 ; changer de langue termine ou conserve la saisie dans le brouillon commun sans mutation cachée.
- [ ] Couvrir répliques, narration et libellés de choix ; conserver résultats, branchements, interpolations, portraits et métadonnées. La langue ne change ni le `sceneId`, ni la référence de dialogue, ni les identités des unités.
- [ ] La bibliothèque et les accès contextuels ouvrent le même document. H6b/G2 consomment ensuite cet éditeur, sans dépendance inverse de D2 vers H6. Supprimer l’ancien message « Une réplique simple reste dans son comportement » ; une scène simple référence toujours son dialogue.
- [ ] Signaler les usages et l’impact d’un document partagé avant édition ; proposer la copie indépendante par les helpers localisés canoniques et publication transactionnelle, avec nouvelles identités d’unités et variantes conservées. Ne pas modifier les autres références sans action explicite.
- [ ] Une modification appartient à `StoryDraft` et à l’historique commun. Les commandes de validation de formulaire rejoignent le même Enregistrer projet ; un bouton de maquette ne justifie ni sauvegarde privée ni acquittement durable prématuré. Annulation de saisie et annulation de transaction respectent les conventions existantes.
- [ ] Préserver Yarn avancé, choix et textes non représentables sans réécriture destructive. Une référence cassée, un conflit de révision, la lecture seule ou une publication refusée gardent originaux et brouillon récupérables. Ne pas retirer la garde d’export D3.

**Créer :** sous `apps/avelune_studio/`, `test/narrative/dialogue_localization_editing_test.dart`, `test/presentation/story_dialogue_language_fields_test.dart`. **Adapter :** `test/presentation/story_dialogues_navigation_test.dart`, `test/narrative/dialogue_draft_codec_test.dart`, `test/dialogues/dialogue_localization_contract_test.dart`, `test/presentation/map_builder_story_line_catalog_test.dart` et les tests de publication existants.

**Commande prévue :** depuis `apps/avelune_studio`, `flutter test --no-pub test/presentation/story_dialogues_navigation_test.dart test/narrative/dialogue_localization_editing_test.dart test/presentation/story_dialogue_language_fields_test.dart test/narrative/dialogue_draft_codec_test.dart test/dialogues/dialogue_localization_contract_test.dart test/presentation/map_builder_story_line_catalog_test.dart`, puis `flutter analyze --no-pub`. Rejouer les tests D1 des packages réellement touchés.

**Preuve native de sortie :** ouvrir le même document partagé depuis deux accès, modifier sa source, constater une traduction conservée à revoir et une langue manquante avec repli, modifier une traduction, annuler/refaire, sauvegarder puis fermer/rouvrir. Vérifier source et traduction côte à côte, choix aux mêmes résultats et identités/références inchangées. Copier indépendamment et prouver que l’original ne change pas. L’export localisé reste refusé tant que D3 n’est pas livré.

### D3 — export et lecture par le Player

**État :** à réaliser après D1/D2b/H3/H6d. Le refus `dialogueLocalizationRuntimeUnsupported` est une garde réelle à conserver jusqu’à prise en charge complète du chemin exporté et du lecteur ; une interface de traduction réussie ne suffit pas.

**Propriétaires à raccorder :** compilation et documents de dialogue dans `packages/map_core/lib/src/dialogue/`, export canonique dans `packages/map_authoring`, export Studio et résolution/chargement des dialogues dans `packages/map_runtime/lib/src/application/`.

- [ ] Exporter les variantes et leur identité par le chemin canonique, en conservant les contrats de compatibilité définis dans D1.
- [ ] Déclarer les capacités nécessaires, valider le paquet et son lecteur, puis remplacer le refus seulement pour le chemin réellement pris en charge. Un Player incompatible doit refuser clairement le nouveau contenu sans altérer un paquet, une sauvegarde ou une partie existante ; ne pas le contourner par un export monolingue silencieux.
- [ ] Résoudre les répliques et libellés de choix avec la langue effective du jeu, puis son repli. Réutiliser le mécanisme de préférence linguistique déjà présent ; ne pas introduire une langue différente propre au seul système de dialogue.
- [ ] Conserver interpolations, portraits, métadonnées et règles de feedback lorsqu’un texte change de langue ; valider les contraintes qui dépendent du texte réellement affiché.
- [ ] Tester une traduction absente, un tag régional comme `fr-CA`, une langue non disponible et une ancienne exportation monolingue.
- [ ] Exécuter un parcours natif Studio → sauvegarde/réouverture → export → Player dans deux langues, avec une réplique simple et un dialogue à choix. Le résultat d’un choix doit rester identique quelle que soit la langue.
- [ ] Vérifier que la langue choisie est réappliquée correctement lors d’une nouvelle session par le mécanisme existant ; ne pas modifier le format de progression sauvegardée pour stocker les traductions.

**Modifier :** `packages/map_authoring/lib/src/domains/distribution/runtime_project_projection_builder.dart`, les codecs/compilation de `packages/map_core/lib/src/dialogue/` requis par D1 et `packages/map_runtime/lib/src/application/load_dialogue_content.dart`, `resolve_dialogue.dart`, `parse_yarn_dialogue.dart`, uniquement sur les chemins concernés. Préserver les barrels publics et les frontières Dart/Flutter.

**Adapter :** `packages/map_authoring/test/domains/distribution/dialogue_localization_export_guard_test.dart`, `packages/map_runtime/test/compiled_dialogue_runtime_test.dart`, `dialogue_choice_cancellation_test.dart`, les tests d’export Studio. **Créer :** `packages/map_authoring/test/domains/distribution/dialogue_localization_export_test.dart`, `packages/map_runtime/test/localized_dialogue_runtime_test.dart`.

**Commandes prévues :** dans `packages/map_authoring`, `dart test test/dialogue/dialogue_localization_document_test.dart test/domains/narrative/dialogue_localization_actions_test.dart test/domains/distribution/dialogue_localization_export_guard_test.dart test/domains/distribution/dialogue_localization_export_test.dart`, puis `dart analyze` ; dans `packages/map_runtime`, `flutter test --no-pub test/localized_dialogue_runtime_test.dart test/compiled_dialogue_runtime_test.dart test/dialogue_choice_cancellation_test.dart`, puis `flutter analyze --no-pub`. Étendre l’analyse aux autres packages réellement modifiés et prouver la parité MCP des contrats/actions canoniques affectés.

**Preuves de sortie :** variantes réellement visibles dans le Player, repli correct, progression identique et ancien contenu monolingue protégé toujours lisible. Parcours natif Studio → sauvegarde/réouverture → export → Player en deux langues, choix au même résultat, langue régionale, traduction manquante et ancienne exportation ; formats/capacités inconnus laissent les octets originaux intacts. Ne pas modifier le format des sauvegardes de progression pour y stocker les traductions ; les tests de sauvegarde/reprise au format courant restent requis.

## 15. H9 — rendre la vérification complète sur son périmètre et navigable

**État :** à réaliser après H4/H6d/H7/G2/D2b. La navigation réutilise les destinations précises H6d, le graphe G2 et les documents D2b, sans nouvelle interprétation des conditions ou des variantes.

**Modifier :** `verification_view.dart`, `story_page_navigation.dart`, `ProjectVerificationController`, `verification_problems.dart`. Créer `verification_snapshot.dart`.

- [ ] Conserver le lancement explicite sur les données enregistrées, la progression et l’annulation du travail appartenant à cette analyse.
- [ ] Conserver dans le résultat applicatif les informations de couverture nécessaires du rapport et la révision enregistrée analysée. Marquer les résultats périmés si cette révision change ; signaler séparément un brouillon non enregistré.
- [ ] Après annulation, erreur de lecture ou dimension non vérifiée, afficher un état partiel ou incomplet. La présence d’une liste vide ne suffit pas pour afficher « Aucun problème ».
- [ ] Présenter gravité, objet, emplacement, message compréhensible et action disponible. Utiliser un compteur de navigation qui indique aussi l’absence d’analyse ou sa péremption.
- [ ] Ouvrir directement une scène sans porteur, une fiche de fait, une règle ou un jalon. Ne pas convertir une destination de scène en premier comportement arbitraire.
- [ ] Ouvrir un déclencheur par son identité et sa carte, et un document de dialogue par son identité ; conserver le contexte de retour. Une source ou référence disparue produit un état indisponible explicite, jamais une règle de repli sur une autre carte.
- [ ] Distinguer à compléter, désactivé, traduction manquante, repli, traduction à revoir et erreur réellement bloquante selon les contrats. Ne pas inventer de gravité ou annoncer une couverture linguistique exhaustive lorsque le rapport ne l’évalue pas. Conserver les diagnostics d’activation incomplète et le refus d’export D3 tant qu’il s’applique.
- [ ] Sélectionner une étape de graphe seulement si le diagnostic fournit une identité fiable. Sinon, ouvrir la scène et ses diagnostics locaux ; ne pas réutiliser `stepId` de trame comme identifiant de bloc.
- [ ] Conserver les gravités de `diagnoseScene` et la distinction entre diagnostic local et publication refusée. Une scène refusée à l’enregistrement reste dans le brouillon avec une erreur explicite.
- [ ] Ne pas modifier le moteur pour faire correspondre ses résultats aux exemples fictifs de la maquette.

**Nouveaux tests :** `test/verification/verification_snapshot_test.dart`, `test/presentation/story_verification_navigation_test.dart`.

**Adapter :** `test/verification/project_verification_controller_test.dart`, `project_verification_catalog_test.dart`, `verification_page_test.dart`.

**Cas à prouver :** révision qui change pendant ou après analyse ; brouillon non vérifié clairement indiqué ; source illisible ; annulation ; résultats vides mais incomplets ; scène sans porteur ; cible supprimée ; sélection et modification sans déclenchement d’analyse ; gravité inchangée ; déclencheur de B pendant que Carte garde A ; document partagé/localisé ; source désactivée ; référence cassée sans sélection de repli ; absence de couverture des traductions explicitement annoncée.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/verification test/presentation/story_verification_navigation_test.dart test/scenes/graph/scene_graph_checks_test.dart -r failures-only
```

**Preuve native de sortie :** lancer une analyse enregistrée, modifier le brouillon et constater sa portée/fraîcheur ; ouvrir un problème de règle sur B, une scène sans porteur et un dialogue partagé, puis revenir. Annuler une analyse ou rendre une cible indisponible ne doit pas afficher un faux résultat sain. Les tests verts seuls ne valident pas ce parcours.

## 16. H10 — parcours complets, performance et retrait de l’ancien rendu

**État :** à réaliser après tous les lots restants, y compris G1/G2 et D3. La clôture distingue comparaison de maquette, comportement natif Studio, sauvegarde durable et exécution Player.

**Modifier :** les seules intégrations encore nécessaires ; supprimer les anciens widgets devenus sans appelant au fil de leur remplacement, avec leurs seules clés l10n effectivement inutilisées.

**Nouveaux tests :** `test/presentation/story_workspace_journey_test.dart`, `test/narrative/story_workspace_catalog_journey_test.dart`, `test/narrative/story_workspace_work_counts_test.dart`.

- [ ] Réaliser le parcours projet vide → histoire → chapitre → jalons → liens → journal → sauvegarde → fermeture → réouverture par les vrais adaptateurs.
- [ ] Réaliser le parcours trois cartes → trois déclencheurs → cas/conditions → scène simple ou partagée → document de dialogue/traductions → fait commun → annulation/refaire → enregistrement → export sur copie → lecture Player. Même une réplique simple passe par Début → Dialogue → Fin ; aucun texte nouveau n’est stocké dans une règle.
- [ ] Vérifier les refus : projet en lecture seule, conflit d’écriture externe, dialogue manquant, publication refusée, scène partagée et expression complexe. Aucun original ni brouillon ne doit être réinitialisé.
- [ ] Vérifier que les cinématiques existantes et leurs références traversent ce parcours sans être modifiées par le retrait de leur entrée Histoire.
- [ ] Contrôler le journal dans le vrai Player : texte, indices conditionnels, ordre courant, sauvegarde/reprise au format actuel. Ne pas vendre un test de projection comme preuve de ce parcours.
- [ ] Vérifier clavier, focus, tabulation, lecteur d’écran et taille de texte augmentée sur les commandes principales. Les raccourcis de champ restent prioritaires pendant la saisie.
- [ ] Rechercher les appelants avant de retirer les résidus de l’ancien rendu déjà remplacé par H1, le formulaire narratif local remplacé par H6c et les seules clés l10n devenues inutiles. Garder les commandes canoniques, helpers partagés encore consommés, codecs, fixtures historiques utiles et tests de compatibilité ; ne pas confondre ancien vocabulaire interne et code mort.
- [ ] Exécuter la campagne de performance ci-dessous, puis les suites de non-régression pertinentes. Relancer seul tout fichier en échec et indiquer s’il est lié au chantier.

**Parcours d’acceptation obligatoires :**

| Parcours | Preuve attendue |
|---|---|
| Rencontrer un PNJ puis changer sa réplique | Déclencheur → scène minimale → même document ; premier cas valable selon fait simulé, ordre et textes conservés après sauvegarde/réouverture. |
| Scène partagée | Les usages sont annoncés ; modifier la scène concerne ses utilisateurs ; une copie indépendante suit le chemin existant. |
| Scène sans carte | Elle apparaît, s’ouvre et revient au catalogue sans porteur inventé. |
| Rattachement déplacé | Origine annoncée, transaction explicite, retour arrière complet. |
| Journal | Le Player lit les textes exportés et ses règles de progression actuelles ; aucune nouvelle sémantique implicite. |
| Retour Carte / Histoire | Même filtre, même objet et même position de liste ; brouillon identique. |
| Contexte croisé A/B | Modifier la règle de B depuis Histoire conserve la carte A et ses modifications physiques jusqu’à une navigation explicite ; le retour restaure la sélection et la vue d’origine. |
| Carte vide et création filtrée | Aucun déclencheur étranger sélectionné ; invitation à créer une source locale. Une source proposée appartient à la carte filtrée. |
| Brouillon incomplet | Créé inactif ; activation refusée sans scène ou résultat attendu requis ; aucune référence factice et aucune perte du brouillon. |
| Référence cassée ou source désactivée | État fidèle et chemin de réparation disponible ; aucun remplacement, changement de carte ou activation automatique. |
| Cas, répétition et expression complexe | Priorité, ordre, ET/OU et réarmement sur résultat conservés après édition d’un autre champ et annulation/refaire. |
| Dialogue partagé et localisé | Bibliothèque/déclencheur/graphe ouvrent le même document ; source modifiée → variantes à revoir, repli visible, identités/résultats de choix invariants. |
| Renommer/retirer une association | Opération annulable ; scène et dialogue liés restent présents, avec leurs autres usages intacts. |
| Interactions physiques | Position, apparence, orientation, collision, déplacements et emprise supportés restent éditables ; sélection, zoom, déplacement de vue, placement et annulation fonctionnent. |
| Graphe Blueprint | Même scène, mêmes ports/liens et résultats après changement de présentation ; recherche, palette, clavier, navigation et dispositions supportées vérifiées sur petite et grande scènes. |
| Écriture concurrente | Refus explicite, données originales préservées et édition locale récupérable. |
| Vérification incomplète | Aucun faux statut sain et aucune suppression débloquée. |

### Performance : comptages structurels puis mesures natives

Les objectifs 100 ms de retour visible et 500 ms de persistance durable restent des critères d’acceptation des modifications simples. Les anciens chiffres de sauvegarde de scène cités dans le prompt ne sont pas une mesure de cette version.

1. Utiliser une fixture petite et une fixture à deux fois la taille narrative, avec cartes non pertinentes présentes. Mesurer lectures, écritures, décodages et invalidations pour les mêmes opérations.
2. Pour renommer un fait ou un chapitre et éditer un texte de journal : zéro décodage de carte, zéro lecture de dialogue non concerné et zéro validation globale.
3. Pour ouvrir le catalogue : lecture des titres et relations nécessaires, sans ouvrir tous les documents ; pour ouvrir une fiche : seulement son document et ses dépendances.
4. Pour modifier un comportement sur une carte inactive : au plus la carte pertinente si elle n’est pas déjà courante en mémoire, puis aucune relecture non pertinente aux modifications suivantes.
   Pour modifier une traduction : uniquement le document et ses métadonnées/dépendances réelles, sans relire toutes les langues, scènes ou cartes. Les aperçus sont bornés aux lignes visibles et à la sélection ; un filtre de carte ne réimporte aucun document.
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

Lancer uniquement le bundle appartenant à ce build, enregistrer son PID, puis capturer sa fenêtre. Après chaque sous-lot D2a, D2b, H6a–H6d, G1/G2 ou autre changement d’écran, interaction, sauvegarde, annulation ou ouverture, effectuer une vraie passe native conformément à la section « Native Studio verification » des politiques. Ne pas attendre H10 pour essayer les nouveaux écrans. Un lot purement documentaire ne nécessite pas une compilation cérémonielle.

Pour chaque lot concerné : utiliser les parcours d’acceptation dans l’application, couvrir les états pertinents, essayer annuler/refaire puis sauvegarder, fermer et rouvrir, relever les temps et examiner les textes et l’ergonomie. Séparer observations et déductions. Corriger les défauts bloquants dans le même lot avec une non-régression, puis refaire la passe après une correction risquée ou annoncer que le contrôle n’a pas été répété. Un écran non essayé réellement ne peut pas être annoncé terminé.

À produire lors des futurs sous-lots : captures natives utiles du cadre, projet vide, trame, éditeur central QUAND/SI/ALORS/RÉPÉTITION, brouillon inactif, Interactions Propriétés/résumés, bibliothèque, source/traduction, graphe Blueprint, fait/usages, règle, vérification incomplète et retours Carte/Histoire. Les six captures MagicPath de la section 1 et les preuves natives historiques de la section 3 restent distinctes. Aucune capture ne prouve à elle seule la durabilité ou la lecture Player.

### Nettoyage

Enregistrer PID du runner et descendants pendant les tests ; arrêter seulement les survivants de cette exécution après vérification de leur identité. Ne jamais tuer un processus par nom.

Retirer seulement les admissions de catalogue et préférences réellement créées ou modifiées par ce harness, en vérifiant qu’aucune session concurrente ne les a reprises. Supprimer la copie, les exports et le build temporaires appartenant au chantier ; garder seulement les preuves utiles dans un emplacement accepté pour la livraison.

## 18. Commandes finales et critères de sortie

Les commandes suivantes sont prévues pour l’implémentation restante ; elles n’ont pas été exécutées pendant cette révision documentaire. Les cibles nouvelles sont déclarées dans leurs sous-lots ; les créer avant ces commandes. Lancer les fichiers concernés avant les regroupements plus larges et relancer seul tout fichier en échec, avec résultat et attribution explicites.

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter test --no-pub test/story_workspace test/storyline test/game_behaviours test/game_memory test/verification test/scenes test/narrative test/dialogues -r failures-only
flutter test --no-pub test/presentation/story_trigger_workspace_test.dart test/presentation/story_trigger_editor_test.dart test/presentation/story_trigger_activation_test.dart test/presentation/story_behaviour_simulation_test.dart test/presentation/map_builder_interactions_panel_test.dart test/presentation/map_builder_interaction_trigger_cards_test.dart test/presentation/story_interactions_round_trip_test.dart test/presentation/story_trigger_map_context_test.dart
flutter test --no-pub test/presentation/story_workspace_journey_test.dart test/presentation/story_workspace_layout_test.dart test/presentation/story_workspace_navigation_test.dart test/presentation/story_scene_catalog_test.dart test/presentation/story_scene_trigger_round_trip_test.dart test/presentation/story_facts_rules_workspace_test.dart test/presentation/story_dialogue_catalog_test.dart test/presentation/story_dialogue_language_fields_test.dart test/presentation/story_dialogues_navigation_test.dart test/presentation/story_verification_navigation_test.dart test/presentation/map_builder_story_publication_test.dart test/presentation/map_builder_story_catalog_save_test.dart
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
- [ ] Libellés Déclencheurs et Carte · Interactions cohérents partout, sans renommage des contrats/identifiants internes.
- [ ] Liste compacte, édition centrale, contexte repliable et répétition séparée conformes à la nouvelle référence ; ALORS ne propose qu’une scène.
- [ ] Propriétés physiques et gestes de carte préservés ; cartes locales de résumé, gestion réversible et accès précis remplacent le formulaire narratif local.
- [ ] Création inactive, activation protégée, carte vide et création filtrée sans source étrangère ni donnée factice.
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
- [ ] Rendu Blueprint, palette et couleurs harmonisés sur le graphe existant ; ports/liens, choix, gestes et dispositions supportées conservés ; écarts décoratifs explicités sans capacité fictive.
- [ ] Anciens formats conservés ; ancien rendu remplacé retiré seulement après preuve d’absence d’appelants.
- [ ] Aucun fichier Dart manuel ou test ajouté au-dessus de 350 lignes ; aucun commentaire de code ajouté ; aucun affaiblissement d’`analysis_options.yaml`.
- [ ] Captures natives utiles partagées, processus possédés arrêtés et environnement QA nettoyé.
- [ ] Statut Git final relu ; les changements d’autres sessions sont explicitement distingués.

## 19. Parité MCP et limites de l’engagement

MCP parity: N/A pour cette révision documentaire.

La parité MCP reste N/A pour les lots limités à la présentation, à la navigation et aux projections applicatives, y compris le libellé auteur Déclencheurs et le mode Interactions. D2a réutilise la requête de titres de dialogues déjà canonique ; si les métadonnées nécessaires imposent une extension, la traiter explicitement à sa frontière propriétaire. D2b/D3 exigent une vérification de parité dès qu’ils touchent un contrat de données, une action canonique `map_authoring` ou une commande d’éditeur : le chantier complet ne peut pas être annoncé globalement N/A. Les règles de création, d’activation et de copie passent toujours par les chemins canoniques.

Une insuffisance avérée d’une requête ou action canonique doit être isolée et décrite avant de modifier son contrat. Cette évolution déclencherait le skill `skills/using-pokemap-mcp/SKILL.md`, ses preuves de parité et un ajustement ciblé du plan. Elle ne sera pas contournée par un écrivain de fichiers privé du Studio.

Ce plan ne valide pas encore la jouabilité, les performances, la compatibilité en exécution ou les anciennes assertions de tests rouges. Il fixe les preuves nécessaires pour pouvoir les annoncer ensuite.

## 20. Livraison du plan et prochaine étape

Revue de cohérence effectuée par le même agent : référence MagicPath, responsabilités, dépendances entre lots, conservation des sémantiques, fichiers proposés et couverture des parcours. Il ne s’agit pas d’une revue indépendante.

Seul ce document existant est modifié par la révision du 16 novembre ; aucune entrée `.gitignore`, aucun fichier applicatif ou test, aucun nouveau rapport ni Markdown n’est ajouté. Les critères du skill `writing-plans` sont adaptés à la réconciliation du plan existant : conserver ses lots et donner propriétaires, cas, commandes et preuves, sans inventer du code natif ni autoriser un démarrage d’implémentation.

La prochaine étape proposée est **D2a, bibliothèque de documents**, puis D2b avant l’éditeur de Déclencheurs. L’ordre restant complet est celui de la section 5. H0–H5 restent des acquis historiques ; aucune case de la nouvelle refonte n’est cochée par cette seule révision.

### Contrôles réellement exécutés pour le document

| Contrôle | Résultat observé |
|---|---|
| `git status --short --untracked-files=all`, `git branch --show-current`, `git log -14 --format='%h %s'` au démarrage | Arbre propre sur `main`, HEAD `165dde0e9` ; commits H0, D1, H1–H5 retrouvés. |
| Captures de référence | Six fichiers présents et ouverts ; captures de maquette distinctes des preuves natives historiques. |
| Contrôle du lien MagicPath avec `curl -ILsS --max-time 20` | HTTP 200 ; confirme l’accès au lien, pas une nouvelle exécution des parcours ni une inspection du code de la révision MagicPath. |
| Contrôle programmatique des liens et chemins | Aucun lien local cassé ; les chemins explicites absents sont les deux nouveaux tests D3 déclarés. Les autres nouvelles cibles sont déclarées dans leurs sous-lots. |
| Relecture de couverture et dépendances | Acquis historiques distingués ; D2a/D2b, H6a–H6d et G1/G2 bornés, cinématiques exclues, séquence sans dépendance inversée. |
| `git diff --check` | Code de sortie 0, aucune erreur affichée. |
| `bash tools/scripts/check_markdown_hygiene.sh` | Code de sortie 1 : deux README ignorés préexistants sont signalés et comptés comme nouveaux ; aucun Markdown créé par cette révision. |
| Tests Dart / Flutter, analyse statique, build et QA native | Non exécutés pour cette révision documentaire. Les commandes des lots sont des validations futures, distinctes des résultats historiques. |

Les deux fichiers qui font échouer le contrôle Markdown global sont `apps/avelune_android/flutter_runtime/.ios/Flutter/README.md` et `apps/avelune_android/flutter_runtime/.ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`, déjà signalés dans la préparation historique du plan. Ils ne sont ni créés ni modifiés par cette tâche et restent intacts ; le budget de nouveaux documents n’a pas été augmenté pour masquer cet état.

Périmètre Git de cette révision : modification du seul `documentation/reports/avelune_studio/plans/2026-11-15-refonte-histoire.md`, sans staging, commit ou push. Aucun fichier applicatif, test, processus persistant ou environnement QA créé ; les preuves historiques et la session Studio ouverte à la demande de Yoahn ne sont pas touchées par cette tâche documentaire.
