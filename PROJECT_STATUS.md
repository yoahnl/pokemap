# Project Status (pokemonProject)

Last updated: 2026-03-21

## 1. Resume du projet
Editeur de maps Pokemon-like/RPG sur grille en monorepo Flutter/Dart avec separation `map_core` / `map_editor` / `map_runtime`.

Note importante: pour le moment, les tests ne sont pas une priorite. Ne pas ajouter de tests et ne pas investir de temps sur la couverture dans les taches courantes, sauf demande explicite.

## 2. Architecture actuelle
- `packages/map_core`: modeles metier, serialization JSON, validation, operations pures (resize, paint).
- `packages/map_editor`: UI Flutter Desktop, Riverpod, use cases applicatifs, persistence fichiers.
- `packages/map_runtime`: base runtime Flame encore minimale.
- Flux principal: UI -> `EditorNotifier` -> use cases -> repositories filesystem -> JSON.
- Les assets tilesets sont importes physiquement dans le projet (`assets/tilesets`) et references en chemin relatif dans le manifest.

## 3. Fonctionnalites faites
- Ouvrir un projet existant.
- Sauvegarder un projet.
- Gerer un manifest de projet.
- Creer / charger / sauvegarder une map.
- Gerer plusieurs maps dans un meme projet.
- Redimensionner une map (resize tile/collision + conservation des donnees + troncature).
- Renommer / supprimer / dupliquer une map (logique + UI).
- Parametres globaux projet (`tileWidth`, `tileHeight`, `displayScale`, `defaultMapWidth`, `defaultMapHeight`) avec persistance.
- Toolbar avec action `Project Settings` et action `Resize Map`.
- Import tileset (copie locale + manifest), scope global/groupe, ordre (`sortOrder`), assignation a une map.
- Rendu des TileLayers sur le canvas a partir du tileset actif.
- Palette tiles fonctionnelle (selection tile unitaire + peinture sur map).
- Mode creation d element de palette par selection rectangulaire dans le tileset (clic+drag).
- Creation d elements de palette nommes/categorises, persistes dans `project.json`.
- Palette d elements categorises (onglet Elements) avec preview visuel et selection de brush.
- Peinture multi-tile depuis un element de palette sur la layer tile active.
- Modularite core/editor/runtime maintenue.

## 4. Fonctionnalites partiellement faites
- Gestion multi-tilesets: base solide en place, UX de gestion encore basique.
- Categorie palette: structure persistante en place, edition UX encore simple.
- Selection rectangulaire: faite dans la grille du tileset, pas encore sur le canvas map.
- Sauvegarde avec etat dirty: fonctionne sur les flux principaux, a durcir sur tous les cas limites.
- Verification de coherence metier: utile mais encore partielle.
- Runtime Flame: squelette present, integration editor/runtime incomplete.
- Orientation Pokemon-like: base metier prete, outils de mapping avances encore manquants.
- Clean Architecture stricte: direction respecte, quelques simplifications existent dans le notifier/UI.

## 5. Fonctionnalites non faites
- Connexions entre maps.
- Edition complete des layers (ajouter/renommer/reordonner/masquer/supprimer).
- Outils avances (eraser, fill, selection map, copier-coller de zone, undo/redo).
- Collisions avancees (peinture/visualisation/types de sol).
- Entites gameplay (warps, triggers, PNJ, objets, panneaux, spawns) et leurs editeurs.
- Inspector de proprietes complet (map, projet, entites).
- Gestion assets projet plus large (hors tilesets).
- Preview in-game runtime.

## 6. Tache en cours
Terminee: elements de palette metier + selection rectangulaire tileset + palette categorisee + peinture multi-tile.

## 7. Dernieres modifications realisees
2026-03-21:
- `map_core`:
  - `TilesetPaletteEntry` enrichi avec `name`.
  - Ajout de `paintTilePatternOnLayer` pour peindre un motif multi-tile sur une TileLayer.
  - `paintTileOnLayer` s appuie desormais sur la logique pattern.
  - Validation palette renforcee (ID non vide + unicite deja en place).
- `map_editor`:
  - Nouveaux use cases:
    - creation d un element de palette nomme (`CreateTilesetPaletteEntryUseCase`),
    - peinture pattern multi-tile (`PaintTilePatternOnMapUseCase`).
  - Providers Riverpod ajoutes pour ces use cases.
  - `EditorNotifier` etendu:
    - gestion des entrees palette actives,
    - selection d un element comme brush,
    - creation d element depuis une zone source,
    - peinture du brush actif (tile unitaire ou element multi-tile).
  - `MapCanvas` branche sur la peinture du brush actif.
  - `TilesetPalettePanel` refondu:
    - onglets `Tiles` / `Elements`,
    - mode creation d element avec selection rectangle clic+drag,
    - dialog de creation (nom, categorie, layer recommandee),
    - liste d elements categorises avec previews.
- Codegen regenere (`freezed` / `json_serializable` / `riverpod_generator`).

## 8. Prochaines etapes recommandees
- Ajouter la suppression/edition/reordonancement des elements de palette.
- Ajouter une logique de layer recommandee plus exploitee dans l UX (proposition auto de layer cible).
- Ajouter des elements composites plus riches (meta supplementaires, variantes, contraintes de pose).
- Ameliorer l UX painting (preview ghost de la taille de l element sous la souris, feedback de clipping).
- Commencer les outils map manquants prioritaires (eraser, fill, selection/copy-paste).

## 9. Decisions d architecture importantes
- La peinture map reste dans le coeur metier (`map_core`) via operations pures reutilisables.
- Les traitements applicatifs restent dans les use cases (`map_editor/src/application/use_cases`).
- L UI ne persiste pas directement: elle passe par `EditorNotifier` puis use cases/repositories.
- Les elements de palette sont persistes au niveau `ProjectTilesetEntry.paletteEntries`.
- Un element de palette est defini par un rectangle source dans le tileset (`x`, `y`, `width`, `height`) + metadonnees (`id`, `name`, `category`, `recommendedLayerId`).
- Politique hors limites pour la pose multi-tile: clipping (on peint uniquement les cellules dans la map).

## 10. Points de vigilance / dette technique / bugs connus
- Le clipping hors limites est pratique mais silencieux: pas encore de feedback explicite quand une partie est coupee.
- Pas encore de suppression/renommage d element de palette cote UI.
- La validation metier ne couvre pas encore tous les cas de coherence possibles (ex: dependances futures entre palette/layers/metadonnees gameplay).
- Le rendu/peinture est fonctionnel mais sans optimisations de performance avancees.
- Les warnings analyse existants (deprecations Riverpod/Flutter FormField APIs) ne sont pas traites dans cette tache.

## Checklist fonctionnelle (etat)
- Ouvrir un projet existant: fait
- Sauvegarder un projet: fait
- Gerer un manifest de projet: fait
- Creer une map: fait
- Charger une map: fait
- Sauvegarder une map: fait
- Renommer une map: fait
- Supprimer une map: fait
- Dupliquer une map: fait
- Redimensionner une map: fait
- Gerer plusieurs maps dans un meme projet: fait
- Gerer les connexions entre maps: pas fait
- Afficher une grille editable: partiellement fait
- Se deplacer dans le canvas: fait
- Zoomer dans le canvas: fait
- Selectionner un outil: fait
- Selectionner une layer active: fait
- Ajouter/renommer/reordonner/masquer/supprimer des layers: pas fait
- Peindre des tiles: fait
- Effacer des tiles: pas fait
- Remplir une zone: pas fait
- Faire de la selection rectangulaire: partiellement fait
- Copier-coller une zone: pas fait
- Avoir une palette de tiles: fait
- Charger et afficher un vrai tileset: fait
- Gerer plusieurs tilesets: partiellement fait
- Associer un tileset a une map: fait
- Peindre les collisions: pas fait
- Visualiser les collisions: pas fait
- Gerer plusieurs types de collisions ou comportements de sol: pas fait
- Poser des warps: pas fait
- Configurer les warps: pas fait
- Poser des triggers: pas fait
- Configurer les triggers: pas fait
- Poser des PNJ: pas fait
- Poser des objets ramassables: pas fait
- Poser des panneaux: pas fait
- Poser des points de spawn: pas fait
- Editer les proprietes des entites: pas fait
- Editer les proprietes des maps: pas fait
- Editer les proprietes globales du projet: partiellement fait
- Avoir un inspector de proprietes: pas fait
- Avoir un explorateur de projet: fait
- Avoir une toolbar claire: fait
- Avoir une barre de statut: fait
- Supporter l undo/redo: pas fait
- Avoir une sauvegarde propre avec etat dirty: partiellement fait
- Pouvoir previsualiser le rendu in-game: pas fait
- Preparer un runtime compatible Flame: partiellement fait
- Avoir un format JSON propre et stable: fait
- Valider les donnees metier: fait
- Verifier les erreurs de coherence: partiellement fait
- Gerer les assets du projet: partiellement fait
- Pouvoir editer progressivement routes/villes/interieurs/donjons: partiellement fait
- Etre pense specifiquement pour un jeu de type Pokemon sur grille: partiellement fait
- Rester coherent avec une Clean Architecture stricte: partiellement fait
- Rester modulaire entre core, editor et runtime: fait
