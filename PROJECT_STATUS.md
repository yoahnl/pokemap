# Project Status (pokemonProject)

Last updated: 2026-03-22

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
- Modes de workspace central:
  - mode `map`: le canvas central affiche et edite la map selectionnee,
  - mode `tileset`: le canvas central affiche et edite le tileset selectionne.
- Canvas central polymorphe:
  - `EditorCanvasHost` route vers `MapCanvas` ou `TilesetEditorCanvas` selon le mode,
  - en mode tileset, la map active peut rester en memoire mais n est plus affichee.
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
- Validation map renforcee (`MapValidator.validate`):
  - checks stricts des champs map (id/name/tilesetId/size),
  - unicite IDs internes (layers/entities/warps/triggers),
  - validation complete des layers (opacity, tailles de grilles, tile IDs non negatifs),
  - validation des positions entites/warps/triggers et des zones de triggers.

## 4. Fonctionnalites partiellement faites
- Gestion multi-tilesets: fonctionnelle mais UX de tri/recherche encore simple.
- Edition palette brute tiles + bibliotheque elements: coexistent, rationalisation UX restante.
- Systeme de brush: source de verite unifiee en place, enrichissements UX possibles (preview cross-tileset, invalidation proactive selon contexte).
- Elements contextuels monde: resolution de base ok, pas encore de modes avances configurables.
- Workspace tileset: suppression/reorder des groupes internes non implementes.
- Interaction selection vs scroll dans le canvas tileset: base solide, raffinements UX possibles.
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
refonte du systeme de selection de brush dans `map_editor` avec une source unique explicite (`activeBrush`) et adaptation complete de la peinture.

## 7. Dernieres modifications realisees
2026-03-22:
- `map_editor`:
  - refonte du modele de brush selectionne:
    - `EditorBrush` devient la source unique de verite (none/tile/paletteEntry/projectElement),
    - enrichissement des variants `tile` et `paletteEntry` avec `tilesetId` pour eviter les ambiguities cross-tileset.
  - `EditorNotifier`:
    - suppression de la logique concurrente sur `selectedTileId` / `selectedPaletteEntryId` / `selectedProjectElementId`,
    - `create/load project/map`, `assign tileset`, `delete map` et `delete tileset` synchronisent correctement `activeBrush`,
    - `selectPaletteTile`, `selectPaletteEntry`, `selectProjectElement` alimentent uniquement `activeBrush`,
    - `paintSelectedBrushAt` simplifie et rebase sur `activeBrush` uniquement,
    - ajout de helpers pour resoudre un brush en pattern de peinture et centraliser les erreurs de peinture.
  - `TilesetPalettePanel`:
    - lecture de la selection via `activeBrush`,
    - highlight/preview/selection d element adaptes au nouveau modele,
    - suppression des dependances UI aux anciens champs de selection.
  - codegen regenere (`freezed`/`riverpod`) pour aligner l etat et le notifier.

2026-03-22:
- `map_core`:
  - `MapValidator.validate(MapData map)` etendu avec validations completes:
    - champs map obligatoires non vides (`id`, `name`, `tilesetId`),
    - tailles map strictement positives,
    - unicite des IDs internes (`layers`, `entities`, `warps`, `triggers`),
    - validation par type de layer:
      - `TileLayer`: taille de grille exacte + tile IDs non negatifs,
      - `CollisionLayer`: taille de grille exacte,
      - `ObjectLayer`: validation structurelle (`id`, `name`, `opacity`),
    - contrainte au moins une layer et au moins une `TileLayer`,
    - validation bornes entites/warps/triggers,
    - validation zones de triggers (taille positive + zone entierement dans la map),
    - messages `ValidationException` explicites et orientes diagnostic.
- `map_editor`:
  - aucun changement fonctionnel dans cette etape.

2026-03-22 (iteration precedente):
- `map_editor` etat/notifier:
  - ajout du mode explicite `EditorWorkspaceMode` (`map` / `tileset`) dans `EditorState`,
  - `loadMap(...)` force le mode `map`,
  - `selectTilesetWorkspace(...)` force le mode `tileset`.
- UI shell:
  - ajout d un host central `EditorCanvasHost`,
  - le centre n affiche plus toujours `MapCanvas`.
- Nouveau canvas central tileset:
  - ajout de `TilesetEditorCanvas`,
  - affichage principal de l image tileset + grille + scroll + selection rectangulaire,
  - creation d element depuis selection directement dans le canvas central.
- Panneau droit:
  - `TilesetPalettePanel` rendu secondaire en mode tileset (onglet `Elements` uniquement),
  - l edition visuelle principale du tileset est deplacee au centre.

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
- Lier explicitement l UI du brush (labels/preview) a des metadonnees uniformes par type de brush.
- Ajouter un resolveur de brush partage entre panneau droit et canvas pour la previsualisation ghost avant peinture.
- Ajouter suppression et reorder des groupes internes de tileset.
- Ajouter drag/drop de classement des elements dans un tileset.
- Ajouter filtres rapides (tags, recherche texte, layer recommandee).
- Ajouter preview ghost de l element sous curseur avant pose sur la map.
- Ajouter edition/suppression des elements directement depuis le workspace.
- Ajouter des interactions de navigation plus avancees dans `TilesetEditorCanvas` (panning dedie, raccourcis).
- Ajouter ensuite des validations de coherence inter-maps au niveau projet (ex: existence reelle des `targetMapId` des warps) dans la validation projet.

## 9. Decisions d architecture importantes
- `EditorState.activeBrush` est la seule source de verite pour la selection de brush.
- Les types de brush restent explicites et distincts:
  - tile unitaire (`tileId` + `tilesetId`),
  - palette entry (`entryId` + `tilesetId`),
  - project element (`elementId`).
- La peinture map ne lit plus de champs de selection concurrents; elle ne consomme que `activeBrush`.
- Les groupes internes de tileset sont separes des groupes du monde et des layers.
- Le lien element -> groupe interne est persiste via `tilesetGroupId`.
- Le workspace central est pilote par un mode explicite (`EditorWorkspaceMode`).
- Le tileset cible est pilote par `selectedTilesetEditorId` dans `EditorNotifier`.
- La validation map stricte reste centralisee dans `map_core` via `MapValidator`.
- La logique de resolution/liste des elements d un tileset reste cote use cases, pas dans les widgets.
- La compatibilite avec l existant est conservee:
  - import/assign tileset,
  - painting tile unitaire/multi-tile,
  - bibliotheque d elements deja en place.

## 10. Points de vigilance / dette technique / bugs connus
- Le rendu de preview/selection reste distribue entre widgets; une unification de la resolution visuelle du brush ameliorerait la maintenabilite.
- Les brushes lies a un tileset different sont bloques a la peinture (volontaire), mais l UX peut encore mieux guider l utilisateur avant le clic.
- Suppression/reparentage de groupes internes non implemente dans cette iteration.
- Quelques lints/deprecations preexistants dans le projet restent presents (hors scope).
- La logique visuelle tileset est maintenant centrale; le panneau droit reste mixte (outils + bibliotheque) et peut encore etre simplifie.
- Le paint d un element d un autre tileset que celui de la map active est bloque cote notifier avec message d erreur (comportement volontaire).
- `MapValidator` ne verifie pas l existence reelle de la map cible des warps (verification volontairement gardee au niveau projet).

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
- Mode explicite map/tileset du canvas central: fait
- Affichage du tileset selectionne dans le canvas central: fait
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

## Mini tableau priorites (etat)
- Systeme de brush: fait
- Layers: partiellement fait
- Collisions: pas fait
- Undo/redo: pas fait
- Warps/triggers/entities: pas fait
