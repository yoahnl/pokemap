# Project Status (pokemonProject)

Last updated: 2026-03-21

## 1. Resume du projet
Editeur de maps Pokemon-like/RPG sur grille en monorepo Flutter/Dart:
- `packages/map_core`
- `packages/map_editor`
- `packages/map_runtime`

Architecture visee:
UI -> `EditorNotifier` -> use cases -> repositories/filesystem -> JSON.

Note importante:
les tests ne sont pas une priorite pour le moment. Ne pas ajouter de tests ni passer du temps sur la couverture sauf demande explicite.

## 2. Architecture actuelle
- `map_core`: modeles metier, serialization JSON, validation metier, operations pures.
- `map_editor`: Flutter Desktop, Riverpod, use cases, persistance filesystem, UI.
- `map_runtime`: base Flame minimale (preparation, pas encore une preview complete).

Separations metier explicites:
- Groupes du monde (`ProjectMapGroup`) pour l organisation des maps.
- Groupes internes de tileset (`TilesetElementGroup`) pour organiser la bibliotheque d elements d un tileset.
- Categories d elements (`ProjectElementCategory`) pour classifier la bibliotheque.
- Layers de map (`TileLayer`, `CollisionLayer`, `ObjectLayer`) pour la cible de peinture.

## 3. Fonctionnalites faites
- Ouvrir/sauvegarder projet.
- Gestion du manifest projet.
- Creer/charger/sauvegarder/renommer/supprimer/dupliquer/resize de map.
- Parametres globaux projet (`tileWidth`, `tileHeight`, `displayScale`, `defaultMapWidth`, `defaultMapHeight`).
- Import tilesets (copie locale + chemin relatif), scope global/groupe, assignation a une map.
- Rendu des tile layers sur canvas + peinture tile unitaire et multi-tile.
- Bibliotheque d elements projet persistee:
  - categories hierarchiques,
  - elements nommes avec source rect,
  - scope monde optionnel (`groupId`),
  - layer recommandee optionnelle,
  - tags optionnels.
- Workspace Tileset (menu Tilesets + panneau droit):
  - selection explicite du tileset courant dans l explorateur,
  - affichage image complete du tileset avec grille + scroll,
  - creation d element depuis selection rectangulaire,
  - listing des elements du tileset selectionne.
- Groupes internes de tileset persistes:
  - modele `TilesetElementGroup` par tileset,
  - sous-groupes via `parentGroupId`,
  - rattachement d un element via `tilesetGroupId`,
  - edition de groupe (create/subgroup/rename) depuis l UI.
- Validation metier etendue:
  - unicite IDs (maps, groupes monde, tilesets, categories, elements),
  - coherence hierarchies (groupes monde, categories, groupes internes tileset),
  - detection de cycles,
  - coherence element -> tileset/category/groupId/tilesetGroupId/source rect.

## 4. Fonctionnalites partiellement faites
- Gestion multi-tilesets: fonctionnelle mais UX de tri/recherche encore simple.
- Edition palette brute tiles + bibliotheque elements: coexistent, rationalisation UX restante.
- Elements contextuels monde: resolution de base ok, pas encore de modes avances configurables.
- Workspace tileset: suppression/reorder des groupes internes non implementes.
- Dirty state: operationnel sur les flux principaux, a homogeniser.
- Runtime Flame: base en place, integration preview in-game non terminee.

## 5. Fonctionnalites non faites
- Connexions entre maps.
- Edition complete des layers (add/rename/reorder/hide/delete).
- Outils avances map (eraser/fill/selection rect map/copy-paste/undo-redo).
- Collisions avancees (types/comportements).
- Warps/triggers/NPC/objets/panneaux/spawn (pose + edition).
- Inspector de proprietes complet.
- Preview runtime in-game.
- Gestion assets projet au-dela des tilesets.

## 6. Tache en cours
Terminee pour cette etape:
transformer la section Tilesets en workspace d edition avec groupes internes de tileset persistes et edition d elements lies au tileset selectionne.

## 7. Dernieres modifications realisees
2026-03-21:
- `map_core`:
  - `ProjectTilesetEntry` enrichi avec `elementGroups`.
  - Nouveau modele `TilesetElementGroup`.
  - `ProjectElementEntry` enrichi avec `tilesetGroupId`.
  - Codegen `freezed/json` regenere.
  - Validation etendue:
    - coherence/acyclicite groupes internes tileset,
    - coherence element `tilesetGroupId`.
- `map_editor` use cases:
  - `CreateTilesetElementGroupUseCase`
  - `CreateTilesetElementSubgroupUseCase`
  - `RenameTilesetElementGroupUseCase`
  - `ResolveTilesetElementsUseCase`
  - `CreateProjectElementUseCase` / `UpdateProjectElementUseCase` etendus avec `tilesetGroupId`.
- Providers Riverpod:
  - nouveaux providers pour les use cases ci-dessus + codegen regenere.
- `EditorState`:
  - ajout `selectedTilesetEditorId`
  - ajout `selectedTilesetElementGroupId`
- `EditorNotifier`:
  - selection du tileset workspace,
  - CRUD minimal groupes internes tileset,
  - listage des elements par tileset/groupe interne,
  - create/update element avec `tilesetGroupId`,
  - synchro de la selection workspace sur create/load/assign/delete tileset/map.
- UI:
  - `ProjectExplorerPanel`: node tileset selectionnable + highlight + correction overflow header.
  - `TilesetPalettePanel`:
    - mode workspace sur tileset selectionne (pas uniquement map active),
    - affichage image complete du tileset avec grille/scroll,
    - panneau groupes internes (create/subgroup/rename + filtre),
    - creation/edition d element avec champ groupe interne tileset,
    - liste des elements du tileset avec metadonnees (groupe monde + groupe interne + layer).

## 8. Prochaines etapes recommandees
- Ajouter suppression et reorder des groupes internes de tileset.
- Ajouter drag/drop de classement des elements dans un tileset.
- Ajouter filtres rapides (tags, recherche texte, layer recommandee).
- Ajouter preview ghost de l element sous curseur avant pose sur la map.
- Ajouter edition/suppression des elements directement depuis le workspace.

## 9. Decisions d architecture importantes
- Les groupes internes de tileset sont separes des groupes du monde et des layers.
- Le lien element -> groupe interne est persiste via `tilesetGroupId`.
- Le workspace tileset est pilote par l etat (`selectedTilesetEditorId`) dans `EditorNotifier`.
- La logique de resolution/liste des elements d un tileset reste cote use cases, pas dans les widgets.
- La compatibilite avec l existant est conservee:
  - import/assign tileset,
  - painting tile unitaire/multi-tile,
  - bibliotheque d elements deja en place.

## 10. Points de vigilance / dette technique / bugs connus
- Suppression/reparentage de groupes internes non implemente dans cette iteration.
- Quelques lints/deprecations preexistants dans le projet restent presents (hors scope).
- Le panneau droit combine encore deux niveaux (palette brute + bibliotheque metier), une convergence UX reste a faire.
- Le paint d un element d un autre tileset que celui de la map active est bloque cote notifier avec message d erreur (comportement volontaire).

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
- Faire de la selection rectangulaire: fait
- Copier-coller une zone: pas fait
- Avoir une palette de tiles: fait
- Charger et afficher un vrai tileset: fait
- Gerer plusieurs tilesets: fait
- Associer un tileset a une map: fait
- Workspace d edition de tileset: fait
- Groupes internes de tileset (categorie/sous-categorie): fait
- Creation d element depuis tileset: fait
- Edition d element (nom/categorie/groupe monde/groupe interne/layer/tags): fait
- Resolution des elements par tileset + groupe interne: fait
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
