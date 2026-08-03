import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/l10n/app_localizations.dart';
import 'package:map_editor/l10n/l10n.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';

const _shellKeys = <String>{
  'appTitle',
  'brandName',
  'narrativeStudio',
  'beta',
  'back',
  'maps',
  'overview',
  'storylines',
  'scenes',
  'events',
  'cinematics',
  'dialogues',
  'facts',
  'worldRules',
  'validator',
  'eventBuilder',
  'mapEvents',
  'shellSemantics',
  'validate',
  'allChangesSaved',
  'unsavedChanges',
  'narrativeUnsavedTitle',
  'narrativeUnsavedMessage',
  'narrativeStayHere',
  'narrativeDiscard',
  'narrativeSave',
  'narrativeStatusSaved',
  'narrativeStatusDirty',
  'narrativeStatusSaving',
  'narrativeStatusFailed',
  'narrativeStatusConflicted',
  'narrativeStatusRecovered',
  'narrativeUndoTooltip',
  'narrativeRedoTooltip',
  'narrativeSaveTooltip',
  'narrativeAutosaveDisableTooltip',
  'narrativeAutosaveEnableTooltip',
  'narrativeCompareTooltip',
  'narrativeReloadTooltip',
  'narrativeKeepLocalTooltip',
  'narrativeDiscardTooltip',
  'narrativeCompareTitle',
  'narrativeCompareSemantics',
  'narrativeCompareBaseline',
  'narrativeCompareLocal',
  'narrativeCompareExternal',
  'narrativeNoCinematics',
  'narrativeCinematicCount',
  'migrationCenterSemantics',
  'migrationCenterTitle',
  'migrationCenterDryRunSummary',
  'migrationCenterClose',
  'migrationCenterRefresh',
  'migrationCenterCreateBackup',
  'migrationCenterLegacyRemaining',
  'migrationCenterBlockers',
  'migrationCenterLossRisks',
  'migrationCenterReadersRetirable',
  'migrationCenterCompatibilityReadOnly',
  'migrationCenterCanonicalMessage',
  'migrationCenterReadOnlyMessage',
  'migrationCenterStorylineDomain',
  'migrationCenterEventDomain',
  'migrationCenterCinematicDomain',
  'migrationCenterDomainSummary',
  'migrationCenterCanonical',
  'migrationCenterLegacyVisible',
  'migrationCenterBlockerDependencySummary',
  'migrationCenterExamine',
  'migrationCenterRollbackHint',
  'commandPaletteBarrier',
  'commandPaletteSemantics',
  'commandPaletteTitle',
  'commandPaletteSearchHint',
  'commandPaletteSearchSemantics',
  'commandPaletteNoResults',
  'commandPaletteNoResultsHint',
  'sceneGraphInputPortSemantics',
  'sceneGraphOutputPortSemantics',
  'commandPaletteKindMap',
  'commandPaletteKindStoryline',
  'commandPaletteKindChapter',
  'commandPaletteKindStep',
  'commandPaletteKindScene',
  'commandPaletteKindEvent',
  'commandPaletteKindCinematic',
  'commandPaletteKindDialogue',
  'commandPaletteKindFact',
  'commandPaletteKindWorldRule',
  'commandPaletteKindMedia',
  'commandPaletteKindDiagnostic',
  'commandPaletteActionNavigation',
  'commandPaletteActionCreate',
  'commandPaletteActionValidate',
  'commandPaletteActionPreview',
  'commandPaletteActionSave',
  'commandPaletteTooltip',
  'personalizationReadinessSemantics',
  'personalizationReadinessTitle',
  'personalizationReadinessDescription',
  'personalizationExportBlocked',
  'personalizationReadyWithWarnings',
  'personalizationReadyToExport',
  'personalizationChecking',
  'personalizationPreflightInterrupted',
  'personalizationPreflightStale',
  'personalizationPreflightRequired',
  'personalizationDraftMustBeSaved',
  'personalizationRunPreflight',
  'personalizationRerunPreflight',
  'personalizationSaveGuidance',
  'personalizationSaveDraft',
  'personalizationCorrectionsRecommended',
  'personalizationExportReadyGuidance',
  'personalizationExportLockedGuidance',
  'personalizationContinueToExport',
  'personalizationCategoryBranding',
  'personalizationCategoryIntro',
  'personalizationCategoryTypography',
  'personalizationCategoryTheme',
  'personalizationCategoryValid',
  'personalizationCategoryDefaultValid',
  'personalizationCategoryNeedsCorrection',
  'personalizationCategoryNeedsReview',
  'personalizationCategoryReady',
  'personalizationBlockerCount',
  'personalizationWarningCount',
  'personalizationCorrectInCategory',
  'personalizationUseSafeTheme',
  'personalizationSeverityBlocker',
  'personalizationSeverityWarning',
  'personalizationPreflightReadError',
  'editorUpdateAvailableTitle',
  'editorUpdateAvailableBody',
  'editorUpdateReadNotes',
  'editorUpdateInstall',
  'editorUpdateCheck',
  'editorUpdateChecking',
  'editorUpdateUpToDate',
  'editorUpdateUpToDateBody',
  'editorUpdateManualCheckFailedTitle',
  'editorUpdateManualCheckFailed',
  'editorUpdateRetry',
  'editorUpdateOpenGitHub',
  'editorUpdateUnsavedTitle',
  'editorUpdateUnsavedBody',
  'editorUpdateSaveBeforeRestart',
  'editorUpdateCancelled',
  'editorUpdateUnsupported',
  'editorUpdateUnsupportedTitle',
  'editorUpdateDismiss',
  'editorUpdateBackToEditor',
  'editorUpdateRetryRestart',
  'editorUpdateInstalling',
  'editorUpdateRestarting',
  'editorUpdateHelp',
  'editorUpdateBlockerMap',
  'editorUpdateBlockerProjectManifest',
  'editorUpdateBlockerNarrative',
  'editorUpdateBlockerPersonalization',
  'editorUpdateBlockerBorderPreview',
  'editorUpdateBlockerBorderStudio',
  'editorUpdateBlockerPathStudio',
  'editorUpdateBlockerStepStudio',
  'editorUpdateBlockerEnvironmentStudio',
  'editorUpdateBlockerDialogueStudio',
  'editorUpdateBlockerGlobalStoryStudio',
  'editorUpdateBlockerEventBuilderV2',
  'editorUpdateBlockerPendingTemplate',
  'editorUpdateBlockerSaveInProgress',
  'editorUpdateBlockerUnknown',
};

void main() {
  test('FR and EN ARB expose the same complete shell key set', () {
    final french = _messageKeys(File('lib/l10n/app_fr.arb'));
    final english = _messageKeys(File('lib/l10n/app_en.arb'));

    expect(french, _shellKeys);
    expect(english, _shellKeys);
    expect(
        AppLocalizations.supportedLocales, const [Locale('fr'), Locale('en')]);
  });

  testWidgets('shell resolves French and English rail labels', (tester) async {
    await _pumpLocalizedShell(tester, const Locale('fr'));
    expect(find.text('Aperçu'), findsOneWidget);
    expect(find.text('Événements'), findsOneWidget);
    expect(find.text('Événements par map'), findsOneWidget);

    await _pumpLocalizedShell(tester, const Locale('en'));
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Map events'), findsOneWidget);
  });

  testWidgets('unsupported locale falls back to French', (tester) async {
    late String resolvedOverview;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            resolvedOverview = context.pokeMapL10n.overview;
            return Text(resolvedOverview);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(resolvedOverview, 'Aperçu');
    expect(find.text('Aperçu'), findsOneWidget);
  });

  testWidgets('migration and command palette strings resolve in FR and EN',
      (tester) async {
    await _pumpLocalizedShell(tester, const Locale('fr'));
    var french =
        tester.element(find.byType(NarrativeStudioProductShell)).pokeMapL10n;
    expect(french.migrationCenterTitle, 'Migration Narrative Studio');
    expect(french.commandPaletteTitle, 'Aller à…');
    expect(
      french.sceneGraphOutputPortSemantics('Victoire', 'combat'),
      contains('Victoire'),
    );

    await _pumpLocalizedShell(tester, const Locale('en'));
    final english =
        tester.element(find.byType(NarrativeStudioProductShell)).pokeMapL10n;
    expect(english.migrationCenterTitle, 'Narrative Studio migration');
    expect(english.commandPaletteTitle, 'Go to…');
    expect(
      english.migrationCenterDomainSummary(2, 1),
      '2 remaining • 1 ready',
    );
  });

  test('shared shell source contains no product UI string literal', () {
    const paths = <String>[
      'lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart',
      'lib/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart',
      'lib/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart',
      'lib/src/ui/canvas/narrative_studio/narrative_legacy_migration_center.dart',
    ];
    final patterns = <RegExp>[
      RegExp(r'''Text\(\s*['"]'''),
      RegExp(r'''\blabel:\s*['"]'''),
      RegExp(r'''\btooltip:\s*['"]'''),
      RegExp(r'''Semantics\([^)]*\blabel:\s*['"]''', dotAll: true),
    ];

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      for (final pattern in patterns) {
        expect(
          pattern.hasMatch(source),
          isFalse,
          reason: '$path still owns a product literal matched by $pattern',
        );
      }
    }
  });
}

Set<String> _messageKeys(File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return json.keys
      .where((key) => key != '@@locale' && !key.startsWith('@'))
      .toSet();
}

Future<void> _pumpLocalizedShell(WidgetTester tester, Locale locale) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 941);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: NarrativeStudioProductShell(
          selectedDestination: NarrativeStudioDestination.events,
          selectedLocation: NarrativeStudioRouteLocation.events(),
          onSelectDestination: (_) {},
          onSelectLocation: (_) {},
          onOpenMaps: () {},
          workspace: const SizedBox.expand(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
