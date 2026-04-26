# Surface Engine - Lot 1 - Caracterisation de l'autotile existant

Date: 2026-04-26

## 1. Resume executif

Le Lot 1 a ete execute comme un lot de caracterisation uniquement. Aucun modele Surface n'a ete cree, aucun fichier de production n'a ete modifie, aucun modele Freezed/JSON n'a ete touche et aucun comportement runtime/editor/gameplay n'a ete change.

Le travail ajoute un nouveau fichier de test:

- `packages/map_core/test/map_terrain_autotile_characterization_test.dart`

Ce test verrouille le comportement actuel de `packages/map_core/lib/src/operations/map_terrain_autotile.dart` autour de:

- la table de correspondance masque cardinal -> `TerrainPathVariant`;
- les formes cardinales de base;
- les lignes horizontales et verticales;
- les quatre coins;
- les quatre tes;
- la croix;
- le bloc plein 3x3;
- les coins interieurs lies aux diagonales;
- les comportements speciaux en bord de carte;
- les cellules inactives;
- les coordonnees hors grille;
- les tailles invalides;
- les grilles incompletes;
- la tolerance des listes trop longues;
- la parite generale entre resolver path et resolver terrain.

Le test cible passe avec 21 tests. Le test complet de `map_core` a ete lance et echoue sur un test existant hors lot, `legacy_editor_json_compat_collision_test.dart`, avec une erreur de parsing JSON de profil collision. Cet echec n'est pas lie au nouveau fichier de caracterisation.

## 2. Fichiers consultes

### Instructions et etat repo

- `AGENTS.md`
- `reports/analysis/surface_engine_initial_audit.md`

### Production map_core

- `packages/map_core/lib/src/operations/map_terrain_autotile.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/geometry.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/pubspec.yaml`

### Tests map_core existants

- `packages/map_core/test/path_preset_frames_test.dart`
- `packages/map_core/test/path_animation_triggers_test.dart`
- liste des tests sous `packages/map_core/test` via `rg --files`
- recherche des usages `resolvePathVariantAt`, `resolveTerrainPathVariantAt`, `resolvePathCardinalMaskAt`, `resolveTerrainCardinalMaskAt`, `TerrainPathVariant`, `PathLayer`, `TerrainLayer` via `rg`

## 3. Fichiers crees

- `packages/map_core/test/map_terrain_autotile_characterization_test.dart`
- `reports/analysis/surface_engine_lot_1_autotile_characterization.md`

## 4. Fichiers modifies

Aucun fichier de production existant n'a ete modifie.

Les seules modifications de contenu de ce lot sont les deux fichiers nouveaux listes ci-dessus. Le fichier de test a ensuite ete formate avec `/opt/homebrew/bin/dart format`.

## 5. Liste complete des cas testes

Le nouveau fichier contient 21 tests.

### Table de masques

1. `resolvePathVariantFromMask(0..15)` est caracterise completement:
   - `0 -> isolated`
   - `1 -> endNorth`
   - `2 -> endEast`
   - `3 -> cornerNE`
   - `4 -> endSouth`
   - `5 -> vertical`
   - `6 -> cornerSE`
   - `7 -> teeEast`
   - `8 -> endWest`
   - `9 -> cornerNW`
   - `10 -> horizontal`
   - `11 -> teeNorth`
   - `12 -> cornerSW`
   - `13 -> teeWest`
   - `14 -> teeSouth`
   - `15 -> cross`
2. Les masques invalides `-1` et `16` jettent `ValidationException`.

### Formes cardinales path

3. Cellule active isolee:

```text
...
.X.
...
```

Attendu actuel: masque `0`, variante `isolated`.

4. Ligne horizontale:

```text
.....
.XXX.
.....
```

Attendus actuels:

- cellule centrale: masque `10`, variante `horizontal`;
- extremite gauche: masque `2`, variante `endEast`;
- extremite droite: masque `8`, variante `endWest`.

5. Ligne verticale:

```text
..X..
..X..
..X..
```

Attendus actuels:

- cellule centrale: masque `5`, variante `vertical`;
- extremite haute: masque `4`, variante `endSouth`;
- extremite basse: masque `1`, variante `endNorth`.

6. Coins en L:

```text
.X.
.XX
...
```

Attendu actuel: `cornerNE`.

```text
.X.
XX.
...
```

Attendu actuel: `cornerNW`.

```text
...
.XX
.X.
```

Attendu actuel: `cornerSE`.

```text
...
XX.
.X.
```

Attendu actuel: `cornerSW`.

7. Tes:

```text
.X.
XXX
...
```

Attendu actuel: `teeNorth`.

```text
...
XXX
.X.
```

Attendu actuel: `teeSouth`.

```text
.X.
XX.
.X.
```

Attendu actuel: `teeWest`.

```text
.X.
.XX
.X.
```

Attendu actuel: `teeEast`.

8. Croix:

```text
.X.
XXX
.X.
```

Attendu actuel: masque `15`, variante `cross`.

9. Bloc plein 3x3:

```text
XXX
XXX
XXX
```

Attendus actuels:

- centre: masque `15`, variante `cross`;
- bord haut non-corner: masque `14`, variante finale `cross` par promotion de bord;
- coin haut-gauche: masque `6`, variante `cornerSE`.

### Diagonales

10. Une seule diagonale manquante, avec les quatre cardinaux presents, produit un coin interieur.

Missing NE:

```text
XX.
XXX
XXX
```

Attendu actuel: `innerCornerNE`.

Missing SE:

```text
XXX
XXX
XX.
```

Attendu actuel: `innerCornerSE`.

Missing SW:

```text
XXX
XXX
.XX
```

Attendu actuel: `innerCornerSW`.

Missing NW:

```text
.XX
XXX
XXX
```

Attendu actuel: `innerCornerNW`.

11. Plusieurs diagonales manquantes avec les quatre cardinaux presents restent `cross`.

```text
.X.
XXX
.X.
```

Attendu actuel: `cross`.

### Bords de carte

12. Une cellule de bord haut non-corner avec voisins est/ouest est promue en `cross`.
13. Une cellule de bord bas non-corner avec voisins est/ouest est promue en `cross`.
14. Une cellule de bord gauche non-corner avec voisins nord/sud est promue en `cross`.
15. Une cellule de bord droit non-corner avec voisins nord/sud est promue en `cross`.
16. Une cellule dans un coin de map qui touche deux bords garde sa variante de coin, par exemple top-left avec est/sud actifs garde `cornerSE`.
17. Une cellule de bord qui touche exactement un bord peut convertir un coin en extremite. Exemple top edge, base `cornerSE`, variante finale `endEast`.

### Cellule inactive et entrees invalides

18. Une cellule courante inactive n'est pas verifiee par le resolver. Si ses voisins cardinaux sont actifs, elle peut resoudre `cross`.

```text
.X.
X.X
.X.
```

La cellule centrale est inactive, mais la variante actuelle retournee est `cross`.

19. Les coordonnees hors grille jettent `ValidationException`:

- `x < 0`;
- `y < 0`;
- `x >= width`;
- `y >= height`.

20. Les tailles invalides ou grilles incompletes jettent `ValidationException`:

- largeur `0`;
- hauteur `0`;
- liste de cellules plus courte que `width * height`.

21. Une liste de cellules plus longue que `width * height` est acceptee et les cellules supplementaires sont ignorees par l'indexation courante.

### Terrain resolver

Les tests incluent aussi la parite terrain:

- le resolver terrain utilise `TerrainType` comme matcher;
- un terrain demande qui ne correspond pas aux voisins produit le masque du terrain demande, pas le masque des autres terrains;
- le resolver terrain a le meme comportement que le path resolver sur cellule courante inactive;
- les validations terrain rejettent les grilles incompletes et positions hors bornes.

## 6. Ce que les tests prouvent sur le comportement actuel

### Fonction publique actuellement utilisee

Les fonctions publiques pertinentes exposees par `map_core.dart` sont:

- `resolvePathCardinalMaskAt`;
- `resolvePathVariantFromMask`;
- `resolvePathVariantAt`;
- `resolveTerrainCardinalMaskAt`;
- `resolveTerrainPathVariantFromMask`;
- `resolveTerrainPathVariantAt`.

La fonction interne commune est `_resolvePathVariantAt`. Elle est utilisee par le resolver path et le resolver terrain.

### Valeurs `TerrainPathVariant` existantes

Les valeurs existantes sont:

- `isolated`
- `endNorth`
- `endEast`
- `endSouth`
- `endWest`
- `horizontal`
- `vertical`
- `cornerNE`
- `cornerSE`
- `cornerSW`
- `cornerNW`
- `innerCornerNE`
- `innerCornerSE`
- `innerCornerSW`
- `innerCornerNW`
- `teeNorth`
- `teeEast`
- `teeSouth`
- `teeWest`
- `cross`

Il n'existe pas de variante distincte nommee `center` ou `fill`. Le centre d'un bloc plein 3x3 resout actuellement `cross`.

### Voisins cardinaux

Les voisins cardinaux sont encodes dans un masque quatre bits:

- nord: `1`;
- est: `2`;
- sud: `4`;
- ouest: `8`.

La table `resolvePathVariantFromMask` est le contrat central actuel. Le resolver ne regarde pas la cellule courante pour calculer ce masque: il regarde uniquement les voisins.

### Diagonales

Les diagonales ne sont prises en compte que si le masque cardinal vaut `15`, donc si les quatre voisins cardinaux sont presents.

Le resolver produit un `innerCorner*` uniquement si exactement une diagonale est absente et les trois autres diagonales sont presentes. Si plusieurs diagonales sont absentes, la cellule reste `cross`.

### Bords de carte

Les voisins hors carte ne matchent pas lors du calcul du masque. Cependant, apres la resolution de base, le resolver applique deux ajustements de bord:

1. Certains coins qui touchent exactement un bord de carte peuvent devenir des extremites.
2. Certains variants intermediaires (`horizontal`, `vertical`, `tee*`) sont promus en `cross` si la cellule touche un bord et que la connexion manquante pointe hors carte.

Ce comportement est special: le hors-carte est d'abord traite comme vide pour le masque, puis certains cas de bord sont remplis par une logique de correction.

### Hors grille

Une position de resolution hors grille jette `ValidationException`.

Les checks couvrent:

- `x < 0`;
- `y < 0`;
- `x >= width`;
- `y >= height`.

### Tailles invalides

Une taille de map avec largeur ou hauteur inferieure ou egale a zero jette `ValidationException`.

Une liste de cellules plus courte que `width * height` jette `ValidationException`.

Une liste plus longue que `width * height` est acceptee.

## 7. Points etranges ou fragiles observes

### La cellule courante n'est pas verifiee

`resolvePathVariantAt` et `resolveTerrainPathVariantAt` ne verifient pas que la cellule courante est active ou correspond au terrain demande. Ils resolvent uniquement depuis les voisins.

Ce n'est pas forcement un bug si les appelants garantissent de n'appeler le resolver que sur des cellules actives. Mais c'est une fragilite importante pour une future Surface Engine, qui devrait probablement expliciter ce contrat.

### Le centre d'un bloc plein est `cross`

Il n'existe pas de variant `center` ou `fill`. Un bloc plein 3x3 retourne `cross` au centre. C'est peut-etre suffisant pour le schema actuel, mais ce vocabulaire risque d'etre ambigu pour des surfaces comme l'eau, la lave ou les hautes herbes.

### Les noms `teeNorth`, `cornerNE`, etc. sont lies au masque

Les noms semblent correspondre aux directions connectees dans le masque, pas forcement a une convention visuelle universelle. Une migration vers des roles Surface devra eviter de supposer que ces noms sont les roles finaux du moteur.

### Les bords de carte appliquent des corrections non evidentes

Le resolver traite le hors-carte comme vide pour le masque, puis promeut certains variants en `cross` ou convertit certains coins en extremites.

Cette logique est importante a preserver pour compatibilite, mais elle devrait etre documentee comme une politique de bord, pas enfouie dans une resolution generale de surface.

### Les listes trop longues sont acceptees

La validation interdit les listes trop courtes, mais pas les listes trop longues. Les cellules supplementaires sont ignorees par l'indexation courante. C'est probablement une tolerance legacy, mais une future representation de grille devra choisir si elle preserve cette tolerance.

### Les diagonales ne servent que pour un cas tres strict

Les diagonales ne sont pas un systeme general de transition. Elles ne produisent un coin interieur que dans le cas "quatre cardinaux presents + exactement une diagonale absente". Cela ne couvre pas toutes les transitions de surfaces modernes.

## 8. Impact pour la future Surface Engine

Ces tests donnent un filet de securite pour remplacer ou adapter progressivement l'autotiling actuel.

Pour une future Surface Engine:

- `TerrainPathVariant` peut etre conserve comme schema legacy;
- un nouvel autotile resolver devra pouvoir reproduire ce comportement quand il lit des `PathLayer`/`ProjectPathPreset` existants;
- le comportement de bord devra devenir une politique explicite;
- les coins interieurs devront etre separes d'une notion plus generale de transition/role;
- le resolver devrait clarifier s'il attend que la cellule courante soit active;
- le modele Surface ne doit pas confondre `cross` avec un vrai centre/fill sans decision de migration;
- les surfaces modernes auront probablement besoin de roles plus precis que les 19 variants actuels.

Ce lot ne dit pas comment construire Surface Engine. Il dit seulement ce que le systeme actuel fait, pour eviter de casser les maps et previews existantes.

## 9. Commandes de test lancees

### Format

Commande initiale:

```bash
dart format packages/map_core/test/map_terrain_autotile_characterization_test.dart
```

Resultat:

```text
zsh:1: command not found: dart
```

Le binaire `dart` n'etait pas dans le `PATH` du shell. Le repo contient cependant un binaire disponible sous `/opt/homebrew/bin/dart`, utilise ensuite.

Commande utilisee:

```bash
/opt/homebrew/bin/dart format packages/map_core/test/map_terrain_autotile_characterization_test.dart
```

Resultat:

```text
Formatted packages/map_core/test/map_terrain_autotile_characterization_test.dart
Formatted 1 file (1 changed) in 0.01 seconds.
```

Une deuxieme passe apres correction de commentaire a retourne:

```text
Formatted 1 file (0 changed) in 0.01 seconds.
```

### Test cible, premier run

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/map_terrain_autotile_characterization_test.dart
```

Resultat initial:

```text
+13 -1: map_terrain_autotile characterization map edges and out-of-map neighbors single-edge corner replacements turn some corner variants into ends [E]
Expected: <6>
  Actual: <2>
Some tests failed.
```

Cause: erreur dans le fixture de test. Le commentaire disait que la cellule testee avait des voisins est/sud, mais le voisin sud etait place dans la mauvaise colonne. Le fixture a ete corrige sans modifier le code de production.

### Test cible, apres correction

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/map_terrain_autotile_characterization_test.dart
```

Resultat:

```text
+21: All tests passed!
```

### Test complet map_core

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```

Resultat:

```text
+151 -1: Some tests failed.
```

Echec:

```text
test/legacy_editor_json_compat_collision_test.dart:
legacy collision profile compat unknown legacy keys do not prevent manifest parsing [E]
type 'List<int>' is not a subtype of type 'Map<String, dynamic>' in type cast
package:map_core/src/models/element_collision_profile.g.dart 46:33
```

Cet echec est hors lot: le nouveau test d'autotile ne modifie pas les modeles de collision, les fichiers generated, ni le test legacy concerne.

## 10. Resultats des tests

Le test cible du lot passe:

```text
/opt/homebrew/bin/dart test test/map_terrain_autotile_characterization_test.dart
+21: All tests passed!
```

Le test complet `map_core` ne passe pas dans l'etat actuel du workspace:

```text
/opt/homebrew/bin/dart test
+151 -1: Some tests failed.
```

L'echec complet est documente ci-dessus et concerne un test de compatibilite JSON de collision existant.

## 11. Autocritique finale

Le lot reste volontairement conservateur: il ajoute des tests de caracterisation plutot qu'une correction de comportement. C'est exactement le bon niveau de risque pour preparer une migration Surface Engine.

Limites de cette passe:

- les tests ciblent surtout l'API publique path, avec des tests de parite terrain representatifs; ils ne testent pas toutes les combinaisons terrain possibles;
- les tests verrouillent le comportement actuel, meme quand il est discutable, comme la resolution d'une cellule inactive;
- le test complet `map_core` echoue sur une dette existante, ce qui limite la preuve globale de non-regression;
- aucune analyse de couverture n'a ete lancee;
- aucun test runtime/editor n'a ete lance, car le lot est strictement `map_core`.

Ces limites sont acceptables pour Lot 1. Les prochains lots devraient s'appuyer sur ce filet avant toute extraction ou adaptation.

## 12. Ce que le prompt semble discutable ou incomplet

### Le prompt parle de "terrain/path autotile", mais le coeur actuel est path-like

Le fichier `map_terrain_autotile.dart` partage une resolution commune entre path et terrain, mais le vocabulaire reste `TerrainPathVariant` et les fonctions internes s'appellent `_resolvePathVariantAt`. Les tests refletent cette realite.

### Le prompt mentionne une variante "centre"

Le cas "bloc plein 3x3" demande un attendu "variante centre". Or le modele actuel n'a pas de `center`. Le comportement actuel est `cross`. Le test documente donc le comportement reel, pas l'intention future.

### Les orientations des noms peuvent etre ambigues

Les noms comme `teeNorth` ou `cornerNE` peuvent etre lus comme des directions visuelles. Dans le code actuel, ils sont surtout issus de la table de masque cardinal. Les commentaires du test insistent sur ce point.

### Les cellules inactives sont hors contrat implicite

Le prompt demande de tester une cellule inactive. L'API le permet, mais les appelants normaux ne devraient probablement pas l'appeler sur une cellule inactive. Le test documente le comportement reel sans le presenter comme desirable.

### Le rapport final demande le contenu complet des fichiers

Cette exigence est utile pour revue, mais elle rend la reponse finale longue. Les chemins exacts sont tout de meme fournis et les contenus complets sont inclus dans la reponse finale comme demande.

## 13. Auto-review independante

### Est-ce que le lot est reste strictement limite aux tests de caracterisation?

Oui. Le lot ajoute un fichier de test et un rapport. Aucun modele Surface, moteur Surface, runtime, editeur ou gameplay n'a ete cree ou modifie.

### Est-ce qu'aucun comportement production n'a ete modifie?

Oui. Aucun fichier sous `packages/map_core/lib` n'a ete modifie.

### Est-ce que les cas obligatoires sont couverts?

Oui. Les cas obligatoires sont couverts:

- cellule isolee;
- ligne horizontale, centre et extremites;
- ligne verticale, centre et extremites;
- quatre coins;
- quatre tes;
- croix;
- bloc plein 3x3 centre, bord et coin;
- coins interieurs lies aux diagonales;
- bords de carte haut/bas/gauche/droite/corner;
- cellule inactive;
- coordonnees hors grille;
- tailles invalides et grille incomplete.

Le test ajoute aussi des caracterisations supplementaires utiles: table complete des masques, masques invalides, listes trop longues et parite terrain.

### Est-ce que les tests documentent le comportement actuel plutot qu'un comportement reve?

Oui. Les tests verrouillent notamment des comportements discutables mais actuels: centre de bloc plein en `cross`, cellule inactive resolue depuis ses voisins, edge fill en `cross`, listes trop longues acceptees.

### Est-ce que les commandes interdites Git n'ont pas ete utilisees?

Oui. Aucune commande Git d'ecriture n'a ete utilisee. Les commandes Git utilisees sont des commandes de lecture (`git status --short`, `git diff --stat`).

### Est-ce que le rapport est assez detaille?

Oui. Il liste les fichiers consultes, fichiers crees, fichiers modifies, cas testes, preuves, fragilites, impact Surface Engine, commandes, resultats, autocritique et points discutables.

### Est-ce que quelque chose du prompt etait ambigu ou discutable?

Oui. Les points principaux sont la mention d'une variante `centre` inexistante, l'ambiguite des noms directionnels, et le fait que le resolver accepte des cellules inactives meme si cet usage est probablement hors contrat implicite.
