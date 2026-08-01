# PERF-RM-02 — Plan d'implémentation occlusion runtime

**Scope :** déplacer la préparation immuable hors de `render` et culler les patches hors caméra. Aucun changement de masque, rotation, profondeur ou collision gameplay.

## Audit initial

- Le composant décode déjà le masque et calcule `_drawRuns` une fois, mais `render` reconstruit encore transform, prédicat et `Path` via `drawQuarterTurnPixels` à chaque frame.
- `PlayableMapGame` instancie chaque patch et possède `camera.visibleWorldRect`.
- Les tests couvrent rotations 0–3, masques asymétriques, opacité, translation et goldens d'ordre de profondeur.
- La recherche Flame configurée n'a retourné aucune documentation exploitable ; l'implémentation reste sur Flame 1.37.0 et les patterns du dépôt.

## Étapes test-first

- [ ] Étendre `quarter_turn_pixel_renderer_test.dart` avec un plan immuable préparé une fois et dessiné plusieurs fois sans nouvelle préparation.
- [ ] Étendre `placed_element_occlusion_patch_component_test.dart` : deux renders réutilisent le plan ; patch hors viewport produit zéro draw ; intersection bord/halo reste visible.
- [ ] Exécuter les tests et conserver RED sur les compteurs/API absents.
- [ ] Ajouter dans le renderer un plan local immuable qui enregistre une fois les commandes pixel exactes et conserve le résultat de préparation ; lifecycle explicite de sa `Picture`.
- [ ] Remplacer le rééchantillonnage du composant par le dessin du plan ; conserver les compteurs de diagnostic et les sorties pixel exactes.
- [ ] Injecter un provider de visible-world-rect ; `PlayableMapGame` fournit `camera.visibleWorldRect`. Le rectangle monde du composant inclut sa taille transformée et un halo d'un pixel monde.
- [ ] Disposer le plan lors du retrait du composant sans disposer le tileset partagé.
- [ ] Relancer rotations, masques vide/invalide, opacity, goldens, smoke runtime et analyseur.

## Non-objectifs et risques

- Pas de cache global de `Picture`, pas de désactivation de l'occlusion, pas de modification de `map_core`.
- Le culling doit utiliser la position courante après translation d'origine, pas les coordonnées initiales de l'instruction.
- La ressource enregistrée ne doit pas survivre au composant.

## Preuves attendues

- Préparation exactement une fois, plusieurs renders ; zéro dessin hors viewport.
- Pixels/rotations et ordre acteur-toit identiques.
- Profil Selbrume trois runs seulement si le runner profile contractuel est disponible ; sinon gate explicitement non prouvée.

