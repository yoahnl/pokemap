import 'dart:convert';

import 'package:map_authoring/map_authoring_documents.dart'
    show decodeValidatedMapDocument;
import 'package:map_authoring/map_authoring_local.dart'
    show LocalProjectFileReader;
import 'package:map_core/map_core.dart';

import '../domain/verification_port.dart';

MapData verificationMap(ProjectManifest project, VerificationMapSource source) {
  try {
    final map = decodeValidatedMapDocument(
      source.bytes,
      source.entry.relativePath,
      validateMap: (map) =>
          MapValidator.validate(map, projectDialogueContext: project),
    );
    if (map.id != source.entry.id) throw const FormatException();
    return map;
  } on Object catch (failure) {
    throw VerificationFailure(
      'Carte illisible (${source.entry.relativePath}) : $failure',
    );
  }
}

Future<ProjectItemCatalog?> verificationItemCatalog(
  ProjectManifest project,
  List<MapData> maps,
  String projectRoot,
) async {
  final path = project.pokemon.catalogFiles['items']?.trim();
  if (path == null || path.isEmpty) return null;
  final required = buildNarrativeDependencyIndex(project: project, maps: maps)
      .usages
      .any((usage) => usage.target.kind == NarrativeDependencyTargetKind.item);
  if (!required) return null;
  try {
    final bytes = await const LocalProjectFileReader().readBytes(
      projectRoot: projectRoot,
      relativePath: path,
    );
    final catalog = decodeProjectItemCatalog(jsonDecode(utf8.decode(bytes)));
    final blocking = validateProjectItemCatalog(
      catalog,
      capabilityTruth: itemSystemV1CapabilityTruth,
    ).diagnostics.where((diagnostic) => diagnostic.isBlocking).firstOrNull;
    if (blocking != null) {
      throw FormatException('${blocking.path} : ${blocking.message}');
    }
    return catalog;
  } on Object catch (failure) {
    throw VerificationFailure(
      'Catalogue des objets illisible ($path) : $failure',
    );
  }
}
