import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../support/dashboard_notifier_harness.dart';

void main() {
  late Directory root;
  late GameLibraryStore libraryStore;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hub-dashboard-');
    libraryStore = GameLibraryStore(supportRoot: root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('initialization exposes a guided empty library', () async {
    final harness = buildDashboardHarness(
      supportRoot: root,
      libraryStore: libraryStore,
      activityReader: (_) async => const HubGameActivity(),
    );

    await harness.notifier.initialize();

    expect(harness.snapshot.status, HubDashboardStatus.ready);
    expect(harness.snapshot.games, isEmpty);
    expect(harness.snapshot.library.revision, 0);
    harness.dispose();
  });

  test(
    'initialization consumes editor exports before reading the library',
    () async {
      var consumed = false;
      final harness = buildDashboardHarness(
        supportRoot: root,
        libraryStore: libraryStore,
        activityReader: (_) async => const HubGameActivity(),
        editorExportConsumer: () async {
          consumed = true;
          await libraryStore.save(
            GameLibrary(
              revision: 1,
              updatedAt: DateTime.utc(2026, 7, 25),
              games: <InstalledGame>[
                _game('games.example.exported', 'Exported'),
              ],
            ),
          );
          return const <EditorExportInstallResult>[
            EditorExportInstallResult(
              requestId: 'export-004',
              status: EditorExportInstallStatus.installed,
              code: 'installed',
            ),
          ];
        },
      );

      await harness.notifier.initialize();

      expect(consumed, isTrue);
      expect(harness.snapshot.games.single.game.title, 'Exported');
      harness.dispose();
    },
  );

  test('search, recent ordering, and selection are deterministic', () async {
    await libraryStore.save(
      GameLibrary(
        revision: 1,
        updatedAt: DateTime.utc(2026, 7, 25),
        games: <InstalledGame>[
          _game('games.example.aube', 'Aube'),
          _game('games.example.brume', 'Brume'),
        ],
      ),
    );
    final harness = buildDashboardHarness(
      supportRoot: root,
      libraryStore: libraryStore,
      activityReader:
          (game) async => HubGameActivity(
            canContinue: true,
            lastSaveAt:
                game.title == 'Brume'
                    ? DateTime.utc(2026, 7, 25)
                    : DateTime.utc(2026, 7, 24),
            playTimeSeconds: game.title == 'Brume' ? 7200 : 3600,
          ),
    );

    await harness.notifier.initialize();

    expect(harness.snapshot.games.map((game) => game.game.title), <String>[
      'Brume',
      'Aube',
    ]);
    harness.notifier.setQuery('aub');
    expect(harness.snapshot.visibleGames.single.game.title, 'Aube');
    harness.notifier.selectGame('games.example.aube');
    expect(harness.snapshot.selectedGame?.game.title, 'Aube');
    harness.notifier.closeGameDetails();
    expect(harness.snapshot.selectedGame, isNull);
    harness.dispose();
  });

  test(
    'package import publishes progress then refreshes the library',
    () async {
      var storageReads = 0;
      final harness = buildDashboardHarness(
        supportRoot: root,
        libraryStore: libraryStore,
        activityReader: (_) async => const HubGameActivity(),
        storageReader:
            () async => HubStorageSnapshot(usedBytes: ++storageReads),
        importer: (_, token, onProgress) async {
          expect(token.isCancelled, isFalse);
          onProgress(
            const GameInstallProgress(
              stage: GameInstallStage.extracting,
              completedFiles: 2,
              totalFiles: 4,
              completedBytes: 20,
              totalBytes: 40,
              cancellable: true,
            ),
          );
          await libraryStore.save(
            GameLibrary(
              revision: 1,
              updatedAt: DateTime.utc(2026, 7, 25),
              games: <InstalledGame>[_game('games.example.aube', 'Aube')],
            ),
          );
        },
      );
      final observed = harness.observeStatuses();

      await harness.notifier.initialize();
      final package = File('${root.path}/aube.avelunegame');
      await package.writeAsBytes(<int>[1, 2, 3]);
      await harness.notifier.importPackage(package);

      expect(observed, contains(HubDashboardStatus.installing));
      expect(harness.snapshot.games.single.game.title, 'Aube');
      expect(harness.snapshot.status, HubDashboardStatus.ready);
      expect(
        storageReads,
        2,
        reason: 'Storage is refreshed after installation.',
      );
      harness.dispose();
    },
  );

  test('cancel forwards to the active installation token', () async {
    late GameInstallCancellationToken received;
    final started = Completer<void>();
    final release = Completer<void>();
    final harness = buildDashboardHarness(
      supportRoot: root,
      libraryStore: libraryStore,
      activityReader: (_) async => const HubGameActivity(),
      importer: (_, token, __) async {
        received = token;
        started.complete();
        await release.future;
      },
    );
    await harness.notifier.initialize();
    final package = File('${root.path}/aube.avelunegame');
    await package.writeAsBytes(<int>[1]);

    final import = harness.notifier.importPackage(package);
    await started.future;
    harness.notifier.cancelImport();
    expect(received.isCancelled, isTrue);
    release.complete();
    await import;
    harness.dispose();
  });

  test('installer cancellation returns to the ready library state', () async {
    final harness = buildDashboardHarness(
      supportRoot: root,
      libraryStore: libraryStore,
      activityReader: (_) async => const HubGameActivity(),
      importer: (_, __, ___) async {
        throw const GameInstallationException(
          GameInstallationDiagnostic(
            code: GameInstallationErrorCode.cancelled,
            stage: GameInstallStage.cancelled,
            retryable: false,
            repairSuggested: false,
          ),
        );
      },
    );
    await harness.notifier.initialize();
    final package = File('${root.path}/aube.avelunegame');
    await package.writeAsBytes(<int>[1]);

    await harness.notifier.importPackage(package);

    expect(harness.snapshot.status, HubDashboardStatus.ready);
    expect(harness.snapshot.safeErrorMessage, isNull);
    harness.dispose();
  });

  test(
    'unexpected installer failures become player-safe diagnostics',
    () async {
      final harness = buildDashboardHarness(
        supportRoot: root,
        libraryStore: libraryStore,
        activityReader: (_) async => const HubGameActivity(),
        importer: (_, __, ___) async => throw StateError('private path'),
      );
      await harness.notifier.initialize();
      final package = File('${root.path}/aube.avelunegame');
      await package.writeAsBytes(<int>[1]);

      await harness.notifier.importPackage(package);

      expect(harness.snapshot.status, HubDashboardStatus.error);
      expect(harness.snapshot.diagnostics.last.code, 'install.unexpected');
      expect(harness.snapshot.safeErrorMessage, isNot(contains(root.path)));
      harness.dispose();
    },
  );

  test(
    'installation failures persist their exact cause in the Hub log',
    () async {
      final log = File('${root.path}/logs/hub.log');
      final harness = buildDashboardHarness(
        supportRoot: root,
        libraryStore: libraryStore,
        activityReader: (_) async => const HubGameActivity(),
        diagnosticLogFile: log,
        importer: (_, __, ___) async {
          throw GameInstallationException(
            const GameInstallationDiagnostic(
              code: GameInstallationErrorCode.integrityFailed,
              stage: GameInstallStage.inspecting,
              retryable: true,
              repairSuggested: false,
            ),
            cause: FileSystemException(
              'Operation not permitted',
              '${root.path}/selbrume.avelunegame',
              const OSError('Operation not permitted', 1),
            ),
          );
        },
      );
      await harness.notifier.initialize();
      final package = File('${root.path}/selbrume.avelunegame');
      await package.writeAsBytes(<int>[1]);

      await harness.notifier.importPackage(package);

      final diagnostic = harness.snapshot.diagnostics.last;
      expect(diagnostic.code, 'install.integrityFailed');
      expect(diagnostic.technicalDetails, contains('Operation not permitted'));
      expect(diagnostic.technicalDetails, contains(package.path));
      expect(diagnostic.logPath, log.path);
      expect(await log.exists(), isTrue);
      final persisted = await log.readAsString();
      expect(persisted, contains('Operation not permitted'));
      expect(persisted, contains(package.path));
      harness.dispose();
    },
  );

  test(
    'file picker failures are visible and persisted before installation',
    () async {
      final log = File('${root.path}/logs/hub-import.log');
      final harness = buildDashboardHarness(
        supportRoot: root,
        libraryStore: libraryStore,
        activityReader: (_) async => const HubGameActivity(),
        diagnosticLogFile: log,
      );
      await harness.notifier.initialize();

      await harness.notifier.reportImportPickerFailure(
        code: 'importPicker.missingEntitlement',
        message: 'Le sélecteur de fichiers ne peut pas s’ouvrir.',
        recommendation: 'Fermez complètement le Hub puis relancez-le.',
        cause: StateError(
          'Missing com.apple.security.files.user-selected.read-only entitlement.',
        ),
        stackTrace: StackTrace.current,
      );

      final diagnostic = harness.snapshot.diagnostics.last;
      expect(harness.snapshot.status, HubDashboardStatus.error);
      expect(
        harness.snapshot.safeErrorMessage,
        'Le sélecteur de fichiers ne peut pas s’ouvrir.',
      );
      expect(diagnostic.code, 'importPicker.missingEntitlement');
      expect(diagnostic.recommendation, contains('relancez'));
      expect(
        diagnostic.technicalDetails,
        contains('com.apple.security.files.user-selected.read-only'),
      );
      expect(diagnostic.logPath, log.path);
      final persisted = await log.readAsString();
      expect(persisted, contains('"operation":"pickPackage"'));
      expect(persisted, contains('"code":"importPicker.missingEntitlement"'));
      harness.dispose();
    },
  );

  test('rapid preference changes are persisted in order', () async {
    final preferences = HubPreferencesStore(supportRoot: root);
    final harness = buildDashboardHarness(
      supportRoot: root,
      libraryStore: libraryStore,
      activityReader: (_) async => const HubGameActivity(),
      preferencesStore: preferences,
    );
    await harness.notifier.initialize();
    final first = const PlayerPreferences().copyWith(
      language: PlayerLanguage.fr,
    );
    final second = const PlayerPreferences().copyWith(
      language: PlayerLanguage.en,
    );
    final last = second.copyWith(theme: PlayerThemePreference.dark);

    await Future.wait(<Future<void>>[
      harness.notifier.updatePreferences(first),
      harness.notifier.updatePreferences(second),
      harness.notifier.updatePreferences(last),
    ]);

    expect((await preferences.load()).preferences, last);
    harness.dispose();
  });
}

InstalledGame _game(String gameId, String title) {
  final version = InstalledGameVersion(
    gameVersion: Version.parse('1.0.0'),
    treeSha256: 'a' * 64,
    installedAt: DateTime.utc(2026, 7, 25),
    receiptFileName: '1.0.0-${'a' * 64}.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  return InstalledGame(
    gameId: gameId,
    title: title,
    description: 'Une aventure',
    authorName: 'Studio',
    defaultLocale: 'fr',
    supportedLocales: <String>['fr'],
    current: version.pointer,
    versions: <InstalledGameVersion>[version],
  );
}
