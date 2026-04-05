# Dialogue Studio — suppression de la bibliothèque redondante

## 1. Résumé exécutif

Le panneau **« Dialogue Library »** dans le **World Explorer** (`ProjectExplorerPanel`) dupliquait la liste des dialogues, le glisser-déposer, les menus contextuels et l’import `.yarn` / `.txt` déjà couverts (ou remplaçables) par **Dialogue Studio**. Ce bloc a été **retiré**. L’import fichier a été **rebranché** dans la colonne gauche de `DialogueStudioWorkspace`. Les libellés de l’inspecteur d’entités qui renvoyaient vers « l’explorateur / bibliothèque Dialogues » ont été **alignés** sur Dialogue Studio. Aucune couche d’abstraction nouvelle, aucune écriture Git.

## 2. Où vivait encore l’ancienne Dialogue Library

- **Fichier principal** : `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
  - Carte `InspectorSectionCard` titrée **« Dialogue Library »** dans `_ProjectExplorerPanelState._buildTree`, avec actions « New script », « New folder », « Import .yarn or .txt ».
  - Méthodes d’îlot : `_buildScriptLibraryIsland`, `_buildScriptLibrarySection`.
  - État local : `_expandScriptLib`, hauteur `hScript`.
  - **Au-dessus de la classe** : types et helpers dédiés au DnD et aux menus ( `_DialogueLibraryDragData`, feedbacks drag, `_DialogueFolderMoveOption`, prompts dossiers/scripts, `_importProjectDialoguePicker`, `_showProjectDialogueContextMenu`, etc.).
  - **Sous-widgets privés** : `_DialogueLibraryRootDropStrip`, `_DialogueFolderHeaderDnD`, `_DialogueLibraryFolderNode`, `_DialogueScriptNode`.
- **Non concerné** : `ProjectExplorerPanel` en tant que widget reste le conteneur du World Explorer ; seule la section dialogue-yarn y était redondante avec Dialogue Studio.

## 3. Ce qui était redondant

- **Double liste** : arborescence dialogues + sélection `selectProjectDialogue` identique en esprit à la colonne gauche de Dialogue Studio.
- **Double point d’entrée produit** : deux endroits présentés comme « la » bibliothèque de scripts Yarn.
- **Wording** : sous-titre World Explorer et textes d’aide dans `entity_properties_panel.dart` qui parlaient encore de la bibliothèque dans l’explorateur.

## 4. Décision prise

**Cas 1 — suppression complète du panneau explorer** : le panneau gauche redondant est supprimé. Les **use cases** (`EditorNotifier` : création, dossiers, import, renommage, suppression) restent disponibles via Dialogue Studio ou l’inspecteur existant. L’import fichier est **déplacé** vers Dialogue Studio avec `folderId: null` (racine du manifeste), comme l’action « Import » simple de l’ancien bandeau.

**Non réalisé dans cette passe** : parité fonctionnelle avec les menus contextuels avancés de l’ancien panneau (import **dans un dossier précis**, déplacement de dossiers par DnD depuis l’explorer). Ces flux existent toujours côté notifier si une autre UI les rappelle plus tard ; ils ne sont plus exposés depuis le World Explorer.

## 5. Modifications réalisées

| Fichier | Changement |
|---------|------------|
| `lib/src/ui/panels/project_explorer_panel.dart` | Suppression de la carte « Dialogue Library », de `_expandScriptLib` / `hScript`, des méthodes `_buildScriptLibrary*`, `_promptNewProjectDialogue`, de tout le bloc helpers DnD/menus dialogue au niveau fichier (sauf ce qui concerne **tilesets**), et des classes `_DialogueLibrary*` / `_DialogueScriptNode`. Sous-titre du header World Explorer mis à jour pour orienter vers Dialogue Studio. |
| `lib/src/ui/canvas/dialogue_studio_workspace.dart` | Import `file_picker`, bouton **« Importer .yarn / .txt »** + méthode `_importProjectDialogue` (équivalent de l’ancien picker : `FilePicker` + `showMacosEditorPromptSheet` + `notifier.importProjectDialogue(..., folderId: null)`). Titres / sous-titres de la colonne gauche et message vide du centre ajustés pour parler de **sélecteur / liste** plutôt que de « bibliothèque » concurrente. |
| `lib/src/ui/panels/entity_properties_panel.dart` | Remplacement des mentions « explorateur (bibliothèque Dialogues) » / « Dialogue (bibliothèque) » par des formulations centrées **Dialogue Studio** et **dialogue (projet)**. |

## 6. Ce qui a été conservé volontairement

- **Dialogue Studio** (`DialogueStudioWorkspace`, mode `EditorWorkspaceMode.dialogue`, toolbar existante).
- **Narrative Studio** dans l’explorer (`NarrativeLibraryPanel` — scénarios, pas doublon de la liste Yarn projet).
- **Tileset Library** et tout le DnD / menus **tilesets** dans `project_explorer_panel.dart`.
- **Dropdowns** PNJ / panneaux / dresseur : toujours alimentés par `project.dialogues` ; la donnée manifeste ne change pas.

## 7. Ce qui a été refusé

- Nouveau service/provider partagé pour l’import (duplication locale du flux picker dans Dialogue Studio, sans abstraction « au cas où »).
- Réimplémentation dans cette passe du DnD dossiers/scripts et des menus contextuels complets dans Dialogue Studio.
- Toute opération Git (commit, stash, etc.), conformément à la consigne.

## 8. Impacts sur la navigation / shell / panneaux

- **Shell** : inchangé ; `EditorShellPage` importe toujours `ProjectExplorerPanel`.
- **Side panel gauche** : une section en moins dans le scroll du World Explorer ; hiérarchie **Tileset → Narrative → World → …** conservée.
- **Sélection** : `selectedProjectDialogueId` toujours pilotée par Dialogue Studio (et par les flows existants ailleurs si présents).
- **Cutscene → Dialogue Studio** : non modifié (pas de fichier cutscene touché dans cette passe).

## 9. Tests mis à jour ou exécutés

- **Aucun test automatisé modifié** (pas de test ciblant la section supprimée du fichier explorer).
- **Exécutés** depuis `packages/map_editor` :
  - `flutter test test/dialogue_yarn_codec_test.dart`
  - `flutter test test/dialogue_editor_validation_test.dart`
  - `flutter test test/dialogue_preview_runner_test.dart`  
  Tous **verts**.
- `flutter analyze` sur le package : pas d’erreur bloquante sur les fichiers modifiés (uniquement des infos `prefer_const_*` préexistantes / globales).

## 10. Risques restants

- **Import dans un sous-dossier** : l’ancien menu dossier permettait `importProjectDialogue(..., folderId: id)`. Le nouveau bouton Dialogue Studio importe à la **racine** (`folderId: null`). Réorganisation ensuite possible si d’autres commandes existent ailleurs ; sinon besoin d’un futur contrôle ciblé dossier dans Dialogue Studio.
- **DnD / déplacement rapide** depuis l’explorer : supprimé avec le panneau ; les API notifier de déplacement restent disponibles mais ne sont plus exposées dans ce panneau.
- **Utilisateurs habitués** au chemin « World Explorer → Dialogue Library » : doivent passer par **Dialogue Studio** ou la **Narrative Studio** selon le besoin.
