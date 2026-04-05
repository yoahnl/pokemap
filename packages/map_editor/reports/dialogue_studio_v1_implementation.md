# Dialogue Studio — passe V1 (implémentation réelle)

**Date (contexte repo)** : avril 2026  
**Contrainte respectée** : aucune opération Git d’écriture effectuée dans le cadre de cette passe (pas de commit / push / stash, etc.).

---

## 1. Analyse du problème avant passe

### Constats

- Les dialogues projet vivaient surtout dans l’**explorateur** (`ProjectExplorerPanel`) comme **fichiers `.yarn`**, avec création via `CreateProjectDialogueUseCase` et un stub `minimalYarnStub`.
- Le **parseur runtime** Yarn (`packages/map_runtime/.../parse_yarn_dialogue.dart`) :
  - **ignore** les lignes `<<…>>` qui ne sont pas `<<jump …>>` ;
  - **n’enregistre pas** les nœuds dont le corps serait vide après parse.
- `map_editor` **ne dépend pas** de `map_runtime` (évite d’attirer Flame dans l’éditeur). Toute logique d’édition doit donc vivre dans `map_editor` ou un package neutre.

### Écart produit

L’UX « bibliothèque de scripts » ne répond pas au rôle **Dialogue Studio** : montage conversationnel **no-code**, blocs lisibles, inspecteur, preview honnête, IA branchée **pour de vrai** (Mistral HTTP), sans faire du Yarn brut la vue principale.

---

## 2. Décisions produit (retenues)

| Décision | Justification |
|----------|----------------|
| **Vérité UX = modèle structuré** (`DialogueEditorDocument` + steps scellés) | Le créateur raisonne en blocs, pas en syntaxe. |
| **Yarn = persistance / export** | `emitDocumentToYarn` / `parseYarnToDocument` ; onglet « Yarn » en **lecture seule** générée depuis les blocs (pas d’édition bidirectionnelle Yarn↔modèle dans cette passe). |
| **Codec aligné sur le runtime + extensions** | Même structure de choix / indentation / `<<jump>>` que le parseur runtime ; **conservation** des autres `<<…>>` et des **nœuds vides** pour l’éditeur. |
| **Preview autonome dans `map_editor`** | Pas de dépendance à `map_runtime` ; machine d’état minimale (`DialoguePreviewSession`) qui saute les commandes comme le runtime le fait largement aujourd’hui. |
| **IA = Mistral REST direct** | Un client HTTP minimal (`MistralDialogueClient`) : pas de couche provider abstraite vide. Clé : champ UI + `MISTRAL_API_KEY` env. |
| **Cutscene → Dialogue** | Callback unique `onOpenDialogueStudio` sur `CutsceneStudioWorkspace` : sélection du dialogue + `selectDialogueWorkspace()`. Changement **minimal** sur Cutscene. |
| **Workspace `EditorWorkspaceMode.dialogue`** | Cohérent avec Global / Step / Cutscene ; bandeau narratif + toolbar + shell mis à jour. |

---

## 3. Architecture retenue

### 3.1 Fichiers **nouveaux**

| Fichier | Rôle |
|---------|------|
| `lib/src/features/dialogue/application/dialogue_editor_model.dart` | Modèle : nœuds, branches, types de blocs (Start, Réplique, Narration, Choix, Jump, Condition, Commande, Fin). IDs stables par bloc. |
| `lib/src/features/dialogue/application/dialogue_yarn_codec.dart` | Parse / emit Yarn ↔ document ; extension « garder les `<<>>` non-jump ». |
| `lib/src/features/dialogue/application/dialogue_editor_validation.dart` | Règles réelles : réplique vide, saut inconnu, choix sans suite, nœud orphelin (heuristique), etc. |
| `lib/src/features/dialogue/application/dialogue_preview_runner.dart` | Preview joueur : lignes, choix, sauts. |
| `lib/src/features/dialogue/application/mistral_dialogue_client.dart` | Client `http` → `api.mistral.ai/v1/chat/completions` + `stripMarkdownFences`. |
| `lib/src/ui/canvas/dialogue_studio_workspace.dart` | UI **3 colonnes** (wireframe) : bibliothèque + canvas + inspecteur / validation. |
| `test/dialogue_yarn_codec_test.dart` | Tests parse stub, round-trip, préservation `<<>>`. |
| `test/dialogue_editor_validation_test.dart` | Tests validation ciblés. |
| `test/dialogue_preview_runner_test.dart` | Test ligne → choix → branche. |

### 3.2 Fichiers **modifiés** (pourquoi)

| Fichier | Motif |
|---------|--------|
| `lib/src/features/editor/state/editor_state.dart` | Ajout `EditorWorkspaceMode.dialogue`. |
| `lib/src/features/editor/state/editor_notifier.dart` | `selectDialogueWorkspace()`, `saveProjectDialogueYarnBody()` + use case Riverpod. |
| `lib/src/application/use_cases/project_dialogue_use_cases.dart` | `SaveDialogueYarnBodyUseCase` : écrit le `.yarn` sur disque sans toucher au manifest. |
| `lib/src/app/providers/use_case_providers.dart` | Provider `@riverpod` pour la sauvegarde. |
| `pubspec.yaml` | Dépendance directe `http`. |
| `lib/src/ui/canvas/narrative_workspace_canvas.dart` | Chip « Dialogue », corps `DialogueStudioWorkspace`, callback cutscene. |
| `lib/src/ui/canvas/editor_canvas_host.dart` | Router le mode dialogue vers `NarrativeWorkspaceCanvas`. |
| `lib/src/ui/editor_shell_page.dart` | Titres, sous-titres, narrative flag, inspecteur narratif pour dialogue. |
| `lib/src/ui/shared/top_toolbar.dart` | Bouton Dialogue Studio. |
| `lib/src/ui/panels/narrative_library_panel.dart` | Raccourci « Dialogue ». |
| `lib/src/ui/panels/narrative_inspector_panel.dart` | Libellé mode + sélection dialogue projet. |
| `lib/src/ui/canvas/cutscene_studio_workspace.dart` | `onOpenDialogueStudio` + bouton « Ouvrir dans Dialogue Studio » sur bloc dialogue. |

**Fichiers générés** (build_runner) : `use_case_providers.g.dart`, `editor_notifier.g.dart`, etc. — régénération standard du package.

---

## 4. Ce qui est **réellement branché**

- **Navigation** : toolbar, bandeau narratif central, panneau bibliothèque narratif → `EditorWorkspaceMode.dialogue`.
- **Bibliothèque gauche** : arborescence via `buildDialogueLibraryTree` (map_core), recherche locale, création dialogue / dossier (use cases existants), renommer / supprimer, sélection → `selectedProjectDialogueId`.
- **Chargement** : lecture fichier `projectRootPath` + `ProjectDialogueEntry.relativePath` → parse → document.
- **Canvas** : sélection de bloc, suppression, ajout de blocs (barre d’outils), branches visibles pour les choix.
- **Inspecteur** : champs pour réplique, narration, choix (libellés + ajout d’option), jump, condition, commande.
- **Validation** : liste d’issues réelles dans la colonne droite (partagée avec les règles du module).
- **Sauvegarde** : `emitDocumentToYarn` → `SaveDialogueYarnBodyUseCase` → disque.
- **IA** :
  - « Générer avec IA » / « Continuer avec IA » : prompt système Yarn → réponse Mistral → `stripMarkdownFences` → `parseYarnToDocument` → canvas.
  - Actions inspecteur : reformulation / raccourcir / générer 3 libellés (choix) — **même client**, clé requise.
- **Cutscene** : bouton visible si `onOpenDialogueStudio != null` et `dialogueId` renseigné.

---

## 5. Limites exactes & hors scope volontaire

| Limite | Détail honnête |
|--------|----------------|
| **Yarn onglet** | Texte **généré** depuis le modèle ; **pas** d’édition Yarn qui réinjecte dans les blocs (évite un parse « magique » non maîtrisé dans l’UI). |
| **`defaultStartNode` manifest** | Le preview utilise **le premier nœud** du fichier (ou titre explicite futur) — **non** branché sur `ProjectDialogueEntry.defaultStartNode` dans cette passe. |
| **Round-trip parfait** | Le bloc **Début** (`DeStartStep`) est **injecté** à l’import pour le wireframe et **omis** à l’export → pas de ligne Yarn équivalente (volontaire). |
| **Narration** | Convention : ligne `(texte)` ; pas un type Yarn distinct côté moteur. |
| **Inspecteur + `TextEditingController`** | Les champs recréent des contrôleurs à chaque rebuild : **UX perfectible** (curseur qui saute possible) ; acceptable pour V1, à factoriser en stateful léger si besoin. |
| **Dupliquer dialogue** | Non implémenté (pas de use case dédié dans cette passe). |
| **Tests Mistral** | Pas de test réseau intégré (dépendance externe + clé) ; logique testée via codec / validation / preview. |
| **Runtime** | Aucun changement : le jeu continue d’utiliser son parseur ; les **commandes** non-jump restent **non exécutées** côté runtime comme avant — l’éditeur ne les **perd** plus à la ré-enregistrement. |

---

## 6. Explication du code produit (résumé technique)

### Modèle (`dialogue_editor_model.dart`)

- `DialogueEditorNode` = un bloc `title: …` … `===`.
- Steps scellés : réplique (`speaker` + `body`), narration, choix (`DeChoiceBranch` avec sous-steps), jump, condition (`<<if…>>`), commande, fin, start visuel.
- `newDialogueEditorId()` : IDs uniques sans package `uuid`.

### Codec (`dialogue_yarn_codec.dart`)

- Reprend la logique du parseur runtime (choix `->`, indentation, `<<jump>>`).
- **Différences** : lignes `<<…>>` non-jump → `DeCommandStep` ou `DeConditionStep` ; nœuds **sans** lignes acceptés ; après parse, **premier nœud** reçoit un `DeStartStep` pour l’UX.

### Validation (`dialogue_editor_validation.dart`)

- Parcours récursif des steps et des branches ; titres dupliqués ; sauts orphelins ; avertissements choix sans `<<jump>>` ; info « aperçu Yarn disponible ».

### Preview (`dialogue_preview_runner.dart`)

- File d’événements `DialoguePreviewLine` / `DialoguePreviewChoicePrompt` / `DialoguePreviewEnded`.
- `choose(i)` poursuit dans la branche sélectionnée.

### Mistral (`mistral_dialogue_client.dart`)

- POST JSON, lecture `choices[0].message.content`, erreurs explicites si HTTP ≠ 2xx ou JSON inattendu.

### UI (`dialogue_studio_workspace.dart`)

- **Colonne gauche** : wireframe « Bibliothèque des dialogues » (titres FR), boutons Nouveau / Dossier, recherche, liste, carte « Infos sélection ».
- **Centre** : onglets Visuel / Aperçu / Yarn ; barre IA + clé + instruction ; canvas par nœud ; barre « Ajouter : … ».
- **Droite** : inspecteur contextuel + liste validation.

### Sauvegarde (`SaveDialogueYarnBodyUseCase`)

- Résout le chemin via `ProjectWorkspace.resolveProjectRelativePath` et `File.writeAsString` — **manifest inchangé**.

### Cutscene (`cutscene_studio_workspace.dart`)

- Paramètre optionnel `onOpenDialogueStudio` pour ne pas casser d’autres contextes ; ici câblé depuis `narrative_workspace_canvas.dart`.

---

## 7. Tests ajoutés

- `dialogue_yarn_codec_test.dart` : stub projet, round-trip, conservation `<<set>>` / `<<if>>`.
- `dialogue_editor_validation_test.dart` : corps vide, saut inconnu.
- `dialogue_preview_runner_test.dart` : flux avec choix.

Commande :

```bash
cd packages/map_editor && flutter test test/dialogue_yarn_codec_test.dart test/dialogue_editor_validation_test.dart test/dialogue_preview_runner_test.dart
```

---

## 8. Pistes suivantes (non réalisées ici)

- Brancher `defaultStartNode` sur le preview et sur un badge « nœud d’entrée » dans l’inspecteur de fichier.
- Édition Yarn bidirectionnelle **contrôlée** (bouton « Appliquer » + garde-fous + diff).
- Stabiliser les champs inspecteur (contrôleurs persistants par `stepId`).
- Dupliquer dialogue (copie disque + entrée manifest).
- Partager le codec dans un petit package `map_dialogue` consommé par runtime + editor (si la dette duplication devient gênante).

---

## 9. Synthèse « vérité produit »

- **Branché** : studio visuel 3 colonnes, persistance `.yarn`, validation, preview simple, IA Mistral réelle (avec clé), lien depuis Cutscene.
- **Partiel** : Yarn = export affiché, pas éditable en retour ; preview sans `defaultStartNode` manifest.
- **Hors scope volontaire** : usine à gaz IA, provider générique, édition Yarn complète, duplication dialogue, refactor massif des autres studios.
