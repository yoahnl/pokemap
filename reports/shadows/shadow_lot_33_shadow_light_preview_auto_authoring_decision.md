# Shadow-33 - Shadow Light Preview / Auto Shadow Authoring Decision V0

## 1. Resume executif

Shadow-33 est un lot de decision. Aucun code de production n'est modifie.

Constat : les lots Shadow-27 a Shadow-32 ont rendu les ombres configurables, persistables, visibles dans le runtime et visibles dans l'editeur, mais ils n'ont pas encore choisi une lumiere, une direction, une longueur de portee, ni des valeurs automatiques par type d'objet. Il est donc normal que les captures montrent encore des ovales lourds ou peu naturels si les champs restent en `auto` ou proches des defaults V0.

Decision retenue :

- ajouter d'abord une preview de lumiere editor-only, non persistante, pour comparer matin / midi / soir sans toucher au runtime ;
- extraire ensuite une operation pure `map_core` de transformation lumineuse si la preview valide le comportement ;
- brancher le runtime seulement apres cette operation commune ;
- ajouter l'auto-shadow authoring sous forme d'actions explicites, jamais d'ecriture silencieuse ;
- ne pas ajouter de modele persistant de lumiere globale avant validation visuelle.

## 2. Probleme observe utilisateur

Les captures utilisateur montrent :

- des ombres encore trop larges pour des objets hauts et fins ;
- des ovales uniformes qui ne donnent pas l'impression d'une heure de jour ;
- des champs `auto` visibles dans l'UI, mais aucune difference evidente sans valeurs renseignees ;
- une attente legitime : pouvoir previsualiser une lumiere et obtenir des valeurs d'ombre raisonnables sans tout regler a la main.

Le probleme n'est pas que les lots precedents n'ont rien fait. Ils ont prepare le systeme. Le probleme est qu'ils n'ont pas encore introduit une decision de lumiere ou une generation automatique de config.

## 3. Pourquoi les lots precedents ne suffisent pas visuellement

Shadow-27 a ajoute `StaticShadowFootprintConfig` et les champs optionnels dans les configs d'element et d'instance.

Shadow-28 a ajoute `resolveStaticShadowGeometry(...)` avec des defaults V0 :

```text
anchorXRatio = 0.5
anchorYRatio = 1.0
footprintWidthRatio = 0.75
footprintHeightRatio = 0.25
```

Shadow-29 et Shadow-30 ont branche le runtime et la preview editor sur cette geometrie commune.

Shadow-31 et Shadow-32 ont expose l'edition manuelle des footprints.

Ces lots ne modifient pas automatiquement les donnees existantes. Si un element garde un footprint `null`, il garde la formule V0. Si aucun preset ou champ n'est applique, le rendu reste volontairement proche de l'ancien comportement.

## 4. Audit des modeles core

Fichiers audites :

- `packages/map_core/lib/src/models/shadow.dart`
- `packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart`
- `packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart`
- `packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart`
- `packages/map_core/lib/src/operations/shadow_config_resolver.dart`

Extraits constates :

```text
StaticShadowFootprintConfig:
- anchorXRatio
- anchorYRatio
- footprintWidthRatio
- footprintHeightRatio

ProjectElementShadowConfig:
- castsShadow
- shadowProfileId
- offsetX / offsetY
- scaleX / scaleY
- opacity
- footprint

MapPlacedElementShadowOverride:
- mode
- shadowProfileId
- offsetX / offsetY
- scaleX / scaleY
- opacity
- footprint
```

Il n'existe pas aujourd'hui de modele :

- `ShadowEnvironment`
- `WorldLightState`
- `LightDirection`
- heure de jour persistante
- direction de soleil persistante

Conclusion : le core porte les configs d'authoring d'ombre, mais pas une lumiere globale.

## 5. Audit geometrie core

Fichier audite :

- `packages/map_core/lib/src/operations/static_shadow_geometry.dart`

La geometrie commune calcule :

```text
anchorX = metrics.left + metrics.visualWidth * footprint.anchorXRatio
anchorY = metrics.top + metrics.visualHeight * footprint.anchorYRatio
baseWidth = metrics.visualWidth * footprint.footprintWidthRatio
baseHeight = metrics.visualHeight * footprint.footprintHeightRatio
width = baseWidth * shadowConfig.scaleX
height = baseHeight * shadowConfig.scaleY
centerX = anchorX + shadowConfig.offsetX
centerY = anchorY + shadowConfig.offsetY
left = centerX - width / 2
top = centerY - height / 2
```

Cette operation ne filtre pas les modes et ne connait pas l'heure de la journee. Elle applique seulement footprint, offset et scale.

Conclusion : c'est le bon point d'ancrage futur pour une transformation de lumiere pure, mais il ne faut pas surcharger cette fonction existante avec une notion environnementale implicite.

## 6. Audit runtime shadows

Fichiers audites :

- `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`
- `packages/map_runtime/lib/src/shadow/shadow_runtime_resolver.dart`
- `packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart`

Constats :

- `StaticPlacedElementShadowRuntimeInput` porte `elementFootprint` et `overrideFootprint` ;
- `staticPlacedElementShadowAnchorFromMetrics(...)` appelle `resolveStaticShadowGeometry(...)` ;
- le runtime garde `resolveShadowRuntimeInstruction(...)` pour appliquer offset, scale, opacity et couleur ;
- la collection transmet `source.elementShadow?.footprint` et `source.placedOverride?.footprint`.

Conclusion : le runtime est aligne sur la geometrie core, mais il n'a pas encore d'entree de lumiere globale ou de preview horaire.

## 7. Audit editor preview

Fichier audite :

- `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`

Constats :

- `buildEditorStaticShadowPreviewInstructions(...)` calcule `baseLeft`, `baseTop`, `visualWidth`, `visualHeight` ;
- il appelle `resolveStaticShadowGeometry(...)` ;
- il transmet `element.shadow?.footprint` et `placed.shadowOverride?.footprint` ;
- il mappe `geometry.left`, `geometry.top`, `geometry.width`, `geometry.height` vers l'instruction de preview.

Conclusion : l'editeur montre la geometrie commune, mais aucune variation matin / midi / soir n'existe encore.

## 8. Audit UI authoring existante

Fichiers audites :

- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart`

Constats :

- `ElementShadowSection` expose `Empreinte au sol` quand l'element projette une ombre ;
- `PlacedElementShadowOverrideSection` expose `Reglages rapides` puis `Empreinte de cette instance` en mode `Personnaliser` ;
- les champs `auto` signifient `null`, donc heritage des defaults V0 ou du niveau precedent ;
- l'utilisateur peut corriger manuellement, mais il n'a pas encore un bouton de suggestion automatique.

Conclusion : l'UI actuelle est une UI de reglage. Il manque une UI de simulation lumineuse et une UI d'aide a l'authoring.

## 9. Footprint vs tuning preset vs lumiere globale

Le footprint n'est pas une lumiere. Il decrit l'emprise locale au sol de l'objet :

- ou l'ombre est ancree ;
- quelle largeur et hauteur de base utiliser ;
- comment un lampadaire differe d'un stand ou d'un panneau.

Les presets Shadow-25 ne sont pas une lumiere. Ils changent vite les champs d'une instance :

- `offsetX`
- `offsetY`
- `scaleX`
- `scaleY`
- `opacity`

Une lumiere globale est autre chose. Elle represente une intention environnementale :

- midi : ombre plus courte et plus centree ;
- matin : ombre portee dans une direction ;
- soir : ombre plus longue dans l'autre direction ;
- nuit : opacite faible ou ombres attenuees selon direction artistique.

Il faut donc eviter de faire passer une lumiere globale pour un simple preset d'instance.

## 10. Options de stockage lumiere

### Option A - Tout editor-only en V0

La preview de lumiere existe seulement dans l'editeur. Elle ne modifie pas le projet et ne touche pas le runtime.

Avantages :

- tres faible risque ;
- permet de juger visuellement les directions ;
- aucune migration JSON ;
- aucune ambiguite gameplay.

Inconvenients :

- le runtime ne change pas encore ;
- la preview n'est pas une feature finale.

### Option B - Modele persistant dans `ProjectManifest`

Ajouter un champ de type `ShadowEnvironment` ou equivalent dans le manifest.

Avantages :

- centralise ;
- runtime et editor peuvent consommer le meme etat.

Inconvenients :

- schema change ;
- migration / generated files ;
- risque de figer trop tot une mauvaise abstraction ;
- confusion entre authoring, rendu et gameplay.

### Option C - Modele persistant par map dans `MapData`

Chaque map porte son ambiance lumineuse.

Avantages :

- utile a long terme pour maps interieures, grottes, villes, routes ;
- plus flexible qu'un manifest global.

Inconvenients :

- schema change encore plus visible ;
- demande une decision produit plus large sur l'heure de jour ;
- risque de melanger preview editor et runtime canonique.

### Option D - Profil Shadow porte la lumiere

Mettre direction / heure dans `ProjectShadowProfile`.

Avantages :

- facile a partager ;
- peu de nouveaux objets.

Inconvenients :

- melange style de shadow et environnement ;
- un profil ne devrait pas savoir si la scene est au matin ou au soir ;
- mauvais point d'extension pour une lumiere globale.

Decision : Option A en premier.

## 11. Decision lumiere V0

Recommandation Shadow-34 :

```text
Editor Shadow Light Preview V0
```

Ajouter une preview editor-only, non persistante, avec des presets stables :

- `midi` : ombre courte, presque centree ;
- `matin` : ombre portee dans une direction ;
- `soir` : ombre portee dans la direction opposee ;
- `neutre` : comportement actuel.

Cette preview doit agir comme un transform visuel temporaire applique aux instructions de preview, sans ecrire dans `ProjectManifest`, `MapData`, `ProjectElementShadowConfig` ou `MapPlacedElementShadowOverride`.

Champs conceptuels recommandes pour le transform editor-only :

```text
id
label
directionX
directionY
lengthMultiplier
scaleXMultiplier
scaleYMultiplier
opacityMultiplier
```

Regles :

- `directionX` / `directionY` doivent etre finis ;
- le vecteur nul represente une ombre centree ;
- `lengthMultiplier >= 0` ;
- `scaleXMultiplier > 0` ;
- `scaleYMultiplier > 0` ;
- `opacityMultiplier` borne a `[0, 1]` ou applique puis clamp.

Le transform doit etre separe de `resolveStaticShadowGeometry(...)` au debut, pour eviter de modifier trop vite le contrat core.

## 12. Decision auto-shadow V0

Recommandation Shadow-37 :

```text
Element Auto Shadow Suggestion V0
```

Ajouter une action explicite dans l'UI element, par exemple :

```text
Suggérer une empreinte
```

Cette action calcule une `ProjectElementShadowConfig` plausible a partir des metriques disponibles de l'element source :

- dimensions de la premiere frame ;
- ratio largeur / hauteur ;
- eventuellement categorie heuristique simple : haut-fin, bas-large, moyen.

Elle doit ecrire uniquement sur l'element source, et seulement quand l'utilisateur clique.

Regles :

- pas d'application automatique silencieuse ;
- pas de modification des instances ;
- preservation de `shadowProfileId`, `castsShadow`, offsets, scales et opacite quand ils existent ;
- reset manuel toujours possible ;
- suggestion testee et stable.

## 13. Combinaison avec overrides existants

Ordre conceptuel recommande :

```text
1. ProjectShadowProfile fournit le style de base.
2. ProjectElementShadowConfig fournit les defaults de l'objet.
3. MapPlacedElementShadowOverride fournit l'exception locale.
4. Geometry core resout footprint + offset + scale + opacity.
5. Light preview/runtime environment transforme la geometrie finale sans ecrire dans l'authoring local.
```

Pourquoi cet ordre :

- le footprint reste une propriete de l'objet ou de l'instance ;
- la lumiere reste une propriete de la scene ou de la preview ;
- les overrides utilisateur ne sont pas detruits par un changement d'heure ;
- le runtime et l'editeur peuvent finir par partager la meme operation lumineuse.

## 14. Compatibilite JSON / migrations

Pour Shadow-34, aucune migration :

- editor-only ;
- pas de champ persistant ;
- pas de codec JSON ;
- pas de generated file.

Pour un futur modele persistant de lumiere, recommandation :

- preferer des champs optionnels ;
- absence de lumiere = comportement actuel ;
- ne pas migrer les anciens projets de force ;
- encoder seulement les valeurs non-nulles ou non-default selon le style existant ;
- reserver la modification de `ProjectManifest` ou `MapData` a un lot dedie.

## 15. Alignement runtime/editor

Trajectoire recommandee :

```text
Shadow-34 : preview lumineuse editor-only
Shadow-35 : operation core pure de transform lumineux
Shadow-36 : integration runtime du transform lumineux
```

Le runtime ne doit pas importer de logique editor. L'editeur ne doit pas importer `map_runtime`.

Si la preview de Shadow-34 donne un bon rendu, Shadow-35 extrait l'algorithme dans `map_core` sous une API pure, par exemple :

```text
StaticShadowLightTransform
applyStaticShadowLightTransform(...)
```

Cette operation prendrait une `ResolvedStaticShadowGeometry` ou une instruction equivalent core, puis renverrait une geometrie transformee. Le nom exact doit etre decide dans le lot concerne.

## 16. Roadmap proposee Shadow-34+

### Shadow-34 - Editor Shadow Light Preview V0

Objectif : ajouter dans l'editeur une preview non persistante matin / midi / soir / neutre.

Contraintes :

- pas de runtime ;
- pas de modele persistant ;
- pas de JSON ;
- pas de blur ;
- pas de Shadow Studio ;
- tests builder + UI minimale si necessaire.

### Shadow-35 - Static Shadow Light Transform Core V0

Objectif : extraire la transformation lumineuse dans `map_core` apres validation visuelle.

Contraintes :

- operation pure ;
- pas de modele persistant ;
- pas de runtime/editor direct hors consommation future ;
- tests de direction, longueur, opacite, clamp.

### Shadow-36 - Runtime Shadow Light Transform Integration V0

Objectif : faire consommer au runtime la meme transformation lumineuse core.

Contraintes :

- pas de schema persistant si possible ;
- source runtime temporaire ou host-level config explicite ;
- tests anti double offset/scale/opacity.

### Shadow-37 - Element Auto Shadow Suggestion V0

Objectif : bouton explicite qui propose un footprint / offset / scale / opacity par defaut pour un element source.

Contraintes :

- ecrit `ProjectElementShadowConfig` seulement ;
- ne touche pas les instances ;
- ne remplace pas silencieusement les reglages utilisateur ;
- suggestions stables et testees.

### Shadow-38 - Instance Auto Shadow Suggestion V0

Objectif : action explicite similaire pour une instance precise.

Contraintes :

- ecrit `MapPlacedElementShadowOverride.custom` seulement ;
- preserve le footprint existant sauf demande claire ;
- ne touche pas l'element source.

### Shadow-39 - Selbrume Visual QA / Shadow Calibration Pass

Objectif : calibrer visuellement des cas reels : lampadaire, maison, panneau, arbre, stand, puits.

Contraintes :

- capture avant/apres ;
- valeurs recommandees documentees ;
- pas de nouvelle architecture.

### Shadow-40 - Persistent Shadow Environment Decision V0

Objectif : decider si la lumiere doit etre persistante par map, par projet, ou rester runtime/editor state.

Contrainte : ne le faire qu'apres les preuves visuelles des lots 34 a 39.

## 17. Alternatives rejetees

### Rejeter : ajouter directement `WorldLightState`

Trop tot. Les captures montrent un besoin de rendu, pas encore une preuve que le bon modele persistant est connu.

### Rejeter : modifier les profils Shadow pour porter l'heure

Un profil de shadow decrit le style d'ombre. L'heure de jour decrit la scene. Melanger les deux compliquerait les overrides.

### Rejeter : auto-appliquer des valeurs a tous les elements

Risque eleve de detruire un authoring manuel. L'auto-shadow doit rester une action explicite et reversible.

### Rejeter : faire un Shadow Studio complet

Le besoin immediat est de voir une difference claire et d'obtenir des valeurs utiles. Un studio complet serait trop large.

### Rejeter : blur / atlas / sprites d'ombre en V0

Le probleme actuel est la geometrie et la direction, pas la technique de rendu avancee.

## 18. Risques / reserves

- Les presets de lumiere peuvent donner un bon rendu dans Selbrume mais moins bon ailleurs.
- Une preview editor-only peut frustrer si elle n'arrive pas vite dans le runtime ; la roadmap limite ce risque avec Shadow-35/36.
- Les heuristiques auto-shadow doivent rester modestes. Un calcul automatique base sur la bounding box ne comprendra pas toujours la forme reelle du sprite.
- Les captures montrent que certaines maisons ou arbres peuvent avoir besoin de regles par famille d'assets, pas seulement de ratios generiques.

## 19. Reponses aux 12 questions obligatoires

1. Pourquoi les ombres sont-elles encore moches apres Shadow-27 a Shadow-32 ?
   Parce que ces lots ont pose le modele, les overrides, la geometrie commune et l'UI manuelle. Ils n'ont pas encore choisi de direction de lumiere ni genere automatiquement des valeurs d'authoring.

2. Faut-il une preview par heure de jour ?
   Oui, mais d'abord editor-only et non persistante pour tester le rendu sans migration.

3. Faut-il une lumiere globale persistante tout de suite ?
   Non. La bonne forme du modele n'est pas encore prouvee.

4. La lumiere doit-elle vivre dans `ProjectShadowProfile` ?
   Non. Le profil est un style partage, pas un etat de scene.

5. La lumiere doit-elle vivre dans `ProjectManifest` ?
   Pas en V0. Ce sera a reevaluer apres validation visuelle.

6. La lumiere doit-elle vivre dans `MapData` ?
   Probablement a terme si chaque map a une ambiance propre, mais pas avant une decision dediee.

7. Comment eviter de casser les overrides existants ?
   En appliquant la lumiere comme transform d'environnement apres la resolution des configs locales, sans ecrire dans les overrides.

8. Comment faire l'auto-shadow sans surprise ?
   Par bouton explicite, avec preservation des champs existants, jamais par ecriture silencieuse.

9. Les presets rapides Shadow-25 suffisent-ils ?
   Non. Ils aident une instance, mais ne modelisent ni heure de jour ni suggestion par element source.

10. Ou mettre l'algorithme partage runtime/editor ?
    Dans `map_core`, apres validation editor-only.

11. Pourquoi ne pas faire le runtime en meme temps que la preview ?
    Parce qu'il faut d'abord calibrer visuellement la direction et la longueur sans risquer de changer le comportement runtime.

12. Quel prochain lot faire ?
    Shadow-34 : Editor Shadow Light Preview V0.

## 20. Commandes lancees

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "StaticShadowFootprintConfig|ProjectElementShadowConfig|MapPlacedElementShadowOverride|ResolvedShadowConfig" packages/map_core/lib/src
rg -n "resolveStaticShadowGeometry|ResolvedStaticShadowGeometry|StaticShadowVisualMetrics" packages/map_core/lib/src/operations
rg -n "StaticPlacedElementShadowRuntimeInput|resolveStaticPlacedElementShadow|resolveShadowRuntimeInstruction" packages/map_runtime/lib/src/shadow
rg -n "buildEditorStaticShadowPreviewInstructions|EditorStaticShadowPreviewInstruction" packages/map_editor/lib/src/application/shadow
rg -n "ElementShadowSection|Empreinte au sol|PlacedElementShadowOverrideSection|Empreinte de cette instance|Réglages rapides" packages/map_editor/lib/src
sed -n '1,280p' packages/map_core/lib/src/operations/static_shadow_geometry.dart
sed -n '1,240p' packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
sed -n '1,180p' packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
sed -n '1,190p' packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
sed -n '1,460p' packages/map_core/lib/src/models/shadow.dart
sed -n '1,180p' packages/map_runtime/lib/src/shadow/shadow_runtime_resolver.dart
sed -n '300,470p' packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
sed -n '280,460p' packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

Resultats des commandes finales :

```text
git diff --check
=> aucune sortie

git diff --stat
=> aucune sortie

git diff --name-status
=> aucune sortie

git status --short --untracked-files=all
=> ?? reports/shadows/shadow_lot_33_shadow_light_preview_auto_authoring_decision.md
```

## 21. Resultats des audits

### AGENTS

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Seul `../pokemonProject/AGENTS.md` s'applique au workspace courant.

### Core models

Le scan core a trouve notamment :

```text
packages/map_core/lib/src/models/shadow.dart:45:final class StaticShadowFootprintConfig
packages/map_core/lib/src/models/shadow.dart:171:final class ProjectElementShadowConfig
packages/map_core/lib/src/models/shadow.dart:245:final class MapPlacedElementShadowOverride
packages/map_core/lib/src/operations/shadow_config_resolver.dart:30:final class ResolvedShadowConfig
```

Il a aussi confirme que les codecs Shadow portent deja `footprint`, mais aucun modele de lumiere globale.

### Geometry core

Le scan geometry a trouve :

```text
packages/map_core/lib/src/operations/static_shadow_geometry.dart:10:final class StaticShadowVisualMetrics
packages/map_core/lib/src/operations/static_shadow_geometry.dart:100:final class ResolvedStaticShadowGeometry
packages/map_core/lib/src/operations/static_shadow_geometry.dart:207:ResolvedStaticShadowGeometry resolveStaticShadowGeometry
```

### Runtime

Le scan runtime a trouve :

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:53:final inputs = <StaticPlacedElementShadowRuntimeInput>[];
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:68:StaticPlacedElementShadowRuntimeInput(
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:68:final class StaticPlacedElementShadowRuntimeInput
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:130:resolveStaticPlacedElementShadowRuntimeInstruction
packages/map_runtime/lib/src/shadow/shadow_runtime_resolver.dart:69:ShadowRuntimeRenderInstruction? resolveShadowRuntimeInstruction
```

### Editor preview

Le scan editor preview a trouve :

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:3:final class EditorStaticShadowPreviewInstruction
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:54:List<EditorStaticShadowPreviewInstruction>
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:55:buildEditorStaticShadowPreviewInstructions
```

### UI authoring

Le scan UI a trouve :

```text
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart:300:'Réglages rapides'
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart:368:'Empreinte de cette instance'
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart:323:'Empreinte au sol'
```

## 22. git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Resultat :

```text

```

Le status initial etait propre.

## 23. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Resultat :

```text
?? reports/shadows/shadow_lot_33_shadow_light_preview_auto_authoring_decision.md
```

Seul le rapport Shadow-33 est present dans le status final.

## 24. git diff --stat

Commande :

```bash
git diff --stat
```

Resultat :

```text

```

`git diff --stat` ne liste aucune modification suivie, car le lot a cree uniquement un nouveau rapport non suivi.

## 25. Auto-review

- Ai-je modifie du code de production ? non.
- Ai-je cree seulement le rapport de decision ? oui.
- Ai-je explique pourquoi les ombres restent visuellement pauvres ? oui.
- Ai-je decide une trajectoire pour la preview par heure de jour ? oui.
- Ai-je evite une lumiere globale persistante prematuree ? oui.
- Ai-je traite l'auto-shadow comme action explicite ? oui.
- Ai-je preserve la separation runtime/editor/core ? oui.
- Ai-je propose une roadmap de micro-lots ? oui.
- Ai-je evite Shadow Studio, blur, atlas, zOrder, zIndex ? oui.
- Ai-je evite tout commit ? oui.

## 26. Regard critique sur le prompt

Le besoin utilisateur est clair : il faut enfin obtenir une difference visible. Le risque du prompt serait de vouloir sauter directement vers une lumiere persistante et un systeme automatique global. La decision retenue garde une progression plus sure : preview editor-only, validation visuelle, extraction core, integration runtime, puis authoring automatique explicite.

Le point discutable : demander une preview suivant l'heure de la journee peut sembler impliquer un vrai systeme de time-of-day. Pour V0, il vaut mieux parler de presets de preview lumineuse. Le time-of-day persistant doit rester un lot separe.
