import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_workshop.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';

void main() {
  test('the map lists border profiles without their pieces and resolves only the chosen one', () async {
    final measures = <int, ({int profileReads, int choiceReads})>{};
    for (final unrelated in [0, 150, 450]) {
      final fixture = await _BorderFixture.create(unrelated: unrelated);
      try {
        await fixture.openWorkspace();
        final workspace = fixture.workspace;
        expect(workspace.hasBorderProfiles, isFalse);
        expect(workspace.hasBorderBlueprint('cliff_target'), isFalse);
        final pieces = fixture.blockedPieceFiles();
        if (unrelated > 0) expect(pieces, isNotEmpty);

        final profileReads = await fixture.guarded(
          pieces,
          workspace.ensureBorderProfiles,
        );
        expect(workspace.hasBorderProfiles, isTrue);
        final listed = workspace.project!;
        expect(listed.borderCatalog.records.length, unrelated + 2);
        expect(
          listed.models3d.where((model) => model.id.startsWith('piece_')),
          isEmpty,
        );
        expect(
          listed.resourceLibraryCatalog
              .entryFor('borderBlueprint', 'cliff_target')
              ?.familyId,
          'family_cliffs',
        );
        expect(
          listed.resourceLibraryCatalog.families.map((family) => family.id),
          contains('family_cliffs'),
        );

        final choiceReads = await fixture.guarded(
          pieces,
          () => workspace.ensureBorderBlueprint('cliff_target'),
        );
        expect(workspace.hasBorderBlueprint('cliff_target'), isTrue);
        expect(workspace.hasBorderBlueprint('cliff_other'), isFalse);
        expect(
          workspace.project!.models3d
              .map((model) => model.id)
              .where((id) => id.startsWith('piece_'))
              .toSet(),
          {'piece_target_a', 'piece_target_b'},
        );
        expect(workspace.project!.borderCatalog.records.length, unrelated + 2);
        expect(
          workspace.visualProject!.models3d.map((model) => model.id),
          containsAll(['piece_target_a', 'piece_target_b']),
        );
        measures[unrelated] = (
          profileReads: profileReads,
          choiceReads: choiceReads,
        );

        await fixture.mutate('resource.classify', {
          'resourceKind': 'borderBlueprint',
          'resourceId': 'cliff_other',
          'familyId': 'family_cliffs',
        });
        expect(
          workspace.project!.resourceLibraryCatalog
              .entryFor('borderBlueprint', 'cliff_other')
              ?.familyId,
          'family_cliffs',
        );

        expect(workspace.hasWorkshop(MapWorkspaceWorkshop.resources), isFalse);
        await workspace.activate(
          workspace.project!.maps.singleWhere((map) => map.id == 'clairiere'),
        );
        expect(workspace.error, isNull);
        expect(workspace.project!.borderCatalog.records.length, unrelated + 2);
        expect(
          workspace.project!.models3d.map((model) => model.id),
          containsAll(['piece_target_a', 'piece_target_b']),
        );
        await fixture.mutate('resource.classify', {
          'resourceKind': 'borderBlueprint',
          'resourceId': 'cliff_other',
          'description': 'Après changement de carte',
        });

        await workspace.ensureResourceKind('element');
        expect(workspace.error, isNull);
        expect(workspace.hasBorderProfiles, isTrue);
        expect(workspace.hasBorderBlueprint('cliff_target'), isTrue);
        expect(workspace.project!.borderCatalog.records.length, unrelated + 2);
        expect(
          workspace.project!.models3d.map((model) => model.id),
          containsAll(['piece_target_a', 'piece_target_b']),
        );
        await fixture.mutate('resource.classify', {
          'resourceKind': 'borderBlueprint',
          'resourceId': 'cliff_other',
          'familyId': null,
          'description': null,
        });
        expect(
          workspace.project!.resourceLibraryCatalog.entryFor(
            'borderBlueprint',
            'cliff_other',
          ),
          isNull,
        );

        await fixture.reopen();
        expect(fixture.workspace.hasBorderProfiles, isFalse);
        await fixture.workspace.ensureBorderProfiles();
        expect(
          fixture.workspace.project!.resourceLibraryCatalog.entryFor(
            'borderBlueprint',
            'cliff_other',
          ),
          isNull,
        );
      } finally {
        await fixture.dispose();
      }
    }
    printOnFailure('$measures');
    expect(measures[150]!.choiceReads, measures[0]!.choiceReads);
    expect(measures[450]!.choiceReads, measures[0]!.choiceReads);
  }, timeout: const Timeout(Duration(minutes: 4)));

  test('the old family loading resolves every border piece', () async {
    final fixture = await _BorderFixture.create(unrelated: 12);
    try {
      await fixture.openWorkspace();
      await fixture.workspace.ensureResourceKind('borderBlueprint');
      expect(
        fixture.workspace.project!.models3d
            .where((model) => model.id.startsWith('piece_'))
            .length,
        2 * 14,
      );
      expect(fixture.workspace.hasBorderProfiles, isTrue);
      expect(fixture.workspace.hasBorderBlueprint('cliff_other'), isTrue);
    } finally {
      await fixture.dispose();
    }
  });
}

BorderBlueprintRecord _border(String id, List<String> modelIds) {
  final transforms = BorderTransformPolicy(
    allowFlipX: false,
    allowedQuarterTurns: const [0, 1, 2, 3],
  );
  final defaults = BorderGenerationParams(
    irregularityPermille: 0,
    detailDensityPermille: 0,
    variationPermille: 0,
    maxOverlapPx: 0,
    gapTolerancePx: 0,
    depthRows: 1,
  );
  final roles = [
    BorderPrimitiveRole.lineStraight,
    BorderPrimitiveRole.lineCorner,
  ];
  final draft = BorderBlueprintDraftDefinition(
    name: 'Falaise $id',
    previewSeed: BorderSignedInt64.fromInt(3),
    template: BorderBlueprintTemplate.connectedLine,
    primitives: [
      for (final (index, role) in roles.indexed)
        BorderPrimitiveDraft(
          id: role.name,
          sourceModelId: modelIds[index],
          role: role,
          authoredOrientation: BorderPrimitiveOrientation.east,
          weight: 1000,
          transforms: transforms,
        ),
    ],
    defaults: defaults,
    sortOrder: 0,
  );
  return BorderBlueprintRecord(
    id: id,
    draft: BorderBlueprintDraft(baseRevision: 1, definition: draft),
    latestPublished: BorderBlueprintRevision(
      revision: 1,
      definition: BorderBlueprintPublishedDefinition(
        name: draft.name,
        previewSeed: draft.previewSeed,
        template: draft.template,
        primitives: [
          for (final primitive in draft.primitives)
            BorderPublishedPrimitive(
              id: primitive.id,
              sourceModelId: primitive.sourceModelId,
              role: primitive.role,
              authoredOrientation: primitive.authoredOrientation,
              weight: primitive.weight,
              transforms: primitive.transforms,
            ),
        ],
        defaults: defaults,
        sortOrder: 0,
      ),
    ),
  );
}

ProjectModel3dEntry _model(String id) => ProjectModel3dEntry(
  id: id,
  name: 'Pièce $id',
  sourceAssetId: 'source_$id',
  relativePath: 'assets/models3d/$id.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 1, y: 1, z: 1),
    ),
    meshCount: 1,
    triangleCount: 4,
  ),
);

final class _BorderFixture {
  _BorderFixture(this.root, this.sessions, this.session);

  final Directory root;
  final LocalProjectSessionAdapter sessions;
  ProjectSession session;
  late LocalMapWorkspaceAdapter maps;
  late MapWorkspaceController workspace;
  late LocalResourceAdapter resources;
  bool _open = false;

  static Future<_BorderFixture> create({required int unrelated}) async {
    final root = await Directory.systemTemp.createTemp(
      'studio_border_profiles_',
    );
    await writeExampleProject(root);
    for (final id in ['jardin', 'clairiere']) {
      final mapFile = File('${root.path}/maps/$id.json');
      final map = MapData.fromJson(
        jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
      );
      await mapFile.writeAsString(
        jsonEncode(
          MapData(
            id: map.id,
            name: map.name,
            version: ProjectVersion.v9,
            size: const GridSize(width: 8, height: 6),
            spatialScene: MapSpatialScene(
              width: 8,
              depth: 6,
              heightLevels: List.filled(48, 0),
            ),
          ).toJson(),
        ),
      );
    }
    final file = File('${root.path}/project.json');
    final original = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    final names = [
      'target',
      'other',
      for (var index = 0; index < unrelated; index++)
        'u${index.toString().padLeft(4, '0')}',
    ];
    await file.delete();
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'studio-border-profiles-test',
      project: original.copyWith(
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        models3d: [
          for (final name in names) ...[
            _model('piece_${name}_a'),
            _model('piece_${name}_b'),
          ],
        ],
        borderCatalog: ProjectBorderCatalog(
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
          records: [
            for (final name in names)
              _border('cliff_$name', ['piece_${name}_a', 'piece_${name}_b']),
          ],
        ),
        resourceLibraryCatalog: ResourceLibraryCatalog(
          families: [ResourceFamily(id: 'family_cliffs', name: 'Falaises')],
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'borderBlueprint',
              resourceId: 'cliff_target',
              familyId: 'family_cliffs',
            ),
          ],
        ),
      ),
    );
    final sessions = LocalProjectSessionAdapter();
    final session = await sessions.open(await root.resolveSymbolicLinks());
    expect(session.storage, ProjectSessionStorage.workingCatalog);
    return _BorderFixture(root, sessions, session);
  }

  Future<void> openWorkspace() async {
    maps = LocalMapWorkspaceAdapter();
    workspace = MapWorkspaceController(session, maps);
    await workspace.initialize();
    expect(workspace.error, isNull);
    resources = LocalResourceAdapter(session: session, mapAdapter: maps);
    _open = true;
  }

  Map<String, File> blockedPieceFiles() {
    final blocked = <String, File>{};
    for (final file in root.listSync(recursive: true).whereType<File>()) {
      if (!file.path.contains('/catalog/objects/')) continue;
      final raw = jsonDecode(file.readAsStringSync());
      if (raw is! Map || raw['type'] != 'leaf' || raw['entries'] is! List) {
        continue;
      }
      final entries = raw['entries'] as List;
      if (entries.isNotEmpty &&
          entries.every((entry) {
            final id = '${entry['key']['id']}';
            return id.startsWith('piece_u') || id.startsWith('piece_other');
          })) {
        blocked[file.path] = file;
      }
    }
    return blocked;
  }

  Future<int> guarded(
    Map<String, File> blocked,
    Future<void> Function() body,
  ) async {
    final attempts = <String>[];
    var reads = 0;
    final outside = Zone.current;
    await IOOverrides.runZoned(
      body,
      createFile: (path) {
        if (path.contains('/catalog/objects/') &&
            !const {
              'leaf',
              'branch',
            }.contains(outside.run(() => _objectType(File(path))))) {
          reads++;
        }
        final original = blocked[path];
        return original == null
            ? outside.run(() => File(path))
            : _UnreadableFile(original, attempts);
      },
    );
    expect(attempts, isEmpty);
    return reads;
  }

  Future<void> mutate(String action, Map<String, Object?> parameters) async {
    final revision = await resources.captureResourceRevision();
    final preparation = await resources.prepareOperation(
      action,
      parameters,
      expectedSnapshotRevision: revision,
    );
    final receipt = await resources.applyPrepared(preparation);
    workspace.acceptResources(receipt.before, receipt.manifest);
  }

  Future<void> reopen() async {
    await _close();
    await sessions.close(session);
    session = await sessions.open(await root.resolveSymbolicLinks());
    await openWorkspace();
  }

  Future<void> _close() async {
    if (!_open) return;
    _open = false;
    await resources.dispose();
    workspace.dispose();
  }

  Future<void> dispose() async {
    await _close();
    await sessions.close(session);
    await root.delete(recursive: true);
  }
}

String? _objectType(File file) {
  try {
    final raw = jsonDecode(file.readAsStringSync());
    return raw is Map ? raw['type'] as String? : null;
  } on Object {
    return null;
  }
}

class _UnreadableFile implements File {
  _UnreadableFile(this.delegate, this.attempts);
  final File delegate;
  final List<String> attempts;
  Never deny() {
    attempts.add(path);
    throw StateError('Unrelated border piece read: $path');
  }

  @override
  String get path => delegate.path;
  @override
  Uri get uri => delegate.uri;
  @override
  bool get isAbsolute => delegate.isAbsolute;
  @override
  File get absolute => delegate.absolute;
  @override
  Directory get parent => delegate.parent;
  @override
  Future<Uint8List> readAsBytes() async => deny();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async => deny();
  @override
  Stream<List<int>> openRead([int? start, int? end]) => deny();
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async =>
      deny();
  @override
  Future<bool> exists() => delegate.exists();
  @override
  Future<FileStat> stat() => delegate.stat();
  @override
  Future<String> resolveSymbolicLinks() => delegate.resolveSymbolicLinks();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
