# Project Status (pokemonProject)

Last updated: 2026-03-21

## 1. Resume du projet
Editeur de maps sur grille pour un RPG/Pokemon-like, base sur Flutter/Dart, organise en monorepo avec un `core` (modele + validation), un `editor` (UI + workflows) et un `runtime` (execution/preview in-game).

Note importante: pour le moment, les tests ne sont pas une priorite. Ne pas en ajouter / ne pas etendre la couverture dans les taches courantes, sauf demande explicite.

## 2. Architecture actuelle
- `packages/map_core`: modeles (Freezed/JSON), exceptions, validation minimale, logique metier pure reutilisable.
- `packages/map_editor`: application Flutter Desktop (Riverpod), use cases applicatifs, repositories fichiers, UI (toolbar, explorer, canvas).
- `packages/map_runtime`: runtime Flame (structure en place, rendu/chargement encore minimal).
- `ProjectFileSystem` gere maintenant aussi l'import physique d'assets tilesets (`assets/tilesets`) avec chemins relatifs persistes.

Flux typique (editor):
- UI -> `EditorNotifier` (Riverpod) -> `*UseCase` -> `Repository` (filesystem) -> JSON.

## 3. Fonctionnalites faites
- Ouvrir un projet existant
- Sauvegarder un projet
- Gerer un manifest de projet
- Creer une map
- Charger une map
- Sauvegarder une map
- Gerer plusieurs maps dans un meme projet
- Se deplacer dans le canvas
- Zoomer dans le canvas
- Selectionner un outil
- Selectionner une layer active (basique)
- Avoir un explorateur de projet
- Avoir une toolbar claire
- Avoir une barre de statut
- Avoir un format JSON propre et stable
- Valider les donnees metier (validation minimale)
- Rester modulaire entre core, editor et runtime
- Redimensionner une map (tile/collision layers + size) (fait le 2026-03-21)
- Parametres globaux de projet (tile size/scale + taille map par defaut) + UI d'edition (fait le 2026-03-21)
- Gestion tilesets projet (import/copie + scope global/groupe + ordre + assignation map) (fait le 2026-03-21)
- Afficher un panneau palette/tileset a droite avec tileset actif de la map (fait le 2026-03-21)
- Rendu des TileLayer sur le canvas a partir du tileset actif (fait le 2026-03-21)
- Selection d'un tile dans la palette + peinture unitaire sur TileLayer active (fait le 2026-03-21)

## 4. Fonctionnalites partiellement faites
- Renommer une map: fait cote logique et UI, verification fonctionnelle a faire
- Supprimer une map: fait cote logique et UI, verification fonctionnelle a faire
- Dupliquer une map: fait cote logique et UI, verification fonctionnelle a faire
- Afficher une grille editable (affichage + hover, pas d'edition)
- Gerer plusieurs tilesets (import/organisation/manifest + rendu/palette de base)
- Associer un tileset a une map (selection UI + persistance ok, controle d'eligibilite global/groupe/parents)
- Categorie de palette pour tileset (base persistante + filtrage + edition unitaire)
- Support multi-tile dans le modele palette (rect source), edition/painting multi-tile non encore implemente
- Avoir une sauvegarde propre avec etat dirty (isDirty present, workflow a durcir)
- Verifier les erreurs de coherence (validation tres partielle)
- Preparer un runtime compatible Flame (squelette present)
- Pouvoir editer progressivement routes/villes/interieurs/donjons (base de structure)
- Pense specifique Pokemon sur grille (base de modele + direction)
- Coherence Clean Architecture stricte (globalement visee, mais pas totalement appliquee partout)

## 5. Fonctionnalites non faites
- Gerer les connexions entre maps
- Ajouter/renommer/reordonner/masquer/supprimer des layers
- Effacer/remplir des tiles
- Selection rectangulaire + copier-coller
- Palette avancee (selection rectangulaire, outils avances)
- Peindre/visualiser collisions + types de collisions/sol
- Warps/triggers/npc/objets/panneaux/spawn (pose + config)
- Inspector de proprietes
- Editer proprietes des maps / globales du projet / entites
- Undo/redo
- Previsualiser le rendu in-game (runtime preview)
- Gerer les assets du projet

## 6. Tache en cours
Aucune (derniere tache livree: workflow palette -> selection -> paint tile).

## 7. Dernieres modifications realisees
2026-03-21:
- Ajout d'une logique metier de resize dans `map_core` (`resizeMapData`) pour redimensionner les layers tile/collision en preservant les donnees.
- Ajout d'un `ResizeMapUseCase` dans `map_editor` et d'une action UI "Resize Map" dans la toolbar (dialog width/height + validation).
- Ajout d'un repaint explicite du canvas quand la map change (important pour le resize).
- Creation de ce fichier `PROJECT_STATUS.md` pour le suivi persistant.
- Ajout d'une configuration globale `ProjectSettings` dans le manifest (tileWidth, tileHeight, displayScale, defaultMapWidth/Height).
- Ajout d'un dialog "Project Settings" pour editer le nom du projet + settings et persister dans `project.json`.
- Le canvas et la creation de map utilisent maintenant les settings globaux (fin du `32` en dur).
- Evolution du modele `ProjectTilesetEntry` avec `scope`, `groupId`, `sortOrder`, `isWorldTileset`.
- Ajout de validations tilesets (unicite IDs, coherence scope/group, chemin relatif, unicite du world tileset).
- Ajout de use cases tilesets: import, update scope/metadata, reorder, suppression protegee, assignation tileset a la map active.
- UI: import de tileset depuis disque, section tilesets structuree (globaux + par groupe), actions de gestion, selector de tileset pour map active.
- Ajout d'un modele palette persistant dans le manifest (`TilesetPaletteEntry`, `TilesetSourceRect`, `PaletteCategory`).
- Ajout d'une operation metier pure de painting tile dans `map_core` et use case dedie dans `map_editor`.
- Remplacement du panneau droit vide par un panneau palette fonctionnel: categories, target layer, grille de tiles, preview, edition categorie.
- Rendu reel des TileLayer sur le canvas en utilisant l'image du tileset actif.
- Painting unitaire sur clic palette + clic map (outil `tilePaint`) avec marquage `isDirty`.

## 8. Prochaines etapes recommandees
- Verification fonctionnelle rapide des actions map (rename/delete/duplicate/resize) sur un vrai projet.
- Decide et implementer une strategie de gestion des entites/warps/triggers hors-bounds apres shrink (conserver, tronquer, ou avertir).
- Ajouter le painting multi-tile (elements composites) en s'appuyant sur `TilesetSourceRect` (width/height > 1).
- Ajouter les outils d'edition manquants autour du painting (eraser, fill, selection rectangulaire, copier-coller).
- Brancher la logique tilesets dans `map_runtime` pour preparer la coherence editor/runtime.

## 9. Decisions d'architecture importantes
- Le resize est une operation pure dans `map_core` (reutilisable) et est invoque via un use case dans `map_editor` (UI -> notifier -> use case).
- Les layers tile/collision sont des tableaux flatten (row-major attendu: index = y * width + x).
- Object layers ne sont pas redimensionnees pour le moment (pas de dependance explicite a une grille fixe).
- Les tilesets sont importes physiquement dans le projet (pas de reference absolue externe) et references via `relativePath` dans le manifest.
- L'assignation d'un tileset a une map est contrainte par une resolution metier: global + groupe de la map + parents de groupe.
- La palette persistante est stockee au niveau `ProjectTilesetEntry` pour preparer categories et elements composites sans coupler la UI.

## 10. Points de vigilance / dette technique / bugs connus
- En cas de reduction de map, les `entities/warps/triggers` peuvent se retrouver hors de la nouvelle grille: non gere pour l'instant.
- La validation metier est minimale (taille positive); les tailles de layers ne sont pas verifiees systematiquement.
- Le rendu des TileLayer considere `tileId <= 0` comme vide; le flux actuel de painting unitaire utilise des IDs >= 1.
- Le painting multi-tile n'est pas encore active dans les use cases (base modele prete, UI/logic a etendre).
- Apres ajout/modif de providers Riverpod, il faut regenerer le code (`build_runner`) pour eviter des erreurs du type `ResizeMapUseCaseRef` inconnu.
- Modifier les settings globaux impacte visuellement le canvas (ok), mais l'effet sur les maps existantes n'est pas versionne ni historise (a clarifier si besoin).
- La suppression d'un tileset est bloquee s'il est encore utilise par au moins une map (controle via chargement des maps du manifest).
- Le rendu visuel de l'image tileset (palette/painting) n'est pas encore implemente malgre l'import et la persistance.

## Checklist fonctionnelle (etat)
- Ouvrir un projet existant: fait
- Sauvegarder un projet: fait
- Gerer un manifest de projet: fait
- Creer une map: fait
- Charger une map: fait
- Sauvegarder une map: fait
- Renommer une map: partiellement fait
- Supprimer une map: partiellement fait
- Dupliquer une map: partiellement fait
- Redimensionner une map: fait
- Gerer plusieurs maps dans un meme projet: fait
- Gerer les connexions entre maps: pas fait
- Afficher une grille editable: partiellement fait
- Se deplacer dans le canvas: fait
- Zoomer dans le canvas: fait
- Selectionner un outil: fait
- Selectionner une layer active: fait
- Ajouter/renommer/reordonner/masquer/supprimer des layers: pas fait
- Peindre des tiles: partiellement fait
- Effacer des tiles: pas fait
- Remplir une zone: pas fait
- Faire de la selection rectangulaire: pas fait
- Copier-coller une zone: pas fait
- Avoir une palette de tiles: partiellement fait
- Charger et afficher un vrai tileset: partiellement fait
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
- Supporter l'undo/redo: pas fait
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
