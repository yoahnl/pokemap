import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'native_project_writer.dart';

bool matchesRegeneratedSourceEventAtlasImport({
  required NativeMutation mutation,
  required NativeArtifact? artifact,
  required NativeProjectDraft? regeneratedEvents,
  ContractLimits jsonLimits = const ContractLimits(),
}) {
  if (regeneratedEvents == null ||
      artifact == null ||
      mutation.actionId != 'tileset.import_image' ||
      artifact.reference.mediaType != 'image/png' ||
      artifact.handle != mutation.parameters['artifactHandle'] ||
      !const {(512, 384), (64, 48)}.contains((
        mutation.parameters['tileWidth'],
        mutation.parameters['tileHeight']
      ))) {
    return false;
  }
  final expected = regeneratedEvents.mutations
      .where((entry) => entry.operationId == mutation.operationId)
      .toList();
  if (expected.length != 1 ||
      canonicalJsonOf(expected.single.toJson(0), limits: jsonLimits) !=
          canonicalJsonOf(mutation.toJson(0), limits: jsonLimits)) {
    return false;
  }
  final originals = regeneratedEvents.artifacts
      .where((entry) => entry.handle == artifact.handle)
      .toList();
  if (originals.length != 1 ||
      originals.single.reference.mediaType != 'image/png' ||
      originals.single.rawSha256 != artifact.rawSha256 ||
      originals.single.bytes.length != artifact.bytes.length) {
    return false;
  }
  for (var index = 0; index < artifact.bytes.length; index++) {
    if (originals.single.bytes[index] != artifact.bytes[index]) {
      return false;
    }
  }
  return true;
}
