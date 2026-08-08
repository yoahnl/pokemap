# Densité des variantes Smart Tile — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **Décision supersédante du 8 août 2026 :** la règle globale de longueur et son cliquet ont été retirés. Toutes les tâches et commandes de ce plan relatives à `tools/check_file_length.dart`, `tools/file_length_baseline.txt` ou au seuil de 3 000 lignes sont obsolètes et ne doivent plus être exécutées.

**Goal:** Permettre à un auteur d'ajuster la fréquence de chaque variante d'une règle Smart Tile depuis le panneau « Peindre » de World Map, avec un défaut porté par le preset et une surcharge optionnelle par calque.

**Architecture :** Le calcul de redistribution est une fonction pure isolée dans la couche application de `map_editor`. L'interface est un widget autonome inséré dans le panneau de peinture existant. L'écriture passe par deux chemins canoniques : `smart_tile.preset.publish` (déjà présent, à câbler) pour le défaut du preset, et une action nouvelle `smart_tile.layer.set_candidate_weights` pour la surcharge de calque. La surcharge est appliquée à la préparation du résolveur, jamais dans la boucle de cellules.

**Tech Stack :** Dart / Flutter, Freezed + json_serializable, Riverpod, `flutter_test`, design system PokeMap.

**Spec :** `documentation/architecture/2026-08-07-densite-variantes-smart-tile-design.md`

## Global Constraints

- Les poids d'une règle somment toujours exactement à `1000`. Constante partagée : `kSmartTileVariantWeightTotal = 1000`.
- Un poids valant `0` est légal et exclut le candidat du tirage ; un poids négatif est refusé.
- Un candidat que l'auteur a posé à `0` reste à exactement `0` et sort de la redistribution.
- Un candidat dont la part arrondirait à `0` sans avoir été posé à `0` est plancherisé à `1`.
- Aucune règle ne doit se retrouver sans candidat de poids positif.
- **Cliquet de longueur.** `tools/file_length_baseline.txt` gèle plusieurs fichiers que ce plan touche : ils sont tolérés au-dessus de 3000 lignes mais **ne peuvent jamais grandir**. Ils peuvent rétrécir.

  | Fichier | Gelé à | Conséquence pour ce plan |
  |---|---|---|
  | `…/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart` | 4412 | non touché, rien à faire |
  | `…/features/editor/state/editor_notifier.dart` | 14607 | Tasks 4 et 9 doivent nettoyer plus qu'elles n'ajoutent (Task 4a) |
  | `packages/map_core/lib/src/validation/validators.dart` | 3106 | Task 10 doit nettoyer plus qu'elle n'ajoute (Task 10a) |

  Vérifier après chaque tâche touchant ces fichiers : `dart tools/check_file_length.dart`. Le contrôle échoue à la moindre ligne de plus.
- Aucun fichier de production hors cliquet ne doit dépasser 3000 lignes.
- Toute nouvelle chaîne visible par l'auteur est en français, comme le reste du panneau.
- Commandes de test : `flutter test` dans `packages/map_editor`, `dart test` dans `packages/map_core` et `packages/map_authoring`.
- Travail directement sur `main`, un commit par tâche.

## File Structure

**Lot 1 — le réglage sur le preset**

| Fichier | Responsabilité |
|---|---|
| `packages/map_editor/lib/src/features/editor/application/smart_tile_variant_density.dart` *(créer)* | Fonctions pures de normalisation et de redistribution des poids. Aucune dépendance Flutter. |
| `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_smart_tile_density_section.dart` *(créer)* | Widget de la section repliée : ligne de résumé, curseurs, boutons. Purement présentationnel, piloté par callbacks. |
| `packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_publication_service.dart` *(modifier)* | Ajouter `publishPreset` : la forme `preset` de l'action canonique. |
| `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_smart_tile_paint_palette.dart` *(modifier)* | Insérer la section entre `Matière à peindre` et `Motifs réutilisables`. |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` *(modifier)* | Méthode `applySmartTilePresetVariantWeights`. |

**Lot 2 — la surcharge par calque**

| Fichier | Responsabilité |
|---|---|
| `packages/map_core/lib/src/models/map_layer.dart` *(modifier)* | Champ `candidateWeights` sur `MapLayer.smartTile`. |
| `packages/map_core/lib/src/operations/smart_tile_resolver.dart` *(modifier)* | Appliquer la surcharge à la préparation des règles. |
| `packages/map_core/lib/src/operations/smart_tile_layer_visual_resolver.dart` *(modifier)* | Passer la table du calque au résolveur préparé. |
| `packages/map_authoring/lib/src/domains/maps/smart_tile_layer_actions.dart` *(modifier)* | Action `smart_tile.layer.set_candidate_weights` et ses trois refus. |
| `packages/map_core/lib/src/validation/validators.dart` *(modifier)* | Avertissement sur les clés orphelines. |

---

# Lot 1 — le réglage sur le preset

## Task 1 : Calcul de redistribution

**Files:**
- Create: `packages/map_editor/lib/src/features/editor/application/smart_tile_variant_density.dart`
- Test: `packages/map_editor/test/features/editor/application/smart_tile_variant_density_test.dart`

**Interfaces:**
- Consomme : rien.
- Produit : `const int kSmartTileVariantWeightTotal`, `Map<String, int> normaliseSmartTileVariantWeights(Map<String, int> weights)`, `Map<String, int> rescaleSmartTileVariantWeights({required Map<String, int> weights, required String targetId, required int targetPermille})`. Les clés d'entrée sont des identifiants de candidat ; la sortie contient exactement les mêmes clés.

- [ ] **Step 1 : Écrire les tests qui échouent**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/application/smart_tile_variant_density.dart';

void main() {
  group('normaliseSmartTileVariantWeights', () {
    test('ramène le total à 1000 sans changer les proportions', () {
      final result = normaliseSmartTileVariantWeights(
        <String, int>{'a': 1000, 'b': 1000, 'c': 1000, 'd': 1000},
      );
      expect(result.values.reduce((a, b) => a + b), kSmartTileVariantWeightTotal);
      expect(result, <String, int>{'a': 250, 'b': 250, 'c': 250, 'd': 250});
    });

    test('répartit le reste au plus fort reste quand la division tombe mal', () {
      final result = normaliseSmartTileVariantWeights(
        <String, int>{'a': 1, 'b': 1, 'c': 1},
      );
      expect(result.values.reduce((a, b) => a + b), kSmartTileVariantWeightTotal);
      expect(result.values.toList()..sort(), <int>[333, 333, 334]);
    });

    test('laisse un poids nul à zéro', () {
      final result = normaliseSmartTileVariantWeights(
        <String, int>{'a': 1000, 'b': 0, 'c': 1000},
      );
      expect(result['b'], 0);
      expect(result['a']! + result['c']!, kSmartTileVariantWeightTotal);
    });
  });

  group('rescaleSmartTileVariantWeights', () {
    test('pose la cible et repartage le reste en conservant les rapports', () {
      final result = rescaleSmartTileVariantWeights(
        weights: <String, int>{'eau1': 250, 'eau2': 250, 'eau3': 250, 'roc': 250},
        targetId: 'roc',
        targetPermille: 10,
      );
      expect(result['roc'], 10);
      expect(result['eau1'], result['eau2']);
      expect(result['eau2'], result['eau3']);
      expect(result.values.reduce((a, b) => a + b), kSmartTileVariantWeightTotal);
    });

    test('une cible à zéro sort de la redistribution', () {
      final result = rescaleSmartTileVariantWeights(
        weights: <String, int>{'a': 500, 'roc': 500},
        targetId: 'roc',
        targetPermille: 0,
      );
      expect(result['roc'], 0);
      expect(result['a'], kSmartTileVariantWeightTotal);
    });

    test('borne la cible pour garder un point à chaque variante vivante', () {
      // 990 est inatteignable : il faut 1 pour mille à chacune des 40 autres
      // variantes positives. La cible est ramenée à 1000 - 40 = 960.
      final weights = <String, int>{'gros': 1000};
      for (var i = 0; i < 40; i += 1) {
        weights['petit$i'] = 1;
      }
      final result = rescaleSmartTileVariantWeights(
        weights: weights,
        targetId: 'gros',
        targetPermille: 990,
      );
      expect(result['gros'], 960);
      for (var i = 0; i < 40; i += 1) {
        expect(result['petit$i'], 1);
      }
      expect(result.values.reduce((a, b) => a + b), kSmartTileVariantWeightTotal);
    });

    test('la seule variante positive reste à 1000 quoi qu\'on demande', () {
      final result = rescaleSmartTileVariantWeights(
        weights: <String, int>{'seul': 1000, 'mort': 0},
        targetId: 'seul',
        targetPermille: 300,
      );
      expect(result['seul'], kSmartTileVariantWeightTotal);
      expect(result['mort'], 0);
    });

    test('refuse une cible hors bornes', () {
      expect(
        () => rescaleSmartTileVariantWeights(
          weights: <String, int>{'a': 1000},
          targetId: 'a',
          targetPermille: 1001,
        ),
        throwsArgumentError,
      );
    });

    test('refuse un identifiant absent', () {
      expect(
        () => rescaleSmartTileVariantWeights(
          weights: <String, int>{'a': 1000},
          targetId: 'inconnu',
          targetPermille: 500,
        ),
        throwsArgumentError,
      );
    });
  });
}
```

- [ ] **Step 2 : Lancer les tests pour vérifier qu'ils échouent**

Run: `cd packages/map_editor && flutter test test/features/editor/application/smart_tile_variant_density_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../smart_tile_variant_density.dart'`

- [ ] **Step 3 : Écrire l'implémentation**

```dart
/// Total fixe vers lequel les poids d'une règle Smart Tile sont normalisés.
///
/// Une part se lit donc en pour mille : 10 vaut 1 %. Cette résolution suffit
/// pour régler une densité à l'œil et garde chaque poids dans la bande que le
/// reste de l'éditeur accepte déjà.
const int kSmartTileVariantWeightTotal = 1000;

/// Ramène [weights] à [kSmartTileVariantWeightTotal] sans changer les parts.
///
/// Les entrées nulles restent nulles. Le reliquat d'arrondi va aux plus forts
/// restes, puis toute entrée non nulle tombée à zéro est remontée à 1 aux
/// dépens de la plus grosse.
Map<String, int> normaliseSmartTileVariantWeights(Map<String, int> weights) {
  return _distribute(weights, budget: kSmartTileVariantWeightTotal);
}

/// Pose [targetPermille] sur [targetId] et repartage le reste entre les autres
/// en conservant leurs rapports.
Map<String, int> rescaleSmartTileVariantWeights({
  required Map<String, int> weights,
  required String targetId,
  required int targetPermille,
}) {
  if (targetPermille < 0 || targetPermille > kSmartTileVariantWeightTotal) {
    throw ArgumentError.value(
      targetPermille,
      'targetPermille',
      'La part visée doit tenir dans [0, $kSmartTileVariantWeightTotal].',
    );
  }
  if (!weights.containsKey(targetId)) {
    throw ArgumentError.value(targetId, 'targetId', 'Candidat inconnu.');
  }

  final others = <String, int>{
    for (final entry in weights.entries)
      if (entry.key != targetId) entry.key: entry.value,
  };
  // Le plancher anti-« jamais » impose un plafond à la cible : chaque autre
  // variante positive garde au moins 1 pour mille. Et la seule variante
  // positive d'une règle reste à 1000 — rien ne peut compenser sa baisse.
  final positiveOtherCount = others.values.where((value) => value > 0).length;
  final int effectivePermille;
  if (positiveOtherCount == 0) {
    effectivePermille = kSmartTileVariantWeightTotal;
  } else {
    final ceiling = kSmartTileVariantWeightTotal - positiveOtherCount;
    effectivePermille =
        targetPermille > ceiling ? (ceiling < 0 ? 0 : ceiling) : targetPermille;
  }
  final distributed = _distribute(
    others,
    budget: kSmartTileVariantWeightTotal - effectivePermille,
  );
  return <String, int>{
    for (final key in weights.keys)
      key: key == targetId ? effectivePermille : distributed[key]!,
  };
}

/// Répartit [budget] entre [weights] proportionnellement, au plus fort reste.
Map<String, int> _distribute(Map<String, int> weights, {required int budget}) {
  final result = <String, int>{for (final key in weights.keys) key: 0};
  if (budget <= 0) return result;

  final positive = <String, int>{
    for (final entry in weights.entries)
      if (entry.value > 0) entry.key: entry.value,
  };
  if (positive.isEmpty) return result;

  final total = positive.values.reduce((a, b) => a + b);
  final remainders = <MapEntry<String, double>>[];
  var assigned = 0;
  for (final entry in positive.entries) {
    final exact = entry.value * budget / total;
    final floor = exact.floor();
    result[entry.key] = floor;
    assigned += floor;
    remainders.add(MapEntry<String, double>(entry.key, exact - floor));
  }

  remainders.sort((a, b) {
    final byRemainder = b.value.compareTo(a.value);
    return byRemainder != 0 ? byRemainder : a.key.compareTo(b.key);
  });
  for (var index = 0; assigned < budget; index += 1, assigned += 1) {
    final key = remainders[index % remainders.length].key;
    result[key] = result[key]! + 1;
  }

  _floorPositiveEntries(result, positive.keys);
  return result;
}

/// Remonte à 1 toute entrée voulue non nulle tombée à zéro, en prenant sur la
/// plus grosse. Sans ça, « rare » deviendrait « jamais » par simple arrondi.
void _floorPositiveEntries(Map<String, int> result, Iterable<String> intended) {
  for (final key in intended) {
    if (result[key]! > 0) continue;
    final donor = result.entries
        .where((entry) => entry.value > 1)
        .fold<MapEntry<String, int>?>(
          null,
          (best, entry) => best == null || entry.value > best.value ? entry : best,
        );
    if (donor == null) return;
    result[donor.key] = donor.value - 1;
    result[key] = 1;
  }
}
```

- [ ] **Step 4 : Lancer les tests pour vérifier qu'ils passent**

Run: `cd packages/map_editor && flutter test test/features/editor/application/smart_tile_variant_density_test.dart`
Expected: PASS — 9 tests

- [ ] **Step 5 : Commit**

```bash
git add packages/map_editor/lib/src/features/editor/application/smart_tile_variant_density.dart packages/map_editor/test/features/editor/application/smart_tile_variant_density_test.dart
git commit -m "feat(editor): compute Smart Tile variant density redistribution"
```

---

## Task 2 : `publishPreset` sur le service de publication

**Files:**
- Modify: `packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_publication_service.dart`
- Test: `packages/map_editor/test/smart_tiles_studio/smart_tile_publication_service_test.dart`

**Interfaces:**
- Consomme : `SmartTilePublicationGateway` (`load`, `plan`, `apply`), inchangé.
- Produit : `Future<String> SmartTilePublicationService.publishPreset({required String projectRootPath, required ProjectSmartTilePreset preset})`, qui renvoie l'identifiant de reçu.

- [ ] **Step 1 : Écrire le test qui échoue**

Ajouter dans le fichier de test existant, en réutilisant le faux `SmartTilePublicationGateway` déjà présent :

```dart
test('publishPreset envoie la charge preset et renvoie le reçu', () async {
  final gateway = FakeSmartTilePublicationGateway();
  const service = SmartTilePublicationService(gateway: gateway);
  final preset = _preset(id: 'eau', weightOfFirstCandidate: 40);

  final receipt = await service.publishPreset(
    projectRootPath: '/projet',
    preset: preset,
  );

  expect(receipt, gateway.lastReceiptId);
  expect(gateway.lastParameters!.keys, <String>['preset']);
  expect(
    (gateway.lastParameters!['preset']! as Map<String, Object?>)['id'],
    'eau',
  );
  expect(gateway.lastExpectedRevision, gateway.snapshotRevision);
});

test('publishPreset dérive une clé d\'idempotence stable du contenu', () async {
  final gateway = FakeSmartTilePublicationGateway();
  const service = SmartTilePublicationService(gateway: gateway);
  final preset = _preset(id: 'eau', weightOfFirstCandidate: 40);

  await service.publishPreset(projectRootPath: '/projet', preset: preset);
  final first = gateway.lastIdempotencyKey;
  await service.publishPreset(projectRootPath: '/projet', preset: preset);

  expect(gateway.lastIdempotencyKey, first);
});
```

- [ ] **Step 2 : Lancer le test pour vérifier qu'il échoue**

Run: `cd packages/map_editor && flutter test test/smart_tiles_studio/smart_tile_publication_service_test.dart`
Expected: FAIL — `The method 'publishPreset' isn't defined for the type 'SmartTilePublicationService'`

- [ ] **Step 3 : Écrire l'implémentation**

Ajouter à `SmartTilePublicationService` (imports : `dart:convert`, `package:crypto/crypto.dart`) :

```dart
  /// Publie un preset déjà existant en remplaçant son contenu.
  ///
  /// C'est la seconde forme de `smart_tile.preset.publish` : elle prend le
  /// preset complet au lieu d'un brouillon, et sert à modifier un preset
  /// publié sans repasser par l'assistant.
  Future<String> publishPreset({
    required String projectRootPath,
    required ProjectSmartTilePreset preset,
  }) async {
    final snapshot = await _gateway.load(projectRootPath: projectRootPath);
    final payload = preset.toJson();
    final fingerprint = sha256
        .convert(utf8.encode(jsonEncode(payload)))
        .toString()
        .substring(0, 20);
    final plan = await _gateway.plan(
      projectRootPath: projectRootPath,
      parameters: <String, Object?>{'preset': payload},
      expectedRevision: snapshot.snapshotRevision,
      idempotencyKey: 'smart-tile-preset-publish-$fingerprint',
    );
    return _gateway.apply(
      plan: plan,
      operationId: 'smart-tile-preset-publish-$fingerprint',
    );
  }
```

- [ ] **Step 4 : Lancer les tests pour vérifier qu'ils passent**

Run: `cd packages/map_editor && flutter test test/smart_tiles_studio/smart_tile_publication_service_test.dart`
Expected: PASS — les tests existants du fichier plus les deux nouveaux

- [ ] **Step 5 : Commit**

```bash
git add packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_publication_service.dart packages/map_editor/test/smart_tiles_studio/smart_tile_publication_service_test.dart
git commit -m "feat(editor): publish an existing Smart Tile preset by payload"
```

---

## Task 3 : La section repliée, sans écriture

**Files:**
- Create: `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_smart_tile_density_section.dart`
- Test: `packages/map_editor/test/features/editor/presentation/world_map/world_map_smart_tile_density_section_test.dart`

**Interfaces:**
- Consomme : `rescaleSmartTileVariantWeights`, `kSmartTileVariantWeightTotal` (Task 1) ; `PokeMapGuidedSlider`, `PokeMapSectionHeader`, `PokeMapButton` du design system.
- Produit : `WorldMapSmartTileDensitySection`, avec les paramètres `rule` (`SmartTileRule`), `spriteBuilder` (`Widget Function(SmartTileCandidate)`), `initialWeights` (`Map<String, int>`), `onApply` (`Future<void> Function(Map<String, int>)`), `isEditable` (`bool`). Le widget porte son état d'édition local ; il n'écrit rien lui-même.

- [ ] **Step 1 : Écrire les tests qui échouent**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_smart_tile_density_section.dart';
import 'package:map_editor/src/theme/theme.dart';

SmartTileRule _rule() => SmartTileRule(
      id: 'rule-0',
      centerMatch: const SmartTileSlotMatch.any(),
      signature: const SmartTileSignature(),
      candidates: <SmartTileCandidate>[
        for (var index = 0; index < 3; index += 1)
          SmartTileCandidate(
            id: 'cand-$index',
            weight: 1000,
            parts: const <SmartTileVisualPart>[],
          ),
      ],
    );

Future<void> _pump(WidgetTester tester, {required Widget child}) =>
    tester.pumpWidget(
      PokeMapTheme(child: MaterialApp(home: Scaffold(body: child))),
    );

void main() {
  testWidgets('est repliée par défaut et résume les variantes', (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        initialWeights: const <String, int>{},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_) async {},
      ),
    );

    expect(find.text('3 variantes'), findsOneWidget);
    expect(find.byType(PokeMapGuidedSlider), findsNothing);
  });

  testWidgets('déplie la liste au clic sur le résumé', (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        initialWeights: const <String, int>{},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();

    expect(find.byType(PokeMapGuidedSlider), findsNWidgets(3));
  });

  testWidgets('affiche « jamais » pour une variante à zéro', (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        initialWeights: const <String, int>{'cand-0': 0, 'cand-1': 500, 'cand-2': 500},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();

    expect(find.text('jamais'), findsOneWidget);
  });

  testWidgets('Appliquer transmet une table qui somme à 1000, une seule fois',
      (tester) async {
    final applied = <Map<String, int>>[];
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        initialWeights: const <String, int>{},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (weights) async => applied.add(weights),
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('world-map-density-apply')));
    await tester.pumpAndSettle();

    expect(applied, hasLength(1));
    expect(applied.single.values.reduce((a, b) => a + b), 1000);
  });

  testWidgets('Réinitialiser restaure les poids d\'ouverture', (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        initialWeights: const <String, int>{'cand-0': 800, 'cand-1': 100, 'cand-2': 100},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('world-map-density-reset')));
    await tester.pumpAndSettle();

    expect(find.text('80,0 %'), findsOneWidget);
  });

  testWidgets('signale les variantes qui s\'écartent du preset', (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        initialWeights: const <String, int>{'cand-0': 900, 'cand-1': 50, 'cand-2': 50},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_) async {},
      ),
    );

    expect(find.textContaining('modifiée'), findsOneWidget);
  });

  testWidgets('prévient que le premier enregistrement remélange la surface',
      (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        initialWeights: const <String, int>{},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('world-map-density-reshuffle-notice')),
      findsOneWidget,
    );
  });
}
```

L'avertissement de remélange vient de la spec : la normalisation change `totalWeight`, et le tirage étant `hash % totalWeight`, la surface se retire dès le premier enregistrement même sans avoir bougé un curseur. Il doit être dit, pas découvert.

- [ ] **Step 2 : Lancer les tests pour vérifier qu'ils échouent**

Run: `cd packages/map_editor && flutter test test/features/editor/presentation/world_map/world_map_smart_tile_density_section_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../world_map_smart_tile_density_section.dart'`

- [ ] **Step 3 : Écrire l'implémentation**

```dart
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_variant_density.dart';

/// Réglage de la fréquence de chaque variante d'une règle Smart Tile.
///
/// Repliée par défaut : le panneau de peinture garde sa longueur, et la ligne
/// de résumé suffit à voir qu'un réglage s'écarte du preset. Le widget ne
/// touche à rien — il rend une table de poids à [onApply] et attend.
class WorldMapSmartTileDensitySection extends StatefulWidget {
  const WorldMapSmartTileDensitySection({
    super.key,
    required this.rule,
    required this.initialWeights,
    required this.spriteBuilder,
    required this.onApply,
    this.isEditable = true,
  });

  final SmartTileRule rule;

  /// Poids d'ouverture, par identifiant de candidat. Une entrée absente prend
  /// le poids porté par le candidat lui-même.
  final Map<String, int> initialWeights;

  final Widget Function(SmartTileCandidate candidate) spriteBuilder;
  final Future<void> Function(Map<String, int> weights) onApply;
  final bool isEditable;

  @override
  State<WorldMapSmartTileDensitySection> createState() =>
      _WorldMapSmartTileDensitySectionState();
}

class _WorldMapSmartTileDensitySectionState
    extends State<WorldMapSmartTileDensitySection> {
  late Map<String, int> _opening;
  late Map<String, int> _current;
  var _expanded = false;
  var _applying = false;

  @override
  void initState() {
    super.initState();
    _opening = _normalisedOpening();
    _current = Map<String, int>.of(_opening);
  }

  @override
  void didUpdateWidget(WorldMapSmartTileDensitySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rule.id == widget.rule.id &&
        mapEquals(oldWidget.initialWeights, widget.initialWeights)) {
      return;
    }
    _opening = _normalisedOpening();
    _current = Map<String, int>.of(_opening);
  }

  Map<String, int> _normalisedOpening() {
    return normaliseSmartTileVariantWeights(<String, int>{
      for (final candidate in widget.rule.candidates)
        candidate.id: widget.initialWeights[candidate.id] ?? candidate.weight,
    });
  }

  int get _changedCount => _opening.entries
      .where((entry) => _defaultOf(entry.key) != entry.value)
      .length;

  int _defaultOf(String candidateId) => _defaults[candidateId] ?? 0;

  late final Map<String, int> _defaults = normaliseSmartTileVariantWeights(
    <String, int>{
      for (final candidate in widget.rule.candidates)
        candidate.id: candidate.weight,
    },
  );

  bool get _dirty => !mapEquals(_current, _opening);

  String _label(int permille) => permille == 0
      ? 'jamais'
      : '${(permille / 10).toStringAsFixed(1).replaceAll('.', ',')} %';

  @override
  Widget build(BuildContext context) {
    final count = widget.rule.candidates.length;
    final changed = _changedCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 10),
        const PokeMapSectionHeader(
          title: 'Densité des variantes',
          description: 'Ajuste la fréquence de chaque forme possible pour '
              'cette matière.',
        ),
        const SizedBox(height: 8),
        PokeMapButton(
          key: const Key('world-map-density-summary'),
          onPressed: () => setState(() => _expanded = !_expanded),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.compact,
          trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          child: Text(
            changed == 0
                ? '$count variantes'
                : '$count variantes · $changed modifiée${changed > 1 ? 's' : ''}',
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          const PokeMapBadge(
            key: Key('world-map-density-reshuffle-notice'),
            variant: PokeMapBadgeVariant.warning,
            label: 'Le premier enregistrement redistribue le tirage : la '
                'surface se remélange, même sans avoir bougé un curseur.',
          ),
          const SizedBox(height: 8),
          for (final candidate in widget.rule.candidates)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: <Widget>[
                  widget.spriteBuilder(candidate),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PokeMapGuidedSlider(
                      key: ValueKey<String>('world-map-density-${candidate.id}'),
                      label: _label(_current[candidate.id]!),
                      value: _current[candidate.id]!,
                      max: kSmartTileVariantWeightTotal,
                      onChanged: widget.isEditable
                          ? (next) => setState(() {
                                _current = rescaleSmartTileVariantWeights(
                                  weights: _current,
                                  targetId: candidate.id,
                                  targetPermille: next,
                                );
                              })
                          : (_) {},
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: PokeMapButton(
                  key: const Key('world-map-density-reset'),
                  onPressed: _dirty
                      ? () => setState(() => _current = Map<String, int>.of(_opening))
                      : null,
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.compact,
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: PokeMapButton(
                  key: const Key('world-map-density-apply'),
                  onPressed: _applying || !widget.isEditable
                      ? null
                      : () async {
                          setState(() => _applying = true);
                          try {
                            await widget.onApply(Map<String, int>.of(_current));
                            if (mounted) setState(() => _opening = Map<String, int>.of(_current));
                          } finally {
                            if (mounted) setState(() => _applying = false);
                          }
                        },
                  variant: PokeMapButtonVariant.primary,
                  size: PokeMapButtonSize.compact,
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 4 : Lancer les tests pour vérifier qu'ils passent**

Run: `cd packages/map_editor && flutter test test/features/editor/presentation/world_map/world_map_smart_tile_density_section_test.dart`
Expected: PASS — 6 tests

- [ ] **Step 5 : Commit**

```bash
git add packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_smart_tile_density_section.dart packages/map_editor/test/features/editor/presentation/world_map/world_map_smart_tile_density_section_test.dart
git commit -m "feat(editor): add the Smart Tile variant density section"
```

---

## Task 4a : Dégager de la place dans `editor_notifier.dart`

**Files:**
- Create: `packages/map_editor/lib/src/features/editor/state/editor_notifier_tileset_import.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- Modify: `tools/file_length_baseline.txt`

**Interfaces:**
- Consomme : rien.
- Produit : `extension EditorNotifierTilesetImport on EditorNotifier` portant `importProjectTileset` et `updateProjectTileset`, déplacées telles quelles.

Les Tasks 4 et 9 ajoutent environ 90 lignes à un fichier gelé. Cette tâche en sort davantage, pour que le solde reste négatif. Les deux méthodes de tileset choisies n'utilisent que `state`, `ref` et `_projectWorkspace` — vérifier avant de déplacer que `_projectWorkspace` est accessible depuis une extension ; si elle est privée, exposer un accesseur de paquet plutôt que de rendre le champ public.

- [ ] **Step 1 : Vérifier l'état de départ**

Run: `cd packages/map_editor && wc -l lib/src/features/editor/state/editor_notifier.dart`
Expected: 14607 lignes (ou la valeur courante du baseline)

- [ ] **Step 2 : Déplacer les deux méthodes**

Couper `importProjectTileset` (`editor_notifier.dart:3861`) et `updateProjectTileset` (`:3899`) et leurs éventuels helpers privés exclusifs, les coller dans le nouveau fichier sous une extension, et ajouter l'import correspondant.

- [ ] **Step 3 : Lancer les tests existants**

Run: `cd packages/map_editor && flutter test`
Expected: PASS — aucun changement de comportement, seulement un déplacement

- [ ] **Step 4 : Vérifier le solde et rafraîchir le baseline**

```bash
cd packages/map_editor && wc -l lib/src/features/editor/state/editor_notifier.dart
cd ../.. && dart tools/check_file_length.dart --update-baseline
```
Expected: le fichier a perdu au moins 120 lignes ; le baseline enregistre la nouvelle valeur

- [ ] **Step 5 : Commit**

```bash
git add packages/map_editor/lib/src/features/editor/state/ tools/file_length_baseline.txt
git commit -m "refactor(editor): move tileset import off the editor notifier"
```

---

## Task 4 : Brancher la section sur le preset

**Files:**
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- Modify: `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_smart_tile_paint_palette.dart:286` (juste avant le bloc `Motifs réutilisables`)
- Test: `packages/map_editor/test/features/editor/presentation/world_map/world_map_smart_tile_density_wiring_test.dart`

**Interfaces:**
- Consomme : `WorldMapSmartTileDensitySection` (Task 3), `SmartTilePublicationService.publishPreset` (Task 2).
- Produit : `ProjectSmartTilePreset applySmartTileVariantWeights({required ProjectSmartTilePreset preset, required String ruleId, required Map<String, int> weights})` dans `smart_tile_variant_density.dart` ; `SmartTileRule smartTileFillRuleOf(ProjectSmartTilePreset preset)` dans le même fichier ; `Future<void> EditorNotifier.applySmartTilePresetVariantWeights({required String presetId, required String ruleId, required Map<String, int> weights})`.

La transformation du preset est extraite en fonction pure : c'est la seule partie de la tâche qui mérite un test, et ça évite d'inventer un harnais autour du notifier — il n'en existe pas dans ce paquet.

- [ ] **Step 1 : Écrire les tests qui échouent**

Dans `packages/map_editor/test/features/editor/application/smart_tile_variant_density_test.dart` :

```dart
  group('applySmartTileVariantWeights', () {
    test('réécrit les poids de la règle visée et laisse les autres', () {
      final preset = _presetWithTwoRules();
      final updated = applySmartTileVariantWeights(
        preset: preset,
        ruleId: 'rule-0',
        weights: const <String, int>{'r0-c0': 900, 'r0-c1': 100},
      );

      expect(
        updated.rules.firstWhere((r) => r.id == 'rule-0')
            .candidates.map((c) => c.weight),
        <int>[900, 100],
      );
      expect(
        updated.rules.firstWhere((r) => r.id == 'rule-1'),
        preset.rules.firstWhere((r) => r.id == 'rule-1'),
      );
    });

    test('laisse intact un candidat absent de la table', () {
      final preset = _presetWithTwoRules();
      final updated = applySmartTileVariantWeights(
        preset: preset,
        ruleId: 'rule-0',
        weights: const <String, int>{'r0-c0': 900},
      );
      expect(
        updated.rules.firstWhere((r) => r.id == 'rule-0').candidates.last.weight,
        preset.rules.firstWhere((r) => r.id == 'rule-0').candidates.last.weight,
      );
    });
  });

  group('smartTileFillRuleOf', () {
    test('retient la règle qui porte le plus de variantes', () {
      expect(smartTileFillRuleOf(_presetWithTwoRules()).id, 'rule-0');
    });
  });
```

Et dans `packages/map_editor/test/features/editor/presentation/world_map/world_map_smart_tile_density_wiring_test.dart`, un test de rendu réutilisant le harnais Riverpod déjà employé par `world_map_paint_inspector_test.dart` (mêmes `ProviderScope` et surcharges de providers) :

```dart
testWidgets('la palette rend la section quand un calque Smart Tile est actif',
    (tester) async {
  await tester.pumpWidget(
    _paletteHost(subtool: WorldMapPaintSubtool.path),
  );
  await tester.pumpAndSettle();

  expect(find.byType(WorldMapSmartTileDensitySection), findsOneWidget);
});
```

`_paletteHost` est à écrire dans ce fichier en copiant la construction de `ProviderScope` de `world_map_paint_inspector_test.dart` : mêmes surcharges de `editorNotifierProvider` et de `worldMapWorkspaceSessionProvider`, avec un projet portant un preset publié en usage `path` et un calque Smart Tile actif qui le référence.

- [ ] **Step 2 : Lancer les tests pour vérifier qu'ils échouent**

Run: `cd packages/map_editor && flutter test test/features/editor/application/smart_tile_variant_density_test.dart test/features/editor/presentation/world_map/world_map_smart_tile_density_wiring_test.dart`
Expected: FAIL — `The function 'applySmartTileVariantWeights' isn't defined`

- [ ] **Step 3 : Écrire l'implémentation**

Dans `smart_tile_variant_density.dart`, les deux fonctions pures :

```dart
/// Règle dont les variantes se voient le plus : celle qui en porte le plus.
///
/// Sur un Wang Set importé, c'est la tuile de remplissage — celle qui couvre
/// l'intérieur d'une surface, donc celle dont la densité saute aux yeux.
SmartTileRule smartTileFillRuleOf(ProjectSmartTilePreset preset) {
  return preset.rules.reduce(
    (best, rule) =>
        rule.candidates.length > best.candidates.length ? rule : best,
  );
}

/// Renvoie [preset] avec les poids de la règle [ruleId] réécrits.
///
/// Un candidat absent de [weights] garde le sien : la table n'a pas besoin
/// d'être exhaustive.
ProjectSmartTilePreset applySmartTileVariantWeights({
  required ProjectSmartTilePreset preset,
  required String ruleId,
  required Map<String, int> weights,
}) {
  return preset.copyWith(
    rules: <SmartTileRule>[
      for (final rule in preset.rules)
        if (rule.id != ruleId)
          rule
        else
          rule.copyWith(
            candidates: <SmartTileCandidate>[
              for (final candidate in rule.candidates)
                candidate.copyWith(
                  weight: weights[candidate.id] ?? candidate.weight,
                ),
            ],
          ),
    ],
  );
}
```

Dans `editor_notifier.dart` :

```dart
  /// Réécrit les poids d'une règle du preset et republie celui-ci.
  ///
  /// La portée est volontairement globale : c'est le défaut du preset, pas une
  /// surcharge de calque.
  Future<void> applySmartTilePresetVariantWeights({
    required String presetId,
    required String ruleId,
    required Map<String, int> weights,
  }) async {
    final project = state.project;
    final root = _projectWorkspace?.projectRootPath;
    if (project == null || root == null) return;

    final preset = project.smartTileCatalog.presets
        .where((candidate) => candidate.id == presetId)
        .firstOrNull;
    if (preset == null) return;

    final updated = applySmartTileVariantWeights(
      preset: preset,
      ruleId: ruleId,
      weights: weights,
    );

    try {
      await ref
          .read(smartTilePublicationServiceProvider)
          .publishPreset(projectRootPath: root, preset: updated);
      await reloadProject();
      state = state.copyWith(
        statusMessage: 'Densité des variantes mise à jour',
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(errorMessage: 'Densité non enregistrée : $error');
    }
  }
```

Dans `world_map_smart_tile_paint_palette.dart`, insérer entre la fermeture du bloc `Matière à peindre` et l'ouverture du bloc `Motifs réutilisables` :

```dart
              if (activePreset != null && activeLayer != null)
                WorldMapSmartTileDensitySection(
                  rule: smartTileFillRuleOf(activePreset),
                  initialWeights: const <String, int>{},
                  spriteBuilder: (candidate) => SmartTileSpritePreview(
                    candidate: candidate,
                    preset: activePreset,
                    size: 24,
                  ),
                  isEditable: canEdit,
                  onApply: (weights) => notifier
                      .applySmartTilePresetVariantWeights(
                    presetId: activePreset.id,
                    ruleId: smartTileFillRuleOf(activePreset).id,
                    weights: weights,
                  ),
                ),
```

`SmartTileSpritePreview` existe déjà dans
`packages/map_editor/lib/src/features/smart_tiles_studio/presentation/smart_tile_sprite_preview.dart` ;
vérifier sa signature avant de l'appeler et adapter les arguments si besoin.

- [ ] **Step 4 : Lancer les tests pour vérifier qu'ils passent**

Run: `cd packages/map_editor && flutter test test/features/editor/presentation/world_map/`
Expected: PASS — tous les tests du dossier, dont les nouveaux

- [ ] **Step 5 : Commit**

```bash
git add packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_smart_tile_paint_palette.dart packages/map_editor/test/features/editor/presentation/world_map/world_map_smart_tile_density_wiring_test.dart
git commit -m "feat(editor): tune Smart Tile variant density from the paint panel"
```

**Lot 1 terminé.** À ce point, la densité est réglable sur le preset depuis le panneau Peindre. Vérifier à la main sur `le_train_de_17h42` : ouvrir Peindre > Chemin > `water to grass-godot (river orientation)`, déplier la section, descendre les six variantes à rocher, appliquer, et regarder la rivière.

---

# Lot 2 — la surcharge par calque

## Task 5 : Champ `candidateWeights` sur le calque

**Files:**
- Modify: `packages/map_core/lib/src/models/map_layer.dart:117-130`
- Test: `packages/map_core/test/map_layer_smart_tile_candidate_weights_test.dart`

**Interfaces:**
- Produit : `Map<String, int> SmartTileLayer.candidateWeights`, défaut `<String, int>{}`.

- [ ] **Step 1 : Écrire les tests qui échouent**

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('candidateWeights vaut une table vide par défaut', () {
    const layer = MapLayer.smartTile(
      id: 'riviere',
      name: 'Rivière',
      presetId: 'eau',
      usage: SmartTileUsage.path,
      field: SmartTileField.empty(width: 2, height: 2),
    );
    expect((layer as SmartTileLayer).candidateWeights, isEmpty);
  });

  test('un calque écrit sans le champ se relit', () {
    final json = <String, dynamic>{
      'type': 'smartTile',
      'id': 'riviere',
      'name': 'Rivière',
      'presetId': 'eau',
      'usage': 'path',
      'field': SmartTileField.empty(width: 2, height: 2).toJson(),
    };
    final layer = MapLayer.fromJson(json) as SmartTileLayer;
    expect(layer.candidateWeights, isEmpty);
  });

  test('aller-retour de sérialisation', () {
    final layer = MapLayer.smartTile(
      id: 'riviere',
      name: 'Rivière',
      presetId: 'eau',
      usage: SmartTileUsage.path,
      field: SmartTileField.empty(width: 2, height: 2),
      candidateWeights: const <String, int>{'cand-5': 0, 'cand-0': 900},
    ) as SmartTileLayer;
    final round = MapLayer.fromJson(layer.toJson()) as SmartTileLayer;
    expect(round.candidateWeights, layer.candidateWeights);
  });

  test('une table vide n\'écrit pas de clé', () {
    const layer = MapLayer.smartTile(
      id: 'riviere',
      name: 'Rivière',
      presetId: 'eau',
      usage: SmartTileUsage.path,
      field: SmartTileField.empty(width: 2, height: 2),
    );
    expect(layer.toJson().containsKey('candidateWeights'), isFalse);
  });
}
```

Ce dernier test porte l'exigence de la spec sur le bruit de sérialisation : sans lui, chaque
calque Smart Tile de chaque carte gagne un `"candidateWeights":{}` inutile.

- [ ] **Step 2 : Lancer les tests pour vérifier qu'ils échouent**

Run: `cd packages/map_core && dart test test/map_layer_smart_tile_candidate_weights_test.dart`
Expected: FAIL — `No named parameter with the name 'candidateWeights'`

- [ ] **Step 3 : Ajouter le champ et régénérer**

Dans `map_layer.dart`, ajouter après `@Default(0) int layerSeed,` :

```dart
    @JsonKey(includeIfNull: false)
    @Default(<String, int>{}) Map<String, int> candidateWeights,
```

Puis régénérer :

```bash
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
```

`includeIfNull` ne couvre pas une table vide. Si le test « une table vide n'écrit pas de clé »
échoue encore après régénération, écrire un `toJson` personnalisé sur `SmartTileLayer` qui retire
la clé quand `candidateWeights.isEmpty`, plutôt que de laisser toutes les cartes grossir.

- [ ] **Step 4 : Lancer les tests pour vérifier qu'ils passent**

Run: `cd packages/map_core && dart test test/map_layer_smart_tile_candidate_weights_test.dart && dart test`
Expected: PASS — les trois nouveaux tests, et aucune régression sur la suite complète

- [ ] **Step 5 : Commit**

```bash
git add packages/map_core/lib/src/models/map_layer.dart packages/map_core/lib/src/models/map_layer.freezed.dart packages/map_core/lib/src/models/map_layer.g.dart packages/map_core/test/map_layer_smart_tile_candidate_weights_test.dart
git commit -m "feat(core): carry per-layer Smart Tile candidate weights"
```

---

## Task 6 : Le résolveur applique la surcharge

**Files:**
- Modify: `packages/map_core/lib/src/operations/smart_tile_resolver.dart:44-110`
- Test: `packages/map_core/test/smart_tile_resolver_candidate_weights_test.dart`

**Interfaces:**
- Consomme : rien de nouveau.
- Produit : paramètre nommé optionnel `Map<String, int> candidateWeights = const <String, int>{}` sur `resolveSmartTile` et sur la fabrique `PreparedSmartTileResolver`.

- [ ] **Step 1 : Écrire les tests qui échouent**

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('une table vide reproduit le comportement actuel', () {
    final sans = _resolveAll(const <String, int>{});
    final avec = _resolveAll(const <String, int>{});
    expect(avec, sans);
  });

  test('un poids nul exclut le candidat du tirage', () {
    final ids = _resolveAll(const <String, int>{'cand-1': 0});
    expect(ids, isNot(contains('cand-1')));
    expect(ids, contains('cand-0'));
  });

  test('un poids écrasant fait sortir presque toujours le même candidat', () {
    final ids = _resolveAll(const <String, int>{'cand-0': 999, 'cand-1': 1});
    final part = ids.where((id) => id == 'cand-0').length / ids.length;
    expect(part, greaterThan(0.9));
  });

  test('une clé inconnue est ignorée sans erreur', () {
    expect(
      () => _resolveAll(const <String, int>{'cand-inexistant': 500}),
      returnsNormally,
    );
  });
}
```

`_resolveAll` construit un preset à deux candidats, résout 400 cellules et renvoie la liste des identifiants de candidat retenus.

- [ ] **Step 2 : Lancer les tests pour vérifier qu'ils échouent**

Run: `cd packages/map_core && dart test test/smart_tile_resolver_candidate_weights_test.dart`
Expected: FAIL — `No named parameter with the name 'candidateWeights'`

- [ ] **Step 3 : Écrire l'implémentation**

Ajouter le paramètre à `resolveSmartTile` et à la fabrique `PreparedSmartTileResolver`, puis l'appliquer dans `prepare` avant de construire `_PreparedSmartTileRule` :

```dart
    _PreparedSmartTileRule prepare(SmartTileRule rule) {
      final effective = candidateWeights.isEmpty
          ? rule
          : rule.copyWith(
              candidates: <SmartTileCandidate>[
                for (final candidate in rule.candidates)
                  candidateWeights.containsKey(candidate.id)
                      ? candidate.copyWith(weight: candidateWeights[candidate.id]!)
                      : candidate,
              ],
            );
      return _PreparedSmartTileRule(
        rule: effective,
        // … le reste inchangé, en remplaçant `rule` par `effective`
      );
    }
```

Le filtre `weight > 0` et la somme `totalWeight` de `_PreparedSmartTileRule` opèrent alors sur les poids effectifs, sans autre changement.

- [ ] **Step 4 : Lancer les tests pour vérifier qu'ils passent**

Run: `cd packages/map_core && dart test`
Expected: PASS — la suite complète, dont les quatre nouveaux tests

- [ ] **Step 5 : Commit**

```bash
git add packages/map_core/lib/src/operations/smart_tile_resolver.dart packages/map_core/test/smart_tile_resolver_candidate_weights_test.dart
git commit -m "feat(core): apply per-layer candidate weights at rule preparation"
```

---

## Task 7 : Passer la surcharge depuis le résolveur visuel

**Files:**
- Modify: `packages/map_core/lib/src/operations/smart_tile_layer_visual_resolver.dart:320-336`
- Test: `packages/map_core/test/smart_tile_layer_visual_resolver_candidate_weights_test.dart`

**Interfaces:**
- Consomme : le paramètre `candidateWeights` de Task 6.
- Produit : rien de nouveau côté signature ; le résolveur visuel lit `layer.candidateWeights`.

- [ ] **Step 1 : Écrire le test qui échoue**

```dart
test('les visuels respectent la surcharge du calque', () {
  final sans = _visualsFor(candidateWeights: const <String, int>{});
  final avec = _visualsFor(candidateWeights: const <String, int>{'cand-1': 0});

  expect(sans.map((v) => v.candidateId).toSet(), contains('cand-1'));
  expect(avec.map((v) => v.candidateId).toSet(), isNot(contains('cand-1')));
});
```

- [ ] **Step 2 : Lancer le test pour vérifier qu'il échoue**

Run: `cd packages/map_core && dart test test/smart_tile_layer_visual_resolver_candidate_weights_test.dart`
Expected: FAIL — les deux ensembles sont identiques, `cand-1` apparaît dans les deux

- [ ] **Step 3 : Écrire l'implémentation**

À la construction du résolveur préparé, passer la table du calque :

```dart
  final resolver = PreparedSmartTileResolver(
    preset: preset,
    materials: catalog.materials,
    mapId: map.id,
    layerId: layer.id,
    projectSeed: projectSeed,
    layerSeed: layer.layerSeed,
    candidateWeights: layer.candidateWeights,
  );
```

- [ ] **Step 4 : Lancer les tests pour vérifier qu'ils passent**

Run: `cd packages/map_core && dart test`
Expected: PASS

- [ ] **Step 5 : Commit**

```bash
git add packages/map_core/lib/src/operations/smart_tile_layer_visual_resolver.dart packages/map_core/test/smart_tile_layer_visual_resolver_candidate_weights_test.dart
git commit -m "feat(core): honour layer candidate weights when resolving visuals"
```

---

## Task 8 : Action canonique `smart_tile.layer.set_candidate_weights`

**Files:**
- Modify: `packages/map_authoring/lib/src/domains/maps/smart_tile_layer_actions.dart`
- Test: `packages/map_authoring/test/domains/maps/smart_tile_layer_actions_test.dart`

**Interfaces:**
- Consomme : le champ `candidateWeights` de Task 5.
- Produit : l'action `smart_tile.layer.set_candidate_weights`, version 1, paramètres `mapId` (String), `layerId` (String), `weights` (`Map<String, int>`). Codes de refus : `smart_tile.layer.weight_invalid`, `smart_tile.layer.candidate_unknown`, `smart_tile.layer.rule_without_candidate`.

- [ ] **Step 1 : Écrire les tests qui échouent**

```dart
group('smart_tile.layer.set_candidate_weights', () {
  test('remplace la table du calque et se rejoue à l\'identique', () async {
    final setup = await _LayerActionSetup.create();
    addTearDown(setup.dispose);

    final planned = await setup.plan(<String, Object?>{
      'mapId': 'm01',
      'layerId': 'riviere',
      'weights': <String, Object?>{'cand-0': 900, 'cand-1': 100},
    });
    await setup.apply(planned, operationId: 'op-1');
    await setup.apply(planned, operationId: 'op-1');

    final layer = await setup.smartTileLayer('m01', 'riviere');
    expect(layer.candidateWeights, <String, int>{'cand-0': 900, 'cand-1': 100});
  });

  test('remplace, ne fusionne pas', () async {
    final setup = await _LayerActionSetup.create(
      initialWeights: const <String, int>{'cand-0': 1, 'cand-1': 999},
    );
    addTearDown(setup.dispose);

    await setup.applyPlan(<String, Object?>{
      'mapId': 'm01',
      'layerId': 'riviere',
      'weights': <String, Object?>{'cand-0': 500},
    });

    final layer = await setup.smartTileLayer('m01', 'riviere');
    expect(layer.candidateWeights, <String, int>{'cand-0': 500});
  });

  test('refuse un poids négatif', () async {
    final setup = await _LayerActionSetup.create();
    addTearDown(setup.dispose);
    await expectLater(
      setup.plan(<String, Object?>{
        'mapId': 'm01',
        'layerId': 'riviere',
        'weights': <String, Object?>{'cand-0': -1},
      }),
      throwsA(isA<Object>().having(
        (e) => '$e', 'code', contains('smart_tile.layer.weight_invalid'))),
    );
  });

  test('refuse un candidat absent du preset', () async {
    final setup = await _LayerActionSetup.create();
    addTearDown(setup.dispose);
    await expectLater(
      setup.plan(<String, Object?>{
        'mapId': 'm01',
        'layerId': 'riviere',
        'weights': <String, Object?>{'cand-inconnu': 10},
      }),
      throwsA(isA<Object>().having(
        (e) => '$e', 'code', contains('smart_tile.layer.candidate_unknown'))),
    );
  });

  test('refuse de vider une règle de tout candidat positif', () async {
    final setup = await _LayerActionSetup.create();
    addTearDown(setup.dispose);
    await expectLater(
      setup.plan(<String, Object?>{
        'mapId': 'm01',
        'layerId': 'riviere',
        'weights': <String, Object?>{'cand-0': 0, 'cand-1': 0},
      }),
      throwsA(isA<Object>().having(
        (e) => '$e', 'code', contains('smart_tile.layer.rule_without_candidate'))),
    );
  });

  test('s\'annule et rend la table précédente', () async {
    final setup = await _LayerActionSetup.create(
      initialWeights: const <String, int>{'cand-0': 700, 'cand-1': 300},
    );
    addTearDown(setup.dispose);

    final entryId = await setup.applyPlan(<String, Object?>{
      'mapId': 'm01',
      'layerId': 'riviere',
      'weights': <String, Object?>{'cand-0': 100, 'cand-1': 900},
    });
    await setup.undo(entryId);

    final layer = await setup.smartTileLayer('m01', 'riviere');
    expect(layer.candidateWeights, <String, int>{'cand-0': 700, 'cand-1': 300});
  });
});
```

- [ ] **Step 2 : Lancer les tests pour vérifier qu'ils échouent**

Run: `cd packages/map_authoring && dart test test/domains/maps/smart_tile_layer_actions_test.dart`
Expected: FAIL — action inconnue du répartiteur

- [ ] **Step 3 : Écrire l'implémentation**

Déclarer le descripteur à côté de `smart_tile.layer.normalize`, router dans le `switch` du répartiteur, puis :

```dart
  AuthoringMutationDraft _setCandidateWeights(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'mapId', 'layerId', 'weights'},
    );
    final mapId = parameters.string('mapId');
    final layerId = parameters.string('layerId');
    final raw = parameters.object('weights');

    final layer = _requireSmartTileLayer(planning, mapId: mapId, layerId: layerId);
    final preset = _requirePreset(planning, layer.presetId);
    final known = <String>{
      for (final rule in preset.rules)
        for (final candidate in rule.candidates) candidate.id,
    };

    final weights = <String, int>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is! int || value < 0) {
        throw semanticFailure(
          'smart_tile.layer.weight_invalid',
          'Un poids de variante doit être un entier positif ou nul.',
          details: <String, Object?>{'candidateId': entry.key, 'weight': value},
        );
      }
      if (!known.contains(entry.key)) {
        throw semanticFailure(
          'smart_tile.layer.candidate_unknown',
          'Cette variante n’appartient pas au preset du calque.',
          details: <String, Object?>{'candidateId': entry.key},
        );
      }
      weights[entry.key] = value;
    }

    for (final rule in preset.rules) {
      final positive = rule.candidates.where(
        (candidate) => (weights[candidate.id] ?? candidate.weight) > 0,
      );
      if (positive.isEmpty) {
        throw semanticFailure(
          'smart_tile.layer.rule_without_candidate',
          'Cette table laisserait une règle sans aucune variante.',
          details: <String, Object?>{'ruleId': rule.id},
        );
      }
    }

    return _layerDraft(
      planning,
      mapId: mapId,
      layer: layer.copyWith(candidateWeights: weights),
      operation: 'smart_tile.layer.set_candidate_weights',
      path: '/maps/$mapId/layers/$layerId/candidateWeights',
      before: layer.candidateWeights,
      after: weights,
    );
  }
```

- [ ] **Step 4 : Lancer les tests pour vérifier qu'ils passent**

Run: `cd packages/map_authoring && dart test`
Expected: PASS — la suite complète, dont les six nouveaux tests. Le contrôle de parité passe : le préfixe `smart_tile.layer.` route déjà vers ce fichier de test.

- [ ] **Step 5 : Commit**

```bash
git add packages/map_authoring/lib/src/domains/maps/smart_tile_layer_actions.dart packages/map_authoring/test/domains/maps/smart_tile_layer_actions_test.dart
git commit -m "feat(authoring): set Smart Tile candidate weights on one layer"
```

---

## Task 9 : Sélecteur de portée dans la section

**Files:**
- Modify: `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_smart_tile_density_section.dart`
- Modify: `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_smart_tile_paint_palette.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- Test: `packages/map_editor/test/features/editor/presentation/world_map/world_map_smart_tile_density_section_test.dart`

**Interfaces:**
- Consomme : l'action de Task 8.
- Produit : `enum SmartTileDensityScope { layer, preset }` exporté par le fichier de section ; `WorldMapSmartTileDensitySection` gagne `layerWeights`, `presetWeights` et `onApply` devient `Future<void> Function(SmartTileDensityScope scope, Map<String, int> weights)` ; `Future<void> EditorNotifier.applySmartTileLayerVariantWeights({required String mapId, required String layerId, required Map<String, int> weights})`.

- [ ] **Step 1 : Écrire les tests qui échouent**

```dart
testWidgets('bascule la source des curseurs avec la portée', (tester) async {
  await _pump(
    tester,
    child: WorldMapSmartTileDensitySection(
      rule: _rule(),
      layerWeights: const <String, int>{'cand-0': 900, 'cand-1': 50, 'cand-2': 50},
      presetWeights: const <String, int>{'cand-0': 334, 'cand-1': 333, 'cand-2': 333},
      spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
      onApply: (_, __) async {},
    ),
  );

  await tester.tap(find.byKey(const Key('world-map-density-summary')));
  await tester.pumpAndSettle();
  expect(find.text('90,0 %'), findsOneWidget);

  await tester.tap(find.byKey(const Key('world-map-density-scope-preset')));
  await tester.pumpAndSettle();
  expect(find.text('33,4 %'), findsOneWidget);
});

testWidgets('Appliquer transmet la portée choisie', (tester) async {
  final calls = <SmartTileDensityScope>[];
  await _pump(
    tester,
    child: WorldMapSmartTileDensitySection(
      rule: _rule(),
      layerWeights: const <String, int>{},
      presetWeights: const <String, int>{},
      spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
      onApply: (scope, _) async => calls.add(scope),
    ),
  );

  await tester.tap(find.byKey(const Key('world-map-density-summary')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('world-map-density-scope-preset')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('world-map-density-apply')));
  await tester.pumpAndSettle();

  expect(calls, <SmartTileDensityScope>[SmartTileDensityScope.preset]);
});
```

- [ ] **Step 2 : Lancer les tests pour vérifier qu'ils échouent**

Run: `cd packages/map_editor && flutter test test/features/editor/presentation/world_map/world_map_smart_tile_density_section_test.dart`
Expected: FAIL — `No named parameter with the name 'layerWeights'`

- [ ] **Step 3 : Écrire l'implémentation**

Remplacer `initialWeights` par le couple `layerWeights` / `presetWeights`, garder un `_scope` dans l'état, recalculer `_opening` et `_current` à chaque bascule depuis la source correspondante, et rendre au-dessus des curseurs :

```dart
          Row(
            children: <Widget>[
              Expanded(
                child: PokeMapButton(
                  key: const Key('world-map-density-scope-layer'),
                  onPressed: () => _selectScope(SmartTileDensityScope.layer),
                  variant: _scope == SmartTileDensityScope.layer
                      ? PokeMapButtonVariant.primary
                      : PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.compact,
                  child: const Text('Ce calque'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: PokeMapButton(
                  key: const Key('world-map-density-scope-preset'),
                  onPressed: () => _selectScope(SmartTileDensityScope.preset),
                  variant: _scope == SmartTileDensityScope.preset
                      ? PokeMapButtonVariant.primary
                      : PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.compact,
                  child: const Text('Tous les calques'),
                ),
              ),
            ],
          ),
```

Dans `editor_notifier.dart`, la méthode jumelle de Task 4 :

```dart
  /// Écrit la surcharge de variantes portée par un calque.
  ///
  /// Même chemin canonique que les gestes de peinture Smart Tile : on planifie,
  /// on applique, puis on adopte le cliché renvoyé pour que la carte à l'écran
  /// reparte de la révision écrite.
  Future<void> applySmartTileLayerVariantWeights({
    required String mapId,
    required String layerId,
    required Map<String, int> weights,
  }) async {
    final projectRootPath = state.projectRootPath;
    if (projectRootPath == null) return;

    final parameters = <String, Object?>{
      'mapId': mapId,
      'layerId': layerId,
      'weights': weights,
    };
    final identity = _smartTileEditorMutationIdentity(
      purpose: 'smart-tile-candidate-weights',
      values: <String, Object?>{
        'mapId': mapId,
        'layerId': layerId,
        'sequence': ++_smartTileGestureSequence,
      },
    );

    try {
      final mutations = ref.read(authoringMutationAdapterProvider);
      final plan = await mutations.plan(
        projectRootPath,
        actionId: 'smart_tile.layer.set_candidate_weights',
        parameters: parameters,
        idempotencyKey: identity,
        requestId: identity,
      );
      final applied = await mutations.apply(plan, operationId: '$identity-apply');
      await _adoptCanonicalSmartTileSnapshot(
        projectRootPath: projectRootPath,
        expectedSnapshotRevision: applied.snapshotRevision,
        mapId: mapId,
        layerId: layerId,
        statusMessage: 'Densité des variantes mise à jour sur ce calque.',
      );
    } catch (error) {
      state = state.copyWith(
        errorMessage: canonicalSmartTileFailureMessage(error),
      );
    }
  }
```

`_smartTileEditorMutationIdentity`, `_smartTileGestureSequence`,
`_adoptCanonicalSmartTileSnapshot`, `authoringMutationAdapterProvider` et
`canonicalSmartTileFailureMessage` existent déjà dans ce fichier — c'est le chemin qu'emprunte
`_commitCanonicalSmartTileGesture`.

et dans la palette, router selon la portée :

```dart
                  onApply: (scope, weights) => switch (scope) {
                    SmartTileDensityScope.layer =>
                      notifier.applySmartTileLayerVariantWeights(
                        mapId: snapshot.map!.id,
                        layerId: activeLayer.id,
                        weights: weights,
                      ),
                    SmartTileDensityScope.preset =>
                      notifier.applySmartTilePresetVariantWeights(
                        presetId: activePreset.id,
                        ruleId: smartTileFillRuleOf(activePreset).id,
                        weights: weights,
                      ),
                  },
```

- [ ] **Step 4 : Lancer les tests pour vérifier qu'ils passent**

Run: `cd packages/map_editor && flutter test test/features/editor/`
Expected: PASS

- [ ] **Step 5 : Commit**

```bash
git add packages/map_editor/lib/src/features/editor/presentation/world_map/ packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/test/features/editor/presentation/world_map/
git commit -m "feat(editor): choose between layer and preset variant density"
```

---

## Task 10a : Dégager de la place dans `validators.dart`

**Files:**
- Create: `packages/map_core/lib/src/validation/smart_tile_layer_validation.dart`
- Modify: `packages/map_core/lib/src/validation/validators.dart:2681-2720`
- Modify: `tools/file_length_baseline.txt`

**Interfaces:**
- Produit : `List<ValidationDiagnostic> validateSmartTileLayer({required SmartTileLayer layer, required ProjectSmartTilePreset preset})`, appelée depuis la branche `smartTile:` de `validators.dart`.

`validators.dart` est gelé à 3106 lignes. Sortir la validation de calque Smart Tile dans son propre fichier fait de la place pour Task 10 et rapproche le fichier de la limite de 3000.

- [ ] **Step 1 : Écrire le test de non-régression**

Dans `packages/map_core/test/validators_smart_tile_layer_test.dart`, reprendre les cas existants de validation de calque Smart Tile (preset inconnu, palette de matériaux invalide) en appelant directement `validateSmartTileLayer`.

- [ ] **Step 2 : Lancer le test pour vérifier qu'il échoue**

Run: `cd packages/map_core && dart test test/validators_smart_tile_layer_test.dart`
Expected: FAIL — `validateSmartTileLayer` n'existe pas

- [ ] **Step 3 : Extraire la fonction**

Déplacer le corps de la branche `smartTile:` dans le nouveau fichier, et ne laisser dans `validators.dart` que l'appel et l'ajout des diagnostics retournés.

- [ ] **Step 4 : Vérifier le solde et rafraîchir le baseline**

```bash
cd packages/map_core && dart test && wc -l lib/src/validation/validators.dart
cd ../.. && dart tools/check_file_length.dart --update-baseline
```
Expected: PASS, et `validators.dart` a perdu au moins 40 lignes

- [ ] **Step 5 : Commit**

```bash
git add packages/map_core/lib/src/validation/ packages/map_core/test/validators_smart_tile_layer_test.dart tools/file_length_baseline.txt
git commit -m "refactor(core): extract Smart Tile layer validation"
```

---

## Task 10 : Avertissement sur les clés orphelines

**Files:**
- Modify: `packages/map_core/lib/src/validation/smart_tile_layer_validation.dart` (créé en Task 10a)
- Test: `packages/map_core/test/validators_smart_tile_candidate_weights_test.dart`

**Interfaces:**
- Consomme : le champ de Task 5.
- Produit : un diagnostic d'avertissement de code `smart_tile_layer_candidate_weight_orphan`, jamais une exception.

- [ ] **Step 1 : Écrire les tests qui échouent**

```dart
test('une clé absente du preset produit un avertissement, pas une erreur', () {
  final diagnostics = validateProject(_projectWithLayerWeights(
    const <String, int>{'cand-0': 500, 'cand-mort': 500},
  ));
  final orphan = diagnostics.singleWhere(
    (d) => d.code == 'smart_tile_layer_candidate_weight_orphan',
  );
  expect(orphan.severity, ValidationSeverity.warning);
  expect(orphan.details['candidateIds'], <String>['cand-mort']);
});

test('aucune clé morte, aucun diagnostic', () {
  final diagnostics = validateProject(_projectWithLayerWeights(
    const <String, int>{'cand-0': 500},
  ));
  expect(
    diagnostics.where(
      (d) => d.code == 'smart_tile_layer_candidate_weight_orphan',
    ),
    isEmpty,
  );
});

test('la carte reste ouvrable malgré une clé morte', () {
  expect(
    () => validateProject(_projectWithLayerWeights(
      const <String, int>{'cand-mort': 500},
    )),
    returnsNormally,
  );
});
```

- [ ] **Step 2 : Lancer les tests pour vérifier qu'ils échouent**

Run: `cd packages/map_core && dart test test/validators_smart_tile_candidate_weights_test.dart`
Expected: FAIL — `Bad state: No element` (le diagnostic n'existe pas)

- [ ] **Step 3 : Écrire l'implémentation**

Dans `validateSmartTileLayer`, après le contrôle de `materialPalette` :

```dart
        final knownCandidateIds = <String>{
          for (final rule in preset.rules)
            for (final candidate in rule.candidates) candidate.id,
        };
        final orphans = smartTileLayer.candidateWeights.keys
            .where((id) => !knownCandidateIds.contains(id))
            .toList(growable: false)
          ..sort();
        if (orphans.isNotEmpty) {
          diagnostics.add(
            ValidationDiagnostic(
              code: 'smart_tile_layer_candidate_weight_orphan',
              severity: ValidationSeverity.warning,
              message: 'Le calque "${smartTileLayer.id}" règle la densité de '
                  'variantes absentes de son preset. Ces réglages sont ignorés.',
              details: <String, Object?>{
                'layerId': smartTileLayer.id,
                'candidateIds': orphans,
              },
            ),
          );
        }
```

- [ ] **Step 4 : Lancer les tests pour vérifier qu'ils passent**

Run: `cd packages/map_core && dart test`
Expected: PASS

- [ ] **Step 5 : Commit**

```bash
git add packages/map_core/lib/src/validation/validators.dart packages/map_core/test/validators_smart_tile_candidate_weights_test.dart
git commit -m "feat(core): warn about orphan Smart Tile candidate weights"
```

---

## Vérification finale

- [ ] `cd packages/map_core && dart test`
- [ ] `cd packages/map_authoring && dart test`
- [ ] `cd packages/map_editor && flutter test`
- [ ] `dart tools/check_file_length.dart` — aucun fichier hors cliquet
- [ ] `dart analyze` propre sur les trois paquets
- [ ] À la main sur `le_train_de_17h42` : régler les rochers de `water to grass-godot (river orientation)` à ~1 % sur un calque, vérifier qu'un second calque utilisant le même preset garde sa densité d'origine, puis basculer sur « tous les calques » et vérifier que le second calque suit.
