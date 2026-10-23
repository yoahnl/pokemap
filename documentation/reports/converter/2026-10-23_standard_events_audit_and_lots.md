# Événements standards — audit et lots de correction

Date : 23 octobre 2026. Référentiel : `/Users/karim/Project/pokemonProject`, HEAD `231ec890215c301830aaaa72b0ea8381270bfad1`, branche `main`.

> Exécution future : utiliser `skills/executing-plans/SKILL.md`, puis la vérification et la revue du lot. Ce document autorise un découpage, pas l'implémentation ni une opération Git. Les corrections doivent rester indépendantes de toute région, carte ou jeu particulier.

**Objectif :** déterminer ce qui manque réellement dans le convertisseur, Studio et la runtime pour convertir, modifier et jouer les événements standards d'un projet RMXP/Pokémon Essentials compatible.

**Architecture :** conserver les contrats natifs typés et les consommateurs existants. Étendre les modèles uniquement lorsqu'une sémantique nécessaire est absente ; raccorder toute capacité d'édition à `map_authoring` et à ses transports. Ne pas remplacer les règles de combat Avelune, exécuter du Ruby source ou utiliser une IA pour interpréter les événements.

**Stack :** Dart, Flutter/Flame, modèles `map_core`, gameplay pur `map_gameplay`, exécution `map_runtime`, Studio actuel `apps/avelune_studio`, API `map_authoring`, convertisseur core/adapters et MCP.

## 1. Verdict et périmètre

Le socle existe : conditions, événements, scènes, dialogues, choix, déplacements, cinématiques, objets, combats et sauvegardes ont des modèles et des consommateurs. Le problème n'est pas un moteur sans événements.

Les manques confirmés se répartissent en quatre ensembles :

1. **Convertisseur :** composition trop restrictive, commandes standards non traduites et reconnaissances de scénarios fermés qui ne constituent pas un compilateur réutilisable.
2. **Runtime/modèles :** processus parallèles de pages non représentés de façon générale, mouvement autonome non configurable par page active, opérandes calculées et quelques interactions métier absentes du chemin narratif canonique.
3. **Studio :** perte possible de politiques de dialogue lors d'une édition, politiques non exposées, contexte local manquant dans un écran, simulateur incomplet pour les états d'instance.
4. **Authoring et preuve :** un comportement techniquement exprimable peut rester trop compliqué à créer/modifier ; la parité de l'ancien `map_editor` ne prouve pas celle du Studio actuel.

Le standard audité comprend les pages et déclencheurs RMXP, les commandes natives de contrôle, texte, état, déplacement, transfert et présentation, ainsi que les helpers Essentials dont la sémantique peut être attestée. Les appels Ruby/plugins arbitraires restent hors périmètre. Safari et machines à sous restent signalés non pris en charge conformément au choix utilisateur. La parité des cinématiques 3D n'est pas un prérequis de conversion RMXP 2D.

**Critère supplémentaire demandé par l'utilisateur :** si une tâche simple ou répétitive exige de manipuler plusieurs couches techniques, de dupliquer des graphes ou de passer par du JSON, cela compte comme une lacune de Studio, même si le modèle sait stocker le résultat. Le plan doit corriger l'outil plutôt qu'institutionnaliser un contournement dans le convertisseur.

Cet audit est une inspection des contrats, de leurs consommateurs et de tests ciblés ; il ne certifie pas chaque variante de toutes les commandes RMXP, une campagne complète, une performance mobile ni une build distribuée.

## 2. Audit initial, état observé et niveaux de preuve

État Git initial : 123 entrées préexistantes, suivies/non suivies, notamment Studio, portes, spatial, runtime et authoring. Aucun changement préexistant dans les deux packages du convertisseur. Aucun de ces travaux n'est modifié par l'audit.

Sources techniques : `AGENTS.md`, `codex_rule.md`, index des skills, workflows `writing-plans`, `verification-before-completion`, `using-pokemap-mcp`, roadmap des mécaniques et plan existant `documentation/reports/converter/plans/2026-10-21_converter_kanto_delivery_plan.md`. Les anciennes preuves du plan ne sont pas promues en validations actuelles.

Lots FG concernés : FG-080/081/082, FG-083 à FG-092, FG-093/094 et FG-180 à FG-183. La roadmap comporte des statuts historiques ; son état ne constitue pas un inventaire fiable des capacités présentes. Aucun statut ni gate bêta n'est modifié.

Le projet publié Kanto contient actuellement 383 cartes, 416 dresseurs et 4 415 records : 3 514 configurés et 901 brouillons. **Les records configurés sont notamment des pages ; les 901 brouillons représentent des événements source entiers refusés. Leur ratio n'est pas un pourcentage de jouabilité.**

Rapprochement en lecture seule : les 901 IDs de brouillons courants correspondent tous aux mutations de provenance du reçu `Inventaires/Convertisseur-complet/kanto-full-final-3-receipt.json.gz`. Les anciennes étiquettes associées à ces propriétaires incluent 437 `sourceCommandUnqualified`, 245 `sourceConditionUnqualified`, 208 `sourceDoorProgramUnsupported` et 84 `sourceParallelEventUnsupported`. Ces catégories se recouvrent, sont historiques et **ne sont pas une nouvelle analyse des causes par le code courant**. Elles servent à sélectionner les familles ; elles ne prouvent ni 208 portes cassées ni 901 blocages de progression.

Le reçu indépendant courant confirme validation et réouverture des données Kanto, mais indique `visualTraversalCertified=false`. Hoenn a 366 cartes normalisées après réparation autorisée de la référence d'atlas ; cela ne certifie pas une publication native jouable.

Niveaux utilisés ci-dessous : **présent** = contrat et consommateur retrouvés ; **partiel** = sous-ensemble précis ; **absent du chemin canonique observé** = contrat/opération nécessaire non disponible dans ce chemin ; **non certifié** = preuve d'exécution/édition manquante, sans inférer une panne.

## 3. Matrice des événements standards

Les chemins de preuve sont relatifs à la racine du dépôt ; les lignes sont celles du checkout audité.

| Famille | Convertisseur | Modèle/runtime | Studio actuel | Cause et correction |
|---|---|---|---|---|
| Interaction, entrée, contact, autorun | Partiel selon formes, contact mobile restreint | Sources Event V2 et dispatch présents | Déclencheurs et activation éditables en 2D | Étendre qualification de contact/priorité et combinaisons ; ne pas recréer le dispatch |
| Pages, priorités et page invisible | Traduction et masquage déjà présents | Variantes conditionnelles de personnage/collision présentes | Éditeur de variantes présent | Compléter les cas de page, conserver le masquage par page supérieure non qualifiée |
| Mouvement autonome selon la page | Restrictif | Mouvement global du PNJ, sans mouvement dans la variante active | Route globale éditable, pas politique par page | Vrai ajout modèle/runtime/Studio, STD-05 |
| Switches/self-switches persistants | Présents dans les formes qualifiées | Facts persistants présents | Conditions/facts présents | Ne pas confondre avec mémoire d'instance temporaire |
| État local d'instance | Certaines portées temporaires prises en charge | Writer présent, qualification du catalogue encore négative | Création conditionnelle incomplète ; simulation sans instance | Raccorder puis qualifier le programme complet, STD-05 |
| Conditions d'équipe, badge, argent, avatar | Sous-ensemble reconnu depuis la source | Plusieurs conditions natives existent déjà | Formulaires de conditions nombreux | Faire la correspondance attestée, pas ajouter chaque condition comme nouvelle mécanique |
| Variables littérales | Set/add/sub entiers bornés | Affectation et delta constants présents | Formulaires présents | Composition et propagation de dépendances, STD-03 |
| Variables calculées au jeu | Non génériques | Pas d'opérande canonique variable/copier/calculer retrouvée | Pas de formulaire de cette sémantique | Vrai contrat fermé à compléter, STD-04 |
| Texte, choix, annulation, rythme | Sous-ensemble déjà traduit | Politiques de ligne/choix exécutables | Politiques non exposées et risque de perte à l'édition | Défaut concret Studio, STD-01 |
| Saisie numérique RMXP 103 | Absente du dispatcher général | Saisie texte vers string, pas saisie nombre vers entier dans le chemin narratif | Formulaire en jeu à fournir | Ajout typé borné, STD-04 ; un champ numérique d'éditeur ne suffit pas |
| Événements communs manuels finis | Expansion et retour imbriqué présents, garde globale trop large | Un appel natif dédié n'est pas nécessaire à une expansion finie | Édition des scènes résultantes possible | Qualifier le graphe de dépendances utile, STD-03 |
| Boucles et labels RMXP 112/113/118/119 | Absents génériquement | Graphe cyclique exécutable sous `maxSteps`, défaut 100 ; warning de diagnostic | Exposition/qualification incohérente | Compiler les formes finies ; réserver répétition durable à STD-07 |
| Pages parallèles et communs automatiques | Refus sauf adaptations fermées/dormance prouvée | Pas d'ordonnanceur général de page parallèle | Pas d'authoring complet de ce cycle de vie | Vrai ajout transversal, STD-07 |
| Objet donné/retiré, soin, cadeaux | Helpers/scénarios qualifiés ; commandes natives RMXP non toutes traduites | Plusieurs conséquences natives existent | Actions guidées existantes | Raccorder les primitives standard à l'existant, STD-03 |
| Argent RMXP 125 | Pas de traduction générale | Don présent ; retrait générique d'événement absent, boutique distincte | Mutation de solde et paiement conditionnel à distinguer | Respecter les bornes/poursuite de la source ; issue d'échec seulement si prévue, STD-04 |
| Route forcée, attente de fin | Sous-ensembles restrictifs, dépendance à des formes de porte | Routes et cinématiques natives avec barrières présentes | Éditeurs route/attente présents | Cibler le bon contrat puis composer, STD-06 |
| Saut, déplacements simultanés | Pas de traduction générale de toute route | Saut et groupe parallèle de cinématique présents | Inspecteurs natifs présents | Manque de conversion/qualification, pas absence générale du saut |
| Graphisme d'événement/tile, opacité et changement temporaire | Plusieurs cas refusés | Variantes de personnage présentes ; équivalences temporaires à qualifier | Variantes éditables | Étudier chaque effet et sa restauration ; pas d'équivalence inventée, STD-06/08 |
| BGM/ME/SE | Sous-ensemble qualifié | Contrôleurs et commandes natifs présents | Actions audio présentes | Étendre conversion sans doubler les propriétaires audio |
| BGS, fade/reprise audio et stop SE | Pas de traduction générale | Correspondance exacte de chaque canal non certifiée par cet audit | Ne pas promettre l'édition d'un contrat absent | Compléter/adopter explicitement les équivalences, STD-08 |
| Images et effets d'écran RMXP | Images 231–235, flash/shake/transitions non génériques | Cinématiques avec fade/shake/fx présentes ; équivalence aux slots RMXP à établir | Outils cinématiques présents | Compléter binding et contrats réellement manquants, STD-08 |
| Timer RMXP 124 | Absent du dispatcher général | Minuterie narrative équivalente non certifiée | Non certifiée | À recenser comme commande explicite, pas silencieusement supprimer ; STD-04/07 selon durée de vie |
| Combat et suites de progression | Bindings présents mais composition limitée | Combat Avelune et conséquences natifs | Dresseur/rencontre et sorties éditables | Préserver victoire/défaite/annulation/récompense ; aucune reprise du moteur Essentials |
| Sauvegarde/reprise | Sortie native disponible | État persistant ; save bloquée pendant activité narrative | Enregistrer projet et tester disponibles | Qualifier à point sûr ; aucune promesse de reprise au milieu d'une cinématique |

## 4. Constats techniques vérifiables

### C-01 — Des scénarios fermés remplacent encore une partie de la composition générique

`packages/avelune_converter_core/lib/src/source_oak_parcel_program.dart:153–195` exige six pages et une empreinte constante de pages normalisées, coordonnées comprises. `source_intro_program.dart:98–120` exige une signature de commandes et certains littéraux de variables. Certains IDs sont capturés/normalisés : il serait faux d'affirmer que tout est lié à des IDs fixes. Ces reconnaisseurs refusent sûrement les variantes inconnues, mais ne prouvent pas une capacité générale de transcription.

`packages/avelune_converter_adapters/lib/src/source_sequence_program.dart:124–219` limite fortement nombre de pages, self-switch final et corps autorisés ; `source_interaction_program.dart:159–223` exige à la fois choix et route, sans effets généraux de progression après eux. Une séquence valide mêlant des primitives déjà natives peut donc rester brouillon.

**Correction :** compiler des primitives typées et leur composition ; retirer les reconnaissances de scénario seulement après preuve équivalente. Aucun relâchement de la sûreté, aucune branche sur nom/région/coordonnée de jeu.

### C-02 — Le dispatcher ne couvre qu'un sous-ensemble du standard

`packages/avelune_converter_core/lib/src/source_events.dart:1863–2152` contient les cas généraux 101, 102, 106, 108, 111, 115, 117, 122, 121, 123, 201, 209, 208, 210, 223, 241, 249, 250, 355 et 322. Le 322 est explicitement refusé ; 355 passe par des reconnaissances contraintes. Les terminaisons/continuations sont traitées ailleurs : cette liste n'est pas une certification exhaustive.

Absences générales constatées : 103 saisie numérique, 112/113 boucles, 118/119 labels, 124 timer, 125 argent, 126 objets, 202 relocalisation, 221/222 transitions, 224/225 flash/shake, 231–235 images, 242 fade BGM, 245/246 BGS, 247/248 mémorisation/reprise, 251 stop SE. Des scénarios spécialisés peuvent reconnaître un fragment de ces commandes.

Les commandes RMXP sont vérifiables dans la référence locale en lecture seule `/Users/karim/Project/pokemonProject autre dossiers/pokemonsdk-development/scripts/1 RMXP Scripts/026 Interpreter_3.rb:63,227,241,278,283` et `028 Interpreter_5.rb:196–380`. Cette référence décrit RMXP/PSDK ; elle ne remplace pas l'attestation des helpers propres à la version Essentials source.

### C-03 — Les dépendances communes et parallèles sont admises trop globalement

`source_events.dart:1224–1241,1788–1794` exige une archive d'événements communs entièrement manuels avant admission de certains appels. `packages/avelune_converter_adapters/lib/src/source_event_execution_context.dart:1071–1090,1168–1173` refuse les automatiques et parallèles actifs hors cas fermés. Un programme manuel indépendant peut être pénalisé par un autre programme automatique de l'archive.

Une expansion finie d'appel commun ne nécessite pas un nouvel interpréteur runtime. En revanche, un processus parallèle qui continue pendant la marche nécessite un cycle de vie distinct de l'autorun bloquant et du groupe parallèle de cinématique.

### C-04 — Routes, contact et diagnostics de portes trop confondus

`source_events.dart:2455–2496`, `source_interaction_program.dart:247–276`, `source_npc_fixed_route_binding.dart:130–147,197–229` restreignent primitives, paramètres, acteurs et autonomie. `source_event_projection.dart:4173–4201,4451–4452,4716–4745` rattache plusieurs refus de contact/route/position à `sourceDoorProgramUnsupported`, même hors d'une porte.

`source_event_projection.dart:1377–1416` propage à juste titre les dépendances d'acteurs/self-switches puis met en brouillon l'événement entier. Améliorer la causalité du diagnostic ; ne pas activer arbitrairement le préfixe d'un événement de progression refusé.

### R-01 — Processus parallèle persistant manquant

`packages/map_core/lib/src/models/narrative_event_source_ref.dart:15–24` et le consommateur `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1276–1424` couvrent notamment entrée, interaction, contact et autorun. L'autorun acquiert une activité narrative bloquante. Il n'existe pas dans ce chemin de programme de page parallèle avec cadence, rendement, instance, arrêt et reprise.

Les cinématiques parallèles existent : `packages/map_runtime/lib/src/application/scene_runtime/cinematic_runtime_playback_controller.dart:476–491`, tests `cinematic_parallel_playback_test.dart:42–107`. Cela ne remplace pas un processus d'événement persistant.

### R-02 — Mouvement autonome par page absent, autonomie statique déjà présente

`packages/map_core/lib/src/models/map_entity_presentation.dart:58–91` ne porte pas de configuration de mouvement dans une variante. `map_entity_presentation_projection.dart:119–129` conserve le mouvement du PNJ initial. `packages/map_runtime/lib/src/presentation/flame/playable_map_game_npc_fixed_routes.dart:29–54,123–131` consomme ce mouvement global.

L'autonomie statique aléatoire/bouclée, avec vitesse et pause, existe déjà (`map_entity_payloads.dart:144–155,303–313`). La lacune est le changement de cette politique avec la page, pas « les PNJ ne savent pas bouger ».

### R-03 — État calculé, saisie de nombre et paiement générique à compléter

`packages/map_core/lib/src/models/scene_consequence.dart:38–58,325–381` expose valeur littérale et delta constant, sans opérande générale de copie/calcul à l'exécution retrouvée. Le convertisseur limite aussi les variables à set/add/sub littéraux (`source_events.dart:1919–1940,2673–2683`).

`scene_structured_interaction.dart:4–10` et `packages/map_runtime/lib/src/application/scene_runtime/scene_interactive_text_input.dart:27–30` proposent une saisie texte typée string, pas le nombre RMXP vers variable entière. `scene_consequence.dart:10–32,97–101` expose `giveMoney`, sans retrait canonique d'événement ; le writer refuse un montant non positif (`scene_consequence_runtime_writer.dart:519–532`). La boutique débite déjà (`packages/map_gameplay/lib/src/game_state_mutations.dart:443–447`), mais ce n'est pas une conséquence générale de paiement.

Ne pas contourner ces manques avec un don négatif, une string non typée ou un état inventé. Ajouter les contrats nécessaires selon les commandes effectivement recensées, y compris leur refus transactionnel.

**Distinction économique issue de la critique :** un retrait standard n'est pas automatiquement un achat conditionnel. La référence RMXP locale `scripts/1 RMXP Scripts/027 Interpreter_4.rb:194–200` applique la commande 125 puis continue ; `017 Game_Party.rb:76–77` borne le solde sans branche d'échec. La version Essentials attestée reste l'autorité pour ses propres bornes/comportements. Le futur contrat doit donc séparer mutation du solde selon la source et paiement avec précondition lorsque le programme source en possède une ; ne pas inventer un échec pour fonds insuffisants sur toute commande 125.

### R-04 — Boucles : budget réel, diagnostic trompeur, pas absence absolue

`packages/map_core/lib/src/diagnostics/scene_diagnostics.dart:2228–2268` émet un **warning** de cycle. `scene_runtime_plan_builder.dart:13–16` ne bloque que les erreurs. `scene_runtime_executor.dart:97,165–245` suit les arêtes puis échoue si `maxSteps` est dépassé, valeur par défaut 100. Le test `packages/map_core/test/scene_runtime_executor_test.dart:699–719` couvre ce plafond.

Une boucle finie sous budget peut fonctionner aujourd'hui. Le manque est une qualification cohérente, la compilation source et, pour les répétitions durables, un contrat de rendement/ordonnancement. Supprimer le plafond sans remplacement serait dangereux.

### R-05 — Mémoire d'instance : consommateur présent, qualification incomplète

Le catalogue de commandes indique `setMapEventInstanceBoolean` non supporté pour l'édition/runtime (`packages/map_core/lib/src/read_models/narrative_command_catalog.dart:139–165`) alors que le writer l'exécute (`scene_consequence_runtime_writer.dart:189–193`) et que `packages/map_runtime/test/scene_map_instance_consequence_writer_test.dart:12–109` couvre écriture, idempotence, instance périmée et rollback.

Il faut qualifier et exposer le programme complet avant de changer ce verdict. Les self-switches persistants source déjà mappés vers des facts ne sont pas tous affectés par cette limite de mémoire temporaire.

### S-01 — Changer le départ d'un dialogue peut perdre des politiques importées

`packages/map_core/lib/src/models/scene_asset.dart:1442–1456` porte `choicePolicies`, `linePolicies`, `declaredCancellationOutcomes`. `apps/avelune_studio/lib/presentation/features/scenes/scene_inspector_fields.dart:56–63` reconstruit ce payload lors de `onStartChanged` sans ces collections, qui reprennent leur valeur vide.

Le changement de document a une omission similaire (`:19–26`), mais exige une politique d'invalidation contrôlée des références devenues incompatibles. Ne pas copier aveuglément les politiques d'un autre document. L'édition du texte suit un autre chemin, qui possède déjà des tests de préservation : `apps/avelune_studio/test/dialogues/dialogue_line_text_edit_publication_test.dart:216–329`.

### S-02 — Certaines politiques natives restent inaccessibles dans Studio

Le même inspecteur `scene_inspector_fields.dart:6–79` n'expose pas les règles d'annulation/choix initial et le feedback des lignes. Les actions canoniques existent dans `packages/map_authoring/lib/src/domains/narrative/scene_actions.dart:570–580` et alentour : `scene.dialogue.choicePolicy.update`, `scene.dialogue.lineFeedback.update`. L'ancien `map_editor` possède un formulaire de choix (`scene_dialogue_choice_policy_dialog.dart:129–169`). Ce n'est pas une absence du contrat natif.

La parité « editor » citée par `packages/map_authoring/lib/src/parity/full_authoring_parity.dart:790–803` concerne notamment l'ancien éditeur ; elle ne certifie pas le Studio actuel.

### S-03 — Contexte local non transmis depuis l'écran Événements

`apps/avelune_studio/lib/presentation/features/events/event_page_content.dart:49–55` construit `EventConditions` sans propriétaire carte/entité. `event_condition_dialog.dart:127–134` conditionne le choix de mémoire locale à ce contexte. Une condition existante peut récupérer son contexte (`:68–70`) ; l'éditeur de variantes le transmet correctement (`entity_presentation_controls.dart:205–212`). C'est un raccordement manquant, pas une nouvelle mécanique.

### S-04 — Simulation sans état local d'instance

`event_simulation_dialog.dart:48–53`, `packages/map_core/lib/src/read_models/narrative_event_validation_read_model.dart:45–70` et `authoring/narrative_event_configuration_operations.dart:64–95` ne fournissent pas les instances/cartes requises par `operations/narrative_event_dispatch_authority.dart:486–508`. La simulation ne certifie donc pas correctement une condition de mémoire locale ; cela ne prouve pas une panne du Player.

Précision importante : `source_event_projection.dart:478–485` traduit les switches et self-switches persistants source en facts, qui bénéficient de la simulation existante. Les `tempSwitch` sont traduits en mémoire native d'instance (`:1203–1211`). Le manque ne concerne donc pas indistinctement tous les self-switches importés.

### S-05 — Un événement répétitif n'a pas encore une unité d'édition cohérente

`apps/avelune_studio/lib/presentation/features/events/event_library.dart:62–69,119–141` affiche une liste plate de records. `event_view_state.dart:3–15` porte un événement actif et les onglets déclencheur/conditions/scène/options. `event_scene_panel.dart:23–60` associe une scène à ouvrir séparément ; `event_summary.dart:103–104` renvoie explicitement les actions et branches à cet autre éditeur. L'apparence/collision conditionnelle est ailleurs (`entity_presentation_controls.dart:93–213`). Modifier un PNJ avant/après un cadeau demande donc de coordonner records, priorités, conditions, scènes et variantes sans objet d'édition groupé qui en assure la cohérence.

La duplication existe (`event_workspace_layout.dart:192–205`, `features/events/application/event_workspace_commands.dart:57–72`), mais `packages/map_core/lib/src/operations/narrative_event_record_operations.dart:113–136` conserve source, conditions et `sceneId`, avec nouvel ID/ordre et retour en brouillon. C'est une duplication de règle partageant ses documents, pas une instanciation indépendante d'un comportement sur un autre PNJ. Le test `apps/avelune_studio/test/events/event_workspace_ui08_test.dart:63` couvre le brouillon distinct, pas le clonage de toutes les dépendances.

**Manque d'authoring confirmé par les opérations**, sans mesure inventée de clics ni prétention d'audit visuel : proposer un événement natif à pages et un choix explicite de partage/copie du comportement. Réutiliser les records/scènes/variantes pour l'exécution s'ils suffisent ; ne pas créer un second moteur pour améliorer le formulaire. C'est le fondement du lot STD-EV-02.

### Limites qui ne deviennent pas des prérequis artificiels

- La runtime 2D joue déjà sauts, animations, dialogues, audio, fade et groupes parallèles de cinématique. Le sink spatial 3D en limite plusieurs (`spatial_cinematic_runtime_playback_sink.dart:143–156`) : signalement distinct, pas nouveau bloqueur du convertisseur 2D.
- La musique possède déjà un propriétaire et une restauration (`runtime_scene_music_controller.dart:16–110`, `playable_map_game_scene_music.dart:25–75`). Le défaut historique de double musique ne permet pas d'affirmer que ce système manque encore ; toute régression doit être reproduite sur la build visée.
- La sauvegarde est bloquée pendant l'activité narrative (`narrative_runtime_activity_gate.dart:81–115`). Qualifier une sauvegarde à point sûr n'impose pas de reprendre au milieu d'une cinématique.

## 5. Lots génériques et ordre de livraison

Identifiants **STD-EV-01 à STD-EV-09**, limités à cet audit. Ils organisent les corrections des chantiers existants ; ils ne créent pas neuf tickets bêta et ne remplacent pas les acquis AC/EV/CV/RC.

Chaque lot commence par son cas de reproduction synthétique, conserve les refus négatifs utiles et se termine par une preuve de consommation et d'édition dans le Studio actuel. Un test qui ne fait que relire du JSON ne suffit pas. Les chemins indiquent les zones à modifier, pas l'autorisation de refactorer l'ensemble du fichier.

| Lot | Livrable | Responsabilité | Dépendances |
|---|---|---|---|
| STD-EV-01 | Éditer un dialogue sans perte, avec politiques accessibles | Studio + authoring | Aucune ; première correction recommandée |
| STD-EV-02 | Édition native simple des événements répétitifs et à pages | Studio + modèle/authoring si nécessaire | Peut concevoir en parallèle de 01 ; qualification après 05/06 selon fonctions |
| STD-EV-03 | Composition générique des commandes déjà représentables et diagnostics causaux | Convertisseur | Matrice du présent audit ; pas besoin d'attendre tous les ajouts moteur |
| STD-EV-04 | Variables calculées, saisie numérique et paiements typés | Core/gameplay/runtime/Studio/convertisseur | 03 pour intégration source |
| STD-EV-05 | Pages, mouvement autonome, contact et mémoire locale cohérents | Core/gameplay/runtime/Studio/convertisseur | 01 ; réutilise 03 |
| STD-EV-06 | Routes, portes et cinématiques composables | Convertisseur d'abord ; compléments natifs motivés | 03 ; 05 si autonomie de page requise |
| STD-EV-07 | Cycle de vie des événements parallèles nécessaires | Core/gameplay/runtime/Studio/convertisseur | 03/04/05, contrat d'arbitrage avant code |
| STD-EV-08 | Présentation et canaux audio standards | Convertisseur + contrats manquants identifiés | 03/06 ; 07 seulement pour effets réellement persistants |
| STD-EV-09 | Conversion et édition multijeu démontrées de bout en bout | Qualification intégrée | Itératif après chaque lot ; verdict final après familles annoncées |

### STD-EV-01 — Édition sûre des dialogues

**Fichiers :** `apps/avelune_studio/lib/presentation/features/scenes/scene_inspector_fields.dart`, formulaires de scène existants ; actions dédiées de `packages/map_authoring/lib/src/domains/narrative/scene_actions.dart` ; tests Studio de scène/dialogue et tests de transports dédiés.

- [ ] Reproduire : dialogue avec annulation vers une branche, choix initial et cadence ; modifier uniquement son départ.
- [ ] Préserver les politiques encore valides via la mutation canonique ; diagnostiquer les références invalidées par un vrai changement de document.
- [ ] Exposer les règles d'annulation/choix/feedback dans Studio, avec pickers et aperçu. Aucun champ JSON.
- [ ] Vérifier modification, publication, fermeture/réouverture et comportement du dialogue au clavier/tactile. Annulation interdite doit le rester ; aucune issue silencieusement ajoutée/perdue.

**Sortie :** éditer une scène importée ne supprime pas ses autres comportements. Le correctif de préservation peut être livré avant le formulaire complet.

### STD-EV-02 — Authoring simple, réutilisable et centré sur l'événement

**Zones :** `apps/avelune_studio/lib/features/events/`, `presentation/features/events/`, formulaires de scènes/variantes ; domaines `map_authoring` events/scenes/entities. Étendre le contrat canonique seulement si la composition actuelle ne permet pas une mutation atomique cohérente.

- [ ] Décrire trois parcours synthétiques : PNJ différent après un switch ; objet à ramasser une seule fois ; porte verrouillée puis ouverte par un objet. Ajouter un dialogue avant/après combat pour la réutilisation.
- [ ] Permettre création/édition depuis une entrée logique, conditions/actions/pages visibles et références sélectionnées. Ne pas demander à l'utilisateur de synchroniser manuellement sprite, collision, trigger, scène et état consommé.
- [ ] Réutiliser les capacités existantes de duplication/modèles ; compléter celles réellement absentes. Un modèle reçoit des paramètres métier, pas des IDs à recopier ou du Ruby.
- [ ] Prévisualiser la page active et le motif de non-déclenchement ; visualiser les conséquences liées. Les détails avancés restent accessibles.
- [ ] Vérifier une seconde instance avec d'autres ressources/conditions, sans modifier la première et sans dépendance au jeu utilisé comme fixture.

**Sortie :** les cas simples restent simples dans Studio. Le nombre d'écrans/actions et les erreurs de synchronisation sont évalués sur ces parcours, pas une réduction de clics arbitraire inventée à l'avance.

### STD-EV-03 — Compilation composable et causalité des refus

**Fichiers :** `source_events.dart`, `source_sequence_program.dart`, `source_interaction_program.dart`, `source_event_projection.dart`, `source_event_execution_context.dart`, profils/bindings du convertisseur ; tests EV02/EV04/EV05 et composition.

- [ ] Construire une table versionnée commande/condition/déclencheur → équivalent natif/adaptation/refus, avec preuve de section moteur. Les empreintes attestent la version, jamais l'identité d'un jeu admis.
- [ ] Composer texte, choix, conditions, effets natifs, transfert et attente sans exiger un nombre de pages ou une forme de quête déterminée.
- [ ] Développer les appels communs finis avec retour local et budgets ; qualifier la fermeture de dépendances utile sans imposer que toute l'archive soit manuelle.
- [ ] Produire pour chaque refus la cause racine, ses dépendants et son propriétaire : source invalide, convertisseur, contrat natif absent ou hors périmètre.
- [ ] Faire des tests de variations : noms, textes, IDs, coordonnées, ordre de décoration et découpage en événements communs changés ; comportement inchangé. La modification sémantique doit au contraire être détectée.
- [ ] Remplacer progressivement les reconnaissances de scénarios fermés, sans activer une variante auparavant refusée avant d'avoir son équivalence prouvée.

**Sortie :** une même composition marche sur des fixtures originales et sur deux sources compatibles avec un seul exécutable ; aucune branche de production sur Kanto/Hoenn, carte, personnage ou quête. Les profils de moteur/version attestés restent légitimes.

### STD-EV-04 — État et interactions typés manquants

**Zones :** modèles conditions/conséquences/interactions `map_core`, décisions et mutations `map_gameplay`, handlers `map_runtime`, formulaires Studio, actions `map_authoring`, parseur source.

- [ ] Spécifier les seules opérations nécessaires du standard : copie de variable, calcul entier avec bornes et erreurs, lectures de jeu autorisées ; aléatoire déterministe sauvegardé uniquement si nécessaire.
- [ ] Ajouter saisie numérique vers entier avec chiffres/bornes, valeur initiale, annulation et interaction mobile/clavier.
- [ ] Ajouter une mutation du solde respectant les bornes et la poursuite de la source attestée ; séparer le paiement conditionnel avec précondition, annulation et issue d'échec uniquement lorsque le programme source les prévoit. Commit atomique ; aucune somme négative détournée en don.
- [ ] Clarifier cycles finis, diagnostic et plafond d'exécution. Compiler/dérouler ce qui est prouvé fini ; ne pas retirer les limites pour rendre un test vert.
- [ ] Recenser l'utilisation des timers et définir leur durée de vie avant toute traduction : attente finie ou processus persistant. Ne pas inventer un compteur de progression.
- [ ] Tester avant/après, refus, répétition, annulation, rollback, save/load et formulaires sans scripts.

**Sortie :** les commandes standard annoncées utilisent des opérations natives contrôlées ; aucune évaluation Ruby ni expression dynamique non bornée.

### STD-EV-05 — Pages, autonomie, contact et état local

**Fichiers :** `map_entity_presentation.dart`, sa projection, contrôleurs d'autonomie/dispatch, catalogue de commandes et input de simulation, `event_page_content.dart`, `event_condition_dialog.dart`, simulation Studio, projection source.

- [ ] Permettre une politique de mouvement par page/variante et passer proprement d'une route à l'immobilité ou à une autre route.
- [ ] Définir réévaluation/annulation aux changements de page, priorité, collision, orientation et page invisible ; préserver l'identité de l'acteur.
- [ ] Qualifier contacts mobiles, empreintes et passage initial du propriétaire, sans déclenchement multiple ou softlock.
- [ ] Raccorder le contexte réel du propriétaire dans le formulaire de condition locale ; aucune entité inventée pour une source globale.
- [ ] Étendre la simulation avec carte/instance/état local et la même autorité que le Player ; références absentes donnent un diagnostic.
- [ ] Qualifier le programme complet des booléens d'instance avant de modifier le catalogue supported ; distinguer durée de vie de l'instance et facts persistants.

**Sortie :** la page visible, sa collision, son mouvement et son déclenchement expriment le même état ; sauvegarde/reprise et éviction de carte respectent les portées déclarées.

### STD-EV-06 — Déplacements, portes et cinématiques sans scénario spécial

**Zones :** parseur/bindings de routes et projection source ; modèles route/cinématique existants ; exécuteurs, formulaires et tests de routes/cinématiques.

- [ ] Choisir routes natives ou timeline cinématique selon la sémantique, notamment sauts et déplacements simultanés déjà disponibles.
- [ ] Composer plusieurs acteurs, rotations, pauses, barrière de fin et dialogue, avec portée de visibilité/through/graphisme restaurée.
- [ ] Distinguer bloqué/skippable/non-skippable, acteur absent, départ de carte et annulation ; aucune attente infinie.
- [ ] Dériver une porte depuis graphisme, pages, route et transfert, sans identifiant de carte ni empreinte de quête ; séparer ses diagnostics de ceux d'un PNJ qui marche.
- [ ] Tester départ/arrivée, destinations intérieures/extérieures et contrôle rendu au joueur ; éditer la séquence dans Studio puis la rejouer.

**Sortie :** la même séquence reste fonctionnelle avec d'autres acteurs/cartes. La fidélité temporelle adaptée doit être annoncée, jamais déduite de la seule présence d'une route.

### STD-EV-07 — Processus parallèles avec cycle de vie explicite

**Zones :** contrat Event V2, scheduler pur `map_gameplay`, intégration narrative/runtime, authoring/Studio et projection des communs automatiques/parallèles.

- [ ] Prioriser les processus utiles observés ; garder les dormants prouvés dormants. Ne pas construire un interpréteur complet pour une page développable en une opération finie.
- [ ] Définir page/instance propriétaire, cadence, rendement, budget, suspension, déduplication et arrêt au transfert/désactivation.
- [ ] Définir l'arbitrage avec dialogue, combat, musique et mutations partagées ; pas de boucle occupée sur le thread UI.
- [ ] Définir l'état sauvegardé aux points sûrs et l'interdiction des tâches orphelines après chargement.
- [ ] Tester deux processus indépendants, dépendants, une page qui change, une carte quittée et une reprise ; mesurer le coût localement. Aucune CI macOS/soak coûteuse ajoutée.

**Sortie :** processus parallèles annoncés exécutables et annulables, sans se faire passer pour des autoruns bloquants. Tout programme encore non représentable reste explicitement refusé.

### STD-EV-08 — Présentation et audio standards

**Zones :** AST source, bindings audio/présentation, modèles cinématiques/interactions nécessaires, gestionnaires audio runtime et formulaires Studio.

- [ ] Traduire fade/reprise/arrêt des canaux source avec un propriétaire explicite : carte, scène, effet court, combat. Vérifier l'équivalence BGS séparément.
- [ ] Définir slots d'image, déplacement/effacement, ton/flash/shake, opacité et graphisme temporaire ; réutiliser les outils natifs lorsqu'ils suffisent.
- [ ] Distinguer ressource réellement manquante, adaptation Avelune acceptée et défaut du convertisseur. Aucun média deviné ni disparition silencieuse.
- [ ] Vérifier visuellement et auditivement carte → cinématique → combat Avelune → retour carte, interruption comprise.
- [ ] Modifier les paramètres dans Studio, sauvegarder et rejouer ; maintenir les refus pour les effets sans équivalent annoncé.

**Sortie :** pas de double propriétaire de musique, pas d'effet effacé implicitement, et édition normale des éléments convertis.

### STD-EV-09 — Qualification multijeu et livraison contrôlée

**Zones :** tests/fixtures du workflow public, Studio actuel, Player et export/install ; aucune règle métier dans un harness privé.

- [ ] Convertir un corpus synthétique original couvrant chaque famille annoncée et ses cas négatifs, puis deux projets compatibles avec le même convertisseur.
- [ ] Parcourir le bouton Convertir, ouvrir le résultat, modifier réellement dialogue/condition/porte/route, enregistrer, fermer et rouvrir.
- [ ] Jouer depuis une vraie nouvelle partie une tranche avec objet, passage conditionnel, cinématique, rencontre/combat Avelune et récompense ; sauvegarder puis recharger dans un autre processus.
- [ ] Vérifier séparément sur iPhone entrée tactile, annulation, audio et progression ; build/TestFlight et disponibilité utilisateur sont des preuves distinctes.
- [ ] Publier un bilan par événement source, avec pages, causes, adaptations et conséquences sur le trajet testé ; ne pas convertir un nombre de records en taux de compatibilité.
- [ ] Vérifier API directe, JSONL/CLI, Studio et MCP ; fournir les reçus du Studio actuel, pas uniquement ceux de l'ancien éditeur.

**Sortie :** promesse de compatibilité limitée aux versions/familles prouvées et résultat jouable/modifiable reproductible. Aucun « tout le jeu » si une étape requise reste désactivée.

## 6. Vérifications de l'audit et commandes d'implémentation futures

Tests frais sur la copie de qualification existante `/Users/karim/Project/avelune project/Inventaires/Convertisseur-generique/qualification`, dont les sources centrales et fichiers de tests utilisés ont été comparés au checkout pour le périmètre contrôlé. Les dépendances de cette copie n'utilisent pas les sources sales du checkout actif. Cela ne certifie pas les 123 modifications concurrentes.

| Commande, depuis le package indiqué | Résultat frais | Limite |
|---|---|---|
| adapters : `dart test test/source_common_events_ev05_test.dart test/source_event_pages_ev02_test.dart test/source_dialogue_text_ev04_test.dart test/source_interaction_program_test.dart --reporter expanded --concurrency=1` | 105 réussis, exit 0 ; runner surveillé 16918, 13,869 s ; aucun survivant possédé | Corpus synthétique ciblé, pas tous les événements source |
| map_core : `dart test test/scene_diagnostics_test.dart test/scene_dialogue_choice_policy_test.dart test/scene_consequence_model_test.dart test/scene_actor_variant_reference_test.dart --reporter expanded --concurrency=1` | 70 réussis, exit 0 ; runner surveillé 17567, 7,777 s ; aucun survivant possédé | Contrats/diagnostics, pas preuve de rendu ni d'édition UI |
| map_core : `dart test test/scene_runtime_executor_test.dart --reporter expanded --concurrency=1` | 29 réussis, exit 0 ; runner surveillé 22864, 2,025 s ; aucun survivant possédé | Exécuteur pur et callbacks ; pas le Player Flutter complet |

Reçus/logs : `/Users/karim/Project/avelune project/Inventaires/Convertisseur-complet/standard-audit-adapters-20261023-processes.json`, `standard-audit-core-20261023-processes.json` et `standard-audit-executor-20261023-processes.json`. Le wrapper existant suit PID, descendants, identité et limites de ressources ; aucun kill par nom de processus.

Une passe séparée a également exécuté `dart test test/source_event_conditions_ev02_test.dart --reporter expanded` dans le core du convertisseur : 5 réussis, exit 0. Son arbre PID n'a pas été capturé pendant le run ; inspection ultérieure sans processus correspondant au chemin exact du test. Ne pas annoncer pour ce run un certificat de zéro descendant.

Catalogue MCP live interrogé pendant l'audit : 444 actions déclarées, 97 ressources dans le résumé de parité, 70 types dans la liste de ressources exposée. `catalogComplete=true`, mais `transportCertificationComplete=false` et `itemTransportCertificationComplete=false`. Les compteurs désignent des surfaces différentes. La présence d'une action n'est pas une preuve de son formulaire dans Studio ni d'une exécution fraîche sur tous les transports.

Les tests UI/runtime existants cités dans les constats ont été lus, pas tous relancés. Aucune application graphique, build, génération complète, analyse de tous les packages ou livraison mobile n'est lancée pour cet audit documentaire. **Pas de correction logicielle implémentée**, donc pas de nouveau test de régression prétendument vert pour S-01. Le premier lot doit commencer par ce RED. Build/analyse applicatifs : N/A à la modification documentaire ; la meilleure validation ici est lecture des consommateurs, tests ciblés et contrôles documentaires.

Commandes à prévoir par lot, après les tests RED propres à son périmètre :

```sh
# Depuis apps/avelune_studio
flutter test test/events_ui08_conditions_simulation_test.dart test/map_workspace/entity_presentation_controls_test.dart test/scenes/scene_actor_action_publication_test.dart test/dialogues/dialogue_line_text_edit_publication_test.dart
flutter test test/presentation/scene_wait_for_actor_routes_form_test.dart test/cinematics/cinematic_parallel_ui10_test.dart

# Depuis packages/map_runtime
flutter test test/scene_map_instance_consequence_writer_test.dart test/scene_actor_variant_route_test.dart test/npc_fixed_route_player_test.dart
flutter test test/cinematic_parallel_playback_test.dart test/playable_map_game_cinematic_runtime_integration_test.dart test/scene_music_runtime_integration_test.dart

# Depuis packages/map_authoring
dart test test/domains/narrative/scene_dialogue_choice_policy_actions_test.dart test/domains/narrative/scene_dialogue_line_feedback_actions_test.dart test/domains/narrative/event_record_batch_transport_test.dart
dart run tool/pmcp085_conformance.dart
dart test test/parity/full_authoring_parity_test.dart

# Depuis tools/pokemap_mcp
npm run check
npm run build
npm test
```

Ces commandes futures ne sont pas annoncées réussies par ce document. Elles doivent être ajustées au lot, complétées des nouveaux cas, lancées avec suivi/nettoyage des descendants, et suivies d'un `pokemap_describe` live. Les commandes `dart analyze`/`flutter analyze` et le build pertinent se font package par package après un vrai changement de code.

## 7. Revue, risques et clôture documentaire

Passes séparées :

- **Audit/architecture convertisseur : PARTIAL.** Couverture insuffisante et formes de scénario confirmées ; aucun besoin de moteur inféré du seul refus du parseur.
- **Audit runtime : PARTIAL.** Consommateurs retrouvés ; ajouts ciblés nécessaires. Revue croisée ayant corrigé le faux diagnostic « boucles impossibles » en limite d'exécution/qualification.
- **Audit Studio/authoring : PARTIAL.** Quatre écarts concrets confirmés ; aucune justification d'une réécriture générale.
- **Implémentation : non engagée**, conformément à la demande d'audit et découpage.
- **Tests : PASS borné** aux commandes fraîches ci-dessus ; pas de certification exhaustive.
- **Build/validation : build applicatif N/A**, contrôle documentaire et fraîcheur des références requis.
- **Critique finale indépendante : approuvable après précision P2 intégrée.** Aucun P1 factuel identifié. La revue a fait distinguer retrait standard et paiement conditionnel ; correction appliquée à la matrice, au constat et à STD-EV-04. Les cycles, les compteurs historiques et les limites des preuves ont été revérifiés.

Risques : assouplir une admission avant d'avoir son équivalence ; créer un interpréteur non borné ; modifier des contrats partagés sans leur formulaire ; confondre état d'instance et switch persistant ; utiliser les tests de l'ancien éditeur pour certifier Studio ; mélanger travail concurrent et version publiée ; imposer des ajouts 3D à une conversion 2D ; appeler « supporté » un événement simplement stocké.

Auto-critique : plusieurs preuves sont structurelles, pas issues d'un parcours visuel frais. Le standard comporte des variantes nombreuses ; le rapport distingue les équivalences observées et les capacités non certifiées. Le rattachement historique des 901 causes ne remplace pas une nouvelle analyse de chaque source. L'effort de développement et les délais ne sont pas estimés à partir de ces compteurs.

**Inventaire des modifications :** uniquement ce document, créé pour l'audit explicitement demandé. Zones : verdict/périmètre, matrice, constats localisés, neuf lots avec critères de sortie, vérifications et limites. Aucun diff de production, aucune modification des projets Kanto/Hoenn, de la roadmap, des sources externes ou des réglages MCP. Aucun Git add/commit/push demandé ou réalisé pour cet audit.

Contrôles documentaires frais : `git diff --check`, exit 0 ; `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh`, exit 0, « Markdown hygiene: 1 new Markdown file(s), all in canonical locations. » Le budget d'un document correspond à l'audit consolidé explicitement demandé. Tous les chemins complets de dépôt cités ont été vérifiés existants. État Git final observé : 124 entrées, soit les 123 préexistantes et ce seul rapport non suivi ; index vide, HEAD inchangé. Les deux fichiers de cache kernel des suites possédées dans la copie de qualification ont été supprimés après fin des trois runners et absence de lock ; environ 138 Mio logiques, aucun cache du checkout actif ou d'une application utilisateur touché. Espace libre observé avant ce nettoyage : 60,5 Gio ; aucune garantie de variation physique déduite de la taille logique.

Traçabilité : contexte existant CV-01–04, domaine unique **Monde & narration**, Post Bêta, gate bêta inchangée. L'audit et son plan sont proposés **TO REVIEW** ; le chantier de conversion global reste **DOING/PARTIAL**. Les lots correctifs futurs ne sont pas créés silencieusement comme nouveaux tickets bêta.
