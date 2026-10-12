import 'dart:async';

import 'package:avelune_converter/vision_desktop_services.dart';
import 'package:avelune_converter/vision_panel.dart';
import 'package:avelune_converter/vision_preview.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../packages/avelune_converter_adapters/test/support/original_asset_fixture.dart';

final class _Vault implements VisionSecretVault {
  int reads = 0;
  int writes = 0;
  int deletes = 0;
  @override
  Future<String?> read() async {
    reads++;
    return 'public-decoy-key';
  }

  @override
  Future<void> write(String secret) async {
    writes++;
  }

  @override
  Future<void> delete() async {
    deletes++;
  }
}

final class _Port implements VisionPort {
  final requests = <VisionRequest>[];
  Future<void>? gate;
  Object? failure;
  @override
  Future<VisionResponse> suggest(
    VisionRequest request, {
    ScanCancellation? cancellation,
  }) async {
    requests.add(request);
    await gate;
    if (failure case final error?) throw error;
    final context = request.context;
    return VisionResponse.fromJson({
      'schemaVersion': '1.0',
      'kind': 'visionResponse',
      'exampleOnly': false,
      'requestId': context.requestId.value,
      'sourceSnapshotHash': context.sourceSnapshotHash.value,
      'inputRevision': context.inputRevision,
      'suggestions': [
        {
          'suggestionId': 'ui-suggestion',
          'candidateIds': context.candidateIds.map((id) => id.value).toList(),
          'sourceRegionIds': context.sourceRegionIds
              .map((id) => id.value)
              .toList(),
          'proposedName': 'Arbre suggéré',
          'category': 'nature',
          'tags': ['arbre'],
          'evidenceSummary': 'À vérifier sur la découpe affichée',
          'uncertainties': ['Suggestion à confirmer'],
          'confidenceLabel': 'medium',
        },
      ],
    });
  }
}

void main() {
  late OriginalAssetFixture fixture;
  late AssetReviewSession session;
  late _Vault vault;
  late _Port port;
  var factories = 0;
  var sourceReads = 0;
  var changes = 0;
  setUp(() async {
    fixture = await OriginalAssetFixture.create();
    final candidate = fixture.treeCandidate();
    session = AssetReviewSession.create(
      sessionId: ConverterId('vision-panel-session'),
      logicalProjectNamespace: candidate.logicalProjectNamespace,
      sourceSnapshotHash: candidate.sourceSnapshotHash,
      selectedSourceMapIds: [1, 8, 12],
      outputMode: candidate.outputMode,
      proposalGenerationHash: canonicalHashOf('vision-panel-original-fixture'),
      candidates: [candidate],
    );
    vault = _Vault();
    port = _Port();
    factories = 0;
    sourceReads = 0;
    changes = 0;
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => ConverterVisionPanel(
                session: session,
                vault: vault,
                sourceFiles: () async {
                  sourceReads++;
                  return fixture.literalFixture.files;
                },
                verifySource: () async => true,
                excludedRoots: () async => [],
                clientFactory:
                    ({
                      required vault,
                      required liveContext,
                      required sourceFiles,
                      required excludedRoots,
                    }) async {
                      factories++;
                      return ConverterVisionClient(
                        port: port,
                        usage: () async => VisionUsageSnapshot(
                          requestCount: port.requests.length,
                          retryCount: 0,
                          unknownAttempts: 0,
                          knownCostMicros: null,
                          reservedCostMicros: null,
                        ),
                      );
                    },
                onSessionChanged: (next, previous) {
                  expect(previous, session.canonicalHash);
                  changes++;
                  setState(() => session = next);
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> prepare(WidgetTester tester) async {
    await tap(tester, 'vision-check-key');
    await tap(
      tester,
      'vision-candidate-${session.activeCandidates.single.candidateId.value}',
    );
    await tap(tester, 'vision-prepare');
    for (
      var i = 0;
      i < 50 && find.byKey(const ValueKey('vision-preview')).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(find.byKey(const ValueKey('vision-preview')), findsOneWidget);
  }

  testWidgets(
    'optional panel starts without key, source, factory or network work',
    (tester) async {
      await pump(tester);
      expect(find.text('Assistance visuelle facultative'), findsOneWidget);
      expect(vault.reads, 0);
      expect(factories, 0);
      expect(sourceReads, 0);
      expect(port.requests, isEmpty);
      expect(changes, 0);
      final input = find.descendant(
        of: find.byKey(const ValueKey('vision-key')),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(input).obscureText, isTrue);
    },
  );

  testWidgets(
    'only displayed material and consent dispatch, human metadata remains unapproved',
    (tester) async {
      await pump(tester);
      await prepare(tester);
      final before = session.activeCandidates.single;
      expect(
        tester
            .widget<StudioButton>(find.byKey(const ValueKey('vision-send')))
            .onPressed,
        isNull,
      );
      expect(port.requests, isEmpty);
      await tap(tester, 'vision-consent');
      await tap(tester, 'vision-send');
      await tester.pumpAndSettle();
      expect(port.requests, hasLength(1));
      final request = port.requests.single;
      expect(
        request.material.candidateHashes[before.candidateId],
        before.canonicalHash,
      );
      expect(
        request.material.crops.map((crop) => crop.regionId).toSet(),
        before.parts
            .map((part) => visionRegionId(before.candidateId, part.partId))
            .toSet(),
      );
      expect(request.consent.materialHash, request.material.canonicalHash);
      expect(session.frame.visionProposals, hasLength(1));
      expect(session.activeCandidates.single.name, before.name);
      expect(find.text('Catégorie proposée : Nature'), findsOneWidget);
      expect(find.text('Objet concerné : ${before.name}'), findsOneWidget);
      await tap(
        tester,
        'vision-apply-${session.frame.visionProposals.single.proposalId.value}',
      );
      await tester.pumpAndSettle();
      expect(session.activeCandidates.single.name, 'Arbre suggéré');
      expect(session.activeCandidates.single.state, CandidateState.needsReview);
      expect(session.activeCandidates.single.approvedRevision, isNull);
      expect(find.textContaining('Coût inconnu'), findsOneWidget);
    },
  );

  testWidgets(
    'selection change during a late response rejects all suggestions',
    (tester) async {
      final gate = Completer<void>();
      port.gate = gate.future;
      await pump(tester);
      await prepare(tester);
      final initialHash = session.canonicalHash;
      await tap(tester, 'vision-consent');
      await tap(tester, 'vision-send');
      expect(port.requests, hasLength(1));
      await tap(
        tester,
        'vision-candidate-${session.activeCandidates.single.candidateId.value}',
      );
      gate.complete();
      await tester.pumpAndSettle();
      expect(session.canonicalHash, initialHash);
      expect(session.frame.visionProposals, isEmpty);
      expect(changes, 0);
    },
  );

  testWidgets('provider failure never exposes a secret or mutates review', (
    tester,
  ) async {
    port.failure = StateError('Authorization Bearer public-decoy-key');
    await pump(tester);
    await prepare(tester);
    final initialHash = session.canonicalHash;
    await tap(tester, 'vision-consent');
    await tap(tester, 'vision-send');
    await tester.pumpAndSettle();
    expect(find.textContaining('public-decoy-key'), findsNothing);
    expect(find.textContaining('Authorization'), findsNothing);
    expect(find.byKey(const ValueKey('vision-error')), findsOneWidget);
    expect(session.canonicalHash, initialHash);
    expect(changes, 0);
  });

  testWidgets('rejected key gives useful recovery while preserving review', (
    tester,
  ) async {
    port.failure = const VisionAssistanceException('vision.keyRejected');
    await pump(tester);
    await prepare(tester);
    final initialHash = session.canonicalHash;
    await tap(tester, 'vision-consent');
    await tap(tester, 'vision-send');
    await tester.pumpAndSettle();
    expect(
      find.text('Le fournisseur refuse cette clé. La revue est conservée.'),
      findsOneWidget,
    );
    expect(session.canonicalHash, initialHash);
    expect(changes, 0);
  });
}
