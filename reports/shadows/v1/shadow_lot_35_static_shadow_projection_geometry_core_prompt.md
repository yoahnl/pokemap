# Shadow-35 — Static Shadow Projection Geometry Core V0

Tu travailles dans le repo local :

```text
/Users/karim/Project/pokemonProject
```

## Préambule du Samouraï des Ombres Portées

Tu vas exécuter le **Lot Shadow-35**, avec la précision d’un samouraï vendéen qui refuse qu’un lampadaire projette une galette de crêpe molle au lieu d’une vraie ombre lisible.

Les lots précédents ont rendu les ombres configurables.

Le problème restant n’est plus seulement l’authoring.

Le problème est géométrique :

```text
Une ellipse ne peut pas ressembler à une ombre portée de bâtiment.
Une ellipse ne peut pas donner une vraie direction de lumière.
Une ellipse ne peut pas transformer un lampadaire en silhouette crédible.
```

Shadow-35 pose la première brique : une géométrie pure de projection polygonale dans `map_core`.

Ce lot ne doit pas encore modifier le runtime.

Ce lot ne doit pas encore modifier l’éditeur.

Ce lot ne doit pas encore changer visuellement le jeu.

Ce lot doit seulement créer une opération pure et testée qui pourra ensuite être consommée par le runtime et la preview editor.

---

# CONTRAT DE LIVRAISON — À LIRE AVANT TOUT

Ce lot ne sera considéré comme terminé que si le rapport final contient un **Evidence Pack complet, honnête et vérifiable**.

Tu dois impérativement distinguer :

```text
- fichiers déjà présents/modifiés avant Shadow-35 ;
- fichiers créés/modifiés par Shadow-35 ;
- fichiers non suivis préexistants hors lot ;
- dettes préexistantes hors lot ;
- problèmes réellement introduits par Shadow-35.
```

Formulations interdites pour remplacer une preuve attendue :

```text
voir le dépôt
voir le worktree
relancer git diff
diff disponible dans git
contenu non reproduit
contenu tronqué
trop long pour être inclus
artefact externe
journal de tâche
à lire sur la machine
hors de ce fichier pour limiter la taille
```

Pour les tests ciblés, tu dois fournir la sortie complète utile.

Pour les tests globaux longs, tu dois fournir au minimum :

```text
- commande exacte ;
- résultat final exact ;
- ligne finale exacte du type +XXX: All tests passed!
```

Si un test global échoue, tu dois fournir l’échec complet utile et expliquer précisément si c’est une dette préexistante ou une régression du lot.

Tu ne dois faire aucun commit.

Commandes interdites :

```bash
git add
git commit
git push
git reset
git checkout
git restore
git stash
git merge
git rebase
git tag
```

Commandes Git autorisées uniquement en lecture :

```bash
git status --short --untracked-files=all
git diff
git diff --stat
git diff --check
git diff --name-status
git log
git show
```

N’ajoute pas de commentaires dans le code.

Les rapports Markdown peuvent être détaillés, mais le code doit rester sans commentaires ajoutés.

---

# 0. Design gate AGENTS.md

Avant toute implémentation :

1. Lis les `AGENTS.md` applicables.
2. Si `AGENTS.md` impose une étape design avant ce type de lot core / geometry, tu dois t’arrêter après le design.
3. Dans ce cas, ne modifie aucun fichier de production et fournis uniquement le design proposé.
4. Si `AGENTS.md` autorise l’implémentation directe, exécute le lot.

Ce lot touche uniquement `map_core`, avec de la géométrie pure.

Respecte strictement le workflow du repo.

---

# 1. Contexte

Les lots récents ont posé :

```text
Shadow-27 — Static Shadow Footprint Value Object / JSON V0
Shadow-28 — Static Shadow Footprint Merge / Geometry Core V0
Shadow-29 — Runtime Static Shadow Geometry Integration V0
Shadow-30 — Editor Static Shadow Preview Geometry Integration V0
Shadow-31 — Element Shadow Footprint UI V0
Shadow-32 — Instance Shadow Footprint Override UI V0
Shadow-33 — Shadow Light Preview / Auto Authoring Decision V0
Shadow-34 — Editor Shadow Light Preview V0
```

État actuel :

```text
map_core :
- StaticShadowFootprintConfig existe ;
- resolveStaticShadowGeometry(...) existe ;
- la géométrie actuelle produit une ellipse rectangulaire finale.

map_runtime :
- le renderer Shadow dessine via Canvas.drawOval(...) ;
- les static shadows runtime consomment resolveStaticShadowGeometry(...).

map_editor :
- la preview canvas consomme resolveStaticShadowGeometry(...) ;
- la preview lumière editor-only existe ;
- le painter Shadow dessine encore via Canvas.drawOval(...).
```

Problème :

```text
Les ombres statiques restent des ovales.
Même bien placés, ces ovales ne ressemblent pas à la référence utilisateur.
```

Référence visuelle attendue :

```text
- bâtiments : ombres portées larges, plates, directionnelles ;
- lampadaires : ombres fines, attachées au pied ;
- panneaux / puits / stands : ombres locales et proportionnées ;
- PNJ / joueur : contact shadow actuel conservé.
```

---

# 2. Mission Shadow-35

Tu dois exécuter uniquement :

```text
Shadow-35 — Static Shadow Projection Geometry Core V0
```

Objectif :

```text
Créer dans map_core une opération pure qui transforme une géométrie statique résolue
en quadrilatère d’ombre portée directionnelle.
```

Cette opération doit préparer :

```text
Shadow-36 — Runtime Projected Shadow Instruction / Renderer V0
Shadow-37 — Runtime Static Object Projection Integration V0
Shadow-38 — Editor Static Projected Shadow Preview V0
```

Mantra :

```text
Shadow-28 donne l’empreinte au sol.
Shadow-35 projette cette empreinte dans une direction.
Shadow-36/37/38 la rendront visible.
```

---

# 3. Périmètre autorisé

Tu peux créer :

```text
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
reports/shadows/shadow_lot_35_static_shadow_projection_geometry_core.md
```

Tu peux modifier :

```text
packages/map_core/lib/map_core.dart
```

Tu peux lire / auditer :

```text
packages/map_core/lib/src/operations/static_shadow_geometry.dart
packages/map_core/test/shadow/static_shadow_geometry_test.dart
reports/shadows/shadow_projected_static_shadows_plan.md
reports/shadows/shadow_lot_28_static_shadow_footprint_merge_geometry_core.md
reports/shadows/shadow_lot_33_shadow_light_preview_auto_authoring_decision.md
reports/shadows/shadow_lot_34_editor_shadow_light_preview.md
```

---

# 4. Périmètre interdit

Tu ne dois PAS modifier :

```text
packages/map_runtime/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
```

Tu ne dois PAS modifier les modèles persistants :

```text
packages/map_core/lib/src/models/**
```

Tu ne dois PAS modifier les codecs JSON :

```text
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
```

Tu ne dois PAS lancer :

```text
build_runner
```

Tu ne dois PAS créer :

```text
Shadow Studio
UI footprint
runtime integration
editor preview integration
direction globale persistante
time-of-day
WorldLightState
ShadowLightProfile
LightDirection persistent model
blur
saveLayer
ImageFilter
shadow sprite
shadow atlas
zOrder
zIndex
migration JSON
nouveau Flame Component
```

Ce lot ne doit produire aucune feature visible.

---

# 5. Design attendu

## 5.1 API core pure

Créer dans :

```text
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
```

des classes pures sans Flutter :

```dart
final class ProjectedStaticShadowPoint {
  ProjectedStaticShadowPoint({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;
}
```

```dart
final class StaticShadowProjectionSpec {
  StaticShadowProjectionSpec({
    required this.directionX,
    required this.directionY,
    required this.lengthRatio,
    required this.nearWidthMultiplier,
    required this.farWidthMultiplier,
  });

  final double directionX;
  final double directionY;
  final double lengthRatio;
  final double nearWidthMultiplier;
  final double farWidthMultiplier;
}
```

```dart
final class ProjectedStaticShadowGeometry {
  ProjectedStaticShadowGeometry({
    required this.nearLeft,
    required this.nearRight,
    required this.farRight,
    required this.farLeft,
  });

  final ProjectedStaticShadowPoint nearLeft;
  final ProjectedStaticShadowPoint nearRight;
  final ProjectedStaticShadowPoint farRight;
  final ProjectedStaticShadowPoint farLeft;

  List<ProjectedStaticShadowPoint> get points;
}
```

Fonction :

```dart
ProjectedStaticShadowGeometry resolveProjectedStaticShadowGeometry({
  required ResolvedStaticShadowGeometry baseGeometry,
  required StaticShadowVisualMetrics metrics,
  StaticShadowProjectionSpec projectionSpec =
      defaultStaticShadowProjectionSpec,
});
```

Constante :

```dart
const defaultStaticShadowProjectionDirectionX = 1.0;
const defaultStaticShadowProjectionDirectionY = 0.45;
const defaultStaticShadowProjectionLengthRatio = 0.32;
const defaultStaticShadowProjectionNearWidthMultiplier = 0.92;
const defaultStaticShadowProjectionFarWidthMultiplier = 1.18;
```

Tu peux ajuster légèrement les noms si le style existant l’exige, mais garde l’intention.

## 5.2 Formule géométrique V0

Entrées :

```text
baseGeometry.centerX
baseGeometry.centerY
baseGeometry.width
baseGeometry.height
metrics.visualHeight
projectionSpec.directionX / directionY
projectionSpec.lengthRatio
projectionSpec.nearWidthMultiplier
projectionSpec.farWidthMultiplier
```

Formule :

```text
directionLength = sqrt(directionX^2 + directionY^2)
dirX = directionX / directionLength
dirY = directionY / directionLength

perpX = -dirY
perpY = dirX

projectionLength = metrics.visualHeight * lengthRatio

nearCenterX = baseGeometry.centerX
nearCenterY = baseGeometry.centerY

farCenterX = nearCenterX + dirX * projectionLength
farCenterY = nearCenterY + dirY * projectionLength

nearWidth = baseGeometry.width * nearWidthMultiplier
farWidth = baseGeometry.width * farWidthMultiplier

nearLeft  = nearCenter - perp * nearWidth / 2
nearRight = nearCenter + perp * nearWidth / 2
farRight  = farCenter + perp * farWidth / 2
farLeft   = farCenter - perp * farWidth / 2
```

Important :

```text
baseGeometry.height n’est pas utilisé pour la largeur du polygon.
Il reste une propriété de la géométrie ellipse existante.
La projection doit surtout dépendre de l’emprise au sol et de la hauteur visuelle.
```

Pourquoi `metrics.visualHeight` :

```text
Un objet haut doit pouvoir projeter plus loin qu’un objet bas.
Un lampadaire haut projette une ombre plus longue, mais fine si son footprint est fin.
Une maison projette une ombre large grâce à son footprint, pas à cause de toute sa hauteur.
```

## 5.3 Validation

`ProjectedStaticShadowPoint` :

```text
x finite
y finite
```

`StaticShadowProjectionSpec` :

```text
directionX finite
directionY finite
direction non nulle
lengthRatio finite > 0
nearWidthMultiplier finite > 0
farWidthMultiplier finite > 0
```

`ProjectedStaticShadowGeometry` :

```text
les 4 points non-null ;
les 4 points finite ;
surface polygonale non nulle.
```

Tu peux vérifier la surface via shoelace formula.

`resolveProjectedStaticShadowGeometry(...)` :

```text
ne filtre pas mode/renderPass ;
ne décide pas si une ombre doit être rendue ;
ne touche pas opacity/couleur ;
ne modifie pas la géométrie d’origine ;
ne dépend pas de Flutter.
```

## 5.4 Égalité

Les trois classes doivent avoir :

```text
operator ==
hashCode
```

À tester.

---

# 6. Cas métier attendus

```text
Base geometry fine + visualHeight élevé
→ polygon long mais étroit.

Base geometry large + visualHeight élevé
→ polygon large et plus long.

Direction bas-droite
→ farCenter.x > nearCenter.x
→ farCenter.y > nearCenter.y

Direction bas-gauche
→ farCenter.x < nearCenter.x
→ farCenter.y > nearCenter.y

farWidthMultiplier > nearWidthMultiplier
→ far edge plus large que near edge.

nearWidthMultiplier == farWidthMultiplier
→ parallélogramme stable.
```

---

# 7. Tests attendus

Créer :

```text
packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
```

À couvrir :

## 7.1 ProjectedStaticShadowPoint

```text
1. valid point accepted ;
2. x NaN rejected ;
3. x Infinity rejected ;
4. y NaN rejected ;
5. y Infinity rejected ;
6. equality/hashCode includes x/y.
```

## 7.2 StaticShadowProjectionSpec

```text
1. default spec has stable expected values ;
2. valid direction accepted ;
3. zero direction rejected ;
4. direction NaN/Infinity rejected ;
5. lengthRatio <= 0 rejected ;
6. nearWidthMultiplier <= 0 rejected ;
7. farWidthMultiplier <= 0 rejected ;
8. equality/hashCode includes all fields.
```

## 7.3 ProjectedStaticShadowGeometry

```text
1. valid four-point polygon accepted ;
2. duplicate / degenerate polygon rejected ;
3. points getter returns [nearLeft, nearRight, farRight, farLeft] ;
4. equality/hashCode includes all four points.
```

## 7.4 resolveProjectedStaticShadowGeometry

```text
1. default projection moves far edge down-right ;
2. custom down-left direction moves far edge down-left ;
3. projection length uses metrics.visualHeight ;
4. near width uses baseGeometry.width * nearWidthMultiplier ;
5. far width uses baseGeometry.width * farWidthMultiplier ;
6. changing baseGeometry.height does not change polygon width ;
7. changing baseGeometry.width changes near/far edge widths ;
8. narrow base geometry produces narrow polygon ;
9. wide base geometry produces wide polygon ;
10. output points are finite ;
11. function does not mutate input objects.
```

## 7.5 Compatibility avec Shadow-28

Ajouter un test qui compose :

```text
StaticShadowVisualMetrics
ResolvedShadowConfig
resolveStaticShadowGeometry(...)
resolveProjectedStaticShadowGeometry(...)
```

Cas :

```text
visualWidth = 32
visualHeight = 64
footprintWidthRatio = 0.25
footprintHeightRatio = 0.08
```

Attendu :

```text
le polygon est basé sur la largeur résolue du footprint ;
la longueur dépend de visualHeight ;
aucun offset/scale n’est appliqué une deuxième fois.
```

---

# 8. Régressions à lancer

Relancer au minimum :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow
cd packages/map_core && dart test
cd packages/map_core && dart analyze
```

Ne pas modifier `map_editor` ni `map_runtime`.

Donc pas besoin de relancer ces packages.

---

# 9. Vérifications anti-dérive obligatoires

À lancer et reporter :

```bash
cd /Users/karim/Project/pokemonProject

git status --short --untracked-files=all
find .. -name AGENTS.md -print
```

Diff-only interdits hors `map_core` :

```bash
git diff --name-only | rg -n "packages/map_editor|packages/map_runtime|packages/map_gameplay|packages/map_battle"
```

Résultat attendu :

```text
aucune sortie
```

Diff-only modèles persistants interdits :

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models"
```

Résultat attendu :

```text
aucune sortie
```

Diff-only JSON codecs interdits :

```bash
git diff --name-only | rg -n "project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
```

Résultat attendu :

```text
aucune sortie
```

Diff-only generated files interdits :

```bash
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
```

Résultat attendu :

```text
aucune sortie
```

Diff-only runtime/editor concepts interdits :

```bash
git diff -U0 -- packages/map_core \
  | rg -n "Canvas|Flame|drawOval|drawPath|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex"
```

Résultat attendu :

```text
aucune sortie
```

Note :

```text
Le mot "direction" peut apparaître dans les noms directionX/directionY.
Le scan interdit LightDirection comme modèle persistant, pas les champs locaux de projection.
```

Vérifier aussi :

```bash
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

---

# 10. Rapport final attendu

Créer :

```text
reports/shadows/shadow_lot_35_static_shadow_projection_geometry_core.md
```

Le rapport doit contenir :

```text
1. Résumé du lot
2. Design retenu
3. Fichiers créés
4. Fichiers modifiés
5. Fichiers non modifiés explicitement
6. API projection ajoutée
7. Formule de projection
8. Defaults V0
9. Validation des points/spec/polygon
10. Compatibilité avec resolveStaticShadowGeometry(...)
11. Pourquoi ce lot ne touche pas runtime/editor
12. Pourquoi ce lot ne crée pas de lumière globale persistante
13. Tests ajoutés
14. Commandes lancées
15. Résultats complets des tests ciblés
16. Ligne finale exacte des tests globaux
17. Résultats des scans anti-dérive
18. git status initial
19. git status final
20. git diff --stat
21. Non-objectifs respectés
22. Risques / réserves
23. Auto-review finale
24. Regard critique sur le prompt
25. Contenu complet des fichiers créés/modifiés
26. Diffs complets ou équivalents /dev/null pour fichiers créés
```

Le rapport doit inclure le contenu complet des fichiers texte/code créés ou modifiés par ce lot si raisonnable.

Pour les nouveaux petits fichiers Shadow, contenu complet obligatoire.

---

# 11. Auto-review obligatoire

Avant de finaliser, fais une passe de review séparée.

Tu dois répondre dans le rapport :

```text
- Ai-je ajouté une géométrie pure de projection statique ? oui.
- Ai-je gardé map_core sans Flutter/Flame ? oui.
- Ai-je évité de toucher au runtime ? oui.
- Ai-je évité de toucher à l’éditeur ? oui.
- Ai-je évité de modifier les modèles persistants ? oui.
- Ai-je évité de modifier les codecs JSON ? oui.
- Ai-je évité build_runner ? oui.
- Ai-je évité blur/saveLayer/ImageFilter ? oui.
- Ai-je évité une lumière globale persistante ? oui.
- Ai-je laissé le filtrage mode/renderPass aux futurs builders runtime/editor ? oui.
```

Tu dois aussi signaler tout point du prompt que tu juges discutable ou impossible à respecter, avec explication.

---

# 12. Critères de validation

Le lot est réussi si :

```text
- ProjectedStaticShadowPoint existe ;
- StaticShadowProjectionSpec existe ;
- ProjectedStaticShadowGeometry existe ;
- resolveProjectedStaticShadowGeometry(...) existe ;
- les defaults V0 sont stables et testés ;
- la projection produit un quadrilatère non dégénéré ;
- la longueur dépend de metrics.visualHeight ;
- la largeur dépend de baseGeometry.width ;
- aucun runtime/editor modifié ;
- aucun modèle persistant modifié ;
- aucun codec JSON modifié ;
- aucun generated file ;
- tests ciblés verts ;
- test/shadow map_core vert ;
- dart analyze vert ;
- Evidence Pack complet présent ;
- aucun commit.
```

---

# 13. Résumé attendu en fin de réponse Codex

À la fin, donne un résumé court :

```text
Shadow-35 terminé.
Géométrie core de projection statique ajoutée.
ProjectedStaticShadowPoint / StaticShadowProjectionSpec / ProjectedStaticShadowGeometry ajoutés.
resolveProjectedStaticShadowGeometry(...) ajouté.
Aucun runtime/editor modifié.
Aucun modèle/codec JSON modifié.
Tests ciblés : ...
test/shadow : ...
map_core complet : ...
analyze : ...
Rapport : reports/shadows/shadow_lot_35_static_shadow_projection_geometry_core.md
Aucun commit effectué.
```

