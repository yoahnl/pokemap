import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:avelune_studio/presentation/features/stories/story_progression_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_action_card.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/ui13_host_harness.dart';
import '../support/ui13_widget_verification_port.dart';

void main() {
  testWidgets('overview summarizes the last real verification report', (
    tester,
  ) async {
    late Ui13WidgetVerificationPort monitored;
    final project = await host(
      tester,
      launch: false,
      wrap: (port) {
        monitored = port as Ui13WidgetVerificationPort;
        return port;
      },
    );
    await activate(tester, find.byTooltip('Retour à Histoire'));
    expect(find.textContaining('Non vérifié'), findsOneWidget);
    expect(monitored.runs, 0);
    expect(monitored.analyses, 0);
    expect(monitored.sourceReads, 0);
    await activate(tester, find.text('Ouvrir la vérification').first);
    await activate(tester, find.text('Lancer la vérification').first);
    final controller = opened(tester);
    for (var i = 0; i < 40 && controller.report == null; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final report = opened(tester).report!;
    final reads = monitored.runs;
    final analyses = monitored.analyses;
    final sources = monitored.sourceReads;
    await activate(tester, find.byTooltip('Retour à Histoire'));
    expect(find.byType(NarrativeStoryPane), findsOneWidget);
    expect(find.text('Vérification narrative'), findsWidgets);
    expect(find.text('Rapport du projet'), findsOneWidget);
    expect(
      find.textContaining(
        '${report.countOf(NarrativeProjectDiagnosticSeverity.error)} erreur(s)',
      ),
      findsWidgets,
    );
    expect(
      find.textContaining(
        '${report.countOf(NarrativeProjectDiagnosticSeverity.warning)} avertissement(s)',
      ),
      findsWidgets,
    );
    expect(find.textContaining('Périmètre :'), findsOneWidget);
    expect(find.textContaining('Structure :'), findsOneWidget);
    expect(find.textContaining('Limites :'), findsOneWidget);
    expect(monitored.runs, reads);
    expect(monitored.analyses, analyses);
    expect(monitored.sourceReads, sources);
    await activate(
      tester,
      find.widgetWithText(StudioActionCard, 'Nouvelle histoire'),
    );
    await tester.enterText(find.byType(TextField).last, 'À vérifier');
    await activate(tester, find.widgetWithText(StudioButton, 'Créer'));
    expect(find.byType(StoryProgressionPage), findsOneWidget);
    final storyId = tester
        .widget<StoryProgressionPage>(find.byType(StoryProgressionPage))
        .controller
        .activeId!;
    await activate(tester, find.widgetWithText(StudioButton, 'Histoire').last);
    expect(
      find.textContaining('Modifications depuis ce contrôle'),
      findsOneWidget,
    );
    expect(monitored.runs, reads);
    expect(monitored.analyses, analyses);
    await activate(tester, find.text('Ouvrir la vérification').first);
    await activate(tester, find.text('Lancer la vérification').first);
    for (
      var i = 0;
      i < 40 && controller.report?.requestId == report.requestId;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(controller.report?.requestId, isNot(report.requestId));
    final refreshedAnalyses = monitored.analyses;
    final refreshedSources = monitored.sourceReads;
    await activate(tester, find.byTooltip('Retour à Histoire'));
    expect(
      find.textContaining('Modifications depuis ce contrôle'),
      findsNothing,
    );
    await activate(tester, find.byKey(ValueKey('overview-story-$storyId')));
    final story = tester.widget<StoryProgressionPage>(
      find.byType(StoryProgressionPage),
    );
    expect(
      story.controller.mutate(
        (current) => current.copyWith(
          storylines: [
            for (final item in current.storylines)
              item.id == storyId
                  ? item.copyWith(title: 'À vérifier encore')
                  : item,
          ],
        ),
      ),
      isTrue,
    );
    await activate(tester, find.widgetWithText(StudioButton, 'Histoire').last);
    expect(
      find.textContaining('Modifications depuis ce contrôle'),
      findsOneWidget,
    );
    expect(monitored.analyses, refreshedAnalyses);
    expect(monitored.sourceReads, refreshedSources);
    expect(project.maps.project?.name, isNotEmpty);
  });
}
