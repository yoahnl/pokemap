# NS-EVENT-RESET-00 — Event Builder V2 Reference UI Specification V0

## 1. Image source et dimensions

Source officielle fournie par l’utilisateur :

```text
/Users/karim/Desktop/assets/pokeMap/définitive/4 - événements/1 - événements.png
```

```text
Dimensions : 1672 × 941 px
SHA-256 : 2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885
Statut : north star Event Builder V2
```

Légende des mesures :

- **[M] mesuré** : relevé reproductible accompagné d'un artefact annoté ;
- **[E] estimé** : déduit visuellement, tolérance ±4 px ;
- **[V] à valider** : dépend du rendu Flutter, du font metrics ou de
  l’interaction réelle.

Cette image est une cible de composition, densité et hiérarchie. Elle n’autorise
pas à déplacer dans l’Event Builder des responsabilités appartenant aux Scenes.

## 2. Découpage en régions

Coordonnées au format `x, y, largeur, hauteur` :

| Région | Bounding box | Largeur écran | Statut |
|---|---:|---:|---|
| Header marque | `0, 0, 1672, 50` | 100 % | [E] |
| Barre contexte/actions | `207, 50, 1465, 52` | 87,6 % | [E] |
| Navigation produit | `8, 102, 191, 817` | 11,4 % | [E] |
| Colonne Événements | `207, 102, 266, 817` | 15,9 % | [E] |
| Bibliothèque | `481, 102, 213, 817` | 12,7 % | [E] |
| Éditeur central | `702, 102, 565, 817` | 33,8 % | [E] |
| Inspecteur | `1274, 102, 388, 817` | 23,2 % | [E] |

La structure cible est donc un shell fixe à cinq panneaux :

```text
Navigation | Events | Bibliothèque | Éditeur | Inspecteur
```

Cette cible V2 supersède, pour le futur produit, le choix de simplification
NS-EVENT-41 qui masquait la bibliothèque permanente. La bibliothèque revient
par décision utilisateur explicite, mais ses capacités doivent rester honnêtes.

## 3. Grille de layout

- Marges viewport gauche/droite : **[E] 8–10 px**.
- Gouttières entre panneaux : **[E] 8 px**.
- Ligne de départ du workspace : **[E] y = 102 px**.
- Hauteur utile des panneaux : **[E] 817 px**.
- Padding Events : **[E] 14 px**.
- Padding Bibliothèque : **[E] 10–12 px**.
- Padding Éditeur : **[E] 18 px**.
- Padding Inspecteur : **[E] 17 px**.
- Alignement vertical des quatre panneaux métier strict à `y = 102`.
- Le header marque occupe toute la largeur ; la barre contexte commence après
  la navigation, à `x = 207`.

Contraintes Flutter futures :

```text
navigation = 191 px
events = 266 px
library = 213 px
editor = min 565 px à la référence
inspector = 388 px
gaps = 8 px
```

Le centre absorbe en priorité les variations de largeur. Les colonnes Events et
Inspecteur ne doivent pas osciller lors d’un changement de sélection.

## 4. Largeurs et hauteurs estimées

### Chrome

| Élément | Mesure |
|---|---:|
| Header marque | [E] 50 px |
| Barre contexte/actions | [E] 52 px |
| Contrôle standard du header | [E] ~36 px |
| Bouton icône header | [E] ~42 × 36 px |

### Éditeur central

| Élément | Bounding box |
|---|---:|
| Déclencheur | `[E] 720, 148, 302, 74` |
| Conditions | `[E] 720, 240, 391, 120` |
| Actions | `[E] 720, 376, 391, 114` |
| Bande Résultats | `[E] 720, 508, 391, 34` |
| Issue Victoire | `[E] 743, 565, 140, 32` |
| Issue Défaite | `[E] 943, 565, 134, 32` |
| Réactions gauche | `[E] 716, 611, 190, 120` |
| Réactions droite | `[E] 918, 611, 195, 120` |
| Changements du monde | `[E] 720, 746, 391, 105` |
| Fin de l’événement | `[E] 831, 867, 162, 35` |
| Drop target latéral de l'image | `[E] 1128, y, 102, 48` ; référence mesurée, non rendu en V2 sans drag/drop fonctionnel |

Le rail principal mesure environ **391 px**. Les branches résultats débordent
latéralement sans modifier la largeur de colonne.

### Contrôles

- Champs et lignes : **[E] 30–32 px**.
- Lignes Bibliothèque : **[E] 27–29 px**.
- CTA `Nouvel événement` : **[E] 221, 849, 237, 41**.
- Badges : **[E] 16–20 px** de haut.
- Ports : **[E] 7–8 px** de diamètre.

## 5. Espacements

- Espacement titre → aide : **[E] 3–5 px**.
- Espacement aide → premier contrôle : **[E] 10–12 px**.
- Padding interne d’une ligne compacte : **[E] 7–10 px horizontal**.
- Espacement entre blocs centraux : **[E] 14–18 px**, connecteur inclus.
- Espacement entre sections Inspecteur : **[E] 16–20 px**.
- Séparateur Inspecteur : **[E] 1 px**, avec 14–18 px de respiration.
- Groupes Bibliothèque : **[E] 8–10 px** entre catégories.
- Aucun grand espace décoratif : chaque zone visible sert la lecture ou l’action.

## 6. Typographies

| Usage | Taille / graisse estimée |
|---|---|
| Marque | 20 px / 700 |
| Titre principal de panneau | 15–16 px / 600–700 |
| Titre d’Event Inspecteur | 16 px / 700 |
| Navigation et CTA | 13 px / 500–600 |
| Corps et champs | 11–12 px / 400–500 |
| Section uppercase | 11–12 px / 600–700 |
| Métadonnées et aide | 10–11 px / 400–500 |

Famille probable : Inter ou sans-serif UI proche. **[V]** La famille exacte,
les hauteurs de ligne et métriques doivent être validées contre les tokens
PokeMap. Aucun letter-spacing négatif.

Les titres de cartes restent compacts ; aucun texte hero dans un outil dense.

## 7. Couleurs sémantiques

Palette estimée, à mapper sur les tokens PokeMap :

| Rôle | Valeur visuelle estimée |
|---|---|
| Fond viewport | `#07111D` |
| Panneaux | `#0B1624` |
| Champs | `#0A1421` |
| Bordure neutre | `#1B2A3B` |
| Texte fort | `#F1F5F9` |
| Texte secondaire | `#A5B1C3` |
| Texte muted | `#6F7E92` |
| Sélection | bleu `#3B82F6`, fond `#142B4D` |
| Déclencheur | violet `#A855F7` |
| Conditions | bleu `#4B8DF8` |
| Actions / validé | vert `#22C55E` |
| Réactions | ambre `#F59E0B` |
| Monde | cyan `#16C2D5` |
| Défaite / erreur | rouge `#EF4444` |

Les couleurs métier sont des bordures, icônes et fonds teintés à **[E] 8–14 %
d’opacité**, pas de grands aplats. Les valeurs exactes et contrastes WCAG sont
**[V]**. Aucun hardcode feature ne sera autorisé : tokens design system seuls.

## 8. Cartes et surfaces

- Shells structurants : rayon **[E] 7–8 px**, bordure 1 px.
- Blocs métier : rayon **[E] 6–7 px**.
- Inputs et lignes sélectionnées : rayon **[E] 5–6 px**.
- Drop targets de la référence : rayon **[E] 8 px**, bordure pointillée 1 px.
  Ils ne sont pas reproduits tant qu'un drag/drop fonctionnel et accessible
  n'est pas livré.
- Badges : capsule.
- Ombres très faibles ; la hiérarchie vient surtout des bordures et contrastes.

Types de cartes :

```text
shell de panneau
ligne de navigation
groupe de bibliothèque teinté
bloc métier
table compacte
issue
réaction read-only
terminal
diagnostic
```

Les cartes ne sont pas imbriquées pour la décoration. Une carte interne existe
uniquement si elle représente une unité métier répétable ou interactive.

### 8.1 Liste Events project-level

La colonne Events est une vue de tout le projet. Les titres de maps/zones vus
dans la north star sont des regroupements et facettes de filtre, jamais des
owners. La map active ne réduit pas implicitement la liste. Les Events
`outcomeReceived`, les drafts sans source et les sources cassées restent
accessibles dans des groupes dédiés.

## 9. Bibliothèque

La Bibliothèque est permanente à la largeur cible. Elle sépare visuellement ce
que l'Event peut modifier de ce qui appartient à la Scene liée :

```text
CONFIGURER L'ÉVÉNEMENT
Déclencheurs
Conditions
Scene liée
Comportement

DANS LA SCENE LIÉE
Résultats
Réactions
Monde
```

Règles fonctionnelles :

- clic comme interaction primaire pour les éléments Event-owned ;
- aucun grip, cadre pointillé, texte `Déposez ici` ou affordance de drag/drop
  tant que le geste, l'alternative clavier, les cibles valides et les tests
  d'interaction ne sont pas livrés ;
- disponibilités calculées depuis le contrat réel ;
- résultat, réaction et monde n'ont ni grip ni commande `Ajouter`. Ils sont
  marqués `Lecture seule` / `Défini dans la Scene` et leur seule commande est
  `Ouvrir la Scene` ou `Voir le détail` ;
- `Jouer une Scene` est l’action Event V0 ; combat, dialogue, cinématique,
  récompense et conséquence apparaissent uniquement comme capacités du Scene
  Builder, jamais comme lignes ajoutables à l'Event ;
- aucune ligne décorative ne doit paraître authorable ;
- catégories et lignes conservent les teintes de l’image.

## 10. Éditeur central

Le flow visuel reste vertical et borné :

```text
Déclencheur source-first
→ Conditions
→ Action principale : Scene
→ Issues de la Scene en lecture seule
→ Réactions de Scene en lecture seule
→ Changements du monde projetés en lecture seule
→ Comportement Event
→ Fin
```

Le bloc Déclencheur doit afficher :

```text
Type : Interaction avec un personnage ou un objet
Cible : Lysa — PNJ
Lieu : Port des Brisants
```

Actions locales : `Modifier`, `Changer de source`, `Voir sur la carte`.

Si plusieurs Events actifs partagent la même source, un résumé contextuel est
obligatoire :

```text
3 événements utilisent cette source
Premier candidat évalué selon l'ordre actuel : Rencontre Lysa au port
L'exécution dépendra des conditions, de la consommation et des exécutions en cours.
[Gérer l'ordre de déclenchement]
```

Le réglage no-code expose une `Priorité de déclenchement`. L'`order` stable et
le tie-break par ID restent des détails internes. Publier produit toujours un
Event configuré inactif. Un conflit `(priority, order)` avec un autre Event
actif autorise cette publication mais bloque l'action séparée `Activer` jusqu'à
réparation. `Désactiver` reste disponible sur un Event actif.

Le centre n’est pas un graph libre. Les connecteurs servent la lecture d’un
ordre connu. Les branches visibles proviennent des outcomes de la Scene liée ;
elles ne créent pas un second moteur de branchement Event.

## 11. Inspecteur

Ordre cible :

1. résumé Event, statut et ID secondaire ;
2. `SOURCE DU DÉCLENCHEUR` ;
3. conditions ;
4. Scene liée et projections ;
5. comportement ;
6. concurrence sur la source, uniquement si elle existe ;
7. diagnostics et navigation.

La section source contient obligatoirement :

```text
Type
Cible
Lieu
Voir sur la carte (si source spatiale)
Changer de source
```

Les références techniques restent masquées dans le parcours normal. Pour une
source non spatiale, aucun CTA carte n’est rendu. Pour une source cassée,
`Rebrancher la source` remplace la navigation.

La section concurrence affiche les autres Events actifs, leur priorité humaine,
le premier candidat évalué pour le snapshot courant et une action `Gérer
l'ordre de déclenchement`. Elle précise qu'un candidat suivant peut être choisi
si le précédent est inéligible. Elle est absente lorsqu'une source n'a qu'un
seul Event actif.

## 12. États

États obligatoires :

- Event sélectionné / non sélectionné ;
- actif, brouillon, inactif ;
- prêt, à configurer, à corriger ;
- source non choisie, choisie, manquante, supprimée, non supportée ;
- source spatiale / non spatiale ;
- liste vide, recherche vide, catégorie vide ;
- lecture seule Scene-owned ;
- chargement, sauvegarde, conflit de révision ;
- hover, focus clavier, disabled, pressed ;
- diagnostics error, warning et info.

Les états ne reposent jamais uniquement sur la couleur : icône, texte et
semantics sont obligatoires.

`Source non choisie` affiche `Aucun élément déclencheur choisi`, une commande
`Choisir un élément déclencheur`, aucun CTA carte et une publication bloquée.
Cet état de draft est persisté au reload et reste distinct d'une référence
cassée. Une source cassée conserve sa référence exacte et affiche une erreur
bloquante avec `Rebrancher` ou `Détacher` explicite.

## 13. Scrolls

- Aucun scroll global du shell à 1672 × 941.
- Scroll vertical indépendant pour Events, Bibliothèque, Éditeur et Inspecteur.
- Headers de panneau sticky à la référence ; CTA bas de liste sticky dans la
  colonne Events. Cette décision doit être testée, pas laissée implicite.
- Le rail central garde son axe au scroll ; les connecteurs restent alignés.
- Une sélection ne doit pas modifier le scroll des colonnes non concernées.
- Changer d’Event replace le centre sur le premier bloc en erreur ou le début.
- Le focus clavier doit faire défiler uniquement la colonne propriétaire.
- À largeur réduite, la Bibliothèque s'ouvre en side sheet modale au-dessus du
  workspace. Le fond devient inerte, Tab/Shift+Tab restent dans la sheet,
  `Escape` la ferme et le focus revient au bouton d'ouverture.
- La fermeture/réouverture conserve scroll et catégorie active pendant la
  session ; un changement de projet les réinitialise.
- Pour 3 outcomes ou plus, les branches passent en liste verticale compacte ;
  aucun connecteur ne sort du viewport horizontal.

## 14. Interactions

### Création Narrative Studio

```text
Nouvel événement
→ Nom
→ Type de déclenchement
→ Map si nécessaire
→ Source réelle
→ Conditions
→ Scene
→ Comportement
→ Publier (configuré inactif)
→ Activer (action séparée, soumise aux conflits)
```

Matrice de sélection et de persistance :

| Type choisi par l'auteur | Écrans visibles | Choix humain | Référence persistée | Gate de publication |
|---|---|---|---|---|
| `Parler ou examiner` | Lieu → personnage/objet | libellé + kind + aperçu map | `entityInteract(mapId, entityId)` | map et entity existantes |
| `Entrer dans une zone` | Lieu → zone | nom + footprint aperçu | `triggerEnter(mapId, triggerId)` | map et trigger existants |
| `Arriver sur une carte` | carte | nom et aperçu de la carte | `mapEnter(mapId)` | map existante |
| `Après un résultat` | résultat | origine Scene/Battle ou bridge Scenario legacy + libellé | `outcomeReceived(NarrativeOutcomeRef)` | producteur public stable et résultat existants/émettables |

Chaque variante doit couvrir le test : choisir → sauvegarder → fermer → rouvrir
→ retrouver la même source. Yarn apparaît seulement comme contexte sous la
Scene qui le réémet ; il persiste `producerKind = scene`. Un dialogue hors Scene
reste legacy et non sélectionnable V2.

Une suppression externe conserve le record configuré et la référence cassée,
affiche un diagnostic bloquant et n'effectue aucune mutation au chargement.
Seule l'action explicite `Détacher`, après impact preview, transforme le record
en draft sans source. Aucune correspondance de nom ou de position n'est admise.

### Création Map Editor

```text
Sélectionner Lysa / une zone / un objet
→ Créer un Event ici
→ source préremplie
→ ouvrir le même Event dans Narrative Studio
```

### Navigation

- `Voir sur la carte` ouvre la bonne map, sélectionne et centre la source.
- `Choisir sur la carte` utilise le vrai Map Editor, jamais une mini-map.
- `Changer de source` préserve nom, conditions, Scene et comportement.
- Retirer la source laisse un brouillon incomplet sans supprimer la source.

Termes interdits dans l’UI normale :

```text
layerId
EventPosition
MapEventType
metadata
sourceId technique
binding
adapter
```

Traductions no-code obligatoires :

| Terme modèle/diagnostic | Libellé UI normal |
|---|---|
| entity | personnage ou objet |
| source | élément déclencheur, ou libellé concret |
| map scope | lieu |
| outcome | résultat |
| oneShot | une seule fois |
| reusable | à chaque fois |
| legacy | ancien format à convertir |
| runtime unsupported | non disponible en jeu dans cette version |

`Source` reste acceptable comme titre secondaire dans les diagnostics avancés,
jamais comme seule instruction de choix.

## 15. Responsive desktop

### 1672 × 941

Référence stricte : cinq panneaux visibles et mesures ci-dessus.

### 1480–1671 px

- navigation 176–191 px ;
- Events 236–266 px ;
- Bibliothèque 190–213 px ;
- Inspecteur 330–388 px ;
- centre minimum 500 px ;
- densité légèrement réduite, aucune suppression fonctionnelle ;
- budget minimal vérifié : `176 + 236 + 190 + 500 + 330 + 32 gaps + 16
  marges = 1480 px`.

### 1280–1479 px

- navigation réductible par commande explicite si le budget l'exige ;
- Bibliothèque devient une side sheet modale avec bouton, fond inerte, focus
  trap, focus retour et `Escape`, pas une disparition silencieuse ;
- Inspecteur reste accessible en panneau droit ;
- aucun texte ou bouton ne doit déborder ;
- à 1280 px, budget cible hors Bibliothèque : `168 navigation + 220 Events +
  480 centre + 320 Inspecteur + 24 gaps + 16 marges = 1228 px`.

Sous 1280 px : état desktop non supporté V0 qui préserve l'état de l'éditeur et
le focus précédent. Aucun font-size ne varie directement avec la largeur.

## 16. Écarts fonctionnels volontaires

La north star contient des contrôles qui dépassent le contrat Event canonique.
Écarts obligatoires :

| Image | V2 honnête |
|---|---|
| Actions directes combat/objet/téléport | Scene-owned ; lien vers Scene Builder |
| Résultats possibles authorables | Outcomes de Scene, lecture seule |
| Réactions Event | Branches/réactions de Scene, lecture seule |
| Changements du monde éditables | SceneConsequences read-only ; World Rules passives |
| Drop targets partout | Absents tant que drag/drop et alternative clavier ne sont pas fonctionnels |
| Fin de l’Event après branches | Fin du résumé projeté, pas exécution d’un graph Event |

Frontière non négociable :

```text
Event déclenche.
Scene orchestre.
Cinematic met en scène.
Battle résout.
Fact persiste.
World Rule projette.
Validator diagnostique.
```

## 17. Visual QA future

Chaque lot visuel de Phase K doit produire :

- capture référence 1672 × 941 ;
- capture implémentation 1672 × 941 ;
- overlay 50 % ;
- comparaison côte à côte ;
- matrice zone par zone ;
- capture liste vide, création, édition, source cassée et diagnostic ;
- desktop 1280, 1440, 1672 et largeur large ;
- text scale 100 % et 125 % ;
- assertions anti-overflow et glyphes ;
- audit clavier/semantics ;
- justification de chaque écart majeur.

Protocole de mesure reproductible :

1. raster source identifié par le SHA-256 de la section 1 ;
2. coordonnées en pixels physiques, origine au coin haut-gauche inclus ;
3. bounding box relevée bord extérieur inclus à 100 % sur le raster source ;
4. capture Flutter avec `devicePixelRatio = 1.0`, ou normalisée sans interpolation
   vers le même raster 1672 × 941 avant comparaison ;
5. script ou calque d'annotation conservé dans l'Evidence Pack de V2-38 ;
6. une mesure sans artefact annoté reste `[E]`. Toutes les coordonnées de ce V0
   sont donc `[E]` ; V2-38 pourra les promouvoir en `[M]` avec son Evidence Pack.

L’image seule n’est pas une validation. La comparaison doit utiliser le même
état, les mêmes données et le même viewport.

## 18. Critères pixel-fidelity

Verdict visuel PASS lorsque :

- bords des panneaux à ±4 px de la référence ;
- gouttières à ±2 px ;
- hauteurs chrome à ±3 px ;
- baseline des titres à ±3 px ;
- largeur des colonnes à ±1,5 % ;
- rayons et bordures perceptuellement équivalents ;
- palette mappée aux tokens avec contraste AA ;
- densité des lignes comparable sans clipping ;
- connecteurs non cassés et ports centrés ;
- CTA, sélection et statuts reconnaissables immédiatement ;
- aucun contrôle trompeur ajouté pour copier le raster ;
- aucun drop target ou grip sans interaction fonctionnelle et clavier ;
- aucun ownership Event/Scene violé ;
- chaque différence majeure est corrigée, documentée ou justifiée.

Réserves à valider dans l’application : famille typographique exacte, opacités,
scrollbars, sticky headers, hit areas, clavier, drag/drop et rendu des listes
dynamiques.
