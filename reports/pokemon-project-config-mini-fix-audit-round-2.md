# Audit ciblé — Mini-fix lot 10 — migration du manifest Pokémon

## 1. Résumé exécutif
### Verdict
**GARDE**

Le mini-fix qui retire l’injection de :

```dart
if (!next.containsKey('pokemon')) {
  next['pokemon'] = <String, dynamic>{};
}
```

dans `migrateProjectManifestJson(...)` est cohérent avec l’architecture actuelle du projet et ne doit pas être revert.

### Pourquoi, en une phrase
Dans le codebase actuel, `migrateProjectManifestJson(...)` n’est jamais consommée comme un JSON “stabilisé” autonome : elle est toujours utilisée comme une couche de compatibilité juste avant `ProjectManifest.fromJson(...)`, et ce dernier porte déjà explicitement le fallback via `@Default(ProjectPokemonConfig())`.

### Niveau de sévérité réel
Ce mini-fix ne corrige pas un bug fonctionnel majeur ; il corrige une **redondance de responsabilité**. Ce n’est pas une urgence produit, mais c’est une amélioration saine et cohérente.

## 2. Problème exact audité
Question auditée :

- faut-il laisser la migration legacy injecter un bloc `pokemon` vide ;
- ou faut-il laisser le modèle appliquer son default lorsqu’un ancien `project.json` n’a pas de champ `pokemon` ?

Le point important n’est pas “est-ce que ça marche” ; les deux marchent.

Le vrai point est :
- **où doit vivre cette responsabilité** ;
- et si la doctrine actuelle du projet rend cette injection utile ou non.

## 3. Responsabilité réelle de `migrateProjectManifestJson(...)`
### 3.1 Ce que fait réellement la fonction aujourd’hui
`migrateProjectManifestJson(...)` ne se contente pas d’ajouter des defaults. Elle fait plusieurs types d’opérations :

1. **Compatibilité structurelle simple**
   - ajoute certains tableaux manquants (`dialogues`, `dialogueFolders`, `tilesetFolders`, `characters`) ;
   - renomme ou remappe certains champs legacy (`playerCharacterId` -> `defaultPlayerCharacterId`, `characterRef` / `spriteCharacterId` / `overworldCharacterId` -> `characterId`) ;
   - reclasse `terrainPresetCategories` vers `terrainCategories` et `pathCategories`.

2. **Réparation de payload legacy**
   - corrige la forme cassée de certains `collisionProfile` d’éléments ;
   - dérive `surfaceKind` depuis des champs legacy quand nécessaire.

### 3.2 Ce qu’elle n’est pas
Dans l’état actuel du projet, cette fonction **n’est pas** un canonicalizer complet du JSON projet.

Elle ne produit pas un manifest “pleinement explicite” où tous les defaults du modèle seraient injectés dans le JSON.

Exemples :
- `groups` a un `@Default([])` mais n’est pas injecté dans la migration ;
- `elementCategories` a un `@Default([])` mais n’est pas injecté ;
- `encounterTables`, `scripts`, `scenarios`, `globalProperties` ont des defaults mais ne sont pas tous injectés systématiquement ;
- `pokemon` fonctionne maintenant comme ces champs-là.

### 3.3 Conclusion sur sa responsabilité réelle
La responsabilité réelle actuelle est :

**une couche de compatibilité minimale + quelques réparations ciblées de payload legacy avant désérialisation.**

Ce n’est **pas** une fonction de normalisation exhaustive destinée à rendre le JSON final explicitement complet.

## 4. Call sites exacts de `migrateProjectManifestJson(...)`
Recherche effectuée dans le codebase :

```bash
rg -n "migrateProjectManifestJson\\(" -S
```

En excluant les fichiers de rapport, les call sites de code réels sont :

### 4.1 `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart:36`
Contexte :

```dart
final json = migrateProjectManifestJson(
  jsonDecode(content) as Map<String, dynamic>,
);
final manifest = ProjectManifest.fromJson(json);
ProjectValidator.validate(manifest);
return manifest;
```

Analyse :
- la migration est immédiatement suivie d’un `ProjectManifest.fromJson(...)` ;
- l’absence de `pokemon` dans le JSON migré ne pose aucun problème fonctionnel ;
- le fallback du modèle s’applique immédiatement ;
- il n’existe pas ici de consommation intermédiaire du `Map<String, dynamic>` migré.

Conclusion :
**aucun problème conceptuel ni fonctionnel** à ne plus injecter `pokemon`.

### 4.2 `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart:38`
Contexte :

```dart
final migrated = migrateProjectManifestJson(raw);
final manifest = ProjectManifest.fromJson(migrated);
ProjectValidator.validate(manifest);
return manifest;
```

Analyse :
- même pattern : compat JSON -> désérialisation immédiate ;
- aucun composant runtime ne lit le `Map<String, dynamic>` migré directement ;
- l’absence explicite de `pokemon` dans le JSON migré est sans effet tant que `ProjectManifest.fromJson(...)` suit immédiatement.

Conclusion :
**aucun risque pratique identifié**.

### 4.3 `packages/map_gameplay/test/placed_elements_collision_test.dart:99`
### 4.4 `packages/map_gameplay/test/placed_elements_collision_test.dart:138`
### 4.5 `packages/map_gameplay/test/placed_elements_collision_test.dart:142`
Contexte :

```dart
ProjectManifest.fromJson(
  migrateProjectManifestJson(_legacyBrokenProjectJson()),
)
```

Analyse :
- usage de test seulement ;
- la migration est immédiatement consommée par `fromJson(...)`.

Conclusion :
**aucun argument pour garder l’injection `pokemon` ici**.

### 4.6 `packages/map_core/test/legacy_editor_json_compat_collision_test.dart:9`
### 4.7 `packages/map_core/test/legacy_editor_json_compat_collision_test.dart:26`
### 4.8 `packages/map_core/test/legacy_editor_json_compat_collision_test.dart:35`
Contexte :
- tests unitaires `map_core`, même pattern migration -> `ProjectManifest.fromJson(...)`.

Conclusion :
**là aussi, pas de besoin d’un `pokemon` injecté côté migration**.

### 4.9 Synthèse sur les call sites
Dans le code réel du repo, **il n’existe aucun call site où le JSON retourné par `migrateProjectManifestJson(...)` est exploité en tant qu’artefact autonome stabilisé**.

C’est le point le plus important de l’audit.

Le faux bon argument serait :
> “Il vaut mieux injecter `pokemon` pour que le JSON migré soit complet.”

Ce serait recevable **seulement si** ce JSON migré était réutilisé ailleurs comme JSON normalisé. Ce n’est pas le cas dans le codebase actuel.

## 5. Doctrine implicite actuelle du projet sur les migrations legacy
### 5.1 Doctrine observée
La doctrine actuelle est **mixte**, mais avec une dominante claire :

- la migration fait des **réparations utiles et ciblées** quand un ancien payload ne peut pas être correctement compris tel quel ;
- elle injecte aussi quelques champs manquants historiques ;
- mais elle **ne cherche pas** à matérialiser tous les defaults du modèle dans le JSON.

### 5.2 Exemples concrets côté “injecter/normaliser”
Dans `legacy_editor_json_compat.dart`, on voit :

- ajout de `dialogues` si absent ;
- ajout de `dialogueFolders` si absent ;
- ajout de `tilesetFolders` si absent ;
- ajout de `characters` si absent.

Cela montre qu’il existe un héritage de normalisation partielle.

### 5.3 Exemples concrets côté “laisser le modèle appliquer les defaults”
Dans `project_manifest.dart` et `project_manifest.g.dart`, de nombreux champs ont un fallback direct au niveau désérialisation :

- `groups` -> `const []`
- `dialogues` -> `const []`
- `scripts` -> `const []`
- `scenarios` -> `const []`
- `characters` -> `const []`
- `settings` -> `const ProjectSettings()`
- `pokemon` -> `const ProjectPokemonConfig()`
- `globalProperties` -> `const {}`

Et pourtant, la migration n’injecte pas systématiquement tous ces champs.

### 5.4 Conclusion doctrinale
La doctrine implicite actuelle n’est pas :

> “Le JSON migré doit être entièrement explicite.”

Elle est plutôt :

> “La migration corrige ce qui est legacy/bloquant ou historiquement utile, puis le modèle finit le travail.”

Dans cette doctrine, `pokemon` est mieux placé **dans le modèle** que **dans la migration**.

## 6. Est-ce une vraie amélioration ou une perte de normalisation utile ?
### 6.1 Ce que le retrait améliore vraiment
Le retrait améliore réellement :
- la séparation des responsabilités ;
- la lisibilité de la migration ;
- la cohérence avec les call sites réels ;
- l’alignement avec le fait que `ProjectManifest.fromJson(...)` porte déjà ce default.

### 6.2 Ce qu’il ne faut pas sur-vendre
Il ne faut pas raconter que l’ancienne ligne était catastrophique.

Elle était :
- **redondante** ;
- **benigne** ;
- mais **pas nécessaire**.

Ce n’était pas un bug critique. C’était un bruit de responsabilité.

### 6.3 Ce qu’il ne faut pas sous-estimer
Si on accepte sans réfléchir que la migration ajoute des defaults déjà couverts par le modèle, on finit par :
- dupliquer la politique de fallback à deux endroits ;
- augmenter le coût de maintenance ;
- rendre la doctrine de migration floue.

Donc oui, c’est un petit point, mais ce n’est pas du purisme gratuit.

## 7. Recommandation nette
### Verdict final
**GARDE**

### Pourquoi
Je recommande de **garder la suppression** parce que :

1. tous les call sites réels consomment immédiatement le JSON migré via `ProjectManifest.fromJson(...)` ;
2. `ProjectManifest.fromJson(...)` a déjà un fallback explicite et stable pour `pokemon` ;
3. la migration n’a pas de rôle avéré de canonicalisation complète ;
4. remettre l’injection réintroduirait une duplication de responsabilité sans gain concret.

## 8. Faut-il revert ?
### Réponse
**Non.**

Remettre l’injection serait surtout :
- une préférence de style pour un JSON migré “plus explicite” ;
- pas une nécessité technique démontrée par le code actuel.

### Faux bon argument à écarter
> “Comme la migration injecte déjà d’autres champs manquants, il faut aussi réinjecter `pokemon`.”

Ce raisonnement est faible ici, parce que :
- la migration n’injecte pas tous les defaults ;
- `pokemon` n’a pas de logique de conversion legacy ;
- aucun call site n’a besoin du champ matérialisé dans le `Map`.

## 9. Le test ajouté est-il suffisant ?
### Réponse courte
**Fonctionnellement : oui.**

Le test ajouté prouve le point critique :
- un manifest legacy sans bloc `pokemon` reste lisible ;
- on retombe bien sur `const ProjectPokemonConfig()` après désérialisation.

### Réponse plus précise
Si l’objectif est de verrouiller le comportement fonctionnel, le test est suffisant.

Si l’objectif est de verrouiller aussi la **doctrine exacte de migration**, alors il manque un test plus directement ciblé :

```dart
test('migration does not synthesize pokemon when absent', () {
  final migrated = migrateProjectManifestJson(_legacyBrokenProjectJson());

  expect(migrated.containsKey('pokemon'), isFalse);
});
```

### Mon avis
Ce test supplémentaire serait **plus pertinent doctrinalement**, mais il n’est **pas strictement nécessaire** pour justifier le verdict GARDE.

Autrement dit :
- le test actuel suffit pour dire “le mini-fix ne casse rien” ;
- ce test supplémentaire servirait à dire “on assume explicitement cette responsabilité”.

## 10. Patch minimal si on voulait REVERT
Je ne recommande pas ce revert.

Mais si quelqu’un décidait malgré tout de revenir en arrière, le patch minimal serait :

```diff
diff --git a/packages/map_core/lib/src/io/legacy_editor_json_compat.dart b/packages/map_core/lib/src/io/legacy_editor_json_compat.dart
@@
   if (!next.containsKey('characters')) {
     next['characters'] = <dynamic>[];
   }
+  if (!next.containsKey('pokemon')) {
+    next['pokemon'] = <String, dynamic>{};
+  }
   final settings = raw['settings'];
```

Et c’est tout.

Mais encore une fois : **je ne recommande pas ce patch**.

## 11. Fichiers inspectés pour cet audit
- `packages/map_core/lib/src/io/legacy_editor_json_compat.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_gameplay/test/placed_elements_collision_test.dart`
- `packages/map_core/test/legacy_editor_json_compat_collision_test.dart`

## 12. Commandes réellement exécutées
```bash
rg -n "migrateProjectManifestJson\\(" -S
sed -n '1,220p' packages/map_core/lib/src/io/legacy_editor_json_compat.dart
rg -n "ProjectManifest\\.fromJson|fromJson\\(Map<String, dynamic> json\\) =>\\s*_\\$ProjectManifestFromJson|loadProject|saveProject|migrateProjectManifestJson" packages/map_core packages/map_editor -S
sed -n '1,140p' packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '1,140p' packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
sed -n '80,170p' packages/map_gameplay/test/placed_elements_collision_test.dart
rg -n "dialogues: json\\['dialogues'\\]|dialogueFolders: json\\['dialogueFolders'\\]|tilesetFolders: json\\['tilesetFolders'\\]|characters: json\\['characters'\\]|pokemon: json\\['pokemon'\\]" packages/map_core/lib/src/models/project_manifest.g.dart -S
sed -n '70,130p' packages/map_core/lib/src/models/project_manifest.g.dart
sed -n '20,70p' packages/map_core/lib/src/models/project_manifest.dart
git status --short
git diff --stat -- packages/map_core/lib/src/io/legacy_editor_json_compat.dart packages/map_core/test/legacy_editor_json_compat_collision_test.dart
git diff -- packages/map_core/lib/src/io/legacy_editor_json_compat.dart packages/map_core/test/legacy_editor_json_compat_collision_test.dart
```

## 13. État Git utile au moment de l’audit
```text
 M packages/map_core/lib/src/io/legacy_editor_json_compat.dart
 M packages/map_core/test/legacy_editor_json_compat_collision_test.dart
?? reports/pokemon-project-config-mini-fix-round-1.md
```

Important :
- ces changements existaient déjà dans l’arbre de travail au moment de l’audit ;
- je ne les ai pas modifiés pour “forcer” la conclusion ;
- le présent audit n’ajoute aucun changement de code.

## 14. Conclusion honnête
Le bon jugement ici n’est pas “la ligne supprimée était mauvaise donc il fallait absolument l’enlever”, ni “la ligne était inoffensive donc autant la remettre”.

Le jugement correct est :

- **fonctionnellement**, les deux approches marchent ;
- **architecturalement**, dans ce codebase précis, la suppression est plus propre ;
- **doctrinalement**, la migration n’a pas de mandat clair pour matérialiser tous les defaults du modèle ;
- **pratiquement**, aucun call site réel n’a besoin de `pokemon` injecté dans le JSON migré.

Donc le mini-fix doit être **gardé**.
