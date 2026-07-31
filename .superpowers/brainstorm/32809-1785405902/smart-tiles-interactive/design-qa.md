# Design QA — Smart Tiles Studio interactif

## Références comparées

- Maquette Figma : `PokeMap — Smart Tiles Studio simplifié`
- Cible visuelle : interface desktop PokeMap sombre, panneaux bleu nuit, accent vert pour la validation et bleu pour l’action.
- Prototype : parcours local en cinq étapes utilisant les véritables images ERW.
- Viewport de contrôle : `1280 × 720`.

## Comparaisons obligatoires

### Structure et hiérarchie

- Barre supérieure, navigation latérale, progression, contenu principal et états contextuels correspondent à la maquette.
- Le parcours commence par les quatre usages réellement prévus dans PokeMap : `Path`, `Terrain`, `Environment Studio` et `Border Studio`.
- Une étape distincte demande ensuite de choisir un guide classique en comparant uniquement la disposition des cellules.
- Le choix de l’usage et celui du format de raccord ne sont plus mélangés.
- Les cinq étapes conservent un titre, une explication, un contrôle principal et une action suivante claire.

Verdict : conforme.

### Palette, typographie et densité

- Palette bleu nuit, bordures froides, validation verte et action bleue conservées.
- Inter est utilisé avec une hiérarchie cohérente entre titres, explications, métadonnées et aides.
- La densité visuelle reste proche de l’éditeur existant sans reprendre son inspecteur technique illisible.

Verdict : conforme.

### Images et assets

- L’atlas ERW réel est affiché à l’étape Placement.
- Le guide ERW 16 reprend sa disposition irrégulière et sa numérotation de 1 à 16.
- La véritable preview de test du chemin est utilisée dans le banc d’essai et la publication.
- Le pixel art conserve un rendu net grâce à `image-rendering: pixelated`.

Verdict : conforme.

### Interactions et états

- Les quatre usages PokeMap sont sélectionnables et le bouton de continuation reprend le choix en langage naturel.
- Chaque usage possède un catalogue adapté de quatre guides, dont un guide personnalisé.
- Le guide ERW 16, le guide Edge 16 et le Blob 47 sont comparables visuellement avant le placement.
- La grille de contrôle peut être affichée ou masquée.
- Les réglages avancés de grille sont repliés par défaut.
- L’utilisateur indique uniquement la cellule numéro 1 du guide dans l’atlas.
- Le guide complet est superposé sur l’image et toutes les cellules sont calculées relativement à ce repère.
- L’action de test reste désactivée tant que le guide n’est pas placé.
- Les formes de test sont sélectionnables et l’état actif est visible.
- La publication affiche un résumé final et l’action `Utiliser dans une map` produit une confirmation.
- Les retours vers les étapes précédentes sont disponibles sans navigation externe.

Verdict : conforme.

### Accessibilité et résilience

- Les contrôles utilisent des boutons, cases à cocher, titres et libellés sémantiques.
- Les états sélectionnés ne reposent pas uniquement sur la couleur.
- Le focus clavier est visible.
- Sous `1280 × 720`, les étapes les plus denses utilisent le défilement interne de l’espace de travail sans faire bouger le chrome global.

Verdict : conforme.

## Défauts trouvés et corrections

| Priorité | Défaut | Correction | État |
|---|---|---|---|
| P1 | Le défilement de l’étape Image était conservé à l’ouverture des étapes suivantes. | Réinitialisation du défilement à chaque changement d’étape et verrouillage du chrome global. | Corrigé |
| P2 | Le grand atlas pouvait faire défiler toute la fenêtre au lieu du seul espace de travail. | Cadre applicatif fixé à la hauteur du viewport, défilement limité au workspace. | Corrigé |
| P1 | L’ancienne analyse pouvait laisser croire qu’un atlas arbitraire serait compris automatiquement. | Suppression complète de cette analyse au profit d’un guide choisi explicitement et d’un placement déterministe. | Corrigé |
| P1 | Le premier écran mélangeait usages, formats Wang et modes d’assistance. | Réduction aux quatre usages PokeMap, suivie d’une étape Guide séparée. | Corrigé |
| P1 | Les premiers schémas illustraient le résultat dans la map mais pas la disposition attendue dans l’atlas. | Création d’un catalogue de guides numérotés, dont la disposition ERW 16 fournie par l’auteur. | Corrigé |
| P3 | Les actions finales peuvent nécessiter un léger défilement vertical sur un écran de seulement 720 px de haut. | Comportement accepté : action accessible dans le même panneau, sans perte de contexte. | Suivi optionnel |

## Vérification fonctionnelle

- Affichage et sélection des quatre usages PokeMap à `1280 × 720` : passés.
- Progression `Path` vers le catalogue des guides : passée.
- Affichage simultané des guides ERW 16, Edge 16, Blob 47 et personnalisé : passé.
- Sélection de `Terrain` et ouverture du catalogue Terrain avec Blob 47 recommandé : passées.
- Ouverture des réglages de grille : passée.
- Masquage de la grille : passé.
- Action de test désactivée avant le placement du guide : passée.
- Placement du guide ERW 16 depuis un unique repère : passé.
- Superposition visuelle du guide complet et affichage des 16 cellules associées : passés.
- Passage direct du guide ERW 16 au banc d’essai : passé.
- Changement de forme dans le banc d’essai : passé.
- Publication et confirmation d’utilisation : passées.
- Console navigateur : aucune erreur ou alerte.

## Limite volontaire du prototype

Le prototype valide le parcours d’auteur et ses états interactifs. Il ne contient pas encore le modèle Wang de production ni l’extraction réelle des pixels : le guide, ses positions relatives et la superposition sont représentés dans l’interface pour valider l’ergonomie avant l’intégration dans les packages PokeMap.

## Résultat final

`final result: passed`
