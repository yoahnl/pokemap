# Densité des variantes Smart Tile — design

**Date :** 2026-08-07
**Statut :** validé, prêt pour un plan d'implémentation

## Problème

Un Wang Set importé depuis Tiled compile tous ses candidats au même poids. `compileTiledWangImport`
calcule `weight = max(1, (probability ?? 1) * 1000)`, et les planches ERW « Grass Land » ne
déclarent aucune probabilité par tuile — la seule occurrence de l'attribut porte sur la couleur du
Wang Set (`<wangcolor … probability="1"/>`). Tous les candidats sortent donc à `1000`.

Conséquence mesurée sur `water to grass-godot (river orientation)` : la règle de remplissage
« quatre coins en eau » compte 11 candidats, dont 5 d'eau nue et 6 portant un rocher. Le tirage
étant uniforme, **environ 55 % des tuiles d'eau ouverte reçoivent un caillou**. La nappe est
inutilisable telle quelle.

Le poids est déjà éditable par candidat, mais uniquement dans l'étape « Formes » de l'assistant de
brouillon. Un preset importé s'ouvre dans l'établi du Studio, dont l'onglet Règles est en lecture
seule. Aucun chemin ne mène donc d'un preset publié à ses poids.

## Décisions

| Question | Décision |
|---|---|
| Granularité | Un curseur par variante, gradué en fréquence réelle |
| Redistribution | Les autres variantes se repartagent le reste en conservant leurs rapports |
| Écriture | Aperçu local, puis bouton « Appliquer » — une transaction, un reçu, une annulation |
| Portée | Défaut sur le preset **et** surcharge par calque, avec sélecteur |
| Emplacement | Panneau « Peindre » de World Map, section repliée par défaut |

L'emplacement découle d'un constat d'usage : une densité de décor ne se juge pas sur la grille du
banc d'essai, mais sur la surface réelle à l'échelle où on la regarde.

## Modèle de données

Le preset ne change pas. `SmartTileCandidate.weight` reste la valeur par défaut, écrite à l'import
et éditable. C'est la référence quand un calque ne dit rien.

`SmartTileLayer` gagne un champ :

```dart
@Default(<String, int>{}) Map<String, int> candidateWeights,
```

La clé est l'identifiant du candidat. Aucune imbrication par règle : les identifiants compilés sont
déjà uniques dans le preset (`…-w0-rule-7-candidate-3`).

Sémantique :

- clé absente → poids du preset ;
- clé présente → elle gagne, y compris à `0` ;
- table vide → le calque suit intégralement le preset.

C'est ce dernier cas que désérialisent tous les calques existants. Aucune migration : le champ a un
défaut et `map_layer.dart` n'active pas `disallowUnrecognizedKeys`.

**Clés orphelines.** Si la planche source est réimportée, les identifiants changent et les
surcharges pointent dans le vide. Le résolveur ignore silencieusement une clé inconnue ; la
validation émet un **avertissement** listant les clés mortes du calque. Une carte reste ouvrable.

**Bruit de sérialisation.** `json_serializable` écrit les valeurs par défaut. À vérifier à
l'implémentation : si chaque calque Smart Tile gagne un `"candidateWeights":{}` inutile, omettre la
clé quand la table est vide.

## Résolveur

L'injection se fait à la préparation, pas dans la boucle de cellules.

`PreparedSmartTileResolver` existe pour ne faire qu'une fois le travail stable par preset.
`_PreparedSmartTileRule` filtre déjà les candidats à `weight > 0` et somme `totalWeight` à la
construction. La fabrique reçoit un paramètre optionnel `candidateWeights` et chaque candidat en
sort avec son poids effectif, avant le filtre et avant la somme.

La boucle chaude ne bouge pas : `_resolvePreparedCandidate` continue de tirer `hash % totalWeight`
sur une liste déjà filtrée. Le coût est une lecture de table par candidat, une fois par calque rendu.

`resolveSmartTile`, point d'entrée de compatibilité, reçoit le même paramètre avec `const {}` par
défaut. Quatre appelants existent ; seul `smart_tile_layer_visual_resolver.dart` a un calque sous la
main et doit le passer. La reconstruction, le banc d'essai et les fonds de cinématique restent au
défaut.

**Cas dégénéré.** Si tous les candidats d'une règle tombent à 0, la liste préparée est vide et le
résolveur renvoie déjà `noCandidate` avec un message, sans division par zéro. Ce n'est pas un
plantage, mais c'est un mauvais état : il est interdit à l'écriture (voir plus bas), pas rattrapé ici.

**Effet de bord assumé.** Le ticket est tiré contre la liste triée et le poids total. Changer un
poids redistribue le tirage sur toutes les cellules de la règle, pas seulement celles qui portaient
un décor : la surface se remélange à chaque ajustement. C'est inhérent au tirage pondéré.
`layerSeed` reste le bouton pour obtenir un autre tirage à densité égale.

## Interface

La section vit dans le panneau « Peindre » de World Map
(`world_map_smart_tile_paint_palette.dart`, 566 lignes), insérée entre `Matière à peindre` et
`Motifs réutilisables`. Elle est **repliée par défaut** : le panneau garde sa longueur actuelle, et
la ligne repliée affiche le nombre de variantes et, le cas échéant, combien s'écartent du preset.

Dépliée, elle contient :

- le sélecteur de portée **ce calque / tous les calques** ;
- une ligne par variante : vignette du sprite, `PokeMapGuidedSlider`, part en pourcentage à une
  décimale ;
- un curseur à zéro affiche **« jamais »** plutôt que `0 %` ;
- les boutons **Réinitialiser** et **Appliquer**.

Le composant `PokeMapGuidedSlider` existe déjà et convient tel quel : valeur entière, `min`/`max`,
libellé, description, `onChanged` / `onChangeStart` / `onChangeEnd`.

**Normalisation.** Les poids d'une règle sont renormalisés pour sommer exactement à `1000` après
chaque ajustement, par arrondi au plus fort reste. Cela donne une résolution de 0,1 % et maintient
chaque poids dans la bande `1..1000` qu'accepte le champ existant de l'étape Formes. Deux règles
d'arrondi :

- un candidat que l'auteur a posé à `0` reste à exactement `0` et sort de la redistribution ;
- un candidat dont la part arrondirait à `0` sans avoir été posé à `0` est plancherisé à `1`, pour
  que « rare » ne devienne jamais « jamais » par accident ;
- conséquence arithmétique du plancher : la cible demandée est **bornée** à `1000 − N` où `N` est
  le nombre d'autres variantes positives — demander 99 % avec quarante variantes vivantes pose
  96 %, et le curseur retombe sur la valeur réellement posée ; la seule variante positive d'une
  règle reste à `1000`, il n'y a rien pour compenser une baisse.

Les presets importés arrivent avec tous leurs candidats à `1000`, soit un total de `11000` pour une
règle à 11 variantes. Le premier « Appliquer » les renormalise à un total de `1000`. La distribution
relative est préservée, donc les proportions ne changent pas — mais `totalWeight` change, et le
tirage étant `hash % totalWeight`, **la surface se remélange dès le premier enregistrement, même
sans avoir bougé un curseur**. À dire dans l'interface plutôt qu'à laisser découvrir.

**Lecture selon la portée.** Les curseurs affichent toujours les poids de la source sélectionnée :
sur « ce calque », la table du calque complétée par les défauts du preset ; sur « tous les calques »,
les poids du preset seuls. Changer de portée recharge les curseurs depuis l'autre source. Une
surcharge de calque continue de l'emporter sur le défaut du preset pour ce calque : éditer « tous
les calques » ne rend pas ses surcharges à un calque qui en a.

Le Studio n'est pas touché. L'onglet Règles reste en lecture seule, et le sélecteur de portée couvre
déjà le cas « défaut du preset ». `smart_tiles_studio_panel.dart`, gelé à 4412 lignes dans
`tools/file_length_baseline.txt`, ne bouge pas.

## Écriture canonique

Deux portées, deux chemins.

**« tous les calques »** écrit les poids du preset via `smart_tile.preset.publish` avec la charge
`preset`, qui remplace le preset et force son statut à publié. L'action existe. Il manque une
méthode sur `SmartTilePublicationService`, qui ne câble aujourd'hui que la forme `draftId`.

**« ce calque »** n'a aucun chemin : les actions Smart Tile de calque se limitent à `create`,
`delete`, `merge`, `normalize` et `reconstruct`. Il faut une action canonique nouvelle,
`smart_tile.layer.set_candidate_weights`, dans `smart_tile_layer_actions.dart`. Paramètres :
`mapId`, `layerId`, et la table complète des poids — un remplacement, pas un correctif, pour rester
idempotent et annulable d'un bloc.

Trois refus, portés par l'action plutôt que par l'interface :

| Code | Condition |
|---|---|
| `weight_invalid` | un poids négatif |
| `candidate_unknown` | un identifiant absent du preset du calque |
| `rule_without_candidate` | une table qui viderait une règle de tout candidat positif |

Le registre de parité route déjà le préfixe `smart_tile.layer.` vers
`test/domains/maps/smart_tile_layer_actions_test.dart`. La nouvelle action hérite de l'exigence de
couverture sans modifier `full_authoring_parity.dart`.

## Tests

La redistribution est la seule vraie logique ; le reste est du câblage. Elle est testée seule, hors
widget : à partir de N poids et d'une part cible pour l'un d'eux, produire N entiers sommant à
`1000`, conservant les rapports des autres, et respectant les deux règles d'arrondi ci-dessus.

Autour :

- **map_core** — le résolveur applique la surcharge à la préparation et recalcule `totalWeight` ;
  un poids `0` exclut le candidat ; une clé inconnue est ignorée ; **une table vide reproduit
  exactement le comportement actuel** (garde-fou de non-régression) ;
- **map_core** — aller-retour de sérialisation, et relecture d'une carte écrite sans le champ ;
- **map_authoring** — la nouvelle action : cas nominal, les trois refus, rejeu à l'identique,
  annulation ;
- **map_editor** — la section est repliée par défaut, affiche « jamais » à zéro, un clic sur
  Appliquer produit exactement un appel, Réinitialiser restaure l'état d'ouverture.

## Lots

| Lot | Contenu | Ce que ça débloque |
|---|---|---|
| 1 | Section repliée dans le panneau Peindre, portée « tous les calques » seule, méthode `preset` sur `SmartTilePublicationService`, calcul de redistribution et ses tests | La densité est réglable sans toucher au modèle de données |
| 2 | Champ `candidateWeights` sur `SmartTileLayer`, passage dans le résolveur, action `smart_tile.layer.set_candidate_weights`, sélecteur de portée, avertissement de validation sur les clés orphelines | La surcharge par calque |

Le lot 1 résout le problème d'origine seul. Le lot 2 ajoute la granularité par calque.

## Hors périmètre

- Marquer une variante comme « décoration » dans le modèle canonique. Les données ne portent pas
  cette notion, et l'écarter est ce qui a fait choisir un curseur par variante.
- Régler la densité depuis le Studio. La portée « tous les calques » du panneau Peindre couvre le
  besoin ; y revenir plus tard reste possible sans rien défaire.
- Renommer les matériaux importés. Les Wang Sets ERW arrivent avec une couleur sans nom, affichée
  « Matériau 1 ». Gênant, mais indépendant.
- Rejouer un tirage à densité constante. `layerSeed` existe et n'est pas exposé ; c'est un sujet
  distinct.
