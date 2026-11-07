import 'package:avelune_studio/features/project_cs/application/project_cs_controller.dart';
import 'package:avelune_studio/features/project_cs/domain/project_cs_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_surf/application/project_surf_controller.dart';
import 'package:avelune_studio/features/project_surf/domain/project_surf_port.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_cs_panel.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

final _badge = ScriptConditionFactory.badgeOwned('zephyr');

void main() {
  late _Port port;
  late ProjectCsController abilities;
  late ProjectSurfController surf;

  setUp(() {
    port = _Port();
    abilities = ProjectCsController(session: workspaceSession, port: port);
    surf = ProjectSurfController(
      session: workspaceSession,
      port: port,
      dimension: ProjectDimension.threeD,
    );
  });

  tearDown(() {
    abilities.dispose();
    surf.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectCsPanel(
              owner: abilities,
              surf: surf,
              settings: ProjectSettings(dimension: ProjectDimension.threeD),
              showActions: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'the eleven abilities show their real support and activation-only ones stay so',
    (tester) async {
      await pump(tester);
      for (final entry in ProjectFieldAbilityRegistry.entries) {
        expect(find.byKey(ValueKey('cs-${entry.id}')), findsOneWidget);
        expect(find.byKey(ValueKey('cs-support-${entry.id}')), findsOneWidget);
      }
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('cs-support-rock_climb')))
            .data,
        'Activation seule',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('cs-support-defog')))
            .data,
        'Activation seule',
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('cs-support-surf'))).data,
        'Mécanique disponible',
      );
      expect(FieldAbility.values, hasLength(9));
    },
  );

  testWidgets(
    'enabling Surf keeps unlocking a separate progression condition',
    (tester) async {
      port.surf = ProjectSurfSettings(
        enabled: false,
        accessMode: ProjectSurfAccessMode.condition,
        condition: _badge,
      );
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('cs-surf')));
      await tester.pumpAndSettle();
      expect(surf.preview.value.enabled, isTrue);
      expect(surf.preview.value.accessMode, ProjectSurfAccessMode.condition);
      expect(surf.preview.value.condition, isNotNull);
      final summary = find.byKey(const ValueKey('cs-summary-surf'));
      expect(summary, findsOneWidget);
      expect(find.textContaining('Autorisée dans ce jeu'), findsOneWidget);
      expect(
        find.textContaining('Débloquée pour le joueur : selon une condition'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Pokémon de l’équipe doit connaître Surf'),
        findsOneWidget,
      );
    },
  );

  test(
    'disabling an ability keeps its settings and progression references',
    () async {
      port.surf = ProjectSurfSettings(
        accessMode: ProjectSurfAccessMode.condition,
        condition: _badge,
        speedCellsPerSecond: 6,
      );
      await surf.open();
      surf.change(enabled: false);
      expect(await surf.save(), isTrue);
      expect(port.surf!.enabled, isFalse);
      expect(port.surf!.speedCellsPerSecond, 6);
      expect(port.surf!.accessMode, ProjectSurfAccessMode.condition);
      expect(port.surf!.condition, isNotNull);
    },
  );

  test('Surf speed accepts a comma and has no artificial maximum', () async {
    await surf.open();
    surf.editSpeed('1,5');
    expect(surf.speedInputError, isNull);
    expect(surf.preview.value.speedCellsPerSecond, 1.5);
    surf.editSpeed('45');
    expect(surf.speedInputError, isNull);
    expect(surf.preview.value.speedCellsPerSecond, 45);
    surf.editSpeed('0');
    expect(surf.speedInputError, isNotNull);
    expect(surf.preview.value.speedCellsPerSecond, 45);
  });
}

final class _Port implements ProjectCsPort, ProjectSurfPort {
  ProjectFieldAbilitiesSettings? cs;
  ProjectSurfSettings? surf = const ProjectSurfSettings();
  int writes = 0;

  @override
  Future<ProjectCsState> loadFieldAbilities(ProjectSession session) async =>
      ProjectCsState(configuration: cs, revision: '$writes');

  @override
  Future<ProjectCsState> saveFieldAbility(
    ProjectSession session,
    FieldAbility ability,
    bool enabled,
    String expectedRevision,
  ) => saveFieldAbilityId(session, ability.name, enabled, expectedRevision);

  @override
  Future<ProjectCsState> saveFieldAbilityId(
    ProjectSession session,
    String abilityId,
    bool enabled,
    String expectedRevision,
  ) async {
    writes++;
    final disabled = {...?cs?.disabledAbilityIds};
    enabled ? disabled.remove(abilityId) : disabled.add(abilityId);
    cs = ProjectFieldAbilitiesSettings.fromIds(disabled);
    return ProjectCsState(configuration: cs, revision: '$writes');
  }

  @override
  Future<ProjectSurfState> loadSurf(ProjectSession session) async =>
      ProjectSurfState(configuration: surf, revision: '$writes');

  @override
  Future<ProjectSurfState> saveSurf(
    ProjectSession session,
    ProjectSurfSettings? configuration,
    String expectedRevision,
  ) async {
    if (expectedRevision != '$writes') throw StateError('stale');
    writes++;
    surf = configuration;
    return ProjectSurfState(configuration: surf, revision: '$writes');
  }

  @override
  Future<ProjectSurfReferences> loadSurfReferences(
    ProjectSession session,
  ) async => const ProjectSurfReferences(badges: {'zephyr': 'Badge Zéphyr'});

  @override
  Future<NarrativeFactDefinition> loadSurfFact(
    ProjectSession session,
    String id,
  ) => throw UnimplementedError();
}
