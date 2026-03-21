# Project Status (pokemonProject)

Last updated: 2026-03-21

## 1. Resume du projet
Editeur de maps Pokemon-like/RPG sur grille en monorepo Flutter/Dart:
- `packages/map_core`
- `packages/map_editor`
- `packages/map_runtime`

Le projet suit une architecture orientee Clean Architecture (UI -> notifier -> use cases -> repositories/filesystem -> JSON).

Note importante: les tests ne sont pas une priorite pour le moment. Ne pas ajouter de tests ou passer du temps sur la couverture sauf demande explicite.

## 2. Architecture actuelle
- `map_core`: modeles metier, serialization JSON, validation metier, operations pures.
- `map_editor`: application Flutter Desktop, Riverpod, use cases, persistance filesystem, UI.
- `map_runtime`: base runtime Flame encore minimale.

Axes metier clairement separes:
- Groupes du monde (CITY/ROUTE/VILLAGE/... via `ProjectMapGroup`).
- Bibliotheque d elements (categories/sous-categories + elements).
- Layers de map (TileLayer/CollisionLayer/ObjectLayer, selectionnee pour peindre).

## 3. Fonctionnalites faites
- Ouvrir/sauvegarder projet.
- Gestion manifest projet.
- Creer/charger/sauvegarder map.
- Renommer/supprimer/dupliquer map.
- Redimensionnement de map.
- Parametres globaux projet (`tileWidth`, `tileHeight`, `displayScale`, `defaultMapWidth`, `defaultMapHeight`).
- Import tilesets (copie locale + manifest), scope global/groupe, assignation map.
- Rendu tileset/layers sur canvas.
- Peinture tile unitaire.
- Peinture multi-tile.
- Bibliotheque d elements persistee au niveau projet:
  - categories hierarchiques (`ProjectElementCategory`),
  - elements nommes (`ProjectElementEntry`),
  - source rect dans tileset,
  - rattachement groupe optionnel (global si `groupId == null`),
  - layer recommandee optionnelle,
  - tags optionnels.
- UI `Elements` dediee:
  - section explicite dans le panneau droit (onglet `Elements`),
  - navigation categories/sous-categories (arborescence repliable),
  - creation categorie/sous-categorie,
  - renommage categorie,
  - creation d element depuis selection rectangulaire tileset,
  - edition d element (nom/categorie/groupe/layer/tags),
  - visualisation du tileset source et du scope global/groupe,
  - selection d element comme brush de peinture.

## 4. Fonctionnalites partiellement faites
- Gestion multi-tilesets: base bonne, UX encore simple.
- Edition palette brute tiles: maintenue pour compatibilite, pas encore rationalisee avec la bibliotheque.
- Resolution contextuelle des elements:
  - faite pour map active (global + groupe map + ancetres),
  - pas encore de mode avance de “descendants/sous-groupes dynamiques” configurable.
- Gestion dirty state: operationnelle sur les flux principaux, a durcir globalement.
- Validation metier: solide pour les invariants de base, encore extensible.
- Runtime Flame: preparation en place, integration non terminee.

## 5. Fonctionnalites non faites
- Connexions entre maps.
- Edition complete des layers (ajout/rename/reorder/visibility/suppression).
- Outils avancees map (eraser, fill, selection rectangulaire map, copy/paste, undo/redo).
- Collisions avancees (types de collision/comportement de sol).
- Warps/triggers/NPC/objets/panneaux/spawn (pose + edition complete).
- Inspector de proprietes complet.
- Preview in-game runtime.
- Gestion assets projet au-dela des tilesets.

## 6. Tache en cours
Terminee: evolution vers une vraie bibliotheque d elements projet (structure metier + use cases + UI + persistance + painting).

## 7. Dernieres modifications realisees
2026-03-21:
- `map_core`:
  - `ProjectManifest` enrichi avec:
    - `elementCategories`,
    - `elements`.
  - Ajout des modeles:
    - `ProjectElementCategory`,
    - `ProjectElementEntry`.
  - Validation metier etendue:
    - unicite IDs categories/elements,
    - coherence parent/enfant categories + detection de cycle,
    - coherence element->category,
    - coherence element->tileset,
    - coherence element->group,
    - coherence source rect.
- `map_editor` use cases:
  - `CreateElementCategoryUseCase`,
  - `CreateElementSubcategoryUseCase`,
  - `RenameElementCategoryUseCase`,
  - `CreateProjectElementUseCase`,
  - `UpdateProjectElementUseCase`,
  - `ResolveVisibleProjectElementsUseCase`.
  - `CreateProjectUseCase` initialise des categories par defaut pour la bibliotheque.
  - `LoadProjectUseCase` injecte les categories par defaut si projet ancien sans bibliotheque.
- `EditorState`:
  - ajout `selectedProjectElementId` pour le brush element metier.
- `EditorNotifier`:
  - CRUD categories/elements,
  - resolution des elements visibles selon contexte de map,
  - selection de brush element,
  - peinture prioritaire via element metier selectionne.
- UI `TilesetPalettePanel` refondu:
  - onglet `Tiles` conserve (legacy palette tiles),
  - onglet `Elements` dedie (arborescence + liste + edition),
  - workflow creation element depuis selection rectangulaire tileset.
- Providers Riverpod mis a jour + codegen regenere.

## 8. Prochaines etapes recommandees
- Ajouter suppression/reorder de categories et elements.
- Ajouter deplacement drag-and-drop d element entre categories.
- Ajouter feedback visuel de clipping lors du paint multi-tile hors map.
- Ajouter mode de resolution contextuelle configurable (inclure/exclure descendants de groupe).
- Ajouter UX de previsualisation “ghost” de l element sous curseur avant pose.
- Connecter progressivement les elements metier aux futurs outils gameplay (warps/triggers/NPC).

## 9. Decisions d architecture importantes
- La bibliotheque d elements est un modele projet global (`ProjectManifest`) et non un detail purement UI.
- Les categories/sous-categories d elements sont separees des groupes du monde:
  - categorie = organisation de bibliotheque,
  - groupe = contexte metier monde,
  - layer = cible de peinture map.
- La logique metier de resolution contextuelle est dans des use cases, pas dans les widgets.
- Le painting reste centralise via operations/use cases, l UI ne modifie pas directement les donnees map.
- Contrainte actuelle de resolution contextuelle:
  - elements visibles par defaut = globaux + elements lies au groupe de la map active + ancetres.

## 10. Points de vigilance / dette technique / bugs connus
- Pas de suppression d element/categorie dans cette iteration.
- UX categories encore simple (pas de drag-and-drop de tri/reparentage).
- Le mode `All tilesets` peut afficher des elements non peignables sur la map si tileset different de la map active (controle present au paint, feedback ameliorable).
- Certaines deprecations Flutter/Riverpod preexistantes restent visibles a l analyse (hors scope de cette tache).
- Les anciens `paletteEntries` de tileset sont conserves pour la palette brute legacy; une strategie de convergence future est a definir.

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
- Bibliotheque d elements dediee: fait
- Categories/sous-categories d elements: fait
- Rattachement element a groupe/sous-groupe: fait
- Creation d element depuis tileset: fait
- Edition element (nom/categorie/groupe/layer/tags): fait
- Resolution contextuelle elements (global + groupe + ancetres): fait
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
