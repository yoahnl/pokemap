import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_player_ui/personalization_preview.dart';
import 'package:path/path.dart' as p;

void main() {
  test('certifies every persisted V10 field group end to end', () {
    const expectedFieldGroups = <String>{
      '/presentation/branding',
      '/presentation/title',
      '/presentation/intro',
      '/presentation/titleMotion',
      '/presentation/typography',
      '/presentation/theme',
      '/presentation/surfacePalettes',
      '/presentation/pause',
      '/presentation/dialogue',
      '/presentation/battle',
      '/presentation/menuLabels',
      '/presentation/windows',
      '/presentation/layouts/title',
      '/presentation/layouts/pauseMenu',
      '/presentation/layouts/dialogue',
      '/presentation/layouts/battle',
    };

    expect(projectPresentationV10AuthorableFieldGroups, expectedFieldGroups);
    expect(personalizationV10FieldConsumptionMatrix.schemaVersion, 10);
    expect(
      personalizationV10FieldConsumptionMatrix.excludedFieldReasons.keys,
      const <String>{'/presentation/schemaVersion'},
    );
    final productionWidgetNames = PlayerPersonalizationPreviewContract
        .productionWidgetTypes
        .values
        .expand((types) => types)
        .map((type) => type.toString())
        .toSet();
    for (final entry in personalizationV10FieldConsumptionMatrix.entries) {
      final capability = personalizationCapabilityRegistry.require(
        entry.capabilityId,
      );
      expect(capability.effect, PersonalizationControlEffect.project);
      expect(capability.testKeys, contains(entry.editorControlKey));
      for (final fieldGroup in entry.fieldGroups) {
        expect(
          capability.projectPaths.any(
            (path) => fieldGroup == path || fieldGroup.startsWith('$path/'),
          ),
          isTrue,
          reason: '${entry.capabilityId} must claim $fieldGroup',
        );
      }
      expect(productionWidgetNames, contains(entry.previewWidget));
      expect(entry.runtimeConsumer, isNotEmpty);
      expect(entry.exportConsumer, 'GamePackageBuilder');
      expect(entry.mcpAction, 'presentation.update');
    }
  });

  test('fails closed when a V10 field group has no end-to-end evidence', () {
    expect(
      () => personalizationV10FieldConsumptionMatrix.requireCompleteFor(
        const <String>{'/presentation/futureSurface'},
      ),
      throwsStateError,
    );
  });

  test('fails closed when two controls claim the same concrete field', () {
    final matrix = PersonalizationFieldConsumptionMatrix(
      schemaVersion: 10,
      excludedFieldReasons: const <String, String>{},
      entries: <PersonalizationFieldConsumptionEntry>[
        PersonalizationFieldConsumptionEntry(
          fieldGroups: const <String>{'/presentation/dialogue'},
          capabilityId: 'dialogue.geometry',
          editorControlKey: 'geometry',
          previewWidget: 'PlayerDialogueSurface',
          runtimeConsumer: 'PlayerDialogueSurface',
        ),
        PersonalizationFieldConsumptionEntry(
          fieldGroups: const <String>{'/presentation/dialogue/textColor'},
          capabilityId: 'dialogue.colors',
          editorControlKey: 'colors',
          previewWidget: 'PlayerDialogueSurface',
          runtimeConsumer: 'PlayerDialogueSurface',
        ),
      ],
    );

    expect(
      () => matrix.requireCompleteFor(const <String>{
        '/presentation/dialogue/textColor',
      }),
      throwsStateError,
    );
  });

  test('covers every concrete field in the V10 acceptance project', () {
    final projectFile = File(
      p.join(
        Directory.current.parent.parent.path,
        'examples',
        'playable_runtime_host',
        'golden_personalization_v3',
        'project.json',
      ),
    );
    final project = jsonDecode(projectFile.readAsStringSync());
    final presentation = (project as Map<String, dynamic>)['presentation'];
    final fieldPaths = _leafPaths(presentation, path: '/presentation');

    expect(fieldPaths, hasLength(266));
    expect(
      () => personalizationV10FieldConsumptionMatrix.requireCompleteFor(
        fieldPaths,
      ),
      returnsNormally,
    );
  });
}

Set<String> _leafPaths(Object? value, {required String path}) {
  if (value is Map<String, dynamic>) {
    return <String>{
      for (final entry in value.entries)
        ..._leafPaths(entry.value, path: '$path/${entry.key}'),
    };
  }
  if (value is List<Object?>) {
    return <String>{
      for (final item in value) ..._leafPaths(item, path: '$path/*'),
    };
  }
  return <String>{path};
}
