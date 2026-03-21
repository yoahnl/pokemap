# Project Status (pokemonProject)

Last updated: 2026-03-21

## 1. Resume du projet
Editeur de maps sur grille pour un RPG/Pokemon-like, base sur Flutter/Dart, organise en monorepo avec un `core` (modele + validation), un `editor` (UI + workflows) et un `runtime` (execution/preview in-game).

Note importante: pour le moment, les tests ne sont pas une priorite. Ne pas en ajouter / ne pas etendre la couverture dans les taches courantes, sauf demande explicite.

## 2. Architecture actuelle
- `packages/map_core`: modeles (Freezed/JSON), exceptions, validation minimale, logique metier pure reutilisable.
- `packages/map_editor`: application Flutter Desktop (Riverpod), use cases applicatifs, repositories fichiers, UI (toolbar, explorer, canvas).
- `packages/map_runtime`: runtime Flame (structure en place, rendu/chargement encore minimal).

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

## 4. Fonctionnalites partiellement faites
- Renommer une map: fait cote logique et UI, verification fonctionnelle a faire
- Supprimer une map: fait cote logique et UI, verification fonctionnelle a faire
- Dupliquer une map: fait cote logique et UI, verification fonctionnelle a faire
- Afficher une grille editable (affichage + hover, pas d'edition)
- Gerer plusieurs tilesets (structure, pas d'UI/usage complet)
- Associer un tileset a une map (champ `tilesetId`, integration partielle)
- Avoir une sauvegarde propre avec etat dirty (isDirty present, workflow a durcir)
- Verifier les erreurs de coherence (validation tres partielle)
- Preparer un runtime compatible Flame (squelette present)
- Pouvoir editer progressivement routes/villes/interieurs/donjons (base de structure)
- Pense specifique Pokemon sur grille (base de modele + direction)
- Coherence Clean Architecture stricte (globalement visee, mais pas totalement appliquee partout)

## 5. Fonctionnalites non faites
- Gerer les connexions entre maps
- Ajouter/renommer/reordonner/masquer/supprimer des layers
- Peindre/effacer/remplir des tiles
- Selection rectangulaire + copier-coller
- Palette de tiles + charger/afficher un vrai tileset
- Peindre/visualiser collisions + types de collisions/sol
- Warps/triggers/npc/objets/panneaux/spawn (pose + config)
- Inspector de proprietes
- Editer proprietes des maps / globales du projet / entites
- Undo/redo
- Previsualiser le rendu in-game (runtime preview)
- Gerer les assets du projet

## 6. Tache en cours
Aucune (derniere tache livree: redimensionnement de map).

## 7. Dernieres modifications realisees
2026-03-21:
- Ajout d'une logique metier de resize dans `map_core` (`resizeMapData`) pour redimensionner les layers tile/collision en preservant les donnees.
- Ajout d'un `ResizeMapUseCase` dans `map_editor` et d'une action UI "Resize Map" dans la toolbar (dialog width/height + validation).
- Ajout d'un repaint explicite du canvas quand la map change (important pour le resize).
- Creation de ce fichier `PROJECT_STATUS.md` pour le suivi persistant.
- Ajout d'une configuration globale `ProjectSettings` dans le manifest (tileWidth, tileHeight, displayScale, defaultMapWidth/Height).
- Ajout d'un dialog "Project Settings" pour editer le nom du projet + settings et persister dans `project.json`.
- Le canvas et la creation de map utilisent maintenant les settings globaux (fin du `32` en dur).

## 8. Prochaines etapes recommandees
- Verification fonctionnelle rapide des actions map (rename/delete/duplicate/resize) sur un vrai projet.
- Decide et implementer une strategie de gestion des entites/warps/triggers hors-bounds apres shrink (conserver, tronquer, ou avertir).
- Commencer la pile "edition tile": rendu tileset, palette, outil pinceau, ecriture dans tile layers.

## 9. Decisions d'architecture importantes
- Le resize est une operation pure dans `map_core` (reutilisable) et est invoque via un use case dans `map_editor` (UI -> notifier -> use case).
- Les layers tile/collision sont des tableaux flatten (row-major attendu: index = y * width + x).
- Object layers ne sont pas redimensionnees pour le moment (pas de dependance explicite a une grille fixe).

## 10. Points de vigilance / dette technique / bugs connus
- En cas de reduction de map, les `entities/warps/triggers` peuvent se retrouver hors de la nouvelle grille: non gere pour l'instant.
- La validation metier est minimale (taille positive); les tailles de layers ne sont pas verifiees systematiquement.
- Le rendu/edition de tiles n'est pas encore implemente: l'indexation flatten devra rester coherente partout.
- Apres ajout/modif de providers Riverpod, il faut regenerer le code (`build_runner`) pour eviter des erreurs du type `ResizeMapUseCaseRef` inconnu.
- Modifier les settings globaux impacte visuellement le canvas (ok), mais l'effet sur les maps existantes n'est pas versionne ni historise (a clarifier si besoin).

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
- Peindre des tiles: pas fait
- Effacer des tiles: pas fait
- Remplir une zone: pas fait
- Faire de la selection rectangulaire: pas fait
- Copier-coller une zone: pas fait
- Avoir une palette de tiles: pas fait
- Charger et afficher un vrai tileset: pas fait
- Gerer plusieurs tilesets: partiellement fait
- Associer un tileset a une map: partiellement fait
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
- Gerer les assets du projet: pas fait
- Pouvoir editer progressivement routes/villes/interieurs/donjons: partiellement fait
- Etre pense specifiquement pour un jeu de type Pokemon sur grille: partiellement fait
- Rester coherent avec une Clean Architecture stricte: partiellement fait
- Rester modulaire entre core, editor et runtime: fait
