import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

/// BETA-CIN-085 — the receipt refuses the two things the ticket fears.
///
/// "Canary vert en assemblant des fakes ou en plaçant l'interaction hors de la
/// Presentation." Both are named as the main risk, so both get a refusal that
/// says which one it caught. Everything else here exists because a green
/// receipt has to mean something narrower than "it worked".
void main() {
  test('a complete installed-Hub journey is certified', () {
    final receipt = InstalledHubJourneyReceipt.fromMeasurements(
      measurements: _measurements(),
      provenance: _provenance(),
    );

    expect(receipt.passed, isTrue, reason: receipt.violations.toString());
    expect(receipt.violations, isEmpty);
    expect(
      receipt.uncertifiedLimits,
      isNotEmpty,
      reason: 'the limits travel with the verdict, not in a commit message',
    );
  });

  group('the dialogue must happen DURING the Presentation', () {
    for (final outside in const <String>[
      'playing',
      'resuming',
      'stopped',
      'skipped',
      'disposed',
      'backgrounded',
    ]) {
      test('a cue observed while $outside is the old canary', () {
        expect(
          () => InstalledHubJourneyReceipt.fromMeasurements(
            measurements: _measurements(interactionState: outside),
            provenance: _provenance(),
          ),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('old canary'),
            ),
          ),
        );
      });
    }

    for (final inside in InstalledHubJourneyReceipt.insidePresentationStates) {
      test('a cue observed while $inside is accepted', () {
        final receipt = InstalledHubJourneyReceipt.fromMeasurements(
          measurements: _measurements(interactionState: inside),
          provenance: _provenance(),
        );
        expect(receipt.passed, isTrue);
      });
    }

    test('a path that answered nothing is refused', () {
      expect(
        () => InstalledHubJourneyReceipt.fromMeasurements(
          measurements: _measurements(noInteractions: true),
          provenance: _provenance(),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('did not exercise the dialogue'),
          ),
        ),
      );
    });
  });

  group('the journey must have run against the installed copy', () {
    test('an author workspace root is refused', () {
      expect(
        () => InstalledHubJourneyReceipt.fromMeasurements(
          measurements: _measurements(
            installedRoot: '/Users/someone/Desktop/my project/authoring',
          ),
          provenance: _provenance(),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('installed library'),
          ),
        ),
      );
    });

    test('the package hashes are required, so a fake cannot present them', () {
      expect(
        () => InstalledHubJourneyReceipt.fromMeasurements(
          measurements: _measurements(packageSha: 'not-a-digest'),
          provenance: _provenance(),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('every exit releases everything and commits exactly once', () {
    for (final path in InstalledHubJourneyReceipt.journeyPaths) {
      test('$path committing twice is a named violation', () {
        final receipt = InstalledHubJourneyReceipt.fromMeasurements(
          measurements: _measurements(doubleCommitPath: path),
          provenance: _provenance(),
        );
        expect(receipt.violations, <String>['paths.$path.terminalCommits']);
      });

      test('$path committing zero times is also a violation', () {
        final receipt = InstalledHubJourneyReceipt.fromMeasurements(
          measurements: _measurements(zeroCommitPath: path),
          provenance: _provenance(),
        );
        expect(receipt.violations, <String>['paths.$path.terminalCommits']);
      });
    }

    for (final resource in InstalledHubJourneyReceipt.residualResources) {
      test('a leaked $resource on cancel is named', () {
        final receipt = InstalledHubJourneyReceipt.fromMeasurements(
          measurements: _measurements(
            residual: (path: 'cancel', resource: resource),
          ),
          provenance: _provenance(),
        );
        expect(receipt.violations, <String>['paths.cancel.residual.$resource']);
      });
    }

    test('a missing path is refused rather than skipped', () {
      final measurements = _measurements();
      (measurements['paths']! as Map<String, Object?>).remove('error');
      expect(
        () => InstalledHubJourneyReceipt.fromMeasurements(
          measurements: measurements,
          provenance: _provenance(),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('error'),
          ),
        ),
      );
    });
  });

  group('the committed draft has to survive and change nothing else', () {
    test('all three fields are required', () {
      expect(
        () => InstalledHubJourneyReceipt.fromMeasurements(
          measurements: _measurements(
            committedFields: <String>['playerName'],
          ),
          provenance: _provenance(),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('avatar'),
          ),
        ),
      );
    });

    test('a mutated project config fails the receipt', () {
      final receipt = InstalledHubJourneyReceipt.fromMeasurements(
        measurements: _measurements(projectConfigUnchanged: false),
        provenance: _provenance(),
      );
      expect(receipt.violations, contains('persistence.projectConfigMutated'));
    });

    test('a draft that did not survive reload fails the receipt', () {
      final receipt = InstalledHubJourneyReceipt.fromMeasurements(
        measurements: _measurements(survivedReload: false),
        provenance: _provenance(),
      );
      expect(receipt.violations, contains('persistence.survivedReload'));
    });
  });

  group('the receipt says what it did not certify', () {
    test('an empty limits list is refused', () {
      expect(
        () => InstalledHubJourneyReceipt.fromMeasurements(
          measurements: _measurements(limits: const <String>[]),
          provenance: _provenance(),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('least likely to be true'),
          ),
        ),
      );
    });

    test('a dirty tree is refused', () {
      expect(
        () => InstalledHubJourneyReceipt.fromMeasurements(
          measurements: _measurements(),
          provenance: _provenance(treeState: 'dirty'),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('the commands that produced the run are required', () {
      expect(
        () => InstalledHubJourneyReceipt.fromMeasurements(
          measurements: _measurements(),
          provenance: _provenance(commands: const <String>[]),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('the receipt round-trips through JSON', () {
    final receipt = InstalledHubJourneyReceipt.fromMeasurements(
      measurements: _measurements(),
      provenance: _provenance(),
    );
    final restored = InstalledHubJourneyReceipt.fromJson(receipt.toJson());

    expect(restored.toJson(), receipt.toJson());
    expect(restored.passed, isTrue);
  });
}

Map<String, Object?> _measurements({
  String interactionState = 'interactionHold',
  bool noInteractions = false,
  String installedRoot =
      '/Users/x/Library/Containers/app.pokemap.hub/Data/Library/Application '
      'Support/app.pokemap.hub/PokeMap/games/games.pokemap.certification.'
      'neutral/versions/1.0.0',
  String packageSha =
      '1c373f632aaa2fd98e3f1694946b635cb7fe831a8492f71612a4104a5d68f197',
  String? doubleCommitPath,
  String? zeroCommitPath,
  ({String path, String resource})? residual,
  List<String>? committedFields,
  bool projectConfigUnchanged = true,
  bool survivedReload = true,
  List<String>? limits,
}) {
  Map<String, Object?> path(String name) => <String, Object?>{
        'outcome': name == 'nominal' ? 'ready' : name,
        'terminalCommits': doubleCommitPath == name
            ? 2
            : zeroCommitPath == name
                ? 0
                : 1,
        'interactions': noInteractions
            ? <Object?>[]
            : <Object?>[
                <String, Object?>{
                  'markerId': 'cue_player_name',
                  'kind': 'text',
                  'presentationState': interactionState,
                  'presentationNodeId': 'opening',
                },
              ],
        'residual': <String, Object?>{
          for (final resource in InstalledHubJourneyReceipt.residualResources)
            resource: residual != null &&
                    residual.path == name &&
                    residual.resource == resource
                ? 1
                : 0,
        },
      };

  return <String, Object?>{
    'schemaVersion': 1,
    'benchmark': 'installed_hub_journey_cin_085',
    'installedPackage': <String, Object?>{
      'gameId': 'games.pokemap.certification.neutral',
      'gameVersion': '1.0.0',
      'treeSha256':
          '680d93dc156b2ff23b3e555cf356addbbe71466ba8874836963d95e5c730d3e5',
      'packageSha256': packageSha,
      'installedVersionRoot': installedRoot,
    },
    'paths': <String, Object?>{
      for (final name in InstalledHubJourneyReceipt.journeyPaths)
        name: path(name),
    },
    'persistence': <String, Object?>{
      'committedDraftFields': committedFields ??
          InstalledHubJourneyReceipt.committedDraftFields.toList(),
      'visibleAfterHandoff': true,
      'survivedReload': survivedReload,
      'projectConfigUnchanged': projectConfigUnchanged,
    },
    'uncertifiedLimits': limits ??
        const <String>[
          'iOS and Android were not exercised: this run is macOS only.',
          'Corrupted media was not injected; the fixture carries valid assets.',
        ],
  };
}

Map<String, Object?> _provenance({
  String treeState = 'clean',
  List<String>? commands,
}) =>
    <String, Object?>{
      'commit': '0123456789abcdef0123456789abcdef01234567',
      'treeState': treeState,
      'platform': 'macos 27.0.0',
      'commands': commands ??
          const <String>[
            'dart run bin/build_dialogued_pre_session_package.dart '
                '--output night-watch-1.0.0.avelunegame',
            'flutter test integration_test/installed_hub_journey_test.dart',
          ],
      'recordedAtUtc': '2026-08-22T00:00:00.000Z',
    };
