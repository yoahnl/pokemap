import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/narrative/pokemap_narrative_reference_picker.dart';
import 'package:map_editor/src/ui/design_system/pokemap_search_field.dart';

void main() {
  const sceneKey = NarrativeDependencyKey.scene('scene_port_a');
  const secondSceneKey = NarrativeDependencyKey.scene('scene_port_b');
  const incompatibleKey = NarrativeDependencyKey.scene('scene_other_scope');
  const missingKey = NarrativeDependencyKey.scene('scene_missing');
  const mapChildA = NarrativeDependencyKey.mapSource(
    mapId: 'map_port',
    sourceKind: 'entity',
    sourceId: 'shared_npc',
  );
  const mapChildB = NarrativeDependencyKey.mapSource(
    mapId: 'map_forest',
    sourceKind: 'entity',
    sourceId: 'shared_npc',
  );

  testWidgets('shows an honest empty state', (tester) async {
    await _pumpPicker(
      tester,
      readModel: CanonicalNarrativeReferencePickerReadModel(
        groups: const <CanonicalNarrativeReferenceGroup>[],
        missingSelection: null,
      ),
    );

    expect(find.text('Aucune référence disponible'), findsOneWidget);
    expect(find.text('Créez ou publiez une référence compatible.'),
        findsOneWidget);
  });

  testWidgets('shows readable labels, technical IDs and a broken selection',
      (tester) async {
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(key: sceneKey, label: 'Rencontre'),
          _option(
            key: secondSceneKey,
            label: 'Rencontre',
            publicationStatus: NarrativeReferencePublicationStatus.draft,
          ),
          _option(
            key: incompatibleKey,
            label: 'Rencontre lointaine',
            availability: NarrativeReferenceAvailability.incompatible,
            diagnostic: 'Disponible dans une autre portée',
          ),
        ],
        missingSelection: _option(
          key: missingKey,
          label: 'Référence introuvable',
          availability: NarrativeReferenceAvailability.missing,
          diagnostic: 'La scène sélectionnée n’existe plus.',
        ),
      ),
      selectedKey: missingKey,
    );

    expect(find.text('Rencontre'), findsNWidgets(2));
    expect(find.text('scene_port_a'), findsOneWidget);
    expect(find.text('Port Selbrume'), findsWidgets);
    expect(find.text('Brouillon'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('narrative-reference-missing')),
      findsOneWidget,
    );
    expect(find.text('scene_missing'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Disponible dans une autre portée'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Disponible dans une autre portée'), findsOneWidget);
  });

  testWidgets('search delegates to the canonical read model', (tester) async {
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(key: sceneKey, label: 'Rencontre'),
          _option(
            key: secondSceneKey,
            label: 'Embuscade',
            diagnostic: 'Combat optionnel',
          ),
        ],
      ),
    );

    await tester.enterText(find.byType(TextField), 'scene_port_a');
    await tester.pump();

    expect(find.text('Rencontre'), findsOneWidget);
    expect(find.text('Embuscade'), findsNothing);

    await tester.enterText(find.byType(TextField), 'combat optionnel');
    await tester.pump();

    expect(find.text('Rencontre'), findsNothing);
    expect(find.text('Embuscade'), findsOneWidget);
  });

  testWidgets('selects available rows but never incompatible rows',
      (tester) async {
    final selected = <NarrativeDependencyKey>[];
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(key: sceneKey, label: 'Rencontre'),
          _option(
            key: incompatibleKey,
            label: 'Rencontre lointaine',
            availability: NarrativeReferenceAvailability.incompatible,
            diagnostic: 'Disponible dans une autre portée',
          ),
        ],
      ),
      onSelected: (option) => selected.add(option.key),
    );

    await tester
        .tap(find.byKey(const ValueKey<NarrativeDependencyKey>(sceneKey)));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<NarrativeDependencyKey>(incompatibleKey)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, <NarrativeDependencyKey>[sceneKey]);
    expect(_hasFocus(tester, incompatibleKey), isFalse);
  });

  testWidgets('copies the technical ID of a broken reference', (tester) async {
    final platformCalls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: const <CanonicalNarrativeReferenceOption>[],
        missingSelection: _option(
          key: missingKey,
          label: 'Référence introuvable',
          availability: NarrativeReferenceAvailability.missing,
          diagnostic: 'La scène sélectionnée n’existe plus.',
        ),
      ),
    );

    await tester.tap(find.byTooltip('Copier l’identifiant scene_missing'));
    await tester.pump();

    expect(
      platformCalls
          .singleWhere((call) => call.method == 'Clipboard.setData')
          .arguments,
      <String, dynamic>{'text': 'scene_missing'},
    );
  });

  testWidgets('opens a navigable existing selection filtered as incompatible',
      (tester) async {
    const intent = NarrativeDependencyNavigationIntent(
      kind: NarrativeDependencyTargetKind.scene,
      assetId: 'scene_other_scope',
    );
    final opened = <NarrativeDependencyNavigationIntent>[];
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: const <CanonicalNarrativeReferenceOption>[],
        incompatibleSelection: _option(
          key: incompatibleKey,
          label: 'Rencontre lointaine',
          availability: NarrativeReferenceAvailability.incompatible,
          diagnostic: 'Ce type n’est pas autorisé ici.',
          navigationIntent: intent,
        ),
      ),
      onOpen: opened.add,
    );

    expect(
      find.byKey(
        const ValueKey<String>(
          'narrative-reference-incompatible-selection',
        ),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Ouvrir Rencontre lointaine'));
    await tester.pump();

    expect(opened, const <NarrativeDependencyNavigationIntent>[intent]);
  });

  testWidgets('copies technical IDs and opens only navigable options',
      (tester) async {
    final platformCalls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final opened = <NarrativeDependencyNavigationIntent>[];
    const navigationIntent = NarrativeDependencyNavigationIntent(
      kind: NarrativeDependencyTargetKind.scene,
      assetId: 'scene_port_a',
    );

    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(
            key: sceneKey,
            label: 'Rencontre',
            navigationIntent: navigationIntent,
          ),
          _option(key: secondSceneKey, label: 'Embuscade'),
        ],
      ),
      onOpen: opened.add,
    );

    await tester.tap(find.byTooltip('Copier l’identifiant scene_port_a'));
    await tester.pump();
    await tester.tap(find.byTooltip('Ouvrir Rencontre'));
    await tester.pump();

    expect(
      platformCalls.where((call) => call.method == 'Clipboard.setData'),
      hasLength(1),
    );
    expect(
      platformCalls
          .singleWhere((call) => call.method == 'Clipboard.setData')
          .arguments,
      <String, dynamic>{'text': 'scene_port_a'},
    );
    expect(opened, <NarrativeDependencyNavigationIntent>[navigationIntent]);
    expect(find.byTooltip('Ouvrir Embuscade'), findsNothing);
  });

  testWidgets(
      'Arrow keys cycle available options, Enter selects and Escape returns to search',
      (tester) async {
    final selected = <NarrativeDependencyKey>[];
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(key: sceneKey, label: 'Rencontre'),
          _option(
            key: incompatibleKey,
            label: 'Hors portée',
            availability: NarrativeReferenceAvailability.incompatible,
            diagnostic: 'Disponible dans une autre portée',
          ),
          _option(key: secondSceneKey, label: 'Embuscade'),
        ],
      ),
      onSelected: (option) => selected.add(option.key),
    );

    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_hasFocus(tester, sceneKey), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_hasFocus(tester, secondSceneKey), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_hasFocus(tester, sceneKey), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(_hasFocus(tester, secondSceneKey), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, <NarrativeDependencyKey>[secondSceneKey]);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue);
  });

  testWidgets('full dependency keys avoid map-child key and focus collisions',
      (tester) async {
    final selected = <NarrativeDependencyKey>[];
    await _pumpPicker(
      tester,
      readModel: _readModel(
        groupLabel: 'Éléments de map',
        options: <CanonicalNarrativeReferenceOption>[
          _option(
            key: mapChildA,
            label: 'Guide',
            kindLabel: 'PNJ',
            breadcrumbLabels: const <String>['Port Selbrume'],
          ),
          _option(
            key: mapChildB,
            label: 'Guide',
            kindLabel: 'PNJ',
            breadcrumbLabels: const <String>['Forêt Brumeuse'],
          ),
        ],
      ),
      onSelected: (option) => selected.add(option.key),
    );

    final portFinder =
        find.byKey(const ValueKey<NarrativeDependencyKey>(mapChildA));
    final forestFinder =
        find.byKey(const ValueKey<NarrativeDependencyKey>(mapChildB));
    expect(portFinder, findsOneWidget);
    expect(forestFinder, findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_hasFocus(tester, mapChildA), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_hasFocus(tester, mapChildB), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, <NarrativeDependencyKey>[mapChildB]);
  });

  testWidgets(
      'filtering retains a surviving full-key focus or returns to search',
      (tester) async {
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(key: sceneKey, label: 'Rencontre'),
          _option(key: secondSceneKey, label: 'Embuscade'),
        ],
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_hasFocus(tester, sceneKey), isTrue);

    tester
        .widget<PokeMapSearchField>(find.byType(PokeMapSearchField))
        .onChanged(
          'scene_port_a',
        );
    await tester.pump();
    expect(_hasFocus(tester, sceneKey), isTrue);

    tester
        .widget<PokeMapSearchField>(find.byType(PokeMapSearchField))
        .onChanged(
          'absent',
        );
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue);
  });

  testWidgets('disabled picker blocks search, focus, selection, copy and open',
      (tester) async {
    final selected = <CanonicalNarrativeReferenceOption>[];
    final opened = <NarrativeDependencyNavigationIntent>[];
    final platformCalls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    const intent = NarrativeDependencyNavigationIntent(
      kind: NarrativeDependencyTargetKind.scene,
      assetId: 'scene_port_a',
    );
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(
            key: sceneKey,
            label: 'Rencontre',
            navigationIntent: intent,
          ),
        ],
      ),
      enabled: false,
      onSelected: selected.add,
      onOpen: opened.add,
    );

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester
        .tap(find.byKey(const ValueKey<NarrativeDependencyKey>(sceneKey)));
    await tester.tap(find.byTooltip('Copier l’identifiant scene_port_a'));
    await tester.tap(find.byTooltip('Ouvrir Rencontre'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, isEmpty);
    expect(opened, isEmpty);
    expect(
      platformCalls.where((call) => call.method == 'Clipboard.setData'),
      isEmpty,
    );
    expect(_hasFocus(tester, sceneKey), isFalse);
  });

  testWidgets('semantics announce label, ID, availability and exact reason',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(key: sceneKey, label: 'Rencontre'),
          _option(
            key: incompatibleKey,
            label: 'Rencontre lointaine',
            availability: NarrativeReferenceAvailability.incompatible,
            diagnostic: 'Disponible dans une autre portée',
          ),
        ],
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Rencontre, scene_port_a, disponible, Port Selbrume',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Rencontre lointaine, scene_other_scope, incompatible, '
        'Port Selbrume, Disponible dans une autre portée',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('supports an unbounded scrolling parent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PokeMapNarrativeReferencePicker(
              label: 'Référence narrative',
              readModel: _readModel(
                options: <CanonicalNarrativeReferenceOption>[
                  _option(key: sceneKey, label: 'Rencontre'),
                ],
              ),
              selectedKey: null,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Rencontre'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a compact bounded height with a scrollable long list',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 220,
            child: PokeMapNarrativeReferencePicker(
              label: 'Référence narrative',
              readModel: _readModel(
                options: <CanonicalNarrativeReferenceOption>[
                  for (var index = 0; index < 8; index++)
                    _option(
                      key: NarrativeDependencyKey.scene('scene_$index'),
                      label: 'Scène $index',
                    ),
                ],
              ),
              selectedKey: null,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Scrollable), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

bool _hasFocus(WidgetTester tester, NarrativeDependencyKey key) {
  return tester
          .widget<FocusableActionDetector>(
            find.byKey(ValueKey<NarrativeDependencyKey>(key)),
          )
          .focusNode
          ?.hasFocus ??
      false;
}

Future<void> _pumpPicker(
  WidgetTester tester, {
  required CanonicalNarrativeReferencePickerReadModel readModel,
  NarrativeDependencyKey? selectedKey,
  ValueChanged<CanonicalNarrativeReferenceOption>? onSelected,
  ValueChanged<NarrativeDependencyNavigationIntent>? onOpen,
  bool enabled = true,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 520,
          height: 720,
          child: PokeMapNarrativeReferencePicker(
            label: 'Référence narrative',
            readModel: readModel,
            selectedKey: selectedKey,
            enabled: enabled,
            onSelected: onSelected ?? (_) {},
            onOpen: onOpen,
          ),
        ),
      ),
    ),
  );
}

CanonicalNarrativeReferencePickerReadModel _readModel({
  required List<CanonicalNarrativeReferenceOption> options,
  String groupLabel = 'Scenes',
  CanonicalNarrativeReferenceOption? missingSelection,
  CanonicalNarrativeReferenceOption? incompatibleSelection,
}) {
  return CanonicalNarrativeReferencePickerReadModel(
    groups: <CanonicalNarrativeReferenceGroup>[
      CanonicalNarrativeReferenceGroup(label: groupLabel, options: options),
    ],
    missingSelection: missingSelection,
    incompatibleSelection: incompatibleSelection,
  );
}

CanonicalNarrativeReferenceOption _option({
  required NarrativeDependencyKey key,
  required String label,
  String kindLabel = 'Scene',
  List<String> breadcrumbLabels = const <String>['Port Selbrume'],
  NarrativeReferencePublicationStatus publicationStatus =
      NarrativeReferencePublicationStatus.published,
  NarrativeReferenceAvailability availability =
      NarrativeReferenceAvailability.available,
  String? diagnostic,
  NarrativeDependencyNavigationIntent? navigationIntent,
}) {
  return CanonicalNarrativeReferenceOption(
    key: key,
    label: label,
    technicalId: key.id,
    kindLabel: kindLabel,
    groupLabel: 'Scenes',
    breadcrumbLabels: breadcrumbLabels,
    publicationStatus: publicationStatus,
    availability: availability,
    diagnostic: diagnostic,
    navigationIntent: navigationIntent,
    usageCount: 0,
  );
}
