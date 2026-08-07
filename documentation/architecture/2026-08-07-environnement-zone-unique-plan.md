# Zone unique par calque d'environnement — plan d'implémentation

> **Pour les agents :** utiliser `superpowers:subagent-driven-development` ou
> `superpowers:executing-plans` pour dérouler ce plan tâche par tâche. Les
> étapes sont cochables (`- [ ]`).

**But :** un calque d'environnement porte exactement une zone, et il devient
impossible d'en avoir plus — dans le modèle, dans l'API canonique et dans
l'éditeur.

**Architecture :** l'invariant est posé au seul point de construction de
`EnvironmentLayerContent`, qui rejette plus d'une zone. Les cartes existantes
sont réparées à la lecture, avant que ce constructeur ne soit atteint, par une
migration JSON branchée dans `MapData.fromJson` — même mécanique que
`_migrateLegacyTileLayers`. L'éditeur cesse alors d'exposer le concept : la zone
naît avec le calque et ne se choisit plus.

**Stack :** Dart / Flutter, `flutter test`, packages `map_core`, `map_authoring`,
`map_editor`.

## Contraintes globales

- La forme sérialisée reste `content.areas: []` (tableau), de longueur 0 ou 1.
  On ne change pas le schéma JSON : seul l'invariant change. Cela évite de
  toucher les 24 fichiers `lib` et 57 fichiers de test qui itèrent la liste.
- Aucune carte existante ne doit cesser de se charger. `map_port_brisants.json`
  porte 2 zones sur 2 presets distincts : elle doit devenir 2 calques
  d'environnement, sans perte de masque ni de placements générés.
- Une zone vide = masque à 0 cellule **et** aucun placement généré. Une zone
  vide surnuméraire est supprimée, jamais éclatée en calque.
- Messages d'interface en français, commentaires et messages de commit en
  anglais, conformément au dépôt.
- Chaque tâche se termine par un commit vert.

---

## Structure de fichiers

| Fichier | Responsabilité |
|---|---|
| `packages/map_core/lib/src/compatibility/environment_single_area_migration.dart` | **Créé.** Répare le JSON des calques d'environnement multi-zones. |
| `packages/map_core/lib/src/models/map_data.dart` | **Modifié.** Branche la migration dans `fromJson`. |
| `packages/map_core/lib/src/models/environment.dart` | **Modifié.** Invariant « au plus une zone » + accesseur `area`. |
| `packages/map_authoring/lib/src/domains/maps/environment_actions.dart` | **Modifié.** `attach_to_tile_layer` crée la zone ; `area_create` disparaît. |
| `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_environment_inspector.dart` | **Modifié.** Plus de sélecteur de zone ni de création/suppression. |
| `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_layers_inspector.dart` | **Modifié.** Activer l'environnement demande le preset et crée la zone. |

---

### Tâche 1 : migration JSON des calques multi-zones

**Fichiers :**
- Créer : `packages/map_core/lib/src/compatibility/environment_single_area_migration.dart`
- Modifier : `packages/map_core/lib/src/models/map_data.dart:47`
- Modifier : `packages/map_core/lib/map_core.dart` (export)
- Test : `packages/map_core/test/environment_single_area_migration_test.dart`

**Interfaces :**
- Produit : `Map<String, dynamic> migrateEnvironmentSingleAreaMapJson(Map<String, dynamic> json)`
  — rend `json` inchangé (même instance) si aucun calque n'a plus d'une zone.

- [ ] **Étape 1 : écrire le test qui échoue**

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _area(String id, {int painted = 0, int generated = 0}) {
  return <String, dynamic>{
    'id': id,
    'name': 'Zone $id',
    'presetId': 'preset_$id',
    'mask': <String, dynamic>{
      'width': 2,
      'height': 2,
      'cells': <bool>[painted > 0, false, false, false],
    },
    'seed': 1,
    'generatedPlacementIds': <String>[
      for (var i = 0; i < generated; i++) 'p_${id}_$i',
    ],
  };
}

Map<String, dynamic> _mapWith(List<Map<String, dynamic>> areas) {
  return <String, dynamic>{
    'id': 'm',
    'name': 'M',
    'version': 'v6',
    'size': <String, dynamic>{'width': 2, 'height': 2},
    'layers': <Object?>[
      <String, dynamic>{
        'runtimeType': 'environment',
        'id': 'env',
        'name': 'Env',
        'content': <String, dynamic>{
          'targetTileLayerId': 'tiles',
          'areas': areas,
        },
      },
    ],
  };
}

void main() {
  test('drops the empty extras and keeps the authored zone', () {
    final migrated = migrateEnvironmentSingleAreaMapJson(
      _mapWith(<Map<String, dynamic>>[
        _area('a1'),
        _area('a2', painted: 1, generated: 3),
        _area('a3'),
      ]),
    );

    final layers = migrated['layers'] as List<Object?>;
    expect(layers, hasLength(1));
    final areas = ((layers.single as Map)['content']
        as Map)['areas'] as List<Object?>;
    expect(areas, hasLength(1));
    expect((areas.single as Map)['id'], 'a2');
  });

  test('splits several authored zones into one layer each', () {
    final migrated = migrateEnvironmentSingleAreaMapJson(
      _mapWith(<Map<String, dynamic>>[
        _area('a1', painted: 1),
        _area('a2', generated: 2),
      ]),
    );

    final layers = (migrated['layers'] as List<Object?>)
        .cast<Map<String, dynamic>>();
    expect(layers, hasLength(2));
    expect(layers[0]['id'], 'env');
    expect(layers[1]['id'], 'env__a2');
    for (final layer in layers) {
      expect(((layer['content'] as Map)['areas'] as List), hasLength(1));
      expect((layer['content'] as Map)['targetTileLayerId'], 'tiles');
    }
  });

  test('keeps a single empty zone rather than emptying the layer', () {
    final migrated = migrateEnvironmentSingleAreaMapJson(
      _mapWith(<Map<String, dynamic>>[_area('a1')]),
    );

    final layers = migrated['layers'] as List<Object?>;
    final areas = ((layers.single as Map)['content']
        as Map)['areas'] as List<Object?>;
    expect(areas, hasLength(1));
  });

  test('returns the same instance when nothing needs repairing', () {
    final json = _mapWith(<Map<String, dynamic>>[_area('a1', painted: 1)]);
    expect(identical(migrateEnvironmentSingleAreaMapJson(json), json), isTrue);
  });
}
```

- [ ] **Étape 2 : lancer le test et vérifier qu'il échoue**

```bash
cd packages/map_core && dart test test/environment_single_area_migration_test.dart
```

Attendu : échec de compilation, `migrateEnvironmentSingleAreaMapJson` non défini.

- [ ] **Étape 3 : écrire la migration**

```dart
/// Repairs maps authored before an Environment layer was limited to one zone.
///
/// Extra zones that were never drawn on carry no authored work, so they are
/// dropped. Zones that do carry work become one layer each: the invariant is
/// one zone per layer, and a map is allowed as many layers as it needs.
Map<String, dynamic> migrateEnvironmentSingleAreaMapJson(
  Map<String, dynamic> json,
) {
  final rawLayers = json['layers'];
  if (rawLayers is! List) return json;
  var changed = false;
  final layers = <Object?>[];
  for (final rawLayer in rawLayers) {
    if (rawLayer is! Map || rawLayer['runtimeType'] != 'environment') {
      layers.add(rawLayer);
      continue;
    }
    final layer = Map<String, dynamic>.from(rawLayer);
    final content = layer['content'];
    if (content is! Map) {
      layers.add(rawLayer);
      continue;
    }
    final rawAreas = content['areas'];
    if (rawAreas is! List || rawAreas.length <= 1) {
      layers.add(rawLayer);
      continue;
    }
    final authored = <Map<String, dynamic>>[];
    for (final rawArea in rawAreas) {
      if (rawArea is! Map) continue;
      final area = Map<String, dynamic>.from(rawArea);
      if (_environmentAreaCarriesWork(area)) authored.add(area);
    }
    if (authored.isEmpty) {
      // Every zone was empty: keep the first so the layer stays authorable.
      final first = rawAreas.first;
      if (first is Map) authored.add(Map<String, dynamic>.from(first));
    }
    changed = true;
    for (var index = 0; index < authored.length; index += 1) {
      final area = authored[index];
      final suffix = index == 0 ? '' : '__${area['id']}';
      layers.add(<String, dynamic>{
        ...layer,
        'id': '${layer['id']}$suffix',
        if (index > 0) 'name': '${layer['name']} — ${area['name']}',
        'content': <String, dynamic>{
          ...Map<String, dynamic>.from(content),
          'areas': <Object?>[area],
        },
      });
    }
  }
  if (!changed) return json;
  return <String, dynamic>{...json, 'layers': layers};
}

bool _environmentAreaCarriesWork(Map<String, dynamic> area) {
  final generated = area['generatedPlacementIds'];
  if (generated is List && generated.isNotEmpty) return true;
  final mask = area['mask'];
  if (mask is! Map) return false;
  final cells = mask['cells'];
  if (cells is! List) return false;
  return cells.any((cell) => cell == true);
}
```

- [ ] **Étape 4 : brancher la migration dans `MapData.fromJson`**

Dans `packages/map_core/lib/src/models/map_data.dart`, remplacer la première
ligne de `fromJson` :

```dart
    final canonical = migrateEnvironmentSingleAreaMapJson(
      _migrateLegacyTileLayers(json),
    );
```

Ajouter l'import `import '../compatibility/environment_single_area_migration.dart';`
et l'export dans `packages/map_core/lib/map_core.dart` :

```dart
export 'src/compatibility/environment_single_area_migration.dart';
```

- [ ] **Étape 5 : lancer les tests**

```bash
cd packages/map_core && dart test test/environment_single_area_migration_test.dart
```

Attendu : `All tests passed!`

- [ ] **Étape 6 : vérifier que rien d'autre ne casse**

```bash
cd packages/map_core && dart test
```

Attendu : mêmes échecs qu'avant la tâche (les tests `border/` sensibles à la
charge), aucun nouvel échec.

- [ ] **Étape 7 : commit**

```bash
git add packages/map_core/lib/src/compatibility/environment_single_area_migration.dart packages/map_core/lib/src/models/map_data.dart packages/map_core/lib/map_core.dart packages/map_core/test/environment_single_area_migration_test.dart
git commit -m "fix(environment): repair multi-zone layers on load"
```

---

### Tâche 2 : invariant « au plus une zone » dans le modèle

**Fichiers :**
- Modifier : `packages/map_core/lib/src/models/environment.dart:497-520`
- Test : `packages/map_core/test/environment_layer_content_test.dart`

**Interfaces :**
- Consomme : la migration de la tâche 1 (sans elle, les cartes existantes
  lèveraient à la lecture).
- Produit : `EnvironmentArea? get area` sur `EnvironmentLayerContent` ;
  le constructeur lève `ArgumentError` au-delà d'une zone.

- [ ] **Étape 1 : écrire le test qui échoue**

```dart
  test('refuses more than one zone', () {
    expect(
      () => EnvironmentLayerContent(
        targetTileLayerId: 'tiles',
        areas: <EnvironmentArea>[_area('a1'), _area('a2')],
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('exposes the single zone directly', () {
    final content = EnvironmentLayerContent(
      targetTileLayerId: 'tiles',
      areas: <EnvironmentArea>[_area('a1')],
    );
    expect(content.area?.id, 'a1');
    expect(EnvironmentLayerContent.emptyContent.area, isNull);
  });
```

`_area` construit un `EnvironmentArea` minimal ; reprendre le helper déjà
présent dans ce fichier de test.

- [ ] **Étape 2 : lancer le test et vérifier qu'il échoue**

```bash
cd packages/map_core && dart test test/environment_layer_content_test.dart
```

Attendu : le premier test échoue (aucune exception levée), le second ne compile
pas (`area` non défini).

- [ ] **Étape 3 : poser l'invariant**

Dans la factory `EnvironmentLayerContent`, après la boucle de déduplication :

```dart
    if (copy.length > 1) {
      throw ArgumentError.value(
        copy.length,
        'areas',
        'An Environment layer carries exactly one zone. Author a second '
            'Environment layer on the same TileLayer instead.',
      );
    }
```

Et à côté de `hasAreas` :

```dart
  /// The single zone this layer carries, or null while it has none.
  EnvironmentArea? get area => areas.isEmpty ? null : areas.first;
```

- [ ] **Étape 4 : lancer les tests**

```bash
cd packages/map_core && dart test test/environment_layer_content_test.dart
```

Attendu : `All tests passed!`

- [ ] **Étape 5 : vérifier map_core et map_editor**

```bash
cd packages/map_core && dart test
cd ../map_editor && flutter test test/environment_studio
```

Attendu : aucun nouvel échec. Tout test qui construisait deux zones doit être
corrigé ici — il documentait un comportement qui n'existe plus.

- [ ] **Étape 6 : commit**

```bash
git add packages/map_core/lib/src/models/environment.dart packages/map_core/test/environment_layer_content_test.dart
git commit -m "feat(environment): make a second zone impossible to build"
```

---

### Tâche 3 : l'API canonique crée la zone avec le calque

**Fichiers :**
- Modifier : `packages/map_authoring/lib/src/domains/maps/environment_actions.dart:137-160`
- Test : `packages/map_authoring/test/domains/maps/environment_actions_test.dart`
- Test : `packages/map_core/test/authoring_capability_inventory_test.dart`

**Interfaces :**
- Consomme : l'invariant de la tâche 2.
- Produit : `environment.attach_to_tile_layer` accepte désormais un paramètre
  `presetId` obligatoire et rend un calque déjà pourvu de sa zone.
  `environment.area_create` n'existe plus.

- [ ] **Étape 1 : écrire le test qui échoue**

```dart
  test('attaching an environment already carries its zone', () async {
    final result = await plan(
      actionId: 'environment.attach_to_tile_layer',
      parameters: <String, Object?>{
        'mapId': 'm',
        'tileLayerId': 'tiles',
        'presetId': 'preset1',
      },
    );

    final layer = result.map.layers.whereType<EnvironmentLayer>().single;
    expect(layer.content.area, isNotNull);
    expect(layer.content.area!.presetId, 'preset1');
  });

  test('area_create is gone', () {
    expect(
      EnvironmentActions.descriptors.map((item) => item.id),
      isNot(contains('environment.area_create')),
    );
  });
```

Reprendre le helper `plan(...)` déjà utilisé dans ce fichier de test.

- [ ] **Étape 2 : lancer le test et vérifier qu'il échoue**

```bash
cd packages/map_authoring && dart test test/domains/maps/environment_actions_test.dart
```

Attendu : `attach_to_tile_layer` rejette le paramètre `presetId` inconnu.

- [ ] **Étape 3 : fusionner la création de zone dans l'attachement**

Dans `environment_actions.dart` : retirer le descripteur
`'environment.area_create'` et sa branche de `build`, ajouter `presetId` aux
`allowedParameters` de `_attachToTileLayer`, et y créer la zone via le même
chemin que l'ancien `_areaCreate`.

- [ ] **Étape 4 : mettre l'inventaire à jour**

Dans `packages/map_core/test/authoring_capability_inventory_test.dart`, retirer
`'environment.area_create'` de l'ensemble attendu.

- [ ] **Étape 5 : lancer les tests**

```bash
cd packages/map_authoring && dart test test/domains test/parity
cd ../map_core && dart test test/authoring_capability_inventory_test.dart
```

Attendu : `All tests passed!` (hors échecs préexistants).

- [ ] **Étape 6 : commit**

```bash
git add packages/map_authoring packages/map_core/test/authoring_capability_inventory_test.dart
git commit -m "feat(environment): fold zone creation into attaching a layer"
```

---

### Tâche 4 : l'éditeur cesse d'exposer la zone

**Fichiers :**
- Modifier : `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_environment_inspector.dart` (`_ZoneCard`)
- Modifier : `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_layers_inspector.dart` (`buildEnableEnvironmentAction`)
- Modifier : `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` (`enableEnvironmentForActiveTileLayer`)
- Test : `packages/map_editor/test/features/editor/presentation/world_map/world_map_environment_inspector_test.dart`
- Test : `packages/map_editor/test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart`

**Interfaces :**
- Consomme : `EnvironmentLayerContent.area` (tâche 2).
- Produit : `enableEnvironmentForActiveTileLayer({required String presetId})`.

- [ ] **Étape 1 : écrire le test qui échoue**

```dart
  testWidgets('the zone is never offered as a choice', (tester) async {
    final harness = _Harness(
      _map(areas: <EnvironmentArea>[_area()]),
      activeLayerId: 'tiles',
      selectedEnvironmentAreaId: 'area1',
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    for (final key in const <String>[
      'world-map-environment-area',
      'world-map-environment-create-area',
      'world-map-environment-rename',
      'world-map-environment-delete',
    ]) {
      expect(find.byKey(ValueKey<String>(key)), findsNothing, reason: key);
    }
    // The preset stays changeable: it is the zone's only remaining choice.
    expect(
      find.byKey(const ValueKey<String>('world-map-environment-preset')),
      findsOneWidget,
    );
  });
```

- [ ] **Étape 2 : lancer le test et vérifier qu'il échoue**

```bash
cd packages/map_editor && flutter test test/features/editor/presentation/world_map/world_map_environment_inspector_test.dart
```

Attendu : échec, le sélecteur de zone est encore là.

- [ ] **Étape 3 : remplacer `_ZoneCard` par une carte « Preset »**

Supprimer le sélecteur de zone, « Ouvrir une zone », « Renommer » et
« Supprimer ». Garder un unique `PokeMapDropdownField<String>` de clé
`world-map-environment-preset` câblé sur
`notifier.setEnvironmentAreaPresetForActiveTileLayer`, alimenté par
`state.project?.environmentPresets`.

- [ ] **Étape 4 : demander le preset au moment d'activer l'environnement**

Dans `world_map_layers_inspector.dart`, `buildEnableEnvironmentAction` ouvre le
sélecteur de preset (réutiliser `_showWorldMapEnvironmentTargetDialog` comme
modèle) puis appelle
`notifier.enableEnvironmentForActiveTileLayer(presetId: picked.id)`.

Dans `editor_notifier.dart`, `enableEnvironmentForActiveTileLayer` prend
`{required String presetId}` et enchaîne l'attachement puis la création de la
zone dans une seule mutation.

- [ ] **Étape 5 : lancer les tests**

```bash
cd packages/map_editor && flutter test test/features/editor/presentation/world_map test/environment_studio
```

Attendu : `All tests passed!`

- [ ] **Étape 6 : commit**

```bash
git add packages/map_editor
git commit -m "feat(environment): stop asking the author about zones"
```

---

### Tâche 5 : réparer les cartes de l'auteur

**Fichiers :**
- Aucun fichier du dépôt. Agit sur `~/Desktop/pokeMap Project/`.

**Interfaces :**
- Consomme : la migration de la tâche 1, déjà branchée à la lecture.

- [ ] **Étape 1 : constater l'état avant**

```bash
cd packages/map_core && dart run tool/environment_zone_report.dart "$HOME/Desktop/pokeMap Project"
```

Si l'outil n'existe pas, le script Python du rapport de session fait l'affaire :
il compte zones / zones utilisées / presets distincts par calque.

Attendu : `map_hanazuki_village` 10 zones dont 1 utilisée,
`map_port_brisants` 2 zones dont 2 utilisées.

- [ ] **Étape 2 : ouvrir puis enregistrer chaque carte concernée depuis l'éditeur**

La migration s'applique à la lecture ; l'enregistrement la fixe sur disque.
Ouvrir `map_hanazuki_village` puis `map_port_brisants`, et enregistrer.

- [ ] **Étape 3 : vérifier après**

Relancer le rapport de l'étape 1.

Attendu : `map_hanazuki_village` 1 calque d'environnement, 1 zone, 1851
cellules peintes et 655 placements conservés. `map_port_brisants` 2 calques
d'environnement, 1 zone chacun, les deux presets conservés.

- [ ] **Étape 4 : jouer la carte pour vérifier le rendu**

Ouvrir `map_hanazuki_village` dans l'éditeur : la végétation générée doit être
identique à avant migration.

---

## Auto-revue

**Couverture du besoin.** « Une zone unique par calque » → tâche 2 (invariant).
« Impossible d'en avoir plus » → tâche 2 côté modèle, tâche 3 côté API
canonique, tâche 4 côté interface. « Faire les choses proprement » → tâche 1
pour que les cartes existantes survivent, tâche 5 pour que les tiennes soient
réellement réparées.

**Point ouvert assumé.** La forme sérialisée garde un tableau `areas`. C'est un
choix de coût : l'invariant rend le second élément impossible, mais le stockage
reste pluriel. Passer à un champ `area` unique dans le JSON demanderait de
toucher 24 fichiers `lib` et 57 fichiers de test, et une seconde migration
d'écriture. À arbitrer si la forme du fichier compte autant que le
comportement.

**Cohérence des noms.** `migrateEnvironmentSingleAreaMapJson` (tâche 1),
`EnvironmentLayerContent.area` (tâche 2),
`environment.attach_to_tile_layer` + `presetId` (tâche 3),
`enableEnvironmentForActiveTileLayer({required String presetId})` et
`setEnvironmentAreaPresetForActiveTileLayer` (tâche 4).
