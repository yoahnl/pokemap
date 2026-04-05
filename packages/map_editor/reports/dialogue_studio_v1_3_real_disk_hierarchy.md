# Dialogue Studio V1.3 — Hiérarchie disque réelle sous `dialogues/`

## 1. Diagnostic exact

### Ce qui était surtout logique / manifeste

- Avant V1.3, les **dossiers** (`ProjectDialogueFolder`) et les **`folderId`** structuraient l’UI et l’arbre (`buildDialogueLibraryTree`), mais la **création / import / déplacement** des dialogues ne garantissaient pas que chaque entrée vivait sous un chemin disque qui **reflète** la hiérarchie des dossiers (fichiers souvent plats sous `dialogues/<id>.yarn` même lorsque `folderId` pointait vers un sous-dossier logique).

### Ce qui ne correspondait pas au disque

- Un dialogue pouvait être **classé** dans un dossier en manifeste sans que le fichier soit **physiquement** dans `dialogues/<segments…>/<id>.yarn`.
- Les opérations de bibliothèque (assigner à un dossier, racine, renommer ou déplacer un dossier) ne **déplaçaient** pas systématiquement les fichiers ni ne **réécrivaient** les préfixes de `relativePath` en accord avec la nouvelle géométrie de dossiers.

### Pourquoi c’était insuffisant

- Pour un outil orienté **projet fichier** (Git, recherche, outils externes), la hiérarchie visible doit être **la même** que celle du disque. Sinon le manifeste et l’explorateur **mentent** sur l’emplacement réel des assets.

---

## 2. Décisions prises

### Création de dialogue (`CreateProjectDialogueUseCase`)

- **ID fichier** : `generateUniqueDialogueId` à partir du nom (slug + suffixe si collision d’ID manifeste).
- **Chemin** : `expectedDialogueFileRelativePath` → `dialogues/<id>.yarn` à la racine bibliothèque, ou `dialogues/<segment1>/<segment2>/…/<id>.yarn` si `folderId` est défini.
- **Segments dossier** : `computeDialogueFolderDiskSegments` — un segment par dossier, **unique dans la fratrie** (suffixe `_2`, `_3`, … si deux noms slugifient pareil).
- **Disque** : création des parents + écriture du stub Yarn après `assertDestinationFileAvailable`.

### Import (`ImportProjectDialogueUseCase`)

- Même règle de chemin que la création ; **copie** du fichier source vers la destination calculée ; extension conservée (`.yarn` ou `.txt`).

### Déplacement d’un dialogue vers un dossier (`AssignDialogueToLibraryFolderUseCase`)

- Recalcul du chemin cible avec le **même** `id` et la **même** extension.
- **`moveProjectRelativeFile`** si le chemin change ; mise à jour `folderId`, `relativePath`, `sortOrder`.

### Retour à la racine (`MoveDialogueToLibraryRootUseCase`)

- Cible `dialogues/<id>.<ext>` ; move disque si nécessaire ; `folderId: null`.

### Renommage d’un dialogue affiché (`UpdateProjectDialogueUseCase`)

- **Décision explicite** : le renommage **ne renomme pas** le fichier sur disque. Le fichier reste `« id ».yarn` (ou `.txt`) à l’emplacement de `relativePath`. Seul le champ **`name`** (affichage / métadonnée) change.  
- **Pourquoi** : identité stable par `id` + chemins runtime ; éviter de casser des références ou des outils qui s’appuient sur le nom de fichier = id.  
- **Cohérence produit** : le nom affiché peut diverger du nom de fichier ; c’est **documenté** sur la classe.

### Renommage de dossier (`RenameDialogueLibraryFolderUseCase`)

- Si l’ancien répertoire dossier existe sur disque : **`moveProjectRelativeDirectory(oldDir, newDir)`** puis **réécriture** des `relativePath` des dialogues dont le chemin était sous l’ancien préfixe (`rewritePathPrefix`).
- Si l’ancien répertoire **n’existe pas** (projet legacy jamais matérialisé sur disque) : **seul** le manifeste des dossiers est mis à jour ; **aucune** réécriture des `relativePath` des dialogues (évite de désynchroniser un fichier réel encore à l’ancien chemin). Voir **limites** ci-dessous.

### Déplacement de dossier (`MoveDialogueLibraryFolderUseCase`)

- Même schéma que le renommage : move répertoire + propagation des préfixes sur les dialogues **si** le répertoire source existait.

### Collisions

| Situation | Comportement |
|-----------|----------------|
| Création / import : fichier cible déjà présent | `EditorValidationException` : *Target file already exists: …* (`assertDestinationFileAvailable`) |
| Move dialogue : destination occupée | `EditorValidationException` : *destination exists …* (`moveProjectRelativeFile`) |
| Move dossier disque : cible existe | `EditorValidationException` : *target exists …* (`moveProjectRelativeDirectory`) |
| Deux entrées manifeste, même `relativePath` | `ProjectValidator` → `ValidationException` (*Duplicate dialogue relativePath…*) |

**Pas** d’auto-suffixe silencieux sur les fichiers (stratégie : **refus explicite** sauf déjà géré par **IDs uniques** à la création).

### Suppression de dossier (`DeleteDialogueLibraryFolderUseCase`)

- **Refus** si sous-dossiers ou dialogues avec ce `folderId` → `EditorConflictException` avec message clair.
- Si suppression autorisée : mise à jour manifeste puis **`deleteEmptyProjectRelativeDirectory`** (échec silencieux si le dossier n’est pas vide côté OS — le manifeste reste la garde principale).

### Slugs et caractères

- `slugifyDialoguePathSegment` : minuscules, caractères non `[a-z0-9_]` → `_`, compactage des `_`, trim des bords ; chaîne vide → `folder`.

---

## 3. Source(s) de vérité

| Couche | Rôle |
|--------|------|
| **Manifeste** | Liste des dossiers (`ProjectDialogueFolder`) et des entrées (`ProjectDialogueEntry` avec `folderId`, `relativePath`, `id`, …). |
| **`relativePath`** | Doit désigner le **fichier réel** sous la racine projet ; validé par `ProjectValidator` (préfixe `dialogues/`, pas d’échappement, unicité). |
| **Disque** | Fichiers `.yarn`/`.txt` et répertoires créés / déplacés par les use cases. |
| **Arbre dérivé** | `buildDialogueLibraryTree` : projection **manifeste** (`folderId` + tri) ; cohérent avec le disque **si** les use cases ont été utilisés pour muter le projet. |

**Règle** : après une opération supportée V1.3, `folderId` et le préfixe de `relativePath` doivent **décrire le même sous-arbre** que les segments disque du dossier.

---

## 4. Ce qui est réellement branché

### Écriture disque + manifeste

- `CreateProjectDialogueUseCase` — création fichier + entrée.
- `ImportProjectDialogueUseCase` — copie + entrée.
- `AssignDialogueToLibraryFolderUseCase` / `MoveDialogueToLibraryRootUseCase` — move fichier + entrée.
- `CreateDialogueLibraryFolderUseCase` — manifeste + `ensureDialogueFolderDirectoryExists`.
- `RenameDialogueLibraryFolderUseCase` / `MoveDialogueLibraryFolderUseCase` — move répertoire + réécriture chemins dialogues (conditions ci-dessus).
- `DeleteDialogueLibraryFolderUseCase` — suppression manifeste + tentative suppression dossier vide.
- `UpdateProjectDialogueUseCase` — manifeste uniquement (pas de rename fichier).
- `DeleteProjectDialogueUseCase` — inchangé pour V1.3 (supprime le fichier à `relativePath`).

### Lecture

- **Dialogue Studio** (`dialogue_studio_workspace.dart`) : arbre via `buildDialogueLibraryTree` ; actions qui passent par les providers / notifiers appellent les use cases ci-dessus (pas de second chemin « virtuel » ajouté en V1.3).
- **Project Explorer** (`project_explorer_panel.dart`) : même arbre en lecture / sélection pour ouvrir le studio.
- **Support chemins partagé** : `dialogue_disk_path_support.dart` (segments, chemins attendus, move fichier/répertoire, assert disponibilité).

### Helpers sans branchement fantôme

- Toutes les fonctions exportées de `dialogue_disk_path_support.dart` sont utilisées depuis `project_dialogue_use_cases.dart` ou `project_dialogue_library_use_cases.dart`.

---

## 5. Ce qui a été refusé / hors périmètre

- **Drag-and-drop** fichier/dossier dans l’UI : non requis pour V1.3 ; les actions passent par menus / commandes existantes.
- **Service de synchronisation** générique manifeste ↔ disque : pas d’ajout ; la logique est **dans** les use cases concernés.
- **Renommage fichier = nom affiché** : explicitement **non** pour limiter la complexité et les références cassées (voir décision §2).
- **Refactor** Global Story / Step / Cutscene / runtime : non touché.

---

## 6. Limites restantes

1. **Projets legacy** où les dossiers n’ont **jamais** eu de répertoire disque : renommer / déplacer un dossier **ne réaligne pas** automatiquement les `relativePath` des dialogues (le code vérifie `Directory(oldAbs).exists()`). Il faudrait une **migration** dédiée ou une action « réconcilier disque » pour ces cas.
2. **`UpdateProjectDialogueUseCase`** ne vérifie pas que `relativePath` pointe encore vers un fichier existant après des manipulations externes (hors éditeur).
3. **Suite `flutter test` complète** du package `map_editor` : un test **Global Story Studio** (`global_story_studio_workspace_test.dart` — *can insert a step and add a destination link…*) échoue dans l’environnement actuel (`Bad state: No element` sur un `tap`) ; **non lié** aux changements Dialogue V1.3. Les tests **dialogue** listés en §7 passent.

---

## 7. Tests exécutés

### Commandes

```bash
cd packages/map_editor
flutter test \
  test/dialogue_disk_hierarchy_v13_test.dart \
  test/project_dialogue_import_and_folder_use_case_test.dart \
  test/dialogue_studio_explorer_dialogue_widgets_test.dart \
  test/dialogue_editor_validation_test.dart \
  test/dialogue_preview_runner_test.dart \
  test/dialogue_yarn_codec_test.dart

cd packages/map_core
dart test test/dialogue_library_tree_test.dart

cd packages/map_editor
dart analyze lib/src/application/use_cases/dialogue_disk_path_support.dart \
  lib/src/application/use_cases/project_dialogue_use_cases.dart \
  lib/src/application/use_cases/project_dialogue_library_use_cases.dart
```

### Résultats

- Toutes les commandes ci-dessus : **succès** (tests OK, analyze sans issue).
- `flutter test` sur **tout** le package `map_editor` : **1 échec** sur un test Global Story Studio (voir §6).

### Fichiers de tests V1.3 notables

- `test/dialogue_disk_hierarchy_v13_test.dart` : disque + manifeste (création, assign, racine, rename/move dossier, suppression refusée, doublon `relativePath`, collisions création/assign, import imbriqué, cohérence `buildDialogueLibraryTree`).
- `test/project_dialogue_import_and_folder_use_case_test.dart` : chemins imbriqués attendus (mis à jour en V1.3).
- `test/dialogue_studio_explorer_dialogue_widgets_test.dart` : studio + explorer (sélection, section dialogues).

---

## 8. Extraits de code importants

### Chemins attendus et segments disque

- `packages/map_editor/lib/src/application/use_cases/dialogue_disk_path_support.dart` : `computeDialogueFolderDiskSegments`, `dialogueFolderDirectoryRelativePath`, `expectedDialogueFileRelativePath`, `rewritePathPrefix`, `moveProjectRelativeFile`, `moveProjectRelativeDirectory`, `assertDestinationFileAvailable`.

### Use cases dialogue projet

- `packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart` : création, import, mise à jour (doc rename affiché seul).

### Use cases bibliothèque dossiers

- `packages/map_editor/lib/src/application/use_cases/project_dialogue_library_use_cases.dart` : dossiers + assign + racine + rename/move avec propagation.

### Validation unicité `relativePath`

- `packages/map_core/lib/src/validation/validators.dart` : boucle sur `dialogues` avec détection des doublons de chemin normalisé.

---

*Rapport généré dans le cadre de Dialogue Studio V1.3 — hiérarchie disque alignée sur le manifeste.*
