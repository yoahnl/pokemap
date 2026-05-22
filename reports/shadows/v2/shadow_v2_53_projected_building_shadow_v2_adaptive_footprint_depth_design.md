# ShadowV2-53 — Projected Building Shadow V2 Adaptive Footprint Depth Design Gate

## 1. Résumé exécutif

ShadowV2-53 est un design gate / audit only. Aucun code, test, screenshot, baseline, fixture, JSON, renderer, painter, Selbrume ou fichier de production n'a été modifié.

Décision recommandée : ne pas choisir directement C, ne pas créer maintenant un profil tall officiel, et ne pas passer à JSON/persistence. Le prochain lot doit être un artifact comparatif ciblé :

```text
ShadowV2-54 — Projected Building Shadow V2 Adaptive Depth Candidate Matrix Artifact
```

Diagnostic principal : la profondeur footprint actuelle est déjà proportionnelle à la hauteur visuelle, car `depth = metrics.visualHeight * footprint.depthRatio`. Le problème n'est donc pas l'absence totale de proportion à la hauteur. Le problème potentiel est que `depthRatio` reste constant par preset. Pour un bâtiment haut, un ratio fixe comme `0.26` peut produire une profondeur absolue plus grande, mais encore trop timide visuellement.

La piste la plus saine est de comparer visuellement une formule adaptative bornée contre les candidats fixes existants avant toute persistance.

## 2. Objectif du lot

Objectif exact :

```text
Analyser si la longueur / profondeur de l'ombre ShadowV2 footprint doit rester pilotée par un depthRatio fixe,
ou si elle doit devenir adaptative selon la hauteur visuelle du bâtiment,
avec une formule simple, bornée, Pokemon-like,
sans créer une usine à gaz de soleil dynamique ou de presets infinis.
```

Questions traitées :

```text
1. Oui, la profondeur actuelle est déjà proportionnelle à visualHeight.
2. Le bâtiment C peut rester trop court parce que depthRatio est constant.
3. Le problème principal est le ratio constant, pas la formule absolue.
4. Un profil tall fixe reste possible, mais il est trop tôt pour l'officialiser.
5. Une formule adaptiveHeightDepth est plausible si elle est bornée et limitée aux bâtiments.
6. Il faut tester standard + tall fixe + adaptive avant de choisir.
7. Oui, tester un C+ plus long est utile.
8. Non, JSON/persistence doit attendre.
9. Lot 54 doit produire une matrice adaptive depth contrôlée.
```

## 3. Rappel ShadowV2-50 à ShadowV2-52

ShadowV2-50 :

```text
Artifact multi-bâtiments contrôlé.
A = simple_house_4x5
B = wide_house_6x5
C = tall_shop_4x7
D = small_kiosk_3x4
Conclusion : standard ShadowV2 footprint fonctionne bien sur A, B, D ; C paraît potentiellement trop timide.
```

ShadowV2-51 :

```text
Design gate tall-building.
Décision : ne pas passer à JSON/persistence, ne pas modifier la calibration standard, ne pas créer de profil tall officiel.
Prochain pas : matrice contrôlée pour le bâtiment haut C.
```

ShadowV2-52 :

```text
Artifact tall-building matrix créé.
A = Standard V2 current
B = Tall deeper
C = Tall deeper softer
D = Tall attached
E = Tall reference-like
Lecture : C est le meilleur compromis actuel, mais il peut encore paraître un peu court.
```

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

Interprétation :

```text
Aucun fichier préexistant non suivi au début de ShadowV2-53.
Aucune modification suivie préexistante.
Worktree initial propre.
```

Fichiers préexistants avant ShadowV2-53 :

```text
Aucun fichier préexistant non lié au lot dans git status.
```

Fichiers créés par ShadowV2-53 :

```text
reports/shadows/v2/shadow_v2_53_projected_building_shadow_v2_adaptive_footprint_depth_design.md
```

Fichiers modifiés par ShadowV2-53 :

```text
Aucun fichier préexistant modifié.
```

Fichiers supprimés par ShadowV2-53 :

```text
Aucun.
```

Problèmes introduits par ShadowV2-53 :

```text
Aucun identifié.
```

## 5. Skills Google Flutter/Dart et sub-agents utilisés

Skills utilisés ou consultés :

```text
superpowers:using-superpowers
superpowers:brainstorming
superpowers:writing-plans
superpowers:verification-before-completion
superpowers:subagent-driven-development
karpathy-guidelines
```

Décision sur les skills :

```text
Le skill brainstorming contient un workflow de spec séparée sous docs/ et commit.
Ce workflow entre en conflit avec le contrat strict du Lot 53, qui autorise uniquement un rapport Markdown sous reports/shadows/v2.
Le lot applique donc l'esprit du skill : comparer les options, formuler une recommandation unique, garder le scope borné.
Il n'applique pas les étapes qui créeraient des fichiers hors scope ou des commits.
```

Skills Google Flutter/Dart :

```text
Aucun skill explicitement nommé Google Flutter ou Google Dart n'a été détecté.
Les vérifications pertinentes ont été faites via les instructions AGENTS, les skills génériques disponibles,
les audits read-only du code Dart existant et les rapports/artifacts ShadowV2 précédents.
```

Sub-agents utilisés :

```text
Geometry audit sub-agent : utilisé.
Visual review sub-agent : utilisé.
Adaptive design sub-agent : utilisé.
Scope / evidence sub-agent : utilisé.
```

Synthèse des sub-agents :

```text
Geometry audit : confirme depth = visualHeight * depthRatio et ratios constants par preset.
Visual review : confirme C favori, mais encore potentiellement court pour 112 px de hauteur.
Scope/evidence : confirme worktree initial propre et seul rapport Lot 53 autorisé.
Adaptive design : recommande un artifact, pas JSON/persistence ; suggère de garder A/B/D comme contrôles et d'envisager un garde-fou height/width.
```

## 6. Décision AGENTS / design gate

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "skills|Flutter|Dart|Google|sub-agent|subagent|Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sortie `find` :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Sortie AGENTS pertinente :

```text
5:This repository is a Dart/Flutter monorepo for a Pokemon-style editor/runtime/battle stack.
12:    - Pure Dart models, serialization, validation.
19:    - Independent from Flutter.
21:    - Flutter + Flame runtime.
24:    - Flutter desktop authoring app.
401:Use this when starting work so agents find and invoke relevant skills before responding, clarifying, exploring, or editing.
581:Pure Dart packages:
589:Flutter packages and apps:
611:For pure Dart packages, use `dart analyze`.
613:For Flutter packages and apps, use `flutter analyze`.
860:1. Use `superpowers:subagent-driven-development` when applicable.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
```

Décision :

```text
Lot 53 est design-only.
Le design gate est déjà l'objet du lot.
Aucune implémentation, aucun test et aucune image ne doivent être créés.
```

## 7. Fichiers audités

Fichiers audités pour la formule footprint :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Fichiers audités pour l'artifact Lot 52 :

```text
reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
reports/shadows/v2/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix_artifact.md
packages/map_runtime/tool/shadow/shadow_v2_tall_building_variant_matrix_artifact_test.dart
```

Autres sources consultées :

```text
AGENTS.md
reports/shadows/v2/*
packages/map_runtime/tool/shadow/*
packages/map_core/lib/*
```

## 8. Audit formule footprint actuelle

Commande obligatoire :

```bash
rg -n "ProjectedShadowFootprintTuning|attachYRatio|frontWidthRatio|rearWidthRatio|depthRatio|skewXRatio|frontY|frontWidth|rearWidth|depth|rearCenterX|rearY|resolveProjectedBuildingShadowGeometry" packages/map_core/lib packages/map_core/test/shadow_v2
```

Lignes pertinentes :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:148:  final frontY = metrics.top +
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:149:      metrics.visualHeight * footprint.attachYRatio +
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:152:  final frontWidth = metrics.visualWidth * footprint.frontWidthRatio;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:153:  final rearWidth = metrics.visualWidth * footprint.rearWidthRatio;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:154:  final depth = metrics.visualHeight * footprint.depthRatio;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:156:  final rearCenterX = centerX + metrics.visualWidth * footprint.skewXRatio;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:157:  final rearY = frontY + depth;
packages/map_core/lib/src/models/projected_building_shadow.dart:181:  factory ProjectedShadowFootprintTuning({
packages/map_core/lib/src/models/projected_building_shadow.dart:182:    double attachYRatio = 0.86,
packages/map_core/lib/src/models/projected_building_shadow.dart:183:    double frontWidthRatio = 1.10,
packages/map_core/lib/src/models/projected_building_shadow.dart:184:    double rearWidthRatio = 1.20,
packages/map_core/lib/src/models/projected_building_shadow.dart:185:    double depthRatio = 0.28,
packages/map_core/lib/src/models/projected_building_shadow.dart:186:    double skewXRatio = 0.10,
```

Formule exacte actuelle :

```text
centerX = metrics.left + metrics.visualWidth * 0.5 + config.localOffset.x
frontY = metrics.top + metrics.visualHeight * footprint.attachYRatio + config.localOffset.y

frontWidth = metrics.visualWidth * footprint.frontWidthRatio
rearWidth = metrics.visualWidth * footprint.rearWidthRatio
depth = metrics.visualHeight * footprint.depthRatio

rearCenterX = centerX + metrics.visualWidth * footprint.skewXRatio
rearY = frontY + depth

frontLeft = (centerX - frontWidth / 2, frontY)
frontRight = (centerX + frontWidth / 2, frontY)
rearRight = (rearCenterX + rearWidth / 2, rearY)
rearLeft = (rearCenterX - rearWidth / 2, rearY)
```

Rôle de `visualHeight` :

```text
visualHeight pilote déjà frontY via attachYRatio.
visualHeight pilote déjà depth via depthRatio.
Donc la profondeur absolue est déjà proportionnelle à la hauteur visuelle.
```

Rôle de `depthRatio` :

```text
depthRatio est le coefficient multiplicateur de visualHeight.
Si depthRatio reste constant, un bâtiment haut gagne bien de la profondeur absolue,
mais il garde la même proportion relative de profondeur.
```

Pourquoi cela peut rester insuffisant :

```text
Un bâtiment haut peut avoir besoin d'une ombre visuellement plus assumée que la simple mise à l'échelle linéaire avec le même ratio.
L'oeil compare la masse verticale, l'attache, la profondeur visible sous le bâtiment et la référence Pokemon-like.
Avec depthRatio 0.26, tall_shop_4x7 donne depth = 112 * 0.26 = 29.12.
Cela dépasse le bas du bâtiment de façon lisible, mais potentiellement trop discrète.
```

Paramètres constants aujourd'hui :

```text
attachYRatio
frontWidthRatio
rearWidthRatio
depthRatio
skewXRatio
opacity
colorHexRgb
```

Paramètres qui pourraient être adaptatifs :

```text
depthRatio en priorité.
attachYRatio secondairement pour soutenir l'attache.
rearWidthRatio secondairement pour soutenir la masse arrière.
opacity très prudemment, plutôt vers moins d'opacité si la profondeur augmente.
frontWidthRatio et skewXRatio seulement si une référence visuelle l'exige.
```

## 9. Audit artifact Lot 52

Commandes obligatoires :

```bash
file reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
ls -lh reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png || sha256sum reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
```

Sortie `file` :

```text
reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png: PNG image data, 1000 x 480, 8-bit/color RGBA, non-interlaced
```

Sortie `ls -lh` :

```text
-rw-r--r--@ 1 karim  staff   9.9K May 22 16:42 reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
```

Sortie SHA-256 :

```text
9f6ccb75df10c5116d3cf2e332576b593d10eed6706ad4b75dd875d3b94a4226  reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
```

Métadonnées :

```text
Dimensions : 1000 x 480
Taille affichée : 9.9K
Hash SHA-256 : 9f6ccb75df10c5116d3cf2e332576b593d10eed6706ad4b75dd875d3b94a4226
Colonnes : A, B, C, D, E
Ligne 1 : shadow-only
Ligne 2 : shadow + tall building
```

Pipeline documenté par le Lot 52 :

```text
ProjectBuildingShadowPreset
ProjectElementProjectedBuildingShadowConfig
StaticShadowVisualMetrics
resolveProjectedBuildingShadowGeometry(...)
createProjectedBuildingShadowRuntimeInstruction(...)
ShadowRuntimeInstructionCollection
ShadowRuntimeRenderer.renderCollectionPass(...)
```

Lecture visuelle provisoire :

```text
A est visiblement trop court pour C tall_shop_4x7.
B ajoute de la profondeur mais paraît un peu brut / plus dense.
C est le meilleur compromis actuel : plus profond, plus doux, pas trop plaque.
D est plus attaché mais trop rentré sous le bâtiment.
E soutient mieux la masse haute, mais risque l'effet plaque grise.
```

## 10. Analyse des variantes A/B/C/D/E

### A — Standard V2 current

Paramètres :

```text
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
```

Diagnostic :

```text
Bon témoin standard.
Fonctionne pour bâtiments simples/larges/compacts selon ShadowV2-50.
Pour tall_shop_4x7, l'ombre paraît trop courte / trop timide.
Depth absolu : 112 * 0.26 = 29.12.
```

### B — Tall deeper

Paramètres :

```text
attachYRatio: 0.80
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.34
skewXRatio: 0.08
opacity: 0.25
```

Diagnostic :

```text
Plus profond et sûr.
Depth absolu : 112 * 0.34 = 38.08.
La correction est lisible, mais l'opacité 0.25 et le dessin plus franc peuvent sembler un peu bruts.
```

### C — Tall deeper softer

Paramètres :

```text
attachYRatio: 0.80
frontWidthRatio: 1.30
rearWidthRatio: 1.45
depthRatio: 0.38
skewXRatio: 0.08
opacity: 0.23
```

Diagnostic :

```text
Favori utilisateur actuel.
Bon équilibre entre profondeur, douceur et masse.
Depth absolu : 112 * 0.38 = 42.56.
La sortie reste peut-être encore un peu courte pour un bâtiment de 112 px de haut,
car environ 20 px seulement restent très visibles sous le bâtiment dans le panel building.
```

### D — Tall attached

Paramètres :

```text
attachYRatio: 0.76
frontWidthRatio: 1.24
rearWidthRatio: 1.38
depthRatio: 0.34
skewXRatio: 0.08
opacity: 0.25
```

Diagnostic :

```text
Plus attaché sous le volume.
Mais le front plus haut et la largeur plus rentrée donnent une ombre trop cachée / trop serrée.
Ce n'est pas le meilleur signal pour résoudre le manque de profondeur perçu.
```

### E — Tall reference-like

Paramètres :

```text
attachYRatio: 0.78
frontWidthRatio: 1.34
rearWidthRatio: 1.50
depthRatio: 0.40
skewXRatio: 0.10
opacity: 0.23
```

Diagnostic :

```text
Plus proche d'une ombre assumée pour grands bâtiments.
Depth absolu : 112 * 0.40 = 44.80.
La masse arrière est plus convaincante, mais le front plus large, le rearWidthRatio 1.50 et le skew 0.10 augmentent le risque de plaque grise.
```

## 11. Diagnostic : proportionnel mais insuffisant

Diagnostic central :

```text
La profondeur est déjà proportionnelle à visualHeight.
Le système n'est donc pas "non proportionnel".
```

Ce qui reste fixe :

```text
depthRatio reste fixe par preset.
attachYRatio reste fixe par preset.
rearWidthRatio reste fixe par preset.
opacity reste fixe par preset.
```

Pourquoi C peut rester trop court :

```text
Avec depthRatio 0.26, passer de 80 px à 112 px augmente bien la profondeur absolue.
Mais cela conserve le même ratio relatif.
Or un bâtiment haut peut demander une réponse stylisée non linéaire ou au moins un ratio plus haut,
afin que la silhouette verticale soit mieux soutenue par son footprint.
```

Conclusion :

```text
La bonne formulation n'est pas "rendre l'ombre proportionnelle à la hauteur".
La bonne formulation est "tester si le depthRatio doit augmenter doucement avec visualHeight,
dans des bornes strictes, seulement pour les bâtiments".
```

## 12. Options étudiées

### Option A — Garder Standard V2 unique

Analyse :

```text
Avantage : simplicité maximale.
Avantage : cohérence uniforme.
Avantage : fonctionne déjà pour A/B/D.
Inconvénient : probablement insuffisant pour C.
Inconvénient : ignore le signal visuel du Lot 52.
```

Décision :

```text
Rejetée comme décision immédiate.
La standard reste utile comme baseline, mais elle ne doit pas clore le sujet tall.
```

### Option B — Créer un profil tall fixe

Analyse :

```text
Avantage : simple à authorer.
Avantage : editor-approved si choisi manuellement.
Avantage : ne crée pas de formule implicite.
Inconvénient : ajoute un profil.
Inconvénient : demande une règle humaine ou editor.
Inconvénient : C est favori mais peut-être encore court, donc le profil n'est pas prêt.
```

Décision :

```text
Possible plus tard, mais pas à officialiser au Lot 53.
```

### Option C — Créer une formule adaptiveHeightDepth

Analyse :

```text
Avantage : répond à l'intuition utilisateur sans oublier que la formule actuelle est déjà partiellement proportionnelle.
Avantage : évite de multiplier les presets standard/tall/wide trop vite.
Avantage : peut rester très bornée.
Inconvénient : introduit un automatisme.
Inconvénient : peut contredire l'asset-driven si appliqué silencieusement à tous les objets.
```

Décision :

```text
Piste prometteuse, mais à tester visuellement avant toute implémentation ou persistence.
```

### Option D — Créer une matrice C / C+ / E / adaptive

Analyse :

```text
Avantage : meilleure preuve visuelle.
Avantage : garde JSON/persistence hors scope.
Avantage : compare fixe vs adaptatif sans figer le modèle.
Avantage : peut vérifier que les bâtiments bas A/D ne sont pas cassés.
```

Décision :

```text
Option recommandée.
```

### Option E — Passer directement à JSON/persistence

Analyse :

```text
Avantage : avance vers l'usage réel.
Inconvénient : encode une stratégie incomplète.
Inconvénient : ne répond pas au cas C.
Inconvénient : risque de devoir migrer ou revalider trop vite.
```

Décision :

```text
Rejetée maintenant.
```

### Option F — Modifier renderer/painter / banding

Analyse :

```text
Le problème observé est d'abord longueur / profondeur / ratio.
Changer le renderer ou le painter mélangerait calibration et rendu.
```

Décision :

```text
Rejetée.
```

## 13. Formules adaptatives étudiées

### Formula A — Fixed current

```text
depthRatio = 0.26
attachYRatio = 0.82
rearWidthRatio = 1.42
opacity = 0.24
```

Rôle :

```text
Témoin standard.
```

### Formula B — Fixed tall C

```text
depthRatio = 0.38
attachYRatio = 0.80
rearWidthRatio = 1.45
opacity = 0.23
```

Rôle :

```text
Favori utilisateur actuel, mais peut-être encore un peu court.
```

### Formula C — Adaptive standard-to-C

```text
referenceHeight = 80
targetHeight = 112
heightT = clamp((visualHeight - referenceHeight) / (targetHeight - referenceHeight), 0, 1)

effectiveDepthRatio = lerp(0.26, 0.38, heightT)
effectiveAttachYRatio = lerp(0.82, 0.80, heightT)
effectiveRearWidthRatio = lerp(1.42, 1.45, heightT)
effectiveOpacity = lerp(0.24, 0.23, heightT)

frontWidthRatio = 1.30
skewXRatio = 0.08
colorHexRgb = 606060
```

Diagnostic :

```text
Bonne première formule adaptative.
Elle reproduit la standard pour les bâtiments bas et C pour visualHeight 112.
Elle est bornée et lisible.
```

### Formula D — Adaptive C+

```text
referenceHeight = 80
targetHeight = 112
heightT = clamp((visualHeight - referenceHeight) / (targetHeight - referenceHeight), 0, 1)

effectiveDepthRatio = lerp(0.26, 0.42, heightT)
effectiveAttachYRatio = lerp(0.82, 0.80, heightT)
effectiveRearWidthRatio = lerp(1.42, 1.47, heightT)
effectiveOpacity = lerp(0.24, 0.22, heightT)

frontWidthRatio = 1.30
skewXRatio = 0.08
colorHexRgb = 606060
```

Diagnostic :

```text
Candidat utile si C est trop court.
Il pousse la profondeur à 47.04 px sur tall_shop_4x7.
L'opacité 0.22 compense le risque plaque, mais peut devenir trop discrète selon le fond.
```

### Formula E — Adaptive reference-like bounded

```text
referenceHeight = 80
targetHeight = 112
heightT = clamp((visualHeight - referenceHeight) / (targetHeight - referenceHeight), 0, 1)

effectiveDepthRatio = lerp(0.26, 0.40, heightT)
effectiveAttachYRatio = lerp(0.82, 0.78, heightT)
effectiveFrontWidthRatio = lerp(1.30, 1.34, heightT)
effectiveRearWidthRatio = lerp(1.42, 1.50, heightT)
effectiveSkewXRatio = lerp(0.08, 0.10, heightT)
effectiveOpacity = lerp(0.24, 0.23, heightT)
```

Diagnostic :

```text
Plus proche d'une référence grands bâtiments.
Mais cette formule varie plus de paramètres et augmente le risque de plaque grise.
Elle doit rester candidate visuelle, pas recommandation de modèle.
```

## 14. Calculs par hauteur

### Formula C — Adaptive standard-to-C

| visualHeight | heightT | effectiveDepthRatio | effectiveAttachYRatio | effectiveRearWidthRatio | effectiveOpacity |
|---:|---:|---:|---:|---:|---:|
| 64 | 0.00 | 0.260 | 0.820 | 1.420 | 0.240 |
| 80 | 0.00 | 0.260 | 0.820 | 1.420 | 0.240 |
| 96 | 0.50 | 0.320 | 0.810 | 1.435 | 0.235 |
| 112 | 1.00 | 0.380 | 0.800 | 1.450 | 0.230 |
| 128 | 1.00 | 0.380 | 0.800 | 1.450 | 0.230 |

### Formula D — Adaptive C+

| visualHeight | heightT | effectiveDepthRatio | effectiveAttachYRatio | effectiveRearWidthRatio | effectiveOpacity |
|---:|---:|---:|---:|---:|---:|
| 64 | 0.00 | 0.260 | 0.820 | 1.420 | 0.240 |
| 80 | 0.00 | 0.260 | 0.820 | 1.420 | 0.240 |
| 96 | 0.50 | 0.340 | 0.810 | 1.445 | 0.230 |
| 112 | 1.00 | 0.420 | 0.800 | 1.470 | 0.220 |
| 128 | 1.00 | 0.420 | 0.800 | 1.470 | 0.220 |

### Formula E — Adaptive reference-like bounded

| visualHeight | heightT | effectiveDepthRatio | effectiveAttachYRatio | effectiveRearWidthRatio | effectiveOpacity |
|---:|---:|---:|---:|---:|---:|
| 64 | 0.00 | 0.260 | 0.820 | 1.420 | 0.240 |
| 80 | 0.00 | 0.260 | 0.820 | 1.420 | 0.240 |
| 96 | 0.50 | 0.330 | 0.800 | 1.460 | 0.235 |
| 112 | 1.00 | 0.400 | 0.780 | 1.500 | 0.230 |
| 128 | 1.00 | 0.400 | 0.780 | 1.500 | 0.230 |

Interprétation :

```text
Les formules sont volontairement clampées dès 112 px.
Elles ne continuent donc pas à allonger l'ombre indéfiniment pour des bâtiments plus hauts.
Cette borne est essentielle pour éviter une dérive pseudo-physique.
```

## 15. Calculs sur tall_shop_4x7

Entrée :

```text
left = 68
top = 48
visualWidth = 64
visualHeight = 112
centerX = 100
```

### Formula C — Adaptive standard-to-C

À `visualHeight = 112` :

```text
heightT = 1.00
attachYRatio = 0.80
frontWidthRatio = 1.30
rearWidthRatio = 1.45
depthRatio = 0.38
skewXRatio = 0.08
opacity = 0.23

frontY = 48 + 112 * 0.80 = 137.60
frontWidth = 64 * 1.30 = 83.20
rearWidth = 64 * 1.45 = 92.80
depth = 112 * 0.38 = 42.56
rearCenterX = 100 + 64 * 0.08 = 105.12
rearY = 137.60 + 42.56 = 180.16
```

Points attendus :

```text
frontLeft  = (58.40, 137.60)
frontRight = (141.60, 137.60)
rearRight  = (151.52, 180.16)
rearLeft   = (58.72, 180.16)
```

Bounds attendus :

```text
left = 58.40
top = 137.60
width = 93.12
height = 42.56
```

### Formula D — Adaptive C+

À `visualHeight = 112` :

```text
heightT = 1.00
attachYRatio = 0.80
frontWidthRatio = 1.30
rearWidthRatio = 1.47
depthRatio = 0.42
skewXRatio = 0.08
opacity = 0.22

frontY = 48 + 112 * 0.80 = 137.60
frontWidth = 64 * 1.30 = 83.20
rearWidth = 64 * 1.47 = 94.08
depth = 112 * 0.42 = 47.04
rearCenterX = 100 + 64 * 0.08 = 105.12
rearY = 137.60 + 47.04 = 184.64
```

Points attendus :

```text
frontLeft  = (58.40, 137.60)
frontRight = (141.60, 137.60)
rearRight  = (152.16, 184.64)
rearLeft   = (58.08, 184.64)
```

Bounds attendus :

```text
left = 58.08
top = 137.60
width = 94.08
height = 47.04
```

Comparaison :

```text
Formula C reproduit exactement le candidat C du Lot 52 pour visualHeight 112.
Formula D propose un C+ : +4.48 px de profondeur, rearWidth légèrement plus large, opacity plus basse.
```

## 16. Scope : adaptive depth vs asset-driven / editor-approved

Décision nuancée :

```text
Adaptive depth est acceptable seulement comme stratégie explicitement contrôlée.
Elle ne doit pas devenir un backfill silencieux.
Elle ne doit pas s'appliquer à tous les objets.
Elle ne doit pas créer un soleil dynamique.
Elle ne doit pas remplacer l'approbation éditeur.
```

Conditions d'acceptabilité :

```text
- limité aux bâtiments / volumes contrôlés ;
- contrôlé par un preset explicite ;
- borné par min/target/max ;
- idéalement gardé par hauteur absolue et par proportion height/width, pas par hauteur seule ;
- désactivable ou évitable par authoring ;
- non appliqué aux petits props, lampadaires, poteaux, arbres ou objets fins ;
- validé visuellement avant JSON/persistence ;
- documenté comme calibration artistique, pas simulation physique.
```

Conditions de rejet :

```text
- application automatique à tous les objets ;
- application basée seulement sur visualHeight sans vérifier la silhouette ;
- backfill silencieux de données existantes ;
- dépendance à une direction solaire dynamique ;
- variation non bornée avec visualHeight ;
- mélange avec renderer/painter ou JSON dans le même lot ;
- mutation des defaults ProjectedShadowFootprintTuning().
```

## 17. Option recommandée

Option recommandée :

```text
Option D — Créer une matrice C / C+ / E / adaptive.
```

Décision :

```text
nouvel artifact comparatif
```

Diagnostic :

```text
standard actuel :
  Bon pour bâtiments simples/larges/compacts, trop timide pour tall_shop_4x7.

C actuel :
  Meilleur compromis Lot 52, doux et plus profond, mais peut-être encore court.

C trop court :
  Oui, c'est plausible. La question est assez forte pour retarder JSON/persistence.

adaptive formula :
  Prometteuse si elle reste bornée, explicite, limitée aux bâtiments et validée visuellement.
```

Pourquoi :

```text
Le système est déjà proportionnel à visualHeight.
Mais le ratio fixe peut sous-réagir pour les bâtiments hauts.
Choisir C maintenant serait prématuré.
Choisir C+ sans image serait aussi prématuré.
Une matrice adaptative donnera la preuve visuelle la plus propre.
```

Pourquoi les autres options sont rejetées :

```text
Standard unique : trop faible pour C.
Tall fixe immédiat : C n'est pas encore suffisamment tranché.
Adaptive implémentée directement : trop tôt sans artifact.
JSON/persistence : prématuré tant que tall/adaptive n'est pas décidé.
Renderer/painter : hors sujet.
Selbrume : trop tôt, trop de variables.
```

Lot 54 doit faire :

```text
Créer un artifact contrôlé comparant :
- Standard V2 fixe ;
- C tall deeper softer ;
- C+ plus long ;
- Adaptive standard-to-C ;
- Adaptive C+ ;
- E reference-like éventuellement.

Le faire sur tall_shop_4x7.
Ajouter idéalement A simple_house_4x5 et D small_kiosk_3x4 en ligne de contrôle
pour vérifier que l'adaptive ne casse pas les bâtiments bas.
```

Lot 54 ne doit pas faire :

```text
Ne pas modifier production.
Ne pas modifier map_core.
Ne pas modifier renderer/painter.
Ne pas créer JSON/persistence.
Ne pas toucher Selbrume.
Ne pas créer baseline/golden.
Ne pas créer profil tall officiel.
Ne pas appliquer aux petits props / lampadaires / objets fins.
```

## 18. Plan précis du Lot 54

Nom recommandé :

```text
ShadowV2-54 — Projected Building Shadow V2 Adaptive Depth Candidate Matrix Artifact
```

Objectif :

```text
Générer un artifact contrôlé comparant la standard V2, C tall deeper softer,
C+ plus long et des formules adaptatives bornées,
avant de décider s'il faut un profil tall fixe ou une profondeur adaptative bornée.
```

Image recommandée :

```text
Deux zones :
1. Zone principale tall_shop_4x7 : Standard, C, C+, Adaptive C, Adaptive C+, E.
2. Zone de contrôle bâtiments bas : simple_house_4x5 et small_kiosk_3x4 avec Standard vs Adaptive.
Option utile : reprendre aussi wide_house_6x5 pour prouver que l'adaptive ne réagit pas à la largeur seule.
```

Garde-fou conceptuel à étudier, sans l'implémenter dans le Lot 53 :

```text
heightGate = clamp((visualHeight - 80) / 32, 0, 1)
ratioGate = clamp((visualHeight / visualWidth - 1.25) / 0.50, 0, 1)
adaptiveHeightDepth = heightGate * ratioGate
```

Rôle :

```text
Empêcher un petit prop haut ou une silhouette trop fine de recevoir automatiquement une ombre tall-building.
Ce garde-fou doit rester candidat d'artifact, pas modèle officiel.
```

Fichiers probables :

```text
packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart
reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
reports/shadows/v2/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix_artifact.md
```

Validations obligatoires :

```text
- image créée sous reports/shadows/screenshots ;
- aucune baseline/golden ;
- harness manuel seulement ;
- pipeline resolver -> adapter -> renderer ;
- points/bounds calculés explicitement ;
- Standard V2 fixe préservée ;
- adaptive formulas locales au harness ;
- pas de mutation des defaults ;
- pas de JSON/persistence ;
- pas de Selbrume ;
- pas de renderer/painter ;
- test ciblé et analyze ciblé si le lot est artifact/test harness.
```

Décision après Lot 54 :

```text
Si adaptive C ou adaptive C+ bat clairement le profil fixe, ouvrir un design gate sur modèle/preset adaptive.
Si C fixe suffit, ouvrir un design gate tall variant selection.
Si aucune variante ne bat la standard, passer à persistence design gate.
```

## 19. Fichiers explicitement interdits au Lot 54

Interdits :

```text
packages/map_core/lib/**
packages/map_runtime/lib/**
packages/map_runtime/test/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/**
reports/shadows/baselines/**
project.json
```

Interdits conceptuels :

```text
nouveau renderer
nouveau painter
nouveau codec JSON
nouveau modèle persistant
nouveau profil tall officiel
authoring editor
auto-shadow policy
soleil dynamique
baseline/golden
petits props / lampadaires / poteaux / objets fins
```

## 20. Risques / réserves

Risques :

```text
Une formule adaptive peut devenir une règle magique si elle n'est pas explicitement authorée.
Une formule trop profonde peut produire une plaque grise.
Une formule trop douce peut résoudre la longueur mais perdre la lisibilité.
Tester seulement tall_shop_4x7 peut sur-optimiser un cas.
Tester trop de dimensions peut diluer le lot.
```

Réserves :

```text
Lot 53 ne crée aucune image et ne prouve donc pas visuellement les formules adaptatives.
Les calculs sont conceptuels et doivent être validés par un artifact.
La préférence pour C vient de l'image Lot 52 et reste une lecture visuelle, pas une décision finale de modèle.
```

## 21. Auto-critique

Checklist d'auto-review :

```text
Le lot est-il bien design-only ?
Oui. Seul ce rapport est créé.

Le rapport répond-il vraiment à l'intuition "ombre proportionnelle à la hauteur" ?
Oui. Il confirme que la formule actuelle le fait déjà via visualHeight * depthRatio.

Le rapport reconnaît-il que le système est déjà partiellement proportionnel ?
Oui. C'est le diagnostic central.

Le rapport évite-t-il une formule automatique dangereuse ?
Oui. Toute formule adaptive est bornée, limitée aux bâtiments et non officielle à ce stade.

Les formules adaptatives sont-elles bornées ?
Oui. Elles clampent entre referenceHeight 80 et targetHeight 112, avec max explicites.

Les petits props / lampadaires sont-ils exclus ?
Oui. Ils sont explicitement hors scope.

Le plan Lot 54 évite-t-il Selbrume / baseline / production / renderer / painter ?
Oui.

Le rapport contient-il toutes les preuves ?
Oui : commandes, formule, métadonnées PNG, options, calculs, décision, plan, git final.
```

Checklist finale :

```text
- [x] Design-only respecté
- [x] Aucun fichier de production modifié
- [x] Aucun test créé/modifié
- [x] Aucun fichier map_core modifié
- [x] Aucun fichier map_runtime modifié
- [x] Aucun fichier map_editor modifié
- [x] Aucun fichier Selbrume modifié
- [x] Aucun generated modifié
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] Formule footprint actuelle auditée
- [x] Proportion visualHeight reconnue
- [x] Problème depthRatio constant analysé
- [x] Artifact Lot 52 audité
- [x] A Standard analysé
- [x] B Tall deeper analysé
- [x] C Tall deeper softer analysé
- [x] D Tall attached analysé
- [x] E Reference-like analysé
- [x] Adaptive depth vs tall fixed tranché
- [x] JSON/persistence tranché
- [x] Renderer/painter explicitement exclus
- [x] Petits props / lampadaires hors scope
- [x] Option recommandée unique
- [x] Plan ShadowV2-54 précis
- [x] Fichiers interdits au Lot 54 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope
```

## 22. Regard critique sur le prompt

Le prompt est bien orienté : il corrige explicitement une mauvaise simplification possible. Dire "l'ombre devrait être proportionnelle à la hauteur" aurait été trop imprécis, car la formule actuelle l'est déjà partiellement.

Le pivot vers adaptive depth est sain parce qu'il sépare trois sujets :

```text
1. géométrie actuelle ;
2. calibration artistique ;
3. persistance / authoring.
```

Point de vigilance :

```text
Le Lot 54 devra rester un artifact, pas une implémentation déguisée.
Il devra tester assez peu de variantes pour rester lisible.
Il devra vérifier que l'adaptive ne dégrade pas les bâtiments bas.
```

## 23. Commandes lancées

Commandes obligatoires et complémentaires :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "skills|Flutter|Dart|Google|sub-agent|subagent|Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md

rg -n "ProjectedShadowFootprintTuning|attachYRatio|frontWidthRatio|rearWidthRatio|depthRatio|skewXRatio|frontY|frontWidth|rearWidth|depth|rearCenterX|rearY|resolveProjectedBuildingShadowGeometry" packages/map_core/lib packages/map_core/test/shadow_v2

file reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
ls -lh reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png || sha256sum reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png

rg -n "candidate-a-standard-v2-current|candidate-b-tall-deeper|candidate-c-tall-deeper-softer|candidate-d-tall-attached|candidate-e-tall-reference-like|attachYRatio|frontWidthRatio|rearWidthRatio|depthRatio|skewXRatio|opacity|colorHexRgb|points|bounds" reports/shadows/v2 packages/map_runtime/tool

rg -n "adaptive|height|visualHeight|C\\+|tall|depthRatio|persistence|JSON|Selbrume|renderer|painter|lampadaire|prop|asset-driven|editor-approved" reports/shadows/v2 packages/map_runtime/tool packages/map_core/lib

python3 - <<'PY'
Calcul local des tables adaptive C/D/E et points tall_shop_4x7 pour Formula C/D.
PY

git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Notes :

```text
Aucun test lancé, conformément au contrat design-only.
Aucun build_runner lancé.
Aucun script Selbrume lancé.
Aucun outil screenshot lancé.
```

## 24. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale :

```text
```

Interprétation :

```text
Aucune modification suivie.
Le rapport Lot 53 est non suivi, donc absent de git diff --stat.
```

## 25. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale :

```text
```

Interprétation :

```text
Aucune modification suivie.
```

## 26. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale :

```text
```

Interprétation :

```text
Propre.
```

## 27. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? reports/shadows/v2/shadow_v2_53_projected_building_shadow_v2_adaptive_footprint_depth_design.md
```

Inventaire final :

```text
Créé :
reports/shadows/v2/shadow_v2_53_projected_building_shadow_v2_adaptive_footprint_depth_design.md

Modifié :
Aucun.

Supprimé :
Aucun.

Generated :
Aucun.

Screenshot / baseline :
Aucun.

Fichiers de production :
Aucun.

Tests créés/modifiés :
Aucun.
```

Confirmation :

```text
Un seul rapport Markdown a été créé.
Le rapport courant est le fichier créé ; il n'embarque pas une copie récursive de lui-même.
```
