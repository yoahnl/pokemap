import 'dart:io';

import 'package:image/image.dart' as image;
import 'package:path/path.dart' as path;

final List<PersonalizationAcceptanceContactSheet>
personalizationAcceptanceContactSheets =
    <PersonalizationAcceptanceContactSheet>[
      _sheet('editor', 'landscape', _sceneItems),
      _sheet('editor', 'portrait', _sceneItems),
      _sheet('editor', 'variants', _variantItems),
      _sheet('player', 'landscape', _sceneItems),
      _sheet('player', 'portrait', _sceneItems),
      _sheet('player', 'variants', _variantItems),
    ];

const List<(String, String)> _sceneItems = <(String, String)>[
  ('globalStyle', 'Style global'),
  ('title', 'Ecran titre'),
  ('intro', 'Intro'),
  ('pause', 'Menu Pause'),
  ('dialogue', 'Dialogue'),
  ('battle', 'Combat'),
];

const List<(String, String)> _variantItems = <(String, String)>[
  ('dialogueText2x', 'Dialogue - texte 200 %'),
  ('dialogueChoices', 'Dialogue - choix'),
  ('battleCommands', 'Combat - commandes'),
  ('battleMoves', 'Combat - capacites'),
  ('battleTarget', 'Combat - cible'),
  ('battleMessage', 'Combat - message'),
];

final class PersonalizationAcceptanceContactSheet {
  const PersonalizationAcceptanceContactSheet({
    required this.id,
    required this.title,
    required this.items,
  });

  final String id;
  final String title;
  final List<PersonalizationAcceptanceContactSheetItem> items;
}

final class PersonalizationAcceptanceContactSheetItem {
  const PersonalizationAcceptanceContactSheetItem({
    required this.label,
    required this.sourcePath,
  });

  final String label;
  final String sourcePath;
}

PersonalizationAcceptanceContactSheet _sheet(
  String audience,
  String group,
  List<(String, String)> entries,
) {
  final isEditor = audience == 'editor';
  final sourceDirectory = isEditor
      ? 'packages/map_editor/test/personalization/goldens/personalization'
      : 'packages/map_player_ui/test/player/goldens/player_personalization';
  final sourcePrefix = switch ((isEditor, group)) {
    (true, 'landscape') => 'editor_landscape_',
    (true, 'portrait') => 'editor_portrait_',
    (true, 'variants') => 'editor_variant_',
    (false, 'landscape') => 'landscape_',
    (false, 'portrait') => 'portrait_',
    (false, 'variants') => 'variant_',
    _ => throw ArgumentError.value(group, 'group'),
  };
  final audienceLabel = isEditor ? 'Editor' : 'Player';
  final groupLabel = switch (group) {
    'landscape' => 'paysage',
    'portrait' => 'portrait',
    'variants' => 'variantes Dialogue et Combat',
    _ => throw ArgumentError.value(group, 'group'),
  };

  return PersonalizationAcceptanceContactSheet(
    id: '${audience}_$group',
    title: '$audienceLabel - $groupLabel',
    items: entries
        .map(
          (entry) => PersonalizationAcceptanceContactSheetItem(
            label: entry.$2,
            sourcePath: '$sourceDirectory/$sourcePrefix${entry.$1}.png',
          ),
        )
        .toList(growable: false),
  );
}

Directory findPersonalizationRepositoryRoot(Directory start) {
  var current = start.absolute;
  while (true) {
    final marker = File(
      path.join(current.path, 'packages', 'map_editor', 'pubspec.yaml'),
    );
    if (marker.existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('PokeMap repository root not found from ${start.path}');
    }
    current = parent;
  }
}

List<File> buildPersonalizationAcceptanceContactSheets({
  required Directory repositoryRoot,
  required Directory outputDirectory,
}) {
  outputDirectory.createSync(recursive: true);
  return personalizationAcceptanceContactSheets
      .map((sheet) {
        final output = File(path.join(outputDirectory.path, '${sheet.id}.png'));
        output.writeAsBytesSync(
          image.encodePng(_renderSheet(repositoryRoot, sheet)),
        );
        return output;
      })
      .toList(growable: false);
}

image.Image _renderSheet(
  Directory repositoryRoot,
  PersonalizationAcceptanceContactSheet sheet,
) {
  const columns = 2;
  const margin = 24;
  const gap = 16;
  const titleHeight = 56;
  const labelHeight = 38;
  final (previewWidth, previewHeight) = switch (sheet.id) {
    'editor_landscape' || 'editor_variants' => (480, 450),
    'editor_portrait' => (300, 540),
    'player_landscape' || 'player_variants' => (480, 270),
    'player_portrait' => (304, 540),
    _ => throw StateError('Unknown contact sheet ${sheet.id}'),
  };
  final rows = (sheet.items.length / columns).ceil();
  final cellHeight = labelHeight + previewHeight;
  final canvas = image.Image(
    width: margin * 2 + previewWidth * columns + gap * (columns - 1),
    height: margin * 2 + titleHeight + cellHeight * rows + gap * (rows - 1),
    numChannels: 4,
  );
  final background = image.ColorRgb8(7, 17, 31);
  final cellBackground = image.ColorRgb8(15, 31, 51);
  final titleColor = image.ColorRgb8(235, 242, 255);
  final labelColor = image.ColorRgb8(176, 196, 226);
  image.fill(canvas, color: background);
  image.drawString(
    canvas,
    sheet.title,
    font: image.arial24,
    x: margin,
    y: margin,
    color: titleColor,
  );

  for (var index = 0; index < sheet.items.length; index += 1) {
    final item = sheet.items[index];
    final column = index % columns;
    final row = index ~/ columns;
    final x = margin + column * (previewWidth + gap);
    final y = margin + titleHeight + row * (cellHeight + gap);
    final sourceFile = File(path.join(repositoryRoot.path, item.sourcePath));
    final decoded = image.decodePng(sourceFile.readAsBytesSync());
    if (decoded == null) {
      throw StateError('Unable to decode ${sourceFile.path}');
    }
    final preview = image.copyResize(
      decoded,
      width: previewWidth,
      height: previewHeight,
      maintainAspect: true,
      backgroundColor: cellBackground,
      interpolation: image.Interpolation.linear,
    );
    image.drawString(
      canvas,
      item.label,
      font: image.arial24,
      x: x,
      y: y + 4,
      color: labelColor,
    );
    image.compositeImage(canvas, preview, dstX: x, dstY: y + labelHeight);
  }

  return canvas;
}

void main(List<String> arguments) {
  final repositoryRoot = findPersonalizationRepositoryRoot(Directory.current);
  final outputDirectory = arguments.isEmpty
      ? Directory(
          path.join(
            repositoryRoot.path,
            'documentation',
            'reports',
            'roadmap',
            'personalization',
            'assets',
            'personalization-studio-v3',
          ),
        )
      : Directory(path.absolute(arguments.single));
  final outputs = buildPersonalizationAcceptanceContactSheets(
    repositoryRoot: repositoryRoot,
    outputDirectory: outputDirectory,
  );
  for (final output in outputs) {
    stdout.writeln(path.relative(output.path, from: repositoryRoot.path));
  }
}
