import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../tool/create_example_project.dart';

const _rssGrowthLimitBytes = 1536 * 1024 * 1024;
const _requestedOutputPath = String.fromEnvironment(
  'AVELUNE_RESOURCE_MEMORY_OUTPUT',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'opens, revisits and closes a real Studio project without runaway RSS',
    (tester) async {
      expect(Platform.isMacOS, isTrue);
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final directory = await Directory.systemTemp.createTemp(
        'avelune-resource-memory-e2e-',
      );
      final session = ProjectSessionController(LocalProjectSessionAdapter());
      final samples = <int>[];
      Timer? sampler;
      try {
        await writeExampleProject(
          directory,
          stress: true,
          stressAtlasCount: 24,
          stressErrorCount: 0,
        );
        await session.open(await directory.resolveSymbolicLinks());
        expect(session.state.project, isNotNull);

        final rssBeforeBytes = ProcessInfo.currentRss;
        sampler = Timer.periodic(
          const Duration(milliseconds: 50),
          (_) => samples.add(ProcessInfo.currentRss),
        );
        await tester.pumpWidget(StudioBootstrap(debugSession: session));
        await _pumpUntil(tester, find.byKey(const ValueKey('home-tool-map')));

        for (var cycle = 0; cycle < 3; cycle++) {
          await tester.tap(find.byKey(const ValueKey('home-tool-map')));
          await _pumpUntil(tester, find.byKey(const ValueKey('map-canvas')));
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Accueil').first);
          await _pumpUntil(tester, find.byKey(const ValueKey('home-tool-map')));
        }

        await tester.tap(find.byKey(const ValueKey('Fermer le projet')));
        await _pumpUntil(tester, find.text('Aucun projet ouvert'));
        expect(session.state.project, isNull);
        expect(tester.takeException(), isNull);

        sampler.cancel();
        final rssAfterCloseBytes = ProcessInfo.currentRss;
        samples.add(rssAfterCloseBytes);
        final sampledPeakRssBytes = samples.reduce((a, b) => a > b ? a : b);
        final processPeakRssBytes = ProcessInfo.maxRss;
        final peakRssBytes = sampledPeakRssBytes > processPeakRssBytes
            ? sampledPeakRssBytes
            : processPeakRssBytes;
        final growthBytes = peakRssBytes - rssBeforeBytes;
        binding.reportData = <String, dynamic>{
          'journey': 'avelune_studio_resource_memory',
          'fixture': 'stress-example-24-atlases-0-errors',
          'cycles': 3,
          'sampleCount': samples.length,
          'rssBeforeBytes': rssBeforeBytes,
          'sampledPeakRssBytes': sampledPeakRssBytes,
          'processPeakRssBytes': processPeakRssBytes,
          'peakRssBytes': peakRssBytes,
          'rssAfterCloseBytes': rssAfterCloseBytes,
          'rssGrowthBytes': growthBytes,
          'emergencyRssGrowthLimitBytes': _rssGrowthLimitBytes,
        };
        if (_requestedOutputPath.isNotEmpty) {
          await File(
            _requestedOutputPath,
          ).writeAsString(jsonEncode(binding.reportData));
        }
        expect(
          growthBytes,
          lessThan(_rssGrowthLimitBytes),
          reason: 'A small project must not grow by more than 1.5 GiB.',
        );
      } finally {
        sampler?.cancel();
        await tester.pumpWidget(const SizedBox.shrink());
        await session.dispose();
        if (await directory.exists()) await directory.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 400; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw TestFailure('Studio did not reach $finder');
}
