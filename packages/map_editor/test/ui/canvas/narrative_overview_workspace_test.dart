import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart';
import 'package:map_editor/src/features/narrative/application/global_story_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/application/overview/narrative_overview_read_model.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
import 'package:map_editor/src/ui/canvas/narrative_overview_workspace.dart';

void main() {
  testWidgets(
    'NarrativeOverviewWorkspace renders a minimal authoring overview from the read model',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await _pumpOverview(tester, readModel);

      expect(
        find.byKey(const ValueKey('narrative-overview-page-header')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('narrative-overview-breadcrumb')),
        findsOneWidget,
      );
      expect(find.text('PokeMap'), findsOneWidget);
      expect(find.widgetWithText(CupertinoButton, 'PokeMap'), findsNothing);
      expect(find.text('Narrative Studio'), findsOneWidget);
      expect(find.text('Aperçu'), findsWidgets);
      expect(
        find.text(
          'Vue d’ensemble auteur : métriques et statuts honnêtes.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Narrative Overview'), findsNothing);
      expect(find.textContaining('progression'), findsNothing);
      expect(find.textContaining('jouable'), findsNothing);
      expect(find.textContaining('test_project'), findsWidgets);
      expect(find.textContaining('Non évalué'), findsWidgets);
      expect(find.text('Indicateurs auteur'), findsOneWidget);
      for (final label in <String>[
        'Chapitres',
        'Scènes',
        'Cinématiques',
        'Quêtes',
        'Dialogues',
        'Problèmes ouverts',
      ]) {
        expect(find.text(label), findsWidgets);
      }
      for (final metricId in <String>[
        'chapters',
        'scenes',
        'cutscenes',
        'quests',
        'dialogues',
        'open_issues',
      ]) {
        expect(
          find.byKey(ValueKey('narrative-overview-kpi-$metricId')),
          findsOneWidget,
        );
      }
      await tester.scrollUntilVisible(
        find.byKey(
          const ValueKey('narrative-overview-empty-states-section'),
          skipOffstage: false,
        ),
        320,
      );
      await tester.pump();
      expect(
        find.text('Données à venir', skipOffstage: false),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace does not present unavailable modules as real data',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await _pumpOverview(tester, readModel);

      expect(_textInKpi('dialogues', '0'), findsOneWidget);
      expect(_textInKpi('chapters', '0'), findsOneWidget);
      expect(_textInKpi('quests', 'Hors scope V0'), findsOneWidget);
      expect(_textInKpi('quests', 'Pas de modèle Quest'), findsOneWidget);
      expect(_textInKpi('open_issues', 'Non évalué'), findsOneWidget);
      expect(
        _textInKpi('open_issues', 'Validation non lancée'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(
          const ValueKey('narrative-overview-empty-states-section'),
          skipOffstage: false,
        ),
        320,
      );
      await tester.pump();
      expect(
        _textInEmptyState('facts', 'Nécessite un modèle'),
        findsOneWidget,
      );
      expect(
        _textInEmptyState('recent_activity', 'Hors scope V0'),
        findsOneWidget,
      );
      expect(
        _textInEmptyState('notifications', 'Hors scope V0'),
        findsOneWidget,
      );

      expect(find.textContaining('Selbrume'), findsNothing);
      expect(find.textContaining('La brume du phare'), findsNothing);
      expect(find.text('42'), findsNothing);
      expect(find.text('1 236'), findsNothing);
      expect(find.text('1236'), findsNothing);
      expect(find.text('24'), findsNothing);
      expect(find.text('12'), findsNothing);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace renders honest upcoming data states and footer metadata',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await _pumpOverview(tester, readModel, width: 1440, height: 1180);

      await tester.scrollUntilVisible(
        find.byKey(
          const ValueKey('narrative-overview-empty-states-section'),
          skipOffstage: false,
        ),
        360,
      );
      await tester.pump();

      expect(find.text('Données à venir', skipOffstage: false), findsOneWidget);
      expect(_textInEmptyState('facts', 'Facts'), findsOneWidget);
      expect(_textInEmptyState('facts', 'Nécessite un modèle'), findsOneWidget);
      expect(
        _textInEmptyState(
          'facts',
          'Registre de connaissances à définir avant affichage.',
        ),
        findsOneWidget,
      );
      expect(
        _textInEmptyState('recent_activity', 'Activité récente'),
        findsOneWidget,
      );
      expect(
        _textInEmptyState('recent_activity', 'Hors scope V0'),
        findsOneWidget,
      );
      expect(
        _textInEmptyState('notifications', 'Notifications'),
        findsOneWidget,
      );
      expect(
        _textInEmptyState('notifications', 'Hors scope V0'),
        findsOneWidget,
      );
      expect(_textInEmptyState('footer_locale', 'Locale'), findsOneWidget);
      expect(_textInEmptyState('footer_locale', 'Non définie'), findsOneWidget);
      expect(_textInEmptyState('footer_version', 'Version'), findsOneWidget);
      expect(
        _textInEmptyState('footer_version', 'Non définie'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(
          const ValueKey('narrative-overview-footer'),
          skipOffstage: false,
        ),
        320,
      );
      await tester.pump();

      expect(_textInFooter('project', 'Projet : test_project'), findsOneWidget);
      expect(_textInFooter('locale', 'Locale : non définie'), findsOneWidget);
      expect(_textInFooter('version', 'Version : non définie'), findsOneWidget);

      for (final fakeActivity in <String>[
        'Cinématique modifiée',
        'Dialogue ajouté',
        'Chapitre édité',
        'Problème résolu',
        'Fact créé',
        'Il y a 15 min',
        'il y a 15 min',
      ]) {
        expect(find.textContaining(fakeActivity), findsNothing);
      }
      expect(find.text('FR'), findsNothing);
      expect(find.text('v0.3.0'), findsNothing);
      expect(find.textContaining('Selbrume'), findsNothing);
      expect(find.textContaining('Port Selbrume'), findsNothing);
      expect(find.textContaining('Mystère'), findsNothing);
      expect(find.text('42'), findsNothing);
      expect(find.text('1 236'), findsNothing);
      expect(find.text('1236'), findsNothing);
      expect(find.text('24'), findsNothing);
      expect(find.text('12'), findsNothing);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace KPI cards consume read model values',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      await _pumpOverview(tester, readModel, width: 960);

      expect(_textInKpi('dialogues', '1'), findsOneWidget);
      expect(_textInKpi('dialogues', 'Disponible'), findsOneWidget);
      expect(_textInKpi('quests', 'Hors scope V0'), findsOneWidget);
      expect(_textInKpi('open_issues', 'Non évalué'), findsOneWidget);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await _pumpOverview(tester, readModel, width: 620, height: 720);

      expect(find.text('Aperçu'), findsWidgets);
      expect(
        find.text(
          'Vue d’ensemble auteur : métriques et statuts honnêtes.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('test_project'), findsWidgets);
      expect(find.byKey(const ValueKey('narrative-overview-kpi-grid')),
          findsOneWidget);
      expect(_textInKpi('cutscenes', '0'), findsOneWidget);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace keeps KPI cards visible after header density polish',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await _pumpOverview(tester, readModel, width: 1440, height: 720);

      final header = find.byKey(
        const ValueKey('narrative-overview-page-header'),
      );
      final kpiGrid = find.byKey(
        const ValueKey('narrative-overview-kpi-grid'),
      );

      expect(header, findsOneWidget);
      expect(kpiGrid, findsOneWidget);
      expect(tester.getTopLeft(kpiGrid).dy, lessThanOrEqualTo(165));
      expect(find.text('Indicateurs auteur'), findsOneWidget);
      expect(find.text('Histoire principale'), findsOneWidget);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace renders an honest empty main story card',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await _pumpOverview(tester, readModel);

      expect(find.byKey(const ValueKey('narrative-overview-main-story-card')),
          findsOneWidget);
      expect(find.text('Histoire principale'), findsOneWidget);
      expect(find.text('Aucune histoire principale'), findsOneWidget);
      expect(find.text('Aucune histoire principale définie.'), findsOneWidget);
      expect(find.text('Modifier à venir'), findsOneWidget);
      expect(_textInMainStory('Problèmes ouverts'), findsOneWidget);
      expect(_textInMainStory('Non évalué'), findsWidgets);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace renders explicit main story data from the read model',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          scenarios: <ScenarioAsset>[
            _globalStoryWithDocuments(),
            _cutsceneScenario(
              id: 'test_cutscene_1',
              dialogueId: 'test_dialogue_1',
            ),
          ],
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      await _pumpOverview(tester, readModel, width: 1040, height: 960);

      expect(find.text('Test Main Story'), findsOneWidget);
      expect(find.text('A generic authoring synopsis.'), findsOneWidget);
      expect(_textInMainStory('Scènes liées'), findsOneWidget);
      expect(_textInMainStory('Dialogues liés'), findsOneWidget);
      expect(_textInMainStory('1'), findsNWidgets(2));
      expect(_textInMainStory('Problèmes ouverts'), findsOneWidget);
      expect(_textInMainStory('Non évalué'), findsWidgets);
      expect(find.text('Test Chapter One'), findsWidgets);
      expect(find.text('Test Chapter Two'), findsWidgets);
      expect(find.textContaining('Fallback'), findsNothing);
      expect(find.textContaining('Selbrume'), findsNothing);
      expect(find.textContaining('La brume du phare'), findsNothing);
      expect(find.text('42'), findsNothing);
      expect(find.text('27'), findsNothing);
      expect(find.text('412'), findsNothing);
      expect(find.text('3'), findsNothing);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace explains missing description and fallback chapters',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          scenarios: const <ScenarioAsset>[
            ScenarioAsset(
              id: 'test_global_story',
              name: 'Fallback Test Story',
              description: '',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
              metadata: <String, String>{
                'step.id': 'test_step_1',
                'step.name': 'Fallback Step',
                'step.cutsceneIds': 'test_cutscene_1',
              },
            ),
            ScenarioAsset(
              id: 'test_cutscene_1',
              name: 'Test Cutscene',
              scope: ScenarioScope.localEventFlow,
              entryNodeId: 'start',
              metadata: <String, String>{
                kCutsceneStudioSchemaMetadataKey: kCutsceneStudioSchemaVersion,
              },
            ),
          ],
        ),
      );

      await _pumpOverview(tester, readModel, width: 1040, height: 960);

      expect(find.text('Fallback Test Story'), findsOneWidget);
      expect(find.text('Synopsis non renseigné.'), findsOneWidget);
      expect(find.text('Chapitres issus d’un fallback'), findsOneWidget);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace renders ambiguous main story state explicitly',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          scenarios: const <ScenarioAsset>[
            ScenarioAsset(
              id: 'test_global_story_a',
              name: 'Test Story A',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
            ),
            ScenarioAsset(
              id: 'test_global_story_b',
              name: 'Test Story B',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
            ),
          ],
        ),
      );

      await _pumpOverview(tester, readModel);

      expect(find.text('Sélection requise'), findsOneWidget);
      expect(find.text('Plusieurs histoires principales possibles.'),
          findsOneWidget);
      expect(find.text('Source ambiguë'), findsOneWidget);
      expect(_textInMainStory('Indisponible'), findsWidgets);
      expect(find.text('Test Story A'), findsNothing);
      expect(find.text('Test Story B'), findsNothing);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace renders honest narrative module cards',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await _pumpOverview(tester, readModel, width: 1040, height: 1120);

      expect(find.text('Modules narratifs'), findsOneWidget);
      expect(find.byKey(const ValueKey('narrative-overview-module-grid')),
          findsOneWidget);
      for (final moduleId in <String>[
        NarrativeOverviewModuleIds.quests,
        NarrativeOverviewModuleIds.cutscenes,
        NarrativeOverviewModuleIds.dialogues,
        NarrativeOverviewModuleIds.conditions,
        NarrativeOverviewModuleIds.worldRules,
        NarrativeOverviewModuleIds.facts,
      ]) {
        expect(
          find.byKey(ValueKey('narrative-overview-module-$moduleId')),
          findsOneWidget,
        );
      }
      for (final label in <String>[
        'Quêtes annexes',
        'Cinématiques',
        'Dialogues',
        'Conditions narratives',
        'Règles du monde',
        'Facts',
      ]) {
        expect(find.text(label), findsWidgets);
      }

      expect(
        _textInModule(
          NarrativeOverviewModuleIds.quests,
          'Hors scope V0',
        ),
        findsOneWidget,
      );
      expect(
        _textInModule(
          NarrativeOverviewModuleIds.quests,
          'Les quêtes ne sont pas encore modélisées en V0.',
        ),
        findsOneWidget,
      );
      expect(
        _textInModule(
          NarrativeOverviewModuleIds.facts,
          'Nécessite un modèle',
        ),
        findsOneWidget,
      );
      expect(
        _textInModule(
          NarrativeOverviewModuleIds.facts,
          'Les Facts nécessitent un futur registre de connaissances.',
        ),
        findsOneWidget,
      );
      expect(
          _textInModule(NarrativeOverviewModuleIds.quests, '0'), findsNothing);
      expect(
          _textInModule(NarrativeOverviewModuleIds.facts, '0'), findsNothing);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace module cards consume read model values',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          scenarios: <ScenarioAsset>[
            _globalStoryWithDocuments(),
            _cutsceneScenario(
              id: 'test_cutscene_1',
              dialogueId: 'test_dialogue_1',
            ),
          ],
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      await _pumpOverview(tester, readModel, width: 1040, height: 1120);

      expect(_textInModule(NarrativeOverviewModuleIds.cutscenes, '1'),
          findsOneWidget);
      expect(_textInModule(NarrativeOverviewModuleIds.dialogues, '1'),
          findsOneWidget);
      expect(_textInModule(NarrativeOverviewModuleIds.conditions, '2'),
          findsOneWidget);
      expect(_textInModule(NarrativeOverviewModuleIds.worldRules, '1'),
          findsOneWidget);
      expect(
        _textInModule(NarrativeOverviewModuleIds.dialogues, 'Indisponible'),
        findsOneWidget,
      );
      expect(
        _textInModule(
          NarrativeOverviewModuleIds.dialogues,
          'Lignes de dialogue',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Selbrume'), findsNothing);
      expect(find.textContaining('La brume du phare'), findsNothing);
      expect(find.text('42'), findsNothing);
      expect(find.text('24'), findsNothing);
      expect(find.text('12'), findsNothing);
      expect(find.text('312'), findsNothing);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace module grid keeps previous overview blocks visible',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await _pumpOverview(tester, readModel, width: 680, height: 1180);

      expect(find.text('Indicateurs auteur'), findsOneWidget);
      expect(find.byKey(const ValueKey('narrative-overview-main-story-card')),
          findsOneWidget);
      expect(find.text('Modules narratifs'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey(
            'narrative-overview-module-${NarrativeOverviewModuleIds.quests}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'narrative-overview-module-${NarrativeOverviewModuleIds.facts}',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace renders an honest structure inspector panel',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await _pumpOverview(tester, readModel, width: 1440, height: 980);

      expect(
        find.byKey(
          const ValueKey('narrative-overview-structure-inspector'),
        ),
        findsOneWidget,
      );
      expect(_textInStructureInspector('STRUCTURE NARRATIVE'), findsOneWidget);
      expect(_textInStructureInspector('test_project'), findsOneWidget);
      expect(_textInStructureInspector('Non évalué'), findsWidgets);
      expect(_textInStructureInspector('À jour'), findsNothing);
      expect(
        _textInStructureInspector('Description non disponible en V0.'),
        findsOneWidget,
      );
      expect(
        _textInStructureInspector('Tags non disponibles en V0.'),
        findsOneWidget,
      );
      expect(
        _textInStructureInspector('Aucun chapitre authoré.'),
        findsOneWidget,
      );
      expect(
        _textInStructureInspector('Validation non lancée'),
        findsOneWidget,
      );
      expect(_textInStructureCounter('facts', 'Facts'), findsOneWidget);
      expect(
        _textInStructureCounter('facts', 'Nécessite un modèle'),
        findsOneWidget,
      );

      for (final forbidden in <String>[
        'Selbrume',
        'Port Selbrume',
        'Phare',
        'Mystère',
        'Exploration',
        'Fantastique',
        'Côtiers',
      ]) {
        expect(find.textContaining(forbidden), findsNothing);
      }
      expect(find.text('42'), findsNothing);
      expect(find.text('24'), findsNothing);
      expect(find.text('12'), findsNothing);
      expect(find.text('312'), findsNothing);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace structure inspector consumes read model counters and chapters',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          scenarios: <ScenarioAsset>[
            _globalStoryWithDocuments(),
            _cutsceneScenario(
              id: 'test_cutscene_1',
              dialogueId: 'test_dialogue_1',
            ),
          ],
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      await _pumpOverview(tester, readModel, width: 1440, height: 980);

      expect(_textInStructureCounter('chapters', '2'), findsOneWidget);
      expect(_textInStructureCounter('scenes', '1'), findsOneWidget);
      expect(_textInStructureCounter('cutscenes', '1'), findsOneWidget);
      expect(_textInStructureCounter('dialogues', '1'), findsOneWidget);
      expect(
        _textInStructureCounter('facts', 'Nécessite un modèle'),
        findsOneWidget,
      );
      expect(_textInStructureInspector('Test Chapter One'), findsOneWidget);
      expect(_textInStructureInspector('Test Chapter Two'), findsOneWidget);
      expect(_textInStructureInspector('KPI cards'), findsNothing);
      expect(find.textContaining('Selbrume'), findsNothing);
      expect(find.textContaining('La brume du phare'), findsNothing);
      expect(find.text('42'), findsNothing);
      expect(find.text('27'), findsNothing);
      expect(find.text('412'), findsNothing);
      expect(find.text('312'), findsNothing);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace structure inspector shows clean validation as up to date',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
        narrativeValidationReport: NarrativeValidationReport(
          diagnostics: const <NarrativeValidationDiagnostic>[],
        ),
      );

      await _pumpOverview(tester, readModel, width: 1440, height: 980);

      expect(_textInStructureInspector('À jour'), findsWidgets);
      expect(
        _textInStructureInspector('0 diagnostic(s) narratif(s)'),
        findsOneWidget,
      );
      expect(_textInStructureEditorial('validation', 'À jour'), findsOneWidget);
      expect(_textInStructureEditorial('review', '0'), findsOneWidget);
      expect(_textInStructureEditorial('blocking', '0'), findsOneWidget);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace structure inspector maps warnings to review state',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
        narrativeValidationReport: NarrativeValidationReport(
          diagnostics: <NarrativeValidationDiagnostic>[
            _diagnostic(NarrativeValidationSeverity.warning),
          ],
        ),
      );

      await _pumpOverview(tester, readModel, width: 1440, height: 980);

      expect(_textInStructureInspector('À revoir'), findsWidgets);
      expect(
          _textInStructureEditorial('validation', 'À revoir'), findsOneWidget);
      expect(_textInStructureEditorial('review', '1'), findsOneWidget);
      expect(_textInStructureEditorial('blocking', '0'), findsOneWidget);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace structure inspector maps errors to blocking state',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
        narrativeValidationReport: NarrativeValidationReport(
          diagnostics: <NarrativeValidationDiagnostic>[
            _diagnostic(NarrativeValidationSeverity.error),
          ],
        ),
      );

      await _pumpOverview(tester, readModel, width: 1440, height: 980);

      expect(_textInStructureInspector('Bloquant'), findsWidgets);
      expect(
          _textInStructureEditorial('validation', 'Bloquant'), findsOneWidget);
      expect(_textInStructureEditorial('review', '0'), findsOneWidget);
      expect(_textInStructureEditorial('blocking', '1'), findsOneWidget);
      expect(_textInStructureInspector('À jour'), findsNothing);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace keeps the structure inspector beside the main column on large desktop',
    (tester) async {
      final readModel = _storyOverviewReadModel();

      await _pumpOverview(tester, readModel, width: 1600, height: 1400);

      final mainColumn = find.byKey(
        const ValueKey('narrative-overview-main-column'),
      );
      final structureColumn = find.byKey(
        const ValueKey('narrative-overview-structure-column'),
      );

      expect(mainColumn, findsOneWidget);
      expect(structureColumn, findsOneWidget);

      final mainRect = tester.getRect(mainColumn);
      final structureRect = tester.getRect(structureColumn);

      expect(structureRect.left, greaterThan(mainRect.right));
      expect((structureRect.top - mainRect.top).abs(), lessThanOrEqualTo(1));
      expect(find.text('Indicateurs auteur'), findsOneWidget);
      expect(find.text('Histoire principale'), findsOneWidget);
      expect(find.text('Modules narratifs'), findsOneWidget);
      expect(find.text('Données à venir'), findsOneWidget);
      expect(find.text('STRUCTURE NARRATIVE'), findsOneWidget);
      expect(find.byKey(const ValueKey('narrative-overview-footer')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace stacks the structure inspector after the main column on medium desktop',
    (tester) async {
      final readModel = _storyOverviewReadModel();

      await _pumpOverview(tester, readModel, width: 1180, height: 1900);

      final mainColumn = find.byKey(
        const ValueKey('narrative-overview-main-column'),
      );
      final structureColumn = find.byKey(
        const ValueKey('narrative-overview-structure-column'),
      );

      expect(mainColumn, findsOneWidget);
      expect(structureColumn, findsOneWidget);

      final mainRect = tester.getRect(mainColumn);
      final structureRect = tester.getRect(structureColumn);

      expect(structureRect.top, greaterThan(mainRect.bottom));
      expect(structureRect.left, closeTo(mainRect.left, 1));
      expect(find.text('Indicateurs auteur'), findsOneWidget);
      expect(find.text('Histoire principale'), findsOneWidget);
      expect(find.text('Modules narratifs'), findsOneWidget);
      expect(find.text('Données à venir'), findsOneWidget);
      expect(find.text('STRUCTURE NARRATIVE'), findsOneWidget);
      expect(find.byKey(const ValueKey('narrative-overview-footer')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace keeps V0 unavailable data honest after responsive polish',
    (tester) async {
      final readModel = _storyOverviewReadModel();

      await _pumpOverview(tester, readModel, width: 1600, height: 1400);

      expect(_textInEmptyState('facts', 'Nécessite un modèle'), findsOneWidget);
      expect(
        _textInEmptyState('recent_activity', 'Hors scope V0'),
        findsOneWidget,
      );
      expect(
        _textInEmptyState('notifications', 'Hors scope V0'),
        findsOneWidget,
      );
      expect(find.text('FR'), findsNothing);
      expect(find.text('v0.3.0'), findsNothing);
      expect(find.textContaining('Selbrume'), findsNothing);
      expect(find.text('42'), findsNothing);
      expect(find.text('1 236'), findsNothing);
      expect(find.text('1236'), findsNothing);
      expect(find.text('24'), findsNothing);
      expect(find.text('12'), findsNothing);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace captures KPI cards screenshot when requested',
    (tester) async {
      if (!const bool.fromEnvironment('NS_HOME_04_CAPTURE_SCREENSHOT')) {
        return;
      }

      await _loadScreenshotFont();
      tester.view.physicalSize = const Size(1180, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: ColoredBox(
                key: const ValueKey('ns-home-04-screenshot-root'),
                color: const Color(0xFF07111F),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: _screenshotFontFamily),
                  child: Center(
                    child: SizedBox(
                      width: 1180,
                      height: 760,
                      child: NarrativeOverviewWorkspace(readModel: readModel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        'ns_home_04_overview_kpi_cards.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('ns-home-04-screenshot-root')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace captures main story card screenshot when requested',
    (tester) async {
      if (!const bool.fromEnvironment('NS_HOME_05_CAPTURE_SCREENSHOT')) {
        return;
      }

      await _loadScreenshotFont();
      tester.view.physicalSize = const Size(1180, 980);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          scenarios: <ScenarioAsset>[
            _globalStoryWithDocuments(),
            _cutsceneScenario(
              id: 'test_cutscene_1',
              dialogueId: 'test_dialogue_1',
            ),
          ],
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: ColoredBox(
                key: const ValueKey('ns-home-05-screenshot-root'),
                color: const Color(0xFF07111F),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: _screenshotFontFamily),
                  child: Center(
                    child: SizedBox(
                      width: 1180,
                      height: 980,
                      child: NarrativeOverviewWorkspace(readModel: readModel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        'ns_home_05_overview_main_story_card.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('ns-home-05-screenshot-root')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace captures module cards grid screenshot when requested',
    (tester) async {
      if (!const bool.fromEnvironment('NS_HOME_06_CAPTURE_SCREENSHOT')) {
        return;
      }

      await _loadScreenshotFont();
      tester.view.physicalSize = const Size(1180, 1220);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          scenarios: <ScenarioAsset>[
            _globalStoryWithDocuments(),
            _cutsceneScenario(
              id: 'test_cutscene_1',
              dialogueId: 'test_dialogue_1',
            ),
          ],
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: ColoredBox(
                key: const ValueKey('ns-home-06-screenshot-root'),
                color: const Color(0xFF07111F),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: _screenshotFontFamily),
                  child: Center(
                    child: SizedBox(
                      width: 1180,
                      height: 1220,
                      child: NarrativeOverviewWorkspace(readModel: readModel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        'ns_home_06_overview_module_cards_grid.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('ns-home-06-screenshot-root')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace captures structure inspector screenshot when requested',
    (tester) async {
      if (!const bool.fromEnvironment('NS_HOME_07_CAPTURE_SCREENSHOT')) {
        return;
      }

      await _loadScreenshotFont();
      tester.view.physicalSize = const Size(1440, 980);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          scenarios: <ScenarioAsset>[
            _globalStoryWithDocuments(),
            _cutsceneScenario(
              id: 'test_cutscene_1',
              dialogueId: 'test_dialogue_1',
            ),
          ],
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: ColoredBox(
                key: const ValueKey('ns-home-07-screenshot-root'),
                color: const Color(0xFF07111F),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: _screenshotFontFamily),
                  child: Center(
                    child: SizedBox(
                      width: 1440,
                      height: 980,
                      child: NarrativeOverviewWorkspace(readModel: readModel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        'ns_home_07_overview_structure_inspector.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('ns-home-07-screenshot-root')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace captures empty states and footer screenshot when requested',
    (tester) async {
      if (!const bool.fromEnvironment('NS_HOME_08_CAPTURE_SCREENSHOT')) {
        return;
      }

      await _loadScreenshotFont();
      tester.view.physicalSize = const Size(1600, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          scenarios: <ScenarioAsset>[
            _globalStoryWithDocuments(),
            _cutsceneScenario(
              id: 'test_cutscene_1',
              dialogueId: 'test_dialogue_1',
            ),
          ],
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: ColoredBox(
                key: const ValueKey('ns-home-08-screenshot-root'),
                color: const Color(0xFF07111F),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: _screenshotFontFamily),
                  child: Center(
                    child: SizedBox(
                      width: 1600,
                      height: 1800,
                      child: NarrativeOverviewWorkspace(readModel: readModel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        'ns_home_08_overview_empty_states_footer.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('ns-home-08-screenshot-root')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace captures responsive polish desktop screenshot when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
          'NS_HOME_09_CAPTURE_DESKTOP_SCREENSHOT')) {
        return;
      }

      await _loadScreenshotFont();
      tester.view.physicalSize = const Size(1600, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final readModel = _storyOverviewReadModel();

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: ColoredBox(
                key: const ValueKey('ns-home-09-desktop-screenshot-root'),
                color: const Color(0xFF07111F),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: _screenshotFontFamily),
                  child: Center(
                    child: SizedBox(
                      width: 1600,
                      height: 1800,
                      child: NarrativeOverviewWorkspace(readModel: readModel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        'ns_home_09_overview_responsive_polish_desktop.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('ns-home-09-desktop-screenshot-root')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace captures responsive polish medium screenshot when requested',
    (tester) async {
      if (!const bool.fromEnvironment('NS_HOME_09_CAPTURE_MEDIUM_SCREENSHOT')) {
        return;
      }

      await _loadScreenshotFont();
      tester.view.physicalSize = const Size(1180, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final readModel = _storyOverviewReadModel();

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: ColoredBox(
                key: const ValueKey('ns-home-09-medium-screenshot-root'),
                color: const Color(0xFF07111F),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: _screenshotFontFamily),
                  child: Center(
                    child: SizedBox(
                      width: 1180,
                      height: 2400,
                      child: NarrativeOverviewWorkspace(readModel: readModel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        'ns_home_09_overview_responsive_polish_medium.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('ns-home-09-medium-screenshot-root')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );
}

const _screenshotFontFamily = 'NsHome04ScreenshotFont';

Future<void> _loadScreenshotFont() async {
  final fontBytes =
      File('/System/Library/Fonts/Supplemental/Arial.ttf').readAsBytesSync();
  final loader = FontLoader(_screenshotFontFamily)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(fontBytes)));
  await loader.load();
}

Finder _textInKpi(String metricId, String text) {
  return find.descendant(
    of: find.byKey(ValueKey('narrative-overview-kpi-$metricId')),
    matching: find.text(text),
  );
}

Finder _textInMainStory(String text) {
  return find.descendant(
    of: find.byKey(const ValueKey('narrative-overview-main-story-card')),
    matching: find.text(text),
  );
}

Finder _textInModule(String moduleId, String text) {
  return find.descendant(
    of: find.byKey(ValueKey('narrative-overview-module-$moduleId')),
    matching: find.text(text),
  );
}

Finder _textInStructureInspector(String text) {
  return find.descendant(
    of: find.byKey(
      const ValueKey('narrative-overview-structure-inspector'),
    ),
    matching: find.text(text),
  );
}

Finder _textInStructureCounter(String metricId, String text) {
  return find.descendant(
    of: find.byKey(ValueKey('narrative-overview-structure-counter-$metricId')),
    matching: find.text(text),
  );
}

Finder _textInStructureEditorial(String slot, String text) {
  return find.descendant(
    of: find.byKey(ValueKey('narrative-overview-structure-editorial-$slot')),
    matching: find.text(text),
  );
}

Finder _textInEmptyState(String slot, String text) {
  return find.descendant(
    of: find.byKey(ValueKey('narrative-overview-empty-state-$slot')),
    matching: find.text(text),
  );
}

Finder _textInFooter(String slot, String text) {
  return find.descendant(
    of: find.byKey(ValueKey('narrative-overview-footer-$slot')),
    matching: find.text(text),
  );
}

NarrativeValidationDiagnostic _diagnostic(
  NarrativeValidationSeverity severity,
) {
  return NarrativeValidationDiagnostic(
    severity: severity,
    kind: NarrativeValidationDiagnosticKind.scenarioGraphHasNoSource,
    message: 'Test diagnostic',
    path: 'scenarios/test_global_story',
    scenarioId: 'test_global_story',
  );
}

NarrativeOverviewReadModel _storyOverviewReadModel() {
  return buildNarrativeOverviewReadModel(
    project: _minimalProject(
      'test_project',
      scenarios: <ScenarioAsset>[
        _globalStoryWithDocuments(),
        _cutsceneScenario(
          id: 'test_cutscene_1',
          dialogueId: 'test_dialogue_1',
        ),
      ],
      dialogues: const <ProjectDialogueEntry>[
        ProjectDialogueEntry(
          id: 'test_dialogue_1',
          name: 'Test Dialogue',
          relativePath: 'dialogues/test_dialogue_1.yarn',
        ),
      ],
    ),
  );
}

Future<void> _pumpOverview(
  WidgetTester tester,
  NarrativeOverviewReadModel readModel, {
  double width = 900,
  double height = 1220,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  return tester.pumpWidget(
    MacosTheme(
      data: MacosThemeData.light(),
      child: CupertinoApp(
        home: CupertinoPageScaffold(
          child: SizedBox(
            width: width,
            height: height,
            child: NarrativeOverviewWorkspace(readModel: readModel),
          ),
        ),
      ),
    ),
  );
}

ProjectManifest _minimalProject(
  String name, {
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
}) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: name,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: scenarios,
    dialogues: dialogues,
  );
}

ScenarioAsset _globalStoryWithDocuments({
  String name = 'Test Main Story',
  String description = 'A generic authoring synopsis.',
}) {
  const stepDocument = StepStudioDocument(
    globalStoryScenarioId: 'test_global_story',
    steps: <StepStudioStep>[
      StepStudioStep(
        id: 'test_step_1',
        name: 'Step One',
        description: 'First test step.',
        order: 0,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.atGameStart,
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.whenCutsceneEnds,
          cutsceneId: 'test_cutscene_1',
        ),
        cutscenes: <StepStudioCutsceneLink>[
          StepStudioCutsceneLink(
            cutsceneId: 'test_cutscene_1',
            role: StepStudioCutsceneRole.main,
          ),
        ],
        worldChanges: <StepStudioWorldChange>[
          StepStudioWorldChange(
            mapId: 'test_map',
            entityId: 'test_entity',
            presenceRule: StepStudioPresenceRule.visibleAfterStepCompletion,
          ),
        ],
      ),
      StepStudioStep(
        id: 'test_step_2',
        name: 'Step Two',
        description: 'Second test step.',
        order: 1,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.afterStep,
          stepId: 'test_step_1',
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
      ),
    ],
  );

  const globalStoryDocument = GlobalStoryStudioDocument(
    globalStoryScenarioId: 'test_global_story',
    entryStepId: 'test_step_1',
    nodes: <GlobalStoryStepNode>[
      GlobalStoryStepNode(
        stepId: 'test_step_1',
        links: <GlobalStoryStepLink>[
          GlobalStoryStepLink(toStepId: 'test_step_2'),
        ],
      ),
      GlobalStoryStepNode(stepId: 'test_step_2'),
    ],
    chapters: <GlobalStoryChapter>[
      GlobalStoryChapter(
        id: 'test_chapter_1',
        name: 'Test Chapter One',
        description: 'First test chapter.',
        stepIds: <String>['test_step_1'],
        order: 0,
      ),
      GlobalStoryChapter(
        id: 'test_chapter_2',
        name: 'Test Chapter Two',
        description: 'Second test chapter.',
        stepIds: <String>['test_step_2'],
        order: 1,
      ),
    ],
  );

  return ScenarioAsset(
    id: 'test_global_story',
    name: name,
    description: description,
    scope: ScenarioScope.globalStory,
    entryNodeId: 'start',
    metadata: <String, String>{
      kStepStudioSchemaMetadataKey: kStepStudioSchemaVersion,
      kStepStudioDocumentMetadataKey: stepDocument.toMetadataJson(),
      kGlobalStoryStudioSchemaMetadataKey: kGlobalStoryStudioSchemaVersion,
      kGlobalStoryStudioDocumentMetadataKey:
          globalStoryDocument.toMetadataJson(),
    },
  );
}

ScenarioAsset _cutsceneScenario({
  required String id,
  String? dialogueId,
}) {
  return ScenarioAsset(
    id: id,
    name: 'Test Cutscene',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'start',
    metadata: const <String, String>{
      kCutsceneStudioSchemaMetadataKey: kCutsceneStudioSchemaVersion,
    },
    nodes: <ScenarioNode>[
      if (dialogueId != null)
        ScenarioNode(
          id: 'open_dialogue',
          payload: const ScenarioNodePayload(actionKind: 'openDialogue'),
          binding: ScenarioNodeBinding(dialogueId: dialogueId),
        ),
    ],
  );
}
