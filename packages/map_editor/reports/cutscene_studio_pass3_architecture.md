# Cutscene Studio — Passe 3 : architecture modulaire + mémoire `.cursor/`

Rapport d’ingénierie (PokeMap / `map_editor`). Aucune opération Git d’écriture dans le cadre de cette passe.

---

## 1. Pourquoi la passe 3 existait

La passe 2 avait corrigé l’**honnêteté runtime** (`flowMerge`, `authoringPlaceholder`, advisories, tests) mais **`cutscene_studio_authoring.dart` restait un monolithe** (~2300 lignes), difficile à naviguer et risqué pour les prochaines itérations (retour des mêmes erreurs : mélange UI/domaine, scope qui dérape, hacks silencieux).

La passe 3 avait pour but **strict** : **découpage physique**, **barrel léger**, **capitalisation** dans `.cursor/`, **sans** refonte produit ni chantier transversal.

---

## 2. Ce qui restait « sale » avant cette passe

- Un seul fichier concentrait : constantes, modèles, flow, codec JSON, mutations, parse, compile, templates, documentation implicite.
- Les **helpers** `_trimOrNull` / `_normalizeNodeId` étaient **privés au fichier** : tout découpage en librairies séparées aurait exigé des **API publiques explicites** (`cutsceneStudioTrimOrNull`, `cutsceneStudioNormalizeNodeId`, etc.).
- `cutscene_studio_runtime_advisories.dart` vivait à côté du monolithe au lieu d’être **cohérent** avec le dossier module.

---

## 3. Découpage physique réalisé

Nouveau répertoire :

`packages/map_editor/lib/src/features/narrative/application/cutscene_studio/`

| Fichier | Contenu extrait du monolithe |
|---------|------------------------------|
| `cutscene_studio_models.dart` | Constantes, enums, labels, source, bloc, entrées de flow, égalité de flow, document, parse result, trim/outcome/nomalize publics. |
| `cutscene_studio_flow.dart` | `flattenMainTrunkFlowToBlocks`, `cutsceneLinearFlowFromBlocks`, `effectiveCutsceneFlowForDocument`. |
| `cutscene_studio_flow_codec.dart` | JSON blocs + entrées + encode/decode metadata. |
| `cutscene_studio_flow_mutations.dart` | Recherche, remplacement, suppression, insert/move tronc, insert branche. |
| `cutscene_studio_parser.dart` | `parseScenarioToCutsceneStudioDocument` + helpers de graphe / bloc. |
| `cutscene_studio_compiler.dart` | `buildScenarioFromCutsceneStudioDocument`, compilateur graphe, builders de nœuds. |
| `cutscene_studio_templates.dart` | Templates + démo flow. |
| `cutscene_studio_runtime_advisories.dart` | `cutsceneStudioRuntimeAdvisories`. |
| `cutscene_studio_authoring.dart` | **Barrel** : `export` uniquement. |

**Shims de compatibilité** (imports historiques inchangés pour le reste du code) :

- `application/cutscene_studio_authoring.dart` → `export 'cutscene_studio/cutscene_studio_authoring.dart';`
- `application/cutscene_studio_runtime_advisories.dart` → `export 'cutscene_studio/cutscene_studio_runtime_advisories.dart';`

---

## 4. Nouveaux fichiers créés

- Tous les fichiers du dossier `cutscene_studio/` listés ci-dessus.
- Racine **`.cursor/`** avec 7 fichiers markdown (voir §9–10).

---

## 5. Responsabilité de chaque fichier (rappel opérationnel)

- **Models** : vérité métier et types ; **trim / normalize / outcome** centralisés pour parser + compiler sans cycle avec `flow.dart`.
- **Flow** : dérivation « ce que le studio utilise » à partir du document (tronc vs arbre).
- **Codec** : contrat JSON metadata ; aucune logique compile.
- **Mutations** : transformations pures pour DnD / inspecteur.
- **Parser** : lecture graphe + metadata ; honnêteté sur le linéaire vs branches sans JSON.
- **Compiler** : écriture graphe + metadata ; `flowMerge` / placeholders explicites.
- **Templates** : seeds produit.
- **Advisories** : texte pour bandeau MVP.
- **Barrel** : point d’entrée unique pour l’app et les tests.

---

## 6. Source de vérité (inchangée fonctionnellement)

- **`cutsceneFlow`** canonique si renseigné et non vide.
- **`blocks`** = projection tronc ; synchronisée par le workspace lors des commits de flow.
- **Legacy** : pas de `cutsceneFlow` → linéarisation depuis `blocks` via `effectiveCutsceneFlowForDocument`.

La documentation sur `CutsceneStudioDocument` est conservée dans **models**.

---

## 7. Imports rationalisés

- **UI / tests** : continuer d’importer `cutscene_studio_authoring.dart` (racine `application/`) pour tout le domaine public.
- **Interne module** : imports relatifs `cutscene_studio_*.dart` **dans le même dossier** uniquement.
- **Workspace** : import redondant `cutscene_studio_runtime_advisories.dart` supprimé (tout exporté par le barrel).
- **Tests** : un seul import package vers le barrel.

**Graphe de dépendance interne** (sans cycle) :

`models` ← `flow`, `codec`, `mutations`, `templates`, `parser`, `compiler`, `advisories` ; `flow` ← `templates`, `parser`, `compiler`, `advisories` ; `codec` ← `parser`, `compiler`.

---

## 8. Laissé volontairement inchangé

- **Paradigme UI** Cutscene (palette / flow / inspecteur).
- **Global Story Studio**, Step Studio, shell, layout global.
- **Contrats runtime** `map_runtime` (passe 2).
- **Comportement** parse/compile/advisories : validé par `flutter test test/cutscene_studio_authoring_test.dart`.

---

## 9. Conception du dossier `.cursor/`

Emplacement : **racine du dépôt** `pokemonProject/.cursor/`.

Objectif : **mémoire durable** pour aligner futures interventions sur :

- vision produit no-code ;
- architecture (pas de fichiers décharge) ;
- scope discipliné ;
- honnêteté runtime / placeholders ;
- règles de génération de code et rapports.

---

## 10. Contenu de chaque fichier `.cursor/`

| Fichier | Contenu |
|---------|---------|
| `README.md` | Rôle du dossier, table des matières, lien avec le code. |
| `project_vision.md` | PokeMap comme outil de création de jeu, pas « éditeur de maps » seul. |
| `clean_architecture_rules.md` | Responsabilités, fichiers, pureté, SoT, legacy, honnêteté, référence au dossier `cutscene_studio/`. |
| `cutscene_studio_rules.md` | Paradigme UI figé, SoT flow/blocks, table fichier↔rôle, évolution disciplinée. |
| `ui_ux_rules.md` | Gauche/centre/droite, interdits, desktop. |
| `scope_rules.md` | Pas d’élargissement gratuit, pas de Git par défaut, rapports `reports/`. |
| `code_generation_rules.md` | Commentaires, rapports, tests ciblés, pas de fichiers parasites. |

---

## 11. Comment guider les prochaines interventions

1. Lire **scope** + **architecture** + **cutscene_studio_rules** avant toute évolution narrative.
2. Toucher **uniquement** `application/cutscene_studio/` (+ shims si nécessaire) pour le domaine Cutscene.
3. Si un sous-fichier grossit encore : **scinder** (ex. extraire `cutscene_studio_outcomes.dart`) plutôt que regonfler `models` ou `compiler`.
4. Documenter les compromis dans **commentaires** + **rapport** si la passe est structurante.

---

## 12. Risques résiduels

- **`cutscene_studio_models.dart`** reste le plus gros fichier du module (~760 lignes) : acceptable pour un agrégat de types, mais à surveiller si de nombreux kinds ou champs s’ajoutent.
- **Barrel** réexporte tout : risque de **conflits de noms** si deux sous-modules exportent le même symbole (peu probable aujourd’hui).
- **Helpers publics** (`cutsceneStudioTrimOrNull`, etc.) : surface API plus large ; éviter leur usage hors module sauf nécessité.

---

## 13. Prochaines étapes possibles

1. Extraire un fichier **`cutscene_studio_outcomes.dart`** si `models` grossit encore (outcome + trim y sont regroupés pour éviter les cycles).
2. Tests unitaires **ciblés** sur une mutation ou un round-trip codec isolé (optionnel, faible priorité).
3. Mettre à jour **`AGENTS.md`** racine avec un lien vers `.cursor/` (hors scope strict de cette passe si non demandé).

---

*Fin du rapport — Passe 3 architecture Cutscene Studio + `.cursor/`.*
