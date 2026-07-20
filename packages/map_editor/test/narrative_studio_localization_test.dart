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

  test('shared shell source contains no product UI string literal', () {
    const paths = <String>[
      'lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart',
      'lib/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart',
      'lib/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart',
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
