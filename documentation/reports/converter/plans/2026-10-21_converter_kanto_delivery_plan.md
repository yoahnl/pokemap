# Convertisseur Essentials vers Avelune — Plan de livraison Kanto

> Exécution : appliquer `skills/executing-plans/SKILL.md` lot par lot après instruction de réalisation. Les sections 1 à 11 décrivent le plan initial ; la section 12 distingue les résultats exécutés et leurs limites. Les commandes Git d’écriture restent soumises à une demande explicite. Le système d’accélération appartient à une autre conversation.

**Objectif :** sélectionner le projet RPG Maker/Pokémon Essentials de référence dans Avelune Converter, lancer la conversion, ouvrir le résultat dans Studio, le modifier et jouer une progression Kanto vérifiée, en conservant les combats Avelune et sans IA pour traduire le gameplay.

**Architecture :** conserver l’analyse source inerte et les contrats dans `avelune_converter_core`, les entrées/sorties, associations et règles de projection dans `avelune_converter_adapters`, le parcours utilisateur dans `apps/avelune_converter`. Les données produites sont natives Avelune et passent par `map_authoring`. Les règles de gameplay, de combat et de rendu restent dans leurs packages respectifs.

**Technologies :** Dart, Flutter desktop, modèles natifs Avelune, authoring API/JSONL/MCP, Player Flutter/Flame, hôte SwiftUI pour la validation iPhone.

**Date et base :** 21 octobre 2026 ; `main`, `fea811e3f1123790c972a4ebb6457de04bbe341e`. État Git initial propre. Contexte Notion existant : `CV-01–04 — Import automatique Essentials des CS, objets et rencontres`, domaine unique Post Bêta « Monde & narration », page `3fc197a7-bfa5-8186-8403-feb0124a16fa`. Pas de nouveau ticket par correction ou par carte, pas de modification du périmètre bêta.

## 1. Contrat de résultat et limites

### 1.1 Ce que signifie « le convertisseur fonctionne »

- [ ] Une source appartenant à une variante Essentials explicitement admise est reconnue avec des diagnostics compréhensibles.
- [ ] Le parcours public analyse, prépare et écrit le projet sans script de préparation privé, chemin local caché ou modification manuelle de JSON.
- [ ] Toutes les cartes du périmètre sélectionné sont présentes ; pour la source Kanto de référence, le nombre attendu est 383.
- [ ] Les dialogues, événements, pages, portes, rencontres et catalogues sont rapprochés de la source avec une décision traçable ; aucun élément inconnu n’est silencieusement perdu ou activé.
- [ ] Les règles standards nécessaires au parcours annoncé sont traduites ; leurs effets fonctionnent dans le Player et survivent à une sauvegarde/reprise.
- [ ] Le résultat s’ouvre, s’édite, s’enregistre et se rouvre dans Studio.
- [ ] Les limites et adaptations sont visibles avant la conversion et dans son résultat.
- [ ] Le jeu exporté démarre dans une version compatible du Player. La disponibilité TestFlight est une preuve de livraison distincte.

Ce contrat distingue trois niveaux : projet généré, tranche jouable, campagne qualifiée. Un projet généré avec des événements requis encore désactivés ne doit pas être annoncé comme campagne jouable. Un test isolé de bataille ne prouve pas le trajet pour l’atteindre.

### 1.2 Périmètre conservé

- Combats et moteur Avelune ; Pokémon/niveaux source lorsqu’admis, attaques par défaut Avelune lorsque la source ne les précise pas et selon la décision utilisateur existante.
- Analyse déterministe ; aucune exécution Ruby, aucun appel IA nécessaire à une conversion de gameplay.
- Scripts/plugins arbitraires hors objectif. Reconnaître un appel standard connu n’autorise pas à exécuter du Ruby inconnu.
- Mode Safari et machines à sous signalés comme non pris en charge, conformément au choix utilisateur. Si une dépendance indispensable à la progression passe par eux, cette dépendance reste un blocage à expliciter ; une exclusion ne vaut pas réparation de progression.
- Transition Avelune pour les téléporteurs acceptée ; ne pas rouvrir une recherche de reproduction exacte du double fantôme source.
- Source complète et médias licenciés fournis localement ; aucun atlas absent n’est inventé ou téléchargé implicitement. Une substitution éventuelle est déclarée.
- Accélération ×2/×5/×10 : chantier externe. Le présent plan reste exécutable à ×1 et prévoit uniquement son intégration de test lorsqu’elle sera disponible.
- Aucun nouvel objectif de parité de règles de combat Essentials, reconstruction artistique générale, import des sauvegardes RPG Maker ou adaptation de toutes les versions Essentials.

### 1.3 Répertoires

- Application et source : `/Users/karim/Project/pokemonProject/apps/avelune_converter`.
- Projet Kanto déjà proposé aux tests : `/Users/karim/Project/avelune project/Kanto — Portes et progression` ; le préserver, notamment ses modifications utilisateur.
- Source de référence observée : `/Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto` ; résoudre son chemin réel et vérifier ses empreintes avant exécution.
- Futur résultat neuf proposé : `/Users/karim/Project/avelune project/Kanto — Conversion automatique`. Refuser l’écrasement si ce chemin existe déjà ; choisir alors un nom explicite dans l’application.
- Preuves existantes : `/Users/karim/Project/avelune project/Inventaires/Kanto EV-10/lot6/execution`.
- Nouvelle exécution : un seul sous-dossier de preuves identifié par SHA source/outils ; pas de copie complète du dépôt pour chaque passe ni de nouvelle collection de projets sur le Bureau.

## 2. Audit initial : acquis, écarts et preuves

Audit en lecture seule du code et des reçus. Aucun nouveau test de jeu ni build n’est exécuté pour rédiger ce plan. Les résultats ci-dessous sont des preuves antérieures relues, pas des résultats rejoués sur demande.

| Sujet | Constat vérifié dans les sources ou reçus | Conséquence pour le plan |
|---|---|---|
| Parcours public | `converter_app.dart` possède scan, préparation, approbation, écriture et inspection du départ ; `ConverterWorkflow` utilise des workers et des empreintes | Réutiliser le parcours, ne pas recréer un bouton ou un pipeline parallèle |
| Profil automatique | `builtin_source_interpretation_profiles.dart` admet une seule empreinte exacte de `Data/Scripts.rxdata` ; son profil ne couvre pas toutes les déclarations du harness Kanto | Rapprocher les réglages publics et le harness ; distinguer Kanto de la compatibilité Essentials générale |
| Recettes | `ConverterStudyPlanRecipe` conserve profil, sources complémentaires, associations et décisions | Réutiliser la recette pour reproductibilité et relocalisation |
| Writer | `native_project_writer.dart` exige une destination neuve, utilise un staging et une publication contrôlée | Ne pas annoncer de mise à jour publique incrémentale d’un jeu déjà édité |
| Census | `SourceInteractionInventory.build` impose un snapshot et un census complets ; l’exporteur produit les inventaires d’événements/pages | Réutiliser cet inventaire ; ajouter le rapprochement au résultat courant plutôt qu’un nouveau census concurrent |
| Compteurs | `notYetQualifiedPageCount` décrit une qualification non faite par cet inventaire d’observations ; les anciennes catégories de gaps peuvent se recouvrir | Aucun ancien compteur ne doit être utilisé comme nombre actuel de bugs ou comme pourcentage de jouabilité |
| Kanto | 383 cartes dans les preuves de publication et d’ouverture Studio | Ne pas réimporter les cartes avant chaque correction |
| Début de partie | `campaign-prefix-through-parcel-v13.json` atteste un préfixe joué jusqu’au colis/Pokédex | Conserver cette preuve, mais la rejouer sur le résultat neuf pour fermer la chaîne publique |
| Premier badge | `campaign-master-first-badge-cold-smoke-v2.json` atteste une reprise native avec badge et sortie ; `singleRunNewGameToFirstBadgeQualified=false` | La continuité via sauvegardes est utile ; le parcours unique depuis une nouvelle partie reste à qualifier |
| Manoir | `mansion-full-route-final-qualification-v2.json` atteste le trajet Manoir → Clé Secrète ramassée naturellement → arène, sans injection de clé ni repositionnement | Régression à conserver, pas une fonctionnalité à inventer à nouveau |
| Studio | `campaign-first-badge-studio-ui-receipt-v2.json` : ouverture/canvas/383 cartes, mais édition persistée et réouverture froide non qualifiées après problème de focus | Obtenir la preuve visible manquante ; absence de preuve ne signifie pas bug de sauvegarde démontré |
| Paquet | `pending-code-delivery-final-receipt.json` : 819 tests réussis, 27 dépendants de fixtures ignorés, 11 tests MCP ; installation complète automatisée réussie | Ne pas extrapoler ces suites à toute la campagne ou aux tests source ignorés |
| Hôte SwiftUI | `kanto-swiftui-native-install-receipt.json` : import UI puis début d’une nouvelle partie sur My Mac (Designed for iPad) ; iPhone physique non testé | Test macOS et test iPhone séparés |
| Distribution | Le correctif de référence Pokédex est dans le code poussé ; la compilation Xcode Cloud était en cours à la dernière vérification | Ne pas confondre Git, build, traitement Apple et disponibilité TestFlight ; revérifier lors de RC-10 |

Les anciens audits de CS/donneurs et les anciennes listes d’événements absents servent à trouver des candidats ; ils ne prouvent pas qu’un correctif plus récent manque encore. Les preuves doivent préciser source, SHA de code, profil, recette, sortie exacte et mode d’exécution.

## 3. Jalons et ordre d’exécution

Les identifiants `RC-*` désignent uniquement ce plan de fiabilisation ; ils ne remplacent pas les anciens lots AC/EV/CV et ne déclarent pas leurs acquis caducs.

| Lot | Résultat | Nature du travail restant | Dépendances |
|---|---|---|---|
| RC-01 | État courant fiable et priorités de progression | Audit/rapprochement, code seulement si projection manquante | Aucune |
| RC-02 | Préparation Kanto autonome dans l’application | Intégration des règles et décisions encore extérieures au parcours public | RC-01 |
| RC-03 | Conversion neuve par l’interface, reproductible et contrôlée | Qualification publique, corrections conditionnelles | RC-02 |
| RC-04 | Nouvelle partie → premier badge sur cette sortie | Parcours continu, correction des seuls blocages observés | RC-03 ; RC-09A avant remise utilisateur |
| RC-05 | Cartes, portes et connexions fiables à l’échelle du monde | Census structurel + tests des variantes et trajets critiques | RC-01 ; contrôle final sur RC-03 |
| RC-06 | Événements standards, dialogues et cinématiques fiables | Corrections par famille source et par cause commune | RC-01 ; vérification finale après RC-03 |
| RC-07 | Obtention et utilisation des objets, CS et rencontres | Vérification intégrée et corrections ciblées | RC-01, familles RC-06 nécessaires |
| RC-08 | Progression principale de Kanto vérifiée par tranches | Parcours et causes communes, pas campagne d’un seul bloc | RC-04 ; RC-05/06/07 selon tranche |
| RC-09 | Projet réellement modifiable et persistant dans Studio | Qualification édition/API/transports sur sortie neuve | RC-03 ; complément après RC-08 |
| RC-10 | Export et installation jouables, dont iPhone | Qualification du paquet et de l’app compatible | RC-03/04 ; finale après RC-08/09 |
| RC-11 | Conversion réutilisable sur une seconde source compatible | Généralisation bornée et tests de variations | RC-02/03 ; finale après première livraison Kanto |
| RC-12 | Livraison vérifiable et périmètre de compatibilité clair | Synthèse des gates et distribution du convertisseur | Gates du jalon annoncé |

**Jalon J1 — première livraison utile :** RC-01 → RC-02 → RC-03 → RC-09A → RC-04A, avec RC-12 limité à la tranche. L’utilisateur convertit et teste de la nouvelle partie au premier badge sur une combinaison starter/avatar explicitement qualifiée ; toute la suite et les branches restantes ne sont pas annoncées terminées. RC-04B complète ces variantes avant une promesse de prise en charge intégrale du départ Kanto.

**Jalon J2 — Kanto principal :** corrections RC-05/06/07 pilotées par les tranches RC-08, puis RC-09B/RC-10/RC-12. Aucun blocage de progression requis non traité dans le périmètre annoncé.

**Jalon J3 — outil réutilisable :** RC-11 et nouvelle RC-12. Matrice de versions/profils admis et preuve sur une autre source ; ce jalon ne signifie pas « n’importe quel jeu Essentials et tous ses plugins ».

Commencer par le plus petit bloqueur du jalon courant. Les vérifications d’autres familles ne doivent pas retarder J1 si elles ne sont pas nécessaires à son trajet. Si RC-02/03 passent déjà, les fermer avec les preuves au lieu d’inventer du développement.

## 4. Détail des lots

### RC-01 — Réconcilier source, convertisseur et projet courant

**But utilisateur :** savoir exactement quels éléments sont convertis, exclus ou bloquants aujourd’hui.

**Travail :**

- [x] Figer les SHA du code, snapshot source, médias, profil et recette ; relever l’état Git et l’espace disque. Les sources supplémentaires sont choisies explicitement, avec leur provenance ; aucun voisin de dossier lu implicitement.
- [x] Réutiliser le census complet existant pour les cartes, événements, pages, commandes et catalogues ; distinguer une page inactive par condition d’un événement mis en quarantaine.
- [x] Rapprocher chaque événement/page source avec ses objets natifs actuels, ses diagnostics et sa règle de reconnaissance. Classer : traduit, adaptation native déclarée, défaut source, association manquante, mécanique exclue, erreur du convertisseur, preuve runtime manquante.
- [x] Distinguer ces catégories de la criticité : progression nécessaire, contenu optionnel, présentation. Une criticité supposée reste « à vérifier » tant que la source ne justifie pas la dépendance.
- [x] Comparer le parcours UI aux outils Kanto : profil enrichi, programmes déclarés, portes dérivées, ressources partagées, substitutions et catalogues.
- [x] Produire un ledger machine-readable unique avec coordonnées source, famille, cible, motif, dépendances et test témoin. Réutiliser les exports CSV/JSON ; pas de tableau manuel divergent.

**Zones :** `packages/avelune_converter_core/lib/src/source_interaction_inventory.dart`, `packages/avelune_converter_adapters/tool/export_source_interaction_inventory.dart`, `lib/src/converter_workflow.dart`, `tool/lot6_kanto_qualification.dart` ; ne modifier que si une donnée nécessaire est réellement absente.

**Tests :** `source_interaction_inventory_test.dart`, `export_source_interaction_inventory_test.dart`. Positif : couverture exacte de la source. Négatif : carte/événement absent, doublon, mauvais snapshot/profil, historique incompatible. Régression : aucun ancien chiffre de quarantaine utilisé comme verdict courant.

**Sortie :** census rapproché au résultat courant, liste ordonnée des blocages avec témoins reproductibles et inconnues explicitement marquées. Aucun pourcentage global inventé.

### RC-02 — Rendre la préparation Kanto autonome

**But utilisateur :** sélectionner la source et les éventuels fichiers partagés sans demander à un agent de fabriquer un profil privé.

**Travail :**

- [ ] Pour chaque différence RC-01 entre harness et application, décider si elle est une règle générale déjà qualifiée, une association calculable depuis la source, ou une adaptation nécessitant un choix humain.
- [ ] Raccorder les règles générales qualifiées au pipeline public core/adapters ; supprimer la dépendance opérationnelle aux fichiers privés d’Inventaires pour une conversion fraîche. Conserver les preuves historiques comme preuves.
- [ ] Détecter les modules/profils admis sans autoriser de Ruby arbitraire ; comparer les sections pertinentes quand cette reconnaissance est qualifiée. Une modification d’une section réellement utilisée doit invalider la sémantique correspondante.
- [ ] Présenter les associations manquantes et adaptations avant écriture ; un fichier absent n’est pas remplacé silencieusement. Les changements de règles, de clé source, d’origine primaire/partagée ou de profil invalident la préparation et son approbation.
- [ ] Faire fonctionner sauvegarde/reprise/relocalisation de la recette avec tous les réglages nécessaires ; ne pas dépendre des noms de dossiers de cette machine.
- [ ] Conserver les refus explicites pour variantes non admises ; préciser les capacités disponibles au lieu d’afficher une compatibilité générale infondée.

**Zones :** core `source_interpretation_profile.dart`, `source_declared_programs.dart`, `source_event_adaptations.dart` ; adapters `builtin_source_interpretation_profiles.dart`, `converter_workflow.dart`, `converter_study_plan_recipe.dart`, `source_event_study_composer.dart` ; app `converter_app.dart`, `desktop_services.dart`.

**Tests :** `builtin_source_interpretation_profiles_test.dart`, `source_interpretation_profile_store_test.dart`, `converter_study_plan_recipe_test.dart`, `converter_workflow_test.dart`, app `converter_session_lifecycle_test.dart`, `cli_desktop_plan_parity_test.dart`. Cas : mêmes données relocalisées, sections pertinentes altérées, source incomplète, association périmée, reprise de recette, absence d’IA et d’exécution Ruby.

**Sortie :** la source Kanto est préparée depuis une session vierge de l’application ; chaque intervention humaine est un choix explicite disponible dans l’interface, pas une fabrication de données hors produit. La compatibilité d’autres sources reste RC-11.

### RC-03 — Convertir depuis l’application et prouver la sortie

**But utilisateur :** obtenir un projet jouable en suivant le parcours normal du logiciel.

- [ ] Lancer l’application construite sur le SHA retenu, sélectionner la source complète et une destination neuve dans `Project/avelune project`, choisir le périmètre complet et examiner le résumé.
- [ ] Préparer, approuver et convertir par les contrôles publics. Enregistrer recette, profil, adaptations, identités de préparation et reçu de publication.
- [ ] Vérifier 383 cartes pour cette source, présence des catalogues et du départ, validité des références, fermeture des dépendances et diagnostics événementiels. Rapprocher au ledger RC-01 ; l’absence de diagnostic n’est pas un test de progression.
- [ ] Préparer à nouveau la même entrée et comparer des empreintes sémantiques explicites, en distinguant les métadonnées volatiles documentées. Utiliser d’abord les tests synthétiques de reproductibilité ; une deuxième écriture complète réelle n’est faite que si la preuve ne peut pas être obtenue autrement.
- [ ] Vérifier destination existante, source modifiée entre scan et publication, annulation, erreur d’écriture et quota/espace insuffisant par fixtures bornées. L’échec doit laisser le jeu utilisateur intact et ne pas présenter un staging comme résultat terminé.
- [ ] Chronométrer les phases réelles et relever leur consommation disque. Ne pas imposer un objectif en secondes sans baseline ; corriger une régression démontrée et conserver progression/annulation.
- [ ] Garder l’avertissement « projet d’étude/non certifié » tant que les gates de jeu annoncés ne sont pas verts ; n’améliorer le libellé qu’en fonction du niveau effectivement atteint.

**Zones :** `converter_app.dart`, adapters `converter_workflow.dart`, `native_project_writer.dart`, `native_mutation_batches.dart`, `converter_study_plan_recipe.dart`. Aucune refonte générale du writer.

**Tests :** app `converter_app_test.dart`, `converter_session_lifecycle_test.dart` ; adapters `publication_workflow_reproducibility_test.dart`, `native_project_writer_test.dart`, `native_project_writer_manifest_limits_test.dart`, `native_mutation_batches_test.dart`.

**Sortie :** reçu liant le clic au dossier exact, contrôles structurels et sémantiques verts, aucun ajustement manuel post-conversion nécessaire pour le départ annoncé. Cette sortie devient la référence de J1.

### RC-04 — Nouvelle partie jusqu’au premier badge

**But utilisateur :** commencer réellement le jeu converti et obtenir le premier badge sans déblocage artificiel.

- [ ] À partir de la sortie RC-03, créer une nouvelle partie sans sauvegarde préexistante : identité, avatar, introduction, maison, laboratoire et starter par les interactions prévues.
- [ ] Jouer rival, soins et reprise après défaite selon les règles Avelune ; vérifier le déverrouillage de la progression après victoire ou défaite conforme à la source.
- [ ] Récupérer et remettre le colis, obtenir le Pokédex, franchir les blocages du début, traverser la forêt et atteindre l’arène par les déplacements publics.
- [ ] Affronter Pierre, obtenir badge/CT/argent une seule fois, terminer le dialogue, sortir de l’arène, sauvegarder et reprendre dans un processus neuf.
- [ ] Obtenir au moins un parcours continu sans injection de position, d’objet, de badge, de drapeau ou d’équipe ; les sauvegardes naturelles sont permises. Un harnais découpé doit reprendre l’état exact de la session précédente et rester annoncé comme preuve segmentée tant que le run continu n’existe pas.
- [ ] RC-04A : livrer J1 avec un starter et un avatar nommés dans les preuves, choisis par les contrôles normaux. RC-04B : vérifier séparément les autres choix de starter et les deux avatars sur leurs branches divergentes ; réutiliser les segments communs uniquement avec équivalence d’état démontrée. Les variantes non qualifiées restent visibles comme limites de J1 ; ne pas attribuer une couverture totale à un seul starter.
- [ ] Pour tout échec, distinguer problème du convertisseur, défaut runtime, stratégie de test perdante ou défaut de source. Une défaite naturelle contre Pierre n’est pas à elle seule un bug du convertisseur.

**Zones :** core `source_fresh_entry_program.dart`, `source_starter_choice_program.dart`, `source_first_rival_program.dart`, `source_oak_parcel_program.dart` ; adapters bindings/projectors correspondants. Runtime/gameplay seulement si le défaut se situe réellement dans leur contrat.

**Tests :** runtime `source_converted_intro_journey_test.dart`, `source_converted_starter_journey_test.dart`, `source_converted_first_rival_journey_test.dart`, `source_converted_campaign_prefix_journey_test.dart`, `source_converted_home_defeat_recovery_journey_test.dart`, `source_converted_forest_passage_journey_test.dart`, `source_converted_gym_reward_journey_test.dart`. Le test de préfixe actuel s’arrête au colis et ne couvre pas Pierre : ajouter au moment de RC-04 un scénario durable combiné dans `packages/map_runtime/test/source_converted_new_game_first_badge_journey_test.dart` (fichier prévu, non créé par ce plan), en réutilisant les interactions et gardes existantes sans importer un état préparé. Les continuations externes historiques ne remplacent pas ce test de régression versionné.

**Sortie :** J1 jouable et reproductible, sauvegarde au premier badge vérifiée à froid, résultat visible remis à l’utilisateur après RC-09A. Audio et rendu vérifiés séparément des parcours sans fenêtre.

### RC-05 — Monde, portes, connexions et rendu des cartes

**But utilisateur :** circuler normalement sans destination absente, apparition dans un mur ou décor perdu.

- [ ] Construire le graphe des connexions et transferts issus de la source ; vérifier existence des cartes, limites, positions d’arrivée, orientations, autoruns d’arrivée et conditions de retour.
- [ ] Grouper les variantes : portes simples, portes conditionnelles, portes à objet, escaliers, ascenseurs, téléporteurs, trous et connexions de bord. Tester chaque famille avec entrée/sortie et reprise froide.
- [ ] Vérifier qu’un événement devant une arrivée ne rend pas le joueur prisonnier ; respecter l’état du verrou et du déplacement après transfert.
- [ ] Contrôler les identités des médias et atlas, autotiles, transparence, couches/priorités, collisions et animations de terrain ; conserver les régressions des carrés noirs et hautes herbes.
- [ ] Comparer source et sortie à échelle identique sur extérieurs, intérieurs, grottes et cartes combinant plusieurs salles. Deux salles dans une même carte source restent une carte, sauf migration explicitement conçue.
- [ ] Ne pas exiger de parcourir toutes les cases : contrôle exhaustif des références et variantes, inspection des anomalies et passages critiques ; tracer les zones non parcourues manuellement.

**Zones :** core `source_directed_jump_semantics.dart`, `source_events.dart`, normalisation ; adapters `source_event_projection.dart`, `source_static_door_program.dart`, `source_stair_program.dart` et bindings de portes/connexions identifiés par le census ; test source avant modification. Rendu runtime uniquement si cause prouvée.

**Tests :** adapters `source_standard_progression_doors_test.dart`, `source_post_transfer_step_test.dart`, `source_routed_door_profile_test.dart`, `source_event_arrival_validation_test.dart` ; runtime `source_converted_doors_lot4_test.dart`, `source_converted_standard_progression_doors_test.dart`, `source_converted_post_transfer_step_test.dart`, `source_converted_grass_rustle_test.dart`.

**Sortie :** aucun lien natif requis invalide, variantes critiques jouées, écarts visuels listés avec origine source/conversion/runtime établie. Traverser une connexion ne prouve pas toutes les portes conditionnelles.

### RC-06 — Événements, dialogues, pages et cinématiques standards

**But utilisateur :** parler aux PNJ, déclencher les scènes et continuer à jouer sans blocage ou histoire sautée.

- [ ] Reprendre les familles classées RC-01, dans l’ordre des dépendances du jalon ; ne pas activer toutes les quarantaines aveuglément.
- [ ] Vérifier ordre/priorité des pages, switches, self-switches, variables, conditions imbriquées et réévaluation après transfert ou chargement.
- [ ] Vérifier déclenchements action/contact/autorun/parallèle, fin de scène et verrous d’entrée. Un parallèle vide ou dormant n’est pas un événement manquant à activer.
- [ ] Vérifier dialogues multilignes, paramètres textuels, choix, annulation autorisée/interdite, branche d’annulation, saisie de nom et résultat de dialogue.
- [ ] Vérifier déplacements de PNJ/joueur, orientation, visibilité, réactions, attente de fin de route, effets sonores, musique et transitions. Les scènes utilisent les contrats natifs Avelune déjà disponibles.
- [ ] Pour chaque famille mal convertie : fixture minimale causale, oracle source avec fichier/section/lignes, règle déterministe, projection, admission writer et test runtime. Varier les IDs/positions non sémantiques ; refuser un appel proche mais inconnu.
- [ ] Préserver une unité cohérente : pas de demi-scène activée après suppression silencieuse d’une commande indispensable. Une séquence inconnue est explicitement exclue avec son effet potentiel sur la progression.
- [ ] Lire les sources PSDK désignées lorsque la question porte sur sa parité d’animation, de timing ou d’audio ; la logique effective du jeu importé est déterminée depuis sa source Essentials. Ne pas substituer une implémentation Dart à l’oracle source.

**Zones :** core `source_events.dart`, `source_event_adaptations.dart`, `source_declared_programs.dart`, programmes typés ; adapters `source_sequence_program.dart`, `source_event_projection.dart`, `source_event_study_composer.dart`, bindings audio/poses. Les contrats cibles restent dans core/authoring/gameplay/runtime selon leur responsabilité.

**Tests :** core `source_event_conditions_ev02_test.dart`, `source_events_test.dart`, tests de programme ciblé ; adapters `source_dialogue_audio_workflow_lot5_test.dart`, `source_event_catalog_policy_writer_test.dart` ; runtime `source_converted_choice_event_traces_test.dart`, `source_converted_event_traces_test.dart`, `source_converted_standard_commands_lot5_test.dart`, `source_converted_escort_journey_test.dart`.

**Sortie :** chaque famille admise a une preuve de traduction et d’exécution, conservation des effets/sorties, sauvegarde/reprise et cas négatif ; les scènes Ruby personnalisées restent hors périmètre avec diagnostic.

### RC-07 — Objets, CS, rencontres et services reliés à la progression

**But utilisateur :** obtenir puis utiliser ce qui permet réellement d’avancer.

- [ ] Vérifier ramassages visibles/cachés, donneurs, objets clés et consommation : précondition, capacité du sac/équipe, refus/annulation, récompense unique et sauvegarde.
- [ ] Vérifier la chaîne CS complète : donneur/objet → apprentissage ou capacité native prévue → badge/prérequis → obstacle/terrain → effet persistant. Conserver les adaptations de sélection de Pokémon déjà annoncées.
- [ ] Contrôler Coupe, Force, Éclate-Roc, Surf, Flash et Vol lorsqu’ils sont effectivement utilisés par cette source. Cascade/Plongée ou une capacité absente de Kanto ne deviennent pas des exigences de cette livraison.
- [ ] Vérifier Repousse, Corde Sortie, Vélo et cannes : contexte permis/interdit, consommation, restauration d’état après carte/combat/rechargement.
- [ ] Vérifier herbes, eau, pêche, rochers et rencontres statiques lorsqu’une table source existe ; espèces, niveaux, poids, conditions, fréquence et consommation de la rencontre. Aucune table inventée pour un rocher sans table source.
- [ ] Vérifier soins/Centre, boutique, PC, cadeaux/échanges, gains et récompenses nécessaires au parcours ; refuser proprement une espèce, attaque ou objet non associé au catalogue natif.
- [ ] Distinguer règles de combat et données importées. Les valeurs importées ne doivent pas remplacer les règles Avelune ; les attaques par défaut suivent le catalogue natif selon le choix utilisateur.

**Zones :** adapters `source_event_item_bindings.dart`, `source_catalog_projection.dart`, bindings d’obstacles/donneurs/rencontres/catalogues ; core programmes correspondants. Aucune nouvelle mécanique native sans défaut de capacité démontré et décision de périmètre.

**Tests :** `source_tea_giver_test.dart`, `source_inventory_controller_test.dart`, `source_machine_existing_project_real_source_test.dart`, `source_native_surf_projection_test.dart`, `native_cut_move_qualification_test.dart`, `native_encounter_generic_qualification_test.dart`, `native_trainer_catalog_qualification_test.dart` ; runtime `source_converted_inventory_gates_test.dart`, `source_converted_cut_giver_journey_test.dart`, `source_converted_fly_reward_journey_test.dart`, `source_converted_center_nurse_trace_test.dart`.

**Sortie :** pour chaque élément requis, preuve d’obtention naturelle et d’utilisation ; une scène lancée avec un sac ou un badge injecté ne prouve que le mécanisme isolé, jamais cette chaîne.

### RC-08 — Parcours principal de Kanto par tranches

**But utilisateur :** poursuivre la partie au-delà du premier badge et atteindre une fin annoncée sans raccourci de QA.

La liste suivante définit des tranches candidates à confronter au graphe source RC-01. Les noms FR sont des repères de lecture, pas une affirmation que ce projet suit exactement tous les jeux officiels. L’ordre et les dépendances sont ceux de la source. Les extensions optionnelles/îles sont classées séparément avant toute promesse de « Kanto complet ».

| Sous-lot | Parcours candidat | Témoins et conditions à relever |
|---|---|---|
| RC-08A | Après Pierre, Mont Sélénite, Azuria et ses sorties | Rival/PNJ bloquants, portes, badges et objets source requis, Centre, sauvegarde |
| RC-08B | Léo, routes vers Carmin, bateau et Coupe | Billet/accès, capitaine et obtention naturelle de la CS, déverrouillages, arène selon graphe |
| RC-08C | Céladopole/Safrania et accès conditionnels | Thé, gardes, repaire/ascenseurs, cartes/objets clés et drapeaux réellement utilisés |
| RC-08D | Lavanville et Tour Pokémon | Condition de visibilité/objet requis, événements spectres, Fuji, récompense et blocages associés |
| RC-08E | Parmanie et accès aux capacités d’exploration | Surf, Force, objets/donneurs, dépendance éventuelle au Safari et décision explicite si mécanique exclue indispensable |
| RC-08F | Manoir, Clé Secrète et arène de Cramois’Île | Rejouer la régression existante sur la nouvelle sortie, clé naturelle, porte avant/après clé, victoire et récompenses |
| RC-08G | Dernière arène, route de fin, Ligue/fin source | Badges requis, rochers/portes, chaîne de combats, récompenses et état de fin réels |
| RC-08H | Contenu optionnel et variantes annoncés dans le census | Îles, intérieurs isolés, légendaires/rencontres uniques, quêtes et alternatives : qualifiés ou explicitement hors tranche |

**Méthode commune à chaque sous-lot :**

- [ ] Définir départ, arrivée, prérequis, événements/capacités et test existant pertinent depuis la source.
- [ ] Utiliser une sauvegarde naturelle de la tranche précédente, empreinte vérifiée, sans fabriquer les conditions manquantes.
- [ ] Jouer les contrôles publics jusqu’au prochain jalon, avec au moins une sauvegarde/reprise froide et une répétition d’interaction consommée.
- [ ] Corriger les causes communes dans le convertisseur ; retester d’abord une projection bornée et un voisin négatif. Publier les changements ciblés via authoring canonique sur la seule référence QA concernée.
- [ ] Retenir les preuves causales et le segment utile ; conserver un chaînage exact des sauvegardes. Ne pas prétendre à un run unique si les sessions sont segmentées.
- [ ] Reporter la correction dans la recette/parcours public ; vérifier son résultat à la génération finale, sans dépendance à un patch privé de contenu.

**Sortie :** graphe des étapes requises couvert par les tranches, aucune récompense/condition requise injectée, sauvegardes chaînées et exclusions optionnelles listées. Si une mécanique exclue coupe le chemin principal, J2 reste PARTIAL jusqu’à une adaptation native explicitement acceptée ou une correction supportée.

### RC-09 — Modification réelle dans Studio

**RC-09A, avant remise de J1 :**

- [ ] Ouvrir le dossier exact RC-03 dans Studio, vérifier projet/carte et version native compatibles.
- [ ] Choisir une modification réversible dans une carte/interaction de la tranche ; noter la valeur avant, modifier via l’interface puis enregistrer.
- [ ] Fermer le projet et le processus Studio possédé ; relancer, rouvrir le même dossier et vérifier la valeur persistée puis son effet dans le Player.
- [ ] Restaurer via les opérations normales la modification de QA si elle ne fait pas partie de la livraison ; ne pas perdre une modification utilisateur concurrente.

**RC-09B, avant remise de J2 :** répéter sur un PNJ/dialogue conditionnel et une porte ou scène importée afin de vérifier que les données ne sont pas seulement des images ou du contenu opaque. Contrôler annulation/undo lorsque applicable et absence de réécriture massive involontaire.

**Zones :** UI Studio et contrats `map_authoring` existants. Modifier seulement après reproduction d’une défaillance. Toute nouvelle sémantique persiste dans les modèles natifs et reste exposée via transports canoniques.

**Tests :** tests d’authoring de scènes/warps/faits correspondant à la modification, `test/parity/full_authoring_parity_test.dart` si contrat changé, tests widget ciblés de l’inspecteur réellement concerné.

**Sortie :** preuve visible de modification/enregistrement/réouverture froide et effet Player. Un dialogue de renommage affiché ou une modification en mémoire ne suffit pas.

### RC-10 — Paquet exporté et Player sur les plateformes annoncées

- [ ] Exporter depuis la sortie qualifiée par le mécanisme canonique ; vérifier manifest, versions/capacités, références, catalogues, médias et empreintes. Aucun chemin source privé requis à l’exécution.
- [ ] Installer le paquet avec la version courante de l’hôte dans une bibliothèque isolée ; conserver les jeux et sauvegardes utilisateur.
- [ ] Tester démarrage, nouvelle partie, changement de carte, dialogue, combat et sauvegarde/reprise ; distinguer paquet de jeu et binaire de l’application.
- [ ] Rejouer le rejet historique `referenceEscapesRoot` pour la condition Pokédex `national:1:151` : accepté seulement dans le contrat typé attendu ; les vraies échappées de chemin restent rejetées.
- [ ] Vérifier l’app SwiftUI sur My Mac si nécessaire, puis sur iPhone physique avec la build effectivement distribuée ; version/build et paquet exacts dans le reçu. Le lancement sur Mac ne ferme pas le gate iPhone.
- [ ] Contrôler séparément Git, compilation/signature, upload, traitement Apple, groupe TestFlight et installation. Une disponibilité TestFlight manquante ne signifie pas automatiquement échec de conversion.
- [ ] Pour une publication supplémentaire, appliquer l’autorisation Git/distribution en vigueur ; le présent plan ne lance pas d’upload ni de release.

**Zones/tests :** `packages/map_authoring/test/domains/distribution/game_package_export_api_test.dart`, `runtime_projection_reference_closure_test.dart` ; `packages/map_distribution` validateur/builder ; Hub `test/features/installation/game_package_installer_test.dart`, `test/platform/partitioned_installed_game_smoke_test.dart` ; app SwiftUI existante si cause native démontrée.

**Sortie :** paquet identifié installable et jouable sur chaque plateforme revendiquée ; erreurs et limites de temps/performance mesurées, statut distribution explicite. iPhone non disponible implique gate iPhone ouvert, pas blocage des preuves macOS acquises.

### RC-11 — Réutilisation au-delà du projet Kanto

- [ ] Définir la liste exacte des variantes Essentials supportées ; publier un diagnostic « non admis » précis pour les autres.
- [ ] Utiliser les fixtures originales/synthétiques pour varier namespace, IDs de cartes/événements, positions, noms, chemins et ordre des sections non sémantiques. La règle reconnue doit dépendre du programme et de ses préconditions réelles.
- [ ] Modifier une commande ou section sémantique pertinente et vérifier un refus contrôlé plutôt qu’une traduction approximative.
- [ ] Choisir un second projet compatible, distinct de Kanto et complet localement ; un dossier voisin partageant les mêmes scripts prouve une variation de contenu, pas une nouvelle version de moteur.
- [ ] Convertir une tranche cohérente par le parcours public puis ouvrir/modifier/jouer/sauvegarder ; qualifier le périmètre réellement couvert, sans s’imposer une deuxième campagne intégrale.
- [ ] Tester une source inconnue : conserver le diagnostic et le contenu littéral autorisé sans annoncer que le gameplay est converti.

**Zones/tests :** profils core/adapters et tests de familles du lot ; `source_interpretation_profile_test.dart`, `source_custom_plugin_policy_test.dart`, `builtin_source_interpretation_profiles_test.dart`, `publication_workflow_reproducibility_test.dart`.

**Sortie :** un contrat de compatibilité borné et une preuve indépendante. Cette étape ne bloque pas la livraison J1 de Kanto, mais elle est nécessaire avant de présenter le logiciel comme convertisseur réutilisable pour la variante admise.

### RC-12 — Livraison du convertisseur et clôture des preuves

- [ ] Construire l’application macOS Converter sur le SHA qualifié ; contrôler la copie utilisée dans Apps/Applications et afficher une identité de version exploitable.
- [ ] Faire un dernier contrôle de recette/génération sur les familles modifiées depuis RC-03. Une seule génération complète finale si les contrôles bornés ne permettent pas de fermer la preuve sur l’ensemble des corrections.
- [ ] Fournir le dossier projet, le paquet si applicable, les instructions courtes d’ouverture et une liste claire « fonctionne / limites connues / non pris en charge ».
- [ ] Publier la matrice finale par carte/événement/famille et par gate ; zéro événement absent du rapprochement, zéro blocage requis inexpliqué dans le parcours annoncé. Le nombre de tests n’est pas un pourcentage de jeu converti.
- [ ] Mettre le contexte Notion existant à jour avec SHA, fichiers, commandes, preuves et limites. Proposer les tranches vérifiées TO REVIEW ; DONE reste la décision utilisateur. Aucune réécriture des statuts de la roadmap FG sans demande.
- [ ] Après instruction explicite de commit/push, vérifier diff ciblé, changements concurrents et divergence distante ; ne pas publier d’autres travaux silencieusement. Le présent plan lui-même n’est pas une autorisation Git.
- [ ] Fermer les outils de QA possédés, vérifier les descendants et l’espace disque, nettoyer uniquement les temporaires attribués avec provenance certaine.

**Sortie :** J1, J2 ou J3 annoncé avec son périmètre exact et ses gates. Pas de verdict « tout Kanto fonctionne » si seule la tranche du premier badge est qualifiée.

## 5. Protocole de correction sans régénérations répétées

1. Reproduire le défaut sur son événement et ses dépendances minimales, sans modifier la source.
2. Écrire le test causal : condition valide refusée ou effet source perdu ; inclure voisin négatif, mauvais profil et invariants à préserver.
3. Corriger le recognizer/projector/workflow responsable. Si le défaut est runtime, le corriger dans ce package avec le test de contrat et rejouer la projection.
4. Comparer les objets natifs avant/après et la fermeture de leurs dépendances. Appliquer les seules actions canoniques nécessaires au projet QA ; vérifier les préimages pour ne pas écraser une modification utilisateur.
5. Jouer le segment concerné, sauvegarder/recharger si l’effet persiste ; mettre à jour le ledger, la recette et le test public de non-régression.
6. Ne réécrire toutes les cartes qu’à RC-03 et, si nécessaire, à la validation finale des nouvelles règles. Les snapshots source et médias immuables se réutilisent après contrôle de leurs empreintes.

**Important :** les patchs canoniques de QA ne sont pas une fonctionnalité publique de mise à jour d’un projet édité. Créer un vrai outil de reconversion avec fusion des modifications, conflits et reprise est un chantier distinct, non requis pour J1/J2. Ne pas le cacher dans un lot de performance.

## 6. Matrice minimale d’acceptation

| Gate | Preuve minimale | Ce qui ne suffit pas |
|---|---|---|
| Source | Source/profil/outils identifiés et fichiers inchangés | Nom de dossier ou version supposée |
| Conversion publique | Interaction UI → recette → reçu → sortie exacte | Appel d’un outil privé ayant enrichi le profil |
| Census | Cartes/événements/pages rapprochés sans omission | Compteur global d’événements actifs |
| Sémantique | Famille reconnue, effets/conditions/sorties conservés et cas négatif | JSON valide ou programme portant un nom attendu |
| Départ | Nouvelle partie sans sauvegarde préparée ni état injecté | Lancement sur carte QA avec équipe déjà fournie |
| Parcours J1 | Début → premier badge continu, puis reprise froide | Victoire isolée avec Pokémon niveau100 ou segments annoncés continus |
| Progression J2 | Tranches nécessaires chaînées et fin source atteinte | Toutes les cartes affichables |
| Studio | Modifier, enregistrer, fermer, rouvrir, rejouer | Inspector affiché ou donnée changée seulement en mémoire |
| Export | Références fermées et paquet compatible | Archive produite sans installation |
| Player | Installation puis démarrage et interaction/save | Test de validation du paquet seul |
| Visuel/audio | Observation de scènes et rendu sur une app visible, audio réellement écouté si revendiqué | Tests sans fenêtre et backend audio simulé |
| Mobile | App/build exacte sur iPhone physique avec paquet exact | My Mac (Designed for iPad), simulateur ou TestFlight simplement « traité » |
| Généricité | Variation contrôlée + seconde source admise | Kanto renommé ou compatibilité inférée du marketing Essentials |

Toute preuve décrit son mode : synthétique, projection réelle, runtime sans fenêtre, UI visible, dispositif physique ; ses exclusions ne disparaissent pas lorsqu’un autre mode passe.

## 7. Vérification, commandes et gestion des fixtures

### 7.1 Commandes ciblées prévues

Les commandes suivantes sont un point d’entrée exécutable depuis les packages concernés, après sélection du lot. Elles ne sont pas exécutées lors de la rédaction. Avant toute commande Flutter, lancer via un superviseur enregistrant PID, descendants et empreintes de commande ; inspecter/récolter uniquement ses survivants. Les chemins de tests ci-dessous existent à la base du plan.

```bash
cd /Users/karim/Project/pokemonProject/packages/avelune_converter_core
dart test test/source_interaction_inventory_test.dart test/source_interpretation_profile_test.dart test/source_event_conditions_ev02_test.dart
dart analyze
```

```bash
cd /Users/karim/Project/pokemonProject/packages/avelune_converter_adapters
dart test test/builtin_source_interpretation_profiles_test.dart test/converter_study_plan_recipe_test.dart test/converter_workflow_test.dart test/publication_workflow_reproducibility_test.dart
dart analyze
```

```bash
cd /Users/karim/Project/pokemonProject/apps/avelune_converter
flutter test --concurrency=1 test/converter_app_test.dart test/converter_session_lifecycle_test.dart test/cli_desktop_plan_parity_test.dart test/playable_start_setup_test.dart
flutter analyze
flutter build macos --debug
```

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test --concurrency=1 test/phase_a_golden_battle_slice_smoke_test.dart
```

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host
flutter test --concurrency=1 test/phase_a_golden_slice_launch_test.dart
```

Chaque test réel lit ses variables d’environnement documentées dans son fichier. Par exemple, `source_converted_campaign_prefix_journey_test.dart` utilise `AVELUNE_CAMPAIGN_PREFIX_PROJECT` et `AVELUNE_CAMPAIGN_PREFIX_RECEIPT`. Leur absence peut ignorer le test : un run vert avec skip ne qualifie pas le parcours. Relever l’argv exact, les valeurs de chemins non sensibles, le SHA des fixtures et le nombre de skips dans le reçu ; ne pas inventer un nom d’argument commun aux différents harnesses.

Pour une règle modifiée, lancer son test précis avant/après ; les suites complètes des packages touchés viennent après les tests ciblés. Élargir ensuite seulement si dépendances ou défauts le justifient. Les parcours longs restent locaux et opt-in ; aucune nouvelle dépendance de certification coûteuse dans la CI.

### 7.2 Parité authoring et MCP

Une correction pure de reconnaissance source qui n’ajoute aucun contrat cible peut justifier « nouvelle exposition N/A », avec preuve de sa consommation par le workflow. Une action, un modèle, une validation ou un comportement d’authoring modifié exige preuves direct API, JSONL/CLI, éditeur et MCP selon son applicabilité.

```bash
cd /Users/karim/Project/pokemonProject/packages/map_authoring
dart run tool/pmcp085_conformance.dart
dart test test/parity/full_authoring_parity_test.dart
dart analyze
```

```bash
cd /Users/karim/Project/pokemonProject/tools/pokemap_mcp
npm run check
npm run build
npm test
```

Après changement du serveur/contrats, vérifier `pokemap_describe` vivant et les actions réellement exposées ; ouvrir seulement la racine étroite déjà autorisée, conserver ses handles et fermer le workspace après usage. Ne pas demander une nouvelle autorisation pour la racine `/Users/karim/Project/avelune project` déjà approuvée, mais vérifier que sa configuration effective la contient. Un gap global de certification préexistant ne devient pas une nouvelle dépendance du lot : décrire son périmètre et prouver les contrats touchés.

### 7.3 Liens avec la roadmap FG

Références techniques, sans mise à jour de statut : FG-010 à FG-016 (départ/save), FG-040/043/048/051 (persistance/récompenses), FG-064/067/068/070/071/073 (objets/services), FG-080 à FG-093 (événements/warps/PNJ), FG-100 à FG-108 (rencontres), FG-120 à FG-129 selon capacité réellement présente, FG-140/141/143 à FG-147 (progression), FG-180/182/183 (readiness et régression).

Le statut global de ces mécaniques ne découle pas de la qualification du convertisseur. Le rapport de chaque lot distingue TODO/PARTIAL/BLOCKED et proposition de statut avec preuve ; ne pas retoucher une mécanique déjà livrée uniquement pour harmoniser la roadmap historique.

## 8. Ressources, temps et coordination

- Un seul build ou parcours lourd à la fois dans cette conversation. Lire plusieurs zones indépendantes en parallèle est possible ; aucune copie concurrente du projet utilisateur.
- Relever `df` avant/après conversion et build. Avec les 24 GiB libres observés à la rédaction, ne pas lancer de générations complètes répétées sans estimer l’occupation maximale du staging et des médias ; seuil d’admission fondé sur les octets prévus, pas sur une promesse de mémoire/disque arbitraire.
- Ne pas supprimer de source, média, SDK actif, sauvegarde ou historique d’authoring utilisateur. Conserver manifest/identité des temporaires possédés et vérifier qu’ils ne servent plus avant purge.
- Aucun délai de livraison chiffré avant RC-01/03 : le nombre actuel de blocages n’est pas établi. Après J1, donner un délai borné par tranche à partir des coûts mesurés et des familles restantes, avec risques explicites.
- Point utilisateur à chaque sous-lot : ce qu’il peut tester, dossier exact, bugs corrigés dans le convertisseur, tests exécutés et limites. Un silence de plusieurs heures ne constitue pas un suivi acceptable.
- L’autre conversation possède l’accélération. Éviter les modifications concurrentes des horloges/contrôles ; les parcours acceptent ×1. Après livraison de son API, faire une vérification séparée que les preuves accélérées conservent les invariants avant de s’en servir comme preuves normales.
- Ne pas créer de nouveaux sous-projets Notion ni de familles bêta. Utiliser le contexte existant pour les corrections et leur preuve ; un nouveau chantier produit distinct se classe en Post Bêta selon la procédure du dépôt.

## 9. Mesure de progression et règles d’arrêt

**Mesures à publier après RC-01 :** nombre de cartes rapprochées/attendues ; événements/pages par décision exclusive ; familles reconnues/testées ; blocages requis restants ; tranches de progression qualifiées ; gates Studio/Player/mobile ouverts. Les catégories à recouvrement sont présentées séparément.

**Pourcentages :** autorisés seulement avec dénominateur et définition stables, par exemple « 383/383 références de cartes contrôlées ». Interdit d’en déduire « jeu 100 % converti ». Une estimation de travail restante, si demandée, reste séparée de la couverture fonctionnelle.

**Arrêts imposés :**

- Source altérée ou profil incohérent : arrêter la publication, conserver le diagnostic.
- Nécessité d’une mécanique exclue sur le chemin obligatoire : expliciter l’impact et proposer une adaptation native ; ne pas retirer la condition en silence.
- Modification utilisateur concurrente : refuser le patch ciblé si sa préimage ne correspond plus ; ne pas écraser.
- Test bloqué : diagnostiquer une fois la cause/harness/focus/processus, changer d’approche ; ne pas relancer indéfiniment le même parcours.
- Source incomplète : signaler le fichier manquant et les éléments affectés ; aucune récupération implicite sur Internet ni invention IA.
- Échec de CI/build ou de signature : séparer cause et portée ; conserver les preuves fonctionnelles acquises et ne pas déclarer la livraison binaire prête.

## 10. Risques et autocritique

| Risque | Effet | Réponse du plan |
|---|---|---|
| Confondre correctifs du MASTER et parcours public | Le jeu actuel marche mais une nouvelle conversion perd les corrections | RC-01/02 puis reçu UI RC-03, régression finale RC-12 |
| Profils trop attachés à une archive exacte | Promesse générique incorrecte | Compatibilité bornée J1/J2, généralisation RC-11 |
| Transformer toute quarantaine en bug | Travail sans fin et activation dangereuse | Classification source/capacité/criticité avant correction |
| Mélanger tests injectés et progression naturelle | Fausse preuve de jeu complet | Modes de preuve explicites et chaîne de sauvegardes |
| Safari exclu mais récompense nécessaire | Campagne bloquée malgré diagnostic honnête | Dépendance explicitement vérifiée RC-07/08E |
| Perte de modifications Studio lors d’une reconversion | Travail utilisateur écrasé | Writer destination neuve conservé ; mise à jour/fusion publique hors lot |
| Runtime mobile/version de paquet décalés | Installation échoue sans défaut du contenu converti | Matrice de compatibilité et build exacte RC-10 |
| Temps/disk absorbés par les vérifications | Peu de résultat visible | Test borné par famille, J1 livré tôt, une référence QA et générations finales rares |

Le plan est volontairement détaillé, mais il ne demande pas douze réécritures de sous-systèmes. Plusieurs lots peuvent se fermer par qualification si le code suffit. Les correctifs exacts et leurs diffs seront définis après un défaut reproduit ; inventer aujourd’hui un patch complet pour chaque famille rendrait le plan moins fiable. Les tranches RC-08 sont candidates et seront ajustées au graphe source avant exécution, sans changer silencieusement le résultat promis.

## 11. Preuve de la planification et revue

- Audit initial : code du parcours public, writer, recettes, profil builtin, inventaire, tests et reçus réels relus ; état initial propre sur `fea811e3f`.
- Passe Architecture : pipeline existant confirmé ; profil builtin à empreinte précise et writer à destination neuve identifiés ; interdiction de présenter les patchs QA comme fonctionnalité de reconversion.
- Passe Tests : préfixe colis et premier badge segmenté distingués ; ouverture Studio distinguée de modification persistée ; corpus et commandes opt-in identifiés.
- Passe Progression : preuve Manoir conservée ; anciens audits de donneurs non réutilisés comme liste actuelle de manques ; dépendance Safari et tranches à confronter à la source explicites.
- Passe Implémentation du livrable : un seul document consolidé créé ; aucune ligne de code produit, fixture ou donnée de jeu changée ; aucun test fonctionnel ou build justifié pour ce changement documentaire.
- Passe Build/Validation : chemins existants cités contrôlés, aucun manquant ; futur fichier RC-04 explicitement identifié. Douze lots, blocs de code équilibrés et aucun espace en fin de ligne. `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` : `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.` ; budget d’un document correspondant à la demande directe de plan. `git diff --check` : exit0. Aucun résultat de build réaffirmé comme frais ; tests fonctionnels et build N/A pour cette seule rédaction.
- Passe Critique finale : verdict indépendant PASS après relecture des corrections intégrées : chemin d’implémentation de porte corrigé, scénario durable combiné jusqu’à Pierre explicitement prévu, RC-04A/04B séparés pour ne pas retarder J1 avec toutes les variantes. Aucune réserve bloquante du plan ; ce verdict ne qualifie pas la campagne.
- État du checkout à la validation documentaire : ce plan est le seul fichier ajouté par cette tâche. Des changements concurrents de l’accélération sont apparus dans Studio, authoring, core, runtime et les tests du host ; ils sont conservés sans modification ni staging. Aucun commit/push demandé par ce message et donc aucun exécuté. Résultat de planification proposé à revue ; produit global toujours DOING/PARTIAL.


## 12. Exécution RC-01 — rapprochement courant

Demande directe : « commit et push et vraiment me faire cette fois le RC01 ». Le correctif mobile déjà en attente et l’outillage de rapprochement sont dans le périmètre autorisé. Les changements concurrents de vitesse de test, d’audio, de plateformes mobiles et de transport MCP restent exclus du staging. Aucun commentaire ajouté au code, conformément à l’instruction directe ; la consigne contraire de `codex_rule.md` ne prévaut pas.

### 12.1 Audit initial et décisions

- Révision de départ de la planification : `fea811e3f1123790c972a4ebb6457de04bbe341e`. Lors de l’exécution, le checkout `main` contient aussi les modifications concurrentes énumérées par `git status --short --untracked-files=all` ; elles sont conservées.
- Le census `SourceInteractionInventory` existe déjà. Ses compteurs `notYetQualified` sont des observations non rapprochées, pas une mesure de bugs. Une sortie de projection ancienne ne suffit pas à constater les capacités actuelles du convertisseur.
- La recette de référence admise est `Inventaires/Kanto EV-10/lot6/full-conversion-29/plan-recipe.json`, version 13/réglages 10, namespace `ev09-real-source-defects`. Les sources supplémentaires Johto puis Hoenn sont sélectionnées explicitement. Aucun scan des dossiers voisins implicite.
- Le MASTER reste `/Users/karim/Project/avelune project/Kanto — Portes et progression`. Son manifeste de 14 047 721 octets conserve le SHA-256 `e53050064f8d057bfa8d8d5e6a8c38dec7c52a6c456b5c39f0b4d5e935b549eb`. Les 383 JSON de cartes totalisent 27 837 533 octets ; leur digest ordonné `(relativePath, SHA-256)` est `5f7a5759534bb020214d38b3d51edcfbbef7dd9be615ace67ac418de916c5dfd`. Deux lectures de l’auditeur natif confirment ces mêmes octets.
- Une nouvelle préparation canonique est nécessaire pour comparer la projection actuelle et le MASTER. Elle appelle `ConverterWorkflow.scanSource` et `prepareStudy`, jamais le writer ni la publication. Le census et les opérations développées restent des artefacts d’audit ; aucun nouveau jeu ni média n’est écrit.
- Portée de rapprochement : seuls les objets attendus dont une opération développée porte l’identité exacte d’un événement source sont comparés. Une égalité d’objets n’est pas la preuve de toutes les pages, de la fidélité de chaque commande ni d’un trajet joué. Le ledger expose `selectedExpectedObjectsOnly`, `pageNativeCoverageCertified:false`, `runtimeProof:notReplayed` et `criticality:requiresReview`.
- Les références d’appels communs, signaux de transfert et règles source sont conservées comme témoins. Elles ne sont pas transformées en graphe de dépendances obligatoires sans preuve source. Un événement facultatif ou indispensable non établi reste à examiner.

### 12.2 Code livré et zones concernées

| Fichier | Zone et raison | Impact et preuve |
|---|---|---|
| `packages/map_runtime/lib/src/presentation/flame/dialogue_overlay_component.dart` | Présentation du dialogue inline de cinématique | Réutilise le dialogue tactile natif révisionné ; repli Flame conservé |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Compteur de révision partagé | Une présentation de dialogue ne réutilise pas une ancienne révision |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game_support.dart` | État/verrou/propriétaire de l’attente cinématique | Le toucher peut terminer une attente de texte sans réactiver les déplacements |
| `packages/map_runtime/test/playable_map_game_cinematic_runtime_integration_test.dart` | Régression cinématique | Dialogue inline, interaction, attente et fin de présentation |
| `packages/map_player_ui/test/player/pokemap_player_session_view_test.dart` | Régression widget du Player | Présentation et confirmation tactiles dans le conteneur réel |
| `packages/avelune_converter_adapters/lib/src/source_event_execution_context.dart` | `readTransfers`, `read` et reconnaissance des contrôleurs d’inventaire | Transmet la même autorité source possédée dans le lot de transferts |
| `packages/avelune_converter_adapters/lib/src/source_transfer_program_authority.dart` | Compteurs de calcul et de qualification | Prouve une seule analyse partagée ; sceaux source et profil conservés |
| `packages/avelune_converter_adapters/test/source_generic_execution_context_test.dart` | Lot de deux portes puis lecture directe | Une analyse, trois qualifications ; garde-fous d’autorité inchangés |
| `packages/avelune_converter_adapters/lib/src/source_interaction_reconciliation.dart` | `SourceInteractionReconciliation.build`, index observés, normalisation des objets et résumé | Joint source/projection/objets natifs ; refuse provenance, census ou identités incohérents |
| `packages/avelune_converter_adapters/tool/reconcile_source_interactions.dart` | CLI, validation des enveloppes, lecture canonique native, CSV et reçu | Entrées explicites, hashes croisés, résultat neuf hors projet, deux lectures stables et fermeture des handles |
| `packages/avelune_converter_adapters/test/source_interaction_reconciliation_test.dart` | Tests unitaires de rapprochement | Présence, écart, brouillon/configuré, locators, pages, ownership et refus négatifs |
| `packages/avelune_converter_adapters/test/reconcile_source_interactions_cli_test.dart` | Tests du vrai point d’entrée CLI | Révisions/hashes/liens de préparation, chemins, entrée périmée et sortie contrôlée |
| Ce plan | Section 12 et état RC-01 | Un seul document consolidé, aucune modification de la roadmap FG |

Le premier correctif est commité et poussé dans `096e07849848316877b57a78cbc3439d550576f7`. La préparation complète a ensuite révélé une analyse source complète recréée pour chaque contexte de transfert. Le correctif déterministe `15081bcbbc59bb3b1665e4d7e880f5305d2fd7b8`, lui aussi poussé, transmet l’autorité existante au lecteur des contrôleurs d’inventaire. Il n’ajoute aucun cache global, ne fait pas confiance à une analyse injectée et ne modifie ni les données source ni les combats Avelune. Aucun gain de durée totale n’est annoncé sans mesure finale comparable.

### 12.3 Vérification exécutée

- Correctif tactile : index exact figé et testé avant commit ; **66 tests runtime + 96 tests UI = 162 réussis**. Les reçus et logs sont sous `Inventaires/Kanto EV-10/lot6/execution/mobile-intro-*`. Aucun test physique iPhone rejoué et aucune disponibilité TestFlight déduite de ce push.
- Correctif d’autorité : `dart test -r expanded test/source_generic_execution_context_test.dart test/source_inventory_controller_test.dart` depuis `packages/avelune_converter_adapters` : **39 réussis, 1 ignoré opt-in**. Analyse ciblée des trois fichiers : `No issues found!`. Logs `Inventaires/RC-01/transfer-authority-tests.log` et reçu de processus sans survivant.
- Une vérification adjacente conserve un échec préexistant : `source_transfer_program_authority_test.dart:198`, `static doors and stairs reuse the same authority without changing fingerprints`, attendu une porte statique, obtenu zéro avant le résolveur. Reproduction isolée avec le fichier d’autorité exact d’avant correction, puis restauration des octets de travail : échec identique. Cette suite élargie a donné **45 réussis, 1 ignoré, 1 échec** ; elle n’est pas annoncée verte.
- Rapprochement : `dart test -r expanded test/source_interaction_reconciliation_test.dart test/reconcile_source_interactions_cli_test.dart test/export_source_interaction_inventory_test.dart test/builtin_source_interpretation_profiles_test.dart test/source_routed_door_profile_test.dart` : **46 réussis**. Log `Inventaires/RC-01/adapters-targeted-tests-final.log`, reçu sans survivant.
- Core : `dart test test/source_interaction_inventory_test.dart` depuis `packages/avelune_converter_core` : **9 réussis**.
- Analyse ciblée des quatre nouveaux Dart : `No issues found!`. Analyse du package adapters : exit 0, zéro erreur et zéro avertissement, **3 informations de style préexistantes** dans `source_event_item_bindings.dart:299,504,543`.
- Build de l’outil réel : `dart compile exe tool/reconcile_source_interactions.dart -o /private/tmp/avelune-rc01-reconcile` : exit 0, log `Inventaires/RC-01/reconciler-build-v3.log`, reçu sans survivant. Le manifeste consommateur `consumer-source-manifest-v3.json` lie les quatre fichiers et le binaire aux tests et au producteur `15081bcbb`.
- Parité authoring/MCP : nouvelle exposition N/A pour cet audit local en lecture seule. La lecture du projet utilise les services canoniques `AuthoringReadApi`, `ProjectOpenService` et `ProjectSnapshotLoader.strict`, avec racine étroite au projet et fermeture des handles. Aucun contrat, action, serveur MCP, comportement d’édition, sérialisation produit ni règle cible ajouté ; reconstruire le serveur inchangé ne certifierait pas une nouvelle capacité.
- Roadmap : FG-000/146/147 restent PARTIAL dans cette preuve ; FG-180 n’est pas recertifié globalement. Aucune mécanique, règle de combat ni traduction Ruby arbitraire ajoutée.

### 12.4 Comparaison application et préparation Kanto

Le reçu `Inventaires/RC-01/public-workflow-delta.json` est pinné sur `096e07849` ; la révision producteur `15081bcbb` ajoute uniquement le partage de l’autorité de transfert. Les provenances restent distinctes. Les **20 sections de scripts, zéro programme déclaré et les retours de ramassage sont identiques** entre le profil builtin et le profil de la recette. La piste d’une section audio manquante ou de programmes déclarés supplémentaires n’est pas confirmée.

L’écart d’intégration prouvé est la dérivation de **deux présentations de portes** dans `tool/lot6_routed_door_patterns.dart` : `OBJ_FRLG_Doors4` (départ 1, arrivée 0, SHA `12f9110e8f5c6645da429f98c113c846547a57771174ed24faab4146ca99b586`) et `OBJ_FRLG_Doors1` (départ 3, arrivée 1, SHA `d55e8581be9721af4ab2cef0a4804ac54ef52516d84decfecd4fd536b554fd72`). Le consommateur est `source_routed_door_program.dart`. RC-02 doit raccorder cette dérivation au pipeline public avec les preuves des atlas, sans dégrader les refus lorsqu’un fichier change.

Une substitution visuelle est explicite : `trainer_SCIENTIST` absent devient `NPC_FRLG_SCIENTIST` attesté par SHA. Trois adaptations source sont déjà déclarées (Map082 événement3 pages0/1 : cible de remise à zéro du soin4→7 ; Map233 événement2 page1 : tuile647 hors atlas omise). Deux associations d’objets `DREAMMAIL`/`RETROMAIL` pointent explicitement vers le catalogue Hoenn choisi. Une exclusion de dépendance est déclarée Map295 événement12 page1 commande17. Ces choix ne doivent pas devenir des réparations silencieuses.

L’interface possède déjà les contrôles de sources supplémentaires, adaptations, associations d’objets, décisions de dépendances, première image d’autotile, budgets et import/export de recette. RC-02 doit qualifier leurs interactions et la reprise/relocalisation ; il ne doit pas recréer ces panneaux. Le namespace public initial et celui de la recette peuvent différer ; les identités natives ne se comparent pas naïvement entre deux namespaces.


### 12.5 Census frais et reproductibilité

Le producteur v3 est figé sur `15081bcbbc59bb3b1665e4d7e880f5305d2fd7b8`. Son code exact et les SHA de 157 fichiers core/adapters sont enregistrés dans `Inventaires/RC-01/20261021-v3/tool-source-manifest.json` ; le nouveau module de rapprochement non importé par le producteur est exclu explicitement de ce manifeste et pinné séparément côté consommateur. Le script d’audit est identifié par SHA `9c4b1dbeee4ce0eb3729751b17e02a52723d61c2ccda572d3a8d48a643f823cf`.

| Mesure de recensement | Valeur fraîche | Portée |
|---|---|---|
| Cartes | 383 | Toutes les cartes sélectionnées ; zéro carte non traitée |
| Événements | 3 941 | Identités et locators source, pas nombre de PNJ humains |
| Pages | 5 936 | Toutes les pages, y compris inactives selon les conditions |
| Commandes brutes | 59 115 | Ce nombre ne mesure pas le nombre de commandes traduites |
| Événements portant un transfert brut | 891 | Rôle source, peut se recouper avec dialogue et autres rôles |
| Événements portant un dialogue | 2 093 | Rôle source, pas preuve de restitution du texte |
| Candidats PNJ | 1 103 | Heuristique d’inventaire, pas census humain certifié |
| Diagnostics d’image source non résolue | 32 | Six références graphiques distinctes, pas 32 pertes natives |

Empreintes courantes : snapshot `b824f0f9bf7cea3372a2dbf7382934b09450224d542d04b1585dcd9b23e1bed5` ; normalisation `14c3a275ec7f060c9131680c82cfecbfd1678d007b1054b9d563056c0e158756` ; profil d’analyse `730fc867d09f1bc6ad2fc9c820961bc8b5d23b5912c3ce3f6f3e01f873de6450` ; profil d’interprétation `7d20648e06b6c4e7a74cea3363f08b366f0c43ebc4219c049a68014f44a901cd` ; recette brute `d32bfad00a2d5e6db254b006c3ff72c28ec297b0d5a5b7c6d2490845f37ff2f0`.

Le census vérifie à nouveau les fichiers lus : `sourceFilesVerifiedUnchanged:true`. Son champ `notYetQualified` reste intégral par construction ; le verdict doit venir du rapprochement suivant, jamais de ce compteur. Les corps d’événements communs, les scripts globaux et la jouabilité restent hors certification de cet inventaire.

Les six références de caractères non résolues sont `NPC_FRLG_WOMAN_2_FORMAL` (19 diagnostics), `berrytreeAGUAVBERRY` (5), `trainer_FRLG_WOMAN` (4), `trchar013` (2), `trchar035` (1) et `trchar045` (1). Les locators exacts sont dans `missing-source-image-diagnostics.json`. Le diagnostic démontre une résolution graphique source manquante dans cette normalisation ; il ne démontre ni blocage de progression ni perte d’un objet natif.

La première préparation v2 a été arrêtée après identification du recalcul des analyses de transfert ; son reçu conserve cette annulation et zéro processus survivant. La v3 utilise le correctif. Une unique extension de la limite de supervision de 30 à 45 minutes a été décidée après traces prouvant le passage des transferts puis de l’import des personnages. Le reçu `deadline-intervention-v3.json` documente l’annulation du seul timer de supervision, sans modification du producteur ni des algorithmes ; un watchdog externe vérifie PID, date de démarrage et commande. Les stacks sont des instantanés, pas un profil CPU ni une estimation de pourcentage. La préparation historique utilisait un exécutable AOT ; le lancement v3 via Dart VM ne constitue pas un benchmark directement comparable.


### 12.6 Résultat actuel du rapprochement

**Verdict RC-01 : TO REVIEW pour le census et le rapprochement de la couche événementielle sélectionnée.** Les décisions de traduction et les différences d’objets sont désormais calculées sur les données courantes. La composition finale de toutes les couches de catalogue, les dépendances obligatoires et la jouabilité de chaque page restent non certifiées ; cette limite P2 est conservée explicitement, pas convertie en nombre de bugs.

La préparation v3 réussit avec `PREPARED_WITHOUT_NATIVE_WRITES`, `preparedCanApprove:true`, `sourceFilesVerifiedUnchanged:true`, `projectTransactions:0`, `destinationCreated:false`. Elle dure 2 493 673 ms (41 min 34 s environ en JIT), se termine avant la borne externe de 45 minutes et laisse zéro survivant parmi les huit processus suivis. Le watchdog confirme `processEndedBeforeDeadline`.

Les 19 123 opérations événementielles développées sont sous la limite CLI de 32 768. Le finaliseur crée un fichier `current-converter-event-mutations-linked.json` neuf, sans modifier l’original, pour lier les SHA bruts de projection et de mutations. Le reçu `audit-export-links.json` conserve les deux origines et leurs empreintes. Le draft complet contient 22 845 enveloppes ; ses 3 832 artefacts, soit 277 008 727 octets en mémoire, ne sont pas écrits comme médias.

| Décision du convertisseur courant | Événements | Sens exact |
|---|---:|---|
| `adaptedStaticSemantics` | 2 698 | Reconnaissance et traduction déclarées par le projecteur courant |
| `partiallyAdapted` | 0 | Aucun événement dans cette catégorie sur cette exécution |
| `quarantinedWholeEvent` | 1 243 | Refus actuel ; ce total n’est pas le nombre de bugs ni le nombre d’événements désactivés du MASTER |
| Total | 3 941 | Catégories exclusives, census intégral |

| Comparaison à l’état natif actuel | Événements | Portée |
|---|---:|---|
| `match` | 3 010 | Objets sélectionnés conformes à leurs états attendus dans la couche événementielle |
| `different` | 545 | Au moins une différence de valeurs sérialisées, pas une panne démontrée |
| `missing` | 365 | Au moins une identité attendue absente ; cela peut être le brouillon de quarantaine attendu face à un événement natif déjà configuré |
| `partiallyAssessed` | 19 | Actions de décor/catégorie/image non comparées conservées explicitement |
| `notAssessed` | 2 | FollowingPokemon (Map009/30) et Glowing Button L (Map145/12), sans objet attendu sélectionné ; leurs objets natifs actuels existent |
| Total | 3 941 | Catégories exclusives, aucun taux de jouabilité déduit |

Le ledger couvre 5 936 pages ; leur comparaison se répartit en 4 303 `match`, 1 065 `different`, 433 `missing`, 133 partielles et 2 non évaluées. Ces nombres n’annulent jamais `pageNativeCoverageCertified:false`. Les 16 272 objets attendus uniques ont des témoins d’identité et d’empreinte. Les lignes partagées entre pages ou événements ne doivent pas être additionnées comme objets uniques.

Le snapshot natif contient 383 cartes, 3 254 entités, 837 déclencheurs, 549 warps, 4 831 records d’événements, 4 002 dialogues, 3 826 scènes, 845 facts, 12 règles, 416 dresseurs, 333 tables de rencontres, 27 boutiques, 8 badges, 147 personnages et 11 cinématiques. Ce sont des présences dans les données natives, pas une équivalence des catalogues source. Par événement source, les états de registre sont exclusifs : 2 713 configurés seuls, 1 001 avec brouillon seul, 6 mixtes configuré+brouillon et 221 sans record de registre. Ces 221 ne sont pas déclarés perdus : une entité passive ou un obstacle peut fonctionner par un autre contrat natif.

**Réserve P2 de composition, vérifiée par la revue :** les 545 événements `different` correspondent à 546 entités. Le regroupement des champs sérialisés relève notamment 460 différences de présentation et 84 de `interactiveEncounter`, avec quelques différences de nom/propriétés/NPC ; les compteurs de champs se recouvrent. `SourceCatalogStudyComposer` émet `entity.set_interactive_encounter` avec des propriétaires de catalogue et de carte, sans propriétaire d’événement : ces enrichissements sont hors du filtre d’export événementiel. Les 84 différences de rencontres ne prouvent donc pas qu’une conversion complète fraîche les perd. `reconciliation-limitations.json` porte `finalComposedObjectStateCertified:false`, et le rapprochement final de ces overlays reste à faire avant toute certification de parité de composition globale. Aucun champ n’est retiré silencieusement du ledger pour améliorer ses chiffres.

Exemples vérifiés sur les valeurs complètes : l’Intro possède deux variantes de présentation dans les opérations attendues sélectionnées et trois dans le MASTER ; Oak cutscene en a une contre deux, Daisy une contre deux. Le professeur possède une politique de quarantaine attendue différente des propriétés du MASTER. Une différence de nom inclut un espace terminal sur la Poké Ball Plante. Ces témoins justifient une investigation ; ils ne justifient pas 545 corrections automatiques.

Le reçu natif `read-receipt.json` observe deux fois la même révision `sha256:c4d76d232485ddf404b8a3c295a38a8c515c5813b4d59394abdcbaeaf306ade0`, zéro mutation et les trois entrées ré-hashées avant sortie. Les empreintes brutes sont : inventaire `94d4199d71227de53857b5135a96a91d3b15c9e70c26db620ef8f3f93a9d7860` ; projection `53a96c7235f9fa601f09df1c181133b095093adb593c19624699a664b83d478f` ; mutations liées `9fe5bc17b3cde26515d40ecb19d9bfd2ce95ba6c91af38d5c8c90a988d7a97b6`. Le ledger brut est `20932697f1872e54e626d85dee1b3deea95ccd0c0fe304686575eafad08de161`.

### 12.7 Causes et ordre de traitement après RC-01

Les familles de gaps se recouvrent : contexte/autonomie de carte 442 événements ; dormance/parallélisme 436 chacun ; présentation 266 ; conditions 250 ; contact joueur/événement 225 ; programme de porte 213 ; association de personnage 187 ; association sonore 126. Leur somme n’est pas un nombre d’événements bloqués. Le classement déterministe détaillé et ses inconnues sont dans `reconciliation-analysis.json`, avec locators, codes non classés, adaptations et témoins.

Les exclusions autorisées sont localisées sur huit événements : machines à sous Map044/1,2,3,4,5,6,10 et Safari Map050/2. Elles sont reconnues dans les commandes brutes inertes, sans exécution Ruby. La décision de dépendance exclue de Map295/12 ne signifie pas que toutes ses pages sont exclues. Les trois adaptations source touchent deux événements distincts ; les diagnostics graphiques touchent 30 événements. Une association manquante, une anomalie source, une mécanique exclue et un bug reproduit gardent des classes différentes.

| Priorité | Témoin actuel | Action bornée pour la suite |
|---|---|---|
| 1 — continuité du départ dans une conversion fraîche | Map009/1 Professor : `sourceOakParcelExecutionContextMissing` ; Map009/8 Starter Cutscene Controller et Map012/22 Parcel event controller : contexte/autonomie/parallélisme refusés | Comprendre et corriger les causes communes de qualification dans le pipeline automatique ; réutiliser les fixtures et preuves de contexte, puis rejouer le départ sur une sortie fraîche |
| 2 — préparation publique | Deux patterns de portes attestés présents uniquement dans l’outil de préparation Kanto | Intégrer leur dérivation au workflow public, conserver refus si l’atlas ou ses empreintes changent |
| 3 — fidélité des pages et état final composé | Présentations différentes et couches de rencontres non incluses dans les mutations sélectionnées | Qualifier les variantes vides/conditionnelles et rapprocher les overlays avant de conclure à une perte native ; aucun écrasement du MASTER sur ces seuls chiffres |
| 4 — associations et présentation localisées | Exemples Map038/5 et11 : animation de fenêtre non qualifiée ; Map064/9 : acteur d’arrivée non qualifié ; six références graphiques non résolues | Traiter une famille à la fois, distinguer un choix humain d’une règle source calculable et conserver le refus des scripts arbitraires |
| Hors objectif accepté | Sept événements machines à sous et un événement Safari | Garder le diagnostic explicite ; vérifier séparément les dépendances réellement nécessaires |

Les trois témoins prioritaires du départ ne sont pas des contenus absents du MASTER : le professeur y a 4 records configurés et 4 scènes, le contrôleur starter 3/3, celui du colis 2/2. Pour ces deux derniers, le statut `missing` porte sur le **record de quarantaine frais attendu**. En revanche, Pierre (Map020/3) et la donneuse de Thé (Map042/5) sont déclarés adaptés et leurs objets sélectionnés correspondent. Aucun trajet n’est rejoué par RC-01 ; la criticité globale reste `requiresReview`.

La comparaison historique `historical-projection-delta.json` est indépendante de celle du MASTER. L’ancienne projection full29 portait 1 052 quarantaines, pas les 1 007 brouillons du projet ensuite modifié. Sur 3 941 identités communes et aucune perdue : 2 606 adaptations et 960 quarantaines stables ; 92 événements réadmis ; 283 nouveaux refus, soit +191 net. Parmi ces 283, 266 concernent le contexte parallèle/autonomie sur 141 cartes ; les 17 autres concernent Dotted Hole (cartes 361–365) et leurs associations audio/présentation. Ce delta ne devient pas une liste de 283 régressions runtime.

### 12.8 Défaut de l’outil d’audit corrigé, revue et livraison

La première exécution de rapprochement s’est arrêtée sur `json.inert at $.area.pos` : un `MapTrigger.toJson()` conserve des objets de géométrie encodables imbriqués. `_hash` passe désormais par la sérialisation JSON native avant le hash canonique, pour les valeurs attendues comme observées. Un test construit un vrai `MapTrigger` avec `MapRect/GridPos`, compare sa mutation JSON et vérifie qu’une position déplacée donne bien `different`. Après correction du nom d’action de la fixture (`trigger.create`), le RED reproduit exactement `json.inert` ; le GREEN et la suite ciblée donnent **47 réussis**, zéro survivant. Aucun export source ni préparation n’a été rejoué pour ce défaut consommateur.

Commandes finales depuis `packages/avelune_converter_adapters` :

```bash
dart test -r expanded test/source_interaction_reconciliation_test.dart test/reconcile_source_interactions_cli_test.dart test/export_source_interaction_inventory_test.dart test/builtin_source_interpretation_profiles_test.dart test/source_routed_door_profile_test.dart
dart analyze lib/src/source_interaction_reconciliation.dart tool/reconcile_source_interactions.dart test/source_interaction_reconciliation_test.dart test/reconcile_source_interactions_cli_test.dart
dart compile exe tool/reconcile_source_interactions.dart -o /private/tmp/avelune-rc01-reconcile
```

Résultats : **47 réussis**, `No issues found!`, build exit 0. Logs `adapters-targeted-tests-v4.log`, `reconciler-build-v4.log` et reçus de processus sans survivant sous `Inventaires/RC-01`. Les suites plus anciennes restent documentées en 12.3 ; l’échec adjacent de fixture n’est pas masqué. Le manifeste final `consumer-source-manifest-v4.json` remplace les anciens manifests comme pointeur de validation sans les réécrire.

L’exécution CLI finale utilise les six arguments explicites : inventaire v3, projection v3, mutations liées v3, MASTER, dossier neuf `20261021-v3/reconciliation`, révision producteur `15081bcbbc59bb3b1665e4d7e880f5305d2fd7b8`. `reconciliation-v4.log.processes.json` : exit 0, zéro survivant. Les cinq sorties sont `ledger.json`, `summary.json`, `events.csv`, `pages.csv` et `read-receipt.json` ; les CSV comptent respectivement 3 941 et 5 936 lignes de données. Le script d’analyse complémentaire est pinné dans `analysis-producer.py` ; il regroupe les causes et les témoins sans remplacer le ledger.

| Passe / responsable | Verdict frais |
|---|---|
| Audit / Architecture — `rc01_census_contract_audit` | Source exhaustive, producteurs vérifiés, provenance et delta historique relus ; succès sans writer ni Ruby/IA |
| Implémentation — `rc01_native_project_audit`, parent et revue réciproque | Code de rapprochement et correctif d’autorité ciblés ; données natives conservées |
| Tests — parent et `rc01_public_workflow_audit` | RED réel de géométrie puis 47 GREEN ; 39+1 ignoré pour l’autorité, 9 core, 162 tactile ; fixture adjacente préexistante encore en échec |
| Build / Validation — parent | Binaire AOT construit, CLI réel réussi, racines/hashes/census et processus vérifiés |
| Critique finale — `rc01_public_workflow_audit` | Favorable sur la portée déclarée ; réserve P2 sur les overlays de catalogue, explicitement conservée |
| Contrôle natif — `rc01_native_project_audit` | Sommes événements/pages, hashes des trois entrées, valeurs différentes et MASTER immuable confirmés ; proposition TO REVIEW, pas campagne certifiée |

Auto-critique : cet audit apporte enfin des nombres courants et des témoins exploitables. Son sous-ensemble de mutations ne suffit pas à comparer l’état composé final de tous les catalogues ; les scènes, textes, médias et pages ne sont pas certifiés par une égalité d’objets. La prochaine action utile est ciblée sur la préparation du départ et les écarts publics établis, pas une nouvelle régénération globale ni une retouche manuelle du projet.


### 12.9 État Git et clôture de publication

Avant staging final : `main` et `origin/main` vérifiés sur `15081bcbbc59bb3b1665e4d7e880f5305d2fd7b8`, index vide. Les cinq fichiers propres restants sont le rapprochement, son CLI, leurs deux suites et ce plan. Les 41 fichiers concurrents (35 modifiés, 6 non suivis) sont conservés sans staging. Les chemins exacts de l’état initial figurent dans le reçu externe `Inventaires/RC-01/git-prepublication.json`.

Vérifications finales : quatre Dart formatés sans changement ; `git diff --check` exit 0 ; `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` : `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.` Le budget d’un Markdown correspond au plan explicitement demandé, consolidé avec cet audit. SSD : 23 Gio libres lors de la préparation et avant publication. Aucune application de test ouverte pour RC-01 ; les tests, builds, préparation, finaliseur, watchdog et rapprochement possédés ont terminé, sans survivant dans leurs reçus respectifs.

Le SHA du commit de rapprochement et la vérification de sa publication sont enregistrés après commit dans `Inventaires/RC-01/git-delivery-final.json` et dans le contexte Notion existant. Le ticket produit global reste DOING/PARTIAL ; le recensement et rapprochement RC-01 sont proposés TO REVIEW avec la réserve P2 documentée. Aucune PR, livraison TestFlight ou qualification physique iPhone n’est déduite de cette publication Git.

## 13. Exécution RC-02 — préparation des séquences de départ et portes

### 13.1 Périmètre, audit initial et décision

Demande : corriger dans la conversion automatique les blocages du professeur, du contrôleur starter et de la livraison du colis, intégrer les règles de portes manquantes, conserver les combats Avelune, tester puis commit/push sur main. Aucun recours à une IA ni exécution des scripts Ruby source.

Base Git : `961cfc202c9b79ff297048ee3d0129b0c1bf987e`, main aligné avec origin/main. Les 41 fichiers concurrents déjà sales (35 suivis et 6 non suivis, Studio/runtime/audio/vitesse/MCP) sont exclus du périmètre et du build isolé. SSD : 20 Gio au début du lot, puis 27 Gio lors de la validation ; aucune régénération des 383 cartes ni modification du MASTER.

Le RED sur les cartes originales complètes `{6,9,10,12,202}` conserve tous leurs événements et pages, dont le parallèle non admis Map202/e9. Il reproduit trois refus après 162282 ms : Professor Map009/e1 avec `sourceOakParcelExecutionContextMissing`, starter Map009/e8 et colis Map012/e22 avec `sourceParallelDormancyUnqualified` et `sourceParallelEventUnsupported`. Les maps 9 et 12 ne contiennent pas de parallèle ; le contexte générique étendait leurs contrôles à toutes les maps représentées. L'audit confirme aussi que la dérivation des deux présentations de portes existe seulement dans le harness historique.

Décision : conserver le binding de toutes les maps natives, mais calculer l'admission des programmes fermés par propriétaire, carte active, destinations littérales `201` et voisins retenus. Les écritures susceptibles de réveiller un parallèle local restent recensées globalement. Les contrôles d'archives, sections, plugins, common events, autonomie et refus des variantes inconnues ne sont pas relâchés. La présentation des portes est dérivée des octets attestés dans le worker public, uniquement en périmètre `full` et sur les cartes sélectionnées ou dépendances explicitement incluses.

### 13.2 Fichiers et zones modifiés

Les chemins du tableau sont relatifs à `packages/avelune_converter_adapters/`, sauf ce plan.

| Fichier | Zone et raison |
| --- | --- |
| `lib/src/source_event_execution_context.dart` | Contexte par propriétaire, batch `readProgramContexts`, scope dérivé des programmes autoritaires ; partage des hashes, mutations, witnesses et audits par scope ; binding natif intégral conservé |
| `lib/src/source_event_projection.dart` | Qualification par propriétaire, interdiction de transformer un contexte local en admission globale, sélection du contexte et evidence `programExecutionContexts` |
| `lib/src/source_event_study_composer.dart` | Raccordement du batch au parcours automatique, rétention explicite Oak/First Rival, conservation des témoins |
| `lib/src/source_oak_parcel_projection.dart` | Qualification du contexte du professeur plutôt que du contexte global |
| `lib/src/source_first_rival_projection.dart` | Même raccordement par propriétaire ; construction du combat natif inchangée |
| `lib/src/source_routed_door_pattern_derivation.dart` (nouveau) | Dérivation canonique bornée des patterns depuis deux pages brutes et un atlas exact ; vérification du profil, des sections et SHA, refus des conflits |
| `lib/src/converter_workflow.dart` | Appel public de la dérivation avant normalisation, garde `full`, filtre `wanted`, règles version 8 avec empreintes portes et contextes |
| `lib/avelune_converter_adapters.dart` | Export de la dérivation canonique |
| `tool/lot6_routed_door_patterns.dart` | Délégation du harness vers la fonction de production, suppression de l'implémentation dupliquée |
| `test/source_program_execution_context_test.dart` (nouveau) | Composition, propriétaire/scope, mutation native, refus local/voisin/writer distant, packing partagé des bindings |
| `test/source_progression_context_real_source_test.dart` (nouveau) | RED/GREEN réel des trois séquences ; parallèle distant toujours en quarantaine sans scène ni record activé |
| `test/source_external_warp_preserve_facing_test.dart` | Destination réelle `201` comprise dans le scope ; cible opaque refusée |
| `test/source_external_warp_composition_test.dart` | Oracle de composition mis à jour pour les preuves par propriétaire |
| `test/source_routed_door_workflow_test.dart` (nouveau) | Préparation publique sans patterns privés, mode world, restauration de recette et map malformée sélectionnée/hors sélection |
| `test/lot6_routed_door_patterns_test.dart` | Sections/SHA, PNG invalides ou hors limites, conflits et lectures limitées à la sélection |
| `test/converter_study_plan_recipe_test.dart` | Ancienne empreinte de règles refusée avant scan ou approbation |
| Ce plan, section 13 | Preuves consolidées et limites du lot ; aucune roadmap FG modifiée |

### 13.3 Preuves techniques fraîches

Racine externe des preuves : `/Users/karim/Project/avelune project/Inventaires/RC-02`. Les commandes exactes et identités des processus sont conservées dans les reçus associés aux logs ; aucun processus survivant n'est déduit de son seul nom.

- `dart test test/source_progression_context_real_source_test.dart --reporter expanded --concurrency=1` : **4 réussis**, exit 0, composition 159162 ms. Même sélection complète et même profil attesté que le RED. Professor conserve six masques, quatre pages exécutables et `partiallyAdapted` ; starter et colis sont `adaptedStaticSemantics` avec leurs routes et interactions ; Map202/e9 reste désactivé. Log `progression-context-real-green.log` et reçu sans survivant.
- Suite finale de 14 fichiers adapters, commande dans `adapters-final.log.processes.json` : **271 réussis, 17 ignorés opt-in**, exit 0, 26 s. Comprend workflow, recettes, profils builtin/store, portes, contextes, séquences, don fini, transfert externe et premier rival. Les 17 skips ne sont pas des validations du corpus externe.
- Dérivation réelle depuis le profil **builtin** `essentials-static-walking-events-items`, zéro pattern en entrée : exactement deux patterns en sortie, `OBJ_FRLG_Doors4` 1→0 et `OBJ_FRLG_Doors1` 3→1, avec les SHA RC-01 inchangés. **4075 ms, 386 lectures, 7767110 octets**. Les octets Scripts viennent de Johto et sont acceptés seulement par longueur/SHA exacts ; maps et atlas viennent de Kanto. Preuve `doors-real-derivation.json`. Aucune composition ni écriture de jeu dans ce contrôle.
- Tests world/full RED puis GREEN et test de map malformée hors sélection documentés dans `doors-world-red.log`, `doors-world-final.log`, `doors-selection-red.log` et `doors-selection-final.log`. Une carte hors sélection n'est plus lue par cette dérivation ; une carte sélectionnée invalide bloque toujours la préparation sans écriture.
- `dart format --output=none --set-exit-if-changed` sur les quatre nouveaux fichiers Dart et le wrapper : **5 fichiers, 0 modifié**, exit 0. Les fichiers historiques ne sont pas reformatés globalement.

Les anciennes preuves `Kanto EV-10/lot6/full-conversion-29` n'étant plus présentes pendant ce lot, le test réel utilise le profil extrait de `RC-01/20261021-v3/effective-settings.json`. Empreinte canonique revalidée : `7d20648e06b6c4e7a74cea3363f08b366f0c43ebc4219c049a68014f44a901cd`. Le produit n'a aucune dépendance opérationnelle vers ce fichier de preuve ; le builtin et la dérivation publique restent la voie de préparation.

### 13.4 Revues et limites conservées

Audit/architecture : cause commune établie avant modification, sans changement des allowlists. Implémentation : correctifs raccordés aux composeurs de production et au workflow public. Tests : RED réel puis GREEN réel, négatifs de propriétaire, scope, writers et sources conservés. Critique finale indépendante : **aucun finding P1/P2 confirmé** dans les 16 chemins adapters ; aucun mélange avec les fichiers concurrents. Build/validation et publication sont consignés ci-dessous après leur exécution.

Parité authoring/MCP : aucun nouveau modèle natif, commande d'authoring, contrat JSONL ou action MCP. Le convertisseur continue à émettre les opérations natives existantes ; le patch corrige leur admission depuis la source. Les transports de préparation/reprise CLI et application sont contrôlés séparément. Les changements MCP concurrents sont exclus ; aucun serveur ni liste de racines n'est modifié pour ce lot. Pas de changement Flame ou des règles de combat.

Limites : les deux pages supérieures du professeur restent explicitement non prises en charge et masquent correctement leurs pages inférieures lorsqu'elles sont sélectionnées. Le GREEN réel qualifie les composeurs sur cinq cartes originales ; la préparation publique des portes et la reprise sont couvertes par des fixtures ciblées. Cela ne certifie ni une conversion fraîche des 383 cartes depuis l'interface, ni le parcours Player jusqu'au badge, ni une installation mobile. Ces preuves restent RC-03/RC-04. Les règles de combat sont celles d'Avelune.

### 13.5 Build isolé, analyse et livraison Git

Le build utilise un export temporaire de la base `961cfc202` avec uniquement les 16 fichiers adapters RC-02 superposés : 3451 fichiers, environ 57,1 Mo avant dépendances/build. Les fichiers concurrents sont exclus ; les `package_config.json` ne référencent aucun paquet du checkout actif. Les manifests SHA et la preuve d'isolation sont `build-export-manifest.json` et `build-package-config-proof.json`.

- Dans `tools/avelune_converter_cli` de l'export : `dart compile exe bin/avelune_converter.dart -o <preuves>/avelune-converter-rc02` : exit 0, Mach-O arm64, SHA `b485903d7e187e8faa28f432ed8a89c3c59f9795991ec2ff8fe3478739a65476`. Log `build-cli-aot.log`.
- Dans `apps/avelune_converter` de l'export : `flutter test --no-pub --reporter expanded test/converter_session_lifecycle_test.dart test/cli_desktop_plan_parity_test.dart`, avec `AVELUNE_AC16_CLI_EXECUTABLE` vers ce vrai binaire : **7 réussis**, exit 0. Le reçu `build-cli-desktop-parity-evidence.json` donne `equal=true` et `sourceUnchanged=true`, avec révision native identique entre CLI et application. Ce test est headless, pas une session de conversion Kanto manuelle.
- Dans la même application : `flutter build macos --debug --no-pub` : **`✓ Built build/macos/Build/Products/Debug/Avelune Converter.app`**. Les avertissements de dépréciation Keychain et de phase Run Script sont conservés dans `build-macos-debug.log`, sans correctif hors périmètre.
- Dans l'export isolé : `flutter analyze --no-pub` pour l'application et `dart analyze` pour le CLI : **`No issues found!`**, exit 0. Les reçus de tests, analyses et builds indiquent tous zéro survivant.
- Dans adapters actif : `dart analyze` après retrait d'un import devenu redondant : exit 0, **aucune erreur ni warning**, trois infos de style préexistantes dans `source_event_item_bindings.dart` lignes 299, 504 et 543. Log `adapters-analyze-cleaned.log`. Après cet ajustement de test, `dart test test/lot6_routed_door_patterns_test.dart --reporter expanded` : **15 réussis**, exit 0.
- `git diff --check` et `bash tools/scripts/check_markdown_hygiene.sh` : exit 0 ; **`Markdown hygiene: no new Markdown files.`**

Verdict des correctifs RC-02 demandés : **TO REVIEW**, dans le contexte Notion existant CV01–04, dont le périmètre produit global reste DOING/PARTIAL. Aucun statut FG ou bêta n'est promu. L'auto-critique conserve la limite principale : le prochain contrôle utilisateur est une conversion fraîche par l'application, puis l'ouverture et le trajet dans Studio/Player ; les tests de ce lot ne la remplacent pas.

Le staging et le commit sont limités aux 16 fichiers adapters du tableau et à ce plan. Les 41 fichiers concurrents restent hors index. Le SHA publié, le rapprochement de main distant et le statut Git final sont enregistrés après publication dans `Inventaires/RC-02/git-delivery-final.json` et dans le contexte Notion, pour éviter une référence de commit autoréférente dans ce document.
