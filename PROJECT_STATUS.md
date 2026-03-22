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
- Affectation des tilesets au niveau `TileLayer.tilesetId` (et non plus au niveau map pour la logique active).

## 3. Fonctionnalites faites
- Ouvrir/sauvegarder projet.
- Gestion du manifest projet.
- Creer/charger/sauvegarder/renommer/supprimer/dupliquer/resize de map.
- Parametres globaux projet (`tileWidth`, `tileHeight`, `displayScale`, `defaultMapWidth`, `defaultMapHeight`).
- Import tilesets (copie locale + chemin relatif), scope global/groupe, assignation a une `TileLayer`.
- Rendu des tile layers sur canvas + peinture tile unitaire et multi-tile.
- Ghost preview map operationnel:
  - preview paint pour tile simple, palette entry et project element,
  - statut visuel valide/invalide selon compatibilite de tileset avec la `TileLayer` active,
  - preview erase dedie avec rendu distinct.
- Outil eraser operationnel:
  - clic + drag,
  - effacement 1x1 sans brush selectionne,
  - effacement multi-tiles base sur la taille du brush courant.
- Resolution commune du brush dans `EditorNotifier`:
  - partagee entre paint, erase et preview,
  - meme logique de pattern/tileset/source rect,
  - aucune emission d erreur au simple hover.
- Systeme de layers operationnel sur map active:
  - ajout / renommage / suppression / reorder (avant/arriere),
  - action "supprimer tous les layers" avec map pouvant rester a zero layer,
  - masquage / affichage,
  - opacite editable,
  - selection de layer active robuste avec fallback coherent (ou `null` si aucun layer).
- Tilesets par layer operationnels:
  - chaque `TileLayer` porte son `tilesetId`,
  - le rendu map gere plusieurs tilesets en parallele selon la pile de layers,
  - la peinture valide le brush contre le tileset de la layer active.
- Panneau `Layers` dedie dans l UI (mode map):
  - liste ordonnee des layers,
  - type (`tile` / `collision` / `object`),
  - selection active,
  - actions directes (move/rename/delete/visibility/opacity/add).
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
  - checks stricts des champs map (id/name/size),
  - unicite IDs internes (layers/entities/warps/triggers),
  - validation complete des layers (opacity, tailles de grilles, tile IDs non negatifs),
  - validation des positions entites/warps/triggers et des zones de triggers,
- map valide meme avec zero layer (choix explicite de conception pour ce projet).
- Undo/redo map-level operationnel pour la map active:
  - paint/erase tile et pattern,
  - mutations layers (add/rename/delete/delete all/reorder/visibility/opacity),
  - resize map,
  - assignation tileset a la layer active,
  - piles `undo/redo` limitees et coherentes avec l etat dirty,
  - drag paint/erase groupe en une seule entree d historique (stroke).
- Raccourcis clavier desktop operationnels:
  - macOS: `Cmd+Z`, `Cmd+Shift+Z`, `Cmd+Y`,
  - Windows/Linux: `Ctrl+Z`, `Ctrl+Shift+Z`, `Ctrl+Y`,
  - sauvegarde: `Cmd+S` (macOS), `Ctrl+S` (Windows/Linux),
  - raccourcis ignores quand un champ texte est focus.
- Suppression d element projet operationnelle:
  - use case dedie + provider + integration notifier,
  - action UI explicite sur chaque carte d element,
  - nettoyage automatique du brush si l element supprime etait selectionne.
- Refactor structurel engage sur les use cases:
  - extraction de `paint`, `layer`, `map` dans des fichiers dedies:
    - `paint_use_cases.dart`,
    - `layer_use_cases.dart`,
    - `map_use_cases.dart`,
  - `project_use_cases.dart` reste point d entree, avec `part` pour ces blocs.

## 4. Fonctionnalites partiellement faites
- Gestion multi-tilesets: fonctionnelle mais UX de tri/recherche encore simple.
- Edition palette brute tiles + bibliotheque elements: coexistent, rationalisation UX restante.
- Systeme de layers: base edition/rendu solide, mais edition avancee (locks/groupes/layers specialisees Pokemon) non implementee.
- Elements contextuels monde: resolution de base ok, pas encore de modes avances configurables.
- Workspace tileset: suppression/reorder des groupes internes non implementes.
- Interaction selection vs scroll dans le canvas tileset: base solide, raffinements UX possibles.
- Dirty state: operationnel sur les flux principaux, a homogeniser.
- Runtime Flame: base en place, integration preview in-game non terminee.

## 5. Fonctionnalites non faites
- Connexions entre maps.
- Edition avancee des layers (locks/groupes/presets/layers specialisees).
- Outils avances map (fill/selection rect map/copy-paste).
- Undo/redo global projet (au-dela de la map active).
- Collisions avancees (types/comportements).
- Warps/triggers/NPC/objets/panneaux/spawn (pose + edition).
- Inspector de proprietes complet.
- Preview runtime in-game.
- Gestion assets projet au-dela des tilesets.

## 6. Tache en cours
Terminee pour cette etape:
- undo/redo map-level robuste avec regroupement des strokes paint/erase,
- raccourcis desktop undo/redo,
- suppression d elements projet depuis l UI,
- nettoyage structurel initial des use cases (`paint`/`layer`/`map`).

## 7. Dernieres modifications realisees
2026-03-22 (ghost preview + erase):
- `map_core`:
  - nouvelles operations pures dans `map_paint.dart`:
    - `eraseTileOnLayer(...)`,
    - `eraseTilePatternOnLayer(...)`.
- `map_editor`:
  - nouveaux use cases:
    - `EraseTileOnMapUseCase`,
    - `EraseTilePatternOnMapUseCase`.
  - nouveaux providers Riverpod associes.
  - `EditorNotifier`:
    - refactor de resolution brush partagee (paint/preview/erase),
    - ajout `resolveMapToolPreview(...)` (preview paint/erase),
    - ajout `eraseAt(...)` (clic + drag),
    - compatibilite tileset/layer evaluee pour distinguer preview valide/invalide,
    - aucun spam `errorMessage` lors du hover.
  - `MapCanvas` / `MapGridPainter`:
    - routing gestures `tilePaint` et `eraser`,
    - rendu du ghost preview paint semi-transparent,
    - rendu preview invalide avec overlay de refus,
    - rendu preview erase dedie.

2026-03-22 (undo/redo + shortcuts + delete element):
- `map_editor`:
  - `EditorState`:
    - ajout de l historique map active (`mapUndoStack`, `mapRedoStack`),
    - ajout de `mapStrokeStart`,
    - ajout de `savedMapSnapshot`,
    - ajout des flags `canUndoMap` / `canRedoMap`.
  - `EditorNotifier`:
    - ajout `beginMapStroke()`, `endMapStroke()`, `undoMap()`, `redoMap()`,
    - centralisation des mutations map via `_applyMapMutation(...)`,
    - invalidation redo sur nouvelle mutation,
    - coherence dirty/snapshot apres undo/redo/save,
    - integration stroke dans paint/erase pour produire une seule entree par drag.
  - `MapCanvas`:
    - integration cycle stroke en gestures (tap/pan start/update/end/cancel),
    - drag paint/erase agrège en une seule action undo.
  - `EditorShellPage`:
    - ajout du systeme `Shortcuts`/`Actions` pour undo/redo desktop,
    - ajout du raccourci sauvegarde desktop (`Cmd+S` / `Ctrl+S`),
    - garde contre declenchement quand un champ texte est focus.
  - `TopToolbar`:
    - ajout boutons `Undo` / `Redo` relies a `canUndoMap` / `canRedoMap`.
  - Elements:
    - ajout `DeleteProjectElementUseCase` + provider,
    - ajout `deleteProjectElement(...)` dans le notifier,
    - action de suppression UI dans `TilesetPalettePanel` avec confirmation.
  - Refactor use cases:
    - extraction dans fichiers dedies:
      - `map_use_cases.dart`,
      - `layer_use_cases.dart`,
      - `paint_use_cases.dart`.

2026-03-22 (correctifs fin d etape layers):
- `map_editor`:
  - `LayersPanel`: correction des actions de reorder pour que:
    - bouton Haut -> `moveMapLayerUp`,
    - bouton Bas -> `moveMapLayerDown`,
    - tooltips alignes avec ce comportement.
  - `MapCanvas`: correction de l ordre de peinture pour respecter la pile affichee:
    - layer la plus basse dessinee en premier,
    - layer la plus haute dessinee en dernier (donc visible au-dessus).

2026-03-22:
- refonte tilesets par layer (option 1):
  - `map_core`:
    - `TileLayer` enrichi avec `tilesetId`,
    - `MapData.tilesetId` garde en mode legacy de compatibilite JSON,
    - `MapValidator` adapte: plus de contrainte sur `map.tilesetId`; validation du `tilesetId` de `TileLayer` quand renseigne.
  - `map_editor`:
    - assignation de tileset deplacee de la map vers les `TileLayer`,
    - suppression du selecteur explicite de tileset dans la toolbar (plus de notion UI "Map Tileset" / "Active Layer Tileset"),
    - liaison implicite: au paint, une tile layer vide/sans tileset se lie automatiquement au tileset du brush,
    - migration a chaud des anciennes maps chargees: si une tile layer n a pas de `tilesetId`, reprise du `map.tilesetId` legacy,
    - blocage de suppression d un tileset s il est encore utilise par une tile layer d une map,
    - rendu `MapCanvas` multi-tilesets (une image par `tilesetId` de tile layer),
    - peinture basee sur le tileset du brush + coherence de la tile layer cible (fin du couplage dur `map.tilesetId`).

2026-03-22:
- `map_core`:
  - ajout d operations pures `map_layers.dart`:
    - ajout de layer (`tile`/`collision`/`object`) avec initialisation de grilles correcte,
    - renommage / suppression sans contrainte de minimum de layers,
    - reorder,
    - visibilite,
    - opacite.
  - ajout enum `MapLayerKind`.
  - export des operations layers dans `map_core.dart`.
- `map_editor`:
  - nouveaux use cases layers:
    - `AddMapLayerUseCase`,
    - `RenameMapLayerUseCase`,
    - `DeleteMapLayerUseCase`,
    - `MoveMapLayerUseCase`,
    - `SetMapLayerVisibilityUseCase`,
    - `SetMapLayerOpacityUseCase`.
  - nouveaux providers Riverpod associes.
  - `EditorNotifier`:
    - CRUD layers map active + reorder + visibilite + opacite,
    - selection de layer active robuste (validation + fallback apres suppression),
    - coherence `activeLayerId` renforcee sur create/load/resize/assign/delete map,
    - peinture bloquee explicitement si la layer active n est pas une `TileLayer`.
  - UI:
    - ajout d un panneau dedie `LayersPanel` (mode map),
    - integration du panneau layers dans la colonne droite via `EditorShellPage`,
    - actions utilisateur disponibles: select/add/rename/delete/reorder/visibility/opacity.
  - action supplementaire layers:
    - suppression globale des layers de la map sans layer de fallback; une map vide en layers est valide/sauvegardable.
  - canvas map:
    - rendu des tile layers garde l ordre reel de la pile,
    - visibilite respectee,
    - opacite appliquee au niveau layer via `saveLayer`.

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
    - champs map obligatoires non vides (`id`, `name`),
    - tailles map strictement positives,
    - unicite des IDs internes (`layers`, `entities`, `warps`, `triggers`),
    - validation par type de layer:
      - `TileLayer`: taille de grille exacte + tile IDs non negatifs,
      - `CollisionLayer`: taille de grille exacte,
      - `ObjectLayer`: validation structurelle (`id`, `name`, `opacity`),
    - map valide meme sans aucun layer,
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
- Finaliser l eclatement complet du monolithe `project_use_cases.dart` (tilesets/elements/projet) pour aligner toute la couche application sur la meme granularite.
- Ajouter suppression/reorder des groupes internes de tileset et suppression de palette entries.
- Lier explicitement l UI du brush (labels/preview) a des metadonnees uniformes par type de brush.
- Ajouter locks, duplication et eventuel grouping de layers.
- Ajouter edition collisions dediee (outil collision + rendu overlay collision).
- Ajouter drag/drop de classement des elements dans un tileset.
- Ajouter filtres rapides (tags, recherche texte, layer recommandee).
- Ajouter edition/suppression des elements directement depuis le workspace central tileset.
- Ajouter des interactions de navigation plus avancees dans `TilesetEditorCanvas` (panning dedie, raccourcis).
- Ajouter un feedback explicite de la raison d invalidite directement dans l UI quand la preview est en mode refuse.
- Ajouter ensuite des validations de coherence inter-maps au niveau projet (ex: existence reelle des `targetMapId` des warps) dans la validation projet.

## 9. Decisions d architecture importantes
- `EditorState.activeBrush` est la seule source de verite pour la selection de brush.
- Les types de brush restent explicites et distincts:
  - tile unitaire (`tileId` + `tilesetId`),
  - palette entry (`entryId` + `tilesetId`),
  - project element (`elementId`).
- La resolution de brush est mutualisee dans `EditorNotifier` et reutilisee par paint/erase/preview.
- La peinture map ne lit plus de champs de selection concurrents; elle ne consomme que `activeBrush`.
- Le ghost preview est pilote cote notifier avec un statut explicite (`valid` / `invalid`) et rendu cote painter.
- L eraser reutilise la taille du brush courant, avec fallback 1x1 quand `activeBrush` vaut `none`.
- Les mutations de layers sont centralisees via operations pures `map_core` + use cases `map_editor`.
- `activeLayerId` reste pilote cote notifier et est resolu automatiquement vers une layer valide, ou `null` si la map n a plus de layer.
- Les groupes internes de tileset sont separes des groupes du monde et des layers.
- Le lien element -> groupe interne est persiste via `tilesetGroupId`.
- Le workspace central est pilote par un mode explicite (`EditorWorkspaceMode`).
- Le tileset cible est pilote par `selectedTilesetEditorId` dans `EditorNotifier`.
- La validation map stricte reste centralisee dans `map_core` via `MapValidator`.
- La logique de resolution/liste des elements d un tileset reste cote use cases, pas dans les widgets.
- Les tilesets sont portes par les `TileLayer`; `MapData.tilesetId` reste seulement en fallback legacy.
- L historique undo/redo est volontairement scope a la map active (pas d historique global projet pour cette iteration).
- Toute mutation map passe par `_applyMapMutation(...)` dans le notifier pour garder un seul pipeline de coherence (undo/redo, dirty, layer active, tileset selectionne).
- Les strokes paint/erase sont traites comme des transactions logiques (begin/end) pour eviter une entree d historique par cellule.
- Les raccourcis undo/redo sont geres au shell via `Shortcuts/Actions` avec garde de focus texte.
- La compatibilite avec l existant est conservee:
  - import/assign tileset,
  - painting tile unitaire/multi-tile,
  - bibliotheque d elements deja en place.

## 10. Points de vigilance / dette technique / bugs connus
- Le ghost preview invalide pre-vient le refus avant clic, mais la raison detaillee n est pas encore affichee directement dans l UI.
- Les brushes lies a un tileset different restent bloques a la peinture si la layer active ne peut pas etre rebindee.
- Les layers `collision` et `object` sont gerables en pile mais leur rendu visuel dedie reste minimal (pas d overlay collision avancee ni d objets editoriaux).
- Le panneau layers est fonctionnel mais sans lock/groupes/filtres; ergonomie a enrichir avant des maps tres grandes.
- Une map peut maintenant etre volontairement sans layers; toute action de peinture est alors no-op tant qu aucune layer active tile n est selectionnee.
- Les anciennes maps restent lisibles via fallback legacy `map.tilesetId`; la migration complete du champ legacy n est pas encore supprimee du schema.
- Suppression/reparentage de groupes internes non implemente dans cette iteration.
- Undo/redo reste limite a la map active:
  - pas d historique cross-map,
  - pas de persistance d historique entre changements de map.
- Quelques lints/deprecations preexistants dans le projet restent presents (hors scope).
- La logique visuelle tileset est maintenant centrale; le panneau droit reste mixte (outils + bibliotheque) et peut encore etre simplifie.
- Le paint d un element d un autre tileset que celui de la map active est bloque cote notifier avec message d erreur (comportement volontaire).
- `MapValidator` ne verifie pas l existence reelle de la map cible des warps (verification volontairement gardee au niveau projet).
- Le concept metier courant est `tileset par TileLayer`; `MapData.tilesetId` est conserve en legacy JSON uniquement.

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
- Ajouter/renommer/reordonner/masquer/supprimer des layers: fait
- Peindre des tiles: fait
- Effacer des tiles: fait
- Ghost preview brush: fait
- Preview d effacement: fait
- Remplir une zone: pas fait
- Faire de la selection rectangulaire: fait
- Copier-coller une zone: pas fait
- Avoir une palette de tiles: fait
- Charger et afficher un vrai tileset: fait
- Gerer plusieurs tilesets: fait
- Associer un tileset a une TileLayer: fait
- Workspace d edition de tileset: fait
- Panneau Layers dedie: fait
- Respect strict de la pile visuelle des layers (ordre panneau -> rendu canvas): fait
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
- Supporter l undo/redo: fait (map active)
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
- Ghost preview + erase: fait
- Systeme de brush: fait
- Layers: fait (base MVP), evolutions avancees non faites
- Collisions: pas fait
- Undo/redo: fait (map active)
- Warps/triggers/entities: pas fait
