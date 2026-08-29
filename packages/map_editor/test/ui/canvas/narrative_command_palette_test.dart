import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/narrative_capability_evidence.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_command_palette.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';

void main() {
  test('authoring attestation covers every publishable builder command', () {
    final catalog = NarrativeCommandCatalog.canonical();
    final attestation =
        buildMapEditorNarrativeCommandAuthoringAttestation(catalog: catalog);

    expect(
      attestation.referencesByCapabilityId.keys,
      unorderedEquals(catalog.publishable.map((command) => command.id)),
    );
    expect(
      attestation.referenceFor(NarrativeCommandIds.railJourney),
      endsWith(
        'narrative_template_catalog.dart#buildSceneRailJourneyPayload',
      ),
    );
    expect(
      attestation.referencesByCapabilityId.entries
          .where((entry) => entry.key != NarrativeCommandIds.railJourney)
          .map((entry) => entry.value),
      everyElement(endsWith('scene_action_builder.dart#SceneActionBuilder')),
    );
  });

  testWidgets('palette searches accents, ids and opens the selected asset', (
    tester,
  ) async {
    NarrativeGlobalSearchEntry? opened;
    await tester.pumpWidget(
      _host(
        NarrativeCommandPalette(
          index: _index,
          actions: const [],
          onOpenEntry: (entry) => opened = entry,
          onDismiss: () {},
        ),
      ),
    );

    await tester.enterText(
      find.byKey(narrativeCommandPaletteSearchKey),
      'ecl brm',
    );
    await tester.pump();

    expect(find.text('Éclat de Brume'), findsOneWidget);
    expect(find.text('fact.eclat'), findsOneWidget);

    await tester.tap(find.text('Éclat de Brume'));
    expect(opened?.technicalId, 'fact.eclat');
  });

  testWidgets('palette exposes available product commands to keyboard', (
    tester,
  ) async {
    var saved = false;
    await tester.pumpWidget(
      _host(
        NarrativeCommandPalette(
          index: _index,
          actions: [
            NarrativeCommandPaletteAction(
              id: 'save',
              label: 'Enregistrer le projet',
              kind: NarrativeCommandPaletteActionKind.save,
              onInvoke: () => saved = true,
            ),
          ],
          onOpenEntry: (_) {},
          onDismiss: () {},
        ),
      ),
    );

    expect(find.text('Enregistrer le projet'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(saved, isTrue);
  });

  testWidgets(
      'authoring actions expose only commands executable by the current runtime',
      (tester) async {
    NarrativeCommandDescriptor? opened;
    final actions = buildNarrativeCommandAuthoringPaletteActions(
      runtimeCommandIds: const {
        NarrativeCommandIds.healParty,
        NarrativeCommandIds.awardBadge,
        NarrativeCommandIds.unlockFieldAbility,
        NarrativeCommandIds.railJourney,
      },
      capabilityTruth: _completeTruth(),
      onOpenCommand: (command) => opened = command,
    );
    await tester.pumpWidget(
      _host(
        NarrativeCommandPalette(
          index: _index,
          actions: actions,
          onOpenEntry: (_) {},
          onDismiss: () {},
        ),
      ),
    );

    expect(find.text('Créer · Soigner l’équipe'), findsOneWidget);
    expect(find.text('Créer · Donner un badge'), findsOneWidget);
    expect(
      find.text('Créer · Débloquer une capacité terrain'),
      findsOneWidget,
    );
    expect(find.text('Créer · Piloter un voyage ferroviaire'), findsOneWidget);
    expect(find.textContaining('Modifier la présence'), findsNothing);

    await tester.tap(find.text('Créer · Donner un badge'));
    expect(opened?.id, NarrativeCommandIds.awardBadge);
  });

  test('authoring actions hide a promoted command with incomplete truth', () {
    final actions = buildNarrativeCommandAuthoringPaletteActions(
      runtimeCommandIds: const {NarrativeCommandIds.healParty},
      capabilityTruth: const [
        ProjectCapabilityTruthRecord.promoted(
          capabilityId: 'narrative.command.${NarrativeCommandIds.healParty}',
          authoringControl: 'SceneActionBuilder.healParty',
          contractField: 'healParty',
          runtimeConsumer: '',
          playerSurface: 'Scene flow',
          positiveTest: 'positive_test.dart',
          negativeTest: 'negative_test.dart',
        ),
      ],
      onOpenCommand: (_) {},
    );

    expect(actions, isEmpty);
  });

  testWidgets('product shell opens palette with command K and restores focus', (
    tester,
  ) async {
    final focusNode = FocusNode(debugLabel: 'workspace-anchor');
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      _host(
        NarrativeStudioProductShell(
          selectedDestination: NarrativeStudioDestination.overview,
          onSelectDestination: (_) {},
          onOpenMaps: () {},
          globalSearchIndex: _index,
          onOpenSearchEntry: (_) {},
          commandPaletteActions: const [],
          workspace: Focus(
            focusNode: focusNode,
            autofocus: true,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();

    expect(find.byKey(narrativeCommandPaletteKey), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(narrativeCommandPaletteKey), findsNothing);
    expect(focusNode.hasFocus, isTrue);
  });
}

List<ProjectCapabilityTruthRecord> _completeTruth() {
  final catalog = NarrativeCommandCatalog.canonical();
  final fallback = ProjectCapabilityTruthAttestation(
    referencesByCapabilityId: {
      for (final command in catalog.publishable)
        command.id: 'verified_adapter.dart#${command.id}',
    },
  );
  return buildNarrativeCommandCapabilityTruthMatrix(
    catalog: catalog,
    authoring: buildMapEditorNarrativeCommandAuthoringAttestation(
      catalog: catalog,
    ),
    runtime: fallback,
    playerSurface: fallback,
    positiveTests: fallback,
    negativeTests: fallback,
  );
}

final _index = NarrativeGlobalSearchIndex.fromEntries(
  revision: 1,
  entries: const [
    NarrativeGlobalSearchEntry(
      kind: NarrativeGlobalSearchKind.fact,
      technicalId: 'fact.eclat',
      label: 'Éclat de Brume',
      tags: ['port'],
    ),
    NarrativeGlobalSearchEntry(
      kind: NarrativeGlobalSearchKind.scene,
      technicalId: 'scene.port',
      label: 'Rencontre au port',
    ),
  ],
);

Widget _host(Widget child) => MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SizedBox(width: 1200, height: 800, child: child),
      ),
    );
