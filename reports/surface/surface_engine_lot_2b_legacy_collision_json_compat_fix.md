# Surface Engine - Lot 2-bis - Fix legacy collision JSON compat debt

Date: 2026-04-26

## 1. Resume executif

Le Lot 2-bis corrige la dette JSON legacy qui bloquait le test complet de `map_core` depuis les Lots 1 et 2.

Le bug etait reproductible avec:

```text
test/legacy_editor_json_compat_collision_test.dart:
legacy collision profile compat unknown legacy keys do not prevent manifest parsing [E]
type 'List<int>' is not a subtype of type 'Map<String, dynamic>' in type cast
package:map_core/src/models/element_collision_profile.g.dart 46:33
```

La cause etait un ancien payload `collisionProfile` contenant:

```dart
'pixelMask': <int>[1, 0, 1]
```

Le champ `pixelMask` est aujourd'hui un champ connu, mappe vers:

```dart
@JsonKey(name: 'pixelMask') ElementCollisionPixelMask? collisionMask
```

Le generated parser tentait donc de caster cette ancienne liste en `Map<String, dynamic>`, avant meme que le reste du profil collision puisse etre parse.

La correction ajoute une normalisation ciblee dans `ElementCollisionProfile.fromJson`, uniquement pour les champs de masque connus:

- `visualMask`;
- `pixelMask`;
- `occlusionMask`.

Si l'un de ces champs est absent ou `null`, il est laisse tel quel. S'il est une vraie map, il est conserve comme `Map<String, dynamic>`. S'il est une ancienne forme incompatible (`List<int>`, string, bool, number, etc.), il est retire avant l'appel au generated parser.

Le test complet `map_core` passe maintenant:

```text
+173: All tests passed!
```

## 2. Pourquoi ce lot etait necessaire avant la suite Surface Engine

Les prochains lots Surface Engine vont ajouter progressivement des modeles persistants et de nouvelles primitives JSON dans `map_core`. Avant d'ajouter de nouveaux contrats, il fallait supprimer le bruit rouge connu du package.

Sinon, chaque futur lot aurait ete force de documenter le meme echec hors scope:

- impossible de savoir rapidement si un changement Surface casse `map_core`;
- verification globale moins fiable;
- dette JSON legacy masquant les regressions reelles;
- risque d'ajouter de nouveaux modeles sur un socle de parsing deja fragile.

Ce lot remet `map_core` dans un etat testable sans creer de Surface Engine.

## 3. Fichiers consultes

### Tests et dette reproduite

- `packages/map_core/test/legacy_editor_json_compat_collision_test.dart`
- `packages/map_core/test/element_collision_profile_model_test.dart`
- `packages/map_core/test/element_collision_profile_pixel_mask_json_test.dart`
- `packages/map_core/test/map_terrain_autotile_characterization_test.dart`
- `packages/map_core/test/tile_visual_frame_timeline_test.dart`

### Production map_core

- `packages/map_core/lib/src/models/element_collision_profile.dart`
- `packages/map_core/lib/src/models/element_collision_profile.g.dart` en lecture seule
- `packages/map_core/lib/src/io/legacy_editor_json_compat.dart`
- `packages/map_core/lib/src/collision/element_collision_legacy_migration.dart`

### Fichiers precedents utiles au contexte

- `reports/analysis/surface_engine_lot_1_autotile_characterization.md`
- `reports/analysis/surface_engine_lot_2_tile_visual_frame_timeline.md`

## 4. Fichiers crees

- `reports/analysis/surface_engine_lot_2b_legacy_collision_json_compat_fix.md`

## 5. Fichiers modifies

- `packages/map_core/lib/src/models/element_collision_profile.dart`
- `packages/map_core/test/element_collision_profile_pixel_mask_json_test.dart`

Aucun fichier generated `.g.dart` ou `.freezed.dart` n'a ete modifie.

Aucun fichier `map_runtime`, `map_editor` ou `map_gameplay` n'a ete modifie.

## 6. Cause exacte du bug

Dans `element_collision_profile.dart`, `ElementCollisionProfile` declare:

```dart
ElementCollisionPixelMask? visualMask,
@JsonKey(name: 'pixelMask') ElementCollisionPixelMask? collisionMask,
ElementCollisionPixelMask? occlusionMask,
```

Le generated parser lit ensuite les champs comme des maps:

```dart
visualMask: json['visualMask'] == null
    ? null
    : ElementCollisionPixelMask.fromJson(
        json['visualMask'] as Map<String, dynamic>),
collisionMask: json['pixelMask'] == null
    ? null
    : ElementCollisionPixelMask.fromJson(
        json['pixelMask'] as Map<String, dynamic>),
occlusionMask: json['occlusionMask'] == null
    ? null
    : ElementCollisionPixelMask.fromJson(
        json['occlusionMask'] as Map<String, dynamic>),
```

Un vieux payload avec `pixelMask: <int>[1, 0, 1]` n'est pas une map. Le cast genere plante immediatement:

```text
type 'List<int>' is not a subtype of type 'Map<String, dynamic>' in type cast
```

Le reste du profil collision contenait pourtant des champs encore valides, notamment `cells`, `shapeCells`, `manualAddedCells` et `manualRemovedCells`. Le probleme etait donc trop local pour justifier de supprimer tout le profil.

## 7. Strategie de correction retenue

La correction est faite dans le factory source:

```dart
factory ElementCollisionProfile.fromJson(Map<String, dynamic> json) =>
    _$ElementCollisionProfileFromJson(
      _normalizeElementCollisionProfileJson(json),
    );
```

La normalisation privee:

- copie le JSON d'entree;
- inspecte seulement `visualMask`, `pixelMask`, `occlusionMask`;
- conserve les champs absents;
- conserve les champs `null`;
- conserve les maps valides en les normalisant en `Map<String, dynamic>`;
- retire les valeurs non-map incompatibles;
- laisse le generated parser traiter tout le reste.

Le bon endroit est `ElementCollisionProfile.fromJson`, plutot que seulement `migrateProjectManifestJson`, pour deux raisons:

1. Le bug peut etre declenche par un manifest migre, mais aussi par un appel direct a `ElementCollisionProfile.fromJson`.
2. La responsabilite est locale au contrat JSON de `ElementCollisionProfile`: ces trois champs sont les seuls qui acceptent historiquement un ancien nom/format incompatible avec leur type moderne.

## 8. Pourquoi la correction est ciblee et non dangereuse

La correction ne fait pas de `try/catch` global.

Elle ne fait pas:

```dart
try {
  return _$ElementCollisionProfileFromJson(json);
} catch (_) {
  return const ElementCollisionProfile();
}
```

Elle ne masque donc pas toutes les erreurs de parsing.

Elle ne supprime pas tout `collisionProfile` quand un masque est invalide.

Elle ne tente pas de convertir une ancienne liste en `ElementCollisionPixelMask`, car l'encodage exact de cette ancienne forme n'est pas connu.

Elle ne touche pas:

- `source`;
- `padding`;
- `cells`;
- `shapeCells`;
- `manualAddedCells`;
- `manualRemovedCells`.

Les masques valides continuent de parser comme avant, y compris:

- `pixelMask` valide;
- `visualMask` valide;
- `occlusionMask` valide.

Les masques invalides sont ignores proprement et seulement eux.

## 9. Tests ajoutes ou modifies

Le test existant suivant est conserve et passe sans affaiblissement:

```text
legacy collision profile compat unknown legacy keys do not prevent manifest parsing
```

Le fichier `packages/map_core/test/element_collision_profile_pixel_mask_json_test.dart` a ete enrichi avec des tests directs:

1. `supports pixelMask`
   - verifie que le `pixelMask` moderne valide continue de parser.

2. `ignores legacy non-map pixelMask while preserving cells`
   - `pixelMask: <int>[1, 0, 1]`;
   - pas d'exception;
   - `collisionMask == null`;
   - `cells` conserve.

3. `keeps valid pixelMask map data intact`
   - map valide avec `widthPx`, `heightPx`, `encoding`, `dataBase64`;
   - toutes les donnees sont conservees.

4. `ignores legacy non-map visual and occlusion masks`
   - `visualMask` et `occlusionMask` sous forme de listes;
   - pas d'exception;
   - champs correspondants `null`;
   - `cells` conserve.

5. `keeps valid visual and occlusion masks intact`
   - les deux champs valides restent parses.

6. `mask normalization does not affect authored cell lists`
   - verifie que `cells`, `shapeCells`, `manualAddedCells`, `manualRemovedCells` restent parses normalement.

## 10. Commandes lancees

### Reproduction rouge obligatoire

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_editor_json_compat_collision_test.dart
```

Resultat avant correction:

```text
+1 -1: legacy collision profile compat unknown legacy keys do not prevent manifest parsing [E]
type 'List<int>' is not a subtype of type 'Map<String, dynamic>' in type cast
Some tests failed.
```

### Tests directs ajoutes, avant correction

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/element_collision_profile_pixel_mask_json_test.dart
```

Resultat avant correction:

```text
+3 -3: Some tests failed.
```

Les trois echecs etaient les cas non-map:

- `pixelMask` liste;
- `visualMask` liste;
- `pixelMask` liste avec listes de cellules.

### Format

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart format \
  lib/src/models/element_collision_profile.dart \
  test/element_collision_profile_pixel_mask_json_test.dart
```

Resultat:

```text
Formatted 2 files (0 changed) in 0.01 seconds.
```

### Tests directs collision apres correction

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/element_collision_profile_pixel_mask_json_test.dart
```

Resultat:

```text
+6: All tests passed!
```

### Test legacy apres correction

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_editor_json_compat_collision_test.dart
```

Resultat:

```text
+3: All tests passed!
```

### Tests Lot 1

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/map_terrain_autotile_characterization_test.dart
```

Resultat:

```text
+21: All tests passed!
```

### Tests Lot 2

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/tile_visual_frame_timeline_test.dart
```

Resultat:

```text
+16: All tests passed!
```

### Analyse statique ciblee

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze \
  lib/src/models/element_collision_profile.dart \
  test/element_collision_profile_pixel_mask_json_test.dart
```

Resultat:

```text
Analyzing element_collision_profile.dart, element_collision_profile_pixel_mask_json_test.dart...
No issues found!
```

### Test complet map_core

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```

Resultat:

```text
+173: All tests passed!
```

## 11. Resultats des tests

Tous les tests requis pour ce lot passent:

- `legacy_editor_json_compat_collision_test.dart`: `+3`;
- `element_collision_profile_pixel_mask_json_test.dart`: `+6`;
- `map_terrain_autotile_characterization_test.dart`: `+21`;
- `tile_visual_frame_timeline_test.dart`: `+16`;
- analyse ciblee: `No issues found!`;
- `map_core` complet: `+173`.

Le rouge historique du test complet `map_core` est corrige.

## 12. Ce qui n'a volontairement pas ete fait

Ce lot n'a pas:

- cree de modele `Surface`;
- cree de `SurfaceEngine`;
- modifie les fichiers Lot 1 ou Lot 2;
- modifie `tile_visual_frame_timeline.dart`;
- modifie `map_terrain_autotile.dart`;
- modifie `ProjectManifest` pour ajouter des surfaces;
- modifie `map_runtime`;
- modifie `map_editor`;
- modifie `map_gameplay`;
- modifie manuellement un `.g.dart`;
- modifie manuellement un `.freezed.dart`;
- converti les anciennes listes de masque en masques modernes;
- masque globalement les erreurs de parsing;
- supprime un `collisionProfile` entier a cause d'un champ de masque invalide.

## 13. Points de vigilance pour les futurs modeles JSON Surface

Ce bug est un bon rappel pour les futurs modeles Surface:

- quand un ancien champ devient un champ connu avec un type plus strict, le generated parser peut planter avant la migration metier;
- les factories `fromJson` peuvent etre un bon endroit pour normaliser localement les champs legacy connus;
- les normalisations doivent etre ciblees, pas des `try/catch` globaux;
- une valeur legacy incompatible ne doit pas detruire tout un objet si le reste du payload est encore utile;
- les formats inconnus ne doivent pas etre convertis arbitrairement;
- les tests doivent couvrir a la fois donnees valides modernes et donnees invalides legacy.

Pour Surface Engine, cela suggere d'ajouter des tests JSON de compatibilite des le premier modele persiste.

## 14. Autocritique finale

La correction est volontairement conservative. Elle ne resout que les champs de masque connus qui peuvent avoir une ancienne forme incompatible.

Limites:

- une map de masque avec un schema interne invalide continuera de lever une erreur via `ElementCollisionPixelMask.fromJson`;
- les anciennes listes `pixelMask` ne sont pas migrees vers un masque pixel moderne, car leur encodage exact n'est pas defini ici;
- la normalisation est privee a `element_collision_profile.dart`, donc non reutilisable telle quelle ailleurs.

Ces limites sont intentionnelles. Le lot visait a rendre le parsing tolerant au legacy non-map sans affaiblir le contrat JSON moderne.

## 15. Ce que le prompt semble discutable ou incomplet

### Le test parle d'"unknown legacy keys", mais `pixelMask` n'est plus inconnu

Le nom du test historique dit "unknown legacy keys", mais le champ qui casse est devenu connu: `pixelMask`. Le probleme vient justement du fait que ce nom est maintenant mappe vers `collisionMask`.

### Le format ancien de `List<int>` n'est pas specifie

Le prompt donne l'exemple `<int>[1, 0, 1]`, mais ne definit pas son encodage historique. La decision prudente est donc de l'ignorer plutot que de l'interpreter.

### La migration manifest aurait pu etre un autre point de correction

`migrateProjectManifestJson` aurait pu supprimer le champ avant parsing du manifest. Mais cela n'aurait pas protege les appels directs a `ElementCollisionProfile.fromJson`. Le factory local est donc plus robuste et plus ciblé.

## 16. Auto-review independante

### Est-ce que le lot est reste strictement limite a la dette legacy collision JSON?

Oui. Seuls le modele collision source, son test JSON et ce rapport ont ete touches.

### Est-ce qu'aucun modele Surface n'a ete cree?

Oui. Aucun type ou modele Surface n'a ete ajoute.

### Est-ce qu'aucun fichier runtime/editor/gameplay n'a ete modifie?

Oui. Aucun fichier `map_runtime`, `map_editor` ou `map_gameplay` n'a ete modifie.

### Est-ce que les fichiers generes `.g.dart` / `.freezed.dart` n'ont pas ete modifies manuellement?

Oui. `element_collision_profile.g.dart` a ete consulte en lecture seule. Aucun fichier generated n'a ete modifie.

### Est-ce que le test legacy existant passe sans etre affaibli?

Oui. `legacy_editor_json_compat_collision_test.dart` passe avec `+3`. Le test n'a pas ete modifie.

### Est-ce que les masques valides continuent de parser?

Oui. Les tests couvrent `pixelMask`, `visualMask` et `occlusionMask` valides.

### Est-ce que les masques invalides legacy sont ignores proprement?

Oui. Les champs non-map sont retires avant le generated parser, et le reste du profil parse.

### Est-ce que les tests des Lots 1 et 2 passent toujours?

Oui. Lot 1 passe avec `+21`, Lot 2 passe avec `+16`.

### Est-ce que `map_core` complet passe?

Oui. `/opt/homebrew/bin/dart test` passe avec `+173`.

### Est-ce que les commandes Git interdites n'ont pas ete utilisees?

Oui. Aucune commande Git d'ecriture n'a ete utilisee.

### Est-ce que le rapport est assez detaille?

Oui. Il documente la cause, la correction, les tests, les resultats, les non-objectifs et les vigilances Surface.

### Est-ce que quelque chose du prompt etait ambigu ou discutable?

Oui. Le format exact de l'ancien `List<int>` n'est pas specifie, donc il ne doit pas etre converti arbitrairement en masque moderne.
