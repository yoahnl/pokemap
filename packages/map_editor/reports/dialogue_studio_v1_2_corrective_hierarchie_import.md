# Dialogue Studio V1.2 — rapport correctif (hiérarchie, import, explorateur)

## 1. Analyse du problème

### 1.1 Ce que la passe V1.1 avait retiré

- **Panneau « Dialogue Library »** dans `ProjectExplorerPanel` : liste complète, DnD, menus contextuels, import avec cible de dossier.
- **Conséquences réelles** (constat produit utilisateur) :
  - Import systématique à la **racine manifeste** depuis Dialogue Studio (`folderId: null`), sans choix explicite de dossier cible.
  - **Hiérarchie** peu lisible dans le studio (dossiers affichés comme simples titres sans repli, sans interaction « cible »).
  - **Visibilité projet** : plus d’arborescence dialogues dans l’explorateur latéral, alors que le produit demande de comprendre où vivent les `.yarn` dans le manifeste.

### 1.2 Structures de données déjà en place (rien d’inventé)

| Concept | Modèle / API |
|--------|----------------|
| Dossiers | `ProjectDialogueFolder` dans `ProjectManifest.dialogueFolders` |
| Fichiers logiques | `ProjectDialogueEntry` dans `ProjectManifest.dialogues` (`relativePath`, `folderId`) |
| Arbre dérivé | `buildDialogueLibraryTree` / `DialogueLibraryBranch` (`packages/map_core/.../dialogue_library_tree.dart`) |
| Picker dossiers | `flattenDialogueFoldersForPicker` |
| Anti-cycles déplacement dossier | `dialogueFolderSubtreeIds` |
| Création / import | `CreateProjectDialogueUseCase`, `ImportProjectDialogueUseCase` (`folderId` optionnel) |
| Orchestration UI | `EditorNotifier` : `createProjectDialogue`, `importProjectDialogue`, `createDialogueLibraryFolder`, `renameDialogueLibraryFolder`, `moveDialogueLibraryFolder`, `deleteDialogueLibraryFolder`, `assignDialogueToLibraryFolder`, `moveDialogueToLibraryRoot`, `selectProjectDialogue`, `selectDialogueWorkspace` |

### 1.3 « Helpers supprimés » réutilisés proprement

La passe V1.1 avait supprimé des **widgets + DnD** dans l’explorateur, pas les **use cases**. Cette passe **ne restaure pas** le DnD explorer. Elle réutilise :

- Les **mêmes use cases** que l’ancien panneau (via `EditorNotifier`).
- Les **helpers map_core** déjà exportés (`buildDialogueLibraryTree`, `flattenDialogueFoldersForPicker`, `dialogueFolderSubtreeIds`).
- Le **schéma mental** des pickers `_AssignDialogueFolderDest` / options de déplacement, réimplémenté **localement** dans `dialogue_studio_workspace.dart` sous forme de petites classes privées `_DialogueFolderMoveOption` et `_AssignDialogueFolderDest` (pas de nouveau module partagé « au cas où »).

---

## 2. Décisions produit

### 2.1 Frontière retenue : Project Explorer vs Dialogue Studio

| Zone | Rôle |
|------|------|
| **Dialogue Studio** | **Centre opérationnel** : arborescence interactive, cible d’import/création, menus dossier & dialogue, édition, aperçu, Yarn, IA. |
| **Project Explorer — carte « Dialogues (projet) »** | **Vue projet honnête** : même hiérarchie manifeste, **lecture + sélection** ; un tap sur un fichier bascule vers Dialogue Studio (`selectProjectDialogue` + `selectDialogueWorkspace`). **Aucune** création / import / renommage depuis cette carte (évite la double UX « deux studios »). |

### 2.2 Solution choisie pour la visibilité hiérarchique

- **Option retenue** : *section légère* dans l’explorateur (titre **« Dialogues (projet) »**), plus arborescence complète dans Dialogue Studio.
- **Pourquoi** : le code de `ProjectExplorerPanel` est déjà structuré en `InspectorSectionCard` ; ajouter une carte dédiée est **minimal**, **branché** à `buildDialogueLibraryTree`, et respecte la consigne « pas un second studio » (pas d’actions de gestion sur la carte).

### 2.3 Import dans un dossier après cette passe

1. L’utilisateur **sélectionne une cible** :
   - **Racine** : bouton « Racine — dialogues sans dossier » → `_sidebarTargetFolderId = null`.
   - **Dossier** : tap sur le **nom du dossier** dans l’arbre → `_sidebarTargetFolderId = id` du dossier (surbrillance bleue).
2. Tap sur un **fichier dialogue** : ouvre le dialogue **et** aligne la cible sur le `folderId` du fichier (comportement pratique pour « continuer dans le même dossier »).
3. **Importer .yarn / .txt** appelle `EditorNotifier.importProjectDialogue(..., folderId: _sidebarTargetFolderId)`.
4. **Sélection automatique** : déjà gérée dans le notifier (`selectedProjectDialogueId` = dernière entrée après import) — inchangé, toujours valide tant que le use case append en fin de liste.

---

## 3. Décisions UX

- **Langage** : libellés en français dans Dialogue Studio pour la colonne gauche (cohérent avec le fichier existant).
- **Repli** : chevron **séparé** du tap « cible dossier » pour éviter la confusion chevron = sélection.
- **Menus** : `⋯` dossier (renommer, sous-dossier, déplacer, supprimer) et `⋯` dialogue (renommer, ranger, racine).
- **Carte explorateur** : sous-titre explicite sur le fait que l’édition se fait dans Dialogue Studio ; bouton crayon → `selectDialogueWorkspace`.

---

## 4. Décisions techniques

### 4.1 Fichiers modifiés

| Fichier | Rôle des changements |
|---------|----------------------|
| `lib/src/ui/canvas/dialogue_studio_workspace.dart` | État `_sidebarTargetFolderId`, UI cible racine/dossier, arbre `_StudioDialogueFolderTreeNode`, menus branchés notifier, import/création avec `folderId`, déplacement via pickers. |
| `lib/src/ui/panels/project_explorer_panel.dart` | Carte **Dialogues (projet)**, `_buildProjectDialoguesReadOnlyOverview`, widget `_ProjectExplorerDialogueFolderNode`. |
| `test/project_dialogue_import_and_folder_use_case_test.dart` | **Nouveau** — preuves disque + manifeste pour import racine / dossier et création dans dossier. |
| `test/dialogue_studio_explorer_dialogue_widgets_test.dart` | **Nouveau** — studio + explorateur (MacosTheme, fichier `.yarn` réel sur disque pour éviter spinners infinis). |
| `packages/map_core/test/dialogue_library_tree_test.dart` | **Nouveau** — forme de l’arbre dérivé du manifeste. |

### 4.2 Fichiers volontairement non modifiés

- `EditorNotifier` / `project_dialogue_use_cases.dart` : comportement déjà correct ; pas besoin de nouvelle abstraction.
- Global Story / Step / Cutscene studios : hors scope.
- **DnD** dans l’explorateur : **non réintroduit** (risque de duplication produit ; déplacement explicite via menus / pickers dans Dialogue Studio).

---

## 5. Extraits de code commentés (comportement clé)

### 5.1 Cible d’import / création (état local réellement branché)

```dart
/// Dossier « cible » pour les actions **Nouveau**, **Nouveau dossier** et **Importer**.
///
/// `null` = racine du manifeste (dialogues sans `folderId`), comme dans les use cases
/// [EditorNotifier.createProjectDialogue] / [EditorNotifier.importProjectDialogue].
String? _sidebarTargetFolderId;
```

### 5.2 Passage du `folderId` à l’import (plus de `null` imposé)

```dart
await notifier.importProjectDialogue(
  absoluteSourcePath: path,
  displayName: displayName,
  folderId: _sidebarTargetFolderId,
);
```

### 5.3 Explorateur : lecture seule + ouverture studio

```dart
onTap: () {
  notifier.selectProjectDialogue(d.id);
  notifier.selectDialogueWorkspace();
},
```

---

## 6. Ce qui a été volontairement refusé

- **Réimplémenter la « Dialogue Library » complète** dans l’explorateur (DnD + trois boutons d’action dans le header).
- **Nouveau package / service** « DialogueTreeService » ou provider global sans second consommateur.
- **DnD** dans Dialogue Studio dans cette passe (non requis pour satisfaire les capacités minimales ; déplacement explicite via UI).

---

## 7. Risques restants

- **Suppression de dossier** : le use case échoue si le dossier contient encore des dialogues ou des sous-dossiers ; le menu propose quand même « Supprimer » — l’erreur remonte via `errorMessage` notifier (comportement existant).
- **Tests widget** : dépendent de `MacosTheme` + fichier `.yarn` sur disque pour éviter les animations infinies ; ce n’est pas un test d’intégration bout-en-bout FilePicker (non automatisable sans plugin).
- **Chemins disque** : les fichiers `.yarn` restent sous `dialogues/` plat côté workspace ; seul le **manifeste** porte la hiérarchie par `folderId` (comportement historique du projet, non modifié ici).

---

## 8. Résultats des tests

| Commande | Résultat |
|----------|----------|
| `dart test test/dialogue_library_tree_test.dart` (depuis `packages/map_core`) | OK |
| `flutter test test/project_dialogue_import_and_folder_use_case_test.dart` | OK |
| `flutter test test/dialogue_studio_explorer_dialogue_widgets_test.dart` | OK |
| `flutter test test/dialogue_yarn_codec_test.dart` (régression rapide) | OK |

---

## 9. Critère de réussite (auto-évaluation)

- **Dialogue Studio = centre** : oui (gestion complète dans la colonne gauche + cartes existantes).
- **Dossiers / fichiers réellement gérés** : oui (use cases + UI explicite).
- **Hiérarchie projet visible** : oui (carte explorateur + arbre studio).
- **Import utile avec dossier** : oui (`_sidebarTargetFolderId` → `importProjectDialogue`).
- **Pas de duplication « deux studios »** : oui (explorateur en lecture seule pour les dialogues).
- **Rien d’inventé hors manifeste / use cases** : oui.

---

## 10. Note sur Git

Aucune opération Git d’écriture effectuée dans le cadre de cette passe (conformément à la consigne).
