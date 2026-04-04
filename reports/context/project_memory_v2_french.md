# Mémoire Projet Pokémon-like Editor - Version 2 (Durable)

## 1. VISION PRODUIT

Le projet est un éditeur Flutter/Dart ambitieux visant à permettre la création de jeux Pokémon-like modernes.

**Vision finale** : Créer une sorte de RPG Maker Pokémon-like moderne, guidé, lisible, agréable, accessible, avec une UX très no-code.

**Objectif à long terme** : Permettre à quelqu'un de créer facilement un jeu Pokémon-like complet, sans devoir toucher du code ou du JSON à la main à chaque étape.

**Public cible** : Non seulement les développeurs expérimentés, mais aussi les créateurs non techniques. **Règle produit** : Ma mère devrait idéalement pouvoir comprendre le produit.

**Philosophie UX** :
- Lisible
- Hiérarchique  
- Intuitive
- Guidée
- Agréable
- Chaleureuse
- Très no-code
- Pensée aussi pour des personnes non techniques

## 2. ARCHITECTURE NARRATIVE FONDAMENTALE

Le système narratif repose sur 3 niveaux STRICTEMENT séparés :
1. **Global Story**
2. **Step** 
3. **Cutscene**

**Cette séparation est non négociable**. Elle doit rester visible :
- dans les données
- dans l'architecture
- dans l'UX
- dans les workflows
- dans le runtime

Si ces 3 niveaux se mélangent, le système devient confus.

### 2.1. GLOBAL STORY

**Responsabilité** : Progression globale du jeu (MACRO)

**Gère** :
- Chapitres / arcs
- Ordre global des steps
- Gros embranchements
- Convergences
- Point d'entrée global
- Transitions macro entre steps

**Ne gère PAS** :
- Dialogues détaillés
- Pathfinding
- Déplacements PNJ
- Caméra
- Waits
- Actions concrètes de scène
- Logique locale détaillée d'une step

**Règle métier absolue** : IL N'Y A QU'UN SEUL scénario global dans le jeu. Un seul Global Story principal.

### 2.2. STEP

**Responsabilité** : Unité de progression lisible (LOCAL)

**Gère** :
- Activation
- Validation
- Outcomes métier
- Outcomes de progression
- Cutscenes liées
- Changements persistants du monde
- Logique locale de progression

**Ne gère PAS** :
- Mise en scène détaillée (c'est la cutscene)
- Ne doit pas devenir une cutscene déguisée

### 2.3. CUTSCENE

**Responsabilité** : Mise en scène concrète (EXÉCUTION)

**Gère** :
- Dialogues
- Déplacements PNJ
- Pathfinding
- Caméra
- Animations
- Waits
- Choix joueur
- Transitions
- Signaux locaux
- Outcomes émis pendant la scène

## 3. STRUCTURE DU REPO

### 3.1. Packages Principaux
- `map_editor` - Éditeur principal
- `map_runtime` - Runtime de jeu
- `map_core` - Modèles de données partagés
- `map_gameplay` - Logique de gameplay pure Dart
- `map_battle` - Moteur de combat

### 3.2. Architecture Éditeur
- Workspaces centraux
- Navigation latérale
- Inspecteur contextuel
- Logique narrative
- Runtime de cutscene/scenario
- Systèmes de déplacements PNJ/pathfinding/mouvements scriptés

## 4. ÉTAT ACTUEL DES STUDIOS NARRATIFS

### 4.1. CUTSCENE STUDIO
**Historique** : Évolution significative d'une approche trop technique vers une approche no-code avec blocs métier.

**Fonctionnalités actuelles** :
- Blocs métier : dialogue, narration, moveCharacter, followCharacter, faceCharacter, transitionMap, starterChoice, wait, sceneResult
- Mode avancé : runScript pour compatibilité
- Runtime étendu pour gestion avancée des scènes

**Classes clés** : `CutsceneStudioWorkspace`, blocs de type `CutsceneBlock`

### 4.2. STEP STUDIO
**Responsabilités** : Logique locale des étapes de jeu

**Fonctionnalités** :
- Identité de la step
- Activation/Validation
- Cutscenes liées
- Résultats de progression
- Monde/Persistance

**Bug historique critique** : Boucle infinie dans `build()` avec `for` sans `index++` causant freeze et montée RAM à 183 Go. **Fix** : Remplacement par `.asMap().entries`.

**Classes clés** : `StepStudioDocument`, `StepStudioStep`, `StepStudioActivationRule`, `StepStudioCompletionRule`

### 4.3. GLOBAL STORY STUDIO
**Responsabilité** : Structure macro du jeu (mise en place des chapitres, ordonnancement des steps)

**Historique** : Initialement trop similaire au Step Studio, puis refonte UX avec introduction des chapitres et structure hiérarchique.

**Fonctionnalités actuelles** :
- Chapitres visibles
- Steps compactes
- Lecture top-down
- Gestion des embranchements et convergences

**Classes clés** : `GlobalStoryStudioWorkspace`, `GlobalStoryStudioDocument`, `GlobalStoryChapter`, `GlobalStoryStepNode`, `GlobalStoryStepExitMode`

## 5. DOCUMENTS D'AUTORING

### 5.1. GlobalStoryStudioDocument
Structure macro pour la progression globale :
```dart
class GlobalStoryStudioDocument {
  final String globalStoryScenarioId;
  final String entryStepId;
  final List<GlobalStoryChapter> chapters;
  final List<GlobalStoryStepNode> nodes;
}
```

### 5.2. StepStudioDocument
Structure locale pour les étapes :
```dart
class StepStudioDocument {
  final String globalStoryScenarioId;
  final List<StepStudioStep> steps;
}
```

### 5.3. GlobalStoryChapter
Organisation hiérarchique :
```dart
class GlobalStoryChapter {
  final String id;
  final String name;
  final List<String> stepIds; // Référence aux steps par ID
}
```

## 6. OUTCOMES SYSTEM

### 6.1. Types d'Outcomes
- **Locaux** : starter.selected.fire, professor_intro.accepted, rival.arrived
- **Globaux/Progression** : chapter_1.starter_chosen, badge_1.obtained

### 6.2. Philosophie
Génération depuis labels humains + scope clair plutôt que saisie manuelle d'IDs techniques.

## 7. PROBLÈMES UX IDENTIFIÉS

### 7.1. Bouton "Insérer" - Problème Historique
**Contexte** : Dans l'UI du Global Story Studio, le bouton "Insérer" avait un comportement ambigu.

**Comportement initial** : Clic directement sur "Insérer" ajoutait une nouvelle step sans choix explicite pour l'utilisateur.

**Problème** : L'utilisateur s'attendait à un choix entre "Nouvelle step" et "Insérer une step existante".

**Solution actuelle** : Le système a évolué pour proposer deux actions distinctes :
- "Nouvelle" (New) - crée une nouvelle step
- "Insérer" (Insert) - permet de sélectionner une step existante à insérer

## 8. DÉCISIONS NON NÉGOCIABLES

1. **Un seul Global Story** : Jamais plusieurs arbres globaux concurrents
2. **Séparation stricte** : Global Story ≠ Step ≠ Cutscene
3. **No-code prioritaire** : Toujours préférer les interfaces guidées aux saisies techniques
4. **Persistance intelligente** : Les changements monde doivent être déclaratifs
5. **Hiérarchie claire** : Global → Local → Exécution

## 9. POINTS D'ATTENTION POUR FUTURE CONTINUATION

### 9.1. Points de Confusion Fréquents
- Global Story ne gère pas les détails de scene (c'est la cutscene)
- Step Studio ne gère pas la mise en scène (c'est la cutscene)
- Les pathfinding appartiennent à la cutscene, pas au Global Story

### 9.2. Bugs Historiques Importants
- **Step Studio** : Boucle infinie dans `build()` avec `for` sans `index++`
- **Performance** : Montée RAM excessive lors de boucles non sécurisées
- **Fix standard** : Utiliser `.asMap().entries` pour les itérations dans `build()`

### 9.3. Erreurs de Concept Communes
- Confondre Global Story (macro) avec Step (local)
- Tenter de configurer des détails de scène dans Global Story
- Mélanger les responsabilités entre les 3 couches

## 10. PHILOSOPHIE NO-CODE

### 10.1. Éléments à Maximiser
- Dropdowns
- Pickers
- Menus
- Listes
- Actions explicites
- Libellés métier compréhensibles
- Interfaces adaptées au niveau de responsabilité

### 10.2. Éléments à Minimiser
- IDs saisis à la main
- JSON saisis à la main
- Formulaires trop techniques
- Popups système moches
- Alertes pauvres avec juste des boutons
- Écrans froids type back-office administratif
- Surfaces demandant de comprendre la structure interne du moteur

## 11. FICHIERS CLÉS À CONNAÎTRE

### 11.1. Global Story Studio
- `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart`
- Contient `_createNewStepAfter()` et `_insertExistingStepAfter()`

### 11.2. Step Studio
- `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart`
- Contient la logique de gestion des étapes locales

### 11.3. Cutscene Studio
- `packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart`
- Contient les blocs de script et la logique d'exécution

### 11.4. Modèles de Données
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/narrative_models.dart`

## 12. EXEMPLE DE RÉFÉRENCE : CHOIX DU STARTER

```
GLOBAL STORY
├─ Chapter: "Début"
│  └─ Step: "Choisir son starter"
│     └─ Cutscene: "starter_selection"
│        ├─ Intro professeur
│        ├─ Choix : feu/eau/plante
│        ├─ Branche feu → starter.selected.fire
│        ├─ Branche eau → starter.selected.water
│        ├─ Branche plante → starter.selected.grass
│        └─ Bloc final → starter donné + chapter_1.starter_chosen
```

## 13. TYPES DE BRANCHES SUPPORTÉS

- **Exclusives** : Une seule route parmi plusieurs
- **Parallèles** : Plusieurs arcs avançant en parallèle
- **Conditionnelles** : Branche s'ouvre selon condition
- **Convergentes** : Plusieurs routes reviennent vers même point

**Importance des convergences** : Essentielles pour éviter l'explosion incontrôlée de l'histoire.

## 14. PATTERNS D'IMPLÉMENTATION IMPORTANTES

### 14.1. Pattern de Documents Complémentaires
Le Global Story Studio gère deux documents complémentaires :
1. `StepStudioDocument` (identité + ordre des steps)
2. `GlobalStoryStudioDocument` (liens macro entre steps)

### 14.2. Pattern de Normalisation
- `normalizeGlobalStoryStudioDocument()` pour maintenir la cohérence
- `parseGlobalStoryStudioDocumentFromGlobalScenario()` pour la lecture
- `applyGlobalStoryStudioDocumentToGlobalScenario()` pour l'écriture

### 14.3. Pattern de Sélection Différée
Utilisation de `WidgetsBinding.instance.addPostFrameCallback()` pour gérer les sélections sans conflit avec le cycle de build.

## 15. GUIDELINES DE DÉVELOPPEMENT

### 15.1. Pour les Futures Évolutions
- Maintenir la séparation stricte des 3 couches
- Préférer les interfaces guidées aux formulaires techniques
- Assurer la cohérence des comportements entre les studios
- Documenter les décisions architecturales dans des fichiers dédiés

### 15.2. Pour les Corrections de Bug
- Toujours vérifier l'impact sur les 3 couches narratives
- Tester la performance avec des projets volumineux
- Préférer les itérations sûres (`.asMap().entries`) dans les méthodes `build()`

### 15.3. Pour les Nouvelles Fonctionnalités
- S'assurer qu'elles sont positionnées au bon niveau (Global/Step/Cutscene)
- Maintenir la philosophie no-code
- Présenter les fonctionnalités avec des libellés métier clairs
- Éviter d'ajouter des capacités qui mélangent les responsabilités

## 16. DOCUMENTATION DE RÉFÉRENCE À MAINTENIR

Ce document doit être mis à jour à chaque décision architecturale importante, chaque bug critique découvert, chaque évolution significative de l'UX, ou chaque clarification conceptuelle.

**Dernière mise à jour** : 4 avril 2026
**Version** : V2 (Durable)
**Responsable** : Mémoire projet Pokémon-like Editor