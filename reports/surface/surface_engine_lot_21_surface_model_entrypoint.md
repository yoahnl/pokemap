# Lot 21 — Surface Model Entrypoint V0

**Date (rédaction)** : 2026-04-26  
**Objectif** : introduire le premier fichier modèle `surface.dart` dans `map_core` avec un enum minimal [`SurfaceAtlasLayout`], **sans** modifier `ProjectManifest` ni générer de JSON/Freezed.

---

## 1. Résumé exécutif

- Ajout de `packages/map_core/lib/src/models/surface.dart` contenant **uniquement** l’enum `SurfaceAtlasLayout` (`grid`, `columnsAreVariantsRowsAreFrames`, `rowsAreVariantsColumnsAreFrames`) avec documentation.
- Export public via `export 'src/models/surface.dart';` dans `map_core.dart`.
- Trois tests de garde : ordre de l’enum, absence (dans le JSON manifest courant) des clés Surface futures, et non-régression `ProjectPathPreset` minimal.
- Aucun `build_runner`, aucun `.g.dart` / `.freezed.dart` nouveau, `ProjectManifest` **non** modifié.
- Analyse ciblée : **No issues found!**  
- Tests : cible `+3`, suite complète `+527` **All tests passed!**

---

## 2. Pourquoi ce lot vient après le Lot 20

Le Lot 20 a clos la phase **P0.5** (bridge vertical-atlas + wrappers) et a recommandé de ne plus multiplier les one-liners legacy. Le Lot 21 ouvre la **phase modèle** avec un point d’entrée **inoffensif** : un vocabulaire d’atlas partagé, sans accrochage persistant, pour ne pas bousculer le contrat `ProjectManifest` avant que les lots suivants ne le cadrer.

---

## 3. Fichiers consultés (audit)

- `packages/map_core/lib/map_core.dart` — zone d’exports.
- `packages/map_core/lib/src/models/project_manifest.dart` — vérification qu’aucun champ Surface n’existe encore (confirmé) ; rappel : Freezed/JSON ailleurs, **hors** périmètre de modification Lot 21.
- `packages/map_core/lib/src/models/enums.dart`, `tileset.dart`, `map_layer.dart`, `visual_frame_json.dart` contexte.
- `reports/surface/surface_engine_lot_20_legacy_vertical_atlas_bridge_consolidation.md`.
- `surface project/pokemap_surface_engine_micro_lots.md` (présent) — alignement P1.01.
- `surface project/pokemap_surface_engine_spec.md` (présent).

---

## 4. Fichiers créés

| Fichier | Rôle |
|---------|------|
| `packages/map_core/lib/src/models/surface.dart` | Enum `SurfaceAtlasLayout` |
| `packages/map_core/test/surface_model_entrypoint_test.dart` | Tests d’accès public + garde-fous |
| `reports/surface/surface_engine_lot_21_surface_model_entrypoint.md` | Ce rapport |

---

## 5. Fichier modifié

| Fichier | Modification |
|---------|--------------|
| `packages/map_core/lib/map_core.dart` | `+1` ligne d’`export` |

---

## 6. API ajoutée

- **`enum SurfaceAtlasLayout`**

---

## 7. Explication des valeurs de `SurfaceAtlasLayout`

| Valeur | Rôle documenté |
|--------|-----------------|
| `grid` | Atlas en grille classique, sans imposer l’alignement variante/animation sur un axe. |
| `columnsAreVariantsRowsAreFrames` | **Colonnes = variantes**, **lignes = frames** — correspond au bridge lots **11–19** (vertical atlas : `x` = variante, `y` = frame). |
| `rowsAreVariantsColumnsAreFrames` | **Miroir** : lignes = variantes, colonnes = frames, pour ne pas cristalliser une seule orientation. |

**Choix** : **pas** de `@JsonValue` / `json_annotation` ici. Les valeurs stables en `snake_case` pour le JSON (si besoin) seront mieux gérées **avec** le lot qui introduit la sérialisation `Surface*`, pour éviter de suggérer une semantique JSON **sans** codegen autorisé ni contract tests manifest.

---

## 8. Ce qui a été testé

- Ordre et contenu de `SurfaceAtlasLayout.values`.
- `ProjectManifest.toJson()` : absence des clés **de premier niveau** `surfaceDefinitions`, `surfaceAtlases`, `surfaceAnimations`, `surfacePresets`, `surfaceCategories` (vérification sur la `Map` — import de test limité à `map_core` + `test`, sans `dart:convert`).
- Construction d’un `ProjectPathPreset` minimal (API toujours accessible).

---

## 9. Ce que les tests prouvent

- L’**export** `package:map_core/map_core.dart` réexporte `SurfaceAtlasLayout` correctement.
- Le **lot n’a pas ajouté** de champs Surface sur le `ProjectManifest` (aucune de ces clés **au sommet** de `toJson()` aujourd’hui).
- **Aucun break** sur le type legacy `ProjectPathPreset` pour un scénario minimal.

---

## 10. Ce qui n’a volontairement pas été fait

- Pas de `SurfaceDefinition`, `ProjectSurface*`, `SurfaceLayer`.
- Pas de changement de `MapData`, `MapLayer` structurelle.
- Pas de `build_runner` / part files / générés.
- Pas de modification des opérations vertical-atlas, ni des wrappers eau/lave/glace/herbes.
- Pas de `map_runtime` / `map_editor` / `map_gameplay` / `map_battle`.

---

## 11. Pourquoi `ProjectManifest` n’a pas été modifié

- Le prochain vrai **contrat** persistant (listes, IDs, liens) doit être **spécifié** en lot dédié ; l’injection d’un seul field mal nommé forcerait une migration / compat JSON prématurée.
- Ici, seul un **énum côté Dart** sert d’**ancre** sémantique partagée.

---

## 12. Pourquoi aucun fichier generated n’a été créé

- Contrainte explicite du lot ; l’**enum** n’a **pas** besoin de Freezed. Les champs `ProjectManifest` futurs s’adosseront à un **plan de sérialisation** unifié (probablement avec codegen **au moment voulu**).

---

## 13. Impact pour les prochains lots Surface

- Les lots peuvent se référer à un **vocabulaire d’atlas** sans dépendre de `PathSurfaceKind` pour décrire la **géométrie** d’un pack de tuiles.
- `columnsAreVariantsRowsAreFrames` relie explicitement l’héritage P0.5 au futur modèle.
- Prochaine étape logique (hors petit 21) : champs de manifest, schéma JSON, ou DTOs Freezed **quand** le lot l’imposera.

---

## 14. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_model_entrypoint_test.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze \
  lib/src/models/surface.dart \
  test/surface_model_entrypoint_test.dart \
  lib/map_core.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```

---

## 15. Résultats exacts (tests ciblés)

```text
00:00 +0: ... loading ...
00:00 +1: ... SurfaceAtlasLayout.values exposes exactly ...
00:00 +2: ... ProjectManifest JSON has no surface engine manifest keys yet
00:00 +3: ... ProjectPathPreset construction remains available unchanged
00:00 +3: All tests passed!
```

**Exit code** : 0

---

## 16. Résultats exacts (analyse ciblée)

```text
Analyzing surface.dart, surface_model_entrypoint_test.dart, map_core.dart...
No issues found!
```

**Exit code** : 0

---

## 17. Total exact — `dart test` complet (map_core)

```text
... +527: All tests passed!
```

**Exit code** : 0

*(Avant ce lot, la dernière suite notée côté Lot 20 / consolidation était +524 : **+3** comptes ici = les 3 tests du Lot 21.)*

---

## 18. Points de vigilance

- La **garantie d’absence** de champs dans le **JSON** repose sur `ProjectManifest` actuel : si un autre outil **injecte** des clés `surface*` ailleurs, ce test ne couvre **pas** ce flux.
- L’**ordre** de déclaration de l’enum est contractuel pour le test (et pour tout `index` en sérialisation future) : le premier lot de sérialisation devra s’y référer explicitement.
- `grid` n’établit **pas** de lien automatique vers autotile path — c’est voulu.

---

## 19. Autocritique finale

- Le rapport s’appuie sur l’**état** du dépôt au moment de l’exécution.
- Aucun **git write** n’a été utilisé (conformité prompt Lot 21).

---

## 20. Ce que le prompt semble discutable ou incomplet

- **Emplacement** de l’`export` : le texte ne fixe pas d’**ordre strict** (alphabétique vs. clustering `project_manifest`) ; l’export a été placé **après** `visual_frame_json`, avant les `operations/`.
- **@JsonValue** : utilisable sans générer *ce* fichier, mais conduirait visuellement vers une couche JSON **sans** règles d’enregistrement côté `ProjectManifest` — volontairement repoussé.
- Compteur **+527** : dépend de l’**historique** de la suite ; toute branche parallèle peut diverger légèrement.

---

## 21. Auto-review indépendante (réponses explicites)

| Question | Réponse |
|----------|---------|
| Lot strictement limité au modèle entrypoint + test + report + export ? | **Oui** |
| Seuls `surface.dart`, test, rapport, `map_core` modifié ? | **Oui** (rapport sous `reports/surface/`) |
| Aucun `ProjectManifest` modifié ? | **Oui** |
| Aucun Freezed/JSON généré créé ? | **Oui** |
| Aucun `.g.dart` / `.freezed.dart` ajouté ? | **Oui** |
| Aucun runtime / editor / gameplay / battle modifié ? | **Oui** |
| `SurfaceAtlasLayout` a exactement 3 cas dans l’ordre requis ? | **Oui** (test) |
| Export public `map_core` OK ? | **Oui** (import unique du test) |
| Tests prouvent absence (pour l’instant) de clés surface dans `toJson()` ? | **Oui** (clés explicites listées) |
| Suite complète `map_core` verte avec total +527 ? | **Oui** |
| Contenu/diff : voir remise de lot / workspace | **Fourni par l’agent** |
| Commandes git interdites non utilisées ? | **Oui** |
| Rapport honnête sur limites ? | **Oui** (§18) |

---

## 22. Contenu intégral des fichiers créés/modifiés (référence)

Voir livrable dans l’arbre : `packages/map_core/lib/src/models/surface.dart`, `test/surface_model_entrypoint_test.dart`, `reports/surface/surface_engine_lot_21_surface_model_entrypoint.md`, et la ligne d’`export` dans `map_core.dart`.

## 23. Diff complet (fichiers suivis + nouveaux)

Les fichiers **non suivis** n’apparaissent **pas** dans `git diff` ; le diff des nouveaux fichiers = **ajout intégral** (équivalent `diff -u /dev/null <fichier>`).

*Fin du rapport Lot 21.*
