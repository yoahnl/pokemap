import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = Platform.environment['AVELUNE_PROJECT_COPY'];
  test(
    'isolated Train building atlas renders a real decor without loading its 329 atlas catalogue',
    () async {
      final manifest = ProjectManifest.fromJson(
        jsonDecode(await File('$root/project.json').readAsString())
            as Map<String, dynamic>,
      );
      final session = ProjectSession(
        sessionId: 'large-atlas-proof',
        name: manifest.name,
        directoryPath: root!,
      );
      final resources = await StudioMapResources.load(session, manifest);
      addTearDown(resources.dispose);
      expect(manifest.tilesets.length, greaterThan(128));
      expect(resources.store.decoder.reads, 0);
      final element = manifest.elements.firstWhere(
        (element) => element.frames.any(
          (frame) =>
              frame.tilesetId == 'hgss-buildings-assembled' ||
              frame.tilesetId.isEmpty &&
                  element.tilesetId == 'hgss-buildings-assembled',
        ),
      );
      resources.setBrush(element, null);
      await resources.settled;
      expect(resources.diagnostics, isEmpty);
      final atlas = resources.images['hgss-buildings-assembled']!;
      final frame = element.frames.first;
      final source = ui.Rect.fromLTWH(
        (frame.source.x * manifest.settings.tileWidth).toDouble(),
        (frame.source.y * manifest.settings.tileHeight).toDouble(),
        (frame.source.width * manifest.settings.tileWidth).toDouble(),
        (frame.source.height * manifest.settings.tileHeight).toDouble(),
      );
      final recorder = ui.PictureRecorder();
      atlas.drawImageRect(
        ui.Canvas(recorder),
        source,
        ui.Offset.zero & source.size,
        ui.Paint(),
      );
      final picture = recorder.endRecording();
      final rendered = await picture.toImage(
        source.width.toInt(),
        source.height.toInt(),
      );
      picture.dispose();
      final pixels = await rendered.toByteData();
      rendered.dispose();
      expect(
        [
          for (var offset = 3; offset < pixels!.lengthInBytes; offset += 4)
            pixels.getUint8(offset),
        ].any((alpha) => alpha > 0),
        isTrue,
      );
      expect(resources.store.decoder.decodes, 1);
      expect(resources.decodedBytes, 86507520);
      expect(
        resources.store.peakAccountedBytes,
        lessThanOrEqualTo(resources.store.maximumWorkingBytes),
      );
      stdout.writeln(
        jsonEncode({
          'projectCopy': root,
          'catalogueAtlases': manifest.tilesets.length,
          'element': element.id,
          'atlas': 'hgss-buildings-assembled',
          'width': atlas.width,
          'height': atlas.height,
          'reads': resources.store.decoder.reads,
          'decodes': resources.store.decoder.decodes,
          'residentBytes': resources.decodedBytes,
          'estimatedPeakAccountedBytes': resources.store.peakAccountedBytes,
          'maximumWorkingBytes': resources.store.maximumWorkingBytes,
        }),
      );
    },
    skip: root == null ? 'AVELUNE_PROJECT_COPY non fourni' : false,
  );
}
