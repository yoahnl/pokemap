import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/new_game/contact_device_configuration_sheet.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'contact device form uses labelled fact and conversation pickers',
    (tester) async {
      ProjectContactDeviceConfig? saved;
      final project = ProjectManifest(
        name: 'Travel',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        maps: [],
        tilesets: [],
        facts: [
          for (final id in ['owned', 'known'])
            NarrativeFactDefinition(id: id, label: 'Variable $id'),
        ],
        scenes: [
          for (final id in ['call', 'busy'])
            SceneAsset(
              id: id,
              name: 'Conversation $id',
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: [
                  SceneNode(id: 'start', kind: SceneNodeKind.start),
                  SceneNode(id: 'end', kind: SceneNodeKind.end),
                ],
                edges: [
                  SceneEdge(
                    id: 'e',
                    fromNodeId: 'start',
                    fromPortId: 'completed',
                    toNodeId: 'end',
                    kind: SceneEdgeKind.defaultFlow,
                  ),
                ],
              ),
            ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: ContactDeviceConfigurationForm(
              project: project,
              onSave: (config) async {
                saved = config;
                return true;
              },
            ),
          ),
        ),
      );
      tester
          .widget<PokeMapToggleTile>(
            find.byKey(const Key('contact-device-enabled')),
          )
          .onChanged(true);
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('contact-device-label')),
        'Carnet',
      );
      tester
          .widget<PokeMapDropdownField<String>>(
            find.byKey(const Key('contact-device-acquired')),
          )
          .onChanged('owned');
      await tester.tap(find.byKey(const Key('contact-device-add')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('contact-label-0')),
        'Mentor',
      );
      for (final entry in {
        'contact-registered-0': 'known',
        'contact-scene-0': 'call',
        'contact-unavailable-0': 'busy',
      }.entries) {
        tester
            .widget<PokeMapDropdownField<String>>(find.byKey(Key(entry.key)))
            .onChanged(entry.value);
      }
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const Key('contact-device-save')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('contact-device-save')));
      await tester.pumpAndSettle();
      expect(saved!.label, 'Carnet');
      expect(saved!.acquiredFactId, 'owned');
      expect(saved!.contacts.single.label, 'Mentor');
      expect(saved!.contacts.single.registeredFactId, 'known');
      expect(saved!.contacts.single.sceneId, 'call');
      expect(saved!.contacts.single.unavailableSceneId, 'busy');
      expect(tester.takeException(), isNull);
    },
  );
}
