import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/story_workspace/application/story_workspace_state.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/story/story_navigation.dart';
import 'package:avelune_studio/presentation/features/story/story_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final section in [StorySection.behaviours, StorySection.trame]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'the Verification label and badge fit and work at ${section.name} ×$scale',
        (tester) async {
          tester.view.physicalSize = const Size(1440, 4000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          const badgeText = 'À lancer';
          final selections = <StorySection>[];
          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('fr'),
              theme: studioTheme(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: StoryNavigation(
                  selected: section,
                  onSelected: selections.add,
                  verificationMarker: const StudioBadge(badgeText),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final badge = tester.renderObject<RenderParagraph>(
            find.text(badgeText),
          );
          for (var i = 0; i < badgeText.length; i++) {
            if (badgeText[i] == ' ') continue;
            final boxes = badge.getBoxesForSelection(
              TextSelection(baseOffset: i, extentOffset: i + 1),
            );
            expect(
              boxes,
              isNotEmpty,
              reason: 'character ${badgeText[i]} at $i',
            );
            expect(boxes.last.right, lessThanOrEqualTo(badge.size.width + 0.5));
            expect(
              boxes.last.bottom,
              lessThanOrEqualTo(badge.size.height + 0.5),
            );
          }
          final semanticLabel = find.bySemanticsLabel(
            RegExp('Vérification.*À lancer'),
          );
          expect(semanticLabel, findsOneWidget);
          final verification = tester.element(
            find.byKey(const ValueKey('story-section-verification')),
          );
          for (var i = 0; i < StorySection.values.length; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
          }
          var focusedOnVerification = false;
          FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
            element,
          ) {
            focusedOnVerification |= identical(element, verification);
            return !focusedOnVerification;
          });
          expect(focusedOnVerification, isTrue);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          expect(selections, [StorySection.verification]);
        },
      );
    }
  }

  testWidgets(
    'the narrow Histoire rail leaves room for the Verification label',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          theme: studioTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StoryWorkspace(
              section: StorySection.behaviours,
              onSelected: (_) {},
              editable: true,
              verificationMarker: const StudioBadge('À lancer'),
              builder: (panels) => panels(const SizedBox(), const SizedBox()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final label = tester.getRect(find.text('Vérification'));
      final badge = tester.getRect(find.text('À lancer'));
      expect(label.height, lessThan(55));
      expect(badge.top, greaterThan(label.bottom));
    },
  );

  testWidgets(
    'a collapsed inspector keeps edits and remains reachable at reduced width',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StoryWorkspace(
              section: StorySection.facts,
              onSelected: (_) {},
              editable: true,
              builder: (panels) => panels(
                const Text('Liste'),
                const TextField(key: ValueKey('inspector-draft')),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('story-inspector')), findsNothing);
      final toggle = find.byKey(const ValueKey('story-toggle-inspector'));
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('inspector-draft')),
        'Saisie conservée',
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text('Liste'), findsOneWidget);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text('Saisie conservée'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all seven section labels follow the Studio language', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final locale in [const Locale('fr'), const Locale('en')]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          theme: studioTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StoryWorkspace(
              section: StorySection.trame,
              onSelected: (_) {},
              editable: true,
              builder: (panels) => panels(const SizedBox(), const SizedBox()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final entries = tester.widgetList<StudioNavigationEntry>(
        find.byType(StudioNavigationEntry),
      );
      expect(
        entries.map((entry) => entry.label),
        locale.languageCode == 'fr'
            ? [
                'Trame',
                'Déclencheurs',
                'Scènes',
                'Dialogues',
                'Faits',
                'Règles du monde',
                'Vérification',
              ]
            : [
                'Plot',
                'Triggers',
                'Scenes',
                'Dialogues',
                'Facts',
                'World rules',
                'Verification',
              ],
      );
      expect(tester.takeException(), isNull);
    }
  });
}
