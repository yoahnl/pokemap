# AS-UI-012 — États et règles du monde

Réalisation de l'image 08 du kit Narrative Studio, précédée de la vérification
de continuité UI11.

Base de travail : `849b530ff` au démarrage du lot, deux commits plus loin que
le `670346c3b` sur lequel le pack a été préparé. Les apports de ces commits ont
été conservés. SDK local Flutter `3.48.0-0.4.pre` ; la CI épingle
`3.46.0-0.3.pre`, différence qui a son importance plus bas.

## Accès

| Élément | Emplacement |
| --- | --- |
| Page | `apps/avelune_studio/lib/presentation/features/world/` |
| Application | `apps/avelune_studio/lib/features/world/` |
| Raccordement à l'hôte | `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_world_binding.dart` |
| Captures | `documentation/reports/avelune_studio/UI12_etats_regles/captures/` |
| Entrée | Histoire → **États et règles du monde** |

## Continuité UI11

**R1 — import `ScrollCacheExtent`.** Le correctif préfixé était déjà présent
dans la base et n'a pas été touché. Sa validation ne vient pas d'une commande
locale : le workflow distant a tourné sur la tête courante et son étape
« Editor smoke and static checks » est passée avec le SDK qu'il épingle
lui-même (run `35592618319`). Aucune règle d'analyse, version épinglée ni
exclusion n'a été modifiée.

**R2 — retour après un détour par une seconde scène.** Le défaut est reproduit
puis corrigé. L'origine d'un retour n'était qu'un `WorkspaceSpace`, c'est-à-dire
un espace et non un document : ouvrir la scène B depuis les usages remplaçait
la scène active, puis le retour de B réempruntait l'ouverture générale des
présentations, laquelle remet l'origine à Histoire. Le parcours
A → P → B → P → A perdait donc A.

Le contexte de retour porte désormais l'identité du document visé, et l'entrée
dans une bibliothèque est distinguée du retour vers un document déjà ouvert.
Une destination disparue affiche un état explicite au lieu d'ouvrir un
homonyme. `previewSceneId` suivait la scène active, donc B après le détour ;
il suit maintenant l'origine réelle.

La preuve est un test qui monte le véritable `MapWorkspaceScreen` avec ses
ports de scène et de présentation et rejoue le parcours complet ; il échoue
avec le comportement précédent.

## Ce qui a été réutilisé

Aucun moteur nouveau. La page s'appuie sur `buildFactsWorldRulesManagerReadModel`
pour la bibliothèque, les usages et les catalogues de sources, cibles, effets et
dialogues ; sur `buildNarrativeDependencyIndex` pour les dépendances ; sur
`simulateNarrativeWorldState` pour le test ; sur les actions canoniques
`fact.*` et `world_rule.*` via la transaction de catalogue narratif ; et sur le
renderer de cartes du workspace pour l'aperçu.

**Les états ne sont pas réappropriés.** Les histoires gardent déjà leur version
de travail dans `NarrativeWorkspaceController.pendingFacts`, et la page édite ce
même brouillon : un état ouvert depuis une histoire et depuis cette page restent
un seul document. Les règles n'avaient pas de brouillon ; UI12 leur en donne un.

## Deux contraintes du modèle qui ont façonné le code

**L'identité appartient à l'opération canonique.** `fact.create` et
`world_rule.create` dérivent l'identifiant de leur libellé et refusent tout
autre, un identifiant provisoire étant rejeté à la publication. Le nom
définitif est donc calculé au moment d'enregistrer — un état nommé « Train
parti » devient `fact_train_parti` — et le brouillon comme les règles qui le
référencent suivent ce renommage.

**Une règle canonique est indivisible.** `WorldRuleDefinition` exige source,
cible et effet à la fois, alors que l'auteur les remplit un par un. Un brouillon
les garde optionnelles et ne devient une définition que lorsque la relation est
entière : une règle incomplète nomme ce qui lui manque, reste navigable, et
n'atteint ni les projections ni la publication.

## Composition livrée

Une page, deux vues liées. Bibliothèque à gauche avec sa recherche et sa
sélection propres à chaque vue, espace de composition au centre, panneau de
test à droite. À petite taille les panneaux se replient en feuilles et le
centre garde sa place ; aucune réduction homothétique.

La vue États édite nom, description, catégorie, type et **« Valeur initiale du
projet »**, nommée ainsi pour ne jamais se confondre avec la valeur de test ni
avec celle d'une partie. Les usages sont présentés séparément en « Lu par » et
« Modifié par ». Une liaison historique reste visible et bloque un changement de
type au lieu de disparaître.

La vue Règles compose la relation en trois blocs reliés. Le catalogue d'effets
est filtré par la cible, et changer de cible retire un effet devenu
incompatible plutôt que de conserver une combinaison que la projection
refuserait.

Le panneau de test annonce « Simulation locale — aucune modification du projet
ni d'une partie » et sépare trois faits que la maquette confondait : la règle
est-elle activée, sa condition est-elle satisfaite, son effet est-il celui que
la projection retient pour cette cible. Les règles concurrentes sur la même
cible sont listées avec leur priorité et un accès direct.

L'aperçu montre la vraie carte, avec une bascule Avant / Après qui conserve le
cadrage. L'image « après » retire du dessin ce que le rapport de simulation
masque : l'image et le verdict ne peuvent pas se contredire. Une cible sans
représentation visuelle n'obtient pas d'icône inventée — un événement affiche
son état, configuré ou non, actif ou non, masqué ou non.

## Écarts assumés par rapport au PNG

| Dans l'image 08 | Livré | Raison |
| --- | --- | --- |
| Type « Énumération » | Booléen, Nombre entier, Texte | `NarrativeValueKind` n'en contient pas d'autre ; une énumération stockée en chaîne serait une fausse capacité. |
| Plusieurs conditions, plusieurs effets, « Sinon » | Une source, une cible, un effet | `WorldRuleDefinition` est indivisible. Une règle inverse est un second document explicite, jamais un port caché. |
| « Animation d'apparition » | Absent | Aucun moteur correspondant. |
| « Journaliser l'exécution », « Exécuter au chargement » | Absents | Aucune capacité vérifiée derrière ces commandes. |
| États actif alors qu'une règle est éditée | L'onglet suit le document édité | Deux vues liées, une seule page. |
| Deux bibliothèques et un éditeur côte à côte | Une bibliothèque par vue | Les usages et le contexte vivent dans le panneau de droite. |
| Priorité « Normale » / « Haute » | Saisie numérique | Aucune table canonique ne définit ces libellés. |

## Sécurisation des brouillons et des sauvegardes

Trois défauts déduits du code lors de la revue de `2aee3e01`. Chacun a d'abord
été reproduit sur l'état courant du dépôt par un test qui échoue, puis corrigé.

**Une règle pouvait disparaître à la fermeture.** `pendingRules` ne participait
à aucune protection globale : `WorkspaceActions.allowClose()` interrogeait les
cartes, les ressources, les histoires, les scènes, les dialogues, les
cinématiques, les présentations et les événements, jamais le monde. La
reproduction est plus sévère que la déduction : avec un état sale en plus de la
règle, le dialogue s'affichait bien — grâce à l'état — l'auteur choisissait
« Enregistrer », l'état partait, la règle restait dans son brouillon, et
l'espace se fermait quand même. Une règle seule ne déclenchait aucune question.

Le contrôleur du monde est désormais fourni à `WorkspaceActions` comme les
autres. Ses brouillons de règles comptent dans la question posée, la branche
« Enregistrer » les publie après les états et les événements dont ils
dépendent, et une publication en cours compte dans `busy`. Pas de second
gestionnaire : c'est le même garde, donc aussi celui du changement de projet,
`allowSwitch` pointant sur `allowClose`.

Une règle qui refuse de partir garde l'espace ouvert et dit pourquoi : son
message rejoint l'erreur de l'espace de travail, visible hors de la page. Une
règle incomplète n'est jamais ignorée en silence, elle nomme ce qui lui manque
et fait échouer la fermeture.

**Une modification faite pendant une écriture était perdue.** `saveRule()`
retirait le brouillon sans condition au retour de la publication. La version
envoyée est maintenant figée avant l'appel ; au retour, la base enregistrée est
relue depuis le manifeste publié, et le brouillon vivant n'est effacé que s'il
lui est identique. S'il a changé pendant l'écriture, il survit — y compris
lorsque l'identifiant provisoire devient l'identifiant canonique : le
brouillon, son historique et la sélection suivent ce renommage au lieu d'être
supprimés avec l'ancienne clé.

**Une règle enregistrée avant son état levait une exception.** La préparation
canonique `addWorldRule` était appelée hors du `try` : un état encore en
brouillon faisait remonter un `ArgumentError` jusqu'au bouton. Elle est
désormais couverte, et la dépendance est nommée plutôt que traduite en erreur
d'authoring : « L'état « X » n'est pas encore enregistré. » La page propose de
l'enregistrer d'abord, dans le même geste. Si l'état part et que la règle
échoue ensuite, le résultat partiel est rapporté comme tel et le brouillon de
la règle est conservé. La même préparation canonique côté états est passée sous
gestion d'erreur. Aucun moteur transactionnel n'a été ajouté : ce sont deux
publications existantes enchaînées et un compte rendu honnête.

## Tests exacts

Les périmètres ne s'additionnent pas : la suite Studio contient déjà les tests
ciblés UI12.

| Périmètre | Commande | Résultat |
| --- | --- | --- |
| Parcours états et règles, écriture puis réouverture | `flutter test test/ui12_world_controller_test.dart` | vert |
| Composition depuis les contrôles de la page | `flutter test test/ui12_world_page_test.dart` | 2 verts |
| Brouillons de règles, écriture retenue, dépendance d'état | `flutter test test/ui12_world_drafts_test.dart` | 4 verts |
| Protections de fermeture, hôte réel | `flutter test test/ui12_world_close_test.dart` | 3 verts |
| Entrée Histoire et retour, hôte réel | `flutter test test/ui12_world_navigation_test.dart` | vert |
| Quatre tailles, texte à 150 % à 1024 | `flutter test test/ui12_world_responsive_test.dart` | 4 verts |
| Retour A → P → B → P → A, hôte réel | `flutter test test/ui12_workspace_return_test.dart` | vert |
| Parité simulateur et runtime | `flutter test test/narrative_world_state_simulation_parity_test.dart` (map_runtime) | 4 verts |
| Suite Studio | `flutter test` dans `apps/avelune_studio` | 656 verts, 2 ignorés, 1 échec d'environnement |
| Frontières d'architecture | `flutter test test/architecture/architecture_boundaries_test.dart` | 7 verts |
| Analyse Studio | `flutter analyze` | `No issues found!` |
| Étape CI Editor | workflow distant, run `35592618319` | succès |

Chaque correctif a été vérifié par la négative : le test de retour échoue avec
l'ouverture générale d'origine, et le test de priorité échoue lorsque la règle
concurrente passe en priorité inférieure. Les trois défauts du lot de
sécurisation ont été exécutés avant correction sur l'état courant : le
brouillon revenait vide après le reçu, `saveRule` levait un `ArgumentError`, et
les deux parcours de fermeture échouaient — l'un en fermant malgré la règle
restée en brouillon, l'autre sans même poser la question.

## Limites et échecs préexistants

**`packages/map_runtime`** compte quatre échecs et une erreur d'analyse sur
`scene_battle_runtime_outcome_adapter_test.dart`,
`scene_event_runtime_hook_test.dart`,
`session/playable_map_game_session_runtime_test.dart` et
`smart_tile_triggered_animation_render_test.dart`. L'attribution est démontrée,
pas supposée : la seule modification du paquet, le test de parité, a été
retirée et remise, et les quatre échecs se reproduisent à l'identique sans
elle. Ils concernent les issues de combat et les sessions, sans rapport avec ce
lot.

**`desktop_workspace_layout_test`** du Studio échoue par intermittence sur
cette machine, avec le message « Les E/S réelles ne terminent pas entre les
frames en 20 secondes ». Le défaut avait déjà été attribué à l'environnement
lors de UI11, par trois reproductions au commit de base ; il repasse au vert
lorsque la charge retombe. Les exécutions de ce lot se sont faites avec des
charges allant jusqu'à 180. Lors du lot de sécurisation, le même échec est
réapparu dans la suite complète puis a été rejoué seul, au vert, avec des
moyennes de charge de 62, 99 et 109.

Limites de la page, annoncées plutôt que masquées :

- l'ouverture d'un état **depuis un bloc de scène** n'est pas câblée ; le §18
  la présente comme une possibilité, pas une exigence ;
- les usages ouvrent une scène lorsque la destination est une scène ; les
  autres genres d'usage restent consultables sans navigation ;
- à 1024 × 640 avec texte à 150 %, le libellé « Nom de la règle » est à
  l'étroit contre le bord du panneau et le bloc Condition se prolonge sous la
  ligne de flottaison du défilement. Rien n'est inatteignable, mais c'est un
  écart de confort ;
- la simulation couvre les valeurs d'états, les étapes terminées et les
  événements consommés ; elle ne prétend pas exécuter une scène ;
- aucun parcours runtime publié n'a été joué pour observer le changement en
  jeu ; la parité est établie entre le simulateur et le hook de projection, ce
  qui n'est pas la même preuve.

Limites du lot de sécurisation :

- `saveAll()` publie les règles une par une par les actions canoniques
  existantes. Si la deuxième de trois échoue, la première est déjà écrite : le
  résultat partiel est rapporté et les brouillons restants sont conservés, mais
  l'ensemble n'est pas atomique. C'était la consigne, pas un oubli ;
- une fermeture demandée pendant une publication est refusée sans message,
  comme pour tous les autres contrôleurs : l'auteur voit seulement l'espace
  rester ouvert ;
- les cibles de règles sont validées contre les cartes chargées à l'ouverture
  de la page. Une entité présente uniquement dans un brouillon de carte reste
  donc refusée à l'enregistrement de la règle ;
- dans un test de widgets, deux écritures réelles enchaînées peuvent entrer en
  collision avec le `runAsync` de `pumpIo`. Le test de page attend sans en
  ouvrir un second ; le test de fermeture reste sensible au minutage.

La réserve UI07 sur le raccordement des résultats de scènes modernes à la
progression structurée reste ouverte : la source `storyStepCompletion` lit une
progression existante, elle ne l'implémente pas.

## Journaux

`logs/suite-studio-finale.txt` conserve la fin de la dernière exécution
complète, échec d'environnement compris.

## Captures

Rendus de widgets réels, sans retouche.

| Fichier | Contenu |
| --- | --- |
| `ui12-01-etats.png` | Vue États, définition enregistrée |
| `ui12-02-regle.png` | Vue Règles, relation composée et testée |
| `ui12-03-apres.png` | Aperçu Après la règle, personnage retiré du dessin |
| `ui12-04-taille-{1536,1440,1280,1024}.png` | Quatre tailles, texte à 150 % à 1024 |

## Validation attendue

La validation visuelle de Yoahn reste le dernier contrôle. UI13 n'est pas
commencé, et ce lot ne clôt ni la réserve UI07 ni la finalisation de la vue
d'ensemble UI05.
