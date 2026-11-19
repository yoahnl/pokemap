import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  const validator = GamePackageContentValidator(GamePackageSecurityPolicy());
  for (final catalogObject in [false, true]) {
    final path = catalogObject
        ? 'project/catalog/objects/${'a' * 64}.json'
        : 'project/project.json';

    void validate({
      String text = 'Guide: Bonjour !',
      String relativePath = 'dialogues/guide.yarn',
      String? adjacentSource,
    }) {
      final localization = DialogueLocalization(
        sourceLocale: 'fr',
        units: [
          DialogueTextUnit(
            id: 'line_guide',
            binding: '/Start/0',
            kind: DialogueTextKind.line,
            source: text,
            translations: {
              'en': DialogueTranslation(text: 'Guide: Hello!', source: text),
            },
          ),
        ],
      );
      final dialogue = {
        'id': 'guide',
        'name': 'Guide',
        'relativePath': relativePath,
        'localization': localization.toJson(),
        if (adjacentSource != null) 'source': adjacentSource,
      };
      final root = catalogObject
          ? {
              'type': 'unit',
              'key': {
                'id': '["projectDefinition","dialogues",0]',
                'kind': 'catalogMetadata',
              },
              'payload': {
                'section': r'$projectDefinition',
                'value': {'field': 'dialogues', 'definition': dialogue},
              },
            }
          : {
              'dialogues': [dialogue]
            };
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(root)));
      validator.validate(
        GamePackageFileEntry(
          path: path,
          size: bytes.length,
          sha256: '0' * 64,
          mediaType: 'application/json',
        ),
        bytes,
      );
    }

    Matcher rejected(String code) => throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', code),
        );

    group(path, () {
      test('allows a speaker in the source and translation snapshot', () {
        expect(validate, returnsNormally);
      });
      test('checks the actual dialogue reference', () {
        expect(
          () => validate(relativePath: '../other/guide.yarn'),
          rejected('referenceEscapesRoot'),
        );
      });
      test('checks a neighboring source field', () {
        expect(
          () => validate(adjacentSource: '../other/guide.yarn'),
          rejected('referenceEscapesRoot'),
        );
      });
      test('still scans localized text for credential markers', () {
        expect(
          () => validate(text: 'Guide: -----BEGIN PRIVATE KEY-----'),
          rejected('probableSecret'),
        );
      });
    });
  }
}
