import 'dart:convert';

import 'package:map_authoring/map_authoring_documents.dart'
    show decodeValidatedMapDocument;
import 'package:map_authoring/map_authoring_local.dart'
    show
        CatalogTargetedMapSelection,
        LocalProjectFileReader,
        ProjectOpenService,
        WorkspaceHandleStore,
        WorkspacePolicy;
import 'package:map_core/map_core.dart';

import '../domain/verification_port.dart';

const _catalogMapDefinitionFields = {
  'groups',
  'settings',
  'newGame',
  'scenes',
  'eventRegistry',
  'cinematics',
  'trainers',
  'scenarios',
  'pokemon',
};

typedef VerificationMaps = ({
  List<MapData> maps,
  List<ProjectMapEntry> unreadable,
});

Future<VerificationMaps> verificationMaps(
  ProjectManifest project,
  List<VerificationMapSource> sources, {
  required String projectRoot,
  required bool catalog,
}) async {
  if (!catalog) {
    return _readEach(
      sources,
      (source) async => _decoded(
        source,
        (map) => MapValidator.validate(map, projectDialogueContext: project),
      ),
    );
  }
  const reader = LocalProjectFileReader();
  final service = ProjectOpenService(
    policy: await WorkspacePolicy.create(
      allowedRootPaths: [projectRoot],
      fileReader: reader,
    ),
    fileReader: reader,
    handles: WorkspaceHandleStore(),
    catalogMetadataFields: _catalogMapDefinitionFields,
  );
  final opened = await service.openProject(projectRoot);
  try {
    final definitions = await service.catalogProject(opened.projectHandle);
    if (definitions == null) {
      throw const VerificationFailure('Le catalogue du projet est illisible.');
    }
    return await _readEach(sources, (source) async {
      final map = _decoded(source, (_) {});
      await CatalogTargetedMapSelection.read(
        reader: definitions,
        mapId: source.entry.id,
        projectedMap: map,
      );
      return map;
    });
  } finally {
    service.closeWorkspace(opened.workspaceHandle);
  }
}

MapData _decoded(
  VerificationMapSource source,
  void Function(MapData map) validate,
) {
  final map = decodeValidatedMapDocument(
    source.bytes,
    source.entry.relativePath,
    validateMap: validate,
  );
  if (map.id != source.entry.id) throw const FormatException();
  return map;
}

Future<VerificationMaps> _readEach(
  List<VerificationMapSource> sources,
  Future<MapData> Function(VerificationMapSource source) read,
) async {
  final maps = <MapData>[];
  final unreadable = <ProjectMapEntry>[];
  for (final source in sources) {
    try {
      maps.add(await read(source));
    } on Object {
      unreadable.add(source.entry);
    }
  }
  return (maps: maps, unreadable: unreadable);
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
