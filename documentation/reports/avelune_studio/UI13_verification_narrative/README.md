# AS-UI-013 — Vérification narrative

Réalisation de l'image 09 du kit Narrative Studio, précédée de la validation
du correctif UI12 de la PR #10.

Base de travail : `main` à `edf0f96c96a8db4475c5f3eb084fc8a88062894c`, la base
exacte du pack. SDK local Flutter `3.48.0-0.4.pre` ; la CI épingle
`3.46.0-0.3.pre`, différence non levée par les exécutions locales de ce lot.

## Accès

| Élément | Emplacement |
| --- | --- |
| Page | `apps/avelune_studio/lib/presentation/features/verification/` |
| Application | `apps/avelune_studio/lib/features/verification/application/` |
| Domaine et adaptateur | `apps/avelune_studio/lib/features/verification/{domain,data}/` |
| Raccordement à l'hôte | `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_verification_binding.dart` |
| Entrée | Histoire → **Vérification narrative** |
| Captures | `documentation/reports/avelune_studio/UI13_verification_narrative/captures/` |

## Continuité UI12 — PR #10

Le correctif **n'était pas dans `main`** : `0eb343d9e` a `edf0f96c9` pour
parent et n'est pas un ancêtre de la tête. Il a donc été repris comme
changements locaux de fichiers (`git apply` du diff exact), sans fusion, sans
changement de branche et sans commit. Les modifications d'un autre intervenant
présentes dans l'arbre — icônes iOS et logos — ont été conservées.

**Ses tests ne compilaient pas.** Deux erreurs réelles, corrigées sans toucher
à l'attendu des tests :

- `test/ui12_world_close_test.dart` n'importait plus la bibliothèque du
  contrôleur monde, donc les méthodes d'extension `saveFact` et `saveRule`
  étaient introuvables ;
- `StorylineAsset` exige `type` ; l'histoire de `ui12_world_global_close_test`
  était construite sans lui.

**Un défaut de harnais bloquait ensuite trois tests.** La garde de fermeture
enchaîne désormais assez d'écritures réelles (`saveNewFacts`, présentations,
scènes, ressources, histoires, événements, monde, cartes) pour que l'une
d'elles ouvre un `runAsync` pendant celui de `pumpIo`, ce que `flutter_test`
refuse. Le correctif est à la source, pas dans le minutage :
`WidgetResourcePort.serial` fait attendre son tour à l'appelant au lieu de le
faire refuser. `pumpIo`, le port de ressources, le port narratif UI05 et le
port monde UI12 y passent tous.

La réserve notée dans le rapport UI12 — « le test de fermeture reste sensible
au minutage » — est donc levée.

Contrôle par la négative : les quatre fichiers de production de la PR retirés,
**4 tests tombent** (`invalid rule input blocks global save until corrected`,
`global close saves new world states with Stories connected`,
`invalid input on a clean rule still requires an explicit choice`,
`a failed rule keeps close blocked after its new state is saved`). Les tests
pilotent bien le correctif, et non le UI12 déjà présent.

## Ce qui a été réutilisé

Aucun moteur nouveau, aucun solveur nouveau. La page appelle
`validateNarrativeProject` pour les diagnostics, `buildNarrativeDependencyIndex`
pour le graphe et les identités, `validateNarrativePhysicalReachability` pour
l'accessibilité physique, `NarrativeMultidimensionalValidationReport` pour les
quatre dimensions, `NarrativeRuntimeSmokeReceipt` et
`selbrumeReleaseV1Profile` pour la preuve d'exécution,
`computeNarrativeProjectFingerprint` pour l'empreinte des entrées, et
`stableKey` comme identité de diagnostic.

`map_editor` n'est pas importé. Le coordinateur historique a été remplacé par
une mince orchestration Studio qui appelle les mêmes fonctions canoniques et
reprend sa répartition de codes (`narrative*` et
`oneShotRetryableOutcomeSoftlock` vers la dimension narrative, le reste vers la
structure).

**Une dépendance a été ajoutée : `map_gameplay`**, Dart pur, qui n'apporte que
`map_core`. Elle porte le solveur d'accessibilité physique. Le garde-fou
d'architecture du Studio a refusé son barrel dans la couche application, parce
qu'il atteint `map_core.dart` et donc `dart:io` : le solveur est donc appelé
**depuis l'adaptateur**, et ne traverse le port que sous forme canonique
(`NarrativeValidationDimensionResult`). Le garde-fou n'a pas été modifié.

## Honnêteté du verdict

Pas de score, pas de pourcentage, pas de jauge. Les quatre dimensions gardent
leurs états canoniques `pass / fail / indeterminate / notRun` avec des libellés
français, et `overallStatus` n'est pas remplacé par une moyenne. Sur la fixture
de recette, le rapport réel donne structure **En échec**, résolution narrative
**Vérifié**, accessibilité physique **Vérifié**, vérification en jeu **Non
exécuté** — quatre verdicts distincts, aucun promu.

Les compteurs viennent des diagnostics analysés. Une catégorie sans problème
affiche « Aucun problème détecté dans ce périmètre », jamais « 100 % ». Une
liste filtrée vide dit « Ce zéro est celui du filtre, pas celui du projet ».

Les catalogues Pokémon restent tri-état : le Studio ne les lit pas, ils sont
donc déclarés **non contrôlés** et `requirePokemonCatalogs` n'a pas été touché.
Le validateur produit lui-même l'avertissement correspondant.

**Preuve runtime.** Le reçu est lu à
`.pokemap/validation/narrative_runtime_smoke_receipt.json` et classé : absent,
illisible, mauvais profil, suites incomplètes, périmé, ou frais. L'empreinte
comparée est calculée avec le même cadrage et les mêmes exclusions que
l'écrivain canonique du reçu. Aucun reçu n'est fabriqué ; un reçu frais en
échec donne `fail`, pas `notRun`.

## Fraîcheur et identité du rapport

Chaque rapport porte sa date réelle, la version du validateur, le périmètre
analysé, l'empreinte des entrées (`computeNarrativeProjectFingerprint` sur le
manifeste de travail et les cartes) et une clé de fraîcheur.

Un filtre, un défilement ou un zoom n'invalident rien. Une modification de
contenu **sans changement d'identifiant ni de compte** rend le rapport périmé,
et la page affiche « Modifications depuis la vérification ». Le rapport garde
sa propre date : il n'est jamais recalculé en silence.

La clé de fraîcheur observe l'instance du manifeste adoptée, les brouillons
d'états, d'histoires et de règles, et les cartes ouvertes modifiées. Elle ne
surveille pas le disque en continu : une modification faite **hors du Studio**
n'est vue qu'au prochain contrôle explicite, et la page l'annonce dans ses
limites.

## Ce qui n'est jamais fait

Ouvrir la page, changer un filtre, sélectionner une ligne ou déplacer le graphe
ne lance aucun contrôle et n'écrit rien : un test compare les empreintes de
tous les fichiers du projet avant et après une consultation complète. Un second
clic pendant un contrôle est ignoré, pas empilé. Les boutons **Corriger**,
**Compléter** et **Optimiser** de la maquette sont remplacés par **Ouvrir dans
l'éditeur** : `hasDeterministicRepair` vaut `false`, aucune mutation n'en
découle.

Une règle UI12 incomplète n'est ni forcée dans le modèle ni ignorée : elle est
listée à part sous « Brouillons à compléter », avec ce qui lui manque.

## Écarts assumés par rapport au PNG

| Dans l'image 09 | Livré | Raison |
| --- | --- | --- |
| Score « 92 % Validé » et anneau | Quatre dimensions à état canonique | Aucun score valide n'est défini ; une moyenne masquerait un `notRun`. |
| Pourcentages par catégorie (100 %) | « Aucun problème détecté dans ce périmètre » | Un périmètre sans erreur connue n'est pas un périmètre terminé. |
| Compteurs 59 / 28 / 12 / 18 / 6 / 14 | Périmètre réel analysé | Les nombres du PNG sont illustratifs. |
| Boutons Corriger / Compléter / Optimiser | Ouvrir dans l'éditeur | Aucune réparation déterministe au contrat. |
| Exports PDF / Markdown / JSON | Absents | Le codec JSON existe, mais aucun export desktop n'est raccordé ; l'afficher serait un faux bouton. |
| « Condition toujours fausse », « Durée très longue (> 30s) » | Absents | Le validateur ne produit pas ces règles. |
| Aperçu de carte dans le panneau droit | Contexte textuel qualifié | Les miniatures ne sont pas chargées pour une vérification de références ; la localisation est nommée. |
| « Chapitre 2 · En développement » verrouillé | Absent | Un badge de maquette n'est pas un obstacle démontré. |

## Composition livrée

Cadre Avelune, navigation principale et tokens conservés. Titre, retour
Histoire, action dominante **Lancer la vérification** et périmètre annoncé dans
l'en-tête.

À gauche, la synthèse : quatre dimensions, compteurs par gravité, catégories
cliquables qui filtrent, brouillons à compléter, et un repli « Couverture et
limites ». Au centre, le graphe de contexte puis la liste. À droite, le détail
et l'ouverture de l'éditeur.

Le graphe est une **projection en lecture seule**. À la sélection, il montre le
propriétaire, la cible et un voisinage borné à 24 nœuds ; les arêtes portent un
sens dérivé du genre canonique de la cible (référence, condition, progression,
localisation) ; une référence absente est dessinée comme absente, en rouge,
sans document de remplacement. Pan, zoom, réduire, agrandir et ajuster à la vue
sont disponibles, les commandes étant des boutons atteignables au clavier.

La liste est paresseuse, triée erreurs d'abord et stable ; l'identité est
`stableKey`, jamais l'index de ligne. Une sélection masquée par un filtre est
annoncée « Sélection hors filtre » et l'action continue de viser le bon
élément.

## Navigation et retour

Les destinations canoniques sont raccordées aux pages existantes : scène UI06,
événement UI08, dialogue UI09, cinématique UI10, histoire UI07, état et règle
UI12, carte. Une destination absente affiche « Cible indisponible » au lieu
d'ouvrir un homonyme ; une cible disparue explique l'échec sans changer la
sélection.

Le retour est typé par espace : ouvrir une scène depuis la vérification pose
l'origine sur la vérification, et le retour retrouve le rapport, la sélection,
la recherche et les filtres. Un test dans le véritable `MapWorkspaceScreen`
rejoue Histoire → Vérification → règle → UI12 → retour et vérifie l'identité du
rapport par `identical`.

## Tests exacts

Depuis `apps/avelune_studio`.

| Périmètre | Commande | Résultat |
| --- | --- | --- |
| Continuité UI12 et PR #10 | `flutter test test/ui12_world_close_test.dart test/ui12_world_global_close_test.dart test/ui12_world_drafts_test.dart test/ui12_world_page_test.dart test/ui12_world_controller_test.dart test/ui12_world_navigation_test.dart test/ui12_workspace_return_test.dart` | 15 verts (`logs/ui12-pr10-continuite.txt`) |
| UI13, les cinq fichiers ensemble | `flutter test test/ui13_verification_controller_test.dart test/ui13_verification_runtime_test.dart test/ui13_verification_page_test.dart test/ui13_verification_navigation_test.dart test/ui13_verification_scale_test.dart` | **28 verts** (`logs/ui13-cible.txt`) |
| — contrôleur | `test/ui13_verification_controller_test.dart` | 12 |
| — preuves runtime | `test/ui13_verification_runtime_test.dart` | 6 |
| — page et parcours | `test/ui13_verification_page_test.dart` | 4 |
| — hôte réel, aller-retour | `test/ui13_verification_navigation_test.dart` | 1 |
| — quatre tailles et grande liste | `test/ui13_verification_scale_test.dart` | 5 |
| Frontières d'architecture | `flutter test test/architecture/architecture_boundaries_test.dart` | 7 verts (`logs/architecture.txt`) |
| Analyse Studio | `flutter analyze` | `No issues found!` (`logs/analyse.txt`) |
| Suite Studio | `flutter test` | **687 verts, 2 ignorés, 1 échec** (`logs/suite-studio-finale.txt`) |

Ce que ces tests prouvent, cas par cas : entrée passive sans calcul ni
écriture ; lancement unique malgré un second clic ; concordance exacte des
`stableKey` entre la page et `validateNarrativeProject` sur la même entrée ;
brouillon incomplet listé à part ; obsolescence sur modification de contenu
seule ; zéro filtré distinct du zéro projet ; sélection hors filtre ; absence
totale d'écriture disque pendant une consultation ; correction réelle dans
l'éditeur puis disparition du diagnostic à la relance et relecture par un
adaptateur neuf ; rapport d'un autre projet jamais adopté ; cinq états de reçu
runtime ; virtualisation à 4 000 lignes sans nouveau contrôle.

## Limites et écarts ouverts

- **Aucun parcours runtime réel n'a été joué.** La dimension « Vérification en
  jeu » lit un reçu ; elle ne l'écrit pas et le Studio n'a pas d'exécuteur. Sur
  un projet sans reçu, elle reste `notRun`.
- **La fraîcheur ne surveille pas le disque.** Une modification externe est vue
  au prochain contrôle explicite, pas en temps réel.
- **L'annulation abandonne le résultat, elle n'interrompt pas le solveur.**
  L'analyse canonique est synchrone ; le bouton « Abandonner le contrôle »
  libère la page et écarte le rapport en cours, ce que son libellé dit.
- **Les brouillons d'interactions ne sont pas représentables** dans le manifeste
  analysé. Leur nombre est nommé dans les limites du rapport et c'est leur
  version enregistrée qui est contrôlée.
- **Le retour depuis Histoires et progression rejoint Histoire**, pas le
  rapport : cet espace n'a pas d'origine typée dans l'hôte. Le libellé de la
  destination le dit avant l'ouverture.
- **Un clic simple sur une ligne attend la fenêtre de double-clic** (300 ms)
  parce que le double-clic ouvre l'éditeur, comme le demande le §12.
- À 1024 × 640 avec texte à 150 %, le panneau du graphe est à l'étroit et un
  nœud peut être coupé ; le graphe garde son pan et son zoom, et la liste, le
  lancement et l'accès à l'éditeur restent atteignables.
- Le périmètre analysé est narratif. Les catalogues Pokémon, les objets et les
  abilities ne sont pas lus : ils sont déclarés non contrôlés.
- La réserve UI07 **résultats des scènes modernes → progression structurée**
  reste ouverte, et UI13 ne la contourne pas.

## Échecs observés

**`desktop_workspace_layout_test`** échoue dans la suite finale et à nouveau
seul, avec « Les E/S réelles ne terminent pas entre les frames en 20 secondes »
(`logs/desktop-layout-seul.txt`). Ce test n'est pas touché par ce lot, et le
même symptôme avait été attribué à l'environnement lors de UI11, par trois
reproductions au commit de base. Ce soir il est instable : **passé seul deux
fois, échoué seul une fois**, avec des moyennes de charge comprises entre 374
et 507. Je n'ai pas rejoué ce test au commit de base dans ce lot, donc je ne le
déclare pas préexistant : je le signale comme instable sous charge et à
revérifier sur une machine calme.

**`cinematics_ui10_error_recovery_test`** a échoué **une seule fois**, dans une
exécution intermédiaire de la suite, puis a passé trois fois seul et dans les
deux suites suivantes. Le détail de l'échec n'a pas été capturé dans ce
journal. Ce test parle des champs invalides, que la PR #10 modifie dans
`studio_commit_field.dart` : à surveiller, même si rien n'a pu être reproduit.

## Journaux et captures

`logs/` conserve les sorties des commandes ci-dessus, produites sur l'état
final livré. La suite Studio de ce journal n'écrit pas ses captures ici : le
dossier ne contient que les rendus UI13. `captures/` contient les
rendus de widgets réels, sans retouche :

| Fichier | Contenu |
| --- | --- |
| `ui13-00-avant-controle.png` | Page ouverte, aucun contrôle lancé |
| `ui13-01-rapport.png` | Rapport réel daté, quatre dimensions |
| `ui13-02-diagnostic.png` | Diagnostic sélectionné, contexte et éditeur |
| `ui13-03-perime.png` | Rapport devenu périmé après une modification |
| `ui13-04-taille-{1536,1440,1280,1024}.png` | Quatre tailles, texte à 150 % à 1024 |

## Validation attendue

La validation visuelle de Yoahn reste le dernier contrôle. Aucun commit, aucune
fusion, aucune écriture Notion. UI13 n'est pas clos tant qu'il ne l'a pas vu,
et ce lot ne termine ni UI05 ni la réserve UI07.
