import 'package:avelune_converter_core/avelune_converter_core.dart';

bool sourceEventUsesFixedDirectionPresentation(SourceEventDefinition event) =>
    event.pages.any((page) => page.graphic?.directionFix == true) &&
    event.pages.every((page) => page.triggerCode == 0 &&
        page.sourcePage.commands.every((command) => const {
          0, 101, 401, 102, 402, 403, 404, 108, 408, 111, 411, 412, 115, 121, 122, 123,
        }.contains(command.code) || (page.graphic?.directionFix == false &&
            const {209, 509, 210}.contains(command.code))));

String sourceFixedDirectionCharacterId({
  required SourceSnapshot snapshot,
  required SourceFileEntry imageFile,
  required int pattern,
  required int direction,
}) => 'source-event-${canonicalHashOf({
  'kind': 'sourceEventCharacter',
  'version': 1,
  'namespace': snapshot.logicalProjectNamespace.value,
  'sourceFileId': imageFile.fileId.value,
  'sourcePath': imageFile.relativePath,
  'sourceFileHash': imageFile.sha256!.value,
  'sourcePattern': pattern,
  'fixedSourceDirection': direction,
}).value.substring(0, 32)}';
