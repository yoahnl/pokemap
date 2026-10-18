import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart'
    hide PixelSize;
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  final scriptsPath = Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'];
  test(
      'canonical jump survives two same-edge connections and strict native writer reopen',
      () async {
    final output =
        await Directory.systemTemp.createTemp('ac15-connected-ledge-');
    addTearDown(() => output.delete(recursive: true));
    final atlas = image.Image(width: 256, height: 64, numChannels: 4);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        atlas.setPixelRgba(x, y, 31, 41, 59, 255);
      }
    }
    for (var part = 0; part < 3; part++) {
      for (var y = 48; y < 64; y++) {
        for (var x = 32 * part; x < 32 * (part + 1); x++) {
          atlas.setPixelRgba(x, y, 73 + part * 20, x, y, 255);
        }
      }
    }
    final fixture = await LiteralTileFixture.create(
        scriptsBytes:
            await File(Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS']!)
                .readAsBytes(),
        includeEventSystem: true,
        maps: [
          for (final id in [98, 100, 101])
            LiteralFixtureMap(
                id: id,
                width: 12,
                height: id == 98 ? 12 : 6,
                layers: [
                  List.filled(id == 98 ? 144 : 72, 384),
                  [
                    for (var index = 0; index < (id == 98 ? 144 : 72); index++)
                      if (id == 98 && index >= 25 && index <= 27)
                        392 + index - 25
                      else
                        0,
                  ],
                  List.filled(id == 98 ? 144 : 72, 0),
                ]),
        ],
        tilesets: [
          LiteralFixtureTileset(
              id: 1,
              png: image.encodePng(atlas),
              passages: {392: 7, 393: 7, 394: 7},
              terrainTags: {392: 1, 393: 1, 394: 1}),
        ],
        extraFiles: {
          'Data/map_connections.dat': _marshalConnections([
            [98, 'E', 0, 100, 'W', 0],
            [98, 'E', 6, 101, 'W', 0],
          ]),
          'PBS/metadata.txt':
              utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
          'Graphics/Characters/OriginalPlayer.png': image
              .encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
        });
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: fixture.snapshot,
        files: fixture.files,
        selectedMapIds: {98, 100, 101},
        includeConnections: true,
        includeEventSystem: true);
    final literal = await const LiteralTileComposer().compose(
        source: source,
        files: fixture.files,
        selectedSourceMapIds: [98, 100, 101],
        projectName: 'Original connected ledge',
        parentPath: output.path,
        folderName: 'original-connected-ledge');
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: source, base: literal, files: fixture.files))!;
    final event = (await const SourceEventStudyComposer()
        .compose(source: source, base: semantic, files: fixture.files))!;
    final draft = event.draft;
    expect(
        draft.mutations.where(
            (row) => row.actionId == 'connection.create_bidirectional_apply'),
        hasLength(2));
    final original = event.projection.nativeMaps[98]!;
    expect(original.connections.map((connection) => connection.offset), [0, 6]);
    expect(original.layers.whereType<BorderLayer>(), isNotEmpty);
    final approval = approveNativeFixtureDraft(draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, draft);
    expect(receipt.verified, isTrue);
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    try {
      final native = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(native.loadDiagnostics, isEmpty);
      expect(native.maps, hasLength(3));
      ProjectValidator.validate(native.manifest, maps: native.maps);
      final map = native.mapById(draft.mapIds[98]!)!;
      expect(map.connections, original.connections);
      for (final connection in map.connections) {
        final neighbor = native.mapById(connection.targetMapId)!;
        expect(neighbor.connections.single.targetMapId, map.id);
        expect(
            neighbor.connections.single.direction, MapConnectionDirection.west);
        expect(neighbor.connections.single.offset, -connection.offset);
      }
      final bindings = bindMaterializedBorderJumpFaces(
          map: map,
          project: native.manifest,
          tileSize: const PixelSize(width: 32, height: 32));
      expect(bindings.map((binding) => binding.carrierCell), [
        const GridPos(x: 1, y: 2),
        const GridPos(x: 2, y: 2),
        const GridPos(x: 3, y: 2),
      ]);
      for (final x in [1, 2, 3]) {
        final world = GameplayWorldState.initial(
            map: map,
            project: native.manifest,
            playerPos: GridPos(x: x, y: 1),
            tileWidth: 32,
            tileHeight: 32);
        expect(world.map.connections, original.connections);
        final jump =
            stepGameplayWorld(world, const MoveIntent(Direction.south));
        expect(jump, isA<Jumped>());
        expect((jump as Jumped).plan.landingPos, GridPos(x: x, y: 3));
        final reverse = GameplayWorldState.initial(
            map: map,
            project: native.manifest,
            playerPos: GridPos(x: x, y: 3),
            tileWidth: 32,
            tileHeight: 32);
        expect(
            stepGameplayWorld(
                reverse, const MoveIntent(Direction.north, pixelsPerStep: 32)),
            isA<Blocked>());
      }
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  }, skip: scriptsPath == null);
}

List<int> _marshalConnections(List<List<Object>> rows) {
  int compactInteger(int value) {
    if (value < 0 || value >= 123) {
      throw ArgumentError.value(value, 'value', 'Fixture integer out of range');
    }
    return value == 0 ? 0 : value + 5;
  }

  List<int> encode(Object value) => switch (value) {
        int() => [0x69, compactInteger(value)],
        String() => [
            0x22,
            compactInteger(utf8.encode(value).length),
            ...utf8.encode(value),
          ],
        List() => [
            0x5b,
            compactInteger(value.length),
            for (final item in value) ...encode(item as Object),
          ],
        _ => throw ArgumentError.value(value, 'value'),
      };
  return [4, 8, ...encode(rows)];
}
