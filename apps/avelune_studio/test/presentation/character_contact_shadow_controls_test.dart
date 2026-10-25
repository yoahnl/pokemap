import 'package:avelune_studio/presentation/features/characters/character_contact_shadow_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:avelune_studio/presentation/features/characters/character_studio_controller.dart';
import 'package:avelune_studio/presentation/features/characters/character_studio_page.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
    testWidgets(
      'contact shadow settings appear only for 3D characters: ${dimension.name}',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var project = workspaceProject.copyWith(
          settings: ProjectSettings(dimension: dimension),
          characters: [
            const ProjectCharacterEntry(
              id: 'agent',
              name: 'Agent',
              tilesetId: 'atlas',
            ),
          ],
        );
        final calls = <(String, Map<String, Object?>)>[];
        final controller = CharacterStudioController(
          project: () => project,
          mutate: (action, params) async {
            calls.add((action, params));
            if (action == 'project.actor_contact_shadows.configure') {
              project = project.copyWith(
                settings: project.settings.copyWith(
                  actorContactShadowsByDefault: params['enabled'] as bool,
                ),
              );
            } else {
              project = project.copyWith(
                characters: [
                  project.characters.single.copyWith(
                    contactShadow: params['contactShadow'] as bool?,
                  ),
                ],
              );
            }
            return project;
          },
        )..setSection(CharacterStudioSection.identity);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => CharacterStudioPage(
                  project: project,
                  visuals: WorkspaceTestVisuals(),
                  controller: controller,
                  onBack: () {},
                  onImport: () {},
                  port: _UnusedPort(),
                  onImportPortrait: (_) {},
                  onImportAnimation: (_, _) {},
                ),
              ),
            ),
          ),
        );
        final global = find.byKey(
          const ValueKey('project-actor-contact-shadows-default'),
        );
        final individual = find.byKey(
          const ValueKey('character-contact-shadow'),
        );
        if (dimension == ProjectDimension.twoD) {
          expect(global, findsNothing);
          expect(individual, findsNothing);
        } else {
          expect(tester.widget<StudioToggleRow>(global).value, isFalse);
          expect(tester.widget<StudioToggleRow>(individual).value, isFalse);
          await tester.tap(global);
          await tester.pump();
          expect(calls.single.$1, 'project.actor_contact_shadows.configure');
          expect(calls.single.$2, {'enabled': true});
          expect(tester.widget<StudioToggleRow>(individual).value, isTrue);
          await tester.tap(individual);
          await tester.pump();
          expect(calls, hasLength(1));
          expect(controller.dirty, isTrue);
          await tester.tap(find.text('Enregistrer'));
          await tester.pump();
          expect(calls.last.$1, 'characterStudio.character.update');
          expect(calls.last.$2, {
            'characterId': 'agent',
            'contactShadow': false,
          });
          expect(controller.dirty, isFalse);
          await tester.tap(
            find.byKey(const ValueKey('character-contact-shadow-inherit')),
          );
          await tester.pump();
          await tester.tap(find.text('Enregistrer'));
          await tester.pump();
          expect(calls.last.$2, {
            'characterId': 'agent',
            'contactShadow': null,
          });
          expect(tester.widget<StudioToggleRow>(individual).value, isTrue);
          tester.view.physicalSize = const Size(640, 640);
          await tester.pump();
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'character contact shadow inherits, overrides and returns to project',
    (tester) async {
      bool? value;
      var projectDefault = false;
      var busy = false;
      Widget panel() => MaterialApp(
        home: Scaffold(
          body: CharacterContactShadowControls(
            projectDefault: projectDefault,
            value: value,
            busy: busy,
            onChanged: (next) => value = next,
          ),
        ),
      );
      bool enabled() =>
          tester.widget<StudioToggleRow>(find.byType(StudioToggleRow)).value;
      await tester.pumpWidget(panel());
      expect(enabled(), isFalse);
      expect(
        find.textContaining('Suit le projet · désactivée'),
        findsOneWidget,
      );
      projectDefault = true;
      await tester.pumpWidget(panel());
      expect(enabled(), isTrue);
      await tester.tap(find.byKey(const ValueKey('character-contact-shadow')));
      await tester.pumpWidget(panel());
      expect(value, isFalse);
      expect(enabled(), isFalse);
      expect(find.textContaining('Réglage propre'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('character-contact-shadow-inherit')),
      );
      await tester.pumpWidget(panel());
      expect(value, isNull);
      expect(enabled(), isTrue);
      busy = true;
      await tester.pumpWidget(panel());
      expect(
        tester.widget<StudioToggleRow>(find.byType(StudioToggleRow)).onChanged,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _UnusedPort implements ResourcePort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected resource access');
}
