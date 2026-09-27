import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _sourcePath = String.fromEnvironment('AVELUNE_RESOURCE_PROJECT');
const _rssGrowthLimitBytes = 1536 * 1024 * 1024;
const _decodedLimitBytes = 256 * 1024 * 1024;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'large project map visits stay within resource and process budgets',
    () async {
      final root = await Directory(_sourcePath).resolveSymbolicLinks();
      final manifest = ProjectManifest.fromJson(
        jsonDecode(await File('$root/project.json').readAsString())
            as Map<String, dynamic>,
      );
      expect(manifest.maps, isNotEmpty);
      final session = ProjectSession(
        sessionId: 'resource-probe',
        name: manifest.name,
        directoryPath: root,
      );
      final mapsBySize = manifest.maps.toList()
        ..sort(
          (a, b) => File('$root/${b.relativePath}').lengthSync().compareTo(
            File('$root/${a.relativePath}').lengthSync(),
          ),
        );
      final selected = [
        manifest.maps.first,
        ...mapsBySize
            .where((entry) => entry.id != manifest.maps.first.id)
            .take(5),
      ];
      final resources = await StudioMapResources.load(session, manifest);
      final initialRssBytes = ProcessInfo.currentRss;
      var peakRssBytes = initialRssBytes;
      var peakDecodedBytes = 0;
      try {
        for (var cycle = 0; cycle < 3; cycle++) {
          for (final entry in selected) {
            final map = MapData.fromJson(
              jsonDecode(
                    await File('$root/${entry.relativePath}').readAsString(),
                  )
                  as Map<String, dynamic>,
            );
            resources.setActiveMap(map);
            await resources.settled;
            final rssBytes = ProcessInfo.currentRss;
            if (rssBytes > peakRssBytes) peakRssBytes = rssBytes;
            if (resources.decodedBytes > peakDecodedBytes) {
              peakDecodedBytes = resources.decodedBytes;
            }
            expect(
              resources.decodedBytes,
              lessThanOrEqualTo(_decodedLimitBytes),
            );
          }
        }
        final processPeakRssBytes = ProcessInfo.maxRss;
        if (processPeakRssBytes > peakRssBytes) {
          peakRssBytes = processPeakRssBytes;
        }
        final result = {
          'project': manifest.name,
          'mapIds': selected.map((entry) => entry.id).toList(),
          'cycles': 3,
          'rssBeforeBytes': initialRssBytes,
          'rssPeakBytes': peakRssBytes,
          'rssGrowthBytes': peakRssBytes - initialRssBytes,
          'peakDecodedBytes': peakDecodedBytes,
          'peakAccountedBytes': resources.store.peakAccountedBytes,
          'evictions': resources.store.evictions,
          'diagnostics': resources.diagnostics.length,
        };
        stdout.writeln('RESOURCE_MEMORY_RESULT=${jsonEncode(result)}');
        expect(peakRssBytes - initialRssBytes, lessThan(_rssGrowthLimitBytes));
      } finally {
        await resources.dispose();
        expect(resources.decodedBytes, 0);
      }
    },
    skip: _sourcePath.isEmpty ? 'Set AVELUNE_RESOURCE_PROJECT' : false,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
