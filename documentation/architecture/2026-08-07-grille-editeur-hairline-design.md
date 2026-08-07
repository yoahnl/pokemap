# Grille de l'éditeur : un vrai hairline — design

**Date :** 2026-08-07
**Statut :** validé, prêt pour un plan d'implémentation

## Problème

La grille de World Map se lit comme un voile épais posé sur la carte. Elle reste utile — elle
matérialise les cellules — mais elle domine l'aperçu visuel au point de le fausser.

Elle est dessinée dans `MapGridPainter`, à
`packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:681` :

```dart
final gridPaint = Paint()
  ..color = PokeMapLegacyColors.white10   // 0x1AFFFFFF
  ..strokeWidth = 1.0 / zoom
  ..style = PaintingStyle.stroke;
```

Le tracé se fait dans le canvas déjà mis à l'échelle (`canvas.translate(offset); canvas.scale(zoom)`
à la ligne 488). Le `1.0 / zoom` compense correctement cette échelle : le trait mesure bien **1
pixel logique** à l'écran, quel que soit le zoom. Ce n'est donc pas une erreur d'échelle.

Le défaut est ailleurs, et il tient à deux faits qui se combinent :

1. **Les positions sont fractionnaires.** Une tuile occupe `settings.tileWidth *
   settings.displayScale * zoom` pixels logiques. À 42 % de zoom, cela donne ≈ 17,5 px — jamais un
   compte rond. Les lignes ne tombent donc pratiquement jamais sur une frontière de pixel.
2. **L'anti-aliasing est actif** (défaut de `Paint`). Un trait de 1 px logique centré sur une
   coordonnée fractionnaire est réparti par l'anti-aliasing sur **deux colonnes de pixels
   physiques**, chacune à couverture partielle. Sur un écran Retina (`devicePixelRatio` = 2), ce
   même trait couvre déjà 2 pixels physiques avant même l'étalement.

Le résultat n'est pas un filet mais un **bandeau flou de 2 à 3 pixels physiques**. Un trait flou se
lit systématiquement plus épais et plus sale qu'un trait franc, même à contraste égal — c'est cette
perception que décrit la gêne.

Accessoirement, aucun réglage n'existe : `showGrid` provient d'un `bool.fromEnvironment`
(`map_canvas.dart:87`) destiné aux captures Marionette, pas d'une préférence utilisateur. Il n'y a
ni bouton ni opacité. Ce point est constaté, pas traité ici.

## Décisions

| Question | Décision |
|---|---|
| Nature du trait | `strokeWidth = 0` → hairline, soit exactement 1 pixel physique |
| Anti-aliasing | Désactivé (`isAntiAlias = false`) |
| Compensation de zoom | Supprimée — un hairline est par définition invariant à la transformation |
| Couleur | Inchangée (`white10`, `0x1AFFFFFF`) |
| Surface UI | Aucune |

Le choix du hairline plutôt qu'un tracé en espace écran vient de sa taille : deux lignes contre une
quarantaine, pour le même résultat visuel dans le cas nominal. Le tracé en espace écran reste
documenté en repli (voir *Risques*).

Ne pas toucher à la couleur est délibéré. Un trait franc à 10 % de blanc sera déjà nettement plus
discret que le bandeau flou actuel : changer les deux paramètres en même temps rendrait impossible
de juger lequel a produit l'effet.

## Le correctif

```dart
final gridPaint = Paint()
  ..color = PokeMapLegacyColors.white10
  ..strokeWidth = 0        // hairline : 1 pixel physique, quelle que soit la matrice
  ..isAntiAlias = false    // le trait tombe sur un pixel net, sans étalement
  ..style = PaintingStyle.stroke;
```

Les deux boucles de `drawLine` (lignes 687 à 702) ne changent pas. Le compteur
`cullingCounter?.gridLineVisits` ne change pas.

`strokeWidth = 0` n'est pas un trait de largeur nulle : dans Skia comme dans Impeller, zéro est la
convention qui demande un *hairline* — la primitive rastérise une ligne d'un pixel de large dans
l'espace du périphérique, en ignorant l'échelle du canvas. C'est exactement la propriété qui rend le
`/ zoom` inutile.

## Ce que ça change à l'écran

| `devicePixelRatio` | Aujourd'hui | Après |
|---|---|---|
| 2 (Retina) | 2 à 3 px physiques à couverture partielle | 1 px physique à `alpha` plein |
| 1 | 1 à 2 px physiques à couverture partielle | 1 px physique à `alpha` plein |

Sur Retina, l'empreinte du trait est donc divisée par deux et le flou disparaît. Sur un écran non
Retina, la largeur ne bouge quasiment pas : le gain se limite à la netteté et à la fin du
chevauchement sur deux colonnes. C'est le cas de figure où l'amélioration sera la moins spectaculaire
— autant le dire d'avance.

**Contrepartie assumée.** Un hairline s'aligne sur la grille de pixels physiques, pas sur les
coordonnées du monde. En panoramique ou en zoom continu, une ligne pourra donc se décaler d'un pixel
au passage d'un seuil. C'est le comportement standard des éditeurs de tuiles et le prix normal de la
netteté ; l'alternative (positions exactes) est précisément ce qui produit le flou actuel.

## Risques

**1. Le rendu Impeller des hairlines — le seul point que les tests ne prouvent pas.**
`flutter_test` rastérise par son propre chemin ; un test vert ne garantit donc pas le rendu obtenu
par l'application réelle sur macOS. Si Impeller rend les hairlines absents ou irréguliers, le repli
est le tracé en espace écran : sortir la grille du canvas mis à l'échelle (après le `canvas.restore()`
de la ligne 759), calculer les positions en pixels logiques (`offset.dx + x * tileWidth * zoom`),
arrondir chaque position au pixel physique (`(v * dpr).round() / dpr`), `strokeWidth = 1 / dpr`,
anti-aliasing désactivé. Le `devicePixelRatio` arriverait par
`MediaQuery.devicePixelRatioOf(context)`, passé au painter et ajouté à `shouldRepaint`. Ce repli est
hors périmètre de ce lot ; il est décrit ici pour ne pas avoir à le retrouver.

**2. Un test existant peut rougir sans que le correctif soit faux.**
`can hide the editor grid for clean visual QA captures`
(`packages/map_editor/test/map_grid_painter_test.dart:202`) lit l'alpha d'**un pixel codé en dur**,
la colonne 32 (`map_grid_painter_test.dart:231`). Aujourd'hui, le trait anti-aliasé de 1 px centré
sur `x = 32` teinte les colonnes 31 **et** 32, donc l'assertion passe. Un hairline ne tombe que sur
**une** des deux, et laquelle relève du moteur. Le test doit donc être assoupli pour balayer le
voisinage de la frontière au lieu d'interroger une colonne fixe. C'est une correction de test, pas
une régression produit — mais elle doit être faite en connaissance de cause, pas en ajustant le
nombre jusqu'à ce que ça passe.

**3. Le cliquet de longueur de fichier.**
`map_grid_painter_test.dart:1076` contraint la taille de
`lib/src/ui/canvas/map_canvas/map_grid_painter.dart`. Le correctif ajoute une ligne nette : à
vérifier, et à ne pas contourner en compactant le tracé.

## Vérification

- **Nouveau test — l'anti-aliasing est bien éteint.** À `zoom: 1`, `tileWidth: 32`, sur le modèle du
  helper `alphaAtGridLine` existant : balayer les colonnes autour d'une frontière de tuile et
  vérifier qu'**exactement une** est teintée, que son alpha vaut `26` (`0x1A` non dilué — la preuve
  que rien n'a été étalé), et que ses voisines valent `0`. Avant le correctif, deux colonnes portent
  chacune un alpha partiel : le test échoue, ce qui en fait un vrai garde-fou.
- **Test existant adapté** selon le risque 2.
- **Contrôle visuel obligatoire** dans l'application, pas seulement en test : ouvrir *Village
  d'Hanazuki*, capturer à 42 % puis à 100 %, comparer à l'état actuel. C'est la seule preuve pour le
  risque 1.
- `dart analyze` propre, et les suites `map_grid_painter_test.dart` et
  `map_grid_painter_layer_order_test.dart` vertes.

## Hors périmètre

- **Le contraste.** Si, une fois le trait net, 10 % de blanc reste trop présent, le réglage suivant
  est l'alpha (6 à 8 %) ou une encre sombre (`0x14000000`), qui se lit comme un joint entre tuiles
  plutôt que comme un voile clair. Cela exige d'introduire un token `gridLine` dédié dans
  `editor_paint_palette.dart` : `white10` est partagé avec trois autres écrans et ne peut pas être
  réglé sans effets de bord.
- **Le contrôle utilisateur.** Transformer `showGrid` en état éditeur : bouton dans la barre
  d'outils, raccourci clavier, crans d'intensité, persistance, le `bool.fromEnvironment` restant en
  surcharge pour Marionette. Le panneau cinématique a déjà un précédent de bouton « Masquer la
  grille » (`cinematic_map_backdrop_preview_panel.dart:1343`).
- **Le tracé en espace écran**, décrit au risque 1, tant que le hairline suffit.
