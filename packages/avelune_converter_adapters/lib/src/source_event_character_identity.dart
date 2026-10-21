import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

bool sourceEventUsesFixedDirectionPresentation(SourceEventDefinition event) =>
    event.pages.any((page) => page.graphic?.directionFix == true) &&
    event.pages.every((page) =>
        page.triggerCode == 0 &&
        page.sourcePage.commands.every((command) =>
            const {
              0,
              101,
              401,
              102,
              402,
              403,
              404,
              108,
              408,
              111,
              411,
              412,
              115,
              121,
              122,
              123,
            }.contains(command.code) ||
            (page.graphic?.directionFix == false &&
                const {209, 509, 210}.contains(command.code))));

String sourceFixedDirectionCharacterId({
  required SourceSnapshot snapshot,
  required SourceFileEntry imageFile,
  required int pattern,
  required int direction,
}) =>
    'source-event-${canonicalHashOf({
          'kind': 'sourceEventCharacter',
          'version': 1,
          'namespace': snapshot.logicalProjectNamespace.value,
          'sourceFileId': imageFile.fileId.value,
          'sourcePath': imageFile.relativePath,
          'sourceFileHash': imageFile.sha256!.value,
          'sourcePattern': pattern,
          'fixedSourceDirection': direction,
        }).value.substring(0, 32)}';

GridSize? sourcePassiveFixedFootprint(SourceEventDefinition event) {
  if (event.pages.isEmpty ||
      !sourceEventUsesFixedDirectionPresentation(event) ||
      event.pages.any((page) =>
          page.triggerCode != 0 ||
          !page.isEmpty ||
          page.graphic?.moveType != 0 ||
          page.graphic?.stepAnime != false ||
          (page.graphic!.characterName.isNotEmpty &&
              !page.graphic!.directionFix))) {
    return null;
  }
  final matches = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false)
      .allMatches(event.name)
      .toList();
  if (matches.length != 1) return null;
  final width = int.tryParse(matches.single.group(1)!);
  final height = int.tryParse(matches.single.group(2)!);
  if (width == null ||
      height == null ||
      width < 1 ||
      height < 1 ||
      width > 5 ||
      height > 5 ||
      width * height == 1) {
    return null;
  }
  return GridSize(width: width, height: height);
}
